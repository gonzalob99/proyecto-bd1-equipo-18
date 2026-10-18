# Consulta de Negocio Avanzada

**Proyecto:** Aura Store — Sistema de gestión para un comercio de indumentaria deportiva
**Etapa V:** Consultas SQL — `sql/consultas/consulta_avanzada.sql`

## Necesidad que resuelve

Identificar a los clientes "por encima del promedio": los que gastaron más que el gasto promedio de todos los clientes del comercio, junto con la cantidad de compras que hicieron. Sirve, por ejemplo, para decidir a quién dirigir una campaña de fidelización.

## Cómo funciona

Combina tres tablas con `JOIN`:

```
cliente → compra → detalle_compra
```

Agrupa por cliente (`GROUP BY cli.id_cliente, cli.nombre, cli.apellido`) y calcula:

- `COUNT(DISTINCT c.id_compra)`: cantidad de compras del cliente.
- `SUM(dc.cantidad_comprada * dc.precio_unitario)`: gasto total del cliente.

Y filtra con `HAVING` (no `WHERE`, porque la condición depende de un valor ya agregado — el gasto total por cliente) contra una **subconsulta** que calcula el promedio general de gasto por cliente:

```sql
HAVING SUM(dc.cantidad_comprada * dc.precio_unitario) > (
    SELECT AVG(gasto_cliente.total)
    FROM (
        SELECT SUM(dc2.cantidad_comprada * dc2.precio_unitario) AS total
        FROM compra c2
        JOIN detalle_compra dc2 ON dc2.id_compra = c2.id_compra
        GROUP BY c2.id_cliente
    ) AS gasto_cliente
)
```

La subconsulta interna calcula, para cada cliente, cuánto gastó en total (una fila por cliente). La subconsulta externa promedia esos totales — es decir, el promedio se calcula **por cliente**, no dividiendo el total general de ventas por la cantidad de compras. Esta distinción importa: promediar directamente sobre todas las líneas de `detalle_compra` les daría más peso a los clientes que hicieron más compras, en vez de tratar a cada cliente por igual.

## Por qué `HAVING` y no `WHERE`

`WHERE` filtra filas antes de agrupar, y en ese momento todavía no existe el dato "gasto total por cliente" (que es un resultado de `SUM()` sobre el grupo). `HAVING` filtra después de agrupar, así que puede usar el resultado de la función de agregación.

## Supuestos

- Un cliente sin ninguna compra no aparece en el resultado (el `JOIN` lo descarta), lo cual es correcto: no tiene sentido evaluarlo contra un promedio de gasto si nunca gastó nada.
- El promedio se recalcula cada vez que corre la consulta, sobre los datos vigentes — no es un valor fijo guardado en ningún lado.
