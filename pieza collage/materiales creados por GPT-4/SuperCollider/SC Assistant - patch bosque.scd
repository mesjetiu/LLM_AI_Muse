// Patch obtenido con SuperCollider Assistant
// 09/11/2023
// https://platform.openai.com/playground?thread=thread_5Sqry82fvt0tclH4mX0yDIln

// grabado en path: '/home/carlos/.local/share/SuperCollider/Recordings/SC_240106_184815.wav'



(
s.boot;

// Definir un sintetizador más suave para el sonido del viento y las hojas
SynthDef(\softFoliage, {
    arg out=0, amp=0.1, pan=0;
    var sound, filterFreq;

    // Crear un ruido rosado que tiene una calidad más suave que el ruido blanco
    sound = PinkNoise.ar(amp);

    // Modular la frecuencia del filtro para simular el movimiento del viento en las hojas
    filterFreq = LFNoise1.kr(Rand(0.1, 0.5)).exprange(300, 2000);
    sound = LPF.ar(sound, filterFreq);

    // Utilizar una envolvente suave para modelar el sonido con más naturalidad
    sound = sound * EnvGen.kr(Env.linen(5, 10, 5, 0.1), doneAction: 2);

    Out.ar(out, Pan2.ar(sound, pan));
}).add;

// Definir el synth para los pájaros como se hizo inicialmente
SynthDef(\birds, {
    arg out=0, amp=0.05, pan=0;
    var z;
    z = SinOsc.ar(2200 + (SinOsc.kr([5, 6]) * 100)).abs - 0.97;
    z = HPF.ar(z * amp, 1000);
    z = z * EnvGen.ar(Env.perc(0.1, Rand(2, 3)), doneAction: 2);
    Out.ar(out, Pan2.ar(z, pan));
}).add;

// Inicializar el patrón para generar el sonido del viento
Pbind(
    \instrument, \softFoliage,
    \dur, Pwhite(8, 12),  // Duración más larga para un sonido continuo
    \amp, 0.2,
    \pan, Pwhite(-1, 1)
).play;

// Inicializar el patrón para los pájaros
Pbind(
    \instrument, \birds,
    \dur, Pexprand(0.1, 1),
    \amp, 0.05,
    \pan, Pwhite(-1, 1)
).play;
)