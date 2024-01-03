(
SynthDef(\paulstretchPoly, { |out = 0, bufnum, envBufnum, pan = 0, stretch = 8, window = 0.25, amp = 1, rate = 1|
    // Los detalles internos de la SynthDef se mantienen iguales que en la versión monofónica
    var trigPeriod, sig, chain, trig, pos, fftSize;
    fftSize = 2**floor(log2(window*SampleRate.ir));
    trigPeriod = fftSize/SampleRate.ir;
    trig = Impulse.ar(1/trigPeriod);
    pos = Demand.ar(trig, 0, demandUGens: Dseries(0, trigPeriod/stretch));
    sig = [GrainBuf.ar(1, trig, trigPeriod, bufnum, rate, pos, envbufnum: envBufnum),
        GrainBuf.ar(1, trig, trigPeriod, bufnum, rate, pos + (trigPeriod/(2*stretch)), envbufnum: envBufnum)]*amp;
    sig = sig.collect({ |item, i|
        chain = FFT(LocalBuf(fftSize), item, hop: 1.0, wintype: -1);
        chain = PV_Diffuser(chain, 1 - trig);
        item = IFFT(chain, wintype: -1);
    });
    sig = sig*PlayBuf.ar(1, envBufnum, 1/(trigPeriod), loop:1);
    sig[1] = DelayC.ar(sig[1], trigPeriod/2, trigPeriod/2);
    Out.ar(out, Pan2.ar(Mix.new(sig), pan));
}).add;

s.waitForBoot({
    var numSynths = 8; // Número de instancias de Synth que quieres crear
    var envBuf, envSignal, buffer, synths;

    // Carga del buffer con el archivo de sonido
    buffer = Buffer.read(s, Platform.resourceDir +/+ "sounds/a11wlk01.wav");

    // Creación y carga del buffer de envolvente
    envBuf = Buffer.alloc(s, s.sampleRate, 1);
    envSignal = Signal.newClear(s.sampleRate).waveFill({|x| (1 - x.pow(2)).pow(1.25)}, -1.0, 1.0);
    envBuf.loadCollection(envSignal);
    s.sync();

    // Creación de múltiples instancias de Synth con diferentes parámetros
    synths = Array.fill(numSynths, { |i|
        var delayTime = i.rand; // Tiempo de espera antes de iniciar la instancia
        var rateValue = [0.125, 0.25, 0.5, -0.125, -0.25, -0.5].choose; // Velocidades de reproducción, incluidas negativas
        var stretchValue = (8.rand + 0.5).round(0.01); // Valores de estiramiento
        var panValue = [-1, 1].choose; // Posición estéreo

        // Se utiliza 'fork' para permitir tiempos de inicio escalonados
        fork({
            delayTime.wait; // Espera antes de empezar
            Synth(\paulstretchPoly, [
                \bufnum, buffer.bufnum,
                \envBufnum, envBuf.bufnum,
                \pan, panValue,
                \stretch, stretchValue,
                \rate, rateValue,
                \amp, 0.3.rand + 0.2 // Volumen aleatorio dentro de un rango
            ]);
        });
    });
});
)
