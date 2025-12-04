# modelo_usuario.py
from conexion import obtener_conexion
from datetime import date

def agregar_usuario(nombre, apellido, direccion, telefono, email, cuota_mensual=2500.00, cuota_al_dia=True, estado='activo'):
    conn = obtener_conexion()
    cur = conn.cursor()
    try:
        sql = """INSERT INTO usuarios (nombre, apellido, direccion, telefono, email, fecha_inscripcion, cuota_mensual, cuota_al_dia, estado)
                 VALUES (%s,%s,%s,%s,%s,CURDATE(),%s,%s,%s)"""
        cur.execute(sql, (nombre, apellido, direccion, telefono, email, cuota_mensual, cuota_al_dia, estado))
        conn.commit()
        return cur.lastrowid
    except Exception as e:
        conn.rollback()
        raise
    finally:
        cur.close(); conn.close()

def obtener_usuario(id_usuario):
    conn = obtener_conexion()
    cur = conn.cursor(dictionary=True)
    try:
        cur.execute("SELECT * FROM usuarios WHERE id_usuario=%s", (id_usuario,))
        return cur.fetchone()
    finally:
        cur.close(); conn.close()

def listar_usuarios():
    conn = obtener_conexion()
    cur = conn.cursor(dictionary=True)
    try:
        cur.execute("SELECT * FROM usuarios ORDER BY id_usuario")
        return cur.fetchall()
    finally:
        cur.close(); conn.close()

def actualizar_usuario(id_usuario, **kwargs):
    allowed = ["nombre","apellido","direccion","telefono","email","cuota_mensual","cuota_al_dia","estado"]
    parts=[]
    vals=[]
    for k,v in kwargs.items():
        if k in allowed:
            parts.append(f"{k}=%s")
            vals.append(v)
    if not parts:
        return False
    vals.append(id_usuario)
    sql = "UPDATE usuarios SET " + ", ".join(parts) + " WHERE id_usuario=%s"
    conn = obtener_conexion()
    cur = conn.cursor()
    try:
        cur.execute(sql, tuple(vals))
        conn.commit()
        return cur.rowcount>0
    except:
        conn.rollback()
        raise
    finally:
        cur.close(); conn.close()

def eliminar_usuario(id_usuario):
    conn = obtener_conexion()
    cur = conn.cursor()
    try:
        # verificar prestamos activos
        cur.execute("SELECT COUNT(*) FROM prestamos WHERE id_usuario=%s AND estado='activo'", (id_usuario,))
        if cur.fetchone()[0] > 0:
            return False
        cur.execute("DELETE FROM usuarios WHERE id_usuario=%s", (id_usuario,))
        conn.commit()
        return cur.rowcount>0
    except:
        conn.rollback()
        raise
    finally:
        cur.close(); conn.close()

def buscar_usuarios(texto):
    conn = obtener_conexion()
    cur = conn.cursor(dictionary=True)
    try:
        like = f"%{texto}%"
        cur.execute("SELECT * FROM usuarios WHERE nombre LIKE %s OR apellido LIKE %s OR email LIKE %s", (like,like,like))
        return cur.fetchall()
    finally:
        cur.close(); conn.close()
