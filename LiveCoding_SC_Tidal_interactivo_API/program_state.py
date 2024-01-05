class ProgramState:
    def __init__(self):
        self.running = True
        self.events = []

    def stop(self):
        self.running = False
        self.record_event("Programa detenido.")

    def is_running(self):
        return self.running

    def record_event(self, event):
        self.events.append(event)
        # Aquí se puede eventualmente implementar lógica para guardar los eventos en un archivo o base de datos

    def get_events(self):
        return self.events


# Instancia global del estado del programa
estado_programa = ProgramState()
