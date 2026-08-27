/*
================================================================================
Data Warehouse Database Setup Script
================================================================================
Purpose:
This script creates and initializes the 'DataWarehouse' database and sets up
the Bronze, Silver, and Gold schemas.

WARNING:
Running this script will permanently DELETE the entire 'DataWarehouse'
database, including ALL data, tables, views, stored procedures, and other
database objects contained within it.

Make sure you have a backup of the database before executing this script.
DO NOT run this script in a production environment unless you fully understand
the consequences.

================================================================================
*/


USE master;
GO

-- Drop the DataWarehouse database if it exists
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'DataWarehouse')
BEGIN
    ALTER DATABASE DataWarehouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE DataWarehouse;
END;
GO

-- Create the DataWarehouse database
CREATE DATABASE DataWarehouse;
GO

USE DataWarehouse;
GO
CREATE SCHEMA bronze;
GO 
CREATE SCHEMA silver;
GO
CREATE SCHEMA gold;
GO
