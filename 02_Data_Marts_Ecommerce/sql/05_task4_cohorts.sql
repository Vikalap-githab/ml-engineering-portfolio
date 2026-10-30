
/* Выводы по Задаче 4: Когортный анализ качества привлечения (2023 год)
 *
 * Методологическая оговорка:
 * - Средняя продолжительность активности (lifetime) считается только среди клиентов,
 *   которые совершили повторную покупку (lifetime > 0). Клиенты с одним заказом
 *   исключены, чтобы метрика отражала реальную активность, а не долю "одноразовых".
 * - Падение lifetime к декабрю частично объясняется эффектом короткого окна наблюдения:
 *   у клиентов, пришедших в конце года, физически меньше времени для повторных покупок.
 *
 * Ключевые инсайты:
 * - Эффект "Black Friday" (ноябрь): резкий скачок привлечения (+66% к октябрю),
 *   но низкая доля вернувшихся клиентов и минимальный lifetime. Это "охотники за скидками".
 * - "Золотые" когорты: август и сентябрь показывают максимальное качество аудитории
 *   (высокий рейтинг, высокий чек).
 * - Стабильное ядро: ~20% пользователей предпочитают денежные переводы на протяжении всего года.
 *
 * Рекомендации для бизнеса:
 * - Проанализировать каналы привлечения ноябрьской когорты и сместить бюджет на удержание.
 * - Изучить опыт августа-сентября и масштабировать его на другие месяцы.
 * - Улучшить UX оплаты денежными переводами (QR-коды, автозаполнение реквизитов).
 */

SELECT 
    TO_CHAR(DATE_TRUNC('month', first_order_ts), 'YYYY-MM') AS month,
    COUNT(DISTINCT user_id) AS count_users,
    ROUND(
        COUNT(CASE WHEN EXTRACT(EPOCH FROM lifetime) > 0 THEN 1 END)::NUMERIC / 
        NULLIF(COUNT(DISTINCT user_id), 0) * 100, 
        2
    ) AS returning_users_pct,
    ROUND(
        AVG(CASE WHEN EXTRACT(EPOCH FROM lifetime) > 0 THEN EXTRACT(EPOCH FROM lifetime) END) / 86400, 
        2
    ) AS avg_lifetime_days,
    SUM(total_orders) AS count_orders,
    ROUND(SUM(total_order_costs)::NUMERIC / NULLIF(SUM(total_orders), 0), 2) AS avg_cost_orders,
    ROUND(AVG(avg_order_rating), 2) AS avg_order_rating,
    ROUND((SUM(used_money_transfer)::NUMERIC / NULLIF(COUNT(DISTINCT user_id), 0)) * 100, 2) AS money_transfer_users_ratio_pct
FROM ds_ecom.product_user_features
WHERE EXTRACT(YEAR FROM first_order_ts) = 2023
GROUP BY TO_CHAR(DATE_TRUNC('month', first_order_ts), 'YYYY-MM')
ORDER BY month;
