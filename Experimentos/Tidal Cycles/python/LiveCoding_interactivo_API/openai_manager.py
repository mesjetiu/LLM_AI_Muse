import json
import os
import time
from openai import OpenAI
from threading import Thread
from config_manager import config
from command_functions import quit_script_command


class OpenAIManager:
    def __init__(self):
        self.api_key = self.leer_api_key()
        self.client = self.crear_cliente_openai(self.api_key)
        self.system_prompt = self.leer_system_prompt()
        self.assistant_thread = None
        self.retrieval_files = self.obtener_retrieval_files()

    def leer_api_key(self):
        with open(config['api_key_file'], 'r') as api_file:
            return api_file.read().strip()

    def leer_system_prompt(self):
        with open(config['system_prompt_file'], 'r') as file:
            return file.read()

    def crear_cliente_openai(self, api_key):
        return OpenAI(api_key=api_key)

    def obtener_retrieval_files(self):
        directorio = config['assistant_retrieval_folder']
        archivos = []
        for name in os.listdir(directorio):
            ruta_completa = os.path.join(directorio, name)
            if os.path.isfile(ruta_completa):
                archivos.append(ruta_completa)
        if not archivos:
            print(f"Error: El directorio '{directorio}' está vacío.")
            quit_script_command()
        return archivos

    def wait_on_run(self, run):
        while run.status == "queued" or run.status == "in_progress":
            run = self.client.beta.threads.runs.retrieve(
                thread_id=self.assistant_thread.id,
                run_id=run.id,
            )
            time.sleep(0.5)
        return run

    def crear_assistant(self, instructions):
        return self.client.beta.assistants.create(
            name="Math Tutor",
            instructions=instructions,
            model=config["model"],
        )

    def crear_hilo_assistant(self):
        self.assistant_thread = self.client.beta.threads.create()

    def consulta_assistant(self, assistant, content):
        if self.assistant_thread is None:
            self.crear_hilo_assistant()

        message = self.client.beta.threads.messages.create(
            thread_id=self.assistant_thread.id,
            role="user",
            content=content,
        )
        run = self.client.beta.threads.runs.create(
            thread_id=self.assistant_thread.id,
            assistant_id=assistant.id,
        )
        run = self.wait_on_run(run)
        messages = self.client.beta.threads.messages.list(
            thread_id=self.assistant_thread.id, order="asc", after=message.id
        )
        value = json.loads(messages.model_dump_json())[
            'data'][0]['content'][0]['text']['value']
        return value

    def consulta_chat(self, messages, content):
        messages[1]["content"] = content
        response = self.client.chat.completions.create(
            model=config["model"],
            messages=messages,
            temperature=config["temperature"],
            max_tokens=config["max_tokens"],
            top_p=config["top_p"],
            frequency_penalty=config["frequency_penalty"],
            presence_penalty=config["presence_penalty"]
        )
        return response.choices[0].message.content

    def consult_openai_api(self, content, api_response, api_call_in_progress):
        messages = [{"role": "system", "content": self.system_prompt},
                    {"role": "user", "content": ""}]

        try:
            print("Consultando API de OpenAI...")
            if config["bot_mode"] == "assistant":
                assistant = self.crear_assistant(self.system_prompt)
                respuesta = self.consulta_assistant(assistant, content)
            elif config["bot_mode"] == "chat":
                respuesta = self.consulta_chat(messages, content)
            print(f"Respuesta de la API: {respuesta}")
            api_response[0] = respuesta
        except Exception as e:
            print(f"Error en la llamada a la API de OpenAI: {e}")
            api_response[0] = None
        finally:
            api_call_in_progress[0] = False


# Uso de la clase
openai_manager = OpenAIManager()
# Ejemplo de uso: openai_manager.consult_openai_api(...)
