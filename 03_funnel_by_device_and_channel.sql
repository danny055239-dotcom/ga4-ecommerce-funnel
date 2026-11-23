-- 03 依裝置與流量來源比較轉換表現
-- 商業問題：哪個裝置、哪個來源的轉換最好或最差？購物車放棄率差多少？
-- 說明：traffic_source.medium 是使用者「第一次」造訪的來源，不是每次工作階段的來源，報告中要註明。

WITH events AS (
  SELECT
    user_pseudo_id,
    (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') AS session_id,
    event_name,
    device.category      AS device,
    traffic_source.medium AS first_medium
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
),

sessions AS (
  SELECT
    CONCAT(user_pseudo_id, '-', CAST(session_id AS STRING)) AS session_key,
    ANY_VALUE(device)       AS device,
    ANY_VALUE(first_medium) AS first_medium,
    MAX(IF(event_name = 'add_to_cart', 1, 0)) AS added_to_cart,
    MAX(IF(event_name = 'purchase', 1, 0))    AS purchased
  FROM events
  WHERE session_id IS NOT NULL
  GROUP BY session_key
),

by_dim AS (
  SELECT '裝置' AS dimension, device AS value, session_key, added_to_cart, purchased FROM sessions
  UNION ALL
  SELECT '首次來源', first_medium, session_key, added_to_cart, purchased FROM sessions
)

SELECT
  dimension,
  value,
  COUNT(*)            AS sessions,
  SUM(added_to_cart)  AS cart_sessions,
  SUM(purchased)      AS purchase_sessions,
  ROUND(SAFE_DIVIDE(SUM(purchased), COUNT(*)), 4)                AS conversion_rate,
  ROUND(SAFE_DIVIDE(SUM(added_to_cart), COUNT(*)), 4)            AS add_to_cart_rate,
  ROUND(1 - SAFE_DIVIDE(SUM(purchased), SUM(added_to_cart)), 4)  AS cart_abandonment_rate
FROM by_dim
GROUP BY dimension, value
HAVING COUNT(*) >= 500   -- 排除樣本太小的組別
ORDER BY dimension, sessions DESC;
