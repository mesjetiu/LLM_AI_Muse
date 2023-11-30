import time
import os
import datetime
from watchdog.observers import Observer
from file_watcher import MyHandler
from sound_engine import iniciar_supercollider, iniciar_ghci, run_sclang_command
from config_manager import config
from program_state import estado_programa


def response_handler(response):
    print("Respuesta de OpenAI:", response)


def main():

    # Obtén la fecha y hora actual
    current_datetime = datetime.datetime.now()

    # Formatea la fecha y hora para el nombre del archivo de código
    formatted_datetime = current_datetime.strftime("%Y.%m.%d_%H%M")
    # La 'extension' depende del modo (tidal o supercollider)
    extension = ".tidal" if config['mode_tidal_supercollider'] == "tidal" else ".scd"
    nombre_archivo = f"session_{formatted_datetime}{extension}"

    # Crear el archivo si no existe
    if not os.path.exists(nombre_archivo):
        open(nombre_archivo, 'w').close()
        print(f"Archivo creado: {nombre_archivo}")

    # Inicializar procesos de TidalCycles o SuperCollider
    process_SC, process = None, None
    # Iniciar el proceso de SuperCollider (se usa en ambos modos)

    process_SC = iniciar_supercollider(config['sclang_path'])
    if config['mode_tidal_supercollider'] == "tidal":
        process = iniciar_ghci(config['ghci_path'])

    # Configurar y iniciar el observador de archivos
    event_handler = MyHandler(
        process, process_SC, config, response_handler, nombre_archivo)
    observer = Observer()
    observer.schedule(event_handler, path='./', recursive=False)
    observer.start()

    # Bucle principal
    try:
        while estado_programa.is_running():
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
