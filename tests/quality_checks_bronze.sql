 /*
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

SELECT * FROM bronze.erp_cust_az12 WHERE cid = 'AW00029483';

SELECT COUNT(*) FROM bronze.erp_cust_az12