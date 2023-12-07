// Haz un patch en supercollider para hacer live coding. Que tenga cierta complejidad, desde el primer momento. Comenzamos con una textura interesante
(
Ndef(\s, { |out=0|
    var sig = LFSaw.ar([100, 101], 0, 0.5, 0.5);
    Out.ar(out, sig);
}).play;
)

// Modificamos el código para que sea más complejo
(
Ndef(\s, { |out=0|
    var sig = LFSaw.ar([100, 101], 0, 0.5, 0.5);
    sig = sig + LFSaw.ar([100, 101], 0, 0.5, 0.5);
    Out.ar(out, sig);
}).play;
)

// menos rugoso el sonido y con más elementos...
(
Ndef(\s, { |out=0|
    var sig = LFSaw.ar([100, 101], 0, 0.5, 0.5);
    sig = sig + LFSaw.ar([100, 101], 0, 0.5, 0.5);
    sig = sig + LFSaw.ar([100, 101], 0, 0.5, 0.5);
    sig = sig + LFSaw.ar([100, 101], 0, 0.5, 0.5);
    Out.ar(out, sig);
}).play;
)

// ahora con un filtro
(
Ndef(\s, { |out=0|
    var sig = LFSaw.ar([100, 101], 0, 0.5, 0.5);
    sig = sig + LFSaw.ar([100, 101], 0, 0.5, 0.5);
    sig = sig + LFSaw.ar([100, 101], 0, 0.5, 0.5);
    sig = sig + LFSaw.ar([100, 101], 0, 0.5, 0.5);
    sig = LPF.ar(sig, 1000);
    Out.ar(out, sig);
}).play;
)
)

// para hacer que el fade sea más lento

(
Ndef(\s, { |out=0|
    var sig = LFSaw.ar([100, 101], 0, 0.5, 0.5);
    sig = sig + LFSaw.ar([100, 101], 0, 0.5, 0.5);
    sig = sig + LFSaw.ar([100, 101], 0, 0.5, 0.5);
    sig = sig + LFSaw.ar([100, 101], 0, 0.5, 0.5);
    sig = LPF.ar(sig, 1000);
    sig = sig * 0.5;
    Out.ar(out, sig);
}).play;
)


// fadetime del Ndef de 8 segundos
(
Ndef(\s, { |out=0|
    var sig = LFSaw.ar([100, 101], 0, 0.5, 0.5);
    sig = sig + LFSaw.ar([100, 101], 0, 0.5, 0.5);
    sig = sig + LFSaw.ar([100, 101], 0, 0.5, 0.5);
    sig = sig + LFSaw.ar([100, 101], 0, 0.5, 0.5);
    sig = LPF.ar(sig, 1000);
    sig = sig * 0.5;
    Out.ar(out, sig);
}).play;
)



// 1. variando la frecuencia de los osciladores
(
Ndef(\s, { |out=0|
    var sig = LFSaw.ar([100, 101], 0, 0.5, 0.5);
    sig = sig + LFSaw.ar([100.1, 101.1], 0, 0.5, 0.5);
    sig = sig + LFSaw.ar([100.2, 101.2], 0, 0.5, 0.5);
    sig = sig + LFSaw.ar([100.3, 101.3], 0, 0.5, 0.5);
    sig = LPF.ar(sig, 1000);
    sig = sig * 0.5;
    Out.ar(out, sig);
}).play;
)

// el anterior es muy bueno, hagamos más variaciones interesantes, cambiando técnicas de síntesis

// usando granulado como base de la textura sonora
(
Ndef(\s, { |out=0|
    var sig = GrainSin.ar(2, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1);
    sig = sig + GrainSin.ar(2, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1);
    sig = sig + GrainSin.ar(2, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1);
    sig = sig + GrainSin.ar(2, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1);
    sig = LPF.ar(sig, 1000);
    sig = sig * 0.5;
    Out.ar(out, sig);
}).play;
)

// establecemos fadetime fijo para cualquier cambio de Ndef \s

Ndef(\s).fadeTime = 8;