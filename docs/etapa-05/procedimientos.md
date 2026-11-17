# Procedimientos Almacenados

**Proyecto:** Aura Store — Sistema de gestión para un comercio de indumentaria deportiva
**Etapa V:** Procedimientos y funciones almacenadas

## 1. Definición y objetivo

Un procedimiento almacenado es un programa SQL guardado dentro del motor que ejecuta varias operaciones como una única llamada. Su objetivo es centralizar en la base una lógica que de otro modo cada aplicación tendría que repetir.

## 2. Ventajas y aplicaciones

- Reutilizan la lógica de negocio desde cualquier cliente.
- Evitan que cada aplicación arme la venta con sentencias sueltas.
- Centralizan reglas de negocio en un único componente.
- Facilitan la seguridad: al usuario se le puede dar permiso de ejecución sobre el procedimiento sin darle acceso directo a las tablas.

## 3. Implementación en SQL Server Express

`CREATE OR ALTER PROCEDURE` con parámetros de entrada y un parámetro `OUTPUT` para devolver el id de la compra generada. Dentro del procedimiento se usa `BEGIN TRANSACTION` con `TRY/CATCH` y `SET XACT_ABORT ON` para que una falla revierta todo.

## 4. Caso concreto aplicado: `dbo.sp_registrar_compra`

**Problema de negocio:** registrar una compra de un producto en un talle, sin que el usuario deba ejecutar varias consultas por separado ni repetir las validaciones de stock.

**Parámetros:** `@id_cliente`, `@id_metodo`, `@id_producto`, `@talle`, `@cantidad` y, como salida, `@id_compra_generada`.

**Pasos que realiza:**

1. Valida que la cantidad sea positiva. Busca el `stock_id` y el precio actual del producto para el talle indicado. Si no existe stock cargado para ese producto y talle, devuelve un error y termina.
2. Verifica la disponibilidad con la función `dbo.fn_verificar_disponibilidad_stock`. Si no alcanza el stock, devuelve un error y termina, antes de abrir la transacción.
3. Dentro de una transacción, verifica y descuenta el stock en una sola sentencia `UPDATE`. Si otra compra consumió el stock desde la consulta inicial, el `UPDATE` no afecta filas y el procedimiento devuelve un error.
4. Inserta el encabezado en `compra`, obtiene su id con `SCOPE_IDENTITY()` e inserta el renglón en `detalle_compra` con el precio actual.
5. Confirma la transacción. Si algo falla, hace `ROLLBACK` del descuento y de cualquier inserción realizada, y vuelve a lanzar el error.

Las ventas nuevas se registran con `dbo.sp_registrar_compra` para que la validación, el descuento de stock y la venta se ejecuten en la misma transacción.

## 5. Script y pruebas

- Definición: `sql/tecnico/procedimientos/registrar_compra.sql`
- Demostración: `sql/tecnico/procedimientos/pruebas_registrar_compra.sql`

Instalar y actualizar los scripts según la [puesta en marcha](../../README.md#puesta-en-marcha).

### Caso correcto

Producto 1, talle M, cantidad 1 (stock inicial 15).

Con los datos de prueba recién cargados se esperan estos resultados.

 - Se crea la compra 15 (cliente 2, método 4) y su detalle 16 (stock_id 2, cantidad 1, precio 95999.00).
 - El stock de producto 1 talle M pasa de 15 a 14.
 - El total de compras pasa de 14 a 15.

### Caso incorrecto

Producto 1, talle M, cantidad 99999.

Se espera el error «Stock insuficiente para completar la compra». El total de compras queda en 15 y el stock sigue en 14.

## 6. Observación sobre la demostración

Cada ejecución del caso correcto registra una compra nueva y descuenta stock. Para repetir la demostración desde cero, hay que recargar la base con `sql/dml/datos_prueba.sql`.
