// Asegúrate de que el servidor de sonido esté iniciado
s.boot;

(
SynthDef(\paisaje_cascada, {
    // Rugido constante de la cascada utilizando ruido blanco
    var cascada = WhiteNoise.ar(0.025); // Ajusta el nivel para que sea suave
    cascada = LPF.ar(cascada, 500) * 0.25; // Filtro de paso bajo para suavizar el sonido de la cascada

    // Ecos de la cascada para simular la reverberación natural del espacio
    var eco = CombL.ar(cascada, 0.3, [0.3, 0.35], 10);

    // Sonidos de la naturaleza y vida silvestre de la selva circundante
    var naturaleza = LFNoise0.kr(0.2).range(300, 8000) * 0.005; // Ajusta el nivel para que sea ambiental
    naturaleza = naturaleza * SinOsc.ar([400, 404], 0, 0.2);

    // Combinamos todos los elementos
    var sonido = cascada + eco + naturaleza;

    // Enviamos el sonido al bus de audio estéreo
    Out.ar(0, sonido.dup); // 'dup' duplica la señal para dos canales estéreo
}).add;
)

// Ejecutamos el SynthDef
x = Synth(\paisaje_cascada);

// Ejemplo de cómo detener el sonido después de un tiempo
(
fork {
    60.wait; // Esperamos 60 segundos para una experiencia inmersiva
    x.free;  // Liberamos el synth
};
)
