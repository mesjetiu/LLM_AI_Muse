import subprocess
import time
import re

# Iniciar sclang con el proceso de SuperCollider
process = subprocess.Popen(["sclang"], stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                           stderr=subprocess.PIPE, text=True, bufsize=1, universal_newlines=True)

# Función para enviar un comando a SuperCollider a través de sclang


def run_sclang_command(command):
    print("Enviando comando a SuperCollider:", command)
    process.stdin.write(command + "\n")
    process.stdin.flush()

# Función para leer los comandos y duraciones de un archivo de texto


def read_sclang_commands_from_file(file_path):
    commands = []
    current_command = []
    duration = 0

    with open(file_path, 'r') as file:
        for line in file:
            stripped_line = line.strip()

            # Verificar si la línea es un comentario con duración
            if stripped_line.startswith("//"):
                match = re.search(r"- (\d+) segundos", stripped_line)
                if match:
                    # Combinar las líneas acumuladas en una sola línea
                    combined_command = ' '.join(current_command)
                    if combined_command:
                        commands.append(
                            {"code": combined_command, "duration": duration})
                    current_command = []
                    duration = int(match.group(1))
                continue

            # Acumular líneas de código que no son comentarios
            if stripped_line and not stripped_line.startswith("//"):
                current_command.append(stripped_line)

    # Agregar el último comando si hay alguno
    if current_command:
        combined_command = ' '.join(current_command)
        commands.append({"code": combined_command, "duration": duration})

    return commands


commands = read_sclang_commands_from_file(
    "./Experimentos/SuperCollider_Python/ej3.scd")

for command in commands:
    run_sclang_command(command["code"])
    print(f"Esperando {command['duration']} segundos...")
    time.sleep(command["duration"])

process.stdin.close()
process.terminate()
