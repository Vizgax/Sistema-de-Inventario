using System;
using System.Data;
using System.Data.Common;
using System.Globalization;
using System.Web.UI.WebControls;
using Inventario.Datos;
using Inventario.Modelos;

namespace Inventario.Pages
{
    public partial class Crud : System.Web.UI.Page
    {
        private static readonly CultureInfo Inv = CultureInfo.InvariantCulture;

        protected void Page_Load(object sender, EventArgs e)
        {
            if (IsPostBack) return;
            try
            {
                CargarCategorias();
                LimpiarFormulario();
                CargarProductos();
            }
            catch (Exception ex)
            {
                MostrarMensaje("No se pudo conectar a la base de datos (" + ProductoDAL.NombreMotor + "). Revise MotorBD y la cadena de conexion en Web.config. Detalle: "
                    + ex.Message, "danger");
            }
        }

        // ================= READ =================
        private void CargarCategorias()
        {
            ddlCategoria.DataSource = ProductoDAL.ListarCategorias();
            ddlCategoria.DataTextField = "Texto";
            ddlCategoria.DataValueField = "CategoriaId";
            ddlCategoria.DataBind();
            ddlCategoria.Items.Insert(0, new ListItem("-- Seleccione --", "0"));
        }

        private void CargarProductos()
        {
            DataTable dt = ProductoDAL.Listar(txtBuscar.Text);
            gvProductos.DataSource = dt;
            gvProductos.DataBind();
            litTotal.Text = dt.Rows.Count + " producto(s) encontrado(s).";
        }

        protected void btnBuscar_Click(object sender, EventArgs e)
        {
            gvProductos.PageIndex = 0;
            CargarProductos();
        }

        protected void btnVerTodos_Click(object sender, EventArgs e)
        {
            txtBuscar.Text = string.Empty;
            gvProductos.PageIndex = 0;
            CargarProductos();
        }

        protected void gvProductos_PageIndexChanging(object sender, GridViewPageEventArgs e)
        {
            gvProductos.PageIndex = e.NewPageIndex;
            CargarProductos();
        }

        // ================= CREATE =================
        protected void btnGuardar_Click(object sender, EventArgs e)
        {
            if (!IsValid) return;
            Producto p;
            if (!LeerFormulario(out p)) return;

            try
            {
                ProductoDAL.Crear(p);
                MostrarMensaje("Producto <strong>" + Server.HtmlEncode(p.Nombre) + "</strong> registrado con el codigo <strong>"
                    + Server.HtmlEncode(p.Codigo) + "</strong>.", "success", true);
                LimpiarFormulario();
                CargarProductos();
            }
            catch (DbException ex)
            {
                MostrarErrorSql(ex);
            }
        }

        // ================= UPDATE =================
        protected void btnActualizar_Click(object sender, EventArgs e)
        {
            if (!IsValid) return;
            Producto p;
            if (!LeerFormulario(out p)) return;
            p.ProductoId = Convert.ToInt32(hfProductoId.Value);

            try
            {
                string codigoAnterior = txtCodigo.Text;
                if (ProductoDAL.Actualizar(p))
                {
                    string texto = "Producto <strong>" + Server.HtmlEncode(p.Nombre) + "</strong> actualizado correctamente.";
                    if (p.Codigo != codigoAnterior)
                        texto += " Por el cambio de categoria su nuevo codigo es <strong>" + Server.HtmlEncode(p.Codigo) + "</strong>.";
                    MostrarMensaje(texto, "success", true);
                }
                else
                    MostrarMensaje("El producto ya no existe en la base de datos.", "warning");
                LimpiarFormulario();
                CargarProductos();
            }
            catch (DbException ex)
            {
                MostrarErrorSql(ex);
            }
        }

