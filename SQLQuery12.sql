-- blocking and lock waits
-- step 1: identify blocking chains
-- step 2: check for the blocking session
-- step 3: check what the session wants to do
/* Causes:
1. long transaction - Rollback or wait for completion
2. missing index - add an index 
3. explicit lock - change the isolation level
*/
use SalesDB;
go

-- create a long transaction that locks the table
/*create table SalesDetails (
	salesId int primary key identity(1,1),
	salesperson nvarchar(100),
	region nvarchar(50),
	amount decimal(10,2),
	salesDate Datetime,
	orderid int,
	customerid int,
	status nvarchar(20) default 'pending'
);

create nonclustered index idx_salesdetails_salesperson
on dbo.salesdetails(salesperson)
include (region, amount, status);

create nonclustered index idx_salesdetails_region
on dbo.salesdetails(region)
include (salesperson, amount);

create nonclustered index idx_salesdetails_status
on dbo.salesdetails(status)
include (salesperson, amount, salesdate);

insert into SalesDetails (salesperson, region, amount, salesDate, orderid, customerid, status)
select 
	case when ROW_NUMBER() over (order by t1.object_id) % 3 = 0 then 'John'
		 when ROW_NUMBER() over (order by t1.object_id) % 3 = 1 then 'Jane'
		 else 'Mike'
	end as salesperson,
	case when ROW_NUMBER() over (order by t1.object_id) % 1 = 0 then 'North'
		 else 'South'
	end as region,
	ABS(checksum(t1.object_id)) % 50000 + 100.00 as amount,
	dateadd(day, - abs(checksum(t1.object_id)) % 30, getdate()) as salesdate,
	ROW_NUMBER() over (order by t1.object_id) as orderId,
	ABS(checksum(t1.object_id)) % 500 + 1 as customerid,
	case when ROW_NUMBER() over (order by t1.object_id) % 5 = 0 then 'completed'
		when ROW_NUMBER() over (order by t1.object_id) % 5 = 1 then 'cancelled'
		else 'pending'
	end as status
from sys.objects t1
where t1.object_id <30;


select *  from SalesDetails;*/

