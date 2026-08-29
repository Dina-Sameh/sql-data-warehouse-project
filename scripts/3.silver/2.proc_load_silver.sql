/*
===============================================================================
Stored Procedure: Load Silver Layer (Bronze -> Silver)
===============================================================================
Script Purpose:
    This stored procedure loads data into the 'silver' schema from bronze schema. 
    It performs the following actions:
    - Truncates the silver tables before loading data.
    - Inserts transformed and cleansed data from Bronze into Silver tables.

Parameters:
    None. 
	  This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC silver.load_silver;
===============================================================================
*/
CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN
	DECLARE 
		@start_time DATETIME, 
		@end_time DATETIME, 
		@batch_start_time DATETIME, 
		@batch_end_time DATETIME; 

	-- TRY/CATCH is used to handle and report errors during the loading process.
	BEGIN TRY
		-- Capture the start time of the entire Silver loading batch.
		SET @batch_start_time = GETDATE();

		PRINT '================================================';
		PRINT 'Loading Silver Layer';
		PRINT '================================================';

		PRINT '------------------------------------------------';
		PRINT 'Loading CRM Tables';
		PRINT '------------------------------------------------';

		-- Capture the start time for loading the current table.
		SET @start_time = GETDATE();
		PRINT 'Table 1: silver.crm_cust_info';
		PRINT '------------------------------------------------';
		PRINT '>> Deleting all existing data in the silver.crm_cust_info table';
		TRUNCATE TABLE silver.crm_cust_info;
		PRINT '>> Inserting cleaned data into the silver.crm_cust_info table';
		INSERT INTO silver.crm_cust_info(
			cst_id, 
			cst_key, 
			cst_firstname, 
			cst_lastname, 
			cst_marital_status, 
			cst_gndr, 
			cst_create_date
		)
		-- Remove all Duplicates in Primary Key (cst_id) by keeping the latest record based on cst_create_date 
		-- Remove all records with NULL cst_id
		-- Remove Unwanted Spaces in cst_firstname and cst_lastname 
		-- Convert cst_marital_status and cst_gndr to full words (Single, Married, Male, Female)
		SELECT 
			cst_id, 
			cst_key, 
			TRIM(cst_firstname), 
			TRIM(cst_lastname),  
			CASE 
				WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single' 
				WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
				ELSE 'N/A' 
			END AS cst_marital_status, 
			CASE 
				WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male' 
				WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
				ELSE 'N/A' 
			END AS cst_gndr,
			cst_create_date
		FROM (
			SELECT 
				*,
				ROW_NUMBER() OVER (
					PARTITION BY cst_id 
					ORDER BY cst_create_date DESC
				) AS flag_last 
			FROM bronze.crm_cust_info
			WHERE cst_id IS NOT NULL
		) t
		WHERE flag_last = 1;

		-- Calculate and print the load duration for the current table.
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '>> -------------';


        SET @start_time = GETDATE();
		PRINT '------------------------------------------------';
		PRINT 'Table 2: silver.crm_prd_info';
		PRINT '------------------------------------------------';
		PRINT '>> Deleting all existing data in the silver.crm_prd_info table'
		TRUNCATE TABLE silver.crm_prd_info;
		PRINT '>> Inserting cleaned data into the silver.crm_prd_info table';
		INSERT INTO silver.crm_prd_info(
			prd_id, 
			cat_id,
			prd_key, 
			prd_nm, 
			prd_cost, 
			prd_line, 
			prd_start_dt, 
			prd_end_dt
		)
		SELECT 
			prd_id, 
			REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id, -- Extract category ID from prd_key and replace '-' with '_'
			SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key, -- Extract product key from prd_key
			prd_nm,
			ISNULL(prd_cost, 0) AS prd_cost, -- Replace NULL prd_cost with 0
			CASE
				WHEN UPPER(TRIM(prd_line)) = 'M' THEN 'Mountain' 
				WHEN UPPER(TRIM(prd_line)) = 'R' THEN 'Road'
				WHEN UPPER(TRIM(prd_line)) = 'S' THEN 'Other Sales'
				WHEN UPPER(TRIM(prd_line)) = 'T' THEN 'Touring'
				ELSE 'N/A'
			END AS prd_line, -- Map product line codes to descriptive names
			prd_start_dt,
			DATEADD(
				DAY, 
				-1, 
				LEAD(prd_start_dt) OVER (
					PARTITION BY prd_key 
					ORDER BY prd_start_dt
				)
			) AS prd_end_dt -- Calculate prd_end_dt as one day before the next prd_start_dt for the same prd_id, This is Data Enrichment
		FROM bronze.crm_prd_info

		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '>> -------------';

        SET @start_time = GETDATE();
		PRINT '------------------------------------------------';
		PRINT 'Table 3: silver.crm_sales_details';
		PRINT '------------------------------------------------';
		PRINT '>> Deleting all existing data in the silver.crm_sales_details table'
		TRUNCATE TABLE silver.crm_sales_details;
		PRINT '>> Inserting cleaned data into the silver.crm_sales_details table';
		INSERT INTO silver.crm_sales_details(
			sls_ord_num,
			sls_prd_key,
			sls_cust_id,
			sls_order_dt,
			sls_ship_dt,
			sls_due_dt,
			sls_sales,
			sls_quantity,
			sls_price
		)
		SELECT 
			sls_ord_num,
			sls_prd_key,
			sls_cust_id,
			CASE 
				WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL 
				ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE) 
			END AS sls_order_dt,
    
			CASE 
				WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) != 8 THEN NULL 
				ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE) 
			END AS sls_ship_dt,
			CASE 
				WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8 THEN NULL 
				ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE) 
			END AS sls_due_dt,
			CASE WHEN sls_sales IS NULL OR sls_sales <=0 OR sls_sales != sls_quantity * ABS(sls_price)
					THEN sls_quantity * ABS(sls_price)
					ELSE sls_sales
			END AS sls_sales, -- Recalculate sls_sales if original value is missing or incorrect
			sls_quantity,
			CASE WHEN sls_price IS NULL OR sls_price <=0 
					THEN sls_sales / NULLIF(sls_quantity, 0)
					ELSE sls_price
			END AS sls_price -- Derive sls_price if original value is invalid
		FROM bronze.crm_sales_details
		WHERE sls_ord_num IS NOT NULL;
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '>> -------------';


		PRINT '------------------------------------------------';
		PRINT 'Loading ERP Tables';
		PRINT '------------------------------------------------';

		SET @start_time = GETDATE();
		PRINT 'Table 1: silver.erp_cust_az12';
		PRINT '------------------------------------------------';
		PRINT '>> Deleting all existing data in the silver.erp_cust_az12 table'
		TRUNCATE TABLE silver.erp_cust_az12;
		PRINT '>> Inserting cleaned data into the silver.erp_cust_az12 table';
		INSERT INTO silver.erp_cust_az12( cid, bdate, gen )
		SELECT 
			CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid)) -- Remove 'NAS' prefix from cid if it exists
				ELSE cid 
			END AS cid,
			CASE WHEN bdate < '1924-01-01' OR bdate > GETDATE() THEN NULL 
				 ELSE bdate 
			END AS bdate, -- Set bdate to NULL if it is outside the valid range (before 1924 or after today)
			CASE WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female' 
				 WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
				 ELSE 'N/A'
			END AS gen -- Normalize gen values to 'Male', 'Female', and handle unknown cases as 'N/A'
		FROM bronze.erp_cust_az12;
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '>> -------------';
		

		SET @start_time = GETDATE();
		PRINT '------------------------------------------------';
		PRINT 'Table 2: silver.erp_loc_a101';
		PRINT '------------------------------------------------';
		PRINT '>> Deleting all existing data in the silver.erp_loc_a101 table'
		TRUNCATE TABLE silver.erp_loc_a101;
		PRINT '>> Inserting cleaned data into the silver.erp_loc_a101 table';
		INSERT INTO silver.erp_loc_a101 (cid, cntry)
		SELECT 
			REPLACE(cid, '-','') cid,
			CASE 
				WHEN UPPER(TRIM(cntry)) IN ('AU', 'AUS', 'AUSTRALIA') THEN 'Australia'
				WHEN UPPER(TRIM(cntry)) IN ('CA', 'CAN', 'CANADA') THEN 'Canada'
				WHEN UPPER(TRIM(cntry)) IN ('DE', 'DEU', 'GERMANY') THEN 'Germany'
				WHEN UPPER(TRIM(cntry)) IN ('FR', 'FRA', 'FRANCE') THEN 'France'
				WHEN UPPER(TRIM(cntry)) IN ('GB', 'UK', 'UNITED KINGDOM') THEN 'United Kingdom'
				WHEN UPPER(TRIM(cntry)) IN ('US', 'USA', 'UNITED STATES') THEN 'United States'
				WHEN TRIM(cntry) IS NULL OR TRIM(cntry) = '' THEN 'N/A'
				ELSE TRIM(cntry)
			END AS cntry -- Normalize cntry values, and handle missing or blank cases as 'N/A'
		FROM bronze.erp_loc_a101
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '>> -------------';


		SET @start_time = GETDATE();
		PRINT '------------------------------------------------';
		PRINT 'Table 3: silver.erp_px_cat_g1v2';
		PRINT '------------------------------------------------';
		PRINT '>> Deleting all existing data in the silver.erp_px_cat_g1v2 table'
		TRUNCATE TABLE silver.erp_px_cat_g1v2;
		PRINT '>> Inserting cleaned data into the silver.erp_px_cat_g1v2 table';
		INSERT INTO silver.erp_px_cat_g1v2 (id, cat, subcat, maintenance)
		SELECT 
			id, 
			cat, 
			subcat,
			maintenance
		FROM bronze.erp_px_cat_g1v2
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '>> -------------';

		-- Capture the end time of the entire Silver loading batch.
		SET @batch_end_time = GETDATE();
		PRINT '==========================================';
		PRINT 'Loading Silver Layer is Completed';
        PRINT '   - Total Load Duration: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds';
		PRINT '==========================================';
	END TRY
	BEGIN CATCH
		PRINT '==========================================';
		PRINT 'ERROR OCCURED DURING LOADING SILVER LAYER';
		PRINT 'Error Message: ' + ERROR_MESSAGE();
		PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS NVARCHAR);
		PRINT 'Error State: ' + CAST(ERROR_STATE() AS NVARCHAR);
		PRINT '==========================================';
		-- Re-throw the error to the caller after logging the error details
		THROW;
	END CATCH
END
