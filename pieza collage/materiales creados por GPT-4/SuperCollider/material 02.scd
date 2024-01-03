(
// Primera capa: Ritmo percusivo
Ndef(\a,
    \setsrc -> Pbind(\source,
        Pseq([
            { WhiteNoise.ar() * EnvGen.kr(Env.perc, doneAction:2) * 0.1 },
            { Impulse.ar(4 + [0,1]) * 0.1 },
        ], inf),
        \dur, Prand([0.25, 0.5, 0.75], inf)
    )
).play;

// Segunda capa: Melodía
Ndef(\b,
    \setsrc -> Pbind(\source,
        Pseq([
            { SinOsc.ar([440, 442]) * 0.2 },
            { Saw.ar([330, 332]) * 0.1 },
        ], inf),
        \dur, Prand([1, 1.5, 2], inf)
    )
).play;

// Tercera capa: Textura armónica
Ndef(\c,
    \setsrc -> Pbind(\source,
        Pseq([
            { Pulse.ar([110, 112]) * 0.1 },
            { LFTri.ar(LFNoise1.kr(1).range(200,300) + 1 * 180 + [0,1], 0.04) * 0.2 },
        ], inf),
        \dur, Prand([2, 3, 4], inf)
    )
).play;
)
