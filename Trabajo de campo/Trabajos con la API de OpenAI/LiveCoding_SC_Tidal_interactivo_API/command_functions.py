# command_functions.py
from program_state import estado_programa
from config_manager import config


def set_api_on_off_command(new_state=None):
    if new_state == "on":
        config["api_enabled"] = True
        print("API activada.")
    elif new_state == "off":
        config["api_enabled"] = False
        print("API desactivada.")
    else:
        print("Comando no reconocido. Introduce 'set api on' o 'set api off'.")


# def restart_command(service, process, process_SC, iniciar_ghci, run_tidal_command, boot_tidal_path, iniciar_supercollider):
#     if service == "ghci":
#         if process is not None:
#             process.terminate()
#             process.wait()
#             process = iniciar_ghci()
#             run_tidal_command(process, f":script {boot_tidal_path}")
#             print(f"Proceso GHCI reiniciado.")
#         else:
#             print("No se puede reiniciar el proceso. GHCI no se ha iniciado previamente.")
#     elif service == "sclang":
#         if process_SC is not None:
#             run_sclang_command(process_SC, "thisProcess.shutdown;\n")
#             run_sclang_command(process_SC, "0.exit;\n")
#             while process_SC.poll() is None:
#                 time.sleep(0.1)
#             process_SC.stdin.close()
#             process_SC.terminate()
#             process_SC = iniciar_supercollider()
#             print(f"Proceso sclang reiniciado.")
#         else:
#             print(
#                 "No se puede reiniciar el proceso. SuperCollider no se ha iniciado previamente.")
#     else:
#         print("Comando no reconocido. Introduce 'restart ghci' o 'restart sclang'.")


def set_model_command(new_model=None):
    config["model"] = new_model.strip()
    print(f"Modelo cambiado a {config['model']}.")


def set_bot_mode_command(new_bot_mode=None):
    config["bot_mode"] = new_bot_mode.strip()
    print(f"Bot mode cambiado a {config['bot_mode']}.")


def set_temperature_command(new_temperature=None):
    config["temperature"] = float(new_temperature.strip())
    print(f"Temperatura cambiada a {config['temperature']}.")


def set_max_tokens_command(new_max_tokens=None):
    config["max_tokens"] = int(new_max_tokens.strip())
    print(f"Max tokens cambiado a {config['max_tokens']}.")


def set_top_p_command(new_top_p=None):
    config["top_p"] = float(new_top_p.strip())
    print(f"Top P cambiado a {config['top_p']}.")


def set_frequency_penalty_command(new_frequency_penalty=None):
    config["frequency_penalty"] = float(new_frequency_penalty.strip())
    print(
        f"Penalización de frecuencia cambiada a {config['frequency_penalty']}.")


def set_presence_penalty_command(new_presence_penalty=None):
    config["presence_penalty"] = float(new_presence_penalty.strip())
    print(
        f"Penalización de presencia cambiada a {config['presence_penalty']}.")


def set_wait_time_before_api_command(new_wait_time=None):
    config["wait_time_before_api"] = int(new_wait_time.strip())
    print(
        f"Tiempo de espera antes de la API cambiado a {config['wait_time_before_api']} segundos.")


def set_wait_time_after_api_command(new_wait_time=None):
    config["wait_time_after_api"] = int(new_wait_time.strip())
    print(
        f"Tiempo de espera después de la API cambiado a {config['wait_time_after_api']} segundos.")


def quit_script_command():
    estado_programa.stop()
    print("Saliendo del script...")
