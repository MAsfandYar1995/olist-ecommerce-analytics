{{ config(materialized='semantic_view') }}

TABLES (
    sales AS {{ ref('fact_order_items') }}
        PRIMARY KEY (order_id, order_item_id)
)

FACTS (
    sales.quantity AS quantity
        COMMENT = 'Number of units represented by the order-item row.',

    sales.item_price AS item_price
        COMMENT = 'Selling price of the individual order item.',

    sales.freight_amount AS freight_amount
        COMMENT = 'Freight charge associated with the order item.',

    sales.gross_amount AS gross_amount
        COMMENT = 'Item price plus freight amount.'
)

DIMENSIONS (
    sales.order_id AS order_id
        COMMENT = 'Unique identifier for an Olist order.',

    sales.order_item_id AS order_item_id
        COMMENT = 'Sequence number identifying an item within an order.',

    sales.customer_key AS customer_key
        COMMENT = 'Surrogate key identifying the customer.',

    sales.product_key AS product_key
        COMMENT = 'Surrogate key identifying the product.',

    sales.seller_key AS seller_key
        COMMENT = 'Surrogate key identifying the seller.',

    sales.order_date_key AS order_date_key
        COMMENT = 'Date key representing the order purchase date.'
)

METRICS (
    sales.total_sales AS SUM(sales.gross_amount)
        COMMENT = 'Total gross sales including freight.',

    sales.product_revenue AS SUM(sales.item_price)
        COMMENT = 'Total item revenue excluding freight.',

    sales.total_freight AS SUM(sales.freight_amount)
        COMMENT = 'Total freight charges.',

    sales.units_sold AS SUM(sales.quantity)
        COMMENT = 'Total number of units sold.',

    sales.order_count AS COUNT(DISTINCT sales.order_id)
        COMMENT = 'Number of distinct customer orders.',

    sales.order_item_count AS COUNT(*)
        COMMENT = 'Number of order-item rows.',

    sales.average_item_price AS AVG(sales.item_price)
        COMMENT = 'Average selling price per order item.',

    sales.average_order_value AS
        SUM(sales.gross_amount) / NULLIF(COUNT(DISTINCT sales.order_id), 0)
        COMMENT = 'Average gross sales value per order.'
)

COMMENT = 'Olist sales semantic view at order-item grain.'