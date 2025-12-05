
-- ---------------------------------------------------------------------
-- 1) CREACIÓN DE BASE DE DATOS
-- ---------------------------------------------------------------------
DROP DATABASE IF EXISTS ProyectoBiblioteca;
CREATE DATABASE ProyectoBiblioteca;
USE ProyectoBiblioteca;

-- ---------------------------------------------------------------------
-- 2) TABLAS
-- ---------------------------------------------------------------------

-- Tabla: usuarios
CREATE TABLE usuarios (
    id_usuario INT AUTO_INCREMENT PRIMARY KEY,
    dni        VARCHAR(20)  NOT NULL UNIQUE,
    nombre     VARCHAR(100) NOT NULL,
    apellido   VARCHAR(100) NOT NULL,
    email      VARCHAR(120) NOT NULL UNIQUE,
    telefono   VARCHAR(50),
    fecha_alta DATE         NOT NULL,
    estado     ENUM('activo', 'inactivo') NOT NULL DEFAULT 'activo'
);

-- Tabla: libros
CREATE TABLE libros (
    id_libro   INT AUTO_INCREMENT PRIMARY KEY,
    titulo     VARCHAR(255) NOT NULL,
    autor      VARCHAR(255) NOT NULL,
    año        INT,
    genero     VARCHAR(100),
    disponible BOOLEAN NOT NULL DEFAULT 1
);

-- Tabla: cuotas (definición de montos por mes/año)
CREATE TABLE cuotas (
    id_cuota INT AUTO_INCREMENT PRIMARY KEY,
    mes      INT NOT NULL,
    año      INT NOT NULL,
    monto    DECIMAL(10,2) NOT NULL,

    CONSTRAINT uq_cuotas_mes_anio UNIQUE (mes, año),
    CONSTRAINT chk_mes_valido CHECK (mes BETWEEN 1 AND 12)
);

-- Tabla: pagos de cuotas
CREATE TABLE pagos (
    id_pago    INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario INT NOT NULL,
    mes        INT NOT NULL,
    año        INT NOT NULL,
    fecha_pago DATE NOT NULL,

    CONSTRAINT fk_pagos_usuario
        FOREIGN KEY (id_usuario)
        REFERENCES usuarios(id_usuario)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT uq_pago_unico
        UNIQUE (id_usuario, mes, año),

    CONSTRAINT chk_mes_pago
        CHECK (mes BETWEEN 1 AND 12)
);

-- Tabla: préstamos
CREATE TABLE prestamos (
    id_prestamo           INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario            INT NOT NULL,
    id_libro              INT NOT NULL,
    fecha_prestamo        DATE NOT NULL,
    fecha_devolucion      DATE NOT NULL,
    fecha_devolucion_real DATE,
    estado ENUM('en_curso', 'devuelto', 'atrasado') 
           NOT NULL DEFAULT 'en_curso',

    CONSTRAINT fk_prestamos_usuario
        FOREIGN KEY (id_usuario)
        REFERENCES usuarios(id_usuario)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_prestamos_libro
        FOREIGN KEY (id_libro)
        REFERENCES libros(id_libro)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);

-- ---------------------------------------------------------------------
-- 3) INSERTS 
-- ---------------------------------------------------------------------

-- Usuarios
INSERT INTO usuarios (dni, nombre, apellido, email, telefono, fecha_alta, estado)
VALUES
('40123123', 'Juan', 'Pérez', 'juan.perez@example.com', '1122334455', '2025-02-10', 'activo'),
('40234567', 'María', 'Gómez', 'maria.gomez@example.com', '1133445566', '2025-03-01', 'activo'),
('40345678', 'Carlos', 'López', 'carlos.lopez@example.com', '1144556677', '2025-03-20', 'activo'),
('40456789', 'Ana', 'Martínez', 'ana.martinez@example.com', '1155667788', '2025-04-05', 'activo'),
('40567890', 'Lucía', 'Ramos', 'lucia.ramos@example.com', '1166778899', '2025-04-28', 'activo'),
('40678901', 'Pedro', 'Sosa', 'pedro.sosa@example.com', '1177889900', '2025-05-12', 'activo'),
('40789012', 'Sofía', 'Fernández', 'sofia.fernandez@example.com', '1188990011', '2025-06-03', 'activo'),
('40890123', 'Diego', 'Silva', 'diego.silva@example.com', '1199001122', '2025-06-25', 'activo'),
('40901234', 'Carla', 'Mendoza', 'carla.mendoza@example.com', '1100112233', '2025-07-14', 'activo'),
('41012345', 'Federico', 'Ibáñez', 'federico.ibanez@example.com', '1110223344', '2025-08-02', 'activo');

