-- =============================================================
-- Aura Store - Registro de una compra con transacciones explicitas
-- Etapa V - Manejo de transacciones
-- =============================================================
-- Ejecutar sobre la base de prueba con las tablas creadas y sin
-- una transaccion abierta. Si la base tiene el trigger de stock
-- anterior, retirarlo con el paso 4 del README antes del ejemplo.
-- El COMMIT deja guardados la compra y el descuento de stock.
-- =============================================================

USE aura_store;
GO

-- =========================================================
-- A. PREPARACION DE DATOS
-- Se insertan las filas de ejemplo que falten. IDENTITY_INSERT
-- permite asignarles los ids usados por el script. Estas filas
-- se insertan antes de abrir la transaccion de compra.
-- =========================================================

-- Método de pago
IF NOT EXISTS (SELECT 1 FROM metodo_pago WHERE id_metodo = 1)
BEGIN
    SET IDENTITY_INSERT metodo_pago ON;
    INSERT INTO metodo_pago (id_metodo, descripcion) VALUES (1, 'Efectivo');
    SET IDENTITY_INSERT metodo_pago OFF;
END

-- Cliente
IF NOT EXISTS (SELECT 1 FROM cliente WHERE id_cliente = 1)
BEGIN
    SET IDENTITY_INSERT cliente ON;
    INSERT INTO cliente (id_cliente, nombre, apellido, email) VALUES (1, 'Francisco', 'Gomez', 'francisco@email.com');
    SET IDENTITY_INSERT cliente OFF;
END

-- Liga
IF NOT EXISTS (SELECT 1 FROM liga WHERE id_liga = 1)
BEGIN
    SET IDENTITY_INSERT liga ON;
    INSERT INTO liga (id_liga, nombre) VALUES (1, 'Liga Principal');
    SET IDENTITY_INSERT liga OFF;
END

-- Producto de la liga de ejemplo
IF NOT EXISTS (SELECT 1 FROM producto WHERE id_producto = 1)
BEGIN
    SET IDENTITY_INSERT producto ON;
    INSERT INTO producto (id_producto, id_liga, nombre, precio_actual, equipo, equipacion) 
    VALUES (1, 1, 'Camiseta Titular', 1000.00, 'Equipo Local', 'Principal');
    SET IDENTITY_INSERT producto OFF;
END

-- Stock de talle L para el producto de ejemplo
IF NOT EXISTS (SELECT 1 FROM stock WHERE stock_id = 1)
BEGIN
    SET IDENTITY_INSERT stock ON;
    INSERT INTO stock (stock_id, id_producto, cantidad_disponible, talle) VALUES (1, 1, 10, 'L');
    SET IDENTITY_INSERT stock OFF;
END
GO

-- =========================================================
-- B. TRANSACCION DE COMPRA
-- Se descuenta una unidad del stock 1 y se guarda una compra con
-- su detalle. El COMMIT confirma el descuento y ambas inserciones.
-- =========================================================
DECLARE @id_cliente INT = 1;
DECLARE @id_metodo INT = 1;
DECLARE @stock_id INT = 1;
DECLARE @cantidad_comprada INT = 1;

BEGIN TRY
    BEGIN TRANSACTION;

    -- Se comprueba que alcance el stock en la misma sentencia
    -- que lo descuenta. Si no se actualiza una fila, se aborta la compra.
    UPDATE dbo.stock
    SET cantidad_disponible = cantidad_disponible - @cantidad_comprada
    WHERE stock_id = @stock_id
      AND @cantidad_comprada > 0
      AND cantidad_disponible >= @cantidad_comprada;

    IF @@ROWCOUNT = 0
        THROW 50001, 'Stock insuficiente o cantidad invalida.', 1;

    -- Se guarda el encabezado y se obtiene el id para el detalle.
    INSERT INTO compra (id_cliente, id_metodo)
    VALUES (@id_cliente, @id_metodo);

    DECLARE @id_compra_actual INT = SCOPE_IDENTITY();

    -- Se toma el precio de catalogo para guardarlo en el detalle.
    DECLARE @precio_unitario DECIMAL(10,2);
    SELECT @precio_unitario = p.precio_actual
    FROM stock s
    JOIN producto p ON s.id_producto = p.id_producto
    WHERE s.stock_id = @stock_id;

    INSERT INTO detalle_compra (id_compra, stock_id, cantidad_comprada, precio_unitario)
    VALUES (@id_compra_actual, @stock_id, @cantidad_comprada, @precio_unitario);

    COMMIT TRANSACTION;
    PRINT 'Transaccion exitosa.';

END TRY
-- =========================================================
-- C. MANEJO DE ERRORES
-- Si falla la compra, se revierte la transaccion abierta y se
-- muestra el error en la pestana Mensajes de SSMS.
-- =========================================================
BEGIN CATCH
    IF @@TRANCOUNT > 0
    BEGIN
        ROLLBACK TRANSACTION;
    END

    PRINT 'Ocurrio un error, se cancelo la operacion. ' + ERROR_MESSAGE();
END CATCH;
GO
