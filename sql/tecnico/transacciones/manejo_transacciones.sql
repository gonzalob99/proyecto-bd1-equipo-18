-- Aura Store - Manejo de transacciones (Etapa V)
USE aura_store;
GO

-- 1. Insertar datos de prueba cumpliendo estrictamente con todas las columnas obligatorias

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

-- Producto (incluyendo tanto 'equipo' como 'equipacion')
IF NOT EXISTS (SELECT 1 FROM producto WHERE id_producto = 1)
BEGIN
    SET IDENTITY_INSERT producto ON;
    INSERT INTO producto (id_producto, id_liga, nombre, precio_actual, equipo, equipacion) 
    VALUES (1, 1, 'Camiseta Titular', 1000.00, 'Equipo Local', 'Principal');
    SET IDENTITY_INSERT producto OFF;
END

-- Stock (asociado al producto 1)
IF NOT EXISTS (SELECT 1 FROM stock WHERE stock_id = 1)
BEGIN
    SET IDENTITY_INSERT stock ON;
    INSERT INTO stock (stock_id, id_producto, cantidad_disponible, talle) VALUES (1, 1, 10, 'L');
    SET IDENTITY_INSERT stock OFF;
END
GO

-- 2. Ejecutar la transacción de compra
DECLARE @id_cliente INT = 1;
DECLARE @id_metodo INT = 1;
DECLARE @stock_id INT = 1;
DECLARE @cantidad_comprada INT = 1;

BEGIN TRY
    -- Arrancamos la transacción
    BEGIN TRANSACTION;

    -- Descontar stock solo si alcanza la cantidad disponible.
    UPDATE dbo.stock
    SET cantidad_disponible = cantidad_disponible - @cantidad_comprada
    WHERE stock_id = @stock_id
      AND @cantidad_comprada > 0
      AND cantidad_disponible >= @cantidad_comprada;

    IF @@ROWCOUNT = 0
        THROW 50001, 'Stock insuficiente o cantidad invalida.', 1;

    -- Registrar compra principal
    INSERT INTO compra (id_cliente, id_metodo)
    VALUES (@id_cliente, @id_metodo);

    DECLARE @id_compra_actual INT = SCOPE_IDENTITY();

    -- Obtener precio del producto
    DECLARE @precio_unitario DECIMAL(10,2);
    SELECT @precio_unitario = p.precio_actual
    FROM stock s
    JOIN producto p ON s.id_producto = p.id_producto
    WHERE s.stock_id = @stock_id;

    -- Registrar detalle de compra
    INSERT INTO detalle_compra (id_compra, stock_id, cantidad_comprada, precio_unitario)
    VALUES (@id_compra_actual, @stock_id, @cantidad_comprada, @precio_unitario);

    -- Confirmar cambios
    COMMIT TRANSACTION;
    PRINT 'Transaccion exitosa.';

END TRY
BEGIN CATCH
    -- Revertir en caso de error
    IF @@TRANCOUNT > 0
    BEGIN
        ROLLBACK TRANSACTION;
    END

    PRINT 'Ocurrio un error, se cancelo la operacion. ' + ERROR_MESSAGE();
END CATCH;
GO
