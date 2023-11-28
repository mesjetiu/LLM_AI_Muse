import time
from watchdog.events import FileSystemEventHandler
from sound_engine import run_tidal_command, run_sclang_command
from openai_integration import start_api_thread

class MyHandler(FileSystemEventHandler):
    def __init__(self, process, process_SC, config):
        self.last_modified = time.time()
        self.process = process
        self.process_SC = process_SC
        self.config = config
        self.processed_blocks = set()

    def segment_into_blocks(self, content):
        """
        Divide el contenido en bloques para su procesamiento.
        :param content: Contenido del archivo.
        :return: Conjunto de bloques.
        """
        blocks = set()
        lines = content.split('\n')
        current_block = []
        for line in lines:
            clean_line = line.split(self.config['comentario'])[0].strip()
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

        if os.path.basename(event.src_path) == self.config['nombre_archivo']:
            with open(event.src_path, 'r') as file:
                new_content = file.read()
            new_blocks = self.segment_into_blocks(new_content)

            for block in new_blocks - self.processed_blocks:
                # Aquí procesas cada bloque (puedes necesitar más lógica aquí)
                if self.config['mode_tidal_supercollider'] == "tidal":
                    run_tidal_command(self.process, block, self.config['create_log_file'], self.config['comentario'])
                elif self.config['mode_tidal_supercollider'] == "supercollider":
                    run_sclang_command(self.process_SC, block, self.config['create_log_file'], self.config['comentario'])

            # Actualiza los bloques procesados
            self.processed_blocks = new_blocks

            # Si la API está habilitada, inicia un hilo para consultarla
            if self.config['api_enabled']:
                start_api_thread(/* Parámetros necesarios para la función */)

        self.last_modified = time.time()
