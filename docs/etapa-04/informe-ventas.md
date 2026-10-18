# Informe de Ventas

**Proyecto:** Aura Store — Sistema de gestión para un comercio de indumentaria deportiva
**Etapa V:** Consultas SQL — `sql/consultas/informe_ventas.sql`

## Necesidad que resuelve

Saber cuánto se vendió — en cantidad de ventas, unidades y dinero — por categoría de producto, dentro de un rango de fechas determinado.

## Por qué se agrupa por `liga` y no por vendedor

La consigna original permitía agrupar "por vendedor o por categoría de producto". El modelo de Aura Store no tiene la figura de vendedor: es un comercio de venta directa al cliente, sin un actor intermedio que registre a quién le corresponde cada venta. Por eso se usó `liga` como la categoría de producto, que es la única clasificación que existe en el esquema (cada producto pertenece a una liga).

## Cómo funciona

Parte de `detalle_compra` (porque ahí están las cantidades y precios reales de cada venta) y encadena los `JOIN` necesarios para llegar hasta `liga`:

```
detalle_compra → stock → producto → liga
detalle_compra → compra (para filtrar por fecha)
```

Filtra por el rango de fechas con `WHERE c.fecha BETWEEN @fecha_desde AND @fecha_hasta`, y agrupa por `liga.nombre` calculando tres métricas:

- `COUNT(DISTINCT c.id_compra)`: cantidad de ventas distintas que incluyeron productos de esa liga (se usa `DISTINCT` porque una misma compra puede tener varias líneas de la misma liga, y no se quiere contar la compra más de una vez).
- `SUM(dc.cantidad_comprada)`: unidades vendidas.
- `SUM(dc.cantidad_comprada * dc.precio_unitario)`: total facturado.

## Parámetros

`@fecha_desde` y `@fecha_hasta` al principio del script — cambiarlos para consultar otro período.

## Supuestos

- Se cuenta la venta por liga en base a las líneas de detalle, no por compra completa: si una compra incluye productos de dos ligas distintas, esa compra aporta a las métricas de ambas ligas.
- El filtro de fecha se aplica sobre `compra.fecha` (cuándo se concretó la venta), no sobre ninguna fecha de `producto` o `stock`.
