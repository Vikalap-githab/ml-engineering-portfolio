/* Задача 1. Сегментация пользователей 
 * Разделите пользователей на группы по количеству совершённых ими заказов.
 * Подсчитайте для каждой группы общее количество пользователей,
 * среднее количество заказов, среднюю стоимость заказа.
 * 
 * Выделите такие сегменты:
 * - 1 заказ — сегмент 1 заказ
 * - от 2 до 5 заказов — сегмент 2-5 заказов
 * - от 6 до 10 заказов — сегмент 6-10 заказов
 * - 11 и более заказов — сегмент 11 и более заказов
*/

WITH user_segments AS (
    SELECT 
        user_id,
        total_order_costs,
        total_orders,
        CASE
            WHEN total_orders = 1 THEN '1 заказ'
            WHEN total_orders >= 2 AND total_orders <= 5 THEN '2—5 заказов'
            WHEN total_orders >= 6 AND total_orders <= 10 THEN '6–10 заказов'   
            ELSE '11 и более заказов' 
        END AS segment
    FROM ds_ecom.product_user_features
)
SELECT 
    segment,
    COUNT(DISTINCT user_id) AS user_count,
    ROUND(AVG(total_orders), 2) AS avg_orders,
    ROUND(SUM(total_order_costs)::NUMERIC / NULLIF(SUM(total_orders), 0), 2) AS avg_order_cost
FROM user_segments
GROUP BY segment
ORDER BY MIN(total_orders);
