-- =============================================================
-- Aura Store - Factura / Comprobante de una compra
-- Etapa IV - Consultas y Casos de Uso
-- =============================================================
-- Consolida encabezado (cliente, fecha, método de pago) y detalle
-- de una compra puntual, calculando el subtotal de cada renglón
-- y el total acumulado línea a línea (como en un ticket impreso).
--
-- Cambiar @id_compra por el id de la compra a facturar.
-- =============================================================

USE aura_store;
GO

DECLARE @id_compra INT = 7;

SELECT
    c.id_compra,
    cli.nombre + ' ' + cli.apellido AS cliente,
    cli.email,
    c.fecha,
    mp.descripcion AS metodo_pago,
    p.nombre AS producto,
    p.equipo,
    s.talle,
    dc.cantidad_comprada,
    dc.precio_unitario,
    dc.cantidad_comprada * dc.precio_unitario AS subtotal_renglon,
    SUM(dc.cantidad_comprada * dc.precio_unitario) OVER (
        ORDER BY dc.id_detalle_compra
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS total_acumulado
FROM compra c
JOIN cliente cli        ON cli.id_cliente = c.id_cliente
JOIN metodo_pago mp     ON mp.id_metodo = c.id_metodo
JOIN detalle_compra dc  ON dc.id_compra = c.id_compra
JOIN stock s            ON s.stock_id = dc.stock_id
JOIN producto p         ON p.id_producto = s.id_producto
WHERE c.id_compra = @id_compra
ORDER BY dc.id_detalle_compra;