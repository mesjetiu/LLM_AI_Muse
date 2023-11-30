import datetime
from config_manager import config
import os

if config['create_log_file'] == "true":
    # Obtén la fecha y hora actual
    current_datetime = datetime.datetime.now()

    # Formatea la fecha y hora para el nombre del archivo de log
    formatted_datetime = current_datetime.strftime("%Y.%m.%d_%H%M")
    # La 'extension' depende del modo (tidal o supercollider)
    extension = ".tidal" if config['mode_tidal_supercollider'] == "tidal" else ".scd"
    log_filename = f"log_{formatted_datetime}{extension}"

    # Crear el archivo si no existe
    if not os.path.exists(log_filename):
        open(log_filename, 'w').close()
        print(f"Archivo creado: {log_filename}")


def log_command(command, comentario):
    """
    Registra un comando en el archivo de log.
    :param log_filename: Nombre del archivo de log.
    :param command: Comando a registrar.
    :param comentario: Símbolo de comentario para el log.
    """
    global log_filename
    current_time = datetime.datetime.now()
    with open(log_filename, 'a') as log_file:
        log_file.write(
            f"{current_time.strftime('%Y-%m-%d %H:%M:%S')} - {command} {comentario}\n")
