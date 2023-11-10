// https://platform.openai.com/playground?assistant=asst_jRoEFqfb7RegBABBvS7qEi1i&mode=assistant&thread=thread_rBWh90uWsG61HOYB7AfsEC69
// 09/11/2023
// SC Assistant
// No llega a ninguna parte tras iterar. Cada vez peor...


// Define el SynthDef para FM Synthesis.
SynthDef(\fmSynth, { |freq = 440, modRatio = 2, index = 1, amp = 0.5|
    var modulator, carrier, env;

    // El oscilador modulador con su índice de modulación
    modulator = SinOsc.ar(freq * modRatio, 0, index);

    // El oscilador portador, modulado por el modulador
    carrier = SinOsc.ar(freq + modulator, 0, amp);

    // La envolvente asegura que el sonido no corta abruptamente
    env = EnvGen.ar(Env.perc(0.01, 1, 0.2, -4), doneAction: 2);

    // Emitimos la señal, multiplicando por la envolvente para que tenga un ataque y decaimiento suave
    Out.ar(0, carrier * env ! 2); // Estéreo
}).add;

// Inicia el servidor de audio si aún no está corriendo.
s.boot;

// Espera a que el SynthDef se haya cargado en el servidor.
s.sync;

// Crea la interfaz de usuario con Sliders para controlar los parámetros del Synth.
(
    var window, freqSlider, modRatioSlider, indexSlider, ampSlider, synth;

    // Crea la ventana de la UI
    window = Window.new("FM Synth Explorer", Rect(100, 100, 400, 300)).front;

    // Frecuencia del portador
    freqSlider = EZSlider.new(window, Rect(10, 10, 380, 20), "Carrier Freq", { |slider|
        synth.set(\freq, slider.value);
    }, 440, 20, 4000);

    // Relación de modulación
    modRatioSlider = EZSlider.new(window, Rect(10, 40, 380, 20), "Mod Ratio", { |slider|
        synth.set(\modRatio, slider.value);
    }, 2, 0.1, 20);

    // Índice de modulación
    indexSlider = EZSlider.new(window, Rect(10, 70, 380, 20), "Mod Index", { |slider|
        synth.set(\index, slider.value);
    }, 1, 0, 20);

    // Amplitud
    ampSlider = EZSlider.new(window, Rect(10, 100, 380, 20), "Amp", { |slider|
        synth.set(\amp, slider.value);
    }, 0.5, 0, 1);

    // Inicia el Synth
    synth = Synth(\fmSynth);

    // Asegura que el Synth se libere al cerrar la ventana
    window.onClose = { synth.free; };
)