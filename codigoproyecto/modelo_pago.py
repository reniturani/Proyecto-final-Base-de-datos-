# modelo_pago.py
from conexion import obtener_conexion
from datetime import date

def add_pago(id_usuario, anio, mes, monto, estado='pagado'):
    conn = obtener_conexion()
    cur = conn.cursor()
    try:
        cur.execute("INSERT INTO pagos (id_usuario, anio, mes, monto, estado) VALUES (%s,%s,%s,%s,%s)",
                    (id_usuario, anio, mes, monto, estado))
        conn.commit()
        return cur.lastrowid
    except Exception:
        conn.rollback()
        raise
    finally:
        cur.close(); conn.close()

def modificar_cuota_para_mes(id_usuario, anio, mes, nuevo_monto):
    conn = obtener_conexion()
    cur = conn.cursor()
    try:
        cur.execute("UPDATE pagos SET monto=%s WHERE id_usuario=%s AND anio=%s AND mes=%s",
                    (nuevo_monto, id_usuario, anio, mes))
        conn.commit()
        return cur.rowcount>0
    except:
        conn.rollback()
        raise
    finally:
        cur.close(); conn.close()

def listar_pagos():
    conn = obtener_conexion()
    cur = conn.cursor(dictionary=True)
    try:
        cur.execute("SELECT p.*, u.nombre, u.apellido FROM pagos p JOIN usuarios u ON p.id_usuario = u.id_usuario ORDER BY p.id_pago")
        return cur.fetchall()
    finally:
        cur.close(); conn.close()

def reporte_morosos_promedio_meses():
    """
    Promedio de meses de antigüedad de los socios que no estén al día.
    Consideramos moroso si cuota_al_dia = FALSE o tiene pagos pendientes/atrasados.
    """
    conn = obtener_conexion()
    cur = conn.cursor(dictionary=True)
    try:
        cur.execute("""
            SELECT u.id_usuario, u.fecha_inscripcion
            FROM usuarios u
            LEFT JOIN pagos p ON p.id_usuario = u.id_usuario AND p.estado IN ('pendiente','atrasado')
            WHERE u.cuota_al_dia = FALSE OR p.id_pago IS NOT NULL
            GROUP BY u.id_usuario
        """)
        rows = cur.fetchall()
        if not rows:
            return 0
        from datetime import date
        hoy = date.today()
        total_months = 0
        for r in rows:
            fi = r['fecha_inscripcion']
            months = (hoy.year - fi.year) * 12 + (hoy.month - fi.month)
            total_months += months
        promedio = total_months / len(rows)
        return round(promedio,2)
    finally:
        cur.close(); conn.close()
