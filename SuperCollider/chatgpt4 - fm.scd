/*
https://chat.openai.com/share/72cf2979-ecd4-4451-9d46-f822bb85522b

"User
crea un script en supercollider que genere un sonido variable, con base en la frecuencia modulada. Utiliza Pbind y construye tu propio synthdef. Asegúrate de que cada evento tiene un principio y un fin, liberando los synths adecuadamente.
Construye el proyecto en fases. Para ello, tu primera respuesta quiero que sea unas reflexiones tuyas de cómo construirías el proyecto, a modo de apuntes, para asegurarte de que harás bien la sintaxis y las especificaciones, pero no se trata de la respuesta final. Una vez hayas hecho esta respuesta intemedia, te diré que continues con la respuesta final, y entonces sí, darás un código final."

*/


(
SynthDef(\fmSynth, {
    arg freq=440, mDepth=100, mFreq=5, dur=1, amp=0.5;
    var modulator, carrier, env;

    // Envolvente ADSR
    env = EnvGen.kr(Env.perc(0.01, dur, 1, -1), doneAction: 2);

    // Oscilador modulador
    modulator = SinOsc.ar(mFreq) * mDepth;

    // Oscilador portador
    carrier = SinOsc.ar(freq + modulator) * env * amp;

    Out.ar(0, [carrier, carrier]); // Salida estéreo
}).add;
)

(
Pbind(
    \instrument, \fmSynth,
    \freq, Pwhite(300, 600, inf),  // Frecuencias entre 300 y 600 Hz
    \mDepth, Pwhite(50, 150, inf),  // Profundidad de modulación entre 50 y 150
    \mFreq, Pwhite(2, 10, inf),  // Frecuencia del modulador entre 2 y 10 Hz
    \dur, 0.5,  // Duración de 0.5 segundos por evento
    \amp, 0.5   // Amplitud fija de 0.5 para todos los eventos
).play;
)




/*
"ok, siguiendo el mismo procedimiento (respuesta intermedia de proyecto y respuesta final), modifica el código para que sea mucho más interesante. Me interesan las frecuencas moduladas en alta frecuencia, quizás combinadas con modulaciones en baja frecuencia (tal como tienes ahora), con la finalidad de explorar timbres, ya que la baja frecuencia de modulación solo produce vibratos, pero no consigue nuevas tímbricas."
*/

(
SynthDef(\fmSynthEnhanced, {
    arg freq=440, mDepth=100, mFreq=5, dur=1, amp=0.5;
    var modulator, carrier, env, signal;

    env = EnvGen.kr(Env.perc(0.01, dur, 1, -1), doneAction: 2);

    // Oscilador modulador
    modulator = SinOsc.ar(mFreq) * mDepth;

    // Oscilador portador
    carrier = SinOsc.ar(freq + modulator);

    // Suma de osciladores para enriquecer el timbre
    signal = carrier + (SinOsc.ar(freq * 2 + modulator * 0.5) * 0.5);
    signal = signal * env * amp;

    // Efecto de reverberación
    signal = FreeVerb.ar(signal, mix: 0.2, room: 0.8);

    Out.ar(0, [signal, signal]);
}).add;
)

(
Pbind(
    \instrument, \fmSynthEnhanced,
    \freq, Pwhite(300, 600, inf),
    \mDepth, Pwhite(50, 500, inf),  // Mayor rango para mDepth
    \mFreq, Pseq([Pwhite(2, 10, 1), Pwhite(100, 1000, 1)], inf),  // Combinación de baja y alta frecuencia
    \dur, Pwhite(0.2, 1, inf),  // Variación en la duración
    \amp, Pwhite(0.3, 0.7, inf)   // Variación en la amplitud
).play;
)

/*
"ok, me gustaría explorar el campo stereo fónico, con múltiples instancias de estos sonidos. ¿Sería posible? De nuevo, primero planifica, y después implementa."
*/

(
SynthDef(\fmSynthEnhanced, {
    arg freq=440, mDepth=100, mFreq=5, dur=1, amp=0.5;
    var modulator, carrier, env, signal;

    env = EnvGen.kr(Env.perc(0.01, dur, 1, -1), doneAction: 2);

    // Oscilador modulador
    modulator = SinOsc.ar(mFreq) * mDepth;

    // Oscilador portador
    carrier = SinOsc.ar(freq + modulator);

    // Suma de osciladores para enriquecer el timbre
    signal = carrier + (SinOsc.ar(freq * 2 + modulator * 0.5) * 0.5);
    signal = signal * env * amp;

    // Efecto de reverberación
    signal = FreeVerb.ar(signal, mix: 0.2, room: 0.8);

    Out.ar(0, [signal, signal]);
}).add;
)

(
Pbind(
    \instrument, \fmSynthEnhanced,
    \freq, Pwhite(300, 600, inf),
    \mDepth, Pwhite(50, 500, inf),  // Mayor rango para mDepth
    \mFreq, Pseq([Pwhite(2, 10, 1), Pwhite(100, 1000, 1)], inf),  // Combinación de baja y alta frecuencia
    \dur, Pwhite(0.2, 1, inf),  // Variación en la duración
    \amp, Pwhite(0.3, 0.7, inf)   // Variación en la amplitud
).play;
)


/*
"modifícalo. Quiero que haya más eventos, pero cada evento ha de tener un paneo difernete (aleatorio...). Quiero que todo pase a un synth de reverb, en lugar de tener el efecto dentro del propio synth, ya que cuando se termina el synth se termina la reverb...
Planifica con cuidado y después implementa"

*/

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


/*
Todo ok.

Busquemos cierta evolución en el tiempo. Ahora mismo es un proyecto con un resultado monótono. Lo escuchado los primeros 5 segundos en análogo a lo que se escucha todo el tiempo. Necesitamos dar variedad y evolución. Me interesan cambios progresivos del sonido, los eventos, sus parámetros, etc.
Como siempre, planifica primero con cuidado y con método, para finalmente implementar.

*/

~freqCurve = Pseg([300, 600, 400], [10, 10], \exp).asStream;
~mDepthCurve = Pseg([50, 500, 100], [10, 10], \lin).asStream;
~mFreqCurve = Pseg([2, 100, 5], [10, 10], \exp).asStream;
~durCurve = Pseg([1, 0.2, 0.8], [10, 10], \exp).asStream;

(
Pbind(
    \instrument, \fmSynthNoReverb,

    // Uso de las curvas de evolución
    \freq, Pfunc({ ~freqCurve.next }),
    \mDepth, Pfunc({ ~mDepthCurve.next }),
    \mFreq, Pfunc({ ~mFreqCurve.next }),
    \dur, Pfunc({ ~durCurve.next }),

    \amp, Pwhite(0.3, 0.7, inf),
    \pan, Pwhite(-1, 1, inf),  // Valores entre -1 (izquierda) y 1 (derecha)
    \bus, ~reverbBus   // Enviar al bus de reverberación
).play;
)
