import json
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


# Código para assistant_mode (pruebas)


def show_json(obj):
    print(json.loads(obj.model_dump_json()))


def wait_on_run(run, thread):
    while run.status == "queued" or run.status == "in_progress":
        run = client.beta.threads.runs.retrieve(
            thread_id=thread.id,
            run_id=run.id,
        )
        time.sleep(0.5)
    return run


# Creamos un assistant
assistant = client.beta.assistants.create(
    name="Math Tutor",
    instructions="Eres un tutor de matemáticas. Ayuda a resolver operaciones en una sola frase.",
    model="gpt-4-1106-preview",
)

# Creamos un hilo del assistant, que tendrá toda la conversación con el usuario
thread = client.beta.threads.create()

message = client.beta.threads.messages.create(
    thread_id=thread.id,
    role="user",
    content="Necesito resolver la ecuación 3x - 11 = 14. Por favor, ayúdame.",
)

# Un run es una conversación entre el assistant y el usuario, que se ejecuta en un hilo.
run = client.beta.threads.runs.create(
    thread_id=thread.id,
    assistant_id=assistant.id,
)

# Esperamos a que el run termine en un loop
run = wait_on_run(run, thread)

# Obtenemos la respuesta del assistant
messages = client.beta.threads.messages.list(thread_id=thread.id)

# iteramos sobre los mensajes del assistant

message = client.beta.threads.messages.create(
    thread_id=thread.id, role="user", content="me lo puedes explicar como a un niño de 5?"
)

run = client.beta.threads.runs.create(
    thread_id=thread.id,
    assistant_id=assistant.id,
)

wait_on_run(run, thread)

# Retrieve all the messages added after our last user message
messages = client.beta.threads.messages.list(
    thread_id=thread.id, order="asc", after=message.id
)
# show_json(messages)

# Extraemos la respuesta del asistente
value = json.loads(messages.model_dump_json())[
    'data'][0]['content'][0]['text']['value']
print(value)

# fin código assistant_mode (pruebas)-------------------------------------------------------


def chat_openai(response):
    # Se finaliza la consulta a la API
    return response.choices[0].message.content


def asisstant_openai(response):
    return response.choices[0].text  # a implementar...


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
        if config["asisstant_mode"]:
            respuesta = asisstant_openai(response)
        else:
            respuesta = chat_openai(response)
        print(f"Respuesta de la API: {respuesta}")
        api_response[0] = respuesta
    except Exception as e:
        print(f"Error en la llamada a la API de OpenAI: {e}")
        api_response[0] = None
    finally:
        time.sleep(config["wait_time_after_api"])
        api_call_in_progress[0] = False
