-- Crear Schema
CREATE SCHEMA IF NOT EXISTS farmacia;

-- Crear Tablas
CREATE TABLE farmacia.categoria (
    id_categoria SERIAL PRIMARY KEY,
    nombre VARCHAR(22),
    descripcion VARCHAR(320)
);

CREATE TABLE farmacia.proveedores (
    id_proveedor SERIAL PRIMARY KEY,
    nombre VARCHAR(23) NOT NULL,
    contacto_nombre VARCHAR(24) NOT NULL,
    contacto_email VARCHAR (23) NOT NULL,
    telefono VARCHAR (10) NOT NULL,
    direccion VARCHAR (32) NOT NULL
);

CREATE TABLE farmacia.metodos_pago (
    id_metodo_pago SERIAL PRIMARY KEY,
    nombre VARCHAR(23)
);

CREATE TABLE farmacia.supermercados (
    id_supermercado SERIAL PRIMARY KEY,
    nombre VARCHAR(25) NOT NULL,
    direccion VARCHAR(26) NOT NULL,
    ciudad TEXT,
    pais VARCHAR (26)
);

CREATE TABLE farmacia.clientes (
    id_cliente SERIAL PRIMARY KEY,
    nombre VARCHAR(25) NOT NULL,
    apellido VARCHAR (25) NOT NULL,
    email VARCHAR (23) NOT NULL,
    telefono VARCHAR(10),
    direccion VARCHAR(34)
);

CREATE TABLE farmacia.empleados (
    id_empleado SERIAL PRIMARY KEY,
    nombre VARCHAR(23) NOT NULL,
    apellido VARCHAR(22) NOT NULL,
    puesto VARCHAR (20) NOT NULL,
    salario DECIMAL(10,2) NOT NULL,
    fecha_ingreso DATE NOT NULL
);

CREATE TABLE farmacia.productos (
    id_producto SERIAL PRIMARY KEY,
    nombre VARCHAR(25) NOT NULL,
    descripcion VARCHAR(390) NOT NULL,
    precio DECIMAL(23,2) NOT NULL,
    id_categoria INT,
    id_proveedor INT,
    stock INT NOT NULL CHECK (stock > 0),
    fecha_ingreso DATE,
    FOREIGN KEY (id_categoria) REFERENCES farmacia.categoria(id_categoria),
    FOREIGN KEY (id_proveedor) REFERENCES farmacia.proveedores(id_proveedor)
);


CREATE TABLE farmacia.ventas (
    id_venta SERIAL PRIMARY KEY,
    id_cliente INT,
    id_empleado INT,
    id_supermercado INT,
    fecha_venta DATE DEFAULT CURRENT_DATE,
	id_producto INT,
    total DECIMAL (38,2) NOT NULL CHECK(total > 0),
    id_metodo_pago INT,
    FOREIGN KEY (id_cliente) REFERENCES farmacia.clientes(id_cliente),
    FOREIGN KEY (id_empleado) REFERENCES farmacia.empleados(id_empleado),
    FOREIGN KEY (id_supermercado) REFERENCES farmacia.supermercados(id_supermercado),
    FOREIGN KEY (id_metodo_pago) REFERENCES farmacia.metodos_pago(id_metodo_pago),
	FOREIGN KEY (id_producto) REFERENCES farmacia.productos (id_producto)
);

--- Insertar Datos

INSERT INTO farmacia.categoria (nombre, descripcion) 
VALUES 
    ('Frutas', 'Productos frescos y naturales como manzanas, naranjas, etc.'),
    ('Verduras', 'Productos frescos como lechugas, zanahorias, etc.'),
    ('Lácteos', 'Productos derivados de la leche como quesos, yogures, etc.'),
    ('Bebidas', 'Bebidas gaseosas, jugos, aguas, etc.');

INSERT INTO farmacia.proveedores (nombre, contacto_nombre, contacto_email, telefono, direccion) 
VALUES 
    ('Proveedor A', 'Carlos Pérez', 'carlos@proveedora.com', '555-1234', 'Av. 123, Bogotá'),
    ('Proveedor B', 'Ana Gómez', 'ana@proveedora.com', '555-5678', 'Calle 45, Medellín');

INSERT INTO farmacia.metodos_pago (nombre) 
VALUES 
    ('Efectivo'),
    ('Tarjeta de Crédito'),
    ('Tarjeta de Débito');

INSERT INTO farmacia.productos (nombre, descripcion, precio, id_categoria, id_proveedor, stock, fecha_ingreso) 
VALUES 
    ('Manzana', 'Fruta roja, rica en vitaminas', 1.50, 1, 1, 100, '2024-01-01'),
    ('Leche Entera', 'Leche de vaca entera', 2.00, 3, 2, 200, '2024-01-01'),
    ('Zanahoria', 'Verdura fresca, rica en vitamina A', 1.20, 2, 1, 150, '2024-01-01'),
    ('Coca-Cola', 'Bebida refrescante', 1.00, 4, 2, 250, '2024-01-01');


