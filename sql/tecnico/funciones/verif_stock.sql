-- =============================================================
-- Aura Store - Funcion de disponibilidad de stock
-- Etapa V - Procedimientos y funciones almacenadas
-- =============================================================
-- Ejecutar despues de crear la base y antes de registrar_compra.sql.
-- La funcion consulta el stock de un producto y talle y devuelve
-- un BIT. El procedimiento de compra la usa como validacion previa.
-- =============================================================

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

    -- =========================================================
    -- A. CONSULTA DE STOCK
    -- La combinacion de producto y talle identifica una fila de stock.
    -- Si no hay una fila para ese talle, @stock_actual queda en NULL.
    -- =========================================================
    SELECT @stock_actual = cantidad_disponible
    FROM stock
    WHERE id_producto = @id_producto
      AND talle = @talle;

    -- =========================================================
    -- B. RESULTADO DE DISPONIBILIDAD
    -- Devuelve 1 si alcanza el stock, incluso si se pide la cantidad
    -- exacta. Devuelve 0 si falta la fila o el stock es insuficiente.
    -- =========================================================
    IF @stock_actual IS NOT NULL AND @stock_actual >= @cantidad_requerida
        SET @disponible = 1;
    ELSE
        SET @disponible = 0;

    RETURN @disponible;
END;
GO
