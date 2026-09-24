# Proceso de Normalización

**Proyecto:** Aura Store — Sistema de gestión para un comercio de indumentaria deportiva
**Etapa II:** Modelado Conceptual y Lógico — Punto 3

Este documento muestra, paso a paso, cómo evoluciona el modelo desde una relación inicial sin normalizar hasta el esquema en Tercera Forma Normal (3FN), que coincide con el modelo relacional obtenido del DER (`modelo-relacional.md`).

**Convenciones:** `PK` = clave primaria · `FK` = clave foránea · `PK/FK` = atributo que es a la vez clave primaria y foránea · `{ ... }` = grupo repetitivo.

---

## 0. Punto de partida: relación sin normalizar (0FN)

Se parte de una única relación que reúne toda la información que maneja un comprobante de compra:

```
COMPRA_0FN (
  id_compra, fecha,
  id_cliente, nombre_cliente, apellido_cliente, email_cliente,
  id_metodo, descripcion_metodo,
  { id_producto, nombre_producto, descripcion_producto, precio_actual,
    equipo, equipacion, id_liga, nombre_liga,
    talle, cantidad_disponible, cantidad_comprada, precio_unitario }
)
```

> `monto_total` no se incluye: es un atributo derivado (punteado en el DER) que se calcula a partir del detalle de la compra (ver nota 1).

Una compra puede incluir varios productos y, de cada uno, varios talles. Por eso los atributos entre llaves forman un **grupo repetitivo**.

### Dependencias funcionales (DF) identificadas

Surgen de las reglas del negocio y del DER:

| N° | Dependencia funcional | Significado |
|----|-----------------------|-------------|
| DF1 | `id_compra → fecha, id_cliente, id_metodo` | Cada compra tiene una fecha, un cliente y un método de pago. |
| DF2 | `id_cliente → nombre_cliente, apellido_cliente, email_cliente` | Los datos personales dependen del cliente. |
| DF3 | `id_metodo → descripcion_metodo` | La descripción depende del método de pago. |
| DF4 | `id_producto → nombre_producto, descripcion_producto, precio_actual, equipo, equipacion, id_liga` | Los datos del producto dependen del producto; cada producto pertenece a una liga. |
| DF5 | `id_liga → nombre_liga` | El nombre depende de la liga. |
| DF6 | `(id_producto, talle) → cantidad_disponible` | El stock se lleva por producto y talle. |
| DF7 | `(id_compra, id_producto, talle) → cantidad_comprada, precio_unitario` | Cada línea de compra registra cantidad y precio al momento de la compra. |

---

## 1. Primera Forma Normal (1FN)

**Criterio:** todos los atributos deben ser atómicos (un solo valor por celda), no debe haber grupos repetitivos y cada relación debe tener clave primaria.

### Problema detectado

En `COMPRA_0FN` una misma fila tendría que guardar varios valores en las columnas del grupo repetitivo. Ejemplo (datos de ejemplo):

| id_compra | fecha | id_cliente | id_producto | talle | cantidad_comprada |
|-----------|-------|------------|-------------|-------|-------------------|
| 1 | 2026-05-10 | 7 | 15, 15, 22 | M, L, S | 1, 1, 2 |

Esto viola la atomicidad: no se puede consultar, actualizar ni ordenar por un producto o talle individual.

### Transformación

El grupo repetitivo se separa en una nueva relación. Esta lleva la clave de la relación original (`id_compra`) más la clave que identifica cada ocurrencia del grupo (`id_producto`, `talle`). El talle forma parte de la clave porque un mismo producto puede comprarse en varios talles dentro de la misma compra.

| id_compra | id_producto | talle | cantidad_comprada |
|-----------|-------------|-------|-------------------|
| 1 | 15 | M | 1 |
| 1 | 15 | L | 1 |
| 1 | 22 | S | 2 |

### Verificación de atomicidad

| Atributo | ¿Atómico? | Observación |
|----------|-----------|-------------|
| nombre_cliente / apellido_cliente | Sí | Están separados en dos atributos. |
| fecha | Sí | Un único valor de fecha. |
| talle | Sí | Un valor por fila; ya no hay listas de talles. |
| equipo / equipacion | Sí | Un solo valor descriptivo cada uno. |

### Resultado en 1FN

