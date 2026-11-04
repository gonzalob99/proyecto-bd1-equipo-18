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

1. Busca el `stock_id` y el precio actual del producto para el talle indicado. Si no existe stock cargado para ese producto y talle, devuelve un error y termina.
2. Verifica la disponibilidad con la función `dbo.fn_verificar_disponibilidad_stock`. Si no alcanza el stock, devuelve un error y termina, antes de abrir la transacción.
3. Dentro de una transacción, inserta el encabezado en `compra` y obtiene su id con `SCOPE_IDENTITY()`.
4. Inserta el renglón en `detalle_compra` con el precio actual. Este insert dispara `dbo.trg_actualizar_stock_despues_de_compra`, que valida de nuevo el stock y lo descuenta.
5. Confirma la transacción. Si algo falla, hace `ROLLBACK` y vuelve a lanzar el error.

**Decisión de diseño:** el procedimiento no descuenta el stock por su cuenta. Ese descuento lo hace el trigger, para no hacerlo dos veces. El procedimiento solo se encarga de la lógica de la venta y de dar un mensaje de error claro.

## 5. Script y pruebas

- Definición: `sql/tecnico/procedimientos/registrar_compra.sql`
- Demostración: `sql/tecnico/procedimientos/pruebas_registrar_compra.sql`

Requiere haber ejecutado antes `sql/tecnico/funciones/verif_stock.sql` y `sql/tecnico/triggers/actualizar_stock.sql`.

### Caso correcto

Producto 1, talle M, cantidad 1 (stock inicial 15).

Resultado obtenido:
- Se creó la compra 15 (cliente 2, método 4) y su detalle 16 (stock_id 2, cantidad 1, precio 95999.00).
- El stock de producto 1 talle M pasó de 15 a 14.
- El total de compras pasó de 14 a 15.

### Caso incorrecto

Producto 1, talle M, cantidad 99999.

Resultado esperado: error "Stock insuficiente para completar la compra", sin compra ni detalle nuevos. Verificado porque el total de compras quedó en 15 después del intento.

## 6. Observación sobre la demostración

Cada ejecución del caso correcto registra una compra nueva y descuenta stock. Para repetir la demostración desde cero, hay que recargar la base con `sql/dml/datos_prueba.sql`.
