# Optimización de consultas mediante índices

**Proyecto:** Aura Store — Sistema de gestión para un comercio de indumentaria deportiva  
**Etapa V:** Temas técnicos — Optimización de consultas

## 1. Objetivo

Facilitar las consultas de compras por fecha y el informe de ventas por liga desarrollado en la etapa anterior.

Para esto se propone agregar un índice sobre `compra.fecha`. Un índice permite buscar información sin tener que revisar todos los registros, de forma similar al índice de un libro. Esto puede ayudar cuando el historial de compras aumenta y se necesita consultar un período determinado.

Los índices también ocupan espacio y deben actualizarse cuando cambian los datos. Por eso se eligió uno relacionado con las consultas del proyecto.

## 2. Índice sobre la fecha de compra

**Archivo:** `sql/tecnico/indices/crear_indices.sql`.

La tabla `compra` ya tiene un índice agrupado por `id_compra`, generado por su clave primaria. Como una tabla solo puede tener un índice agrupado, se conserva el existente y se agrega uno no agrupado por fecha:

```sql
CREATE NONCLUSTERED INDEX IX_compra_fecha_cobertura
ON dbo.compra (fecha)
INCLUDE (id_cliente, id_metodo);
```

Este índice funciona de la siguiente manera:

- `fecha` permite buscar las compras del período solicitado.
- `INCLUDE` agrega los datos de cliente y método de pago al índice, para obtenerlos sin buscarlos por separado.
- `id_compra` ya está disponible porque es la clave del índice agrupado de la tabla.

Así, el índice contiene todos los datos necesarios para un listado de compras con identificador, fecha, cliente y método de pago. A esto se lo llama **índice con cobertura** para esa consulta.

El script comprueba que exista la tabla y que el índice no haya sido creado anteriormente. Al finalizar, muestra el nombre del índice y sus columnas.

## 3. Aplicación al informe de ventas

**Archivo:** `sql/consultas/informe_ventas_optimizado.sql`.

Se retoma el informe de la Etapa IV, que muestra cantidad de ventas, unidades y total vendido por liga dentro de un período.

El índice puede ayudar a encontrar las compras correspondientes a esas fechas. Después se combinan las demás tablas para calcular los resultados del informe.

También se ajustó el filtro:

```sql
WHERE c.fecha >= @fecha_desde
  AND c.fecha < DATEADD(DAY, 1, @fecha_hasta)
```

Por ejemplo, si se consulta septiembre, se incluyen las compras desde el 1 de septiembre hasta antes del 1 de octubre. De esta manera se toma completo el último día, incluyendo las compras que tengan horas o fracciones de segundo.

El filtro anterior con `BETWEEN` también podía utilizar un índice. Este cambio permite incluir correctamente el último día; la mejora en la búsqueda se propone mediante el nuevo índice.

Los importes se siguen calculando con `detalle_compra.precio_unitario`, para conservar el precio pagado en cada compra.

## 4. Demostración preparada

**Archivo:** `sql/tecnico/indices/pruebas_indices.sql`.

Los datos iniciales tienen 14 compras, una cantidad pequeña para comparar el rendimiento. Por eso se preparó una tabla temporal con **1.100.000 compras de ejemplo**, con las mismas columnas y tipos de datos que `compra`.

La tabla temporal no tiene claves foráneas ni triggers. Se elimina al terminar y no modifica las compras ni el stock del negocio.

La prueba compara la misma consulta en tres situaciones:

| Escenario | Qué se compara |
|---|---|
| Sin índice por fecha | La búsqueda usando solamente el índice existente por `id_compra`. |
| Índice simple por fecha | La búsqueda con un índice por fecha, que no contiene los datos de cliente y método de pago. |
| Índice con cobertura | La búsqueda con un índice que incluye todos los datos solicitados en el listado. |

Cada consulta se ejecuta tres veces. Se activan `SET STATISTICS IO` y `SET STATISTICS TIME` para registrar las lecturas de datos y los tiempos.

En el plan de ejecución se puede observar cómo resolvió la consulta SQL Server:

- **Scan:** recorre los registros para encontrar los que cumplen el filtro.
- **Seek:** busca una fecha o un rango dentro del índice.
- **Key Lookup:** busca los datos que faltan en el índice no agrupado.

El plan elegido depende de la cantidad de datos y del período consultado. Agregar un índice no garantiza que siempre se utilice.

## 5. Ejecución y resultados esperados

Para realizar la comparación se debe ejecutar `pruebas_indices.sql` completo en una misma conexión, con la base `aura_store` creada. En SQL Server Management Studio se puede activar el plan de ejecución real con `Ctrl + M`.

Luego se pueden revisar los tiempos, las lecturas lógicas y los planes de los tres escenarios. El porcentaje de costo que aparece en el plan es una estimación relativa a su lote, no un tiempo medido.

Con los parámetros preparados, se esperan **1.100.000 registros en total y 603 compras para el día consultado**, en cualquiera de los tres escenarios. Los índices deben cambiar la forma de buscar los datos, sin cambiar el resultado.

Para aplicar el índice a los datos del proyecto se ejecuta `crear_indices.sql` y después se puede consultar `informe_ventas_optimizado.sql`.

**Las pruebas en SQL Server quedan pendientes**, ya que no se contaba con una instancia disponible. Por lo tanto, todavía no se presentan mediciones ni capturas que demuestren una mejora de rendimiento.

## 6. Archivos

- `sql/tecnico/indices/crear_indices.sql`: crea el índice en la tabla `compra`.
- `sql/tecnico/indices/pruebas_indices.sql`: prepara los datos de ejemplo y compara los tres escenarios.
- `sql/consultas/informe_ventas_optimizado.sql`: consulta las ventas por liga dentro de un período.

## 7. Conclusión

Se preparó un índice por fecha para facilitar las consultas del historial de compras, conservando la clave primaria y la estructura del proyecto.

También se dejó una demostración para comparar la consulta sin índice por fecha, con un índice simple y con uno con cobertura. La mejora que se obtenga deberá comprobarse al ejecutar las pruebas en SQL Server.
