
WITH profiled_sessions as (
	SELECT DISTINCT session_id profiled_session_id from sys.dm_exec_query_profiles
)
SELECT 
   [Session ID]    = s.session_id, 
   [User Process]  = CONVERT(CHAR(1), s.is_user_process),
   [Login]         = s.login_name,   
   [Database]      = CASE WHEN s.database_id=0 THEN N'' ELSE ISNULL(db_name(s.database_id),N'') END,
   [Task State]    = ISNULL(t.task_state, N''), 
   [Command]       = ISNULL(r.command, N''), 
   [Application]   = ISNULL(s.program_name, N''), 
   [Wait Time (ms)]     = ISNULL(w.wait_duration_ms, 0),
   [Wait Type]     = ISNULL(w.wait_type, N''),
   [Wait Resource] = ISNULL(w.resource_description, N''), 
   [Blocked By]    = ISNULL(CONVERT (varchar, w.blocking_session_id), ''),
   [Head Blocker]  = 
        CASE 
            -- session has an active request, is blocked, but is blocking others or session is idle but has an open tran and is blocking others
            WHEN r2.session_id IS NOT NULL AND (r.blocking_session_id = 0 OR r.session_id IS NULL) THEN '1' 
            -- session is either not blocking someone, or is blocking someone but is blocked by another party
            ELSE ''
        END, 
   [Total CPU (ms)] = s.cpu_time, 
   [Total Physical I/O (MB)]   = (s.reads + s.writes) * 8 / 1024, 
   [Memory Use (KB)]  = s.memory_usage * (8192 / 1024), 
   [Open Transactions] = ISNULL(r.open_transaction_count,0), 
   [Login Time]    = s.login_time, 
   [Last Request Start Time] = s.last_request_start_time,
   [Host Name]     = ISNULL(s.host_name, N''),
   [Net Address]   = ISNULL(c.client_net_address, N''), 
   [Execution Context ID] = ISNULL(t.exec_context_id, 0),
   [Request ID] = ISNULL(r.request_id, 0),
   [Workload Group] = ISNULL(g.name, N''),
   [Profiled Session Id] = profiled_session_id
FROM sys.dm_exec_sessions s LEFT OUTER JOIN sys.dm_exec_connections c ON (s.session_id = c.session_id)
LEFT OUTER JOIN sys.dm_exec_requests r ON (s.session_id = r.session_id)
LEFT OUTER JOIN sys.dm_os_tasks t ON (r.session_id = t.session_id AND r.request_id = t.request_id)
OUTER APPLY
(
    -- In some cases (e.g. parallel queries, also waiting for a worker), one thread can be flagged as 
    -- waiting for several different threads.  This will cause that thread to show up in multiple rows 
    -- in our grid, which we don't want.
    SELECT TOP 1 * 
    FROM sys.dm_os_waiting_tasks wt
    WHERE wt.waiting_task_address = t.task_address
    ORDER BY wt.wait_duration_ms desc
) w
LEFT OUTER JOIN sys.dm_exec_requests r2 ON (s.session_id = r2.blocking_session_id)
LEFT OUTER JOIN sys.dm_resource_governor_workload_groups g ON (g.group_id = s.group_id)
LEFT OUTER JOIN profiled_sessions ON profiled_session_id = s.session_id
ORDER BY s.session_id;
