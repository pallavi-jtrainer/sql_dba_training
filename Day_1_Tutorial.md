# SQL Server 2025 DBA Training - Day 1
## SQL Server Architecture, Administration, Security & Backup Recovery

**Duration:** 8 Hours (9:00 AM - 5:00 PM)  
**Target Audience:** SQL Professionals with SQL Knowledge  
**SQL Server Version:** SQL Server 2025  
**Training Focus:** Hands-on DBA Administration

---

## Table of Contents

1. [Pre-Training Setup](#pre-training-setup)
2. [Session 1: SQL Server 2025 Installation & Architecture (9:00 AM - 11:00 AM)](#session-1-sql-server-2025-installation--architecture)
3. [Session 2: Instance Configuration & Memory Management (11:00 AM - 1:00 PM)](#session-2-instance-configuration--memory-management)
4. [Session 3: Database Administration Fundamentals (1:00 PM - 3:00 PM)](#session-3-database-administration-fundamentals)
5. [Session 4: Authentication, Security & Backup Recovery (3:00 PM - 5:00 PM)](#session-4-authentication-security--backup-recovery)
6. [Hands-On Labs Summary](#hands-on-labs-summary)

---

## Pre-Training Setup

### System Requirements

Before starting the training, ensure your system meets these requirements:

**Hardware Requirements:**
- CPU: 4+ cores (8+ recommended for lab exercises)
- RAM: 16 GB minimum (32 GB recommended)
- Disk Space: 50 GB free (SSD recommended)
- Network: Stable internet connection

**Software Requirements:**
- Windows Server 2022 or Windows 11/10 Pro (Build 21H2+)
- .NET Framework 4.8 or higher
- PowerShell 5.1 or PowerShell 7.x

### Pre-Installation Verification

Run this PowerShell command to verify system readiness:

```powershell
# Verify Windows Version
[System.Environment]::OSVersion.VersionString

# Check RAM
(Get-WmiObject -Class Win32_ComputerSystem).TotalPhysicalMemory / 1GB

# Check Disk Space (C: drive)
(Get-Volume -DriveLetter C).SizeRemaining / 1GB

# Check PowerShell Version
$PSVersionTable.PSVersion

# Check .NET Framework
(Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full').Release
```

---

## Session 1: SQL Server 2025 Installation & Architecture

### 9:00 AM - 10:00 AM | Part A: Installation & Configuration

#### Step 1: Download SQL Server 2025

```powershell
# Create directory for SQL Server installation media
$SQLPath = "C:\SQLServer2025Media"
New-Item -ItemType Directory -Path $SQLPath -Force

# SQL Server 2025 Developer Edition Download URL
# Download from: https://www.microsoft.com/en-us/sql-server/sql-server-downloads
# Choose: SQL Server 2025 Developer Edition
```

#### Step 2: Prepare System for Installation

```powershell
# Run as Administrator
# Disable User Account Control temporarily
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -Value 0

# Restart is required - Run this after restart:
# Create system accounts needed for SQL Server

# Create SQL Server service account (optional - can use built-in account)
$password = ConvertTo-SecureString -AsPlainText -Force -String "P@ssw0rd123!"
New-LocalUser -Name "SQLServiceAccount" -Password $password -FullName "SQL Server Service Account" -Description "Service account for SQL Server 2025" -ErrorAction SilentlyContinue

Add-LocalGroupMember -Group "Administrators" -Member "SQLServiceAccount" -ErrorAction SilentlyContinue
```

#### Step 3: Execute SQL Server Installation

```
1. Extract SQL Server 2025 installation media
2. Run: setup.exe from the extracted folder
3. Follow Installation Wizard:
   
   a) Specify Installation Type:
      - Choose: "New SQL Server stand-alone installation"
   
   b) Product Key:
      - Leave blank for Developer Edition (free)
   
   c) License Terms:
      - Accept the license terms
   
   d) Global Rules:
      - All should pass (if not, address warnings)
   
   e) Microsoft Update:
      - Enable for security patches
   
   f) Install Setup Files:
      - Click "Install" to download setup support files
   
   g) Feature Selection:
      ✓ Database Engine Services
      ✓ SQL Server Replication
      ✓ Full-Text and Semantic Extractions for Search
      ✓ Machine Learning Services (R and Python)
      ✓ Analysis Services (SSAS) - Optional
      ✓ Reporting Services (SSRS) - Optional
      ✓ Integration Services (SSIS) - Optional
      ✓ SQL Server Management Tools - Basic
      ✓ SQL Server Management Tools - Complete
   
   h) Instance Configuration:
      - Instance Name: MSSQLSERVER (default)
      - Instance ID: MSSQLSERVER
      - Instance Root Directory: C:\Program Files\Microsoft SQL Server
   
   i) Server Configuration:
      - SQL Server Database Engine:
        * Service Account: SQLServiceAccount (or Network Service)
        * Startup Type: Automatic
      - SQL Server Agent:
        * Service Account: SQLServiceAccount (or Network Service)
        * Startup Type: Automatic
      - SQL Server Browser:
        * Service Account: NT AUTHORITY\LOCAL SERVICE
        * Startup Type: Disabled (unless needed)
   
   j) Database Engine Configuration:
      - Authentication Mode: Mixed Mode (SQL and Windows)
      - SQL Server Administrator Password: P@ssw0rd123!
      - Add Windows User: DOMAIN\YourUsername (as administrator)
   
   k) Analysis Services Configuration (if selected):
      - Server Mode: Tabular
      - Administrator: Your Windows Account
   
   l) Ready to Install:
      - Review configuration and proceed
   
   m) Installation Progress:
      - Wait for completion (15-30 minutes)
   
   n) Completion:
      - Click "Close" when finished
```

#### Step 4: Verify Installation

```powershell
# Verify SQL Server services are running
Get-Service -Name "MSSQL*" | Select-Object Status, DisplayName

# Expected Output:
# Status  DisplayName
# ------  -----------
# Running SQL Server (MSSQLSERVER)
# Stopped SQL Server Agent (MSSQLSERVER)
# Running SQL Server Browser

# Start SQL Server Agent
Start-Service -Name "SQLSERVERAGENT"
```

#### Step 5: Connect to SQL Server

```powershell
# Using SQL Server Management Studio (SSMS)
# Launch SSMS and connect with:
# - Server Name: localhost or (local)
# - Authentication: Windows Authentication
# - User Name: Your Windows Username

# Using PowerShell
$SQLServer = "localhost"
$SQLInstance = "MSSQLSERVER"

# Test connection
$connString = "Server=$SQLServer\$SQLInstance;Integrated Security=true;"
[System.Data.SqlClient.SqlConnection] $conn = New-Object System.Data.SqlClient.SqlConnection
$conn.ConnectionString = $connString
$conn.Open()
Write-Host "Connected successfully!"
$conn.Close()
```

---

### 10:00 AM - 11:00 AM | Part B: SQL Server Architecture Overview

#### Understanding SQLOS and Memory Architecture

SQLOS (SQL Server Operating System) is the abstraction layer that manages:
- Memory allocation and management
- Scheduling and CPU management
- I/O operations
- Synchronization primitives

**Key Memory Components:**

```sql
-- VIEW 1: Check total server memory configuration
EXEC sp_configure 'max server memory';

-- Result shows current max server memory in MB
-- Default: 2,147,483,647 MB (effectively unlimited)

-- VIEW 2: Check actual memory usage
SELECT 
    (SELECT cntr_value 
     FROM sys.dm_os_performance_counters 
     WHERE counter_name = 'Total Server Memory (KB)') / 1024 AS [Total Memory Used (MB)],
    (SELECT cntr_value 
     FROM sys.dm_os_performance_counters 
     WHERE counter_name = 'Target Server Memory (KB)') / 1024 AS [Target Memory (MB)],
    (SELECT cntr_value 
     FROM sys.dm_os_performance_counters 
     WHERE counter_name = 'Free Memory (KB)') / 1024 AS [Free Memory (MB)];

-- VIEW 3: Detailed memory breakdown
SELECT 
    type,
    SUM(pages_kb) / 1024 AS [Size (MB)]
FROM sys.dm_os_memory_clerks
GROUP BY type
ORDER BY SUM(pages_kb) DESC;
```

**Buffer Pool Overview:**

The Buffer Pool is the largest memory consumer in SQL Server.

```sql
-- Check Buffer Pool statistics
SELECT 
    SUM(pages_kb) AS [Buffer Pool Size (KB)],
    SUM(pages_kb) / 1024 AS [Buffer Pool Size (MB)],
    SUM(pages_in_use_kb) AS [Pages In Use (KB)],
    SUM(pages_in_use_kb) / 1024 AS [Pages In Use (MB)]
FROM sys.dm_os_memory_clerks
WHERE type = 'MEMORYCLERK_SQLBUFFERPOOL';

-- Cache Hit Ratio (should be > 99%)
SELECT 
    'Buffer Pool Hit Ratio' AS Metric,
    CAST(100.0 * (1 - (physical_reads / (physical_reads + buffer_cache_hit_ratio))) 
         AS NUMERIC(5,2)) AS [Hit Ratio %]
FROM sys.dm_os_performance_counters
WHERE counter_name = 'Buffer Manager'
  AND object_name LIKE '%Buffer Manager%';
```

#### Storage Engine Architecture

```sql
-- VIEW: Database files and location
SELECT 
    DB_NAME(database_id) AS [Database Name],
    file_id,
    name AS [Logical File Name],
    physical_name AS [Physical Path],
    size * 8 / 1024 AS [Size (MB)],
    max_size * 8 / 1024 AS [Max Size (MB)],
    CASE 
        WHEN is_percent_growth = 1 THEN CAST(growth AS VARCHAR) + ' %'
        ELSE CAST(growth * 8 / 1024 AS VARCHAR) + ' MB'
    END AS [Auto-grow Setting]
FROM sys.master_files
WHERE database_id > 4  -- Exclude system databases
ORDER BY DB_NAME(database_id), file_id;
```

#### Query Processing Pipeline

SQL Server processes queries through these stages:

```
1. Parsing (Syntax check)
2. Binding (Schema validation)
3. Optimization (Execution plan generation)
4. Compilation (Plan caching)
5. Execution (Plan execution)
```

**Check Compiled Plans Cache:**

```sql
-- VIEW: SQL Server Plan Cache
SELECT TOP 10
    usecounts,
    objtype,
    SUBSTRING(text, 1, 100) AS [Query Text]
FROM sys.dm_exec_cached_plans
CROSS APPLY sys.dm_exec_sql_text(plan_handle)
ORDER BY usecounts DESC;

-- VIEW: Cache Memory Usage
SELECT 
    SUM(pages_in_use_kb) / 1024 AS [Plan Cache Size (MB)]
FROM sys.dm_os_memory_clerks
WHERE type = 'MEMORYCLERK_SQLOPTIMIZER';
```

---

## Session 2: Instance Configuration & Memory Management

### 11:00 AM - 12:00 PM | Part A: Server Configuration

#### Configure Maximum Server Memory

```sql
-- IMPORTANT: Never set max server memory to 100% of physical RAM
-- Reserve 4GB for OS (minimum)

-- Step 1: Check current configuration
EXEC sp_configure 'max server memory';

-- Step 2: Set max server memory for a 16GB system
-- Formula: Total RAM - 4GB (for OS)
-- Example: 16GB - 4GB = 12GB = 12288 MB
EXEC sp_configure 'max server memory', 12288;

-- Step 3: Apply the configuration
RECONFIGURE;

-- Step 4: Verify the change
EXEC sp_configure 'max server memory';

-- Step 5: View memory usage after configuration
SELECT 
    'Max Server Memory' AS Setting,
    value_in_use AS [Value (MB)]
FROM sys.configurations
WHERE name = 'max server memory (MB)';
```

**Lab Exercise 1.1:**
```
1. Check your current max server memory
2. Calculate appropriate value for your system
3. Update the configuration
4. Query sys.dm_os_performance_counters to verify
```

#### Configure MAXDOP (Maximum Degree of Parallelism)

```sql
-- MAXDOP affects how many CPU cores SQL Server uses for a single query
-- Recommendation: Set to number of physical cores (not logical processors)
-- For most systems: 4-8 cores is optimal

-- Step 1: Check current MAXDOP
EXEC sp_configure 'max degree of parallelism';

-- Step 2: Set MAXDOP (example for 8-core system)
EXEC sp_configure 'max degree of parallelism', 8;
RECONFIGURE;

-- Step 3: Verify
SELECT 
    'Max Degree of Parallelism' AS Setting,
    value_in_use AS [Value]
FROM sys.configurations
WHERE name = 'max degree of parallelism';

-- Step 4: Check query parallelism stats
SELECT TOP 10
    creation_time,
    last_execution_time,
    execution_count,
    total_elapsed_time / execution_count / 1000000 AS [Avg Duration (seconds)],
    SUBSTRING(text, 1, 80) AS [Query]
FROM sys.dm_exec_query_stats
CROSS APPLY sys.dm_exec_sql_text(sql_handle)
WHERE total_logical_reads > 1000
ORDER BY total_elapsed_time DESC;
```

#### Configure Cost Threshold for Parallelism

```sql
-- This setting controls when SQL Server uses parallelism
-- Lower values = more queries use parallelism
-- Higher values = only expensive queries use parallelism
-- Recommended: 50-100 (not the default 5)

-- Step 1: Check current setting
EXEC sp_configure 'cost threshold for parallelism';

-- Step 2: Set to recommended value
EXEC sp_configure 'cost threshold for parallelism', 50;
RECONFIGURE;

-- Step 3: Verify
SELECT 
    'Cost Threshold for Parallelism' AS Setting,
    value_in_use AS [Value]
FROM sys.configurations
WHERE name = 'cost threshold for parallelism';
```

#### Configure TempDB for Optimal Performance

```sql
-- TempDB is used for sorting, joins, temporary tables, etc.
-- Poor TempDB configuration is a common bottleneck

-- Step 1: Check current TempDB configuration
SELECT 
    file_id,
    name,
    physical_name,
    size * 8 / 1024 AS [Size (MB)]
FROM sys.master_files
WHERE database_id = 2;  -- 2 = TempDB

-- Step 2: Check TempDB location (should be on fast disk, preferably SSD)
-- If not ideal, perform the following:
-- a) Stop SQL Server
-- b) Move TempDB files to better location
-- c) Update location in SQL Server Configuration Manager
-- d) Restart SQL Server

-- Step 3: Optimal TempDB configuration for multi-core system
-- 1. One data file per physical core
-- 2. All files same size
-- 3. Auto-grow all files equally

-- Example: Create additional TempDB files (if needed)
-- NOTE: This example assumes TempDB is on E: drive

-- Check current files
SELECT 
    file_id,
    name,
    physical_name,
    size * 8 / 1024 AS [Size (MB)]
FROM sys.master_files
WHERE database_id = 2
ORDER BY file_id;

-- For 8-core system, we want 8 TempDB data files
-- Procedure to add files: Use ALTER DATABASE tempdb
-- ALTER DATABASE tempdb ADD FILE (NAME='tempdev5', FILENAME='E:\MSSQL15.MSSQLSERVER\MSSQL\Data\tempdb_5.mdf', SIZE=100MB, FILEGROWTH=10MB);
-- Repeat for each additional file needed

-- Step 4: Configure TempDB auto-grow
-- All files should be same size and auto-grow equally
-- Set auto-grow to fixed value, not percentage
```

**Lab Exercise 1.2:**
```
1. Document current TempDB configuration
2. Identify number of physical cores
3. Plan TempDB file configuration
4. Add additional files if needed (practice, don't implement on production)
```

---

### 12:00 PM - 1:00 PM | Lunch Break

---

## Session 3: Database Administration Fundamentals

### 1:00 PM - 2:00 PM | Part A: Database Files and Filegroups

#### Understanding Database File Types

```sql
-- Every database consists of:
-- 1. Primary data file (.mdf) - required, contains system objects
-- 2. Secondary data file(s) (.ndf) - optional
-- 3. Transaction log file(s) (.ldf) - required

-- Step 1: Create a sample database with multiple files
CREATE DATABASE SampleDB
ON PRIMARY
(
    NAME = 'SampleDB_Primary',
    FILENAME = 'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\Data\SampleDB_Primary.mdf',
    SIZE = 100MB,
    FILEGROWTH = 10MB
),
FILEGROUP FG_Secondary
(
    NAME = 'SampleDB_Secondary1',
    FILENAME = 'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\Data\SampleDB_Secondary1.ndf',
    SIZE = 100MB,
    FILEGROWTH = 10MB
)
LOG ON
(
    NAME = 'SampleDB_Log',
    FILENAME = 'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\Data\SampleDB_Log.ldf',
    SIZE = 50MB,
    FILEGROWTH = 5MB
);

-- Step 2: Query database file information
SELECT 
    file_id,
    name,
    physical_name,
    type_desc,
    size * 8 / 1024 AS [Size (MB)],
    CASE 
        WHEN max_size = -1 THEN 'Unlimited'
        ELSE CAST(max_size * 8 / 1024 AS VARCHAR(20)) + ' MB'
    END AS [Max Size]
FROM sys.master_files
WHERE database_id = DB_ID('SampleDB');

-- Step 3: Check file usage
SELECT 
    DB_NAME(mf.database_id) AS [Database],
    mf.name AS [File Name],
    mf.type_desc,
    CAST(FILEPROPERTY(mf.name, 'SpaceUsed') * 8 / 1024.0 AS NUMERIC(10, 2)) AS [Used Space (MB)],
    CAST((mf.size - FILEPROPERTY(mf.name, 'SpaceUsed')) * 8 / 1024.0 AS NUMERIC(10, 2)) AS [Free Space (MB)]
FROM sys.master_files mf
WHERE mf.database_id = DB_ID('SampleDB');
```

#### Filegroup Management

```sql
-- Filegroups organize data files logically
-- Use filegroups to distribute I/O across disks

-- Step 1: Add a new filegroup
ALTER DATABASE SampleDB
ADD FILEGROUP FG_Analytics;

-- Step 2: Add files to the new filegroup
ALTER DATABASE SampleDB
ADD FILE
(
    NAME = 'SampleDB_Analytics1',
    FILENAME = 'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\Data\SampleDB_Analytics1.ndf',
    SIZE = 100MB,
    FILEGROWTH = 10MB
)
TO FILEGROUP FG_Analytics;

-- Step 3: Make PRIMARY default filegroup
ALTER DATABASE SampleDB
MODIFY FILEGROUP [PRIMARY] DEFAULT;

-- Step 4: Query filegroup information
SELECT 
    name AS [Filegroup Name],
    type_desc AS [Type]
FROM sys.filegroups;

-- Step 5: Create table on specific filegroup
USE SampleDB;
CREATE TABLE AnalyticsData
(
    AnalyticsID INT PRIMARY KEY,
    EventDate DATETIME,
    EventData NVARCHAR(MAX)
)
ON FG_Analytics;

-- Verify table placement
SELECT 
    t.name AS [Table Name],
    fg.name AS [Filegroup Name]
FROM sys.tables t
JOIN sys.indexes i ON t.object_id = i.object_id
JOIN sys.filegroups fg ON i.data_space_id = fg.data_space_id
WHERE t.name = 'AnalyticsData';
```

**Lab Exercise 1.3:**
```
1. Create SampleDB with multiple filegroups
2. Add files to different filegroups
3. Create tables on specific filegroups
4. Query metadata to verify placement
```

#### Compatibility Levels

```sql
-- Compatibility level controls database behavior for backward compatibility
-- SQL Server 2025 supports compatibility levels 90-160

-- Step 1: Check current compatibility level
SELECT 
    'Compatibility Level' AS Setting,
    compatibility_level AS [Level]
FROM sys.databases
WHERE name = 'SampleDB';

-- Step 2: Set to SQL Server 2025 compatibility level (160)
ALTER DATABASE SampleDB SET COMPATIBILITY_LEVEL = 160;

-- Step 3: Verify change
SELECT 
    name,
    compatibility_level
FROM sys.databases
WHERE name = 'SampleDB';

-- Step 4: Understand compatibility level differences
-- SQL Server 2025 (160) Features:
-- - Optimized Cardinality Estimation
-- - Intelligent Query Processing (IQP)
-- - Parameter Sensitive Plan Optimization (PSPO)
-- - Approximate Query Processing
-- - Memory Grant Feedback
-- - Batch Mode on Rowstore

-- Example: Query Store (requires 130+)
ALTER DATABASE SampleDB SET QUERY_STORE = ON;
ALTER DATABASE SampleDB SET QUERY_STORE (OPERATION_MODE = READ_WRITE);
```

#### Auto-Growth Configuration

```sql
-- IMPORTANT: Properly configured auto-growth prevents outages
-- But frequent auto-growth indicates capacity planning issues

-- Step 1: Check current auto-growth settings
SELECT 
    mf.name,
    mf.size * 8 / 1024 AS [Current Size (MB)],
    CASE 
        WHEN mf.is_percent_growth = 1 THEN CAST(mf.growth AS VARCHAR) + ' %'
        ELSE CAST(mf.growth * 8 / 1024 AS VARCHAR) + ' MB'
    END AS [Growth Setting]
FROM sys.master_files mf
WHERE mf.database_id = DB_ID('SampleDB');

-- Step 2: Set best-practice auto-growth for data files (fixed 500 MB)
ALTER DATABASE SampleDB
MODIFY FILE (NAME = 'SampleDB_Primary', FILEGROWTH = 500MB);

-- Step 3: Set best-practice auto-growth for log file (fixed 100 MB)
ALTER DATABASE SampleDB
MODIFY FILE (NAME = 'SampleDB_Log', FILEGROWTH = 100MB);

-- Step 4: Set maximum file size to prevent unlimited growth
-- This example sets 10 GB max for data file
ALTER DATABASE SampleDB
MODIFY FILE (NAME = 'SampleDB_Primary', MAXSIZE = 10GB);

-- Step 5: Disable auto-growth if managed manually (not recommended)
-- ALTER DATABASE SampleDB
-- MODIFY FILE (NAME = 'SampleDB_Primary', FILEGROWTH = 0);
```

**Lab Exercise 1.4:**
```
1. Review current auto-growth settings
2. Update to fixed-value growth (not percentage)
3. Set appropriate max file sizes
4. Verify changes in sys.master_files
```

---

### 2:00 PM - 3:00 PM | Part B: Database Instant File Initialization

#### Instant File Initialization (IFI)

IFI significantly speeds up file creation and growth by skipping zeroing of file space.

```sql
-- Step 1: Check if IFI is enabled
-- This requires Windows privilege check

-- Option A: Check via SQL Server startup flags
-- Navigate to: SQL Server Configuration Manager
--             > SQL Server Services
--             > SQL Server (MSSQLSERVER)
--             > Right-click > Properties
--             > Startup Parameters tab
-- Look for: -T1117 (Enable IFI flag) or -T1801 (Disable IFI flag)

-- Step 2: Enable IFI on Windows
-- SQL Server service account must have SE_MANAGE_VOLUME_NAME privilege

-- Open Group Policy Editor (gpedit.msc)
-- Navigate to: Computer Configuration > Windows Settings > Security Settings > Local Policies > User Rights Assignment
-- Add SQL Server service account to "Perform Volume Maintenance Tasks"

-- Step 3: Restart SQL Server service
# PowerShell (run as Administrator)
Restart-Service -Name 'MSSQL$MSSQLSERVER' -Force

-- Step 4: Verify IFI is working
-- Performance test: Compare file growth times with/without IFI
-- Without IFI: Growing a 1GB file can take 30+ seconds
-- With IFI: Growing a 1GB file should complete in seconds

-- Step 5: Test file growth performance
-- Run this query multiple times to test
SELECT COUNT(*)
FROM sys.dm_exec_requests
WHERE session_id > 50;

-- Then monitor file growth in Activity Monitor during table creation
```

**Important Note:** IFI should NOT be used if the database contains sensitive data that has been deleted, as it won't zero that space.

---

### 3:00 PM - 4:00 PM | Part C: Authentication, Security & Permissions

#### Authentication Modes

```sql
-- SQL Server supports two authentication modes:
-- 1. Windows Authentication - Recommended for domain environments
-- 2. Mixed Mode - Supports both Windows and SQL Authentication

-- Step 1: Check current authentication mode
-- This requires registry check

# PowerShell
$regPath = 'HKLM:\SOFTWARE\Microsoft\MSSQLServer\MSSQLServer'
$loginMode = Get-ItemProperty -Path $regPath -Name LoginMode

# 1 = Windows Authentication
# 2 = Mixed Mode (Windows + SQL)
Write-Host "Login Mode: $($loginMode.LoginMode)"

-- Step 2: Change authentication mode (if needed)
-- IMPORTANT: This requires service restart

# PowerShell (run as Administrator)
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\MSSQLServer\MSSQLServer' -Name LoginMode -Value 2
Restart-Service -Name 'MSSQL$MSSQLSERVER' -Force
```

#### SQL Authentication

```sql
-- Step 1: Create SQL Server login
CREATE LOGIN [AppUser1] WITH PASSWORD = 'P@ssw0rd123456!';

-- Step 2: Enable password policy enforcement
-- This is automatic for new logins

-- Step 3: Create another login for demonstration
CREATE LOGIN [DBAUser] WITH PASSWORD = 'D@BAP@ssw0rd123!';

-- Step 4: Query logins
SELECT 
    name,
    type_desc,
    create_date,
    CASE 
        WHEN name = 'sa' THEN 'System Administrator'
        ELSE 'Custom Login'
    END AS [Purpose]
FROM sys.syslogins
ORDER BY create_date DESC;

-- Step 5: Force password change on first login
ALTER LOGIN [AppUser1] WITH CHECK_POLICY = ON, CHECK_EXPIRATION = ON;

-- Step 6: Expire password to force change
ALTER LOGIN [AppUser1] WITH PASSWORD = 'P@ssw0rd123456!' MUST_CHANGE;
```

#### Windows Authentication

```sql
-- Step 1: Create Windows login from Active Directory
-- Format: [DOMAIN\Username] or [ComputerName\LocalUser]

CREATE LOGIN [CORP\jane.smith] FROM WINDOWS;
CREATE LOGIN [CORP\sqladmins] FROM WINDOWS;

-- Step 2: Query Windows logins
SELECT 
    name,
    type_desc,
    create_date
FROM sys.server_principals
WHERE type_desc = 'WINDOWS_LOGIN'
ORDER BY create_date DESC;

-- Step 3: Create user in database from Windows login
USE SampleDB;
CREATE USER [CORP\jane.smith] FOR LOGIN [CORP\jane.smith];

-- Step 4: Add Windows group (preferred for management)
-- In SSMS, right-click Logins > New Login > Search for group
-- Or use T-SQL:
-- CREATE LOGIN [CORP\sqladmins] FROM WINDOWS;
-- USE SampleDB;
-- CREATE USER [CORP\sqladmins] FOR LOGIN [CORP\sqladmins];
```

**Lab Exercise 1.5:**
```
1. Create 3 SQL Server logins
2. Create 2 Windows logins (use local machine if no domain)
3. Query sys.syslogins to verify
4. Create corresponding database users
```

#### Database Roles and Permissions

```sql
-- Step 1: Understand fixed server roles
SELECT 
    name,
    type_desc
FROM sys.server_principals
WHERE type_desc = 'SERVER_ROLE'
ORDER BY name;

-- Step 2: Check membership of server roles
-- Query sp_helpsrvrolemember stored procedure
EXEC sp_helpsrvrolemember;

-- Step 3: Add user to server role
ALTER SERVER ROLE [sysadmin] ADD MEMBER [CORP\sqladmins];

-- Step 4: Understand database roles
USE SampleDB;
SELECT 
    name,
    type_desc
FROM sys.database_principals
WHERE type_desc = 'DATABASE_ROLE'
ORDER BY name;

-- Step 5: Create custom database role
CREATE ROLE db_developers;

-- Step 6: Grant permissions to role
GRANT SELECT, INSERT, UPDATE ON OBJECT::dbo.AnalyticsData TO db_developers;

-- Step 7: Add user to database role
ALTER ROLE db_developers ADD MEMBER [AppUser1];

-- Step 8: Query role membership
SELECT 
    dp.name AS [Role Name],
    m.name AS [Member]
FROM sys.database_role_members drm
JOIN sys.database_principals dp ON drm.role_principal_id = dp.principal_id
JOIN sys.database_principals m ON drm.member_principal_id = m.principal_id
WHERE dp.type_desc = 'DATABASE_ROLE';
```

---

### 4:00 PM - 5:00 PM | Part D: Backup & Recovery

#### Backup Strategies

```sql
-- SQL Server supports three recovery models:
-- 1. SIMPLE - No log backups, point-in-time recovery not available
-- 2. BULK_LOGGED - Log backups available, minimal logging for bulk operations
-- 3. FULL - Log backups available, point-in-time recovery available

-- Step 1: Set recovery model to FULL
ALTER DATABASE SampleDB SET RECOVERY FULL;

-- Step 2: Verify recovery model
SELECT 
    name,
    recovery_model_desc
FROM sys.databases
WHERE name = 'SampleDB';

-- Step 3: Create initial full backup
-- IMPORTANT: Full backup is required before transaction log backups can be taken

BACKUP DATABASE SampleDB
TO DISK = N'C:\Backups\SampleDB_Full_20250124.bak'
WITH 
    COMPRESSION,
    INIT,
    NAME = N'SampleDB Full Backup',
    DESCRIPTION = N'Initial full backup for Day 1 lab',
    STATS = 5;

-- Step 4: Verify backup
RESTORE LABELONLY 
FROM DISK = N'C:\Backups\SampleDB_Full_20250124.bak';
```

#### Differential Backups

```sql
-- Differential backup only backs up changed data since last full backup
-- Faster and smaller than full backup
-- Requires full backup to restore

-- Step 1: Create some test data
USE SampleDB;
INSERT INTO AnalyticsData (AnalyticsID, EventDate, EventData)
VALUES 
    (1, GETDATE(), 'Test Event 1'),
    (2, GETDATE(), 'Test Event 2');

-- Step 2: Create differential backup
BACKUP DATABASE SampleDB
TO DISK = N'C:\Backups\SampleDB_Diff_20250124.bak'
WITH 
    DIFFERENTIAL,
    COMPRESSION,
    INIT,
    NAME = N'SampleDB Differential Backup',
    STATS = 5;

-- Step 3: Query backup history
SELECT 
    bs.database_name,
    bs.backup_start_date,
    bs.backup_finish_date,
    bs.type,
    bs.backup_size / 1024 / 1024 AS [Size (MB)]
FROM msdb.dbo.backupset bs
WHERE bs.database_name = 'SampleDB'
ORDER BY bs.backup_start_date DESC;
```

#### Transaction Log Backups

```sql
-- Transaction log backup captures all changes since last log backup
-- Essential for point-in-time recovery

-- Step 1: Create transaction log backup (can be taken frequently)
BACKUP LOG SampleDB
TO DISK = N'C:\Backups\SampleDB_Log_20250124_1000.trn'
WITH 
    COMPRESSION,
    INIT,
    NAME = N'SampleDB Transaction Log Backup',
    STATS = 5;

-- Step 2: Create another log backup
WAITFOR DELAY '00:00:10';  -- Wait 10 seconds
INSERT INTO SampleDB.dbo.AnalyticsData (AnalyticsID, EventDate, EventData)
VALUES (3, GETDATE(), 'Test Event 3');

BACKUP LOG SampleDB
TO DISK = N'C:\Backups\SampleDB_Log_20250124_1001.trn'
WITH 
    COMPRESSION,
    INIT,
    NAME = N'SampleDB Transaction Log Backup 2',
    STATS = 5;

-- Step 3: Query transaction log backup history
SELECT 
    bs.database_name,
    bs.backup_start_date,
    bs.backup_finish_date,
    bs.type,
    bs.backup_size / 1024 / 1024 AS [Size (MB)]
FROM msdb.dbo.backupset bs
WHERE bs.database_name = 'SampleDB'
  AND bs.type = 'L'  -- L = Log backup
ORDER BY bs.backup_start_date DESC;
```

#### Point-in-Time Recovery

```sql
-- Step 1: Simulate data loss
USE SampleDB;
DELETE FROM AnalyticsData WHERE AnalyticsID = 3;

-- Note the current time
SELECT GETDATE() AS [Current Time];

-- Step 2: Create one more log backup (to capture the delete)
BACKUP LOG SampleDB
TO DISK = N'C:\Backups\SampleDB_Log_20250124_1002.trn'
WITH 
    COMPRESSION,
    INIT,
    NAME = N'SampleDB Transaction Log Backup 3',
    STATS = 5;

-- Step 3: Restore using point-in-time recovery
-- Use STOPAT to recover to specific time

-- IMPORTANT: Put database in FULL recovery mode first
ALTER DATABASE SampleDB SET RECOVERY FULL;

-- Restore full backup
RESTORE DATABASE SampleDB
FROM DISK = N'C:\Backups\SampleDB_Full_20250124.bak'
WITH NORECOVERY;

-- Restore differential backup (if available)
RESTORE DATABASE SampleDB
FROM DISK = N'C:\Backups\SampleDB_Diff_20250124.bak'
WITH NORECOVERY;

-- Restore log backups to point just before the delete
-- Format: YYYY-MM-DD HH:MM:SS.nnn
RESTORE LOG SampleDB
FROM DISK = N'C:\Backups\SampleDB_Log_20250124_1001.trn'
WITH RECOVERY, STOPAT = '2025-01-24 10:00:30';

-- Step 4: Verify recovered data
SELECT * FROM AnalyticsData;

-- Step 5: Query LSN (Log Sequence Number) to verify recovery progress
SELECT 
    bs.database_name,
    bs.backup_start_date,
    bs.backup_finish_date,
    bs.type,
    bs.first_lsn,
    bs.last_lsn,
    bs.checkpoint_lsn
FROM msdb.dbo.backupset bs
WHERE bs.database_name = 'SampleDB'
ORDER BY bs.backup_start_date;
```

**Lab Exercise 1.6: Complete Backup and Recovery Scenario**

```
SCENARIO: Database SampleDB needs point-in-time recovery

STEPS:
1. Put SampleDB in FULL recovery mode
2. Create initial full backup
3. Insert test data (record time: Time1)
4. Create differential backup
5. Insert more data (record time: Time2)
6. Create transaction log backup
7. Perform DELETE operation (record time: Time3)
8. Create final transaction log backup
9. Restore SampleDB to recover deleted data (use STOPAT between Time2 and Time3)
10. Verify all data is recovered
11. Query backup history to confirm backup chain
```

---

## Hands-On Labs Summary

### Lab 1: SQL Server Installation and Configuration
- Install SQL Server 2025
- Verify all services are running
- Connect via SSMS and PowerShell
- Document system configuration

### Lab 2: Memory and Optimizer Configuration
- Document current memory settings
- Calculate and set appropriate max server memory
- Configure MAXDOP based on CPU cores
- Configure cost threshold for parallelism
- Verify TempDB configuration

### Lab 3: Database File Management
- Create database with multiple filegroups
- Add files to filegroups
- Configure auto-growth appropriately
- Create tables on specific filegroups
- Query file usage and metadata

### Lab 4: Authentication and Security
- Create SQL Server logins
- Create Windows logins
- Create database users
- Create and configure database roles
- Grant appropriate permissions
- Verify login and role membership

### Lab 5: Complete Backup and Recovery
- Set recovery model to FULL
- Create full, differential, and log backups
- Practice point-in-time recovery
- Query backup metadata
- Verify recovery scenarios

---

## Summary

**Day 1 has covered:**
1. ✓ SQL Server 2025 installation and configuration
2. ✓ SQL Server architecture (SQLOS, Memory, Storage, Query Processing)
3. ✓ Instance configuration (MAXDOP, Memory, Cost Threshold)
4. ✓ Database administration (Files, Filegroups, Compatibility Levels)
5. ✓ Authentication and security (Logins, Users, Roles, Permissions)
6. ✓ Backup and recovery strategies (Full, Differential, Log, Point-in-Time)

**Key Takeaways:**
- SQL Server needs proper memory configuration for optimal performance
- TempDB is critical - configure with one file per physical core
- Use FULL recovery model for production databases requiring point-in-time recovery
- Implement Windows Authentication where possible for better security
- Create and test backup/recovery procedures before relying on them

**Next Steps (Day 2):**
Tomorrow we'll dive into monitoring, troubleshooting, and log analysis using DMVs, Extended Events, and performance baselines.

---

## Additional Resources

- [Day 1 Codes.txt](./Day_1_Codes.txt) - All working SQL scripts and PowerShell commands
- [Day 1 Deep Dive.txt](./Day_1_Deep_Dive.txt) - Detailed technical explanations and theory
- SQL Server 2025 Books Online: https://learn.microsoft.com/en-us/sql/
- SQL Server Management Studio Downloads: https://learn.microsoft.com/en-us/sql/ssms/