        // ================= EDITAR / DELETE (botones del GridView) =================
        protected void gvProductos_RowCommand(object sender, GridViewCommandEventArgs e)
        {
            if (e.CommandName != "Editar" && e.CommandName != "Eliminar") return; // paginacion, etc.
            int id = Convert.ToInt32(e.CommandArgument);

            try
            {
                if (e.CommandName == "Editar")
                {
                    Producto p = ProductoDAL.ObtenerPorId(id);
                    if (p == null)
                    {
                        MostrarMensaje("El producto seleccionado no existe.", "warning");
                        CargarProductos();
                        return;
                    }
                    hfProductoId.Value = p.ProductoId.ToString();
                    txtCodigo.Text = p.Codigo;
                    txtNombre.Text = p.Nombre;
                    txtDescripcion.Text = p.Descripcion;
                    ddlCategoria.SelectedValue = p.CategoriaId.ToString();
                    txtPrecio.Text = p.Precio.ToString("0.00", Inv);
                    txtStock.Text = p.Stock.ToString();
                    txtFecha.Text = p.FechaIngreso.ToString("yyyy-MM-dd");

                    litTituloForm.Text = "Editando producto #" + p.ProductoId;
                    btnGuardar.Visible = false;
                    btnActualizar.Visible = true;
                    pnlMensaje.Visible = false;
                }
                else // Eliminar
                {
                    if (ProductoDAL.Eliminar(id))
                        MostrarMensaje("Producto con ID " + id + " eliminado.", "success", true);
                    else
                        MostrarMensaje("El producto ya habia sido eliminado.", "warning");

                    if (hfProductoId.Value == id.ToString()) LimpiarFormulario();
                    CargarProductos();
                }
            }
            catch (DbException ex)
            {
                MostrarErrorSql(ex);
            }
        }

        protected void btnCancelar_Click(object sender, EventArgs e)
        {
            LimpiarFormulario();
            pnlMensaje.Visible = false;
        }

        // ================= Utilidades =================
        private bool LeerFormulario(out Producto p)
        {
            p = null;
            decimal precio;
            int stock;
            DateTime fecha;

            if (!decimal.TryParse(txtPrecio.Text.Replace(',', '.'), NumberStyles.Number, Inv, out precio) || precio < 0)
            {
                MostrarMensaje("El precio no es valido.", "warning");
                return false;
            }
            if (!int.TryParse(txtStock.Text, out stock) || stock < 0)
            {
                MostrarMensaje("El stock no es valido.", "warning");
                return false;
            }
            if (!DateTime.TryParseExact(txtFecha.Text, "yyyy-MM-dd", Inv, DateTimeStyles.None, out fecha))
            {
                MostrarMensaje("La fecha no es valida.", "warning");
                return false;
            }

            p = new Producto
            {
                Nombre = txtNombre.Text.Trim(),
                Descripcion = txtDescripcion.Text.Trim(),
                CategoriaId = Convert.ToInt32(ddlCategoria.SelectedValue),
                Precio = precio,
                Stock = stock,
                FechaIngreso = fecha
            };
            return true;
        }

        private void LimpiarFormulario()
        {
            hfProductoId.Value = string.Empty;
            txtCodigo.Text = string.Empty;
            txtNombre.Text = string.Empty;
            txtDescripcion.Text = string.Empty;
            if (ddlCategoria.Items.Count > 0) ddlCategoria.SelectedIndex = 0;
            txtPrecio.Text = string.Empty;
            txtStock.Text = string.Empty;
            txtFecha.Text = DateTime.Today.ToString("yyyy-MM-dd");
            litTituloForm.Text = "Nuevo producto";
            btnGuardar.Visible = true;
            btnActualizar.Visible = false;
        }

        private void MostrarErrorSql(DbException ex)
        {
            if (ProductoDAL.EsDuplicado(ex))
                MostrarMensaje("Se genero un codigo repetido. Intente guardar de nuevo.", "warning");
            else
                MostrarMensaje("Error de base de datos: " + Server.HtmlEncode(ex.Message), "danger");
        }

        private void MostrarMensaje(string texto, string tipo, bool html = false)
        {
            pnlMensaje.Visible = true;
            pnlMensaje.CssClass = "alert alert-" + tipo + " alert-dismissible fade show";
            litMensaje.Text = (html ? texto : Server.HtmlEncode(texto))
                + "<button type=\"button\" class=\"btn-close\" data-bs-dismiss=\"alert\" aria-label=\"Cerrar\"></button>";
        }
    }
}
