
SELECT
    order_id,
    order_item_id,
    product_id,
    seller_id,
    shipping_limit_date,
    price,
    freight_value,
    current_timestamp() AS _bronze_loaded_at
FROM {{ source('olist_ecommerce', 'order_items') }}