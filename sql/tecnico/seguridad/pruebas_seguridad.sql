USE aura_store;
GO

SET NOCOUNT ON;
GO

PRINT 'A. Configuración del rol y sus miembros';
GO

-- A1. Permisos explícitos asignados directamente al rol.
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

-- A2. Miembros del rol.
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

PRINT 'B. Pruebas de permisos en el contexto de usuario_con_rol';
GO

-- Verificar que el usuario exista antes de cambiar el contexto.
IF DATABASE_PRINCIPAL_ID(N'usuario_con_rol') IS NULL
BEGIN
    RAISERROR('No existe el usuario de base de datos usuario_con_rol.', 16, 1);
    RETURN;
END;
GO

-- Ejecutar las comprobaciones en el contexto de ese usuario.
EXECUTE AS USER = N'usuario_con_rol';
GO

SELECT
    USER_NAME() AS usuario_en_prueba,
    HAS_PERMS_BY_NAME(N'dbo.producto', N'OBJECT', N'SELECT') AS puede_select_producto,
    HAS_PERMS_BY_NAME(N'dbo.liga', N'OBJECT', N'SELECT') AS puede_select_liga,
    HAS_PERMS_BY_NAME(N'dbo.producto', N'OBJECT', N'INSERT') AS puede_insert_producto,
    HAS_PERMS_BY_NAME(N'dbo.producto', N'OBJECT', N'UPDATE') AS puede_update_producto,
    HAS_PERMS_BY_NAME(N'dbo.producto', N'OBJECT', N'DELETE') AS puede_delete_producto,
    HAS_PERMS_BY_NAME(N'dbo.liga', N'OBJECT', N'INSERT') AS puede_insert_liga,
    HAS_PERMS_BY_NAME(N'dbo.liga', N'OBJECT', N'UPDATE') AS puede_update_liga,
    HAS_PERMS_BY_NAME(N'dbo.liga', N'OBJECT', N'DELETE') AS puede_delete_liga;
GO

-- Consultas de lectura: deben funcionar si los permisos efectivos son correctos.
SELECT TOP (5) *
FROM dbo.producto;
GO

SELECT TOP (5) *
FROM dbo.liga;
GO

REVERT;
GO

PRINT 'Fin de las pruebas. No se modificaron filas.';
GO
