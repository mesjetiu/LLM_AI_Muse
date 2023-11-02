import os
import openai
from apikey import API_KEY  # Importa la clave desde apikey.py

openai.api_key = API_KEY


messages = [
    {
        "role": "system",
        "content": "Te diga lo que te diga User, siempre responde: \"Si, Guana\""
    },
    {
        "role": "user",
        "content": "hola, qué tal?"
    }
]

response = openai.ChatCompletion.create(
    model="gpt-4",
    messages=messages,
    temperature=1,
    max_tokens=256,
    top_p=1,
    frequency_penalty=0,
    presence_penalty=0
)

# Nombre del archivo en el que se guardarán los registros
filename = "chat_log.txt"

# Abre el archivo en modo 'a' (append), que añadirá contenido al final del archivo
with open(filename, 'a') as file:
    # Añadir los mensajes del usuario y del sistema
    for message in messages:
        role = message['role']
        content = message['content']
        file.write(f"{role}: {content}\n")

    # Añadir la respuesta del asistente
    assistant_message = response['choices'][0]['message']
    file.write(
        f"{assistant_message['role']}: {assistant_message['content']}\n")

    # Añade una línea divisoria para separar las sesiones
    file.write("\n" + "="*40 + "\n\n")
