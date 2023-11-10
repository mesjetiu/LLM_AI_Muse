/* vamos a hacer una sesión de live coding con SuperCollider. Partiremos de un Pbindef que iremos modificando con toda suerte de patrones. Los patrones iniciales serán complejos, evitando secuencias de notas en forma de escala que restarían interés. Buscaremos patrones que mezclen diversas texturas y creen nuevas en conjunto. La impredecibilidad es uno de los objetivos. */

(
Pdef(\piano, Pbind(
    \instrument, \piano,
    \scale, Scale.minorPentatonic,
    \degree, Pseq([0, 1, 2, 3, 4, 5, 6, 7], inf),
    \dur, Pseq([0.25, 0.25, 0.25, 0.25, 0.25, 0.25, 0.25], inf),
    \amp, Pseq([0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5], inf),
    \legato, Pseq([0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5], inf),
    \octave, Pseq([4, 4, 4, 4, 4, 4, 4], inf),
    \pan, Pseq([0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5], inf),
    \blur, Pseq([0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5], inf),
    \legato, Pseq([0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5], inf),
    \sus, Pseq([0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5], inf),
    \atk, Pseq([0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5], inf),
    \rel, Pseq([0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5], inf),
)).play;
)

