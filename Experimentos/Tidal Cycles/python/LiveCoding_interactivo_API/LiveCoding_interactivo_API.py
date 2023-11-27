import subprocess
import time
import datetime
import os
import sys
import json
from openai import OpenAI
# from apikey import API_KEY  # Importa la clave desde apikey.py
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler
from threading import Thread


running = True  # Condición de ejecución del script

# Variables para controlar el estado de la API
api_call_in_progress = False
api_response_pending = None

config = None
API_KEY = None

# Leer el archivo de configuración
with open('config.json', 'r') as config_file:
    config = json.load(config_file)

# Asignar variables desde el archivo de configuración
boot_tidal_path = config['boot_tidal_path']
api_enabled = config['api_enabled']
api_key_file = config['api_key_file']
model = config['model']
temperature = config['temperature']
max_tokens = config['max_tokens']
top_p = config['top_p']
frequency_penalty = config['frequency_penalty']
presence_penalty = config['presence_penalty']
wait_time_before_api = config['wait_time_before_api']
wait_time_after_api = config['wait_time_after_api']
system_prompt_file = config['system_prompt_file']

# Leer la clave API del archivo especificado
with open(api_key_file, 'r') as api_file:
    API_KEY = api_file.read().strip()


# Obtén la fecha y hora actual
current_datetime = datetime.datetime.now()

# Formatea la fecha y hora para el nombre del archivo
formatted_datetime = current_datetime.strftime("%Y.%m.%d_%H%M")
nombre_archivo_tidal = f"tidal_session_{formatted_datetime}.tidal"

# Crear el archivo si no existe
if not os.path.exists(nombre_archivo_tidal):
    open(nombre_archivo_tidal, 'w').close()

# Crear un archivo de log
log_filename = f"tidal_log_{datetime.datetime.now().strftime('%Y%m%d_%H%M%S')}.tidal"
open(log_filename, 'w').close()  # Crea el archivo si no existe

last_command_time = datetime.datetime.now()

# Crear el cliente de OpenAI
client = OpenAI(api_key=API_KEY)

# Leer el mensaje del sistema desde un archivo externo
with open(system_prompt_file, 'r') as file:
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


def iniciar_ghci():
    # Iniciar GHCi con el proceso de TidalCycles
    try:
        process = subprocess.Popen(["ghci"], stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                                   stderr=subprocess.PIPE, text=True, bufsize=1, universal_newlines=True)
    except Exception as e:
        print(f"Error al iniciar GHCi: {e}")
        sys.exit(1)

    return process


def iniciar_supercollider():
    # Iniciar sclang con el proceso de SuperCollider
    try:
        process_SC = subprocess.Popen(["sclang"], stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                                      stderr=subprocess.PIPE, text=True, bufsize=1, universal_newlines=True)
    except Exception as e:
        print(f"Error al iniciar SuperCollider: {e}")
        sys.exit(1)

    return process_SC


# Iniciar GHCi con el proceso de TidalCycles
process = iniciar_ghci()

# Iniciar sclang con el proceso de SuperCollider
process_SC = iniciar_supercollider()

# Función para registrar un comando en el archivo de log


def log_command(command):
    global last_command_time
    current_time = datetime.datetime.now()
    duration = int((current_time - last_command_time).total_seconds())
    with open(log_filename, 'a') as log_file:
        if duration > 0:
            log_file.write(f"{command} -- {duration} segundos\n")
        else:
            log_file.write(f"{command}\n")
    last_command_time = current_time

# Función para enviar un comando a TidalCycles a través de GHCi


def run_tidal_command(command):
    global process
    try:
        # Unir todas las líneas del patrón en una sola cadena
        full_command = ' '.join(command.split('\n'))
        print("Enviando comando a TidalCycles:", full_command)
        process.stdin.write(full_command + "\n")
        process.stdin.flush()
        log_command(full_command)
    except Exception as e:
        print(f"Error al enviar comando a TidalCycles: {e}")

# Función para enviar un comando a SuperCollider a través de sclang


def run_sclang_command(command):
    global process_SC
    # print("Enviando comando a SuperCollider:", command)
    process_SC.stdin.write(command + "\n")
    process_SC.stdin.flush()


# Inicializar TidalCycles
run_tidal_command(f":script {boot_tidal_path}")
# time.sleep(5)  # Esperar a que TidalCycles se inicialice

# Leer y almacenar la versión inicial del archivo de Tidal
with open(nombre_archivo_tidal, 'r') as file:
    original_content = file.read()


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


def quit_script_command():
    global running
    running = False


