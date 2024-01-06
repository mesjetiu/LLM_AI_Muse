// SATURA


// Definición del SynthDef de OteyPiano con la adición de un parámetro de velocidad para variar la dinámica
(
SynthDef(\chopin_oteypiano, { |out=0, freq=440, gate=1, amp=0.5, rho=1, vel=1|
    var son = OteyPiano.ar(freq, amp * vel, rho: rho) * EnvGen.ar(Env.asr(0.01, 1, 0.5), gate, doneAction: 2);
    Out.ar(out, Pan2.ar(son, LinLin.kr(freq, 36.midicps, 90.midicps, -0.75, 0.75)));
}).add;
)

// Pieza inspirada en Chopin y Liszt
(
Pbindef(\piano,
    \instrument, \chopin_oteypiano,
    \delta, Pwhite(0.4, 1),
    \dur, Pwhite(0.25, 0.1),
	\legato, Pbrown(5,8.0),
    \freq, Pseq([
        Prand([300, 320, 350, 380], 8)*2,    // Arpegio ascendente
        Pseq([400, 380, 360, 340, 320, 300, 280], 1),  // Escala descendente
        Prand([500, 530, 560, 590], 8)*1,    // Arpegio ascendente en otra octava
        Pseq([600, 580, 550, 520, 490, 460, 430], 1)*2  // Escala descendente
    ], inf),
    \amp, 0.1,
    \vel, Pwhite(0.5, 1.2),  // Dinámica variable para capturar la expresividad
    \rho, Pwhite(0.5, 2)
).play;
)

