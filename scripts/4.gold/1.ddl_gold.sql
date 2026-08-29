/*
===============================================================================
DDL Script: Create Gold Views
===============================================================================
Script Purpose:
    This script creates views for the Gold layer in the data warehouse. 
    The Gold layer represents the final dimension and fact tables (Star Schema)

    Each view performs transformations and combines data from the Silver layer 
    to produce a clean, enriched, and business-ready dataset.

Usage:
    - These views can be queried directly for analytics and reporting.
===============================================================================
*/

-- =============================================================================
-- Create Dimension: gold.dim_customers
-- =============================================================================
IF OBJECT_ID('gold.dim_customers', 'V') IS NOT NULL
    DROP VIEW gold.dim_customers;
GO

CREATE VIEW gold.dim_customers AS
SELECT
    ROW_NUMBER() OVER (ORDER BY cst_id) AS customer_key, -- Surrogate key
    CusInfo.cst_id                          AS customer_id,
    CusInfo.cst_key                         AS customer_number,
    CusInfo.cst_firstname                   AS first_name,
    CusInfo.cst_lastname                    AS last_name,
    CusLoc.cntry                           AS country,
    CusInfo.cst_marital_status              AS marital_status,
    CASE 
        WHEN CusInfo.cst_gndr != 'n/a' THEN CusInfo.cst_gndr -- CRM is the primary source for gender
        ELSE COALESCE(CusBirth.gen, 'n/a')  			   -- Fallback to ERP data
    END                                AS gender,
    CusBirth.bdate                           AS birthdate,
    CusInfo.cst_create_date                 AS create_date
FROM silver.crm_cust_info CusInfo
LEFT JOIN silver.erp_cust_az12 CusBirth
    ON CusInfo.cst_key = CusBirth.cid
LEFT JOIN silver.erp_loc_a101 CusLoc
    ON CusInfo.cst_key = CusLoc.cid;
GO

-- =============================================================================
-- Create Dimension: gold.dim_products
-- =============================================================================
IF OBJECT_ID('gold.dim_products', 'V') IS NOT NULL
    DROP VIEW gold.dim_products;
GO

CREATE VIEW gold.dim_products AS
SELECT
    ROW_NUMBER() OVER (ORDER BY ProdInfo.prd_start_dt, ProdInfo.prd_key) AS product_key, -- Surrogate key
    ProdInfo.prd_id       AS product_id,
    ProdInfo.prd_key      AS product_number,
    ProdInfo.prd_nm       AS product_name,
    ProdInfo.cat_id       AS category_id,
    Cat.cat          AS category,
    Cat.subcat       AS subcategory,
    Cat.maintenance  AS maintenance,
    ProdInfo.prd_cost     AS cost,
    ProdInfo.prd_line     AS product_line,
    ProdInfo.prd_start_dt AS start_date
FROM silver.crm_prd_info ProdInfo
LEFT JOIN silver.erp_px_cat_g1v2 Cat
    ON ProdInfo.cat_id = Cat.id
WHERE ProdInfo.prd_end_dt IS NULL; -- Filter out all historical data
GO

-- =============================================================================
-- Create Fact Table: gold.fact_sales
-- =============================================================================
IF OBJECT_ID('gold.fact_sales', 'V') IS NOT NULL
    DROP VIEW gold.fact_sales;
GO

CREATE VIEW gold.fact_sales AS
SELECT
    s.sls_ord_num  AS order_number,
    p.product_key  AS product_key,
    c.customer_key AS customer_key,
    s.sls_order_dt AS order_date,
    s.sls_ship_dt  AS shipping_date,
    s.sls_due_dt   AS due_date,
    s.sls_sales    AS sales_amount,
    s.sls_quantity AS quantity,
    s.sls_price    AS price
FROM silver.crm_sales_details s
LEFT JOIN gold.dim_products p
    ON s.sls_prd_key = p.product_number
LEFT JOIN gold.dim_customers c
    ON s.sls_cust_id = c.customer_id;
GO
