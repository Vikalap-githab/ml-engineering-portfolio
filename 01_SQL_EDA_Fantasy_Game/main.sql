/* Проект «Секреты Тёмнолесья»
 * Цель проекта: изучить влияние характеристик игроков и их игровых персонажей 
 * на покупку внутриигровой валюты «райские лепестки», а также оценить 
 * активность игроков при совершении внутриигровых покупок
 * 
 * Автор: Лапшина Виктория Борисовна
 * Дата: 28.09.2026г.
*/

-- Часть 1. Исследовательский анализ данных
-- Задача 1. Исследование доли платящих игроков

-- 1.1. Доля платящих пользователей по всем данным:
-- Напишите ваш запрос здесь
SELECT 
       COUNT(*) AS total_users,
       SUM(payer) AS paying_users,
       ROUND((SUM(payer)::NUMERIC / COUNT(*)) * 100, 2) AS paying_share_percent
FROM fantasy.users;
       
-- 1.2. Доля платящих пользователей в разрезе расы персонажа:
-- Напишите ваш запрос здесь
SELECT 
       r.race,
       SUM(payer) AS paying_users,
       COUNT(u.id) AS total_users,
       ROUND((SUM(u.payer)::NUMERIC / COUNT(u.id)) * 100, 2) AS paying_share_percent
FROM fantasy.users AS u
JOIN fantasy.race AS r ON u.race_id = r.race_id
GROUP BY r.race
ORDER BY paying_share_percent DESC;

-- Задача 2. Исследование внутриигровых покупок
-- 2.1. Статистические показатели по полю amount:
-- Напишите ваш запрос здесь
SELECT 
       COUNT(amount) AS total_purchases,
       SUM(amount) AS total_amount,
       MIN(amount) AS min_amount,
       MAX(amount) AS max_amount,
       AVG(amount) AS avg_amount,
       PERCENTILE_CONT(0.5)WITHIN GROUP(ORDER BY amount) AS median_amount,
       STDDEV(amount) AS stddev_amount
FROM fantasy.events;

-- 2.2: Аномальные нулевые покупки:
-- Напишите ваш запрос здесь
SELECT 
       SUM(CASE WHEN amount = 0 THEN 1 ELSE 0 END) AS zero_purchases,
       ROUND(SUM(CASE WHEN amount = 0 THEN 1 ELSE 0 END)::NUMERIC / COUNT(*) * 100, 2) AS zero_share
FROM fantasy.events;
-- 2.3: Популярные эпические предметы:
-- Напишите ваш запрос здесь
SELECT 
       i.game_items,
       COUNT(*) AS total_sales,
       ROUND(COUNT(*)::NUMERIC / SUM(COUNT(*)) OVER() * 100,2) AS sales_share_percent,
       ROUND(
            COUNT(DISTINCT e.id)::NUMERIC / 
            (SELECT COUNT(DISTINCT id) FROM fantasy.events WHERE amount > 0) 
        * 100, 2
    ) AS buyers_share_percent
FROM fantasy.events AS e
JOIN fantasy.items AS i ON e.item_code = i.item_code
WHERE e.amount > 0
GROUP BY i.game_items
ORDER BY buyers_share_percent DESC;

-- Часть 2. Решение ad hoc-задачbи
-- Задача: Зависимость активности игроков от расы персонажа:
-- Напишите ваш запрос здесь
WITH total_by_users_race AS (
     SELECT 
           race_id,
           COUNT(id) AS total_users
     FROM fantasy.users
     GROUP BY race_id
),
active_buyers_by_race AS (
    SELECT 
           u.race_id,
           COUNT(DISTINCT u.id) AS buyers_count,
           COUNT(DISTINCT CASE WHEN u.payer = 1 THEN u.id END) AS paying_players_count           
    FROM fantasy.users AS u
    JOIN fantasy.events AS e ON u.id = e.id 
    WHERE e.amount > 0
    GROUP BY u.race_id
),
purchase_activity_by_race AS (
    SELECT 
           u.race_id,
           COUNT(*) AS total_purchases,
           SUM(e.amount) AS total_amount
    FROM fantasy.users AS u
    JOIN fantasy.events AS e ON u.id = e.id 
    WHERE e.amount > 0
    GROUP BY u.race_id 
)
SELECT 
     r.race,
     t.total_users,
     a.buyers_count,
     ROUND(a.buyers_count::NUMERIC / t.total_users * 100, 2) AS buyers_share,
     ROUND (a.paying_players_count::NUMERIC / a.buyers_count * 100, 2) AS paying_share,
     ROUND(p.total_purchases::NUMERIC / a.buyers_count, 2) AS purchases_per_buyer,
     ROUND(p.total_amount::NUMERIC / p.total_purchases, 2) AS avg_check,
     ROUND(p.total_amount::NUMERIC / a.buyers_count, 2) AS arpu
FROM fantasy.race AS r 
LEFT JOIN total_by_users_race AS t ON r.race_id = t.race_id 
LEFT JOIN active_buyers_by_race AS a ON r.race_id = a.race_id 
LEFT JOIN purchase_activity_by_race AS p ON r.race_id = p.race_id 
ORDER BY t.total_users DESC;