-- Libros
INSERT INTO libros (titulo, autor, año, genero, disponible)
VALUES
('Cien años de soledad', 'Gabriel García Márquez', 1967, 'Novela', 1),
('El principito', 'Antoine de Saint-Exupéry', 1943, 'Fábula', 1),
('1984', 'George Orwell', 1949, 'Distopía', 1),
('Don Quijote de la Mancha', 'Miguel de Cervantes', 1605, 'Novela', 1),
('Harry Potter y la piedra filosofal', 'J.K. Rowling', 1997, 'Fantasía', 1),
('El señor de los anillos', 'J.R.R. Tolkien', 1954, 'Fantasía', 1),
('Farenheit 451', 'Ray Bradbury', 1953, 'Distopía', 1),
('Crimen y castigo', 'Fiódor Dostoyevski', 1866, 'Novela', 1),
('Orgullo y prejuicio', 'Jane Austen', 1813, 'Romance', 1),
('La sombra del viento', 'Carlos Ruiz Zafón', 2001, 'Misterio', 1);

-- Cuotas
INSERT INTO cuotas (mes, año, monto) VALUES
(1,  2025, 2000.00),
(2,  2025, 2000.00),
(3,  2025, 2200.00),
(4,  2025, 2200.00),
(5,  2025, 2400.00),
(6,  2025, 2400.00),
(7,  2025, 2600.00),
(8,  2025, 2600.00),
(9,  2025, 2600.00),
(10, 2025, 2800.00),
(11, 2025, 2800.00),
(12, 2025, 3000.00);

-- ---------------------------------------------------------------------
-- 4) ÍNDICES
-- ---------------------------------------------------------------------

CREATE INDEX idx_prestamos_usuario ON prestamos(id_usuario);
CREATE INDEX idx_prestamos_libro   ON prestamos(id_libro);
CREATE INDEX idx_pagos_usuario_anio_mes ON pagos(id_usuario, año, mes);
CREATE INDEX idx_libros_genero ON libros(genero);

-- ---------------------------------------------------------------------
-- 5) FUNCIÓN DE MULTA (3% DE LA CUOTA MENSUAL * DÍAS DE ATRASO)
-- ---------------------------------------------------------------------

DELIMITER $$

CREATE FUNCTION fn_CalcularMulta(p_id_prestamo INT)
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    DECLARE v_fecha_estimada DATE;
    DECLARE v_fecha_real DATE;
    DECLARE v_mes INT;
    DECLARE v_año INT;
    DECLARE v_cuota DECIMAL(10,2);
    DECLARE v_dias INT;
    DECLARE v_multa DECIMAL(10,2);

    -- Obtener fechas
    SELECT fecha_devolucion, fecha_devolucion_real
    INTO v_fecha_estimada, v_fecha_real
    FROM prestamos
    WHERE id_prestamo = p_id_prestamo;

    -- Si no hubo devolución o no está atrasado: multa 0
    IF v_fecha_real IS NULL OR v_fecha_real <= v_fecha_estimada THEN
        RETURN 0;
    END IF;

    -- Obtener mes y año de la devolución estimada
    SET v_mes = MONTH(v_fecha_estimada);
    SET v_año = YEAR(v_fecha_estimada);

    -- Obtener monto de la cuota de ese mes/año
    SELECT monto INTO v_cuota
    FROM cuotas
    WHERE mes = v_mes AND año = v_año;

    -- Días de atraso
    SET v_dias = DATEDIFF(v_fecha_real, v_fecha_estimada);

    -- Multa: días * (3% de la cuota mensual)
    SET v_multa = v_dias * (v_cuota * 0.03);

    RETURN v_multa;
