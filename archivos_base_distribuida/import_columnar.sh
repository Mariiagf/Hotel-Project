#!/bin/bash
# Este script configura el formato columnar y carga las tablas reservas y resenas.
# Se conecta a localhost:35432 con el usuario postgres (sin PGPASSWORD).

# --- Configuración de Conexión ---
HOST="localhost"
PORT="35432"
USER="postgres"
DB="postgres"
SQL_FILE="hoteles_columnar.sql"

# Ejecutar el SQL de creación de tablas columnares y redistribución
psql -h $HOST -p $PORT -U $USER -d $DB -a -f $SQL_FILE

# --- Carga de datos de las dos tablas ---

# 1. reservas (Columnar)
TABLE_NAME="hoteles.reservas"
CSV_NAME="reservas.csv"
echo "Copiando datos a la tabla columnar $TABLE_NAME desde $CSV_NAME..."
psql -h $HOST -p $PORT -U $USER -d $DB -c "\copy $TABLE_NAME from '$CSV_NAME' WITH (FORMAT csv, HEADER true, DELIMITER ',')"

# 2. resenas (Columnar)
TABLE_NAME="hoteles.resenas"
CSV_NAME="resenas.csv"
echo "Copiando datos a la tabla columnar $TABLE_NAME desde $CSV_NAME..."
psql -h $HOST -p $PORT -U $USER -d $DB -c "\copy $TABLE_NAME from '$CSV_NAME' WITH (FORMAT csv, HEADER true, DELIMITER ',')"
