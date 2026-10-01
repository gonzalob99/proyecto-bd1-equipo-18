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
    id_metodo_pago INT IDENTITY(1,1) NOT NULL,
    nombre VARCHAR(50) NOT NULL,
    -- Restricciones del metodo de pago, de la misma manera que en la tabla liga, y tambien hacemos que sea unico el nombre del metodo de pago.
    CONSTRAINT PK_metodo_pago PRIMARY KEY (id_metodo_pago),
    CONSTRAINT UQ_metodo_pago_nombre UNIQUE (nombre)
);

CREATE TABLE cliente (
    id_cliente INT IDENTITY(1,1) NOT NULL,
    nombre VARCHAR(50) NOT NULL,
    apellido VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL,
    --Restricciones de cliente, igual que en las anteriores.
    CONSTRAINT PK_cliente PRIMARY KEY (id_cliente),
    CONSTRAINT UQ_cliente_email UNIQUE (email),
    CONSTRAINT CK_cliente_email CHECK (email LIKE '%_@_%')
);

CREATE TABLE producto (
    id_producto INT IDENTITY(1,1) NOT NULL,
    id_liga INT NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    descripcion VARCHAR(255) NULL,
    precio DECIMAL(10,2) NOT NULL,
    equipo VARCHAR(100) NOT NULL,
    equipacion VARCHAR(50) NOT NULL,
    --Restricciones de producto, ahora agregamos, ademas de lo que veniamos haciedno, que verifique que el precio sea no negativo.
    CONSTRAINT PK_producto PRIMARY KEY (id_producto),
    CONSTRAINT FK_producto_liga FOREIGN KEY (id_liga) REFERENCES liga (id_liga),
    CONSTRAINT CK_producto_precio CHECK (precio > 0)
);

CREATE TABLE compra (
    id_compra INT IDENTITY(1,1) NOT NULL,
    id_cliente INT NOT NULL,
    id_metodo_pago INT NOT NULL,
    fecha DATETIME NOT NULL CONSTRAINT DF_compra_fecha DEFAULT GETDATE(),
    --Restricciones de compra, nada nuevo, vease tablas anteriores.
    CONSTRAINT PK_compra PRIMARY KEY (id_compra),
    CONSTRAINT FK_compra_cliente FOREIGN KEY (id_cliente) REFERENCES cliente (id_cliente),
    CONSTRAINT FK_compra_metodo_pago FOREIGN KEY (id_metodo_pago) REFERENCES metodo_pago (id_metodo_pago)
);

CREATE TABLE stock (
    id_stock INT IDENTITY(1,1) NOT NULL,
    id_producto INT NOT NULL,
    talle VARCHAR(5) NOT NULL,
    disponible INT NOT NULL CONSTRAINT DF_stock_disponible DEFAULT 0,
    --Restricciones de stock, vease tablas anteriores, hacemos que siempre verifique que el stock sea no negativo.
    CONSTRAINT PK_stock PRIMARY KEY (id_stock),
    CONSTRAINT FK_stock_producto FOREIGN KEY (id_producto) REFERENCES producto (id_producto),
    CONSTRAINT UQ_stock_producto_talle UNIQUE (id_producto, talle),
    CONSTRAINT CK_stock_disponible CHECK (disponible >= 0)
);

CREATE TABLE detalle_compra (
    id_detalle INT IDENTITY(1,1) NOT NULL,
    id_compra INT NOT NULL,
    id_stock INT NOT NULL,
    cantidad INT NOT NULL,
    precio_unitario DECIMAL(10,2) NOT NULL,
    --Restricciones de detalle_compra, vease tablas anteriores.
    CONSTRAINT PK_detalle_compra PRIMARY KEY (id_detalle),
    CONSTRAINT FK_detalle_compra_compra FOREIGN KEY (id_compra) REFERENCES compra (id_compra),
    CONSTRAINT FK_detalle_compra_stock FOREIGN KEY (id_stock) REFERENCES stock (id_stock),
    CONSTRAINT UQ_detalle_compra_compra_stock UNIQUE (id_compra, id_stock),
    CONSTRAINT CK_detalle_compra_cantidad CHECK (cantidad > 0),
    CONSTRAINT CK_detalle_compra_precio_unitario CHECK (precio_unitario >= 0)
);