END$$

-- ---------------------------------------------------------------------
-- 6) PROCEDIMIENTOS ALMACENADOS
-- ---------------------------------------------------------------------

-- ==============
-- 6.1 Gestión de Usuarios (CRUD)
-- ==============

CREATE PROCEDURE CrearUsuario(
    IN p_dni VARCHAR(20),
    IN p_nombre VARCHAR(100),
    IN p_apellido VARCHAR(100),
    IN p_email VARCHAR(120),
    IN p_telefono VARCHAR(50),
    IN p_fecha_alta DATE,
    IN p_estado ENUM('activo','inactivo')
)
BEGIN
    DECLARE v_dni   INT;
    DECLARE v_email INT;

    SELECT COUNT(*) INTO v_dni FROM usuarios WHERE dni = p_dni;
    IF v_dni > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El DNI ingresado ya existe';
    END IF;

    SELECT COUNT(*) INTO v_email FROM usuarios WHERE email = p_email;
    IF v_email > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El email ingresado ya está registrado';
    END IF;

    INSERT INTO usuarios (dni, nombre, apellido, email, telefono, fecha_alta, estado)
    VALUES (p_dni, p_nombre, p_apellido, p_email, p_telefono, p_fecha_alta, p_estado);
END$$

CREATE PROCEDURE VerUsuario(
    IN p_id_usuario INT
)
BEGIN
    SELECT *
    FROM usuarios
    WHERE id_usuario = p_id_usuario;
END$$

CREATE PROCEDURE ActualizarUsuario(
    IN p_id_usuario INT,
    IN p_dni VARCHAR(20),
    IN p_nombre VARCHAR(100),
    IN p_apellido VARCHAR(100),
    IN p_email VARCHAR(120),
    IN p_telefono VARCHAR(50),
    IN p_estado ENUM('activo','inactivo')
)
BEGIN
    DECLARE v_dni   INT;
    DECLARE v_email INT;

    SELECT COUNT(*) INTO v_dni 
    FROM usuarios 
    WHERE dni = p_dni AND id_usuario <> p_id_usuario;

    IF v_dni > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'DNI ya registrado por otro usuario';
    END IF;

    SELECT COUNT(*) INTO v_email 
    FROM usuarios 
    WHERE email = p_email AND id_usuario <> p_id_usuario;

    IF v_email > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Email ya registrado por otro usuario';
    END IF;

    UPDATE usuarios
    SET dni      = p_dni,
        nombre   = p_nombre,
        apellido = p_apellido,
        email    = p_email,
        telefono = p_telefono,
        estado   = p_estado
    WHERE id_usuario = p_id_usuario;
END$$

CREATE PROCEDURE EliminarUsuario(
    IN p_id_usuario INT
)
BEGIN
    DECLARE v_prestamos INT;
    DECLARE v_pagos     INT;

    SELECT COUNT(*) INTO v_prestamos 
    FROM prestamos 
    WHERE id_usuario = p_id_usuario;

    IF v_prestamos > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No se puede eliminar: el usuario tiene préstamos asociados';
    END IF;

    SELECT COUNT(*) INTO v_pagos
    FROM pagos
    WHERE id_usuario = p_id_usuario;

    IF v_pagos > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No se puede eliminar: el usuario tiene pagos asociados';
    END IF;

    DELETE FROM usuarios WHERE id_usuario = p_id_usuario;
END$$

-- ==============
-- 6.2 Gestión de Libros (CRUD)
-- ==============

CREATE PROCEDURE CrearLibro(
    IN p_titulo VARCHAR(255),
    IN p_autor VARCHAR(255),
    IN p_año INT,
    IN p_genero VARCHAR(100),
    IN p_disponible BOOLEAN
)
BEGIN
    INSERT INTO libros (titulo, autor, año, genero, disponible)
    VALUES (p_titulo, p_autor, p_año, p_genero, p_disponible);
END$$

CREATE PROCEDURE VerLibro(
    IN p_id_libro INT
)
BEGIN
    SELECT *
    FROM libros
    WHERE id_libro = p_id_libro;
