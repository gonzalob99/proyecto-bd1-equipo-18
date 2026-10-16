-- =============================================================
-- Aura Store - Alerta General de Stock Crítico y Reposición
-- Etapa IV - Consultas y Casos de Uso
-- =============================================================
-- Caso de uso:
-- El encargado de compras y depósito necesita un reporte general
-- de todos los artículos cuyo stock disponible sea menor o igual
-- a un umbral mínimo de seguridad, priorizando los agotados.
--
-- Contenido temático: JOIN (INNER / LEFT), WHERE, ORDER BY, ISNULL.
-- =============================================================

USE aura_store;
GO

-- Umbral mínimo de stock configurable
DECLARE @umbral_minimo INT = 3;

SELECT
    p.id_producto,
    p.nombre AS producto,
    p.equipo,
    l.nombre AS liga,
    s.talle,
    ISNULL(s.cantidad_disponible, 0) AS stock_disponible,
    @umbral_minimo AS umbral_minimo
FROM producto p
INNER JOIN liga l ON l.id_liga = p.id_liga
LEFT JOIN stock s ON s.id_producto = p.id_producto
WHERE ISNULL(s.cantidad_disponible, 0) <= @umbral_minimo
ORDER BY
    ISNULL(s.cantidad_disponible, 0) ASC,
    p.nombre ASC,
    s.talle ASC;
