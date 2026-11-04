-- =============================================================
-- Aura Store - Indice para consultas de compras por fecha
-- Etapa V - Optimizacion de consultas
-- =============================================================
-- Caso de uso: consultar compras de un periodo y facilitar el
-- filtro por fecha del informe de ventas de la Etapa IV.
-- Ejecutar despues de sql/ddl/crear_bd.sql.
-- =============================================================

USE aura_store;
GO

IF OBJECT_ID(N'dbo.compra', N'U') IS NULL
BEGIN
    RAISERROR('Primero se debe crear la tabla dbo.compra.', 16, 1);
    RETURN;
END;

-- PK_compra ya genera un indice agrupado por id_compra.
-- Se conserva esa clave y se agrega un indice NO agrupado por fecha.
-- INCLUDE guarda los datos del cliente y del metodo de pago en
-- el nivel hoja, para cubrir tambien el listado de compras.
-- id_compra ya forma parte del indice por ser la clave agrupada.
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

-- Verificar el indice y sus columnas declaradas.
-- La clave agrupada implicita (id_compra) no aparece en este listado.
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
