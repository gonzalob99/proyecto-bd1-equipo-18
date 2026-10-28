USE aura_store;
GO

CREATE OR ALTER FUNCTION dbo.fn_verificar_disponibilidad_stock
(
    @id_producto INT,
    @talle VARCHAR(5),
    @cantidad_requerida INT
)
RETURNS BIT
AS
BEGIN
    DECLARE @stock_actual INT;
    DECLARE @disponible BIT = 0;

    SELECT @stock_actual = cantidad_disponible
    FROM stock
    WHERE id_producto = @id_producto
      AND talle = @talle;

    IF @stock_actual IS NOT NULL AND @stock_actual >= @cantidad_requerida
        SET @disponible = 1;
    ELSE
        SET @disponible = 0;

    RETURN @disponible;
END;
GO
