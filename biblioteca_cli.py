import mysql.connector
from mysql.connector import Error

# ==========================================================
#  CONEXIÓN A LA BASE DE DATOS
# ==========================================================

def conectar():
    try:
        conexion = mysql.connector.connect(
            host="localhost",
            user="root",          
            password="12341",       
            database="ProyectoBiblioteca"
        )
        return conexion
    except Error as e:
        print("Error al conectar a MySQL:", e)
        return None


# ==========================================================
#  FUNCIÓN AUXILIAR PARA LLAMAR PROCEDIMIENTOS
# ==========================================================

def call_sp(nombre_sp, params=()):
    conexion = conectar()
    if not conexion:
        return None

    try:
        cursor = conexion.cursor()
        cursor.callproc(nombre_sp, params)
        conexion.commit()

        resultados = []
        for result in cursor.stored_results():
            resultados.extend(result.fetchall())

        cursor.close()
        conexion.close()
        return resultados

    except Error as e:
        print("Error ejecutando SP:", e)
        return None



# ==========================================================
#  GESTIÓN DE USUARIOS
# ==========================================================

def menu_usuarios():
    while True:
        print("\n=== MENÚ USUARIOS ===")
        print("1. Crear usuario")
        print("2. Ver usuario")
        print("3. Actualizar usuario")
        print("4. Eliminar usuario")
        print("0. Volver")

        opcion = input("Seleccione: ")

        if opcion == "1":
            crear_usuario()
        elif opcion == "2":
            ver_usuario()
        elif opcion == "3":
            actualizar_usuario()
        elif opcion == "4":
            eliminar_usuario()
        elif opcion == "0":
            break
        else:
            print("Opción inválida")


def crear_usuario():
    print("\n--- Crear Usuario ---")
    dni = input("DNI: ")
    nombre = input("Nombre: ")
    apellido = input("Apellido: ")
    email = input("Email: ")
    telefono = input("Teléfono: ")
    fecha_alta = input("Fecha alta (YYYY-MM-DD): ")
    estado = "activo"

    call_sp("CrearUsuario", (dni, nombre, apellido, email, telefono, fecha_alta, estado))
    print("Usuario creado correctamente.")


def ver_usuario():
    print("\n--- Ver Usuario ---")
    idu = input("ID usuario: ")

    datos = call_sp("VerUsuario", (idu,))
    if datos:
        print("\nID | DNI | Nombre | Apellido | Email | Teléfono | Alta | Estado")
        for fila in datos:
            print(fila)
    else:
        print("Usuario no encontrado.")


def actualizar_usuario():
    print("\n--- Actualizar Usuario ---")
    idu = input("ID usuario: ")

    dni = input("Nuevo DNI: ")
    nombre = input("Nuevo nombre: ")
    apellido = input("Nuevo apellido: ")
    email = input("Nuevo email: ")
    telefono = input("Nuevo teléfono: ")
    estado = input("Estado (activo/inactivo): ")

    call_sp("ActualizarUsuario", (idu, dni, nombre, apellido, email, telefono, estado))
    print("Usuario actualizado correctamente.")


def eliminar_usuario():
    print("\n--- Eliminar Usuario ---")
    idu = input("ID usuario: ")

    call_sp("EliminarUsuario", (idu,))
    print("Usuario eliminado (si no tenía préstamos ni pagos).")



# ==========================================================
#  GESTIÓN DE LIBROS
# ==========================================================

def menu_libros():
    while True:
        print("\n=== MENÚ LIBROS ===")
        print("1. Crear libro")
        print("2. Ver libro")
        print("3. Actualizar libro")
        print("4. Eliminar libro")
        print("0. Volver")

        opcion = input("Seleccione: ")

        if opcion == "1":
            crear_libro()
        elif opcion == "2":
            ver_libro()
        elif opcion == "3":
            actualizar_libro()
        elif opcion == "4":
            eliminar_libro()
        elif opcion == "0":
            break
        else:
            print("Opción inválida")


def crear_libro():
    print("\n--- Crear Libro ---")
    titulo = input("Título: ")
    autor = input("Autor: ")
    año = input("Año: ")
    genero = input("Género: ")
    disponible = 1

    call_sp("CrearLibro", (titulo, autor, año, genero, disponible))
    print("Libro creado correctamente.")


def ver_libro():
    print("\n--- Ver Libro ---")
    idl = input("ID libro: ")

    datos = call_sp("VerLibro", (idl,))
    if datos:
        print("ID | Título | Autor | Año | Género | Disponible")
        for fila in datos:
            print(fila)
    else:
        print("Libro no encontrado.")


def actualizar_libro():
    print("\n--- Actualizar Libro ---")
    idl = input("ID libro: ")

    titulo = input("Nuevo título: ")
    autor = input("Nuevo autor: ")
    año = input("Nuevo año: ")
    genero = input("Nuevo género: ")
    disponible = input("Disponible (1/0): ")

    call_sp("ActualizarLibro", (idl, titulo, autor, año, genero, disponible))
    print("Libro actualizado correctamente.")


