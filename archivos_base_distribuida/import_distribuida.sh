# Este script configura y carga la base de datos distribuida Citus.
# Se conecta a localhost:35432 con el usuario postgres (sin PGPASSWORD).

# Configuración de Conexión 
HOST="localhost"
PORT="35432"
USER="postgres"
DB="postgres"
SQL_FILE="hoteles_distribuida.sql"


# Ejecutar el SQL 
psql -h $HOST -p $PORT -U $USER -d $DB -a -f $SQL_FILE

echo "Cargando datos en las tablas distribuidas/referencia..."

# 1. hoteles
psql -h $HOST -p $PORT -U $USER -d $DB -c "\copy hoteles.hoteles from 'hoteles.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',')"

# 2. personas
psql -h $HOST -p $PORT -U $USER -d $DB -c "\copy hoteles.personas from 'personas.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',')"

# 3. clientes
psql -h $HOST -p $PORT -U $USER -d $DB -c "\copy hoteles.clientes from 'clientes.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',')"

# 4. empleados
psql -h $HOST -p $PORT -U $USER -d $DB -c "\copy hoteles.empleados from 'empleados.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',')"

# 5. habitaciones
psql -h $HOST -p $PORT -U $USER -d $DB -c "\copy hoteles.habitaciones from 'habitaciones.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',')"

# 6. puntos_interes
psql -h $HOST -p $PORT -U $USER -d $DB -c "\copy hoteles.puntos_interes from 'puntos_interes.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',')"

# 7. reservas
psql -h $HOST -p $PORT -U $USER -d $DB -c "\copy hoteles.reservas from 'reservas.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',')"

# 8. resenas
psql -h $HOST -p $PORT -U $USER -d $DB -c "\copy hoteles.resenas from 'resenas.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',')"

echo "Proceso de importación finalizado."