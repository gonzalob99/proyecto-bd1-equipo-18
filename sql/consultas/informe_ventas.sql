-- =============================================================
-- Aura Store - Reporte agregado de ventas
-- Etapa V - Consultas SQL
-- =============================================================
-- Total vendido, unidades y cantidad de ventas, agrupado por
-- categoría de producto, en un rango de fechas.
--
-- El modelo no tiene vendedores (es venta directa al cliente, sin
-- un actor "vendedor" en el DER), así que se usa `liga` como la
-- categoría de producto para agrupar, que es la clasificación que
-- sí existe en el esquema.
--
-- Cambiar @fecha_desde / @fecha_hasta para otro período.
-- =============================================================

USE AuraStore;
GO

DECLARE @fecha_desde DATETIME = '2026-06-01T00:00:00';
DECLARE @fecha_hasta DATETIME = '2026-08-30T23:59:59';

SELECT
    l.nombre AS liga,
    COUNT(DISTINCT c.id_compra) AS cantidad_ventas,
    SUM(dc.cantidad_comprada) AS unidades_vendidas,
    SUM(dc.cantidad_comprada * dc.precio_unitario) AS total_vendido
FROM detalle_compra dc
JOIN compra c     ON c.id_compra = dc.id_compra
JOIN stock s      ON s.stock_id = dc.stock_id
JOIN producto p   ON p.id_producto = s.id_producto
JOIN liga l       ON l.id_liga = p.id_liga
WHERE c.fecha BETWEEN @fecha_desde AND @fecha_hasta
GROUP BY l.nombre
ORDER BY total_vendido DESC;
