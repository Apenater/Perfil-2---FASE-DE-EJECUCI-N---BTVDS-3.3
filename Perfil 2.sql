DROP DATABASE IF EXISTS gadgets_base;
CREATE DATABASE gadgets_base;
USE gadgets_base;

-- Creación de un nuevo usuario con permisos específicos
-- CREATE USER 'gadgets_user'@'localhost' IDENTIFIED BY 'password';
-- GRANT SELECT, INSERT, UPDATE, DELETE, EXECUTE, CREATE ROUTINE ON gadgets_base.* TO 'gadgets_user'@'localhost';
-- FLUSH PRIVILEGES;

-- Tabla de categorías
CREATE TABLE tb_categorias (
  id_categoria INT AUTO_INCREMENT PRIMARY KEY,
  nombre_c VARCHAR(100) NOT NULL,
  descripcion VARCHAR(200),
  foto VARCHAR(200)
);

-- Tabla de marcas
CREATE TABLE tb_marcas (
  id_marca INT AUTO_INCREMENT PRIMARY KEY,
  nombre_marca VARCHAR(50),
  foto_marca VARCHAR(200)
);

-- Tabla de fotos de productos
CREATE TABLE tb_foto_productos (
  id_foto INT AUTO_INCREMENT PRIMARY KEY,
  foto VARCHAR(200) NOT NULL
);

-- Tabla de administradores
CREATE TABLE tb_administrador (
  id_admin INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(200) NOT NULL,
  apellido VARCHAR(200) NOT NULL,
  correo VARCHAR(200) NOT NULL,
  telefono INT NOT NULL,
  id_tipo_usuario INT,
  contrasenia_admin VARCHAR(40) NOT NULL
);

-- Tabla de productos
CREATE TABLE tb_productos (
  id_producto INT AUTO_INCREMENT PRIMARY KEY,
  id_categoria INT NOT NULL,
  nombre_producto VARCHAR(50) NOT NULL,
  precio FLOAT NOT NULL,
  modelo VARCHAR(50),
  c_stock INT NOT NULL,
  descripcion VARCHAR(100),
  especificaciones VARCHAR(100),
  id_marca INT,
  id_foto INT,
  id_admin INT,
  FOREIGN KEY (id_categoria) REFERENCES tb_categorias(id_categoria),
  FOREIGN KEY (id_marca) REFERENCES tb_marcas(id_marca),
  FOREIGN KEY (id_foto) REFERENCES tb_foto_productos(id_foto),
  FOREIGN KEY (id_admin) REFERENCES tb_administrador(id_admin)
);

CREATE TABLE tb_clientes (
  id_usuario INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(200) NOT NULL,
  apellido VARCHAR(200) NOT NULL,
  correo VARCHAR(200) NOT NULL,
  telefono INT NOT NULL,
  contrasenia_usuario VARCHAR(40) NOT NULL
);

-- Tabla de comentarios
CREATE TABLE tb_comentarios (
  id_comentario INT AUTO_INCREMENT PRIMARY KEY,
  comentario VARCHAR(225) NOT NULL,
  fecha_publicacion DATE NOT NULL,
  id_usuario INT,
  id_producto INT,
  CONSTRAINT fk_comentarios_clientes FOREIGN KEY (id_usuario) REFERENCES tb_clientes(id_usuario),
  CONSTRAINT fk_comentarios_productos FOREIGN KEY (id_producto) REFERENCES tb_productos(id_producto)
);

-- Tabla de ofertas
CREATE TABLE tb_ofertas (
  id_oferta INT AUTO_INCREMENT PRIMARY KEY,
  titulo VARCHAR(50),
  descripcion VARCHAR(225) NOT NULL,
  descuento FLOAT(3,2) NOT NULL,
  foto VARCHAR(200),
  id_producto INT,
  CONSTRAINT fk_ofertas_productos FOREIGN KEY (id_producto) REFERENCES tb_productos(id_producto)
);

-- Tabla de pedidos
CREATE TABLE tb_pedido (
  id_pedido INT AUTO_INCREMENT PRIMARY KEY,
  fecha DATE NOT NULL,
  total FLOAT NOT NULL,
  id_usuario INT,
  CONSTRAINT fk_pedido_clientes FOREIGN KEY (id_usuario) REFERENCES tb_clientes(id_usuario)
);

-- Tabla de detalles de pedido
CREATE TABLE tb_detalle_pedido (
  id_detalle INT AUTO_INCREMENT PRIMARY KEY,
  precio FLOAT NOT NULL,
  sub_total FLOAT NOT NULL,
  cantidad INT NOT NULL,
  id_pedido INT,
  id_producto INT,
  CONSTRAINT fk_detalle_pedido_pedido FOREIGN KEY (id_pedido) REFERENCES tb_pedido(id_pedido),
  CONSTRAINT fk_detalle_pedido_productos FOREIGN KEY (id_producto) REFERENCES tb_productos(id_producto)
);

