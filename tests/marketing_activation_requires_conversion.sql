
SELECT 
  *
FROM {{ ref('fact_marketing_funnel') }}
WHERE activated_seller_flag = 1
  AND converted_flag = 0