

{{ config(severity = 'warn') }}


SELECT *
FROM {{ ref('fact_order_fulfillment') }}
WHERE
    approval_days < 0
    OR handoff_days < 0
    OR delivery_days < 0
    OR total_fulfillment_days < 0