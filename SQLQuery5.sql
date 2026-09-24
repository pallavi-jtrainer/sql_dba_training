use DBA_Day2_Lab;
go

-- Incident: Unauthorized Data Access
/*
DBA, Application, Customer Support, Reporting, Auditor*/

-- step 1: Find the current users logged in
select name, type_desc, authentication_type_desc, default_schema_name
from sys.database_principals
where type IN ('S', 'U', 'E' ,'X')
order by name;

-- step 2: find the role
select 
	member.name as Username,
	role.name as Rolename
from sys.database_role_members drm
join sys.database_principals role
	on drm.role_principal_id = role.principal_id
join sys.database_principals member
	on drm.member_principal_id = member.principal_id
where member.name = 'CustomerSupportUser';

-- step 3: Confirm the actual permissions

-- step 4: whether the user belongs to any fixed roles

-- step 5: determine what is needed and what is not

-- step 6: remove what is not needed

-- OR

-- create a dedicated role and assign
create role CustomerSupportRole;

grant select on object::DBA_Day2_Lab.Customer to CustomerSupportRole;
grant select on object::DBA_Day2_Lab.Orders to CustomerSupportRole;

alter role customersupportrole 
add member customersupportuser;


