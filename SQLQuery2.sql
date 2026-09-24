-- Row level security

/*use SalesDB;

create table Sales (
	salesid int primary key,
	salesperson varchar(100) not null,
	region varchar(100) not null,
	amount decimal(10,2) not null,
	salesDate DateTime not null
);

insert into sales values
(1, 'John', 'North', 12000.00, '2026-01-02'),
(2, 'Jane', 'South', 15000.00, '2026-01-03'),
(3, 'John', 'North', 10000.00, '2026-01-04'),
(4, 'Jane', 'South', 20000.00, '2026-01-05'),
(5, 'John', 'North', 22000.00, '2026-01-06'),
(6, 'Jane', 'South', 12000.00, '2026-01-07');
*/

-- predicate function
/*create function dbo.fn_SalesSecurityPredicate(@Region varchar(100))
returns table
with schemabinding
AS
Return 
(
	select 1 as result
	where @Region = CAST(SESSION_CONTEXT(N'Region') as varchar(100))
	or IS_MEMBER(N'db_owner') = 1
);*/

-- security policy
/*create security policy SalesSecurityPolicy
add filter predicate dbo.fn_SalesSecurityPredicate(Region)
on dbo.sales
with (state = on);

go*/

-- create users for testing
-- step 1: create server logins
/*use master;
go

create login NorthUser with Password = 'Pass123!';
create login SouthUser with Password = 'Pass123!';*/


-- step 2: create users for these logins
-- use SalesDB;

-- create user NorthUser for login NorthUser;
-- create user SouthUser for login SouthUser;

-- step 3: grant permissions
--Grant select on dbo.Sales to NorthUser;
/* grant select on dbo.Sales to SouthUser;
go

execute as user = 'SouthUser';
go

exec sys.sp_set_session_context
	@key = N'Region',
	@value = N'South'
go

Select * from dbo.Sales;
go

Revert;
go */

-- select * from dbo.sales;

/* troubleshooting RLS 
Step 1: check if RLS enabled
Step 2: check the predicate function
Step 3: check USER_NAME() or SESSION_CONTEXT()
Step 4: update the predicate to check for table mapping
Step 5: create a mapping table (optional)
Step 6: test again */