// Grabado en SC_240105_170144.wav


// 1. Definimos el SynthDef con modulación de frecuencia.
(
SynthDef(\fmModulator, { |out = 0, freq = 440, modDepth = 100, modFreq = 5, dur = 1|
    // Generador de modulación
    var modulator = SinOsc.ar(modFreq) * modDepth;

    // Oscilador principal con frecuencia modulada
    var signal = SinOsc.ar(freq + modulator) * 0.5;

    // Envoltura para dar principio y fin al sonido
    var env = EnvGen.kr(Env.perc(0.01, dur - 0.01), doneAction: 2);

    // Multiplicamos la señal por la envoltura
    signal = signal * env;

    // Enviamos la señal al canal de salida
    Out.ar(out, [signal, signal]);
}).add;
)

// 2. Usamos Pbind para secuenciar eventos de nuestro SynthDef.
(
Pbind(
    \instrument, \fmModulator, // Usamos el SynthDef definido anteriormente
    \freq, Pwhite(300, 600),   // Frecuencias aleatorias entre 300 y 600 Hz
    \modDepth, Pwhite(50, 150), // Profundidad de modulación variable
    \modFreq, Pwhite(1, 10),  // Frecuencia de modulación variable
    \dur, 0.5                  // Duración de cada nota
).play;
)


// nueva versión con efectos espaciales:

(
SynthDef(\fmModulator, { |out = 0, freq = 440, modDepth = 100, modFreq = 5, pan = 0, dur = 1|
    // Generador de modulación
    var modulator = SinOsc.ar(modFreq) * modDepth;

    // Oscilador principal con frecuencia modulada
    var signal = SinOsc.ar(freq *1 + modulator) * 0.5;

    // Envoltura para dar principio y fin al sonido
    var env = EnvGen.kr(Env.perc(0.01, dur*3 - 0.01), doneAction: 2);

    // Multiplicamos la señal por la envoltura
    signal = signal * env;

    // Aplicamos paneo
    signal = Pan2.ar(signal, pan);

    // Aplicamos reverb
    signal = FreeVerb.ar(signal, 0.2, 0.6, 0.5); // Puedes ajustar estos parámetros para cambiar la reverb

    // Enviamos la señal al canal de salida
    Out.ar(out, signal);
}).add;
)

// 2. Usamos Pbind para secuenciar eventos de nuestro SynthDef con paneo.
(
Pbind(
    \instrument, \fmModulator,  // Usamos el SynthDef definido anteriormente
    \freq, Pwhite(0.0, 1).linexp(0, 1, 100, 600),    // Frecuencias aleatorias entre 300 y 600 Hz
    \modDepth, Pwhite(50, 150), // Profundidad de modulación variable
    \modFreq, Pwhite(30, 200.0),    // Frecuencia de modulación variable
    \pan, Pwhite(-1.0, 1),        // Paneo aleatorio
    \dur, Pwhite(0.5, 9),                   // Duración de cada nota
	\legato, 3
).play;
)
