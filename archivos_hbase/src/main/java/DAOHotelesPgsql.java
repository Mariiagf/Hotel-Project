import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import java.util.Properties;

public class DAOHotelesPgsql {
    Connection con;

    public DAOHotelesPgsql(String servidor, String puerto, String baseDatos, String usuario, String clave){
        try {
            Properties propUsuario = new Properties();
            propUsuario.setProperty("user", usuario);
            propUsuario.setProperty("password", clave);
            // Asegúrate de añadir ?currentSchema=hoteles si usas esquemas
            this.con = DriverManager.getConnection("jdbc:postgresql://" + servidor + ":" + puerto + "/" + baseDatos, propUsuario);
        } catch (SQLException ex) {
            System.out.print("Error conectando a PostgreSQL: " + ex.getMessage() + "\n");
        }
    }

    public void close(){
        try { con.close(); } catch (SQLException ex) { ex.printStackTrace(); }
    }

    public List<Hotel> getHoteles() {
        List<Hotel> listaHoteles = new ArrayList<>();

        PreparedStatement stmHoteles = null;
        PreparedStatement stmHabitaciones = null;
        PreparedStatement stmEmpleados = null;
        PreparedStatement stmResenas = null;

        try {
            // 1. Obtener Hoteles
            String sqlHoteles = "SELECT id, nombre, fecha_inauguracion FROM hoteles.hoteles";
            stmHoteles = con.prepareStatement(sqlHoteles);
            ResultSet rsHoteles = stmHoteles.executeQuery();

            while (rsHoteles.next()) {
                int idHotel = rsHoteles.getInt("id");

                // Listas auxiliares para este hotel
                List<Habitacion> habs = new ArrayList<>();
                List<Empleado> emps = new ArrayList<>();
                List<Resena> ress = new ArrayList<>();

                // 2. Obtener Habitaciones del hotel actual
                String sqlHab = "SELECT numero, tipo, precio_noche FROM hoteles.habitaciones WHERE hotel = ?";
                stmHabitaciones = con.prepareStatement(sqlHab);
                stmHabitaciones.setInt(1, idHotel);
                ResultSet rsHab = stmHabitaciones.executeQuery();
                while (rsHab.next()) {
                    habs.add(new Habitacion(
                            rsHab.getInt("numero"),
                            rsHab.getString("tipo"),
                            rsHab.getInt("precio_noche")
                    ));
                }

                // 3. Obtener Empleados (Hacemos JOIN con Personas para sacar el nombre)
                String sqlEmp = "SELECT e.dni_empleado, e.cargo, p.nombre " +
                        "FROM hoteles.empleados e " +
                        "JOIN hoteles.personas p ON e.dni_empleado = p.dni " +
                        "WHERE e.hotel = ?";
                stmEmpleados = con.prepareStatement(sqlEmp);
                stmEmpleados.setInt(1, idHotel);
                ResultSet rsEmp = stmEmpleados.executeQuery();
                while (rsEmp.next()) {
                    emps.add(new Empleado(
                            rsEmp.getString("dni_empleado"),
                            rsEmp.getString("nombre"),
                            rsEmp.getString("cargo")
                    ));
                }

                // 4. Obtener Reseñas
                String sqlRes = "SELECT id_reseña, descripcion, valoracion FROM hoteles.resenas WHERE hotel = ?";
                stmResenas = con.prepareStatement(sqlRes);
                stmResenas.setInt(1, idHotel);
                ResultSet rsRes = stmResenas.executeQuery();
                while (rsRes.next()) {
                    ress.add(new Resena(
                            rsRes.getInt("id_reseña"),
                            rsRes.getString("descripcion"),
                            rsRes.getInt("valoracion")
                    ));
                }

                // Crear objeto Hotel y añadir a la lista
                listaHoteles.add(new Hotel(
                        idHotel,
                        rsHoteles.getString("nombre"),
                        rsHoteles.getDate("fecha_inauguracion"),
                        habs, emps, ress
                ));
            }

        } catch (SQLException ex) {
            System.out.println("Error SQL: " + ex.getMessage());
            ex.printStackTrace();
        }

        return listaHoteles;
    }
}
