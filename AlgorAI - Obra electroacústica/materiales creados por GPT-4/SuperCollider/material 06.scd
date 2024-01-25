// Definimos la duración total de la pieza
var duracionTotal = 25;

SynthDef.new(\generativa, {
    var sonido1, sonido2, env, modIndex, carrierFreq, sonidoProcesado, mezclaFinal, pan;

    // Envoltura de amplitud para los sonidos
    env = Env.perc(0.01, duracionTotal, 0.1, -4).kr;

    // Capa de síntesis granular con ruido blanco
    sonido1 = GrainBuf.ar(
        numChannels: 2,
        trigger: Impulse.kr(Rand(5, 15)),  // Frecuencia de trigger aleatoria
        dur: Rand(0.1, 1),  // Duración aleatoria
        sndbuf: { WhiteNoise.ar() ! 2 },
        rate: Rand(0.5, 2),  // Tasa aleatoria
        pos: Rand(0, 1),  // Posición aleatoria
        interp: 4,
        pan: Rand(-1, 1)  // Paneo aleatorio
    ) * env;

    // Capa de síntesis FM
    modIndex = LFNoise1.kr(Rand(0.1, 2)).range(0, 3);
    carrierFreq = LFNoise1.kr(Rand(0.1, 0.2)).range(200, 800);
    sonido2 = SinOsc.ar(
        freq: carrierFreq + (modIndex * SinOsc.kr(Rand(2, 6)).range(0, 100)),  // Modulador con frecuencia aleatoria
        mul: env
    );

    // Procesamiento espacial
    sonidoProcesado = [
        FreeVerb.ar(sonido1, mix: Rand(0.2, 0.4), room: Rand(0.8, 1.0)),  // Parámetros de reverb aleatorios
        FreeVerb.ar(sonido2, mix: Rand(0.2, 0.4), room: Rand(0.8, 1.0))
    ];

    // Paneo aleatorio
    pan = Rand(-1, 1.0);

    mezclaFinal = sonidoProcesado.sum;
    mezclaFinal = Pan2.ar(mezclaFinal, pan);  // Paneo aleatorio aplicado

    // Reproducir la mezcla final
    Out.ar(0, mezclaFinal);
}).add;

// Reproducir el SynthDef
Synth.new(\generativa);
