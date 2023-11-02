# Autor: Carlos Arturo Guerra Parra
# Email: carlosarturoguerra@gmail
# Fecha: 2023/11/02
# Descripción: Script para realizar consultas al modelo de OpenAI y guardar los resultados en un archivo JSON. Los steps se definen manualmente.


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

# Leer los mensajes del usuario desde un archivo JSON
with open('user_messages.json', 'r') as file:
    all_user_messages = json.load(file)

# Seleccionar el mensaje del usuario que deseas usar
selected_user_key = "message1"  # o "message2" o "message3" para usar otros mensajes
user_message = all_user_messages[selected_user_key]

# Definir cuántas veces ejecutar todo el script
num_iterations = 2

# Definir el modelo a utilizar
model = "gpt-3.5-turbo-16k-0613"

# Definir los parámetros de la consulta
temperature = 1
max_tokens = 256
top_p = 1
frequency_penalty = 0
presence_penalty = 0

# Función para realizar una consulta al modelo


def make_query(system_message, user_message, model, temperature, max_tokens, top_p, frequency_penalty, presence_penalty):
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
    print(
        f"Respuesta recibida: {response['choices'][0]['message']['content']}")
    return response, request_params

# Función para procesar una iteración completa


def process_iteration(i, user_message):
    print(f"Iteración {i + 1} de {num_iterations}")

    # Obtener la fecha y hora actual para incluirlas en el nombre del archivo de log
    current_datetime = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"chat_log_{current_datetime}_iter{i + 1}.json"

    # Inicializar una lista vacía para almacenar las entradas de log
    log_entries = []

    # Consulta 1
    system_message1 = system_messages[0]
    response1, request_params1 = make_query(
        system_message1, user_message, model, temperature, max_tokens, top_p, frequency_penalty, presence_penalty)
    log_entry1 = {
        "iteration": i + 1,
        "group": selected_group_key,
        "step": 1,
        "request": request_params1,
        "response": response1['choices'][0]
    }
    log_entries.append(log_entry1)

    # Consulta 2
    system_message2 = system_messages[1]
    # Aquí puedes especificar manualmente el mensaje del usuario para la segunda consulta
    user_message2 = "Especificando manualmente el mensaje del usuario para la segunda consulta"
    response2, request_params2 = make_query(
        system_message2, user_message2, model, temperature, max_tokens, top_p, frequency_penalty, presence_penalty)
    log_entry2 = {
        "iteration": i + 1,
        "group": selected_group_key,
        "step": 2,
        "request": request_params2,
        "response": response2['choices'][0]
    }
    log_entries.append(log_entry2)

    # Guardar la lista completa de entradas de log en un archivo JSON
    with open(filename, 'w') as file:
        print(f"Guardando log en {filename}")
        json.dump(log_entries, file, indent=2, ensure_ascii=False)

    print(f"Iteración {i + 1} completada\n{'-'*50}")


# Procesar todas las iteraciones
for i in range(num_iterations):
    process_iteration(i, user_message)

print("Proceso completado.")
