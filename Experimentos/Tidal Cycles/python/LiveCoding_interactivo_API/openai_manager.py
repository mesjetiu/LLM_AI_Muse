import json
import os
import time
from openai import OpenAI
from threading import Thread
from config_manager import config
from command_functions import quit_script_command


class OpenAIManager:
    def __init__(self):
        global config
        self.api_key = self.leer_api_key()
        self.client = self.crear_cliente_openai(self.api_key)
        self.system_prompt = self.leer_system_prompt()
        self.assistant = None
        self.assistant_thread = None
        self.assistant_run = None
        self.retrieval_files = None

    def show_json(self, obj):
        print(json.loads(obj.model_dump_json()))

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
        files_names = []
        retrieval_files = []
        for name in os.listdir(directorio):
            ruta_completa = os.path.join(directorio, name)
            if os.path.isfile(ruta_completa):
                files_names.append(ruta_completa)

        for file_name in files_names:
            with open(file_name, "rb") as file_data:
                retrieval_file = self.client.files.create(
                    file=file_data,
                    purpose="assistants",
                )
                retrieval_files.append(retrieval_file.id)

        return retrieval_files

    def wait_on_run(self):
        while True:
            if self.assistant_run.status not in ["queued", "in_progress"]:
                break

            self.assistant_run = self.client.beta.threads.runs.retrieve(
                thread_id=self.assistant_thread.id,
                run_id=self.assistant_run.id,
            )
            time.sleep(0.5)

    def crear_hilo_assistant(self):
        self.assistant_thread = self.client.beta.threads.create()

    def crear_run_assistant(self):
        self.assistant_run = self.client.beta.threads.runs.create(
            thread_id=self.assistant_thread.id,
            assistant_id=self.assistant.id,
        )

    def crear_assistant(self, instructions):
        name = "SuperCollider Live Coder" if config[
            "mode_tidal_supercollider"] == "tidal" else "Tidal Cycles Live Coder"
        return self.client.beta.assistants.create(
            name=name,
            instructions=instructions,
            # instructions="Eres un profesor de matemáticas. Responde en una sola línea", # línea de prueba
            model=config["model"],
        )

    def consulta_assistant(self, assistant, content):
        if self.assistant is None:
            self.assistant = self.crear_assistant(self.system_prompt)
            print("creado asistente")
        if self.assistant_thread is None:
            self.crear_hilo_assistant()
            print("creado hilo")
        if self.retrieval_files is None:
            self.assistant = self.client.beta.assistants.update(
                self.assistant.id,
                tools=[{"type": "retrieval"}],
                file_ids=self.obtener_retrieval_files(),
            )
            self.show_json(self.assistant)

        message = self.client.beta.threads.messages.create(
            thread_id=self.assistant_thread.id,
            role="user",
            content=content,
        )
        print("mensaje enviado")
        self.crear_run_assistant()
        print("creado run")
        self.wait_on_run()
        print("después de run")
        messages = self.client.beta.threads.messages.list(
            thread_id=self.assistant_thread.id, order="asc", after=message.id
        )
        print("mensajes recibidos")
        value = json.loads(messages.model_dump_json())[
            'data'][0]['content'][0]['text']['value']
        return value

    def consulta_chat(self, content):
        messages = [{"role": "system", "content": self.system_prompt},
                    {"role": "user", "content": content}]
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
        try:
            print("Consultando API de OpenAI...")
            if config["bot_mode"] == "assistant":
                respuesta = self.consulta_assistant(self.assistant, content)
            elif config["bot_mode"] == "chat":
                respuesta = self.consulta_chat(content)
            print(f"Respuesta de la API: {respuesta}")
            api_response[0] = respuesta
        except Exception as e:
            print(f"Error en la llamada a la API de OpenAI: {e}")
            api_response[0] = None
        finally:
            api_call_in_progress[0] = False
