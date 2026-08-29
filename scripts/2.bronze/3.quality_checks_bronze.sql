/*
===============================================================================
Quality Checks
===============================================================================
===============================================================================
Script Purpose:
    This script performs various quality checks for data consistency, accuracy, 
    and standardization across the 'Bronze' layer. It includes checks for:
    - Null or duplicate primary keys.
    - Unwanted spaces in string fields.
    - Data standardization and consistency.
    - Invalid date ranges and orders.
    - Data consistency between related fields.

Usage Notes:
    - Run these checks after data loading Bronze Layer.
    - Investigate and resolve any discrepancies found during the checks.
===============================================================================
    Issue:
        After loading the Bronze layer, we validated the row count of all Bronze
        tables using:

        SELECT COUNT(*) FROM table_name;

        The row counts were compared with the expected number of records in
        each source CSV file. All tables were loaded successfully except
        bronze.erp_cust_az12, which contained 18,483 records instead of the
        expected 18,484.

    Investigation:
        We checked the final record from the source file:

        SELECT *
        FROM bronze.erp_cust_az12
        WHERE cid = 'AW00029483';

        The record was not found in the Bronze table, confirming that the
        final row of the CSV file had not been loaded.

    Root Cause:
        The source CSV file was missing a newline character at the end of the file.
        As a result, BULK INSERT did not properly recognize the final data row.

    Solution:
        Added a newline character at the end of the CSV file to ensure the final
        record is properly recognized and loaded by BULK INSERT.

    Validation:
        Source records (excluding header): 18,484
        Bronze records after loading:      18,484

        After the fix, the Bronze table row count matched the source file,
        confirming that all records were loaded successfully.
 */

-- Execute the stored procedure to load data from the source CSV files into the Bronze layer.
EXEC bronze.load_bronze;


-- Validate the row count of the 'bronze.erp_cust_az12' table after loading. 
-- It should match the expected number of records in the source CSV file.
SELECT COUNT(*) FROM bronze.erp_cust_az12

-- This is the only issue we solved in the Bronze layer, and it was related to the missing newline character in the source CSV file.
SELECT * FROM bronze.erp_cust_az12 WHERE cid = 'AW00029483';

/*
===============================================================================
Quality Checks
===============================================================================
Script Purpose:
    This script performs various quality checks for data consistency, accuracy, 
    and standardization across the 'silver' layer. It includes checks for:
    - Null or duplicate primary keys.
    - Unwanted spaces in string fields.
    - Data standardization and consistency.
    - Invalid date ranges and orders.
    - Data consistency between related fields.

Usage Notes:
    - Run these checks after data loading Silver Layer.
    - Investigate and resolve any discrepancies found during the checks.
===============================================================================
*/

-- ====================================================================
-- Table 1 Checking 'bronze.crm_cust_info'
SELECT TOP 100 * FROM bronze.crm_cust_info;
-- ====================================================================
-- Check for NULLs or Duplicates in Primary Key
-- Expectation: No Results
SELECT 
    cst_id,
    COUNT(*) 
FROM bronze.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL;

-- Results: We have about 6 duplicates and 3 NULL value in the primary key 'cst_id'. 
-- This indicates a data quality issue that needs to be addressed.
-- We need to investigate the source of these duplicates and NULL values, and take appropriate action to resolve them.
-- After investigating the source of these duplicates and NULL values, we found the changing in these records was cst_create_date value.
-- So we decided to keep the latest record based on cst_create_date value and remove the duplicates and NULL values from the 'cst_id'  
-- column to ensure data integrity and accuracy.
-- ====================================================================
-- Check for Unwanted Spaces
-- Expectation: No Results
SELECT 
    cst_firstname 
FROM bronze.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname);

SELECT 
    cst_lastname 
FROM bronze.crm_cust_info
WHERE cst_lastname != TRIM(cst_lastname);

SELECT 
    cst_key
FROM bronze.crm_cust_info
WHERE cst_key != TRIM(cst_key);

SELECT 
    cst_marital_status
FROM bronze.crm_cust_info
WHERE cst_marital_status != TRIM(cst_marital_status);

SELECT 
    cst_gndr 
FROM bronze.crm_cust_info
WHERE cst_gndr != TRIM(cst_gndr);

