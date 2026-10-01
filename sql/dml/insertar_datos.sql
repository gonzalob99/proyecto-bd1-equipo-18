USE AuraStore;
GO

-- 1. Insertar Ligas (10 filas)
INSERT INTO liga (nombre) VALUES
('Liga Profesional Argentina'),
('LaLiga'),
('Premier League'),
('Serie A'),
('Bundesliga'),
('Ligue 1'),
('Brasileirão'),
('Eredivisie'),
('Liga MX'),
('MLS');

-- 2. Insertar Métodos de Pago (8 filas)
INSERT INTO metodo_pago (descripcion) VALUES
('Efectivo'),
('Tarjeta de Débito'),
('Tarjeta de Crédito'),
('Mercado Pago'),
('Transferencia Bancaria'),
('MODO'),
('Cuenta DNI'),
('Cripto / USDT');

-- 3. Insertar Clientes (10 filas)
INSERT INTO cliente (nombre, apellido, email) VALUES
('Francisco', 'Goral', 'francisco@gmail.com'),
('Gonzalo', 'Biancardi', 'gonzalo@gmail.com'),
('Matias', 'Solis', 'matias@gmail.com'),
('Ezequiel', 'Hernandez', 'ezequiel@gmail.com'),
('Nicolas', 'Eduardo', 'nicolas@gmail.com'),
('Lucas', 'Fernandez', 'lucas@gmail.com'),
('Camila', 'Gomez', 'camila@gmail.com'),
('Sofia', 'Martinez', 'sofia@gmail.com'),
('Juan', 'Rodriguez', 'juan@gmail.com'),
('Agustina', 'Lopez', 'agustina@gmail.com');

-- 4. Insertar Productos (10 filas - apuntan a id_liga 1 al 10)
INSERT INTO producto (id_liga, nombre, descripcion, precio_actual, equipo, equipacion) VALUES
(1, 'Camiseta Boca Juniors 2026', 'Camiseta titular dry-fit', 89999.00, 'Boca Juniors', 'Titular'),
(1, 'Camiseta River Plate 2026', 'Camiseta titular oficial', 89999.00, 'River Plate', 'Titular'),
(2, 'Camiseta Real Madrid 2026', 'Camiseta suplente azul', 109999.00, 'Real Madrid', 'Suplente'),
(2, 'Camiseta Barcelona 2026', 'Camiseta titular blaugrana', 109999.00, 'FC Barcelona', 'Titular'),
(3, 'Camiseta Manchester City 2026', 'Camiseta titular celeste', 105000.00, 'Manchester City', 'Titular'),
(3, 'Camiseta Arsenal 2026', 'Camiseta titular roja', 105000.00, 'Arsenal', 'Titular'),
(4, 'Camiseta Inter Milan 2026', 'Camiseta titular nerazzurra', 98000.00, 'Inter Milan', 'Titular'),
(5, 'Camiseta Bayern Munich 2026', 'Camiseta titular roja', 99000.00, 'Bayern Munich', 'Titular'),
(6, 'Camiseta PSG 2026', 'Camiseta titular azul', 102000.00, 'PSG', 'Titular'),
(7, 'Camiseta Flamengo 2026', 'Camiseta titular rubro-negra', 92000.00, 'Flamengo', 'Titular');

-- 5. Insertar Stock (10 filas)
INSERT INTO stock (id_producto, talle, cantidad_disponible) VALUES
(1, 'S', 10),
(1, 'M', 15),
(1, 'L', 20),
(2, 'M', 12),
(2, 'L', 8),
(3, 'L', 10),
(4, 'S', 5),
(5, 'XL', 7),
(6, 'M', 14),
(7, 'L', 9);

-- 6. Insertar Compras (10 filas)
INSERT INTO compra (id_cliente, id_metodo) VALUES
(1, 4),
(2, 3),
(3, 1),
(4, 2),
(5, 5),
(6, 4),
(7, 3),
(8, 1),
(9, 2),
(10, 5);

-- 7. Insertar Detalle de Compra (10 filas)
INSERT INTO detalle_compra (id_compra, stock_id, cantidad_comprada, precio_unitario) VALUES
(1, 2, 1, 89999.00),
(2, 6, 1, 109999.00),
(3, 4, 2, 89999.00),
(4, 1, 1, 89999.00),
(5, 3, 1, 89999.00),
(6, 5, 1, 89999.00),
(7, 7, 1, 109999.00),
(8, 8, 2, 105000.00),
(9, 9, 1, 105000.00),
(10, 10, 1, 98000.00);