```
COMPRA_1FN (
  id_compra [PK], fecha,
  id_cliente, nombre_cliente, apellido_cliente, email_cliente,
  id_metodo, descripcion_metodo
)

DETALLE_COMPRA_1FN (
  id_compra [PK/FK → COMPRA_1FN], id_producto [PK], talle [PK],
  nombre_producto, descripcion_producto, precio_actual,
  equipo, equipacion, id_liga, nombre_liga,
  cantidad_disponible, cantidad_comprada, precio_unitario
)
```

---

## 2. Segunda Forma Normal (2FN)

**Criterio:** estar en 1FN y que todo atributo no clave dependa de **toda** la clave primaria, no solo de una parte (sin dependencias parciales). Solo puede haber dependencias parciales en relaciones con clave compuesta.

### Análisis

- `COMPRA_1FN` tiene clave simple (`id_compra`): **ya cumple 2FN**.
- `DETALLE_COMPRA_1FN` tiene clave compuesta `(id_compra, id_producto, talle)`. Se analiza cada atributo no clave:

| Atributo(s) | Depende de | Tipo de dependencia |
|-------------|------------|---------------------|
| nombre_producto, descripcion_producto, precio_actual, equipo, equipacion, id_liga, nombre_liga | `id_producto` (DF4, DF5) | **Parcial** (solo una parte de la clave) |
| cantidad_disponible | `(id_producto, talle)` (DF6) | **Parcial** (falta `id_compra`) |
| cantidad_comprada, precio_unitario | `(id_compra, id_producto, talle)` (DF7) | Total (correcta) |

### Anomalías que producen las dependencias parciales

- **Redundancia:** los datos del producto se repiten en cada compra que lo incluye.
- **Actualización:** cambiar el `precio_actual` obliga a modificar todas las filas donde aparece el producto; si se olvida alguna, hay inconsistencia.
- **Inserción:** no se puede registrar un producto nuevo ni su stock sin que exista una compra.
- **Eliminación:** al borrar la única compra de un producto se pierden sus datos y su stock.

### Transformación

Cada dependencia parcial se separa en su propia relación, con el determinante como clave:

- Los atributos que dependen de `id_producto` pasan a `PRODUCTO`.
- `cantidad_disponible` pasa a `STOCK`, con clave `(id_producto, talle)`.
- Lo que depende de la clave completa queda en `INCLUYE`.

### Resultado en 2FN

```
COMPRA_2FN (
  id_compra [PK], fecha,
  id_cliente, nombre_cliente, apellido_cliente, email_cliente,
  id_metodo, descripcion_metodo
)

PRODUCTO_2FN (
  id_producto [PK], nombre_producto, descripcion_producto, precio_actual,
  equipo, equipacion, id_liga, nombre_liga
)

STOCK (
  id_producto [PK/FK → PRODUCTO_2FN], talle [PK], cantidad_disponible
)

INCLUYE (
  id_compra [PK/FK → COMPRA_2FN],
  id_producto [PK/FK → STOCK], talle [PK/FK → STOCK],
  cantidad_comprada, precio_unitario
)
```

---

## 3. Tercera Forma Normal (3FN)

**Criterio:** estar en 2FN y que ningún atributo no clave dependa de otro atributo no clave (sin dependencias transitivas). Es decir, todo atributo no clave depende *directamente* de la clave.

### Análisis

| Relación | Dependencia transitiva encontrada | Atributos involucrados |
|----------|-----------------------------------|------------------------|
| COMPRA_2FN | `id_compra → id_cliente → nombre_cliente, apellido_cliente, email_cliente` | Datos del cliente dependen de `id_cliente`, que no es la clave de la relación. |
| COMPRA_2FN | `id_compra → id_metodo → descripcion_metodo` | La descripción depende de `id_metodo`, que no es la clave. |
| PRODUCTO_2FN | `id_producto → id_liga → nombre_liga` | El nombre de la liga depende de `id_liga`, que no es la clave. |
| STOCK | Ninguna | `cantidad_disponible` depende solo de la clave completa. |
| INCLUYE | Ninguna | `cantidad_comprada` y `precio_unitario` dependen solo de la clave completa. |

### Anomalías que producen las dependencias transitivas

