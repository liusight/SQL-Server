-- | FILE     : perf_objects_without_statistics.sql                             |
-- | CLASS    : Tuning                                                          |
-- | PURPOSE  : Report on all objects that do not have statistics collected on  |
-- |            them.   

SELECT
    owner           owner
  , 'Table'         object_type
  , table_name      object_name
  , NULL            partition_name
FROM
    sys.dba_tables 
WHERE
      last_analyzed IS NULL 
  AND owner NOT IN ('SYS','SYSTEM') 
  AND partitioned = 'NO' 
UNION 
SELECT
    owner           owner
  , 'Index'         object_type
  , index_name      object_name
  , NULL            partition_name
FROM
    sys.dba_indexes 
WHERE
      last_analyzed IS NULL 
  AND owner NOT IN ('SYS','SYSTEM') 
  AND partitioned = 'NO' 
UNION 
SELECT
    table_owner       owner
  , 'Table Partition' object_type
  , table_name        object_name
  , partition_name    partition_name
FROM
    sys.dba_tab_partitions 
WHERE
      last_analyzed IS NULL 
  AND table_owner NOT IN ('SYS','SYSTEM') 
UNION 
SELECT
    index_owner       owner
  , 'Index Partition' object_type
  , index_name        object_name
  , partition_name    partition_name
FROM
    sys.dba_ind_partitions 
WHERE
      last_analyzed IS NULL 
  AND index_owner NOT IN ('SYS','SYSTEM')
ORDER BY
    1
  , 2
  , 3
/

