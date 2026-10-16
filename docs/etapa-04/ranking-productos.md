# Ranking de Productos Más Vendidos

**Proyecto:** Aura Store — Sistema de gestión para un comercio de indumentaria deportiva  
**Etapa IV:** Consultas SQL — `sql/consultas/ranking_productos_mas_vendidos.sql`

---

## 1. Necesidad que resuelve

El área comercial y de abastecimiento de Aura Store necesita identificar con precisión cuáles son los productos de mayor rotación (prendas estrella o *bestsellers*). Esto permite:
- Negociar mejores precios por volumen con proveedores para los artículos más demandados.
- Priorizar espacio físico de exhibición en el local o banners principales en la web.
- Evitar quiebres de stock en los artículos que generan el mayor flujo de caja.

---

## 2. Cómo funciona

El script [ranking_productos_mas_vendidos.sql] se basa en la agregación de los renglones históricos de venta:

- **Relación de tablas:** Conecta `detalle_compra` con `compra`, `stock`, `producto` y `liga` mediante combinaciones internas (`INNER JOIN`).
- **Agrupamiento y funciones de agregación:**
  - `GROUP BY p.id_producto, p.nombre, p.equipo, l.nombre`: Agrupa todas las ventas por prenda (consolidando todos los talles de cada modelo).
  - `SUM(dc.cantidad_comprada)`: Calcula el total de unidades físicas despachadas.
  - `COUNT(DISTINCT c.id_compra)`: Cuenta en cuántas transacciones distintas participó el producto.
  - `SUM(dc.cantidad_comprada * dc.precio_unitario)`: Calcula la recaudación monetaria total generada por cada prenda.
- **Filtrado de podio:** Utiliza la cláusula `TOP 5` combinada con `ORDER BY unidades_vendidas DESC` para obtener los 5 artículos con mayor salida.

---

## 3. Columnas del resultado

- `id_producto`: Identificador del producto.
- `producto`: Nombre de la indumentaria.
- `equipo`: Club o selección correspondiente.
- `liga`: Categoría o torneo al que pertenece.
- `unidades_vendidas`: Total de prendas vendidas.
- `cantidad_operaciones`: Cantidad de compras en las que estuvo presente.
- `recaudacion_total`: Dinero total recaudado por el artículo.
