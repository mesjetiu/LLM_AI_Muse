# Asegúrate de importar los módulos y variables necesarios para las funciones

def set_api_on_off_command(api_enabled, new_state):
    """
    Activa o desactiva la API.
    :param api_enabled: Variable para controlar el estado de la API.
    :param new_state: Estado deseado para la API ('on' o 'off').
    :return: Estado actualizado de la API.
    """
    if new_state == "on":
        api_enabled = True
        print("API activada.")
    elif new_state == "off":
        api_enabled = False
        print("API desactivada.")
    else:
        print("Comando no reconocido. Introduce 'set api on' o 'set api off'.")
    return api_enabled

# Aquí puedes agregar otras funciones de comando, como cambiar la configuración del modelo, la temperatura, etc.

# Por ejemplo:


def set_model_command(model, new_model):
    model = new_model.strip()
    print(f"Modelo cambiado a {model}.")
    return model
