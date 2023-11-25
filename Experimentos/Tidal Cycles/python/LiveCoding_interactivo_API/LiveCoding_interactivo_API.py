import subprocess
import time
import sys
from openai import OpenAI
from apikey import API_KEY  # Importa la clave desde apikey.py
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler
from threading import Thread

nombre_archivo_tidal = 'sesion.tidal'

api_call_in_progress = False
api_response_pending = None
api_enabled = False  # O True, dependiendo del estado inicial deseado

# Crear el cliente de OpenAI
client = OpenAI(api_key=API_KEY)

# Definir parámetros para las consultas a la API
model = "gpt-4-1106-preview"  # "gpt-3.5-turbo"  #
temperature = 1
max_tokens = 512
top_p = 1
frequency_penalty = 0
presence_penalty = 0
wait_time_before_api = 10  # Tiempo de espera mínimo antes de llamar a la API
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


def set_api_on_off_command(new_state):
    global api_enabled
    if new_state == "on":
        api_enabled = True
        print("API activada.")
    elif new_state == "off":
        api_enabled = False
        print("API desactivada.")
    else:
        print("Comando no reconocido. Introduce 'set api on' o 'set api off'.")
    print(f"API: {api_enabled}")


# def quit_script_command(new_state):
#     if new_state == "script":
#         print("Terminando la ejecución del script...")
#         observer.stop()
#         observer.join()
#         try:
#             # Enviar un comando de salida a GHCi si es necesario
#             # Por ejemplo: process.stdin.write(":quit\n")
#             process.terminate()
#         except Exception as e:
#             print(f"Error al cerrar GHCi: {e}")
#         sys.exit()


def api_on_command():
    global api_enabled
    api_enabled = True
    print("API activada.")


def api_off_command():
    global api_enabled
    api_enabled = False
    print("API desactivada.")


def set_model_command(new_model):
    global model
    model = new_model.strip()
    print(f"Modelo cambiado a {model}.")


def set_temperature_command(new_temperature):
    global temperature
    temperature = float(new_temperature.strip())
    print(f"Temperatura cambiada a {temperature}.")


def set_max_tokens_command(new_max_tokens):
    global max_tokens
    max_tokens = int(new_max_tokens.strip())
    print(f"Max tokens cambiado a {max_tokens}.")


def set_top_p_command(new_top_p):
    global top_p
    top_p = float(new_top_p.strip())
    print(f"Top P cambiado a {top_p}.")


def set_frequency_penalty_command(new_frequency_penalty):
    global frequency_penalty
    frequency_penalty = float(new_frequency_penalty.strip())
    print(f"Penalización de frecuencia cambiada a {frequency_penalty}.")


def set_presence_penalty_command(new_presence_penalty):
    global presence_penalty
    presence_penalty = float(new_presence_penalty.strip())
    print(f"Penalización de presencia cambiada a {presence_penalty}.")


def set_wait_time_before_api_command(new_wait_time):
    global wait_time_before_api
    wait_time_before_api = int(new_wait_time.strip())
    print(
        f"Tiempo de espera antes de la API cambiado a {wait_time_before_api} segundos.")


def set_wait_time_after_api_command(new_wait_time):
    global wait_time_after_api
    wait_time_after_api = int(new_wait_time.strip())
    print(
        f"Tiempo de espera después de la API cambiado a {wait_time_after_api} segundos.")


# Actualización del diccionario de comandos
command_handlers = {
    "set api": set_api_on_off_command,
    # "quit": quit_script_command,
    "set model": set_model_command,
    "set temperature": set_temperature_command,
    "set max tokens": set_max_tokens_command,
    "set top p": set_top_p_command,
    "set frequency penalty": set_frequency_penalty_command,
    "set presence penalty": set_presence_penalty_command,
    "set wait time before api": set_wait_time_before_api_command,
    "set wait time after api": set_wait_time_after_api_command
}


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
            if not api_call_in_progress and api_enabled:
                api_thread = Thread(
                    target=consult_openai_api, args=(new_content,))
                api_thread.start()

            # Ejecutar comandos nuevos y eliminar los antiguos
            for command in new_commands - original_commands:
                command_parts = command.split()
                command_key = ' '.join(command_parts[:-1])
                command_args = command_parts[-1] if len(
                    command_parts) > 1 else None

                # Verificar primero si el comando completo es conocido
                if command in command_handlers:
                    command_handlers[command]()
                # Luego verificar si la clave sin el último argumento es un comando conocido
                elif command_key in command_handlers and command_args:
                    command_handlers[command_key](command_args)
                else:
                    # Enviar a GHCi si no es un comando reconocido
                    run_tidal_command(command)
                    print(f"Tidal command executed: {command}")

            for command in original_commands - new_commands:
                if command not in command_handlers and ' '.join(command.split()[:-1]) not in command_handlers:
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
