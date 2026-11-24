<%@ Page Title="Productos" Language="C#" MasterPageFile="~/Site1.Master" AutoEventWireup="true" CodeBehind="Crud.aspx.cs" Inherits="Inventario.Pages.Crud" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="server">
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">

    <nav aria-label="breadcrumb">
        <ol class="breadcrumb">
            <li class="breadcrumb-item"><a href="Index.aspx">Inicio</a></li>
            <li class="breadcrumb-item active" aria-current="page">Productos</li>
        </ol>
    </nav>

    <h2 class="h3 mb-3"><i class="bi bi-box-seam me-2"></i>Gestion de productos</h2>

    <!-- Mensajes de resultado -->
    <asp:Panel ID="pnlMensaje" runat="server" Visible="false" role="alert">
        <asp:Literal ID="litMensaje" runat="server" />
    </asp:Panel>

    <div class="row g-4">

        <!-- ============ FORMULARIO (CREATE / UPDATE) ============ -->
        <div class="col-lg-4">
            <div class="card shadow-sm">
                <div class="card-header bg-white fw-semibold">
                    <asp:Literal ID="litTituloForm" runat="server" Text="Nuevo producto" />
                </div>
                <div class="card-body">
                    <asp:HiddenField ID="hfProductoId" runat="server" />

                    <div class="mb-3">
                        <label class="form-label" for="<%= txtCodigo.ClientID %>">Codigo</label>
                        <asp:TextBox ID="txtCodigo" runat="server" CssClass="form-control bg-light fw-semibold" ReadOnly="true"
                            placeholder="Se genera automaticamente" />
                        <div class="form-text">Formato PREFIJO-NNN segun la categoria (ej. ELE-003).</div>
                    </div>

                    <div class="mb-3">
                        <label class="form-label" for="<%= txtNombre.ClientID %>">Nombre</label>
                        <asp:TextBox ID="txtNombre" runat="server" CssClass="form-control" MaxLength="100" />
                        <asp:RequiredFieldValidator ID="rfvNombre" runat="server" ControlToValidate="txtNombre" ValidationGroup="prod"
                            ErrorMessage="El nombre es obligatorio." Display="Dynamic" CssClass="text-danger validator" />
                    </div>

                    <div class="mb-3">
                        <label class="form-label" for="<%= txtDescripcion.ClientID %>">Descripcion</label>
                        <asp:TextBox ID="txtDescripcion" runat="server" CssClass="form-control" TextMode="MultiLine" Rows="2" MaxLength="250" />
                    </div>

                    <div class="mb-3">
                        <label class="form-label" for="<%= ddlCategoria.ClientID %>">Categoria</label>
                        <asp:DropDownList ID="ddlCategoria" runat="server" CssClass="form-select" />
                        <asp:RequiredFieldValidator ID="rfvCategoria" runat="server" ControlToValidate="ddlCategoria" InitialValue="0" ValidationGroup="prod"
                            ErrorMessage="Seleccione una categoria." Display="Dynamic" CssClass="text-danger validator" />
                    </div>

                    <div class="row">
                        <div class="col-6 mb-3">
                            <label class="form-label" for="<%= txtPrecio.ClientID %>">Precio ($)</label>
                            <asp:TextBox ID="txtPrecio" runat="server" CssClass="form-control" TextMode="Number" step="0.01" min="0" />
                            <asp:RequiredFieldValidator ID="rfvPrecio" runat="server" ControlToValidate="txtPrecio" ValidationGroup="prod"
                                ErrorMessage="Requerido." Display="Dynamic" CssClass="text-danger validator" />
                            <asp:RangeValidator ID="rvPrecio" runat="server" ControlToValidate="txtPrecio" ValidationGroup="prod"
                                Type="Double" MinimumValue="0" MaximumValue="99999999" ErrorMessage="Precio invalido." Display="Dynamic" CssClass="text-danger validator" />
                        </div>
                        <div class="col-6 mb-3">
                            <label class="form-label" for="<%= txtStock.ClientID %>">Stock</label>
                            <asp:TextBox ID="txtStock" runat="server" CssClass="form-control" TextMode="Number" min="0" />
                            <asp:RequiredFieldValidator ID="rfvStock" runat="server" ControlToValidate="txtStock" ValidationGroup="prod"
                                ErrorMessage="Requerido." Display="Dynamic" CssClass="text-danger validator" />
                            <asp:RangeValidator ID="rvStock" runat="server" ControlToValidate="txtStock" ValidationGroup="prod"
                                Type="Integer" MinimumValue="0" MaximumValue="1000000" ErrorMessage="Stock invalido." Display="Dynamic" CssClass="text-danger validator" />
                        </div>
                    </div>

                    <div class="mb-3">
                        <label class="form-label" for="<%= txtFecha.ClientID %>">Fecha de ingreso</label>
                        <asp:TextBox ID="txtFecha" runat="server" CssClass="form-control" TextMode="Date" />
                        <asp:RequiredFieldValidator ID="rfvFecha" runat="server" ControlToValidate="txtFecha" ValidationGroup="prod"
                            ErrorMessage="La fecha es obligatoria." Display="Dynamic" CssClass="text-danger validator" />
                    </div>

                    <div class="d-grid gap-2">
                        <asp:Button ID="btnGuardar" runat="server" Text="Guardar" CssClass="btn btn-success"
                            ValidationGroup="prod" OnClick="btnGuardar_Click" />
                        <asp:Button ID="btnActualizar" runat="server" Text="Actualizar" CssClass="btn btn-primary"
                            ValidationGroup="prod" OnClick="btnActualizar_Click" Visible="false" />
                        <asp:Button ID="btnCancelar" runat="server" Text="Limpiar / Cancelar" CssClass="btn btn-outline-secondary"
                            CausesValidation="false" OnClick="btnCancelar_Click" />
                    </div>
                </div>
            </div>
        </div>

        <!-- ============ LISTADO (READ / DELETE) ============ -->
        <div class="col-lg-8">
            <div class="card shadow-sm">
                <div class="card-header bg-white">
                    <asp:Panel ID="pnlBuscar" runat="server" DefaultButton="btnBuscar" CssClass="input-group">
                        <span class="input-group-text"><i class="bi bi-search"></i></span>
                        <asp:TextBox ID="txtBuscar" runat="server" CssClass="form-control" placeholder="Buscar por codigo, nombre o categoria" />
                        <asp:Button ID="btnBuscar" runat="server" Text="Buscar" CssClass="btn btn-dark" CausesValidation="false" OnClick="btnBuscar_Click" />
                        <asp:Button ID="btnVerTodos" runat="server" Text="Ver todos" CssClass="btn btn-outline-dark" CausesValidation="false" OnClick="btnVerTodos_Click" />
                    </asp:Panel>
                </div>
                <div class="card-body p-0 table-responsive">
                    <asp:GridView ID="gvProductos" runat="server" AutoGenerateColumns="false" GridLines="None"
                        DataKeyNames="ProductoId" CssClass="table table-striped table-hover mb-0"
                        HeaderStyle-CssClass="table-dark" AllowPaging="true" PageSize="8"
                        PagerStyle-CssClass="px-3 py-2" OnPageIndexChanging="gvProductos_PageIndexChanging"
                        OnRowCommand="gvProductos_RowCommand" EmptyDataText="No se encontraron productos.">
                        <Columns>
                            <asp:BoundField DataField="ProductoId" HeaderText="ID" />
                            <asp:BoundField DataField="Codigo" HeaderText="Codigo" />
                            <asp:BoundField DataField="Nombre" HeaderText="Nombre" />
                            <asp:BoundField DataField="Categoria" HeaderText="Categoria" />
                            <asp:BoundField DataField="Precio" HeaderText="Precio" DataFormatString="{0:N2}" />
                            <asp:BoundField DataField="Stock" HeaderText="Stock" />
                            <asp:BoundField DataField="FechaIngreso" HeaderText="Ingreso" DataFormatString="{0:dd/MM/yyyy}" />
                            <asp:TemplateField HeaderText="Acciones" ItemStyle-CssClass="text-nowrap">
                                <ItemTemplate>
                                    <asp:LinkButton ID="btnEditar" runat="server" CommandName="Editar"
                                        CommandArgument='<%# Eval("ProductoId") %>' CausesValidation="false"
                                        CssClass="btn btn-sm btn-outline-primary" ToolTip="Editar">
                                        <i class="bi bi-pencil"></i>
                                    </asp:LinkButton>
                                    <asp:LinkButton ID="btnEliminar" runat="server" CommandName="Eliminar"
                                        CommandArgument='<%# Eval("ProductoId") %>' CausesValidation="false"
                                        CssClass="btn btn-sm btn-outline-danger" ToolTip="Eliminar"
                                        OnClientClick="return confirm('Seguro que desea eliminar este producto?');">
                                        <i class="bi bi-trash"></i>
                                    </asp:LinkButton>
                                </ItemTemplate>
                            </asp:TemplateField>
                        </Columns>
                    </asp:GridView>
                </div>
                <div class="card-footer bg-white small text-muted">
                    <asp:Literal ID="litTotal" runat="server" />
                </div>
            </div>
        </div>
    </div>

</asp:Content>
