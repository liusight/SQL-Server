SELECT '/*--ALTER ROLE ADD MEMBER PERMISSIONS--*/ '+' Alter role ' + roles .name + ' add member ' + '[' +users.name+']'
 from sys.database_principals users
  inner join sys .database_role_members link
   on link .member_principal_id = users.principal_id
  inner join sys .database_principals roles
   on roles .principal_id = link.role_principal_id  AND users.name<>'dbo'--order by users.name
   union
SELECT '/*-SECURABLES AND PERMISSIONS GRANTED TO ROLES r_ -*/ '+' GRANT ' + database_permissions.permission_name + ' ON ' + CASE database_permissions.class_desc
       WHEN 'SCHEMA'
           THEN 'SCHEMA::[' + schema_name(major_id ) + ']'
       WHEN 'OBJECT_OR_COLUMN'
           THEN CASE
                   WHEN minor_id = 0
                       THEN'['+ OBJECT_SCHEMA_NAME(major_id ) + '].' + '[' + object_name(major_id ) + ']' COLLATE Latin1_General_CI_AS_KS_WS
                   ELSE (
                           SELECT object_name (object_id) + ' (' + NAME + ')'
                           FROM sys .columns
                           WHERE object_id = database_permissions.major_id
                               AND column_id = database_permissions. minor_id
                           )
                   END
       ELSE 'other'
       END + ' TO [' + database_principals .NAME + ']' COLLATE Latin1_General_CI_AS_KS_WS
FROM sys .database_permissions
JOIN sys .database_principals ON database_permissions .grantee_principal_id = database_principals.principal_id
LEFT JOIN sys. objects --left because it is possible that it is a schema
   ON objects.object_id = database_permissions.major_id
WHERE database_permissions .major_id > 0
   --AND permission_name IN ('SELECT','INSERT','UPDATE','DELETE','EXECUTE')
    AND database_principals.name like 'r[_]%'
       UNION
       SELECT '/*DB ROLE_LEVEL_PERMISSIONS*/  '+
              ' GRANT '+convert(varchar(10), CASE p.type
              WHEN 'RF' THEN 'REFERENCES'
              WHEN 'SL' THEN 'SELECT'
              WHEN 'IN' THEN 'INSERT'
              WHEN 'DL' THEN 'DELETE'
              WHEN 'UP' THEN 'UPDATE'
              END)+' ON '+SCHEMA_NAME(o.schema_id)+'.'+o.name+' TO ['+USER_NAME(p.grantee_principal_id)+']' AS PERMISSION
FROM
       sys.objects o,
       sys.database_permissions p
WHERE
       o.type IN ('U', 'V')
       AND p.class = 1
       AND p.major_id = o.object_id
       AND p.minor_id = 0   -- all columns
       AND p.type IN ('RF','IN','SL','UP','DL')
       AND p.state IN ('W','G')
       AND (p.grantee_principal_id = 0
              OR p.grantee_principal_id = DATABASE_PRINCIPAL_ID()
              OR p.grantor_principal_id = DATABASE_PRINCIPAL_ID())
UNION
SELECT '/*-- [--DB LEVEL PERMISSIONS --] --*/  ' + CASE
WHEN perm.state <> 'W' THEN perm.state_desc --W=Grant With Grant Option
ELSE '  GRANT'
END
+ SPACE(1) + perm.permission_name --CONNECT, etc
+ SPACE(1) + 'TO' + SPACE(1) + '[' + USER_NAME(usr.principal_id) + ']' --COLLATE database_default --TO <user name>
+ CASE
WHEN perm.state <> 'W' THEN SPACE(0)
ELSE SPACE(1) + 'WITH GRANT OPTION'
 END
AS [-- SQL STATEMENTS --]
FROM sys.database_permissions AS perm
INNER JOIN
sys.database_principals AS usr
ON perm.grantee_principal_id = usr.principal_id
--WHERE usr.name = @OldUser
WHERE [perm].[major_id] = 0
AND [usr].[principal_id] > 4 -- 0 to 4 are system users/schemas
--AND [usr].[type] IN ('G', 'S', 'U','R') -- S = SQL user, U = Windows user, G = Windows group R- Database 
--Role