ALTER TABLE tb_clientes ADD cantidad_pedidos INT DEFAULT 0;


-- Trigger para actualizar el stock después de un pedido
DELIMITER //
CREATE TRIGGER after_pedido_insert
AFTER INSERT ON tb_detalle_pedido FOR EACH ROW
BEGIN
  UPDATE tb_productos SET c_stock = c_stock - NEW.cantidad WHERE id_producto = NEW.id_producto;
END;
//
DELIMITER ;

-- Función para calcular el precio total de un pedido
DELIMITER //
CREATE FUNCTION calcular_total_pedido(pedido_id INT) RETURNS FLOAT
BEGIN
  DECLARE total FLOAT;
  SELECT SUM(precio * cantidad) INTO total FROM tb_detalle_pedido WHERE id_pedido = pedido_id;
  RETURN total;
END;
//
DELIMITER ;

-- Procedimiento para insertar un nuevo pedido y sus detalles
DELIMITER //
CREATE PROCEDURE agregar_pedido(
    IN cliente_id INT, 
    IN producto_id INT, 
    IN producto_cantidad INT
)
BEGIN
  DECLARE nuevo_pedido_id INT;
  
  -- Insertar el pedido
  INSERT INTO tb_pedido(fecha, total, id_usuario) VALUES (CURDATE(), 0, cliente_id);
  SET nuevo_pedido_id = LAST_INSERT_ID();
  
  -- Insertar detalles del pedido
  INSERT INTO tb_detalle_pedido(precio, sub_total, cantidad, id_pedido, id_producto) 
  VALUES (
    (SELECT precio FROM tb_productos WHERE id_producto = producto_id),
    (SELECT precio FROM tb_productos WHERE id_producto = producto_id) * producto_cantidad,
    producto_cantidad,
    nuevo_pedido_id,
    producto_id
  );
  
  -- Actualizar total del pedido
  UPDATE tb_pedido SET total = calcular_total_pedido(nuevo_pedido_id) WHERE id_pedido = nuevo_pedido_id;
END;
//
DELIMITER ;

DELIMITER //
CREATE TRIGGER after_new_pedido
AFTER INSERT ON tb_pedido FOR EACH ROW
BEGIN
  UPDATE tb_clientes SET cantidad_pedidos = cantidad_pedidos + 1 WHERE id_usuario = NEW.id_Usuario;
END;
//
DELIMITER ;

DELIMITER //
CREATE TRIGGER after_new_detalle_pedido
AFTER INSERT ON tb_detalle_pedido FOR EACH ROW
BEGIN
  UPDATE tb_productos SET c_stock = c_stock - NEW.cantidad WHERE id_producto = NEW.id_Producto;
END;
//
DELIMITER ;

DELIMITER //
CREATE FUNCTION get_stock_producto(producto_id INT) RETURNS INT
BEGIN
  DECLARE stock_actual INT;
  SELECT c_stock INTO stock_actual FROM tb_productos WHERE id_producto = producto_id;
  RETURN stock_actual;
END;
//
DELIMITER ;

DELIMITER //
CREATE FUNCTION total_gastado_cliente(cliente_id INT) RETURNS FLOAT
BEGIN
  DECLARE total_gastado FLOAT;
  SELECT SUM(total) INTO total_gastado FROM tb_pedido WHERE id_Usuario = cliente_id;
  RETURN IFNULL(total_gastado, 0);
END;
//
DELIMITER ;



INSERT INTO tb_clientes (nombre, apellido, correo, telefono, contrasenia_usuario) VALUES 
('John', 'Doe', 'john.doe@email.com', 1234567890, 'password123'),
('Jane', 'Smith', 'jane.smith@email.com', 1987654321, 'password456');


INSERT INTO tb_categorias (nombre_c, descripcion, foto) VALUES 
('Electrónica', 'Dispositivos electrónicos y accesorios', 'electronica.jpg'),
('Computadoras', 'Equipos de computo y accesorios', 'computadoras.jpg')
;

INSERT INTO tb_marcas (nombre_marca, foto_marca) VALUES 
('Apple', 'apple.jpg'),
('Samsung', 'samsung.jpg')
;

INSERT INTO tb_foto_productos (foto) VALUES 
('producto1.jpg'),
('producto2.jpg')
;

INSERT INTO tb_administrador (nombre, apellido, correo, telefono, id_tipo_usuario, contrasenia_admin) VALUES 
('Juan', 'Pérez', 'juan.perez@example.com', 1234567890, 1, 'contraseña'),
('Ana', 'Lopez', 'ana.lopez@example.com', 1234567891, 2, 'contraseña')
;










