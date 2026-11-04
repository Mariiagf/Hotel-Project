
   --CREACIÓN DE TIPOS


   -- Tipo para direcciones
CREATE TYPE direccion AS (
    provincia varchar(50),
    localidad varchar(50),
    calle varchar(50),
    numero int4,
    codigo_postal int4
);

-- Tipo para información de personas
CREATE TYPE persona_info AS (
    nombre varchar(50),
    dni varchar(50),
    direccion direccion
);

-- Tipo para puntos de interés
CREATE TYPE punto_interes_info AS (
    id_punto varchar,
    geom public.geometry(point, 25829),
    amenity varchar,
    "name" varchar,
    opening_hours varchar,
    cuisine varchar,
    phone varchar
);

-- Tipo para habitaciones
CREATE TYPE habitacion_info AS (
    numero int4,
    piso int4,
    tipo varchar(50),
    capacidad int4,
    precio_noche int4
);

-- Tipo para empleados
CREATE TYPE empleado_info AS (
    dni_empleado varchar(50),
    id_empleado int4,
    cargo varchar(50),
    sueldo float4,
    fecha_incorporacion date,
    dni_director varchar(50),
    persona persona_info
);

-- Tipo para clientes
CREATE TYPE cliente_info AS (
    id_cliente int4,
    dni_cliente varchar(50),
    persona persona_info
);

-- Tipo para reservas
CREATE TYPE reserva_info AS (
    num_reserva int4,
    hotel int4,
    fecha_entrada date,
    duracion int4,
    cliente cliente_info,
    habitacion habitacion_info
);

-- Tipo para reseñas
CREATE TYPE resena_info AS (
    hotel int4,
    id_reseña int4,
    cliente cliente_info,
    descripcion varchar(4096),
    valoracion int4
);

-- Tabla agregada de hoteles
CREATE TABLE hotel_agregado (
    id_hotel int4 NOT NULL,
    localizacion public.geometry(geometry, 25829),
    nombre varchar(50),
    fecha_inauguracion date,
    puntos_interes punto_interes_info[],
    habitaciones habitacion_info[],
    empleados empleado_info[],
    reservas reserva_info[],
    resenas resena_info[],
    clientes cliente_info[],
    CONSTRAINT hotel_agregado_pk PRIMARY KEY (id_hotel)
);

-- INSERT DE LOS DATOS DESDE LA BASE RELACIONAL


INSERT INTO hotel_agregado (
    id_hotel,
    localizacion,
    nombre,
    fecha_inauguracion,
    puntos_interes,
    habitaciones,
    empleados,
    reservas,
    resenas,
    clientes
)
SELECT
    h.id,
    h.localizacion, 
    h.nombre,
    h.fecha_inauguracion,

    (SELECT ARRAY(
        SELECT CAST((
            pi.id,
            pi.geom,
            pi.amenity,
            pi.name,
            pi.opening_hours,
            pi.cuisine,
            pi.phone
        ) AS punto_interes_info)
        FROM hoteles.puntos_interes pi
        WHERE ST_DWithin(h.localizacion, pi.geom, 1000) 
    )) AS puntos_interes,

    -- 2. Array de Habitaciones
    (SELECT ARRAY(
        SELECT CAST((
            hab.numero,
            hab.piso,
            hab.tipo,
            hab.capacidad,
            hab.precio_noche
        ) AS habitacion_info)
        FROM hoteles.habitaciones hab
        WHERE hab.hotel = h.id
    )) AS habitaciones,

    -- 3. Array de Empleados (con su info de Persona anidada)
    (SELECT ARRAY(
        SELECT CAST((
            e.dni_empleado,
            e.id_empleado,
            e.cargo,
            e.sueldo,
            e.fecha_incorporacion,
            e.dni_director,
            CAST(( -- tipo persona_info
                p.nombre,
                p.dni,
                CAST(( -- tipo direccion
                    p.provincia, 
                    p.localidad,
                    p.calle,
                    p.numero, 
                    p.codigo_postal
                ) AS direccion)
            ) AS persona_info)
        ) AS empleado_info)
        FROM hoteles.empleados e
        JOIN hoteles.personas p ON e.dni_empleado = p.dni
        WHERE e.hotel = h.id
    )) AS empleados,

    -- 4. Array de Reservas (con info de Habitación anidada)
    (SELECT ARRAY(
        SELECT CAST((
            r.num_reserva,
            r.hotel, 
            r.fecha_entrada, 
            r.duracion,
            CAST(( --cliente_info 
                c.id_cliente,
                c.dni_cliente,
                CAST((
                    p_cli.nombre, p_cli.dni,
                    CAST((p_cli.provincia, p_cli.localidad, p_cli.calle, p_cli.numero, p_cli.codigo_postal) AS direccion)
                ) AS persona_info)
            ) AS cliente_info),
            CAST(( -- habitacion_info 
                hab.numero, hab.piso, hab.tipo, hab.capacidad, hab.precio_noche
            ) AS habitacion_info)
        ) AS reserva_info)
        FROM hoteles.reservas r
        JOIN hoteles.habitaciones hab ON r.habitacion = hab.numero AND r.hotel = hab.hotel
        JOIN hoteles.clientes c ON r.cliente = c.dni_cliente 
        JOIN hoteles.personas p_cli ON c.dni_cliente = p_cli.dni
        WHERE r.hotel = h.id
    )) AS reservas,
    
   

    -- 5. Array de Reseñas
 (SELECT ARRAY(
        SELECT CAST((
            r.hotel, 
            r.id_reseña, 
            CAST(( 
                c.id_cliente,
                c.dni_cliente,
                CAST((
                    p_cli.nombre, p_cli.dni,
                    CAST((p_cli.provincia, p_cli.localidad, p_cli.calle, p_cli.numero, p_cli.codigo_postal) AS direccion)
                ) AS persona_info)
            ) AS cliente_info),
            r.descripcion, 
            r.valoracion   
        ) AS resena_info)
        FROM hoteles.resenas r
        JOIN hoteles.clientes c ON r.cliente = c.dni_cliente
        JOIN hoteles.personas p_cli ON c.dni_cliente = p_cli.dni
        WHERE r.hotel = h.id
    )) AS resenas,

    -- 6. Array de Clientes (todos los que han reservado o reseñado)
    (SELECT ARRAY(
        SELECT CAST((
            c.id_cliente,
            c.dni_cliente,
            CAST(( -- tipo persona_info
                p.nombre,
                p.dni,
                CAST(( -- tipo direccion
                    p.provincia, p.localidad, p.calle, p.numero, p.codigo_postal
                ) AS direccion)
            ) AS persona_info)
        ) AS cliente_info)
        FROM hoteles.personas p
        JOIN hoteles.clientes c ON p.dni = c.dni_cliente
        WHERE c.dni_cliente IN (
            SELECT cliente FROM hoteles.reservas r WHERE r.hotel = h.id
            UNION 
            SELECT cliente FROM hoteles.resenas re WHERE re.hotel = h.id
        )
    )) AS clientes
    
FROM
    hoteles.hoteles h; 
    
    