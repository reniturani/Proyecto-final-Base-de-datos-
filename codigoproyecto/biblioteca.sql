DROP DATABASE IF EXISTS biblioteca;
CREATE DATABASE biblioteca;
USE biblioteca;

-- =========================
-- TABLAS
-- =========================
CREATE TABLE usuarios (
    id_usuario INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    apellido VARCHAR(100) NOT NULL,
    direccion VARCHAR(255) NOT NULL,
    telefono VARCHAR(20) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    fecha_inscripcion DATE NOT NULL,
    cuota_mensual DECIMAL(10,2) NOT NULL DEFAULT 2500.00,
    cuota_al_dia BOOLEAN NOT NULL DEFAULT TRUE,
    estado ENUM('activo','inactivo') NOT NULL DEFAULT 'activo'
) ENGINE=InnoDB;

CREATE TABLE libros (
    id_libro INT AUTO_INCREMENT PRIMARY KEY,
    titulo VARCHAR(255) NOT NULL,
    editorial VARCHAR(255) NOT NULL,
    categoria VARCHAR(100) NOT NULL,
    autor VARCHAR(255) NOT NULL,
    anio_publicacion INT NOT NULL,
    cantidad_total INT NOT NULL,
    cantidad_disponible INT NOT NULL,
    CONSTRAINT chk_cant CHECK (cantidad_total >= 0 AND cantidad_disponible >= 0)
) ENGINE=InnoDB;

CREATE TABLE prestamos (
    id_prestamo INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario INT NOT NULL,
    id_libro INT NOT NULL,
    fecha_prestamo DATE NOT NULL,
    fecha_estimada_devolucion DATE NOT NULL,
    fecha_devolucion DATE NULL,
    multa DECIMAL(10,2) DEFAULT 0,
    estado ENUM('activo','devuelto','retrasado') NOT NULL DEFAULT 'activo',
    FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (id_libro) REFERENCES libros(id_libro) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE pagos (
    id_pago INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario INT NOT NULL,
    anio INT NOT NULL,
    mes INT NOT NULL,
    monto DECIMAL(10,2) NOT NULL,
    estado ENUM('pagado','pendiente','atrasado') NOT NULL DEFAULT 'pendiente',
    FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario) ON DELETE CASCADE ON UPDATE CASCADE,
    UNIQUE KEY uk_user_anio_mes (id_usuario, anio, mes)
) ENGINE=InnoDB;

-- =========================
-- ÍNDICES 
-- =========================
CREATE INDEX idx_libros_titulo ON libros (titulo);
CREATE INDEX idx_usuarios_nombre ON usuarios (nombre, apellido);
CREATE INDEX idx_prestamos_usuario ON prestamos (id_usuario);
CREATE INDEX idx_pagos_estado ON pagos (estado);

-- =========================
-- FUNCIONES y PROCEDIMIENTOS
-- =========================
-- Función para calcular multa: devuelve monto de multa dado id_prestamo y fecha referencia
DROP FUNCTION IF EXISTS fn_calcular_multa;
DELIMITER $$
CREATE FUNCTION fn_calcular_multa(pid INT, fecha_ref DATE)
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    DECLARE v_fecha_est DATE;
    DECLARE v_id_usuario INT;
    DECLARE v_cuota DECIMAL(10,2);
    DECLARE v_dias INT;
    DECLARE v_multa DECIMAL(10,2);

    SELECT fecha_estimada_devolucion, id_usuario INTO v_fecha_est, v_id_usuario
    FROM prestamos WHERE id_prestamo = pid;

    IF v_fecha_est IS NULL THEN
        RETURN 0;
    END IF;

    IF fecha_ref <= v_fecha_est THEN
        RETURN 0;
    END IF;

    SET v_dias = DATEDIFF(fecha_ref, v_fecha_est);

    SELECT cuota_mensual INTO v_cuota FROM usuarios WHERE id_usuario = v_id_usuario;

    SET v_multa = v_dias * (v_cuota * 0.03);

    RETURN ROUND(v_multa,2);
END$$
DELIMITER ;

