-- Query 1: Current System Health Overview
/*SELECT 
    GETDATE() as [Collection_Time],
    @@SERVERNAME as [Server_Name],
    DB_NAME() as [Database_Name],
    SERVERPROPERTY('ProductVersion') as [SQL_Version];

-- Query 2: Current CPU and Memory Utilization
SELECT 
    CAST(100.0 * 
        SUM(CASE 
                when counter_name = 'Total Server Memory(KB)'
                then cntr_value
                else 0
             end )
             / Nullif(
                    sum(case 
                        when counter_name = 'Target Server Memory (KB)'
                        then cntr_value
                        else 0
                    end), 
                    0
                    ) as numeric(5,2)
                   ) as Memory_Utilization_Percent, osi.sqlserver_start_time
           from sys.dm_os_performance_counters pc
           cross join sys.dm_os_sys_info osi
           where pc.object_name LIKE '%Memory Manager%'
           and pc.counter_name in ('Total Server Memory (KB)', 'Target Server Memory (KB)')
           group by osi.sqlserver_start_time;*/


-- Create baseline collection procedure
CREATE PROCEDURE sp_CollectPerformanceBaseline
    @BaselineName NVARCHAR(100),
    @Notes NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Table to store baseline data
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'PerformanceBaseline')
    BEGIN
        CREATE TABLE PerformanceBaseline (
            BaselineID INT PRIMARY KEY IDENTITY(1,1),
            BaselineName NVARCHAR(100) NOT NULL,
            CollectionTime DATETIME NOT NULL,
            MetricType NVARCHAR(50) NOT NULL,
            MetricName NVARCHAR(255) NOT NULL,
            MetricValue NVARCHAR(MAX),
            Notes NVARCHAR(MAX)
        );
        CREATE INDEX idx_baseline_name_time ON PerformanceBaseline(BaselineName, CollectionTime);
    END
    
    DECLARE @Now DATETIME = GETDATE();
    
    -- Collect CPU Baseline
    INSERT INTO PerformanceBaseline 
    VALUES 
    (@BaselineName, @Now, 'CPU', 'CPU_Usage_Percent', 
     CAST((SELECT TOP 1 CAST(100.0 * SUM(cntr_value) 
            / (SELECT cntr_value FROM sys.dm_os_performance_counters 
               WHERE counter_name = 'Total Server Memory (KB)') 
            AS NUMERIC(5,2))
            FROM sys.dm_os_performance_counters
            WHERE object_name LIKE '%Memory Manager%'), NVARCHAR(MAX)), 
     @Notes);
    
    -- Collect Memory Baseline
    INSERT INTO PerformanceBaseline 
    VALUES 
    (@BaselineName, @Now, 'MEMORY', 'Available_Memory_MB',
     CAST((SELECT (cntr_value / 1024) FROM sys.dm_os_performance_counters 
           WHERE object_name LIKE '%Memory Manager%' 
           AND counter_name = 'Available Memory (KB)'), NVARCHAR(MAX)),
     @Notes);
    
    -- Collect I/O Baseline for all drives
    INSERT INTO PerformanceBaseline 
    SELECT 
        @BaselineName, @Now, 'DISK_IO', 
        'Logical_Reads_Per_Sec_' + CAST(ROW_NUMBER() OVER (ORDER BY database_id) AS NVARCHAR(10)),
        CAST(io.num_of_reads, NVARCHAR(MAX)),
        @Notes
    FROM sys.dm_io_virtual_file_stats(NULL, NULL) io
    WHERE database_id > 4;  -- Skip system databases
    
    -- Collect Wait Stats Baseline
    INSERT INTO PerformanceBaseline 
    SELECT TOP 5
        @BaselineName, @Now, 'WAIT_STATS', wait_type,
        CAST(wait_time_ms AS NVARCHAR(MAX)),
        @Notes
    FROM sys.dm_os_wait_stats
    WHERE wait_type NOT IN ('SQLTRACE_INCREMENTAL_FLUSH_SLEEP', 'SLEEP_TASK')
    ORDER BY wait_time_ms DESC;
    
    -- Collect Active Query Baseline
    INSERT INTO PerformanceBaseline 
    SELECT TOP 10
        @BaselineName, @Now, 'ACTIVE_QUERIES', 
        SUBSTRING(t.text, 1, 100),
        'CPU:' + CAST(r.cpu_time AS NVARCHAR(20)) + 
        'ms, Elapsed:' + CAST(r.total_elapsed_time AS NVARCHAR(20)) + 'ms',
        @Notes
    FROM sys.dm_exec_requests r
    CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) t
    WHERE r.session_id > 50
    ORDER BY r.cpu_time DESC;
    
    PRINT 'Baseline ''' + @BaselineName + ''' collected at ' + CAST(@Now AS NVARCHAR(25));
END;
GO

