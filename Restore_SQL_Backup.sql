------------------------Restore Full Backups

SELECT 
   --CONVERT(CHAR(100), SERVERPROPERTY('Servername')) AS Server, 
   --msdb.dbo.backupset.database_name, 
   --msdb.dbo.backupset.backup_start_date, 
   --msdb.dbo.backupset.backup_finish_date, 
   --msdb.dbo.backupset.expiration_date, 
   --CASE msdb..backupset.type 
   --   WHEN 'D' THEN 'Database' 
   --   WHEN 'L' THEN 'Log' 
   --   END AS backup_type, 
   --msdb.dbo.backupset.backup_size, 
   --msdb.dbo.backupmediafamily.logical_device_name, 
  'RESTORE DATABASE ['+msdb.dbo.backupset.database_name+'] FROM DISK=N'''+msdb.dbo.backupmediafamily.physical_device_name+''' WITH FILE=1, NORECOVERY,REPLACE,NOUNLOAD,STATS=5'
  --, 
   --msdb.dbo.backupset.name AS backupset_name, 
   --msdb.dbo.backupset.description 
FROM 
   msdb.dbo.backupmediafamily 
   INNER JOIN msdb.dbo.backupset ON msdb.dbo.backupmediafamily.media_set_id = msdb.dbo.backupset.media_set_id 
WHERE 
   (CONVERT(datetime, msdb.dbo.backupset.backup_start_date, 102) >= GETDATE() - 3) and msdb..backupset.type ='D' and  msdb.dbo.backupset.database_name not in ('master','msdb','tempdb','model')
ORDER BY 
 
   msdb.dbo.backupset.backup_finish_date desc

------------------------------------Restore Differential Backups


SELECT 
   --CONVERT(CHAR(100), SERVERPROPERTY('Servername')) AS Server, 
   --msdb.dbo.backupset.database_name, 
   --msdb.dbo.backupset.backup_start_date, 
   --msdb.dbo.backupset.backup_finish_date, 
   --msdb.dbo.backupset.expiration_date, 
   --CASE msdb..backupset.type 
   --   WHEN 'D' THEN 'Database' 
   --   WHEN 'L' THEN 'Log' 
   --   END AS backup_type, 
   --msdb.dbo.backupset.backup_size, 
   --msdb.dbo.backupmediafamily.logical_device_name, 
  'RESTORE DATABASE ['+msdb.dbo.backupset.database_name+'] FROM DISK=N'''+msdb.dbo.backupmediafamily.physical_device_name+''' WITH FILE=1, RECOVERY,NOUNLOAD,STATS=5'
  --, 
   --msdb.dbo.backupset.name AS backupset_name, 
   --msdb.dbo.backupset.description 
FROM 
   msdb.dbo.backupmediafamily 
   INNER JOIN msdb.dbo.backupset ON msdb.dbo.backupmediafamily.media_set_id = msdb.dbo.backupset.media_set_id 
WHERE 
   (CONVERT(datetime, msdb.dbo.backupset.backup_start_date, 102) >= GETDATE() - 3) and msdb..backupset.type ='I' and  msdb.dbo.backupset.database_name not in ('master','msdb','tempdb','model')
ORDER BY 
 
   msdb.dbo.backupset.backup_finish_date desc
