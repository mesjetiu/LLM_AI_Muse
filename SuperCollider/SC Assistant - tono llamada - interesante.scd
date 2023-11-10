// SC Assistant
// 09/11/2023
// https://platform.openai.com/playground?assistant=asst_jRoEFqfb7RegBABBvS7qEi1i&mode=assistant&thread=thread_U0n8DqLQ1j5mHIcUWrXGIG65
// Interesante

// Este es un ejemplo simplificado y no grabará el audio automáticamente.


// Tono de llamada
(
s.waitForBoot { // Asegurarse de que el servidor de sonido esté listo antes de ejecutar el código.

    var duracion = 20; // Duración en segundos
    var tempo = 120;// Tempo en BPM
    var notaBase = 60; // Frecuencia base (en MIDI) para la melodía
    var escala = [0, 2, 4, 5, 7, 9, 11]; // Escala mayor
    var secuenciaMelodica; // Inicializamos la secuencia melódica

    SynthDef(\nota, { |freq, dur, amp| // Definición del Synth para las notas.
        var env, src;
        env = Env.perc(0.01, dur, amp, -4).kr(2);
        src = SinOsc.ar(freq, 0, env); // Usa un oscilador senoidal.
        Out.ar(0, src ! 2); // Salida estéreo.
    }).add;

    // Crear una secuencia melódica aleatoria dentro de la escala
    secuenciaMelodica = Pbind(
        \instrument, \nota,
        \dur, Pwhite(0.25, 0.5), // Duraciones aleatorias entre 0.25 y 0.5 segundos
        \freq, Pfunc({ notaBase + escala.choose }).midicps, // Frecuencias en una escala mayor
        \amp, 0.5 // Amplitud constante.
    ).play(TempoClock(tempo/60));

    // Detener la secuencia después de la duración determinada
    duracion.wait;
    secuenciaMelodica.stop;

    // Esto grabaría el audio, pero está comentado para que solo puedas escucharlo por ahora.
    // s.record;
    // duracion.wait;
    // s.stopRecording;
};
)



// Tono de mensaje
// Definimos el SynthDef fuera de cualquier Routine o función de tiempo:
SynthDef(\mensaje, { |freq=440, dur=1, amp=0.5|
    var env = Env.perc(0.01, dur, amp, -4).kr(2);
    var src = SinOsc.ar(freq) * env;
    Out.ar(0, src ! 2); // Salida estéreo
}).add;

// Esperamos a que el SynthDef se haya añadido al servidor antes de ejecutar la secuencia
s.sync;

// Ejecutamos la secuencia en una Routine para gestionar correctamente el tiempo de espera
Routine({
    Pbind(
        \instrument, \mensaje,
        \dur, 0.25,
        \freq, Pseq([800, 1000, 1200, 1000].midicps, 1), // Tocará esta secuencia una vez
        \amp, 0.5
    ).play;
    5.wait; // Esperamos 5 segundos antes de terminar la Routine
}).play;


// Tono de despertador
(
s.waitForBoot {
    SynthDef(\despertador, { |freq=440, dur=1, amp=0.1|
        var env, src;
        env = Env.linen(1, dur, 1, amp, -4).kr(2);
        src = SinOsc.ar([freq, freq*1.01], 0, env);
        Out.ar(0, src ! 2);
    }).add;

    Pbind(
        \instrument, \despertador,
        \dur, Pseq([2, 2, 2, 3, 4], inf),
        \freq, Pseq([440, 550, 660, 550, 440].midicps, inf),
        \amp, Pseq([(0.2..1.0).scramble], inf)
    ).play(TempoClock(0.5));
    30.wait; // Duración del tono de despertador.
};
)