-- Results: We have found unwanted spaces in the 'cst_firstname', 'cst_lastname' columns. 
-- This indicates a data quality issue that needs to be addressed.
-- We need to clean the data by removing unwanted spaces from these columns to ensure consistency and accuracy in the data.

-- ====================================================================
-- Data Standardization & Consistency
SELECT DISTINCT 
    cst_marital_status 
FROM bronze.crm_cust_info;


SELECT DISTINCT 
    cst_gndr
FROM bronze.crm_cust_info;

-- - Results: We have found inconsistent values in the 'cst_marital_status' and 'cst_gndr' columns. 
-- For example, M letters are used for 'Married' and 'Single' is represented as 'S' and 'Female' as 'F' and 'Male' as 'M'. 
-- M is used for both 'Married' and 'Male', which can lead to confusion and misinterpretation of the data.
-- This indicates a data quality issue that needs to be addressed.
-- We need to standardize the values in these columns to ensure consistency and accuracy in the data.

-- ====================================================================
-- Table 2 Checking 'bronze.crm_prd_info'
SELECT TOP 100 * FROM bronze.crm_prd_info;
-- ====================================================================

-- The prd_key column contains category codes that are referenced to id column in bronze.erp_px_cat_g1v2.
-- so We need to seprate the category codes from prd_key column to match with id column in bronze.erp_px_cat_g1v2.

-- Check for NULLs or Duplicates in Primary Key
-- Expectation: No Results
SELECT 
    prd_id,
    COUNT(*) 
FROM bronze.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL;


-- Results: We have found duplicates and NULL values in the 'prd_key' column.

-- Check for Unwanted Spaces
-- Expectation: No Results
SELECT 
    prd_key 
FROM bronze.crm_prd_info
WHERE prd_key != TRIM(prd_key);

SELECT 
    prd_nm 
FROM bronze.crm_prd_info
WHERE prd_nm != TRIM(prd_nm);

-- Check for NULLs or Negative Values in Cost
-- Expectation: No Results
SELECT 
    prd_cost 
FROM bronze.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL;

-- Results: We have found NULL values in the 'prd_cost' column.


-- Data Standardization & Consistency
SELECT DISTINCT 
    prd_line 
FROM bronze.crm_prd_info;

-- Results: We have found inconsistent values in the 'prd_line' column, they write as 'M', 'R', 'S', 'T' instead of full names
-- We need to standardize the values in this column to ensure consistency and accuracy in the data, We will ask the expert of the source system for the full names for the codes. 'Mountain' for M, 'Road' for R, 'Other Sales' for S, 'Touring' for T

-- Check for Invalid Date Orders (Start Date > End Date)
-- Expectation: No Results
SELECT 
    * 
FROM bronze.crm_prd_info
WHERE prd_end_dt < prd_start_dt;

-- Results: We have found invalid date orders their 'prd_start_dt' is greater than 'prd_end_dt'. This indicates a data quality issue that needs to be addressed.
-- We need to investigate the source of these invalid date orders and take appropriate action to resolve them.
-- After investigating the source of these invalid date orders, we found that the 'prd_end_dt' values were incorrect.
-- So we decided to update the 'prd_end_dt' values to ensure that they are greater than or equal to the 'prd_start_dt' values.
-- We will calculate prd_end_dt as one day before the next prd_start_dt for the same prd_id but we need the expert of source system confirmation for this approach before proceeding with the update.

-- ====================================================================
-- ====================================================================
-- Table 3 Checking 'bronze.crm_sales_details'
SELECT TOP 100 * FROM bronze.crm_sales_details;
-- ====================================================================


-- Check for NULLs or Duplicates in Primary Key
-- Expectation: No Results
SELECT 
    sls_ord_num, sls_prd_key,
    COUNT(*) 
FROM bronze.crm_sales_details
GROUP BY sls_ord_num, sls_prd_key
HAVING COUNT(*) > 1 OR sls_ord_num IS NULL;


-- Check for Unwanted Spaces
-- Expectation: No Results
SELECT 
    sls_ord_num 
FROM bronze.crm_sales_details
WHERE sls_ord_num != TRIM(sls_ord_num);


-- Check the integrity of Foreign Keys: sls_prd_key and sls_cust_id
SELECT 
    sls_prd_key
