// Ejemplo frustrado...
// https://chat.openai.com/share/b21ca505-7571-4300-89aa-6927dfcb9ab7



// Definimos la duración total de la pieza
var duracionTotal = 25;

SynthDef.new(\generativa, {
    var sonido1, sonido2, env, modIndex, carrierFreq, sonidoProcesado, mezclaFinal;

    // Envoltura de amplitud para los sonidos
    env = Env.perc(0.01, duracionTotal, 0.1, -4).kr;

    // Capa de síntesis granular con ruido blanco
    sonido1 = GrainBuf.ar(
        numChannels: 2,
        trigger: Impulse.kr(10),
        dur: Rand(0.1, 1),
        sndbuf: { WhiteNoise.ar() ! 2 },  // Ruido blanco en lugar de un buffer de audio
        rate: Rand(0.5, 2),
        pos: Rand(0, 1),
        interp: 4,
        pan: Rand(-1, 1)
    ) * env;

    // Capa de síntesis FM
    modIndex = LFNoise1.kr(Rand(0.1, 2)).range(0, 3);
    carrierFreq = LFNoise1.kr(Rand(0.1, 0.2)).range(200, 800);
    sonido2 = SinOsc.ar(
        freq: carrierFreq + (modIndex * SinOsc.kr(5).range(0, 100)),
        mul: env
    );

    // Procesamiento espacial
    sonidoProcesado = [
        FreeVerb.ar(sonido1, mix: 0.3, room: 0.9),
        FreeVerb.ar(sonido2, mix: 0.3, room: 0.9)
    ];

    mezclaFinal = sonidoProcesado.sum;
    mezclaFinal = Pan2.ar(mezclaFinal, LFNoise1.kr(0.1).range(-1, 1));

    // Reproducir la mezcla final
    Out.ar(0, mezclaFinal);
}).add;

// Reproducir el SynthDef
Synth.new(\generativa);
