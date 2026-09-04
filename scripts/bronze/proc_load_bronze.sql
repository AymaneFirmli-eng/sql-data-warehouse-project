/*
===============================================================================
Script Purpose:
    This script performs a Full Load ("Truncate and Load") process to populate 
    the 'bronze' schema tables from external CSV source files.
    - It truncates existing tables inside an exception-handling block.
    - It bulk-loads raw CSV data from the local machine into PostgreSQL tables.
===============================================================================
*/

DO $$ BEGIN
    RAISE NOTICE '=======================================================';
    RAISE NOTICE 'LOADING BRONZE LAYER...';
    RAISE NOTICE '=======================================================';
END $$;


/* --- TRUNCATE WITH ERROR HANDLING (TRY / CATCH EQUIVALENT) --- */
DO $$ 
BEGIN
    RAISE NOTICE '-------------------------------------------------------';
    RAISE NOTICE 'TRUNCATING CRM & ERP TABLES';
    RAISE NOTICE '-------------------------------------------------------';

    -- Vidage des tables CRM
    TRUNCATE TABLE bronze.crm_cust_info;
    RAISE NOTICE 'crm_cust_info...... TRUNCATED (1/6)';
    
    TRUNCATE TABLE bronze.crm_prd_info;
    RAISE NOTICE 'crm_prd_info...... TRUNCATED (2/6)';
    
    TRUNCATE TABLE bronze.crm_sales_details;
    RAISE NOTICE 'crm_sales_details...... TRUNCATED (3/6)';

    -- Vidage des tables ERP
    TRUNCATE TABLE bronze.erp_cust_az12;
    RAISE NOTICE 'erp_cust_az12...... TRUNCATED (4/6)';
    
    TRUNCATE TABLE bronze.erp_loc_a101;
    RAISE NOTICE 'erp_loc_a101...... TRUNCATED (5/6)';
    
    TRUNCATE TABLE bronze.erp_px_cat_g1v2;
    RAISE NOTICE 'erp_px_cat_g1v2...... TRUNCATED (6/6)';

    RAISE NOTICE '-------------------------------------------------------';
    RAISE NOTICE 'TRUNCATING DONE SUCCESSFULLY';
    RAISE NOTICE '-------------------------------------------------------';

EXCEPTION 
    WHEN others THEN
        RAISE EXCEPTION 'ERREUR CRITIQUE LORS DU TRUNCATE : %', SQLERRM;
END $$;



/* =======================================================
   BULK COPYING INTO THE TABLES
   (Executed outside procedural blocks to comply with PostgreSQL constraints)
   ======================================================= */

DO $$ BEGIN
    RAISE NOTICE '=======================================================';
    RAISE NOTICE ' BULK COPYING INTO THE TABLES';
    RAISE NOTICE '=======================================================';
END $$;


/* CRM */
COPY bronze.crm_cust_info
FROM '/Users/macairm1/Desktop/DATA_ENG_PROJECTS/ongoing/sql-data-warehouse-project/datasets/source_crm/cust_info.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',');

DO $$ BEGIN RAISE NOTICE 'crm_cust_info copy 1/3.... DONE'; END $$;

COPY bronze.crm_prd_info
FROM '/Users/macairm1/Desktop/DATA_ENG_PROJECTS/ongoing/sql-data-warehouse-project/datasets/source_crm/prd_info.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',');

DO $$ BEGIN RAISE NOTICE 'crm_prd_info copy 2/3.... DONE'; END $$;

COPY bronze.crm_sales_details
FROM '/Users/macairm1/Desktop/DATA_ENG_PROJECTS/ongoing/sql-data-warehouse-project/datasets/source_crm/sales_details.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',');

DO $$ BEGIN RAISE NOTICE 'crm_sales_details copy 3/3.... DONE'; END $$;


/* ERP */
COPY bronze.erp_cust_az12
FROM '/Users/macairm1/Desktop/DATA_ENG_PROJECTS/ongoing/sql-data-warehouse-project/datasets/source_erp/CUST_AZ12.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',');

DO $$ BEGIN RAISE NOTICE 'erp_cust_az12 copy 1/3.... DONE'; END $$;

COPY bronze.erp_loc_a101
FROM '/Users/macairm1/Desktop/DATA_ENG_PROJECTS/ongoing/sql-data-warehouse-project/datasets/source_erp/LOC_A101.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',');

DO $$ BEGIN RAISE NOTICE 'erp_loc_a101 copy 2/3.... DONE'; END $$;

COPY bronze.erp_px_cat_g1v2
FROM '/Users/macairm1/Desktop/DATA_ENG_PROJECTS/ongoing/sql-data-warehouse-project/datasets/source_erp/PX_CAT_G1V2.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',');

DO $$ BEGIN
    RAISE NOTICE 'erp_px_cat_g1v2 copy 3/3.... DONE';
    RAISE NOTICE '#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#';
    RAISE NOTICE ' BULK COPYING INTO THE TABLES COMPLETED';
    RAISE NOTICE '#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#';
END $$;
