# Verificación de stock y auditoría de precios

**Proyecto Aura Store** · Etapa V

## Función de disponibilidad de stock

La función [`dbo.fn_verificar_disponibilidad_stock`](../../sql/tecnico/funciones/verif_stock.sql) recibe el identificador del producto, el talle y la cantidad requerida. Devuelve `1` cuando hay stock suficiente y `0` cuando el talle no tiene stock cargado o la cantidad es insuficiente. El procedimiento de compra la usa para hacer una consulta previa y valida el stock de nuevo al descontarlo dentro de la transacción.

```sql
USE aura_store;
GO

SELECT dbo.fn_verificar_disponibilidad_stock(1, 'L', 1) AS prueba_valida;
SELECT dbo.fn_verificar_disponibilidad_stock(1, 'L', 99999) AS prueba_excedida;
```

## Trigger de auditoría de precios

El trigger [`dbo.trg_auditar_precio_producto`](../../sql/tecnico/triggers/auditar_precio_producto.sql) registra los cambios del precio de catálogo de las camisetas. Se ejecuta después de un `UPDATE` sobre `dbo.producto` y une `deleted` (valores anteriores) con `inserted` (valores nuevos) por `id_producto`. Inserta una fila en `dbo.auditoria_precio_producto` por cada producto cuyo `precio_actual` efectivamente cambió, incluso cuando una sola sentencia actualiza varios productos.

La fila guarda el identificador del producto, ambos precios, la fecha y hora en UTC y el login que abrió la sesión de SQL Server. El identificador se guarda sin clave foránea para conservar el historial si se elimina el producto. La auditoría forma parte de la misma transacción que la actualización de precios.

### Demostración con los datos de prueba

El ejemplo aumenta el precio de las camisetas de Boca y River en una sola sentencia y asigna a la del Real Madrid su precio vigente. También ejecuta un `UPDATE` sobre la descripción de la camiseta de Boca. La primera consulta debe devolver dos filas, una por cada precio que subió. La segunda debe devolver cero porque el `ROLLBACK` revierte los precios y los registros de la auditoría.

```sql
USE aura_store;
GO

DECLARE @ultima_auditoria BIGINT = ISNULL(
    (SELECT MAX(id_auditoria) FROM dbo.auditoria_precio_producto), 0
);

BEGIN TRANSACTION;

UPDATE dbo.producto
SET precio_actual = CASE WHEN id_producto IN (1, 2)
                         THEN precio_actual + 1000.00
                         ELSE precio_actual END
WHERE id_producto IN (1, 2, 3);

UPDATE dbo.producto
SET descripcion = 'Descripcion temporal para la prueba'
WHERE id_producto = 1;

SELECT id_producto, precio_anterior, precio_nuevo, fecha_cambio_utc, login_cambio
FROM dbo.auditoria_precio_producto
WHERE id_auditoria > @ultima_auditoria
  AND id_producto IN (1, 2, 3)
ORDER BY id_producto;

ROLLBACK TRANSACTION;

SELECT COUNT(*) AS cambios_de_la_prueba_persistidos
FROM dbo.auditoria_precio_producto
WHERE id_auditoria > @ultima_auditoria
  AND id_producto IN (1, 2, 3);
```
