import mysql.connector

# Conexión a MySQL
conexion = mysql.connector.connect(
    host="localhost",
    user="root",
    password="1234"   
)

cursor = conexion.cursor()

# Leer archivo SQL
with open("biblioteca.sql", "r", encoding="utf-8") as archivo:
    sql_script = archivo.read()

# Ejecutar múltiples sentencias
for sentencia in sql_script.split(";"):
    sentencia = sentencia.strip()
    if sentencia:
        cursor.execute(sentencia)

conexion.commit()
cursor.close()
conexion.close()

print("Base de datos creada correctamente.")
# Asegúrate de tener el archivo 'biblioteca.sql' en el mismo directorio que este script.