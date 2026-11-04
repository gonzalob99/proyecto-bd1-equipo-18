USE aura_store;
GO


-- Ejemplo


-- Caso correcto: producto 1, talle M, 1 unidad (stock suficiente)
DECLARE @nueva_compra INT;

EXEC dbo.sp_registrar_compra
    @id_cliente  = 2,
    @id_metodo   = 4,
    @id_producto = 1,
    @talle       = 'M',
    @cantidad    = 1,
    @id_compra_generada = @nueva_compra OUTPUT;

SELECT @nueva_compra AS id_compra_generada;
SELECT * FROM compra WHERE id_compra = @nueva_compra;
SELECT * FROM detalle_compra WHERE id_compra = @nueva_compra;
GO

-- Caso incorrecto: pedir mas cantidad de la que hay disponible
DECLARE @compra_fallida INT;

BEGIN TRY
    EXEC dbo.sp_registrar_compra
        @id_cliente  = 2,
        @id_metodo   = 4,
        @id_producto = 1,
        @talle       = 'M',
        @cantidad    = 99999,
        @id_compra_generada = @compra_fallida OUTPUT;
END TRY
BEGIN CATCH
    PRINT 'Error capturado (esperado): ' + ERROR_MESSAGE();
END CATCH
GO