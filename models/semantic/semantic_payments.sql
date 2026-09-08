{{ config(materialized='semantic_view') }}

TABLES (
    payments AS {{ ref('fact_payments') }}
        PRIMARY KEY (order_id, payment_sequential)
)

FACTS (
    payments.payment_installments AS payment_installments
        COMMENT = 'Number of installments associated with the payment.',

    payments.payment_amount AS payment_amount
        COMMENT = 'Amount recorded for the payment.'
)

DIMENSIONS (
    payments.order_id AS order_id
        COMMENT = 'Order associated with the payment.',

    payments.payment_sequential AS payment_sequential
        COMMENT = 'Sequence number identifying the payment within an order.',

    payments.customer_key AS customer_key
        COMMENT = 'Surrogate key identifying the customer.',

    payments.order_date_key AS order_date_key
        COMMENT = 'Date key representing the order purchase date.',

    payments.payment_type AS payment_type
        COMMENT = 'Payment method used for the payment.'
)

METRICS (
    payments.total_payment_amount AS SUM(payments.payment_amount)
        COMMENT = 'Total value of payments.',

    payments.payment_count AS COUNT(*)
        COMMENT = 'Number of payment records.',

    payments.order_count AS COUNT(DISTINCT payments.order_id)
        COMMENT = 'Number of distinct orders with payment records.',

    payments.average_payment_amount AS AVG(payments.payment_amount)
        COMMENT = 'Average amount per payment record.',

    payments.average_installments AS AVG(payments.payment_installments)
        COMMENT = 'Average number of installments per payment record.'
)

COMMENT = 'Olist payments semantic view at payment-sequence grain.'