// Sentencia para iniciar el servidor - 1 segundos
s.boot;

// Bloque para crear un sintetizador simple - 2 segundos

(SynthDef(\simpleSynth, {|freq = 440, amp = 0.5| var audio; audio = SinOsc.ar(freq, 0, amp); Out.ar(0, audio);}).add;)


// Sentencia para crear una instancia del sintetizador - 5 segundos
x = Synth(\simpleSynth, [\freq, 261.63, \amp, 0.5]);

// Sentencia para detener todos los sonidos y el servidor - 5 segundos
s.freeAll;
s.quit;