END$$

CREATE PROCEDURE ActualizarLibro(
    IN p_id_libro INT,
    IN p_titulo VARCHAR(255),
    IN p_autor VARCHAR(255),
    IN p_año INT,
    IN p_genero VARCHAR(100),
    IN p_disponible BOOLEAN
)
BEGIN
    UPDATE libros
    SET titulo     = p_titulo,
        autor      = p_autor,
        año        = p_año,
        genero     = p_genero,
        disponible = p_disponible
    WHERE id_libro = p_id_libro;
END$$

CREATE PROCEDURE EliminarLibro(
    IN p_id_libro INT
)
BEGIN
    DECLARE v_prestamos INT;

    SELECT COUNT(*) INTO v_prestamos
    FROM prestamos
    WHERE id_libro = p_id_libro;

    IF v_prestamos > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No se puede eliminar: el libro tiene préstamos asociados';
    END IF;

    DELETE FROM libros WHERE id_libro = p_id_libro;
END$$

-- ==============
-- 6.3 Préstamos (con TRANSACCIÓN)
-- ==============

CREATE PROCEDURE RegistrarPrestamo(
    IN p_id_usuario INT,
    IN p_id_libro INT,
    IN p_fecha_devolucion DATE
)
BEGIN
    DECLARE v_existeUsuario INT;
    DECLARE v_existeLibro   INT;
    DECLARE v_disp          INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Error al registrar el préstamo. Operación revertida.';
    END;

    START TRANSACTION;

    -- Verificar usuario
    SELECT COUNT(*) INTO v_existeUsuario
    FROM usuarios
    WHERE id_usuario = p_id_usuario;

    IF v_existeUsuario = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El usuario no existe';
    END IF;

    -- Verificar libro
    SELECT COUNT(*) INTO v_existeLibro
    FROM libros
    WHERE id_libro = p_id_libro;

    IF v_existeLibro = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El libro no existe';
    END IF;

    -- Verificar disponibilidad
    SELECT disponible INTO v_disp
    FROM libros
    WHERE id_libro = p_id_libro;

    IF v_disp = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El libro NO está disponible';
    END IF;

    -- Crear el préstamo (los triggers manejarán la disponibilidad del libro)
    INSERT INTO prestamos(id_usuario, id_libro, fecha_prestamo, fecha_devolucion)
    VALUES (p_id_usuario, p_id_libro, CURDATE(), p_fecha_devolucion);

    COMMIT;
END$$

CREATE PROCEDURE RegistrarDevolucion(
    IN p_id_prestamo INT,
    IN p_fecha_real DATE
)
BEGIN
    DECLARE v_existePrestamo INT;

    SELECT COUNT(*) INTO v_existePrestamo
    FROM prestamos
    WHERE id_prestamo = p_id_prestamo;

    IF v_existePrestamo = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El préstamo no existe';
    END IF;

    UPDATE prestamos
    SET fecha_devolucion_real = p_fecha_real
    WHERE id_prestamo = p_id_prestamo;

    -- El trigger AFTER UPDATE se encarga de marcar libro disponible
END$$

-- ==============
-- 6.4 Pagos / Cuotas (con TRANSACCIÓN en RegistrarPago)
-- ==============

CREATE PROCEDURE RegistrarPago(
    IN p_id_usuario INT,
    IN p_mes INT,
    IN p_año INT
)
BEGIN
    DECLARE v_existeUsuario INT;
    DECLARE v_existeCuota   INT;
    DECLARE v_pagoPrevio    INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Error al registrar el pago. Operación revertida.';
    END;

    START TRANSACTION;

    -- Verificar que el usuario exista
    SELECT COUNT(*) INTO v_existeUsuario
    FROM usuarios
    WHERE id_usuario = p_id_usuario;

    IF v_existeUsuario = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El usuario no existe';
    END IF;

    -- Verificar cuota
    SELECT COUNT(*) INTO v_existeCuota
    FROM cuotas
    WHERE mes = p_mes AND año = p_año;

    IF v_existeCuota = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La cuota indicada no existe';
    END IF;

    -- Verificar pago previo
    SELECT COUNT(*) INTO v_pagoPrevio
    FROM pagos
    WHERE id_usuario = p_id_usuario
      AND mes        = p_mes
      AND año        = p_año;

    IF v_pagoPrevio > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El pago ya fue registrado anteriormente';
    END IF;

    -- Registrar pago
    INSERT INTO pagos(id_usuario, mes, año, fecha_pago)
    VALUES (p_id_usuario, p_mes, p_año, CURDATE());

    COMMIT;
