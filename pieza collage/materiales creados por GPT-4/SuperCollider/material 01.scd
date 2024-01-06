// Grabado en path: '/home/carlos/.local/share/SuperCollider/Recordings/SC_240105_164828.wav'



(
SynthDef(\acidBold, {
    arg out, freq = 1000, gate = 1, pan = 1, cut = 4000, rez = 0.8, amp = 1, lfoFreq = 0.25;
    var lfo, source;
    lfo = SinOsc.kr(lfoFreq).range(800, 2000);  // LFO para modulación de frecuencia
    source = Pulse.ar(freq + lfo, 0.05);
    Out.ar(out,
        Pan2.ar(
            RLPF.ar(
                source,
            cut * LFNoise1.kr(1).range(0.8,1.2),  // Modulación de cut
            rez + LFNoise1.kr(0.5).range(-0.1, 0.1)),  // Modulación de resonancia
        pan) * EnvGen.kr(Env.perc(0.01, 0.3), gate, amp, doneAction: Done.freeSelf);
    )
}).add;
)

(
Pbind(\instrument, \acidBold, \dur, Pseq([0.25, 0.5, 0.75], inf), \root, -12,
    \degree, Pseq([0, 3, 6, 9, 12, 15, 18, 21], inf),  // Grados modificados
    \pan, Pfunc({1.0.rand2}),
    \cut, Pxrand([1000, 500, 2000, 300], inf),
    \rez, Pfunc({0.7.rand +0.3}), \amp, 0.3).play;
)

(
Pdef(\buckyballBold, Pbind(\instrument, \acidBold, \dur, Pseq([0.06, 0.07, 0.02, 0.01], inf), \root, [-24, -17],
    \degree, Pseq([2, 3, 20, 7, 1, 11, [5, 17], 30], inf)+22, \pan, Pfunc({[1.0.rand2, 1.0.rand2]}),
    \cut, Pxrand([1000, 500, 2000, 300], inf), \rez, Pfunc({0.7.rand +0.3}), \amp, [0.15, 0.22])).play;
)

(
Pdef(\buckyballBold, Pbind(\instrument, \acidBold, \dur, Pseq([0.25, 0.5, 0.75], inf), \root, [-24, -17],
    \degree, Pseq([0b, 3b, 5b, 7b, 9b, 11b, 5b, 0b], inf), \pan, Pfunc({1.0.rand2}),
    \cut, Pxrand([1000, 500, 2000, 300], inf), \rez, Pfunc({0.7.rand +0.3}), \amp, 0.3)).play;
)

(
Pdef(\randomRhythm, Pbind(
  \instrument, \acidBold,
  \dur, Pwhite(0.03, 0.05, inf),  // Duraciones aleatorias entre 0.1 y 1.0 segundos
  \degree, Pseq([0, 10, 4, 2, 7, 9, 11]-24, inf),
  \pan, Pwhite(-1, 1, inf),  // Pan aleatorio
  \cut, Prand([500, 1000, 1500, 2000], inf),
  \rez, Pwhite(0.3, 0.8, inf),  // Resonancia aleatoria
  \amp, Pwhite(0.1, 0.5, inf)  // Amplitud aleatoria
)).play;
)