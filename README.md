# Inventario - Laboratorio CRUD ASP.NET Web Forms (C#)

**Curso:** Herramientas de Programacion Aplicada III (.NET) - UTP FISC - Grupo 1IL133
**Instructora:** Ing. Irina Fong - II Semestre 2026
**Estudiantes:** Diego Sanjur - Tomas Vezga

Aplicacion web ASP.NET Web Forms (.NET Framework 4.8) que administra el inventario de productos de una tienda con las cuatro operaciones CRUD. Usa una **pagina maestra** ([`Site1.Master`](Site1.Master)) con Bootstrap 5.3, y funciona con **MySQL** (MySQL Workbench) o con **SQL Server** (SQL Server Management Studio). El motor se elige en [`Web.config`](Web.config) y todo el acceso a datos se hace con **procedimientos almacenados**.

![Pagina de inicio](docs/capturas/01-inicio.png)

## Estructura

- [`Site1.Master`](Site1.Master) - Pagina maestra: navbar, contenedor (ContentPlaceHolder) y footer
- [`Default.aspx`](Default.aspx) - Redirige a `Pages/Index.aspx`
- [`Pages/`](Pages)
  - [`Index.aspx`](Pages/Index.aspx) - Inicio: resumen del inventario y productos con menor stock
  - [`Crud.aspx`](Pages/Crud.aspx) - Formulario + GridView con Crear, Leer, Actualizar y Eliminar
- [`Modelos/`](Modelos) - [`Producto.cs`](Modelos/Producto.cs): entidad Producto
- [`Datos/`](Datos) - [`ProductoDAL.cs`](Datos/ProductoDAL.cs): capa de acceso a datos (MySqlConnection/SqlConnection, Command, DataAdapter)
- [`Content/`](Content) - [`site.css`](Content/site.css): estilos propios
- [`Database/`](Database)
  - [`InventarioDB_MySQL.sql`](Database/InventarioDB_MySQL.sql) - Script para MySQL (Workbench)
  - [`InventarioDB.sql`](Database/InventarioDB.sql) - Script para SQL Server (SSMS)
- [`docs/capturas/`](docs/capturas) - Capturas de pantalla de este README
- [`Web.config`](Web.config) - Motor (`MotorBD`) y cadenas de conexion

![Estructura del proyecto en Visual Studio](docs/capturas/02-visual-studio.png)

## Como ejecutarlo

### Opcion A: MySQL (configurada por defecto)

1. **Base de datos:** en MySQL Workbench abrir [`Database/InventarioDB_MySQL.sql`](Database/InventarioDB_MySQL.sql) y ejecutarlo completo (boton del rayo, Execute). Se crea `InventarioDB` con tablas, datos de prueba y procedimientos almacenados.
2. **Conector:** en Visual Studio, *Herramientas > Administrador de paquetes NuGet > Consola del Administrador de paquetes* y ejecutar:
   ```
   Install-Package MySql.Data
   ```
3. **Cadena de conexion:** en [`Web.config`](Web.config), en `conexionMySql`, poner el usuario y la contrasena de su MySQL (`User Id=root;Password=...`). Dejar `<add key="MotorBD" value="MySql" />`.
4. **Compilar > Recompilar solucion** y ejecutar con **F5**.

![Base de datos en MySQL Workbench](docs/capturas/03-bd-mysql.png)

### Opcion B: SQL Server

1. En SSMS abrir [`Database/InventarioDB.sql`](Database/InventarioDB.sql) y presionar **F5**.
2. En [`Web.config`](Web.config), cambiar `MotorBD` a `SqlServer` y en `conexionSqlServer` poner el *Server name* que muestra SSMS (`localhost`, `.\SQLEXPRESS` o `(localdb)\MSSQLLocalDB`).
3. Restaurar paquetes NuGet, recompilar y ejecutar con **F5**. (No necesita MySql.Data.)

![Base de datos en SQL Server Management Studio](docs/capturas/04-bd-sqlserver.png)

La pagina de inicio muestra que motor esta en uso.

## Funcionalidad (rubrica)

| Operacion | Donde | Procedimiento almacenado |
|---|---|---|
| CREATE | Formulario > boton **Guardar** (codigo automatico) | `sp_create_producto`, `sp_generar_codigo` |
| READ | GridView con busqueda y paginacion; resumen en Inicio | `sp_read_productos`, `sp_read_producto_id`, `sp_read_categorias`, `sp_resumen_inventario` |
| UPDATE | Boton Editar en la fila > carga el formulario > **Actualizar** | `sp_update_producto` |
| DELETE | Boton Eliminar en la fila (con confirmacion) | `sp_delete_producto` |

### CREATE

Se llena el formulario (el codigo queda en blanco porque lo genera la base de datos) y se presiona **Guardar**.

![Formulario de nuevo producto](docs/capturas/05-create-formulario.png)
![Producto registrado con codigo generado](docs/capturas/06-create-resultado.png)

### READ

Listado con paginacion y busqueda por codigo, nombre o categoria.

![Listado de productos](docs/capturas/07-read-listado.png)
![Busqueda de productos](docs/capturas/08-read-busqueda.png)

### UPDATE

El boton Editar carga el producto en el formulario; al cambiar de categoria recibe un codigo nuevo.

![Producto cargado para editar](docs/capturas/09-update-editando.png)
![Producto actualizado](docs/capturas/10-update-resultado.png)

### DELETE

El boton Eliminar pide confirmacion antes de borrar.

![Confirmacion de eliminacion](docs/capturas/11-delete-confirmacion.png)
![Producto eliminado](docs/capturas/12-delete-resultado.png)

### Codificacion automatica de productos (norma de calidad)

El usuario no escribe el codigo: la base de datos lo genera con el formato **PREFIJO-NNN** segun la categoria (procedimiento `sp_generar_codigo`).

- Electronica = ELE, Oficina = OFI, Limpieza = LIM, Alimentos = ALI, Herramientas = HER.
- Cada categoria lleva su propio consecutivo (columna `Consecutivo`), por ejemplo ELE-001, ELE-002, ELE-003.
- Un numero nunca se reutiliza, aunque se elimine el producto.
- Si un producto cambia de categoria, recibe un codigo nuevo de la categoria destino.
- La generacion ocurre dentro de una transaccion, asi dos usuarios no obtienen el mismo codigo.

### Validaciones

Campos obligatorios, precio y stock no negativos (validadores ASP.NET y restricciones `CHECK` en la base de datos) y fecha con `TextMode="Date"`.

![Validaciones del formulario](docs/capturas/13-validaciones.png)

## Tecnologias

C# - ASP.NET Web Forms - .NET Framework 4.8 - MySQL / Workbench - SQL Server / SSMS - ADO.NET (`MySql.Data`, `System.Data.SqlClient`) - Bootstrap 5.3 - Bootstrap Icons
