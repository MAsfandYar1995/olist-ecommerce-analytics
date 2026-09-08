
WITH source_customers AS (

    SELECT 
        *
    FROM {{ ref('bronze_customers') }}
),

cleaned_customers AS (

    SELECT 
        customer_id,
        customer_unique_id,
        LPAD(customer_zip_code_prefix::VARCHAR, 5, '0') AS customer_zip_code_prefix,
        lower(trim(customer_city)) AS customer_city,
        upper(trim(customer_state)) AS customer_state
    FROM source_customers

) 

SELECT 
    * 
FROM cleaned_customers