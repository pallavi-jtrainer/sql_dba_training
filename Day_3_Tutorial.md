# SQL Server 2025 DBA Training - Day 3
## Query Optimization, Performance Tuning & Maintenance Automation

**Duration:** 8 Hours (9:00 AM - 5:00 PM)  
**Target Audience:** SQL Professionals with SQL Knowledge  
**SQL Server Version:** SQL Server 2025  
**Training Focus:** Query Optimization and Proactive Maintenance

---

## Table of Contents

1. [Session 1: Execution Plans and Query Analysis (9:00 AM - 11:00 AM)](#session-1-execution-plans-and-query-analysis)
2. [Session 2: Index Design and Optimization (11:00 AM - 1:00 PM)](#session-2-index-design-and-optimization)
3. [Session 3: Statistics and Cardinality Estimation (1:00 PM - 3:00 PM)](#session-3-statistics-and-cardinality-estimation)
4. [Session 4: Maintenance Automation and Monitoring (3:00 PM - 5:00 PM)](#session-4-maintenance-automation-and-monitoring)
5. [Hands-On Labs Summary](#hands-on-labs-summary)

---

## Session 1: Execution Plans and Query Analysis

### 9:00 AM - 10:00 AM | Part A: Execution Plan Fundamentals

#### Understanding Execution Plans

An execution plan is SQL Server's recipe for executing a query.

**Plan Generation Process:**

```
User writes query
    ↓
SQL Server parses (syntax check)
    ↓
SQL Server binds (schema validation)
    ↓
Query Optimizer analyzes:
  - Available indexes
  - Table statistics
  - Join order possibilities
  - Access methods
    ↓
Optimizer chooses best plan (lowest cost estimate)
    ↓
Plan gets compiled
    ↓
Plan cached for reuse
    ↓
Plan executes
    ↓
Results returned to user
```

**Viewing Execution Plans:**

```sql
-- Method 1: Actual Execution Plan
-- In SSMS: Query > Include Actual Execution Plan (Ctrl + L in 2019+)
-- Then run query and view plan tab

-- Method 2: Estimated Execution Plan
-- In SSMS: Query > Display Estimated Execution Plan (Ctrl + L)
-- Without executing query

-- Method 3: SET STATISTICS IO
SET STATISTICS IO ON;
SELECT * FROM Orders WHERE OrderID = 1;
SET STATISTICS IO OFF;

-- Output shows:
-- Table 'Orders'. Scan count 1, logical reads 1, physical reads 0

-- Method 4: SET STATISTICS TIME
SET STATISTICS TIME ON;
SELECT * FROM Orders WHERE OrderID = 1;
SET STATISTICS TIME OFF;

-- Output shows:
-- CPU time = 0 ms,  elapsed time = 0 ms

-- Method 5: Query Store Plan Information
SELECT 
    q.query_id,
    qt.query_text,
    p.plan_id,
    rs.avg_cpu_time,
    rs.avg_elapsed_time
FROM sys.query_store_query q
JOIN sys.query_store_query_text qt ON q.query_text_id = qt.query_text_id
JOIN sys.query_store_plan p ON q.query_id = p.query_id
JOIN sys.query_store_runtime_stats rs ON p.plan_id = rs.plan_id
ORDER BY q.query_id;
```

#### Execution Plan Operators

**Common Operators and Their Meanings:**

```
TABLE SCAN
├─ Meaning: Reading entire table sequentially
├─ Cost: HIGH for large tables
├─ When used: No suitable index available
├─ Optimization: Add index, use WHERE clause
└─ Expected: <5% of queries in well-tuned system

INDEX SEEK
├─ Meaning: Using index to find specific rows
├─ Cost: LOW
├─ When used: Index covers WHERE clause conditions
├─ Optimization: Already optimal
└─ Expected: >90% of queries with proper indexes

INDEX SCAN
├─ Meaning: Scanning entire index sequentially
├─ Cost: MEDIUM
├─ When used: All rows needed or no range predicate
├─ Optimization: Add filter (WHERE clause)
└─ Difference from scan: Uses index instead of table

NESTED LOOP JOIN
├─ Meaning: For each outer row, find matching inner row
├─ Cost: LOW for small result sets, HIGH for large
├─ Example: Outer loop 1000 rows, inner 100 rows = 100K lookups
├─ When used: Small result sets, good index on inner table
└─ Optimization: Use for small result sets only

HASH JOIN
├─ Meaning: Build hash table of inner, probe with outer
├─ Cost: MEDIUM, memory intensive
├─ When used: No suitable index, equi-join
├─ Benefit: Good for large result sets
├─ Memory: Can cause spills if insufficient
└─ Optimization: Increase memory, optimize query

MERGE JOIN
├─ Meaning: Requires sorted input, merge sorted streams
├─ Cost: LOW for pre-sorted input
├─ When used: Both inputs sorted, equi-join
├─ Benefit: Fast, no memory needed
└─ Optimization: Add index matching sort order

SORT
├─ Meaning: Sort data by specified columns
├─ Cost: HIGH for large datasets
├─ When used: ORDER BY, GROUP BY, DISTINCT
├─ Memory: Can spill to tempdb
└─ Optimization: Add index on sort column

AGGREGATE
├─ Meaning: GROUP BY, COUNT, SUM, AVG, etc.
├─ Types: Stream Aggregate (on sorted data) vs Hash Aggregate
├─ Stream Aggregate: LOW cost, requires sorted input
├─ Hash Aggregate: Medium cost, no sort needed
└─ Optimization: Add index matching GROUP BY columns

FILTER
├─ Meaning: Apply additional filtering after operation
├─ Cost: Proportion to rows filtered
├─ When used: Additional WHERE conditions
└─ Optimization: Push filter earlier in plan

COMPUTE SCALAR
├─ Meaning: Compute expression for each row
├─ Cost: LOW typically
├─ When used: Computed columns, CASE expressions
└─ Optimization: Unavoidable usually
```

**Execution Plan Properties to Check:**

```
1. Number of rows:
   - Estimated: What optimizer thought
   - Actual: What really happened
   - If greatly different: Statistics outdated
   
2. Operator cost:
   - % of total: Higher = focus here
   - Should be balanced across operators
   
3. Warnings:
   - Red flags (font color change)
   - Examples: Sort/join spill, implicit conversion
   
4. Memory grant:
   - Requested vs Used
   - If used << requested: Overestimate
   - If used >> requested: Spill to disk
   
5. Parallelism:
   - CXPACKET operators
   - Is parallelism helping or hurting?
   
6. Type of scan:
   - Table scan vs Index seek
   - Is index being used optimally?
```

**Lab Exercise 3.1: Execution Plan Analysis**

```
SCENARIO: Analyze execution plan for Orders query

STEPS:
1. Enable "Include Actual Execution Plan" in SSMS
2. Run: SELECT * FROM dbo.Orders WHERE CustomerID = 1 ORDER BY OrderDate DESC
3. Examine execution plan:
   - How many operators?
   - Is there a table scan or index seek?
   - What's the biggest cost?
4. Run: SELECT * FROM dbo.Orders ORDER BY OrderDate DESC LIMIT 1000
5. Compare plans
6. Note differences
7. Recommend optimizations
```

---

### 10:00 AM - 11:00 AM | Part B: Query Analysis and Tuning Workflow

#### The Query Tuning Process

```sql
-- SQL Script: Systematic Query Tuning Workflow

-- STEP 1: BASELINE - Measure current performance
SET STATISTICS TIME ON;
SET STATISTICS IO ON;

SELECT 
    c.CustomerName,
    o.OrderID,
    o.OrderDate,
    o.TotalAmount
FROM dbo.Orders o
JOIN dbo.Customers c ON o.CustomerID = c.CustomerID
WHERE o.OrderDate >= '2024-01-01'
  AND o.TotalAmount > 100
ORDER BY o.OrderDate DESC;

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;

-- Results show:
-- CPU time = XX ms,  elapsed time = YY ms
-- Table 'Orders' scan count, logical reads, physical reads
-- Table 'Customers' scan count, logical reads, physical reads

-- STEP 2: ANALYZE EXECUTION PLAN
-- Issue: Table scan on Orders?
--        Join using nested loop instead of hash?
--        Missing index on CustomerID?

-- STEP 3: IMPLEMENT FIX
-- Solution: Create index on (OrderDate, TotalAmount)

CREATE NONCLUSTERED INDEX IX_Orders_DateAmount
ON dbo.Orders (OrderDate, TotalAmount)
INCLUDE (CustomerID, OrderID, TotalAmount);

-- STEP 4: CLEAR PLAN CACHE
-- Force recompilation with new index
DBCC FREEPROCCACHE;

-- STEP 5: RE-BASELINE - Measure after fix
SET STATISTICS TIME ON;
SET STATISTICS IO ON;

SELECT 
    c.CustomerName,
    o.OrderID,
    o.OrderDate,
    o.TotalAmount
FROM dbo.Orders o
JOIN dbo.Customers c ON o.CustomerID = c.CustomerID
WHERE o.OrderDate >= '2024-01-01'
  AND o.TotalAmount > 100
ORDER BY o.OrderDate DESC;

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;

-- Results show (expected improvements):
-- CPU time reduced: XX ms → YY ms
-- Logical reads reduced
-- Table scan changed to index seek

-- STEP 6: COMPARE - Document improvement
-- Before: 250 ms, 1000 logical reads
-- After: 50 ms, 50 logical reads
-- Improvement: 80% faster, 95% fewer reads

-- STEP 7: MONITOR - Watch for regression
-- Add to monitoring: Track execution time daily
-- Alert if avg time increases by > 20%
```

#### Query Tuning Best Practices

**DO's:**

```sql
-- ✓ Use parameterization to improve plan reuse
DECLARE @CustomerID INT = 1;
SELECT * FROM Orders WHERE CustomerID = @CustomerID;
-- Plan can be reused for different CustomerID values

-- ✓ Use appropriate data types (match column type)
DECLARE @OrderID INT = 1;
SELECT * FROM Orders WHERE OrderID = @OrderID;
-- Don't use: WHERE OrderID = '1' (string to int conversion)

-- ✓ Test in staging first
-- Always test performance fixes before production

-- ✓ Test with realistic data volumes
-- Small data set might behave differently than production

-- ✓ Measure before and after
-- Need baseline to show improvement

-- ✓ Focus on most expensive queries
-- TOP 10 expensive queries often account for 80% of CPU time

-- ✓ Consider write impact of indexes
-- New index improves SELECT but slows INSERT/UPDATE/DELETE
```

**DON'Ts:**

```sql
-- ✗ Don't modify system catalog directly
-- Never do: UPDATE sys.syscolumns ...

-- ✗ Don't force bad plans
-- If plan forced, future statistics improvements are ignored

-- ✗ Don't optimize single query without considering system
-- One slow query fix might break another query

-- ✗ Don't use SELECT * in production
-- Retrieve only needed columns

-- ✗ Don't add unnecessary ORDER BY
-- Without ORDER BY, no guarantee of row order

-- ✗ Don't ignore parameter sniffing
-- First execution parameter values affect plan

-- ✗ Don't create overlapping indexes
-- Wasted space, maintenance overhead

-- ✗ Don't assume query needs index before analyzing
-- Query might be fast enough, memory wasted on unused index
```

**Query Tuning Checklist:**

```
□ Run SET STATISTICS TIME/IO before
□ Check execution plan (scan vs seek)
□ Examine estimated vs actual row counts
□ Look for table scans (candidates for indexes)
□ Look for warnings (spills, conversions)
□ Consider index on WHERE clause columns
□ Consider covering index for frequent queries
□ Run after fix and compare times
□ Check for parameter sniffing issues
□ Verify no write overhead increase
□ Document before/after metrics
□ Monitor in production for regression
□ Update documentation/runbooks
```

---

## Session 2: Index Design and Optimization

### 11:00 AM - 12:00 PM | Part A: Index Fundamentals

#### Types of Indexes

```sql
-- SQL Script: Index Types and Creation

-- 1. CLUSTERED INDEX
-- - Defines physical order of table
-- - One per table only
-- - Usually on primary key
-- - Mandatory for efficient querying

CREATE CLUSTERED INDEX PK_Orders
ON dbo.Orders (OrderID);  -- Primary key

-- 2. NONCLUSTERED INDEX
-- - Additional lookup path
-- - Multiple per table (up to 999)
-- - Point back to clustered index

CREATE NONCLUSTERED INDEX IX_Orders_CustomerID
ON dbo.Orders (CustomerID);

-- 3. UNIQUE INDEX
-- - Enforces uniqueness of column values
-- - Can create unique constraint with index

CREATE UNIQUE NONCLUSTERED INDEX UIX_Orders_RefNo
ON dbo.Orders (ReferenceNumber);

-- 4. COVERING INDEX (with INCLUDE clause)
-- - Includes columns needed by query
-- - Query can be satisfied from index only (no table access)
-- - Faster queries but larger index

CREATE NONCLUSTERED INDEX IX_Orders_DateAmount
ON dbo.Orders (OrderDate, TotalAmount)
INCLUDE (CustomerID, OrderID);  -- INCLUDE columns

-- 5. FILTERED INDEX
-- - Only indexes subset of rows (WHERE condition)
-- - Smaller index, faster maintenance
-- - Good for queries that filter by specific values

CREATE NONCLUSTERED INDEX IX_Orders_PendingStatus
ON dbo.Orders (OrderID)
WHERE OrderStatus = 'Pending';  -- Filter condition

-- 6. COLUMNSTORE INDEX
-- - Column-oriented storage
-- - Excellent for analytics/data warehouse
-- - Poor for OLTP (too much memory for small result sets)

CREATE NONCLUSTERED COLUMNSTORE INDEX IX_Orders_ColumnStore
ON dbo.Orders (OrderDate, TotalAmount, Quantity);

-- Query execution improvements:
SELECT 
    OrderDate,
    SUM(TotalAmount) AS DailyTotal,
    COUNT(*) AS OrderCount
FROM dbo.Orders
GROUP BY OrderDate;
-- Without columnstore: 1000 ms
-- With columnstore: 50 ms (20x faster)
```

#### Index Selection Criteria

**When to Create an Index:**

```
Need to balance:
- Query performance improvement
- Index maintenance cost (inserts/updates/deletes)
- Storage space used
- Memory impact

CREATE INDEX IF:
✓ Query time reduced by > 50%
✓ Query is run frequently
✓ Improvement worth maintenance cost
✓ Storage space available

DON'T CREATE INDEX IF:
✗ Query rarely run
✗ Small improvement (< 10%)
✗ High update overhead (slow inserts)
✗ Storage space constrained
```

**Index Design Principles:**

```sql
-- PRINCIPLE 1: Index on WHERE clause columns
-- Query: WHERE OrderDate >= '2024-01-01' AND CustomerID = 5
-- Index: (OrderDate, CustomerID)

CREATE NONCLUSTERED INDEX IX_Orders_DateCustomer
ON dbo.Orders (OrderDate, CustomerID);

-- PRINCIPLE 2: Column order matters
-- Most selective column first? Or most restrictive?
-- Best practice: Column order based on query pattern

-- Query pattern: mostly filter by OrderDate first
CREATE NONCLUSTERED INDEX IX_Orders_DateCustomer
ON dbo.Orders (OrderDate, CustomerID);  -- OrderDate first

-- PRINCIPLE 3: Cover SELECT columns
-- If query needs: OrderDate, CustomerID, TotalAmount
-- And WHERE uses: OrderDate, CustomerID
-- Add TotalAmount to INCLUDE

CREATE NONCLUSTERED INDEX IX_Orders_DateCustomer_Amt
ON dbo.Orders (OrderDate, CustomerID)
INCLUDE (TotalAmount);  -- No table access needed

-- PRINCIPLE 4: Balance read vs write
-- Heavy read queries: Many indexes okay
-- Heavy write workload: Few indexes (slow deletes/updates)

-- PRINCIPLE 5: Avoid redundant indexes
-- If you have: (OrderDate, CustomerID)
-- Don't create: (OrderDate) - redundant, first two columns cover it

-- PRINCIPLE 6: Monitor unused indexes
SELECT 
    OBJECT_NAME(i.object_id) AS [Table],
    i.name AS [Index],
    ius.user_seeks,
    ius.user_scans,
    ius.user_lookups,
    ius.user_updates
FROM sys.indexes i
LEFT JOIN sys.dm_db_index_usage_stats ius 
    ON i.object_id = ius.object_id 
    AND i.index_id = ius.index_id
WHERE ius.user_seeks + ius.user_scans + ius.user_lookups = 0
  AND i.name IS NOT NULL;  -- Unused indexes

-- PRINCIPLE 7: Regular index maintenance
-- Rebuild if fragmentation > 30%
-- Reorganize if fragmentation 10-30%
-- Ignore if fragmentation < 10%

ALTER INDEX IX_Orders_DateCustomer ON dbo.Orders REBUILD;
```

**Lab Exercise 3.2: Missing Index Identification**

```
SCENARIO: Identify and create beneficial indexes

STEPS:
1. Query sys.dm_db_missing_index_details
2. Calculate improvement measure for each index
3. For top 5 missing indexes:
   - Understand which query they'll help
   - Estimate improvement
   - Create index
4. Rerun query and measure improvement
5. Document before/after metrics
6. Monitor index usage for 1 week
7. Keep or drop based on usage
```

---

### 12:00 PM - 1:00 PM | Lunch Break

---

## Session 3: Statistics and Cardinality Estimation

### 1:00 PM - 2:00 PM | Part A: Statistics Fundamentals

#### What Are Statistics?

Statistics are metadata about data distribution in columns.

```
Example: Customer table with 1 million rows

Without statistics:
- SQL Server doesn't know data distribution
- Estimates uniformly: 1M / 100 possible values = 10K rows each
- Actual: Value 'USA' has 500K rows, 'Canada' has 100K rows
- Wrong estimate → Wrong plan

With statistics:
- Tracks actual distribution
- 'USA' = 500K, 'Canada' = 100K, 'Mexico' = 350K, etc.
- Better estimate → Better plan
```

**Creating Statistics:**

```sql
-- Automatic Statistics Creation
-- Default: ON, statistics created on indexed columns

-- Manual Statistics Creation
CREATE STATISTICS stat_CustomerCountry
ON dbo.Customers (Country);

-- For multiple columns (composite)
CREATE STATISTICS stat_OrderDateAmount
ON dbo.Orders (OrderDate, TotalAmount);

-- View existing statistics
SELECT 
    s.name AS [Statistic Name],
    c.name AS [Column Name],
    STATS_DATE(st.object_id, st.stats_id) AS [Last Updated]
FROM sys.stats s
JOIN sys.stat_headers sh ON s.object_id = sh.object_id AND s.stats_id = sh.stats_id
JOIN sys.columns c ON s.object_id = c.object_id AND s.stats_id = c.column_id
WHERE s.object_id = OBJECT_ID('dbo.Orders')
ORDER BY s.name;

-- Update Statistics
UPDATE STATISTICS dbo.Orders;  -- All statistics on table
UPDATE STATISTICS dbo.Orders (stat_OrderDateAmount);  -- Specific statistic

-- Check statistic details
DBCC SHOW_STATISTICS ('dbo.Orders', 'stat_OrderDateAmount');
-- Output shows histogram of value distribution
```

**Statistics Aging:**

```
When do statistics get outdated?

After bulk load:
- 1 million rows inserted
- Statistics still think there's 100K rows
- Estimates way off
- Solution: Manually update statistics or rebuild index

On changing data:
- Customer preferences change seasonally
- January: 90% orders for winter gear
- July: 90% orders for summer gear
- January statistics used in July = wrong plan
- Solution: Update statistics regularly

Update triggers (automatic):
- Table < 500 rows: Update after any change
- Table 500-10K rows: Update after ~10% change
- Table > 10K rows: Update after 500 + (table size * 10%) changes

Example: Table with 100K rows
- Auto-update threshold = 500 + (100K * 0.1) = 10,500 rows modified
```

#### Cardinality Estimation

Cardinality = number of rows returned

Cardinality Estimator (CE) accuracy affects query plan quality.

```sql
-- SQL Script: Cardinality Estimation Examples

-- Example 1: Simple filter
SELECT * FROM Orders WHERE OrderDate >= '2024-01-01';

-- Estimate: Based on statistics histogram
-- If histogram shows 25% of orders after 2024-01-01
-- Estimate: 1,000,000 * 0.25 = 250,000 rows

-- Example 2: Multiple filters
SELECT * FROM Orders 
WHERE OrderDate >= '2024-01-01'
  AND TotalAmount > 100;

-- Estimate: Combines distributions
-- If 25% after date AND 60% > 100
-- Estimate: 1,000,000 * 0.25 * 0.60 = 150,000 rows
-- (Assumes independence - may not be true)

-- Example 3: Join estimation
SELECT o.OrderID, c.CustomerName
FROM Orders o
JOIN Customers c ON o.CustomerID = c.CustomerID
WHERE o.OrderDate >= '2024-01-01';

-- Estimate:
-- Orders matching date: 250,000
-- Each joins to 1 Customer (1:1 relationship)
-- Estimate: 250,000 rows

-- Check estimated vs actual
SET STATISTICS IO ON;
SELECT * FROM Orders WHERE OrderDate >= '2024-01-01';
SET STATISTICS IO OFF;

-- Message shows:
-- Estimated number of rows: 250000
-- Actual rows returned: 250000 (match = good)
-- Or: Actual rows: 100000 (mismatch = problem)
```

**Cardinality Estimation Versions:**

```
SQL Server 2025 defaults to CE 160 (latest)

Available versions:
- CE 70 (SQL Server 2000 style)
- CE 80 (SQL Server 2008 style)
- CE 120 (SQL Server 2014 style)
- CE 130 (SQL Server 2016+)
- CE 140 (SQL Server 2017+)
- CE 150 (SQL Server 2019+)
- CE 160 (SQL Server 2025+)

Features by version:
- CE 130: Adaptive join selectivity, multi-column cardinality
- CE 140: New selectivity assumptions
- CE 150: Improved memory grant feedback
- CE 160: Advanced ML-based estimation

Set database compatibility level to use newer CE:
ALTER DATABASE OrderDB SET COMPATIBILITY_LEVEL = 160;
```

---

### 2:00 PM - 3:00 PM | Part B: Intelligent Query Processing

Intelligent Query Processing (IQP) is SQL Server 2025 feature for automatic optimization.

```sql
-- SQL Script: IQP Features

-- FEATURE 1: Memory Grant Feedback
-- Problem: Query requests 100 MB memory, needs only 50 MB
--          Or: Requests 50 MB, needs 200 MB (spill to disk)
-- Solution: IQP learns and adjusts
-- Automatic: No configuration needed
-- Benefit: Fewer spills, better memory usage

SELECT 
    CustomerID,
    SUM(TotalAmount) AS Total,
    COUNT(*) AS OrderCount
FROM Orders
GROUP BY CustomerID
HAVING COUNT(*) > 10;

-- IQP monitors this query:
-- First run: Requests 50 MB, uses 100 MB (spill)
-- Second run: Requests 110 MB, no spill (fixed)
-- Third+ runs: Optimal memory granted

-- FEATURE 2: Adaptive Join Selection
-- Problem: At compile time, optimizer doesn't know
--          if 10 or 1,000,000 rows will match filter
-- Solution: Deferred join decision
-- Optimizer builds plan to adapt at runtime
-- Benefit: One plan adapts to multiple scenarios

SELECT o.*, c.CustomerName
FROM Orders o
JOIN Customers c ON o.CustomerID = c.CustomerID
WHERE o.OrderDate >= @DateFilter;

-- First execution (@DateFilter = '2024-01-01'):
-- Returns 1,000 rows, uses nested loop (good)
-- Plan adapted to this result set size

-- Second execution (@DateFilter = '2020-01-01'):
-- Returns 500,000 rows, adapts to hash join (better)
-- Plan learned and adapted

-- FEATURE 3: Batch Mode on Rowstore
-- Problem: Columnstore indexes are fast for analytics,
--          but rowstore tables used in OLTP
-- Solution: Execute rowstore queries in batch mode
-- Benefit: Faster analytics on rowstore tables
-- Automatic: Applies when beneficial

SELECT 
    OrderDate,
    SUM(TotalAmount) AS DailyTotal,
    COUNT(*) AS OrderCount
FROM Orders
GROUP BY OrderDate;

-- Executes in batch mode (vectorized):
-- 1000x faster than row mode
-- Without needing columnstore index

-- Enable IQP features (enabled by default in CE 160)
-- Compatibility level 160 auto-enables IQP
```

**Lab Exercise 3.3: Statistics and Query Analysis**

```
SCENARIO: Analyze statistics impact on query performance

STEPS:
1. Create test table with sample data
2. Create statistics on key columns
3. Run query and check execution plan
4. Update statistics
5. Run same query, compare plans
6. Deliberately create stale statistics
7. Run query with stale stats
8. Observe performance degradation
9. Update statistics
10. Confirm performance improvement
```

---

## Session 4: Maintenance Automation and Monitoring

### 3:00 PM - 4:00 PM | Part A: Maintenance Automation

#### SQL Server Agent Jobs

SQL Server Agent executes scheduled tasks.

```sql
-- SQL Script: Create Maintenance Jobs

-- ENABLE SQL Server Agent (if not already)
-- SQL Server Configuration Manager > SQL Server Services
-- SQL Server Agent > Start Service

-- Check if Agent is running
SELECT 
    status_desc,
    startup_type_desc
FROM sys.dm_server_services
WHERE service_name LIKE '%Agent%';

-- JOB 1: Index Maintenance
USE msdb;

EXEC sp_add_job
    @job_name = 'IndexMaintenance',
    @enabled = 1,
    @description = 'Daily index maintenance (rebuild/reorganize)';

-- Add job step
EXEC sp_add_jobstep
    @job_name = 'IndexMaintenance',
    @step_name = 'Rebuild Fragmented Indexes',
    @subsystem = 'TSQL',
    @command = N'
        USE [SampleDB];
        
        -- Rebuild indexes with fragmentation > 30%
        DECLARE @TableName NVARCHAR(128);
        DECLARE @IndexName NVARCHAR(128);
        
        DECLARE index_cursor CURSOR FOR
        SELECT 
            OBJECT_NAME(ips.object_id),
            i.name
        FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, ''LIMITED'') ips
        JOIN sys.indexes i ON ips.object_id = i.object_id AND ips.index_id = i.index_id
        WHERE ips.avg_fragmentation_in_percent > 30
          AND ips.page_count > 1000;  -- Only large indexes
        
        OPEN index_cursor;
        FETCH NEXT FROM index_cursor INTO @TableName, @IndexName;
        
        WHILE @@FETCH_STATUS = 0
        BEGIN
            PRINT ''Rebuilding '' + @TableName + ''.'' + @IndexName;
            EXEC (''ALTER INDEX ['' + @IndexName + ''] ON ['' + @TableName + ''] REBUILD'');
            FETCH NEXT FROM index_cursor INTO @TableName, @IndexName;
        END
        
        CLOSE index_cursor;
        DEALLOCATE index_cursor;
    ',
    @retry_attempts = 2,
    @retry_interval = 5;

-- Add schedule (daily at 2 AM)
EXEC sp_add_schedule
    @schedule_name = 'DailyMaintenance',
    @freq_type = 4,  -- Daily
    @freq_interval = 1,
    @active_start_time = 020000;  -- 02:00 AM

-- Attach schedule to job
EXEC sp_attach_schedule
    @job_name = 'IndexMaintenance',
    @schedule_name = 'DailyMaintenance';

-- Enable job
EXEC sp_update_job
    @job_name = 'IndexMaintenance',
    @enabled = 1;

-- JOB 2: Update Statistics
EXEC sp_add_job
    @job_name = 'UpdateStatistics',
    @enabled = 1,
    @description = 'Daily statistics update';

EXEC sp_add_jobstep
    @job_name = 'UpdateStatistics',
    @step_name = 'Update All Statistics',
    @subsystem = 'TSQL',
    @command = N'
        USE [SampleDB];
        EXEC sp_updatestats;
    ';

EXEC sp_add_schedule
    @schedule_name = 'DailyStats',
    @freq_type = 4,
    @freq_interval = 1,
    @active_start_time = 030000;  -- 03:00 AM

EXEC sp_attach_schedule
    @job_name = 'UpdateStatistics',
    @schedule_name = 'DailyStats';

-- JOB 3: Integrity Check
EXEC sp_add_job
    @job_name = 'IntegrityCheck',
    @enabled = 1,
    @description = 'Weekly DBCC CHECKDB';

EXEC sp_add_jobstep
    @job_name = 'IntegrityCheck',
    @step_name = 'Run DBCC CHECKDB',
    @subsystem = 'TSQL',
    @command = N'
        DBCC CHECKDB ([SampleDB]) WITH NO_INFOMSGS;
    ';

EXEC sp_add_schedule
    @schedule_name = 'WeeklySunday',
    @freq_type = 8,  -- Weekly
    @freq_interval = 1,  -- Sunday
    @active_start_time = 040000;  -- 04:00 AM

EXEC sp_attach_schedule
    @job_name = 'IntegrityCheck',
    @schedule_name = 'WeeklySunday';

-- View job status
SELECT 
    j.name AS [Job Name],
    j.enabled,
    jh.run_date,
    jh.run_time,
    jh.run_duration,
    CASE jh.run_status
        WHEN 0 THEN 'Failed'
        WHEN 1 THEN 'Succeeded'
        WHEN 3 THEN 'Cancelled'
    END AS [Status]
FROM msdb.dbo.sysjobs j
LEFT JOIN msdb.dbo.sysjobhistory jh ON j.job_id = jh.job_id
WHERE j.name IN ('IndexMaintenance', 'UpdateStatistics', 'IntegrityCheck')
ORDER BY jh.run_date DESC;
```

#### Automated Maintenance Scripts

```sql
-- SQL Script: Maintenance Stored Procedures

-- PROCEDURE 1: Automated Index Maintenance
CREATE OR ALTER PROCEDURE sp_MaintainIndexes
    @RebuildThreshold INT = 30,  -- Fragmentation %
    @ReorganizeThreshold INT = 10,  -- Fragmentation %
    @MinPageCount INT = 1000  -- Minimum pages to consider
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @TableName NVARCHAR(128);
    DECLARE @IndexName NVARCHAR(128);
    DECLARE @Fragmentation NUMERIC(5,2);
    
    PRINT 'Starting index maintenance...'
    PRINT 'Rebuild threshold: ' + CAST(@RebuildThreshold AS VARCHAR(3)) + '%'
    PRINT 'Reorganize threshold: ' + CAST(@ReorganizeThreshold AS VARCHAR(3)) + '%'
    
    -- Cursor for fragmented indexes
    DECLARE index_cursor CURSOR FOR
    SELECT 
        OBJECT_NAME(ips.object_id) AS TableName,
        i.name AS IndexName,
        ips.avg_fragmentation_in_percent
    FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') ips
    JOIN sys.indexes i ON ips.object_id = i.object_id AND ips.index_id = i.index_id
    WHERE ips.avg_fragmentation_in_percent > @ReorganizeThreshold
      AND ips.page_count > @MinPageCount
      AND i.name IS NOT NULL
      AND i.index_id > 0;  -- Exclude heaps
    
    OPEN index_cursor;
    FETCH NEXT FROM index_cursor INTO @TableName, @IndexName, @Fragmentation;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF @Fragmentation > @RebuildThreshold
        BEGIN
            PRINT 'Rebuilding ' + @TableName + '.' + @IndexName + ' (Frag: ' + CAST(@Fragmentation AS VARCHAR(5)) + '%)'
            EXEC ('ALTER INDEX [' + @IndexName + '] ON [' + @TableName + '] REBUILD');
        END
        ELSE
        BEGIN
            PRINT 'Reorganizing ' + @TableName + '.' + @IndexName + ' (Frag: ' + CAST(@Fragmentation AS VARCHAR(5)) + '%)'
            EXEC ('ALTER INDEX [' + @IndexName + '] ON [' + @TableName + '] REORGANIZE');
        END
        
        FETCH NEXT FROM index_cursor INTO @TableName, @IndexName, @Fragmentation;
    END
    
    CLOSE index_cursor;
    DEALLOCATE index_cursor;
    
    PRINT 'Index maintenance complete.'
END;

-- Usage:
-- EXEC sp_MaintainIndexes;

-- PROCEDURE 2: Automated Statistics Update
CREATE OR ALTER PROCEDURE sp_UpdateAllStatistics
    @FullScanPercent INT = 100  -- 100 = full scan, 50 = sample
AS
BEGIN
    SET NOCOUNT ON;
    
    PRINT 'Updating statistics with ' + CAST(@FullScanPercent AS VARCHAR(3)) + '% scan...'
    
    IF @FullScanPercent = 100
        EXEC sp_updatestats;  -- Full scan
    ELSE
    BEGIN
        -- Sample-based update
        DECLARE @TableName NVARCHAR(128);
        DECLARE @Stats CURSOR;
        
        SET @Stats = CURSOR FOR
        SELECT DISTINCT OBJECT_NAME(object_id)
        FROM sys.stats
        WHERE object_id > 0;
        
        OPEN @Stats;
        FETCH NEXT FROM @Stats INTO @TableName;
        
        WHILE @@FETCH_STATUS = 0
        BEGIN
            EXEC ('UPDATE STATISTICS ' + @TableName + ' WITH SAMPLE ' + CAST(@FullScanPercent AS VARCHAR(3)) + ' PERCENT');
            FETCH NEXT FROM @Stats INTO @TableName;
        END
        
        CLOSE @Stats;
        DEALLOCATE @Stats;
    END
    
    PRINT 'Statistics update complete.'
END;

-- Usage:
-- EXEC sp_UpdateAllStatistics @FullScanPercent = 100;
```

---

### 4:00 PM - 5:00 PM | Part B: Monitoring and Alerting

#### Performance Monitoring Strategy

```sql
-- SQL Script: Automated Performance Monitoring

-- Create monitoring table
USE SampleDB;

CREATE TABLE dbo.PerformanceMonitor
(
    MonitorID INT PRIMARY KEY IDENTITY(1,1),
    MonitorTime DATETIME2 DEFAULT GETDATE(),
    MetricName VARCHAR(100),
    MetricValue NUMERIC(15,2),
    Threshold NUMERIC(15,2),
    IsAlert BIT
);

-- Create monitoring procedure
CREATE OR ALTER PROCEDURE sp_CapturePerformanceMetrics
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @CurrentTime DATETIME2 = GETDATE();
    
    -- Capture CPU
    INSERT INTO dbo.PerformanceMonitor (MetricName, MetricValue, Threshold, IsAlert)
    SELECT 
        'CPU % Processor Time',
        (SELECT cntr_value FROM sys.dm_os_performance_counters 
         WHERE object_name LIKE '%Processor%' 
         AND counter_name = '% Processor Time'
         AND instance_name = '_Total') / 100.0,
        80,  -- Alert if > 80%
        CASE WHEN (SELECT cntr_value FROM sys.dm_os_performance_counters 
                  WHERE object_name LIKE '%Processor%' 
                  AND counter_name = '% Processor Time'
                  AND instance_name = '_Total') / 100.0 > 80 THEN 1 ELSE 0 END;
    
    -- Capture Free Memory
    INSERT INTO dbo.PerformanceMonitor (MetricName, MetricValue, Threshold, IsAlert)
    SELECT 
        'Free Memory (MB)',
        (SELECT cntr_value / 1024.0 FROM sys.dm_os_performance_counters 
         WHERE counter_name = 'Free Memory (KB)'),
        512,  -- Alert if < 512 MB
        CASE WHEN (SELECT cntr_value / 1024.0 FROM sys.dm_os_performance_counters 
                  WHERE counter_name = 'Free Memory (KB)') < 512 THEN 1 ELSE 0 END;
    
    -- Capture Page Life Expectancy
    INSERT INTO dbo.PerformanceMonitor (MetricName, MetricValue, Threshold, IsAlert)
    SELECT 
        'Page Life Expectancy',
        (SELECT cntr_value FROM sys.dm_os_performance_counters 
         WHERE counter_name = 'Page life expectancy'),
        300,  -- Alert if < 300 sec
        CASE WHEN (SELECT cntr_value FROM sys.dm_os_performance_counters 
                  WHERE counter_name = 'Page life expectancy') < 300 THEN 1 ELSE 0 END;
    
    -- Log blocking
    INSERT INTO dbo.PerformanceMonitor (MetricName, MetricValue, Threshold, IsAlert)
    SELECT 
        'Blocking Sessions Count',
        COUNT(*),
        5,  -- Alert if > 5 blocked sessions
        CASE WHEN COUNT(*) > 5 THEN 1 ELSE 0 END
    FROM sys.dm_exec_requests
    WHERE blocking_session_id > 0;
    
    PRINT 'Performance metrics captured at ' + CONVERT(VARCHAR, @CurrentTime, 121);
END;

-- Execute monitoring
EXEC sp_CapturePerformanceMetrics;

-- View captured metrics
SELECT 
    MonitorTime,
    MetricName,
    MetricValue,
    Threshold,
    CASE IsAlert WHEN 1 THEN '*** ALERT ***' ELSE 'OK' END AS [Status]
FROM dbo.PerformanceMonitor
ORDER BY MonitorTime DESC, MetricName;

-- View triggered alerts
SELECT 
    MonitorTime,
    MetricName,
    MetricValue,
    Threshold
FROM dbo.PerformanceMonitor
WHERE IsAlert = 1
ORDER BY MonitorTime DESC;
```

#### Alert Best Practices

```
DO's:

✓ Monitor key metrics (CPU, Memory, I/O, Blocking)
✓ Set thresholds based on baseline
✓ Alert EARLY (at 70% of critical level)
✓ Escalate based on duration (single spike vs sustained)
✓ Regular alert testing
✓ Document alert runbooks

DON'Ts:

✗ Alert on every metric change
✗ Alert thresholds too sensitive (too many false positives)
✗ Alert thresholds too loose (miss real problems)
✗ Ignore alerts
✗ Alert without action plan
✗ Alert without clear escalation path
```

---

## Hands-On Labs Summary

### Lab 1: Execution Plan Analysis and Optimization
- Create slow-running queries
- Analyze execution plans
- Identify optimization opportunities
- Implement fixes (indexes, rewrites)
- Measure improvement

### Lab 2: Index Design and Creation
- Identify missing indexes
- Create beneficial indexes
- Monitor index usage
- Remove unused indexes
- Document index strategy

### Lab 3: Statistics and Cardinality
- Create and update statistics
- Analyze cardinality estimates
- Identify stale statistics
- Update statistics
- Measure performance impact

### Lab 4: Query Store Analysis
- Enable Query Store
- Capture query history
- Identify plan regressions
- Force alternative plans
- Monitor for improvements

### Lab 5: Maintenance Automation
- Create SQL Agent jobs
- Schedule index maintenance
- Schedule statistics updates
- Schedule integrity checks
- Monitor job execution

### Lab 6: Comprehensive Optimization Project
- Analyze slow application
- Identify top 5 slow queries
- Optimize each query (index or rewrite)
- Implement maintenance schedule
- Set up monitoring
- Document before/after metrics

---

## Summary

**Day 3 has covered:**
1. ✓ Execution plan analysis and interpretation
2. ✓ Query tuning workflow and best practices
3. ✓ Index design and selection criteria
4. ✓ Statistics and cardinality estimation
5. ✓ Intelligent Query Processing features
6. ✓ Maintenance job automation
7. ✓ Performance monitoring and alerting

**Key Takeaways:**
- Execution plans reveal optimization opportunities
- Systematic query tuning improves performance reliably
- Proper index design multiplies query performance
- Statistics accuracy is critical for good plans
- Automated maintenance prevents performance degradation
- Proactive monitoring catches issues before users notice

**Best Practices:**
- Analyze execution plans before changing code
- Test all optimizations in staging
- Implement maintenance jobs on production systems
- Monitor all optimizations for ongoing effectiveness
- Document all changes for future reference

---

## Additional Resources

- [Day 3 Codes.txt](./Day_3_Codes.txt) - All working SQL scripts
- [Day 3 Deep Dive.txt](./Day_3_Deep_Dive.txt) - Detailed technical explanations
- SQL Server Execution Plans Documentation: https://learn.microsoft.com/en-us/sql/relational-databases/query-processing-architecture
- Index Design Guide: https://learn.microsoft.com/en-us/sql/relational-databases/indexes/indexes
- Query Store Documentation: https://learn.microsoft.com/en-us/sql/relational-databases/performance/monitoring-performance-by-using-the-query-store
