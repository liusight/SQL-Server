

SELECT 'alter index '+i.name+' on '+OBJECT_SCHEMA_NAME(ips.object_id)+'.'+OBJECT_NAME(ips.object_id)+' REBUILD' as RebuildScript, OBJECT_SCHEMA_NAME(ips.object_id) AS schema_name,
       OBJECT_NAME(ips.object_id) AS object_name,
       i.name AS index_name,
       i.type_desc AS index_type,
       ips.avg_fragmentation_in_percent,
       ips.avg_page_space_used_in_percent,
       ips.page_count,
       ips.alloc_unit_type_desc
FROM sys.dm_db_index_physical_stats(DB_ID(), default, default, default, 'SAMPLED') AS ips
INNER JOIN sys.indexes AS i 
ON ips.object_id = i.object_id
   AND
   ips.index_id = i.index_id
   and  ips.avg_fragmentation_in_percent>10
ORDER BY page_count DESC;

-----------------------##############################################################

USE <> --Enter the name of the database you want to reindex
DECLARE @TableName varchar(255)
DECLARE TableCursor CURSOR FOR
    SELECT table_schema+'.'+table_name FROM information_schema.tables 
        WHERE table_type = 'base table'
OPEN TableCursor
FETCH NEXT FROM TableCursor INTO @TableName
WHILE @@FETCH_STATUS = 0
BEGIN
    DBCC DBREINDEX(@TableName)
    FETCH NEXT FROM TableCursor INTO @TableName
END
CLOSE TableCursor
DEALLOCATE TableCursor
