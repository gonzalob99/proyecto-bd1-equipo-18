-- =============================================================
-- Aura Store - Confirmacion y reversion de compras
-- Etapa V - Manejo de transacciones
-- =============================================================
-- Ejecutar TODO el archivo en una misma conexion de SQL Server,
-- sobre la base de prueba y con los pasos 2 a 4 del README hechos.
-- La prueba llama al procedimiento que registra las compras.
-- La compra exitosa se revierte al terminar su caso. SQL Server
-- puede dejar saltos en los identificadores autogenerados.
-- =============================================================

USE aura_store;
GO

SET NOCOUNT ON;
SET IMPLICIT_TRANSACTIONS OFF;

IF @@TRANCOUNT <> 0
    THROW 51000, 'Ejecutar la prueba sin una transaccion abierta.', 1;

IF OBJECT_ID(N'dbo.sp_registrar_compra', N'P') IS NULL
   OR OBJECT_ID(N'dbo.fn_verificar_disponibilidad_stock', N'FN') IS NULL
    THROW 51001, 'Instalar la funcion de stock y el procedimiento de compra.', 1;

-- =============================================================
-- DATOS DE CONTROL
-- Se usa un cliente y un talle validos con stock suficiente.
-- El metodo 4 existe en el DML. El metodo -1 debe estar ausente
-- para que falle el alta del encabezado en el segundo caso.
-- =============================================================
PRINT 'Estado inicial';

DECLARE @id_cliente INT = 2, @id_producto INT = 1, @id_metodo INT = 4;
DECLARE @talle VARCHAR(5) = 'M', @metodo_inexistente INT = -1;
DECLARE @stock_id INT, @stock_antes INT, @stock_despues INT;
DECLARE @compras_antes BIGINT, @compras_despues BIGINT;
DECLARE @detalles_antes BIGINT, @detalles_despues BIGINT;
DECLARE @compra_generada INT, @numero_error INT, @mensaje_error NVARCHAR(4000);

SELECT @stock_id = stock_id, @stock_antes = cantidad_disponible
FROM dbo.stock
WHERE id_producto = @id_producto AND talle = @talle;

IF @stock_antes IS NULL OR @stock_antes < 1
   OR NOT EXISTS (SELECT 1 FROM dbo.cliente WHERE id_cliente = @id_cliente)
   OR NOT EXISTS (SELECT 1 FROM dbo.metodo_pago WHERE id_metodo = @id_metodo)
   OR EXISTS (SELECT 1 FROM dbo.metodo_pago WHERE id_metodo = @metodo_inexistente)
    THROW 51002, 'Cargar los datos de ejemplo. El producto 1 talle M necesita stock y el metodo -1 debe estar libre.', 1;

-- Se acotan los recuentos al cliente y al stock de la prueba.
SELECT @compras_antes = COUNT_BIG(*) FROM dbo.compra WHERE id_cliente = @id_cliente;
SELECT @detalles_antes = COUNT_BIG(*) FROM dbo.detalle_compra WHERE stock_id = @stock_id;

SELECT @stock_antes AS stock_inicial, @compras_antes AS compras_del_cliente,
       @detalles_antes AS detalles_del_stock, @@TRANCOUNT AS transacciones_abiertas;

-- =============================================================
-- A. COMMIT DEL PROCEDIMIENTO
-- El procedimiento registra el encabezado y el detalle y
-- descuenta una unidad. Su COMMIT deja abierto solo el nivel
-- externo, que se revierte para poder repetir la demostracion.
-- =============================================================
PRINT 'A. Compra valida y confirmacion de su transaccion interna';

DECLARE @compra_valida INT;

