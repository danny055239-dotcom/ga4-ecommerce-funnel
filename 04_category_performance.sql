-- 04 商品品類表現：瀏覽 → 加入購物車 → 售出
-- 商業問題：哪些品類「看的人多但加購少」（商品頁或價格可能有問題）？哪些品類營收貢獻最大？

WITH item_events AS (
  SELECT
    event_name,
    item.item_category AS category,
    IFNULL(item.quantity, 0)            AS quantity,
    IFNULL(item.item_revenue_in_usd, 0) AS item_revenue_usd
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`,
    UNNEST(items) AS item
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
    AND event_name IN ('view_item', 'add_to_cart', 'purchase')
)

SELECT
  category,
  COUNTIF(event_name = 'view_item')                      AS item_views,
  COUNTIF(event_name = 'add_to_cart')                    AS add_to_carts,
  SUM(IF(event_name = 'purchase', quantity, 0))          AS units_sold,
  ROUND(SUM(IF(event_name = 'purchase', item_revenue_usd, 0)), 2) AS revenue_usd,
  ROUND(SAFE_DIVIDE(COUNTIF(event_name = 'add_to_cart'), COUNTIF(event_name = 'view_item')), 4) AS view_to_cart_rate
FROM item_events
WHERE category IS NOT NULL
  AND category NOT IN ('', '(not set)')
GROUP BY category
HAVING COUNTIF(event_name = 'view_item') >= 1000   -- 排除瀏覽量太小的品類
ORDER BY revenue_usd DESC;
