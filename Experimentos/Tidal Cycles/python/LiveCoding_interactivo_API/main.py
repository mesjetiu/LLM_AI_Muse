import time
import os
import datetime
from watchdog.observers import Observer
from file_watcher import MyHandler
from sound_engine import iniciar_supercollider, iniciar_ghci, run_sclang_command
from config_manager import config
from openai import OpenAI


def response_handler(response):
    print("Respuesta de OpenAI:", response)


def main():

    # Obtén la fecha y hora actual
    current_datetime = datetime.datetime.now()

    # Formatea la fecha y hora para el nombre del archivo
    formatted_datetime = current_datetime.strftime("%Y.%m.%d_%H%M")
    # Suponiendo que el 'extension' depende del modo (tidal o supercollider)
    extension = ".tidal" if config['mode_tidal_supercollider'] == "tidal" else ".scd"
    nombre_archivo = f"sc_session_{formatted_datetime}{extension}"

    # Crear el archivo si no existe
    if not os.path.exists(nombre_archivo):
        open(nombre_archivo, 'w').close()
        print(f"Archivo creado: {nombre_archivo}")

    # Leer la clave API del archivo especificado
    with open(config['api_key_file'], 'r') as api_file:
        api_key = api_file.read().strip()

    # Crear el cliente de OpenAI
    client = OpenAI(api_key=api_key)

    # Leer el mensaje del sistema desde un archivo externo
    with open(config['system_prompt_file'], 'r') as file:
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

    # Inicializar procesos de TidalCycles o SuperCollider
    process_SC, process = None, None
    if config['mode_tidal_supercollider'] == "tidal":
        process = iniciar_ghci(config['ghci_path'])
    elif config['mode_tidal_supercollider'] == "supercollider":
        process_SC = iniciar_supercollider(config['sclang_path'])

    # Configurar y iniciar el observador de archivos
    event_handler = MyHandler(
        process, process_SC, config, client, messages, response_handler, nombre_archivo)
    observer = Observer()
    observer.schedule(event_handler, path='./', recursive=False)
    observer.start()

    # Bucle principal
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        # Manejo de la señal de salida
        observer.stop()
        if process_SC:
            run_sclang_command(
                process_SC, "thisProcess.shutdown;\n", verbose=False)
            run_sclang_command(process_SC, "0.exit;\n", verbose=False)
        print("Cerrando el programa...")
        observer.join()


if __name__ == "__main__":
    main()
