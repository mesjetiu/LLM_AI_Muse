//  Sesión de Live coding dirigida por chat. Parada por estancamiento. Requiere de mucho feedback. Demasiado.
// https://chat.openai.com/share/0d82133a-d50e-4077-9578-7d5e2e861e8c


// Iniciar el servidor de sonido
s.boot;

(
// Crear un NodeProxy de audio estéreo
~ritmo = { |tempo=1|
    var kick, snare, hat;
    kick = SinOsc.ar(60, 0, 0.5) * EnvGen.kr(Env.perc(0.01, 0.2), Impulse.kr(4/tempo));
    snare = WhiteNoise.ar(0.2) * EnvGen.kr(Env.perc(0.01, 0.1), Impulse.kr(2/tempo, 0.5));
    hat = WhiteNoise.ar(0.1) * EnvGen.kr(Env.perc(0.005, 0.08), Impulse.kr(8/tempo, 0.25));
    [kick + snare, hat]
}.play;
)

(
// Crear un NodeProxy para el bajo
~bajo = { |freq=440, amp=0.6, tempo=1|
    var osc, env;
    osc = SinOsc.ar(freq, 0, amp);
    env = EnvGen.kr(Env.perc(0.01, 0.5, amp, -4), Impulse.kr(1/tempo));
    osc * env
}.play;
)

// Ahora vamos a definir una secuencia para el bajo
(
Pdef(\bajoPat, Pbind(
    \instrument, \default,
    \freq, Pseq([60, 63, 65, 60, 63, 67, 70, 72].midicps, inf),
    \dur, 0.25,
    \amp, 0.6
)).play;
)

// Conecta el bajo con el ritmo
~bajo.set(\freq, Pdef(\bajoPat));

// Ejecuta este código y déjalo correr por otros 2 minutos.


// Redefinir la melodía con una nueva secuencia de notas
(
~melodia.stop; // Detenemos el NodeProxy actual antes de redefinirlo
~melodia = { |tempo=1, dur=0.25|
    var nota, env, osc;
    var scale = [72, 74, 76, 79, 83].midicps; // Nueva secuencia de notas
    nota = Pseq(scale, inf).asStream;
    env = EnvGen.kr(Env.perc(0.01, dur, 0.3, -4), Impulse.kr(4/tempo));
    osc = SinOsc.ar(nota.next, 0, env);
    osc.dup
}.play;
)

// Redefinir el ritmo para cambiar el patrón del hi-hat
(
~ritmo.stop; // Detenemos el NodeProxy actual antes de redefinirlo
~ritmo = { |tempo=1|
    var kick, snare, hat;
    kick = SinOsc.ar(60, 0, 0.5) * EnvGen.kr(Env.perc(0.01, 0.2), Impulse.kr(4/tempo));
    snare = WhiteNoise.ar(0.2) * EnvGen.kr(Env.perc(0.01, 0.1), Impulse.kr(2/tempo, 0.5));
    hat = WhiteNoise.ar(0.1) * EnvGen.kr(Env.perc(0.005, 0.05), Impulse.kr(16/tempo, 0.25)); // Más rápido
    [kick + snare, hat]
}.play;
)

// Ahora hemos actualizado la melodía y el ritmo. Ejecuta este código y déjalo correr por 2 minutos.

// Ejecuta este código y déjalo correr por 2 minutos.

