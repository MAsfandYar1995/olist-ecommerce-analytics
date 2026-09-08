


with source_closed_leads as (

    select *
    from {{ ref('bronze_closed_leads') }}

),

cleaned_closed_leads as (

    select
        
        mql_id,
        seller_id,
        sdr_id,
        sr_id,
        won_date AS won_at,
        won_date::DATE AS won_date,
        lower(trim(business_segment)) AS business_segment,
        lower(trim(lead_type)) AS lead_type,
        lower(trim(lead_behaviour_profile)) AS lead_behaviour_profile,
        has_company,
        has_gtin,
        lower(trim(average_stock)) AS average_stock,
        lower(trim(business_type)) AS business_type,
        declared_product_catalog_size::INTEGER AS declared_product_catalog_size,
        declared_monthly_revenue AS declared_monthly_revenue_amount

    from source_closed_leads

)

select *
from cleaned_closed_leads




