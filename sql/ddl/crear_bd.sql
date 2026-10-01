--Notas:
-- El formato de constraint me parece mas ordenado pero se puede hacer todo en la misma linea si lo quieren modificar
-- Esta bueno tambien para ver los errores despues, asi es mas facil que identifiquemos que fue lo que fallo, onda, por ejemplo si se viola alguna restriccion que le pusimos deberia aparecer
-- el nombre de la regla, para cosas mas complejas despues sirve.

CREATE TABLE liga (
    --Hacemos identity para que se vaya generando solo el numero
    id_liga INT IDENTITY(1,1) NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    -- Restricciones de liga, definimos el id como pk, y le hacemos que el nombre sea unico.
    CONSTRAINT PK_liga PRIMARY KEY (id_liga),
    CONSTRAINT UQ_liga_nombre UNIQUE (nombre)
);

CREATE TABLE metodo_pago (
    id_metodo INT IDENTITY(1,1) NOT NULL,
    descripcion VARCHAR(50) NOT NULL,
    -- Restricciones del metodo de pago, de la misma manera que en la tabla liga, y tambien hacemos que sea unico el nombre del metodo de pago.
    CONSTRAINT PK_metodo_pago PRIMARY KEY (id_metodo),
    CONSTRAINT UQ_metodo_pago_descripcion UNIQUE (descripcion)
);

CREATE TABLE cliente (
    id_cliente INT IDENTITY(1,1) NOT NULL,
    nombre VARCHAR(50) NOT NULL,
    apellido VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL,
    --Restricciones de cliente, igual que en las anteriores.
    CONSTRAINT PK_cliente PRIMARY KEY (id_cliente),
    CONSTRAINT UQ_cliente_email UNIQUE (email)
);

CREATE TABLE producto (
    id_producto INT IDENTITY(1,1) NOT NULL,
    id_liga INT NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    descripcion VARCHAR(255) NULL,
    precio_actual DECIMAL(10,2) NOT NULL,
    equipo VARCHAR(100) NOT NULL,
    equipacion VARCHAR(50) NOT NULL,
    --Restricciones de producto, ahora agregamos, ademas de lo que veniamos haciedno, que verifique que el precio sea positivo.
    CONSTRAINT PK_producto PRIMARY KEY (id_producto),
    --Regla borrado/modificacion: no se puede borrar ni modificar el id de una liga si existen productos asociados,
    --ya que las compras deben conservarse como historial de ventas.
    CONSTRAINT FK_producto_liga FOREIGN KEY (id_liga) REFERENCES liga (id_liga)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
    CONSTRAINT CK_producto_precio_actual CHECK (precio_actual > 0)
);

CREATE TABLE compra (
    id_compra INT IDENTITY(1,1) NOT NULL,
    id_cliente INT NOT NULL,
    id_metodo INT NOT NULL,
    fecha DATETIME NOT NULL CONSTRAINT DF_compra_fecha DEFAULT GETDATE(),
    --Restricciones de compra, nada nuevo, vease tablas anteriores.
    CONSTRAINT PK_compra PRIMARY KEY (id_compra),
    --Reglas de borrado/modificacion: no se puede borrar ni modificar el id de un cliente si tiene compras asociadas,
    --las compras deben conservarse como historial de ventas.
    CONSTRAINT FK_compra_cliente FOREIGN KEY (id_cliente) REFERENCES cliente (id_cliente)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
    --Reglas de borrado/modificacion: No se puede borrar ni modificar el id de un metodo de pago si existen compras asociadas,
    --ya que cada compra debe conservar el metodo de pago utilizado.
    CONSTRAINT FK_compra_metodo_pago FOREIGN KEY (id_metodo) REFERENCES metodo_pago (id_metodo)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
);

CREATE TABLE stock (
    stock_id INT IDENTITY(1,1) NOT NULL,
    id_producto INT NOT NULL,
    talle VARCHAR(5) NOT NULL,
    cantidad_disponible INT NOT NULL CONSTRAINT DF_stock_cantidad_disponible DEFAULT 0,
    --Restricciones de stock, vease tablas anteriores, hacemos que siempre verifique que el stock sea no negativo.
    CONSTRAINT PK_stock PRIMARY KEY (stock_id),
    --Reglas de borrado/modificacion: no se puede borrar ni modificar el id de un producto si tiene stock asociado,
    --para mantener la integridad de la informacion de stock.
    CONSTRAINT FK_stock_producto FOREIGN KEY (id_producto) REFERENCES producto (id_producto)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
    CONSTRAINT UQ_stock_producto_talle UNIQUE (id_producto, talle),
    CONSTRAINT CK_stock_cantidad_disponible CHECK (cantidad_disponible >= 0)
);

CREATE TABLE detalle_compra (
    id_detalle_compra INT IDENTITY(1,1) NOT NULL,
    id_compra INT NOT NULL,
    stock_id INT NOT NULL,
    cantidad_comprada INT NOT NULL,
    precio_unitario DECIMAL(10,2) NOT NULL,
    --Restricciones de detalle_compra, vease tablas anteriores.
    CONSTRAINT PK_detalle_compra PRIMARY KEY (id_detalle_compra),
    --Reglas de borrado/modificacion: no se puede borrar ni modificar el id de una compra si tiene detalles asociados,
    --ya que los detalles forman parte del historial de la venta.
    CONSTRAINT FK_detalle_compra_compra FOREIGN KEY (id_compra) REFERENCES compra (id_compra)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
    --Reglas de borrado/modificacion: no se puede borrar ni modificar el id de un registro de stock si existen detalles de compra asociados,
    -- para conservar la referencia al stock correspondiente en el historial de ventas.
    CONSTRAINT FK_detalle_compra_stock FOREIGN KEY (stock_id) REFERENCES stock (stock_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
    CONSTRAINT UQ_detalle_compra_compra_stock UNIQUE (id_compra, stock_id),
    CONSTRAINT CK_detalle_compra_cantidad_comprada CHECK (cantidad_comprada > 0),
    CONSTRAINT CK_detalle_compra_precio_unitario CHECK (precio_unitario >= 0)
);
