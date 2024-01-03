(
SynthDef(\fmSynthNoReverb, {
    arg freq=440, mDepth=100, mFreq=5, dur=1, amp=0.5, pan=0;
    var modulator, carrier, env, signal;

    env = EnvGen.kr(Env.perc(0.01, dur, 1, -1), doneAction: 2);

    modulator = SinOsc.ar(mFreq) * mDepth;
    carrier = SinOsc.ar(freq + modulator);
    signal = carrier + (SinOsc.ar(freq * 2 + modulator * 0.5) * 0.5);
    signal = signal * env * amp;

    // Aplicar panorámica
    signal = Pan2.ar(signal, pan);

    // Enviar a un bus de audio en lugar de la salida principal
    Out.ar(\bus.kr(0), signal);
}).add;
)

(
SynthDef(\reverbSynth, {
    arg bus, mix=0.2, room=0.8;
    var inSignal;

    inSignal = In.ar(bus, 2);
    inSignal = FreeVerb.ar(inSignal, mix: mix, room: room);

    // Devolver el sonido procesado al bus principal
    Out.ar(0, inSignal);
}).add;
)

// Configurar el bus
~reverbBus = Bus.audio(s, 2);

// Iniciar el Synth de reverberación
~reverbSynth = Synth(\reverbSynth, ['bus': ~reverbBus]);

// Pbind
(
Pbind(
    \instrument, \fmSynthNoReverb,
    \freq, Pwhite(300, 600, inf),
    \mDepth, Pwhite(50, 500, inf),
    \mFreq, Pseq([Pwhite(2, 10, 1), Pwhite(100, 1000, 1)], inf),
    \dur, Pwhite(0.2, 1, inf),
    \amp, Pwhite(0.3, 0.7, inf),
    \pan, Pwhite(-1, 1, inf),  // Valores entre -1 (izquierda) y 1 (derecha)
    \bus, ~reverbBus   // Enviar al bus de reverberación
).play;
)
