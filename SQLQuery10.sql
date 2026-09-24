-- to capture long running queries using Extended Events

/*IF EXISTS (SELECT * FROM sys.server_event_sessions WHERE name = 'LongRunningQueries')
    DROP EVENT SESSION [LongRunningQueries] ON SERVER;
GO

-- Create the Long-Running Queries session
CREATE EVENT SESSION [LongRunningQueries] ON SERVER 
ADD EVENT sqlserver.sp_statement_completed 
(
    ACTION(sqlserver.sql_text, sqlserver.database_id, sqlserver.client_hostname)
    WHERE (duration > 5000000)  -- Duration is in microseconds, so 5000000 = 5 seconds
)
ADD TARGET package0.event_file 
(
    SET filename = 'C:\Program Files\Microsoft SQL Server\MSSQL17.MSSQLSERVER01\MSSQL\Log\LongRunningQueries.xel'
)
WITH (
    MAX_MEMORY = 4096 KB,
    EVENT_RETENTION_MODE = ALLOW_SINGLE_EVENT_LOSS,
    MAX_DISPATCH_LATENCY = 30 SECONDS,
    TRACK_CAUSALITY = OFF,
    STARTUP_STATE = OFF
);
GO

-- Start the session
ALTER EVENT SESSION [LongRunningQueries] ON SERVER STATE = START;
GO

-- Query to see active sessions
SELECT 
    name as [Session_Name],
    startup_state as [Start State]
FROM sys.server_event_sessions
WHERE name = 'LongRunningQueries';*/

-- capture deadlocks
-- Drop if exists
IF EXISTS (SELECT * FROM sys.server_event_sessions WHERE name = 'DeadlockMonitor')
    DROP EVENT SESSION [DeadlockMonitor] ON SERVER;
GO

-- Create Deadlock monitoring session
CREATE EVENT SESSION [DeadlockMonitor] ON SERVER 
ADD EVENT sqlserver.xml_deadlock_report 
(
    ACTION(sqlserver.session_id, sqlserver.sql_text)
)
ADD TARGET package0.event_file 
(
    SET filename = 'C:\Program Files\Microsoft SQL Server\MSSQL17.MSSQLSERVER01\MSSQL\Log\DeadlockMonitor.xel',
    max_file_size = 50
)
WITH (
    MAX_MEMORY = 4096 KB,
    EVENT_RETENTION_MODE = ALLOW_SINGLE_EVENT_LOSS,
    TRACK_CAUSALITY = OFF,
    STARTUP_STATE = ON
);
GO

-- Start the session
ALTER EVENT SESSION [DeadlockMonitor] ON SERVER STATE = START;
GO

-- Verify it's running
SELECT 
    name,
    startup_state,
    package0 = (SELECT COUNT(*) FROM sys.server_event_session_targets 
                WHERE event_session_id = (SELECT event_session_id FROM sys.server_event_sessions 
                                         WHERE name = 'DeadlockMonitor'))
FROM sys.server_event_sessions
WHERE name = 'DeadlockMonitor';
