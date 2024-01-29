(
SynthDef(\atmosfera, {
    | out = 0, freq = 440, amp = 0.3, pan = 0 |
    var sonido, env, modFreq, modAmp, modFilter, ruido, mezcla, reverb, delay;

    // Envolvente larga para una evolución lenta
    env = EnvGen.kr(Env.linen(10, 1, 20, 0.1), doneAction: 2);

    // Ruido de fondo más suave y menos directo
    ruido = Mix.new([PinkNoise.ar(0.03), BrownNoise.ar(0.02)]);

    // Modulaciones más orgánicas y menos predecibles
    modFreq = LFNoise1.kr(0.1.rand).range(0.98, 1.02) * freq;
    modAmp = LFNoise2.kr(0.1.rand).range(0.6, 1) * amp;
    modFilter = LFNoise2.kr(0.3.rand).range(300, 600);

    // Fuente de sonido principal y su modulación
    sonido = SinOsc.ar(modFreq, 0, modAmp);
    sonido = LPF.ar(sonido + ruido, modFilter) * env;

    // Espacialización y efectos
    mezcla = Pan2.ar(sonido, pan);
    reverb = GVerb.ar(mezcla, 40, 10, 0.5, 0.5, 15, 1, 0.7, 0.5);
    delay = CombL.ar(reverb, 0.4, LFNoise1.kr(0.1.rand).range(0.2, 0.3), 3);

    Out.ar(out, delay);
}).add;

// Crear instancias con frecuencias y posiciones estéreo variadas
Synth(\atmosfera, [\freq, 261.63, \pan, -0.5]);
Synth(\atmosfera, [\freq, 293.66, \pan, 0]);
Synth(\atmosfera, [\freq, 329.63, \pan, 0.5]);
)
