# Control de Stock: Alerta General y Consulta por Producto

**Proyecto:** Aura Store — Sistema de gestión para un comercio de indumentaria deportiva  
**Etapa IV:** Consultas SQL — Casos de uso de inventario

---

## 1. Justificación y Casos de Uso

En el rubro de indumentaria deportiva, las consultas de stock responden a dos necesidades operativas bien diferenciadas:

1. **Gestión interna de depósito / reposición preventiva ([alerta_stock_critico.sql]):** El encargado de compras necesita un reporte general de todas las prendas cuyo stock disponible se encuentre en quiebre o por debajo de un umbral mínimo de seguridad (`@umbral_minimo`), ordenado por criticidad para emitir órdenes de compra a proveedores.

2. **Atención a clientes y catálogo digital ([consulta_stock_producto.sql]):** Simula una petición proveniente de una interfaz de usuario donde el cliente o el vendedor en mostrador no conocen el `id_producto`, sino que buscan por nombre o equipo (ej. `'Boca'`, `'Camiseta'`). Se debe retornar la disponibilidad en toda la curva de talles para los artículos coincidentes.

---

## 2. Estrategia SQL y Conceptos de Cátedra Utilizados

Ambos scripts se limitan rigurosamente a los contenidos evaluados en la materia hasta la unidad de subconsultas:

- **Manejo de valores nulos:** Se emplea `ISNULL(s.cantidad_disponible, 0)` para contemplar de forma segura aquellos productos registrados en el catálogo que aún no tengan registros de talles asociados en la tabla `stock`.
- **Combinaciones externas (`LEFT JOIN`):** Permite listar productos independientemente de si tienen o no stock cargado, evitando omitir artículos que necesitan carga inicial.
- **Subconsultas y operadores de coincidencia (`IN`, `LIKE`):** En la consulta por producto, se desacopla la resolución del texto de búsqueda mediante una subconsulta con `WHERE ... LIKE '%' + @nombre_busqueda + '%'`.
- **Parametrización limpia:** Uso de variables `DECLARE` al inicio para facilitar pruebas sin alterar la lógica de las consultas.
