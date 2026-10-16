-- =============================================================
-- Aura Store - Consulta de Disponibilidad de Stock por Producto
-- Etapa IV - Consultas y Casos de Uso
-- =============================================================
-- Caso de uso:
-- Simula una consulta originada desde el frontend/backend donde
-- un usuario o vendedor busca un producto por su nombre (o coincidencia
-- parcial) y necesita verificar la disponibilidad en todos sus talles
-- y si requiere reposición según el umbral mínimo definido.
--
-- Contenido temático: JOIN (LEFT), WHERE con LIKE y subconsulta, ORDER BY.
-- =============================================================

USE aura_store;
GO

-- Parámetros de búsqueda
DECLARE @umbral_minimo INT = 3;
DECLARE @nombre_busqueda VARCHAR(100) = 'Boca';

SELECT
    p.id_producto,
    p.nombre AS producto,
    p.equipo,
    s.talle,
    ISNULL(s.cantidad_disponible, 0) AS stock_disponible,
    @umbral_minimo AS umbral_minimo
FROM producto p
LEFT JOIN stock s ON s.id_producto = p.id_producto
WHERE p.id_producto IN (
    -- Subconsulta: resuelve los productos que coinciden con el término de búsqueda ingresado
    SELECT sub_p.id_producto
    FROM producto sub_p
    WHERE sub_p.nombre LIKE '%' + @nombre_busqueda + '%'
       OR sub_p.equipo LIKE '%' + @nombre_busqueda + '%'
)
ORDER BY
    p.nombre ASC,
    s.talle ASC;
