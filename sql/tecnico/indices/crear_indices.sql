-- =============================================================
-- Aura Store - Indice para consultas de compras por fecha
-- Etapa V - Optimizacion de consultas
-- =============================================================
-- El indice facilita la consulta de compras de un periodo y el
-- filtro por fecha del informe de ventas de la Etapa IV.
-- Ejecutar despues de sql/ddl/crear_bd.sql.
-- =============================================================

USE aura_store;
GO

-- =========================================================
-- A. VERIFICACION DE LA TABLA
-- La tabla dbo.compra debe existir antes de crear el indice.
-- =========================================================
IF OBJECT_ID(N'dbo.compra', N'U') IS NULL
BEGIN
    RAISERROR('Primero se debe crear la tabla dbo.compra.', 16, 1);
    RETURN;
END;

-- =========================================================
-- B. INDICE POR FECHA CON COBERTURA
-- El indice no agrupado usa fecha como clave. INCLUDE agrega
-- id_cliente e id_metodo al nivel hoja para cubrir el listado.
-- id_compra ya forma parte del indice por ser la clave agrupada.
-- =========================================================
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'dbo.compra')
      AND name = N'IX_compra_fecha_cobertura'
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_compra_fecha_cobertura
    ON dbo.compra (fecha)
    INCLUDE (id_cliente, id_metodo);
END;

-- =========================================================
-- C. VERIFICACION DEL INDICE
-- El listado muestra fecha como columna clave e id_cliente e
-- id_metodo como columnas incluidas. id_compra se agrega de forma
-- implicita y queda fuera del listado.
-- =========================================================
SELECT
    i.name AS indice,
    i.type_desc AS tipo,
    col.name AS columna,
    ic.key_ordinal AS orden_clave,
    ic.is_included_column AS es_columna_incluida
FROM sys.indexes i
JOIN sys.index_columns ic
    ON ic.object_id = i.object_id AND ic.index_id = i.index_id
JOIN sys.columns col
    ON col.object_id = ic.object_id AND col.column_id = ic.column_id
WHERE i.object_id = OBJECT_ID(N'dbo.compra')
  AND i.name = N'IX_compra_fecha_cobertura'
ORDER BY ic.is_included_column, ic.key_ordinal, col.column_id;
