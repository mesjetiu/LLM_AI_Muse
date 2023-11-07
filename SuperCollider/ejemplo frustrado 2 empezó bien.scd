// Otro ejemplo que se llena de errores fácilmente y bloquea...
// https://chat.openai.com/share/0a790c8f-06a7-455f-8924-6104e07e869d


(
SynthDef(\paulstretchCreative, { |out = 0, bufnum, envBufnum, pan = 0, stretch = 50, window = 0.25, amp = 1|
	// Paulstretch Creative for SuperCollider
	// This version introduces a Hanning window for the grain envelope and spectral smearing for a different texture.
	//
	// Modified creatively by [Your Name]
	// [Your Website]
	// [Modification Date]
	//
	// Arguments:
	// out: output bus (stereo output)
	// bufnum: the sound buffer. Must be Mono. (Use 2 instances with Buffer.readChannel for stereo)
	// envBufnum: The grain envelope buffer, now using a Hanning window
	// pan: Equal power panning, useful for stereo use.
	// stretch: stretch factor (modulatable)
	// window: the suggested grain size, will be resized to closest fft window size
	// amp: amplification
	var trigPeriod, sig, chain, trig, pos, fftSize, posMod;
	// Calculating fft buffer size according to suggested window size
	fftSize = 2**floor(log2(window*SampleRate.ir));
	// Grain parameters
	// The grain is the exact length of the FFT window
	trigPeriod = fftSize/SampleRate.ir;
	trig = Impulse.ar(1/trigPeriod);
	// Random modulation for grain position
	posMod = LFNoise1.kr(0.1).range(-0.05, 0.05);
	pos = Demand.ar(trig, 0, Dseries(0, trigPeriod/stretch)) + posMod;
	// Extraction of 2 consecutive grains with a Hanning window for the envelope
	sig = [GrainBuf.ar(1, trig, trigPeriod, bufnum, 1, pos, envbufnum: envBufnum),
		GrainBuf.ar(1, trig, trigPeriod, bufnum, 1, pos + (trigPeriod/(3*stretch)), envbufnum: envBufnum)]*amp;
	// FFT processing with PV_MagSmear
	sig = sig.collect({ |item, i|
		chain = FFT(LocalBuf(fftSize), item, hop: 1.0, wintype: -1);
		// PV_MagSmear is used for spectral smearing
		chain = PV_MagSmear(chain, LFNoise1.kr(0.5).range(0, 10));
		item = IFFT(chain, wintype: -1);
	});
	// Reapply the grain envelope using a Hanning window
	sig = sig*PlayBuf.ar(1, envBufnum, 1/(trigPeriod), loop:1);
	// Delay second grain for a third of grain length overlap
	sig[1] = DelayC.ar(sig[1], trigPeriod/3, trigPeriod/3);
	// Panned output
	Out.ar(out, Pan2.ar(Mix.new(sig), pan));
}).add;
)

// Example using a Hanning window
({
	var envBuf, envSignal, buffer;
	buffer = Buffer.read(s, Platform.resourceDir +/+ "sounds/a11wlk01.wav");
	// The grain envelope using a Hanning window for the envelope
	envBuf = Buffer.alloc(s, s.sampleRate, 1);
	envSignal = Signal.fill(s.sampleRate, { |i| 0.5 - 0.5 * cos((2 * Float.pi * i) / s.sampleRate) });
	envBuf.loadCollection(envSignal);
	s.sync();
	// Runs indefinitely
	Synth(\paulstretchCreative, [\bufnum, buffer.bufnum, \envBufnum, envBuf.bufnum]);
}).fork;


