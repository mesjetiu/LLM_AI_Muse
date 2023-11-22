import subprocess
import time
import re

# Iniciar GHCi con el proceso de TidalCycles
process = subprocess.Popen(["ghci"], stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                           stderr=subprocess.PIPE, text=True, bufsize=1, universal_newlines=True)

# Función para enviar un comando a TidalCycles a través de GHCi


def run_tidal_command(command):
    print("Enviando comando:", command)
    process.stdin.write(command + "\n")
    process.stdin.flush()


# Inicializar TidalCycles
print("Inicializando TidalCycles...")
run_tidal_command(":script /usr/share/haskell-tidal/BootTidal.hs")
time.sleep(5)  # Esperar a que TidalCycles se inicialice

# Función para leer los comandos y duraciones de un archivo de texto


def read_tidal_commands_from_file(file_path):
    commands = []
    current_command = ""
    duration = 0

    with open(file_path, 'r') as file:
        for line in file:
            # Ignorar líneas vacías o que son solo comentarios
            if not line.strip() or line.strip().startswith("--"):
                continue

            # Agregar la línea al comando actual
            current_command += line.strip() + " "

            # Buscar la duración en el comentario
            match = re.search(r"-- (\d+)s", line)
            if match:
                duration = int(match.group(1))
                # Guardar el comando acumulado y la duración
                commands.append(
                    {"code": current_command, "duration": duration})
                # Resetear para el siguiente comando
                current_command = ""

    return commands


# Leer comandos y duraciones desde el archivo
commands = read_tidal_commands_from_file(
    "./Experimentos/Tidal Cycles/python/ej.tidal")

# Ejecutar cada comando en TidalCycles
for command in commands:
    run_tidal_command(command["code"])
    time.sleep(command["duration"])

# Detener todos los sonidos y resetear TidalCycles
run_tidal_command("hush")

# Esperar un momento para que el comando 'hush' surta efecto
time.sleep(2)

# Cerrar GHCi
process.stdin.close()
process.terminate()
