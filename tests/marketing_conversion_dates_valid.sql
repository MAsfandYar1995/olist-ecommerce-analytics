{{ config(severity = 'warn') }}

SELECT *
FROM {{ ref('fact_marketing_funnel') }}
WHERE converted_flag = 1
  AND (
      won_date_key IS NULL
      OR days_to_convert < 0
  )