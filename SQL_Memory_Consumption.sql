
                declare @total_alcted_v_res_awe_s_res bigint
                declare @tab table (
                row_no int identity
                ,       type nvarchar(128) collate database_default
                ,       allocated bigint
                ,       vertual_res bigint
                ,       virtual_com bigint
                ,       awe bigint
                ,       shared_res bigint
                ,       shared_com bigint
                ,       graph_type nvarchar(128)
                ,       grand_total bigint
                );

                select  @total_alcted_v_res_awe_s_res = sum(pages_kb + (CASE WHEN type <> 'MEMORYCLERK_SQLBUFFERPOOL' THEN virtual_memory_committed_kb ELSE 0 END) + shared_memory_committed_kb)
                from sys.dm_os_memory_clerks

                insert into @tab
                select  type
                ,       sum(pages_kb) as allocated
                ,       sum(virtual_memory_reserved_kb) as vertual_res
                ,       sum(virtual_memory_committed_kb) as virtual_com
                ,       sum(awe_allocated_kb) as awe
                ,       sum(shared_memory_reserved_kb) as shared_res
                ,       sum(shared_memory_committed_kb) as shared_com
                ,       case  when  (((sum(pages_kb + (CASE WHEN type <> 'MEMORYCLERK_SQLBUFFERPOOL' THEN virtual_memory_committed_kb ELSE 0 END) + shared_memory_committed_kb))/(@total_alcted_v_res_awe_s_res + 0.0)) >= 0.05) OR type = 'MEMORYCLERK_XTP'
                then type
                else 'Other'
                end as graph_type
                ,       (sum(pages_kb + (CASE WHEN type <> 'MEMORYCLERK_SQLBUFFERPOOL' THEN virtual_memory_committed_kb ELSE 0 END) + shared_memory_committed_kb)) as grand_total
                from sys.dm_os_memory_clerks
                group by type
                order by (sum(pages_kb + (CASE WHEN type <> 'MEMORYCLERK_SQLBUFFERPOOL' THEN virtual_memory_committed_kb ELSE 0 END) + shared_memory_committed_kb)) desc

                update @tab set graph_type = type where row_no <= 5
                select  * from @tab
          