SELECT *
FROM {{ ref('fact_payments') }}
WHERE payment_amount < 0