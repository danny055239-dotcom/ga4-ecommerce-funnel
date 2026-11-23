-- 06 新訪客 vs 回訪者的轉換差異
-- 商業問題：回訪者的轉換率比新訪客高多少？值不值得投資再行銷（retargeting）或會員經營？
-- 說明：ga_session_number = 1 代表這位使用者的第一次工作階段。

WITH events AS (
  SELECT
    user_pseudo_id,
    (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id')     AS session_id,
    (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_number') AS session_number,
    event_name,
    ecommerce.purchase_revenue_in_usd AS revenue_usd
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
),

sessions AS (
  SELECT
    CONCAT(user_pseudo_id, '-', CAST(session_id AS STRING)) AS session_key,
    MIN(session_number) AS session_number,
    MAX(IF(event_name = 'add_to_cart', 1, 0)) AS added_to_cart,
    MAX(IF(event_name = 'purchase', 1, 0))    AS purchased,
    SUM(IF(event_name = 'purchase', IFNULL(revenue_usd, 0), 0)) AS revenue_usd
  FROM events
  WHERE session_id IS NOT NULL
  GROUP BY session_key
)

SELECT
  CASE
    WHEN session_number = 1 THEN '新訪客（第 1 次）'
    WHEN session_number BETWEEN 2 AND 3 THEN '回訪者（第 2–3 次）'
    WHEN session_number >= 4 THEN '常客（第 4 次以上）'
    ELSE '未知'
  END AS visitor_type,
  COUNT(*)           AS sessions,
  SUM(purchased)     AS purchase_sessions,
  ROUND(SAFE_DIVIDE(SUM(purchased), COUNT(*)), 4)          AS conversion_rate,
  ROUND(SAFE_DIVIDE(SUM(added_to_cart), COUNT(*)), 4)      AS add_to_cart_rate,
  ROUND(SAFE_DIVIDE(SUM(revenue_usd), SUM(purchased)), 2)  AS avg_order_value_usd
FROM sessions
GROUP BY visitor_type
ORDER BY MIN(IFNULL(session_number, 999));
