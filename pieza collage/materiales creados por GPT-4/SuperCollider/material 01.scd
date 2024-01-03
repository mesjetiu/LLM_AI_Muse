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
Pdef(\buckyballBold, Pbind(\instrument, \acidBold, \dur, Pseq([0.25, 0.5, 0.75], inf), \root, [-24, -17],
    \degree, Pseq([0, 3, 5, 7, 9, 11, [5, 17], 1], inf), \pan, Pfunc({[1.0.rand2, 1.0.rand2]}),
    \cut, Pxrand([1000, 500, 2000, 300], inf), \rez, Pfunc({0.7.rand +0.3}), \amp, [0.15, 0.22])).play;
)

(
Pdef(\buckyballBold, Pbind(\instrument, \acidBold, \dur, Pseq([0.25, 0.5, 0.75], inf), \root, [-24, -17],
    \degree, Pseq([0b, 3b, 5b, 7b, 9b, 11b, 5b, 0b], inf), \pan, Pfunc({1.0.rand2}),
    \cut, Pxrand([1000, 500, 2000, 300], inf), \rez, Pfunc({0.7.rand +0.3}), \amp, 0.3)).play;
)
