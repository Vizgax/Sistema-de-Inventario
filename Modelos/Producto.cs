using System;

namespace Inventario.Modelos
{
    /// <summary>Entidad que representa un registro de la tabla Productos.</summary>
    public class Producto
    {
        public int ProductoId { get; set; }
        public string Codigo { get; set; }
        public string Nombre { get; set; }
        public string Descripcion { get; set; }
        public int CategoriaId { get; set; }
        public decimal Precio { get; set; }
        public int Stock { get; set; }
        public DateTime FechaIngreso { get; set; }
    }
}
