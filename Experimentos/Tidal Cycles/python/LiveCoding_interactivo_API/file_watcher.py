import time
from watchdog.events import FileSystemEventHandler
from sound_engine import run_tidal_command, run_sclang_command
from openai_integration import start_api_thread
import os


class MyHandler(FileSystemEventHandler):
    def __init__(self, process, process_SC, config, client, messages, response_handler, nombre_archivo):
        self.last_modified = time.time()
        self.process = process
        self.process_SC = process_SC
        self.config = config
        self.client = client
        self.messages = messages
        self.response_handler = response_handler
        self.nombre_archivo = nombre_archivo
        self.processed_blocks = set()
        self.comentario = "--" if config['mode_tidal_supercollider'] == "tidal" else "//"

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
        print("Archivo modificado detectado")  # Agregar para el seguimiento
        if time.time() - self.last_modified < 0.1:
            return

        if os.path.basename(event.src_path) == os.path.basename(self.nombre_archivo):
            with open(event.src_path, 'r') as file:
                new_content = file.read()
            new_blocks = self.segment_into_blocks(new_content)

            for block in new_blocks - self.processed_blocks:
                # Agregar para el seguimiento
                print(f"Procesando bloque: {block}")
                if self.config['mode_tidal_supercollider'] == "tidal":
                    run_tidal_command(
                        self.process, block, self.config['create_log_file'], self.comentario)
                elif self.config['mode_tidal_supercollider'] == "supercollider":
                    run_sclang_command(
                        self.process_SC, block, self.config['create_log_file'], self.comentario)

            self.processed_blocks = new_blocks

            if self.config['api_enabled']:
                start_api_thread(
                    client=self.client,
                    model=self.config['model'],
                    temperature=self.config['temperature'],
                    max_tokens=self.config['max_tokens'],
                    top_p=self.config['top_p'],
                    frequency_penalty=self.config['frequency_penalty'],
                    presence_penalty=self.config['presence_penalty'],
                    wait_time_before_api=self.config['wait_time_before_api'],
                    wait_time_after_api=self.config['wait_time_after_api'],
                    messages=self.messages,
                    content=new_content,
                    response_handler=self.response_handler
                )

        self.last_modified = time.time()
