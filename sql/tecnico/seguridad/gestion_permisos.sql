USE aura_store;
GO

SET NOCOUNT ON;
GO

-- Crear el rol y el usuario de prueba si no existen
IF DATABASE_PRINCIPAL_ID(N'rol_consulta_productos') IS NULL
    CREATE ROLE rol_consulta_productos;

IF DATABASE_PRINCIPAL_ID(N'usuario_con_rol') IS NULL
    CREATE USER usuario_con_rol WITHOUT LOGIN;

ALTER ROLE rol_consulta_productos ADD MEMBER usuario_con_rol;
GO

GRANT SELECT ON OBJECT::dbo.producto TO rol_consulta_productos;
GRANT SELECT ON OBJECT::dbo.liga TO rol_consulta_productos;
GO

SELECT
    USER_NAME(dp.grantee_principal_id) AS rol,
    dp.permission_name AS permiso,
    dp.state_desc AS estado,
    OBJECT_SCHEMA_NAME(dp.major_id) AS esquema,
    OBJECT_NAME(dp.major_id) AS objeto
FROM sys.database_permissions AS dp
WHERE dp.grantee_principal_id =
      DATABASE_PRINCIPAL_ID(N'rol_consulta_productos')
  AND dp.class = 1
ORDER BY esquema, objeto, permiso;
GO

SELECT
    r.name AS rol,
    m.name AS miembro,
    m.type_desc AS tipo_miembro
FROM sys.database_role_members AS drm
JOIN sys.database_principals AS r
    ON r.principal_id = drm.role_principal_id
JOIN sys.database_principals AS m
    ON m.principal_id = drm.member_principal_id
WHERE r.name = N'rol_consulta_productos'
ORDER BY m.name;
GO

