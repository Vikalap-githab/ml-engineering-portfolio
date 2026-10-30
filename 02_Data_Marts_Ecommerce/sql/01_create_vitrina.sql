-- Единая CTE с заказами. 
-- Фильтр по статусам и наличие позиций/платежей (отсекаем невалидные заказы).

WITH cte_orders AS (
    SELECT 
        o.order_id,
        o.order_status,
        o.order_purchase_ts,
        u.user_id,
        u.region
    FROM ds_ecom.orders AS o
    JOIN ds_ecom.users AS u ON o.buyer_id = u.buyer_id
    WHERE o.order_status IN ('Доставлено', 'Отменено')
      AND o.order_id IN (SELECT order_id FROM ds_ecom.order_items)
      AND o.order_id IN (SELECT order_id FROM ds_ecom.order_payments)
),

-- Нумерация платежей внутри заказа.
-- Защита от сбоев нумерации: берем первый платеж по порядку, а не по номеру 1.
cte_payments_numbered AS (
    SELECT 
        order_id,
        payment_type,
        payment_installments,
        ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY payment_sequential) AS payment_rn
    FROM ds_ecom.order_payments
),

-- Агрегация платежей по заказу.
cte_payments AS (
    SELECT 
        order_id,
        MAX(CASE WHEN payment_rn = 1 THEN payment_type END) AS first_payment_type,
        MAX(CASE WHEN payment_type = 'промокод' THEN 1 ELSE 0 END) AS has_promo,
        MAX(CASE WHEN payment_installments > 1 THEN 1 ELSE 0 END) AS has_installments
    FROM cte_payments_numbered
    GROUP BY order_id
),

-- Стоимость заказа. Считается только для доставленных заказов.
cte_costs AS (
    SELECT 
        oi.order_id,
        SUM(oi.price) + SUM(oi.delivery_cost) AS total_order_costs
    FROM ds_ecom.order_items AS oi
    JOIN cte_orders AS o ON oi.order_id = o.order_id 
                         AND o.order_status = 'Доставлено'
    GROUP BY oi.order_id
),

-- Средний рейтинг заказа. 
-- Особенности данных: нормализация аномальных оценок (>= 10) к шкале 1-5 делением на 10.
cte_ratings AS (
    SELECT 
        r.order_id,
        ROUND(AVG(
            CASE
                WHEN r.review_score >= 10 THEN r.review_score / 10.0 
                ELSE r.review_score::NUMERIC 
            END
        ), 2) AS avg_review_score  
    FROM ds_ecom.order_reviews AS r
    JOIN cte_orders AS o ON r.order_id = o.order_id
    GROUP BY r.order_id
),

-- Топ-3 региона по количеству заказов.
cte_top_regions AS (
    SELECT region
    FROM cte_orders
    GROUP BY region
    ORDER BY COUNT(order_id) DESC
    LIMIT 3
)

-- Финальный SELECT: группировка по user_id, region.
-- Все метрики считаются агрегатными функциями.
SELECT 
    o.user_id,
    o.region,
    MIN(o.order_purchase_ts) AS first_order_ts,
    MAX(o.order_purchase_ts) AS last_order_ts,
    MAX(o.order_purchase_ts) - MIN(o.order_purchase_ts) AS lifetime,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(AVG(r.avg_review_score), 2) AS avg_order_rating, 
    COUNT(r.avg_review_score) AS num_orders_with_rating,
    SUM(CASE WHEN o.order_status = 'Отменено' THEN 1 ELSE 0 END) AS num_canceled_orders,
    ROUND(
        SUM(CASE WHEN o.order_status = 'Отменено' THEN 1 ELSE 0 END)::NUMERIC / 
        NULLIF(COUNT(DISTINCT o.order_id), 0), 
        2
    ) AS canceled_orders_ratio,
    SUM(c.total_order_costs) AS total_order_costs,
    ROUND(AVG(c.total_order_costs), 2) AS avg_order_cost,
    SUM(p.has_installments) AS num_installment_orders,
    SUM(p.has_promo) AS num_orders_with_promo,
    MAX(CASE WHEN p.first_payment_type = 'денежный перевод' THEN 1 ELSE 0 END) AS used_money_transfer,
    MAX(p.has_installments) AS used_installments,
    MAX(CASE WHEN o.order_status = 'Отменено' THEN 1 ELSE 0 END) AS used_cancel
FROM cte_orders AS o
JOIN cte_payments AS p ON o.order_id = p.order_id          -- INNER JOIN, так как заказы без платежей невалидны
LEFT JOIN cte_costs AS c ON o.order_id = c.order_id         -- LEFT JOIN, чтобы не потерять отмененные заказы
LEFT JOIN cte_ratings AS r ON o.order_id = r.order_id       -- LEFT JOIN, так как отзывы необязательны
JOIN cte_top_regions AS tr ON o.region = tr.region          -- INNER JOIN для фильтрации топ-3 регионов
GROUP BY o.user_id, o.region;
