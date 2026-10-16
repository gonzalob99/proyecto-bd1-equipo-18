# Comprobante de Venta

**Proyecto:** Aura Store — Sistema de gestión para un comercio de indumentaria deportiva
**Etapa IV:** Consultas SQL — `sql/consultas/comprobante_venta.sql`

## Necesidad que resuelve

Generar el comprobante de una compra puntual: quién la hizo, cuándo, con qué método de pago, qué productos y talles incluyó, el subtotal de cada línea y el total de la compra.

## Cómo funciona

El script se divide en dos `SELECT`, identificados por una variable `@id_compra` que se cambia para generar el comprobante de otra venta:

1. **Encabezado:** junta `compra` con `cliente` y `metodo_pago` para mostrar los datos generales de la venta.
2. **Detalle:** junta `detalle_compra` con `stock` y `producto` (para llegar al nombre del producto y el talle, ya que `detalle_compra` solo guarda `stock_id`), calcula el subtotal de cada línea (`cantidad_comprada * precio_unitario`), y usa una **función de ventana** para mostrar el total de la compra:

```sql
SUM(dc.cantidad_comprada * dc.precio_unitario) OVER (PARTITION BY dc.id_compra) AS total_compra
```

`OVER (PARTITION BY dc.id_compra)` le dice al motor "sumá esto para todas las filas de la misma compra, pero mostrámelo en cada fila sin agruparlas". Así el total aparece repetido en cada renglón del detalle, sin necesidad de una tercera consulta aparte ni de agregar una fila extra de "total".

## Columnas del resultado

**Encabezado:** `id_compra`, `fecha`, `cliente` (nombre + apellido), `email`, `metodo_pago`.

**Detalle:** `id_detalle_compra`, `producto`, `talle`, `cantidad_comprada`, `precio_unitario`, `subtotal`, `total_compra`.

## Supuestos

- Se asume que el comprobante se genera para una compra ya cargada (no calcula nada sobre compras futuras o hipotéticas).
- `precio_unitario` es el precio guardado en `detalle_compra`, no `producto.precio_actual` — así el comprobante refleja el precio real pagado en esa compra, aunque el precio del producto haya cambiado después.
