// Ejemplo del archivo de ayuda pasado en One-Shot
(
SynthDef(\fm_grain_test, {arg gate = 1, amp = 1;
    Out.ar(0,
        FMGrain.ar(Impulse.ar(20), 0.2, 440, 200,
            LFNoise1.kr(1).range(1, 10),
            EnvGen.kr(
                Env([0, 1, 0], [1, 1], \sin, 1),
                gate,
                levelScale: amp,
                doneAction: 2)
        )
    )
}).add;
)

s.sendMsg(\s_new, \fm_grain_test, a=s.nextNodeID, 0, 1, \amp, 0.1);
s.sendMsg(\n_set, a, \gate, 0);




// creado en ChatGPT con Zero-Shot
(
{
    var dur, dens, fund, form, indx, pan;
    dur = MouseX.kr(0.01, 0.2, 1, 0.01); // controla la duración de los granos
    dens = MouseY.kr(20, 50, 1, 0.1);    // controla la densidad de los granos
    fund = 200;                           // frecuencia fundamental
    form = 800;                           // frecuencia de la forma
    indx = 2;                             // índice de modulación
    pan = LFNoise2.kr(0.5).range(-1, 1);  // pan aleatorio

    FMGrain.ar(
        numChannels: 2,
        trigger: Impulse.kr(dens),
        dur: dur,
        carfreq: fund,
        modfreq: form,
        index: indx,
        pan: pan
    )
}.play;
)


// creado con One-Shot

(
SynthDef(\fm_grain_artistic, { arg gate = 1, amp = 1;
    var sound, freq, dur, pan, rate, index;

    // Parámetros modificables para la textura
    freq = LFNoise1.kr(0.5).range(200, 1000); // Frecuencia cambiante
    dur = LFNoise2.kr(0.1).range(0.1, 0.5);  // Duración variable de los granos
    pan = LFNoise2.kr(0.2).range(-1, 1);     // Posición estéreo cambiante
    rate = LFNoise1.kr(0.3).range(5, 50);    // Tasa de repetición de los granos
    index = LFNoise1.kr(0.4).range(100, 800); // Índice de modulación

    // Creación de la textura sonora
    sound = FMGrain.ar(
        Impulse.ar(rate), // Generador de impulsos con tasa variable
        dur,              // Duración de los granos
        freq,             // Frecuencia fundamental
        index,            // Índice de modulación
        5,                // Relación de frecuencias
        pan               // Posición estéreo
    );

    // Aplicación del envolvente y salida
    Out.ar(0,
        Pan2.ar(
            sound * EnvGen.kr(
                Env([0, 1, 0], [0.1, 0.1], \sin, 1),
                gate,
                levelScale: amp,
                doneAction: 2
            ),
            pan
        )
    );
}).add;
)

// Ejemplo de uso
s.sendMsg(\s_new, \fm_grain_artistic, a=s.nextNodeID, 0, 1, \amp, 0.1);
s.sendMsg(\n_set, a, \gate, 0);
