// Grabado en path: '/home/carlos/.local/share/SuperCollider/Recordings/SC_240105_170642.wav'


(
{
    var x, y, z, a, b, c, d, e, mix;

    // Tomando la idea de osciladores sinusoidales y distorsión
    x = SinOsc.ar((Decay.ar(Impulse.ar([4,4.005]), 1e3*MouseX.kr(0, 1).abs)*50), MouseY.kr(0, 1)).distort;

    // Incorporando la idea de modulación de frecuencia y filtrado
    y = BPF.ar(Saw.ar([40,40.001]), LFNoise0.kr(128)+1*4e3+146, LFNoise1.kr(1)+1*5e-2+0.01).tanh;

    // Utilizando un delay con modulación
    z = DelayC.ar(LPF.ar(LFNoise0.ar(8)**2 + x.tanh.round(0.05), 6e3), 1, LFNoise0.ar(8!2).range(1e-4, 0.02));

    // Juega con la modulación de un filtro
    a = BHiPass.ar(LFNoise1.ar(8)**3, y.midicps, y/2e3, 67-y);

    // Incorporando elementos de pitch shifting
    b = PitchShift.ar(Saw.ar(Demand.kr(Impulse.kr(4), 0, Drand(([-12, -7, 0, 7, 12]+33).midicps, inf)), Decay.kr(Impulse.kr(4), 3)), 7, 2);

    // Creando una secuencia de ritmo
    c = Impulse.ar(8)*LFNoise1.ar(2);

    // Añadiendo un poco de reverb
    d = GVerb.ar(BPF.ar(c, [400, 800], 1/9, 50).tanh, 100, 10);

    // Mezclando las señales juntas
    mix = Mix.new([x, y, z, a, b, c, d]);

    // Aplicando un limitador para evitar el clipping
    e = Limiter.ar(mix, 1.0);  // El segundo argumento es el nivel máximo permitido, puedes ajustarlo según sea necesario

    // Aplicando un poco de panoramización y envío al output
    Out.ar(0, Splay.ar(e));
}.play;
)
