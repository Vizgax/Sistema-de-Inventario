<%@ Page Title="Inicio" Language="C#" MasterPageFile="~/Site1.Master" AutoEventWireup="true" CodeBehind="Index.aspx.cs" Inherits="Inventario.Pages.Index" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="server">
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">

    <!-- Encabezado -->
    <section class="hero text-white rounded-3 p-4 p-md-5 mb-4 shadow-sm">
        <h1 class="display-6 fw-semibold mb-2">Sistema de Inventario</h1>
        <p class="lead mb-4">Registre, consulte, modifique y elimine productos.
            <span class="badge text-bg-light ms-1"><i class="bi bi-database me-1"></i>Motor: <asp:Literal ID="litMotor" runat="server" Text="-" /></span></p>
        <a href="Crud.aspx" class="btn btn-primary btn-lg"><i class="bi bi-pencil-square me-2"></i>Administrar productos</a>
    </section>

    <asp:Panel ID="pnlError" runat="server" Visible="false" CssClass="alert alert-danger">
        <i class="bi bi-exclamation-triangle me-2"></i><asp:Literal ID="litError" runat="server" />
    </asp:Panel>

    <!-- Resumen (READ) -->
    <div class="row g-3 mb-4">
        <div class="col-6 col-lg-3">
            <div class="card stat-card shadow-sm h-100"><div class="card-body">
                <div class="text-muted small">Productos</div>
                <div class="display-6"><asp:Literal ID="litProductos" runat="server" Text="0" /></div>
            </div></div>
        </div>
        <div class="col-6 col-lg-3">
            <div class="card stat-card success shadow-sm h-100"><div class="card-body">
                <div class="text-muted small">Unidades en stock</div>
                <div class="display-6"><asp:Literal ID="litUnidades" runat="server" Text="0" /></div>
            </div></div>
        </div>
        <div class="col-6 col-lg-3">
            <div class="card stat-card warning shadow-sm h-100"><div class="card-body">
                <div class="text-muted small">Valor del inventario</div>
                <div class="display-6"><asp:Literal ID="litValor" runat="server" Text="$0.00" /></div>
            </div></div>
        </div>
        <div class="col-6 col-lg-3">
            <div class="card stat-card info shadow-sm h-100"><div class="card-body">
                <div class="text-muted small">Categorias</div>
                <div class="display-6"><asp:Literal ID="litCategorias" runat="server" Text="0" /></div>
            </div></div>
        </div>
    </div>

    <!-- Productos con poco stock -->
    <div class="card shadow-sm">
        <div class="card-header bg-white fw-semibold"><i class="bi bi-exclamation-circle text-warning me-2"></i>Productos con menor stock</div>
        <div class="card-body p-0">
            <asp:GridView ID="gvBajoStock" runat="server" AutoGenerateColumns="false" GridLines="None"
                CssClass="table table-hover mb-0" EmptyDataText="No hay productos registrados.">
                <Columns>
                    <asp:BoundField DataField="Codigo" HeaderText="Codigo" />
                    <asp:BoundField DataField="Nombre" HeaderText="Producto" />
                    <asp:BoundField DataField="Categoria" HeaderText="Categoria" />
                    <asp:BoundField DataField="Stock" HeaderText="Stock" />
                </Columns>
            </asp:GridView>
        </div>
    </div>

</asp:Content>
