WITH sellers AS (
    SELECT 
        * 
    FROM {{ ref('stg_sellers') }}
),

geolocation AS (
    SELECT 
        * 
    FROM {{ ref('int_geolocation_deduplicated') }}
)

SELECT 
    s.seller_id,
    s.seller_zip_code_prefix,
    s.seller_city,
    s.seller_state,
    g.longitude AS seller_longitude,
    g.latitude AS seller_latitude
FROM sellers s 
LEFT JOIN geolocation g 
    ON s.seller_zip_code_prefix = g.zip_code_prefix
