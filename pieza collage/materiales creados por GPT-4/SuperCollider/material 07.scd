s.boot; // Arrancar el servidor

// Textura 1: Espacialidad y Drones
(
{
    var freq, amp, pan, drones;

    // Base frecuencial
    freq = MouseX.kr(50, 300, warp:'exponential');

    // Creación de 5 drones con desafinaciones leves
    drones = 5.collect {
        SinOsc.ar(freq + Rand(-10, 10), 0, 0.1)
    }.sum;

    pan = MouseY.kr(-1, 1); // Panoramización con el ratón en eje Y
    Pan2.ar(drones, pan);
}.play;
)

// Textura 2: Granulación
(
{
    var grainSize, grainPos, grains;

    grainSize = MouseX.kr(0.01, 0.5); // Tamaño del grano con el ratón en eje X
    grainPos = MouseY.kr(0, 1); // Posición de inicio del grano con el ratón en eje Y

    // Granos basados en ruido blanco
    grains = GrainSin.ar(2, WhiteNoise.ar(0.5), grainSize, grainPos, 0.1, 1);
    grains;
}.play;
)

// Textura 3: Ruido Modulado
(
{
    var freq, q, mixedNoise, filteredNoise;

    freq = MouseX.kr(50, 5000, warp:'exponential'); // Frecuencia de filtro con el ratón en eje X
    q = MouseY.kr(0.1, 20, warp:'exponential'); // Resonancia (Q) del filtro con el ratón en eje Y

    // Combinación de ruidos
    mixedNoise = Mix([WhiteNoise.ar(0.3), PinkNoise.ar(0.3), BrownNoise.ar(0.3)]);

    // Filtrado resonante
    filteredNoise = RLPF.ar(mixedNoise, freq, q);
    filteredNoise;
}.play;
)
