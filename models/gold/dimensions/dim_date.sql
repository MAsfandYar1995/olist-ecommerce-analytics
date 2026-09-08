{{ config(
    materialized = 'table'
) }}

WITH date_spine AS (

    {{
        dbt_utils.date_spine(
            datepart = "day",
            start_date = "to_date('2016-01-01')",
            end_date = "to_date('2020-01-01')"
        )
    }}

),

final AS (

    SELECT
        TO_NUMBER(TO_CHAR(date_day, 'YYYYMMDD')) AS date_key,
        date_day::DATE AS date,

        DAY(date_day) AS day_of_month,
        DAYOFWEEKISO(date_day) AS day_of_week,
        DAYNAME(date_day) AS day_name,

        WEEKISO(date_day) AS week_of_year,

        MONTH(date_day) AS month_number,
        MONTHNAME(date_day) AS month_name,
        DATE_TRUNC('month', date_day)::DATE AS month_start_date,

        QUARTER(date_day) AS quarter_number,

        YEAR(date_day) AS year,

        TO_CHAR(date_day, 'YYYY-MM') AS year_month,

        CASE
            WHEN DAYOFWEEKISO(date_day) IN (6, 7) THEN TRUE
            ELSE FALSE
        END AS is_weekend

    FROM date_spine

)

SELECT *
FROM final