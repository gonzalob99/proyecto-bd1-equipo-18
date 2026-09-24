# Etapa II: transformación al modelo relacional desde el DER

## Clientes y compras

### `cliente`

**Campos:** `id_cliente` (PK), `nombre`, `apellido`, `email`.  
**Decisión:** identifica a cada comprador. Un cliente puede realizar varias compras; `email` debería ser único según RN.02 de la Etapa I.

### `metodo_pago`

**Campos:** `id_metodo` (PK), `descripcion`.  
**Decisión:** separa los métodos de pago para que un mismo método pueda usarse en muchas compras sin repetir su descripción.

### `compra`

**Campos:** `id_compra` (PK), `id_cliente` (FK → `cliente.id_cliente`), `id_metodo` (FK → `metodo_pago.id_metodo`), `fecha`.  
**Decisión:** registra cada operación con su cliente, método de pago y fecha. Las relaciones `REALIZA` y `ABONA_CON` son 1:N, por eso sus claves foráneas quedan en `compra`.

## Catálogo y stock

### `liga`

**Campos:** `id_liga` (PK), `nombre`.  
**Decisión:** agrupa los productos por liga; una liga puede tener varios productos.

### `producto`

**Campos:** `id_producto` (PK), `id_liga` (FK → `liga.id_liga`), `nombre`, `descripcion`, `precio_actual`, `equipo`, `equipacion`.  
**Decisión:** contiene los datos actuales de cada camiseta. `id_liga` representa la relación 1:N `PERTENECE`; la disponibilidad se guarda aparte porque depende del talle.

### `stock`

**Campos:** `stock_id` (PK), `id_producto` (FK → `producto.id_producto`), `talle`, `cantidad_disponible`.  
**Decisión:** se agrega `stock_id` como identificador único para mantener una sola columna PK. En el DER, `Stock` es una entidad débil y `talle` distingue variantes de un producto; esa regla se conserva con **UNIQUE (`id_producto`, `talle`)**. Esta restricción evita dos filas para el mismo talle de un producto, pero no es otra PK.

## Detalle de cada compra

### `detalle_compra`

**Campos:** `id_detalle_compra` (PK), `id_compra` (FK → `compra.id_compra`), `stock_id` (FK → `stock.stock_id`), `cantidad_comprada`, `precio_unitario`.  
**Decisión:** transforma la relación N:M `INCLUYE` entre `compra` y `stock` en una tabla. Se agrega `id_detalle_compra` para tener una sola columna PK; **UNIQUE (`id_compra`, `stock_id`)** deja un renglón por variante en cada compra. `precio_unitario` conserva el precio cobrado aunque cambie `producto.precio_actual` (RN.09).
