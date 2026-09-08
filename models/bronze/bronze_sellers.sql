SELECT 
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state,
    current_timestamp() AS _bronze_loaded_at
FROM {{ source('olist_ecommerce', 'sellers') }}