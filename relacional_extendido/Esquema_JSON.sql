create schema if not exists modelo_json;

create table modelo_json.documentos_cliente as
select
    c.dni_cliente,
    p.nombre,
    concat(p.calle, ' ', p.numero, ', ', p.localidad) as direccion_actual,
    
    -- Agregación de Reservas 
    (select 
        jsonb_agg(
            jsonb_build_object(
                'id_reserva', r.num_reserva,
                'fecha_entrada', r.fecha_entrada,
                'duracion', r.duracion,
                'num_habitacion_reservada', r.habitacion,
                -- Creamos unha copia do hotel por cada cliente
                'hotel_reservado_info_completa', (
                    select jsonb_build_object(
                        'id_hotel', h.id,
                        'nombre', h.nombre,
                        'localizacion_hotel', ST_AsGeoJSON(h.localizacion)::jsonb,
                        -- Engadimos a cada hotel a información de todas as súas habitacións
                        'habitaciones', (
                            select jsonb_agg(jsonb_build_object(
                                'numero', hab.numero, 
                                'piso', hab.piso, 
                                'tipo', hab.tipo,
                                'capacidad', hab.capacidad, 
                                'precio_noche', hab.precio_noche))
                            from hoteles.habitaciones hab where hab.hotel = h.id),
                        -- Engadimos agora os empregados dese hotel
                        'plantilla', (
                            select jsonb_agg(jsonb_build_object(
                                'dni', e.dni_empleado, 
                                'nombre', p_emp.nombre, 
                                'cargo', e.cargo,
                                'sueldo', e.sueldo, 
                                'fecha_incorporacion', e.fecha_incorporacion, 
                                'dni_director', e.dni_director ))
                            from hoteles.empleados e
                            join hoteles.personas p_emp on e.dni_empleado = p_emp.dni
                            where e.hotel = h.id),
                        
                        'puntos_interes_cercanos', (
                            select jsonb_agg(jsonb_build_object(
                                'nome', pid.name, 
                                'tipo_servizo', pid.amenity, 
                                'horario', pid.opening_hours, 
                                'cociña', pid.cuisine, 
                                'telefono', pid.phone, 
                                'distancia_aprox_metros', ROUND(ST_Distance(h.localizacion, pid.geom)::numeric, 2), 
                                'localizacion_punto', ST_AsGeoJSON(pid.geom)::jsonb))
                            from hoteles.puntos_interes pid
                            where ST_DWithin(h.localizacion, pid.geom, 1000)))
                    from hoteles.hoteles h
                    where r.hotel = h.id)) 
                    order by r.fecha_entrada desc)
     from hoteles.reservas r
     where c.dni_cliente = r.cliente) as historial_reservas,

    -- Agregación de Reseñas
    (select 
        jsonb_agg(
            jsonb_build_object(
                'hotel_id', rs.hotel, 
                'hotel_nombre', h.nombre,
                'valoracion', rs.valoracion,
                'texto', rs.descripcion))
     from hoteles.reseñas rs
     join hoteles.hoteles h on rs.hotel = h.id
     where c.dni_cliente = rs.cliente) as mis_reseñas

from
    hoteles.clientes c
left join
    hoteles.personas p on c.dni_cliente = p.dni;

-- Engadimos a clave primaria
alter table modelo_json.documentos_cliente add primary key (dni_cliente);