END$$

CREATE PROCEDURE ActualizarCuota(
    IN p_mes INT,
    IN p_año INT,
    IN p_nuevo_monto DECIMAL(10,2)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Error al actualizar la cuota. Cambios revertidos.';
    END;

    START TRANSACTION;

    UPDATE cuotas
    SET monto = p_nuevo_monto
    WHERE mes = p_mes AND año = p_año;

    IF ROW_COUNT() = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No existe una cuota para ese mes y año';
    END IF;

    COMMIT;
END$$

-- ==============
-- 6.5 Búsqueda y filtrado 
-- ==============

-- Buscar libros por título, autor o género 
CREATE PROCEDURE BuscarLibros(
    IN p_texto VARCHAR(255)
)
BEGIN
    SELECT *
    FROM libros
    WHERE titulo LIKE CONCAT('%', p_texto, '%')
       OR autor  LIKE CONCAT('%', p_texto, '%')
       OR genero LIKE CONCAT('%', p_texto, '%');
END$$

-- Buscar usuarios por nombre, apellido, DNI, email o ID
CREATE PROCEDURE BuscarUsuarios(
    IN p_texto VARCHAR(255)
)
BEGIN
    SELECT *
    FROM usuarios
    WHERE nombre   LIKE CONCAT('%', p_texto, '%')
       OR apellido LIKE CONCAT('%', p_texto, '%')
       OR dni      LIKE CONCAT('%', p_texto, '%')
       OR email    LIKE CONCAT('%', p_texto, '%')
       OR id_usuario = CAST(p_texto AS UNSIGNED);
END$$

-- ==============
-- 6.6 Reporte de morosos 
-- ==============

-- Cursor: listado de morosos para un mes/año 
CREATE PROCEDURE GenerarListadoMorosos(
    IN p_mes INT,
    IN p_año INT
)
BEGIN
    DECLARE v_id_usuario INT;
    DECLARE v_nombre     VARCHAR(100);
    DECLARE v_apellido   VARCHAR(100);
    DECLARE fin          INT DEFAULT 0;

    DECLARE cur_morosos CURSOR FOR
        SELECT u.id_usuario, u.nombre, u.apellido
        FROM usuarios u
        WHERE NOT EXISTS (
            SELECT 1
            FROM pagos pa
            WHERE pa.id_usuario = u.id_usuario
              AND pa.mes = p_mes
              AND pa.año = p_año
        );

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET fin = 1;

    CREATE TEMPORARY TABLE IF NOT EXISTS tmp_morosos (
        id_usuario INT,
        nombre     VARCHAR(100),
        apellido   VARCHAR(100),
        mes        INT,
        año        INT
    );

    TRUNCATE TABLE tmp_morosos;

    OPEN cur_morosos;

    read_loop: LOOP
        FETCH cur_morosos INTO v_id_usuario, v_nombre, v_apellido;
        IF fin = 1 THEN
            LEAVE read_loop;
        END IF;

        INSERT INTO tmp_morosos (id_usuario, nombre, apellido, mes, año)
        VALUES (v_id_usuario, v_nombre, v_apellido, p_mes, p_año);
    END LOOP;

    CLOSE cur_morosos;

    SELECT * FROM tmp_morosos;
END$$

-- Procedimiento: promedio de meses adeudados por los socios
CREATE PROCEDURE CalcularPromedioMesesAdeudados(
    OUT p_promedio DECIMAL(10,2)
)
BEGIN
    /*
      Para cada usuario, contamos cuántas cuotas (mes/año) definidas
      en la tabla cuotas NO tienen pago registrado en pagos.
      Luego, sacamos el promedio de meses adeudados entre todos.
    */

    SELECT AVG(t.meses_adeudados) INTO p_promedio
    FROM (
        SELECT u.id_usuario,
               COUNT(*) AS meses_adeudados
        FROM usuarios u
        JOIN cuotas c
          ON 1 = 1
        LEFT JOIN pagos pa
          ON pa.id_usuario = u.id_usuario
         AND pa.mes        = c.mes
         AND pa.año        = c.año
        WHERE pa.id_pago IS NULL
        GROUP BY u.id_usuario
    ) AS t;
END$$

-- ---------------------------------------------------------------------
-- 7) TRIGGERS
-- ---------------------------------------------------------------------

