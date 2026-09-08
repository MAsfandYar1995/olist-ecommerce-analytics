WITH base_sellers AS (
    SELECT 
        * 
    FROM {{ ref('int_sellers_enriched') }}
),

final_sellers AS (


    SELECT
        {{ dbt_utils.generate_surrogate_key(['seller_id']) }} AS seller_key,
        seller_id,
        seller_zip_code_prefix,
        seller_city,
        seller_state,
        seller_latitude AS latitude,
        seller_longitude AS longitude
    FROM base_sellers

)

SELECT * FROM final_sellers

