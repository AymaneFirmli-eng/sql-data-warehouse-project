/*
Process: 	  Cleaning data for the silver layer requirement 
Expectation : standardised clean and enriched data
Objective : Move from bronze to silver following the requirements of silver layer 


To run: call load_silver(); and execute it
*/

-- TABLE 1 : crm_cust_info

-- STEP 0 - ENRICHEMENT: data enrichement has been added to the initial DDL

-- STEP 1 - Checking for rows that have no duplicate cst_id
-- Use of a window function ROW_NUMBER() to check for 
-- rows that are flaged 1 only since the other flags are duplicates .

-- STEP 2 - checking for extra spaces (before and after the columns)
-- using the TRIM() function 

-- STEP 3 - by choice replacing to full naming for gndr and marital status
-- using the CASE WHEN THEN END method

-- STEP 4 - Inserting into silver.crm_cust_info

-- STEP 5 - Re-checking all issues before moving on

-- STEP 6 - for all tables >TRUNCATE >LOAD INTO SILVER

-- Missing try catch debugging logic

create or replace procedure silver.load_silver()
language plpgsql
as $$
begin 
	
	truncate table silver.crm_cust_info;
	
	
	insert into silver.crm_cust_info (
	cst_id,
	cst_key,
	cst_firstname,
	cst_lastname,
	cst_marital_status,
	cst_gndr,
	cst_create_date
	)
	
	select 
	cst_id,
	cst_key,
	TRIM(cst_firstname) as cst_firstname,
	TRIM(cst_lastname) as cst_lastname,
	case 
		when UPPER(TRIM(cst_marital_status)) = 'M' then 'Married'
		when UPPER(TRIM(cst_marital_status)) = 'S' then 'Single'
		else 'n/a'
	end cst_marital_status,
	case when UPPER(TRIM(cst_gndr)) = 'M' then 'Male'
		 when UPPER(TRIM(cst_gndr)) = 'F' then 'Female'
		 else 'n/a'
	end cst_gndr,
	cst_create_date
	
	from 
		(
			select 
			*,
			row_number() over(partition by cst_id order by cst_create_date desc) as flag_last
			from bronze.crm_cust_info
			where cst_id IS NOT NULL
		)t
	where flag_last = 1;
	
	

	raise notice 'silver.crm_cust_info loaded';

	
	
	--## TABLE 2 : crm_prd_info
	
	
	-- 1 Shorter case when then end methof for simple mapping
	-- 2 Substring usage for taking parts of string
	-- 3 Casting a type into another type (here timestamp to date)
	-- 4 Using LEAD window function to access next record (line) datain the previous
	-- 4' line and do some manipulations on it 
	
	
	truncate table silver.crm_prd_info;
	
	insert into silver.crm_prd_info (
	prd_id,
	prd_key,
	cat_id,
	prd_nm,
	prd_cost,
	prd_line,
	prd_start_dt,
	prd_end_dt
	)
	select 
	prd_id,
	replace(substring(prd_key , 1 , 5) , '-' , '_') as cat_id,
	substring(prd_key , 7 ,length(prd_key)) as prd_key,
	TRIM(prd_nm) as prd_nm,
	coalesce(prd_cost , 0) as prd_cost,
	CASE UPPER(TRIM(prd_line))
		WHEN 'M' THEN 'Mountain'  
		when 'R' THEN 'Road' 
		WHEN 'S' THEN 'Other sales' 
		WHEN 'T' THEN 'Touring' 
		ELSE 'n/a'
	END prd_line,
	cast( prd_start_dt as date) as prd_start_dt ,
	cast( lead(prd_start_dt) over(partition by prd_key order by prd_start_dt asc) - interval '1 day' as date ) as prd_end_dt
		
	from bronze.crm_prd_info;

	raise notice 'silver.crm_prd_info loaded';

	
	
	--## TABLE 3 : crm_sales_details
	
	
	-- 1 date management from string to date with condition checks  (could be casted directly)
	-- 2 using with procedure a lot to retrieve modified columns withing the query itself
	-- 3 Price and sales and quantity data cleaning and verifying
	-- 4 handling missing and illogical date 
	
	truncate table silver.crm_sales_details;
	
	insert into silver.crm_sales_details (
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
	
	with tempo_table_casting as (
		select 
		sls_ord_num,
		sls_prd_key,
		sls_cust_id,
		-- TRIPLE (ship ,order, due) TRIPLE (year , month, day) separation 
		-- checking for date lengths as well 8 caracters YYYYMDD with limits
		substring(case when length(cast(sls_order_dt as varchar(10))) = 8 then cast(sls_order_dt as varchar(10)) else '19000101' end, 1, 4) as sls_order_dt_year,
		substring(case when length(cast(sls_order_dt as varchar(10))) = 8 then cast(sls_order_dt as varchar(10)) else '19000101' end, 5, 2) as sls_order_dt_month,
		substring(case when length(cast(sls_order_dt as varchar(10))) = 8 then cast(sls_order_dt as varchar(10)) else '19000101' end, 7, 2) as sls_order_dt_day,
		
		substring(case when length(cast(sls_ship_dt as varchar(10))) = 8 then cast(sls_ship_dt as varchar(10)) else '19000101' end, 1, 4) as sls_ship_dt_year,
		substring(case when length(cast(sls_ship_dt as varchar(10))) = 8 then cast(sls_ship_dt as varchar(10)) else '19000101' end, 5, 2) as sls_ship_dt_month,
		substring(case when length(cast(sls_ship_dt as varchar(10))) = 8 then cast(sls_ship_dt as varchar(10)) else '19000101' end, 7, 2) as sls_ship_dt_day,
		
		substring(case when length(cast(sls_due_dt as varchar(10))) = 8 then cast(sls_due_dt as varchar(10)) else '19000101' end, 1, 4) as sls_due_dt_year,
		substring(case when length(cast(sls_due_dt as varchar(10))) = 8 then cast(sls_due_dt as varchar(10)) else '19000101' end, 5, 2) as sls_due_dt_month,
		substring(case when length(cast(sls_due_dt as varchar(10))) = 8 then cast(sls_due_dt as varchar(10)) else '19000101' end, 7, 2) as sls_due_dt_day,
		 -- TRIPLE TRIPLE separation done 
		
		case when sls_sales is null or sls_sales <= 0 or sls_sales != abs(sls_price) * sls_quantity
			 then abs(sls_price) * sls_quantity
			 else sls_sales
		end as sls_sales,
		
		case when sls_quantity <= 0 or sls_quantity is null
		    then nullif(abs(sls_quantity), 0)
		 	else abs(sls_quantity)
		end as sls_quantity,
		
		case when sls_price = 0 or sls_price is null
			 then abs(sls_sales) / nullif(sls_quantity, 0)
		     else abs(sls_price)
		end as sls_price
		
		from bronze.crm_sales_details
	
	)
		
		select 
		sls_ord_num,
		sls_prd_key,
		sls_cust_id,
		-- TRIPLE TRIPLE CAST 
		CAST(sls_order_dt_year ||'-' || sls_order_dt_month || '-' || sls_order_dt_day as date),
		CAST(sls_ship_dt_year ||'-' || sls_ship_dt_month || '-' || sls_ship_dt_day as date),
		CAST(sls_due_dt_year ||'-' || sls_due_dt_month || '-' || sls_due_dt_day as date),
		-- TRIPLE TRIPLE CAST DONE 
		
		sls_sales,
		sls_quantity,
		sls_price
		
		from tempo_table_casting;
	
		
 
		raise notice 'silver.crm_sales_details loaded';

		
	--## TABLE 4 : erp_cust_az12
		
	-- 1 compare to crm ci turns out there is a prefix of three caracters present in the cids normally only 10
	-- 2 for birthday three checks are added 
	-- 2-1 older than 100 years 
	-- 2-2 born after the current time 
	-- 2-3 younger than 18 years 
	-- 3 Handling male female namings and standardizing the namings 
	
	truncate table silver.erp_cust_az12;
		
	insert into silver.erp_cust_az12 (
	cid,
	bdate,
	gen)
	select 
		case when length(cid) > 10 then substring(cid , 4 , length(cid) - 3) 
			 else cid 
		end as cid,
		case when bdate < cast(current_timestamp - interval '100 years' as date) or bdate > CURRENT_TIMESTAMP or bdate > current_timestamp - interval '18 years' then null
			 else bdate 
		end as bdate,
		case when TRIM(gen) in ('M' , 'Male')   then 'Male'
			 when TRIM(gen) in ('F' , 'Female') then 'Female'
			 else 'n/a'
		end as gen
	from bronze.erp_cust_az12;
	
	
		

	raise notice 'silver.erp_cust_az12 loaded';
	
	
	--## TABLE 5 : erp_loc_a101
		
	-- 1 taking off extra - sign in the cid before integration in silver
	-- 2 normalizing the cntry names 
	
	truncate table silver.erp_loc_a101;
	
	insert into silver.erp_loc_a101 (cid , cntry)
	select 
	substring(cid , 1, 2) || substring(cid , 4 , length(cid)) as cid,
	case 
		 when trim(cntry) = '' or cntry is null then 'n/a'
		 when upper(cntry) = 'US' or upper(cntry) = 'USA' then 'United States'
		 when trim(upper(cntry)) = 'DE' then 'Germany'
		 else trim(cntry)
	end as cntry
	from bronze.erp_loc_a101 ela ;
	
	raise notice 'silver.erp_loc_a101 loaded';

	
	
	--## TABLE 6 : erp_px_cat_g1v2
		
	-- 1 CLEAN TABLE -- nice data quality
	
	truncate table silver.erp_px_cat_g1v2;
	
	insert into silver.erp_px_cat_g1v2
	(id,
	cat,
	subcat,
	maintenance)
	select 
	id,
	cat,
	subcat,
	maintenance 
	from bronze.erp_px_cat_g1v2;
	

	raise notice 'silver.erp_px_cat_g1v2 loaded';

end;$$;



call load_silver();
