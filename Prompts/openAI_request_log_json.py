import os
import openai
import json
from apikey import API_KEY  # Importa la clave desde config.py

openai.api_key = API_KEY

messages = [
    {
        "role": "system",
        "content": "Eres experto en lo que se te pregunta."
    },
    {
        "role": "user",
        "content": "qué es la IA?"
    }
]

request_params = {
    "model": "gpt-4",
    "messages": messages,
    "temperature": 1,
    "max_tokens": 256,
    "top_p": 1,
    "frequency_penalty": 0,
    "presence_penalty": 0
}

response = openai.ChatCompletion.create(**request_params)

# Crear un objeto de log que incluye la solicitud y la respuesta
log_entry = {
    "request": request_params,
    "response": response['choices'][0]
}

# Nombre del archivo en el que se guardarán los registros
filename = "chat_log.json"

# Leer el archivo existente y deserializar el contenido a una lista
try:
    with open(filename, 'r') as file:
        log_entries = json.load(file)
except FileNotFoundError:
    log_entries = []  # Si el archivo no existe, iniciar una lista vacía

# Añadir la nueva entrada de log a la lista
log_entries.append(log_entry)

# Guardar la lista completa de entradas de log en un archivo JSON
with open(filename, 'w') as file:
    json.dump(log_entries, file, indent=2, ensure_ascii=False)
