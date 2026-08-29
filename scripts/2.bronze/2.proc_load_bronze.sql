/*
===============================================================================
Stored Procedure: Load Bronze Layer (Source -> Bronze)
===============================================================================
Script Purpose:
    This stored procedure loads data into the 'bronze' schema from external CSV files. 
    It performs the following actions:
    - Truncates the bronze tables before loading data.
    - Uses the `BULK INSERT` command to load data from CSV Files to bronze tables.

Parameters:
    None. 
	  This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC bronze.load_bronze;
===============================================================================
*/
CREATE OR ALTER PROCEDURE bronze.load_bronze AS
BEGIN
	DECLARE 
		@start_time DATETIME, 
		@end_time DATETIME, 
		@batch_start_time DATETIME, 
		@batch_end_time DATETIME; 

	-- TRY/CATCH is used to handle and report errors during the loading process.
	BEGIN TRY

		-- Capture the start time of the entire Bronze loading batch.
		SET @batch_start_time = GETDATE();

		PRINT '================================================';
		PRINT 'Loading Bronze Layer';
		PRINT '================================================';

		PRINT '------------------------------------------------';
		PRINT 'Loading CRM Tables';
		PRINT '------------------------------------------------';

		-- Capture the start time for loading the current table.
		SET @start_time = GETDATE();
		PRINT 'Table 1: bronze.crm_cust_info';
		PRINT '------------------------------------------------';
		-- Clear existing data before loading the latest source data.
		PRINT '>> Deleting all existing data in the bronze.crm_cust_info table';
		TRUNCATE TABLE bronze.crm_cust_info;

		-- Load data directly from the source CSV file into the Bronze table.
		PRINT '>> Inserting data into the bronze.crm_cust_info table';
		BULK INSERT bronze.crm_cust_info
		FROM 'C:\Users\DELL\sql-data-warehouse-project\datasets\source_crm\cust_info.csv'
		WITH (
			FIRSTROW = 2, -- Skip the CSV header row.
			FIELDTERMINATOR = ',', -- Define the delimiter used to separate columns in the CSV file.
			TABLOCK -- Use a table-level lock to improve bulk loading performance.
		);

		-- Calculate and print the load duration for the current table.
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '>> -------------';

        SET @start_time = GETDATE();
		PRINT '------------------------------------------------';
		PRINT 'Table 2: bronze.crm_prd_info';
		PRINT '------------------------------------------------';
		PRINT '>> Deleting all existing data in bronze.crm_prd_info table';
		TRUNCATE TABLE bronze.crm_prd_info;

		PRINT '>> Inserting data into the bronze.crm_prd_info table';
		BULK INSERT bronze.crm_prd_info
		FROM 'C:\Users\DELL\sql-data-warehouse-project\datasets\source_crm\prd_info.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '>> -------------';

        SET @start_time = GETDATE();
		PRINT '------------------------------------------------';
		PRINT 'Table 3: bronze.crm_sales_details';
		PRINT '------------------------------------------------';
		PRINT '>> Deleting all existing data in the bronze.crm_sales_details table';
		TRUNCATE TABLE bronze.crm_sales_details;
		PRINT '>> Inserting data into the bronze.crm_sales_details table';
		BULK INSERT bronze.crm_sales_details
		FROM 'C:\Users\DELL\sql-data-warehouse-project\datasets\source_crm\sales_details.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '>> -------------';

		PRINT '------------------------------------------------';
		PRINT 'Loading ERP Tables';
		PRINT '------------------------------------------------';
		
		SET @start_time = GETDATE();
		PRINT 'Table 1: bronze.erp_cust_az12';
		PRINT '------------------------------------------------';
		PRINT '>> Deleting all existing data in the bronze.erp_cust_az12 table';
		TRUNCATE TABLE bronze.erp_cust_az12;
		PRINT '>> Inserting data into the bronze.erp_cust_az12 table';
		BULK INSERT bronze.erp_cust_az12
		FROM 'C:\Users\DELL\sql-data-warehouse-project\datasets\source_erp\cust_az12.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '>> -------------';

		SET @start_time = GETDATE();
		PRINT '------------------------------------------------';
		PRINT 'Table 2: bronze.erp_loc_a101';
		PRINT '------------------------------------------------';
		PRINT '>> Deleting all existing data in the bronze.erp_loc_a101 table';
		TRUNCATE TABLE bronze.erp_loc_a101;
		PRINT '>> Inserting data into the bronze.erp_loc_a101 table';
		BULK INSERT bronze.erp_loc_a101
		FROM 'C:\Users\DELL\sql-data-warehouse-project\datasets\source_erp\loc_a101.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '>> -------------';
		SET @start_time = GETDATE();
		PRINT '------------------------------------------------';
		PRINT 'Table 3: bronze.erp_px_cat_g1v2';
		PRINT '------------------------------------------------';
		PRINT '>> Deleting all existing data in the bronze.erp_px_cat_g1v2 table';
		TRUNCATE TABLE bronze.erp_px_cat_g1v2;
		PRINT '>> Inserting data into the bronze.erp_px_cat_g1v2 table';
		BULK INSERT bronze.erp_px_cat_g1v2
		FROM 'C:\Users\DELL\sql-data-warehouse-project\datasets\source_erp\px_cat_g1v2.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '>> -------------';

		-- Capture the end time of the entire Bronze loading batch.
		SET @batch_end_time = GETDATE();
		PRINT '==========================================';
		PRINT 'Loading Bronze Layer is Completed';
        PRINT '   - Total Load Duration: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds';
		PRINT '==========================================';
	END TRY
	BEGIN CATCH
		PRINT '==========================================';
		PRINT 'ERROR OCCURED DURING LOADING BRONZE LAYER';
		PRINT 'Error Message: ' + ERROR_MESSAGE();
		PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS NVARCHAR);
		PRINT 'Error State: ' + CAST(ERROR_STATE() AS NVARCHAR);
		PRINT '==========================================';
		-- Re-throw the error to the caller after logging the error details
		THROW;
	END CATCH
END
