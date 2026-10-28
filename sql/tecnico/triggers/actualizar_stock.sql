USE aura_store;


GO
CREATE OR ALTER TRIGGER dbo.trg_actualizar_stock_despues_de_compra
    ON dbo.detalle_compra
    AFTER INSERT
    AS BEGIN
           SET NOCOUNT ON;
           -- Validacion: verificar si algun item insertado supera el stock disponible
           IF EXISTS (SELECT 1
                      FROM   inserted AS i
                             INNER JOIN
                             stock AS s
                             ON i.stock_id = s.stock_id
                      WHERE  s.cantidad_disponible < i.cantidad_comprada)
               BEGIN
                   RAISERROR ('No hay stock suficiente para realizar la venta de uno o mas productos seleccionados.', 16, 1);
                   ROLLBACK;
                   RETURN;
               END
           -- Actualizacion: descontar las cantidades compradas del stock disponible
           UPDATE s
           SET    s.cantidad_disponible = s.cantidad_disponible - i.cantidad_comprada
           FROM   dbo.stock AS s
                  INNER JOIN
                  inserted AS i
                  ON s.stock_id = i.stock_id;
       END