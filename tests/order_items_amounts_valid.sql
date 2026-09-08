SELECT *
FROM {{ ref('fact_order_items') }}
WHERE
    item_price < 0
    OR freight_amount < 0
    OR gross_amount < 0