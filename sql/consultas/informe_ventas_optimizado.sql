-- =============================================================
-- Aura Store - Informe de ventas con filtro por fecha e indice
-- Etapa V - Optimizacion de consultas
-- =============================================================
-- Retoma sql/consultas/informe_ventas.sql de la Etapa IV.
-- Ejecutar antes sql/tecnico/indices/crear_indices.sql.
-- El optimizador decide si utiliza el indice segun el volumen y
-- el rango consultado. Con pocos registros puede preferir un Scan.
-- =============================================================

USE aura_store;
GO

DECLARE @fecha_desde DATE = '20260801';
DECLARE @fecha_hasta DATE = '20260930';

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
-- No se aplica una funcion sobre c.fecha, para permitir buscar
-- el rango en el indice. DATEADD actua solo sobre el parametro.
-- El limite exclusivo incluye el ultimo dia completo, aun si
-- la fecha de la compra contiene fracciones de segundo.
WHERE c.fecha >= @fecha_desde
  AND c.fecha < DATEADD(DAY, 1, @fecha_hasta)
GROUP BY l.nombre
ORDER BY total_vendido DESC;
