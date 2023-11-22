// https://platform.openai.com/playground/p/bnR6JVArL3pXNDWGhU4vwKvV?model=gpt-3.5-turbo&mode=chat


(
SynthDef(\ambient, {
  var out = \out.kr(0);
  var freq = \freq.kr(440);
  var amp = \amp.kr(0.5);
  var env = Env.perc(\attack.kr(1), \release.kr(1), curve: -4).kr(doneAction: 2);
  var sound = SinOsc.ar(freq, 0, amp) * env;
  Out.ar(out, Pan2.ar(sound));
}).add;)

(
SynthDef(\distant_ambience, {
  var out = \out.kr(0);
  var freq = LFNoise0.kr(0.1, 220, 440);
  var amp = \amp.kr(0.3);
  var env = Env.perc(\attack.kr(2), \release.kr(5), curve: -4).kr(doneAction: 2);
  var sound = Mix.fill(8, { |i| SinOsc.ar(freq * (i + 1), 0, amp / (i + 1)) });
  Out.ar(out, Pan2.ar(sound) * env);
}).add;)

(
SynthDef(\ambient, {
  var out = \out.kr(0);
  var freq = LFNoise0.kr(0.1, 220, 440);
  var amp = \amp.kr(0.3);
  var env = Env.perc(\attack.kr(2), \release.kr(5), curve: -4).kr(doneAction: 2);
  var sound = Mix.fill(8, { |i| SinOsc.ar(freq * (i + 1), 0, amp / (i + 1)) });
  Out.ar(out, Pan2.ar(sound) * env);
}).add;
)



(
Pbindef(\ambient, \instrument, \ambient);
Pbindef(\ambient, \amp, Pwhite(0.3, 0.7));
Pbindef(\ambient, \freq, Pexprand(100, 1000));
Pbindef(\ambient, \dur, Pwhite(2, 5));
Pbindef(\ambient).play;
)


(
Pbindef(\ambient, \instrument, \ambient);
Pbindef(\ambient, \amp, Pwhite(0.3, 0.7));
Pbindef(\ambient, \freq, Pexprand(100, 1000));
Pbindef(\ambient, \dur, Pwhite(2, 5));
Pbindef(\ambient, \polyphony, 4);
Pbindef(\ambient).play;
)


(
Pbindef(\ambient,
  \instrument, \ambient,
  \freq, Pseq([440, 550, 660], inf),
  \amp, Pseq([0.5, 0.3, 0.2], inf),
  \out, Pseq([0, 1, 2], inf),
  \polyphony, 3
).play;)


(
SynthDef(\texture, {
  var out = \out.kr(0);
  var freq = LFNoise0.kr(\freq.kr(0.1, 2));
  var amp = LFNoise1.kr(\amp.kr(0.1, 0.5));
  var sound = SinOsc.ar(freq, 0, amp);
  Out.ar(out, sound);
}).add;)


(
Pbindef(\texture,
  \instrument, \texture,
  \freq, Pwhite(0.1, 2.0, inf),
  \amp, Pwhite(0.1, 0.5, inf),
  \out, 0
).play;)

