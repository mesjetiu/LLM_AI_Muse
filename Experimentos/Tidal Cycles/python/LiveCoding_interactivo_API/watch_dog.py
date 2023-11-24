from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler
import time


class MyHandler(FileSystemEventHandler):
    def __init__(self):
        self.last_modified = time.time()

    def on_modified(self, event):
        if time.time() - self.last_modified < 1:  # Debounce por 1 segundo
            return
        if event.src_path.endswith(".tidal"):
            print(f"Archivo modificado: {event.src_path}")
            # Lógica de procesamiento aquí
        self.last_modified = time.time()


# Ruta al archivo de Tidal
path_to_watch = "Experimentos/Tidal Cycles/python/LiveCoding_interactivo_API/dummy.tidal"

# Configurar el observador
event_handler = MyHandler()
observer = Observer()
observer.schedule(event_handler, path=path_to_watch, recursive=False)
observer.start()

try:
    while True:
        # El bucle mantiene el script en ejecución para continuar monitoreando
        time.sleep(1)
except KeyboardInterrupt:
    observer.stop()

observer.join()
