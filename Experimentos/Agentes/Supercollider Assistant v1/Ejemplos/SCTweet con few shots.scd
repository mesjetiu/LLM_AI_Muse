// https://chat.openai.com/share/340c2959-bea8-49b9-bf09-4a9a8c3b68f6
// Acaba con un par de códigos interesantes. Hay que interactuar bastante.


// Ejemplo 1: Secuencia melódica con eco
{CombN.ar(SinOsc.ar([100, 101].midiratio * 60).sum * 0.2, 0.4, 0.4, 3)}.play;

// Ejemplo 2: Percusión sintética con filtrado y resonancia
{RLPF.ar(Dust.ar(15) * 50, MouseX.kr(200, 12000), 0.1)}.play;

// Ejemplo 3: Sintetizador de bajos con modulación de frecuencia
{SinOsc.ar([SinOsc.kr(2, 0, 10, 55), SinOsc.kr(2, 0, 10, 110)], 0, 0.4)}.play;

// Ejemplo 4: Paisaje sonoro con ruido modulado y espacialización
{FreeVerb.ar(HPF.ar(WhiteNoise.ar([0.05, 0.05]), MouseX.kr(100, 5000)), 0.5, 0.7)}.play;

// Ejemplo 5: Secuencias de acordes con un patrón arpegiado
(
{
    var freqs = [60, 64, 67].midicps;
    var trigs = Dust.kr([2, 3, 4]);
    Splay.ar(
        LPF.ar(
            SinOscFB.ar(freqs * [1, 1.01], 0, Decay.kr(trigs, 0.2)),
            5000
        )
    )
}.play;
)


{Splay.ar(RLPF.ar(Dust.ar(3!6) * 50, LFNoise1.kr(2!6).range(200, 12000), 0.1),1)}.play;

{n=6;Splay.ar(RLPF.ar(Dust.ar({|i| i.rand2}!n) * 50, LFNoise1.kr({|i| i.linexp(0,5,0.5,5)}!n).range(200, 12000), 0.1),1)}.play;


//******* Código interesante
(
{
  var n=6, freqs = LFNoise1.kr(n.linrand).range(200, 12000);
  Splay.ar(
    RLPF.ar(
      Dust.ar(freqs * 0.004) * 50,
      freqs,
      LFNoise1.kr(0.1, 0.5).range(0.05, 0.15)
    )
  )
}.play;
)


//******* Código interesante
{n=6;Splay.ar(RLPF.ar(Dust.ar(Array.fill(n,{2.0.rand})+0.01)*50,LFNoise1.kr(Array.fill(n,{2.0.rand})  ).exprange(200,12000),0.1))}.play;


