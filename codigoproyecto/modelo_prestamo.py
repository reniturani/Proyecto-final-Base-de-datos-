# modelo_prestamo.py
from conexion import obtener_conexion
from datetime import date

def crear_prestamo(id_usuario, id_libro, fecha_estimada):
    conn = obtener_conexion()
    cur = conn.cursor()
    try:
        # Llamar al procedimiento almacenado
        cur.callproc('sp_crear_prestamo', (id_usuario, id_libro, fecha_estimada))
        conn.commit()
        # obtener last insert id (no directo con callproc): hacemos select del ultimo prestamo para este usuario/libro reciente
        cur.execute("SELECT LAST_INSERT_ID()")
        last = cur.fetchone()[0]
        return last
    except Exception as e:
        conn.rollback()
        raise
    finally:
        cur.close(); conn.close()

def devolver_prestamo(id_prestamo, fecha_devolucion):
    conn = obtener_conexion()
    cur = conn.cursor()
    try:
        cur.callproc('sp_devolver_prestamo', (id_prestamo, fecha_devolucion))
        conn.commit()
    except Exception as e:
        conn.rollback()
        raise
    finally:
        cur.close(); conn.close()

def calcular_multa(id_prestamo, fecha_ref=None):
    conn = obtener_conexion()
    cur = conn.cursor()
    try:
        if fecha_ref is None:
            fecha_ref = date.today()
        cur.execute("SELECT fn_calcular_multa(%s, %s)", (id_prestamo, fecha_ref))
        return cur.fetchone()[0]
    finally:
        cur.close(); conn.close()

def listar_prestamos():
    conn = obtener_conexion()
    cur = conn.cursor(dictionary=True)
    try:
        cur.execute("""SELECT p.*, u.nombre, u.apellido, l.titulo
                       FROM prestamos p
                       JOIN usuarios u ON p.id_usuario = u.id_usuario
                       JOIN libros l ON p.id_libro = l.id_libro
                       ORDER BY p.id_prestamo""")
        return cur.fetchall()
    finally:
        cur.close(); conn.close()
