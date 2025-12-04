# biblioteca_app.py
from datetime import datetime, date
import modelo_usuario as mu
import modelo_libro as ml
import modelo_prestamo as mp
import modelo_pago as mg

def input_int(prompt, allow_empty=False):
    while True:
        v = input(prompt).strip()
        if allow_empty and v == "":
            return None
        try:
            return int(v)
        except:
            print("Ingresá un número válido.")

def menu_usuarios():
    while True:
        print("\n--- Gestión Usuarios ---")
        print("1 Agregar | 2 Ver todos | 3 Ver por ID | 4 Actualizar | 5 Eliminar | 0 Volver")
        op = input("-> ")
        if op == "1":
            nombre = input("Nombre: "); apellido = input("Apellido: ")
            direccion = input("Dirección: "); telefono = input("Teléfono: ")
            email = input("Email: ")
            try:
                uid = mu.agregar_usuario(nombre, apellido, direccion, telefono, email)
                print("Usuario creado con id:", uid)
            except Exception as e:
                print("Error:", e)
        elif op == "2":
            for u in mu.listar_usuarios():
                print(u)
        elif op == "3":
            idu = input_int("ID: ")
            print(mu.obtener_usuario(idu))
        elif op == "4":
            idu = input_int("ID: ")
            campos = {}
            nombre = input("Nombre (enter omitir): ").strip()
            if nombre: campos["nombre"]=nombre
            apellido = input("Apellido (enter omitir): ").strip()
            if apellido: campos["apellido"]=apellido
            direccion = input("Direccion (enter omitir): ").strip()
            if direccion: campos["direccion"]=direccion
            telefono = input("Telefono (enter omitir): ").strip()
            if telefono: campos["telefono"]=telefono
            email = input("Email (enter omitir): ").strip()
            if email: campos["email"]=email
            estado = input("Estado (activo/inactivo) (enter omitir): ").strip()
            if estado: campos["estado"]=estado
            try:
                ok = mu.actualizar_usuario(idu, **campos)
                print("Actualizado." if ok else "No actualizado.")
            except Exception as e:
                print("Error:", e)
        elif op == "5":
            idu = input_int("ID a eliminar: ")
            ok = mu.eliminar_usuario(idu)
            print("Eliminado." if ok else "No se pudo eliminar (puede tener préstamos activos).")
        else:
            break

def menu_libros():
    while True:
        print("\n--- Gestión Libros ---")
        print("1 Agregar | 2 Ver todos | 3 Ver por ID | 4 Actualizar | 5 Eliminar | 6 Buscar | 0 Volver")
        op = input("-> ")
        if op == "1":
            titulo = input("Título: "); editorial = input("Editorial: ")
            categoria = input("Categoría: "); autor = input("Autor: ")
            anio = input_int("Año publicación: ")
            total = input_int("Cantidad total: ")
            try:
                lid = ml.agregar_libro(titulo, editorial, categoria, autor, anio, total)
                print("Libro creado id:", lid)
            except Exception as e:
                print("Error:", e)
        elif op == "2":
            for l in ml.listar_libros():
                print(l)
        elif op == "3":
            idl = input_int("ID: ")
            print(ml.obtener_libro(idl))
        elif op == "4":
            idl = input_int("ID a actualizar: ")
            campos = {}
            titulo = input("Título (enter omitir): ").strip()
            if titulo: campos["titulo"]=titulo
            editorial = input("Editorial (enter omitir): ").strip()
            if editorial: campos["editorial"]=editorial
            categoria = input("Categoria (enter omitir): ").strip()
            if categoria: campos["categoria"]=categoria
            autor = input("Autor (enter omitir): ").strip()
            if autor: campos["autor"]=autor
            anio = input("Año (enter omitir): ").strip()
            if anio: campos["anio_publicacion"]=int(anio)
            total = input("Cantidad total (enter omitir): ").strip()
            if total: campos["cantidad_total"]=int(total)
            try:
                ok = ml.actualizar_libro(idl, **campos)
                print("Actualizado." if ok else "No actualizado.")
            except Exception as e:
                print("Error:", e)
        elif op == "5":
            idl = input_int("ID a eliminar: ")
            ok = ml.eliminar_libro(idl)
            print("Eliminado." if ok else "No se pudo eliminar (puede tener préstamos activos).")
        elif op == "6":
            t = input("Texto búsqueda: ")
            for r in ml.buscar_libros(t):
                print(r)
        else:
            break

