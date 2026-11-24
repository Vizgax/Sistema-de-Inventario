using System;
using System.Data;
using System.Globalization;
using Inventario.Datos;

namespace Inventario.Pages
{
    public partial class Index : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (IsPostBack) return;
            try
            {
                DataRow r = ProductoDAL.Resumen();
                litProductos.Text = r["TotalProductos"].ToString();
                litUnidades.Text = r["TotalUnidades"].ToString();
                litValor.Text = Convert.ToDecimal(r["ValorInventario"]).ToString("C2", CultureInfo.GetCultureInfo("en-US"));
                litCategorias.Text = r["TotalCategorias"].ToString();
                litMotor.Text = ProductoDAL.NombreMotor;

                DataView vista = ProductoDAL.Listar(null).DefaultView;
                vista.Sort = "Stock ASC";
                DataTable top = vista.ToTable();
                while (top.Rows.Count > 5) top.Rows.RemoveAt(top.Rows.Count - 1);
                gvBajoStock.DataSource = top;
                gvBajoStock.DataBind();
            }
            catch (Exception ex)
            {
                pnlError.Visible = true;
                litError.Text = "No se pudo conectar a la base de datos (" + ProductoDAL.NombreMotor + "). Revise MotorBD y la cadena de conexion en Web.config. Detalle: "
                    + Server.HtmlEncode(ex.Message);
            }
        }
    }
}
