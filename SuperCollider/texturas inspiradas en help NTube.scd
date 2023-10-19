// https://chat.openai.com/share/b8f6e2c6-fad6-47dd-9c56-8a177f22376a


s.boot;

(
SynthDef(\customNTubeSound, {
    var source, filteredNoise, output, pannedOutput;

    // Generamos un sonido que se asemeje a la respiración utilizando PinkNoise, SinOsc y la técnica NTube.ar
    source = PinkNoise.ar * SinOsc.ar(0.25);
    filteredNoise = NTube.ar(
        source,
        [0.97, 1.0, 1.0, 1.0, 1.0, 0.97], // Loss factors
        [0.5, MouseY.kr(-1.0, 1.0), 0.2, -0.4], // Junction reflection coefficients
        [0.01, 0.02, 0.01, 0.005, 0.05] * MouseX.kr(0.001, 1.0, 'exponential') // Delay lengths
    ) * 0.1;

    // Panoramización
    pannedOutput = Pan2.ar(filteredNoise, SinOsc.kr(0.2).range(-1, 1));

    // Aplicamos un limitador
    output = Limiter.ar(pannedOutput, 0.99, 0.01);
    output = output.min(1.0).max(-1.0);

    Out.ar([0, 1], output);
}).add;
)

// Reproducimos el sonido
x = Synth(\customNTubeSound);



s.boot;

(
SynthDef(\customAmbientSound, {
    var source, nTubeProcessed, modulatedFilter, output, stereoOutput;

    // Generamos un noise basado en PinkNoise pero modulado con una SinOsc de baja frecuencia para darle movimiento
    source = PinkNoise.ar(0.5) * SinOsc.kr(0.1).range(0.5, 1.5);

    // Utilizamos NTube para darle un carácter tubular y resonante al noise
    nTubeProcessed = NTube.ar(
        source,
        [0.95, 0.98, 1.0, 1.0, 0.98, 0.95], // Loss factors
        LFNoise1.kr(0.1).range(0.1, 0.9), // Junction reflection coefficients variando con el tiempo
        LFNoise2.kr(0.05).range(0.01, 0.05) // Delay lengths variando aleatoriamente
    ) * 0.3;

    // Añadimos un filtro paso banda que se mueva con el tiempo
    modulatedFilter = BPF.ar(
        nTubeProcessed,
        freq: LFNoise2.kr(0.2).range(300, 2000),
        rq: 0.5
    );

    // Aplicamos un delay estéreo con modulación tipo ping-pong
    stereoOutput = CombC.ar(modulatedFilter, 2.0, LFNoise2.kr(0.1).range(0.05, 0.5), 0.5);
    stereoOutput = DelayN.ar(stereoOutput, 0.2, SinOsc.kr(0.3).range(0.01, 0.1));

    Out.ar([0, 1], stereoOutput);
}).add;
)

// Reproducimos el sonido
y = Synth(\customAmbientSound);




s.boot;

(
SynthDef(\customFMResonance, {
    var fmSource, resonated, output;

    // Generamos una fuente basada en modulación de frecuencia (FM)
    fmSource = SinOsc.ar(
        freq: LFNoise1.kr(0.1).range(100, 400),
        phase: 0,
        mul: 0.5,
        add: SinOsc.ar(
            freq: LFNoise1.kr(0.2).range(400, 800),
            phase: 0,
            mul: LFNoise1.kr(0.5).range(0.1, 1.0)
        )
    );

    // Aplicamos resonadores para realzar ciertas frecuencias y darle carácter espacial
    resonated = Resonz.ar(
        fmSource,
        freq: LFNoise2.kr(0.15).range(500, 2000),
        rq: LFNoise2.kr(0.1).range(0.2, 0.8)
    ) * 0.3;

    // Panoramizamos el sonido para obtener una inmersión estéreo
    output = Pan2.ar(resonated, LFNoise1.kr(0.25).range(-1, 1));

    Out.ar([0, 1], output);
}).add;
)

// Reproducimos el sonido
z = Synth(\customFMResonance);

