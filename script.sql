-- Creamos el administrador de la base de datos
CREATE ROLE admin_viveros WITH LOGIN PASSWORD 'contrasenia';

-- Creación de la base de datos:
CREATE DATABASE viveros WITH OWNER = admin_viveros;

-- Nos conectamos a la base de datos:
\c viveros;

-- Damos todos los privilegios al administrador
GRANT ALL PRIVILEGES ON DATABASE viveros TO admin_viveros;

-- Creación de las tablas

--1. Tabla Vivero
CREATE TABLE Vivero (
    id_vivero SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    longitud NUMERIC(9, 6) NOT NULL,
    latitud NUMERIC(9,6) NOT NULL,

    CONSTRAINT chk_rango_latitud_vivero CHECK(latitud BETWEEN -90 AND 90),
    CONSTRAINT chk_rango_longitud_vivero CHECK(longitud BETWEEN -180 AND 180)
);

--2. Tabla Zona
CREATE TABLE Zona (
    id_vivero INTEGER NOT NULL,
    id_zona INTEGER NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    latitud NUMERIC(9, 6),
    longitud NUMERIC(9, 6),

    PRIMARY KEY (id_vivero, id_zona),

    CONSTRAINT fk_id_vivero_zona FOREIGN KEY (id_vivero) REFERENCES Vivero(id_vivero) ON DELETE CASCADE ON UPDATE CASCADE,

    CONSTRAINT chk_rango_latitud_zona CHECK(latitud BETWEEN -90 AND 90),
    CONSTRAINT chk_rango_longitud_zona CHECK(longitud BETWEEN -180 AND 180)    
);


--3. Tabla Producto
CREATE TABLE Producto (
    id_producto SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL
);

--4. Tabla Almacena
CREATE TABLE Almacena (
    id_vivero INTEGER NOT NULL,
    id_zona INTEGER NOT NULL,
    id_producto INTEGER NOT NULL,
    cantidad INTEGER NOT NULL DEFAULT 0 CHECK (cantidad >= 0),

    PRIMARY KEY (id_vivero, id_zona, id_producto),

    CONSTRAINT fk_id_zona_almacena FOREIGN KEY (id_vivero, id_zona) REFERENCES Zona(id_vivero, id_zona) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_id_producto_almacena FOREIGN KEY (id_producto) REFERENCES Producto(id_producto) ON DELETE CASCADE ON UPDATE CASCADE
);


-- 5. Tabla Empleado
CREATE TABLE Empleado (
    id_empleado SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    dni VARCHAR(15) NOT NULL UNIQUE,
    apellido_1 VARCHAR(100) NOT NULL,
    apellido_2 VARCHAR(100)
);

-- 6. Table Cliente
CREATE TABLE Cliente (
    id_cliente SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    correo VARCHAR(150) NOT NULL,
    tipo VARCHAR(50)
);

--7. Tabla Afiliado
CREATE TABLE Afiliado (
    id_cliente INTEGER PRIMARY KEY,
    fecha_ingreso DATE NOT NULL,
    
    CONSTRAINT fk_id_cliente_afiliado FOREIGN KEY (id_cliente) REFERENCES Cliente(id_cliente) ON DELETE CASCADE ON UPDATE CASCADE
);
-- Actualmente, Afiliado no comprueba que el usuario sea del tipo afiliado, esto se solucionará con un trigger

--8. Tabla Bonificacion
CREATE TABLE Bonificacion (
    id_cliente INTEGER NOT NULL,
    bonificacion TEXT NOT NULL,

    PRIMARY KEY (id_cliente, bonificacion),
    
    CONSTRAINT fk_id_afiliado_bonificacion FOREIGN KEY (id_cliente) REFERENCES Afiliado(id_cliente) ON DELETE CASCADE ON UPDATE CASCADE
);

-- 9. Tabla Pedido
CREATE TABLE Pedido (
    id_pedido SERIAL PRIMARY KEY,
    fecha DATE NOT NULL,
    id_cliente INTEGER NOT NULL,
    id_empleado INTEGER NOT NULL,
    
    CONSTRAINT fk_id_cliente_pedido FOREIGN KEY (id_cliente) REFERENCES Cliente(id_cliente) ON UPDATE CASCADE,
    CONSTRAINT fk_id_empleado_pedido FOREIGN KEY (id_empleado) REFERENCES Empleado(id_empleado) ON UPDATE CASCADE
);