def restart_command(service):
    global process, process_SC
    if service == "ghci":
        if process is not None:
            # Terminar el proceso existente
            process.terminate()
            process.wait()  # Espera a que el proceso termine completamente
            process = iniciar_ghci()
            # Inicializar TidalCycles
            run_tidal_command(f":script {boot_tidal_path}")
            # time.sleep(5)  # Esperar a que TidalCycles se inicialice

    elif service == "sclang":
        run_sclang_command("thisProcess.shutdown;\n")
        run_sclang_command("0.exit;\n")
        # Espera hasta que sclang termine
        while process_SC.poll() is None:
            # Espera un breve momento antes de verificar de nuevo
            time.sleep(0.1)

        process_SC.stdin.close()
        process_SC.terminate()
        process_SC = iniciar_supercollider()
    else:
        print("Comando no reconocido. Introduce 'restart ghci' o 'restart sclang'.")
    print(f"Proceso {service} reiniciado.")


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
    "quit": quit_script_command,
    "restart": restart_command,
    "set model": set_model_command,
    "set temperature": set_temperature_command,
    "set max tokens": set_max_tokens_command,
    "set top p": set_top_p_command,
    "set frequency penalty": set_frequency_penalty_command,
    "set presence penalty": set_presence_penalty_command,
    "set wait time before api": set_wait_time_before_api_command,
    "set wait time after api": set_wait_time_after_api_command
}

# Función para dividir el contenido en bloques


def segment_into_blocks(content):
    blocks = set()
    lines = content.split('\n')
    current_block = []
    for line in lines:
        # Eliminar comentarios y espacios en blanco
        clean_line = line.split('--')[0].strip()
        if not clean_line:
            if current_block:
                blocks.add('\n'.join(current_block))
                current_block = []
            continue
        current_block.append(clean_line)

    if current_block:
        blocks.add('\n'.join(current_block))
    return blocks


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
        print(f"Respuesta de la API: {tidal_command}")

        global api_response_pending
        api_response_pending = response.choices[0].message.content

        # Esperar el tiempo establecido
        time.sleep(wait_time_after_api)

    except Exception as e:
        print(f"Error en la llamada a la API de OpenAI: {e}")
    finally:
        api_call_in_progress = False  # Se finaliza la consulta a la API


# Handler para evento de modificación de archivos

# Diccionario global para almacenar los bloques previos
# processed_blocks = set()


class MyHandler(FileSystemEventHandler):
    def __init__(self):
        self.last_modified = time.time()
        self.processed_blocks = set()

    def on_modified(self, event):
        global api_call_in_progress, api_response_pending, command_handlers, processed_blocks

        if time.time() - self.last_modified < 0.1:
            return

        if os.path.basename(event.src_path) == nombre_archivo_tidal:
            with open(event.src_path, 'r') as file:
                new_content = file.read()
            new_blocks = segment_into_blocks(new_content)

            # Procesar solo los bloques nuevos o modificados
            for block in new_blocks - self.processed_blocks:
                block_key = ' '.join(block.split('\n')[0].split()[:-1])
                block_args = block.split('\n')[0].split()[-1]

                # Verificar primero si el comando completo es conocido
                if block in command_handlers:
                    command_handlers[block]()
                # Luego verificar si la clave sin el último argumento es un comando conocido
                elif block_key in command_handlers and block_args:
                    command_handlers[block_key](block_args)
                else:
                    # Enviar a GHCi si no es un comando reconocido
                    run_tidal_command(block)
                    # print(f"Comando Tidal ejecutado: {command}")

            # Actualizar los bloques procesados
            self.processed_blocks = new_blocks

            # Si no hay una llamada a la API en curso, lanzar un nuevo hilo para la consulta
            if not api_call_in_progress and api_enabled:
                api_thread = Thread(
                    target=consult_openai_api, args=(new_content,))
                api_thread.start()

            if api_response_pending:
                time.sleep(0.2)
                with open(nombre_archivo_tidal, 'a') as file:
                    file.write('\n\n')
                    file.write(api_response_pending + f" -- {model}\n")
                api_response_pending = None

        self.last_modified = time.time()


# Configurar el observador
event_handler = MyHandler()
observer = Observer()
observer.schedule(event_handler, path='./', recursive=False)
observer.start()


# Bucle de ejecución
try:
    while running:
        time.sleep(1)
except KeyboardInterrupt:
    running = False

observer.stop()
observer.join()
# Cerrar el proceso de SuperCollider
run_sclang_command("thisProcess.shutdown;\n")
run_sclang_command("0.exit;\n")
# Espera hasta que sclang termine
while process_SC.poll() is None:
    # Espera un breve momento antes de verificar de nuevo
    time.sleep(0.1)
process_SC.stdin.close()
process_SC.terminate()
