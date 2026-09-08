
SELECT 
    order_id,
    customer_id,
    order_status,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date, 
    order_estimated_delivery_date,
    current_timestamp() AS _bronze_loaded_at
FROM {{ source('olist_ecommerce', 'orders') }}