(
SynthDef(\dual_osc, {
    arg out=0, freq1=440, freq2=660, sustain=0.2;
    var env, sig;
    env = EnvGen.kr(Env.perc(0.01, sustain), doneAction: Done.freeSelf);
    sig = SinOsc.ar([freq1, freq2], 0) * env;
    Out.ar(out, sig);
}).add;
)

(
var freqPattern1, freqPattern2;
freqPattern1 = Pbrown(0.0, 1.0, 0.05, inf).asStream;
freqPattern2 = Pwhite(0.0, 1.0, inf).asStream;

{
    loop {
        var freq1, freq2;
        freq1 = freqPattern1.next * 400 + 100;
        freq2 = freqPattern2.next * 400 + 100;
        Synth(\dual_osc, [\freq1, freq1, \freq2, freq2]);
        0.1.wait;
    }
}.fork;
)
