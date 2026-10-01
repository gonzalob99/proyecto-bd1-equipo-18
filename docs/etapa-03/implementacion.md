# Implementación

**Proyecto:** Aura Store — Sistema de gestión para un comercio de indumentaria deportiva
**Etapa III:** Implementación 

---

## 1. Motor de base de datos

Se eligió **SQL Server (T-SQL)** como motor de base de datos.

---

## 2. Resumen de tablas

| Tabla | Descripción | Clave primaria |
|---|---|---|
| `liga` | Liga o torneo al que pertenece un producto (ej. Liga Profesional Argentina, Premier League). | `id_liga` |
| `metodo_pago` | Medios de pago disponibles (efectivo, tarjeta, transferencia, etc.). | `id_metodo_pago` |
| `cliente` | Personas que realizan compras en el comercio. | `id_cliente` |
| `producto` | Indumentaria deportiva a la venta (camisetas de equipos), vinculada a una liga. | `id_producto` |
| `stock` | Cantidad disponible de cada producto, desglosada por talle. | `id_stock` |
| `compra` | Encabezado de una compra: cliente, método de pago y fecha. | `id_compra` |
| `detalle_compra` | Líneas de una compra: qué stock (producto + talle), cuánto y a qué precio. | `id_detalle` |

---

## 3. Decisiones de diseño al pasar del modelo relacional al DDL

### 3.1. Clave sustituta en `stock` y `detalle_compra`

En el modelo relacional, ciertas combinaciones de atributos permiten identificar de manera unica los registros:

- `stock`: `(id_producto, talle)`
- `detalle_compra`: `(id_compra, id_stock)`

En el DDL se optó por usar **claves sustitutas** como claves primarias: `id_stock` en `stock` e `id_detalle` en `detalle_compra`, ambas `INT IDENTITY`.

**Motivo:** una clave sustituta simplifica las relaciones que dependen de estas tablas. Por ejemplo, `detalle_compra` referencia a `stock` mediante una sola columna (`id_stock`), en lugar de tener que utilizar una clave compuesta.

**La regla de negocio no se pierde:** se preserva con restricciones `UNIQUE`:

```sql
CONSTRAINT UQ_stock_producto_talle UNIQUE (id_producto, talle)
CONSTRAINT UQ_detalle_compra_compra_stock UNIQUE (id_compra, id_stock)
```

Así, aunque la PK ya no sea la combinación natural, el motor sigue impidiendo que se repita un mismo producto+talle en `stock`, o un mismo producto+talle dos veces dentro de la misma compra.

### 3.2. `monto_total` no se persiste

En el DER, `monto_total` de `Compra` está representado con línea punteada (atributo derivado), por lo que no se agregó como columna en `compra`. Se calcula a partir de `detalle_compra`.

### 3.3. `precio_unitario` distinto de `precio`

`producto.precio` es el precio vigente hoy. `detalle_compra.precio_unitario` guarda el precio en el momento de cada compra, de modo que el historial de ventas no cambie si más adelante se actualiza el precio de un producto.

---

## 4. Orden de ejecución de los scripts

1. `sql/ddl/crear_bd.sql` — crea la base `aura_store` y las 7 tablas con sus restricciones.
2. `sql/dml/datos_prueba.sql` — carga entre 8 y 10 registros coherentes por tabla, respetando el orden de dependencia entre tablas (primero las tablas sin FK, después las que dependen de ellas).
