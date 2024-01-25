(
// Definición del Synth
SynthDef.new("ambientSoundscape", {
    arg out=0, freq=440, pan=0, amp = 0;
    var sonido1, sonido2, sonido3, moduladorFreq, moduladorAmp, efecto, envolvente;

    // Generación de Sonidos Base
    sonido1 = SinOsc.ar(freq);
    sonido2 = LFSaw.ar(freq * 0.5, mul: 0.2);
    sonido3 = WhiteNoise.ar(0.1);

    // Manipulación de Frecuencias y Amplitudes
    moduladorFreq = LFNoise1.kr(0.2).range(0.5, 2);
    moduladorAmp = LFPulse.kr(1, 0, 0.5);

    // Espacialización Estereofónica
    sonido1 = Pan2.ar(sonido1, pan);
    sonido2 = Pan2.ar(sonido2, pan * -1); // Inversión del paneo
    sonido3 = Pan2.ar(sonido3, pan);

    // Efectos y Procesamiento de Sonido
    efecto = FreeVerb.ar(sonido1 + sonido2 + sonido3, mix: 0.9, room: 0.8);

    // Control de Envolventes y Dinámicas
	envolvente = Env.perc(0.01, 1, curve: -4).kr( doneAction: Done.freeSelf);
    efecto = efecto * envolvente * amp;

    // Salida
    Out.ar(out, efecto);
}).add;

// Reproducción y Control en Tiempo Real
Pbind(
    \instrument, "ambientSoundscape",
    \freq, Pwhite(200, 1000),
    \dur, Pseq([0.2, 0.5, 0.3, 0.4, 0.1], inf),  // Duraciones variables
    \pan, Pwhite(-1, 1),  // Paneo aleatorio
    \amp, Pbrown(0.1, 0.5, 0.05, inf)  // Amplitud en evolución
).play;
)

