import time
from watchdog.observers import Observer
# Importa los módulos adicionales que crearás
from file_watcher import MyHandler
from sound_engine import iniciar_supercollider, iniciar_ghci, run_sclang_command
from config_manager import cargar_configuracion


def main():
    # Cargar configuración y otros ajustes iniciales
    config = cargar_configuracion('config.json')

    # Inicializar procesos de TidalCycles o SuperCollider
    process_SC, process = None, None
    if config['mode_tidal_supercollider'] == "tidal":
        process = iniciar_ghci(config['ghci_path'])
    elif config['mode_tidal_supercollider'] == "supercollider":
        process_SC = iniciar_supercollider(config['sclang_path'])

    # Configurar y iniciar el observador de archivos
    event_handler = MyHandler(process, process_SC, config)
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
