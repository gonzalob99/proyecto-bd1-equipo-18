# Casos de Uso

**Proyecto:** Aura Store — Sistema de gestión para un comercio de indumentaria deportiva
**Etapa IV:** Consultas SQL — necesidades de información

Este documento resume las tres necesidades de información que debían resolverse en esta etapa, y qué consulta de `sql/consultas/` responde a cada una.

---

## 1. Comprobante / factura de una venta

**Quién lo necesita:** el cliente, al finalizar una compra, o un administrador que tenga que reimprimir un comprobante.

**Pregunta de negocio:** "¿Qué compró el cliente en la compra N, a qué precio cada línea, y cuál fue el total?"

**Consulta:** `comprobante_venta.sql`

---

## 2. Reporte agregado de ventas

**Quién lo necesita:** un administrador, para evaluar qué categorías de productos venden más en un período determinado (por ejemplo, para decidir reposición de stock o promociones).

**Pregunta de negocio:** "¿Cuánto se vendió, en unidades y en dinero, por cada liga (categoría de producto), durante un rango de fechas?"

**Consulta:** `informe_ventas.sql`

> **Nota:** la consigna original pedía agrupar "por vendedor o por categoría de producto". El modelo de Aura Store no tiene la figura de vendedor — es venta directa al cliente — así que se usó `liga` como categoría de producto, que es la única clasificación de productos que existe en el esquema.

---

## 3. Consulta de negocio avanzada

**Quién lo necesita:** un administrador que quiera identificar a los clientes más valiosos del negocio (para campañas de fidelización, por ejemplo).

**Pregunta de negocio:** "¿Qué clientes gastaron más que el promedio general de todos los clientes, y cuántas compras hicieron?"

**Consulta:** `consulta_avanzada.sql`

---

## Resumen

| Necesidad | Archivo SQL | Tablas involucradas | Técnica usada |
|---|---|---|---|
| Comprobante de venta | `comprobante_venta.sql` | `compra`, `cliente`, `metodo_pago`, `detalle_compra`, `stock`, `producto` | Función de ventana (`SUM() OVER`) |
| Reporte agregado de ventas | `informe_ventas.sql` | `detalle_compra`, `compra`, `stock`, `producto`, `liga` | `GROUP BY`, `SUM`, `COUNT`, filtro por rango de fechas |
| Consulta avanzada | `consulta_avanzada.sql` | `cliente`, `compra`, `detalle_compra` | `JOIN` + `HAVING` con subconsulta |
