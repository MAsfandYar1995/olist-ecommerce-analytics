{{ config(materialized='semantic_view') }}

TABLES (
    marketing AS {{ ref('fact_marketing_funnel') }}
        PRIMARY KEY (mql_id),

    sellers AS {{ ref('dim_seller') }}
        PRIMARY KEY (seller_key),

    first_contact_dates AS {{ ref('dim_date') }}
        PRIMARY KEY (date_key),

    won_dates AS {{ ref('dim_date') }}
        PRIMARY KEY (date_key)
)

RELATIONSHIPS (
    marketing_to_sellers AS
        marketing(seller_key)
        REFERENCES sellers(seller_key),

    marketing_to_first_contact_dates AS
        marketing(first_contact_date_key)
        REFERENCES first_contact_dates(date_key),

    marketing_to_won_dates AS
        marketing(won_date_key)
        REFERENCES won_dates(date_key)
)

FACTS (
    marketing.converted_flag AS converted_flag,
    marketing.activated_seller_flag AS activated_seller_flag,
    marketing.days_to_convert AS days_to_convert,
    marketing.declared_monthly_revenue AS declared_monthly_revenue_amount,
    marketing.declared_catalog_size AS declared_product_catalog_size
)

DIMENSIONS (
    marketing.mql_id AS mql_id,

    marketing.landing_page_id AS landing_page_id,
    marketing.origin AS origin,

    marketing.sdr_id AS sdr_id,
    marketing.sr_id AS sr_id,

    marketing.business_segment AS business_segment,
    marketing.lead_type AS lead_type,
    marketing.lead_behaviour_profile AS lead_behaviour_profile,
    marketing.has_company AS has_company,
    marketing.has_gtin AS has_gtin,
    marketing.average_stock AS average_stock,
    marketing.business_type AS business_type,

    sellers.seller_city AS seller_city,
    sellers.seller_state AS seller_state,

    first_contact_dates.first_contact_date AS date,
    first_contact_dates.first_contact_month_start AS month_start_date,
    first_contact_dates.first_contact_month AS month_name,
    first_contact_dates.first_contact_month_number AS month_number,
    first_contact_dates.first_contact_quarter AS quarter_number,
    first_contact_dates.first_contact_year AS year,
    first_contact_dates.first_contact_year_month AS year_month,

    won_dates.won_date AS date,
    won_dates.won_month_start AS month_start_date,
    won_dates.won_month AS month_name,
    won_dates.won_month_number AS month_number,
    won_dates.won_quarter AS quarter_number,
    won_dates.won_year AS year,
    won_dates.won_year_month AS year_month
)

METRICS (
    marketing.mql_count AS
        COUNT(DISTINCT marketing.mql_id),

    marketing.won_deal_count AS
        SUM(marketing.converted_flag),

    marketing.mql_conversion_rate AS
        SUM(marketing.converted_flag)
        / NULLIF(COUNT(DISTINCT marketing.mql_id), 0),

    marketing.activated_seller_count AS
        SUM(marketing.activated_seller_flag),

    marketing.seller_activation_rate AS
        SUM(marketing.activated_seller_flag)
        / NULLIF(SUM(marketing.converted_flag), 0),

    marketing.average_days_to_convert AS
        AVG(
            CASE
                WHEN marketing.converted_flag = 1
                     AND marketing.days_to_convert >= 0
                THEN marketing.days_to_convert
            END
        )
)

COMMENT = 'Marketing semantic view for Olist lead acquisition, conversion and marketplace seller activation analysis'