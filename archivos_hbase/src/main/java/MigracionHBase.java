import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.hbase.HBaseConfiguration;
import org.apache.hadoop.hbase.TableName;
import org.apache.hadoop.hbase.client.*;
import org.apache.hadoop.hbase.util.Bytes;
import java.io.IOException;
import java.util.List;

public class MigracionHBase {

    public static void main(String[] args) {
        // 1. Conectar a PostgreSQL y traer datos
        System.out.println("Leyendo de PostgreSQL...");
        // AJUSTA LOS DATOS DE CONEXIÓN A TU POSTGRES
        DAOHotelesPgsql dao = new DAOHotelesPgsql("localhost", "25432", "alumnobd", "alumnobd", "pwalumnobd");
        List<Hotel> hoteles = dao.getHoteles();
        dao.close();

        System.out.println("Se han recuperado " + hoteles.size() + " hoteles de PostgreSQL.");

        // 2. Conectar a HBase e Insertar
        Configuration config = HBaseConfiguration.create();
        config.set("hbase.zookeeper.quorum", "localhost");
        config.set("hbase.zookeeper.property.clientPort", "2181");

        try (Connection connection = ConnectionFactory.createConnection(config);
             Admin admin = connection.getAdmin()) {

            TableName tableName = TableName.valueOf("hoteles");

            // Crear tabla si no existe
            if (!admin.tableExists(tableName)) {
                System.out.println("Creando tabla HBase...");
                TableDescriptorBuilder tdb = TableDescriptorBuilder.newBuilder(tableName);
                tdb.setColumnFamily(ColumnFamilyDescriptorBuilder.of("info"));
                tdb.setColumnFamily(ColumnFamilyDescriptorBuilder.of("habitaciones"));
                tdb.setColumnFamily(ColumnFamilyDescriptorBuilder.of("empleados"));
                tdb.setColumnFamily(ColumnFamilyDescriptorBuilder.of("resenas"));
                admin.createTable(tdb.build());
            }

            Table table = connection.getTable(tableName);

            // 3. Iterar y crear Puts
            for (Hotel h : hoteles) {
                Put put = new Put(Bytes.toBytes(String.valueOf(h.id))); // RowKey = ID Hotel

                // Info básica
                put.addColumn(Bytes.toBytes("info"), Bytes.toBytes("nombre"), Bytes.toBytes(h.nombre));
                if (h.fechaInauguracion != null) {
                    put.addColumn(Bytes.toBytes("info"), Bytes.toBytes("fecha"), Bytes.toBytes(h.fechaInauguracion.toString()));
                }

                // Habitaciones (Columnas dinámicas)
                for (Habitacion hab : h.habitaciones) {
                    put.addColumn(Bytes.toBytes("habitaciones"), Bytes.toBytes(hab.numero + "_tipo"), Bytes.toBytes(hab.tipo));
                    put.addColumn(Bytes.toBytes("habitaciones"), Bytes.toBytes(hab.numero + "_precio"), Bytes.toBytes(String.valueOf(hab.precio)));
                }

                // Empleados
                for (Empleado emp : h.empleados) {
                    put.addColumn(Bytes.toBytes("empleados"), Bytes.toBytes(emp.dni + "_nombre"), Bytes.toBytes(emp.nombre));
                    put.addColumn(Bytes.toBytes("empleados"), Bytes.toBytes(emp.dni + "_cargo"), Bytes.toBytes(emp.cargo));
                }

                // Reseñas
                for (Resena r : h.resenas) {
                    put.addColumn(Bytes.toBytes("resenas"), Bytes.toBytes(r.id + "_valor"), Bytes.toBytes(String.valueOf(r.valoracion)));
                    if (r.descripcion != null) {
                        put.addColumn(Bytes.toBytes("resenas"), Bytes.toBytes(r.id + "_texto"), Bytes.toBytes(r.descripcion));
                    }
                }

                table.put(put);
                System.out.println("Hotel insertado: " + h.nombre);
            }

            table.close();
            System.out.println("¡Migración completada!");

        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}