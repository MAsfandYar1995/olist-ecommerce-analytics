
WITH geolocation AS (

    SELECT 
        * 
    FROM {{ ref('stg_geolocation') }} 
),
grouped AS (

    SELECT
        
        zip_code_prefix,
        state,
        city,
        COUNT(*) AS occurrences,
        AVG(latitude) AS latitude,
        AVG(longitude) AS longitude
    FROM geolocation
    GROUP BY 1, 2, 3
    
),

deduped AS (


    SELECT 
        zip_code_prefix,
        state,
        city,
        longitude,
        latitude, 
        ROW_NUMBER() OVER (PARTITION BY zip_code_prefix ORDER BY occurrences DESC, state, city) AS occurence_rank
    FROM grouped

)


SELECT 
    zip_code_prefix,
    state,
    city,
    longitude,
    latitude 
FROM deduped 
WHERE occurence_rank = 1