-- Procedimiento para devolver préstamo (actualiza fecha_devolucion, multa y estado; incrementa stock)
DROP PROCEDURE IF EXISTS sp_devolver_prestamo;
DELIMITER $$
CREATE PROCEDURE sp_devolver_prestamo(
    IN pid INT,
    IN p_fecha_devolucion DATE
)
BEGIN
    DECLARE v_fecha_est DATE;
    DECLARE v_id_libro INT;
    DECLARE v_id_usuario INT;
    DECLARE v_multa DECIMAL(10,2);

    START TRANSACTION;
        SELECT fecha_estimada_devolucion, id_libro, id_usuario INTO v_fecha_est, v_id_libro, v_id_usuario
        FROM prestamos WHERE id_prestamo = pid FOR UPDATE;

        IF v_fecha_est IS NULL THEN
            ROLLBACK;
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Prestamo no encontrado';
        END IF;

        IF p_fecha_devolucion > v_fecha_est THEN
            SET v_multa = fn_calcular_multa(pid, p_fecha_devolucion);
            UPDATE prestamos SET fecha_devolucion = p_fecha_devolucion, multa = v_multa, estado = 'retrasado' WHERE id_prestamo = pid;
        ELSE
            SET v_multa = 0;
            UPDATE prestamos SET fecha_devolucion = p_fecha_devolucion, multa = 0, estado = 'devuelto' WHERE id_prestamo = pid;
        END IF;

        UPDATE libros SET cantidad_disponible = cantidad_disponible + 1 WHERE id_libro = v_id_libro;
    COMMIT;
END$$
DELIMITER ;

-- Procedimiento para crear préstamo (valida disponibilidad, decrementa stock)
DROP PROCEDURE IF EXISTS sp_crear_prestamo;
DELIMITER $$
CREATE PROCEDURE sp_crear_prestamo(
    IN p_id_usuario INT,
    IN p_id_libro INT,
    IN p_fecha_estimada DATE
)
BEGIN
    DECLARE v_disponible INT;

    START TRANSACTION;
        SELECT cantidad_disponible INTO v_disponible FROM libros WHERE id_libro = p_id_libro FOR UPDATE;
        IF v_disponible IS NULL THEN
            ROLLBACK;
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Libro no existe';
        END IF;

        IF v_disponible <= 0 THEN
            ROLLBACK;
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No hay ejemplares disponibles';
        END IF;

        INSERT INTO prestamos (id_usuario, id_libro, fecha_prestamo, fecha_estimada_devolucion, estado)
        VALUES (p_id_usuario, p_id_libro, CURDATE(), p_fecha_estimada, 'activo');

        UPDATE libros SET cantidad_disponible = cantidad_disponible - 1 WHERE id_libro = p_id_libro;
    COMMIT;
END$$
DELIMITER ;


-- Usuarios 
INSERT INTO usuarios (nombre, apellido, direccion, telefono, email, fecha_inscripcion, cuota_mensual, cuota_al_dia, estado) VALUES
('Juan', 'Pérez', 'Av. Libertad 123', '1122334455', 'juan.perez@example.com', DATE_SUB(CURDATE(), INTERVAL 12 MONTH), 2500.00, TRUE, 'activo'),
('Ana', 'Gómez', 'Calle Falsa 742', '1133445566', 'ana.gomez@example.com', DATE_SUB(CURDATE(), INTERVAL 8 MONTH), 2500.00, FALSE, 'activo'),
('Luis', 'Martinez', 'San Martín 555', '1144556677', 'luis.martinez@example.com', DATE_SUB(CURDATE(), INTERVAL 10 MONTH), 2500.00, TRUE, 'activo'),
('Marta', 'Rodriguez', 'Belgrano 220', '1155667788', 'marta.rod@example.com', DATE_SUB(CURDATE(), INTERVAL 9 MONTH), 2500.00, TRUE, 'inactivo'),
('Pedro', 'López', 'Mitre 980', '1166778899', 'pedro.lopez@example.com', DATE_SUB(CURDATE(), INTERVAL 11 MONTH), 2500.00, FALSE, 'activo'),
('Lucia', 'Fernandez', 'Rivadavia 321', '1177889900', 'lucia.fernandez@example.com', DATE_SUB(CURDATE(), INTERVAL 6 MONTH), 2500.00, TRUE, 'activo'),
('Ricardo', 'Sosa', 'Urquiza 500', '1188990011', 'ricardo.sosa@example.com', DATE_SUB(CURDATE(), INTERVAL 13 MONTH), 2500.00, FALSE, 'activo'),
('Carla', 'Suarez', 'Chacabuco 45', '1199001122', 'carla.suarez@example.com', DATE_SUB(CURDATE(), INTERVAL 7 MONTH), 2500.00, TRUE, 'inactivo'),
('Diego', 'Ramirez', 'Independencia 111', '1100112233', 'diego.ramirez@example.com', DATE_SUB(CURDATE(), INTERVAL 10 MONTH), 2500.00, TRUE, 'activo'),
('Florencia', 'Alvarez', 'Sarmiento 800', '1111223344', 'flor.alvarez@example.com', DATE_SUB(CURDATE(), INTERVAL 11 MONTH), 2500.00, FALSE, 'activo');

