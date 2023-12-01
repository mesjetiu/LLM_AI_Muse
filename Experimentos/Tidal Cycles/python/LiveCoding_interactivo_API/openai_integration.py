import json
import os
import time
from openai import OpenAI
from threading import Thread
from config_manager import config
from command_functions import quit_script_command

# Funciones de configuración inicial


def leer_api_key():
    with open(config['api_key_file'], 'r') as api_file:
        return api_file.read().strip()


def leer_system_prompt():
    with open(config['system_prompt_file'], 'r') as file:
        return file.read()


def crear_cliente_openai(api_key):
    return OpenAI(api_key=api_key)

# Funciones para manejo de assistant


def obtener_retrieval_files():
    global config
    directorio = config['assistant_retrieval_folder']

    archivos = []
    for name in os.listdir(directorio):
        ruta_completa = os.path.join(directorio, name)
        if os.path.isfile(ruta_completa):
            archivos.append(ruta_completa)

    # Comprobar si el directorio está vacío
    if not archivos:
        print(f"Error: El directorio '{directorio}' está vacío.")
        quit_script_command()

    return archivos


archivos = obtener_retrieval_files()

if archivos is not None:
    print(archivos)
else:
    print("El programa terminará debido a un error.")
    quit_script_command()


# Función de espera para runs


def wait_on_run(run, thread, client):
    while run.status == "queued" or run.status == "in_progress":
        run = client.beta.threads.runs.retrieve(
            thread_id=thread.id,
            run_id=run.id,
        )
        time.sleep(0.5)
    return run


def crear_assistant(client, instructions):
    return client.beta.assistants.create(
        name="Math Tutor",
        instructions=instructions,
        model=config["model"],
    )


# Creación y manejo del hilo del assistant
assistant_thread = None


def crear_hilo_assistant(client):
    global assistant_thread
    assistant_thread = client.beta.threads.create()


def consulta_assistant(client, assistant, content):
    global assistant_thread
    if assistant_thread is None:
        crear_hilo_assistant(client)

    message = client.beta.threads.messages.create(
        thread_id=assistant_thread.id,
        role="user",
        content=content,
    )
    run = client.beta.threads.runs.create(
        thread_id=assistant_thread.id,
        assistant_id=assistant.id,
    )
    run = wait_on_run(run, assistant_thread, client)
    messages = client.beta.threads.messages.list(
        thread_id=assistant_thread.id, order="asc", after=message.id
    )
    value = json.loads(messages.model_dump_json())[
        'data'][0]['content'][0]['text']['value']
    return value


# Funciones para manejo de chat


def consulta_chat(client, messages, content):
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
    return response.choices[0].message.content

# Función principal de consulta


def consult_openai_api(content, api_response, api_call_in_progress):
    api_key = leer_api_key()
    client = crear_cliente_openai(api_key)
    system_prompt = leer_system_prompt()
    messages = [{"role": "system", "content": system_prompt},
                {"role": "user", "content": ""}]

    try:
        print("Consultando API de OpenAI...")
        if config["bot_mode"] == "assistant":
            assistant = crear_assistant(client, system_prompt)
            respuesta = consulta_assistant(client, assistant, content)
        else:
            respuesta = consulta_chat(client, messages, content)
        print(f"Respuesta de la API: {respuesta}")
        api_response[0] = respuesta
    except Exception as e:
        print(f"Error en la llamada a la API de OpenAI: {e}")
        api_response[0] = None
    finally:
        api_call_in_progress[0] = False
