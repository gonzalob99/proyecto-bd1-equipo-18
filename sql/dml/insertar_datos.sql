-- 1. Insertar Ligas
INSERT INTO liga (nombre) VALUES
('Liga Profesional Argentina'),
('LaLiga'),
('Premier League'),
('Serie A'),
('Bundesliga');

-- 2. Insertar Métodos de Pago
INSERT INTO metodo_pago (descripcion) VALUES
('Efectivo'),
('Tarjeta de Débito'),
('Tarjeta de Crédito'),
('Mercado Pago'),
('Transferencia Bancaria');

-- 3. Insertar Clientes
INSERT INTO cliente (nombre, apellido, email) VALUES
('Francisco', 'Goral', 'francisco@gmail.com'),
('Gonzalo', 'Biancardi', 'gonzalo@gmail.com'),
('Matias', 'Solis', 'matias@gmail.com'),
('Ezequiel', 'Hernandez', 'ezequiel@gmail.com'),
('Nicolas', 'Eduardo', 'nicolas@gmail.com');

-- 4. Insertar Productos (id_liga apunta a las ligas cargadas arriba)
INSERT INTO producto (id_liga, nombre, descripcion, precio_actual, equipo, equipacion) VALUES
(1, 'Camiseta Boca Juniors 2026', 'Camiseta titular tela dry-fit', 89999.00, 'Boca Juniors', 'Titular'),
(1, 'Camiseta River Plate 2026', 'Camiseta titular oficial', 89999.00, 'River Plate', 'Titular'),
(2, 'Camiseta Real Madrid 2026', 'Camiseta suplente azul', 109999.00, 'Real Madrid', 'Suplente'),
(2, 'Camiseta Barcelona 2026', 'Camiseta titular blaugrana', 109999.00, 'FC Barcelona', 'Titular'),
(3, 'Camiseta Manchester City 2026', 'Camiseta titular celeste', 105000.00, 'Manchester City', 'Titular');

-- 5. Insertar Stock (id_producto apunta a los productos cargados arriba)
INSERT INTO stock (id_producto, talle, cantidad_disponible) VALUES
(1, 'S', 10),
(1, 'M', 15),
(1, 'L', 20),
(2, 'M', 12),
(2, 'L', 8),
(3, 'L', 10),
(4, 'S', 5),
(5, 'XL', 7);

-- 6. Insertar Compras (id_cliente e id_metodo)
INSERT INTO compra (id_cliente, id_metodo) VALUES
(1, 4), -- Francisco compró con Mercado Pago
(2, 3), -- Gonzalo compró con Tarjeta de Crédito
(3, 1); -- Matias compró con Efectivo

-- 7. Insertar Detalle de Compra (id_compra y stock_id)
INSERT INTO detalle_compra (id_compra, stock_id, cantidad_comprada, precio_unitario) VALUES
(1, 2, 1, 89999.00), -- Compra 1 llevó 1 camiseta de Boca M
(2, 6, 1, 109999.00), -- Compra 2 llevó 1 camiseta de Real Madrid L
(3, 4, 2, 89999.00);  -- Compra 3 llevó 2 camisetas de River M