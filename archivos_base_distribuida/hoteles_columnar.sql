-- Activar la extensión 
CREATE EXTENSION IF NOT EXISTS citus_columnar;

-- Borrar las tablas distribuidas/relacionales originales (solo reservas y resenas)
DROP TABLE IF EXISTS 
    hoteles.reservas,
    hoteles.resenas
CASCADE;

-- Crear las nuevas tablas con formato columnar 
CREATE TABLE hoteles.reservas (
    num_reserva int4 NOT NULL,
    habitacion int4 NOT NULL,
    hotel int4 NOT NULL,
    fecha_entrada date NULL,
    duracion int4 NULL,
    cliente varchar(50) NULL,
    CONSTRAINT reserva_columna PRIMARY KEY (num_reserva, habitacion, hotel)
)USING columnar;

CREATE TABLE hoteles.resenas (
    hotel int4 NOT NULL,
    cliente varchar(50) NOT NULL,
    id_reseña int4 NOT NULL,
    descripcion varchar(4096) NULL,
    valoracion int4 NULL,
    CONSTRAINT reseña_columna PRIMARY KEY (cliente, hotel, "id_reseña")
)USING columnar;

-- Volver a distribuirlas 
SELECT create_distributed_table('hoteles.reservas', 'hotel', colocate_with => 'hoteles.hoteles');
SELECT create_distributed_table('hoteles.resenas', 'hotel', colocate_with => 'hoteles.hoteles');

-- Verificar que se crearon como columnar
--SELECT * FROM citus_tables WHERE table_name IN ('reservas', 'resenas');