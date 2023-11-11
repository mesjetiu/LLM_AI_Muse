// https://platform.openai.com/playground?assistant=asst_vC9nmZAe8RcBA2s0kFM4roFj&mode=assistant&thread=thread_i1XHLNH57r1duSZU5x7nWn5h
// 11/11/2023
// Assistant v2
// Creo que mejor que los más avanzados. Al menos no peor.

(
SynthDef.new(\birds, {
    var env, freq, sig, modFreq, pan;
    modFreq = LFNoise1.kr(rrand(0.5, 2)).range(5, 15);
    env = Env.perc(0.01, 0.1, 0.1).kr(doneAction: 2);
    freq = LFDNoise3.kr(modFreq).exprange(4000, 8000);
    sig = SinOsc.ar(freq) * env;
    pan = LFNoise2.kr(0.5).range(-1, 1);
    Out.ar(0, Pan2.ar(sig, pan));
}).add;

SynthDef.new(\wind, {
    var sig, filt, env, ampMod;
    ampMod = LFNoise1.kr(0.2).range(0.2, 0.7);
    env = Env.linen(2, 10, 2, 1).kr(doneAction: 2);
    sig = WhiteNoise.ar(ampMod);
    filt = BPF.ar(sig, LFNoise1.kr(rrand(0.05, 0.1)).range(150, 250), 0.1) * 0.25;
    Out.ar(0, Pan2.ar(filt * env, LFNoise2.kr(rrand(0.3, 0.5)).range(-1, 1)));
}).add;

SynthDef.new(\leaves, {
    var sig, mod, env;
    env = Env.linen(0.1, 8, 0.1, 0.3).kr(doneAction: 2);
    sig = Dust2.ar(LFNoise2.kr(1).range(50, 400));
    mod = LFNoise1.kr(4).range(0, 0.5);
    Out.ar(0, Pan2.ar(sig * mod * env, LFNoise1.kr(rrand(0.4, 0.6)).range(-1, 1)));
}).add;

SynthDef.new(\insects, {
    var sig, env;
    env = Env.linen(2, 12, 2, 0.1).kr(doneAction: 2);
    sig = Mix.fill(2, {
        LFPulse.ar(rrand(40, 120), 0, LFNoise2.kr(1).range(0.1, 0.5)) * 0.05
    });
    Out.ar(0, Pan2.ar(sig * env, LFNoise1.kr(0.5).range(-1, 1)));
}).add;

Pbind(
    \instrument, \birds,
    \dur, Pfunc({ rrand(0.1, 0.8) }),
    \amp, Pfunc({ rrand(0.3, 0.6) })
).play;

Pbind(
    \instrument, \wind,
    \dur, 1,
    \amp, Pfunc({ rrand(0.2, 0.4) })
).play;

Pbind(
    \instrument, \leaves,
    \dur, Pwrand([0.1, 0.2, 0.5], [0.5, 0.3, 0.2], inf),
    \amp, Pfunc({ rrand(0.1, 0.4) })
).play;

Pbind(
    \instrument, \insects,
    \dur, Pwrand([0.3, 0.7, 1], [0.5, 0.3, 0.2], inf),
    \amp, Pfunc({ rrand(0.05, 0.2) })
).play;
)