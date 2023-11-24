import subprocess
import time
from openai import OpenAI
import json
import datetime
from apikey import API_KEY  # Importa la clave desde apikey.py
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler
from threading import Thread

nombre_archivo_tidal = 'dummy.tidal'

api_call_in_progress = False

# Crear el cliente de OpenAI
client = OpenAI(api_key=API_KEY)

# Definir parámetros para las consultas a la API
model = "gpt-4-1106-preview"
temperature = 1
max_tokens = 512
top_p = 1
frequency_penalty = 0
presence_penalty = 0
wait_time = 15  # Tiempo de espera mínimo entre llamadas a la API
iterations = 5  # Número de iteraciones

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
        "content": "Comienza la sesión. Dame el primer patrón."
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
        print("Enviando comando a TidalCycles:", command)
        process.stdin.write(command + "\n")
        process.stdin.flush()
    except Exception as e:
        print(f"Error al enviar comando a TidalCycles: {e}")


# Inicializar TidalCycles
run_tidal_command(":script /usr/share/haskell-tidal/BootTidal.hs")
time.sleep(5)  # Esperar a que TidalCycles se inicialice

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
            current_pattern = clean_line.split(' $')[0]
            patterns[current_pattern] = clean_line
        elif current_pattern:
            patterns[current_pattern] += '\n' + clean_line

    return patterns

# Función para identificar y almacenar comandos no-patrón


def segment_into_commands(content, patterns):
    commands = set()
    for line in content.split('\n'):
        clean_line = line.split('--')[0].strip()
        if not clean_line or clean_line in patterns.values():
            continue
        commands.add(clean_line)
    return commands


original_patterns = segment_into_patterns(original_content)
original_commands = segment_into_commands(original_content, original_patterns)


def consult_openai_api(content):
    global api_call_in_progress
    api_call_in_progress = True  # Se inicia una consulta a la API
    try:
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
        print(f"Respuesta de la API: {tidal_command}")

        # Esperar el tiempo establecido
        time.sleep(wait_time)

    except Exception as e:
        print(f"Error en la llamada a la API de OpenAI: {e}")
    finally:
        api_call_in_progress = False  # Se finaliza la consulta a la API


# Handler para evento de modificación de archivos


class MyHandler(FileSystemEventHandler):
    def __init__(self):
        self.last_modified = time.time()

    def on_modified(self, event):
        global original_patterns, original_commands
        # Debounce para evitar múltiples disparos por guardar rápidamente
        if time.time() - self.last_modified < 1:
            return

        if event.src_path.endswith(".tidal"):
            with open(event.src_path, 'r') as file:
                new_content = file.read()
            new_patterns = segment_into_patterns(new_content)
            new_commands = segment_into_commands(new_content, new_patterns)

            # Ejecutar patrones modificados
            for pattern in new_patterns:
                if pattern not in original_patterns or new_patterns[pattern] != original_patterns[pattern]:
                    run_tidal_command(new_patterns[pattern])
                    print(f"Tidal: {pattern}\n{new_patterns[pattern]}")

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
