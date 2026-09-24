-- View the buffer pool statistics
/*SELECT 
	object_name, counter_name, cntr_value
FROM
	sys.dm_os_performance_counters
WHERE
	counter_name IN ('Buffer Cache hit ratio', 'Page life expectancy')
ORDER BY counter_name;*/

-- top 10 procedures consuming max memory available in procedure cache
/*SELECT TOP 10
	db_name(p.dbid) AS [DATABASE],
	SUM(cp.size_in_bytes) as [SIZE(KB)],
	COUNT(*) AS [Plans Count],
	Substring(p.text, 1, 50) as [QUERY TEXT]
FROM sys.dm_exec_cached_plans cp
CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle) p
GROUP BY p.dbid, p.text
ORDER BY SUM(cp.size_in_bytes) DESC;*/

-- check the current memory configuration
/*SELECT
	'Server Memory State' AS [Configuration],
	@@SERVERNAME AS [Server Name],
	p.physical_memory_in_use_kb /1024 /1024 as [Physical RAM In Use (GB)],
	p.available_commit_limit_kb /1024 /1024 as [Commited Memory (GB)],
	p.total_virtual_address_space_kb /1024 /1024 as [Virtual Memory(GB)]
FROM
	sys.dm_os_process_memory p;*/


--------------------------- 2025 --------------------------
/*EXEC sp_configure 'buffer pool extention', 1;
Reconfigure;*/

