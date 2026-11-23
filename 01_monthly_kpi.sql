-- 01 每月 KPI：使用者、工作階段、訂單、營收、轉換率、客單價
-- 商業問題：檔期（黑五、聖誕）前後的整體表現有什麼變化？

WITH base AS (
  SELECT
    FORMAT_DATE('%Y-%m', PARSE_DATE('%Y%m%d', event_date)) AS month,
    user_pseudo_id,
    event_name,
    CONCAT(
      user_pseudo_id, '-',
      CAST((SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') AS STRING)
    ) AS session_key,
    ecommerce.purchase_revenue_in_usd AS revenue_usd
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
)

SELECT
  month,
  COUNT(DISTINCT user_pseudo_id) AS users,
  COUNT(DISTINCT session_key) AS sessions,
  COUNTIF(event_name = 'purchase') AS purchases,
  ROUND(SUM(IF(event_name = 'purchase', revenue_usd, 0)), 2) AS revenue_usd,
  ROUND(SAFE_DIVIDE(COUNTIF(event_name = 'purchase'), COUNT(DISTINCT session_key)), 4) AS conversion_rate,
  ROUND(SAFE_DIVIDE(SUM(IF(event_name = 'purchase', revenue_usd, 0)), COUNTIF(event_name = 'purchase')), 2) AS avg_order_value_usd
FROM base
GROUP BY month
ORDER BY month;
