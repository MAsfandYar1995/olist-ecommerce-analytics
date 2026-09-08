


with source_geolocation as (

    select *
    from {{ ref('bronze_geolocation') }}

),

cleaned_geolocation as (

    select
        LPAD(geolocation_zip_code_prefix::VARCHAR, 5, '0') AS zip_code_prefix,
        geolocation_lat as latitude,
        geolocation_lng as longitude,
        lower(trim(geolocation_city)) as city,
        upper(trim(geolocation_state)) as state

    from source_geolocation

)

select *
from cleaned_geolocation