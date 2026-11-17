-- =============================================================
-- Aura Store - Permisos de lectura de productos y ligas
-- Etapa V - Seguridad
-- =============================================================
-- Ejecutar TODO el archivo en una misma conexion de SQL Server,
-- despues de gestion_permisos.sql y con permiso para suplantar
-- a usuario_con_rol (por ejemplo, desde la cuenta administradora).
-- Revisar las pestanas Resultados y Mensajes en SSMS.
-- =============================================================

USE aura_store;
GO

SET NOCOUNT ON;

IF DATABASE_PRINCIPAL_ID(N'usuario_con_rol') IS NULL
   OR DATABASE_PRINCIPAL_ID(N'rol_consulta_productos') IS NULL
    THROW 51001, 'Ejecutar gestion_permisos.sql para crear el rol y el usuario de prueba.', 1;

-- =============================================================
-- A. CONFIGURACION DEL ROL
-- usuario_con_rol debe aparecer como miembro. Se esperan dos
-- GRANT de SELECT sobre dbo.producto y dbo.liga.
-- =============================================================
PRINT 'A. Configuracion del rol';

SELECT r.name AS rol, m.name AS miembro
FROM sys.database_role_members AS drm
JOIN sys.database_principals AS r ON r.principal_id = drm.role_principal_id
JOIN sys.database_principals AS m ON m.principal_id = drm.member_principal_id
WHERE r.name = N'rol_consulta_productos'
ORDER BY m.name;

SELECT OBJECT_SCHEMA_NAME(major_id) AS esquema,
       OBJECT_NAME(major_id) AS objeto, permission_name AS permiso, state_desc AS estado
FROM sys.database_permissions
WHERE grantee_principal_id = DATABASE_PRINCIPAL_ID(N'rol_consulta_productos')
  AND class = 1
ORDER BY esquema, objeto, permiso;

IF NOT EXISTS (
    SELECT 1 FROM sys.database_role_members
    WHERE role_principal_id = DATABASE_PRINCIPAL_ID(N'rol_consulta_productos')
      AND member_principal_id = DATABASE_PRINCIPAL_ID(N'usuario_con_rol')
)
    THROW 51002, 'usuario_con_rol debe pertenecer a rol_consulta_productos.', 1;

-- =============================================================
-- B. PERMISOS EFECTIVOS Y LECTURA
-- Para el usuario, SELECT debe dar 1. INSERT, UPDATE y DELETE
-- deben dar 0 en ambas tablas. Los dos SELECT deben ejecutarse.
-- =============================================================
PRINT 'B. Permisos efectivos y consultas como usuario_con_rol';

DECLARE @permisos TABLE (
    objeto SYSNAME, permiso SYSNAME, esperado INT, obtenido INT
);
DECLARE @error_update INT;

EXECUTE AS USER = N'usuario_con_rol';

BEGIN TRY
    INSERT INTO @permisos (objeto, permiso, esperado, obtenido)
    SELECT o.objeto, p.permiso, p.esperado,
           HAS_PERMS_BY_NAME(o.objeto, N'OBJECT', p.permiso)
    FROM (VALUES (N'dbo.producto'), (N'dbo.liga')) AS o(objeto)
    CROSS JOIN (VALUES (N'SELECT', 1), (N'INSERT', 0), (N'UPDATE', 0), (N'DELETE', 0))
        AS p(permiso, esperado);

    SELECT USER_NAME() AS usuario_en_prueba, objeto, permiso, esperado, obtenido
    FROM @permisos
    ORDER BY objeto, permiso;

    IF EXISTS (SELECT 1 FROM @permisos WHERE obtenido <> esperado OR obtenido IS NULL)
        THROW 51003, 'Los permisos efectivos difieren de los esperados para el rol de lectura.', 1;

    SELECT TOP (5) id_producto, nombre, precio_actual
    FROM dbo.producto
    ORDER BY id_producto;

    SELECT TOP (5) id_liga, nombre
    FROM dbo.liga
    ORDER BY id_liga;

    -- =========================================================
    -- C. OPERACION DE ESCRITURA
    -- SQL Server debe rechazar el UPDATE con el error 229.
    -- WHERE 1 = 0 protege los datos incluso si hubiera un permiso
    -- adicional. sp_executesql permite capturar el error del lote.
    -- =========================================================
    PRINT 'C. Intento de actualizar dbo.producto';

    BEGIN TRY
        EXEC sys.sp_executesql N'UPDATE dbo.producto SET precio_actual = 1 WHERE 1 = 0;';
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 229
            THROW;

        SET @error_update = ERROR_NUMBER();
        SELECT @error_update AS numero_error, ERROR_MESSAGE() AS mensaje_esperado;
    END CATCH;

    IF @error_update IS NULL
        THROW 51004, 'SQL Server debia rechazar el UPDATE con el error 229.', 1;
END TRY
BEGIN CATCH
    -- Se restaura la cuenta original tambien ante un fallo inesperado.
    REVERT;
    THROW;
END CATCH;

REVERT;
SELECT USER_NAME() AS contexto_restaurado;
PRINT 'Prueba correcta. Se recupero el contexto de la conexion.';
