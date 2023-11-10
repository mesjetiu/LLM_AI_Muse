// https://platform.openai.com/playground?assistant=asst_jRoEFqfb7RegBABBvS7qEi1i&mode=assistant&thread=thread_JY2yteYepvLpbTxeXE48XoHM
// 10/11/2023
// SC Assistant
// No muy interesante

(
s.waitForBoot {
    // Definición de la escala exótica.
    var scaleDegrees = [0, 1, 3, 7, 8];
    var root = 60; // MIDI note number para C4.
    var scale = scaleDegrees.collect({ |deg| (deg + root).midicps });

    // Definición del SynthDef para la extrapolación FM.
    SynthDef(\fmExtravaganza, {
        arg freq = 440, index = 3, modRatio = 1.4, amp = 0.2, pan = 0, dur = 1;
        var modulator, carrier, env, filterFreq, modIndex, reverb, signal;

        env = EnvGen.kr(Env.perc(0.01, dur, 1, -4), doneAction: 2);
        filterFreq = freq * LFNoise1.kr(0.2).range(0.5, 2);
        modIndex = LFNoise1.kr(0.1).range(0, 3) * index;
        modulator = SinOsc.ar(freq * modRatio, mul: modIndex);
        carrier = SinOsc.ar(freq + modulator, mul: env);

        // Aplicar efectos.
        reverb = JPverb.ar(carrier, t60: LFNoise1.kr(0.01).exprange(1, 20), damp: LFNoise1.kr(0.05).range(0.1, 0.5)) * amp;
        signal = Pan2.ar(reverb, LFNoise1.kr(0.5).range(-1, 1));

        Out.ar(0, signal);
    }).add;

    // Reproducción del patrón.
    Pbind(
        \instrument, \fmExtravaganza,
        \freq, Prand(scale, inf),
        \index, Pexprand(1, 10, inf),
        \modRatio, Pbrown(0.5, 2.0, 0.1, inf),
        \dur, Pwhite(0.3, 0.7, inf),
        \amp, Pwhite(0.1, 0.5, inf)
    ).play;
}
)