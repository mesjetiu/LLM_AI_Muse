import os
import openai
import json
from apikey import API_KEY  # Importa la clave desde config.py

openai.api_key = API_KEY

# Primera consulta
messages1 = [
    {
        "role": "system",
        "content": "Te diga lo que te diga User, siempre responde: \"Si, Guana\""
    },
    {
        "role": "user",
        "content": "hola, qué tal?"
    }
]

request_params1 = {
    "model": "gpt-3.5-turbo-16k-0613",
    "messages": messages1,
    "temperature": 1,
    "max_tokens": 256,
    "top_p": 1,
    "frequency_penalty": 0,
    "presence_penalty": 0
}

response1 = openai.ChatCompletion.create(**request_params1)
response_content1 = response1['choices'][0]['message']['content']

# Segunda consulta
messages2 = [
    {
        "role": "system",
        "content": "Ahora User responderá con un comentario sobre la respuesta anterior"
    },
    {
        "role": "user",
        "content": f"{response_content1}\n Es interesante, pero ¿cómo se relaciona con la música?"
    }
]

request_params2 = {
    "model": "gpt-3.5-turbo-16k-0613",
    "messages": messages2,
    "temperature": 1,
    "max_tokens": 256,
    "top_p": 1,
    "frequency_penalty": 0,
    "presence_penalty": 0
}

response2 = openai.ChatCompletion.create(**request_params2)

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
