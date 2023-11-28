import subprocess
import datetime
from logger import log_command  # Asumiendo que crees un módulo logger.py


def iniciar_ghci(ghci_path):
    """
    Iniciar GHCi con el proceso de TidalCycles.
    :param ghci_path: Ruta al ejecutable de GHCi.
    :return: Proceso de GHCi.
    """
    try:
        process = subprocess.Popen([ghci_path], stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                                   stderr=subprocess.PIPE, text=True, bufsize=1, universal_newlines=True)
        return process
    except Exception as e:
        print(f"Error al iniciar GHCi: {e}")
        return None


def iniciar_supercollider(sclang_path):
    """
    Iniciar sclang con el proceso de SuperCollider.
    :param sclang_path: Ruta al ejecutable de sclang.
    :return: Proceso de SuperCollider.
    """
    try:
        process_SC = subprocess.Popen([sclang_path], stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                                      stderr=subprocess.PIPE, text=True, bufsize=1, universal_newlines=True)
        return process_SC
    except Exception as e:
        print(f"Error al iniciar SuperCollider: {e}")
        return None


def run_tidal_command(process, command, verbose=True, create_log_file=False, comentario="--"):
    """
    Enviar un comando a TidalCycles a través de GHCi.
    :param process: Proceso de GHCi.
    :param command: Comando a ejecutar.
    :param verbose: Si se imprime el comando.
    :param create_log_file: Si se registra el comando en el archivo de log.
    :param comentario: Símbolo de comentario para el log.
    """
    try:
        if verbose:
            print("Enviando comando a TidalCycles:", command)
        full_command = ' '.join(command.split('\n'))
        process.stdin.write(full_command + "\n")
        process.stdin.flush()
        if create_log_file:
            log_command(full_command, comentario)
    except Exception as e:
        print(f"Error al enviar comando a TidalCycles: {e}")


def run_sclang_command(process_SC, command, verbose=True, create_log_file=False, comentario="//"):
    """
    Enviar un comando a SuperCollider a través de sclang.
    :param process_SC: Proceso de SuperCollider.
    :param command: Comando a ejecutar.
    :param verbose: Si se imprime el comando.
    :param create_log_file: Si se registra el comando en el archivo de log.
    :param comentario: Símbolo de comentario para el log.
    """
    try:
        if verbose:
            print("Enviando comando a SuperCollider:", command)
        full_command = ' '.join(command.split('\n'))
        process_SC.stdin.write(full_command + "\n")
        process_SC.stdin.flush()
        if create_log_file:
            log_command(full_command, comentario)
    except Exception as e:
        print
