import json


def cargar_configuracion(archivo_config):
    """
    Carga la configuración desde un archivo JSON.
    :param archivo_config: Ruta del archivo de configuración.
    :return: Un diccionario con la configuración.
    """
    try:
        with open(archivo_config, 'r') as config_file:
            config = json.load(config_file)
        return config
    except FileNotFoundError:
        print(f"Archivo de configuración {archivo_config} no encontrado.")
        return None
    except json.JSONDecodeError:
        print(
            f"Error al decodificar el archivo de configuración {archivo_config}.")
        return None


def guardar_configuracion(config, archivo_config):
    """
    Guarda la configuración actual en un archivo JSON.
    :param config: Diccionario con la configuración a guardar.
    :param archivo_config: Ruta del archivo de configuración.
    """
    try:
        with open(archivo_config, 'w') as config_file:
            json.dump(config, config_file, indent=4)
    except Exception as e:
        print(f"Error al guardar la configuración: {e}")
