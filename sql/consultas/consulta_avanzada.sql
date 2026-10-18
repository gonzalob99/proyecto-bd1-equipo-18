-- =============================================================
-- Aura Store - Consulta de negocio avanzada
-- Etapa V - Consultas SQL
-- =============================================================
-- Clientes cuyo gasto total supera el promedio de gasto de todos
-- los clientes, junto con la cantidad de compras que realizaron.
--
-- Combina 3 tablas (cliente, compra, detalle_compra) con JOIN,
-- y filtra con HAVING contra una subconsulta que calcula el
-- promedio de gasto por cliente.
-- =============================================================

USE aura_store;
GO

SELECT
    cli.id_cliente,
    cli.nombre + ' ' + cli.apellido AS cliente,
    COUNT(DISTINCT c.id_compra) AS cantidad_compras,
    SUM(dc.cantidad_comprada * dc.precio_unitario) AS gasto_total
FROM cliente cli
JOIN compra c           ON c.id_cliente = cli.id_cliente
JOIN detalle_compra dc  ON dc.id_compra = c.id_compra
GROUP BY cli.id_cliente, cli.nombre, cli.apellido
HAVING SUM(dc.cantidad_comprada * dc.precio_unitario) > (
    -- Subconsulta: promedio de gasto total, calculado por cliente
    SELECT AVG(gasto_cliente.total)
    FROM (
        SELECT SUM(dc2.cantidad_comprada * dc2.precio_unitario) AS total
        FROM compra c2
        JOIN detalle_compra dc2 ON dc2.id_compra = c2.id_compra
        GROUP BY c2.id_cliente
    ) AS gasto_cliente
)
ORDER BY gasto_total DESC;
