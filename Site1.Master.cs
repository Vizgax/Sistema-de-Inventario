using System;
using System.IO;

namespace Inventario
{
    public partial class Site1 : System.Web.UI.MasterPage
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            // Marca como activo el enlace de la pagina actual en la barra de navegacion
            string pagina = Path.GetFileName(Request.Path).ToLowerInvariant();
            if (pagina == "crud.aspx")
                lnkCrud.Attributes["class"] = "nav-link active";
            else
                lnkInicio.Attributes["class"] = "nav-link active";
        }
    }
}