def eliminar_libro():
    print("\n--- Eliminar Libro ---")
    idl = input("ID libro: ")

    call_sp("EliminarLibro", (idl,))
    print("Libro eliminado si no tenía préstamos asociados.")



# ==========================================================
#  PRÉSTAMOS
# ==========================================================

def registrar_prestamo():
    print("\n--- Registrar Préstamo ---")
    id_usuario = input("ID Usuario: ")
    id_libro = input("ID Libro: ")
    fecha_dev = input("Fecha estimada devolución (YYYY-MM-DD): ")

    call_sp("RegistrarPrestamo", (id_usuario, id_libro, fecha_dev))
    print("Préstamo registrado correctamente.")


def registrar_devolucion():
    print("\n--- Registrar Devolución ---")
    id_prestamo = input("ID Préstamo: ")
    fecha_real = input("Fecha de devolución REAL (YYYY-MM-DD): ")

    call_sp("RegistrarDevolucion", (id_prestamo, fecha_real))
    print("Devolución registrada correctamente.")


def mostrar_multa():
    print("\n--- Calcular Multa ---")
    idp = input("ID Préstamo: ")

    conexion = conectar()
    cursor = conexion.cursor()
    cursor.execute(f"SELECT fn_CalcularMulta({idp});")
    multa = cursor.fetchone()[0]
    cursor.close()
    conexion.close()

    print(f"La multa es: ${multa:.2f}")



# ==========================================================
#  PAGOS Y CUOTAS
# ==========================================================

def registrar_pago():
    print("\n--- Registrar Pago de Cuota ---")
    idu = input("ID Usuario: ")
    mes = input("Mes (1-12): ")
    año = input("Año: ")

    call_sp("RegistrarPago", (idu, mes, año))
    print("Pago registrado correctamente.")


def modificar_cuota():
    print("\n--- Modificar Cuota ---")
    mes = input("Mes (1-12): ")
    año = input("Año: ")
    nuevo = input("Nuevo monto: ")

    call_sp("ActualizarCuota", (mes, año, nuevo))
    print("Cuota modificada.")



# ==========================================================
#  BÚSQUEDAS
# ==========================================================

def buscar_usuarios():
    print("\n--- Buscar Usuarios ---")
    texto = input("Ingrese texto: ")

    datos = call_sp("BuscarUsuarios", (texto,))
    for fila in datos:
        print(fila)


def buscar_libros():
    print("\n--- Buscar Libros ---")
    texto = input("Ingrese texto: ")

    datos = call_sp("BuscarLibros", (texto,))
    for fila in datos:
        print(fila)



# ==========================================================
#  MOROSOS Y PROMEDIO
# ==========================================================

def mostrar_morosos():
    print("\n--- Mostrar Morosos ---")
    mes = input("Mes: ")
    año = input("Año: ")

    datos = call_sp("GenerarListadoMorosos", (mes, año))
    print("ID | Nombre | Apellido | Mes | Año")
    for fila in datos:
        print(fila)


def promedio_meses_adeudados():
    print("\n--- Promedio de meses adeudados ---")

    conexion = conectar()
    cursor = conexion.cursor()

    cursor.callproc("CalcularPromedioMesesAdeudados", [0])
    for r in cursor.stored_results():
        prom = r.fetchone()[0]

    cursor.close()
    conexion.close()

    print(f"Promedio de meses adeudados: {prom:.2f}")



# ==========================================================
#  MENÚ PRINCIPAL
# ==========================================================

def menu_principal():
    while True:
        print("\n==== SISTEMA BIBLIOTECA ====")
        print("1. Gestión de Usuarios")
        print("2. Gestión de Libros")
        print("3. Registrar Préstamo")
        print("4. Registrar Devolución")
        print("5. Calcular Multa")
        print("6. Registrar Pago")
        print("7. Modificar Cuota")
        print("8. Buscar Usuarios")
        print("9. Buscar Libros")
        print("10. Morosos")
        print("11. Promedio meses adeudados")
        print("0. Salir")

        opcion = input("Seleccione: ")

        if opcion == "1":
            menu_usuarios()
        elif opcion == "2":
            menu_libros()
        elif opcion == "3":
            registrar_prestamo()
        elif opcion == "4":
            registrar_devolucion()
        elif opcion == "5":
            mostrar_multa()
        elif opcion == "6":
            registrar_pago()
        elif opcion == "7":
            modificar_cuota()
        elif opcion == "8":
            buscar_usuarios()
        elif opcion == "9":
            buscar_libros()
        elif opcion == "10":
            mostrar_morosos()
        elif opcion == "11":
            promedio_meses_adeudados()
        elif opcion == "0":
            print("Saliendo...")
            break
        else:
            print("Opción inválida")



if __name__ == "__main__":
    menu_principal()
