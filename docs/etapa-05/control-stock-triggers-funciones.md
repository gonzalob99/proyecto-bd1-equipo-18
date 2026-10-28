# Automatización y Control de Stock: Funciones y Triggers

**Proyecto:** Aura Store — Sistema de gestión para un comercio de indumentaria deportiva  
**Etapa V:** Lógica de negocio técnica — Programabilidad en el motor de base de datos

---

## 1. Justificación y Objetivos de Negocio

En una tienda de indumentaria deportiva con ventas directas, el inventario es un recurso crítico que debe mantenerse consistente en todo momento. Para evitar inconsistencias (como sobreventas o stocks negativos) y desacoplar la lógica de validación de las aplicaciones cliente, se implementaron dos componentes de base de datos:

1. **Función Escalar de Verificación (`dbo.fn_verificar_disponibilidad_stock`):**
   - **Objetivo:** Permitir a cualquier capa cliente (frontend, backend o procesos de facturación) consultar de forma previa y ligera si existe disponibilidad suficiente de un producto en un talle específico antes de avanzar al checkout.
   - **Archivo:** `sql/tecnico/funciones/verif_stock.sql`.

2. **Trigger Automático de Inventario (`dbo.trg_actualizar_stock_despues_de_compra`):**
   - **Objetivo:** Garantizar la integridad transaccional del stock al registrar ventas en `detalle_compra`. Valida que las cantidades solicitadas no superen el inventario real y realiza el descuento automático en `stock`. Si la cantidad pedida no está cubierta, revierte la transacción.
   - **Archivo:** `sql/tecnico/triggers/actualizar_stock.sql`.

---

## 2. Descripción Técnica de los Componentes

### 2.1. Función Escalar: `dbo.fn_verificar_disponibilidad_stock`

- **Firma:** `(@id_producto INT, @talle VARCHAR(5), @cantidad_requerida INT) RETURNS BIT`
- **Comportamiento:**
  - Consulta la tabla `stock` filtrando por `id_producto` y `talle`.
  - Si el registro existe y `cantidad_disponible >= @cantidad_requerida`, retorna `1` (True).
  - Si no existe disponibilidad o el artículo no posee registro para dicho talle, retorna `0` (False).

#### Ejemplo de uso:

```sql
USE aura_store;
GO

-- Consultar si hay al menos 2 unidades del producto 1 en talle M
SELECT dbo.fn_verificar_disponibilidad_stock(1, 'M', 2) AS hay_stock;
```

---

### 2.2. Trigger: `dbo.trg_actualizar_stock_despues_de_compra`

- **Evento:** `AFTER INSERT` sobre la tabla `dbo.detalle_compra`.
- **Estrategia multirregistro (set-based):**
  - Evalúa la pseudotabla `inserted` mediante un `IF EXISTS` con `INNER JOIN` a `stock`.
  - Si alguna de las líneas insertadas excede el stock disponible actual, dispara un error con `RAISERROR` (severidad 16), ejecuta `ROLLBACK TRANSACTION` y cancela la operación con `RETURN`.
  - Si todas las líneas tienen stock válido, ejecuta un `UPDATE` en lote sobre `stock` descontando `cantidad_comprada`.

---

## 3. Pruebas y Validación

A continuación se detallan los escenarios para verificar el correcto funcionamiento de los objetos:

### 3.1. Prueba de verificación previa (Función)

```sql
USE aura_store;
GO

-- Comprobacion con valores validos vs excesivos
SELECT dbo.fn_verificar_disponibilidad_stock(1, 'L', 1) AS prueba_valida;
SELECT dbo.fn_verificar_disponibilidad_stock(1, 'L', 99999) AS prueba_excedida;
```

### 3.2. Prueba de inserción exitosa con descuento automático (Trigger)

```sql
USE aura_store;
GO

-- 1. Verificar stock actual del producto antes de la compra
SELECT stock_id, id_producto, talle, cantidad_disponible
FROM stock
WHERE stock_id = 1;

-- 2. Insertar compra de prueba
INSERT INTO compra (id_cliente, id_metodo, fecha)
VALUES (1, 1, GETDATE());

DECLARE @id_compra_nueva INT = SCOPE_IDENTITY();

-- 3. Insertar detalle con cantidad disponible valida
INSERT INTO detalle_compra (id_compra, stock_id, cantidad_comprada, precio_unitario)
VALUES (@id_compra_nueva, 1, 1, 45000.00);

-- 4. Comprobar que el stock se haya descontado en 1 unidad
SELECT stock_id, id_producto, talle, cantidad_disponible
FROM stock
WHERE stock_id = 1;
```

### 3.3. Prueba de fallo por stock insuficiente con reversión (Trigger)

```sql
USE aura_store;
GO

-- Intentar vender una cantidad superior a la disponible en stock
INSERT INTO compra (id_cliente, id_metodo, fecha)
VALUES (1, 1, GETDATE());

DECLARE @id_compra_invalida INT = SCOPE_IDENTITY();

-- Debe arrojar error y hacer ROLLBACK
INSERT INTO detalle_compra (id_compra, stock_id, cantidad_comprada, precio_unitario)
VALUES (@id_compra_invalida, 1, 99999, 45000.00);

-- Comprobar que no se altero el stock
SELECT stock_id, cantidad_disponible
FROM stock
WHERE stock_id = 1;
```
