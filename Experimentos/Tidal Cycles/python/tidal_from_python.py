import subprocess
import time
import json

# Iniciar GHCi con el proceso de TidalCycles
process = subprocess.Popen(["ghci"], stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                           stderr=subprocess.PIPE, text=True, bufsize=1, universal_newlines=True)

# Función para enviar un comando a TidalCycles a través de GHCi


def run_tidal_command(command):
    print("Enviando comando:", command)
    process.stdin.write(command + "\n")
    process.stdin.flush()


# Inicializar TidalCycles
print("Inicializando TidalCycles...")
run_tidal_command(":script /usr/share/haskell-tidal/BootTidal.hs")
time.sleep(5)  # Esperar a que TidalCycles se inicialice


# JSON hardcodeado con comandos y duraciones
json_data = '''
[
  {"code": "d1 $ n (scale \\\"ritusen\\\" $ \\\"0 [7 2] 3 2\\\" |+ irand 3) # sound \\\"superpiano\\\"", "duration": 8},
  {"code": "d2 $ segment 16 $ n (scale \\\"minor\\\" $ floor <$> (range 0 14 sine)) # sound \\\"supersaw\\\" # legato 0.5 # lpf 1000 # lpq 0.1", "duration": 10},
  {"code": "d1 $ struct \\\"t(<9 7>,16)\\\" $ n (scale \\\"minor\\\" $ floor <$> (range \\\"<0 4 -8>\\\" \\\"<12 14 13 -13>\\\" sine)) # sound \\\"supersaw\\\" # legato 0.5 # lpf (range 400 5000 saw) # lpq 0.1", "duration": 12},
  {"code": "d3 $ n (fit 0 [9,10,11,12,13,14] \\\"[0 3] [1 2] 4 [~ 5]\\\") # s \\\"alphabet\\\"", "duration": 6},
  {"code": "d4 $ note (fit 2 [0,2,7,5,12] \\\"0 ~ 1 [2 3]\\\") # sound \\\"supermandolin\\\" # legato 2 # gain 1.3", "duration": 14},
  {"code": "d2 $ n \\\"0 ~ 2 [3*2 4*2]\\\" # sound \\\"cpu\\\" # speed 2", "duration": 8},
  {"code": "d1 $ sound \\\"silence\\\"", "duration": 2}
]
'''

# JSON hardcodeado con comandos y duraciones
json_data = '''
[
  {"code": "d1 $ sound \\"arpy*4\\" # speed (slow 2 sine)", "duration": 8},
  {"code": "d2 $ struct \\"t(3,8)\\" $ sound \\"cpu*2\\" # crush 4", "duration": 6},
  {"code": "d3 $ n (scale \\"minor\\" $ floor <$> (range 0 14 sine)) # sound \\"supersaw\\" # legato 0.5 # lpf 1000 # lpq 0.1", "duration": 10},
  {"code": "d4 $ sound \\"supermandolin\\" # n \\"c'maj e'min7\\" # room 0.6 # sz 0.9", "duration": 12},
  {"code": "d1 $ sound \\"arpy*4\\" # speed (slow 4 cosine)", "duration": 8},
  {"code": "d2 $ off \\"0.25\\" (|+ n 7) $ n \\"c e\\" # sound \\"supermandolin\\"", "duration": 6},
  {"code": "d3 $ segment 16 $ n (scale \\"ritusen\\" $ \\"0 [7 2] 3 2\\" |+ irand 3) # sound \\"supersaw\\" # legato 0.5 # lpf (range 400 5000 saw) # lpq 0.1", "duration": 10},
  {"code": "d4 $ off 0.25 (|+ n 12) $ struct \\"t(<9 7>,16)\\" $ segment 16 $ n (scale \\"minor\\" $ floor <$> (slow 2 $ (slow 2 sine + slow 3 cosine) * \\"<6 -3>\\")) # sound \\"supersaw\\" # legato 0.5 # lpf (range 400 5000 saw) # lpq 0.1", "duration": 12},
  {"code": "d1 $ off \\"e\\" (|+ n 7) $ n (slow 2 \\"c(3,8) a(3,8) f(5,8) e*2\\") # sound \\"supermandolin\\" # sustain 0.75", "duration": 8},
  {"code": "d2 $ sound \\"cpu2\\" # n \\"{0 1 [~ 2] 3*2, 5 ~ 3 6 4}\\" # sustain 0.75", "duration": 6},
  {"code": "d3 $ struct \\"t(<9 7>,16)\\" $ n (scale \\"minor\\" $ floor <$> (slow 2 $ (slow 2 sine + slow 3 cosine) * \\"<6 -3>\\")) # sound \\"supersaw\\" # legato 0.5 # lpf (range 400 5000 saw) # lpq 0.1", "duration": 10},
  {"code": "d4 $ silence", "duration": 12}
]
'''

# completa el siguiente json con más eventos
json_data = '''
[
  {"code": "d1 $ sound \\"bd*4\\\"", "lag": 4},
  {"code": "d2 $ sound \\"bass:3*2\\\"", "lag": 3},
  {"code": "d3 $ sound \\"lead:5 [~ lead:4] lead:3*2\\\"", "lag": 5},
]

'''

# Convertir JSON en objetos Python
commands = json.loads(json_data)

# Ejecutar cada comando en TidalCycles
for command in commands:
    run_tidal_command(command["code"])
    time.sleep(command["lag"])

# Detener todos los sonidos y resetear TidalCycles
run_tidal_command("hush")

# Esperar un momento para que el comando 'hush' surta efecto
time.sleep(2)

# Cerrar GHCi
process.stdin.close()
process.terminate()
