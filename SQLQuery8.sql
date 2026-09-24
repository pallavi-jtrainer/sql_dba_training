-- DMV1 - wait stats - sys.dm_os_wait_stats
SELECT TOP 20
    wait_type,
    waiting_tasks_count,
    wait_time_ms,
    avg_wait_time_ms = CAST(wait_time_ms / NULLIF(waiting_tasks_count, 0) AS NUMERIC(12,2)),
    percent_total = CAST(100.0 * wait_time_ms 
                        / SUM(wait_time_ms) OVER () AS NUMERIC(5,2)),
    CAST(wait_time_ms / 1000.0 / 60.0 AS NUMERIC(10,2)) as [Total_Minutes]
FROM sys.dm_os_wait_stats
WHERE wait_type NOT IN (
    'SQLTRACE_INCREMENTAL_FLUSH_SLEEP',
    'LOGMGR_QUEUE',
    'CHECKPOINT_QUEUE',
    'REQUEST_FOR_DEADLOCK_SEARCH',
    'SLEEP_TASK',
    'LAZYWRITER_SLEEP',
    'BROKER_EVENTHANDLER',
    'BROKER_RECEIVE_WAITFOR',
    'BROKER_TO_FLUSH',
    'BROKER_TRANSMITTER',
    'SLEEP_SYSTEMTASK',
    'WAITFOR_TASKSHOP',
    'HADR_CLUSAPI_CALL',
    'HADR_FILESTREAM_IOMGR_IOCOMPLETION'
)
ORDER BY wait_time_ms DESC;

--DMV2 - active requests - sys.dm_exec_requests
SELECT 
    r.session_id,
    r.request_id,
    r.status,
    r.command,
    r.cpu_time as [CPU_ms],
    r.total_elapsed_time as [Elapsed_ms],
    r.logical_reads,
    r.writes,
    r.start_time,
    DATEDIFF(SECOND, r.start_time, GETDATE()) as [Running_Seconds],
    r.wait_type,
    r.wait_time_ms,
    r.dop as [Degree_of_Parallelism],  -- NEW in 2019+
    r.granted_query_memory * 8 / 1024 as [Memory_Grant_MB],
    r.spills,  -- NEW in 2016 SP2+, enhanced in 2022
    DB_NAME(r.database_id) as [Database],
    SUBSTRING(t.text, 1, 100) as [Query_Text],
    l.login_name,
    l.program_name
FROM sys.dm_exec_requests r
LEFT JOIN sys.dm_exec_sql_text(r.sql_handle) t ON 1=1
LEFT JOIN sys.dm_exec_sessions l ON r.session_id = l.session_id
WHERE r.session_id > 50
ORDER BY r.cpu_time DESC;

-- DMV 3 - active sessions - sys.dm_exec_sessions
SELECT TOP 30
    s.session_id,
    s.login_name,
    s.host_name,
    s.program_name,
    s.database_id,
    s.status,
    s.cpu_time,
    s.memory_usage * 8 / 1024 as [Memory_Usage_MB],
    s.logical_reads,
    s.login_time,
    DATEDIFF(MINUTE, s.login_time, GETDATE()) as [Connected_Minutes],
    s.endpoint_id 
FROM sys.dm_exec_sessions s
WHERE s.session_id > 50
ORDER BY s.cpu_time DESC;

-- DMV 4 - index health check - sys.dm_db_index_operational_stats
SELECT 
    DB_NAME(ios.database_id) as [Database],
    OBJECT_NAME(ios.object_id, ios.database_id) as [Table],
    i.name as [Index],
    i.type_desc as [Index_Type],
    ios.leaf_insert_count,
    ios.leaf_delete_count,
    ios.leaf_update_count,
    (ios.leaf_insert_count + ios.leaf_delete_count + ios.leaf_update_count) 
        as [Total_Modifications],
    ios.range_scan_count,
    ios.singleton_lookup_count,
    (ios.range_scan_count + ios.singleton_lookup_count) as [Total_Reads],
    CASE 
        WHEN (ios.range_scan_count + ios.singleton_lookup_count) = 0 THEN 0
        ELSE CAST(100.0 * ios.singleton_lookup_count / 
            (ios.range_scan_count + ios.singleton_lookup_count) AS NUMERIC(5,2))
    END as [Seek_Percent],
    ps.avg_fragmentation_in_percent,
    ps.page_count,
    ps.compressed_page_count  -- NEW in 2016+
FROM sys.dm_db_index_operational_stats(NULL, NULL, NULL, NULL) ios
INNER JOIN sys.indexes i 
    ON ios.object_id = i.object_id 
    AND ios.index_id = i.index_id
INNER JOIN sys.dm_db_index_physical_stats(NULL, NULL, NULL, NULL, 'LIMITED') ps
    ON ios.database_id = ps.database_id
    AND ios.object_id = ps.object_id
    AND ios.index_id = ps.index_id
WHERE ios.database_id > 4
    AND ps.avg_fragmentation_in_percent > 10
    AND ps.page_count > 1000
    AND OBJECT_NAME(ios.object_id, ios.database_id) IS NOT NULL
ORDER BY ps.avg_fragmentation_in_percent DESC;

-- DMV 5 - resource intensive queries - sys.dm_exec_query_stats

-- DMV 6 - query regression using query store - sys.query_store_query

-- DMV 7 - monitoring the version store - sys.dm_tran_version_store

-- DMV 8 - monitoring the i/o per file - sys.dm_io_virtual_file_stats

-- DMV 9 - missing index details - sys.dm_db_missing_index_details
