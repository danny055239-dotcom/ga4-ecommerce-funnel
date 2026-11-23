-- 02 整體購物漏斗（以工作階段為單位）
-- 商業問題：使用者在哪一步流失最多？
-- 說明：這是「開放式漏斗」，每一步只看該工作階段有沒有觸發這個事件，不要求依序完成。

WITH events AS (
  SELECT
    user_pseudo_id,
    (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') AS session_id,
    event_name
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
),

sessions AS (
  SELECT
    CONCAT(user_pseudo_id, '-', CAST(session_id AS STRING)) AS session_key,
    MAX(IF(event_name = 'view_item', 1, 0))        AS viewed_item,
    MAX(IF(event_name = 'add_to_cart', 1, 0))      AS added_to_cart,
    MAX(IF(event_name = 'begin_checkout', 1, 0))   AS began_checkout,
    MAX(IF(event_name = 'add_payment_info', 1, 0)) AS added_payment,
    MAX(IF(event_name = 'purchase', 1, 0))         AS purchased
  FROM events
  WHERE session_id IS NOT NULL
  GROUP BY session_key
),

funnel AS (
  SELECT 1 AS step_order, '1. 所有工作階段' AS step, COUNT(*) AS sessions FROM sessions
  UNION ALL SELECT 2, '2. 瀏覽商品',     SUM(viewed_item)    FROM sessions
  UNION ALL SELECT 3, '3. 加入購物車',   SUM(added_to_cart)  FROM sessions
  UNION ALL SELECT 4, '4. 開始結帳',     SUM(began_checkout) FROM sessions
  UNION ALL SELECT 5, '5. 填寫付款資訊', SUM(added_payment)  FROM sessions
  UNION ALL SELECT 6, '6. 完成購買',     SUM(purchased)      FROM sessions
)

SELECT
  step_order,
  step,
  sessions,
  ROUND(SAFE_DIVIDE(sessions, FIRST_VALUE(sessions) OVER (ORDER BY step_order)), 4) AS rate_from_start,
  ROUND(SAFE_DIVIDE(sessions, LAG(sessions) OVER (ORDER BY step_order)), 4)         AS rate_from_previous_step
FROM funnel
ORDER BY step_order;
