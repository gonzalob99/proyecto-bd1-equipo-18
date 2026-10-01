USE AuraStore;
GO

--LIGAS
--Eredivisie, Liga MX y MLS quedan sin productos por ahora
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

--METODOS DE PAGO
INSERT INTO metodo_pago (descripcion) VALUES
('Efectivo'),
('Tarjeta de Débito'),
('Tarjeta de Crédito'),
('Mercado Pago'),
('Transferencia Bancaria'),
('MODO'),
('Cuenta DNI'),
('Cripto / USDT');

--CLIENTES
--Valentina se registro pero todavia no compro nada
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
('Agustina', 'Lopez', 'agustina@gmail.com'),
('Valentina', 'Ruiz', 'valentina@gmail.com');

--PRODUCTOS
--la de boca ya tiene el precio nuevo (antes estaba 89999)
INSERT INTO producto (id_liga, nombre, descripcion, precio_actual, equipo, equipacion) VALUES
(1, 'Camiseta Boca Juniors 2026', 'Camiseta titular dry-fit', 95999.00, 'Boca Juniors', 'Titular'),
(1, 'Camiseta River Plate 2026', 'Camiseta titular oficial', 89999.00, 'River Plate', 'Titular'),
(2, 'Camiseta Real Madrid 2026', 'Camiseta suplente azul', 109999.00, 'Real Madrid', 'Suplente'),
(2, 'Camiseta Barcelona 2026', 'Camiseta titular blaugrana', 109999.00, 'FC Barcelona', 'Titular'),
(3, 'Camiseta Manchester City 2026', 'Camiseta titular celeste', 105000.00, 'Manchester City', 'Titular'),
(3, 'Camiseta Arsenal 2026', 'Camiseta titular roja', 105000.00, 'Arsenal', 'Titular'),
(4, 'Camiseta Inter Milan 2026', 'Camiseta titular nerazzurra', 98000.00, 'Inter Milan', 'Titular'),
(5, 'Camiseta Bayern Munich 2026', 'Camiseta titular roja', 99000.00, 'Bayern Munich', 'Titular'),
(6, 'Camiseta PSG 2026', 'Camiseta titular azul', 102000.00, 'PSG', 'Titular'),
(7, 'Camiseta Flamengo 2026', 'Camiseta titular rubro-negra', 92000.00, 'Flamengo', 'Titular'),
(1, 'Camiseta Boca Juniors 2026 Suplente', 'Camiseta suplente amarilla', 85000.00, 'Boca Juniors', 'Suplente'),
(6, 'Camiseta PSG 2026 Suplente', NULL, 102000.00, 'PSG', 'Suplente');

--STOCK
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
(7, 'L', 9),
(8, 'M', 6),
(8, 'L', 0),
(9, 'M', 10),
(10, 'L', 4),
(11, 'M', 8),
(11, 'L', 5),
(12, 'S', 3);

--COMPRAS
--Matias compra dos veces el 12/09, Francisco y Gonzalo tienen mas de una compra
INSERT INTO compra (id_cliente, id_metodo, fecha) VALUES
(1, 4, '2026-08-04T11:20:00'),
(2, 3, '2026-08-07T16:10:00'),
(3, 1, '2026-08-12T09:45:00'),
(4, 2, '2026-08-15T20:30:00'),
(5, 5, '2026-08-21T13:05:00'),
(6, 4, '2026-08-26T18:40:00'),
(7, 3, '2026-09-01T10:00:00'),
(8, 1, '2026-09-03T17:25:00'),
(9, 2, '2026-09-06T12:15:00'),
(10, 5, '2026-09-09T19:50:00'),
(3, 4, '2026-09-12T10:30:00'),
(3, 1, '2026-09-12T18:05:00'),
(1, 3, '2026-09-20T15:45:00'),
(2, 4, '2026-09-27T11:20:00');

--DETALLE DE COMPRAS
--boca se vendio a 89999 hasta el aumento, la ultima compra ya es a 95999
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
(10, 10, 1, 98000.00),
(11, 2, 1, 89999.00),
(12, 15, 1, 85000.00),
(13, 6, 1, 109999.00),
(13, 11, 2, 99000.00),
(14, 1, 1, 95999.00);