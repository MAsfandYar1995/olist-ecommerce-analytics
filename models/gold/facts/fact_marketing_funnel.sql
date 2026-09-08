WITH qualified_leads AS (

    SELECT 
        * 
    FROM {{ ref('stg_qualified_leads') }}

),

closed_leads AS (

    SELECT 
        * 
    FROM {{ ref('stg_closed_leads') }}

),

dates AS (

    SELECT 
        * 
    FROM {{ ref('dim_date') }}

),

sellers AS (

    SELECT 
        * 
    FROM {{ ref('dim_seller') }}

)

SELECT 
    ql.mql_id,

    first_contact_dates.date_key AS first_contact_date_key,
    won_dates.date_key AS won_date_key,

    s.seller_key,

    ql.landing_page_id,
    ql.origin,

    cl.sdr_id,
    cl.sr_id,

    cl.business_segment,
    cl.lead_type,
    cl.lead_behaviour_profile,
    cl.has_company,
    cl.has_gtin,
    cl.average_stock,
    cl.business_type,

    cl.declared_product_catalog_size,
    cl.declared_monthly_revenue_amount,

    CASE
        WHEN cl.mql_id IS NOT NULL THEN 1
        ELSE 0
    END AS converted_flag,

    CASE
        WHEN cl.mql_id IS NOT NULL
             AND s.seller_key IS NOT NULL THEN 1
        ELSE 0
    END AS activated_seller_flag,

    cl.won_date - ql.first_contact_date AS days_to_convert

FROM qualified_leads ql 

LEFT JOIN closed_leads cl 
    ON ql.mql_id = cl.mql_id 

LEFT JOIN dates first_contact_dates
    ON first_contact_dates.date = ql.first_contact_date

LEFT JOIN sellers s 
    ON s.seller_id = cl.seller_id

LEFT JOIN dates won_dates
    ON won_dates.date = cl.won_date
