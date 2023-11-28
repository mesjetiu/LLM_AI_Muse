import json

# Inicializa la variable de configuración global
config = {}


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


# Cargar configuración y otros ajustes iniciales
config = cargar_configuracion('config.json')
