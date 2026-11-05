# Aura Store

**Bases de Datos I · Equipo 18**

Aura Store es una base de datos relacional para un comercio de camisetas de fútbol. Su objetivo es gestionar el ciclo completo de ventas, desde el registro de clientes y la consulta del catálogo hasta el control de stock por talle, el registro de compras con su método de pago y la consulta de comprobantes e informes.

El modelo tiene siete tablas, está normalizado hasta la **Tercera Forma Normal (3FN)** y se implementa en **SQL Server (T-SQL)**. Las claves y restricciones mantienen la integridad de los datos. Cada renglón de compra conserva el precio unitario de la venta y el importe total se calcula a partir del detalle.

## Etapas del proyecto

| Etapa | Qué se trabajó | Dónde encontrarlo |
| --- | --- | --- |
| **I. Requerimientos y dominio** | Caso de estudio, alcance, actores y 13 reglas de negocio. Incluyen el registro de clientes, el stock por talle, el precio histórico y el método de pago. | [Descripción del caso](docs/etapa-01/descripcion-caso.md), [alcance](docs/etapa-01/alcance.md) y [reglas de negocio](docs/etapa-01/reglas-negocio.md). |
| **II. Modelado conceptual y lógico** | Entidades, relaciones y cardinalidades en el DER, transformación a tablas con claves primarias y foráneas, y normalización paso a paso de 1FN a 3FN. | [DER](docs/etapa-02/der/der.png), [modelo relacional](docs/etapa-02/Transformaci%C3%B3n%20al%20Modelo%20Relacional/modelo_relacional.md) y [normalización](docs/etapa-02/normalizacion.md). |
| **III. Implementación física** | Creación de la base y sus restricciones, decisiones de diseño y carga de datos de prueba. | [Implementación](docs/etapa-03/implementacion.md), [DDL](sql/ddl/crear_bd.sql) y [DML](sql/dml/datos_prueba.sql). |
| **IV. Consultas y casos de uso** | Comprobante con subtotales y total, ventas por liga en un rango de fechas y clientes con gasto superior al promedio de quienes compraron. También hay consultas de stock, ranking de productos y ventas por método de pago. | [Casos de uso](docs/etapa-04/casos-uso.md), [documentación de las consultas](docs/etapa-04/) y scripts de [comprobante](sql/consultas/comprobante.sql), [informe de ventas](sql/consultas/informe_ventas.sql) y [consulta avanzada](sql/consultas/consulta_avanzada.sql). |
| **V. Temas técnicos** | Procedimiento de compra, función de disponibilidad, transacciones, trigger de stock, permisos de lectura por rol e índice por fecha de compra. | [Documentación técnica](docs/etapa-05/) y [scripts de implementación y pruebas](sql/tecnico/). |

## Estructura del repositorio

- [`docs/`](docs/) reúne los entregables escritos y diagramas, organizados en carpetas de `etapa-01` a `etapa-05`.
- [`sql/`](sql/) reúne los scripts ejecutables. [`ddl/`](sql/ddl/) contiene la creación de la base y sus restricciones, [`dml/`](sql/dml/) la carga de datos de prueba, [`consultas/`](sql/consultas/) los comprobantes y reportes, y [`tecnico/`](sql/tecnico/) la implementación y las pruebas organizadas por tema.

## Puesta en marcha

1. Conectarse a una instancia de **SQL Server** desde **SQL Server Management Studio (SSMS)** con permisos para crear bases de datos.
2. Ejecutar [`crear_bd.sql`](sql/ddl/crear_bd.sql) en una instancia sin una instalación previa del proyecto. El script crea la base `aura_store` y sus tablas.
3. Ejecutar [`datos_prueba.sql`](sql/dml/datos_prueba.sql) antes de instalar el trigger de stock. La carga incluye compras de agosto y septiembre de 2026.
4. Probar el [comprobante](sql/consultas/comprobante.sql) con `@id_compra = 13` para ver dos renglones y el total acumulado. Para ejecutar el [informe de ventas original](sql/consultas/informe_ventas.sql), reemplazar `USE AuraStore` por `USE aura_store` en el editor y ajustar el rango de fechas según el período a consultar.

