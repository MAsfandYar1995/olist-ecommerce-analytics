SELECT 
    order_id,
    payment_sequential,
    payment_type,
    payment_installments,
    payment_value,
    current_timestamp() AS _bronze_loaded_at
FROM {{ source('olist_ecommerce', 'order_payments') }}