-- Desarrollar Consultas

--- Ventas en un supermercado especifico
SELECT v.id_venta, v.fecha_venta, p.nombre AS producto, v.total, c.nombre AS cliente
FROM farmacia.ventas v
JOIN farmacia.productos p ON v.id_venta = p.id_producto
JOIN farmacia.clientes c ON v.id_cliente = c.id_cliente
WHERE v.id_supermercado = 1;

--- Producto mas vendido
SELECT p.nombre AS producto, v.id_supermercado, SUM(v.total) AS total_ventas
FROM farmacia.ventas v
JOIN farmacia.productos p ON v.id_producto = p.id_producto
GROUP BY p.nombre, v.id_supermercado
ORDER BY total_ventas DESC
LIMIT 1;


--- Ventas totales supermercados
SELECT s.nombre AS supermercado, SUM(v.total) AS total_ventas
FROM farmacia.ventas v
JOIN farmacia.supermercados s ON v.id_supermercado = s.id_supermercado
GROUP BY supermercado
ORDER BY total_ventas DESC;

--- Clientes que han comprado mas de una vez, (en caso de que no se permita visualizar los datos del comprador)
SELECT c.id_cliente AS cliente, COUNT(v.id_venta)AS numero_ventas
FROM farmacia.clientes c
JOIN farmacia.ventas v ON c.id_cliente = v.id_cliente
GROUP BY c.id_cliente
HAVING COUNT (v.id_venta) > 1
ORDER BY numero_ventas DESC;

---- Clientes que han comprado mas de una vez con nombre 
SELECT c.nombre, c.apellido, COUNT(v.id_venta) AS num_compras
FROM farmacia.clientes c
JOIN farmacia.ventas v ON c.id_cliente = v.id_cliente
GROUP BY c.id_cliente
HAVING COUNT(v.id_venta) > 1;



--- Productos de una categoría específica y su stock
SELECT p.nombre AS producto,  p.stock AS stock, c.nombre AS categoria
FROM farmacia.productos p
JOIN farmacia.categoria c ON p.id_categoria =c.id_categoria
GROUP BY p.nombre
ORDER BY c.nombre DESC;


--- Sumar el stock por categoría
SELECT c.nombre AS categoria, SUM(p.stock) AS total_stock
FROM farmacia.productos p 
JOIN farmacia.categoria c ON p.id_categoria = c.id_categoria
GROUP BY c.nombre
ORDER BY total_stock DESC;

-- TRIGGER
--- Actualizar el stock
CREATE OR REPLACE FUNCTION actualizar_stock()
RETURNS TRIGGER AS $$
BEGIN
UPDATE farmacia.productos
SET stock = stock - NEW.cantidad
WHERE id_producto = NEW.id_producto;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_actualizar_stock
AFTER INSERT ON farmacia.ventas
FOR EACH ROW
EXECUTE FUNCTION actualizar_stock();

--- Verificar que el stock sea el suficiente para realizar la ventas

CREATE OR REPLACE FUNCTION verificar_stock_suficiente()
RETURNS TRIGGER AS $$
BEGIN
IF(SELECT stock FROM farmacia.productos WHERE id_producto = NEW.id_producto) <= NEW.cantidad THEN
RAISE EXCEPTION ’Stock Insuficiente para el producto %’, NEW.id_producto;
END IF;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_verificar_stock
AFTER INSERT ON farmacia.ventas
FOR EACH ROW
EXECUTE FUNCTION verificar_stock_suficiente();


-- Indice
--- "Este indice mejora la busqueda por id_supermercado en la tabla ventas"
CREATE INDEX idx_id_supermercado_ventas ON farmacia.ventas(id_supermercado);


-- CTE 
--- Ventas por porducto por supermercado
WITH ventas_por_producto AS (
    SELECT p.nombre AS producto, v.id_supermercado, SUM(v.total) AS total_ventas
    FROM farmacia.ventas v
    JOIN farmacia.productos p ON v.id_producto = p.id_producto
    GROUP BY p.nombre, v.id_supermercado
)

SELECT producto, id_supermercado, total_ventas
FROM ventas_por_producto
ORDER BY total_ventas DESC;


--- Empleados con ventas mayor a 1000
WITH ventas_empleados AS (
    SELECT e.nombre AS empleado, SUM(v.total) AS total_ventas
    FROM farmacia.ventas v
    JOIN farmacia.empleados e ON v.id_empleado = e.id_empleado
    GROUP BY e.nombre
)

SELECT empleado, total_ventas
FROM ventas_empleados
WHERE total_ventas > 1000;


