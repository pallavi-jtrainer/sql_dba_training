-- COMPREHENSIVE PERFORMANCE DASHBOARD
-- Run this query to see overall system health at a glance

PRINT '════════════════════════════════════════════════════════════';
PRINT 'SQL SERVER PERFORMANCE DASHBOARD - ' + CONVERT(VARCHAR(25), GETDATE(), 121);
PRINT '════════════════════════════════════════════════════════════';
PRINT '';

-- Section 1: CPU and Memory
PRINT '1. CPU & MEMORY STATUS';
PRINT '─────────────────────';
SELECT TOP 1
    'CPU_Utilization' as [Metric],
    CAST(100.0 * (SELECT SUM(cntr_value) 
        FROM sys.dm_os_performance_counters 
        WHERE object_name LIKE '%Processor%' 
        AND counter_name = '% Processor Time' 
        AND instance_name = '_Total') 
        / (SELECT cntr_value 
           FROM sys.dm_os_performance_counters 
           WHERE object_name LIKE '%Processor%' 
           AND counter_name = '% Processor Time' 
           AND instance_name = '_Total') AS NUMERIC(5,2)) as [Value],
    'Percent' as [Unit]
FROM sys.dm_os_schedulers;

-- Section 2: Top Wait Types
PRINT '';
PRINT '2. TOP 5 WAIT TYPES';
PRINT '───────────────────';
SELECT TOP 5
    CAST(ROW_NUMBER() OVER (ORDER BY wait_time_ms DESC) AS VARCHAR(2)) + '. ' + 
        wait_type as [Wait_Type],
    CAST(CAST(wait_time_ms / 1000.0 AS NUMERIC(12,2)) AS VARCHAR(15)) + ' sec' as [Total_Wait],
    CAST(CAST(wait_time_ms / NULLIF(waiting_tasks_count, 0) AS NUMERIC(10,2)) AS VARCHAR(15)) + ' ms' as [Avg_Wait]
FROM sys.dm_os_wait_stats
WHERE wait_type NOT LIKE 'SLEEP%'
    AND wait_type NOT LIKE 'SQLTRACE%'
ORDER BY wait_time_ms DESC;

-- Section 3: Top Resource Queries
PRINT '';
PRINT '3. TOP 5 RESOURCE-CONSUMING QUERIES (LAST 24 HOURS)';
PRINT '─────────────────────────────────────────────────────';
SELECT TOP 5
    CAST(ROW_NUMBER() OVER (ORDER BY SUM(qs.total_worker_time) DESC) AS VARCHAR(2)) + '. ' +
        SUBSTRING(t.text, 1, 60) as [Query],
    CAST(SUM(qs.total_worker_time) / 1000000.0 AS NUMERIC(12,2)) as [CPU_Seconds],
    SUM(qs.execution_count) as [Executions],
    CAST(AVG(qs.total_elapsed_time) / 1000.0 AS NUMERIC(10,2)) as [Avg_Time_ms]
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) t
WHERE qs.creation_time > DATEADD(HOUR, -24, GETDATE())
GROUP BY qs.sql_handle, t.text
ORDER BY SUM(qs.total_worker_time) DESC;

-- Section 4: Currently Running Queries
PRINT '';
PRINT '4. ACTIVE REQUESTS (RUNNING RIGHT NOW)';
PRINT '──────────────────────────────────────';
SELECT 
    CAST(r.session_id AS VARCHAR(5)) + ' (' + r.status + ')' as [Session],
    SUBSTRING(t.text, 1, 50) as [Query],
    CAST(DATEDIFF(SECOND, r.start_time, GETDATE()) AS VARCHAR(5)) + ' sec' as [Running_For]
FROM sys.dm_exec_requests r
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) t
WHERE r.session_id > 50;

-- Section 5: Index Fragmentation
PRINT '';
PRINT '5. MOST FRAGMENTED INDEXES';
PRINT '───────────────────────────';
SELECT TOP 5
    OBJECT_NAME(i.object_id) as [Table],
    i.name as [Index],
    CAST(ps.avg_fragmentation_in_percent AS NUMERIC(5,2)) as [Fragmentation_%]
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') ps
INNER JOIN sys.indexes i 
    ON ps.object_id = i.object_id 
    AND ps.index_id = i.index_id
WHERE ps.avg_fragmentation_in_percent > 10
    AND ps.page_count > 1000
ORDER BY ps.avg_fragmentation_in_percent DESC;

PRINT '';
PRINT '════════════════════════════════════════════════════════════';