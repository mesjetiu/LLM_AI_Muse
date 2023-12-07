// Interesante!
// https://platform.openai.com/playground?assistant=asst_jRoEFqfb7RegBABBvS7qEi1i&mode=assistant&thread=thread_W0hsopVAd3SiA1yT4zzNbB97
// SC Assitant
// 09/11/2023

(
s.waitForBoot {
    var numChannels = 2; // Estéreo

    s.options.numOutputBusChannels = numChannels;
    s.options.numInputBusChannels = numChannels;
    s.boot;

    SynthDef("grainTexture", {
        arg out=0, dur=2, rate=1, pan=0;
        var env, grain, freq;

        freq = LFNoise1.kr(0.5).exprange(200, 1200);

        grain = GrainSin.ar(
            numChannels: numChannels,
            trigger: Impulse.kr(10),
            dur: LFNoise2.kr(0.5).range(dur * 0.5, dur),
            pan: LFNoise2.kr(0.1).range(-1, 1),
            freq: freq,
            maxGrains: 50
        ) * 0.1;

        env = EnvGen.kr(Env.perc(0.01, 1), doneAction: 2);

        Out.ar(out, grain * env);
    }).add;

    Routine({
        inf.do {
            Synth("grainTexture", [
                \dur, rrand(0.1, 0.5),
                \rate, rrand(0.5, 2),
                \pan, rrand(-1, 1)
            ]);

            (rrand(0.1, 0.5)).wait;
        }
    }).play;
};
)