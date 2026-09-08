SELECT *
FROM {{ ref('fact_order_items') }}
WHERE gross_amount <> item_price + freight_amount