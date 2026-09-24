# Etapa II: transformación al modelo relacional

**Proyecto:** Aura Store, comercio electrónico de indumentaria deportiva (camisetas de fútbol).  
**Base:** diagrama `modelo_relacional.png` y requerimientos de la Etapa I.  
**Notación:** PK = clave primaria; FK = clave foránea. Los campos se transcriben del diagrama; las inconsistencias se señalan al final.

## Catálogo y stock

### `Ligas`

**Campos:** `liga_id` (PK), `nombre`.  
**Decisión:** separa las ligas del catálogo para que varios productos puedan compartir una misma liga sin repetir su nombre.

### `Productos`

**Campos:** `producto_id` (PK), `nombre`, `descripcion`, `precio`, `liga_id` (rotulado PK en el diagrama; ver revisión), `equipo`, `equipacion`, `path_imagen`.  
**Decisión:** reúne los datos generales y el precio *actual* de cada camiseta. `liga_id` la relaciona con `Ligas`; el stock queda fuera porque varía según el talle (RN.03 y RN.04).

### `talle_productos`

**Campos:** `talle_producto_id` (PK), `producto_id` (FK → `Productos.producto_id`), `talle`, `stock`.  
**Decisión:** representa la disponibilidad de cada producto por talle, de modo que las existencias puedan controlarse y descontarse independientemente (RN.04–RN.06). Conviene exigir que la combinación (`producto_id`, `talle`) sea única.

## Usuarios y acceso

### `roles`

**Campos:** `rol_id` (PK), `nombre`, `descripcion`.  
**Decisión:** centraliza los perfiles de acceso, principalmente cliente y administrador, previstos en la Etapa I (RN.13).

### `usuario`

**Campos:** `usuario_id` (PK), `nombre`, `email`, `contraseña`, `rol_id` (FK → `roles.rol_id`).  
**Decisión:** identifica a quienes se registran, compran o administran el sistema. El correo debe ser único para cumplir RN.02; cada usuario queda asociado a un rol.

### `consultas`

**Campos:** `consulta_id` (PK), `usuario_id` (FK → `usuario.usuario_id`), `detalle_consulta`, `leida`.  
**Decisión:** guarda mensajes enviados por usuarios y permite indicar si fueron leídos. Esta tabla modela consultas escritas, una función adicional a la navegación del catálogo mencionada en la Etapa I.

## Ventas y comprobantes

### `ventas_cabecera`

**Campos:** `venta_cabecera_id` (PK), `fecha_venta`, `usuario_id` (FK → `usuario.usuario_id`), `estado`, `total`, `metodo_pago`, `telefono_envio`, `direccion_envio`, `ciudad_envio`, `provincia_envio`, `codigo_postal_envio`, `obsevaciones_envio` (así figura en el diagrama).  
**Decisión:** contiene una fila por compra, vinculada a un cliente, con fecha, estado, método de pago e importe total (RN.07, RN.10 y RN.11). Los datos de envío se conservan en la propia venta para registrar los utilizados en esa operación. El total debe coincidir con la suma de sus renglones.

### `ventas_detalle`

**Campos:** `venta_detalle_id` (PK), `venta_id` (FK → `ventas_cabecera.venta_cabecera_id`), `producto_id` (FK → `Productos.producto_id`), `talle`, `cantidad`, `precio_unitario`, `subtotal`.  
**Decisión:** descompone una compra en sus productos y cantidades; resuelve la relación entre ventas y productos. `precio_unitario` guarda el valor cobrado aunque cambie `Productos.precio` (RN.08 y RN.09). Si se almacena `subtotal`, debe coincidir con `cantidad × precio_unitario`.

### `facturas`

**Campos:** `factura_id` (PK), `usuario_id` (FK → `usuario.usuario_id`), `razon_social`, `cuit_cuil`, `estado_pago`, `fecha`, `total`.  
**Decisión:** guarda la cabecera del comprobante y los datos de facturación usados al emitirlo, junto con fecha, estado de pago e importe. Responde al requisito de emisión y consulta de comprobantes de la Etapa I.

### `detalle_facturas`

**Campos:** `detalle_factura_id` (PK), `factura_id` (FK → `facturas.factura_id`), `producto_id` (FK → `Productos.producto_id`), `cantidad`, `precio_unitario`.  
**Decisión:** registra los renglones del comprobante y el precio facturado de cada producto. Repite parte de la información de `ventas_detalle`, por lo que debe definirse cuándo se copia y cuál de las dos tablas es la fuente para emitir la factura.

## 
