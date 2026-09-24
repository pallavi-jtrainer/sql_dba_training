# SQL Server 2025 DBA Training - Day 2
## Monitoring, Troubleshooting & Log Analysis

**Duration:** 8 Hours (9:00 AM - 5:00 PM)  
**Target Audience:** SQL Professionals with SQL Knowledge  
**SQL Server Version:** SQL Server 2025  
**Training Focus:** Production Monitoring and Troubleshooting

---

## Table of Contents

1. [Review of Day 1 Concepts](#review-of-day-1-concepts)
2. [Session 1: Baseline Metrics and Performance Monitoring (9:00 AM - 11:00 AM)](#session-1-baseline-metrics-and-performance-monitoring)
3. [Session 2: DMVs and Wait Statistics (11:00 AM - 1:00 PM)](#session-2-dmvs-and-wait-statistics)
4. [Session 3: Extended Events and Tracing (1:00 PM - 3:00 PM)](#session-3-extended-events-and-tracing)
5. [Session 4: Blocking, Deadlocks, and Troubleshooting Methodology (3:00 PM - 5:00 PM)](#session-4-blocking-deadlocks-and-troubleshooting-methodology)
6. [Hands-On Labs Summary](#hands-on-labs-summary)

---

## Review of Day 1 Concepts

Before starting Day 2, let's quickly review critical concepts from yesterday:

**Memory Configuration:**
- Max server memory should be: Total RAM - 4 GB
- TempDB requires: One file per physical core
- Buffer pool hit ratio should exceed: 99%

**File Management:**
- Auto-grow should use: Fixed MB, not percentage
- TempDB location should be: Dedicated fast disk (SSD preferred)
- Transaction log should be: On separate disk from data

**Backup Strategy:**
- Production databases should use: FULL recovery model
- Transaction log backups should occur: Every 15-30 minutes
- All backups should be: Tested regularly

---

## Session 1: Baseline Metrics and Performance Monitoring

### 9:00 AM - 10:00 AM | Part A: Understanding Performance Baselines

#### What is a Performance Baseline?

A performance baseline is a documented snapshot of normal system behavior under typical load conditions.

**Why Baselines Matter:**

```
Normal Performance
    ↓
Baseline Established
    ↓
User Reports "System is Slow"
    ↓
Compare Current Metrics to Baseline
    ↓
Identify Deviation
    ↓
Determine Root Cause
```

**Without Baseline:**
- "It's slow" - too vague
- Hard to measure improvement
- Can't distinguish normal fluctuation from problem

**With Baseline:**
- CPU: 40% baseline, now 85% (clear deviation)
- Memory: 14 GB baseline, now 15.5 GB (minor change)
- Disk Queue: 2 baseline, now 15 (significant issue)

#### Establishing Your Baseline

```sql
-- SQL Script: Baseline Metrics Capture

-- Run this script daily for 1-2 weeks during normal operations
-- Record results in spreadsheet for trending

CREATE TABLE dbo.PerformanceBaseline
(
    BaselineID INT PRIMARY KEY IDENTITY(1,1),
    CaptureDate DATETIME2 DEFAULT GETDATE(),
    MetricName VARCHAR(100),
    MetricValue NUMERIC(15,2),
    Unit VARCHAR(50),
    Notes VARCHAR(MAX)
);

-- CPU Metrics
INSERT INTO dbo.PerformanceBaseline (MetricName, MetricValue, Unit, Notes)
SELECT 
    'CPU % Processor Time',
    CAST(
        (SELECT cntr_value FROM sys.dm_os_performance_counters 
         WHERE object_name LIKE '%Processor%' 
         AND counter_name = '% Processor Time'
         AND instance_name = '_Total') * 1.0 / 100 AS NUMERIC(5,2)
    ),
    'Percentage',
    'CPU utilization of all cores'
UNION ALL
SELECT 
    'SQL Batch Requests/sec',
    (SELECT cntr_value FROM sys.dm_os_performance_counters 
     WHERE object_name LIKE '%SQL Statistics%' 
     AND counter_name = 'Batch Requests/sec'),
    'Requests/sec',
    'Query workload intensity'
UNION ALL
SELECT 
    'SQL Compilations/sec',
    (SELECT cntr_value FROM sys.dm_os_performance_counters 
     WHERE object_name LIKE '%SQL Statistics%' 
     AND counter_name = 'SQL Compilations/sec'),
    'Compilations/sec',
    'Query plan cache misses'

-- Memory Metrics
UNION ALL
SELECT 
    'Total Server Memory',
    CAST(
        (SELECT cntr_value / 1024.0 FROM sys.dm_os_performance_counters 
         WHERE counter_name = 'Total Server Memory (KB)') AS NUMERIC(15,2)
    ),
    'MB',
    'Current memory usage'
UNION ALL
SELECT 
    'Target Server Memory',
    CAST(
        (SELECT cntr_value / 1024.0 FROM sys.dm_os_performance_counters 
         WHERE counter_name = 'Target Server Memory (KB)') AS NUMERIC(15,2)
    ),
    'MB',
    'Target memory allocation'
UNION ALL
SELECT 
    'Free Memory',
    CAST(
        (SELECT cntr_value / 1024.0 FROM sys.dm_os_performance_counters 
         WHERE counter_name = 'Free Memory (KB)') AS NUMERIC(15,2)
    ),
    'MB',
    'Available memory'

-- I/O Metrics
UNION ALL
SELECT 
    'Physical Reads/sec',
    (SELECT cntr_value FROM sys.dm_os_performance_counters 
     WHERE counter_name = 'Physical Reads/sec'),
    'Reads/sec',
    'Disk read rate'
UNION ALL
SELECT 
    'Physical Writes/sec',
    (SELECT cntr_value FROM sys.dm_os_performance_counters 
     WHERE counter_name = 'Physical Writes/sec'),
    'Writes/sec',
    'Disk write rate'
UNION ALL
SELECT 
    'Page Life Expectancy',
    (SELECT cntr_value FROM sys.dm_os_performance_counters 
     WHERE counter_name = 'Page life expectancy'),
    'Seconds',
    'How long pages stay in cache (>300 good)'

-- Database Size
UNION ALL
SELECT 
    'Total Database Size',
    CAST(SUM(size * 8.0 / 1024) AS NUMERIC(15,2)),
    'MB',
    'All databases combined'
FROM sys.master_files;

-- View baseline data
SELECT 
    CaptureDate,
    MetricName,
    MetricValue,
    Unit
FROM dbo.PerformanceBaseline
ORDER BY CaptureDate DESC, MetricName;

-- Trend analysis (after 2 weeks of data)
SELECT 
    MetricName,
    MIN(MetricValue) AS [Min Value],
    AVG(MetricValue) AS [Avg Value],
    MAX(MetricValue) AS [Max Value],
    MAX(MetricValue) - MIN(MetricValue) AS [Range]
FROM dbo.PerformanceBaseline
WHERE CaptureDate > DATEADD(DAY, -14, GETDATE())
GROUP BY MetricName
ORDER BY MetricName;
```

**Key Baseline Metrics to Track:**

| Metric | Good | Concerning | Critical |
|--------|------|------------|----------|
| CPU % | < 60% | 60-80% | > 80% |
| Memory % Free | > 20% | 10-20% | < 10% |
| Disk Queue Length | < Cores | Cores-2x Cores | > 2x Cores |
| Page Life Expectancy | > 300 sec | 100-300 sec | < 100 sec |
| Buffer Hit Ratio | > 99% | 95-99% | < 95% |
| Batch Requests/sec | Variable | Variable | Watch trends |
| Physical Reads/sec | Variable | Variable | Watch trends |

#### Trending and Capacity Planning

```sql
-- SQL Script: Monthly Capacity Report

-- Database growth trend
SELECT TOP 12
    DATETRUNC(MONTH, CaptureDate) AS [Month],
    AVG(MetricValue) AS [Avg Database Size (MB)],
    MAX(MetricValue) AS [Peak Database Size (MB)]
FROM dbo.PerformanceBaseline
WHERE MetricName = 'Total Database Size'
GROUP BY DATETRUNC(MONTH, CaptureDate)
ORDER BY DATETRUNC(MONTH, CaptureDate) DESC;

-- Memory trend
SELECT TOP 12
    DATETRUNC(MONTH, CaptureDate) AS [Month],
    AVG(MetricValue) AS [Avg Memory (MB)],
    MAX(MetricValue) AS [Peak Memory (MB)]
FROM dbo.PerformanceBaseline
WHERE MetricName = 'Total Server Memory'
GROUP BY DATETRUNC(MONTH, CaptureDate)
ORDER BY DATETRUNC(MONTH, CaptureDate) DESC;

-- Workload trend (batch requests)
SELECT TOP 12
    DATETRUNC(MONTH, CaptureDate) AS [Month],
    AVG(MetricValue) AS [Avg Requests/sec],
    MAX(MetricValue) AS [Peak Requests/sec]
FROM dbo.PerformanceBaseline
WHERE MetricName = 'SQL Batch Requests/sec'
GROUP BY DATETRUNC(MONTH, CaptureDate)
ORDER BY DATETRUNC(MONTH, CaptureDate) DESC;

-- Growth rate calculation
-- If database grows 1 GB/week, estimate when max file size will be reached
DECLARE @WeeklyGrowth NUMERIC(10,2) = 1;  -- GB per week
DECLARE @CurrentSize INT = 50;  -- GB
DECLARE @MaxFileSize INT = 100;  -- GB
DECLARE @AvailableSpace INT = @MaxFileSize - @CurrentSize;
DECLARE @WeeksUntilFull INT = CEILING(@AvailableSpace / @WeeklyGrowth);

SELECT 
    @CurrentSize AS [Current Size (GB)],
    @WeeklyGrowth AS [Weekly Growth (GB)],
    @AvailableSpace AS [Available Space (GB)],
    @WeeksUntilFull AS [Weeks Until Full];
```

**Lab Exercise 2.1: Baseline Establishment**

```
SCENARIO: Create baseline for your SampleDB

STEPS:
1. Create PerformanceBaseline table (use script above)
2. Run baseline capture script
3. Wait 5 minutes, run again
4. Repeat 5 times (25 minutes total) during normal operations
5. View trend data
6. Identify peak and off-peak patterns
7. Document normal baseline values
8. Plan capacity needs
```

---

### 10:00 AM - 11:00 AM | Part B: Performance Monitoring Tools

#### System Performance Monitor (Perfmon)

Windows Performance Monitor provides OS-level metrics.

**Common SQL Server Counters:**

```
Memory:
├─ Available MBytes
├─ Pages/sec (< 10 is good)
├─ % Committed Bytes in Use
└─ Cache Bytes

Processor:
├─ % Processor Time (all CPUs)
├─ % User Time
├─ % Privileged Time
└─ Interrupts/sec

PhysicalDisk:
├─ % Disk Time (< 80% good)
├─ Avg. Disk Queue Length (< # of spindles)
├─ Disk Read Bytes/sec
├─ Disk Write Bytes/sec
└─ Avg. Disk sec/Transfer

SQL Server: Buffer Manager:
├─ Buffer Cache Hit Ratio (> 99%)
├─ Page reads/sec
├─ Page writes/sec
├─ Free Pages
└─ Total Pages

SQL Server: General Statistics:
├─ Logins/sec
├─ Logouts/sec
├─ User Connections
└─ Processes blocked

SQL Server: SQL Statistics:
├─ Batch Requests/sec
├─ SQL Compilations/sec
├─ SQL Re-Compilations/sec
└─ Guided plan executions/sec
```

**Create Perfmon Data Collector:**

```powershell
# PowerShell Script: Create Perfmon Collector

# Counters to monitor
$counters = @(
    "\Memory\Available MBytes",
    "\Memory\Pages/sec",
    "\Processor(_Total)\% Processor Time",
    "\PhysicalDisk(_Total)\% Disk Time",
    "\PhysicalDisk(_Total)\Avg. Disk Queue Length",
    "\SQL Server:Buffer Manager\Buffer Cache Hit Ratio",
    "\SQL Server:Buffer Manager\Page reads/sec",
    "\SQL Server:Buffer Manager\Page writes/sec",
    "\SQL Server:General Statistics\User Connections",
    "\SQL Server:SQL Statistics\Batch Requests/sec",
    "\SQL Server:SQL Statistics\SQL Compilations/sec"
)

# Create Data Collector Set
$dcsName = "SQL_Server_Performance"
$dcsPath = "C:\PerfLogs\SQLServer"

# Note: Requires Windows Performance Toolkit
# Download from: https://docs.microsoft.com/en-us/windows-hardware/get-started/adk-install
```

#### SQL Server Management Studio Performance Dashboard

SSMS built-in dashboard shows key metrics.

**Access:**
1. Connect to SQL Server in SSMS
2. Right-click server instance
3. Select "Reports" > "Standard Reports" > "Server Dashboard"

**Displays:**
- CPU utilization over last hour
- Memory usage trends
- Top resource consumers
- Recent backups
- Database file status

#### Query Store for Query Monitoring

SQL Server 2025 Query Store tracks query execution history.

```sql
-- SQL Script: Query Store Setup and Monitoring

-- Step 1: Enable Query Store
ALTER DATABASE SampleDB SET QUERY_STORE = ON;

-- Verify Query Store is enabled
SELECT 
    name AS [Database],
    is_query_store_on AS [Query Store Enabled],
    query_store_retention_days
FROM sys.databases
WHERE name = 'SampleDB';

-- Step 2: Generate some query activity
USE SampleDB;
-- Run various queries to generate store data

-- Step 3: View top resource-consuming queries
SELECT TOP 10
    q.query_id,
    q.object_id,
    qt.query_text,
    rs.avg_cpu_time / 1000.0 AS [Avg CPU (ms)],
    rs.avg_elapsed_time / 1000.0 AS [Avg Duration (ms)],
    rs.execution_count,
    rs.avg_logical_io_reads,
    rs.avg_physical_io_reads
FROM sys.query_store_query q
JOIN sys.query_store_query_text qt ON q.query_text_id = qt.query_text_id
JOIN sys.query_store_runtime_stats rs ON q.query_id = rs.query_id
ORDER BY rs.avg_cpu_time DESC;

-- Step 4: Identify query plan changes (regressions)
SELECT 
    q.query_id,
    q.object_name,
    COUNT(DISTINCT p.plan_id) AS [Number of Plans],
    p1.avg_cpu_time AS [Most Expensive CPU],
    p2.avg_cpu_time AS [Least Expensive CPU]
FROM sys.query_store_query q
JOIN sys.query_store_plan p ON q.query_id = p.query_id
CROSS APPLY (
    SELECT TOP 1 * FROM sys.query_store_plan 
    WHERE query_id = q.query_id 
    ORDER BY avg_cpu_time DESC
) p1
CROSS APPLY (
    SELECT TOP 1 * FROM sys.query_store_plan 
    WHERE query_id = q.query_id 
    ORDER BY avg_cpu_time ASC
) p2
GROUP BY q.query_id, q.object_name, p1.avg_cpu_time, p2.avg_cpu_time
HAVING COUNT(DISTINCT p.plan_id) > 1;

-- Step 5: Force best performing plan
EXEC sp_query_store_force_plan @query_id = 1, @plan_id = 1;

-- Step 6: Unforce plan if needed
EXEC sp_query_store_unforce_plan @query_id = 1, @plan_id = 1;

-- Step 7: Query Store size management
-- View Query Store space usage
SELECT 
    name,
    query_store_size_limit_mb,
    query_store_actual_size_mb,
    CAST(query_store_actual_size_mb * 100.0 / query_store_size_limit_mb AS NUMERIC(5,2)) AS [% Full]
FROM sys.database_query_store_options
WHERE database_id = DB_ID('SampleDB');

-- Clear Query Store if needed
-- ALTER DATABASE SampleDB SET QUERY_STORE = CLEAR;
```

**Lab Exercise 2.2: Perfmon and Query Store**

```
SCENARIO: Monitor SampleDB performance

STEPS:
1. Open Perfmon (perfmon.exe)
2. Add SQL Server counters (Buffer Manager, SQL Statistics)
3. Run capture for 30 minutes
4. Enable Query Store on SampleDB
5. Execute several queries
6. View top resource queries in Query Store
7. Compare Perfmon data with Query Store findings
8. Identify which query consumed most resources
```

---

## Session 2: DMVs and Wait Statistics

### 11:00 AM - 12:00 PM | Part A: Dynamic Management Views

DMVs provide detailed view of SQL Server internal state.

#### Most Important DMVs

```sql
-- SQL Script: Key DMVs for Troubleshooting

-- VIEW 1: sys.dm_exec_sessions
-- All active sessions

SELECT 
    session_id,
    login_name,
    host_name,
    database_id,
    status,
    cpu_time / 1000 AS [CPU Time (ms)],
    memory_usage * 8 / 1024 AS [Memory (MB)],
    total_scheduled_time / 1000 AS [Scheduled Time (ms)]
FROM sys.dm_exec_sessions
WHERE session_id > 50  -- Exclude system sessions
ORDER BY cpu_time DESC;

-- VIEW 2: sys.dm_exec_requests
-- Currently executing requests

SELECT 
    session_id,
    status,
    command,
    SUBSTRING(t.text, r.statement_start_offset / 2, 
        (CASE WHEN r.statement_end_offset = -1 
              THEN LEN(CONVERT(NVARCHAR(MAX), t.text)) * 2 
              ELSE r.statement_end_offset 
         END - r.statement_start_offset) / 2) AS [Current Statement],
    cpu_time / 1000 AS [CPU Time (ms)],
    total_elapsed_time / 1000 AS [Elapsed Time (ms)],
    reads,
    writes,
    logical_reads
FROM sys.dm_exec_requests r
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) t
WHERE session_id > 50
ORDER BY cpu_time DESC;

-- VIEW 3: sys.dm_exec_query_stats
-- Query execution statistics (from cache)

SELECT TOP 10
    execution_count,
    total_elapsed_time / 1000000 AS [Total Time (sec)],
    total_elapsed_time / execution_count / 1000 AS [Avg Time (ms)],
    total_worker_time / 1000 AS [Total CPU (ms)],
    total_logical_reads,
    total_physical_reads,
    SUBSTRING(st.text, 1, 100) AS [Query Text]
FROM sys.dm_exec_query_stats
CROSS APPLY sys.dm_exec_sql_text(sql_handle) st
ORDER BY total_elapsed_time DESC;

-- VIEW 4: sys.dm_os_performance_counters
-- Real-time performance metrics

SELECT 
    object_name,
    counter_name,
    instance_name,
    cntr_value
FROM sys.dm_os_performance_counters
WHERE counter_name IN (
    'Total Server Memory (KB)',
    'Target Server Memory (KB)',
    'Batch Requests/sec',
    'SQL Compilations/sec',
    'Physical Reads/sec'
);

-- VIEW 5: sys.dm_os_waiting_tasks
-- Tasks waiting for resources

SELECT 
    session_id,
    wait_type,
    wait_duration_ms,
    last_wait_type,
    SUBSTRING(t.text, 1, 80) AS [Query]
FROM sys.dm_os_waiting_tasks ow
CROSS APPLY sys.dm_exec_sql_text(ow.sql_handle) t
WHERE session_id > 50
ORDER BY wait_duration_ms DESC;

-- VIEW 6: sys.dm_db_missing_index_details
-- Missing indexes

SELECT 
    CONVERT(DECIMAL(18,2), 
        (user_seeks + user_scans + user_lookups) * avg_total_user_cost * avg_user_impact * (user_seeks + user_scans + user_lookups)) 
        AS [Improvement Measure],
    mid.equality_columns,
    mid.included_columns,
    migs.user_seeks,
    migs.avg_total_user_cost,
    migs.avg_user_impact
FROM sys.dm_db_missing_index_details mid
JOIN sys.dm_db_missing_index_groups_stats migs 
    ON mid.index_handle = migs.index_handle
WHERE database_id = DB_ID('SampleDB')
ORDER BY (user_seeks + user_scans + user_lookups) * avg_total_user_cost * avg_user_impact DESC;

-- VIEW 7: sys.dm_db_index_usage_stats
-- Index usage patterns

SELECT 
    object_name(i.object_id) AS [Table],
    i.name AS [Index],
    ius.user_seeks,
    ius.user_scans,
    ius.user_lookups,
    ius.user_updates,
    ius.last_user_seek,
    ius.last_user_scan
FROM sys.dm_db_index_usage_stats ius
JOIN sys.indexes i ON ius.object_id = i.object_id 
    AND ius.index_id = i.index_id
WHERE database_id = DB_ID('SampleDB')
ORDER BY ius.user_seeks + ius.user_scans + ius.user_lookups DESC;

-- VIEW 8: sys.dm_os_memory_clerks
-- Memory allocation by component

SELECT 
    type,
    SUM(pages_kb) / 1024 AS [Size (MB)],
    SUM(pages_in_use_kb) / 1024 AS [In Use (MB)],
    COUNT(*) AS [Number of Entries]
FROM sys.dm_os_memory_clerks
GROUP BY type
ORDER BY SUM(pages_kb) DESC;
```

#### Creating Performance Monitoring Procedures

```sql
-- SQL Script: Create DBA Monitoring Stored Procedures

USE SampleDB;

-- Procedure 1: Top Resource Consumers
CREATE OR ALTER PROCEDURE sp_TopResourceConsumers
    @TopCount INT = 10,
    @SortBy VARCHAR(50) = 'CPU'  -- 'CPU', 'ELAPSED', 'READS', 'WRITES'
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT TOP (@TopCount)
        execution_count,
        CASE WHEN @SortBy = 'CPU' THEN total_worker_time END / 1000 / 1000 AS [Total CPU (sec)],
        CASE WHEN @SortBy = 'ELAPSED' THEN total_elapsed_time END / 1000 / 1000 AS [Total Elapsed (sec)],
        total_logical_reads,
        total_physical_reads,
        total_writes,
        SUBSTRING(st.text, 1, 100) AS [Query Text],
        qs.creation_time,
        qs.last_execution_time
    FROM sys.dm_exec_query_stats qs
    CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) st
    ORDER BY 
        CASE 
            WHEN @SortBy = 'CPU' THEN qs.total_worker_time
            WHEN @SortBy = 'ELAPSED' THEN qs.total_elapsed_time
            WHEN @SortBy = 'READS' THEN qs.total_logical_reads
            WHEN @SortBy = 'WRITES' THEN qs.total_writes
            ELSE qs.total_elapsed_time
        END DESC;
END;

-- Execute the procedure
EXEC sp_TopResourceConsumers @TopCount = 10, @SortBy = 'CPU';

-- Procedure 2: Current Session Activity
CREATE OR ALTER PROCEDURE sp_SessionActivity
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        s.session_id,
        s.login_name,
        s.host_name,
        DB_NAME(s.database_id) AS [Database],
        s.status,
        SUBSTRING(t.text, r.statement_start_offset / 2, 
            (CASE WHEN r.statement_end_offset = -1 
                  THEN DATALENGTH(t.text) 
                  ELSE r.statement_end_offset 
             END - r.statement_start_offset) / 2) AS [Current Command],
        r.cpu_time / 1000 AS [CPU (ms)],
        r.total_elapsed_time / 1000 AS [Elapsed (ms)],
        r.reads,
        r.logical_reads
    FROM sys.dm_exec_sessions s
    LEFT JOIN sys.dm_exec_requests r ON s.session_id = r.session_id
    LEFT JOIN sys.dm_exec_sql_text(r.sql_handle) t ON 1=1
    WHERE s.session_id > 50
    ORDER BY r.cpu_time DESC;
END;

-- Procedure 3: Wait Statistics Summary
CREATE OR ALTER PROCEDURE sp_WaitStatistics
    @ResetStats BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    
    IF @ResetStats = 1
    BEGIN
        DBCC SQLPERF('sys.dm_os_wait_stats', CLEAR);
    END;
    
    SELECT TOP 20
        wait_type,
        waiting_tasks_count,
        wait_time_ms,
        max_wait_time_ms,
        signal_wait_time_ms,
        CAST(wait_time_ms * 100.0 / SUM(wait_time_ms) OVER () AS NUMERIC(5,2)) AS [% of Total Waits]
    FROM sys.dm_os_wait_stats
    WHERE wait_type NOT IN (
        'CLR_SEMAPHORE', 'LAZYWRITER_SLEEP', 'RESOURCE_QUEUE',
        'SLEEP_TASK', 'SLEEP_SYSTEMTASK', 'SQLTRACE_BUFFER_FLUSH',
        'WAITFOR', 'LOGMGR_QUEUE', 'CHECKPOINT_QUEUE'
    )
    ORDER BY wait_time_ms DESC;
END;

-- Usage
EXEC sp_WaitStatistics;
EXEC sp_SessionActivity;
```

---

### 12:00 PM - 1:00 PM | Lunch Break

---

### 1:00 PM - 2:00 PM | Part B: Wait Statistics Analysis

#### Wait Types and Meanings

Wait statistics indicate what SQL Server is doing when not executing.

```sql
-- SQL Script: Wait Type Analysis

-- Top wait types in SQL Server 2025

SELECT TOP 30
    wait_type,
    waiting_tasks_count,
    wait_time_ms,
    signal_wait_time_ms,
    wait_time_ms - signal_wait_time_ms AS [Resource Wait],
    CAST(100.0 * (wait_time_ms - signal_wait_time_ms) / wait_time_ms AS NUMERIC(5,2)) AS [% Resource Wait]
FROM sys.dm_os_wait_stats
WHERE wait_type NOT IN (
    'CLR_SEMAPHORE', 'LAZYWRITER_SLEEP', 'RESOURCE_QUEUE',
    'SLEEP_TASK', 'SLEEP_SYSTEMTASK', 'SQLTRACE_BUFFER_FLUSH',
    'WAITFOR', 'LOGMGR_QUEUE', 'CHECKPOINT_QUEUE'
)
ORDER BY wait_time_ms DESC;

-- Interpretation of wait types:

/*
CPU-related waits:
- CXPACKET: Parallel query wait for worker threads (normal for parallelism)
- SOS_SCHEDULER_YIELD: CPU saturation (CPU waiting for CPU time)

I/O-related waits:
- IO_COMPLETION: Waiting for disk I/O to complete
- PAGEIOLATCH_SH: Waiting for shared latch on page (disk read)
- PAGEIOLATCH_EX: Waiting for exclusive latch on page

Memory-related waits:
- RESOURCE_SEMAPHORE: Waiting for memory grant approval
- MEMORY_ALLOCATION_EXT: Waiting for memory to allocate
- BUFFER_IO_COMPLETION: Waiting for buffer pool I/O

Locking-related waits:
- LCK_M_*: Various lock waits (locks are explicitly named)
- LCK_M_IX: Waiting for intent exclusive lock
- LCK_M_S: Waiting for shared lock
- LCK_M_U: Waiting for update lock

Concurrency waits:
- PAGELATCHES_*: Page latch contention (buffer pool)
- LATCH_*: Memory structure latches

Network waits:
- ASYNC_NETWORK_IO: Client slow to consume results

Log-related waits:
- LOG_RATE_GOVERNOR: Transaction log rate limit
- LOGBUFFER: Transaction log space

*/
```

#### Healthy Wait Statistic Profile

```sql
-- SQL Script: Analyze Wait Profile Health

-- Calculate percentage distribution
SELECT 
    wait_type,
    waiting_tasks_count,
    CAST(100.0 * wait_time_ms / SUM(wait_time_ms) OVER () AS NUMERIC(5,2)) AS [% of Total]
FROM sys.dm_os_wait_stats
WHERE wait_time_ms > 0
  AND wait_type NOT IN (
    'CLR_SEMAPHORE', 'LAZYWRITER_SLEEP', 'RESOURCE_QUEUE',
    'SLEEP_TASK', 'SLEEP_SYSTEMTASK', 'SQLTRACE_BUFFER_FLUSH',
    'WAITFOR', 'LOGMGR_QUEUE', 'CHECKPOINT_QUEUE'
  )
ORDER BY wait_time_ms DESC;

/*
Healthy wait profile looks like:

Wait Type                  | % of Total | Meaning
CXPACKET                   | 20-30%     | Normal parallel query execution
IO_COMPLETION              | 10-20%     | Normal disk I/O
Sleeping                   | 10-20%     | Idle connections
PAGELATCHES_SH             | 5-10%      | Normal page latch contention
LCK_M_*                    | < 5%       | Minimal blocking
SOS_SCHEDULER_YIELD        | < 5%       | Low CPU pressure
WRITELOG                   | 1-3%       | Log writes (expected)
ASYNC_NETWORK_IO           | 1-3%       | Network transmission

Concerning profiles:

If SOS_SCHEDULER_YIELD > 10%:
→ CPU bottleneck
→ Add CPU or optimize queries

If IO_COMPLETION > 30%:
→ Disk I/O bottleneck
→ Add RAM or optimize queries

If RESOURCE_SEMAPHORE > 5%:
→ Memory pressure
→ Increase max server memory or optimize

If LCK_M_* > 10%:
→ Blocking and lock contention
→ Identify blocking queries and optimize

*/
```

**Lab Exercise 2.3: Wait Statistics Analysis**

```
SCENARIO: Analyze wait statistics on SampleDB

STEPS:
1. Create test procedure from sp_WaitStatistics
2. Execute procedure to capture current waits
3. Generate workload (run queries concurrently)
4. Wait 5 minutes, execute procedure again
5. Compare wait profiles before/after
6. Identify dominant wait type
7. Determine root cause
8. Note baseline for your system
```

---

## Session 3: Extended Events and Tracing

### 2:00 PM - 3:00 PM | Part A: Extended Events Fundamentals

Extended Events (XEvents) is SQL Server's event tracing system.

#### Creating an Extended Events Session

```sql
-- SQL Script: Create Extended Events Sessions

-- Simple Session: Capture slow queries (> 1 second)
CREATE EVENT SESSION [SlowQueries] ON SERVER
ADD EVENT sqlserver.sql_statement_completed
(
    ACTION (sqlserver.database_id, sqlserver.session_id, sqlserver.client_hostname)
    WHERE duration > 1000000  -- 1 second in microseconds
)
ADD TARGET package0.event_file
(
    SET filename = N'C:\XEvents\SlowQueries.xel',
    metadatafile = N'C:\XEvents\SlowQueries.xem'
),
ADD TARGET package0.ring_buffer
(
    SET max_memory = 4096
)
WITH
(
    MAX_MEMORY = 4MB,
    EVENT_RETENTION_MODE = ALLOW_SINGLE_EVENT_LOSS,
    STARTUP_STATE = ON
);

-- Start the session
ALTER EVENT SESSION [SlowQueries] ON SERVER STATE = START;

-- Verify session is running
SELECT 
    name,
    state_desc,
    creation_time
FROM sys.dm_xe_sessions
WHERE name = 'SlowQueries';

-- Advanced Session: Capture deadlocks with full context
CREATE EVENT SESSION [DeadlockCapture] ON SERVER
ADD EVENT sqlserver.database_xml_deadlock_report
(
    ACTION (sqlserver.database_id, sqlserver.session_id)
),
ADD EVENT sqlserver.locks_deadlock_chain
(
    ACTION (sqlserver.database_id, sqlserver.session_id, sqlserver.client_hostname)
)
ADD TARGET package0.event_file
(
    SET filename = N'C:\XEvents\DeadlockCapture.xel',
    metadatafile = N'C:\XEvents\DeadlockCapture.xem'
),
ADD TARGET package0.ring_buffer
(
    SET max_memory = 4096
)
WITH
(
    MAX_MEMORY = 4MB,
    EVENT_RETENTION_MODE = ALLOW_SINGLE_EVENT_LOSS,
    STARTUP_STATE = ON
);

-- Session: Error tracking
CREATE EVENT SESSION [ErrorTracking] ON SERVER
ADD EVENT sqlserver.error_reported
(
    WHERE severity >= 10  -- Warnings and errors
),
ADD EVENT sqlserver.timeout_deadlock
(
    WHERE severity >= 10
)
ADD TARGET package0.event_file
(
    SET filename = N'C:\XEvents\ErrorTracking.xel'
)
WITH
(
    MAX_MEMORY = 4MB,
    STARTUP_STATE = ON
);

-- View active XEvent sessions
SELECT 
    name,
    state_desc,
    MAX_MEMORY,
    creation_time
FROM sys.dm_xe_sessions
WHERE name LIKE '%'
ORDER BY name;

-- Stop a session
ALTER EVENT SESSION [SlowQueries] ON SERVER STATE = STOP;

-- Drop session (cannot drop if running)
ALTER EVENT SESSION [SlowQueries] ON SERVER STATE = STOP;
DROP EVENT SESSION [SlowQueries] ON SERVER;
```

#### Querying Extended Events Data

```sql
-- SQL Script: Read Extended Events File

-- Create a helper procedure to read XEvent files
CREATE OR ALTER PROCEDURE sp_ReadExtendedEvent
    @XEventPath NVARCHAR(MAX),
    @TopCount INT = 100
AS
BEGIN
    SET NOCOUNT ON;
    
    WITH cte_xevent AS
    (
        SELECT 
            CAST(event_data AS XML) AS event_xml
        FROM sys.fn_xe_file_target_read_file
        (
            @XEventPath + '*.xel',
            @XEventPath + '*.xem',
            NULL,
            NULL
        )
    )
    SELECT TOP (@TopCount)
        event_xml.value('(event/@timestamp)[1]', 'DATETIME2') AS [Event Time],
        event_xml.value('(event/@name)[1]', 'VARCHAR(MAX)') AS [Event Type],
        event_xml.value('(event/action[@name="session_id"]/value)[1]', 'INT') AS [Session ID],
        event_xml.value('(event/action[@name="database_id"]/value)[1]', 'INT') AS [Database ID],
        event_xml.value('(event/data[@name="duration"]/value)[1]', 'BIGINT') / 1000.0 AS [Duration (ms)],
        event_xml.value('(event/data[@name="statement"]/value)[1]', 'VARCHAR(MAX)') AS [Statement],
        CAST(event_xml AS VARCHAR(MAX)) AS [Full XML]
    FROM cte_xevent
    ORDER BY event_xml.value('(event/@timestamp)[1]', 'DATETIME2') DESC;
END;

-- Example usage:
-- EXEC sp_ReadExtendedEvent N'C:\XEvents\SlowQueries', 50;
```

**Lab Exercise 2.4: Extended Events Setup**

```
SCENARIO: Capture slow queries on SampleDB

STEPS:
1. Create XEvents directory: C:\XEvents
2. Execute SlowQueries event session creation
3. Start the event session
4. Execute some queries
5. Wait for activity
6. Query sys.dm_xe_sessions to verify capture
7. Create procedure to read XEvent file
8. Query captured events
9. Stop and drop session
```

---

### 3:00 PM - 4:00 PM | Part B: Blocking and Deadlock Analysis

#### Understanding Blocking

Blocking occurs when one query holds locks that another query needs.

```sql
-- SQL Script: Detect Current Blocking

-- View currently blocked sessions
SELECT 
    blocking_session_id,
    session_id,
    wait_duration_ms,
    last_wait_type,
    SUBSTRING(t.text, 1, 100) AS [Query]
FROM sys.dm_exec_requests r
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) t
WHERE blocking_session_id > 0;

-- Detailed blocking information
SELECT 
    b.session_id AS [Blocking SID],
    (SELECT login_name FROM sys.dm_exec_sessions WHERE session_id = b.session_id) AS [Blocking User],
    b.status AS [Blocking Status],
    w.session_id AS [Waiting SID],
    (SELECT login_name FROM sys.dm_exec_sessions WHERE session_id = w.session_id) AS [Waiting User],
    w.wait_duration_ms AS [Wait Time (ms)],
    w.last_wait_type,
    SUBSTRING(st_b.text, 1, 100) AS [Blocking Query],
    SUBSTRING(st_w.text, 1, 100) AS [Waiting Query]
FROM sys.dm_exec_requests b
INNER JOIN sys.dm_exec_requests w ON b.session_id = w.blocking_session_id
CROSS APPLY sys.dm_exec_sql_text(b.sql_handle) st_b
CROSS APPLY sys.dm_exec_sql_text(w.sql_handle) st_w;

-- Resolve blocking by killing blocking session (use with caution)
-- Step 1: Identify blocking session ID
DECLARE @BlockingSID INT = 52;

-- Step 2: Kill the blocking session
KILL @BlockingSID;

-- Step 3: Verify it's killed
SELECT 
    session_id,
    status
FROM sys.dm_exec_sessions
WHERE session_id = @BlockingSID;
```

#### Understanding Deadlocks

Deadlock occurs when two queries wait for resources held by each other.

```sql
-- SQL Script: Deadlock Analysis

-- Enable deadlock trace flag for logging
DBCC TRACEON (1222, -1);  -- Deadlock trace flag

-- Enable deadlock graph in Extended Events (as shown in section 3)

-- After deadlock, check SQL Server Error Log
-- File location: C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\Log

-- Or use this query to read error log
EXEC xp_readerrorlog 0, 1, N'Deadlock Graph';

-- Parse deadlock XML (if captured via XEvent)
WITH cte_deadlock AS
(
    SELECT 
        CAST(event_data AS XML) AS event_xml
    FROM sys.fn_xe_file_target_read_file
    (
        N'C:\XEvents\DeadlockCapture*.xel',
        N'C:\XEvents\DeadlockCapture*.xem',
        NULL,
        NULL
    )
)
SELECT 
    event_xml.value('(event/@timestamp)[1]', 'DATETIME2') AS [Deadlock Time],
    event_xml.value('(event/data/value/deadlock/process-list/process/@id)[1]', 'VARCHAR(MAX)') AS [Process 1 ID],
    event_xml.value('(event/data/value/deadlock/process-list/process/@id)[2]', 'VARCHAR(MAX)') AS [Process 2 ID],
    CAST(event_xml AS VARCHAR(MAX)) AS [Full Deadlock Graph]
FROM cte_deadlock;
```

**Common Deadlock Patterns:**

```
Pattern 1: Circular Lock Dependency

Process A: Locks Table1, tries to lock Table2
           ↓
Process B: Locks Table2, tries to lock Table1
           ↓
DEADLOCK!

Solution: Establish lock order (always lock Table1 before Table2)

Pattern 2: Reading in Different Order

Process A: SELECT FROM OrderHeader JOIN OrderDetail
Process B: SELECT FROM OrderDetail JOIN OrderHeader

Solution: Standardize join order

Pattern 3: High Contention on Hot Table

Many processes: SELECT/UPDATE same table
Result: Lock escalation to table lock
Then: Deadlock on table lock

Solution: Add indexes, reduce lock time, use row versioning
```

**Lab Exercise 2.5: Blocking and Deadlock Lab**

```
SCENARIO: Simulate and analyze blocking/deadlock

STEPS FOR BLOCKING LAB:
1. Open two SSMS windows (Window 1, Window 2)
2. Window 1:
   BEGIN TRAN
   UPDATE dbo.Users SET Email = 'new@email.com' WHERE UserID = 1
   -- Don't commit yet
3. Window 2:
   SELECT * FROM dbo.Users WHERE UserID = 1
   -- This will be blocked
4. In another window, execute blocking detection query
5. View results showing session blocking
6. Window 1: COMMIT
7. Verify Window 2 completes

STEPS FOR DEADLOCK LAB:
1. Window 1:
   BEGIN TRAN
   UPDATE dbo.Users SET Email = 'new1@email.com' WHERE UserID = 1
2. Window 2:
   BEGIN TRAN
   UPDATE dbo.Transactions SET Amount = 100 WHERE UserID = 1
3. Window 1:
   UPDATE dbo.Transactions SET Amount = 200 WHERE UserID = 1
4. Window 2:
   UPDATE dbo.Users SET Email = 'new2@email.com' WHERE UserID = 1
5. One window should get deadlock error
6. Check Extended Events for deadlock capture
7. Analyze deadlock graph
```

---

## Session 4: Blocking, Deadlocks, and Troubleshooting Methodology

### 4:00 PM - 5:00 PM | Troubleshooting Methodology

#### DBA Troubleshooting Workflow

```
User Reports "System is Slow"
        ↓
1. SYMPTOMS GATHERING
   - When does it happen?
   - Who is affected?
   - How many users impacted?
   - Frequency: Always? Sometimes?
        ↓
2. IMPACT ASSESSMENT
   - Business impact: High/Medium/Low
   - SLA implications: Breach? At risk?
   - Revenue impact: Yes/No
        ↓
3. EVIDENCE COLLECTION
   - Capture wait stats: sys.dm_os_wait_stats
   - View blocked sessions: sys.dm_exec_requests
   - Query Store history: sys.query_store_*
   - Extended Events: Slow queries
   - Perfmon data: CPU, Memory, I/O
   - SQL Error Log: Errors
        ↓
4. ISOLATION AND DIAGNOSIS
   - One query slow or many?
   - System bottleneck (CPU/Memory/I/O)?
   - Query plan problem?
   - Lock contention?
        ↓
5. REMEDIATION
   - Apply fix (query rewrite, index, config)
   - Test in staging first
   - Have rollback plan
   - Minimal risk approach
        ↓
6. VALIDATION
   - Performance improved?
   - No new problems?
   - Monitor for regression
   - Document solution
        ↓
7. ROOT CAUSE ANALYSIS
   - Why did it happen?
   - How to prevent in future?
   - Process improvements needed?
```

#### Troubleshooting Decision Tree

```sql
-- SQL Script: Comprehensive Troubleshooting Queries

-- STEP 1: Is it CPU?
SELECT 
    'CPU Utilization' AS [Metric],
    CAST(
        (SELECT cntr_value FROM sys.dm_os_performance_counters 
         WHERE object_name LIKE '%Processor%' 
         AND counter_name = '% Processor Time'
         AND instance_name = '_Total') * 1.0 / 100 AS NUMERIC(5,2)
    ) AS [Value],
    'If > 80%, CPU is bottleneck' AS [Action]
UNION ALL
-- STEP 2: Is it Memory?
SELECT 
    'Free Memory (MB)',
    (SELECT cntr_value / 1024.0 FROM sys.dm_os_performance_counters 
     WHERE counter_name = 'Free Memory (KB)'),
    'If < 512 MB free, memory pressure'
UNION ALL
-- STEP 3: Is it I/O?
SELECT 
    'Avg Disk Queue Length',
    (SELECT cntr_value FROM sys.dm_os_performance_counters 
     WHERE object_name LIKE '%Disk%' 
     AND counter_name = 'Avg. Disk Queue Length'
     AND instance_name = '_Total'),
    'If > CPU cores, I/O bottleneck'
UNION ALL
-- STEP 4: Is it Blocking?
SELECT 
    'Active Blocking Sessions',
    COUNT(*),
    'If > 0, blocking is occurring'
FROM sys.dm_exec_requests
WHERE blocking_session_id > 0;

-- STEP 5: Find top resource consumer
SELECT TOP 1
    'Top CPU Consumer',
    SUBSTRING(st.text, 1, 80),
    qs.total_worker_time / 1000 / 1000 AS [Total CPU (sec)]
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) st
ORDER BY qs.total_worker_time DESC;

-- STEP 6: Check wait statistics
SELECT TOP 3
    'Top Wait Type',
    wait_type,
    CAST(100.0 * wait_time_ms / SUM(wait_time_ms) OVER () AS NUMERIC(5,2)) AS [% Total]
FROM sys.dm_os_wait_stats
WHERE wait_type NOT IN ('CLR_SEMAPHORE', 'LAZYWRITER_SLEEP', 'RESOURCE_QUEUE')
ORDER BY wait_time_ms DESC;

-- STEP 7: Check query plans
SELECT TOP 5
    'Expensive Query',
    SUBSTRING(st.text, 1, 80),
    qs.total_elapsed_time / 1000 / 1000 / 1000 AS [Total Time (sec)]
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) st
ORDER BY qs.total_elapsed_time DESC;
```

#### Common Performance Issues and Solutions

| Issue | Symptoms | Diagnosis | Solution |
|-------|----------|-----------|----------|
| **Missing Index** | High logical reads, slow queries | Missing index DMV, execution plan scans | Create index |
| **Parameter Sniffing** | Slow sometimes, fast others | Different plans for different parameters | RECOMPILE, OPTIMIZE FOR |
| **Stale Statistics** | Wrong row estimates, wrong plan | Execution plan cardinality mismatch | UPDATE STATISTICS |
| **High Parallelism** | High CPU, CXPACKET waits | Many parallel queries | Increase COST THRESHOLD |
| **Memory Pressure** | LOW page life expectancy, high reads | Free memory < 512 MB | Increase max server memory |
| **Disk Bottleneck** | HIGH IO_COMPLETION waits | Disk queue > CPU count | Add RAM, add indexes, optimize |
| **Lock Contention** | Blocking detected, LCK waits | sys.dm_exec_requests show blocking | Add index, restructure query |
| **Deadlocks** | User gets error, transaction rolls back | Extended Events, error log | Change lock order |
| **Compilation Overhead** | HIGH compilations, low reuse | SQL Compilations/sec high | Parameterize queries |
| **Log Bottleneck** | LOGBUFFER waits, slow writes | Many logging waits | Add CPU, faster disk, increase log autogrow |

**Lab Exercise 2.6: End-to-End Troubleshooting**

```
SCENARIO: Production database reporting slowness

GIVEN:
- Users report queries running slow (normally 2 sec, now 15+ sec)
- Started after database grew to 50 GB
- Affects multiple users
- Happens randomly

TASK:
1. Establish baseline (what's normal?)
   - Query sys.dm_os_performance_counters
   - Check CPU, Memory, I/O utilization
   
2. Identify bottleneck
   - Check wait statistics
   - Is it CPU, Memory, or I/O?
   
3. Analyze affected queries
   - Query sys.dm_exec_query_stats
   - Find top 3 most expensive queries
   - Get actual execution plans
   
4. Investigate root cause
   - Check for missing indexes
   - Check statistics freshness
   - Look for scan operators in plan
   
5. Implement fix
   - Create suggested indexes
   - Recompile statistics
   - Test performance improvement
   
6. Document solution
   - Before/after metrics
   - Query plan comparison
   - Preventive measures

DELIVERABLES:
- Performance metrics before and after
- Root cause analysis
- Query execution plans
- Index creation script
- Monitoring recommendations
```

---

## Hands-On Labs Summary

### Lab 1: Baseline Establishment
- Create baseline metrics table
- Capture performance metrics
- Trend analysis
- Establish normal values

### Lab 2: Perfmon and Query Store Monitoring
- Configure Perfmon counters
- Enable Query Store
- Monitor top resource queries
- Compare metrics

### Lab 3: DMV Analysis
- Create monitoring procedures
- Query top resource consumers
- Analyze wait statistics
- Identify performance issues

### Lab 4: Extended Events
- Create XEvent sessions (slow queries, deadlocks)
- Capture and read event data
- Analyze patterns
- Set up production monitoring

### Lab 5: Blocking and Deadlock Lab
- Simulate blocking scenarios
- Capture blocking chain
- Simulate deadlock
- Analyze deadlock graph
- Implement resolution

### Lab 6: End-to-End Troubleshooting
- Complete troubleshooting scenario
- Performance diagnosis
- Root cause identification
- Implement fix
- Document solution

---

## Summary

**Day 2 has covered:**
1. ✓ Performance baseline establishment and trending
2. ✓ DMVs for real-time performance monitoring
3. ✓ Wait statistics analysis and interpretation
4. ✓ Extended Events for detailed event capture
5. ✓ Blocking detection and resolution
6. ✓ Deadlock analysis and prevention
7. ✓ Comprehensive troubleshooting methodology

**Key Takeaways:**
- Establish baselines to measure deviations
- Use DMVs for detailed performance visibility
- Wait statistics show resource bottlenecks
- Extended Events capture detailed event data
- Systematic troubleshooting leads to faster resolution

**Next Steps (Day 3):**
Tomorrow we'll focus on query optimization, performance tuning, and maintenance automation.

---

## Additional Resources

- [Day 2 Codes.txt](./Day_2_Codes.txt) - All working SQL scripts
- [Day 2 Deep Dive.txt](./Day_2_Deep_Dive.txt) - Detailed technical explanations
- SQL Server DMV Reference: https://learn.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/system-dynamic-management-views
- Extended Events: https://learn.microsoft.com/en-us/sql/relational-databases/extended-events/extended-events