BEGIN TRY
    BEGIN TRANSACTION;

    EXEC dbo.sp_registrar_compra
        @id_cliente = @id_cliente, @id_metodo = @id_metodo,
        @id_producto = @id_producto, @talle = @talle, @cantidad = 1,
        @id_compra_generada = @compra_valida OUTPUT;

    SELECT @compra_valida AS compra_generada, @stock_antes AS stock_antes,
           cantidad_disponible AS stock_tras_la_compra,
           @@TRANCOUNT AS transacciones_abiertas_al_salir
    FROM dbo.stock
    WHERE stock_id = @stock_id;

    IF @@TRANCOUNT <> 1
       OR NOT EXISTS (SELECT 1 FROM dbo.compra WHERE id_compra = @compra_valida)
       OR NOT EXISTS (SELECT 1 FROM dbo.detalle_compra WHERE id_compra = @compra_valida AND stock_id = @stock_id)
       OR NOT EXISTS (SELECT 1 FROM dbo.stock WHERE stock_id = @stock_id AND cantidad_disponible = @stock_antes - 1)
        THROW 51003, 'La compra valida debia registrar el encabezado y el detalle y cerrar su nivel de transaccion.', 1;

    ROLLBACK TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    THROW;
END CATCH;

-- =============================================================
-- B. FALLO DENTRO DE LA TRANSACCION
-- Se espera el error 547 de FK_compra_metodo_pago. La prueba no
-- abre una transaccion externa para observar el ROLLBACK propio
-- del procedimiento y comprobar que no deja una transaccion abierta.
-- =============================================================
PRINT 'B. Falla al registrar una compra con un metodo inexistente';

BEGIN TRY
    EXEC dbo.sp_registrar_compra
        @id_cliente = @id_cliente, @id_metodo = @metodo_inexistente,
        @id_producto = @id_producto, @talle = @talle, @cantidad = 1,
        @id_compra_generada = @compra_generada OUTPUT;
END TRY
BEGIN CATCH
    SELECT @numero_error = ERROR_NUMBER(), @mensaje_error = ERROR_MESSAGE();
END CATCH;

DECLARE @transacciones_abiertas INT = @@TRANCOUNT;

-- Si hay una falla en el procedimiento, se limpia cualquier
-- transaccion pendiente tras guardar el valor que se va a verificar.
IF @transacciones_abiertas > 0
    ROLLBACK TRANSACTION;

SELECT @numero_error AS numero_error, @mensaje_error AS mensaje_error;

-- =============================================================
-- C. ESTADO DESPUES DEL FALLO
-- Los valores iniciales y finales deben coincidir. Con el DML
-- recien cargado, el stock vuelve a 15 y no aparece una compra nueva.
-- =============================================================
PRINT 'C. Estado despues del rollback';

SELECT @stock_despues = cantidad_disponible FROM dbo.stock WHERE stock_id = @stock_id;
SELECT @compras_despues = COUNT_BIG(*) FROM dbo.compra WHERE id_cliente = @id_cliente;
SELECT @detalles_despues = COUNT_BIG(*) FROM dbo.detalle_compra WHERE stock_id = @stock_id;

SELECT @stock_antes AS stock_antes, @stock_despues AS stock_despues,
       @compras_antes AS compras_antes, @compras_despues AS compras_despues,
       @detalles_antes AS detalles_antes, @detalles_despues AS detalles_despues,
       @transacciones_abiertas AS transacciones_abiertas_al_salir;

IF @numero_error IS NULL OR @numero_error <> 547
   OR @mensaje_error NOT LIKE N'%FK_compra_metodo_pago%'
    THROW 51004, 'Se esperaba un error de la clave foranea del metodo de pago.', 1;

IF @transacciones_abiertas <> 0 OR @compra_generada IS NOT NULL
   OR @stock_despues IS NULL OR @stock_despues <> @stock_antes
   OR @compras_antes <> @compras_despues OR @detalles_antes <> @detalles_despues
    THROW 51005, 'Las pruebas deben terminar con los recuentos y el stock iniciales y sin transacciones abiertas.', 1;

PRINT 'Prueba correcta. El rollback restauro el stock y cerro la transaccion.';
