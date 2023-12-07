// https://platform.openai.com/playground?assistant=asst_NABNalYvxGCNywJhkKPFVZkV&mode=assistant&thread=thread_72WztTVZJ53sguPZz8ZJUV9T
// Assistant v4
// 11/11/2023
// respuesta antes de errores...
(
s.waitForBoot {
    // Define el sintetizador de canto de pájaros
    SynthDef(\pajaros, {
        |out=0, freq=2000, amp=0.1|
        var env, sig, dur;
        dur = rrand(0.1, 0.5);
        env = Env.perc(0.01, dur, amp, -4).kr(doneAction: 2);
        sig = SinOsc.ar(freq, 0, env);
        Out.ar(out, Pan2.ar(sig, LFNoise2.kr(5).range(-1, 1)));
    }).add;

    // Define el sintetizador de viento
    SynthDef(\viento, {
        |out=0, amp=0.2|
        var sig;
        sig = WhiteNoise.ar(LPF.ar(WhiteNoise.ar(), 500)) * amp;
        Out.ar(out, sig ! 2);
    }).add;

    // Define el sintetizador de hojas
    SynthDef(\hojas, {
        |out=0, amp=0.1|
        var sig;
        sig = PinkNoise.ar(amp);
        sig = sig * LFNoise1.kr(1).range(0.3, 1);
        Out.ar(out, sig ! 2);
    }).add;

    // Define el sintetizador de insectos
    SynthDef(\insectos, {
        |out=0, freq=6000, amp=0.05|
        var env, sig, dur;
        dur = rrand(0.6, 1.0);
        env = Env.linen(0.1, dur, 0.1, amp, -4).kr(doneAction: 2);
        sig = SinOsc.ar(freq, 0, env);
        Out.ar(out, Pan2.ar(sig, LFNoise2.kr(3).range(-1, 1)));
    }).add;

    // Lanzar los Synths de pájaros e insectos con un temporizador
    fork {
        inf.do {
            Synth(\pajaros, [
                freq: rrand(1500, 4500),
                amp: rrand(0.05, 0.2),
            ]);
            (rrand(0.5, 2)).wait;
        }
    };

    fork {
        inf.do {
            Synth(\insectos, [
                freq: rrand(4000, 8000),
                amp: rrand(0.03, 0.08),
            ]);
            (rrand(1, 3)).wait;
        }
    };

    // Sintetizadores estáticos de viento y hojas
    Synth(\viento);
    Synth(\hojas);
}
)