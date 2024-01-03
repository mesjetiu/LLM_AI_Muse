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
