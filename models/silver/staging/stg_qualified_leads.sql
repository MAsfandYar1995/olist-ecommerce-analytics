
with source_qualified_leads as (

    select *
    from {{ ref('bronze_qualified_leads') }}

),

cleaned_qualified_leads as (

    select

        mql_id,
        first_contact_date,
        landing_page_id,
        lower(trim(origin)) AS origin

    from source_qualified_leads

)

select *
from cleaned_qualified_leads