-- 10. Tabla Contiene
CREATE TABLE Contiene (
    id_producto INTEGER NOT NULL,
    id_pedido INTEGER NOT NULL,
    cantidad INTEGER NOT NULL,
    
    PRIMARY KEY (id_producto, id_pedido),

    CONSTRAINT fk_id_producto_contiene FOREIGN KEY (id_producto) REFERENCES Producto(id_producto) ON UPDATE CASCADE,
    CONSTRAINT fk_id_pedido_contiene FOREIGN KEY (id_pedido) REFERENCES Pedido(id_pedido) ON UPDATE CASCADE,

    CONSTRAINT chk_cantidad CHECK (cantidad > 0)
);

-- 11. Tabla Tarea
CREATE TABLE Tarea (
    id_tarea SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL
);

-- 12. Tabla Realiza
CREATE TABLE Realiza (
    id_empleado INTEGER NOT NULL,
    id_tarea INTEGER NOT NULL,
    id_vivero INTEGER NOT NULL,
    id_zona INTEGER NOT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE,
    puesto VARCHAR(100) NOT NULL,  -- Aunque podríamos haber creado otra relación

    PRIMARY KEY (id_empleado, id_tarea, id_vivero, id_zona, fecha_inicio),

    CONSTRAINT fk_id_empleado_realiza FOREIGN KEY (id_empleado) REFERENCES Empleado(id_empleado) ON UPDATE CASCADE,
    CONSTRAINT fk_id_tarea_realiza FOREIGN KEY (id_tarea) REFERENCES Tarea (id_tarea) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_id_zona_realiza FOREIGN KEY (id_vivero, id_zona) REFERENCES Zona(id_vivero, id_zona) ON DELETE CASCADE ON UPDATE CASCADE,

    CONSTRAINT chk_fecha CHECK (fecha_fin IS NULL OR fecha_fin >= fecha_inicio)
);

-- Para el atributo derivado del Afiliado, que cuenta la cantidad de pedidos, debemos hacer una vista
CREATE VIEW Vista_Afiliado AS
SELECT a.id_cliente, c.nombre, a.fecha_ingreso,
    (
        SELECT COUNT(*) 
        FROM Pedido p 
        WHERE p.id_cliente = a.id_cliente
    ) AS cantidad_pedidos
FROM 
    Afiliado a
JOIN 
    Cliente c ON a.id_cliente = c.id_cliente;

-- Inserción de datos para las tablas:

-- 1. Vivero
INSERT INTO Vivero (nombre, longitud, latitud) VALUES
    ('Vivero Central Norte', -16.251400, 28.463600),
    ('Vivero Anaga', -16.162200, 28.531100),
    ('Vivero Sur Granadilla', -16.578900, 28.124500),
    ('Vivero Valle de La Orotava', -16.523100, 28.391200),
    ('Vivero Costa Adeje', -16.732100, 28.083400);

-- 2. Zona
INSERT INTO Zona (id_vivero, id_zona, nombre, latitud, longitud) VALUES
    (1, 1, 'Zona de Invernadero A', 28.463700, -16.251500),
    (1, 2, 'Zona Exterior Plantas Exterior', 28.463800, -16.251600),
    (2, 1, 'Zona de Invernadero A', 28.531200, -16.162300),
    (3, 3, 'Zona Semilleros', NULL, NULL), -- Sin coordenadas específicas
    (4, 4, 'Zona Árboles Frutales', 28.391300, -16.523200);

-- 3. Producto
INSERT INTO Producto (nombre) VALUES
    ('Tajinaste Rojo (Echium wildpretii)'),
    ('Palmera Canaria (Phoenix canariensis)'),
    ('Sustrato Universal 50L'),
    ('Maceta de Cerámica 30cm'),
    ('Fertilizante Orgánico NPK');

-- 4. Almacena
INSERT INTO Almacena (id_vivero, id_zona, id_producto, cantidad) VALUES
    (1, 1, 1, 150), -- Tajinaste en Invernadero A
    (1, 2, 2, 45),  -- Palmera Canaria en Exterior
    (2, 1, 1, 0),   -- Sin stock de Tajinaste en Anaga (límite CHECK cantidad >= 0)
    (3, 3, 3, 200), -- Sustrato en Semilleros
    (4, 4, 4, 30);  -- Macetas en Árboles Frutales

