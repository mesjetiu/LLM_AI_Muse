import os
import openai
import json
from apikey import API_KEY  # Importa la clave desde apikey.py

openai.api_key = API_KEY

# Leer los mensajes del sistema desde un archivo JSON
with open('system_messages.json', 'r') as file:
    system_messages = json.load(file)

system_message1 = system_messages['message1']
system_message2 = system_messages['message2']

# Definir los mensajes del usuario para ambas consultas
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


# Primera consulta
response1, request_params1 = make_query(system_message1, user_message)

response_content1 = response1['choices'][0]['message']['content']

# Segunda consulta
response2, request_params2 = make_query(
    system_message2, response_content1)

# Crear objetos de log para cada consulta y respuesta
log_entry1 = {
    "request": request_params1,
    "response": response1['choices'][0]
}

log_entry2 = {
    "request": request_params2,
    "response": response2['choices'][0]
}

# Nombre del archivo en el que se guardarán los registros
filename = "chat_log.json"

# Leer el archivo existente y deserializar el contenido a una lista
try:
    with open(filename, 'r') as file:
        log_entries = json.load(file)
except FileNotFoundError:
    log_entries = []  # Si el archivo no existe, iniciar una lista vacía

# Añadir las nuevas entradas de log a la lista
log_entries.extend([log_entry1, log_entry2])

# Guardar la lista completa de entradas de log en un archivo JSON
with open(filename, 'w') as file:
    json.dump(log_entries, file, indent=2, ensure_ascii=False)
