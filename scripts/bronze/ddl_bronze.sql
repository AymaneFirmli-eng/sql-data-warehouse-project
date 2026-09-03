/* WE ARE USING SNAKE NAMING CONVENTION => everything is in lower case */


/* CRM DATA */
create table bronze.crm_cust_info
(cst_id int,
cst_key  int,
cst_firstname VARCHAR(50),
cst_lastname VARCHAR(50),
cst_marital_status VARCHAR(50),
cst_gndr VARCHAR(50),
cst_create_date date
);

create table bronze.crm_prd_info
(prd_id int,
prd_key  VARCHAR(50),
prd_nm VARCHAR(50),
prd_cost int,
prd_line VARCHAR(50),
prd_start_dt date,
prd_end_dt date
);
create table bronze.crm_sales_details
(sls_ord_num VARCHAR(50),
sls_prd_key VARchar(50),
sls_cust_id int,
sls_order_dt int,
sls_ship_dt int,
sls_due_dt int,
sls_sales int,
sls_quantity int,
sls_price int
);

/* ERP DATA */
create table bronze.erp_loc_a101
(CID VARCHAR(50),
CNTRY VARCHAR(50));


create table bronze.erp_px_cat_g1v2
(ID VARCHAR(50),
BDACATTE date,
SUBCAT varchar(50),
MAINTENANCE varchar(50));


create table bronze.erp_cust_az12
(CID VARCHAR(50),
BDATE date,
GEN varchar(50));