-- 5. Empleado
INSERT INTO Empleado (nombre, dni, apellido_1, apellido_2) VALUES
    ('Carlos', '12345678A', 'Pérez', 'Gómez'),
    ('Sergio', '23456789B', 'Rosales', 'Calzadilla'),
    ('Carlos', '34567890C', 'Santana', NULL), -- Apellido 2 opcional
    ('Laura', '45678901D', 'Morales', 'Delgado'),
    ('Tania', '56789012E', 'Martín', 'Rodríguez');

-- 6. Cliente
INSERT INTO Cliente (nombre, correo, tipo) VALUES
    ('Elena Ramos', 'elena.ramos@email.com', 'Afiliado'),
    ('Jardines del Norte S.L.', 'contacto@jardinesnorte.com', 'Afiliado'),
    ('Pedro González', 'pedro.glez@email.com', 'Afiliado'),
    ('Hotel Miramar', 'compras@hotelmiramar.es', 'Afiliado'),
    ('Ayuntamiento Verde', 'parques@ayto.es', 'Afiliado'),
    ('Beatriz Alemán', 'b.aleman@email.com', NULL); -- no afiliado

-- 7. Afiliado
INSERT INTO Afiliado (id_cliente, fecha_ingreso) VALUES
    (1, '2022-01-15'),
    (2, '2022-06-20'),
    (3, '2023-03-10'),
    (4, '2023-11-01'),
    (5, '2024-01-10');

-- 8. Bonificación
INSERT INTO Bonificacion (id_cliente, bonificacion) VALUES
    (1, 'Descuento del 10% en plantas autóctonas'),
    (1, 'Envío gratuito en compras superiores a 50€'), -- Múltiple o para cliente 1
    (2, 'Tarifa especial Mayorista 15%'),
    (3, 'Cupón bienvenida 5€'),
    (4, 'Mantenimiento de jardinería gratuito 1 mes');


-- 9. Pedido
INSERT INTO Pedido (fecha, id_cliente, id_empleado) VALUES
    ('2024-03-01', 1, 1),
    ('2024-03-02', 2, 2),
    ('2024-03-05', 1, 3), -- Mismo cliente (1) en fecha distinta
    ('2024-03-10', 3, 1),
    ('2024-03-12', 4, 4);

-- 10. Contiene
INSERT INTO Contiene (id_producto, id_pedido, cantidad) VALUES
    (1, 1, 5),  -- Pedido 1 lleva 5 Tajinastes
    (3, 1, 2),  -- Pedido 1 además lleva 2 Sustratos (Múltiples productos por pedido)
    (2, 2, 10), -- Pedido 2 lleva 10 Palmeras
    (4, 3, 4),  -- Pedido 3 lleva 4 Macetas
    (5, 4, 1);  -- Pedido 4 lleva 1 Fertilizante

-- 11. Tarea
INSERT INTO Tarea (nombre) VALUES
    ('Riego y Fertilización'),
    ('Poda de Formación'),
    ('Control de Plagas'),
    ('Inventario y Reagrupación'),
    ('Atención al Cliente y Cobro');

