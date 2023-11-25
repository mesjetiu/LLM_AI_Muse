import subprocess
import time
from openai import OpenAI
import json
import datetime
from apikey import API_KEY  # Importa la clave desde apikey.py
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler
from threading import Thread

nombre_archivo_tidal = 'sesion.tidal'

api_call_in_progress = False
api_response_pending = None

# Crear el cliente de OpenAI
client = OpenAI(api_key=API_KEY)

# Definir parámetros para las consultas a la API
model = "gpt-4-1106-preview"  # "gpt-3.5-turbo"  #
temperature = 1
max_tokens = 512
top_p = 1
frequency_penalty = 0
presence_penalty = 0
wait_time_before_api = 15  # Tiempo de espera mínimo antes de llamar a la API
wait_time_after_api = 30  # Tiempo de espera mínimo tras llamadas a la API

# Leer el mensaje del sistema desde un archivo externo
with open('system_prompt.txt', 'r') as file:
    system_prompt = file.read()

# Mensajes iniciales para la conversación con OpenAI
messages = [
    {
        "role": "system",
        "content": system_prompt
    },
    {
        "role": "user",
        "content": ""
    }
]

# Iniciar GHCi con el proceso de TidalCycles
try:
    process = subprocess.Popen(["ghci"], stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                               stderr=subprocess.PIPE, text=True, bufsize=1, universal_newlines=True)
except Exception as e:
    print(f"Error al iniciar GHCi: {e}")
    exit(1)

# Función para enviar un comando a TidalCycles a través de GHCi


def run_tidal_command(command):
    try:
        # Unir todas las líneas del patrón en una sola cadena
        full_command = ' '.join(command.split('\n'))
        print("Enviando comando a TidalCycles:", full_command)
        process.stdin.write(full_command + "\n")
        process.stdin.flush()
    except Exception as e:
        print(f"Error al enviar comando a TidalCycles: {e}")


# Inicializar TidalCycles
run_tidal_command(":script /usr/share/haskell-tidal/BootTidal.hs")
# time.sleep(5)  # Esperar a que TidalCycles se inicialice

# Leer y almacenar la versión inicial del archivo de Tidal
with open(nombre_archivo_tidal, 'r') as file:
    original_content = file.read()

# Función para dividir el contenido en patrones


def segment_into_patterns(content):
    patterns = {}
    current_pattern = None
    for line in content.split('\n'):
        # Separar comentarios del código del patrón
        pattern_part, _, comment_part = line.partition('--')
        clean_line = pattern_part.strip()

        # Ignorar líneas completamente vacías y finalizar el patrón actual
        if not clean_line:
            current_pattern = None
            continue

        if clean_line.startswith('d') and clean_line[1].isdigit() and ' $' in clean_line:
            # Utilizar toda la línea del patrón como clave
            current_pattern = clean_line
            patterns[current_pattern] = clean_line
        elif current_pattern:
            patterns[current_pattern] += '\n' + clean_line

    return patterns


# Función para identificar y almacenar comandos no-patrón

def segment_into_commands(content):
    commands = set()
    lines = content.split('\n')
    for i, line in enumerate(lines):
        # Eliminar comentarios y espacios en blanco
        clean_line = line.split('--')[0].strip()
        if not clean_line:
            continue

        # Comprobar si la línea es un comando (no comienza con 'dn')
        if not (clean_line.startswith('d') and clean_line[1].isdigit() and ' $' in clean_line):
            # Comprobar si la línea está rodeada por líneas vacías o comentarios
            prev_line = lines[i - 1].split('--')[0].strip() if i > 0 else ''
            next_line = lines[i +
                              1].split('--')[0].strip() if i < len(lines) - 1 else ''
            if not prev_line and not next_line:
                commands.add(clean_line)

    return commands


original_patterns = segment_into_patterns(original_content)
original_commands = segment_into_commands(original_content)


def consult_openai_api(content):
    global api_call_in_progress
    api_call_in_progress = True  # Se inicia una consulta a la API
    time.sleep(wait_time_before_api)
    try:
        print("Consultando API de OpenAI...")
        # Realizar consulta al modelo
        # Actualizar el mensaje del usuario con el contenido actual del archivo
        messages[1]["content"] = content
        response = client.chat.completions.create(
            model=model,
            messages=messages,
            temperature=temperature,
            max_tokens=max_tokens,
            top_p=top_p,
            frequency_penalty=frequency_penalty,
            presence_penalty=presence_penalty
        )

        # Extraer el mensaje de respuesta de la API
        tidal_command = response.choices[0].message.content
        # print(f"Respuesta de la API: {tidal_command}")

        global api_response_pending
        api_response_pending = response.choices[0].message.content

        # Esperar el tiempo establecido
        time.sleep(wait_time_after_api)

    except Exception as e:
        print(f"Error en la llamada a la API de OpenAI: {e}")
    finally:
        api_call_in_progress = False  # Se finaliza la consulta a la API


# Handler para evento de modificación de archivos


class MyHandler(FileSystemEventHandler):
    def __init__(self):
        self.last_modified = time.time()

    def on_modified(self, event):
        global original_patterns, original_commands, api_response_pending
        # Debounce para evitar múltiples disparos por guardar rápidamente
        if time.time() - self.last_modified < 1:
            return

        if event.src_path.endswith(".tidal"):
            with open(event.src_path, 'r') as file:
                new_content = file.read()
            new_patterns = segment_into_patterns(new_content)
            new_commands = segment_into_commands(new_content)

            # Ejecutar patrones modificados
            for pattern in new_patterns:
                if pattern not in original_patterns or new_patterns[pattern] != original_patterns[pattern]:
                    print(f"Patrón completo a enviar: {new_patterns[pattern]}")
                    run_tidal_command(new_patterns[pattern])

            # Si no hay una llamada a la API en curso, lanzar un nuevo hilo para la consulta
            if not api_call_in_progress:
                api_thread = Thread(
                    target=consult_openai_api, args=(new_content,))
                api_thread.start()

            # Ejecutar comandos nuevos y eliminar los antiguos
            for command in new_commands - original_commands:
                run_tidal_command(command)
                print(f"Tidal command executed: {command}")
            for command in original_commands - new_commands:
                print(f"Tidal command removed: {command}")

            original_patterns = new_patterns
            original_commands = new_commands

            if api_response_pending:
                time.sleep(0.2)
                with open(nombre_archivo_tidal, 'a') as file:
                    file.write('\n\n')
                    # Añade comentario con el nombre del modelo
                    file.write(api_response_pending + f" -- {model}\n")
                api_response_pending = None
            else:
                print("No hay respuesta de la API pendiente para escribir")

        self.last_modified = time.time()


# Configurar el observador
event_handler = MyHandler()
observer = Observer()
observer.schedule(event_handler, path='./', recursive=False)
observer.start()

# Resto del script para interactuar con GHCi y la API de OpenAI

# Detener el observador al terminar
try:
    while True:
        time.sleep(1)
except KeyboardInterrupt:
    observer.stop()
observer.join()
