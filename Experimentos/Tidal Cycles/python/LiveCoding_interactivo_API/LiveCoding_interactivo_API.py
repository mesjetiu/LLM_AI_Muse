import subprocess
import time
from openai import OpenAI
import json
import datetime
from apikey import API_KEY  # Importa la clave desde apikey.py

# Crear el cliente de OpenAI
client = OpenAI(api_key=API_KEY)

# Leer el mensaje del sistema desde un archivo externo
with open('Experimentos/Tidal Cycles/python/LiveCoding_OpenAI/system_prompt.txt', 'r') as file:
    system_prompt = file.read()


# Iniciar GHCi con el proceso de TidalCycles
try:
    process = subprocess.Popen(["ghci"], stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                               stderr=subprocess.PIPE, text=True, bufsize=1, universal_newlines=True)
except Exception as e:
    print(f"Error al iniciar GHCi: {e}")
    exit(1)

# Función para enviar un comando a TidalCycles a través de GHCi


def run_tidal_command(command):
    try:
        print("Enviando comando a TidalCycles:", command)
        process.stdin.write(command + "\n")
        process.stdin.flush()
    except Exception as e:
        print(f"Error al enviar comando a TidalCycles: {e}")


# Inicializar TidalCycles
run_tidal_command(":script /usr/share/haskell-tidal/BootTidal.hs")
time.sleep(5)  # Esperar a que TidalCycles se inicialice

# Definir parámetros para las consultas a la API
model = "gpt-4-1106-preview"
temperature = 1
max_tokens = 512
top_p = 1
frequency_penalty = 0
presence_penalty = 0
wait_time = 15  # Tiempo de espera entre comandos en segundos
iterations = 5  # Número de iteraciones

# Crear o abrir el archivo de log
current_datetime = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
filename = f"tidal_session_{current_datetime}.json"
session_log = []

# Mensajes iniciales para la conversación
messages = [
    {
        "role": "system",
        "content": system_prompt
    },
    {
        "role": "user",
        "content": "Comienza la sesión. Dame el primer patrón."
    }
]

# Bucle principal para obtener y ejecutar comandos
for i in range(iterations):
    try:
        # Realizar consulta al modelo
        response = client.chat.completions.create(
            model=model,
            messages=messages,
            temperature=temperature,
            max_tokens=max_tokens,
            top_p=top_p,
            frequency_penalty=frequency_penalty,
            presence_penalty=presence_penalty
        )

        # Extraer el mensaje de respuesta de la API
        tidal_command = response.choices[0].message.content
        print(f"Respuesta de la API: {tidal_command}")

        # Añadir respuesta del asistente al array de mensajes
        messages.append({"role": "assistant", "content": tidal_command})

        # Ejecutar comando en TidalCycles
        run_tidal_command(tidal_command)

        # Agregar al log y guardar inmediatamente
        session_log.append({"user": messages[-2], "assistant": messages[-1]})
        with open(filename, 'w') as file:
            json.dump(session_log, file, indent=2, ensure_ascii=False)

        # Preparar el próximo mensaje del usuario
        user_message = "Dame el siguiente patrón o modificación de uno existente"
        messages.append({"role": "user", "content": user_message})

        # Esperar el tiempo establecido
        time.sleep(wait_time)

        # Si el comando es "hush", terminar el bucle
        if tidal_command.strip() == "hush":
            break

    except Exception as e:
        print(f"Error en la llamada a la API de OpenAI: {e}")
        break  # O manejar de otra manera

# Tiempo adicional para recibir el último patrón y escucharlo
time.sleep(wait_time*2)

# Detener todos los sonidos y resetear TidalCycles (para asegurarnos de que no queda sonido residual)
run_tidal_command("hush")

# Esperar un momento para que el comando 'hush' surta efecto
time.sleep(2)

# Finalizar sesión en GHCi
try:
    process.stdin.close()
    process.terminate()
except Exception as e:
    print(f"Error al cerrar GHCi: {e}")

print(f"Proceso completado. Sesión guardada en {filename}.")
