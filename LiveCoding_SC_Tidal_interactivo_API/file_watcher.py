import time
from watchdog.events import FileSystemEventHandler
from sound_engine import run_tidal_command, run_sclang_command
from openai_manager import OpenAIManager
from command_functions import (
    set_api_on_off_command,
    quit_script_command,
    # restart_command,
    set_model_command,
    set_temperature_command,
    set_max_tokens_command,
    set_top_p_command,
    set_frequency_penalty_command,
    set_presence_penalty_command,
    set_wait_time_before_api_command,
    set_wait_time_after_api_command,
    set_bot_mode_command
    # ... (otros imports de funciones de comando)
)
import os
from threading import Thread
from logger import log_command


class MyHandler(FileSystemEventHandler):
    def __init__(self, process, process_SC, config, response_handler, nombre_archivo):
        self.last_modified = time.time()
        self.process = process
        self.process_SC = process_SC
        self.config = config
        self.response_handler = response_handler
        self.nombre_archivo = nombre_archivo
        self.processed_blocks = set()
        self.comentario = "--" if config['mode_tidal_supercollider'] == "tidal" else "//"
        self.api_call_in_progress = [False]
        self.api_response_pending = [None]
        self.openai_manager = OpenAIManager()

    def segment_into_blocks(self, content):
        blocks = set()
        lines = content.split('\n')
        current_block = []
        for line in lines:
            clean_line = line.split(self.comentario)[0].strip()
            if not clean_line:
                if current_block:
                    blocks.add('\n'.join(current_block))
                    current_block = []
                continue
            current_block.append(clean_line)
        if current_block:
            blocks.add('\n'.join(current_block))
        return blocks

    def on_modified(self, event):
        if time.time() - self.last_modified < 0.1:
            return

        if os.path.basename(event.src_path) == os.path.basename(self.nombre_archivo):
            with open(event.src_path, 'r') as file:
                new_content = file.read()
            new_blocks = self.segment_into_blocks(new_content)

            # Diccionario de manejadores de comandos
            command_handlers = {
                "set api": set_api_on_off_command,
                "quit": quit_script_command,
                # "restart": restart_command,
                "set model": set_model_command,
                "set temperature": set_temperature_command,
                "set max tokens": set_max_tokens_command,
                "set top p": set_top_p_command,
                "set frequency penalty": set_frequency_penalty_command,
                "set presence penalty": set_presence_penalty_command,
                "set wait time before api": set_wait_time_before_api_command,
                "set wait time after api": set_wait_time_after_api_command,
                "set bot mode": set_bot_mode_command
            }

            # Procesar solo los bloques nuevos o modificados
            for block in new_blocks - self.processed_blocks:
                block_key = ' '.join(block.split('\n')[0].split()[:-1])
                block_args = block.split('\n')[0].split()[-1]

                # Verificar primero si el comando completo es conocido
                if block in command_handlers:
                    command_handlers[block]()
                # Luego verificar si la clave sin el último argumento es un comando conocido
                elif block_key in command_handlers and block_args:
                    command_handlers[block_key](block_args)
                elif not self.config['only_system_commands']:
                    if self.config['mode_tidal_supercollider'] == "tidal":
                        run_tidal_command(self.process, block,
                                          self.config['create_log_file'])
                    elif self.config['mode_tidal_supercollider'] == "supercollider":
                        run_sclang_command(
                            self.process_SC, block, self.config['create_log_file'])
                    if self.config['create_log_file']:
                        log_command(block, self.comentario)

            # Actualizar los bloques procesados
            self.processed_blocks = new_blocks

            # Lógica para manejar las llamadas a la API de OpenAI
            if not self.api_call_in_progress[0] and self.config['api_enabled']:
                self.api_call_in_progress[0] = True
                api_thread = Thread(
                    target=self.openai_manager.consult_openai_api, args=(new_content, self.api_response_pending, self.api_call_in_progress))
                api_thread.start()

            # Procesar una respuesta pendiente de la API de OpenAI
            if self.api_response_pending[0]:
                time.sleep(0.2)
                with open(self.nombre_archivo, 'a') as file:
                    file.write('\n')
                    file.write(self.api_response_pending[0] +
                               f" {self.comentario} {self.config['model']}\n")
                self.api_response_pending[0] = None

        self.last_modified = time.time()