-- Libros
INSERT INTO libros (titulo, editorial, categoria, autor, anio_publicacion, cantidad_total, cantidad_disponible) VALUES
('Cien Años de Soledad', 'Sudamericana', 'Novela', 'Gabriel García Márquez', 1967, 10, 7),
('El Hobbit', 'Minotauro', 'Fantasia', 'J.R.R. Tolkien', 1937, 8, 4),
('1984', 'Debolsillo', 'Distopía', 'George Orwell', 1949, 12, 9),
('El Principito', 'Emecé', 'Infantil', 'Antoine de Saint-Exupéry', 1943, 15, 10),
('Don Quijote de la Mancha', 'Alfaguara', 'Clásico', 'Miguel de Cervantes', 1605, 5, 2),
('Harry Potter y la Piedra Filosofal', 'Salamandra', 'Fantasia', 'J.K. Rowling', 1997, 14, 11),
('El Señor de los Anillos', 'Minotauro', 'Fantasia', 'J.R.R. Tolkien', 1954, 9, 3),
('Rayuela', 'Sudamericana', 'Novela', 'Julio Cortázar', 1963, 7, 5),
('Fahrenheit 451', 'Debolsillo', 'Ciencia Ficción', 'Ray Bradbury', 1953, 10, 8),
('La Odisea', 'Gredos', 'Épico', 'Homero', 800, 6, 6);

-- Prestamos 
INSERT INTO prestamos (id_usuario, id_libro, fecha_prestamo, fecha_estimada_devolucion, fecha_devolucion, multa, estado) VALUES
(1, 1, DATE_SUB(CURDATE(), INTERVAL 300 DAY), DATE_SUB(CURDATE(), INTERVAL 290 DAY), DATE_SUB(CURDATE(), INTERVAL 292 DAY), 0, 'devuelto'),
(2, 3, DATE_SUB(CURDATE(), INTERVAL 40 DAY), DATE_SUB(CURDATE(), INTERVAL 30 DAY), NULL, 0, 'activo'),
(3, 5, DATE_SUB(CURDATE(), INTERVAL 25 DAY), DATE_SUB(CURDATE(), INTERVAL 15 DAY), DATE_SUB(CURDATE(), INTERVAL 10 DAY), 300, 'retrasado'),
(4, 2, DATE_SUB(CURDATE(), INTERVAL 20 DAY), DATE_SUB(CURDATE(), INTERVAL 10 DAY), NULL, 0, 'activo'),
(5, 7, DATE_SUB(CURDATE(), INTERVAL 50 DAY), DATE_SUB(CURDATE(), INTERVAL 40 DAY), DATE_SUB(CURDATE(), INTERVAL 38 DAY), 200, 'retrasado'),
(6, 4, DATE_SUB(CURDATE(), INTERVAL 60 DAY), DATE_SUB(CURDATE(), INTERVAL 50 DAY), DATE_SUB(CURDATE(), INTERVAL 50 DAY), 0, 'devuelto'),
(7, 8, DATE_SUB(CURDATE(), INTERVAL 15 DAY), DATE_SUB(CURDATE(), INTERVAL 5 DAY), NULL, 0, 'activo'),
(8, 6, DATE_SUB(CURDATE(), INTERVAL 35 DAY), DATE_SUB(CURDATE(), INTERVAL 25 DAY), DATE_SUB(CURDATE(), INTERVAL 18 DAY), 400, 'retrasado'),
(9, 9, DATE_SUB(CURDATE(), INTERVAL 10 DAY), DATE_SUB(CURDATE(), INTERVAL 1 DAY), NULL, 0, 'activo'),
(10, 10, DATE_SUB(CURDATE(), INTERVAL 5 DAY), DATE_ADD(DATE_SUB(CURDATE(), INTERVAL 5 DAY), INTERVAL 10 DAY), NULL, 0, 'activo');

-- Pagos 
INSERT INTO pagos (id_usuario, anio, mes, monto, estado) VALUES
(1, YEAR(CURDATE()), MONTH(CURDATE()), 2500.00, 'pagado'),
(2, YEAR(CURDATE()), MONTH(CURDATE()), 2500.00, 'pendiente'),
(3, YEAR(CURDATE()), MONTH(CURDATE()), 2500.00, 'pagado'),
(4, YEAR(CURDATE()), MONTH(CURDATE()), 2500.00, 'atrasado'),
(5, YEAR(CURDATE()), MONTH(CURDATE()), 2500.00, 'pagado'),
(6, YEAR(CURDATE()), MONTH(CURDATE()), 2500.00, 'pendiente'),
(7, YEAR(CURDATE()), MONTH(CURDATE()), 2500.00, 'pagado'),
(8, YEAR(CURDATE()), MONTH(CURDATE()), 2500.00, 'atrasado'),
(9, YEAR(CURDATE()), MONTH(CURDATE()), 2500.00, 'pagado'),
(10, YEAR(CURDATE()), MONTH(CURDATE()), 2500.00, 'pendiente');
