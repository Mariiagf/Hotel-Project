import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.hbase.Cell;
import org.apache.hadoop.hbase.CellUtil;
import org.apache.hadoop.hbase.HBaseConfiguration;
import org.apache.hadoop.hbase.TableName;
import org.apache.hadoop.hbase.client.*;
import org.apache.hadoop.hbase.util.Bytes;

import java.io.IOException;

public class ConsultasViables {

    public static void main(String[] args) {
        Configuration config = HBaseConfiguration.create();
        config.set("hbase.zookeeper.quorum", "localhost");
        config.set("hbase.zookeeper.property.clientPort", "2181");

        try (Connection connection = ConnectionFactory.createConnection(config)) {
            Table table = connection.getTable(TableName.valueOf("hoteles"));

            System.out.println("==========================================");
            System.out.println("   CONSULTAS VIABLES EN TU CLÚSTER HBASE");
            System.out.println("==========================================\n");

            // -----------------------------------------------------------------------
            // EJEMPLO 1: LA FICHA COMPLETA (Digital Twin)
            // Caso de uso: La app del hotel carga el perfil del "Meliá Araguaney".
            // Por qué funciona: Usamos GET por ID. Es la operación más rápida de HBase.
            // -----------------------------------------------------------------------
            System.out.println(">>> 1. FICHA TÉCNICA DEL HOTEL ID 1 <<<");

            Get getHotel = new Get(Bytes.toBytes("1")); // ID 1
            Result r1 = table.get(getHotel);

            if (!r1.isEmpty()) {
                // Recuperamos nombre (Fijo)
                byte[] bNombre = r1.getValue(Bytes.toBytes("info"), Bytes.toBytes("nombre"));
                System.out.println("HOTEL: " + Bytes.toString(bNombre));

                // Recuperamos habitaciones (Dinámico)
                System.out.println("  [Inventario de Habitaciones]:");
                for (Cell cell : r1.listCells()) {
                    String familia = Bytes.toString(CellUtil.cloneFamily(cell));
                    String columna = Bytes.toString(CellUtil.cloneQualifier(cell)); // ej: 101_tipo
                    String valor = Bytes.toString(CellUtil.cloneValue(cell));

                    if (familia.equals("habitaciones") && columna.endsWith("_tipo")) {
                        // Truco visual: extraemos el número de la habitación del nombre de la columna
                        String numHab = columna.split("_")[0];
                        System.out.println("   - Hab " + numHab + ": " + valor);
                    }
                }
            } else {
                System.out.println("Hotel 1 no encontrado.");
            }
            System.out.println("\n--------------------------------------------------\n");


            // -----------------------------------------------------------------------
            // EJEMPLO 2: BUSCADOR DE OPORTUNIDADES (Filtro numérico)
            // Caso de uso: Un cliente busca habitaciones por debajo de 100€ en CUALQUIER hotel.
            // Por qué funciona: Escaneamos la familia 'habitaciones' y filtramos en Java.
            // -----------------------------------------------------------------------
            System.out.println(">>> 2. BUSCADOR: Habitaciones por debajo de 100€ <<<");

            Scan scanPrecios = new Scan();
            scanPrecios.addFamily(Bytes.toBytes("habitaciones")); // Optimización: Solo traer esta familia

            ResultScanner scanner = table.getScanner(scanPrecios);

            for (Result r : scanner) {
                String nombreHotel = "Hotel ID " + Bytes.toString(r.getRow()); // RowKey

                for (Cell cell : r.listCells()) {
                    String columna = Bytes.toString(CellUtil.cloneQualifier(cell));
                    String valor = Bytes.toString(CellUtil.cloneValue(cell));

                    // Buscamos columnas de precio (ej: 101_precio)
                    if (columna.endsWith("_precio")) {
                        try {
                            double precio = Double.parseDouble(valor);
                            if (precio < 100.0) {
                                String numHab = columna.split("_")[0];
                                System.out.println(nombreHotel + " -> Hab " + numHab + " por " + precio + "€");
                            }
                        } catch (Exception e) { /* Ignorar datos corruptos */ }
                    }
                }
            }
            scanner.close();
            System.out.println("\n--------------------------------------------------\n");


            // -----------------------------------------------------------------------
            // EJEMPLO 3: AUDITORÍA DE CALIDAD (Filtro de Reseñas)
            // Caso de uso: El gerente quiere ver URGENTEMENTE las quejas (valoración < 3).
            // Por qué funciona: Iteramos sobre las columnas dinámicas de reseñas.
            // -----------------------------------------------------------------------
            System.out.println(">>> 3. ALERTA: Reseñas negativas (Valoración < 3) <<<");

            Scan scanCalidad = new Scan();
            scanCalidad.addFamily(Bytes.toBytes("resenas"));

            ResultScanner scannerCalidad = table.getScanner(scanCalidad);

            for (Result r : scannerCalidad) {
                String idHotel = Bytes.toString(r.getRow());

                for (Cell cell : r.listCells()) {
                    String columna = Bytes.toString(CellUtil.cloneQualifier(cell));
                    String valor = Bytes.toString(CellUtil.cloneValue(cell));

                    // Buscamos columnas de valoración (ej: 1_valor)
                    if (columna.endsWith("_valor")) {
                        try {
                            int estrellas = Integer.parseInt(valor);
                            if (estrellas < 3) {
                                // Hemos encontrado una queja. Ahora buscamos el texto asociado.
                                // El ID de la reseña es el prefijo (ej: "1" de "1_valor")
                                String idResena = columna.split("_")[0];

                                // Buscamos el texto en la misma fila (Result) sin hacer otra consulta
                                byte[] valTexto = r.getValue(Bytes.toBytes("resenas"), Bytes.toBytes(idResena + "_texto"));
                                String textoQueja = (valTexto != null) ? Bytes.toString(valTexto) : "Sin texto";

                                System.out.println("Hotel " + idHotel + " (Nota: " + estrellas + "):");
                                System.out.println("   \"" + textoQueja + "\"");
                            }
                        } catch (Exception e) { }
                    }
                }
            }
            scannerCalidad.close();

            table.close();

        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}