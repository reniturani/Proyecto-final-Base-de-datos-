DROP DATABASE IF EXISTS biblioteca;
CREATE DATABASE biblioteca;
USE biblioteca;

-- TABLAS --

CREATE TABLE usuarios (
    id_usuario INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    apellido VARCHAR(50) NOT NULL,
    fecha_inscripcion DATE NOT NULL,
    cuota_mensual DECIMAL (10,2) NOT NULL ,
    cuota_al_dia BOOLEAN DEFAULT TRUE
);

CREATE TABLE libros (
    id_libro INT AUTO_INCREMENT PRIMARY KEY,
    titulo VARCHAR(100) NOT NULL,
    autor VARCHAR(100) NOT NULL,
    anio INT,
    estado ENUM('disponible','prestado') DEFAULT 'disponible'
);

CREATE TABLE prestamos (
    id_prestamo INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario INT NOT NULL,
    id_libro INT NOT NULL,
    fecha_prestamo DATE NOT NULL,
    fecha_estimada DATE NOT NULL,
    fecha_devolucion DATE,
    multa DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario),
    FOREIGN KEY (id_libro) REFERENCES libros(id_libro)
);

CREATE TABLE cuotas (
    anio INT NOT NULL,
    mes INT NOT NULL,
    monto DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (anio, mes)
);


-- INSERTS --

INSERT INTO usuarios (nombre, apellido, fecha_inscripcion, cuota_mensual, cuota_al_dia) VALUES
('Lucía', 'Gómez', '2025-01-15', 2500.00, TRUE),
('Martín', 'Ríos', '2025-02-10', 2500.00, TRUE),
('Ana', 'Pérez', '2025-03-05', 2500.00, FALSE),
('Diego', 'Cano', '2025-01-28', 2500.00, TRUE),
('Mariana', 'López', '2025-02-18', 2500.00, FALSE),
('Julián', 'Soto', '2025-02-25', 2500.00, TRUE),
('Sofía', 'Mena', '2025-03-12', 2500.00, TRUE),
('Carlos', 'Vega', '2025-01-10', 2500.00, FALSE),
('Elena', 'Forte', '2025-02-03', 2500.00, TRUE),
('Hernán', 'Duarte', '2025-03-01', 2500.00, TRUE);

INSERT INTO libros (titulo, autor, anio, estado) VALUES
('Cien años de soledad', 'Gabriel García Márquez', 1967, 'disponible'),
('1984', 'George Orwell', 1949, 'disponible'),
('El principito', 'Antoine de Saint-Exupéry', 1943, 'prestado'),
('Fahrenheit 451', 'Ray Bradbury', 1953, 'disponible'),
('Crimen y castigo', 'Fiódor Dostoyevski', 1866, 'disponible'),
('Don Quijote de la Mancha', 'Miguel de Cervantes', 1605, 'prestado'),
('El hobbit', 'J. R. R. Tolkien', 1937, 'disponible'),
('La sombra del viento', 'Carlos Ruiz Zafón', 2001, 'disponible'),
('El alquimista', 'Paulo Coelho', 1988, 'disponible'),
('El túnel', 'Ernesto Sabato', 1948, 'disponible');

INSERT INTO prestamos (id_usuario, id_libro, fecha_prestamo, fecha_estimada, fecha_devolucion, multa) VALUES
(1, 3, '2025-04-01', '2025-04-15', '2025-04-14', 0.00),
(2, 6, '2025-04-10', '2025-04-25', NULL, 0.00),
(3, 2, '2025-03-20', '2025-04-05', '2025-04-10', 50.00),
(4, 1, '2025-02-15', '2025-03-01', '2025-03-02', 20.00),
(5, 8, '2025-05-05', '2025-05-20', NULL, 0.00),
(6, 4, '2025-04-22', '2025-05-07', NULL, 0.00),
(7, 10, '2025-05-10', '2025-05-25', NULL, 0.00),
(8, 5, '2025-02-01', '2025-02-15', '2025-02-18', 30.00),
(9, 7, '2025-03-11', '2025-03-26', '2025-03-26', 0.00),
(10, 9, '2025-04-03', '2025-04-18', NULL, 0.00),
(1, 1, '2025-02-05', '2025-02-20', NULL, 0.00),
(3, 3, '2025-01-25', '2025-02-10', '2025-02-20', 75.00);

INSERT INTO cuotas (anio, mes, monto) VALUES
(2025, 1, 2500.00),
(2025, 2, 2500.00),
(2025, 3, 2500.00),
(2025, 4, 2500.00),
(2025, 5, 2500.00),
(2025, 6, 2500.00),
(2025, 7, 2500.00),
(2025, 8, 2500.00),
(2025, 9, 2500.00),
(2025, 10, 2500.00),
(2025, 11, 2500.00),
(2025, 12, 2500.00);

