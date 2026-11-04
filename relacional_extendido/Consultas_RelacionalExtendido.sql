--Consulta 1:
select 
    ((r.cliente).persona).nombre,
    ((r.cliente).persona).dni,
    (r.habitacion).numero as num_habitacion,
    r.duracion as dias_alojamiento
from 
    hotel_agregado h,
    unnest(h.reservas) as r
where 
    h.id_hotel = 1
    and (r.habitacion).piso = 5
    and extract(year from r.fecha_entrada) = 2025;

--Consulta 2:
with ingresos_anuales as (select
        extract(year from r.fecha_entrada) as ano,
        sum(r.duracion * (r.habitacion).precio_noche) as ingresos
    from
        hotel_agregado h,
        unnest(h.reservas) as r
    where
        h.id_hotel = 2
    group by
        ano),
gastos_personal as (select
        ia.ano,
        sum(e.sueldo * 12) as total_gastado
    from
        hotel_agregado h,
        unnest(h.empleados) as e,
        ingresos_anuales ia
    where
        h.id_hotel = 2
        and extract(year from e.fecha_incorporacion) <= ia.ano
    group by
        ia.ano)
select
    i.ano,
    i.ingresos,
    g.total_gastado
from
    ingresos_anuales i
left join
    gastos_personal g on (i.ano = g.ano)
order by
    i.ano desc;

--Consulta 3:
select
    (r.cliente).persona.nombre as nombre_persona, r.valoracion, r.id_resena, r.descripcion
from hoteles.hotel_agregado h,
    UNNEST(h.resenas) as r
where to_tsvector('english', r.descripcion) @@ to_tsquery('english', 'baby')
order by r.valoracion desc;

--Consulta 4:
select distinct
    h.nombre as hotel,
    (c).persona.nombre as cliente,
    (c).dni_cliente
from hoteles.hotel_agregado h,
    UNNEST(h.clientes) as c
where
    (select COUNT(*)
        from UNNEST(h.reservas) as r
        where (r.cliente).dni_cliente = (c).dni_cliente) > 5
    or
    (select COUNT(*)
        from UNNEST(h.resenas) AS re
        where (re.cliente).dni_cliente = (c).dni_cliente) > 5
order by h.nombre, cliente;

--Consulta 5:
select *
from (select
        h.id_hotel,
        h.nombre as nombre_hotel,
        hab.numero as num_habitacion,
        hab.tipo,
        hab.capacidad,
        (select AVG(r.valoracion)
         from UNNEST(h.resenas) as r) as media_valoracion,
        RANK() over (
            partition by h.id_hotel
            order by 
                (select COUNT(*) from UNNEST(h.reservas) as r
                 where (r.habitacion).numero = hab.numero
                 and r.hotel = h.id_hotel) desc,
                (select AVG(r.valoracion) from UNNEST(h.resenas) as r) desc) as ranking
    from hoteles.hotel_agregado h,
         UNNEST(h.habitaciones) as hab  -- desanidamos
) as t
where t.ranking <= 3
order by t.id_hotel, t.ranking;

--Consulta 6:
with empleados_sin_subordinados as (
    select h.id_hotel,
           e.dni_empleado,
           e.cargo as cargo_empleado,
           e.dni_director as dni_jefe
    from hoteles.hotel_agregado h,
         UNNEST(h.empleados) as e
    where e.dni_empleado not in (
        select distinct sub.dni_director
        from hoteles.hotel_agregado h2,
             UNNEST(h2.empleados) as sub
        where sub.dni_director is not null))
select
    e.dni_empleado as empleado,
    e.cargo_empleado,
    e.dni_jefe,
    jefe.cargo as cargo_jefe
from empleados_sin_subordinados e
left join lateral (
    select d.cargo
    from hoteles.hotel_agregado h,
         UNNEST(h.empleados) as d
    where d.dni_empleado = e.dni_jefe
    limit 1) as jefe on true
order by e.dni_empleado;

--Consulta 7:
select distinct
    pi.name,
    pi.opening_hours,
    ST_Distance(h.localizacion, pi.geom) as distancia_en_metros,
    pi.geom,
    h.localizacion AS geom_hotel
from
    hotel_agregado h,
    unnest(h.puntos_interes) as pi
where
    h.id_hotel = 1
    and pi.amenity = 'restaurant'
    and pi.cuisine = 'regional'
order by
    distancia_en_metros asc;

--Consulta 8:
select distinct
    h.nombre as nombre_hotel,
    pi.name as punto_interes,
    pi.amenity as tipo_servicio,
    ST_Buffer(h.localizacion, 500) as area_hotel,
    pi.geom as geometria_punto_interes
from
    hotel_agregado h,
    UNNEST(h.puntos_interes) as pi
where
    h.nombre = 'Hostal dos Reis Católicos'
    and pi.amenity in ('atm', 'pharmacy')
    and ST_DWithin(h.localizacion, pi.geom, 500);