FROM bronze.crm_sales_details
WHERE sls_prd_key NOT IN (SELECT prd_key FROM silver.crm_prd_info); -- In here we used silver.crm_prd_info because we have separated the prd_key from cat_key in the silver layer.

SELECT 
    sls_cust_id
FROM bronze.crm_sales_details
WHERE sls_cust_id NOT IN (SELECT cst_id FROM bronze.crm_cust_info);

-- Check for Invalid Dates
-- Expectation: No Invalid Dates
SELECT NULLIF(sls_order_dt, 0) AS sls_order_dt 
FROM bronze.crm_sales_details
WHERE sls_order_dt <= 0 
    OR LEN(sls_order_dt) != 8 
    OR sls_order_dt > 20260101 
    OR sls_order_dt < 19000101;

SELECT 
    NULLIF(sls_ship_dt, 0) AS sls_ship_dt 
FROM bronze.crm_sales_details
WHERE sls_ship_dt <= 0 
    OR LEN(sls_ship_dt) != 8 
    OR sls_ship_dt > 20260101 
    OR sls_ship_dt < 19000101;

SELECT 
    NULLIF(sls_due_dt, 0) AS sls_due_dt 
FROM bronze.crm_sales_details
WHERE sls_due_dt <= 0 
    OR LEN(sls_due_dt) != 8 
    OR sls_due_dt > 20260101 
    OR sls_due_dt < 19000101;


-- The Date columns in the 'bronze.crm_sales_details' table are stored as integers in the format YYYYMMDD.
-- We need to convert these integer values to date format for better readability and analysis. 
-- But in SQL SEREVER we have to convert them to string first and then to date format. 
-- Also we found 0 values and values that its length is not 8 in the sls_order_dt column, we need to replace these values with NULL to avoid conversion errors.
-- Check for Invalid Date Orders (Order Date > Shipping/Due Dates)
-- Expectation: No Results
SELECT 
    * 
FROM bronze.crm_sales_details
WHERE sls_order_dt > sls_ship_dt 
   OR sls_order_dt > sls_due_dt;

-- Check Data Consistency: 
-- Business Rules:
--       Sales = Quantity * Price 
--       Sales, Quantity, and Price cannot be negative, zero or null.
-- Expectation: No Results
SELECT DISTINCT 
    sls_sales,
    sls_quantity,
    sls_price 
FROM bronze.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
   OR sls_sales IS NULL 
   OR sls_quantity IS NULL 
   OR sls_price IS NULL
   OR sls_sales <= 0 
   OR sls_quantity <= 0 
   OR sls_price <= 0
ORDER BY sls_sales, sls_quantity, sls_price;

-- We have found some records that violate the business rules for sales, quantity, and price.
-- There are null values, negative values, and zero values in these columns, 
-- and some records where the sales value does not equal the product of quantity and price.
-- This indicates a data quality issue that needs to be addressed.
-- We need to tell the source system expert or the business team about these records and duscuss how to handle them.
-- genarlly, the answer will one from the following options:
-- 1. Data issues will be fixed in the source system and the data will be reloaded into the Bronze layer.
-- 2. Data issues have to be fixed in data warehouse, which means we will handle it in the Silver layer. 
--      even though we need to ask the source system expert or the business team to support us to fix it 
--      beacause they know the business rules better than us.
--  Rules:
--	  - If the sales value is negative, zero or null, we can recalculate it as quantity * price.
--	  - If the price value is zero or null, we can recalculate it as sales / quantity.
--    - If the price value is negative, convert it to positive value.

-- ====================================================================
-- Table 4 Checking 'bronze.erp_cust_az12'
-- ====================================================================
SELECT TOP 100 * FROM bronze.erp_cust_az12
WHERE cid LIKE '%AW00011001';
SELECT TOP 100 * FROM silver.crm_cust_info;
-- Check the integrity of Foreign Key: cid
SELECT 
    cid, CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid)) 
        ELSE cid 
    END cid_2, bdate, gen
FROM bronze.erp_cust_az12
WHERE 
    cid NOT IN (SELECT cst_key FROM silver.crm_cust_info)

