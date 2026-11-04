// Hotel.java
import java.util.List;
import java.sql.Date;

public class Hotel {
    public int id;
    public String nombre;
    public Date fechaInauguracion;
    public List<Habitacion> habitaciones;
    public List<Empleado> empleados;
    public List<Resena> resenas;

    public Hotel(int id, String nombre, Date fecha, List<Habitacion> habs, List<Empleado> emps, List<Resena> res) {
        this.id = id;
        this.nombre = nombre;
        this.fechaInauguracion = fecha;
        this.habitaciones = habs;
        this.empleados = emps;
        this.resenas = res;
    }
}
