import os
import openai
import json
from apikey import API_KEY  # Importa la clave desde apikey.py

openai.api_key = API_KEY

# Leer los mensajes del sistema desde un archivo JSON
with open('system_messages.json', 'r') as file:
    all_system_messages = json.load(file)

# Seleccionar el grupo de mensajes del sistema que deseas usar
selected_group_key = "group2"  # o "group2" para usar el otro grupo
system_messages = all_system_messages[selected_group_key]

# Definir el mensaje del usuario inicial
user_message = "hola, qué tal?"

# Función para realizar una consulta al modelo


def make_query(system_message, user_message, model="gpt-3.5-turbo-16k-0613", temperature=1, max_tokens=256, top_p=1, frequency_penalty=0, presence_penalty=0):
    messages = [
        {
            "role": "system",
            "content": system_message
        },
        {
            "role": "user",
            "content": user_message
        }
    ]
    request_params = {
        "model": model,
        "messages": messages,
        "temperature": temperature,
        "max_tokens": max_tokens,
        "top_p": top_p,
        "frequency_penalty": frequency_penalty,
        "presence_penalty": presence_penalty
    }
    response = openai.ChatCompletion.create(**request_params)
    # Devuelve la respuesta completa y los parámetros de la solicitud
    return response, request_params


# Inicializar una lista vacía para almacenar las entradas de log
log_entries = []

# Iterar a través de los mensajes del sistema y realizar una consulta para cada uno
for system_message in system_messages:
    response, request_params = make_query(system_message, user_message)
    response_content = response['choices'][0]['message']['content']

    # Crear un objeto de log para la consulta y respuesta actual
    log_entry = {
        "request": request_params,
        "response": response['choices'][0]
    }

    # Añadir la entrada de log a la lista
    log_entries.append(log_entry)

    # Actualizar user_message para la próxima iteración
    user_message = response_content

# Nombre del archivo en el que se guardarán los registros
filename = "chat_log.json"

# Leer el archivo existente y deserializar el contenido a una lista
try:
    with open(filename, 'r') as file:
        existing_log_entries = json.load(file)
except FileNotFoundError:
    existing_log_entries = []  # Si el archivo no existe, iniciar una lista vacía

# Añadir las nuevas entradas de log a la lista
existing_log_entries.extend(log_entries)

# Guardar la lista completa de entradas de log en un archivo JSON
with open(filename, 'w') as file:
    json.dump(existing_log_entries, file, indent=2, ensure_ascii=False)