-- 12. Realiza
INSERT INTO Realiza (id_empleado, id_tarea, id_vivero, id_zona, fecha_inicio, fecha_fin, puesto) VALUES

    -- ESCENARIO 1: Tarea en curso (fecha_fin IS NULL)
    -- El empleado 1 inicia una tarea de riego y aún no ha finalizado.
    (1, 1, 1, 1, '2024-03-01', NULL, 'Técnico de Riego'),

    -- ESCENARIO 2: Tarea completada el mismo día (fecha_fin = fecha_inicio)
    -- El mismo empleado 1 realiza OTRA tarea (2) el mismo día en la misma zona.
    -- (Varía id_tarea en la PK).
    (1, 2, 1, 1, '2024-03-01', '2024-03-01', 'Auxiliar de Jardinería'),

    -- ESCENARIO 3: Tarea periódica/repetida (Mismo empleado, tarea, vivero y zona, diferente fecha_inicio)
    -- El empleado 1 vuelve a hacer la tarea 1 en la zona (1,1), pero en una fecha posterior.
    -- (Varía fecha_inicio en la PK).
    (1, 1, 1, 1, '2024-03-15', '2024-03-15', 'Técnico de Riego'),

    -- ESCENARIO 4: Movilidad del empleado (Mismo empleado y tarea, diferente zona/vivero)
    -- El empleado 1 realiza la tarea 1, pero esta vez en el vivero 1, zona 2.
    -- (Varía id_zona en la PK).
    (1, 1, 1, 2, '2024-03-10', '2024-03-11', 'Técnico de Riego'),

    -- ESCENARIO 5: Trabajo en equipo / Coincidencia de tarea y fecha
    -- El empleado 2 realiza la misma tarea (1) en la misma zona (1,1) y misma fecha que el empleado 1.
    -- (Varía id_empleado en la PK).
    (2, 1, 1, 1, '2024-03-01', '2024-03-02', 'Asistente de Riego'),

    -- ESCENARIO 6: Tarea de larga duración finalizada
    -- El empleado 3 realiza la tarea 3 (Control de Plagas) en otra zona durante varios días.
    (3, 1, 2, 1, '2024-03-01', '2024-03-10', 'Especialista Fitosanitario'),

    -- ESCENARIO 7: Cambio de puesto y rol para el mismo empleado
    -- El empleado 2 en una zona completamente distinta con otro puesto asignado.
    (2, 4, 3, 3, '2024-03-20', NULL, 'Encargado de Inventario');


-- Operaciones de borrado

-- Primero preparamos nuevas entradas en las tablas para borrarlas y no tocar las originales.

-- Datos para el Ejemplo 1
INSERT INTO Pedido (id_pedido, fecha, id_cliente, id_empleado) 
VALUES (999, '2024-12-31', 1, 1);

-- Datos para el Ejemplo 2 (Vivero y sus dependencias para borrado en cascada)
INSERT INTO Vivero (id_vivero, nombre, longitud, latitud) 
VALUES (999, 'Vivero Temporal de Prueba', 0.000000, 0.000000);
INSERT INTO Zona (id_vivero, id_zona, nombre, latitud, longitud) 
VALUES (999, 1, 'Zona Temporal', 0.000000, 0.000000);
INSERT INTO Almacena (id_vivero, id_zona, id_producto, cantidad) 
VALUES (999, 1, 1, 50);

-- Datos para el Ejemplo 3 (Empleado y sus dependencias)
INSERT INTO Empleado (id_empleado, nombre, dni, apellido_1, apellido_2) 
VALUES (999, 'Empleado', '99999999X', 'De', 'Prueba');
INSERT INTO Pedido (id_pedido, fecha, id_cliente, id_empleado) 
VALUES (998, '2024-12-31', 1, 999);
INSERT INTO Contiene (id_producto, id_pedido, cantidad) 
VALUES (1, 998, 5);
INSERT INTO Realiza (id_empleado, id_tarea, id_vivero, id_zona, fecha_inicio, fecha_fin, puesto) 
VALUES (999, 1, 1, 1, '2024-12-31', '2024-12-31', 'Puesto Temporal');

-- A continuación realizamos el borrado:

-- Ejemplo 1: Borrado simple (Sin restricciones)
DELETE FROM Pedido 
WHERE id_pedido = 999;


-- Ejemplo 2: Borrado en Cascada (ON DELETE CASCADE)
DELETE FROM Vivero 
WHERE id_vivero = 999;


-- Ejemplo 3: Borrado manual.
-- Queremos borrar al Empleado 999, pero tiene datos en 'Realiza' y 'Pedido'.
-- Borramos de abajo hacia arriba para respetar la integridad referencial:

-- Eliminamos su historial en la tabla 'Realiza'
DELETE FROM Realiza 
WHERE id_empleado = 999;

-- Vaciamos los productos de sus pedidos en 'Contiene'
DELETE FROM Contiene 
WHERE id_pedido IN (SELECT id_pedido FROM Pedido WHERE id_empleado = 999);

-- Borramos los registros de 'Pedido' gestionados por él
DELETE FROM Pedido 
WHERE id_empleado = 999;

-- Finalmente, ya podemos borrar al Empleado sin que de error
DELETE FROM Empleado 
WHERE id_empleado = 999;