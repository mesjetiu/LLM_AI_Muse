// https://platform.openai.com/playground?assistant=asst_jRoEFqfb7RegBABBvS7qEi1i&thread=thread_sNm8fDfcwZu3GU4APA6g3SXp
// 09/11/2023
// Interesantísimo!!


// Definimos un bus de audio para la reverberación
~reverbBus = Bus.audio(s, 2);

// SynthDef de reverberación
(
SynthDef(\reverbEffect, { |outBus = 0|
    var sig = In.ar(~reverbBus, 2);
    sig = JPverb.ar(sig[0] + sig[1], t60: 3, size: 0.9, damp: 0.2, earlyDiff: 0.7);
    ReplaceOut.ar(outBus, sig);
}).add;
)

// SynthDefs para gránulos con correcciones de FM y adiciones para variación
(
SynthDef(\grainSynth, { |outBus, freq = 440, dur = 0.1, pan = 0, amp = 0.1, type = 0|
    var sig, env, mod;
    env = EnvGen.ar(Env.perc(0.01, dur, amp), doneAction: 2);
    // Tipo de grano: varía desde FM a pulse a noise
    mod = Select.ar(type,
        [
            SinOsc.ar(freq + SinOsc.ar(Rand(1.0, 100.0)).range(-200, 200)) * env, // FM
            Pulse.ar(freq, 0.5) * env,                                            // Pulse
            WhiteNoise.ar() * env * LFNoise1.kr(5).range(0,1)                    // Noise
        ]
    );
    Out.ar(outBus, Pan2.ar(mod, pan));
}).add;
)

// Creamos la instancia del efecto de reverberación
~reverb = Synth(\reverbEffect, [\outBus, 0]);

// Función para variar la densidad temporal de los granos y tipo de grano
(
~density = { |minTime = 0.05, maxTime = 0.2, typeMin = 0, typeMax = 2|
    Pbind(
        \instrument, \grainSynth,
        \freq, Pexprand(200.0, 2000.0, inf),
        \dur, Pwhite(minTime, maxTime, inf),
        \pan, Pwhite(-1, 1, inf),
        \amp, Pwhite(0.01, 0.1, inf),
        \type, Pwhite(typeMin, typeMax, inf),
        \outBus, ~reverbBus
    ).play;
};

// Iniciar con densidad inicial y tipos de grano
~grainPattern = ~density.value(0.05, 0.1, 0, 0);

// Modificar la densidad y el tipo de grano cada 10 segundos
~changeDensity = {
    inf.do {
        ~grainPattern.stop;
        ~grainPattern = ~density.value(
            0.05.rand2(0.2), // minTime
            (0.2.rand2(0.5)).abs, // maxTime
            0, // typeMin
            2 // typeMax
        );
        10.wait;
    };
}.fork;

// Parar el cambio de densidad y el patrón de grano
~stopPatterns = {
    ~changeDensity.stop;
    ~grainPattern.stop;
    ~reverb.free;
};
)

// Ejecutar ~changeDensity para iniciar el cambio automático en la densidad y tipo de grano
~changeDensity;
