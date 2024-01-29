(
// Definimos el SynthDef para el fondo y los destellos
SynthDef(\ciudad_noche, {
    // Fondo profundo y constante
    var fondo = SinOsc.ar(50, 0, 0.2);

    // Destellos agudos y rápidos que representan las luces y movimientos
    var destellos = Dust.ar(50, 0.1) * WhiteNoise.ar();
    destellos = destellos * EnvGen.ar(Env.perc(0.01, 0.1, 0.1), Dust.kr(2));

    // Sumamos y enviamos el sonido al out
    Out.ar(0, Pan2.ar(fondo + destellos));
}).add;

// Iniciamos el servidor de audio y esperamos a que esté listo
s.waitForBoot {
    // Tocamos el SynthDef
    ~ciudad = Synth(\ciudad_noche);

    // Creamos y tocamos la secuencia de patrones
    ~secuencia = Pbind(
        \instrument, \default,
        \dur, Pwhite(0.1, 0.4),
        \midinote, Prand([60, 62, 64, 65, 67], inf),
        \amp, 0.1
    ).play;

    // Detener la melodía después de un tiempo
    fork {
        10.wait; // Tocar por 10 segundos
        ~secuencia.stop;
        ~ciudad.free;
    };
};
)
