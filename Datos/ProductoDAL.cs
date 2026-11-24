using System;
using System.Configuration;
using System.Data;
using System.Data.Common;
using System.Data.SqlClient;
using Inventario.Modelos;

namespace Inventario.Datos
{
    /// <summary>
    /// Capa de acceso a datos. Todas las operaciones CRUD se hacen mediante
    /// procedimientos almacenados. Funciona con SQL Server o con MySQL:
    /// el motor se elige con la clave "MotorBD" de Web.config (SqlServer | MySql).
    ///
    /// Se usan las clases base de ADO.NET (DbConnection, DbCommand, DbDataAdapter),
    /// que en tiempo de ejecucion son:
    ///   SQL Server -> SqlConnection,   SqlCommand,   SqlDataAdapter
    ///   MySQL      -> MySqlConnection, MySqlCommand, MySqlDataAdapter (paquete NuGet MySql.Data)
    /// </summary>
    public static class ProductoDAL
    {
        // ---------------- Configuracion del motor ----------------
        public static bool EsMySql
        {
            get
            {
                string motor = ConfigurationManager.AppSettings["MotorBD"] ?? "SqlServer";
                return motor.Equals("MySql", StringComparison.OrdinalIgnoreCase);
            }
        }

        public static string NombreMotor
        {
            get { return EsMySql ? "MySQL" : "SQL Server"; }
        }

        private static string Cadena
        {
            get
            {
                string nombre = EsMySql ? "conexionMySql" : "conexionSqlServer";
                return ConfigurationManager.ConnectionStrings[nombre].ConnectionString;
            }
        }

        private static DbProviderFactory fabricaMySql;

        /// <summary>Devuelve la fabrica de objetos ADO.NET del motor elegido.</summary>
        private static DbProviderFactory Fabrica
        {
            get
            {
                if (!EsMySql) return SqlClientFactory.Instance;

                if (fabricaMySql == null)
                {
                    // MySqlClientFactory viene del paquete NuGet MySql.Data
                    Type tipo = Type.GetType("MySql.Data.MySqlClient.MySqlClientFactory, MySql.Data");
                    if (tipo == null)
                        throw new InvalidOperationException(
                            "No se encontro MySql.Data. En Visual Studio abra Herramientas > Administrador de paquetes NuGet > " +
                            "Consola del Administrador de paquetes y ejecute: Install-Package MySql.Data");
                    fabricaMySql = (DbProviderFactory)tipo.GetField("Instance").GetValue(null);
                }
                return fabricaMySql;
            }
        }

        // ---------------- Utilidades ----------------
        private static DbConnection CrearConexion()
        {
            DbConnection con = Fabrica.CreateConnection();
            con.ConnectionString = Cadena;
            return con;
        }

        private static DbCommand CrearComando(DbConnection con, string procedimiento)
        {
            DbCommand cmd = con.CreateCommand();
            cmd.CommandText = procedimiento;
            cmd.CommandType = CommandType.StoredProcedure;
            return cmd;
        }

        private static DbParameter Param(DbCommand cmd, string nombre, DbType tipo, object valor)
        {
            DbParameter p = cmd.CreateParameter();
            p.ParameterName = "@" + nombre;          // en MySQL "@p_Codigo" se asocia a p_Codigo
            p.DbType = tipo;
            p.Value = valor ?? DBNull.Value;
            cmd.Parameters.Add(p);
            return p;
        }

        private static void AgregarParametros(DbCommand cmd, Producto p)
        {
            Param(cmd, "p_Nombre", DbType.String, p.Nombre).Size = 100;
            Param(cmd, "p_Descripcion", DbType.String,
                string.IsNullOrWhiteSpace(p.Descripcion) ? (object)DBNull.Value : p.Descripcion).Size = 250;
            Param(cmd, "p_CategoriaId", DbType.Int32, p.CategoriaId);
            Param(cmd, "p_Precio", DbType.Decimal, p.Precio);
            Param(cmd, "p_Stock", DbType.Int32, p.Stock);
            Param(cmd, "p_FechaIngreso", DbType.Date, p.FechaIngreso);
        }

        private static DataTable LlenarTabla(DbCommand cmd)
        {
            using (DbDataAdapter da = Fabrica.CreateDataAdapter())
            {
                da.SelectCommand = cmd;
                DataTable dt = new DataTable();
                da.Fill(dt);
                return dt;
            }
        }