-- cid column in the 'bronze.erp_cust_az12' table is a foreign key that references the cst_key column in the 'silver.crm_cust_info' table. 
-- But there are three characters difference between these two columns, so we need to remove the first three characters (NAS) from the 'cid' column 
-- in the 'silver.erp_cust_az12' table to match with the 'cst_key' column in the 'silver.crm_cust_info' table.

-- Check the integrity of Foreign Key: cid after removing the first three characters (NAS) from it.
SELECT 
    CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid)) 
        ELSE cid 
    END cid, bdate, gen
FROM bronze.erp_cust_az12
WHERE 
    CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid)) 
        ELSE cid 
    END NOT IN (SELECT cst_key FROM silver.crm_cust_info)

-- Results Zero unmatched records, which proves that the 'cid' column in the 'bronze.erp_cust_az12' table is consistent with the 'cst_key' column 
-- in the 'silver.crm_cust_info' table after removing the first three characters (NAS) from the 'cid' column in the 'bronze.erp_cust_az12' table.

-- Check for NULLs in Foreign Key
SELECT cid
FROM bronze.erp_cust_az12
WHERE cid IS NULL;

-- Identify Out-of-Range Dates
-- Expectation: No Results
SELECT DISTINCT 
    bdate 
FROM bronze.erp_cust_az12
WHERE bdate < '1924-01-01' 
   OR bdate > GETDATE();
-- Results: We have found out-of-range dates that is not between 1924-01-01 and Today in the 'bdate' column, 
-- it's rarely to have a customer his/her age more than 100 years and impossible to have a customer didn't born yet, 
-- which indicates a data quality issue that needs to be addressed.
-- Data Standardization & Consistency
SELECT DISTINCT gen 
FROM bronze.erp_cust_az12;

-- Results: We have found inconsistent values in the 'gen' column, they write as 'M', 'F', 'Male', 'Female, Null, and empty string.
-- ====================================================================
-- Table 5 Checking 'bronze.erp_loc_a101'
-- ====================================================================
-- Check the integrity of Foreign Key: cid
SELECT cid
FROM bronze.erp_loc_a101
WHERE cid NOT IN (SELECT cst_key FROM bronze.crm_cust_info)

-- cid column in the 'bronze.erp_loc_a101' table is a foreign key that references the cst_key column in the 'silver.crm_cust_info' table. 
-- But there a difference between these two columns, so we need to remove '-' character from the 'cid' column 
-- in the 'silver.erp_loc_a101' table to match with the 'cst_key' column in the 'silver.crm_cust_info' table.

-- Check the integrity of Foreign Key: cid after removing - from it
SELECT REPLACE(cid, '-','') cid
FROM bronze.erp_loc_a101
WHERE REPLACE(cid, '-','') NOT IN (SELECT cst_key FROM bronze.crm_cust_info)

-- Data Standardization & Consistency
SELECT DISTINCT 
    cntry 
FROM bronze.erp_loc_a101
ORDER BY cntry;
-- Results: We have found inconsistent values in the 'cntry' column, sometimes they write the country name and sometimes its abbreviation 
-- ====================================================================
-- Checking 'bronze.erp_px_cat_g1v2'
-- ====================================================================
-- Check the integrity of Foreign Key: cid
SELECT id
FROM bronze.erp_px_cat_g1v2
WHERE id NOT IN (SELECT cat_id FROM silver.crm_prd_info)

SELECT *
FROM bronze.erp_px_cat_g1v2
WHERE id = 'CO_PD'

SELECT cat_id 
FROM silver.crm_prd_info
WHERE cat_id LIKE '%PD%'
-- The category CO_PD doesn't have any product

-- Check for Unwanted Spaces
-- Expectation: No Results
SELECT 
    * 
FROM bronze.erp_px_cat_g1v2
WHERE cat != TRIM(cat) 
   OR subcat != TRIM(subcat) 
   OR maintenance != TRIM(maintenance);

-- Data Standardization & Consistency
SELECT DISTINCT 
    cat 
FROM bronze.erp_px_cat_g1v2;

SELECT DISTINCT 
    subcat 
FROM bronze.erp_px_cat_g1v2
ORDER BY subcat;

SELECT DISTINCT 
    maintenance 
FROM bronze.erp_px_cat_g1v2;

-- bronze.erp_px_cat_g1v2 table is clean already, we don't need to make any changing