    
SELECT
    geolocation_zip_code_prefix,
    geolocation_lat,
    geolocation_lng,
    geolocation_city,
    geolocation_state,
    current_timestamp() AS _bronze_loaded_at
FROM {{ source('olist_ecommerce', 'geolocation') }}