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

El script toma el stock inicial del producto 1, talle M. Con los datos recién cargados hay 15 unidades.

- La función devuelve `1` al pedir todo el stock y `0` al superar ese límite o consultar un talle sin stock cargado.
- Al registrar una compra por encima del stock, el procedimiento devuelve «Stock insuficiente para completar la compra» y conserva las existencias.
- Una compra válida genera un encabezado para el cliente 2 con el método de pago 4 y un detalle de una unidad al precio vigente. Con los datos iniciales, el precio es `95999.00` y el stock pasa de 15 a 14.

El script muestra la compra dentro de una transacción de prueba y luego la revierte. Se puede repetir con los mismos datos, aunque SQL Server puede dejar saltos en los identificadores autogenerados.

## 6. Prueba de transacciones

[pruebas_transacciones.sql](../../sql/tecnico/transacciones/pruebas_transacciones.sql) muestra el efecto del `COMMIT` interno en una compra válida. El `ROLLBACK` de la transacción externa revierte esa compra de ejemplo.

El segundo caso llama al procedimiento con stock suficiente y un método de pago inexistente. Después de descontar stock, la inserción del encabezado falla con el error `547` de `FK_compra_metodo_pago`. Se espera que el procedimiento restaure el stock, conserve los recuentos de compras y detalles y deje cero transacciones abiertas.
