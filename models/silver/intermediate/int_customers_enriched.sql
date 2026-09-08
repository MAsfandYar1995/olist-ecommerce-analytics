WITH customers AS (
    SELECT 
        * 
    FROM {{ ref('stg_customers') }}
),

geolocation AS (
    SELECT 
        * 
    FROM {{ ref('int_geolocation_deduplicated') }}
)

SELECT 
    c.customer_id,
    c.customer_unique_id,
    c.customer_zip_code_prefix,
    c.customer_city,
    c.customer_state,
    g.longitude AS customer_longitude,
    g.latitude AS customer_latitude
FROM customers c 
LEFT JOIN geolocation g 
    ON c.customer_zip_code_prefix = g.zip_code_prefix
