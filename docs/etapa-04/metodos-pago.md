# Análisis de Ventas por Método de Pago

**Proyecto:** Aura Store — Sistema de gestión para un comercio de indumentaria deportiva  
**Etapa IV:** Consultas SQL — `sql/consultas/ventas_por_metodo_pago.sql`

---

## 1. Necesidad que resuelve

El área de administración y finanzas requiere visibilidad sobre la distribución de las ventas según el canal de cobro empleado (tarjetas de crédito/débito, transferencias o efectivo). Esta información es crítica para:
- Auditar y conciliar el impacto de las comisiones bancarias y retenciones fiscales según el medio de pago.
- Definir promociones financieras comerciales (por ejemplo, descuentos por pago en efectivo o cuotas sin interés).
- Asegurar la liquidez de caja de la empresa.

---

## 2. Cómo funciona

El script [ventas_por_metodo_pago.sql] emplea exclusivamente herramientas temáticas vistas en clase:

- **Combinación externa (`LEFT JOIN`):** Se parte desde la tabla maestra `metodo_pago` hacia `compra` y `detalle_compra`. De esta manera, si un método de pago fue habilitado pero aún no registra ventas, aparecerá con 0 operaciones y $0 recaudados, en lugar de ser omitido.
- **Agrupamiento (`GROUP BY`):** Agrupa por `mp.id_metodo` y `mp.descripcion`.
- **Cálculo de participación relativa con Subconsulta Escalar:** En lugar de utilizar funciones analíticas avanzadas no vistas en teoría, se calcula el porcentaje de recaudación dividiendo la suma del método contra una **subconsulta escalar**:
  ```sql
  (SELECT SUM(dc_total.cantidad_comprada * dc_total.precio_unitario) FROM detalle_compra dc_total)
  ```
- **Robustez numérica:** Se utiliza `ISNULL` para manejar métodos sin ventas, `NULLIF` para prevenir eventuales divisiones por cero en bases vacías, y `ROUND(..., 2)` para limitar el porcentaje a dos decimales.

---

## 3. Columnas del resultado

- `id_metodo`: Identificador del medio de cobro.
- `metodo_pago`: Descripción (ej. Efectivo, Transferencia, Tarjeta de Crédito).
- `cantidad_operaciones`: Cantidad de compras liquidadas con ese medio.
- `total_recaudado`: Monto monetario total cobrado.
- `porcentaje_recaudacion`: Porcentaje que representa sobre el total general vendido.
