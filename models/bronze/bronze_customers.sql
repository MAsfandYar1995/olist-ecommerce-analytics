
SELECT 
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state,
    current_timestamp() AS _bronze_loaded_at
FROM {{ source('olist_ecommerce', 'customers') }}