// Sentencia para iniciar el servidor - 1 segundos
s.boot;

// Bloque para crear un sintetizador simple - 1 segundos
SynthDef(\simpleSynth, {
    |freq = 440, amp = 0.5|
    var audio;
    audio = SinOsc.ar(freq, 0, amp);
    Out.ar(0, audio);
}).add;

// Sentencia para crear una instancia del sintetizador - 5 segundos
x = Synth(\simpleSynth, [\freq, 261.63, \amp, 0.5]);

// Bloque para modificar los parámetros del sintetizador con el tiempo - 5 segundos
x.set(\freq, 523.25);
x.set(\amp, 0.3);

// Sentencia para liberar el sintetizador - 3 segundos
x.free;

// Bloque para crear y manipular un sintetizador más complejo - 12 segundos
SynthDef(\complexSynth, {
    |freq = 440, amp = 0.5, pan = 0|
    var audio;
    audio = Saw.ar(freq) * EnvGen.kr(Env.perc, doneAction: 2);
    audio = Pan2.ar(audio, pan, amp);
    Out.ar(0, audio);
}).add;


// Esperar - 3 segundos
y = Synth(\complexSynth);

// Sentencia para detener todos los sonidos y el servidor - 5 segundos
s.freeAll;
s.quit;