def menu_prestamos():
    while True:
        print("\n--- Manejo de Préstamos ---")
        print("1 Crear préstamo | 2 Devolver | 3 Calcular multa | 4 Listar | 0 Volver")
        op = input("-> ")
        if op == "1":
            idu = input_int("ID usuario: "); idl = input_int("ID libro: ")
            dias = input_int("Plazo estimado (días): ")
            fecha_est = date.today().replace(day=date.today().day)  # para asegurar objeto date
            fecha_est = date.today()  # usar hoy + dias en procedimiento: p_fecha_estimada debe pasarse como DATE
            fecha_est = date.today().replace(day=date.today().day)  # redundante pero OK
            fecha_estimada = (date.today()).replace(day=date.today().day)  # usar DATE
            # pasamos fecha_estimada como date sumada
            from datetime import timedelta
            fecha_estimada = date.today() + timedelta(days=dias)
            try:
                last = mp.crear_prestamo(idu, idl, fecha_estimada)
                print("Préstamo creado, id estimado:", last)
            except Exception as e:
                print("Error:", e)
        elif op == "2":
            idp = input_int("ID préstamo: ")
            fdev = input("Fecha devolución (YYYY-MM-DD) [enter=hoy]: ").strip()
            if not fdev:
                fdev = date.today()
            else:
                fdev = datetime.strptime(fdev, "%Y-%m-%d").date()
            try:
                mp.devolver_prestamo(idp, fdev)
                print("Devolución registrada.")
            except Exception as e:
                print("Error:", e)
        elif op == "3":
            idp = input_int("ID préstamo: ")
            try:
                multa = mp.calcular_multa(idp)
                print("Multa:", multa)
            except Exception as e:
                print("Error:", e)
        elif op == "4":
            for p in mp.listar_prestamos():
                print(p)
        else:
            break

def menu_busqueda():
    while True:
        print("\n--- Búsqueda y Filtrado ---")
        print("1 Buscar libros | 2 Buscar usuarios | 0 Volver")
        op = input("-> ")
        if op == "1":
            t = input("Texto: ")
            for r in ml.buscar_libros(t):
                print(r)
        elif op == "2":
            t = input("Texto: ")
            for r in mu.buscar_usuarios(t):
                print(r)
        else:
            break

def menu_pagos():
    while True:
        print("\n--- Pagos y Morosos ---")
        print("1 Listar pagos | 2 Modificar cuota (mes/año) | 3 Reporte morosos | 0 Volver")
        op = input("-> ")
        if op == "1":
            for p in mg.listar_pagos():
                print(p)
        elif op == "2":
            idu = input_int("ID usuario: "); anio = input_int("Año: "); mes = input_int("Mes: ")
            monto = float(input("Nuevo monto: "))
            ok = mg.modificar_cuota_para_mes(idu, anio, mes, monto)
            print("Modificado." if ok else "No existe pago para ese usuario/mes/año.")
        elif op == "3":
            prom = mg.reporte_morosos_promedio_meses()
            print("Promedio meses antigüedad morosos:", prom)
        else:
            break

def main():
    print("=== SISTEMA DE GESTIÓN DE BIBLIOTECA ===")
    while True:
        print("\n1 Gestión Usuarios\n2 Gestión Libros\n3 Manejo Préstamos\n4 Búsqueda y Filtrado\n5 Pagos y Morosos\n0 Salir")
        op = input("-> ").strip()
        if op == "1":
            menu_usuarios()
        elif op == "2":
            menu_libros()
        elif op == "3":
            menu_prestamos()
        elif op == "4":
            menu_busqueda()
        elif op == "5":
            menu_pagos()
        elif op == "0":
            print("Chau.")
            break
        else:
            print("Opción inválida.")

if __name__ == "__main__":
    main()
