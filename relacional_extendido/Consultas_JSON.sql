--CONSULTA 1

select
    doc.nombre AS nombre,
    doc.dni_cliente AS dni,
    habitacion ->> 'numero' AS num_habitacion,
    reserva ->> 'duracion' AS dias_alojamiento
from
    modelo_json.documentos_cliente doc, jsonb_array_elements(doc.historial_reservas) AS reserva,
    jsonb_array_elements(reserva -> 'hotel_reservado_info_completa' -> 'habitaciones') AS habitacion
where
    extract(year from TO_DATE(reserva ->> 'fecha_entrada', 'YYYY-MM-DD')) = 2025 and (reserva -> 'hotel_reservado_info_completa' ->> 'id_hotel')::int = 1
    and (habitacion ->> 'piso')::int = 5 and (reserva ->> 'num_habitacion_reservada')::int = (habitacion ->> 'numero')::int;
   
    
    
-- CONSULTA 2 (BEN)
with ingresos_anuales as (
    select extract(year from to_date(reserva ->> 'fecha_entrada', 'YYYY-MM-DD')) as ano,
        sum( (reserva ->> 'duracion')::numeric * (hab ->> 'precio_noche')::numeric ) as ingresos
    from
        modelo_json.documentos_cliente doc, jsonb_array_elements(doc.historial_reservas) as reserva, 
        jsonb_array_elements(reserva -> 'hotel_reservado_info_completa' -> 'habitaciones') as hab
    where
        (reserva -> 'hotel_reservado_info_completa' ->> 'id_hotel')::int = 2 and (reserva ->> 'num_habitacion_reservada')::int = (hab ->> 'numero')::int
    group by ano
),
gastos_personal as (
    select ia.ano, sum(e.sueldo * 12) as total_gastado 
    from
        ingresos_anuales as ia, 
        (select distinct on (emp ->> 'dni') (emp ->> 'sueldo')::numeric as sueldo, emp ->> 'fecha_incorporacion' as fecha_incorporacion
            from modelo_json.documentos_cliente doc, jsonb_array_elements(doc.historial_reservas) as reserva,
                jsonb_array_elements(reserva -> 'hotel_reservado_info_completa' -> 'plantilla') as emp
            where (reserva -> 'hotel_reservado_info_completa' ->> 'id_hotel')::int = 2) as e
    where 
        extract(year from to_date(e.fecha_incorporacion, 'YYYY-MM-DD')) <= ia.ano
    group by ia.ano)
select i.ano, i.ingresos, g.total_gastado
from ingresos_anuales i
left join gastos_personal g on i.ano = g.ano
order by i.ano desc
limit 15;



--CONSULTA 3 (CONSULTA BENEFICIADA)

select doc.nombre as nombre, (reseña ->> 'valoracion')::int as valoracion, reseña ->> 'texto' as descripcion
from modelo_json.documentos_cliente doc, jsonb_array_elements(doc.mis_reseñas) as reseña
where to_tsvector('english', reseña ->> 'texto') @@ to_tsquery('english', 'baby')
order by valoracion desc;


-- CONSULTA 4

select reserva -> 'hotel_reservado_info_completa' ->> 'nombre' as hotel, doc.nombre as cliente, doc.dni_cliente
from modelo_json.documentos_cliente doc, jsonb_array_elements(doc.historial_reservas) as reserva
group by hotel, cliente, doc.dni_cliente
having COUNT(*) > 5
union
select reseña ->> 'hotel_nombre' as hotel, doc.nombre as cliente, doc.dni_cliente
from modelo_json.documentos_cliente doc, jsonb_array_elements(doc.mis_reseñas) as reseña
group by hotel, cliente, doc.dni_cliente
having COUNT(*) > 5;


-- CONSULTA 5

-- Non se pode resolver


-- CONSULTA 6

with recursive censo_empregados as (
    select distinct on (emp ->> 'dni') emp ->> 'dni' as dni_empleado, emp ->> 'cargo' as cargo, emp ->> 'dni_director' as dni_director
    from modelo_json.documentos_cliente doc, jsonb_array_elements(doc.historial_reservas) as reserva,
        jsonb_array_elements(reserva -> 'hotel_reservado_info_completa' -> 'plantilla') as emp),
empleados_sin_subordinados as (
    select *
    from censo_empregados e
    where e.dni_empleado not in (
		select distinct dni_director
        from censo_empregados
        where dni_director is not null)),
jerarquia as (
    select e.dni_empleado as empleado, e.cargo as cargo_empleado, e.dni_director as dni_jefe, 1 as nivel
    from empleados_sin_subordinados e
    union all 
    select j.empleado, j.cargo_empleado, c.dni_director as dni_jefe, j.nivel + 1
    from jerarquia j join censo_empregados c on j.dni_jefe = c.dni_empleado
    where j.dni_jefe is not null)
select j.empleado, j.cargo_empleado, j.dni_jefe, c.cargo as cargo_jefe
from jerarquia j left join censo_empregados c on j.dni_jefe = c.dni_empleado
where j.nivel = 1 
order by j.empleado;


-- CONSULTA 7

select distinct punto_interese ->> 'nome' as name, punto_interese ->> 'horario' as opening_hours,
    (punto_interese ->> 'distancia_aprox_metros')::numeric as distancia_en_metros, ST_GeomFromGeoJSON(punto_interese -> 'localizacion_punto') as geom
from modelo_json.documentos_cliente doc, jsonb_array_elements(doc.historial_reservas) as reserva,
    jsonb_array_elements(reserva -> 'hotel_reservado_info_completa' -> 'puntos_interes_cercanos') as punto_interese
where (reserva -> 'hotel_reservado_info_completa' ->> 'id_hotel')::int = 1
    and punto_interese ->> 'tipo_servizo' = 'restaurant' and punto_interese ->> 'cociña' = 'regional'
order by distancia_en_metros asc;


--CONSULTA 8

select distinct (punto_interese ->> 'nome') as punto_interes, (punto_interese ->> 'tipo_servizo') as tipo_servicio,
    ST_Buffer(ST_GeomFromGeoJSON(reserva -> 'hotel_reservado_info_completa' -> 'localizacion_hotel'), 500) as area_hotel,
    ST_GeomFromGeoJSON(punto_interese -> 'localizacion_punto') as geometria_punto_interes
from modelo_json.documentos_cliente doc, jsonb_array_elements(doc.historial_reservas) as reserva,
    jsonb_array_elements(reserva -> 'hotel_reservado_info_completa' -> 'puntos_interes_cercanos') as punto_interese
where (reserva -> 'hotel_reservado_info_completa' ->> 'nombre') = 'Hostal dos Reis Católicos' and (punto_interese ->> 'tipo_servizo') in ('atm', 'pharmacy')
    and (punto_interese ->> 'distancia_aprox_metros')::numeric <= 500;
    
    