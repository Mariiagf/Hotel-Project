-- 1. LIMPIEZA TOTAL para evitar errores 
DROP SCHEMA IF EXISTS hoteles CASCADE;

-- 2. ACTIVAR POSTGIS 
CREATE EXTENSION IF NOT EXISTS postgis SCHEMA public;

-- 3. CREAR EL ESQUEMA
CREATE SCHEMA hoteles AUTHORIZATION alumnobd;

-- Drop table

-- DROP TABLE hoteles.hoteles;

CREATE TABLE hoteles.hoteles (
	id int4 NOT NULL,
	localizacion public.geometry(geometry, 25829) NULL,
	nombre varchar(50) NULL,
	fecha_inauguracion date NULL,
	CONSTRAINT hotel PRIMARY KEY (id)
);


-- hoteles.personas definition

-- Drop table

-- DROP TABLE hoteles.personas;

CREATE TABLE hoteles.personas (
	nombre varchar(50) NULL,
	dni varchar(50) NOT NULL,
	provincia varchar(50) NULL,
	localidad varchar(50) NULL,
	calle varchar(50) NULL,
	numero int4 NULL,
	codigo_postal int4 NULL,
	CONSTRAINT persona PRIMARY KEY (dni)
);


-- hoteles.puntos_interes definition

-- Drop table

-- DROP TABLE hoteles.puntos_interes;

CREATE TABLE hoteles.puntos_interes (
	id varchar NULL,
	geom public.geometry(point, 25829) NULL,
	amenity varchar NULL,
	"name" varchar NULL,
	opening_hours varchar NULL,
	cuisine varchar NULL,
	phone varchar NULL
);


-- hoteles.clientes definition

-- Drop table

-- DROP TABLE hoteles.clientes;

CREATE TABLE hoteles.clientes (
	dni_cliente varchar(50) NOT NULL,
	id_cliente int4 NULL,
	CONSTRAINT cliente PRIMARY KEY (dni_cliente),
	CONSTRAINT clientes_personas_fk FOREIGN KEY (dni_cliente) REFERENCES hoteles.personas(dni) ON DELETE CASCADE ON UPDATE RESTRICT
);


-- hoteles.empleados definition

-- Drop table

-- DROP TABLE hoteles.empleados;

CREATE TABLE hoteles.empleados (
	dni_empleado varchar(50) NOT NULL,
	hotel int4 NULL,
	id_empleado int4 NULL,
	cargo varchar(50) NULL,
	sueldo float4 NULL,
	fecha_incorporacion date NULL,
	dni_director varchar(50) NULL,
	CONSTRAINT empleado PRIMARY KEY (dni_empleado),
	CONSTRAINT empleados_empleados_fk FOREIGN KEY (dni_director) REFERENCES hoteles.empleados(dni_empleado) ON DELETE CASCADE ON UPDATE RESTRICT,
	CONSTRAINT empleados_hoteles_fk FOREIGN KEY (hotel) REFERENCES hoteles.hoteles(id),
	CONSTRAINT empleados_personas_fk FOREIGN KEY (dni_empleado) REFERENCES hoteles.personas(dni) ON DELETE CASCADE ON UPDATE RESTRICT
);


-- hoteles.habitaciones definition

-- Drop table

-- DROP TABLE hoteles.habitaciones;

CREATE TABLE hoteles.habitaciones (
	hotel int4 NOT NULL,
	numero int4 NOT NULL,
	piso int4 NULL,
	tipo varchar(50) NULL,
	capacidad int4 NULL,
	precio_noche int4 NULL,
	CONSTRAINT habitacion PRIMARY KEY (hotel, numero),
	CONSTRAINT habitaciones_hoteles_fk FOREIGN KEY (hotel) REFERENCES hoteles.hoteles(id) ON DELETE CASCADE ON UPDATE RESTRICT
);


-- hoteles.reservas definition

-- Drop table

-- DROP TABLE hoteles.reservas;

CREATE TABLE hoteles.reservas (
	num_reserva int4 NOT NULL,
	habitacion int4 NOT NULL,
	hotel int4 NOT NULL,
	fecha_entrada date NULL,
	duracion int4 NULL,
	cliente varchar(50) NULL,
	CONSTRAINT reserva PRIMARY KEY (num_reserva, habitacion, hotel),
	CONSTRAINT reservas_clientes_fk FOREIGN KEY (cliente) REFERENCES hoteles.clientes(dni_cliente) ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT reservas_habitaciones_fk FOREIGN KEY (hotel,habitacion) REFERENCES hoteles.habitaciones(hotel,numero) ON DELETE CASCADE ON UPDATE RESTRICT
);


-- hoteles.resenas definition

-- Drop table

-- DROP TABLE hoteles.resenas;

CREATE TABLE hoteles.resenas (
	hotel int4 NOT NULL,
	cliente varchar(50) NOT NULL,
	id_reseña int4 NOT NULL,
	descripcion varchar(4096) NULL,
	valoracion int4 NULL,
	CONSTRAINT reseña PRIMARY KEY (cliente, hotel, "id_reseña"),
	CONSTRAINT reseñas_clientes_fk FOREIGN KEY (cliente) REFERENCES hoteles.clientes(dni_cliente) ON DELETE CASCADE ON UPDATE RESTRICT,
	CONSTRAINT reseñas_hoteles FOREIGN KEY (hotel) REFERENCES hoteles.hoteles(id) ON DELETE CASCADE ON UPDATE RESTRICT
);