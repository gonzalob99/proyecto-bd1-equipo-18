-- =============================================================
-- Aura Store - Ranking de Productos Más Vendidos
-- Etapa IV - Consultas y Casos de Uso
-- =============================================================
-- Caso de uso:
-- El área comercial y de compras necesita conocer cuáles son los
-- productos con mayor salida (prendas estrella) para planificar
-- compras a proveedores, reposición de stock y campañas destacadas.
--
-- Contenido temático: TOP, JOIN (INNER), GROUP BY, SUM, COUNT, ORDER BY.
-- =============================================================

USE aura_store;
GO

-- Límite de posiciones del ranking a mostrar (configurable)
-- Trae el Top 5 de artículos con mayor cantidad de unidades vendidas
SELECT TOP 5
    p.id_producto,
    p.nombre AS producto,
    p.equipo,
    l.nombre AS liga,
    SUM(dc.cantidad_comprada) AS unidades_vendidas,
    COUNT(DISTINCT c.id_compra) AS cantidad_operaciones,
    SUM(dc.cantidad_comprada * dc.precio_unitario) AS recaudacion_total
FROM detalle_compra dc
INNER JOIN compra c ON c.id_compra = dc.id_compra
INNER JOIN stock s ON s.stock_id = dc.stock_id
INNER JOIN producto p ON p.id_producto = s.id_producto
INNER JOIN liga l ON l.id_liga = p.id_liga
GROUP BY
    p.id_producto,
    p.nombre,
    p.equipo,
    l.nombre
ORDER BY
    unidades_vendidas DESC,
    recaudacion_total DESC;
