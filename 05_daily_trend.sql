-- 05 每日趨勢：工作階段、訂單、營收、轉換率
-- 商業問題：黑色星期五（2020-11-27）、網購星期一（2020-11-30）與聖誕節前後，流量和轉換有什麼變化？

WITH base AS (
  SELECT
    PARSE_DATE('%Y%m%d', event_date) AS date,
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
  date,
  FORMAT_DATE('%A', date) AS weekday,
  COUNT(DISTINCT session_key)      AS sessions,
  COUNTIF(event_name = 'purchase') AS purchases,
  ROUND(SUM(IF(event_name = 'purchase', revenue_usd, 0)), 2) AS revenue_usd,
  ROUND(SAFE_DIVIDE(COUNTIF(event_name = 'purchase'), COUNT(DISTINCT session_key)), 4) AS conversion_rate
FROM base
GROUP BY date
ORDER BY date;
