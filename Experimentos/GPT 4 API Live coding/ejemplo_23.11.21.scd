// código de live coding generado por api sentencia a sentencia, devolviendo errores y subsanando.
// Chat terminado al final de la sesión: https://platform.openai.com/playground/p/XHTQ91QOeRmZoHUriyXgenni?model=gpt-4-1106-preview&mode=chat


(
SynthDef(\evolvingPad, {
    |freq = 200, amp = 0.4, pan = 0|
    var sound = SinOsc.ar(freq, 0, amp) * EnvGen.ar(Env.perc(0.01, 1, 0.2), doneAction: 2);
    Out.ar(0, Pan2.ar(sound, pan));
}).add;
)



(
Pbindef(\padPattern,
    \instrument, \evolvingPad,
    \dur, Pseq([0.25, 0.5, 0.75, 1], inf),
    \freq, Pexprand(100, 800, inf),
    \amp, 0.5,
    \pan, Pwhite(-1, 1)
).play;
);

(
SynthDef(\percussiveHits, {
    |freq = 440, amp = 0.5, pan = 0, decay = 0.4|
    var env, sound;
    env = Env.perc(0.01, decay, amp, -4);
    sound = SinOsc.ar(freq) * EnvGen.ar(env, doneAction: 2);
    Out.ar(0, Pan2.ar(sound, pan));
}).add;
)

(
Pbindef(\hitPattern,
    \instrument, \percussiveHits,
    \dur, 0.5,
    \freq, Pseq([440, 660, 880, 990], inf),
    \amp, 0.05,
    \decay, 0.1,
    \pan, Pseq([-1, 0, 1], inf)
).play;
);


(
SynthDef(\texturedDrone, {
    |amp = 0.3, pan = 0|
    var sound = LFSaw.ar([0.1, 0.14]) * 0.02;
    sound = sound + CombN.ar(sound, 0.5, [0.2, 0.25], 4);
    Out.ar(0, Pan2.ar(sound, pan, amp));
}).add;
)

(
Pbindef(\dronePattern,
    \instrument, \texturedDrone,
    \dur, 4,
    \amp, Pseq([0.2, 0.25, 0.3], inf),
    \pan, Pseq([Pwhite(-1, 1), Pwhite(-1, 1), Pwhite(-1, 1)], inf)
).play;
);

(
SynthDef(\bubblyPlucks, {
    |freq = 440, amp = 0.3, pan = 0, atk = 0.005, rel = 0.2|
    var env, sound;
    env = Env.perc(atk, rel, amp, -4);
    sound = Pluck.ar(WhiteNoise.ar(amp), Impulse.kr(4), freq.reciprocal, release: rel) * EnvGen.ar(env);
    Out.ar(0, Pan2.ar(sound, pan));
}).add;
)

(
SynthDef(\bubblyPlucks, {
    |freq = 440, amp = 0.3, pan = 0, atk = 0.005, rel = 0.2|
    var env, sound;
    env = Env.perc(atk, rel, amp, -4);
    sound = Pluck.ar(WhiteNoise.ar(amp), Impulse.kr(4), freq.reciprocal, rel) * EnvGen.ar(env);
    Out.ar(0, Pan2.ar(sound, pan));
}).add;
)


(
Pbindef(\pluckPattern,
    \instrument, \bubblyPlucks,
    \dur, Pseq([0.1, 0.15, 0.2, 0.25], inf),
    \freq, Pexprand(300, 900, inf),
    \amp, 0.1,
    \pan, Pwhite(-1, 1)
).play;
);

Pbindef(\padPattern, \dur, Pseq([0.5, 0.75, 1, 1.5], inf));

Pbindef(\hitPattern, \freq, Pseq([523.25, 659.26, 783.99, 1046.5], inf));

Pbindef(\dronePattern, \amp, Pseq([0.15, 0.2, 0.25, 0.3], inf));


























