-- =============================================================
-- Aura Store - Análisis de Ventas por Método de Pago
-- Etapa IV - Consultas y Casos de Uso
-- =============================================================
-- Caso de uso:
-- El área de administración y finanzas necesita analizar la
-- recaudación total según el medio de cobro utilizado (efectivo,
-- transferencia, tarjetas, etc.) para controlar la liquidez,
-- comisiones financieras y hábitos de pago de los clientes.
--
-- Contenido temático: JOIN (INNER / LEFT), GROUP BY, SUM, COUNT,
--                     Subconsulta escalar para cálculo de porcentajes,
--                     ISNULL, ROUND, ORDER BY.
-- =============================================================

USE aura_store;
GO

SELECT
    mp.id_metodo,
    mp.descripcion AS metodo_pago,
    COUNT(DISTINCT c.id_compra) AS cantidad_operaciones,
    ISNULL(SUM(dc.cantidad_comprada * dc.precio_unitario), 0) AS total_recaudado,
    -- Subconsulta escalar: calcula el porcentaje sobre la recaudación general total
    ROUND(
        ISNULL(SUM(dc.cantidad_comprada * dc.precio_unitario), 0) * 100.0 / NULLIF((
            SELECT SUM(dc_total.cantidad_comprada * dc_total.precio_unitario)
            FROM detalle_compra dc_total
        ), 0),
        2
    ) AS porcentaje_recaudacion
FROM metodo_pago mp
LEFT JOIN compra c           ON c.id_metodo = mp.id_metodo
LEFT JOIN detalle_compra dc  ON dc.id_compra = c.id_compra
GROUP BY
    mp.id_metodo,
    mp.descripcion
ORDER BY
    total_recaudado DESC;