        /// <summary>True si la excepcion es por clave duplicada (codigo repetido).</summary>
        public static bool EsDuplicado(Exception ex)
        {
            SqlException sql = ex as SqlException;
            if (sql != null) return sql.Number == 2627 || sql.Number == 2601;

            // MySqlException.Number == 1062 (Duplicate entry)
            var prop = ex.GetType().GetProperty("Number");
            if (ex.GetType().Name == "MySqlException" && prop != null)
                return Convert.ToInt32(prop.GetValue(ex, null)) == 1062;
            return false;
        }

        // ---------------- CREATE ----------------
        /// <summary>
        /// Inserta el producto. La base de datos genera el codigo (PREFIJO-NNN)
        /// segun la categoria; se devuelve en p.Codigo junto con p.ProductoId.
        /// </summary>
        public static void Crear(Producto p)
        {
            using (DbConnection con = CrearConexion())
            using (DbCommand cmd = CrearComando(con, "sp_create_producto"))
            {
                AgregarParametros(cmd, p);
                con.Open();
                using (DbDataReader dr = cmd.ExecuteReader())
                {
                    if (dr.Read())
                    {
                        p.ProductoId = Convert.ToInt32(dr["ProductoId"]);
                        p.Codigo = dr["Codigo"].ToString();
                    }
                }
            }
        }

        // ---------------- READ ----------------
        public static DataTable Listar(string buscar)
        {
            using (DbConnection con = CrearConexion())
            using (DbCommand cmd = CrearComando(con, "sp_read_productos"))
            {
                Param(cmd, "p_Buscar", DbType.String,
                    string.IsNullOrWhiteSpace(buscar) ? (object)DBNull.Value : buscar.Trim()).Size = 100;
                return LlenarTabla(cmd);
            }
        }

        public static Producto ObtenerPorId(int id)
        {
            using (DbConnection con = CrearConexion())
            using (DbCommand cmd = CrearComando(con, "sp_read_producto_id"))
            {
                Param(cmd, "p_ProductoId", DbType.Int32, id);
                con.Open();
                using (DbDataReader dr = cmd.ExecuteReader())
                {
                    if (!dr.Read()) return null;
                    return new Producto
                    {
                        ProductoId = Convert.ToInt32(dr["ProductoId"]),
                        Codigo = dr["Codigo"].ToString(),
                        Nombre = dr["Nombre"].ToString(),
                        Descripcion = dr["Descripcion"] == DBNull.Value ? "" : dr["Descripcion"].ToString(),
                        CategoriaId = Convert.ToInt32(dr["CategoriaId"]),
                        Precio = Convert.ToDecimal(dr["Precio"]),
                        Stock = Convert.ToInt32(dr["Stock"]),
                        FechaIngreso = Convert.ToDateTime(dr["FechaIngreso"])
                    };
                }
            }
        }

        public static DataTable ListarCategorias()
        {
            using (DbConnection con = CrearConexion())
            using (DbCommand cmd = CrearComando(con, "sp_read_categorias"))
            {
                return LlenarTabla(cmd);
            }
        }

        public static DataRow Resumen()
        {
            using (DbConnection con = CrearConexion())
            using (DbCommand cmd = CrearComando(con, "sp_resumen_inventario"))
            {
                return LlenarTabla(cmd).Rows[0];
            }
        }

        // ---------------- UPDATE ----------------
        /// <summary>
        /// Actualiza el producto. Si cambia de categoria, la base de datos le asigna
        /// un codigo nuevo de esa categoria (queda en p.Codigo). Devuelve false si no existe.
        /// </summary>
        public static bool Actualizar(Producto p)
        {
            using (DbConnection con = CrearConexion())
            using (DbCommand cmd = CrearComando(con, "sp_update_producto"))
            {
                Param(cmd, "p_ProductoId", DbType.Int32, p.ProductoId);
                AgregarParametros(cmd, p);
                con.Open();
                using (DbDataReader dr = cmd.ExecuteReader())
                {
                    if (!dr.Read() || Convert.ToInt32(dr["FilasAfectadas"]) == 0) return false;
                    p.Codigo = dr["Codigo"].ToString();
                    return true;
                }
            }
        }

        // ---------------- DELETE ----------------
        public static bool Eliminar(int id)
        {
            using (DbConnection con = CrearConexion())
            using (DbCommand cmd = CrearComando(con, "sp_delete_producto"))
            {
                Param(cmd, "p_ProductoId", DbType.Int32, id);
                con.Open();
                return Convert.ToInt32(cmd.ExecuteScalar()) > 0;
            }
        }
    }
}
