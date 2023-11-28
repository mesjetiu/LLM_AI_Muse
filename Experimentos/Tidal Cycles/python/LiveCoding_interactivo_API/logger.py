import datetime


def log_command(log_filename, command, comentario):
    """
    Registra un comando en el archivo de log.
    :param log_filename: Nombre del archivo de log.
    :param command: Comando a registrar.
    :param comentario: Símbolo de comentario para el log.
    """
    current_time = datetime.datetime.now()
    with open(log_filename, 'a') as log_file:
        log_file.write(
            f"{current_time.strftime('%Y-%m-%d %H:%M:%S')} - {command} {comentario}\n")
