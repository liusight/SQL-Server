
WITH [EQ] AS
(
  SELECT
  --TOP 20
  SUBSTRING([qt].[text]
           , ( [qs].[statement_start_offset] / 2 ) + 1
           , (( CASE [qs].[statement_end_offset]
                  WHEN -1
                    THEN DATALENGTH([qt].[text])
                  ELSE [qs].[statement_end_offset]
                END - [qs].[statement_start_offset]
              ) / 2
             ) + 1
           ) AS [SQL_Statment]
  , [qs].[execution_count]
  , [qs].[total_logical_reads]
  , [qs].[last_logical_reads]
  , [qs].[total_logical_writes]
  , [qs].[last_logical_writes]
  , [qs].[total_worker_time]
  , [qs].[last_worker_time]
  , [qs].[total_elapsed_time] / 1000000 [total_elapsed_time_in_S]
  , [qs].[last_elapsed_time] / 1000000 [last_elapsed_time_in_S]
  , [qs].[last_execution_time]
  , [qp].[query_plan]
  FROM [sys].[dm_exec_query_stats] [qs]
    CROSS APPLY [sys].dm_exec_sql_text([qs].[sql_handle]) [qt]
    CROSS APPLY [sys].dm_exec_query_plan([qs].[plan_handle]) [qp]
)
SELECT
*
--INTO [dbo].[ExpensiveQuery] /* Uncomment once you have tested the query parameters. Change Schema and table name if desired. */
FROM [EQ]
WHERE [EQ].[total_logical_reads] > 1000 /* Adjust to higher threshold if Query returns too many rows*/
AND [EQ].[last_execution_time] BETWEEN '2024-01-13' AND '2024-05-22' /* Adjust to dates that will cover rapidly climbing latency */

order by [total_logical_reads] desc

