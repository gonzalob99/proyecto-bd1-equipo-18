USE aura_store;
GO

SET NOCOUNT ON;
GO

CREATE OR ALTER PROCEDURE dbo.sp_registrar_compra
    @id_cliente INT,
    @id_metodo  INT,
    @id_producto INT,
    @talle       VARCHAR(5),
    @cantidad    INT,
    @id_compra_generada INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON; -- si algo falla, se revierte toda la transaccion

    DECLARE @stock_id INT;
    DECLARE @precio_actual DECIMAL(10,2);

    -- Validaciones previas (antes de abrir la transaccion)
    SELECT
        @stock_id      = s.stock_id,
        @precio_actual = p.precio_actual
    FROM stock s
    JOIN producto p ON p.id_producto = s.id_producto
    WHERE s.id_producto = @id_producto
      AND s.talle       = @talle;

    IF @stock_id IS NULL
    BEGIN
        RAISERROR('No existe stock cargado para ese producto y talle.', 16, 1);
        RETURN;
    END

    IF dbo.fn_verificar_disponibilidad_stock(@id_producto, @talle, @cantidad) = 0
    BEGIN
        RAISERROR('Stock insuficiente para completar la compra.', 16, 1);
        RETURN;
    END


    -- Registro de la compra
   
    BEGIN TRANSACTION;

    BEGIN TRY
        INSERT INTO compra (id_cliente, id_metodo, fecha)
        VALUES (@id_cliente, @id_metodo, GETDATE());

        SET @id_compra_generada = SCOPE_IDENTITY();

        -- Este INSERT dispara trg_actualizar_stock_despues_de_compra,
        -- que valida de nuevo el stock (control a nivel de motor,
        -- no solo a nivel de aplicacion) y lo descuenta si corresponde.
        INSERT INTO detalle_compra (id_compra, stock_id, cantidad_comprada, precio_unitario)
        VALUES (@id_compra_generada, @stock_id, @cantidad, @precio_actual);

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH
END;
