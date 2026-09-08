
SELECT 
    mql_id,
    first_contact_date,
    landing_page_id,
    origin,
    current_timestamp() AS _bronze_loaded_at
FROM {{ source('olist_marketing', 'marketing_qualified_leads') }}

