SELECT 
    product_category_name,
    product_category_name_english,
    current_timestamp() AS _bronze_loaded_at
FROM {{ source('olist_ecommerce', 'product_category_translation') }}

