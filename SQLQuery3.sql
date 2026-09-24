-- inspect the db files
/*SELECT 
	DB_NAME(database_id) as DatabaseName,
	name as LogicalFileName,
	physical_name,
	type_desc
from
	sys.master_files
Order by DatabaseName;*/

/*create database DBAtrainingDB;
go

select 
	name,
	database_id,
	state_desc,
	recovery_model_desc,
	compatibility_level
from
	sys.databases
where name='DBAtrainingDB';*/

/*create database SalesDB
on primary
(
	Name = SalesDB_Data,
	Filename = 'C:\Users\PallaviPrasad\CT Data\sample_data\SalesDB.mdf',
	size = 200MB,
	maxsize = 10000MB,
	filegrowth = 50MB
)
log on
(
	name = SalesDB_Logs,
	filename = 'C:\Users\PallaviPrasad\CT Data\sample_data\SQL_Logs\SalesDB_log.ldf',
	size = 100MB,
	filegrowth = 50MB
);
go*/

/*drop database SalesDB;
go*/

/*use master;
go*/


/*create database SalesDB
on primary
(
	name = 'SalesDB_Primary',
	filename = 'C:\Users\PallaviPrasad\CT Data\sample_data\SalesDB.mdf',
	size = 500MB,
	maxsize = 25000MB,
	filegrowth = 100MB
),
filegroup Data_FG
(
	name = 'SalesDB_Data_01',
	filename = 'C:\Users\PallaviPrasad\CT Data\sample_data\SalesDB_Data_01.ndf',
	size = 100MB,
	maxsize = 10000MB,
	filegrowth = 50MB
),
filegroup Indexes_FG
(
	name = 'SalesDB_IDX_01',
	filename = 'C:\Users\PallaviPrasad\CT Data\sample_data\SalesDB_IDX_01.ndf',
	size = 100MB,
	maxsize = 10000MB,
	filegrowth = 50MB	
);*/

/*alter database SalesDB Add filegroup Archive_FG;

alter database SalesDB
Add file
(
	name = 'SalesDB_Archive',
	filename = 'C:\Users\PallaviPrasad\CT Data\sample_data\SalesDB_Archive.ndf',
	size = 200MB,
	filegrowth = 50MB
)
to filegroup Archive_FG;*/

-- monitor performance per filegroup
/*select
	fg.name as FileGroup,
	sum(dfs.io_stall_read_ms) as [Read Stall (ms)],
	sum(dfs.io_stall_write_ms) as [Write Stall (ms)],
	sum(dfs.num_of_reads) as [Total Reads],
	sum(dfs.num_of_writes) as [Total Writes]
from
	sys.dm_io_virtual_file_stats(DB_ID(), NULL) dfs
inner join sys.database_files df On dfs.file_id = df.file_id
inner join sys.filegroups fg on df.data_space_id = fg.data_space_id
group by fg.name
order by sum(dfs.io_stall_read_ms) + sum(dfs.io_stall_write_ms) Desc;*/

alter database DBAtrainingDB
set compatibility_level = 170;
go

-- view database compatibility level
select name as Databasename,
	DATABASEPROPERTYEX(name, 'Compatibility') as [Compatibility Level]
from sys.databases
order by name;

go