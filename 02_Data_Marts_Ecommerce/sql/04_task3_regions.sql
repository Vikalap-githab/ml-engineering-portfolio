/* Выводы по Задаче 3: Географическая статистика и платежное поведение
 *
 * Ключевые инсайты:
 * - Рассрочка как драйвер: Более 54% заказов в регионах и почти 48% в Москве оформляются
 *   в рассрочку. Без этого инструмента объем продаж мог бы быть вдвое ниже.
 * - Региональный парадокс: Средний чек в Москве самый низкий, несмотря на максимальный трафик.
 *   В регионах чеки на 11–14% выше, что коррелирует с высокой долей рассрочек (вероятно,
 *   это редкие, но дорогие покупки, например, техника).
 * - Низкая роль промокодов: Доля заказов с промокодами ничтожна (~3.7–4.1%), а отмены
 *   стабильно низкие (< 0.65%), что говорит о высокой осознанности покупок.
 *
 * Рекомендации для бизнеса:
 * - Сделать виджет рассрочки максимально заметным на карточках товаров.
 * - Провести аудит воронки применения промокодов: возможно, условия их получения слишком сложные.
 */

SELECT 
    region,
    COUNT(DISTINCT user_id) AS count_users,
    SUM(total_orders) AS count_orders,
    ROUND(SUM(total_order_costs)::NUMERIC / NULLIF(SUM(total_orders), 0), 2) AS avg_cost_orders,
    ROUND((SUM(num_installment_orders)::NUMERIC / NULLIF(SUM(total_orders), 0)) * 100, 2) AS installment_orders_ratio_pct,
    ROUND((SUM(num_orders_with_promo)::NUMERIC / NULLIF(SUM(total_orders), 0)) * 100, 2) AS promo_orders_ratio_pct,
    ROUND((SUM(used_cancel)::NUMERIC / NULLIF(COUNT(DISTINCT user_id), 0)) * 100, 2) AS canceled_users_ratio_pct
FROM ds_ecom.product_user_features
GROUP BY region
ORDER BY count_users DESC;
