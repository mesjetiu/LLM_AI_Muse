import time
from openai import OpenAI
from threading import Thread
from config_manager import config

system_prompt = None
api_key = None


# Leer la clave API del archivo especificado
with open(config['api_key_file'], 'r') as api_file:
    api_key = api_file.read().strip()

# Crear el cliente de OpenAI
client = OpenAI(api_key=api_key)


# Leer el mensaje del sistema desde un archivo externo
with open(config['system_prompt_file'], 'r') as file:
    system_prompt = file.read()

# Mensajes iniciales para la conversación con OpenAI
messages = [
    {
        "role": "system",
        "content": system_prompt
    },
    {
        "role": "user",
        "content": ""
    }
]


def consult_openai_api(content, api_response, api_call_in_progress):
    time.sleep(config["wait_time_before_api"])
    try:
        print("Consultando API de OpenAI...")
        messages[1]["content"] = content
        response = client.chat.completions.create(
            model=config["model"],
            messages=messages,
            temperature=config["temperature"],
            max_tokens=config["max_tokens"],
            top_p=config["top_p"],
            frequency_penalty=config["frequency_penalty"],
            presence_penalty=config["presence_penalty"]
        )
        # Extraer el mensaje de respuesta de la API
        respuesta = response.choices[0].message.content
        print(f"Respuesta de la API: {respuesta}")
        api_response[0] = respuesta
    except Exception as e:
        print(f"Error en la llamada a la API de OpenAI: {e}")
        api_response[0] = None
    finally:
        time.sleep(config["wait_time_after_api"])
        api_call_in_progress[0] = False  # Se finaliza la consulta a la API
