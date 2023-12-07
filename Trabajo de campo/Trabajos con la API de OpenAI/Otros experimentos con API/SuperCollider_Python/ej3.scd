// Iniciar el servidor de SuperCollider - 3 segundos
s.boot;

// Definir un patrón rítmico y tonal básico - 4 segundos
(
Pbindef(\rhythm,
    \instrument, \default,
    \dur, 0.25,
    \freq, Pseq([440, 660, 880, 550], inf)
).play;
);

// Añadir un poco de variación rítmica - 6 segundos
(
Pbindef(\rhythm,
    \dur, Pseq([0.25, 0.5, 0.25, 0.25], inf)
);
);

// Introducir un efecto de panning - 5 segundos
(
Pbindef(\rhythm,
    \pan, Pseq([-1, 1], inf)
);
);

// Modificar la secuencia de frecuencias - 6 segundos
(
Pbindef(\rhythm,
    \freq, Pseq([261.63, 293.66, 329.63, 349.23], inf)
);
);

// Añadir un efecto de reverberación - 5 segundos
(
Pbindef(\rhythm,
    \effect, \reverb,
    \mix, 0.2
);
);

// Aumentar la mezcla de reverberación - 4 segundos
(
Pbindef(\rhythm,
    \mix, 0.4
);
);

// Detener el patrón - 3 segundos
Pbindef(\rhythm).stop;

// Detener todos los sonidos y el servidor - 3 segundos
s.freeAll;
s.quit;
