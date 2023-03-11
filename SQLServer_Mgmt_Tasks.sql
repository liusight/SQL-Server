
                declare @all_tasks table(
                rowno int identity
                ,	task_address varbinary(8)
                ,	scheduler_id int
                ,	spid int
                ,   request_id int
                ,	login_name sysname collate database_default null
                ,	state nvarchar(60) collate database_default
                ,	cpu_time bigint
                ,	memory_used int
                ,	context_switches_count int
                ,	io_count int
                ,	sql_statement nvarchar(MAX) collate database_default
                ,	task_address_string nvarchar(18) collate database_default
                ,	is_user_process tinyint
                );

                insert into @all_tasks (task_address, scheduler_id, spid,request_id, login_name, state, cpu_time, memory_used,
                context_switches_count,	io_count, sql_statement,is_user_process)
                select  tasks.task_address as task_address
                ,	tasks.scheduler_id
                ,	tasks.session_id
                ,	tasks.request_id
                ,	sessions.login_name
                ,	workers.state
                ,	threads.kernel_time + threads.usermode_time as [cpu time]
                ,	memory.max_pages_in_bytes as [memory used]
                ,	tasks.context_switches_count
                ,	tasks.pending_io_count
                ,	case when requests.sql_handle IS NULL
                then ' '
                else (select top 1 substring(text,(requests.statement_start_offset+2)/2,(case when requests.statement_end_offset = -1 	then len(convert(nvarchar(MAX),text))*2 	else requests.statement_end_offset	end - requests.statement_start_offset) /2  ) from sys.dm_exec_sql_text(requests.sql_handle))
                end as [SQL Statement]
                ,	case when sessions.is_user_process is null then 0 else sessions.is_user_process end
                from sys.dm_os_tasks tasks
                join sys.dm_os_workers workers on tasks.worker_address = workers.worker_address
                left outer join sys.dm_os_threads threads on workers.thread_address = threads.thread_address
                left outer join sys.dm_os_memory_objects memory on workers.memory_object_address = memory.memory_object_address
                left outer join sys.dm_exec_sessions sessions on tasks.session_id = sessions.session_id
                left outer join sys.dm_exec_requests requests on tasks.session_id = requests.session_id and tasks.request_id = requests.request_id
                order by tasks.scheduler_id, tasks.session_id

                select  (dense_rank() over (order by state))%2 as l1
                ,	(dense_rank() over (order by state ,is_user_process desc,spid,task_address))%2 as l2
                ,	rowno
                ,	master.dbo.fn_varbintohexstr(task_address) as task_address
                ,	scheduler_id
                ,	spid
                ,	request_id
                ,	login_name
                ,	UPPER(SUBSTRING(state,1,1))+ Lower(SUBSTRING(state,2,LEN(state))) as state
                ,	cpu_time  as [CPU Time]
                ,	memory_used as [Memory Used]
                ,	context_switches_count
                ,	io_count
                ,	sql_statement as [Sql Statement]
                ,	is_user_process
                from @all_tasks
                order by state,is_user_process desc,spid,task_address
            