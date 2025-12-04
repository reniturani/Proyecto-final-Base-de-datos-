# modelo_libro.py
from conexion import obtener_conexion

def agregar_libro(titulo, editorial, categoria, autor, anio_publicacion, cantidad_total):
    conn = obtener_conexion()
    cur = conn.cursor()
    try:
        sql = """INSERT INTO libros (titulo, editorial, categoria, autor, anio_publicacion, cantidad_total, cantidad_disponible)
                 VALUES (%s,%s,%s,%s,%s,%s,%s)"""
        cur.execute(sql, (titulo, editorial, categoria, autor, anio_publicacion, cantidad_total, cantidad_total))
        conn.commit()
        return cur.lastrowid
    except:
        conn.rollback()
        raise
    finally:
        cur.close(); conn.close()

def obtener_libro(id_libro):
    conn = obtener_conexion()
    cur = conn.cursor(dictionary=True)
    try:
        cur.execute("SELECT * FROM libros WHERE id_libro=%s", (id_libro,))
        return cur.fetchone()
    finally:
        cur.close(); conn.close()

def listar_libros():
    conn = obtener_conexion()
    cur = conn.cursor(dictionary=True)
    try:
        cur.execute("SELECT * FROM libros ORDER BY id_libro")
        return cur.fetchall()
    finally:
        cur.close(); conn.close()

def buscar_libros(texto):
    conn = obtener_conexion()
    cur = conn.cursor(dictionary=True)
    try:
        like = f"%{texto}%"
        cur.execute("SELECT * FROM libros WHERE titulo LIKE %s OR autor LIKE %s OR categoria LIKE %s", (like,like,like))
        return cur.fetchall()
    finally:
        cur.close(); conn.close()

def actualizar_libro(id_libro, **kwargs):
    allowed = ["titulo","editorial","categoria","autor","anio_publicacion","cantidad_total"]
    parts=[]; vals=[]
    for k,v in kwargs.items():
        if k in allowed:
            parts.append(f"{k}=%s"); vals.append(v)
    if not parts:
        return False
    # Ajustar cantidad_disponible si se cambia cantidad_total
    conn = obtener_conexion()
    cur = conn.cursor()
    try:
        cur.execute("SELECT cantidad_total, cantidad_disponible FROM libros WHERE id_libro=%s", (id_libro,))
        row = cur.fetchone()
        if not row: return False
        old_total, old_disp = row
        if "cantidad_total" in kwargs:
            new_total = kwargs["cantidad_total"]
            diff = new_total - old_total
            new_disp = old_disp + diff
            if new_disp < 0:
                raise ValueError("No se puede reducir cantidad_total por debajo de préstamos activos.")
            parts.append("cantidad_disponible=%s"); vals.append(new_disp)
        vals.append(id_libro)
        sql = "UPDATE libros SET " + ", ".join(parts) + " WHERE id_libro=%s"
        cur.execute(sql, tuple(vals))
        conn.commit()
        return cur.rowcount>0
    except:
        conn.rollback()
        raise
    finally:
        cur.close(); conn.close()

def eliminar_libro(id_libro):
    conn = obtener_conexion()
    cur = conn.cursor()
    try:
        cur.execute("SELECT COUNT(*) FROM prestamos WHERE id_libro=%s AND estado='activo'", (id_libro,))
        if cur.fetchone()[0] > 0:
            return False
        cur.execute("DELETE FROM libros WHERE id_libro=%s", (id_libro,))
        conn.commit()
        return cur.rowcount>0
    except:
        conn.rollback()
        raise
    finally:
        cur.close(); conn.close()
