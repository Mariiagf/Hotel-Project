
-- 1. CONFIGURACIÓN Y LIMPIEZA INICIAL
-- Borrar tablas existentes (para limpieza si se ejecuta varias veces)
DROP TABLE IF EXISTS 
    hoteles.reservas,
    hoteles.resenas,
    hoteles.habitaciones,
    hoteles.empleados,
    hoteles.clientes,
    hoteles.puntos_interes,
    hoteles.personas,
    hoteles.hoteles
CASCADE;

DROP SCHEMA IF EXISTS hoteles CASCADE;


-- CREACIÓN DEL ESQUEMA RELACIONAL Y TABLAS


CREATE EXTENSION IF NOT EXISTS postgis;
-- Extensión de Citus
CREATE EXTENSION IF NOT EXISTS citus;


-- Añade los nodos Worker a la configuración del clúster. 
-- Desde el nodo Coordinador
SELECT * from citus_add_node('hoteles-worker1', 5432);
SELECT * from citus_add_node('hoteles-worker2', 5432);

-- Crea el esquema  'hoteles' donde se organizarán las tablas.
CREATE SCHEMA hoteles ;

-- 2. DEFINICIÓN DEL ESQUEMA RELACIONAL

-- Definición de Tablas


CREATE TABLE hoteles.hoteles (
	id int4 NOT NULL,
	localizacion public.geometry(geometry, 25829) NULL,
	nombre varchar(50) NULL,
	fecha_inauguracion date NULL,
	CONSTRAINT hotel PRIMARY KEY (id)
);

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

CREATE TABLE hoteles.puntos_interes (
	id varchar NULL,
	geom public.geometry(point, 25829) NULL,
	amenity varchar NULL,
	"name" varchar NULL,
	opening_hours varchar NULL,
	cuisine varchar NULL,
	phone varchar NULL
);

CREATE TABLE hoteles.clientes (
	dni_cliente varchar(50) NOT NULL,
	id_cliente int4 NULL,
	CONSTRAINT cliente PRIMARY KEY (dni_cliente),
	CONSTRAINT clientes_personas_fk FOREIGN KEY (dni_cliente) REFERENCES hoteles.personas(dni) ON DELETE CASCADE ON UPDATE RESTRICT
);

-- La clave foránea de dni_director a dni_empleado no la usamos porque citus no la permite

CREATE TABLE hoteles.empleados (
	dni_empleado varchar(50) NOT NULL,
	hotel int4 NULL,
	id_empleado int4 NULL,
	cargo varchar(50) NULL,
	sueldo float4 NULL,
	fecha_incorporacion date NULL,
	dni_director varchar(50) NULL,
	CONSTRAINT empleado PRIMARY KEY (dni_empleado, hotel),
	CONSTRAINT empleados_hoteles_fk FOREIGN KEY (hotel) REFERENCES hoteles.hoteles(id),
	CONSTRAINT empleados_personas_fk FOREIGN KEY (dni_empleado) REFERENCES hoteles.personas(dni) ON DELETE CASCADE ON UPDATE RESTRICT
);

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


-- 3. DISTRIBUCIÓN DE TABLAS (Citus)


-- Tablas de Referencia (copias completas en cada worker)
SELECT create_reference_table('hoteles.personas');
SELECT create_reference_table('hoteles.clientes');
SELECT create_reference_table('hoteles.puntos_interes'); 

-- Tablas Distribuidas (particionadas por hotel)
SELECT create_distributed_table('hoteles.hoteles', 'id');
SELECT create_distributed_table('hoteles.habitaciones', 'hotel', colocate_with => 'hoteles.hoteles');
SELECT create_distributed_table('hoteles.empleados', 'hotel', colocate_with => 'hoteles.hoteles');
SELECT create_distributed_table('hoteles.reservas', 'hotel', colocate_with => 'hoteles.hoteles');
SELECT create_distributed_table('hoteles.resenas', 'hotel', colocate_with => 'hoteles.hoteles');

