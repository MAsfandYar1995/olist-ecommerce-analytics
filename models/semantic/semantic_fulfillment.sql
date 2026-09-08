{{ config(materialized='semantic_view') }}

TABLES (
    fulfillment AS {{ ref('fact_order_fulfillment') }}
        PRIMARY KEY (order_id)
)

FACTS (
    fulfillment.approval_days AS approval_days
        COMMENT = 'Days from order purchase to approval.',

    fulfillment.handoff_days AS handoff_days
        COMMENT = 'Days from approval to carrier handoff.',

    fulfillment.shipping_delay_days AS shipping_delay_days
        COMMENT = 'Difference between carrier handoff and shipping deadline.',

    fulfillment.delivery_days AS delivery_days
        COMMENT = 'Days from carrier handoff to customer delivery.',

    fulfillment.total_fulfillment_days AS total_fulfillment_days
        COMMENT = 'Days from order purchase to customer delivery.',

    fulfillment.delivery_delay_days AS delivery_delay_days
        COMMENT = 'Difference between actual and estimated delivery date.'
)

DIMENSIONS (
    fulfillment.order_id AS order_id
        COMMENT = 'Unique order identifier.',

    fulfillment.order_status AS order_status
        COMMENT = 'Current or final status of the order.',

    fulfillment.customer_key AS customer_key
        COMMENT = 'Surrogate key identifying the customer.',

    fulfillment.order_purchase_date_key AS order_purchase_date_key
        COMMENT = 'Date key for order purchase.',

    fulfillment.order_approved_date_key AS order_approved_date_key
        COMMENT = 'Date key for order approval.',

    fulfillment.order_delivered_carrier_date_key AS order_delivered_carrier_date_key
        COMMENT = 'Date key for carrier handoff.',

    fulfillment.order_delivered_customer_date_key AS order_delivered_customer_date_key
        COMMENT = 'Date key for customer delivery.',

    fulfillment.order_estimated_delivery_date_key AS order_estimated_delivery_date_key
        COMMENT = 'Date key for estimated customer delivery.',

    fulfillment.order_latest_shipping_limit_date_key AS order_latest_shipping_limit_date_key
        COMMENT = 'Latest shipping deadline across the order items.',

    fulfillment.on_time_delivery_flag AS on_time_delivery_flag
        COMMENT = '1 when delivered on or before the estimated date, 0 when late.'
)

METRICS (
    fulfillment.order_count AS COUNT(*)
        COMMENT = 'Number of orders.',

    fulfillment.average_approval_days AS AVG(fulfillment.approval_days)
        COMMENT = 'Average time from purchase to approval.',

    fulfillment.average_handoff_days AS AVG(fulfillment.handoff_days)
        COMMENT = 'Average time from approval to carrier handoff.',

    fulfillment.average_delivery_days AS AVG(fulfillment.delivery_days)
        COMMENT = 'Average carrier-to-customer delivery time.',

    fulfillment.average_fulfillment_days AS AVG(fulfillment.total_fulfillment_days)
        COMMENT = 'Average total order fulfillment time.',

    fulfillment.average_delivery_delay_days AS AVG(fulfillment.delivery_delay_days)
        COMMENT = 'Average difference between actual and estimated delivery dates.',

    fulfillment.on_time_delivery_rate AS AVG(fulfillment.on_time_delivery_flag)
        COMMENT = 'Share of completed deliveries delivered on or before the estimated date.'
)

COMMENT = 'Olist order fulfillment and delivery performance semantic view.'