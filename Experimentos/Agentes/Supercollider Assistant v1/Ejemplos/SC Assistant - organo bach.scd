// SC Assistant
// https://platform.openai.com/playground?assistant=asst_jRoEFqfb7RegBABBvS7qEi1i&mode=assistant&thread=thread_EjogsuQ31L9EzQ0pmMtQ2nX6
// 09/11/2023

// Definición del sintetizador de órgano
(
SynthDef(\organo, {
    | freq, amp = 0.1, gate = 1 |
    var sonido, env;

    // Generadores de onda sinusoidal para distintas armónicas del órgano
    sonido = SinOsc.ar(freq, 0, 0.2)
        + SinOsc.ar(freq * 2, 0, 0.1)
        + SinOsc.ar(freq * 3, 0, 0.05)
        + SinOsc.ar(freq * 4, 0, 0.02)
        + SinOsc.ar(freq * 5, 0, 0.01);

    // Envolvente del tipo ADSR
    env = EnvGen.kr(Env.adsr(attackTime: 0.01, decayTime: 0.1, sustainLevel: 0.7, releaseTime: 0.3), gate, doneAction: 2) * amp;
    sonido = sonido * env;

    // Salida del sonido
    Out.ar(0, sonido.dup); // .dup para duplicar el sonido en ambos canales
}).add;
)

// Definición de las líneas melódicas
(
var notas1, notas2, ritmo, duraciones;

notas1 = [60, 62, 64, 65, 67, 69, 71, 72]; // Escala de C mayor ascendente
notas2 = [72, 71, 69, 67, 65, 64, 62, 60]; // Escala de C mayor descendente
ritmo = Pseq([0.5, 0.25, 0.25, 1], inf); // Patrón de ritmo común en la música de Bach
duraciones = ritmo * 0.9; // Pequeño espacio entre notas para simular separación

Ppar([
    Pbind(
        \instrument, \organo,
        \freq, Pseq(notas1.midicps, inf),
        \dur, duraciones
    ),
    Pbind(
        \instrument, \organo,
        \freq, Pseq(notas2.midicps, inf),
        \dur, duraciones
    )
]).play;
)