- **Redundancia:** los datos del cliente se repiten en cada una de sus compras; el nombre de la liga, en cada producto.
- **Actualización:** cambiar el email de un cliente exige modificar todas sus compras.
- **Inserción:** no se puede registrar un cliente, un método de pago o una liga sin una compra o un producto asociado.
- **Eliminación:** al borrar la última compra de un cliente se pierden sus datos.

### Transformación

Cada determinante no clave pasa a ser la clave primaria de una nueva relación, y en la relación original queda como clave foránea:

- `id_cliente` → tabla `CLIENTE`; en `COMPRA` queda como FK.
- `id_metodo` → tabla `METODO_PAGO`; en `COMPRA` queda como FK.
- `id_liga` → tabla `LIGA`; en `PRODUCTO` queda como FK.

### Resultado en 3FN (esquema final)

```
CLIENTE     (id_cliente [PK], nombre, apellido, email)

METODO_PAGO (id_metodo [PK], descripcion)

LIGA        (id_liga [PK], nombre)

PRODUCTO    (id_producto [PK], nombre, descripcion, precio_actual, equipo, equipacion,
             id_liga [FK → LIGA.id_liga])

STOCK       (id_producto [PK/FK → PRODUCTO.id_producto], talle [PK], cantidad_disponible)

COMPRA      (id_compra [PK], fecha,
             id_cliente [FK → CLIENTE.id_cliente],
             id_metodo  [FK → METODO_PAGO.id_metodo])

INCLUYE     (id_compra [PK/FK → COMPRA.id_compra],
             id_producto [PK/FK → STOCK.id_producto],
             talle [PK/FK → STOCK.talle],
             cantidad_comprada, precio_unitario)
```

> En las tablas finales se usan los nombres de atributos del DER (`nombre`, `apellido`, `email`, `descripcion`), ya que el prefijo (`nombre_cliente`, `nombre_producto`, etc.) solo servía para distinguirlos dentro de la relación única inicial. En `INCLUYE`, el par `(id_producto, talle)` es una única clave foránea compuesta hacia `STOCK`.

---

## 4. Resumen de la evolución del modelo

| Etapa | Relaciones resultantes | Problema que resuelve |
|-------|------------------------|-----------------------|
| 0FN | `COMPRA_0FN` (1 relación) | Punto de partida con grupo repetitivo. |
| 1FN | `COMPRA_1FN`, `DETALLE_COMPRA_1FN` (2) | Elimina el grupo repetitivo y garantiza atomicidad. |
| 2FN | `COMPRA_2FN`, `PRODUCTO_2FN`, `STOCK`, `INCLUYE` (4) | Elimina dependencias parciales sobre la clave compuesta del detalle. |
| 3FN | `CLIENTE`, `METODO_PAGO`, `LIGA`, `PRODUCTO`, `STOCK`, `COMPRA`, `INCLUYE` (7) | Elimina dependencias transitivas entre atributos no clave. |

**Verificación:** las 7 relaciones de la 3FN coinciden con las tablas obtenidas al transformar el DER al modelo relacional (`modelo-relacional.md`), por lo que el DER ya estaba correctamente normalizado.

---

## 5. Notas y decisiones de diseño

1. **`monto_total` no se almacena.** Es un atributo derivado: se calcula como la suma de `cantidad_comprada * precio_unitario` de las líneas de `INCLUYE`. Guardarlo agregaría redundancia y riesgo de inconsistencia si se modifica una línea.

2. **`precio_unitario` y `precio_actual` son datos distintos.** `PRODUCTO.precio_actual` es el precio vigente hoy; `INCLUYE.precio_unitario` guarda el precio al momento de la compra, por lo que el historial no cambia cuando se actualiza el precio del producto. Se asume que el precio se registra **por línea de detalle** `(id_compra, id_producto, talle)`, es decir que puede variar entre líneas de una misma compra (por ejemplo, por promociones). Por eso depende de la clave completa. Si la regla fuera que el precio es único por producto dentro de una compra, dependería solo de `(id_compra, id_producto)` y habría que separarlo para mantener la 2FN.

3. **`equipo` no determina `id_liga`.** Se trató `equipo` como un atributo descriptivo del producto y `id_liga` como una clasificación propia del producto. Si el negocio definiera que cada equipo pertenece a una única liga, aparecería una dependencia transitiva `id_producto → equipo → id_liga` y habría que crear una tabla `EQUIPO`. Como el DER modela `equipo` como atributo simple, no se aplicó.
