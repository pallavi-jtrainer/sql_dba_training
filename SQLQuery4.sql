-- Recovery models
-- RM - 1: Simple

/*alter database SalesDB SET RECOVERY SIMPLE;

-- check recovery model
SELECT name, recovery_model_desc
from sys.databases
where name = 'SalesDB';
go
*/
-- backup strategies:
/* 1. Full backup daily or more frequently
   2. No transaction log backups
   3. set a backup Schedule 
   4. differetial backup recommended*/

-- RM - 2: Full
/*alter database SalesDB SET RECOVERY FULL;

-- check recovery model
SELECT name, recovery_model_desc
from sys.databases
where name = 'SalesDB';
go*/

-- backup strategies:
-- 1. Daily backup
-- 2. transaction logs backup every 15 minute
-- 3. differential backup every 4 hours

-- RM - 3: Bulk logging
--alter database SalesDB set recovery Bulk_logged;
--go

/*create table SalesData (
	Order_ID varchar(50) primary key,
	Order_Date datetime not null,
	Region varchar(25) not null,
	State varchar(50),
	City varchar(100),
	Salesperson varchar(50),
	Customer_Segment varchar(50),
	Channel varchar(50),
	Product_Category varchar(100),
	Product varchar(100),
	Units int,
	Unit_Price decimal(10,2),
	Discount_Pct int,
	Revenue decimal(10, 2),
	Cost decimal(10,2),
	Profit decimal(10,2),
	Profit_Margin int,
	Payment_Method	varchar(50), 
	Customer_Rating	decimal(4,2),
	Order_Status varchar(50)

);

go */

-- perform bulk op
/*bulk insert dbo.SalesData from 'C:\Users\PallaviPrasad\OneDrive - CloudThat\Desktop\ai tools data\demo data\copilot demo files\Sales_data.csv'
with (Fieldterminator = ',', rowterminator = '\n');*/


/*alter database SalesDB set recovery full;

backup log salesdb to disk = 'C:\Users\PallaviPrasad\OneDrive - CloudThat\Desktop\SQLData\salesdb_logs.trn';
go*/

/*backup database salesdb to disk = 'C:\Users\PallaviPrasad\CT Data\sample_data\salesdb_full_22092026.bak'
with
	compression, 
	description = 'full backup initial',
	name = 'SalesDB Full Backup';


backup database salesdb to disk = 'C:\Users\PallaviPrasad\CT Data\sample_data\salesdb_diff_22092026_1255.bak'
with
	differential,
	compression, 
	name = 'SalesDB Differential Backup';*/


-- restoring strategies:
-- step 1: start with the full backup
/* restore database salesdb
from disk = 'C:\Users\PallaviPrasad\CT Data\sample_data\salesdb_full_22092026.bak'
with norecovery; */
-- step 2: restore using latest differential backup.
restore database salesdb
from disk = 'C:\Users\PallaviPrasad\CT Data\sample_data\salesdb_diff_22092026_1255.bak'
with recovery;


