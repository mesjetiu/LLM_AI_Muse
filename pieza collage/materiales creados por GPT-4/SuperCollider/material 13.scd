// Grabadas dos versiones:

//path: '/home/carlos/.local/share/SuperCollider/Recordings/SC_240105_174012.wav'

//path: '/home/carlos/.local/share/SuperCollider/Recordings/SC_240105_174107.wav'


(
// Inicialización de la orquestación
s.waitForBoot {
    var introDur = 10, desarrolloDur = 20, interactivoDur = 15, climaxDur = 15, cierreDur = 5;
    var totalDur = introDur + desarrolloDur + interactivoDur + climaxDur + cierreDur;
    var timeline;

    timeline = Routine {
        // Introducción con gabor e imp
        Synth(\gabor, [freq: 440, pan: 0, width: 0.3, sustain: introDur]);
        Synth(\imp, [freq: 440, speed: 1, begin: 0, end: 1, pan: 0, accelerate: 0.5, offset: 0, sustain: introDur]);
        (introDur).wait;

        // Desarrollo con psin y pmsin
        Synth(\psin, [freq: 440, speed: 1, begin: 0, end: 1, pan: 0, accelerate: 0.5, offset: 0, modfreq: 40, sustain: desarrolloDur]);
        Synth(\pmsin, [freq: 440, speed: 1, begin: 0, end: 1, pan: 0, accelerate: 0.5, offset: 0, sustain: desarrolloDur]);
        (desarrolloDur).wait;

        // Interacción en vivo con in e in1
        Synth(\in, [soundin: 0, pan: 0, inputFadeTime: 0.03, sustain: interactivoDur]);
        Synth(\in1, [soundin: 0, pan: 0, inputFadeTime: 0.03, sustain: interactivoDur]);
        (interactivoDur).wait;

        // Climax con una mezcla de synths
        // Aquí puedes añadir más Synths según tu preferencia
        (climaxDur).wait;

        // Cierre con gabor y dirac
        Synth(\gabor, [freq: 440, pan: 0, width: 0.3, sustain: cierreDur]);
        Synth(\dirac, [pan: 0, sustain: cierreDur]);
        (cierreDur).wait;
    };

    timeline.play;
};
)
