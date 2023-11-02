import os
import openai
import json
import datetime
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
    print(f"Enviando consulta: {system_message} / {user_message}")
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
    print("Respuesta recibida")
    return response, request_params


# Definir cuántas veces ejecutar todo el script
num_iterations = 2

for i in range(num_iterations):
    print(f"Iteración {i + 1} de {num_iterations}")

    # Obtener la fecha y hora actual para incluirlas en el nombre del archivo de log
    current_datetime = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"chat_log_{current_datetime}_iter{i + 1}.json"

    # Inicializar una lista vacía para almacenar las entradas de log
    log_entries = []

    # Iterar a través de los mensajes del sistema y realizar una consulta para cada uno
    for step, system_message in enumerate(system_messages, start=1):
        response, request_params = make_query(system_message, user_message)
        response_content = response['choices'][0]['message']['content']

        # Crear un objeto de log para la consulta y respuesta actual
        log_entry = {
            "iteration": i + 1,
            "group": selected_group_key,
            "step": step,
            "request": request_params,
            "response": response['choices'][0]
        }

        # Añadir la entrada de log a la lista
        log_entries.append(log_entry)

        # Actualizar user_message para la próxima iteración
        user_message = response_content

    # Guardar la lista completa de entradas de log en un archivo JSON
    with open(filename, 'w') as file:
        print(f"Guardando log en {filename}")
        json.dump(log_entries, file, indent=2, ensure_ascii=False)

    print(f"Iteración {i + 1} completada\n{'-'*50}")

print("Proceso completado.")