-- Verificar disponibilidad antes de insertar préstamo
CREATE TRIGGER trg_verificar_disponibilidad
BEFORE INSERT ON prestamos
FOR EACH ROW
BEGIN
    DECLARE v_disp INT;

    SELECT disponible INTO v_disp
    FROM libros
    WHERE id_libro = NEW.id_libro;

    IF v_disp = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El libro no está disponible';
    END IF;
END$$

-- Marcar libro NO disponible al registrar un préstamo
CREATE TRIGGER trg_marcar_no_disponible
AFTER INSERT ON prestamos
FOR EACH ROW
BEGIN
    UPDATE libros
    SET disponible = 0
    WHERE id_libro = NEW.id_libro;
END$$

-- Marcar libro disponible al registrar devolución
CREATE TRIGGER trg_marcar_disponible
AFTER UPDATE ON prestamos
FOR EACH ROW
BEGIN
    IF NEW.fecha_devolucion_real IS NOT NULL
       AND OLD.fecha_devolucion_real IS NULL THEN
        UPDATE libros
        SET disponible = 1
        WHERE id_libro = NEW.id_libro;
    END IF;
END$$

-- Marcar préstamo como atrasado automáticamente
CREATE TRIGGER trg_marcar_atrasado
BEFORE UPDATE ON prestamos
FOR EACH ROW
BEGIN
    -- Todavía no devuelto y vencido
    IF NEW.fecha_devolucion_real IS NULL 
       AND CURDATE() > NEW.fecha_devolucion THEN
        SET NEW.estado = 'atrasado';
    END IF;

    -- Devuelto fuera de término
    IF NEW.fecha_devolucion_real IS NOT NULL
       AND NEW.fecha_devolucion_real > NEW.fecha_devolucion THEN
        SET NEW.estado = 'atrasado';
    END IF;
END$$

DELIMITER ;

-- ----------------------------------------------------------------------------------
-- 8) CONSULTAS AVANZADAS (para testing), comentadas para no afectar funcionamiento
-- ----------------------------------------------------------------------------------

-- Libros actualmente prestados
-- SELECT p.id_prestamo, l.titulo, u.nombre, u.apellido, p.fecha_prestamo, p.fecha_devolucion
-- FROM prestamos p
-- JOIN libros l ON p.id_libro = l.id_libro
-- JOIN usuarios u ON p.id_usuario = u.id_usuario
-- WHERE p.estado = 'en_curso';

-- Historial de préstamos por usuario
-- SELECT u.nombre, u.apellido, l.titulo, p.fecha_prestamo, p.fecha_devolucion, p.estado
-- FROM prestamos p
-- JOIN usuarios u ON p.id_usuario = u.id_usuario
-- JOIN libros l ON p.id_libro = l.id_libro
-- WHERE u.id_usuario = 1
-- ORDER BY p.fecha_prestamo DESC;

-- Libros más prestados
-- SELECT l.id_libro, l.titulo, COUNT(p.id_prestamo) AS veces_prestado
-- FROM libros l
-- LEFT JOIN prestamos p ON l.id_libro = p.id_libro
-- GROUP BY l.id_libro, l.titulo
-- ORDER BY veces_prestado DESC;

-- Préstamos con multa
-- SELECT p.id_prestamo, u.nombre, u.apellido,
--        fn_CalcularMulta(p.id_prestamo) AS multa
-- FROM prestamos p
-- JOIN usuarios u ON p.id_usuario = u.id_usuario
-- WHERE fn_CalcularMulta(p.id_prestamo) > 0;
