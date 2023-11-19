
//Figure 1: Immediate machine listening example using Pitch and Amplitude UGens. The original detected pitch appears in your left ear and an octave up in the right.
(
x={
	var in, amp, freq, hasFreq, out;
	in = SoundIn.ar(0);;
	amp = Amplitude.ar(in);
	# freq, hasFreq = Pitch.kr(in);
	LFTri.ar(freq*[1,2]) * amp;
}.play
)

x.free;



//Figure 2: Loudness 

b = Buffer.alloc(s,1024,1);   //for sampling rates 44100 and 48000
//b = Buffer.alloc(s,2048,1); //for sampling rates 88200 and 96000

(  //analyse loudness and poll result
x={
	var in, fft, loudness;
	
	in = SoundIn.ar(0);; 
	
	fft = FFT(b.bufnum, in);
	
	loudness = Loudness.kr(fft); 
	
	loudness.poll(20); //poll for testing 20 times per second
	
	Out.ar(0,Pan2.ar(in)); 
}.play
)

x.free;
b.free;




//Figure 3: MFCC 

b = Buffer.alloc(s,1024,1); //for sampling rates 44100 and 48000
//b = Buffer.alloc(s,2048,1); //for sampling rates 88200 and 96000

//d=Buffer.read(s,"sounds/a11wlk01.wav");


(
x= {
	var in, fft, array;
	
	//in= PlayBuf.ar(1,d.bufnum,BufRateScale.kr(d.bufnum),1,0,1);
	
	in = SoundIn.ar(0);; 
	
	fft = FFT(b.bufnum, in);
	
	array = MFCC.kr(fft); 
	
	array.size.postln; 
	
	Out.kr(0,array); 
	
	Out.ar(0,Pan2.ar(in)); 
}.play
)


c= Bus.new('control', 0, 13); 

//poll coefficients
c.getn(13,{arg val; {val.plot;}.defer}); 


//Continuous graphical display of MFCC values; free routine before closing window

(
var ms; 

w = GUI.window.new("Thirteen MFCC coefficients", Rect(200,400,300,300));

ms = GUI.multiSliderView.new(w, Rect(10,10,260,280));

ms.value_(Array.fill(13,0.0));
ms.valueThumbSize_(20.0);
ms.indexThumbSize_(20.0);
ms.gap_(0);

w.front;

r = {
	
	inf.do{
		
		c.getn(13,{arg val; {ms.value_(val*0.9)}.defer}); 
		
		0.04.wait; //25 frames per second
	};

}.fork;

)


//tidy up
(
r.stop;
b.free;
c.free;
x.free;
w.close;
)




//Figure 4: Onsets

// Prepare the buffer
b = Buffer.alloc(s, 512);

(
x = {
	var sig, chain, onsets, pips, trigger;
	
	sig = SoundIn.ar(0);; 
	
	chain = FFT(b, sig);
	
	// - move the mouse left/right to change the threshold:
	onsets = Onsets.kr(chain, MouseX.kr(0,1), \complex);
	
	trigger= SendTrig.kr(onsets);
	
	pips = SinOsc.ar(880, 0, EnvGen.kr(Env.perc(0.001, 0.1, 0.2), onsets));
	
	Out.ar(0, ((sig * 0.1) + pips).dup);
}.play;
)

(
// register to receive message
a= OSCresponder(s.addr,'/tr',{ arg time,responder,msg;
	[time,responder,msg].postln;
}).add;
)

a.remove; //Free the OSCresponder
x.free; // Free the synth
b.free; // Free the buffer




//Figure 5: BeatTrack


b = Buffer.alloc(s,1024,1); //for sampling rates 44100 and 48000
//b = Buffer.alloc(s,2048,1); //for sampling rates 88200 and 96000

//track audio in (try clapping a beat or beatboxing, but allow up to 6 seconds for tracking to begin); events will be spawned at quarter, eighth and sixteenth note rates
(
x= SynthDef(\help_beattrack2,{	
	var trackb,trackh,trackq,tempo;
	var source;
	var bsound,hsound,qsound;
	
	source = SoundIn.ar(0);;
	
	#trackb,trackh,trackq,tempo = BeatTrack.kr(FFT(b.bufnum, source));
	
	bsound = Pan2.ar(LPF.ar(WhiteNoise.ar*(Decay.kr(trackb,0.05)),1000),0.0);
	
	hsound = Pan2.ar(BPF.ar(WhiteNoise.ar*(Decay.kr(trackh,0.05)),3000,0.66),-0.5);
	
	qsound = Pan2.ar(HPF.ar(WhiteNoise.ar*(Decay.kr(trackq,0.05)),5000),0.5);
	
	Out.ar(0, bsound+hsound+qsound);
}).play;
)


x.free;
b.free; // Free the buffer




//Figure 6: KeyTrack

//straight forward test file with few transients; training set in e minor from MIREX2006 
//You will need to substitute your own soundfile to load here
d=Buffer.read(s,"/Users/nickcollins/Desktop/ML/training_wav/78.wav")


b = Buffer.alloc(s,4096,1); //for sampling rates 44100 and 48000
//b = Buffer.alloc(s,8192,1); //for sampling rates 88200 and 96000

(
x= {
	var in, fft; 
	var key;
	
	in = PlayBuf.ar(1,d.bufnum,BufRateScale.kr(d.bufnum),1,0,1);
	
	fft = FFT(b.bufnum, in);
	
	key = KeyTrack.kr(fft, 2.0, 0.5);
	
	key.poll; //write out detected key
	
	Out.ar(0,Pan2.ar(in)); 
}.play
)

x.free;
b.free;



//Figure 7: Simple melodic transcription
//see melodytranscription.rtf


//Figure 8: OnlineMIDI

//do this first: 
MIDIIn.connect; 	// init for one port midi interface


//now:
m = OnlineMIDI();

m.analyse(3,1.0); //3 seconds window, step size of 1.0 seconds

m.data //poll current data

m.status = true; //prints analysis data as it goes
m.status= false;

//use analysis data to formulate responses

(
SynthDef(\beep2,{arg freq=440,amp=0.1, pan=0.0, dur=0.1; 
var source; 

source= SinOsc.ar(freq*[1,1.007],0,amp*0.5);

Out.ar(0,Pan2.ar(Mix(source)*Line.kr(1,0,dur, doneAction:2),pan))}).add;
)

//to echo each note you play on a MIDI keyboard with a sound; your SynthDef must have freq and amp arguments, and deal with duration and freeing the Synth itself.  
(
m.playinput= true; 
m.inputsynthdef= \beep2; 
)

//set a function that gets called after each window is analysed, to schedule events over the next second 
(
m.response = {|analysis|  
	var number;
	number= analysis.density; 
	//number= max(0,(10-(analysis.density))); //inverting number of notes playing
	
	if(analysis.iois.notEmpty, {
		{
		
		number.do{
		
		Synth(\beep2, [\freq, analysis.pitches.choose.midicps, \amp, 0.2*(rrand(analysis.volumemin, analysis.volumemax))]);
		
		analysis.iois.choose.wait; //could last longer than the next second, but still fun! 
		
		}; 
		
		}.fork;
	}); 
	
};
)


m.response= nil; //stop





// CloudGenMini is based on CloudGenerator, a granular synthesis program 
// by Curtis Roads and John Alexander. 
// This partial miniature version was implemented by Alberto de Campo, 2007. 


	// figure 6.23 - some granular synthdefs and tests
(
	// a gabor (approx. gaussian-shaped) grain
SynthDef(\gab1st, { |out, amp=0.1, freq=440, sustain=0.01, pan| 
	var snd = FSinOsc.ar(freq);
	var env = EnvGen.ar(Env.sine(sustain, amp * AmpComp.ir(freq) * 0.5), doneAction: 2);
	OffsetOut.ar(out, Pan2.ar(snd * env, pan));
}, \ir ! 5).store;

			// wider, quasi-gaussian envelope, with a hold time in the middle. 
SynthDef(\gabWide, { |out, amp=0.1, freq=440, sustain=0.01, pan, width=0.5| 
	var holdT = sustain * width;
	var fadeT = 1 - width * sustain * 0.5;
	var snd = FSinOsc.ar(freq);
	var env = EnvGen.ar(Env([0, 1, 1, 0], [fadeT, holdT, fadeT], \sin), 
		levelScale: amp * AmpComp.ir(freq) * 0.5, 
		doneAction: 2);
	OffsetOut.ar(out, Pan2.ar(snd * env, pan));
}, \ir ! 5).store;

			// a simple percussive envelope
SynthDef(\percSin, { |out, amp=0.1, freq=440, sustain=0.01, pan| 
	var snd = FSinOsc.ar(freq);
	var env = EnvGen.ar(
		Env.perc(0.1, 0.9, amp * AmpComp.ir(freq) * 0.5), 
			timeScale: sustain, doneAction: 2
		);
	OffsetOut.ar(out, Pan2.ar(snd * env, pan));
}, \ir ! 5).store;

			// a reversed  percussive envelope
SynthDef(\percSinRev, { |out, amp=0.1, freq=440, sustain=0.01, pan| 
	var snd = FSinOsc.ar(freq);
	var env = EnvGen.ar(
		Env.perc(0.9, 0.1, amp * AmpComp.ir(freq) * 0.5, 4), 
			timeScale: sustain, doneAction: 2
		);
	OffsetOut.ar(out, Pan2.ar(snd * env, pan));
}, \ir ! 5).store;

		// a noise band grain with percussive envelope
SynthDef(\percNoise, { |out, amp=0.2, freq=440, sustain=0.01, pan, rq=0.1| 
	var snd = BPF.ar(GrayNoise.ar, freq, rq, 3);
	var env = EnvGen.ar(Env.perc, timeScale: sustain, doneAction: 2);
	OffsetOut.ar(out, 
		Pan2.ar(snd * env, pan, amp)
	);
}, \ir ! 6).store

/*	
	// tests for the synthdefs:
Synth(\gab1st);
Synth(\gabWide);
Synth(\percSin);
Synth(\percSinRev);

Synth(\percSin, [\amp, 0.2, \sustain, 0.1]);
Synth(\percNoise, [\amp, 0.2, \sustain, 0.1]);

Synth(\gab1st, [\out, 0, \amp, 0.2, \freq, 2000, \sustain, 0.05, \pan, 0.5] );
*/
);





	// figure 6.24 - global setup and a player Tdef for the cloud.
(
q = q ? (); 

	// some globals
q.paramRNames = [\freqRange, \durRange, \densRange, \ampRange, \panRange]; 
q.paramNames = [\freq, \grDur, \dens, \amp, \pan]; 
q.syndefNames = [\gab1st, \gabWide, \percSin, \percSinRev, \percNoise];

	// specs for some parameters
Spec.add(\xfadeTime, [0.001, 1000, \exp]);
Spec.add(\ring, [0.03, 30, \exp]);
Spec.add(\grDur, [0.0001, 1, \exp]);
Spec.add(\dens, [1, 1000, \exp]);

	// make an empty tdef that plays it, 
	// and put the cloud parameter ranges in the tdef's environment
Tdef(\cloud0)
	.set(
	\synName, \gab1st,
	\vol, 0.25,
	\current, (
		freqRange: [200, 2000],
		ampRange: [0.1, 1],
		durRange: [0.001, 0.01], 
		densRange: [1, 1000],
		panRange: [-1.0, 1.0] 
	)
); 
		
		// make the tdef that plays the cloud of sound particles here, 
		// based on parameter range settings.
Tdef(\cloud0, { |e| 

	loop {
		s.sendBundle(s.latency, [
			"/s_new", e.synName ? \gab1st, 
			-1, 0, 0,
			\freq, 	exprand(e.current.freqRange[0], e.current.freqRange[1]),
			\amp,	exprand(e.current.ampRange[0], e.current.ampRange[1]) * e.vol,
			\sustain,	exprand(e.current.durRange[0], e.current.durRange[1]),
			\pan, 	rrand(e.current.panRange[0], e.current.panRange[1])
		]);
		exprand(e.current.densRange[0].reciprocal, e.current.densRange[1].reciprocal).wait; 
	}
}).quant_(0);	
);




/*
	// figure  6.25	-  tests for the cloud
	
Tdef(\cloud0).play;

	// try changing various things from outside the loop. 
	// change its playing settings 

Tdef(\cloud0).envir.current.put('densRange', [ 50, 200 ]); // dense, async
Tdef(\cloud0).envir.current.put('densRange', [ 1, 10 ]);  // sparse, async
Tdef(\cloud0).envir.current.put('densRange', [ 30, 30 ]); // synchronous

	// for faster access, call the tdef's envir d
d = Tdef(\cloud0).envir;
d.current.put('freqRange', [ 800, 1200 ]);
d.current.put('durRange', [ 0.02, 0.02 ]);

d.current.put('ampRange', [ 0.1, 0.1 ]);

d.current.put('panRange', [ 1.0, 1.0 ]);
d.current.put('panRange', [ -1.0, 1.0 ]);

d.current.put('densRange', [ 30, 60 ]);
d.synName = \percSin;
d.synName = \gab1st;
d.synName = \gabWide;
d.synName = \percSinRev;
d.synName = \percNoise;
d.synName = \percSinRev;
d.synName = \gab1st;
d.current.put('durRange', [ 0.001, 0.08 ]);


*/




	// figure 6.26 - making random settings, and 8 random presets to switch between
(
	// make the Tdef's envir a global variable for easier experimenting
d = Tdef(\cloud0).envir;
	// a pseudo-method to make random settings, kept in the Tdef's environment
		// randomize could also do limited variation on existing setting. 
d.randSet = { |d|
	var randSet = ();	
	q.paramRNames.do { |pName, i| 
		randSet.put(pName, 
			q.paramNames[i].asSpec.map([1.0.rand, 1.0.rand].sort)
		);
	};
	randSet;
};

/* 	test randSet: 
d.current = d.randSet;
*/

// make 8 sets of parameter range settings: 
d.setNames = (1..8).collect { |i| ("set" ++ i).asSymbol };
d.setNames.do { |key| d[key] = d.randSet; }

/*	test switching to the random presets
d.current = d.set1.copy;	// copy to avoid writing into a stored setting when it is current.
d.current = d.set3.copy;	
d.current = d.set8.copy;
*/
);




	// ex. 6.27 - crossfading between different settings with a taskproxy
	
(
	// and some parameters for controlling the fade
d.stopAfterFade = false;
d.xfadeTime = 5; 

d.morphtask = TaskProxy({
	var startSet = d[\current], endSet = d[\target];
	var stepsPerSec = 20;
	var numSteps = d.xfadeTime * stepsPerSec;
	var blendVal, morphSettings;
	
	if (d.target.notNil) { 
		(numSteps).do { |i| 
		//	["numSteps", i].postln;
			blendVal = (i + 1) / numSteps; 
			morphSettings = endSet.collect({ |val, key| 
				(startSet[key] ? val).blend(val, blendVal) 
			});
			d.current_(morphSettings);
			(1/stepsPerSec).wait;
		};
		d.current_(d.target.copy);
		"morph done.".postln;
		if (d.stopAfterFade) { Tdef(\cloud0).stop; };
	};
}).quant_(0);		// no quantization so the task starts immediately

/* test morphing
(
Tdef(\cloud0).play;
d.target = d.set6.copy;
d.morphtask.play;
)
Tdef(\cloud0).stop;

	// playing a a finite cloud with tendency mask: 
(
Tdef(\cloud0).play;		// begin playing
d.stopAfterFade = true; 	// end cloud when crossfade ends
d.xfadeTime = 10; 			// set fade time
d.target = d.set8.copy;		// and target
d.morphtask.play;			// and start crossfade.
)
*/

	// put fading into its own method, with optional stop.
d.fadeTo = { |d, start, end, time, autoStop| 
	d.current = d[start] ? d.current;
	d.target = d[end]; 
	d.xfadeTime = time ? d.xfadeTime;
	if (autoStop.notNil) { d.stopAfterFade = autoStop };
	d.morphtask.stop.play;
};

/* 	// tests fadeTo:
Tdef(\cloud0).play;
d.fadeTo(\current, \set2, 20);
d.fadeTo(\current, \set6, 10);
d.fadeTo(\current, \set5, 3, true);

Tdef(\cloud0).play;
d.fadeTo(\current, \set1, 3, false);
*/ 
);



	// figure 6.28 is an image, the CloudGenMini GUI //




	// figure 6.29 - a lightweight graphical user interface for CloudGenMini 
(
q.makeCloudGui = { |q, tdef, posPoint| 
	var w, ezRangers, fdBox; 
	var setMinis, skipjack; 
	
	posPoint = posPoint ? 0@0;	// where to put the gui window
	
	w = GUI.window.new("CloudGen_mini_sc3", 
		Rect.fromPoints(posPoint, (posPoint + (400@300)).postln)).front;
	w.view.decorator_(FlowLayout(w.bounds.copy.moveTo(0, 0)));
		
	w.view.decorator.nextLine; 
		// the range sliders display the current values
	ezRangers = ();
	
	q.paramRNames.do { |name, i| 
		ezRangers.put(name, 
		EZRanger(w, 400@20, name, q.paramNames[i], 
			{ |sl| tdef.envir.current[name] = sl.value; }, 
			tdef.envir.current[name], labelWidth: 70, numberWidth: 50, unitWidth: 10)
			.round_([0.1, 0.00001, 0.0001, 0.0001, 0.01][i])
		);
	};
		// a just in time - gui for the Tdef
	TdefEditor(tdef, height: 20, w: w); 
	
	GUI.button.new(w, 80@20).states_([[\randomize]])
		.action_({ 
			tdef.envir.target_(d.randSet);
			tdef.envir.morphtask.stop.play;
		});
	
	GUI.staticText.new(w, 60@20).string_("xfadeTime"); 
	fdBox = GUI.numberBox.new(w, 40@20).action_{ |nbx| tdef.envir.xfadeTime = nbx.value }; 

			// skipjack is a task that survives cmd-period:
			// used here for lazy-updating the control views.
	skipjack = SkipJack({  
		q.paramRNames.do { |name| ezRangers[name].value_(tdef.envir.current[name]) };
		fdBox.value_(tdef.envir.xfadeTime); 
		
		// mark last settings that were used by color? 
		// a separate color when changed? 
		
	}, 0.5, { w.isClosed }, name: tdef.key);
	
	w.view.decorator.nextLine;

	// make a new layoutView for the 8 presets; 
	// put button to switch to that preset, 
	// a button to save current settings to that place, 
	// and a miniview of the settings as a visual reminder in it.
	
		// make 8 setButtons
	tdef.envir.setNames.do { |setname, i|	
		var minisliders, setMinis;
		var zone = GUI.compositeView.new(w, Rect(0,0,45, 84));
		zone.decorator = FlowLayout(zone.bounds, 0@0, 5@0); 
		zone.background_(Color.white); 
		
		GUI.button.new(zone, Rect(0,0,45,20)).states_([[setname]])
			.action_({ 
				// just switch: // tdef.envir.current.putAll(d[setname] ? ()) 
				tdef.envir.target = tdef.envir[setname];
				tdef.envir.morphtask.stop.play;
			});
		
		GUI.button.new(zone, Rect(0,0,45,20))
			.states_([["save" ++ (i + 1)]])
			.action_({ 
				d[setname] = tdef.envir.current.copy; 
				setMinis.value;
			});
		
		minisliders = q.paramRNames.collect { |paramRname| 
			GUI.rangeSlider.new(zone, 45@8).enabled_(false);
		};
		setMinis = { 
			q.paramRNames.do { |paramRname, i| 
				var paramName = q.paramNames[i];
				var myrange = d[setname][paramRname];
				var unmapped = paramName.asSpec.unmap(myrange); 
				minisliders[i].lo_(unmapped[0]).hi_(unmapped[1]);
			} 
		};
		setMinis.value;
	};

/* 	Some extras: 
	a volume slider for simple mixing, 
	a popup menu for switching syndefnames; 
	a button to stop/start the skipjack for refreshing, 
	so one can use numberboxes to enter values.
*/
	EZSlider(w, 250@20, "vol", \amp, { |sl|tdef.set(\vol, sl.value) }, 
		0.25, false, 20, 36);

	GUI.staticText.new(w, 50@20).string_("synthdef:"); 
	GUI.popUpMenu.new(w, Rect(0,0,80,20))
		.items_([\gab1st, \gabWide, \percSin, \percSinRev, \percNoise])
		.action_({ |pop| tdef.envir.synName = pop.items[pop.value] });
	
	GUI.button.new(w, 80@20).states_([[\continuous], [\fadeStops]])
		.value_(tdef.envir.stopAfterFade.binaryValue)
		.action_({ |btn|
			tdef.set(\stopAfterFade, btn.value == 1)
		});

	GUI.button.new(w, 80@20).states_([[\skipWatching], [\skipWaiting]])
		.action_({ |btn|
			[ { skipjack.play }, { skipjack.stop }][btn.value].value
		});

};
q.makeCloudGui(Tdef(\cloud0))
);




			// Microsound - code figures //


		// perception at the micro time scale //
		
	//  pulses, transition from rhythm to pitch 
{ Impulse.ar (XLine.kr(12, 48, 6, doneAction: 2)) * 0.1 ! 2 }.play; // up

{ Impulse.ar (XLine.kr(48, 12, 6, doneAction: 2)) * 0.1 ! 2 }.play; // down

{ Impulse.ar (MouseX.kr(12, 48, 1)) * 0.1 ! 2 }.play; // mouse-controlled





	// figure 16.1 short grain durations - pitch to colored click 
(	// a gabor grain, gaussian-shaped envelope
SynthDef(\gabor, { |out, freq = 440, sustain = 1, pan, amp = 0.1, width = 0.25 |
	var env = LFGauss.ar(sustain, width, loop: 0, doneAction: 2);
	var son = FSinOsc.ar(freq, 0.5pi, env);
	OffsetOut.ar(out, Pan2.ar(son, pan, amp));

}, \ir ! 6).memStore;

	// or an approximation with a sine-shaped envelope
SynthDef(\gabor1, { |out, amp=0.1, freq=440, sustain=0.01, pan| 
	var snd = FSinOsc.ar(freq);
	var env = EnvGen.ar(Env.sine(sustain, amp), doneAction: 2);
	OffsetOut.ar(out, Pan2.ar(snd * env, pan));
}, \ir ! 5).memStore;
)

(
Pbindef(\grain,
	\instrument, \gabor, \freq, 1000, 
	\dur, 0.5, \sustain, 20/1000, \amp, 0.2
).play;
)
Pbindef(\grain, \sustain, 10/Pkey(\freq));
Pbindef(\grain, \sustain, 5/Pkey(\freq));
Pbindef(\grain, \sustain, 3/Pkey(\freq));
Pbindef(\grain, \sustain, 2/Pkey(\freq));
Pbindef(\grain, \sustain, 1/Pkey(\freq));

	// successively shorter, end
Pbindef(\grain, \sustain, Pseq((10..1)) / Pkey(\freq)).play;

	// random drift of grain duration
Pbindef(\grain, \sustain, Pbrown(1, 10, 3) / Pkey(\freq), \dur, 0.1).play




	// short grains seem softer 
(
Pbindef(\grain, 
	\instrument, \gabor, \freq, 1000, \dur, 1,
	[\sustain, \amp], Pseq([[0.001, 0.1], [0.1, 0.1]], inf) 
).play;
)
		// short grain 2x louder 
Pbindef(\grain, [\sustain, \amp], Pseq([[0.001, 0.2], [0.1, 0.1]], inf));

		// short grain 4x louder
Pbindef(\grain, [\sustain, \amp], Pseq([[0.001, 0.4], [0.1, 0.1]], inf));



	// a grain with quasi-rectangular envelope, short grain 6x louder.
(
SynthDef(\pip, { |out, freq=440, sustain=0.02, amp=0.2, pan=0| 
	OffsetOut.ar(out, 
		Pan2.ar(SinOsc.ar(freq) 
		* EnvGen.ar(Env.linen(0.0005, sustain - 0.001, 0.0005, amp), doneAction: 2), pan)
	); 
}).memStore;

	// is this equal loudness?
Pbindef(\grain).clear;
Pbindef(\grain, 
	\instrument, \pip,
	\freq, 1000, \dur, 1,
	\sustain, Pseq([0.001, 0.1], inf), 
	\amp, Pseq([0.6, 0.1], inf) 	
).play;
)




	// figure 16.2 - Perception of short silences.
(
p = ProxySpace.push;

~source = { SinOsc.ar * 0.1 };
~silence = { |silDur=0.01| 
	EnvGen.ar(
		Env([0, 1, 1, 0, 0, 1, 1, 0], [0.01, 2, 0.001, silDur, 0.001, 2, 0.01]), 
		doneAction: 2) ! 2
};
~listen = ~source * ~silence;
~listen.play;
)

~silence.spawn([\silDur, 0.001]); // sounds like an added pulse 
~silence.spawn([\silDur, 0.003]);
~silence.spawn([\silDur, 0.01]);
~silence.spawn([\silDur, 0.03]);	  // a pause in the sound

	// try the same examples with noise:
~source = { WhiteNoise.ar * 0.1 };	

p.clear.pop; 




	// figure 16.3 - order confusion with sounds in fast succession. 
	// as grains move closer and closer together, their order becomes ambiguous. 
(
			// a simple percussive envelope
SynthDef(\percSin, { |out, amp=0.1, freq=440, sustain=0.01, pan| 
	var snd = FSinOsc.ar(freq);
	var env = EnvGen.ar(
		Env.perc(0.1, 0.9, amp), timeScale: sustain, doneAction: 2);
	OffsetOut.ar(out, Pan2.ar(snd * env, pan));
}, \ir ! 5).memStore;
)
(
Pbindef(\lo, 
	\instrument, \percSin, \sustain, 0.05, 
	\freq, 250, \amp, 0.2, \dur, 0.5, \lag, 0
).play;
Pbindef(\hi, 
	\instrument, \percSin, \sustain, 0.05, 
	\freq, 875, \amp, 0.1, \dur, 0.5, \lag, 0
).play;
)
	// try different lag times between them
Pbindef(\hi, \lag, 0.1);
Pbindef(\hi, \lag, 0.03);
Pbindef(\hi, \lag, 0.01);
Pbindef(\hi, \lag, 0.003);

	// hi too early or too late by a fixed time - which one is first?
Pbindef(\hi, \lag, ([-1, 1].choose * 0.01).postln).play;
Pbindef(\hi, \lag, ([-1, 1].choose * 0.02).postln);

	// is it easier to hear when the sounds are panned apart?
Pbindef(\hi, \pan, 0.5); Pbindef(\lo, \pan, -0.5);
Pbindef(\hi, \pan, 0);   Pbindef(\lo, \pan, 0);





	// figure 16.4: multiple grains fuse into one composite.
	// when their order changes, the sound is subtly different.
(
Pbindef(\grain4, 
	\instrument, \percSin, \sustain, 0.03, \amp, 0.2,
	\freq, Pshuf([1000, 600, 350, 250]), // random every each time
	\dur, 0.005
).play;
				// repeat grain cluster 
Tdef(\grain, { loop { Pbindef(\grain4).play; 1.wait } }).play;
)
	// fixed order
Pbindef(\grain4, \freq, Pseq([1000, 600, 350, 250].scramble));

	// different order every time
Pbindef(\grain4, \freq, Pshuf([1000, 600, 350, 250]));



			// microsound - code figures - anatomy //


	// waveform, envelope, grain plotted

e = Env.sine.asSignal(400).as(Array); 
w = Array.fill(400, { |i| (i * 2pi / 40).sin });
g = e * w;	

[e, w, g].flop.flat.plot("envelope, wave, grain", Rect(0,0,408,600), numChannels: 3);


	// a gaussian envelope created with the LFGauss UGen
{ LFGauss.ar(0.01, 0.26) }.plot;

	// and a curve created from the gaussian distribution formula
(-1, -0.995 .. 1).collect { |x| exp(squared(x) / (-2.0 * squared(0.26))) }.plot;


	// a gabor grain and tests

(
SynthDef(\gabor0, {|out, freq=440, sustain=0.02, amp=0.2, pan|
	var env = EnvGen.ar(Env.sine(sustain, amp), doneAction: 2);
	var sound = SinOsc.ar(freq) * env;
	OffsetOut.ar(out, Pan2.ar(sound, pan))
}, \ir.dup(5)).memStore;
)
		// test with synth
Synth(\gabor0);		// defaults from SynthDef
Synth(\gabor0, [\freq, 1000, \sustain, 0.005, \amp, 0.1, \pan, 0.5]);

		// test with event.play
(instrument: \gabor0).play;		// default values from Event.defaultEvent
(instrument: \gabor0, sustain: 0.02).play;
(instrument: \gabor0, sustain: 0.002, freq: 1500, amp: 0.3, pan: 0.5).play;
(instrument: \gabor0, sustain: 0.001, freq: 2500, amp: 0.05, pan: -0.5).play;

Synth.grain(\gabor0, [\freq, 2000, \sustain, 0.003]) // higher efficiency, as no NodeID is kept

s.sendMsg("s_new",  \gabor0, -1, 0, 0, \freq, 2000, \sustain, 0.003); // even more efficient, as no Synth object is created.



	// figure 16.6 - making different envelope shapes

Env.sine.plot;		// approx. gaussian 
Env([0, 1, 1, 0], [0.25, 0.5, 0.25] * 0.1, \sin).test.plot; // quasi-gaussian
Env([0, 1, 1, 0], [0.25, 0.5, 0.25] * 0.1, \lin).test.plot; // 3 stage line segments.
Env([0, 1, 1, 0], [0.25, 0.5, 0.25] * 0.1, \welch).test.plot; // welch curve interpolation
Env([1, 0.001], [0.1], \exp).test.plot;	// expoDec (exponential decay);
Env([0.001, 1], [0.1], \exp).test.plot;	// revExpoDec (reverse exponential decay);
Env.perc(0.01, 0.09).test.plot;

(	// a sinc function envelope 
q = q ? ();
q.makeSinc = { |q, num=1, size=400| 
	dup({ |x| x = x.linlin(0, size-1, -pi, pi) * num; sin(x) / x }, size);
}; 
a = q.makeSinc(6);
a.plot(bounds: Rect(0,0,409,200), minval: -1, maxval: 1);
)






(	// more envelopes plotted 
[ 	Env.sine, 
	Env([0, 1, 1, 0], [0.33, 0.34, 0.33], \sin), 
	Env([0, 1, 1, 0], [0.33, 0.34, 0.33], \lin),
	Env([0, 1, 1, 0], [0.33, 0.34, 0.33], \welch),
	Env([1, 0.001], [1], \exp),
	Env([0.001, 1], [1], \exp), 
	Env.perc(0.05, 0.95)
]	.collect(_.discretize(400))
	.add(q.makeSinc(6)).clump(4).collect { |gr4, i| 
		gr4.flop.flat.plot(
			["gauss, quasi-gauss, line, welch", 
			"expodec, rexpodec, perc, sinc" ][i], 
			Rect(420 * i + 100, 300, 408, 400), numChannels: 4)
	};
)



	// figure 16.9 - SynthDefs with different envelopes

(	// a gabor (approx. gaussian-shaped) grain
SynthDef(\gabor1, { |out, amp=0.1, freq=440, sustain=0.01, pan| 
	var snd = FSinOsc.ar(freq);
	var amp2 = amp * AmpComp.ir(freq.max(50)) * 0.5;
	var env = EnvGen.ar(Env.sine(sustain, amp2), doneAction: 2);
	OffsetOut.ar(out, Pan2.ar(snd * env, pan));
}, \ir ! 5).memStore;

			// wider, quasi-gaussian envelope, with a hold time in the middle. 
SynthDef(\gabWide, { |out, amp=0.1, freq=440, sustain=0.01, pan, width=0.5| 
	var holdT = sustain * width;
	var fadeT = 1 - width * sustain * 0.5;
	var snd = FSinOsc.ar(freq);
	var amp2 = amp * AmpComp.ir(freq.max(50)) * 0.5;
	var env = EnvGen.ar(Env([0, 1, 1, 0], [fadeT, holdT, fadeT], \sin), 
		levelScale: amp2, 
		doneAction: 2);
	OffsetOut.ar(out, Pan2.ar(snd * env, pan));
}, \ir ! 5).memStore;

			// a simple percussive envelope
SynthDef(\percSin, { |out, amp=0.1, freq=440, sustain=0.01, pan| 
	var snd = FSinOsc.ar(freq);
	var amp2 = amp * AmpComp.ir(freq.max(50)) * 0.5;
	var env = EnvGen.ar(
		Env.perc(0.1, 0.9, amp2), 
			timeScale: sustain, 
			doneAction: 2);
	OffsetOut.ar(out, Pan2.ar(snd * env, pan));
}, \ir ! 5).memStore;

			// a reversed  percussive envelope
SynthDef(\percSinRev, { |out, amp=0.1, freq=440, sustain=0.01, pan| 
	var snd = FSinOsc.ar(freq);
	var amp2 = amp * AmpComp.ir(freq.max(50)) * 0.5;
	var env = EnvGen.ar(
		Env.perc(0.9, 0.1, amp2), 
			timeScale: sustain, 
			doneAction: 2
		);
	OffsetOut.ar(out, Pan2.ar(snd * env, pan));
}, \ir ! 5).memStore;

			// an exponential decay envelope
SynthDef(\expodec, { |out, amp=0.1, freq=440, sustain=0.01, pan| 
	var snd = FSinOsc.ar(freq);
	var amp2 = AmpComp.ir(freq.max(50)) * 0.5 * amp;
	var env = XLine.ar(amp2, amp2 * 0.001, sustain, doneAction: 2);
	OffsetOut.ar(out, Pan2.ar(snd * env, pan));
}, \ir ! 5).memStore;

			// a reversed exponential decay envelope
SynthDef(\rexpodec, { |out, amp=0.1, freq=440, sustain=0.01, pan| 
	var snd = FSinOsc.ar(freq);
	var amp2 = amp * AmpComp.ir(freq.max(50)) * 0.5;
	var env = XLine.ar(amp2 * 0.001, amp2, sustain, doneAction: 2) 
		* (AmpComp.ir(freq) * 0.5);
	OffsetOut.ar(out, Pan2.ar(snd * env, pan));
}, \ir ! 5).memStore;
)





	// figure 16.10 - changing grain duration, frequency, envelope
(
Pbindef(\grain0,
	\instrument, \gabor1, \freq, 500, 
	\sustain, 0.01, \dur, 0.2	
).play;
)
	// change grain durations
Pbindef(\grain0, \sustain, 0.1);
Pbindef(\grain0, \sustain, 0.03);
Pbindef(\grain0, \sustain, 0.01);
Pbindef(\grain0, \sustain, 0.003);
Pbindef(\grain0, \sustain, 0.001);
Pbindef(\grain0, \sustain, Pn(Pgeom(0.1, 0.9, 60)));
Pbindef(\grain0, \sustain, Pfunc({ exprand(0.0003, 0.03) }));
Pbindef(\grain0, \sustain, 0.03);

	// change grain waveform (sine) frequency
Pbindef(\grain0, \freq, 300);
Pbindef(\grain0, \freq, 1000);
Pbindef(\grain0, \freq, 3000);
Pbindef(\grain0, \freq, Pn(Pgeom(300, 1.125, 32)));
Pbindef(\grain0, \freq, Pfunc({ exprand(300, 3000) }));
Pbindef(\grain0, \freq, 1000);

	// change synthdef for different envelopes
Pbindef(\grain0, \instrument, \gabor1);
Pbindef(\grain0, \instrument, \gabWide);
Pbindef(\grain0, \instrument, \percSin);
Pbindef(\grain0, \instrument, \percSinRev);
Pbindef(\grain0, \instrument, \expodec);
Pbindef(\grain0, \instrument, \rexpodec);
Pbindef(\grain0, \instrument, Prand([\gabWide, \percSin, \percSinRev], inf));





	// bonus track - adjusting phase for attack color
	
(	// an expodec envelope sine grain with adjustable phase
SynthDef(\expodecPH, { |out, amp=0.1, freq=440, click=0, sustain=0.01, pan| 
	var snd = FSinOsc.ar(freq, click * 0.5pi);
	var env = XLine.ar(amp, amp * 0.001, sustain, doneAction: 2) * (AmpComp.ir(freq) * 0.5);
	OffsetOut.ar(out, Pan2.ar(snd * env, pan));
}, \ir ! 6).memStore;
)
(
Pbindef(\grain0).play;
Pbindef(\grain0, 
	\instrument, \expodecPH, 
	\sustain, 0.1, 
	\freq, [100, 300],
	\click, Pseq((0..20)/20, inf) // add more and more click 
).play;
)






	// figure 16.11 - different control strategies applied to density
	
(	// synchronous - regular time intervals
Pbindef(\grain0).clear;
Pbindef(\grain0).play;
Pbindef(\grain0, 
	\instrument, \expodec, 
	\freq, Pn(Penv([200, 1200], [10], \exp), inf),
	\dur, 0.1, \sustain, 0.06
);
)
	// different fixed values
Pbindef(\grain0, \dur, 0.06) 	// rhythm
Pbindef(\grain0, \dur, 0.035)	
Pbindef(\grain0, \dur, 0.02)	// fundamental frequency 50 Hz

	// time-changing values: accelerando/ritardando
Pbindef(\grain0, \dur, Pn(Penv([0.1, 0.02], [4], \exp), inf));
Pbindef(\grain0, \dur, Pn(Penv([0.1, 0.02, 0.06, 0.01].scramble, [3, 2, 1], \exp), inf));

	// repeating values: rhythms or tones
Pbindef(\grain0, \dur, Pstutter(Pwhite(2, 15), Pfunc({ exprand(0.01, 0.3) })));

	// introducing irregularity - quasi-synchronous
Pbindef(\grain0, \dur, 0.03 * Pwhite(0.8, 1.2))
Pbindef(\grain0, \dur, 0.03 * Pbrown(0.6, 1.4, 0.1)) // slower drift
Pbindef(\grain0, \dur, 0.03 * Pwhite(0.2, 1.8))

	// average density constant, vary degree of irregularity  
Pbindef(\grain0, \dur, 0.02 * Pfunc({ (0.1.linrand * 3) + 0.9 }));
Pbindef(\grain0, \dur, 0.02 * Pfunc({ (0.3.linrand * 3) + 0.3 }));
Pbindef(\grain0, \dur, 0.02 * Pfunc({ (1.0.linrand * 3) + 0.0 }));
Pbindef(\grain0, \dur, 0.02 * Pfunc({ 2.45.linrand.squared })); // very irregular


(	// coupling - duration depends on freq parameter
Pbindef(\grain0, 
	\freq, Pn(Penv([200, 1200], [10], \exp), inf),
	\dur, Pfunc({ |ev| 20 / ev.freq  })
);
)

	// different freq movement, different timing
Pbindef(\grain0, \freq, Pbrown(48.0, 96.0, 12.0).midicps);

(	// duration depends on freq, with some variation - tendency mask
Pbindef(\grain0, 
	\freq, Pn(Penv([200, 1200], [10], \exp), inf),
	\dur, Pfunc({ |ev| 20 / ev.freq * rrand(0.5, 1.5)  })
);
)


	// figure 16.12 - control strategies applied to different parameters
(
Pbindef(\grain0).clear;
Pbindef(\grain0, 
	\instrument, \expodec, 
	\freq, 200,
	\sustain, 0.05, \dur, 0.07
).play;
)
	// time-varying freq with envelope pattern
Pbindef(\grain0, \freq, Pn(Penv([200, 1200], [10], \exp), inf));
	// random freq
Pbindef(\grain0, \freq, 400 * Pwhite(-24.0, 24).midiratio);
	// timechanging with random variation
Pbindef(\grain0, \freq, Pn(Penv([400, 2400], [10], \exp), inf) * Pwhite(-24.0, 24).midiratio);

	// panning
Pbindef(\grain0, \pan, Pwhite(-0.8, 0.8));  // random
Pbindef(\grain0, \pan, Pn(Penv([-1, 1], [2]), inf)); // tendency
Pbindef(\grain0, \pan, Pfunc({ |ev| ev.freq.explin(50, 5000, -1, 1) })); // coupled to freq

	// time scattering variants
Pbindef(\grain0, \dur, 0.1 * Pwhite(0.5, 1.5));	// random range
Pbindef(\grain0, \dur, 0.05 * Prand([0, 1, 1, 2, 4], inf)); // rhythmic random

	// amplitude - randomized
Pbindef(\grain0, \amp, Pwhite(0.01, 0.2));	// linear
Pbindef(\grain0, \amp, Pwhite(-50, -14).dbamp); // exponential - more depth
Pbindef(\grain0, \dur, 0.025 * Prand([0, 1, 1, 2, 4], inf)); // could be denser now

	// random amplitude envelopes with Pseg
(
Pbindef(\grain0, 
	\amp, Pseg(
		Pxrand([-50, -20, -30, -40] + 10, inf), // level pattern
		Pxrand([0.5, 1, 2, 3], inf), 		// time pattern
		Prand([\step, \lin], inf)			// curve pattern
	).dbamp
); 
)
	// grain sustain time coupled to freq
Pbindef(\grain0, \sustain, Pkey(\freq).reciprocal * 20).play;


	
	// GrainSin.help example as nodeproxy
	
p = ProxySpace.push;
(
~grain.play;
~grain = {	arg envbuf = -1, density = 10, graindur=0.1, amp=0.2;
	var pan, env, freqdev; 
	var trig = Impulse.kr(density);
	pan = MouseX.kr(-1, 1);		// use mouse x to control panning
	// use WhiteNoise and mouse y to control deviation from center
	freqdev = WhiteNoise.kr(MouseY.kr(400, 0));
	GrainSin.ar(2, trig, graindur, 440 + freqdev, pan, envbuf) * amp
};
)



	// switching envelopes while playing
	
q = q ? ();		// make a dict to keep things around
q.envs = ();		// e.g. some envelopes 
q.bufs = ();		// and some buffers
				// make an envelope, and convert it to a buffer
q.envs.perc1 = Env([0, 1, 0], [0.1, 0.9], -4);
q.bufs.perc1 = Buffer.sendCollection(s, q.envs.perc1.discretize, 1);

	// switch between built-in hanning envelope and custom - perc1
~grain.set(\envbuf, -1);
~grain.set(\envbuf, q.bufs.perc1.bufnum);



	//  fixed parameters and control proxies
~grain.set(\density, 20);
~grain.set(\graindur, 0.03);

	// map a control proxy to a parameter
~grdur = 0.1;
~grain.map(\graindur, ~grdur);
~grdur = { LFNoise1.kr(1).range(0.01, 0.1) };
~grdur = { SinOsc.kr(0.3).range(0.01, 0.1) };
~grdur = 0.01;

	// create random densities from 2 to 2 ** 6, exponentially distributed
~grdensity = { 2 ** LFNoise0.kr(1).range(0, 6) };
	// map to density control
~grain.map(\density, ~grdensity);
~grdensity = { 2 ** LFNoise0.kr(1).range(2, 4) };


~grain.clear;

	// GrainFM with mouse control
(
~grain.play;
		// original
~grain = { arg envbuf = -1, density = 10, graindur=0.1, modfreq=200;
	var pan = MouseX.kr(-1, 1);
	var trig = Impulse.kr(density);
	var freqdev = WhiteNoise.kr(MouseY.kr(0, 400));
	var freq = 440 + freqdev;
	var moddepth = LFNoise1.kr.range(1, 10);
	GrainFM.ar(2, trig, graindur, freq, modfreq, moddepth, pan, envbuf) 
	* 0.2
};
)

(	// help file example rewritten to use MouseX for modulation range
~grain = { arg envbuf = -1, density = 10, graindur=0.1, modfreq=200;
	var pan = WhiteNoise.kr;
	var trig = Impulse.kr(density);
	var freqdev = WhiteNoise.kr(MouseY.kr(0, 400));
	var freq = 440 + freqdev;
	var modrange = MouseX.kr(1, 10);
	var moddepth = LFNoise1.kr.range(1, modrange);
	GrainFM.ar(2, trig, graindur, freq, modfreq, moddepth, pan, envbuf) 
	* 0.2
};
)


	// figure 16.13   - GrainFM with individual control proxies
(
~trig = { |dens=10| Impulse.kr(dens) };
~freq = { MouseX.kr(100, 2000, 1) * LFNoise1.kr(1).range(0.25, 1.75) };
~moddepth = { LFNoise1.kr(20).range(1, 10) };
~modfreq = 200;
~graindur = 0.1;

~grain = { arg envbuf = -1;
	GrainFM.ar(2, ~trig.kr, ~graindur.kr, 
		~freq.kr, ~modfreq.kr, ~moddepth.kr, 
		pan: WhiteNoise.kr, envbuf: envbuf) * 0.2
};
~grain.play;
)
	// change control ugens: 
~modfreq = { ~freq.kr * LFNoise2.kr(1).range(0.5, 2.0) }; // modfreq roughly follows freq
~trig = { |dens=10| Dust.kr(dens)};	// random triggering, same density
~freq = { LFNoise0.kr(0.3).range(200, 800) };
~moddepth = 3; 	// fixed depth
~graindur = { LFNoise0.kr.range(0.01, 0.1) };



	// bonus: blend dust and impulse triggers
~trig = { |dens=20, bal=0.2| Dust.kr(dens * (1-bal)) + Impulse.kr(dens * bal) };
~trig.set(\bal, 0.1);
~trig.set(\bal, 0.5);
~trig.set(\bal, 0.9);

ProxyMixer(p);




p = ProxySpace.push;


	// figure 16.14 - GrainBuf and control proxies

b = Buffer.read(s, "sounds/a11wlk01-44_1.aiff");
(
~grain.set(\wavebuf, b.bufnum);
~trig = { |dens=10| Impulse.kr(dens) };
~graindur = 0.1;
~filepos = {LFNoise2.kr(0.2).range(0, 1) };
~rate = { LFNoise1.kr.range(0.5, 1.5) };

~grain = { arg envbuf = -1, wavebuf = 0;
	GrainBuf.ar(2, ~trig.kr, ~graindur.kr, wavebuf, 
	~rate.kr, ~filepos.kr, 2, WhiteNoise.kr, envbuf) * 0.2
};
~grain.play;
)

	// experiment with control proxies
~trig = { |dens=20| Impulse.kr(dens) };
~rate = { LFNoise1.kr.range(0.99, 1.01) };
~filepos = { MouseX.kr + LFNoise0.kr(100, 0.03) };
~graindur = 0.05;
~trig = { |dens=50| Dust.kr(dens) };

c = Buffer.sendCollection(s, Env.perc(0.01, 0.99).discretize, 1);
~grain.set(\envbuf, c.bufnum); 
~grain.set(\envbuf, -1);

~trig = { |dens=50| Impulse.kr(dens) }; ~graindur = 0.05;






	// FM grain as synthdef
(
SynthDef(\grainFM0, {|out, carfreq=440, modfreq=200, moddepth = 1, 
	sustain=0.02, amp=0.2, pan|
	
	var env = EnvGen.ar(Env.sine(sustain, amp), doneAction: 2);
	var sound = SinOsc.ar(carfreq, SinOsc.ar(modfreq) * moddepth) * env;
	OffsetOut.ar(out, Pan2.ar(sound, pan))
}, \ir.dup(7)).memStore;
)
(instrument: \grainFM0, sustain: 0.1, amp: 0.2).play;

	// to use buffer envelopes: Osc1 
(
q = q ? ();
q.envbuf = Buffer.sendCollection(s, Env.perc(0.1, 0.9).discretize, 1);

SynthDef(\grainFM1, {|out, envbuf, carfreq=440, modfreq=200, moddepth = 1, 
	sustain=0.02, amp=0.2, pan|
	
	var env = Osc1.ar(envbuf, sustain, doneAction: 2);
	var sound = SinOsc.ar(carfreq, SinOsc.ar(modfreq) * moddepth) * env;
	OffsetOut.ar(out, Pan2.ar(sound, pan, amp))
}, \ir.dup(8)).memStore;
)

(instrument: \grainFM1, sustain: 0.1, envbuf: q.envbuf).play;

(
Pbindef(\fm, 
		\instrument, \grainFM1, 
		\carfreq, Pbrown(300, 1200, 300), 
		\modfreq, 200, 
		\modindex, Pbrown(1.0, 10.0, 2.5), 
		\sustain, 0.1, 
		\dur, 0.1,
		\envbuf, q.envbuf,
		\pan, Pwhite(-0.8, 0.8)
).play;
)




	// GrainBuf as synthdef
(
q = q ? ();
q.envbuf = Buffer.sendCollection(s, Env.perc(0.1, 0.9).discretize, 1);
q.apollo = Buffer.read(s,"sounds/a11wlk01.wav");

SynthDef(\grainBuf1, {|out, envbuf, wavebuf, filepos, rate=1, 
	sustain=0.02, amp=0.2, pan|
	
	var env = Osc1.ar(envbuf, sustain, doneAction: 2);
	var sound = PlayBuf.ar(1, wavebuf, 
		rate * BufRateScale.ir(wavebuf), 1,
		startPos: BufFrames.ir(wavebuf) * filepos) 
		* env;
	
	OffsetOut.ar(out, Pan2.ar(sound, pan, amp))
}, \ir.dup(8)).memStore;
)

(instrument: \grainBuf1, sustain: 0.1, envbuf: q.envbuf, wavebuf: q.apollo).play;

(
Pdef(\buf1, 
	Pbind(
		\instrument, \grainBuf1, 
		\envbuf, q.envbuf, \wavebuf, q.apollo,
		\sustain, 0.1, \dur, 0.05,
		\pan, Pwhite(-0.8, 0.8),
		\filepos, Pn(Pseries(0, 0.01, 100))
	)
).play;
)

q.envbuf.sendCollection(Env.sine.discretize);
q.envbuf.sendCollection(Env.perc.discretize);



	// figure 16.15 - Glisson synthesis
(
SynthDef("glisson", 
	{ arg out = 0, envbuf, freq=800, freq2=1200, sustain=0.001, amp=0.2, pan = 0.0;
		var env = Osc1.ar(envbuf, sustain, 2);
		var freqenv = XLine.ar(freq, freq2, sustain);
		OffsetOut.ar(out, 
			Pan2.ar(SinOsc.ar(freqenv) * env, pan, amp)
		)
}, \ir!7).memStore;
)

(
Tdef(\gliss0, { |e|
	100.do({ arg i;
		s.sendBundle(s.latency, ["/s_new", "glisson", -1, 0, 0, 
			\freq, i % 10 * 100 + 1000,
			\freq2, i % 13 * -100 + 3000,
			 \sustain, 0.05, 
			 \amp, 0.1,
			 \envbuf, q.envbuf.bufnum
		]);
		(3 / (i + 10)).wait;
	});
}).play;
)



/*
	Magnetization patterns can be:
	bidirectional, shallow, 
	bidirectional, deep, 
	unidir, up,
	unidir, down,
	converging to center, 
	diverging from center. 
*/

(
SynthDef(\glisson0, { |out, freq1=440, freq2=660, sustain=0.05, amp=0.2, pan, envwide=0.5| 
	var slopetime = (1 - envwide) * 0.5;
	var sound = SinOsc.ar(XLine.ar(freq1, freq2, sustain));
	var env = EnvGen.ar(
		Env([0, amp, amp, 0], [slopetime, envwide, slopetime], \sin), 
		timeScale: sustain,
		doneAction: 2);
	OffsetOut.ar(out, Pan2.ar(sound * env, pan));
}).memStore; 
)

(
Tdef(\biGliss).set(\fmin, 100, \fmax, 5000, \fratio, 1.0); // non-gliss, wide freq range

Tdef(\biGliss, { |envir|
	
	var f1, f2, temp; 
	inf.do { 
		f1 = exprand(envir.fmin, envir.fmax);
		f2 = f1 * (envir.fratio ** 1.0.rand2);
	//	[f1, f2].postln;
		(	instrument: \glisson0, 
			freq1: f1, 
			freq2: f2,
			pan: 1.0.rand2,
			sustain: 0.05
		).play;
		0.03.wait;
	};
}).play;
)
Tdef(\biGliss).play;
Tdef(\biGliss).set(\fratio, 1.4);	// shallow
Tdef(\biGliss).set(\fratio, 3.0);	// wide


Tdef(\biGliss).set(\fmin, 600, \fmax, 600, \fratio, 1.0);  // fixed
Tdef(\biGliss).set(\fmin, 600, \fmax, 600, \fratio, 1.4);  // diverging, shallow
Tdef(\biGliss).set(\fmin, 600, \fmax, 600, \fratio, 2);	   // diverging

(
Tdef(\biGliss).set(\fmin, 1800, \fmax, 600, \fratio, 2.0);	// converging
Tdef(\biGliss, { |envir|
		
	var f1, f2, temp; 
	500.do { 
		f1 = exprand(envir.fmin, envir.fmax);
		f2 = f1 * (envir.fratio ** 1.0.rand2);
		
		(	instrument: \glisson0, 
			freq1: f2, 	// swap f1 and f2 here for converging
			freq2: f1,
			pan: 1.0.rand2,
			sustain: 0.1
		).play;
		0.1.linrand.wait;
	};
}).play;
)

Tdef(\biGliss).set(\fmin, 1800, \fmax, 2600, \fratio, 2.0);   // converging




	// figure 16.16 - Pulsar basics - make a set of waveform and control tables
(
q = ();
q.curr = (); 	// make a dict for the set of tables
q.curr.tab = ();
				// random tables for pulsaret  and envelope waveforms:
q.curr.tab.env = Env.perc.discretize; 
q.curr.tab.pulsaret = Signal.sineFill(1024, { 1.0.rand }.dup(7));

			// random tables for the control parameters:
q.curr.tab.fund = 200 ** Env({1.0.rand}!8, {1.0.rand}!7, \sin).discretize.as(Array);
q.curr.tab.form = 500 ** ( 0.5 + Env({rrand(0.0, 1.0)}!8, {1.0.rand}!7, \sin).discretize.as(Array));
q.curr.tab.amp = 0.2.dup(1024);
q.curr.tab.pan = Signal.sineFill(1024, { 1.0.rand }.dup(7));

			// make buffers from all of them:
q.bufs = q.curr.tab.collect({ |val, key| Buffer.sendCollection(s, val, 1) });
)
		// plot one of them
q.bufs.pulsaret.plot("a pulsaret");




	// figure 16.17 - Pulsars as nodeproxies using GrainBuf
(
p = ProxySpace.push; 

		// fund, form, amp, pan
~controls = [ 16, 100, 0.5, 0]; 
~pulsar1.set(\wavebuf, q.bufs.pulsaret.bufnum);
~pulsar1.set(\envbuf, q.bufs.env.bufnum);

~pulsar1 = { |wavebuf, envbuf = -1| 
	var ctls = ~controls.kr;
	var trig = Impulse.ar(ctls[0]);
	var grdur = ctls[1].reciprocal;
	var rate = ctls[1] * BufDur.kr(wavebuf);
		
	GrainBuf.ar(2, trig, grdur, wavebuf, rate, 0, 4, ctls[3], envbuf);
};
~pulsar1.play;
)

	// crossfade between control settings
~controls.fadeTime = 3; 
~controls = [ 16, 500, 0.5, 0]; 	// change formfreq
~controls = [ 50, 500, 0.5, 0]; 	// change fundfreq
~controls = [ 16, 100, 0.5, 0]; 	// change both
~controls = [ rrand(12, 100), rrand(100, 1000)]; 

(	// control parameters from looping tables
~controls = { |looptime = 10| 
	var rate = BufDur.kr(q.bufs.pulsaret.bufnum) / looptime; 
	A2K.kr(PlayBuf.ar(1, [\fund, \form, \amp, \pan].collect(q.bufs[_]), 
		rate: rate, loop: 1));
};
)


	// figure 16.18 - make new tables and send them to buffers

	// make new pulsaret tables and send them to the buffer:
q.bufs.pulsaret.sendCollection(Array.linrand(1024, -1.0, 1.0)); // noise burst
q.bufs.pulsaret.read("sounds/a11wlk01.wav", 44100 * 1.5);       // sample
q.bufs.pulsaret.sendCollection(Pbrown(-1.0, 1.0, 0.2).asStream.nextN(1024));

	// make a new random fundfreq table, and send it
q.curr.tab.fund = 200 ** Env({1.0.rand}!8, {1.0.rand}!7, \sin).discretize.as(Array);
q.bufs.fund.sendCollection(q.curr.tab.fund);

	// and a new random formfreq table
q.curr.tab.form = 500 ** ( 0.5 + Env({rrand(0.0, 1.0)}!8, {1.0.rand}!7, \sin).discretize.as(Array));
q.bufs.form.sendCollection(q.curr.tab.form);







	// Pulsar synthesis with client-side control
	
		// a pulsaret and an envelope
a = Signal.sineFill(1024, 1/(1..10).scramble).putLast(0);
b = Env.perc.discretize(1024).putLast(0);
		// as buffers
x = Buffer.sendCollection(s, a, 1);
y = Buffer.sendCollection(s, b, 1);

		// a pulsar synthdef
(
SynthDef(\pulsar1, {|out, wavebuf, envbuf, form=200, amp=0.2, pan| 
	var grDur =  1/form;
	var pulsaret = Osc1.ar(wavebuf, grDur);
	var env = Osc1.ar(envbuf, grDur, doneAction: 2);
	
	OffsetOut.ar(out, Pan2.ar(pulsaret * env, pan, amp));
}, \ir ! 6).memStore;
)
Synth(\pulsar1, [\wavebuf, x, \envbuf, y]);

	// a simple pattern
(
Pbindef(\pulsar1, 
		\instrument, \pulsar1, 
		\wavebuf, x, \envbuf, y, 
		\form, Pn(Penv([20, 1200], [4], \exp)).loop, 
		\amp, 0.2, \pan, 0,
		\fund, 12, 
		\dur, Pfunc({ |ev| ev.fund.reciprocal })
).play;
)



	// Control from patterns and tables

Pbindef(\pulsar1, \form, Pn(Penv([20, 1200], [4], \exp)).loop);
Pbindef(\pulsar1, \fund, Pn(Penv([5, 50], [5])).loop);
Pbindef(\pulsar1, \amp, Pn(Penv([0, 0.2, 0.1], [7])).loop);
Pbindef(\pulsar1, \pan, Pbrown(-1.0, 1.0, 0.2));
Pbindef(\pulsar1, \amp, 0.2);

	// use Pseg for a control table reader
f = Env({ 100.0.rand }.dup(10), {1.0.rand}.dup(9).normalizeSum, \sine).asSignal;
f.plot;

Pbindef(\pulsar1, \fund, Pseg(f, 0.01, \lin, inf)).play;




				// time-pitch changing // 



		// figure 16.19 time-pitch changing
p = ProxySpace.push(s.boot);
b = Buffer.read(s, "sounds/a11wlk01-44_1.aiff");
(
~timepitch = {arg sndbuf, pitchRatio=1, pitchRd=0.01, grainRate=10, overlap=2, 
	posSpeed=1, posRd=0.01;
	
	var graindur = overlap / grainRate;
	var pitchrate = pitchRatio + LFNoise0.kr(grainRate, pitchRd);
	var position = LFSaw.kr(posSpeed / BufDur.kr(sndbuf)).range(0, 1) 
		+ LFNoise0.kr(grainRate, posRd);
		
	GrainBuf.ar(2, Impulse.kr(grainRate), graindur, sndbuf, pitchrate,
			position, 4, 0, -1)
};
~timepitch.set(\sndbuf, b.bufnum);
~timepitch.play;
);

Spec.add(\pitchRatio, [0.25, 4, \exp]);
Spec.add(\pitchRd, [0, 0.5, \amp]);
Spec.add(\grainRate, [1, 100, \exp]);
Spec.add(\overlap, [0.25, 16, \exp]);
Spec.add(\posSpeed, [-2, 2]);
Spec.add(\posRd, [0, 0.5, \amp]);
NodeProxyEditor(~timepitch, 10);

	// reconstruct original
~timepitch.set(\pitchRatio, 1, \pitchRd, 0, \grainRate, 20, \overlap, 4, \posSpeed, 1, \posRd, 0);

	// four times as long: tweak pitchRd and posJitter to reduce artifacts
~timepitch.set(\pitchRatio, 1, \pitchRd, 0, \grainRate, 20, \overlap, 4, \posSpeed, 0.25, \posRd, 0);

	// random read position, random pitch
~timepitch.set(\pitchRatio, 1, \pitchRd, 0.5, \grainRate, 20, \overlap, 4, \posSpeed, 0.25, \posRd, 0.5);






			// examples constantQ granulation 


	// figure 16.20 - A constant-Q Synthdef.

b = Buffer.read(s, "sounds/a11wlk01-44_1.aiff");
(
SynthDef(\constQ, { |out, bufnum=0, amp=0.1, pan, centerPos=0.5, sustain=0.1, 
	rate=1, freq=400, rq=0.3| 

	var ringtime = (2.4 / (freq * rq) * 0.66).min(0.5); // estimated
	var ampcomp = (rq ** -1) * (400 / freq ** 0.5);	
	var envSig = EnvGen.ar(Env([0, amp, 0], [0.5, 0.5] * sustain, \welch));
	var cutoffEnv = EnvGen.kr(Env([1, 1, 0], [sustain+ringtime,0.01]), doneAction: 2);
	var grain = PlayBuf.ar(1, bufnum, rate, 0, 
		centerPos - (sustain * rate * 0.5) * BufSampleRate.ir(bufnum), 
		1) * envSig;	
	var filtered = BPF.ar( grain, freq, rq, ampcomp ); 

	OffsetOut.ar(out, Pan2.ar(filtered, pan, cutoffEnv))
}, \ir.dup(8)).memStore;
)

Synth(\constQ, [\bufnum, b, \freq, exprand(100, 10000), \rq, exprand(0.01, 0.1), \sustain, 0.01]);




	// parameter tests for constant Q granulation
	
Synth(\constQ, [\bufnum, b]);
Synth(\constQ, [\bufnum, b, \centerPos, 0.5]);	// centerPos = where in soundfile (seconds)
Synth(\constQ, [\bufnum, b, \centerPos, 1]);	
Synth(\constQ, [\bufnum, b, \centerPos, 1.5]);	
	
	// sustain is sustain of exciter grain: 
Synth(\constQ, [\bufnum, b, \centerPos, 0.5, \sustain, 0.01]);
Synth(\constQ, [\bufnum, b, \centerPos, 0.5, \sustain, 0.03]);
Synth(\constQ, [\bufnum, b, \centerPos, 0.5, \sustain, 0.1]);
Synth(\constQ, [\bufnum, b, \centerPos, 0.5, \sustain, 0.3]);

	// filter parameters, rq of bandpass determines ringtime
Synth(\constQ, [\bufnum, b, \freq, 1200, \rq, 1]);
Synth(\constQ, [\bufnum, b, \freq, 1200, \rq, 0.3]);
Synth(\constQ, [\bufnum, b, \freq, 1200, \rq, 0.1]);
Synth(\constQ, [\bufnum, b, \freq, 1200, \rq, 0.03]);
Synth(\constQ, [\bufnum, b, \freq, 1200, \rq, 0.01]);
Synth(\constQ, [\bufnum, b, \freq, 1200, \rq, 0.003]);

	// lower freq rings longer
Synth(\constQ, [\bufnum, b, \freq, 600, \rq, 0.003]);



	// figure 16.21 - a stream of constant Q grains
(
Pbindef(\gr1Q, 
	\instrument, \constQ, \bufnum, b.bufnum,
	\sustain, 0.01, \amp, 0.2,
	\centerPos, Pn(Penv([1, 2.0], [10], \lin)), 
	\dur, Pn(Penv([0.01, 0.09, 0.03].scramble, [0.38, 0.62] * 10, \exp)),
	\rate, Pwhite(0.95, 1.05), 
	\freq, Pbrown(64.0, 120, 8.0).midicps,
	\pan, Pwhite(-1, 1, inf),
	\rq, 0.03
).play;
)
	// changing parameters while playing
Pbindef(\gr1Q, \rq, 0.1);
Pbindef(\gr1Q, \rq, 0.01);
Pbindef(\gr1Q, \sustain, 0.03, \amp, 0.08);
Pbindef(\gr1Q, \freq, Pbrown(80, 120, 18.0).midicps);

Pbindef(\gr1Q, \rq, 0.03);

Pbindef(\gr1Q, \rate, Pn(Penv([1, 2.0], [6], \lin)));

	// variable duration
Pbindef(\gr1Q, \dur, Pwhite(0.01, 0.02));

	// a rhythm that ends
Pbindef(\gr1Q, \dur, Pgeom(0.01, 1.1, 40));





	//	figure 16.22 - a Wavesets object
w = Wavesets.from("sounds/a11wlk01.wav");

w.xings;			// all integer indices of the zero crossings found
w.numXings;		// the total number of zero crossings
w.lengths;		// lengths of all wavesets
w.amps;			// peak amplitude of every waveset
w.maxima;			// index of positive maximum value in every waveset
w.minima;			// index of negative minimum value in every waveset

w.fracXings;		// fractional zerocrossing points
w.fracLengths;	// and lengths: allows more precise looping.
				
w.lengths.plot;	// show distribution of lengths
w.amps.plot;

	// get data for a single waveset: frameIndex, length (in frames), dur
w.frameFor(140, 1);	
w.ampFor(140, 1);		// peak amplitude of that waveset or group
	
	// extract waveset by hand
w.signal.copyRange(w.xings[150], w.xings[151]).plot("waveset 150");
w.plot(140, 1);	// convenience plotting
w.plot(1510, 1);	

	// plot a group of 5 adjacent wavesets
w.plot(1510, 5)	



	// figure 16.23 and 24 are screenshots



	//	figure 16.25 - wavesets and buffers

	// A Synthdef to play a waveset (or group) n times.
(
	// A wavesets loads the file into a buffer by default.
		b = w.buffer;		
	// Wavesets.prepareSynthDefs loads this synthdef: 
		SynthDef(\wvst0, { arg out = 0, buf = 0, start = 0, length = 441, playRate = 1, sustain = 1, amp=0.2, pan; 
			var phasor = Phasor.ar(0, BufRateScale.ir(buf) * playRate, 0, length) + start;
			var env = EnvGen.ar(Env([amp, amp, 0], [sustain, 0]), doneAction: 2);
			var snd = BufRd.ar(1, buf, phasor) * env;
			
			OffsetOut.ar(out, Pan2.ar(snd, pan));
		}, \ir.dup(8)).memStore;
)

// play from frame 0 to 440, looped for 0.1 secs, so ca 10 repeats. 
(instrument: \wvst0, bufnum: b.bufnum, start: 0, length: 440, amp: 1, sustain: 0.1).play;

	// get data from waveset
(
var start, length, sustain, repeats = 20; 
#start, length, sustain = w.frameFor(150, 5);

(	instrument: \wvst0, bufnum: b.bufnum, amp: 1, 
	start: start, length: length, sustain: sustain * repeats
).play;
)

	// or even simpler: 
w.eventFor(startWs: 150, numWs: 5, repeats: 20, playRate: 1).put(\amp, 0.5).play;




	// figure 16.26 - a pattern to play wavesets

	// by default, this pattern reconstructs a soundfile segment.
(
Pbindef(\ws1).clear;
Pbindef(\ws1, 
	\instrument, \wvst0,
	\startWs, Pn(Pseries(0, 1, 3000), 1), 
	\numWs, 1, 
	\playRate, 1, 
	\bufnum, b.bufnum, 
	\repeats, 1, 
	\amp, 0.4,
	[\start, \length, \sustain], Pfunc({ |ev| 
		var start, length, wsDur; 

		#start, length, wsDur = w.frameFor(ev[\startWs], ev[\numWs]);
		[start, length, wsDur * ev[\repeats] / ev[\playRate].abs]
	}), 
	\dur, Pkey(\sustain)
).play;
)



	//	figure 16.27 - some of wishart's transforms

	// waveset transposition: every second waveset, half speed
Pbindef(\ws1, \playRate, 0.5, \startWs, Pn(Pseries(0, 2, 500), 1)).play;

	// reverse every single waveset 
Pbindef(\ws1, \playRate, -1, \startWs, Pn(Pseries(0, 1, 1000), 1)).play;
	// reverse every 2 wavesets
Pbindef(\ws1, \numWs, 2, \playRate, -1, \startWs, Pn(Pseries(0, 2, 1000), 1)).play;
	// reverse every 20 wavesets
Pbindef(\ws1, \numWs, 20, \playRate, -1, \startWs, Pn(Pseries(0, 20, 1000), 1)).play;
	// restore
Pbindef(\ws1, \numWs, 1, \playRate, 1, \startWs, Pn(Pseries(0, 1, 1000), 1)).play;

	// time stretching
Pbindef(\ws1, \playRate, 1, \repeats, 2).play;
Pbindef(\ws1, \playRate, 1, \repeats, 4).play;
Pbindef(\ws1, \playRate, 1, \repeats, 6).play;
Pbindef(\ws1, \repeats, 1).play;	// restore

	// waveset omission: drop every second
Pbindef(\ws1, \numWs, 1, \freq, Pseq([1, \], inf) ).play;
Pbindef(\ws1, \numWs, 1, \freq, Pseq([1,1, \, \], inf) ).play;
Pbindef(\ws1, \numWs, 1, \freq, Pfunc({ if (0.25.coin, 1, \) }) ).play; // drop randomly
Pbindef(\ws1, \numWs, 1, \freq, 1, \startWs, Pn(Pseries(0, 1, 1000)) ).play; // restore

	// waveset shuffling (randomize waveset order +- 5, 25, 125)
Pbindef(\ws1, \startWs, Pn(Pseries(0, 1, 1000), 1) + Pfunc({ 5.rand2 })).play;
Pbindef(\ws1, \startWs, Pn(Pseries(0, 1, 1000), 1) + Pfunc({ 25.rand2 })).play;
Pbindef(\ws1, \startWs, Pn(Pseries(0, 1, 1000), 1) + Pfunc({ 125.rand2 })).play;	





	//	figure 16.28 - waveset substitution
	
	// the waveform to substitute
c = Buffer.alloc(s, 512); c.sendCollection(Signal.sineFill(512, [1]));
(
Pbindef(\ws1).clear;
Pbindef(\ws1, 
	\instrument, \wvst0,
	\startWs, Pn(Pseries(0, 1, 1000), 5), 
	\numWs, 1, \playRate, 1, 
	\buf, c.bufnum, // sine wave
	\repeats, 1, 
	\amp, 1,
	[\start, \length, \sustain], Pfunc({ |ev| 
		var start, length, wsDur, origRate; 
		origRate = ev[\playRate];
		
			// get orig waveset specs
		#start, length, wsDur = w.frameFor(ev[\startWs], ev[\numWs]);

			// adjust playrate for different length of substituted wave
		ev[\playRate] = origRate * (512 / length); 

			// get amplitude from waveset, to scale full volume sine wave
		ev[\amp] = ev[\amp] * w.ampFor(ev[\startWs], ev[\numWs]);
		
		[0, 512, wsDur * ev[\repeats] / origRate.abs]
	}), 
	\dur, Pkey(\sustain)
).play;
)
	// clearer sinewave-ish segments
Pbindef(\ws1, \playRate, 1, \repeats, 2).play;
Pbindef(\ws1, \playRate, 1, \repeats, 6).play;
Pbindef(\ws1).stop;

	// different waveforms
c.sendCollection(Signal.sineFill(512, 1/(1..4).squared.scramble));
c.sendCollection(Signal.rand(512, -1.0, 1.0));
c.sendCollection(Signal.sineFill(512, [1]));

c.plot;




	//	waveset interpolation - web examples only
(
SynthDef("wsInterp", { arg out = 0, 
	buf1 = 0, start1 = 0, len1 = 1000, 
	buf2 = 0, start2 = 0, len2 = 500, 
	playRate = 1, sustain = 1, 
	amp=0.2, pan; 
	
	var lenRatio = (len1 / len2);
	var playRateLine = Line.ar(playRate, playRate * lenRatio, sustain); 
	
	var phasor1 = Phasor.ar(0, BufRateScale.ir(buf1) * playRateLine, 0, len1);
	var phasor2 = phasor1 / lenRatio; 
	var xfade = Line.ar(0, 1, sustain);
	
	var snd = (BufRd.ar(1, [buf1, buf2], 
		[phasor1 + start1, phasor2 + start2], 
		interpolation: 4)
		* [1 - xfade, xfade]).sum;
	
	OffsetOut.ar(out, 
		Pan2.ar(
			snd * EnvGen.ar(Env([amp, amp, 0], [sustain, 0]), doneAction: 2),
		 	pan
	 	)
	 );
}, \ir.dup(12)).memStore;
)

(
q = q ? ();
q.playInterp = { |q, start1, len1, start2, len2, numWs=200| 
	var set1 = w.frameFor(start1, len1).postln;
	var set2 = w.frameFor(start2, len2).postln; 
	var sustain = (set2[2] + set1[2] * 0.5 * numWs).postln;

	(instrument: \wsInterp, buf1: b.bufnum, buf2: b.bufnum, amp: 0.5,
	
		start1: set1[0], len1: set1[1], playRate: 1,
		start2: set2[0], len1: set2[1], sustain: sustain
	).play;	
};
)
	// some interpolations
q.playInterp(200, 1, 500, 1, 400);
q.playInterp(400, 8, 600, 3, 100);
q.playInterp(200, 1, 500, 5, 600);





	//	figure 16.29 - wavesets played with Tdef 
	
	// very simple first pass, fixed repeat time
(
Tdef(\ws1).set(\startWs, 400);
Tdef(\ws1).set(\numWs, 5);
Tdef(\ws1).set(\repeats, 5);

Tdef(\ws1, { |ev|
	var startFrame, length, wsSustain; 

	loop { 
		#startFrame, length, wsSustain = w.frameFor(ev.startWs.next, ev.numWs);

		(instrument: \wvst0, bufnum: b.bufnum, amp: 1, 
			start: startFrame, length:  length, 
			sustain: wsSustain * ev.repeats;
		).play;
		
		0.1.wait;	
	}
}).play;
)

Tdef(\ws1).set(\startWs, 420);
Tdef(\ws1).set(\repeats, 3);
Tdef(\ws1).set(\numWs, 2);

		// drop in a pattern for starting waveset 		
Tdef(\ws1).set(\startWs, Pn(Pseries(0, 5, 400) + 500, inf).asStream);





	// figure 16.30 - waittime from waveset duration, gap
(
Tdef(\ws1).set(\gap, 3);
Tdef(\ws1, { |ev|
	var startFrame, length, wsSustain, reps; 

	loop { 
		reps = ev.repeats.next;

		#startFrame, length, wsSustain = 
			w.frameFor(ev.startWs.next, ev.numWs.next);			
		
		(instrument: \wvst0, bufnum: b.bufnum, amp: 1, 
			start: startFrame, length:  length, 
			sustain: wsSustain * reps,
			pan: 1.0.rand2
		).play;
		
			// derive waittime from waveset sustain time
			// add gap based on waveset sustain time 
		(wsSustain * (reps + ev.gap.next)).wait;
	}
}).play;
)
	// experiment with dropping in patterns:
	// very irregular gaps
Tdef(\ws1).set(\gap, { exprand(0.1, 20) });
	// sometimes continuous, sometimes gaps
Tdef(\ws1).set(\gap, Pbrown(-10.0, 20, 2.0).max(0).asStream);

	// random repeats
Tdef(\ws1).set(\repeats, { exprand(1, 20).round });
	// randomize number of wavesets per group
Tdef(\ws1).set(\numWs, { exprand(3, 20).round });
Tdef(\ws1).set(\numWs, 3, \repeats, { rrand(2, 5) });

Tdef(\ws1).stop;



	// figure 16.31 - add pitch contour and dropout rate
(
Tdef(\ws1).set(\startWs, Pn(Pseries(0, 5, 400) + 500, inf).asStream);

Tdef(\ws1).set(\gap, 0);
Tdef(\ws1).set(\pitchContour, 0);
Tdef(\ws1).set(\keepCoin, 1.0);
Tdef( 'ws1' ).set( 'repeats' , 5 );
Tdef( 'ws1' ).set( 'numWs' , 3 );

Tdef(\ws1, { |ev|
	var startFrame, length, wsSustain, reps, numWs, len2Avg; 
	var squeezer, playRate;
	loop { 
		reps = ev.repeats.next;
		numWs = ev.numWs.next;
		
		#startFrame, length, wsSustain = 
			w.frameFor(ev.startWs.next, numWs);			
		
		len2Avg = length / numWs / w.avgLength;		
		squeezer = len2Avg ** ev.pitchContour.next;
		wsSustain = wsSustain / squeezer; 
		playRate = 1 * squeezer;

		if (ev.keepCoin.next.coin) { 
			(instrument: \wvst0, bufnum: b.bufnum, amp: 1, 
				start: startFrame, length:  length, 
				sustain: wsSustain * reps,
				playRate: playRate, 
				pan: 1.0.rand2
			).play;
		};
		
		(wsSustain * (reps + ev.gap.next)).wait;
	}
}).play;
)

	// try different pitch Contours:
Tdef(\ws1).set(\pitchContour, 0); 	// original pitch

Tdef(\ws1).set(\pitchContour, 0.5); // flattened contour

		// waveset overtone singing - all equal length
Tdef(\ws1).set(\pitchContour, 1.0); 

		// inversion of contour
Tdef(\ws1).set(\pitchContour, 1.5);
Tdef(\ws1).set(\pitchContour, 2);
Tdef(\ws1).set(\repeats, 3); 

	// waveset omission
Tdef(\ws1).set(\keepCoin, 0.75);
Tdef(\ws1).set(\keepCoin, 1);

	// fade out by omission over 13 secs, pause 2 secs 
Tdef(\ws1).set(\keepCoin, Pn(Penv([1, 0, 0], [13, 2])).asStream).play;

	// add a pitch contour envelope
Tdef(\ws1).set(\pitchContour, Pn(Penv([0, 2, 0], [21, 13])).asStream);




"Hello world"

Server.default = s = Server.internal.boot;

/////////////

play({SinOsc.ar(LFNoise0.kr(12, mul: 600, add: 1000), 0.3)})

/////////////

play({RLPF.ar(Dust.ar([12, 15]), LFNoise1.ar(1/[3, 4], 1500, 1600), 0.02)})

///////////// Figure 1.1 Example of additive synthesis

play({
	var sines = 100, speed = 6;
	Mix.fill(sines, 
		{arg x; 
			Pan2.ar(
				SinOsc.ar(x+1*100, 
					mul: max(0, 
						LFNoise1.kr(speed) +
						Line.kr(1, -1, 30)
					)
				), rand2(1.0))})/sines})

/////////////

rand(100)

exprand(1.0, 100.0) 

thisThread.randSeed = 666; {rand(10.0)} ! 10;

dup("echo", 20)

round([3.141, 5.9265, 358.98], 0.01)

sort([23, 54, 678, 1, 21, 91, 34, 78])

round(dup({exprand(1, 10)}, 100), 0.1)

sort(round(dup({exprand(1, 10)}, 100), 0.1))

/////////////

                            exprand(1.0, 1000.0)
                   dup({exprand(1.0, 1000.0)}, 100)
           sort(dup({exprand(1.0, 1000.0)}, 100))
round(sort(dup({exprand(1.0, 1000.0)}, 100)), 0.01)

///////////// Figure 1.3 Fortuitous futuristic nested music.

(
play(
	{
		CombN.ar(
			SinOsc.ar(
				midicps(
					LFNoise1.ar(3, 24, 
						LFSaw.ar([5, 5.123], 0, 3, 80)
					)
				), 
				0, 0.4), 
			1, 0.3, 2)
	}
)
)

/////////////

[45, 13, 10, 498, 78].sort // collection of items, do this; sort yourself

"echo".dup(20) // echo, do this; repeat yourself 20 times

50.midicps // the number 50, do this; convert yourself into Hz

444.cpsmidi // 444, do this; convert yourself into a midi number

100.rand // 100, do this; pick a number between 0 and yourself

{100.rand}.dup(50) // random picking function, do this; repeat 50 times

[1.001, 45.827, 187.18].round(0.1) // collection of items; round to 0.1

// Mac users only, sorry
"I've just picked up a fault in the AE35 unit".speak // Hal; plot to kill me

/////////////

1000.0 // a number

1000.0.rand // choose a number between 0 and 1000

1000.0.rand.round(0.01) // choose a number and round it

1000.0.rand.round(0.01).post // choose, round, then post

{1000.0.rand.round(0.01).postln}.dup(100).plot // choose, round, dup, plot

{1000.0.rand.round(0.01).postln}.dup(100).postln.sort.plot // choose etc., sort, plot

//Mac only
1000.0.rand.round(0.01).postln.asString.speak // convert to string and speak

5 + 10 * 4

[0, 11, 10, 1, 9, 8, 2, 3, 7, 4, 6, 5].reverse // retrograde of a 12-tone row

12 - [0, 11, 10, 1, 9, 8, 2, 3, 7, 4, 6, 5].reverse // retrograde inversion

[0, 2, 4, 5, 6, 7, 9, 11].scramble // diatonic scale

[60, 62, 64, 67, 69].mirror // pentatonic

[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11].rotate

[60, 62, 64, 65, 67, 69, 71].midicps.round(0.1) // convert midi to frequency in Hz

[1, 0.75, 0.5, 0.25, 0.125].choose // maybe durations?

0.125 * [1, 2, 3, 4, 5, 6, 7, 8].choose // multiples of a smallest quantize value

[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11].permute(6) 

/////////////

exprand(1, 1000.0)

{exprand(1, 1000.0)}

dup(rand(1000.0), 5)  // picks a number, duplicates it

dup({rand(1000.0)}, 5)  //duplicates the function of picking a number

// essentially, this (which has a similar result) 
[rand(1000.0), rand(1000.0), rand(1000.0), rand(1000.0), rand(1000.0)]

/////////////

{LFNoise0.ar}.play  //play a series of random numbers

{LFNoise0.ar(10000)}.plot // plot those numbers

{LFNoise0.ar(10000)}.scope // play and show on a scope

{100.rand}.dup(10) // pick 10 random numbers

{100.rand} ! 10 // same as above

{100.rand}.dup(10).postln.plot // pick 10 numbers, post, then plot them

{100.rand}.dup(100).sort.plot // pick 100 numbers, sort them, then plot

/////////////

{Blip.ar(25, LFNoise0.kr(5, 12, 14), 0.3)}.play // single channel

{Blip.ar(25, LFNoise0.kr([5, 10], 12, 14), 0.3)}.play // stereo

{Blip.ar(25, LFNoise0.kr([5, 10, 2, 25], 12, 14), 0.3)}.play // quad

{Blip.ar(25, LFNoise0.kr([5, 4, 7, 9, 5, 1, 9, 2], 12, 14), 0.3)}.play // 8

/////////////

{PMOsc.ar(440, 550, 7)}.play // pretty boring, like an FM radio

{PMOsc.ar(440, MouseY.kr(1, 550), MouseX.kr(1, 15))}.play

{PMOsc.ar(100, 500, 10, 0, 0.5)}.play // all arguments listed in order

{PMOsc.ar(carfreq: 100, modfreq: 500, pmindex: 10, mul: 0.5)}.play // keywords

{PMOsc.ar(carfreq: 100, mul: 0.5, pmindex: 10, modfreq: 500)}.play // mixed

{SinOsc.ar(mul: MouseX.kr(0, 1.0))}.scope

///////////// Figure 1.4 VCO, VCF, VCA

(
{
	Blip.ar(
		TRand.kr( // frequency or VCO
			100, 1000, // range
			Impulse.kr(Line.kr(1, 20, 60))), // trigger
		TRand.kr( // number of harmonics or VCF
			1, 10, // range
			Impulse.kr(Line.kr(1, 20, 60))), // trigger
		Linen.kr( // mul, or amplitude, VCA
			Impulse.kr(Line.kr(1, 20, 60)), // trigger
			0, // attack
			0.5, // sustain level
			1/Line.kr(1, 20, 60)) // trigger
		)
}.play
)

/////////////

(
a = 440;
b = 3;
c = "math operations";
[c, a, b, a*b, a + b, a.pow(b), a.mod(b)]
)

// same as
["math operations", 440, 3, 440*3, 440 + 3, 440.pow(3), 440.mod(3)]

/////////////

(
{
r = MouseX.kr(1/3, 10);
SinOsc.ar(mul: Linen.kr(Impulse.kr(r), 0, 1, 1/r))
}.play
)

///////////// Example 1.5 Synthesis example with variables and statements

(
// run this first
p = { // make p equal to this function
r = Line.kr(1, 20, 60); // rate
// r = LFTri.kr(1/10) * 3 + 7;
t = Impulse.kr(r); // trigger
// t = Dust.kr(r);
e = Linen.kr(t, 0, 0.5, 1/r); // envelope uses r and t
f = TRand.kr(1, 10, t); // triggered random also uses t
// f = e + 1 * 4;
Blip.ar(f*100, f, e) // f, and e used in Blip
}.play
)

p.free;  // run this to stop it

///////////// Figure 1.6 Phase modulation with modulator as ratio

(
{ // carrier and modulator not linked
	r = Impulse.kr(10);
	c = TRand.kr(100, 5000, r);
	m = TRand.kr(100, 5000, r);
	PMOsc.ar(c, m, 12)*0.3
}.play
)

(
{
	var rate = 4, carrier, modRatio; // declare variables
	carrier = LFNoise0.kr(rate) * 500 + 700;
	modRatio = MouseX.kr(1, 2.0);
	// modulator expressed as ratio, therefore timbre
	PMOsc.ar(carrier, carrier*modRatio, 12)*0.3
}.play
)

/////////////

{SinOsc.ar}.play // generates a temp__reallyLongNumber name

// names the synth and output bus 0 (left) explicitly
SynthDef("sine", {Out.ar(0, SinOsc.ar)}).play

SynthDef("sine", {Out.ar(1, SinOsc.ar)}).play // right channel

// or

(
SynthDef("one_tone_only", {
	var out, freq = 440;
	out = SinOsc.ar(freq);
	Out.ar(0, out)
}).play
)

// then to play it

Synth("one_tone_only");

/////////////

(
SynthDef("different_tones", {
	arg freq = 440; // declare an argument and give it a default value
	var out; 
	out = SinOsc.ar(freq)*0.3;
	Out.ar(0, out)
}).play
)

/////////////

// Run all four, then stop all 

Synth("different_tones", ["freq", 550]);

Synth("different_tones", [\freq, 660]); // same as "freq"

Synth("different_tones", ["freq", 880]);

// If no argument is specified, defaults are used (440)
Synth("different_tones")

/////////////

a = Synth("different_tones", ["freq", 64.midicps]);

b = Synth("different_tones", ["freq", 67.midicps]);

c = Synth("different_tones", ["freq", 72.midicps]);

a.set("freq", 65.midicps);

c.set("freq", 71.midicps);

a.set("freq", 64.midicps); c.set("freq", 72.midicps);

a.free; 

b.free; 

c.free;

///////////// Figure 1.7 Synth definition

(
//run this first
SynthDef("PMCrotale", {
arg midi = 60, tone = 3, art = 1, amp = 0.8, pan = 0; 
var env, out, mod, freq;

freq = midi.midicps;
env = Env.perc(0, art);
mod = 5 + (1/IRand(2, 6));

out = PMOsc.ar(freq, mod*freq, 
	pmindex: EnvGen.kr(env, timeScale: art, levelScale: tone), 
	mul: EnvGen.kr(env, timeScale: art, levelScale: 0.3));

out = Pan2.ar(out, pan);

out = out * EnvGen.kr(env, timeScale: 1.3*art, 
	levelScale: Rand(0.1, 0.5), doneAction:2);  
Out.ar(0, out); //Out.ar(bus, out);

}).add;
)

//Then run this a bunch of times:

Synth("PMCrotale", ["midi", rrand(48, 72).round(1), "tone", rrand(1, 6)])


~houston = Buffer.read(s, "sounds/a11wlk01-44_1.aiff");

~chooston = Buffer.read(s, "sounds/a11wlk01.wav");

{PlayBuf.ar(1, ~houston)}.play; // number of channels and buffer.

{PlayBuf.ar(1, ~chooston)}.play; // number of channels and buffer.

///////////// Figure 1.8 Playback buffers

[~houston.bufnum, ~houston.numChannels, ~houston.path, ~houston.numFrames];

[~chooston.bufnum, ~chooston.numChannels, ~chooston.path, ~chooston.numFrames];

(  // phasing
{
	var rate, trigger, frames;
	frames = ~houston.numFrames; // or use ~chooston.numFrames

	rate = [1, 1.01];
	trigger = Impulse.kr(rate);
	PlayBuf.ar(1, ~houston, 1, trigger, frames * Line.kr(0, 1, 60)) * 
	EnvGen.kr(Env.linen(0.01, 0.96, 0.01), trigger) * rate;
}.play;
)

/////////////

(  // speed and direction change
{
	var speed, direction;
	speed = LFNoise0.kr(12) * 0.2 + 1;
	direction = LFClipNoise.kr(1/3);
	PlayBuf.ar(1, ~houston, (speed * direction), loop: 1);
}.play;
)

///////////// Figure 1.9 Connecting controls with a bus

(
// if these haven't been used they will hold 0
~kbus1 = Bus.control; // a control bus
~kbus2 = Bus.control; // a control bus
{
	var speed, direction;
	speed = In.kr(~kbus1, 1) * 0.2 + 1;
	direction = In.kr(~kbus2);
	PlayBuf.ar(1, ~chooston, (speed * direction), loop: 1);
}.play;
)

(
// Start the controls
{Out.kr(~kbus1, LFNoise0.kr(12))}.play;

{Out.kr(~kbus2, LFClipNoise.kr(1/4))}.play;
)

// Start the second buffer with the same control input buses, 
// but send it to the right channel using Out.ar(1 etc.

(
{
	var speed, direction;
	speed = In.kr(~kbus1, 1) * 0.2 + 1;
	direction = In.kr(~kbus2);
	Out.ar(1, PlayBuf.ar(1, ~houston, (speed * direction), loop: 1));
}.play;
)

/////////////

~kbus3 = Bus.control; // a control bus

~kbus4 = Bus.control; // a control bus
  // run these one at a time, (turn down the speakers!)

{Out.kr(~kbus3, SinOsc.kr(3).scope("out3") * 100)}.play; 

{Out.kr(~kbus4, LFPulse.kr(1/3).scope("out4") * 200)}.play;

{Out.ar(0, SinOsc.ar(In.kr(~kbus3) + In.kr(~kbus4) + 440).scope("left"))}.play;

{Out.ar(1, SinOsc.ar(In.kr(~kbus3) + In.kr(~kbus4) + 880).scope("right"))}.play;

~kbus3 = Bus.control; // a control bus 

~kbus4 = Bus.control; // a control bus 

{Out.kr(~kbus3, SinOsc.kr(3).range(340, 540))}.play;

{Out.kr(~kbus4, LFPulse.kr(6).range(240, 640))}.play;

SynthDef("Switch", {arg freq = 440; Out.ar(0, SinOsc.ar(freq, 0, 0.3)) }).add;

x = Synth("Switch"); // default

x.map(\freq, ~kbus3)

x.map(\freq, ~kbus4)

///////////// Figure 1.10 Buffer modulation

(
{
	Out.ar(0,
		Pan2.ar( PlayBuf.ar(1, ~houston, loop: 1) * 
			SinOsc.ar(LFNoise0.kr(12, mul: 500, add: 600)),
		0.5)
	)
}.play
)

(
{
var source, delay; 
	source = PlayBuf.ar(1, ~chooston, loop: 1);
	delay =  AllpassC.ar(source, 2, [0.65, 1.15], 10);
	Out.ar(0,
	Pan2.ar(source) + delay
	)
}.play
)

///////////// Figure 1.11 FX routing using buses.

// Create and name buses 
~delay = Bus.audio(s, 2);
~mod = Bus.audio(s, 2);
~gate = Bus.audio(s, 2);
~k5 = Bus.control;

{Out.kr(~k5, LFNoise0.kr(4))}.play; // start the control

// Start the last item in the chain, the delay
{Out.ar(0, AllpassC.ar(In.ar(~delay, 2), 2, [0.65, 1.15], 10))}.play 

// Start the next to last item, the modulation
{Out.ar(~delay, In.ar(~mod, 2) * SinOsc.ar(In.kr(~k5)*500 + 1100))}.play

// Start the third to last item, the gate
{Out.ar([0, ~mod], In.ar(~gate, 2) * max(0, In.kr(~k5)))}.play

// Start one buffer
{Out.ar(~gate, Pan2.ar(PlayBuf.ar(1, ~houston, loop: 1), 0.5))}.play;

// Start the other
{Out.ar(~gate, Pan2.ar(PlayBuf.ar(1, ~chooston, loop: 1), -0.5))}.play

/////////////

a = ["C", "C#", "D",  "Eb", "E", "F", "F#", "G", "Ab", "A", "Bb", "B "];

a.at(8);

"Item at index 5 is: ".post; a.at(5).postln; // why didn't it print E?

"Item at index 0 is: ".post; a.at(0).postln; // because we start with 0

do(50, { [0, 2, 4, 5, 7, 9, 11].at(7.rand).postln})

do(50, { ["C", "D", "E", "F", "G", "A", "B"].at(7.rand).postln})

///////////// 

Task({
	50.do({
		["C", "D", "E", "F", "G", "A", "B"].at(7.rand).postln;
		1.wait;
	});
}).play

///////////// Figure 1.12 Random MIDI walk.

Task({
a = ["C", "C#", "D",  "Eb", "E", "F", "F#", "G", "Ab", "A", "Bb", "B"];
"count, midi, pitch, octave".postln;
	do(50, {arg count;
		p = rrand(36, 72);
		[count, p, a.wrapAt(p), (p/12).round(1) - 1].postln;
	1.wait;
	})
}).play

///////////// 1.13 Random Crotale Walk

// This uses the PMCrotale synth definition
(
a = ["C", "C#", "D",  "Eb", "E", "F", "F#", "G", "Ab", "A", "Bb", "B"];
"event, midi, pitch, octave".postln;
r = Task({
	inf.do({ arg count;
		var midi, oct, density;
		density = 1.0; // 100% of the time. Uncomment below for 70%, etc.
		// density = 0.7; 
		// density = 0.3;
		midi = [0, 2, 4, 7, 9].choose;
		// midi = [0, 2, 4, 5, 7, 9, 11].choose;
		// midi = [0, 2, 3, 5, 6, 8, 9, 11] .choose; 
		// midi = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] .choose;
		oct = [48, 60, 72].choose;
		if(density.coin, 
			{ // true action
				"".postln;
				[midi + oct, a.wrapAt(midi), 
				(oct/12).round(1)].post;
				Synth("PMCrotale", 
					["midi", midi + oct, "tone", rrand(1, 7), 
					"art", rrand(0.3, 2.0), "amp", rrand(0.3, 0.6), "pan", 1.0.rand2]);
			}, {["rest"].post}); // false action
		0.2.wait; 
	}); 
}).start
)

r.stop; // run this to stop

/////////////

if(10 == 10, {"10 is indeed equal to 10"}, {"false"})

if((1 < 20).and(1.isInteger), {"1 is less than 20"}, {"false"})

10.do({arg count; [count, if(count.odd, {"odd"}, {"even"})].postln})

(
84.do({arg count; if([0, 4, 7].includes(count%12), 
	{count.post; " is part of a C triad.".postln}, 
	{count.post; " is not part of a C traid".postln})})
)

50.do({if(1.0.rand.round(0.01).post > 0.5,  {" > 0.5".postln}, {" < 0.5".postln})})

50.do({if(1.0.rand > 0.5,  {"play a note".postln}, {"rest".postln})})

50.do({if(0.5.coin, {"play a note".postln}, {"rest".postln})}) // same as above

if((10.odd).or(10 < 20), {"true".postln}, {"false".postln})

/////////////

Array.fill(100, {wchoose([1, 2, 3, 4], [0.5, 0.3, 0.125, 0.075])}).sort

/////////////

[0, 2, 4, 5, 7, 9, 11].do({arg each, count; ["count", count, "each", each].postln})  
// same
[0, 2, 4, 5, 7, 9, 11].do({arg whatever, blech; [blech, whatever].postln})

(
var pc;
pc = ["C", "C#", "D",  "Eb", "E", "F", "F#", "G", "Ab", "A", "Bb", "B"];
[0, 2, 4, 5, 7, 9, 11].do({arg each; pc.wrapAt(each).postln;})
)

///////////// Figure 1.14 Nested do to generate a 12-tone matrix.

(
var row, inversion, pitchClass;
row = Array.series(11, 1).scramble.insert(0, 0); 
// or enter your own row, e.g. Webern's Op 27
// row = [0, 11, 8, 2, 1, 7, 9, 10, 4, 3, 5, 6]; 
row.postln;
inversion = 12 - row;
// I add spaces to the strings for a tidy row
pitchClass = ["C  ", "C# ", "D  ", "Eb ", 
	"E  ", "F  ", "F# ", "G  ", "Ab ", "A  ", "Bb ", "B  "];
inversion.do({arg eachInv;
	var trans;
	trans = (row + eachInv); 
	// prints just pitch class
	trans.do({arg scaleDegree; pitchClass.wrapAt(scaleDegree).post});
	//"".postln; // uncomment these line if you want to do both
	// prints just numbers
	//trans.do({arg scaleDegree; (scaleDegree%12).post; " ".post});
	"".postln;
	});
"".postln
)

/////////////

{LFNoise1.ar(5000)}.plot // random wave 

{max(0, LFNoise1.ar(5000))}.plot // return only positive values

(
{
var ampCont;
ampCont = max(0, LFNoise1.kr(12)); // slow it down for LFO control
SinOsc.ar(440, mul: ampCont)
}.scope
)

///////////// Figure 1.15 Example of additive synthesis

// Mix down a few of them tuned to harmonics:

(
{
var fund = 220;
Mix.ar(
	[
	SinOsc.ar(220, mul: max(0, LFNoise1.kr(12))),
	SinOsc.ar(440, mul: max(0, LFNoise1.kr(12)))*1/2,
	SinOsc.ar(660, mul: max(0, LFNoise1.kr(12)))*1/3,
	SinOsc.ar(880, mul: max(0, LFNoise1.kr(12)))*1/4,
	SinOsc.ar(1110, mul: max(0, LFNoise1.kr(12)))*1/5,
	SinOsc.ar(1320, mul: max(0, LFNoise1.kr(12)))*1/6
	]
)*0.3
}.play
)

///////////// Figure 1.16 Example of additive synthesis

// Try this first
Array.fill(20, {arg cnt; cnt + 1*110}); // harmonics built on 440

// And a patch
(
{Mix.ar(
	Array.fill(12, 
		{arg count; 
		var harm;
		harm = count + 1 * 110; // remember precedence; count + 1, then * 110
			SinOsc.ar(harm, 
				mul: max([0, 0], SinOsc.kr(count+1/4))
				)*1/(count+1)
		})
)*0.7}.play
)

///////////// Figure 1.18 Physically modeled bells. 

// Try this first, to illustrate the array of arrays.

Array.fill(3, {Array.fill(10, {rand(1000)})})	
// Then this patch.
(
{
var scale, specs, freqs, amps, rings, 
	numRes = 5, bells = 20, pan; 
scale = [60, 62, 64, 67, 69].midicps;
	Mix.fill(bells, {
		freqs = Array.fill(numRes, {rrand(1, 15)*(scale.choose)});
		amps = Array.fill(numRes, {rrand(0.3, 0.9)});
		rings = Array.fill(numRes, {rrand(1.0, 4.0)});
		specs = [freqs, amps, rings].round(0.01);
		// specs.postln;
		pan = (LFNoise1.kr(rrand(3, 6))*2).softclip;
		Pan2.ar( 
			Klank.ar(`specs, 
				Dust.ar(1/6, 0.03)), 
				pan)
	})
}.play;
) 

///////////// Figure 1.19 Generative sequences using arrays

( // first define the synth

SynthDef.new("SimpleBlip", { 
arg midi = 60, tone = 10, art = 0.125, amp = 0.2, pan = -1;
var out, temper;	
out =	Pan2.ar(
			Blip.ar( // play the sequence
				midi.midicps,
				tone
				) * EnvGen.kr(Env.perc(0.01, art)),
		pan // pan left, center, or right
	);
DetectSilence.ar(out, doneAction:2);
amp = amp - ((midi - 60) * 0.02);
Out.ar(0, out*amp)
	}).add;
)

/////////////
 
(
// Then run this Task
~inst = [0, 0, 0]; // Three containers for tasks
~pSeq = [0, 0, 0]; // Three containers for sequences
~scaleAdd = [4, 5, 11, nil, 10, 3, 6, nil]; // 
~notes = 
[" C", " C#", " D", " Eb", " E", " F", 
	" F#", " G", " Ab", " A", " Bb", " B"]; 
~rout = Task({
	inf.do({
		arg cnt1; 
		var steps, durSeq, harmSeq;
		steps = rrand(6, 12);
		if(cnt1%6 == 0, // every sixth iteration, add a degree
			{~scale = ~scale.add(~scaleAdd.wrapAt((cnt1/6).round(1) - 1));}); 
		"\nIteration: ".post; cnt1.post; 
		[" (center) ", " (right) ", " (left) "].wrapAt(cnt1).postln;
		if(cnt1%24 == 0, // reset all three
			{~scale = [0, 2, 7, 9]; 
			3.do({arg cnt2; 
				~pSeq.wrapPut(cnt2, 
					Array.fill(steps, 
						{~scale.choose + [48, 60].choose}))})});
		"scale: ".post; ~scale.postln;
		~pSeq.wrapPut(cnt1, // fill array with scale steps
			Array.fill(steps, {~scale.choose + [48, 60].choose}));
		"MIDI seq: ".post; (~pSeq.wrapAt(cnt1)%12).postln;
		"Sequence (notes): ".post; 
		~pSeq.wrapAt(cnt1).do( // print the sequence using note names
			{arg thisItem; ~notes.at(thisItem%12).post}); 
		"".postln;
		// create harmonic and duration arrays
		harmSeq = Array.fill(steps, {rrand(1.0, 5.0)});
		durSeq = Array.fill(steps - 1, {rrand(0.01, 0.9)});
		// stop the previous task at this array position
		~inst.wrapAt(cnt1).stop;
		~inst.wrapPut(cnt1, 
			Task({
				inf.do({arg cnt3; // each sequence
					Synth("SimpleBlip", 
						[\midi, ~pSeq.wrapAt(cnt1).wrapAt(cnt3), 
						\tone, harmSeq.wrapAt(cnt3), 
						\art, durSeq.wrapAt(cnt3), 
						\amp, rrand(0.1, 0.3), 
						\pan, cnt1.wrap(-1, 2)]);
					0.125.wait; // tempo of each note
				})}).start;
		);
		12.wait;})
}).start; // time between each new sequence
)

~rout.stop; // stop new sequences

~inst.at(0).free; // at any time, stop center sequence

~inst.at(1).free; // stop right sequence

~inst.at(2).free; // stop center sequence

/////////////

Server.internal.prepareForRecord; // or Server.local

Server.internal.record;

Server.internal.stopRecording;

// Run these variations before to change file formats.
Server.internal.recSampleFormat = "int16"; // change format

Server.internal.recChannels = 1; // change from the default stereo
// saves file in the SC folder, will be overwritten if repeated

Server.internal.prepareForRecord("myAudio.aif"); 

///////////// Figure 1.20 Offset and scale

(
	{
	var trigger, wave, label, scale, offset;
	trigger = Impulse.kr(10);
	wave = SinOsc.kr(1/10) ; // change to 400
	scale = 1; offset = 0;
//	wave = wave * scale + offset; 
	label = "scale = " ++ scale.asString ++ ", offset = " ++ offset.asString;
	wave.round(0.01).poll(label: label);
	}.scope(1)
)

///////////// Figure 1.21 SinOsc offset and scaled for control

(
	{
	var trigger, control, scale, offset;
	scale = 300; // try other values, but not greater than offset
	offset = 600; // try other values
	trigger = Impulse.kr(10);
	control = SinOsc.ar(1/4).scope("control"); // LFO
	control = control  * scale + offset;
	SinOsc.ar(freq: abs(control).poll).scope("audio")
	}.play
) 

// Speaking of vibrato, I can't resist this faux Theremin. Play it with the Mouse: 

{SinOsc.ar(SinOsc.ar(8, 0, 10, MouseX.kr(400, 1000, 1)))}.play

///////////// Figure 1.22 Test you skills on a patch

(
{
	var carrier, rate, trigger, modRatio, index, control, env;
	rate = 3;
	trigger = Impulse.kr(rate);
	control = LFNoise0.kr(rate);
	carrier = 62;
	modRatio = 4.125;
	index = 10;
	carrier = carrier.midicps;
	carrier.poll(trigger, "carrier"); 
	index.poll(trigger, "index"); 
	modRatio.poll(trigger, "modRatio");
	PMOsc.ar(carrier, carrier*modRatio, index)
}.play
)

///////////// Figure 1.23 PMOsc with offset and scale. 

(
a = SynthDef("PMOsc_ex", 
{
	arg left = 10, right = 10, indexLow = 4, indexHigh = 12;
	var pitch, timbre, trigger, env, index, out;
	trigger = Impulse.kr([left, right]); // trigger
	pitch = TRand.kr(36, 72, trigger).round(1); // C2 to C6
	timbre = LFNoise0.kr(1/20, mul: 0.2, add: 2); // mod control
	env = Linen.kr(trigger, releaseTime: 1/[left, right]); // envelope
	index = env * indexHigh + indexLow; // env scaled and offset for index
	pitch = pitch.midicps; // midi converted to freq
	out = PMOsc.ar(pitch, pitch*timbre, index, mul: env);
	Out.ar(0, out);
}).play
)

a.set("left", 4)

a.set("right", 5)

a.set("indexLow", 1)

a.set("indexHigh", 4)

///////////// Figure 1.24 PMOsc with sample and hold (latch).

(
// run this first
a = SynthDef("Latch_demo",
{
arg rate = 9; 
var freq, latchrate, index, ratio, env, out;
latchrate = rate*LFNoise0.kr(1/10, mul: 0.03, add: 1.6);
index = Latch.kr(
	LFSaw.kr(latchrate, mul: 5, add: 6),
	Impulse.kr(rate)
	);
freq = Latch.kr(
	LFSaw.kr(latchrate, 
	mul: max(0, LFNoise1.kr(1/5, mul: 24, add: 10)), 
	add: LFNoise0.kr(1/7, mul: 12, add: 60)),
	Impulse.kr(rate)
	).round(1).midicps;

ratio = LFNoise1.kr(1/10, mul: 2.0, add: 5.0);

env = EnvGen.kr(
	Env.perc(0, LFNoise0.kr(rate, mul: 1, add: 1.5)/rate), 
	Impulse.kr(rate), 
	LFNoise1.kr([5, 5], 2, 1).max(0).min(0.8));
out = PMOsc.ar(
	[freq, freq * 1.5],
	freq*ratio,
	index,
	mul: env
);
Out.ar(0, out);
}
).play
)

a.set("rate", 10)

a.set("rate", 15)

a.set("rate", 6)

a.free;

///////////// Figure 1.25 It's just a bell.

(
{ // it's just a bell
var burst, burstEnv, bell, delay, dry, 
burstFreq = 500, freqs, amps, rings;
burstEnv = EnvGen.kr(Env.parc(0, 0.05),
				Dust.kr(1/5), 0.1);
// burstEnv.poll(100, "env");
burst = SinOsc.ar(freq: burstFreq,
	mul: burstEnv);
// burst.poll(100, "burst");
freqs = Array.fill(10, {exprand(100, 1000)});
amps = Array.fill(10, {rrand(0.01, 0.1)});
rings = Array.fill(10, {rrand(1.0, 6.0)});
// [freqs, amps, rings].round(0.01).postln;
// "safe" values
// freqs = [100, 200, 300, 400];
// amps = [1, 1, 1, 1];
// rings = [1, 1, 1, 1];

bell = Pan2.ar(
	Klank.ar(`[freqs, amps, rings], burst), 
	rrand(-1.0, 1.0)
);

delay = AllpassN.ar(bell, 2.5, 
	[LFNoise1.kr(7, 1.5, 1.6), LFNoise1.kr(7, 1.5, 1.6)], 
	1, mul: 0.8);
bell 
+ delay
// + SinOsc.ar(mul: LFPulse.kr(1) * 0.05);
}.play
)




// Decaying bell. Run several concurrently. 

(
{
var aenv, fenv, out, trig, dur, base;
dur = rrand(1.0, 6.0);
base = exprand(100, 1000);
trig = Impulse.kr(1/6);
out = Mix.ar(
	Array.fill(15,{
		arg count;
		var thisDur;
		thisDur = dur * rrand(0.5, 1.0);
		aenv = EnvGen.kr(
			Env.new([0, 1, 0.4, 1, 0], [0, 0.5, 0.5, 0]), trig, 
			timeScale: thisDur);
		fenv = EnvGen.kr(
			Env.new([0, 0, 0.5, 0.5, 0], [0.25, 0.5, 0.25, 0]), 
				trig, timeScale: thisDur);
		Pan2.ar(SinOsc.ar( Rand(base, base * 12) * 
			LFNoise1.kr(10, mul: 0.1 * fenv, add: 1), // freq
			mul: aenv // amp
		), ([1, -1].choose) * fenv)
	})
) * EnvGen.kr(Env.linen(0, dur, 0), Impulse.kr(6), timeScale: dur, 
		levelScale: 0.05, doneAction: 2);
out*0.3;
}.play;
)


// Repeating gestures using PM crotales.

(
SynthDef("crotale", {
arg param = #[500, 3, 2, 0, 6, 5, 0, 0.9]; 
var factor, env, out, freq, index, dur;
var bus, ratioa, ratiob, attack, decay, panCont;
freq = param.at(0); index = param.at(1); dur = param.at(2);
bus = param.at(3); ratioa = param.at(4); ratiob = param.at(5);
attack = param.at(6); decay = param.at(7);

env = Env.perc(attack, decay);
factor = gcd(ratioa, ratiob);
ratioa = div(ratioa, factor); 
ratiob = div(ratiob, factor);

panCont = (EnvGen.kr(env, timeScale: dur*1.1, 
	levelBias: -1, levelScale: 2))
			* (IRand(0, 1) * 2 - 1);  // 0*2-1 = -1, 1*2-1 = 1

out = PMOsc.ar(
	ratioa*freq, //or try ratioa*freqCont,
	ratiob*freq, //or try ratioa*freqCont,
	pmindex: EnvGen.kr(env, timeScale: dur, 
		levelBias: 1, levelScale: index), 
	mul: EnvGen.kr(env, timeScale: dur, levelScale: 0.3));

out = Pan2.ar(out, panCont);

out = out * EnvGen.kr(env, timeScale: 1.3*dur, 
	levelScale: Rand(0.1, 0.5), doneAction:2);  
Out.ar(0, out); //Out.ar(bus, out);

}).add;
)

// Define the instrument by running the code
// above, then run this task to actually play 
// the instrument. Run several concurrently.


(
r = Task({
	var freq, indexDepth, indexRange, synthIndex, dur, repeat;
	var next, count, countDown, offset, ratioa, ratiob, envs, env;
	var range = 60, outBus = 0;
	count = 0; countDown = 0; offset = 0;
	envs = [[0, 0.9], [0.01, 0.9], [0.1, 0.8], [0.8, 0.01]];
	repeat = Array.fill(10, 
		{[rrand(range, range+24).round(1).midicps, 3, 
			2.1 - exprand(0.1, 2.0), 0, 1, 1, 0, 0.9]});
	next = Array.fill(10, {[3, 0.75, 0.5, 0.25, 0.125].choose});
	freq = rrand(range, range*2); // these two are just starting points
	indexDepth = 1;
	
	inf.do({
		if(countDown <= 0,
			{
			env = envs.choose;
			next.put(count%10, [3, 0.5, 0.25, 0.125, 0.125].choose); 
			repeat.put(count%10, [
				rrand(range, range + 24).round(1).midicps, 
				rrand(0.1, 12.0),
				2.1 - exprand(0.1, 2.0), outBus, rrand(1, 12),  
				rrand(1, 12), env.at(0), env.at(1)]);
			});
			
			Synth("crotale").setn(\param, repeat.wrapAt(count));
			next.wrapAt(count).wait;   
			if((count > 10).and(countDown <= 0), 
				{offset = countDown = [0, 3.rand, 6.rand].choose; 
				count = count - offset});
	count = count + 1;
	countDown = countDown - 1;
	});
}).play(SystemClock);
)





// Chapter 10 - SwingOSC

// --------
// -------- SECTION 2 - INSTALLATION --------
// --------

//////// configuring startup file
// execute the next line only if you need to explicitly specify a java version
SwingOSC.java = "<javaPath>/java";	// replace <javaPath> here!
SwingOSC.program = "<installPath>/SwingOSC.jar";   // replace <installPath> here!
g = SwingOSC.default;

// --------
// -------- SECTION 3 - A SIMPLE GUI EXAMPLE --------
// --------

//////// booting SwingOSC
g.boot;
// wait until the "SwingOSC : server connected." message appears!

//////// creating and opening a window
~win = JSCWindow.new;
~win.front;

//////// adding a two-state button
(
~playButton = JSCButton( ~win, Rect( 4, 4, 40, 56 ));
~playButton.states = [[ "Play", Color.white, Color.green( 0.4 )],
                      [ "Stop", Color.white, Color.red ]];
~playButton.action = { arg view; "New value is %\n".postf( view.value )};
)

//////// Figure 10.1
// boot the sound synthesis server and prepare a SynthDef for buffer playback
(
s.waitForBoot({
    SynthDef( \bufPlay, { arg buf, amp = 1.0, speed = 1.0;
        Out.ar( 0, Pan2.ar( PlayBuf.ar( 1, buf, speed * BufRateScale.kr( buf ), loop: 1 ) * amp ));
    }).send( s );
    ~buf = Buffer.read( s, "sounds/a11wlk01.wav" );
});
)

// now replace the action function
(
~playButton.action = { arg view;
    if( view.value == 1, {
        ~node = Synth( \bufPlay, [ \buf, ~buf ]);
    }, {
        ~node.free; ~node = nil;
    })
};
)

//////// Figure 10.2
~amp   = 0.5;  // initial amplitude
~speed = 1.0;  // initial speed (1.0 is normal, 0.5 is half-speed, etc.)
(
~playButton.action = { arg view;
    if( view.value == 1, {
        ~node = Synth( \bufPlay, [ \buf, ~buf, \amp, ~amp, \speed, ~speed ]);
    }, {
        ~node.free; ~node = nil;
    })};
)
~win.setInnerExtent( 360, 72 );  // more suitable dimensions for the window
~win.resizable = false;
JSCStaticText( ~win, Rect( 56, 4, 50, 25 )).align_( \right ).string_( "Amp:" );
(
~ampSlider = JSCSlider( ~win, Rect( 110, 4, 200, 25 ))
    .value_( ~amp ) // initial slider position
    .action_({ arg view;
        ~amp = view.value;
        ~node.set( \amp, ~amp );
    });
)
JSCStaticText( ~win, Rect( 56, 32, 50, 25 )).align_( \right ).string_( "Speed:" );
~speedSpec = ControlSpec( 1/8, 8, \exp );
(
~speedSlider = JSCSlider( ~win, Rect( 110, 32, 200, 25 ))
    .value_( ~speedSpec.unmap( ~speed ))  // initial slider position
    .action_({ arg view;
        ~speed = ~speedSpec.map( view.value );
        ~node.set( \speed, ~speed );
    });
)

//////// alternative verbose version
// this is an alternative variant that should not be executed:
~label = JSCStaticText( ~win, Rect( 56, 4, 50, 25 ));
~label.align = \right;
~label.string = "Amp:";

//////// remove the variant if you accidentally executed its code
~label.remove;

// --------
// -------- SECTION 4 - USING THE MODEL-VIEW-CONTROLLER PATTERN --------
// --------

//////// Figure 10.4
~node.free; ~node = nil;

(
~model        = Event.new;
~model.amp    = ~amp;
~model.speed  = ~speed;
~model.node   = ~node;
~model.buf    = ~buf;
~model.adjust = { arg mod, key, value, source;
    mod.put( key, value );
    mod.changed( key, value, source )};

UpdateListener.newFor( ~model, { arg upd, mod, value;
    mod.node.set( \amp, value )}, \amp );
UpdateListener.newFor( ~model, { arg upd, mod, value;
    mod.node.set( \speed, value )}, \speed );

~playButton.action = { arg view;
    if( view.value == 1, {
        ~model.node = Synth( \bufPlay, [
            \buf, ~model.buf, \amp, ~model.amp, \speed, ~model.speed ]);
    }, {
        ~model.node.free; ~model.node = nil;
    })};
~ampSlider.action   = { arg view;
    ~model.adjust( \amp, view.value, view )};
~speedSlider.action = { arg view;
    ~model.adjust( \speed, ~speedSpec.map( view.value ), view )};
)

//////// Figure 10.5
(
~ampText = JSCStaticText( ~win, Rect( ~ampSlider.bounds.right + 2, 4, 50, 25 ));
~ampTextUpd = UpdateListener.newFor( ~model, { arg upd, mod, value;
    ~ampText.string = "% dB".format( value.ampdb.round( 0.1 ))}, \amp );
~speedText = JSCStaticText( ~win, Rect( ~speedSlider.bounds.right + 2, 32, 50, 25 ));
~speedTextUpd = UpdateListener.newFor( ~model, { arg upd, mod, value;
    ~speedText.string = "%\\%".format( (value * 100).round( 0.1 ))}, \speed );
)
// note: the sliders must be initially dragged to cause view updates!

//////// algorithmic controller
(
~ctrlFunc = { 60.do({
	~model.adjust( \speed, exprand( 1/8, 8 ), thisFunction );
	0.1.wait })};
)
~ctrlFunc.fork;	// run as a Routine

//////// Figure 10.7
(
~ampSliderUpd = UpdateListener.newFor( ~model, { arg upd, mod, value, source;
    if( source !== ~ampSlider, {
        ~ampSlider.value = value;
    })}, \amp );
~speedSliderUpd = UpdateListener.newFor( ~model, { arg upd, mod, value, source;
    if( source !== ~speedSlider, {
        ~speedSlider.value = ~speedSpec.unmap( value );
    })}, \speed );
)

//////// remove observers when views close
~ampSlider.onClose   = { ~ampSliderUpd.remove };
~speedSlider.onClose = { ~speedSliderUpd.remove };
~ampText.onClose     = { ~ampTextUpd.remove };
~speedText.onClose   = { ~speedTextUpd.remove };

//////// MVC is complete
~ctrlFunc.fork;

// --------
// -------- SECTION 5 - UNDER THE HOOD - THE INNER WORKINGS OF SWINGSOSC --------
// --------

// --------
// -------- SECTION 6 - RESPONDERS AND ASYNCHRONICITY --------
// --------

//////// seeing which messages are sent by the responders back to the client
g.dumpOSC( 0, 1 );
// if the "/info" messages are bothering, stop alive-thread
g.stopAliveThread;
// turning it off again
g.dumpOSC( 0, 0 );

//////// wait requires code to be run inside a Routine
2.wait; "hello".postln;           // not allowed! ("yield was called outside of a Routine.")
fork { 2.wait; "hello".postln };  // ok!

// --------
// -------- SECTION 7 - EXTENDING THE GUI REPERTOIRE USING JSCUSERVIEW --------
// --------

//////// removing the standard speed JSCSlider
~speedSlider.remove;

//////// Figure 10.13
(
~mySlider            = Event.new;
~mySlider.view       = JSCUserView( ~win, Rect( 110, 32, 200, 145 )).focusVisible_( false );
~mySlider.pos        = ~speedSpec.unmap( ~model.speed );
// these will be used in the final draw func:
~mySlider.pressed    = false;
~mySlider.project    = false;
// this will update the slider position and refresh the view:
~mySlider.adjustPos  = { arg slid, pos;
    slid.pos         = pos;
    slid.view.action.value( slid );
    slid.view.refresh };
// these will set the slider track curve and refresh the view:
~mySlider.adjustCurve= { arg slid, curve;
    slid.curve       = curve;
    slid.lines       = curve.slide( 2, 1 ).clump( 2 );
    slid.lineLens    = slid.lines.collect({ arg pair; pair[ 0 ].dist( pair[ 1 ])}).normalizeSum; 
    slid.projections = nil;
    slid.view.refresh };
// a primary draw function just to indicate the view's bounds:
~mySlider.view.drawFunc = { arg view; var b = view.bounds;
    JPen.line( 0 @ 0, b.width @ b.height );
    JPen.line( 0 @ b.height, b.width @�0 );
    JPen.stroke };
// make the window a little bigger:
~win.setInnerExtent( 370, 180 );
)

//////// Figure 10.14
(
~mySlider.adjustCurve([ 0 @ 0, 0.25 @ 1, 0.5 @ 0, 1.0 @ 0.5 ]);
~mySlider.view.drawFunc = { arg view;
    var b, scale, lnP1, lnP2, linePos, proj, inner, sum = 0;
    b     = view.bounds;
    // scaling factor for coordinates normalized to 0...1
    scale = b.width @ b.height;
    // set the initial curve coordinate
    JPen.moveTo( ~mySlider.curve[ 0 ] * scale );
    (1..(~mySlider.curve.size-1)).do({ arg i;
        // create the curve by adding successive line segments
        JPen.lineTo( ~mySlider.curve[ i ] * scale );
    });
    // stroke the curve with a 2-pixel wide black pen
    JPen.width = 2;
    JPen.color = Color.black;
    JPen.stroke;
    // draw the knob: iterate over the line segments until
    // the one is found inside which the knob (read from ~mySlider.pos)
    // is located.
    block { arg break;
        ~mySlider.lineLens.do({ arg len, i;
            // if we have found the line segment...
            if( sum + len >= ~mySlider.pos, {
                // calucate the point inside this segment
                // (proj) and draw a filled circle around it
                #lnP1, lnP2    = ~mySlider.lines[ i ];
                linePos        = (~mySlider.pos - sum) / len;
                proj           = lnP1 + ((lnP2 - lnP1) * linePos);
                JPen.fillOval( Rect.aboutPoint( proj * scale, 8, 8 ));
                // if this view is focused, use blue color, otherwise grey
                JPen.fillColor = Color.hsv( 0.7, view.hasFocus.if( 0.7, 0.0 ), 1.0 );
                // if the mouse is pressed, the outline should be thicker
                inner          = if( ~mySlider.pressed, 5, 7 );
                JPen.fillOval( Rect.aboutPoint( proj * scale, inner, inner ));
                break.value;
            });
            sum = sum + len;
        });
    };
    
    // a debugging utility to visualize the point projections
    // of the mouse dragging
    if( ~mySlider.project, {
        ~mySlider.projections.do({ arg pt;
            pt = pt * scale;
            JPen.line( pt + (-5 @ -5), pt + (5 @  5) );
            JPen.line( pt + (-5 @  5), pt + (5 @ -5) );
        });
        JPen.width = 1; JPen.stroke;
    });
};
)

//////// Figure 10.15
(
var mouseFunc = { arg view, x, y, modifiers, buttonNumber, clickCount;
    var b, nx, ny, dx, dy, lnP1, lnP2, linePos, lineLenSq,
        proj, dist, sum = 0, minDist = inf, newValue;
    
    b  = view.bounds;
    nx = x / b.width;
    ny = y / b.height;
    ~mySlider.projections = Array( ~mySlider.lines.size );
    // look up the line segment which is closest to the mouse
    ~mySlider.lines.do({ arg pair, i;
        #lnP1, lnP2 = pair;
        dx          = lnP2.x - lnP1.x;
        dy          = lnP2.y - lnP1.y;
        lineLenSq   = (dx*dx) + (dy*dy);
        dist        = (((nx - lnP1.x) * dx) + ((ny - lnP1.y) * dy)) / lineLenSq;
        proj        = (lnP1.x + (dist * dx)) @ (lnP1.y + (dist * dy));
        if( lnP1.x != lnP2.x, {
            linePos = (proj.x - lnP1.x) / dx;
        }, {
            linePos = (proj.y - lnP1.y) / dy;
        });
        if( linePos < 0, {
            proj = lnP1;
        }, { if( linePos > 1, {
            proj = lnP2;
        })});
        ~mySlider.projections.add( proj );
        dist = proj.dist( nx @ ny );
        if( dist < minDist, {
            newValue = sum + (linePos.clip( 0, 1 ) * ~mySlider.lineLens[i]);
            minDist  = dist;
        });
        sum = sum + ~mySlider.lineLens[ i ];
    });
    ~mySlider.pressed = true;
    ~mySlider.adjustPos( newValue );
};
~mySlider.view.mouseDownAction = mouseFunc;
~mySlider.view.mouseMoveAction = mouseFunc;
~mySlider.view.mouseUpAction   = { arg view; ~mySlider.pressed = false; view.refresh };
~mySlider.view.action          = { arg view;
    ~model.adjust( \speed, ~speedSpec.map( ~mySlider.pos ), ~mySlider )};
)

//////// making the point projections visible
~mySlider.project = true; ~mySlider.view.refresh;

//////// using a more elaborate curve
(
~mySlider.adjustCurve( Array.fill( 20, { arg i;
    Polar( (i + 1) / 40, i / 19 * 4pi ).asPoint + (0.5 @ 0.5) }));
)

//////// adding keyboard control
(
~mySlider.view.keyDownAction = { arg view, char, modifiers, unicode, keycode;
    switch( keycode, 37, {   // decrease slider-value with cursor-left
        ~mySlider.adjustPos( (~mySlider.pos - 0.05).max( 0.0 ))},
    39, {   // increase slider-value with cursor-right
        ~mySlider.adjustPos( (~mySlider.pos + 0.05).min( 1.0 ))})};
)

// --------
// -------- SECTION 8 - GENERIC JAVA SCRIPTING --------
// --------

//////// making incoming and outgoing OSC-messages visible
g.dumpOSC( 1, 1 );

//////// instantiating a JFrame and operating on it
~frame = JavaObject( "javax.swing.JFrame", nil, "Test" );
~frame.setSize( 400, 400 );
~frame.setVisible( true );

//////// adding a file chooser to the frame
~cp          = ~frame.getContentPane__;
~fileChooser = JavaObject( "javax.swing.JFileChooser" );
~cp.add( ~fileChooser );
~cp.revalidate;

//////// receiving a primitive value from the server
fork { ~title = ~frame.getTitle_; ~title.postln };

//////// reading the currently selected file's path
// note that this works only if a file is selected,
// otherwise an error is printed. we leave out the
// error handling here for brevity!
(
fork { ~file = ~fileChooser.getSelectedFile__;
       ~fileName = ~file.getAbsolutePath_; ~file.destroy; ~fileName.postln };
)

//////// Figure 10.17
(
~action = { arg fileName; "Selected file is '%'\n".postf( fileName )};
~sResp  = JavaObject( "de.sciss.swingosc.ActionResponder", nil, ~fileChooser.id );
~cResp  = OSCpathResponder( g.addr, [ '/action', ~fileChooser.id ], {
    fork { var file, fileName;
        file     = ~fileChooser.getSelectedFile__;
        fileName = file.getAbsolutePath_;
        file.destroy;
        ~action.value( fileName.asString );
    };
}).add;
)

//////// turn off OSC-dumping
g.dumpOSC( 0, 0 );

// --------
// -------- SECTION 9 - EMBEDDING ARBITRARY SWING VIEWS IN A JSCWINDOW --------
// --------

//////// Figure 10.18
(
~cp.remove( ~fileChooser );
~frame.dispose;
~cp.destroy; ~frame.destroy;
~win.setInnerExtent( 760, 340 );   // again a bit bigger
~plug = JSCPlugView( ~win, Rect( 370, 2, 386, 336 ), ~fileChooser );
~action = { arg fileName; var sf, oldBuf;
    // try to open as a sound file. returns nil if it could not be opened
    if( (sf = SoundFile.openRead( fileName )).notNil, {
        sf.close;  // the header info was read, we can close the file
        if( sf.numChannels == 1, {  // allow mono files only
            oldBuf = ~model.buf;
            if( ~model.node.notNil, {  // free old buffer when synth is freed
                UpdateListener.newFor( ~model.node, { arg upd;
                    upd.remove; oldBuf.free }, \n_end );
                ~model.node.register;
            }, {
                oldBuf.free;
            });
            ~model.buf = Buffer.read( s, fileName );  // replace buffer
        }, {
            "Sound file must be mono".error;
        });
    });
};
)

// --------
// -------- SECTION 10 - USING CUSTOM JAVA CLASSES --------
// --------

// SoundFileChooser.java and JSCSoundFileChooser.sc are contained in separate files!

//////// add the SoundFileChooser.jar to the classpath
g.addClasses( "file://<javaSourceCodePath>/SoundFileChooser.jar" );   // replace <javaSourceCodePath> here!

//////// Figure 10.21
(
~plug.remove;	// this implicitly calls ~fileChooser.destroy!
~soundChooser        = JSCSoundFileChooser( ~win, Rect( 370, 2, 386, 306 ));
~soundChooser.path   = "sounds/a11wlk01.wav".absolutePath;
~loadButton          = JSCButton( ~win, Rect( 370, 312, 60, 24 )).states_([[ "Load" ]]).enabled_( false );
~infoText            = JSCStaticText( ~win, Rect( 438, 312, 318, 24 ));
~soundChooser.action = { arg view; var enabled = false, info = "", sf;
    if( view.path.notNil and: { (sf = SoundFile.openRead( view.path )).notNil }, {
        sf.close;
        enabled         = sf.numChannels == 1;
        info            = "% audio, %-chan. % % kHz, %".format( sf.headerFormat, sf.numChannels, sf.sampleFormat, sf.sampleRate/1000, (sf.numFrames/sf.sampleRate).asTimeString );
    });
    ~loadButton.enabled = enabled;
    ~infoText.string    = info;
};
~loadButton.action   = { ~action.value( ~soundChooser.path )};
)

//////// Figure 10.22
(
~ampSlider.resize     = 2;
~mySlider.view.resize = 5;
~ampText.resize       = 3;
~speedText.resize     = 3;
~soundChooser.resize  = 6;
~loadButton.resize    = 9;
~infoText.resize      = 9;
~win.resizable        = true;
)


// --------
// -------- ALL IN ONE, LEADING TO THE FINAL EXAMPLE --------
// --------

(
s.waitForBoot({
    SynthDef( \bufPlay, { arg buf, amp = 1.0, speed = 1.0;
        Out.ar( 0, Pan2.ar( PlayBuf.ar( 1, buf, speed * BufRateScale.kr( buf ), loop: 1 ) * amp ));
    }).send( s );
    ~buf = Buffer.read( s, "sounds/a11wlk01.wav" );
});

g = SwingOSC.default;
g.waitForBoot({
    // replace <javaSourceCodePath> here!
    g.addClasses( "file://<javaSourceCodePath>/SoundFileChooser.jar" );
    
    ~amp   = 0.5;  // initial amplitude
    ~speed = 1.0;  // initial speed (1.0 is normal, 0.5 is half-speed, etc.)
    
    ~model        = Event.new;
    ~model.amp    = ~amp;
    ~model.speed  = ~speed;
    ~model.node   = ~node;
    ~model.buf    = ~buf;
    ~model.adjust = { arg mod, key, value, source;
        mod.put( key, value );
        mod.changed( key, value, source )};

    UpdateListener.newFor( ~model, { arg upd, mod, value;
        mod.node.set( \amp, value )}, \amp );
    UpdateListener.newFor( ~model, { arg upd, mod, value;
        mod.node.set( \speed, value )}, \speed );
    
    ~win = JSCWindow( "Panel", Rect.new( 128, 60, 760, 340 ));
    ~playButton = JSCButton( ~win, Rect( 4, 4, 40, 56 ))
        .states_([[ "Play", Color.white, Color.green( 0.4 )],
                  [ "Stop", Color.white, Color.red ]])
        .action_({ arg view;
            if( view.value == 1, {
                ~model.node = Synth( \bufPlay, [
                    \buf, ~model.buf, \amp, ~model.amp, \speed, ~model.speed ]);
            }, {
                ~model.node.free; ~model.node = nil;
            })
        });

    JSCStaticText( ~win, Rect( 56, 4, 50, 25 )).align_( \right ).string_( "Amp:" );
    ~ampSlider = JSCSlider( ~win, Rect( 110, 4, 200, 25 ))
        .value_( ~amp ) // initial slider position
        .action_({ arg view;
            ~model.adjust( \amp, view.value, view )});
    JSCStaticText( ~win, Rect( 56, 32, 50, 25 )).align_( \right ).string_( "Speed:" );
    ~speedSpec = ControlSpec( 1/8, 8, \exp );

    ~ampText = JSCStaticText( ~win, Rect( ~ampSlider.bounds.right + 2, 4, 50, 25 ));
    ~ampTextUpd = UpdateListener.newFor( ~model, { arg upd, mod, value;
        ~ampText.string = "% dB".format( value.ampdb.round( 0.1 ))}, \amp );
    ~speedText = JSCStaticText( ~win, Rect( ~ampSlider.bounds.right + 2, 32, 50, 25 ));
    ~speedTextUpd = UpdateListener.newFor( ~model, { arg upd, mod, value;
        ~speedText.string = "%\\%".format( (value * 100).round( 0.1 ))}, \speed );

    ~mySlider            = Event.new;
    ~mySlider.view       = JSCUserView( ~win, Rect( 110, 32, 200, 145 )).focusVisible_( false );
    ~mySlider.pos        = ~speedSpec.unmap( ~model.speed );
    ~mySlider.pressed    = false;
    ~mySlider.project    = false;
    ~mySlider.adjustPos  = { arg slid, pos;
        slid.pos         = pos;
        slid.view.action.value( slid );
        slid.view.refresh };
    ~mySlider.adjustCurve= { arg slid, curve;
        slid.curve       = curve;
        slid.lines       = curve.slide( 2, 1 ).clump( 2 );
        slid.lineLens    = slid.lines.collect({ arg pair; pair[ 0 ].dist( pair[ 1 ])}).normalizeSum; 
        slid.projections = nil;
        slid.view.refresh };

    ~mySlider.adjustCurve( Array.fill( 20, { arg i;
        Polar( (i + 1) / 40, i / 19 * 4pi ).asPoint + (0.5 @ 0.5) }));

    ~mySlider.view.drawFunc = { arg view;
        var b, scale, lnP1, lnP2, linePos, proj, inner, sum = 0;
        b     = view.bounds;
        scale = b.width @ b.height;
        JPen.moveTo( ~mySlider.curve[ 0 ] * scale );
        (1..(~mySlider.curve.size-1)).do({ arg i;
            JPen.lineTo( ~mySlider.curve[ i ] * scale );
        });
        JPen.width = 2;
        JPen.color = Color.black;
        JPen.stroke;
        block { arg break;
            ~mySlider.lineLens.do({ arg len, i;
                if( sum + len >= ~mySlider.pos, {
                    #lnP1, lnP2    = ~mySlider.lines[ i ];
                    linePos        = (~mySlider.pos - sum) / len;
                    proj           = lnP1 + ((lnP2 - lnP1) * linePos);
                    JPen.fillOval( Rect.aboutPoint( proj * scale, 8, 8 ));
                    JPen.fillColor = Color.hsv( 0.7, view.hasFocus.if( 0.7, 0.0 ), 1.0 );
                    inner          = if( ~mySlider.pressed, 5, 7 );
                    JPen.fillOval( Rect.aboutPoint( proj * scale, inner, inner ));
                    break.value;
                });
                sum = sum + len;
            });
        };

        if( ~mySlider.project, {
            ~mySlider.projections.do({ arg pt;
                pt = pt * scale;
                JPen.line( pt + (-5 @ -5), pt + (5 @  5) );
                JPen.line( pt + (-5 @  5), pt + (5 @ -5) );
            });
            JPen.width = 1; JPen.stroke;
        });
    };

    ~ampSliderUpd = UpdateListener.newFor( ~model, { arg upd, mod, value, source;
        if( source !== ~ampSlider, {
            ~ampSlider.value = value;
        })}, \amp );
    ~speedSliderUpd = UpdateListener.newFor( ~model, { arg upd, mod, value, source;
        if( source !== ~mySlider, {
            ~mySlider.adjustPos( ~speedSpec.unmap( value ));
        })}, \speed );

    ~ampSlider.onClose   = { ~ampSliderUpd.remove };
    ~mySlider.onClose    = { ~speedSliderUpd.remove };
    ~ampText.onClose     = { ~ampTextUpd.remove };
    ~speedText.onClose   = { ~speedTextUpd.remove };
    
    ~mouseFunc = { arg view, x, y, modifiers, buttonNumber, clickCount;
        var b, nx, ny, dx, dy, lnP1, lnP2, linePos, lineLenSq,
            proj, dist, sum = 0, minDist = inf, newValue;
    
        b  = view.bounds;
        nx = x / b.width;
        ny = y / b.height;
        ~mySlider.projections = Array( ~mySlider.lines.size );
        ~mySlider.lines.do({ arg pair, i;
            #lnP1, lnP2 = pair;
            dx          = lnP2.x - lnP1.x;
            dy          = lnP2.y - lnP1.y;
            lineLenSq   = (dx*dx) + (dy*dy);
            dist        = (((nx - lnP1.x) * dx) + ((ny - lnP1.y) * dy)) / lineLenSq;
            proj        = (lnP1.x + (dist * dx)) @ (lnP1.y + (dist * dy));
            if( lnP1.x != lnP2.x, {
                linePos = (proj.x - lnP1.x) / dx;
            }, {
                linePos = (proj.y - lnP1.y) / dy;
            });
            if( linePos < 0, {
                proj = lnP1;
            }, { if( linePos > 1, {
                proj = lnP2;
            })});
            ~mySlider.projections.add( proj );
            dist = proj.dist( nx @ ny );
            if( dist < minDist, {
                newValue = sum + (linePos.clip( 0, 1 ) * ~mySlider.lineLens[i]);
                minDist  = dist;
            });
            sum = sum + ~mySlider.lineLens[ i ];
        });
        ~mySlider.pressed = true;
        ~mySlider.adjustPos( newValue );
    };
    ~mySlider.view.mouseDownAction = ~mouseFunc;
    ~mySlider.view.mouseMoveAction = ~mouseFunc;
    ~mySlider.view.mouseUpAction   = { arg view; ~mySlider.pressed = false; view.refresh };
    ~mySlider.view.action          = { arg view;
        ~model.adjust( \speed, ~speedSpec.map( ~mySlider.pos ), ~mySlider )};

    ~mySlider.view.keyDownAction = { arg view, char, modifiers, unicode, keycode;
        switch( keycode, 37, {   // decrease slider-value with cursor-left
            ~mySlider.adjustPos( (~mySlider.pos - 0.05).max( 0.0 ))},
        39, {   // increase slider-value with cursor-right
            ~mySlider.adjustPos( (~mySlider.pos + 0.05).min( 1.0 ))})};

    ~action = { arg fileName; var sf, oldBuf;
        if( (sf = SoundFile.openRead( fileName )).notNil, {
            sf.close;  // the header info was read, we can close the file
            if( sf.numChannels == 1, {  // allow mono files only
                oldBuf = ~model.buf;
                if( ~model.node.notNil, {  // free old buffer when synth is freed
                    UpdateListener.newFor( ~model.node, { arg upd;
                        upd.remove; oldBuf.free }, \n_end );
                    ~model.node.register;
                }, {
                    oldBuf.free;
                });
                ~model.buf = Buffer.read( s, fileName );  // replace buffer
            }, {
                "Sound file must be mono".error;
            });
        });
    };

    ~soundChooser        = JSCSoundFileChooser( ~win, Rect( 370, 2, 386, 306 ));
    ~soundChooser.path   = "sounds/a11wlk01.wav".absolutePath;
    ~loadButton          = JSCButton( ~win, Rect( 370, 312, 60, 24 )).states_([[ "Load" ]]).enabled_( false );
    ~infoText            = JSCStaticText( ~win, Rect( 438, 312, 318, 24 ));
    ~soundChooser.action = { arg view; var enabled = false, info = "", sf;
        if( view.path.notNil and: { (sf = SoundFile.openRead( view.path )).notNil }, {
            sf.close;
            enabled         = sf.numChannels == 1;
            info            = "% audio, %-chan. % % kHz, %".format( sf.headerFormat, sf.numChannels, sf.sampleFormat, sf.sampleRate/1000, (sf.numFrames/sf.sampleRate).asTimeString );
        });
        ~loadButton.enabled = enabled;
        ~infoText.string    = info;
    };
    ~loadButton.action   = { ~action.value( ~soundChooser.path )};

    ~ampSlider.resize     = 2;
    ~mySlider.view.resize = 5;
    ~ampText.resize       = 3;
    ~speedText.resize     = 3;
    ~soundChooser.resize  = 6;
    ~loadButton.resize    = 9;
    ~infoText.resize      = 9;
    
    ~win.front;
})
)

// Tasks 
(
SynthDef("task", { arg out=0, freq=2000;
	var env = EnvGen.kr(Env.perc, 1.0, 0.2, doneAction:2);
	var source = DynKlank.ar(`[ [0.5, 0.8, 1, 1.2, 2, 4]*freq, nil, nil ], PinkNoise.ar(0.007));
	Out.ar(out, source * env ! 2);
}).store;

t = Task({
	var freq;
	loop {
		freq = ((1..10)*220).choose;
		Synth("task", [\freq, freq]);
		0.3.wait;
	}
})
)

t.start
t.stop;


// Patterns
(
SynthDef("pattern", { arg out=0, freq=220, pan=0, gate=1;
	var ctl = RLPF.ar(Saw.ar(5, 1.0, 2), 25, 0.03);
 	var source = SinOsc.ar(ctl * freq) * 0.1;
	var env = EnvGen.kr(Env.adsr, gate, doneAction: 2);
	Out.ar(out, Pan2.ar(source * env, pan));
}).store;

e = Pbind(
	\midinote, Pxrand(#[60, 61, 63, 65, 72], 20), 
	\dur, 0.4,
	\pan, Pwhite(-1.0, 1.0, 20),
	\instrument, \pattern
);
)

e.play;


// ProxySpace
p = p ?? ProxySpace.push(s);

~ctl = { SinOsc.kr(1) * 110 + 440 };
~out = { arg freq=220, amp=0.5; Ringz.ar(Dust.ar(2, 0.4), freq, 0.8) ! 2 };

~out.play;

~out.map(\freq, ~ctl);

~ctl = { SinOsc.kr(LFSaw.kr(5, add: 2.0) * 10) * 220 + 440 };

ProxyMixer.new;

~out.stop;
~out.clear;

// MIDI Example
(
SynthDef(\midi, { arg out=0, midinote=60, dur=0.1;
	var source = Blip.ar(midinote.midicps, 4, 0.2);
	var env = EnvGen.kr(Env.perc(0.1, dur), 1.0, doneAction: 2);
	Out.ar(out, (source * env) ! 2);

}).store;

c = NoteOnResponder( { |src, chan, num, vel|
	[num, vel].postln;
	Synth.new(\midi, [\midinote, num, \dur, vel/512]);
});
)
c.remove;

// NetAddr and OSCresponder example
n = NetAddr("localhost", 57120); 
r = OSCresponder(n, '/good/news', { arg time, resp, msg; [time, msg].postln }).add;

n.sendMsg("/good/news", "you", "not you");

r.remove;
n.disconnect;


// GUI Example
(
	SynthDef(\gui, { arg out=0, freq=8, decay=0.11;
		var in = Formlet.ar(Impulse.ar(freq, 0, 0.4), 800, 0.01, decay);
		Out.ar(out, in ! 2);
	}).memStore;
)
(
	a = Synth.newPaused(\gui);
	w = Window.new( "A GUI window", Rect( 128, 64, 340, 250 ));
	w.view.decorator = FlowLayout( w.view.bounds );

	b = Button.new( w, Rect( 50, 20, 75, 24 ));
	b.states = [[ "Start"],[ "Stop"]];
	b.action_({ arg butt;
		if (butt.value == 1, { a.run }, { a.run(false) });	
	});

	c = Slider2D.new( w, Rect(50, 120, 330, 200));
	c.x_(0.5).y_(0.5).action_({|sl|
			a.setn(\freq, [sl.x * 10 + 3, sl.y / 5 + 0.01]);
	});

	w.front;
)


// Plus-GUI methods
Server.inspect; 					// inspect a class

UGen.browse;						// ClassBrowser
SynthDescLib( \myLib ).read.browse;

s.makeWindow;						// a server control window

Env.perc.test.plot;					// plotting 
										
{SinOsc.ar(LFSaw.kr(1,0,220,440)) *0.1}.scope		// scope


// Open new code window - workaround
"This is a new code window".newTextWindow;   

// Figure 12.3
//
// select the following lines and type C-c C-x
// stop synthesis with C-c C-s

{
	var trem = LFTri.kr(3).range(-12.dbamp, 0.dbamp);
	SinOsc.ar(
		{ rrand(60, 80).midicps } ! 6,
		mul: -10.dbamp * trem
	).clump(2).sum
}.play


// Figure 12.4
//
// evaluate the following lines by double-clicking on the
// first paranthesis when `transient-mark-mode' is enabled
// and pressing C-c C-c

(
x = {
	Saw.ar(
		XLine.kr(20, [400,403,407], 20),
		mul: 0.7
	).clump(2).sum
}.play; "scel";
)

// evaluate this line by pressing C-c C-c
x.free; "rocks";


#!/usr/local/bin/sclang

// Figure 12.1

if (thisProcess.argv.isEmpty) {
	"Missing arguments!".postln;
	exit(1);
};

thisProcess.argv.do { | x, i |
	"% : %\n".postf(i, x);
};

exit(0);


/**** 
	Note: all these examples require tracking data to produce sounds.
	As the subtleties of the tracking data are very hard to simulate, 
	we decided not to provide a (misleading) simulation. To hear the 
	examples in action, please see and hear the videos on the book website.
****/

// example juggling 12 - Rotational Grain Train

(
~rotater = {|amp = 1|
	var rotVel = ~rotVel.kr;	// rotVel and height from tracking data proxies
	BPF.ar(
		Impulse.ar((rotVel > 0.5) * rotVel * 5).lag(0.0001),
		(~height.kr * 120 + 36 + [[0, 7], [0, 12], [0, 16]]).midicps, 
		0.2
	).collect({ |pair| (pair * [1, 0.125]).sum }) 	* 6 * amp
};
)



// example juggling 13 - Rotation Trigger
(
~planeTicker = {|saw2sin = 1, filterFreq = 2000, fSpread = 0.4, amp = 0.1|
	
	var freq = 3000 * fSpread * (~height.kr * 4 - 1).range(0.5, 2);
	
	var src = SelectX.ar(
		saw2sin, 
		[LFSaw.ar(freq) , SinOsc.ar(freq)]
	) 
	* Decay2.ar(
		Trig1.ar(~zeroCrossing.ar, 0.001) * 0.1, 
		0.001,
		0.3
	);
	
	LPF.ar(src, filterFreq, mul: amp * 0.1)
};
)



// example juggling 14 - Distances to the Head
(
~backCross = {|amp = 1|
	var 	numObj = 3;
	var 	in = ~isLeft.kr(numObj);
	var 	height = ~height.kr(numObj), 
		front = ~isFront.kr(numObj); 
	var aEnv, fEnv, aEnvNoise;

	var trig = Trig1.ar((in - Delay1.kr(in)).abs - 1, 0.00001) > 0.5;
	// only trigger if behind the body and near ground
	trig = trig * (front < 0) * (height < 0.26);
	aEnv = EnvGen.kr(Env.perc(0.05, 2), gate: trig);
	aEnvNoise = EnvGen.kr(Env.perc(0.01, 0.1), gate: trig);
	fEnv = EnvGen.kr(
		Env.perc(0.01, 0.1), gate: trig, 
		levelScale: 900, levelBias: 50
	);
	
	aEnv * ((0.2 * WhiteNoise.ar * aEnvNoise) + 
	SinOsc.ar(fEnv * (height * 8).squared * 0.4, 0, 1.5).softclip) * amp
};
)


// example juggling 15 -  Left-right Trigger
(
~distances = {|amp = 0.2795| 
	LFSaw.ar(min((~dist.kr * 2.5 * 90 + 20).midicps, 44100)) * amp
};
)


// example juggling 16 - Rain on Bells
(
~clackUp = { |amp = 0.1|
	Formlet.ar(
		~trigsUp.ar.lag(0.0004), 
		(~height.kr).exprange(25, 2500), 
		0.002,
		0.05
	)
	* (~height.kr * 4 ** 2) 
	* amp
};
)


/// figure sonif 19 - Sound design for a single country
(
~single = { |rootFreq = 220, outProp = 4.5, inProp = 2.2, attack=0.00, decay = 1.0, 
	dens = 2, amp=0.2, x=1, y = 0, step=0.33333| 
	
	var numChans = 4; 
	
	var freqs = rootFreq * [ 1/outProp, 1/inProp, 1, inProp, outProp]; 
	
	var exciter = (Dust2.ar(dens * [ 1,2,4,2,1] * 0.07) // five individual rd triggers for 
												// each component, weighted for center
			+ Dust2.ar(dens * 0.3))					// + some common attacks
				.clip2(0.5)	
				.lag(0.0003) 					// slightly filtered
				* (dens ** -0.5)				// amplitude comp for dust density
			+ PinkNoise.ar(0.002)				// some fused background noise
			* (decay ** -0.5);					// amplitude comp. for decay
				
	var resonator = Formlet.ar( exciter, freqs, 
		Ramp.kr(attack, step), decay, 
		AmpComp.kr(freqs.max(50))
	).softclip.sum; 
	
	var pos = atan2(Ramp.kr(y, step), Ramp.kr(x, step)) * (pi.reciprocal) + 1; // look west.
	
	PanAz.ar(numChans, LeakDC.ar(resonator, 0.95), pos, Ramp.kr(amp, step));
};

~single.play;
)



��
 
 
 
 	 / /   f i g u r e   1 3 . 1   -   L o a d i n g   t h e   d a t a 
 ( 
 q   =   q   ?   ( ) ; 
 q . e x e c d a t a   =   ( ) ; 
 q . e x e c d a t a . y e a r s   =   ( 1 9 7 7   . .   2 0 0 8 ) ;   
 	 / /   d a t a   i s :   [ t o t a l   f o r   e a c h   r e g i o n ,   1 9 7 7   . . .   2 0 0 7 ] ; 
 q . e x e c d a t a . r e g i o n s   =   ( 
 	 T o t a l :   [ 1 0 9 9 , 1 , 0 , 2 , 0 , 1 , 2 , 5 , 2 1 , 1 8 , 1 8 , 2 5 , 1 1 , 1 6 , 2 3 , 1 4 , 3 1 , 3 8 , 3 1 , 
 	 	 	 5 6 , 4 5 , 7 4 , 6 8 , 9 8 , 8 5 , 6 6 , 7 1 , 6 5 , 5 9 , 6 0 , 5 3 , 4 2 , 3 7 ] , 
 	 N o r t h e a s t :   [ 4 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 2 , 0 , 0 , 0 , 1 , 0 , 0 , 0 , 0 , 0 , 1 , 0 , 0 , 0 ] , 
 	 M i d w e s t :   [ 1 2 9 , 0 , 0 , 0 , 0 , 1 , 0 , 0 , 0 , 1 , 0 , 0 , 0 , 1 , 5 , 1 , 1 , 4 , 3 , 1 1 , 9 , 1 0 , 5 , 1 2 , 5 , 1 0 , 9 , 7 , 7 , 1 4 , 6 , 5 , 2 ] , 
 	 S o u t h :   [ 9 3 3 , 0 , 0 , 1 , 0 , 0 , 2 , 5 , 2 1 , 1 6 , 1 8 , 2 4 , 1 0 , 1 3 , 1 7 , 1 3 , 2 6 , 3 0 , 2 6 , 4 1 , 2 9 , 6 0 , 
 	 	 5 5 , 7 4 , 7 6 , 5 0 , 6 1 , 5 7 , 5 0 , 4 3 , 4 4 , 3 6 , 3 5 ] , 
 	 W e s t :   [ 6 7 , 1 , 0 , 1 , 0 , 0 , 0 , 0 , 0 , 1 , 0 , 1 , 1 , 2 , 1 , 0 , 4 , 4 , 2 , 2 , 7 , 4 , 8 , 1 1 , 4 , 4 , 1 , 0 , 2 , 2 , 3 , 1 , 0 ] , 
 	 T e x a s :   [ 4 2 3 , 0 , 0 , 0 , 0 , 0 , 1 , 0 , 3 , 6 , 1 0 , 6 , 3 , 4 , 4 , 5 , 1 2 , 1 7 , 1 4 , 1 9 , 3 , 3 7 , 2 0 , 3 5 , 4 0 , 1 7 , 3 3 , 2 4 , 2 3 , 1 9 , 2 4 , 2 6 , 1 8 ] 
 ) ; 
 q . g e t R e g   =   {   | q ,   r e g N a m e |   q . e x e c d a t a . r e g i o n s [ r e g N a m e ] . d r o p ( 1 )   } ; 
 ) 
 
 
 
 
 
 	 / /   f i g u r e   1 3 . 2   -   M a p p i n g   t h e   d a t a   t o   p i t c h   i n   d i s c r e t e   e v e n t s 
 ( 
 P b i n d e f ( \ e x e c ,   
 	 \ n o t e ,   P s e q ( q . g e t R e g ( \ M i d w e s t ) ) ,   
 	 \ o c t a v e ,   3 ,   
 	 \ d u r ,   5   /   q . e x e c d a t a . y e a r s . s i z e 
 ) . p l a y ; 
 ) 
 	 / /   t h e   d i f f e r e n t   r e g i o n s 
 P b i n d e f ( \ e x e c ,   \ n o t e ,   P s e q ( q . g e t R e g ( \ N o r t h e a s t ) ) ) ; 
 P b i n d e f ( \ e x e c ,   \ n o t e ,   P s e q ( q . g e t R e g ( \ W e s t ) ) ) ; 
 P b i n d e f ( \ e x e c ,   \ n o t e ,   P s e q ( q . g e t R e g ( \ S o u t h ) ) ) ; 
 
 
 
 
 
 	 / /   f i g u r e   1 3 . 3   -   C o n t i n u o u s   d a t a   s o n i f i c a t i o n 
   
 b   =   B u f f e r . s e n d C o l l e c t i o n ( s ,   q . g e t R e g ( \ N o r t h e a s t ) ,   1 ) ;   
 ( 
 N d e f ( \ e x e c ,   {   | d u r   =   5 ,   s c a l e = 5 0 ,   o f f s e t = 2 0 0 |   
 	 v a r   v a l s   =   P l a y B u f . a r ( 1 ,   b ,   d u r   /   S a m p l e R a t e . i r   ) ; 
 	 P a n 2 . a r ( 
 	 	 S i n O s c . a r ( v a l s     *   s c a l e   +   o f f s e t ) ,   0 ,   
 	 	 E n v G e n . k r ( E n v . l i n e n ( 0 . 0 1 ,   d u r ,   0 . 0 1 ,   0 . 2 ) ,   d o n e A c t i o n :   2 ) 
 	 ) ; 
 } ) . p l a y ; 
 ) 
 	 / /   l o a d   o t h e r   r e g i o n s   i n t o   b u f f e r 
 b . s e n d C o l l e c t i o n ( q . g e t R e g ( \ M i d w e s t ) ) ;       N d e f ( \ e x e c ) . s e n d ; 
 
 b . s e n d C o l l e c t i o n ( q . g e t R e g ( \ W e s t ) ) ;       N d e f ( \ e x e c ) . s e n d ; 
 
 b . s e n d C o l l e c t i o n ( q . g e t R e g ( \ S o u t h ) ) ;       N d e f ( \ e x e c ) . s e n d ; 
 
 
 
 
 
 
 	 / /   f i g u r e   1 3 . 4   -     S o u n d   d e s i g n   w i t h   n o i s e   p u l s e s   
 ( 
 S y n t h D e f (   " n o i s e p u l s e s " ,   {   a r g   o u t   =   0 ,   s u s t a i n = 1 . 0 ,   n u m P u l s e s   =   0 ,   p a n   =   0 . 0 ,   a m p   =   0 . 2 ;   
 	 O u t . a r ( o u t ,   
 	 	 P a n A z . a r ( 4 ,   
 	 	 	 P i n k N o i s e . a r   
 	 	 	 *   D e c a y 2 . a r ( I m p u l s e . a r ( n u m P u l s e s   /   s u s t a i n ,   0 ,   n u m P u l s e s . s i g n ) ,   0 . 0 0 1 ,   0 . 2 ) , 
 	 	 	 p a n ,   
 	 	 	 E n v G e n . k r (   E n v . l i n e n ( 0 . 0 ,   0 . 9 9 5 ,   0 . 0 ) ,   l e v e l S c a l e :   a m p ,   t i m e S c a l e :   s u s t a i n ,   d o n e A c t i o n :   2 ) 
 	 	 ) 
 	 ) ; 
 } ) . s t o r e ; 
 S y n t h D e f ( \ t i c k ,   {   | o u t ,   a m p = 0 . 2 ,   p a n |   
 	 O f f s e t O u t . a r ( o u t ,   P a n 2 . a r ( I m p u l s e . a r ( 0 )   *   L i n e . k r ( a m p ,   a m p ,   0 . 0 0 1 ,   d o n e A c t i o n :   2 ) ,   p a n ) )   
 } ) . s t o r e ; 
 ) 
 ( i n s t r u m e n t :   \ n o i s e p u l s e s ,   n u m P u l s e s :   1 0 ,   l e g a t o :   1 ,   d u r :   2 ) . p l a y ; 
 ( i n s t r u m e n t :   \ t i c k ) . p l a y ; 
 
 
 
 
 
 
 	 / /   f i g u r e   1 3 . 5   -   F o u r   r e g i o n s   i n   s e q u e n c e 
 ( 
 T d e f ( \ e x e c s ,   {   
 	 v a r   y e a r D u r   =   2 ; 	 / /   o n e   y e a r   i s   2   s e c o n d s 
 	 v a r   r e g i o n ,   n u m E x e c s ,   n u m y e a r s   =   q . e x e c d a t a . y e a r s . s i z e ;   
 	 [ \ N o r t h e a s t ,   \ M i d w e s t ,   \ W e s t ,   \ S o u t h ] . d o   {   | r e g N a m e ,   i |   
 
 	 	 r e g i o n   =   q . e x e c d a t a . r e g i o n s [ r e g N a m e ] . p o s t l n ;   
 	 	 q . e x e c d a t a . y e a r s . d o   {   | y e a r ,   i |   
 	 	 	 n u m E x e c s   =   r e g i o n [ i   +   1 ] ;   
 	 	 	 [ r e g N a m e ,   y e a r ,   n u m E x e c s ] . p o s t l n ; 
 	 	 	 ( i n s t r u m e n t :   \ t i c k ) . p l a y ; 
 	 	 	 i f   ( n u m E x e c s   >   0 )   { 
 	 	 	 	 ( i n s t r u m e n t :   \ n o i s e p u l s e s ,   l e g a t o :   1 ,   n u m P u l s e s :   n u m E x e c s ,   d u r :   y e a r D u r ) . p l a y ; 
 	 	 	 } ; 
 	 	 	 y e a r D u r . w a i t ; 
 	 	 } ; 
 	 	 y e a r D u r . w a i t ; 
 	 } ; 
 } ) . p l a y ; 
 ) 
 
 
 
 
 
 / /   f i g u r e   1 3 . 6   -   F o u r   r e g i o n s   i n   p a r a l l e l 
 ( 
 / /   f o u r   c h a n n e l s   p l a y i n g ,   o r d e r e d   b y   t o t a l   n u m b e r .   
 / /   O n   s t e r e o   s y s t e m s ,   o n l y   t h e   f i r s t   2   c h a n n e l s   p l a y . 
 T d e f ( \ e x e c s ,   {   
 	 v a r   y e a r D u r   =   2 ; 	 / /   o n e   y e a r   i s   2   s e c o n d s 
 	 q . e x e c d a t a . y e a r s . d o   {   | y e a r ,   i |   
 	 v a r   r e g i o n ,   n u m E x e c s ,   n u m y e a r s   =   q . e x e c d a t a . y e a r s . s i z e ;   
 	 	 / /   o r d e r e d   b y   t o t a l   n u m b e r ,   o n   s t e r e o ,   o n l y   f i r s t   2   p l a y . 
 	 [ \ S o u t h ,   \ M i d w e s t ,     \ W e s t ,   \ N o r t h e a s t   ] . d o   {   | r e g N a m e ,   j |   
 
 	 	 r e g i o n   =   q . e x e c d a t a . r e g i o n s [ r e g N a m e ] . p o s t l n ;   
 	 	 	 n u m E x e c s   =   r e g i o n [ i   +   1 ] ;   
 	 	 	 [ r e g N a m e ,   y e a r ,   n u m E x e c s ] . p o s t l n ; 
 	 	 	 ( i n s t r u m e n t :   \ t i c k ) . p l a y ; 
 	 	 	 i f   ( n u m E x e c s   >   0 )   { 
 	 	 	 	 ( i n s t r u m e n t :   \ n o i s e p u l s e s ,   
 	 	 	 	 	 l e g a t o :   1 , 
 	 	 	 	 	 d u r :   y e a r D u r ,   
 	 	 	 	 	 n u m P u l s e s :   n u m E x e c s ,   
 	 	 	 	 	 p a n :   j   *   0 . 5   -   0 . 2 5   	 / /   t o   4   c h a n n e l s 
 	 	 	 	 ) . p l a y ; 
 	 	 	 } ; 
 	 	 } ; 
 	 	 y e a r D u r . w a i t ; 
 	 } ; 
 } ) . p l a y ; 
 ) 
 
 	 / /   2   i n l i n e   c o d e   e x a m p l e s 
 {   S i n O s c . a r ( [ M o u s e X . k r ( 2 0 0 ,   3 0 0 0 ,   1 ) ,   M o u s e Y . k r ( 2 0 0 ,   3 0 0 0 ,   1 ) ] )   *   0 . 0 1   } . p l a y ; 
 
 {   H e n o n C . a r ( 2 0 0 0 ,   L F N o i s e 2 . k r ( [ 1 ,   1 ] ,   0 . 2 ,   1 . 4 ) ,   0 . 1 4 )   *   0 . 2   } . p l a y ( s ) ; 
 
 
 
 
 	 / /   f i g u r e   1 3 . 7   -   S o n i f i c a t i o n   o f   t a g   s y s t e m s 
 ( 
 / /   c o m p a r e   t w o   a x i o m s   o n   l e f t   a n d   r i g h t   c h a n n e l s 
 / /   �  =   4   ( s i z e   o f   a l p h a b e t ) 
 / /   v   ( d e l e t i o n   n u m b e r )   v a r i e s   [ 1 . . 6 ]   w i t h   h o r i z o n t a l   c u r s o r   p o s i t i o n 
 { 
 	 v a r   t a g ,   r u l e s ,   v a l ; 
 	 r u l e s   =   [ [ 0 ,   1 ,   1 ] ,   [ 1 ,   3 ,   2 ,   0 ] ,   [ 1 ,   2 ] ,   [ 3 ,   1 ,   1 ] ] ;   / /   s a m e   r u l e   f o r   b o t h 
 	 v   =   M o u s e X . k r ( 1 ,   6 ) ; 
 	 v a l   =   d u p   { 
 	 	 v a r   a x i o m   =   A r r a y . f i l l ( 1 4 ,   {   # [ 0 ,   1 ,   2 ,   3 ] . c h o o s e   } ) ;   a x i o m . j o i n . p o s t l n ; 
 	 	 D u t y . a r ( 1   /   S a m p l e R a t e . i r ,   0 ,     D t a g ( 7 e 5 ,   v ,   a x i o m ,   r u l e s ) ,   d o n e A c t i o n :   2 ) ; 
 	 }   *   0 . 1 
 } . p l a y ; 
 ) 
 

/*

Required Quarks: 

	MathLib - includes nSorted method

Recommended Quarks:
	SpeakersCorner - includes SpatioScope class for demonstrating spatialisation.


Quarks.install("MathLib");
Quarks.install("SpeakersCorner");

*** recompile if needed ****

1_Magellan_Final_Prep.scd
	Reads in all data for the magellan sonification, 
	opens other text docs.

2_PlaySingleCountries.scd
	play contries individually
3_Magellan_Reise.scd
	load timeline data (comments in German)
	
4_windDev.scd
	the motion noise, wind and storm sound

5_FinalPlayer.scd
	play the full piece (8 channels)
		
6_VariousTests.scd
	individual steps of the piece, for debugging
	
*/

(
q = q ? ();
q.dir = Document.current.path.dirname;
//	q.filename = q.dir ++ "/ICADConcertData_Extend2.txt";
	q.filename = q.dir ++ "/ICADConcertData_Magellan.txt"; // this data file for magellan

q.text = TabFileReader.read(q.filename, true, false);

		// read the definitive timeline:
(q.dir ++ "/3_Magellan_Reise.scd").loadPaths;

q.names1 = q.text[0];

q.chanNames = q.names1.collect(_.asSymbol);

// Document.new("chanNames:", q.chanNames.asCompileString); 
Document.open(q.dir ++ "/5_FinalPlayer.scd"); 
// Document.open(q.dir ++ "/4_windDev.scd"); 
Document.open(q.dir ++ "/2_PlaySingleCountries.scd"); 

q.dataChans = q.text
	.drop(1)		// drop first line, chanNames
	.flop;				// swap rows and columns

	// read using sonenvir class SEData: 

q.worlddata = SEData.fromNamesData(
	\world,
	q.chanNames, 
	q.dataChans
);

		// convert channels with names to symbols
[ 'Country', 'Capital', 'Region' ].do { |name, i| 
	var chandata = q.worlddata.atChan(name).data;
	chandata.do { |str, i| chandata.put(i, str.asSymbol) };
};

	// convert channels with numbers to floats for better math precision:
q.numberChannels = q.chanNames.reject(
	[ 'Country', 'Capital', 'Region', 'Latitude_deg', 'Longitude_deg' ].includes(_)
); 

q.numberChannels.do { |name, i| 
	var data = q.worlddata.atChan(name).data;
	data.do { |str, i| 
		var num = if (str.every({ |ch| ch.isDecDigit.not }), nil, str.asFloat);
		data.put(i, num);
	};
};

q.worlddata.analyse; 

//	two utilities for distance and angle on the sphere:

q.rad2Deg = 180/pi; q.deg2Rad = pi / 180; 
q.earthRadius = 6372.8; 

q.sphDist = { |q, lat1, long1, lat2, long2, format=\rad| 
	var res;
	lat1 = lat1 * q.deg2Rad; long1 = long1 * q.deg2Rad;
	lat2 = lat2 * q.deg2Rad; long2 = long2 * q.deg2Rad;

	res = 2 * asin( (
		sin(lat2 - lat1 * 0.5).squared 
		+ (cos(lat1) * cos(lat2) * sin((long2 - long1).abs * 0.5).squared)
		).sqrt
	); 
	if (format == \rad, res, { res * q.rad2Deg });
}; 

q.sphAngle = { |q, lat1, long1, lat2, long2, format=\rad| 
	// shorten angle by the ratio of higherLat / lowerLat to 
	
	var highLat, lowLat, shorten; 
	#highLat, lowLat = [lat1, lat2].sort { |a, b| a.abs > b.abs }; 
	shorten = (1-highLat.abs) / (1-lowLat.abs); 
	
	(long2 - long1 @ (lat2 - lat1 * shorten)).theta 
	* (if (format == \rad, 1, q.rad2Deg))
}; 

q.getTopN = {�|q, n = 40, curlat=0, curlong=0| 
	q.vectors.collect({ |vect| vect ++ q.sphDist(vect[1], vect[2], curlat, curlong) })
		.nSorted(n, {�|a, b| a.last < b.last  })
		.collect({ |iVect| 
			var i, vect; #i, vect = iVect; 
			vect.add(  q.sphAngle(vect[1], vect[2], curlong, curlong) );
		});
};

q.vectors = q.worlddata.vectorsCollect([\Country, \Latitude, \Longitude], { |vect, i| vect ++ i }); 

q.setWind = { |q, newCoord, event|
	var speed, angle, dirPoint;
	q.lastCoord = q.lastCoord ? newCoord; 
	q.lastAngle = q.lastAngle ? -0.75pi;	// southwest; 
	[q.lastCoord, q.lastAngle ];
	speed = q.sphDist(q.lastCoord[0], q.lastCoord[1], newCoord[0], newCoord[1]) 
		* 0.33 * q.earthRadius;		// stimmt das so? muss ein durch timestep!!!
		
	angle = if (speed > 0, { 
		q.sphAngle(q.lastCoord[0], q.lastCoord[1], newCoord[0], newCoord[1]);
	}, { q.lastAngle });
	dirPoint = Polar(1, angle).asPoint; 
	q.lastCoord = newCoord; 
	q.lastAngle = angle;
// 	[ \speed, speed, \dirPoint, dirPoint, \event, event].postln;

	event = event ? q.lastEvent ? \normal;
	
	event.switch(
		\storm, { 
			~wind.set(
				\x, dirPoint.x, \y, dirPoint.y,
				\freq, rrand(450, 600), 
				\dRate, rrand(12, 15), \drift, rrand(7, 10), \q, 2.5, 
				\focus, rrand(0.2, 0.4)
			) }, 
		\calm, { 
			~wind.set(
				\x, dirPoint.x, \y, dirPoint.y,
				\freq, rrand(50, 60), 
				\dRate, 1, \drift, 2, 
				\q, 1, 
				\focus, rrand(0.2, 0.5)
			) }, 
		\normal, {	
			\default.postln;
			~wind.set(
				\x, dirPoint.x, \y, dirPoint.y,
				\freq, speed * 3 + 70, 
				\dRate, 3, \drift, rrand(2.5, 4), 
				\q, speed * 0.05 + 1, 
				\focus, ((speed + 5) * 0.2)
			) }
	);
	q.lastEvent = event;
};
)
/*
	// some tests to see that the data loaded OK: 
q.worlddata.chanNames.postcs;
		// some name channels
q.worlddata.atChan('Country').postcs;
q.worlddata.atChan('Capital').postcs;
q.worlddata.atChan('Region').postcs;

		// some number channels
q.worlddata.atChan('Population').postcs;
q.worlddata.atChan('GDP_dollar').postcs;
q.worlddata.atChan('GDP_per_capita').postcs;
q.worlddata.atChan('Housing_total').postcs;

q.worlddata.atChan('Latitude').data.postcs.plot;
q.worlddata.atChan('Longitude').data.postcs.plot;
q.worlddata.atChan('Latitude').data;
q.worlddata.atChan('Longitude').data.do { |d, i| [i, d.round(0.1)].postln };


q.worlddata.channels.do { |chan| [chan.name, chan.min, chan.max, chan.avg, chan.numNil].postln };
*/

/* test for geometry

a = q.worlddata.atVector(5, [ 'Country', 'Latitude', 'Longitude' ]);
q.worlddata.atChan('Country').data.indexOf('Spain');

b = q.worlddata.atVector(158, [ 'Country', 'Latitude', 'Longitude' ]);

c = [ 'Victoria', b[1], b[2] ];

q.sphDist(a[1], a[2], b[1], b[2]) * q.earthRadius;

	// angles: 0 is west, 0.5pi is north, pi is east, -0.5pi is south:
q.sphAngle(50, 0, 50, 20);		// ca London -> Kiew
q.sphAngle(50, 0, 60, 0);		// ca London -> Hebrides
q.sphAngle(50, 0, 50, -120);	// ca London -> Vancouver
q.sphAngle(50, 0, 5, 0);		// ca London -> Accra

		// Antigua_and_Barbuda -> Spain
q.sphAngle(a[1], a[2], b[1], b[2], \deg); //  ca 45 deg NW, OK!

q.sphAngle(a[1], a[2], b[1], b[2]); 

*/

// ten closest countries to sevilla: 
/*
q.vectors = q.worlddata.vectorsCollect([\Country, \Latitude, \Longitude], { |vect, i| vect ++ i }); 

q.vectors;
q.currPos = [\victoria, 37.5, -6];


q.topN = q.getTopN(10, 37.5, -6); q.topN.round(0.01).printAll;

q.topN = q.getTopN(10, -37.5, 174); q.topN.round(0.01).printAll;

q.topN.do { |list| [ list[4] * q.earthRadius, list].round(0.01).postln; };

*/


/* 	Magellan Single Country Examples

Server.default = s = Server.internal.boot;
p = ProxySpace.push(s);

1. 	run ./1_MagellanFinalPrep.scd first to load data.
2.	run this entire file to try what single countries sound like
3.	run the piece from file 5_FinalPlayer.scd


//////// some countries to try line by line

	// little water: 
q.setPxFromData(\Afghanistan); 	// no gini
q.setPxFromData(\Laos); 		// gini known
	
	// low population density:
q.setPxFromData(\Mongolia); 	

	// high pop density
q.setPxFromData(\Hong_Kong); 	
q.setPxFromData(\China); 		


q.setPxFromData(\Denmark); 			// lowest gini
q.setPxFromData(\Switzerland); 		// slightly higher gini
q.setPxFromData(\United_States); 	// much higher gini

	// very poor, no gini
q.setPxFromData(\East_Timor); 	
q.setPxFromData(\Cape_Verde); 
	// very rich, no gini
q.setPxFromData(\Brunei); 

	// poor, known gini
q.setPxFromData(\Mozambique); 		// low gini
q.setPxFromData(\Lesotho); 			// VERY high gini
q.setPxFromData(\Sierra_Leone); 		// highest of all ginis



*/
(
	// adapt to number of speakers available!
q.numSpeakers = 8;		
 
~single = { |rootFreq = 220, outProp = 4.5, inProp = 2.2, 
	attack=0.0, decay = 1.0, dens = 2,
	 amp = 0.2, x = 0, y = 1, step=0.33333| 
	 
	var freqs, exciter, resonator, ampcomp, pos; 
	
	freqs = rootFreq * [ 1/outProp, 1/inProp, 1, inProp, outProp]; 
	
	exciter = (Dust2.ar(dens * [ 1,2,4,2,1] * 0.07) 	// five individual rd triggers for 
												// each component, weighted for center
			+ Dust2.ar(dens * 0.3))					// + some common attacks
				.clip2(0.5)	
				.lag(0.0003) 
				* (dens ** -0.5)				// amplitude compensation for density
			+ PinkNoise.ar(0.002)				// soft background noise 'halo' for fusion
			* (decay ** -0.5);					// amplitude compensation for decay time
				
	resonator = Formlet.ar( exciter, freqs, 
		Ramp.kr(attack, step), decay, 
		AmpComp.kr(freqs.max(50))
	).softclip.sum; 
	
		// convert x, y to angle for panaz, 
		// and rotate to look west.
	pos = atan2(Ramp.kr(y, step), Ramp.kr(x, step)) * (-pi.reciprocal) + 0.5; 

	PanAz.ar(q.numSpeakers, LeakDC.ar(resonator, 0.95), pos, Ramp.kr(amp, step));
};

q.setPxFromData = { |q, name, proxy| 
		var cntIndex = q.worlddata.atChan('Country').data.indexOf(name); 
		var dataVect = q.worlddata.atVector(cntIndex, 
			[\GDP_per_capita, \Density, \Drinking_total, \prop10, \prop20]);
		
		var gdp, dens, drink, prop10, prop20; 
		[name, cntIndex, dataVect].postln; 
		#gdp, dens, drink, prop10, prop20 = dataVect; 
		
		gdp = gdp.expexp(400, 58900, 200, 2200); 
		dens = dens.expexp(1.8, 16204.5, 1.8, 170); 
		drink = (drink ? 100).linlin(13, 100, 0.2, 1.5);  // 1.5 secs max
		proxy = proxy ?�~single; 
		proxy.set(			
			\rootFreq, gdp, 
			\outProp, (prop10 ? 1.2).sqrt, 	// unknown ginis form quartertone cluster
			\inProp, (prop20 ? 1.1).sqrt, 	 
			\decay, drink, 				
			\dens, dens 
		);
};

~single.playN(vol: 0.25);

q.makeButsWin = {
	var w, btns;
	w = Window( "Select a Country", Rect( 128, 400, 1020, 480 ));

	w.view.decorator = FlowLayout( w.view.bounds, 4@4, 1@1 );
	w.view.background = Color( 0.6, 0.8, 0.8 );

	btns = q.worlddata.atChan(\Country).data.collect({ arg name;
		// the same is true for all other widgets
		Button( w, Rect( 0, 0, 100, 24 ))
			.states_([[ name, Color.black, Color.rand(0.6, 1.0) ]])
			.action_({ q.setPxFromData(name); });
	});
	w.front;
};
q.makeButsWin;

Spec.add(\rootFreq, \freq);
Spec.add(\outProp, [1, 100, \exp, 0.01, 10]);
Spec.add(\inProp, [1, 100, \exp, 0.01, 10]);
Spec.add(\attack, [0.0001, 0.1, \exp, 0.0001, 0.01]);
Spec.add(\decay, [0.1, 100, \exp, 0.01, 1]);
Spec.add(\dens, [1, 1000, \exp, 0.01, 10]);
Spec.add(\x, \pan); Spec.add(\y, \pan);
Spec.add(\step, [0.001, 1, \exp, 0.001, 0.1]);

NodeProxyEditor(~single, 12);

	// a window to try changing the directions
q.dirwin = Window("Check Directions", Rect(350,0,240,240)).front;
StaticText(q.dirwin, Rect(70, 0, 100, 20)).string_("West").align_(\center);
StaticText(q.dirwin, Rect(70, 220, 100, 20)).string_("East").align_(\center);
StaticText(q.dirwin, Rect(0, 50, 20, 100)).string_("S\no\nu\nt\nh").align_(\center);
StaticText(q.dirwin, Rect(220, 50, 20, 100)).string_("N\no\nr\nt\nh").align_(\center);

Slider2D(q.dirwin, Rect(20,20,200,200))
	.x_(0.5).y_(1)
	.action = { |sl2d| ~single.set(\x, sl2d.x * 2 - 1, \y, sl2d.y * 2 - 1) };

	// show the speaker setup and sound levels in a SpatioScope if there
q.makeSpatio = { 
	var spatClass = 'SpatioScope'.asClass; 

if (spatClass.notNil) { 
	q.spatio = spatClass.rings([8], 0.8, -0.625pi, bounds: Rect(0, 0, 220, 220));
	q.spatio.parent.bounds_(q.spatio.parent.bounds.moveTo(600,0));
} { 
"	//The SpatioScope class (not installed) could be useful here.
	// To install it, do :
	Quarks.install(\"SpeakersCorner\");".postln;
}
};
q.makeSpatio;
)



// 	Transcription of Travel timeline: 

//	Timeline mostly from Stefan Zweig: Magellan, der Mann und seine Tat, 1937; 
//	SOME details from Antonio Pigafetta: Mit Magellan um die Erde, Edition Erdmann, 2001
//	(Dank an Peter Jakober!)

q.timeline = [
	[10,  8, 1519, 36.7, -6, nil, 'leave_sevilla'], 	
			//datum 10.8.1519; Breitengrad, L�ngengrad,(wikipedia) 
			// Richtungen: (0 westen, 1, norden, 2 osten 3 s�den), information
												
										//anzahl der matrosen, 
			// Schiffe: 	Trinidad, 		130 Tonnen, 66 Mann( + Magellan)
			//			San Antonio,		130 Tonnen, 60 Mann
			//			Concepcion,		90 Tonnen,  45 Mann
			//			Victoria,			90 Tonnen,  42 Mann
			//			Santiago,			60 Tonnen,  32 Mann
			// M�NNER: 234; 170 Spanier, 40 Portugiesen, 20 Italiener, afrikanische und asiatische Dolmetscher												
	
	[20,  8, 1519, 36.4, -6.4,  nil, 'reach_sanlucar'], // erfunden
	[20,  9, 1519, 36.4, -6.4,  nil, 'leave_sanlucar'], // open sea
			//Info: spanische Autorit�ten versuchen die Reise zu verhindern
	
	[26,  9, 1519,  28.5, -16,  nil, 'reach_teneriffa'],
			// 3 Tage in Teneriffa dann Monte Rosse
	
	[ 3, 10, 1519,  28.5, -16,  nil, 'leave_teneriffa'],
			// zu mitternacht wird in see gestochen
			// keine verluste gemeldet...


			// 14. oktober heftige st�rme, 14� n�rdlicher breite
			//stimmung der mannscht verschlechtert sich...wollen heimkehren
	[14, 10, 1519,  14, -23.5, 'storm'],
//	[15, 10, 1519,  14.4, -23.5, 'normal'],

	[16, 10, 1519,  14.9, -23.5,  \normal, 'reach_cape_verde'],
	[26, 10, 1519,  14.9, -23.5,  nil, 'leave_cape_verde'],
	
	[ 28, 11, 1519,  0, -30,  nil, 'cross equator'],		// long is estimate
			//Pigafetta schreibt dass der Equator erst im Dezember erreicht wurde...
			//erste meuterei der spanischen kapit�ne, welche er durch die gefangennahme seines ersten offiziers beendet 
			//(keine Berichte �ber tote gefunden...)
	
	[ 6, 12, 1519,  -8.4, -35,  nil, 'cape_san_augustin'], // near recife/olinda

	[13, 12, 1519, -23, -43.4, nil, 'reach_rio_de_janeiro'],
			//leiden unter hitze.
			//beschreibt die menschenfresser
			//nehmen anscheinend einen oder meherere Brasilianer an Board auf! (Kommen sp�ter im Text vor) (+ca 2Leute)
	
	
	[26, 12, 1519, -23, -43.4,  nil, 'leave_rio_de_janeiro'],
			//Pigafetta schreibt, dass sie erst am 27 dezember abreisen
			//wird noch nichts von Verlusten erw�hnt 

	
	[10,  1, 1520, -35, -55,  nil, 'reach_rio_de_la_plata'],
	[11,  1, 1520, -35, -55,  \storm, ''],
	[13,  1, 1520, -35, -55,  \normal, ''],
			//versuchten die meerenge zu finden, um, so Pigafetta, ins S�dmeer zu kommen, ohne Erfolg
	
	[ 2,  2, 1520, -35, -55,  nil, 'leave_rio_de_la_plata'],

	
	[31,  3, 1520, -49.3, -67.6, nil, 'reach_port_san_julian'],  
			// stay for winter
			// die Essensrationen werden gek�rzt
			//nehemen 2 Riesen auf (+2 Leute)
	
	[ 1,  4, 1520, -49.3, -67.6, nil, 'mutiny'],
			//kapit�n Cartagena, armada , mendoza , coca gevierteilt, mendoza will fl�chten und erschlagen dabei,  
			//MINUS 5 Leute
			//der portugiesische kapit�n wird begnadigt was wiederrum Hass hervorruft
			//der portugiesische Kapit�n und der Bischof versuchen magellan zu t�ten, scheitert, sie werden ausgesetzt
			//MINUS 2 Leute
	
	[ 7,  4, 1520, -49.3, -67.6, nil, 'verdict'],

	[10,  4, 1520, -49.3, -67.6,  \storm],		// these are invented, but typical
	[14,  4, 1520, -49.3, -67.6, \normal],		// invented

	[24,  4, 1520, -49.3, -67.6,  \storm],		// invented
	[26,  4, 1520, -49.3, -67.6,  \normal],		// invented


	[14,  5, 1520, -49.3, -67.6,  \storm],		// invented
	[21,  5, 1520, -49.3, -67.6,  \normal],		// invented
	
	[22,  5, 1520, -49.3, -67.6, nil, 'loss_of_ship_santiago'],
			//die Mannschaft �berlebt aber durch ein Wunder und wird fernversorgt

	[30,  5, 1520, -49.3, -67.6,  \storm],		// these are invented, but typical
	[5,  6, 1520, -49.3, -67.6, \normal],		// invented

	[8,  6, 1520, -49.3, -67.6,  \storm],		// invented
	[20,  6, 1520, -49.3, -67.6,  \normal],		// invented

	[20,  7, 1520, -49.3, -67.6,  \storm],		// invented
	[27,  7, 1520, -49.3, -67.6,  \normal],		// invented

	[10,  8, 1520, -49.3, -67.6,  \storm],		// invented
	[15,  8, 1520, -49.3, -67.6,  \normal],		// invented
	
	[24,  8, 1520, -49.3, -67.6, nil, 'leave_port_san_julian'],
	
	[14, 9, 1520, -50, -68.5, nil, 'reach_rio_santa_cruz'],
			// laut Pigafetta erreichen sie Santa Cruz schon am 14. September!
			// (bleiben dort 2 monate wegen Gefahr von Schiffbruch)
	
	[14, 10, 1520, -50, -68.5, nil, 'leave_rio_santa_cruz'],
			// laut Pigafetta erreichen sie Santa Cruz schon am 14. September!
			// (bleiben dort 2 monate wegen Gefahr von Schiffbruch)

	[21, 10, 1520, -52.7, -68.35, nil, 'reach_cape_of_virgins'], 
			//San Antonio und Concepcion werden vorausgeschickt
			// entry_of_passage
	[22, 10, 1520, -52.7, -68.35, 'storm'], 
			//San Antonio und Concepcion werden vorausgeschickt
			// entry_of_passage
	[24, 10, 1520, -52.7, -68.35, 'normal'], 
			//San Antonio und Concepcion werden vorausgeschickt
			// entry_of_passage
	
	[25, 10, 1520, -52.7, -68.35, nil, 'enter_passage'],   // 1. 11.!
			//laut Pigafetta fahren sie erst am 1.November in die Meeresenge rein.
			//Magellan nennt die Enge ja auch "Allerheiligenstra�e"
	
	[1, 11, 1520, -52.7, -69.5, nil, 'turn'],
	
	[3, 11, 1520, -53.15, -70.9, nil, 'turn'],			// punta arenas
	[5, 11, 1520, -54, -71.2, nil, 'turn'],			// monte victoria
	
	[ 8, 11, 1520, -52.5, -69.5, nil, 'desertion_ship_san_antonio'],
			//schreibt nichts ob die volle Besatzung des Schiffes nach hause f�hrt, ich nehme die volle besatzung an..
			//MINUS 59 Leute; der urspr�ngliche Kapit�n wurde ja schon vorher umgebracht 
	
	[28, 11, 1520, -52.8, -74.6, nil, 'enter_pacific_ocean'], // cabo deseado
			//Essensnot, man i�t verfaultes 
			//MINUS 4 Leute: Hungertod
			//Krankheit: Zahnfleischerkrankung, k�nnen nichts essen, daher:
			//MINUS 19 Leute (auch einer der Riesen ist dabei)
			//essen Ratten - gibt einen Streit: MINUS 2 M�nner 
				// (bei diesem Streit erschl�gt der eine den anderen, der T�ter wird erdrosselt)
	
	[24,  1, 1521, -18.2, -140.8, nil, 'pass_san_pablo'],	// now hao island
			//Magellan meint die Magnetnadel besitzt auf der s�dlichen halbkugel keine Kraft den Nordpol zu finden
	
	[ 4,  2, 1521, 0, -160, nil, 'pass_tiburon_islands'], // unauffindbar, interpoliert
			//erreichen Cipangus (Japan)
			//hoffen die Gew�rzinseln zu erreichen

	[ 16,  2, 1521, 13, -179.74, nil, 'cross_dateline'], // interpolated: cross dateline!
	[ 17,  2, 1521, 13, 178.56, nil, 'passed_dateline'], // interpolated: cross dateline!
	
	[ 6,  3, 1521, 13.4, 144.7, nil, 'reach_ladrones'],	   // now mariana islands, taking guam
			//es kommt zu Feindseligkeiten zwischen den Einheimischen und der Schiffsbesatzung
			//bei den Feindseligkeiten wird ein Matrose verletzt, Beinamputation, MINUS 1 Mann,  da er an den Folgen stirbt
	
	[16,  3, 1521, 10.8, 125.8, nil, 'reach_samar'],   // wikip says homonhon philippines ...
			//gutes Verh�ltnis zwischen der Crew und den Insulanern
			//Insulaner werden durch Kanonfeuer stark erschreckt!
			//Laut Wikipedia sind zu dieser Zeit noch 150 Mann am Leben (das stimmt eigentlich mit meiner Berechnung �berein!!!!)
	
	[28,  3, 1521, 10, 125, nil, 'reach_massawa'], 	//  stimmt!
			//K�nigsbesuch - man prahlt mit Waffen
			//Gutes Verh�ltnis - Tauschhandel
			//Ein bestrafter Matrose wird gegen einen Einheimischen Piloten ausgetauscht
			//Auch der K�nig von Massawa begleitet sie
	
	[ 7,  4, 1521, 10.3, 123.9, nil, 'reach_cebu'],
			//dicke Freundschaft mit dem  K�nig
			//christliche Missionierung - es werden 800 Einheimische getauft
			//MINUS 2 Mann, Tod wegen zuviel Essens, nach der Hungerzeit
			//die Freundschaft ist der Grund f�r den Angriff auf Mactan
	  
	[27,  4, 1521, 10.2, 124, nil, 'death_magellan_on_mactan'],
			//60 Mann der Besatzung greifen gemeinsam mit Magellan an und stehen einem Heer von 1500 gegen�ber
			//Bei dem Kampf sterben 8 Mann und Magellan (MINUS 9 Mann) 
	 
	[ 1,  5, 1521, 10.2, 124, nil, 'death_serrao_and_barbosa'],
     //Verrat durch den Dolmetscher und durch den mittlerweile getauften christlichen K�nig (K�nig von Cebu),
     //Bei diesem Verrat werden 24 Mann (darunter barobosa) erschlagen der Dollmetscher l�uft �ber, und Serranos wird ausgesetzt:
     //MINUS 26 Mann
     
          
	[ 4,  5, 1521, 10.2, 124, nil, 'burn_ship_concepcion'],  
			//schlechte Stimmung wegen des Tods Magellans und wegen der reduzierten Besatzung

//	[ 6,  5, 1521, lat, long, nil, 'deserted_san_antonio_reaches_sevilla'],  

			// erreichen zuerst auch im Juni Panilongon, wo Pigafetta den k�nig besucht, der ist wohlgesonnen
			// danach gehts nach Cagaian (lage laut pigafetta 7� 30') (gibt keine genauen Daten an...), 
			// und erst dann wird palaoan erreicht
	
	[10,  6, 1521, 9.8, 118.7, nil, 'reach palawan'],  // when? - auch pigafetta macht da keinen genaueren angaben
			//erz�hlt vom Hahnenkampf

	[21,  6, 1521, 9.8, 118.7, nil, 'leave_palawan'],  // 
	
	[7,  7, 1521, 4.9, 114.9, 'storm'],  // when? stay for 35 days
	[8,  7, 1521, 4.9, 114.9, 'normal', 'reach_brunei'],  // when? stay for 35 days
			//laut pigafetta wird borneo am 8 Juli erreicht, kommen in den schwersten Sturm
			//wieder Austausch von Geschenken
			//MINUS 2 Matrosen laufen zu den Mauren �ber
			//Verrat durch den K�nig, wollen die Besatzung angreifen, misslingt,
			//2 Matrosen und der Sohn des Steuermanns werden nicht mehr auf das Schiff zur�ckgelassen (MINUS 3 Mann)
			//Kontakt auch mit den Heiden
	
	[12,  8, 1521, 4.9, 114.9, nil, 'leave_brunei'],  // 
	
			// kommen auf der Insel Cimbombon an, auf der sie die Schiffe reparieren wollen
			//bleiben auf dieser Insel 42 tage, Der aufenhaltszeitraum d�rfte zwischen August und September sein.
			//Im September verlassen sie die Insel und bestimmen vorher noch neue Kapit�ne(Gonzalo Gomez und del Cano)
			//gleich danach "bringen sie eine Dschunke auf"
			//segeln zur�ck und suchen die Molukken auf
			//im Oktober segeln sie zur Stadt Maingdanao (Mindanao)
			//26 Oktober �berf�llt sie ein furchtbarer Sturm
			//erreichen Ende Oktober die Inselgruppe zwischen Celebes und den Philipinen

	[ 8, 11, 1521, 0.64, 127.3, nil, 'reach_tidore_moluccan_island'],  // victoria, trinidad, crew 115
			//der K�nig ist der Crew wohlgesonnen
			//bekommen Gew�rznelken (im Tausch)
	
	[18, 12, 1521, 0.64, 127.3, nil, 'trinidad_leaks'],
			//K�nig von Thadore versucht zu helfen, das Leck ist nicht auffindbar
			//die Mannschaft der Trinidad bleibt zur�ck: also ca: (MINUS ca. 54 Mann)
			//es gibt jetzt noch eine Mannschaft bestehend aus 47 Europ�ern und 13 Indern!!!
	 
	[21, 12, 1521, 0.64, 127.3, nil, 'victoria_leaves_tidore'],
			//bei 2� und 55 l�ngen kommen sie auf die Insel Sulach (irgendwann im Dezember)
			//auf Sulach wohnen menschenfresser
			//von dort gehts weiter nach Buru (ca. einen Tag von Sulach entfernt)
	
	[8, 1, 1522, -8.2, 125, nil, 'victoria_reaches_Mallue'],
			//freundlich gesonnen
			//gen�gend Essen
			
	[25,  1, 1522, -8.2, 125, nil, 'victoria_leaves_ombay'],
	
	
	[26, 1, 1522, -9, 125.2, nil, 'victoria_reaches_timor'],
			//zuerst keine Einigung mit dem Befehlshaber �ber den Tausch
			//nahmen den H�uptling eines Ortes gefangen und erpressen Nahrungsmittel
	
	[13,  2, 1522, -9, 125.2, nil, 'victoria_leaves_timor'],
			//9. M�rz �berf�llt sie ein Orkan
			//MINUS 4 Mann beim Orkan ertrunken
			//am 18.M�rz fahren sie bei Neu Masterdam vorbei (38� s�dlicher Breite)
			// schon wieder lebensmittelknappheit, wegen des Orkans,
			//laut Pigafetta erreichen sie das kap der guten Hoffnung bereits am 7.Mai
	 
	[16,  5, 1522, -34.7, 18.9, 'storm', ],
	[18,  5, 1522, -34.7, 18.9, 'normal' ],
	[19,  5, 1522, -34.7, 18.9, \normal, 'round_cape_of_good_hope' ],
			// am 16 Mai �berf�llt sie wieder ein Sturm
			//kommen deswegen langsamer voran
			//laut pigafetta umrunden sie das Cap erst sp�ter 
				// (am 19. Mai sind sie gerade dabei es zu umrunden...)
			//MINUS 21 Mann sterben wegen verhungerns
		
	[ 9,  7, 1522, 14.9, -23.5, nil, 'reach_cabo_verde'],
			//erkennen dass sie sich um einen tag verechnet haben (wegen der Weltumsegelung)
			//MINUS 13 Mann wurden zur�ckgehalten (noch 22 Mann �brig, davon die H�lfte krank)
	
	[ 12, 7, 1522, 14.9, -23.5, nil, 'leave_cabo_verde'],  // guess date
			//MINUS 4 Mann: verhungert
	
	[ 6,  9, 1522, 36.4, -6.4, nil, 'reach_san_lucar'],
			//18 Mann erreichen San Lucar
	
	[ 8,  9, 1522, 36.7, -6, nil, 'reach_sevilla']
];


// the traveling speed wind and storm sound for Navegar - sonification.

(
q.numSpeakers = q.numSpeakers ? 8; 
~wind.clear.ar(q.numSpeakers);

~wind = { |wfreq = 100, q = 1, dRate = 3, drift = 2, amp=0.1, x=0, y= -1, focus=10, step=0.333| 
	var n = 8, snd, pos, panamps; 
	x = Ramp.kr(x, step); y = Ramp.kr(y, step);
	
	pos = atan2(y, x) * (-1/pi) + 0.5; // look west;
	
	wfreq = wfreq.lag(0.3); 
	dRate = dRate.lag(0.3);
	q = q.lag(0.3);
	amp = amp.lag(0.3);
	focus = focus.clip(0.1, 10).lag(0.3);
	panamps = PanAz.kr(8, 1, pos, amp, (20 / focus).min(8)) ** focus; 
	panamps = panamps / (panamps.sum.max(1e-15));
	
	snd = LeakDC.ar(
		RLPF.ar({ BrownNoise.ar + WhiteNoise.ar(0.25) } ! n, 
			wfreq * LFDNoise3.kr(dRate ! n, drift).midiratio, 
			q.reciprocal * LFDNoise3.kr(dRate ! n, 0.2, 1)
		), 
		0.925
	) * panamps * amp; 
//	Splay.ar(snd, levelComp: false);
};

q.setWind = { |q, newCoord, event|
	var speed, angle, dirPoint;
	q.lastCoord = q.lastCoord ? newCoord; 
	q.lastAngle = q.lastAngle ? -0.75pi;	// southwest; 
	[q.lastCoord, q.lastAngle ];
	speed = q.sphDist(q.lastCoord[0], q.lastCoord[1], newCoord[0], newCoord[1]) 
		* 0.33 * q.earthRadius;
		
	angle = if (speed > 0, { 
		q.sphAngle(q.lastCoord[0], q.lastCoord[1], newCoord[0], newCoord[1]);
	}, { q.lastAngle });
	dirPoint = Polar(1, angle).asPoint; 
	q.lastCoord = newCoord; 
	q.lastAngle = angle;
 	[ \setWind, \speed, speed.round(0.001), \dirPoint, dirPoint.round(0.001), \event, event].postln;

	event = event ? q.lastEvent ? \normal;
	q.lastEvent = event;
		event.switch(
			\storm, { 
				~wind.set(
					\x, dirPoint.x, \y, dirPoint.y,
					\wfreq, rrand(200, 350), 
					\dRate, rrand(12, 15), \drift, rrand(7, 10), \q, 2.5, 
					\focus, rrand(0.2, 0.4)
				) }, 
			\calm, { 
				~wind.set(
					\x, dirPoint.x, \y, dirPoint.y,
					\wfreq, rrand(45, 55), 
					\dRate, 1, \drift, 2, 
					\q, 1, 
					\focus, rrand(0.2, 0.5)
				) }, 
			\normal, {	
				// \default.postln;
				~wind.set(
					\x, dirPoint.x, \y, dirPoint.y,
					\wfreq, speed * 1 + 50, 
					\dRate, 3, \drift, rrand(2.5, 4), 
					\q, speed * 0.02 + 1, 
					\focus, (speed * 0.3).sqrt
				) }
		);
};
)

/*	// tests
~wind.playN;
~wind.scope;
q.setWind([-6, 37], \storm);
q.setWind([-6, 36], \calm);
q.setWind([-6, 36], \normal);
q.setWind([-6.5, 37], \normal);
q.setWind([-6, 37], \normal);

NodeProxyEditor(~wind);
*/

/*** 
	This script prepares a proxy for every country, and a Tdef to play the piece.
	It takes a while to load, tells you when ready!

***/ 
(
q.numSpeakers = q.numSpeakers ? 8; 
s.recChannels_(q.numSpeakers);
	
	// settings for the concert version: 
Tdef(\navegar).set(
	\steptime, 1/3, 	// a day is scaled into 0.3333 seconds
	\numCountries, 15, // the 15 nearest countries are heard at any time
	\timelineOff, 0, 	// timeline starts from the first day
	\postEveryN, 10	// every tenth day gets posted.
);
	// testing values
Tdef(\navegar).set(
	\steptime, 1/3, 
	\numCountries, 1, // few countries
	\timelineOff, 4, 
	\postEveryN, 1	// post every day
); 

	// load the wind sound;
(q.dir ++ "/4_windDev.scd").loadPaths;

	// If you have the AmbIEM quark installed, you can render the speakers
	// as sources in a virtual room, to stereo headphones.
	
	// for 8 chans uncomment these:
//Kemar.path_("KemarHRTF/")		// for 8 chan
//	.initBuffers(
//		[25, 70, 115, 160, 200, 245, 290, 335].rotate(1), 
//		[0, 0, 0, 0,  0, 0, 0, 0]
//	);

	// for 12 chans uncomment these:
//Kemar.path_("KemarHRTF/")		// for 12 chans
//	.initBuffers(
//		[	 15,  45,  75, 105, 135, 165, 
//			195, 225, 255, 285, 315, 345 ].rotate(1), 
//		0 ! q.numSpeakers
//	);

	// set up a player nodeproxy for every country;  
	// these are all countries that are being 'touched' by the travel route when q.numCountries = 20.
q.usedNames = 
[ 'Algeria', 'Andorra', 'Angola', 'Antigua_and_Barbuda', 'Argentina', 'Australia', 'Bangladesh', 'Barbados', 'Belgium', 'Belize', 'Benin', 'Bhutan', 'Bolivia', 'Botswana', 'Brazil', 'Brunei', 'Burkina_Faso', 'Burma', 'Burundi', 'Cambodia', 'Cameroon', 'Cape_Verde', 'Central_African_Republic', 'Chad', 'Chile', 'China', 'Colombia', 'Comoros', 'Congo_Democratic_Republic', 'Congo_Republic', 'Costa_Rica', 'Cote_d_Ivoire', 'Cuba', 'Djibouti', 'Dominica', 'Dominican_Republic', 'East_Timor', 'Ecuador', 'El_Salvador', 'Equatorial_Guinea', 'Ethiopia', 'Fiji', 'France', 'Gabon', 'Gambia', 'Ghana', 'Grenada', 'Guatemala', 'Guinea', 'Guyana', 'Haiti', 'Honduras', 'Hong_Kong', 'India', 'Indonesia', 'Ireland', 'Italy', 'Jamaica', 'Japan', 'Kenya', 'Kiribati', 'Korea_North', 'Korea_South', 'Laos', 'Lesotho', 'Liberia', 'Libya', 'Liechtenstein', 'Luxembourg', 'Madagascar', 'Malawi', 'Malaysia', 'Maldives', 'Mali', 'Malta', 'Mauritania', 'Mauritius', 'Mayotte', 'Mexico', 'Monaco', 'Morocco', 'Mozambique', 'Namibia', 'Nepal', 'Netherlands', 'New_Zealand', 'Nicaragua', 'Niger', 'Nigeria', 'Oman', 'Palau', 'Panama', 'Papua_New_Guinea', 'Paraguay', 'Peru', 'Philippines', 'Portugal', 'Puerto_Rico', 'Reunion', 'Rwanda', 'Saint_Helena', 'Samoa', 'San_Marino', 'Senegal', 'Seychelles', 'Sierra_Leone', 'Singapore', 'Slovenia', 'Solomon_Islands', 'Somalia', 'South_Africa', 'Spain', 'Sri_Lanka', 'Suriname', 'Swaziland', 'Switzerland', 'Taiwan', 'Tanzania', 'Thailand', 'Togo', 'Tonga', 'Trinidad_and_Tobago', 'Tunisia', 'Tuvalu', 'Uganda', 'United_Arab_Emirates', 'United_Kingdom', 'Uruguay', 'Vanuatu', 'Venezuela', 'Vietnam', 'Yemen', 'Zambia', 'Zimbabwe' ];

p.clear;

~allChans.ar(q.numSpeakers);
~allChans.bus; 

q.synthfunc = { |rootFreq = 220, outProp = 4.5, inProp = 2.2, 
	attack=0.0, decay = 1.0, dens = 2,
	 amp = 0.2, x = 0, y = 1, step=0.33333| 
	 
	var freqs, exciter, resonator, ampcomp, pos; 
	
	freqs = rootFreq * [ 1/outProp, 1/inProp, 1, inProp, outProp]; 
	
	exciter = (Dust2.ar(dens * [ 1,2,4,2,1] * 0.07) 	// five individual rd triggers for 
												// each component, weighted for center
			+ Dust2.ar(dens * 0.3))					// + some common attacks
				.clip2(0.5)	
				.lag(0.0003) 
				* (dens ** -0.5)				// amplitude compensation for density
			+ PinkNoise.ar(0.002)				// soft background noise 'halo' for fusion
			* (decay ** -0.5);					// amplitude compensation for decay time
				
	resonator = Formlet.ar( exciter, freqs, 
		Ramp.kr(attack, step), decay, 
		AmpComp.kr(freqs.max(50))
	).softclip.sum; 
	
		// convert x, y to angle for panaz, 
		// and rotate to look west.
	pos = atan2(Ramp.kr(y, step), Ramp.kr(x, step)) * (-pi.reciprocal) + 0.5; 

	PanAz.ar(q.numSpeakers, LeakDC.ar(resonator, 0.95), pos, Ramp.kr(amp, step));
};

Spec.specs.put('rootFreq', [100, 2000, \exp].asSpec);
Spec.specs.put('dens', [1.8, 16000, \exp].asSpec);
Spec.specs.put('attack', [0.0003, 0.1, \exp].asSpec);
Spec.specs.put('decay', [0.2, 3, \exp].asSpec);
Spec.specs.put('inProp', [0, 8].asSpec);
Spec.specs.put('outProp', [0, 12].asSpec);
Spec.specs.put('pos', \pan.asSpec);

~wind.clear.ar(q.umSpeakers);

Spec.specs.put('wfreq', [40, 1000, \exp].asSpec);
Spec.specs.put('dRate', [0.1, 30, \exp].asSpec);
Spec.specs.put('drift', [0, 12].asSpec);
Spec.specs.put('q', [0.01, 100, \exp].asSpec);
Spec.specs.put('x', [-100, 100].asSpec);
Spec.specs.put('y', [-100, 100].asSpec);
Spec.specs.put('focus', [0.1, 10, \exp].asSpec);
Spec.specs.put('step', [0.03, 3, \exp].asSpec);

q.usedNames.do { |name| p[name] = nil; p[name].ar(q.numSpeakers); p[name].bus_(~allChans.bus); };


fork {
	var syndef; 
	
	q.usedNames.do { |name, i| 
		0.05.wait; 
		p[name].set(\amp, 0).pause; 
		if (i == 0, { 
			p[name].source_(q[\synthfunc]); 
			syndef = p[name].objects.first.synthDef; 
		}, { 
			p[name].source_(syndef)
		}); 
	};
	
	q.dataVectors = q.usedNames.collect({ |name| 
		var cntIndex = q.worlddata.atChan('Country').data.indexOf(name); 
		var dataVect = q.worlddata.atVector(cntIndex, [\GDP_per_capita, \Density]);
		[name, cntIndex, dataVect]; 
	});
	
		// get static values once from dataset!
	q.usedNames.do { |name| 
		var cntIndex = q.worlddata.atChan('Country').data.indexOf(name); 
		var dataVect = q.worlddata.atVector(cntIndex, 
			[\GDP_per_capita, \Density, \Drinking_total, \prop10, \prop20]);
		
		var gdp, dens, drink, prop10, prop20; 
		[name, cntIndex, dataVect].postln; 
		#gdp, dens, drink, prop10, prop20 = dataVect; 
		
		gdp = gdp.expexp(400, 58900, 200, 2200); 
		dens = dens.expexp(1.8, 16204.5, 1.8, 170); 
		drink = (drink ? 100).linlin(13, 100, 0.2, 1.5); // 1.5 secs max
		
		p[name].set(			
			\rootFreq, gdp, 
			\outProp, (prop10 ? 1.2).sqrt, 	// unknown ginis form quartertone cluster
			\inProp, (prop20 ? 1.1).sqrt, 	// this was wrong in the concert version, fixed for the book
			\decay, drink, 				// wrong in the concert version, fixed for the book
			\dens, dens, 
			
			\attack, 0.1, 	// all distant, off, and in the west
			\amp, 0.0, 
			\x, 1, \y, 0
		);
		0.02.wait;
	}; 
	"\n\nREADY!\n\n\n".postln;
};
);
/*	
	p[\Spain].resume;
	p[\Spain].pause;
*/

	// Final Player sequencer
(
q.allUsed = Set.new(180);

Tdef(\navegar, {�|e| 
	var daysToNext, newStreams = [], oldStreams = [], dyingStreams = []; 
	var finalN; 
	
	p.wakeUp; 
	0.5.wait;
	p.do(_.pause); 
	0.5.wait;
	~allChans.wakeUp; 
	~wind.set(\amp, 0.1).wakeUp.resume;
	
		// orig uses AdCVerb, available in Sonenvir svn
	~out = { var snd = ~allChans.ar(q.numSpeakers) + ~wind.ar(q.numSpeakers); 
		snd // + (AdCVerb.ar(snd, 2.1, 0.6, q.numSpeakers) * 0.01)
	}; 
//		// substitute FreeVerb if you like
//	~out = { var snd = ~allChans.ar(q.numSpeakers) + ~wind.ar(q.numSpeakers); 
//		snd + (FreeVerb.ar(snd, 1, 0.75, 0.8) * 0.01)
//	}; 

		// render to headphone stereo, with a slight bass boost
//	~out = { MidEQ.ar(Kemar.ar(~allChans.ar) + ~wind.ar(q.numSpeakers), 100, 2, 6) };

		// or mix down to plain stereo for testing
//	~out = { Splay.ar(~allChans.ar(q.numSpeakers)[0, 7, 1, 6, 2, 5, 3, 4]) }; 

	~out.wakeUp; 

	0.5.wait;
	~out.resume.play(fadeTime: 10);
	~wind.resume.play(fadeTime: 6);

	q.timeline.drop(e.timelineOff).doAdjacentPairs { |line, line2, i| 
		line.postln; 
		daysToNext = (((line2[2] * 365) + (line2[1] * 30) + line2[0]) 
			- ((line[2] * 365) + (line[1] * 30) + line[0])); 
			
		[ "TIMELINE:", line, line2, q.lastEvent ].postcs;
	//	("	" ++ daysToNext).postln;
		daysToNext.do { |i| 
		
			var posLat = blend(line[3], line2[3], i / daysToNext); 
			var posLong = blend(line[4], line2[4], i / daysToNext);
			
			var topN = q.getTopN(e.numCountries, posLat, posLong); 
			var cntNames = topN.collect(_.first); 
			var poster = i % e.postEveryN == 0;
			
			q.setWind([posLat, posLong], line[5]);
			
			newStreams = cntNames.difference(oldStreams);
	//		[ 'oldStreams', oldStreams ].postln; 
			if (newStreams.notEmpty) { [ 'newStreams', newStreams ].postln };
			
			dyingStreams = oldStreams.difference(cntNames);
			if (dyingStreams.notEmpty) { [ 'dyingStreams', dyingStreams ].postln };

			oldStreams = cntNames; 
			
					// turn off old proxies;
			dyingStreams.do { |name| 
				var px = p[name]; 
				px.set(\amp, 0);
				SystemClock.sched(e.steptime, { px.pause });
			}; 
					// turn on new ones
			newStreams.do { |name| 
				var px = p[name]; 
				px.resume;				
			}; 
			
			if (poster, { [ \SHIP, posLat, posLong, q.lastEvent].round(0.01).postln });

					// update the playing ones
			topN.do { |list|�
				var dist, angle, dirVect, x, y, amp, attack;
				
				dist = list[4] * q.earthRadius; 
				angle = q.sphAngle(posLat, posLong, list[1], list[2]);
				dirVect = Polar(1, angle).asPoint; 
				x = dirVect.x; y = dirVect.y; 	// send x, y as direction vector, 
				
				amp = (dist.max(100) ** -1) * 50;
				attack = dist.max(100).linexp(0, 2000, 0.001, 0.1); 
				
				if (poster, { 
					[ list, \dist, dist, \panAz, angle / pi, \x, x, \y, y, \atan, atan2(y, x), \amp, amp, \att, attack]
						.round(0.001).postln; 
				}); 
				
				p[list.first].set(
					\amp, amp,
					\attack, attack,
					\x, x, 
					\y, y
				);
			};
			// "".postln; 
			finalN = topN; 	// so I can end them;
			
			q.allUsed.addAll(newStreams); 
					
			e.steptime.wait;
		};
		"".postln;
	//	0.5.wait;
	};
	
	("" + q.allUsed.size + "countries touched.").postln;
	~out.end(20);
});
)
/*
~allChans.stop;
~allChans = nil;

~allChans.stop;
~allChans.vol_(0.1);


p[\Spain].resume;

~out = { ~allChans.ar };
~out.play;

// for use with HEADPHONES use these

~out = { Splay.ar(~allChans.ar) };

	// HRTF rendering if you have AmbIEM installed:
~out = { MidEQ.ar(Kemar.ar(~allChans.ar), 100, 2, 6) };
~out = { ~allChans.ar };

// ~out = { Splay.ar(~allChans.ar[0,7,1,6,2,5,3,4]) };


~out.wakeUp.resume.play;

~out.vol_(4);

NodeProxyEditor(~out);
*/

Tdef(\navegar).stop.play;
Tdef(\navegar).pause;
Tdef(\navegar).resume;


Tdef(\navegar).set(\steptime, 0.3, \nCount, 15, \timelineOff, 0, \postN, 10); 

~wind.resume.play;

~wind.set(\amp, 0.08);

NodeProxyEditor(~wind);

s.recChannels_(q.nChans).prepareForRecord("Navegar_8ch.aiff");
s.record;
Tdef(\navegar).stop.play;
Tdef(\navegar).stop;

p.envir.keysValuesDo { |k, px| if (px.paused.not) { k.postln } }; 

~allChans.stop;
~allChans.play(fadeTime: 2);
~allChans.vol_(0.2);


n = NodeProxyEditor(p[\Paraguay]);

n.proxy_(p[\Uruguay], \Uruguay);

p[\East_Timor].pause;
p[\Mauritius].pause;
p[\Madagascar].resume;
p[\Saint_Helena].resume;
p[\Mozambique].resume;

~all8.filter(5, { |in| Splay.ar(in.keep(8)) ++ Silent.ar(6) });

~all8.playN(
	outs: [ 0, [ 0, 1 ], [ 0, 1 ], 1 ],
	amps: [ 1, [ 0.8, 0.5 ], [ 0.5, 0.8 ], 1 ],
	vol: 1
);

~all8.playNDialog;
s.scope(8)

Document.open(q.dir ++ "/Magellan_Reise.rtf")

/*
simple textfile reader for reading in ICAD concert data files in SC3
*/
		// 
(
q = q ? ();
q.dir = Document.current.path.dirname;
q.filename = q.dir ++ "/WorldExtended2.txt";
q.text = TabFileReader.read(q.filename, true, false);
q.names1 = q.text[0];

q.chanNames = q.names1.collect(_.asSymbol);

Document.new("chanNames:", q.chanNames.asCompileString); 

q.dataChans = q.text
	.drop(1)		// drop first line, chanNames
	.drop(-1)		// drop last line, total population
	.flop;								// swap rows and columns

q.worlddata = (); 

q.chanNames.do { |name, i| 
	q.worlddata.put(name, q.dataChans.at(i));
};

		// convert channels with names to symbols
[ 'Country', 'Capital', 'Region' ].do { |name, i| 
	var chandata = q.worlddata.at(name);
	chandata.do { |str, i| chandata.put(i, str.asSymbol) };
};

	// convert channels with numbers to floats for better math precision:
q.numberChannels = q.chanNames.reject(
	[ 'Country', 'Capital', 'Region', 'Latitude_deg', 'Longitude_deg' ].includes(_)
); 

q.numberChannels.do { |name, i| 
	var chandata = q.worlddata.at(name);
	chandata.do { |str, i| 
		var num = if (str.every({ |ch| ch.isDecDigit.not }), nil, str.asFloat);
		chandata.put(i, num);
	};
};
)

/**** 
//	code that was used to convert latitude_deg and longitude_deg to float values:

		// latitude and longitude need special conversion to degrees:
[ 	'Latitude', 'Longitude' ].do { |name, i| 
	var data = q.worlddata.atChan(name).data;
	data.do { |str, i| 
		var sign, degrees, sep, minutes;
		#sign, degrees, sep, minutes = str.select(_.isPrint).split($ ).reject(_.isEmpty);
		
		sign = (N: 1, S: -1, E: 1, W: -1)[sign.asSymbol];
		degrees = degrees.asFloat + ((minutes ? 0).asFloat / 60) * sign;
		
		data.put(i, degrees);
	};
};
	// write it out so you can copy/paste it into Excel
q.worlddata.atChan('Latitude').size.do { |index| 
	var lat, long;
	#lat, long = q.worlddata.atVector(index, [ 'Latitude', 'Longitude' ]).round(0.0001);
	("" ++ lat ++ Char.tab ++ long).postln;
}; "";

****/


// Terra Nullius

// requires worlddata to be loaded - run 1_WorldReadSimple.scd first.

(
q.numberOfChannels  = 8; // number of speakers in the ring
q.numParams = 24 * 2;	// number of data dimensions


q.all = [];

// collect data and keys
// q.all is an array of arrays of values

q.worlddata.keysValuesDo { |key, x| 
	q.all = q.all.add(x);
	q.allKeys = q.allKeys.add(key);
};

// keep a copy
q.allOrig = q.all.copy;

// a function to order along a given dimension
// if no value exists, leave in place (in this piece this doesn't happen, because longitude is used)
q.makeOrder = { |q, i=0|
	var lastval = inf;
	q.currentOrder = q.all.at(i).collect({ |x| x !? {�lastval = x }; x ? lastval }).order;
	
	q.all = q.all.collect { |x| x[q.currentOrder] };
	q.allFlop = q.all.flop;
};

q.numberOfCountiesWithDist = {�|q, dist=5|
	q.allOrig.flop.count({ |x| x[q.allKeys.indexOf('Latitude')].absdif(50) < dist })
};

q.makeSelection = { |q, dist=5|
	var func =  { |country| country[q.allKeys.indexOf('Latitude')].absdif(50) < dist };
	
	q.allFlop = q.allOrig.flop;
	q.allFlop = q.allFlop.select(func);
	q.all = q.allFlop.flop;
	q.all = q.all.keep(q.numParams ? 24); // keep a number of data dimensions only
	q.makeOrder;

};

q.embedSlice = {|q, i=0, dt=1.0, bgamp=0.03, dtEnd|
	
	q.makeOrder(i);
	q.playCurrent(dt, bgamp, dtEnd).embedInStream;	

};

q.playCurrent = { |q, dt=0.05, bgamp=0, dtEnd|
	dtEnd = dtEnd ? dt;
	
	Routine {
		var n = q.allFlop.size;
		
		~out.set(\bgamp, bgamp); // set the background noise amp
		
		q.allFlop.do { |x, i|
			var t = (i+1).linexp(1, n+1, dt, dtEnd); // interpolate speed beteen rounds
			("  % ".format(t) ++ String.fill(x.size, {|i| if(x[i].isNil) { $* } { $ } })).postln;

			x = x.collect { |v| if(v.isNil) { 1 } {�0 } };
			
			~out.group.setn(\amp, x); // set the node proxy band amplitudes
			~out.group.set(\pan, (i / n * 2 - 1)); // set the node proxy pan pos
			
			t.wait;
		};	
	}
};
);


(
p = ProxySpace.push(s.boot);

(
~out = { |bgamp=0.2, pan=0, rq=0.1|
	var n = q.numParams;
	var amp = Control.names(\amp).kr(0.0 ! n); // amplitude controls
	var freqs = (0..n).linexp(0, n, 100, 12400);
	var u1, u2;
	
		thisThread.randSeed = 2006; // scramble the frequencies always the same way
		freqs = freqs.scramble;
	
	amp = amp.lag(0.02);
	
	// filtered noise bands with lagged filter coefficient
	u1 = {|i|
		var freq = freqs[i];
		BPF.ar(WhiteNoise.ar, freq, rq.lag(5)) * AmpComp.ir(freq, 100, 0.6) * amp[i].lag(0.02)
		* LFNoise1.kr(0.3, 0.2, 1)
	}.dup(n);
	
	u1 = u1.sum;
	
	// background noise
	u2 = HPF.ar(Crackle.ar({ 1.32 + 0.001.rand2 } ! n, bgamp.lag(10)), 500);
	
	// mix and pan
	PanAz.ar(q.numberOfChannels, u1, pan)
	+ 
	SplayZ.ar(q.numberOfChannels, u2)
}
);
)


(
Tdef(\x) {
	var steps, noise, count=0;
	
	// set level of background noise to 0, filter bandwidth to 0.5
	~out.set(\bgamp, 0.0, \rq, 0.5);

	// play the proxy to all output channels
	~out.play(0, q.numberOfChannels);
	
	3.wait; // pause before start
	
	steps = (1..11).linexp(1, 11, 3, 130).collect(_.asInteger);

	(steps.size - 2 * 2 + 1).do { |i|
			var dt, dt2, width, flopsize;
			
			// latitudinal width of selection
			width = steps.foldAt(i);
			width.postln;
			
			q.makeSelection(width);
			flopsize = q.allFlop.size;
			
			"q.allFlop.size: %\n".postf(flopsize);
			
			// calculate beginning and ending time steps of this round
			dt = flopsize.linexp(2.5, 100, 3, 0.01);
			dt2 = q.numberOfCountiesWithDist(steps.foldAt(i + 1)).linexp(2.5, 100, 3, 0.01);
			
			// set the filter bandwidth
			~out.set(\rq, i.linexp(1, steps.size * 2, 0.5, 0.01));
			
			// level of background noise
			noise = i.linexp(1, steps.size * 2, 0.002, 3.0);
			q.embedSlice(q.allKeys.indexOf('Longitude'), dt, noise, dt2);
			
	};
	
	~out.group.setn(\amp, 0.0 ! q.all.size); // set all to zero
	
	10.wait;
	
	~out.end(5);
	
	\ende.postln;
	
}.play;
);




/**
In this example the multichannel reverb changes according to where in the space a sound source is located.

*/

s.boot;

( // define the synthdefs:
SynthDef( \pulse, { |out=0,amp=0.3|
	Out.ar( out, amp*Decay.ar( Impulse.ar( 1 ), 0.25, LFCub.ar(1200,0,0.1) ) )
	}).send(s);

SynthDef( \reverb, { |in=0,out=0,mix=0.5,room=0.5,damp=0.5,amp=1|
	Out.ar( out, amp*FreeVerb.ar( In.ar( in, 1 ), mix, room, damp ) )
	}).send(s);
)

( // create infrastructure
b = Bus.audio( s, 1 );
)

( // create synths:
x = Synth.new( \pulse, [\out, b, \amp, 1] );
// create six reverbs, with slightly different settings:
y = 6.collect{ |it,i| Synth.new( \reverb, [\in, b, \out, it, \room, 0.2.rand + 0.4, \damp, 0.2.rand + 0.4], addAction: \addToTail ); };
)


(
// Assign positions to each speaker: (6 speaker setup in a rectangle)
~speakers = [ Point.new( 0, 0 ),  Point.new( 1, 0 ),  Point.new( 2, 0 ),  Point.new( 2, 1 ),  Point.new( 1, 1 ),  Point.new( 0, 1 ) ];

// Position for the source signal:
~src = Point.new( 0, 0 );

// distance spec:
~spec = [0,3].asSpec;

// function to update the location:
~updateLocation = { arg newpos;
	~src = newpos;
	y.do{ |it,i|
		// the mix gets more wet, the further the source is from the speaker:
		it.set( \mix,  ~spec.unmap( ~src.dist( ~speakers.at(i) ) ).postln );
	}
};
)

// corners:
~updateLocation.value( Point.new( 0,0 ) )
~updateLocation.value( Point.new( 1,0 ) )
~updateLocation.value( Point.new( 2,0 ) )
~updateLocation.value( Point.new( 0,1 ) )
~updateLocation.value( Point.new( 1,1 ) )
~updateLocation.value( Point.new( 2,1 ) )

// middle:
~updateLocation.value( Point.new( 0.5,0.5 ) )
~updateLocation.value( Point.new( 1,0.5 ) )
~updateLocation.value( Point.new( 1.5,0.5 ) )
~updateLocation.value( Point.new( 1.5,0 ) )


// clean up:
x.free; y.do{ |it| it.free; }


//////////////////////////////////////////////////////
Figure  17.1 

(
// read a whole sound into memory
s = Server.local;
b = Buffer.read(s,"sounds/a11wlk01.wav"); // remember to free the buffer later.
)
(
SynthDef("help_PlayBuf", { arg out=0,bufnum=0, rate=1;
Out.ar(out,
Pan2.ar(
PlayBuf.ar(1, bufnum, BufRateScale.kr(bufnum)*rate, loop: 1),
0)
)
}).send(s,[\out, 0, \bufnum, b.bufnum]);
)
p=Synth(\help_PlayBuf, [\rate, 0.midiratio]); // original pitch
p.set(\rate, 12.midiratio);	// one octave up
p.set(\rate, 7.midiratio);	// seven semitones up (fifth interval)

b.free;
b=nil;
p.free;
p=nil;
//////////////////////////////////////////////////////
 Figure  17.2 

(
Pbind(
\midinote, Pseq([0, 2, 3, 5, 7]+60, inf),
\dur, 0.3
).play
)
//////////////////////////////////////////////////////
 Figure  17.3 

(
Pbind(
\midinote, Pseq([0, 2, 3, 5.25, 7.5]+60, inf),
\dur, 0.3
).play
)
//////////////////////////////////////////////////////
 Figure  17.4 

(
Pbind(
\note, Pseq([0,2,4,5,7,9,11,12], inf),
\dur, 0.3,
\octave, 5
).play
)
//////////////////////////////////////////////////////
 Figure  17.5 

(
Pbind(
\degree, Pseq([0,1,2,3,4,5,6,7], inf),
\dur, 0.3,
\octave, 5
).play
)
//////////////////////////////////////////////////////
 Figure  17.6 

(
Pbind(
\degree, Pseq([0,1,2,3,4,5,6,7], inf),
\dur, 0.3,
\octave, 5,
\scale, (0..11)
).play
)
//////////////////////////////////////////////////////
 Figure  17.7 

(
Pbind(
\degree, Pseq([0, 2, 2.1, 2.05], inf),
\dur, 0.3,
\scale, (0..11),
\octave, 5
).play
)
//////////////////////////////////////////////////////
 Figure  17.8 

(
Pbind(
\note, Pwhite(-6,9),
\dur, 0.3,
\sustain, 1.1,
\stepsPerOctave, 7
).play
)
//////////////////////////////////////////////////////
 Figure  17.9 
(
e=Pbind(
\degree, Pwhite(-3, 7),
\dur, 0.25,
\stepsPerOctave, 21,
\sustain, 1.1,
\scale, [0, 4, 8, 11, 14, 17]
).play;
)
//////////////////////////////////////////////////////
 Figure  17.10 

(
// previous example should still be running
e.stream=Pbind(
\degree, Pwhite(-3, 7),
\dur, 0.25,
\stepsPerOctave, 21,
\sustain, 1.1,
\scale, [0, 3, 5, 8, 10, 13]
).asStream;
)
//////////////////////////////////////////////////////
 Figure  17.11 

(
var stepsperoctave=3;
Array.fill(stepsperoctave, {arg i; 2.pow(i/stepsperoctave)});
)

Using a function to calculate the value at a chosen degree
(
f = {|degree, steps|
2.pow(degree/steps)
};
)
// 	degree 0
f.(0, 3);
// 	degree 1
f.(1, 3);
// 	degree 2
f.(2, 3);

The function is modified to multiply the value by a root frequency in Hertz
(
f = {|degree, steps, root=440|
2.pow(degree/steps)*root
};
)
//	12 notes per octave, degrees 0,1 and 12
f.(0,12)
f.(1, 12)
f.(12, 12)

//	14 notes per octave, degrees 0,1, 12 and 14
f.(0,14)
f.(1, 14)
f.(12, 14)
f.(14,14)
//////////////////////////////////////////////////////

 Figure 17.12 

(
SynthDef("tone2", { arg freq = 440, amp=0.5, gate=1, envdur=1.5;
var sound, env;
env = EnvGen.kr(Env.perc(0.01, envdur), doneAction:2);
sound = Pan2.ar(SinOsc.ar(freq, 0, amp)*env, 0);
Out.ar(0, sound);
}).load(s);
)
(
a=[ 1, 1.030303030303, 1.0606060606061, 1.1212121212121, 1.3636363636364, 1.6060606060606, 2 ]*220;

// Play the all the notes of the tuning
e=Pbind(
\freq, Pseq( a, inf),
\dur, 0.2,
\amp, 0.5,
\sustain, 0.6,
\instrument, \tone2
).play
)
// Choose the notes randomly
(
e.stream=Pbind(
\freq, Pn(Prand( a, 1)),
\dur, 0.2,
\amp, 0.5,
\sustain, 0.6,
\instrument, \tone2
).asStream
)
//////////////////////////////////////////////////////
 Figure 17.13 

(
~rationames=[1/1, 8/7, 7/6, 6/5, 5/4, 4/3, 7/5, 10/7, 3/2, 8/5, 5/3, 12/7, 7/4];
~scale=[0,3,5,8,10,12];
e = Pbind(
\freq, Pseq([
Pfunc({
(~rationames.wrapAt(~scale).[~scale.size.rand])*440
})
],inf),
\dur, 0.25,
\amp, 0.5,
\instrument, \tone2
).play; // returns an EventStream
)
// set a new scale
~scale=[0,2,5,7,9,11];
~scale=[0,1,3,5,6,8,9];
~scale=[0,3,5,8,10,12];
//////////////////////////////////////////////////////
 Figure 17.14 

(
var n, buts, synths, ratios, rationames;
w = SCWindow("tonality diamond", Rect(200,500,420,150));
w.view.decorator = FlowLayout(w.view.bounds);

rationames=[
"7/4", "3/2","5/4","1/1",
"7/5","6/5","1/1","8/5",
"7/6","1/1","5/3","4/3",
"1/1","12/7","10/7","8/7"
];

n=rationames.size;

n.do({ |i|
SCButton(w, Rect(20,20+(i*30),100,30))
.states_([[rationames[i], Color.black, 
if((rationames[i])=="1/1", {Color.red},{Color.yellow})
]
])
.action_({ arg butt;
Synth(\tone2, [\freq, ((rationames[i]).interpret)*440]);

})
});
w.front;
)
//////////////////////////////////////////////////////
 Figure 17.16 

(
a=Pbind(
\degree, Pwhite(0, 12),
\dur, 0.5,
\octave, 5,
\amp, 0.4,
\stepsPerOctave, 12,
\instrument, \tone2
);
b=Pbind(
\degree, Pwhite(0, 14),
\dur, 0.25,
\octave, 4,
\amp, 0.4,
\stepsPerOctave, 14,
\instrument, \tone2
);
Ppar([a, b]).play;
)
//////////////////////////////////////////////////////
 Figure 17.17 

(
a=Pbind(
\degree, Pfunc({
[
[0, 6, 12].choose, 12.rand
].choose;
}),
\dur, 0.5,
\octave, 4,
\amp, 0.4,
\stepsPerOctave, 12,
\instrument, \tone2
);
b=Pbind(
\degree, Pfunc({
[
[0, 7, 14].choose, 14.rand
].choose;
}),
\dur, 0.25,
\octave, 5,
\amp, 0.3,
\stepsPerOctave, 14,
\instrument, \tone2
);
Ppar([a, b]).play;
)
//////////////////////////////////////////////////////
 Figure 17.18 

(
~tolerance={|a, b, t, max|
var c, d;
c=[];
d=[];
a.do({ |aitem, aindex|
b.do({ |bitem, bindex|
var x;
x = (aitem-bitem).abs;
if( (x > t) && (x < max),
{
c=c.add(aindex);
d=d.add(bindex);
//[aitem, bitem].post; " out of tune ".post; [aindex, bindex].postln;
//" ".postln;
})
})
});
[(0..a.size).difference(c), (0..b.size).difference(d)];
};
)

(
// use the function function with two tunings
var mintreshold, maxtreshold, int;

// two different equal tunings expressed linearly
a=Array.fill(12, { |i| (1/12)*(i) });
b=Array.fill(21, { |i| (1/21)*(i) });

int=1/21;				// smallest interval
mintreshold=int*0.15;
maxtreshold=int*0.85;
/*
intervals inferior to mintreshold are in tune
intervals between mintreshold and maxtreshold are out of tune
intervals superior to maxtreshold are in tune
*/

// print a list of notes from the two tunings which form a dissonant interval
~tolerance.value(a, b, mintreshold, maxtreshold);
)
//////////////////////////////////////////////////////
 Figure 17.19 

(
a=Pbind(
\degree, Pfunc({
// notes which clash with the other tuning have been removed
[0,4,8,12].choose
}),
\dur, 0.5,
\octave, 5,
\amp, 0.4,
\sustain, 0.85,
\stepsPerOctave, 12,
\instrument, \tone2
).play;
b=Pbind(
// notes which clash with the other tuning have been removed
\degree, Pfunc({
[0,7,14,21].choose
}),
\dur, 0.25,
\octave, 4,
\amp, 0.35,
\sustain, 0.85,
\stepsPerOctave, 21,
\instrument, \tone2
).play;
)

(
a.stream=Pbind(
// introducing more notes from that tuning after having changed the threshold
\degree, Pfunc({
[ 0, 1, 4, 7, 8, 9, 9, 12 ].choose
}),
\dur, 0.75,
\octave, 5,
\amp, 0.4,
\sustain, 0.85,
\stepsPerOctave, 12,
\instrument, \tone2
).asStream;
)
//////////////////////////////////////////////////////
 Figure 17.20 

(
f = {|steps| Array.fill(steps, { |i| 2.pow(i/steps) }) };
//	Calculation of the twelve equal-note temperament
x =  f.(12);
//	mapping the tuning to a new range beyond an octave
y = x.linlin(1, 2, 1, 2.25);
//	multiplying by a root frequency
a=y*440;

Pbind(
\freq, Pfunc({ a.choose }),
\dur, 0.25,
\octave, 5,
\amp, 0.5,
\sustain, 1.1,
\instrument, \tone2
).play
)
//////////////////////////////////////////////////////
 Figure 17.21 

(
Pbind(
\degree, Pwhite(0, 18),
\dur, 0.3,
\sustain, 1.0,
\amp, 0.5,
\sustain, 1.1,
\instrument, \tone2,
\stepsPerOctave,  18.809
).play;
)
//////////////////////////////////////////////////////



 Figure 17.22 

(
a=[ 1, 1.09375, 1.1875, 1.28125, 1.375, 1.46875, 1.5625, 1.65625];
b=a*440;
e=Pbind(
\freq, Pseq( b, inf),
\dur, 0.2,
\amp, 0.5,
\instrument, \tone2,
\sustain, 0.6
).play
)
// play in a different order
(
e.stream=Pbind(
\freq, Pn(Pshuf( b, 1)),
\dur, 0.2,
\amp, 0.5,
\instrument, \tone2,
\sustain, 0.6
).asStream
)
//////////////////////////////////////////////////////
 Figure 17.23 

(
// F. Mogini pattern-based Tuning - 2000.
x=880;

Pbind(
\freq, Pn(
Plazy({
if(x<=150, {x=x*2});
if(x>=2000, {x=x/2});
x=[

x*[1.1428,  1.36, 1.26].choose,
x/[1.1428,  1.36, 1.26].choose

].choose
})
),
\dur, 0.14,
\sustain, 0.8,
\cutoff, Pfunc({ 1.0.rand})
).play;
)
//////////////////////////////////////////////////////




 Figure 17.24 

a=(1..16)*100
(
e=Pbind(
\freq, Pseq( a, inf),
\dur, 0.2
).play
)

// a beautiful tuning system can be created from the harmonic series.
(
e.stream=Pbind(
\freq, Pn(Pshuf( a, 1)),
\dur, 0.2,
\sustain, 0.8
).asStream
)
//////////////////////////////////////////////////////
 Figure 17.25

a=(1..11);
(
a.size.do({ |i|
var x=a[i];
while({x>2},{x=x/2});
a.put(i, x)
});
)

b=a.asSet.asArray.sort;
(
e=Pbind(
\freq, Pn(Pshuf( b*440, 1)),
\dur, 0.2,
\sustain, 0.8
).play
)
//////////////////////////////////////////////////////
 Figure 17.26 

a=(1..8);
b=(9..16);
(
a.size.do({ |i|
var x=a[i];
var y=b[i];
// harmonics below 8 remain in the first octave
while({x>2},{x=x/2});
// harmonics above 9 remain in the second octave
while({y>4},{y=y/2});
a.put(i, x);
b.put(i, y);
});
)
a;
b;
c=(a++b).asSet.asArray.sort;
c;

(
e=Pbind(
\freq, Pn(Pshuf( c*200, 1)),
\dur, 0.2,
\sustain, 1.1
).play
)
//////////////////////////////////////////////////////
 Figure 17.27 

(
// 	a function to expand the tuning from one octave to four octaves
~harmsfunc={arg stepsperoctave=7;
var harms;
// calculate each note from the tuning
harms=Array.fill(stepsperoctave, {arg i; 2.pow(i/stepsperoctave)});
harms.size.do({ |i|
if( 0.6.coin, {
// multiply some of the notes to create higher harmonics
harms.put(i, (harms[i])*[1,2,4,8].choose )
})
});
harms.sort;
};
)

//  create an array of virtual harmonics, seven equal-note temperament
~harms=~harmsfunc.value(7);

(
// send a synth definition with some partials and the current value of ~harms

SynthDef(\cfstring1, { arg out=0, freq = 360, gate = 1, pan, amp=0.8;
var sound, eg, fc, osc, a, b, w;
var harms, amps;

// use the harmonics previously calculated
harms=~harms;
//	create new amplitudes for each harmonic
amps=Array.fill(harms.size,{1.0.rand}).normalizeSum*0.1;

osc = Array.fill(harms.size, { |i|
SinOsc.ar(freq * harms[i], 0, amps[i] );
})++[SinOsc.ar(freq , 0, amp*(0.5.rand+0.2) ), SinOsc.ar(freq*2 , 0, amp*(0.5.rand+0.15) )];

eg = EnvGen.kr(Env.asr(0.02,1,1), gate, doneAction:2);

sound = Pan2.ar(eg * Mix.ar(osc), pan);
Out.ar(0, sound);
}).store;
)

(
e=Pbind(
\instrument, \cfstring1,
// frequencies are rpeated so we can notice the effect of harmonics
\degree, Pseq([0,1,2,3,4,5,6,7],inf),
\dur, 0.25,
\stepsPerOctave, 7,
\octave, 4,
\pan, Pfunc({0.5.rand2 })
).play;
)

Send the SynthDef function again to obtain new amplitudes for each harmonic
(
// send a synth definition with some partials and the current value of ~harms

SynthDef(\cfstring1, { arg out=0, freq = 360, gate = 1, pan, amp=0.8;
var sound, eg, fc, osc, a, b, w;
var harms, amps;

// use the harmonics previously calculated
harms=~harms;
//	create new amplitudes for each harmonic
amps=Array.fill(harms.size,{1.0.rand}).normalizeSum*0.1;

osc = Array.fill(harms.size, { |i|
SinOsc.ar(freq * harms[i], 0, amps[i] );
})++[SinOsc.ar(freq , 0, amp*(0.5.rand+0.2) ), SinOsc.ar(freq*2 , 0, amp*(0.5.rand+0.15) )];

eg = EnvGen.kr(Env.asr(0.02,1,1), gate, doneAction:2);

sound = Pan2.ar(eg * Mix.ar(osc), pan);
Out.ar(0, sound);
}).store;
)

// re-evalute the function to create new harmonics (update the SynthDef afterwards)
~harms=~harmsfunc.value(7);
Send the SynthDef function again, as we have done earlier to obtain new amplitudes for each harmonic

// finally playing a random melody to make it less repetitive
(
e.stream=Pbind(
\instrument, \cfstring1,
// frequencies are repeated so we can notice the effect of harmonics
\degree,  Pwhite(0, 7),
\dur, 0.25,
\stepsPerOctave, 7,
\octave, 4,
\pan, Pfunc({0.5.rand2 })
).asStream;
)
// we could develop further and re-write the SynthDef with a partial argument 
// and also change the partials directly from Pbind

//////////////////////////////////////////////////////
 Figure 17.28 

(
var w, keys, steps, octaves;

w = SCWindow.new.name="Custom keyboard: 7 steps per octave";
steps = 7;
octaves= 2;
// seven steps per octave;
a=Array.fill(7, { |i| (1/7)*(i) })+1;
b= a++(a*2);

c=Synth(\default, [\amp, 0]);

keys=Array.fill(steps*octaves,{ |i|

SCButton(w, Rect(20+(i*22),20,20,50))
.states_([
if(i.mod(steps)==0,{
[i.asString, Color.black, Color.red]},{
[i.asString, Color.black, Color.yellow]});

])
.action_({ arg butt;
c.set(\freq,b[i]*220, \amp, 0.25)
});
});

w.front;
)
//////////////////////////////////////////////////////



/* Figure 18.1 */
/*
This example is adapted and extracted from the Non-Realtime Synthesis helpfile itself, accessible from the Main SuperCollider help page.
*/
(
var f, c, d;
// open a file for writing raw OSC data to
f = File("~/test.osc".standardizePath,"w");
// start a sine oscillator at 0.2 seconds.
c = [ 0.2, [\s_new, \default, 1001, 0, 0]];
// convert the bundle to raw OSC
d = c.asRawOSC;
f.write(d.size); // each bundle is preceded by a 32 bit size.
f.write(d); // write the bundle data.
f.close;
)
/* End Figure 18.1 */
/* Figure 18.2 */
s = Server.local;
s.boot;

// a sample SynthDef
SynthDef(\NRT_beep, {arg freq, dur, amp = 0.1;
	var half;
	half = dur * 0.5;
	Out.ar(0, SinOsc.ar(freq, 0, 
		EnvGen.kr(Env.new([0, amp, 0], [half, half], [4, -4]))));
	}).load(s);

(
var score;

// A Score, created from a note-list of time-stamped events.
score = Score.new([
    [0.0,
        [\g_new, 1000],
        [\s_new, \NRT_beep, 1001, 0, 1000, \freq, 75.midicps, \dur, 0.2]
    ], 
    [0.2,
        [\n_free, 1001],
        [\s_new, \NRT_beep, 1001, 0, 1000, \freq, 75.midicps, \dur, 0.2]
    ], 
    [0.4,
        [\n_free, 1001],
        [\s_new, \NRT_beep, 1001, 0, 1000, \freq, 75.midicps, \dur, 0.2]
    ], 
    [0.6,
        [\n_free, 1001],
        [\s_new, \NRT_beep, 1001, 0, 1000, \freq, 75.midicps, \dur, 0.2]
    ], 
    [0.8,
        [\n_free, 1001],
        [\s_new, \NRT_beep, 1001, 0, 1000, \freq, 71.midicps, \dur, 0.2]
    ], 
    [1.0,
        [\n_free, 1001],
        [\s_new, \NRT_beep, 1001, 0, 1000, \freq, 71.midicps, \dur, 0.2]
    ], 
    [1.2,
        [\n_free, 1001],
        [\s_new, \NRT_beep, 1001, 0, 1000, \freq, 82.midicps, \dur, 0.2]
    ], 
    [1.4,
        [\n_free, 1001],
        [\s_new, \NRT_beep, 1001, 0, 1000, \freq, 82.midicps, \dur, 0.2]
    ], 
    [1.6,
        [\n_free, 1001],
        [\s_new, \NRT_beep, 1001, 0, 1000, \freq, 82.midicps, \dur, 0.2]
    ], 
    [1.8,
        [\n_free, 1001],
        [\s_new, \NRT_beep, 1001, 0, 1000, \freq, 82.midicps, \dur, 0.2]
    ], 
    [2.0,
        [\n_free, 1001, 1000]
    ],
	[2.00001, [0]]
]);

score.play(s); // play the Score in real-time...

// ... or render in in Non-Real-Time
score.recordNRT("/tmp/trashme", "~/test.aiff".standardizePath, 
	options: ServerOptions.new.numOutputBusChannels_(1));
)
/* End Figure 18.2 */
/* Figure 18.3 */
(
//In this example, we use the higher-level server abstraction classes, Group and Synth to handle the
// node IDs. At least as important though is the use of variables. Now that the relationships are
// specified rather than the specific values, we can change the gesture dramatically by changing
// just one or two variables. To transpose everything, we only need to change the value of 
// ~baseNote. To adjust the duration, we only need to change the ~dur variable, and this is now 
// independent of the deltaOn (i.e. independent of the amount of time between the start of one
// note and the start of the next note).
var score;
var deltaOn = 0.2;  //amount of time between the start of one note and the start of the next note
var dur = 0.4;      //try changing dur to 0.3, 1.4, 3.4, or whatever you like
var baseNote = 75;  //transpose the entire fragment up or down
var firstPitch  = (baseNote + 0).midicps;  //alter the relationship between any of the pitches
var secondPitch = (baseNote - 4).midicps;  // without effecting the others
var thirdPitch  = (baseNote + 7).midicps;

score = Score.new([
	[t =  0.0,
		(g = Group.basicNew(s)).newMsg,
		//we use environment variables here (identified by the preceding ~) 
		// since we might add or remove events; hence we don't know ahead of 
		// time how many events we have, and therefore how many variables we'll need
		(~s01 = Synth.basicNew(\NRT_beep, s))
			.newMsg(g, [\freq, firstPitch, \dur, dur], \addToHead)
	], 
	[t + dur,
		~s01.freeMsg
	],
	[t = t + deltaOn,
		(~s02 = Synth.basicNew(\NRT_beep, s))
			.newMsg(g, [\freq, firstPitch, \dur, dur], \addToHead)
	], 
	[t + dur,
		~s02.freeMsg
	],
	[t = t + deltaOn,
		(~s03 = Synth.basicNew(\NRT_beep, s))
			.newMsg(g, [\freq, firstPitch, \dur, dur], \addToHead)
	],
	[t + dur,
		~s03.freeMsg
	],
	[t = t + deltaOn,
		(~s04 = Synth.basicNew(\NRT_beep, s))
			.newMsg(g, [\freq, firstPitch, \dur, dur], \addToHead)
	], 
	[t + dur,
		~s04.freeMsg
	],
	[t = t + deltaOn,
		(~s05 = Synth.basicNew(\NRT_beep, s))
			.newMsg(g, [\freq, secondPitch, \dur, dur], \addToHead)
	], 
	[t + dur,
		~s05.freeMsg
	],
	[t = t + deltaOn,
		(~s06 = Synth.basicNew(\NRT_beep, s))
			.newMsg(g, [\freq, secondPitch, \dur, dur], \addToHead)
	], 
	[t + dur,
		~s06.freeMsg
	],
	[t = t + deltaOn,
		(~s07 = Synth.basicNew(\NRT_beep, s))
			.newMsg(g, [\freq, thirdPitch, \dur, dur], \addToHead)
	], 
	[t + dur,
		~s07.freeMsg
	],
	[t = t + deltaOn,
		(~s08 = Synth.basicNew(\NRT_beep, s))
			.newMsg(g, [\freq, thirdPitch, \dur, dur], \addToHead)
	], 
	[t + dur,
		~s08.freeMsg
	],
	[t = t + deltaOn,
		(~s09 = Synth.basicNew(\NRT_beep, s))
			.newMsg(g, [\freq, thirdPitch, \dur, dur], \addToHead)
	], 
	[t + dur,
		~s09.freeMsg
	],
	[t = t + deltaOn,
		(~s10 = Synth.basicNew(\NRT_beep, s))
			.newMsg(g, [\freq, thirdPitch, \dur, dur], \addToHead)
	], 
	[t + dur,
		~s10.freeMsg,
		g.freeMsg
	],
]
);

score.sort;
score.play(s);
)
/* End Figure 18.3 */
/* Figure 18.4 */
(
var score, graingest;

// seed the randomness
thisThread.randSeed_(123);

// a sample SynthDef
SynthDef(\NRT_grain, {arg freq, dur, amp, pan;
	OffsetOut.ar(0, Pan2.ar(
		SinOsc.ar(freq, 0, 
			EnvGen.ar(Env.sine(dur, amp), doneAction: 2)),
		pan)
		);
	}).load(s);

score = Score.new;

// envelope times are scaled to 1.
graingest = {arg score, starttime, duration, windur, overlaps, freqenv, ampenv, panenv;
	var ratio, curfreq, curamp, curpan, notestart, now = 0.0, note;
	while({
		ratio = now / duration;
		curfreq = freqenv[ratio];
		curamp = ampenv[ratio];
		curpan = panenv[ratio];
		notestart = now + starttime;
		note = Synth.basicNew(\NRT_grain);
		score.add([notestart, 
			note.newMsg(1, [\freq, curfreq,\amp, curamp, \dur, windur, \pan, curpan], \addToHead)]
			);
		// check the current event's endtime against the gloabl endtime
		now = now + (windur / overlaps);
		now < duration;
		});
	};

// call the above function to populate the Score

graingest.value(score, 1.0, 10.0, 100.reciprocal, 1, Env([440, 550], [1]), 
	Env([0, 0.2, 0], [0.3, 0.7], [4, -4]), Env([0, 0], [1]));
graingest.value(score, 3.0, 3.0, 130.reciprocal, 2, Env([700, 400], [1]),
	Env([0, 0.2, 0], [0.1, 0.9], [4, -1]), Env([-0.7, 0.7], [1]));

// create a number of short gestures
10.do({arg i;
	graingest.value(score, 5.0.rrand(10.0), 3.0.rrand(5.0), (100 * i).reciprocal, [1, 2, 4].choose,
		Env([1000, 800], [1]), Env([0, 0.2, 0], [0.5, 0.5]), Env([0.5.rand2, 0.5.rand2], [1]));
	});

// save the endtime to the Score to tell NRT when to stop rendering. The above gestures won't
// be more the 16 seconds

score.add([16, [0]]);

// sort the score to ensure events are in the correct order

score.sort;

// render the Score to the users home folder

score.recordNRT("/tmp/trashme", "~/test.aiff".standardizePath, 
	options: ServerOptions.new.numOutputBusChannels_(1));
	
// also save the Score to a file
score.saveToFile("~/test.sc".standardizePath);
)	
/* End Figure 18.4 */	
/* Figure 18.5 */
(
var score, sndbuf, starttime, synth, options;

SynthDef(\NRT_playback, {arg buffer, dur, startPos, amp;
	OffsetOut.ar(0, PlayBuf.ar(1, buffer, BufRateScale.kr(buffer), 
			startPos: startPos * BufSampleRate.kr(buffer)) *
		EnvGen.ar(
			Env.sine(dur, amp),
			doneAction: 2))
	}).load(s);

score = Score.new;

// create a Buffer object for adding to the Score
sndbuf = Buffer.new;

// for NRT rendering, the buffer messages must be added to the Score
score.add([0, sndbuf.allocReadMsg("sounds/a11wlk01-44_1.aiff")]);

starttime = 0.0;

// a small function to create a series of small notes based on the Buffer
while({
	synth = Synth.basicNew(\NRT_playback);
	score.add([starttime, 
		synth.newMsg(s, [\buffer, sndbuf, \dur, 0.1, \startPos, 0.0.rrand(1.0), \amp, 0.1])]);
	starttime = starttime + 0.05;
	starttime < 10.0;
	});

// the dummy command. The soundfile will be 11 seconds long
score.add([11, 0]);

score.sort;

// the ServerOptions for rendering the soundfile
options = ServerOptions.new.numOutputBusChannels_(1);

// write the soundfile out to disk
score.recordNRT("/tmp/trashme", "~/test.aiff".standardizePath, options: options);
)
/* End Figure 18.5 */
/* Figure 18.6 */
(
var score, sndbuf, starttime, synth, options, cond;

SynthDef(\NRT_playback, {arg buffer, dur, startPos, amp;
	OffsetOut.ar(0, PlayBuf.ar(1, buffer, BufRateScale.kr(buffer), 
			startPos: startPos * BufSampleRate.kr(buffer)) *
		EnvGen.ar(
			Env.sine(dur, amp),
			doneAction: 2))
	}).load(s);

score = Score.new;

// set up a Condition to check for when asynchronous events are finished.

cond = Condition.new;

// wrap the code that will run in real-time in a Routine, to allow for the Server to sync
Routine.run({
	// load the buffer
	sndbuf = Buffer.read(s, "sounds/a11wlk01-44_1.aiff");
	
	// pause while the buffer is loaded
	s.sync(cond);
	
	// fill the Score with notes
	
	starttime = 0.0;
	
	while({
		synth = Synth.basicNew(\NRT_playback);
		score.add([starttime, 
			synth.newMsg(s, [\buffer, sndbuf, \dur, 0.1, \startPos, 0.0.rrand(1.0), \amp, 0.1])]);
		starttime = starttime + 0.05;
		starttime < 10.0;
		});
	
	// the last command is NOT needed, since no soundfile is being rendered
//	score.add([11, 0]);
	
	score.sort;
	
	// again, options won't be needed for real time performance
//	options = ServerOptions.new.numOutputBusChannels_(1);
	
	score.play;
	// schedule the freeing of the buffer after the Score is done playing
	SystemClock.sched(11, {sndbuf.free; "Buffer resources freed".postln;});
	})
)
/* End Figure 18.6 */
/* Figure 18.7 */


// environment variables are used for real-time examples of Ctk objects

n = CtkNoteObject(
	SynthDef(\NRT_grain, {arg gate = 1, freq, amp;
		var src, env;
		src = SinOsc.ar(freq, 0, amp);
		env = EnvGen.kr(Env([0, 1, 0], [1, 1], \sin, 1), gate, doneAction:2);
		OffsetOut.ar(0, src * env);
		})
	);
	
// create a new note based on 'n', start to play it in 0.1 seconds
a = n.new(0.1).freq_(440).amp_(0.1).gate_(1).play;
// the release method will set 'gate' to 0.0, and free this node
a.release;

// create another note
a = n.new(0.1).freq_(440).amp_(0.1).play;
// alter the freq argument in real time
a.freq_(550);
// alter the freq with a CtkControl that describes an Env
// CtkControl.env(Env)
a.freq_(CtkControl.env(Env([550, 440, 550], [1, 2], \exp)));
// apply a random control to the amp parameter, with an envelope applied to the range. All 
// parameters to the CtkControl can themselves be CtkControls
// CtkControl.lfo(KRUGen, freq, low, high, phase)
a.amp_(CtkControl.lfo(LFNoise2, 0.5, CtkControl.env(Env([0.1, 0.9], [5])), 0.1));
a.amp_(0.1);

// release the note
a.release;

/* End Figure 18.7 */
/* Figure 18.8 */
// melodic expander
(
var note, keys, durs, now, score, chunk, expander, rangemap;

// 
thisThread.randSeed_(123);

// a simple note player

note = CtkSynthDef(\NRT_dut, {arg key, amp, dur;
		Out.ar(0, SinOsc.ar(key.midicps, 0, XLine.kr(amp, 0.00001, dur)))
		});

// first, make a melody - these will be used as midikeynums (easier to alter later)

keys = [ 72, 72, 79, 79, 81, 81, 79, 77, 77, 76, 76, 74, 74, 72 ];

// a list of durations

durs = [0.25, 0.25, 0.25, 0.25, 0.25, 0.25, 0.5, 0.25, 0.25, 0.25, 0.25, 0.25, 0.25, 0.5];

// create a var to store 'now' in

now = 0.0;

// create a CtkScore with the above melody

score = CtkScore.new;

keys.do({arg thiskey, inc;
	var thisdur;
	thisdur = durs[inc];
	score.add(note.new(now, thisdur).key_(thiskey).amp_(0.2).dur_(thisdur));
	now = now + thisdur;
	});

// first, create a function that will return a chunk of the melody the duration of the chunk
// sets the starttimes of the notes to a base of 0.0

chunk = {arg offset = 0;
	var size, start, end, duration = 0, chunk, copies;
	// the size of the current melody - 1 (for array access)
	size = score.notes.size;
	// the beginning of the chunk can come from the beginning of the melody to the second to 
	// last note
	start = 0.rrand(size-1);
	end = start.rrand(size);
	chunk = score.notes[start..end].collect({arg anote; 
		var newnote;
		newnote = anote.copy(duration + offset);
		duration = duration + anote.duration;
		newnote;
		});
	[chunk, duration];
	};

// now, create a function that will add those chunks to the score, and will keep doing this
// until the score is at least the desired length. Then check the score size, and truncate to 
// desired size.

expander = {arg len;
	var curchunk, chunkdur, insert, inserttime, insertdur, cursize, newnotes;	cursize = score.notes.size;
	while({
		cursize < len
		}, {		
		insert = 0.rrand(cursize - 1);
		inserttime = score.notes[insert].starttime;
		insertdur = score.notes[insert].duration;
		#curchunk, chunkdur = chunk.value(inserttime + insertdur);
		score.notes[(insert+1)..(cursize-1)].do({arg me; 
			me.setStarttime(me.starttime + chunkdur)});
		score = score.add(curchunk);
		(score.notes.size > len).if({
			score.notes.do({arg me, i;
				(i > (len - 1)).if({score.notes.remove(me)});
				})
			});
		cursize = score.notes.size;
		});
	};

// rangemap will place the melodic material within a certain range. The user passes 
// in an envelope that will describe the center pitch in an octave range

rangemap = {arg center;
	score.notes.do({arg me;
		me.key_(me.key.mapIntoRange(12, center[me.starttime]));
		})
	};
		
// expand it to 100 notes
expander.value(100);

// describe a new range of pitches
rangemap.value(Env([60, 96], [20]));

// finally, play the CtkScore

score.play;
)
/* End Figure 18.8 */
/* Figure 18.9 */

(
var score, grain, now, thisdur;
var ampmap, double;

grain = CtkNoteObject(
	SynthDef(\NRT_grain, {arg freq, amp, dur, pan = 0;
		var src, env;
		env = EnvGen.ar(
			Env([0, 1, 0], [0.5, 0.5], \sin),
			timeScale: dur, levelScale: amp);
		src = SinOsc.ar(freq, 0, env);
		OffsetOut.ar(0, Pan2.ar(src, pan));
		})
	);
	
score = CtkScore.new;

now = 0;

// create a 3 second granular gesture

while({
	thisdur = 0.05.rrand(0.1);
	score.add(
		grain.new(now, thisdur).freq_(440.rrand(880)).amp_(0.05).dur_(thisdur).pan_(0));
	now = now + 0.01;
	now < 3;
	});

// a function to later map the amplitude to a given shape
// envtimes should be scaled to 1
ampmap = {arg aScore, env;
	// caled the envs times by the CtkScore's duration
	env.times = env.times * aScore.endtime;
	aScore.notes.do({arg thisNote;
		var curtime;
		curtime = thisNote.starttime;
		thisNote.amp_(env[curtime]);
		});
	};

// returns a new copy of the CtkScore with notes
// double an octave higher
double = {arg aScore, shift = 2;
	var thisScore;
	thisScore = aScore.copy;
	thisScore.notes.do({arg thisNote;
		thisNote.freq_(thisNote.freq * shift)
		});
	thisScore;
	};
		
// a Routine to play the examples
Routine.run({
	var scoreDouble;
	// play the CtkScore;
	score.play;
	score.endtime.wait;
	// remap the amplitudes
	ampmap.value(score, Env([0, 0.2, 0], [0.1, 0.9], [4, -2]));
	1.wait; // pause for a moment
	// play it again!
	score.play;
	score.endtime.wait;
	// add the CtkScore that octaveDouble returns
	scoreDouble = double.value(score, 19.midiratio);
	ampmap.value(scoreDouble, Env([0, 0.25, 0], [0.6, 0.4], [4, -2]));
	score.add(scoreDouble);
	1.wait;
	score.play;
	score.endtime.wait;
	// don't like the second version? remove double
	score.ctkscores.remove(scoreDouble);
	ampmap.value(score, Env([0.15, 0.05], [1]));
	1.wait;
	score.play;
	}).randSeed_(123)
)


/* End Figure 18.9 */
/* Figure 18.10 */
s = Server.local;
s.boot;

~sinosc = CtkSynthDef.new(\NRT_sinosc, 
	{arg outbus = 0, freq = 622.254, phase = 0, amp = 1, offSet = 0;
		Out.ar(outbus, SinOsc.ar(freq, phase, amp, offSet));
	}
);

(
var score;
var baseNote = 75;
var slopeTime = 0.25;
var curve = \sine;
var firstPitch = (baseNote + 0).midicps;
var firstStart = 0.0;
var firstDur = 5.0;
var firstAttackTime = slopeTime * 0.5;
var firstDecayTime  = slopeTime - firstAttackTime;
var firstVibDepth = 0.21;
var firstVibRate = 2.3;
var firstPeakAmp = 0.25;
var firstDecayAmp = 0.01;
var secondPitch = (baseNote - 4).midicps;
var secondStart = 2.2;
var secondDur = 4.0;
var secondAttackTime = slopeTime * 0.5;
var secondDecayTime  = slopeTime - secondAttackTime;
var secondVibDepth = 0.15;
var secondVibRate = 1.7;
var secondPeakAmp = 0.25;
var secondDecayAmp = 0.01;
var thirdPitch = (baseNote + 7).midicps;
var thirdStart = 3.1;
var thirdDur = 3.75;
var thirdAttackTime = slopeTime * 0.5;
var thirdDecayTime  = slopeTime - thirdAttackTime;
var thirdVibDepth = 0.21;
var thirdVibRate = 4;
var thirdPeakAmp = 0.2;
var thirdDecayAmp = 0.25;

score = CtkScore.new(
	~firstGroup = CtkGroup.new(firstStart, firstDur, server: s),
	~sinosc.new(firstStart, firstDur, \tail, ~firstGroup, server: s)
		.freq_(CtkControl.lfo(SinOsc, firstVibRate, 
			(firstPitch - ((firstPitch / (firstPitch.log2)) * (firstVibDepth * (1/3)))), 
			(firstPitch + ((firstPitch / (firstPitch.log2)) * (firstVibDepth * (2/3)))), 
			duration: firstDur, addAction: \head, target: ~firstGroup, server: s))
		.amp_(CtkControl.env(
			Env.new([0, firstPeakAmp, firstDecayAmp, 0], [firstAttackTime, 
				firstDur - (firstAttackTime + firstDecayTime), firstDecayTime], curve), 
			addAction: \head, target: ~firstGroup, server: s)),
	~secondGroup = CtkGroup.new(secondStart, secondDur, server: s),
	~sinosc.new(secondStart, secondDur, \tail, ~secondGroup, server: s)
		.freq_(CtkControl.lfo(SinOsc, secondVibRate, 
			(secondPitch - ((secondPitch / (secondPitch.log2)) * (secondVibDepth * (1/3)))), 
			(secondPitch + ((secondPitch / (secondPitch.log2)) * (secondVibDepth * (2/3)))), 
			duration: secondDur, addAction: \head, target: ~secondGroup, server: s))
		.amp_(CtkControl.env(
			Env.new([0, secondPeakAmp, secondDecayAmp, 0], [secondAttackTime, 
				secondDur - (secondAttackTime + secondDecayTime), secondDecayTime], curve), 
			addAction: \head, target: ~secondGroup, server: s)),
	~thirdGroup = CtkGroup.new(thirdStart, thirdDur, server: s),
	~sinosc.new(thirdStart, thirdDur, \tail, ~thirdGroup, server: s)
		.freq_(CtkControl.lfo(SinOsc, thirdVibRate, 
			(thirdPitch - ((thirdPitch / (thirdPitch.log2)) * (thirdVibDepth * (1/3)))), 
			(thirdPitch + ((thirdPitch / (thirdPitch.log2)) * (thirdVibDepth * (2/3)))), 
			duration: thirdDur, addAction: \head, target: ~thirdGroup, server: s))
		.amp_(CtkControl.env(
			Env.new([0, thirdPeakAmp, thirdDecayAmp, 0], [thirdAttackTime, 
				thirdDur - (thirdAttackTime + thirdDecayTime), thirdDecayTime], curve), 
			addAction: \head, target: ~thirdGroup, server: s))
);

score.play;
)
/* End Figure 18.10 */
/* Figure 18.11 */
VSO_Vib {

	var <pitch, <depth, <rate, <control;

	*new {arg start = 0.0, dur = nil, freq = 1, vibDepth = 0.21, vibRate = 1, 
		addAction = 0, target = 1, server;
		^super.new.initVSO_Vib(start, dur, freq, vibDepth, vibRate, addAction, 
			target, server);
	}
	
	initVSO_Vib {arg start, dur, freq, vibDepth, vibRate, add = 0, tgt = 1, server;
		server = server ?? {Server.default};
		pitch = freq;
		depth = vibDepth;
		rate = vibRate;
		control = CtkControl.lfo(SinOsc, rate, this.getLowerValue,
			this.getUpperValue, 0, start, dur, add, tgt, server: server);
	
	}
	
	getLowerValue {
		^(pitch - ((pitch / (pitch.log2)) * (depth * (1/3))));
	}

	getUpperValue {
		^(pitch + ((pitch / (pitch.log2)) * (depth * (2/3))));
	}
}
/* End Figure 18.11 */
/* Figure 18.12 */
VSO_ADR {

	var <control, <attackDur, <releaseDur, <totalDur;

	*new {arg start = 0.0, dur =  nil, peak = 0.707, decay = 0.01, attackDur = 0.125, 
		releaseDur = 0.125, addAction = 0, target = 1, server;
		^super.new.initVSO_ADR(start, dur, peak, decay, attackDur, releaseDur, addAction,
			target, server);
	}
	
	initVSO_ADR {arg start = 0.0, dur =  nil, peak = 0.707, decay = 0.01, aDur = 0.125, 
		rDur = 0.125, addAction = 0, target = 1, server;
		server = server ?? {Server.default};
		attackDur = aDur;
		releaseDur = rDur;
		totalDur = dur;
		control = CtkControl.env(Env.new([0, peak, decay, 0], 
			[attackDur, this.decayDur, releaseDur], \sine), 
			start, addAction, target, server: server, doneAction: 0);
	}
	
	decayDur {
		^(totalDur - (attackDur + releaseDur));
	}

}
/* End Figure 18.12 */
/* Figure 18.13 */
	initVSO {arg start = 0.0, dur = nil, freq = 622.254, ampPeakLevel = 0.707, 
		ampDecayLevel = 0.01, vibDepth = 0.21, vibRate = 3, addAction = 0, target = 1, 
			server;
		server = server ?? {Server.default};
		group = CtkGroup.new(start, dur, addAction: addAction, target: target, 
			server: server);
		freqCntl = VSO_Vib.new(start, dur, freq, vibDepth, vibRate, \head, group, server);
		ampCntl = VSO_ADR.new(start, dur, ampPeakLevel, ampDecayLevel, addAction: \head, 
			target: group, server: server);
		oscil = sinoscdef.new(start, dur, \tail, group, server)
			.freq_(freqCntl.control).amp_(ampCntl.control);
		score = CtkScore.new(group, oscil);
	}
/* End Figure 18.13 */
/* Figure 18.14 */
VSO {

	classvar <sinoscdef;
	var <score, group, oscil, freqCntl, <ampCntl;
	
	*new {arg start = 0.0, dur = nil, freq = 622.254, ampPeakLevel = 0.707, ampDecayLevel = 0.01, 
		vibDepth = 0.21, vibRate = 3, addAction = 0, target = 1, server;
		^super.new.initVSO(start, dur, freq, ampPeakLevel, ampDecayLevel, 
			vibDepth, vibRate, addAction, target, server);
	}

	*initClass {
		sinoscdef.isNil.if({
			sinoscdef = CtkSynthDef.new(\NRT_sinosc, 
				{arg outbus = 0, freq = 622.254, phase = 0, amp = 1, offSet = 0;
					Out.ar(outbus, SinOsc.ar(freq, phase, amp, offSet));
				})
			});
	}

	initVSO {arg start = 0.0, dur = nil, freq = 622.254, ampPeakLevel = 0.707, 
		ampDecayLevel = 0.01, vibDepth = 0.21, vibRate = 3, addAction = 0, target = 1, 
			server;
		server = server ?? {Server.default};
		group = CtkGroup.new(start, dur, addAction: addAction, target: target, 
			server: server);
		freqCntl = VSO_Vib.new(start, dur, freq, vibDepth, vibRate, \head, group, server);
		ampCntl = VSO_ADR.new(start, dur, ampPeakLevel, ampDecayLevel, addAction: \head, 
			target: group, server: server);
		oscil = sinoscdef.new(start, dur, \tail, group, server)
			.freq_(freqCntl.control).amp_(ampCntl.control);
		score = CtkScore.new(group, oscil);
	}

}
/* End Figure 18.14 */
/* Figure 18.15 */
s = Server.local;
s.boot;

(
var score;
var baseNote = 75;
var firstPitch = (baseNote + 0).midicps;
var secondPitch = (baseNote - 4).midicps;
var thirdPitch = (baseNote + 7).midicps;

score = CtkScore.new(
	(a = VSO.new(0.0, 5.0, firstPitch, 0.25, 0.01, 0.21, 2.3, server: s)).score,
	(b = VSO.new(2.2, 4.0, secondPitch, 0.25, 0.01, 0.15, 1.7, server: s)).score,
	(c = VSO.new(3.1, 3.75, thirdPitch, 0.15, 0.3, 0.21, 4, server: s)).score
);
score.play;
)
/* End Figure 18.15 */
/* Figure 18.16 */
s = Server.local;
s.boot;

(
var score;
var baseNote = 75;
var firstPitch = (baseNote + 0).midicps;
var secondPitch = (baseNote - 4).midicps;
var thirdPitch = (baseNote + 7).midicps;

d = [2.4, 1.7];
a = NRT_TimeFrame.new(0.0, 11);
b = NRT_TimeFrame.new(a.starttime + d.at(0), a.endtime - (a.starttime + d.at(0)));
c = NRT_TimeFrame.new(b.starttime + d.at(1), b.endtime - (b.starttime + d.at(1)));

score = CtkScore.new(
	(a = VSO.new(a.starttime, a.duration, firstPitch, 0.25, 0.01, 0.21, 2.3, server: s)).score,
	(b = VSO.new(b.starttime, b.duration, secondPitch, 0.25, 0.01, 0.15, 1.7, server: s)).score,
	(c = VSO.new(c.starttime, c.duration, thirdPitch, 0.15, 0.3, 0.21, 4, server: s)).score
);
score.play;
//N.B. You may notice three "Node not found" warnings.
// This is expected behavior for this version of Ctk
)
/* End Figure 18.16 */
/* Figure 18.17 */
NRT_TimeFrame {

	var >starttime, >duration;
	
	*new {arg starttime, duration;
		^super.newCopyArgs(starttime, duration);
	}

	starttime {
		^starttime.value;
	}

	duration {
		^duration.value;
	}

	endtime {
		^(this.starttime != nil).if({
			(this.duration != nil).if({
				//call the getter methods rather than accessing
				// the variables directly
				this.starttime + this.duration;
			}, {nil})
		}, {nil});
	}

}
/* End Figure 18.17 */


/* Figure 2.1 */

s = Server.internal.boot;
z = s.scope(4);

// a) mono output
(
a = SynthDef(\UGen_ex1a, {
	Out.ar(0, SinOsc.ar(440, 0, 0.1))
}).play(s);
)	
a.free;

// b) freq input is an Array of 4 items - outputs to busses 0-3
(
a = SynthDef(\UGen_ex1b, {
	Out.ar(0, SinOsc.ar([440, 446, 448.5, 882], 0, 0.1))
}).play(s);
)	
a.free;

// c) Array is added to the 'mul' arg to show mapping
(
a = SynthDef(\UGen_ex1c, {
	Out.ar(0, SinOsc.ar([440, 446, 448.5, 882], 0, [0.1, 0.2, 0.3, 0.4]))
}).play(s);
)	
a.free;

// d) The output of the SinOsc above is actually an Array of four SinOscs. Sum them together
// for an additive synthesis example.
(
a = SynthDef(\UGen_ex1d, {
	Out.ar(0, SinOsc.ar([440, 446, 448.5, 882], 0, [0.1, 0.2, 0.3]).sum);
}).play(s);
)	
a.free;

z.window.close;

/* Figure 2.2 */

Server.default = s = Server.internal.boot;

z = s.scope;
(
SynthDef(\UGen_ex2, {arg freq = 440;
	var src, compressor, limiter, out;
	// 10 SinOsc's, mixed together. Output amplitude is controlled with an Dust UGen
 	// wrapped in a Decay2 UGen to create a spike with an Exponential Decay
	src = SinOsc.ar(
		// a harmonic series based on freq
		Array.series(10, freq, freq),
		0, // phase
		Array.fill(10, {Decay2.ar( 
			// Dust will create an impulse about every 2 seconds, with values between 0
			// and 5
			Dust.ar(0.1, 5),
			// Decay2, attach time of 0.01 seconds and a decay time of 5 seconds to
			// allow for a build up of signal
			0.01, 5)});
		).sum;
	// compress signal about 0.5
	compressor = Compander.ar(src, src, 0.5, 1, 0.1);
	limiter = Limiter.ar(compressor, 0.5);
	// out is the compressed only signal on the left, the compressed and limited on the 
	// right
	out = [DelayN.ar(compressor, 0.02, 0.02), limiter];
	// use Peak and poll to track the highest output values. Updates every second
	Peak.ar(out ++  src, Impulse.kr(1)).poll(1, ["compressed", "limited", "src"]);
	Out.ar(0, out);
}).add;
)	
a = Synth(\UGen_ex2, [\freq, 440]);

a.free; z.window.close;

/* Figure 2.3 */
(
SynthDef(\UGen_ex3, {arg gate = 1, amp = 1, rate = 10;
	var trigger, dur, carfreq, modfreq, index, pan, env;
	trigger = Impulse.ar(rate);
	dur = rate.reciprocal;
	carfreq = LFNoise2.kr.range(100, 110);
	modfreq = LFTri.kr(0.1).exprange(200, 840);
	index = LFCub.kr(0.2).range(4, 10);
	pan = WhiteNoise.ar.range(-0.1, 0.1);
	env = EnvGen.kr(
		Env([0, 1, 0], [1, 1], \sin, 1),
		gate,
		levelScale: amp,
		doneAction: 2);
	Out.ar(0,
		GrainFM.ar(2, trigger, dur, carfreq, modfreq, index,
			pan, -1) * env)
}).add;
)
a = Synth(\UGen_ex3, [\rate, 80, \amp, 0.2]);

b = Synth(\UGen_ex3, [\rate, 42, \amp, 0.2]);

c = Synth(\UGen_ex3, [\rate, 121, \amp, 0.2]);

[a, b, c].do({arg thisSynth; thisSynth.set(\gate, 0)});

/* Figure 2.4 */

(
SynthDef(\UGen_ex4a, {arg id, limit = 1;
	var src, pitch, hasPitch, keynum, outOfTune;
	// read input
	src = SoundIn.ar(0);
	// analyze the frequency of the input
	#pitch, hasPitch = Pitch.kr(src);
	// convert to a midi keynum, but don't round! This value will be used later.
	pitch = pitch.cpsmidi;
	// if you are within an eighth tone of an equal tempered pitch, send a trigger
	outOfTune = (pitch - pitch.round).abs < 0.25;
	// if outOfTune is true, send a trigger. Limit to 1 trigger every 'limit' seconds  
	SendTrig.kr(Trig.kr(outOfTune, limit), id, pitch.round);
}).add;
	
SynthDef(\UGen_ex4b, {arg id1, id2, limit = 1, thresh = 0.5;
	var src, amp, amptrig, timer;
	src = SoundIn.ar(0);
	// analyze the amplitude input, cause a trigger if the output is over the thresh
	amp = Amplitude.kr(src);
	amptrig = Trig.kr(amp > thresh, limit);
	// use amptrig to see how long it is between triggers.
	timer = Timer.kr(amptrig);
	// send the values back with two different ids
	SendTrig.kr(amptrig, id1, amp);
	SendTrig.kr(amptrig, id2, timer);
}).add;

// plays a SinOsc of the pitch you were closest to
SynthDef(\UGen_ex4c, {arg freq;
	Out.ar(1, SinOsc.ar(freq, 0, XLine.kr(0.1, 0.00001, 0.5, doneAction: 2)))
}).add;

// modulated noise to respond to amp spikes
SynthDef(\UGen_ex4d, {arg freq;
	Out.ar(1, LFNoise1.ar(200) * SinOsc.ar(freq, 0, 
		XLine.kr(0.1, 0.00001, 0.5, doneAction: 2)));
}).add;

// allocate three unique ids for the trigger ids
a = UniqueID.next;
b = UniqueID.next;
c = UniqueID.next;	

// an envelope to poll for amp values later
e = Env([440, 880], [1], \exp);

// add the responder
o = OSCresponderNode(s.addr, '/tr', {arg time, responder, msg;
	// the msg is an array with 4 values... post them
	msg.postln;
	// the id sent back from the SendTrig is msg[2]... use it to decide what to do
	case 
		// pitch trigger
		{msg[2] == a}
		// msg[3] is the rounded keynum
		{Synth(\UGen_ex4c, [\freq, msg[3].midicps])}
		// amp trigger
		{msg[2] == b}
		// play a noise burst, higher the amp value, higher the freq (polls the 
		// Env 'e')
		{Synth(\UGen_ex4d, [\freq, e[msg[3]]])}
		// use the Timer value to play a delayed noise burst at 2000 Hz
		{msg[2] == c}
		{SystemClock.sched(msg[3], {
			Synth(\UGen_ex4d, [\freq, 2000]);
			})}
}).add;

// schedule the start our listening synths...
// then sing or tap away on the input.
SystemClock.sched(1.0, {
	Synth(\UGen_ex4a, [\id, a, \limit, 1]);
	Synth(\UGen_ex4b, [\id1, b, \id2, c, \limit, 0.2, \thresh, 0.25]);
});
	
// add a command period function to stop the synths and remove the responder
CmdPeriod.doOnce({
	o.remove; "Removed the responder".postln;
})
)

/* Figure 2.5 */
(
SynthDef(\UGen_ex5, {arg gate = 1, seed = 0, id = 1, amp = 1;
	var src, pitchbase, freq, rq, filt, trigger, env;
	RandID.ir(id);
	RandSeed.ir(1, seed);
	env = EnvGen.kr(Env([0, 1, 0], [1, 4], [4, -4], 1), gate, doneAction: 2);
	src = WhiteNoise.ar;
	trigger = Impulse.kr(Rand.new(2, 5));
	pitchbase = IRand.new(4, 9) * 12;
	freq = TIRand.kr(pitchbase, pitchbase + 12, trigger).midicps;
	rq = LFDNoise3.kr(Rand.new(0.3, 0.8)).range(0.01, 0.005);
	filt = Resonz.ar(src, Lag2.kr(freq), rq);
	Out.ar(0, Pan2.ar(filt, LFNoise1.kr(0.1)) * env * amp)
}).add;
)	
a = Synth(\UGen_ex5, [\seed, 123]);

a.release;

// Using the same seed, we get the same gesture
b = Synth(\UGen_ex5, [\seed, 123]);

b.release;

// passing in different seeds
(
r = Routine.run({
	thisThread.randSeed_(123);
	10.do({
		a = Synth(\UGen_ex5, [\seed, 10000.rand.postln, \amp, 3.dbamp]);
		1.wait;
		a.release;
	})
});
)		
/* Figure 2.6 */
(
SynthDef(\UGen_ex6, {arg gate = 1, roomsize = 200, revtime = 450;
	var src, env, gverb;
	env = EnvGen.kr(Env([0, 1, 0], [1, 4], [4, -4], 1), gate, doneAction: 2);
	src = Resonz.ar(
			Array.fill(4, {Dust.ar(6)}),
			1760 * [1, 2.2, 3.95, 8.76] + 
				Array.fill(4, {LFNoise2.kr(1, 20)}), 
			0.01).sum * 30.dbamp;
	gverb = GVerb.ar(
		src,
		roomsize, 
		revtime, 
		// feedback loop damping
		0.99,
		// input bw of signal
		LFNoise2.kr(0.1).range(0.9, 0.7),
		// spread 
		LFNoise1.kr(0.2).range(0.2, 0.6),
		// almost no direct source 
		-60.dbamp,
		// some early reflection
		-18.dbamp, 
		// lots of the tail
		3.dbamp,
		roomsize);
	Out.ar(0, gverb * env)
}).add;
)	
a = Synth(\UGen_ex6);

a.release;

/* Figure 2.7 */
(
SynthDef(\UGen_ex7a, {arg gate = 1, freq = 440, amp = 0.1, rate = 0.2;
	var src, pos, env;
	src = SinOsc.ar(freq, 0);
	pos = LFNoise2.ar(rate);
	env = EnvGen.kr(
		Env([0, 1, 0], [1, 1], \sin, 1), gate, levelScale: amp, doneAction: 2);
	Out.ar(0, Pan2.ar(src, pos) * env);
}).add;
			
SynthDef(\UGen_ex7b, {arg gate = 1, freq = 440, amp = 0.1, rate = 0.2;
	var src, pos, env;
	src = SinOsc.ar(freq, 0);
	pos = LFNoise2.kr(rate);
	env = EnvGen.kr(
		Env([0, 1, 0], [1, 1], \sin, 1), gate, levelScale: amp, doneAction: 2);
	Out.ar(0, Pan2.ar(src, pos) * env);
}).add;
	
SynthDef(\UGen_ex7c, {arg gate = 1, freq = 440, amp = 0.1, rate = 0.2;
	var src, pos, env;
	src = SinOsc.ar(freq, 0);
	pos = LFNoise2.kr(rate);
	env = EnvGen.kr(
		Env([0, 1, 0], [1, 1], \sin, 1), gate, levelScale: amp, doneAction: 2);
	Out.ar(0, Pan2.ar(src * env, pos));
}).add;
)

// 56% on my machine
(
a = Group.new;
250.do({
	Synth(\UGen_ex7a, [\freq, 440.0.rrand(1760.0), \amp, 0.001, \rate, 0.2], a)
});
)
a.release;

// 39%
(
a = Group.new;
250.do({
	Synth(\UGen_ex7b, [\freq, 440.0.rrand(1760.0), \amp, 0.001, \rate, 0.2], a)
});
)
a.release;

// 35%
(
a = Group.new;
250.do({
	Synth(\UGen_ex7c, [\freq, 440.0.rrand(1760.0), \amp, 0.001, \rate, 0.2], a)
});
)
a.release;

/* Figure 2.8 */
(
SynthDef(\UGen_ex8a, {arg gate = 1, freq = 440, amp = 0.1, rate = 0.2;
	var w, x, y, out, env, decode;
	#w, x, y = PanB2.ar(
		SinOsc.ar(freq, 0), LFNoise2.kr(rate));
	env = EnvGen.kr(
		Env([0, 1, 0], [1, 1], \sin, 1), gate, levelScale: amp, doneAction: 2);
	decode = DecodeB2.ar(2, w, x, y);
	Out.ar(0, decode * env)
}).add;
			
SynthDef(\UGen_ex8b, {arg outbus, freq = 440, rate = 0.2;
	var w, x, y;
	#w, x, y = PanB2.ar(
		SinOsc.ar(freq, 0), LFNoise2.kr(rate));
	Out.ar(outbus, [w, x, y])
}).add;
			
SynthDef(\UGen_ex8c, {arg inbus, gate = 1, amp = 0.1;
	var w, x, y, env, decode;
	#w, x, y = In.ar(inbus, 3);
	env = EnvGen.kr(
		Env([0, 1, 0], [1, 1], \sin, 1), gate, levelScale: amp, doneAction: 14);
	decode = DecodeB2.ar(2, w, x, y) * env;
	ReplaceOut.ar(0, decode);
}).add;
)

(
a = Group.new;
250.do({
	Synth(\UGen_ex8a, [\freq, 440.0.rrand(1760.0), \amp, 0.001, \rate, 0.2], a)
});
)
a.release;

(
a = Group.new;
z = Bus.audio(s, 3);

// the 'catch-all' synth for decoding and enveloping
Synth(\UGen_ex8c, [\inbus, z, \amp, 0.001], a, \addAfter); // add it after the Group containing the encoding synths

250.do({
	Synth(\UGen_ex8b, [\freq, 440.0.rrand(1760.0), \outbus, z, \rate, 0.2], a)
});
)

a.release;	
/* Figure 2.9 */
(
// pass in amp in db
SynthDef(\UGen_ex9a, {arg gate = 1, freq = 440, amp = 0;
	var src, pos, env;
	src = SinOsc.ar(freq, 0, amp.dbamp);
	env = EnvGen.kr(
		Env([0, 1, 0], [1, 1], \sin, 1), gate, doneAction: 2);
	Out.ar(0, Pan2.ar(src * env, Rand(-1.0, 1.0)));
}).add;
	
// pass in linear amplitude
SynthDef(\UGen_ex9b, {arg gate = 1, freq = 440, amp = 1;
	var src, env;
	src = SinOsc.ar(freq, 0, amp);
	env = EnvGen.kr(
		Env([0, 1, 0], [1, 1], \sin, 1), gate, doneAction: 2);
	Out.ar(0, Pan2.ar(src * env, Rand(-1.0, 1.0)));
}).add;
	
SynthDef(\UGen_ex9c, {arg gate = 1, freq = 440, amp = -3, pos = 0;
	var src, env;
	src = SinOsc.ar(freq, 0, amp);
	env = EnvGen.kr(
		Env([0, 1, 0], [1, 1], \sin, 1), gate, doneAction: 2);
	Out.ar(0, Pan2.ar(src * env, pos));
}).add;
)	

// 45% on my machine
(
a = Group.new;
250.do({
	Synth(\UGen_ex9a, [\freq, 440.0.rrand(1760.0), \amp, -60], a)
});
)
a.release;

// 36%
(
a = Group.new;
250.do({
	Synth(\UGen_ex9b, [\freq, 440.0.rrand(1760.0), \amp, -60.dbamp], a)
});
)
a.release;

// 36% (no difference from b)
(
a = Group.new;
250.do({
	Synth(\UGen_ex9c, [\freq, 440.0.rrand(1760.0), \amp, -60.dbamp, \pos, 1.0.rand2], a)
});
)
a.release;

/* Figure 2.10 */
(
SynthDef(\UGen_ex10a, {arg gate = 1;
	var src, delay, env;
	env = EnvGen.kr(
		Env([0, 1, 0], [1, 1], \sin, 1), gate, doneAction: 2);
	src = Decay.ar(Impulse.ar(1), 1.0, PinkNoise.ar(0.1));
	delay = CombN.ar(src, 0.1, Line.kr(0.0001, 0.001, 10));
	Out.ar(0, (delay * env).dup);
}).add;

SynthDef(\UGen_ex10b, {arg gate = 1;
	var src, delay, env;
	env = EnvGen.kr(
		Env([0, 1, 0], [1, 1], \sin, 1), gate, doneAction: 2);
	src = Decay.ar(Impulse.ar(1), 1.0, PinkNoise.ar(0.1));
	delay = CombL.ar(src, 0.1, Line.kr(0.0001, 0.001, 10));	
	Out.ar(0, (delay * env).dup);
}).add;

SynthDef(\UGen_ex10c, {arg gate = 1;
	var src, delay, env;
	env = EnvGen.kr(
		Env([0, 1, 0], [1, 1], \sin, 1), gate, doneAction: 2);
	src = Decay.ar(Impulse.ar(1), 1.0, PinkNoise.ar(0.1));
	delay = CombC.ar(src, 0.1, Line.kr(0.0001, 0.001, 10));	
	Out.ar(0, (delay * env).dup);
}).add;
)

a = Synth(\UGen_ex10a); // no interpolation
a.release;

a = Synth(\UGen_ex10b); // linear interpolation
a.release;

a = Synth(\UGen_ex10c); // cubic interpolation
a.release;

(
SynthDef(\UGen_ex10d, {arg gate = 1, deltime = 0.001;
	var src, delay, env;
	env = EnvGen.kr(
		Env([0, 1, 0], [1, 1], \sin, 1), gate, doneAction: 2);
	src = Decay.ar(Impulse.ar(1), 1.0, PinkNoise.ar(0.1));
	delay = CombN.ar(src, 0.1, deltime);
	Out.ar(0, (delay * env).dup);
}).add;

SynthDef(\UGen_ex10e, {arg gate = 1, deltime = 0.001;
	var src, delay, env;
	env = EnvGen.kr(
		Env([0, 1, 0], [1, 1], \sin, 1), gate, doneAction: 2);
	src = Decay.ar(Impulse.ar(1), 1.0, PinkNoise.ar(0.1));
	delay = CombL.ar(src, 0.1, deltime);
	Out.ar(0, (delay * env).dup);
}).add;
	
SynthDef(\UGen_ex10f, {arg gate = 1, deltime = 0.001;
	var src, delay, env;
	env = EnvGen.kr(
		Env([0, 1, 0], [1, 1], \sin, 1), gate, doneAction: 2);
	src = Decay.ar(Impulse.ar(1), 1.0, PinkNoise.ar(0.1));
	delay = CombC.ar(src, 0.1, deltime);
	Out.ar(0, (delay * env).dup);
}).add;
)

// tune to a specific pitch
a = Synth(\UGen_ex10d, [\deltime, 100.midicps.reciprocal]); // no interpolation
a.release;

a = Synth(\UGen_ex10e, [\deltime, 100.midicps.reciprocal]); // linear interpolation
a.release;

a = Synth(\UGen_ex10f, [\deltime, 100.midicps.reciprocal]); // cubic interpolation
a.release;

// a much longer delay
a = Synth(\UGen_ex10d, [\deltime, 0.1]); // no interpolation
a.release;

a = Synth(\UGen_ex10e, [\deltime, 0.1]); // linear interpolation
a.release;

a = Synth(\UGen_ex10f, [\deltime, 0.1]); // cubic interpolation
a.release;



//////// First step in evolving the buffer slicer from Figure 20.9 into a more flexible prototype.
//////// Here we add support for multiple buffers, from arrays of paths and coordinates.
//////// A pattern, ~buffer, will choose which buffer to use for each event.

// This is a copy of the Figure 20.9 prototype with additions, highlighted by comments.

(
SynthDef(\bufGrainPan, { |start, time, bufnum, pan, rate = 1, amp = 1,
		attack = 0.001, decay = 0.02, outbus|
	var sig;
	sig = PlayBuf.ar(1, bufnum, rate * BufRateScale.kr(bufnum), 1, start, 0)
		* EnvGen.kr(Env.linen(attack, time, decay), doneAction:2);
	Out.ar(outbus, Pan2.ar(sig, pan, amp));
}).add;

PR(\abstractProcess).clone({
	~event = (eventKey: \singleSynthPlayer);
	~quant = 0;

	~delta = Pwhite(1, 5, inf) * 0.1;
	~tfactor = 1;
	~maxStart = Pfunc({ |ev| ev[\bufnum].duration }) - Pkey(\time);
	~startSec = Pwhite(0.0, BPStream(\maxStart), inf);
	~pan = Pwhite(-1.0, 1.0, inf);
	~amp = 1;
	~rate = 1;
	~buffer = Pfunc({ ~bufs.choose });

	~asPattern = {
		Pbind(
			\chan, ~chan,
			\instrument, \bufGrainPan,
			\rate, BPStream(\rate),	// reference to ~rate stream
			\delta, BPStream(\delta),
			\bufnum, BPStream(\buffer),
			\time, BPStream(\tfactor) * Pkey(\delta),
			\start, BPStream(\startSec) * Pfunc({ |ev| ev[\bufnum].sampleRate }),
			\pan, BPStream(\pan),
			\amp, BPStream(\amp)
		)
	};

	~paths = ["sounds/a11wlk01.wav"];	// now an array of strings
		// [startFrame, numFrames] for each path in ~paths
		// if this array is shorter, the path index will be wrapped
		// this default will load the complete soundfile for every path
	~bufCoords = [[0, -1]];

	~prep = {
		~chan = MixerChannel(~collIndex, s, 2, 2);
		~loadBufs.();	// move buffer loading to a separate method for modularity
	};

	~loadBufs = {
		~bufs.do({ |buf| buf.free });
		~bufs = ~paths.collect({ |path, i|
			~loadOneBuf.(path, *~bufCoords.wrapAt(i));
		});
	};
	
	~loadOneBuf = { |path, startFrame, numFrames|
		if(thisProcess.platform.name == \linux and: { path[..5] == "sounds" }) {
			path = Platform.systemAppSupportDir +/+ path;
		};
		"loading %\n".postf(path);
		Buffer.read(s, path, startFrame, numFrames,
			action: { "done loading %\n".postf(path) });
	};
	
		// why not? you should be able to add and remove buffers on the fly
		// removing a buffer if a synth is using it is maybe risky, though
	~addBuf = { |path, startFrame, numFrames|
		~bufs = ~bufs.add(~loadOneBuf.(path, startFrame, numFrames));
	};
	
	~removeBufAt = { |index|
		~bufs[index].free;
		~bufs.removeAt(index);
	};

	~freeCleanup = {
		[~chan, ~bufs].free;
	};
}) => PR(\bufSlicer);
)

PR(\bufSlicer).chuck(BP(\z), parms: (paths: ["sounds/a11wlk01.wav", "sounds/a11wlk01-44_1.aiff"]));

BP(\z).play;

BP(\z).tfactor = sin(Pseries(0, 0.1, inf)) * 0.45 + 0.55;
BP(\z).delta = Pstutter(Pwhite(4, 12, inf), Pxrand((1..6) * 0.05, inf));
BP(\z).startSec = Pclutch(Pwhite(0.0, BPStream(\maxStart), inf), Pdiff(Pkey(\delta)).abs > 0);
BP(\z).buffer = Pclutch(Pfunc({ ~bufs.choose }), Pdiff(Pkey(\delta)).abs > 0);
BP(\z).pan = sin(Ptime(inf));

BP(\z).stop;

BP(\z).free;



//////// Second step in evolving the buffer slicer from Figure 20.9 into a more flexible prototype.
//////// Upping the ante further... now we support multiple synthdefs.
//////// The main pattern does not know in advance which streams to use,
//////// until the specific def is chosen. So, I invent a data structure that holds
//////// the SynthDef and patterns for each argument. At initialization, these
//////// patterns are written into the environment and can be tweaked as in
//////// previous examples.

(
PR(\abstractProcess).clone({
	~event = (eventKey: \singleSynthPlayer);
	~quant = 0;

	~delta = Pwhite(1, 5, inf) * 0.1;
	~def = Pfunc({ ~defs.keys.choose });
	~buffer = Pfunc({ ~bufs.choose });
	~maxStart = Pfunc({ |ev| ev[\bufnum].duration }) - Pkey(\time);

	~basePattern = {
		Pbind(
			\chan, ~chan,
			\def, BPStream(\def),
			\instrument, Pfunc({ |ev| ~defs[ev[\def]].name }),
			\delta, BPStream(\delta),
			\bufnum, BPStream(\buffer)
		)
	};
	
	~userPattern = { nil };
	
	~asPattern = {
		var	userpat = ~userPattern.();
		userpat.notNil.if({
			Pchain(userpat, ~basePattern.())
		}, {
			~basePattern.()
		}).collect({ |ev|
			~defs[ev[\def]].argStreams.pairsDo({ |name, value|
				ev.put(name, value.next(ev));
			});
			ev
		});
	};

	~paths = ["sounds/a11wlk01.wav"];
	~bufCoords = [[0, -1]];

	~prep = {
		~chan = MixerChannel(~collIndex, s, 2, 2);
		~loadBufs.();
		~initSynthDefs.();
	};

	~loadBufs = {
		~bufs.do({ |buf| buf.free });
		~bufs = ~paths.collect({ |path, i|
			~loadOneBuf.(path, *~bufCoords.wrapAt(i));
		});
	};
	~loadOneBuf = { |path, startFrame, numFrames|
		if(thisProcess.platform.name == \linux and: { path[..5] == "sounds" }) {
			path = Platform.systemAppSupportDir +/+ path;
		};
		"loading %\n".postf(path);
		Buffer.read(s, path, startFrame, numFrames,
			action: { "done loading %\n".postf(path) });
	};
	~addBuf = { |path, startFrame, numFrames|
		~bufs = ~bufs.add(~loadOneBuf.(path, startFrame, numFrames));
	};
	~removeBufAt = { |index|
		~bufs[index].free;
		~bufs.removeAt(index);
	};

	~initSynthDefs = {
		var	sdef;
		~defs = ~defs.value;
		~defs.keysValuesDo({ |id, defDict|
			sdef = defDict[\def];
			defDict[\name] = sdef.tryPerform(\name) ? sdef;
			sdef.tryPerform(\send, ~chan.server);
			sdef.tryPerform(\add);
			~initArgsForSynthDef.(id);
		});
	};
	
	~initArgsForSynthDef = { |id|
		var	streamarray = Array.new(~defs[id][\args].size), fullname;
		~defs[id][\args].pairsDo({ |name, pattern|
				// assigning a Pattern to a BP environment variable automatically creates the stream
			fullname = (id ++ name).asSymbol;
			fullname.envirPut(pattern.asPattern);
			streamarray.add(name).add(BPStream(fullname).asStream);
		});
		~defs[id][\argStreams] = streamarray;
	};
	
	~defs = (
		basic: (def: SynthDef(\bufGrainPan, { |start, time, bufnum, pan, rate = 1, amp = 1,
						attack = 0.001, decay = 0.02, outbus|
					var sig;
					sig = PlayBuf.ar(1, bufnum, rate * BufRateScale.kr(bufnum), 1, start, 0)
						* EnvGen.kr(Env.linen(attack, time, decay), doneAction:2);
					Out.ar(outbus, Pan2.ar(sig, pan, amp));
				}),
			args: [
				rate: 1,
				tfactor: 1,
				time: Pkey(\tfactor) * Pkey(\delta),
				startSec: Pwhite(0.0, BPStream(\maxStart), inf),
				start: Pkey(\startSec) * Pfunc({ |ev| ev[\bufnum].sampleRate }),
				pan: Pwhite(-1.0, 1.0, inf),
				amp: 1
			]),
		stretch: (def: SynthDef(\bufStretch, { |start, time, bufnum, pan, rate = 1, amp = 1,
						stretch = 1, attack = 0.001, decay = 0.02, outbus|
					var sig;
					sig = PlayBuf.ar(1, bufnum, rate * BufRateScale.kr(bufnum) / stretch, 1, start, 0);
					sig = PitchShift.ar(sig, pitchRatio: stretch)
						* EnvGen.kr(Env.linen(attack, time, decay), doneAction:2);
					Out.ar(outbus, Pan2.ar(sig, pan, amp));
				}),
			args: [
				rate: 1,
				tfactor: 1,
				stretch: Pexprand(2.0, 4.0, inf),
				delta: Pkey(\delta) * Pkey(\stretch),
				time: Pkey(\tfactor) * Pkey(\delta),
				startSec: Pwhite(0.0, Pfunc({ |ev| ev[\bufnum].duration }) - (Pkey(\time) / Pkey(\stretch))),
				start: Pkey(\startSec) * Pfunc({ |ev| ev[\bufnum].sampleRate }),
				pan: Pwhite(-1.0, 1.0, inf),
				amp: 1
			])
	);

	~freeCleanup = {
		[~chan, ~bufs].free;
	};
}) => PR(\bufSlicer);
)

PR(\bufSlicer).chuck(BP(\z), parms: (paths: ["sounds/a11wlk01.wav", "sounds/a11wlk01-44_1.aiff"]));

BP(\z).play;

BP(\z).def = Pwrand(#[basic, stretch], [0.9, 0.1], inf);

// tfactor, startSec and pan are defined separately for each synthdef
// so, based on the Proto definition, I must prepend the synthdef's key
// delta and buffer are global for all synthdefs, so no prepend
BP(\z).basictfactor = sin(Pseries(0, 0.1, inf)) * 0.45 + 0.55;
BP(\z).delta = Pstutter(Pwhite(4, 12, inf), Pxrand((1..6) * 0.05, inf));
BP(\z).basicstartSec = Pclutch(Pwhite(0.0, BPStream(\maxStart), inf), Pdiff(Pkey(\delta)).abs > 0);
BP(\z).buffer = Pclutch(Pfunc({ ~bufs.choose }), Pdiff(Pkey(\delta)).abs > 0);
BP(\z).basicpan = sin(Ptime(inf));

BP(\z).stop;

BP(\z).free;


/*
Here, the chucking parms dictionary is used to add a new synthdef, not as part of the prototype but just in the instance. To avoid polluting the original defs dictionary, the parameter should copy the original and put new item(s) into it -- PR(\bufSlicer).defs.copy.put(\grains, ...).
*/

(
PR(\bufSlicer).chuck(BP(\z), parms: (
	paths: ["sounds/a11wlk01.wav", "sounds/a11wlk01-44_1.aiff"],
	defs: PR(\bufSlicer).defs.copy.put(
		\grains, (def: SynthDef(\grainspray, { |center = 0.5, width = 0.1,
				durStart = 0.01, durEnd = 0.01, density = 5,
				attack = 0.001, time = 1, decay = 0.02, amp = 1, bufnum, outbus|
			var	trig = Dust.kr(density),
				rate = TExpRand.kr(0.25, 4.0, trig),
				dur = XLine.kr(durStart, durEnd, time),
				pan = TRand.kr(-1.0, 1.0, trig),
				posRand = TRand.kr(width.neg, width, trig),
				sig = TGrains.ar(2, trig, bufnum, rate, center * BufDur.kr(bufnum) + posRand,
					dur, pan, amp);
			Out.ar(outbus, sig * EnvGen.kr(Env.linen(attack, time, decay), doneAction: 2))
		}),
		args: [
			center: Pwhite(0.05, 0.95, inf),
			width: min(Pwhite(0.05, 0.2, inf), min(Pkey(\center), 1.0 - Pkey(\center))),
			time: Pkey(\delta),
			density: Pwhite(20.0, 50.0, inf)
		])
	)
));
)

BP(\z).play;

BP(\z).def = Pwrand(#[basic, stretch, grains], [0.8, 0.15, 0.05], inf);

// Manipulating other streams is an exercise for the reader.

BP(\z).stop;

BP(\z).free;


/*****

This file contains all the code examples from Chapter 20 of The SuperCollider Book.

Most of them require the server to be started. A few use graphics -- if you are using SwingOSC, make sure the SwingOSC server is booted as well.

IMPORTANT NOTE FOR SWINGOSC USERS:
Please also execute this line before running the code examples. Otherwise, some '.gui' statements will fail.

Quarks.install("ddwGUIEnhancementsForSwingOSC");

Macintosh users should *not* install the GUI enhancements for SwingOSC.


See also the example files BufferSlicer-variant1.sc and BufferSlicer-variant2.sc, which take the buffer slicer process (Figure 20.9) to a higher degree of complexity and reusability.

Figure numbers missing from this file are graphics.

--- H. James Harkins

*****/



////////////////////////////////////////
//////// Figure 20.1.
//////// MixerChannel creation, SynthDef conventions, Synth playing

// create the mixer: one channel in, two channels out
s.boot;

m = MixerChannel(\fig1, s, 1, 2);

// bring up a mixing board -- you can play with the level and panning controls
// closing the window, or freeing all of its channels, removes the MixingBoard
b = MixingBoard(\Fig1, nil, m);

// a SynthDef should include an outbus (or out) argument
// so that the MixerChannel can tell it where to write its output
(
SynthDef(\fig1, { |out, lowfreq = 220, hifreq = 1200, decay = 0.05|
	var	trig = Impulse.kr(8);
		// Do not hard-code the outbus here!
		// Out.ar(0, ...) is not OK. Out.ar(outbus, ...) is good.
	Out.ar(out, SinOsc.ar(TExpRand.kr(lowfreq, hifreq, trig)) * Decay2.kr(trig, 0.01, decay));
}).add;
)

a = m.play(\fig1, [lowfreq: 100, hifreq: 2000, decay: 0.1]);

// automate panning - this is done with a control-rate synth
m.automate(\pan, { SinOsc.kr(LFNoise1.kr(0.5).exprange(0.4, 5.0)) });

// the GUI can show the automation
m.watch(\pan);

// add reverb using post-fader send
// auto-play the reverb synth in the completion function
(
r = MixerChannel(\rvb, s, 2, 2, level:1, completionFunc: { |chan|
	"creating reverb synth".postln;
	chan.playfx({ |outbus|
		var	sig = In.ar(outbus, 2);  // read from channel's bus
		FreeVerb2.ar(sig[0], sig[1], 1, 0.6, 0.5)
	});
});

b.add(r);  // add to MixingBoard
)

// feed the signal into the reverb
m.newPostSend(r, 0.6);

// prints out current state of all mixers in the board
// the board is accessible also by MixingBoard.at(0)
b.postSettings;

// fade to black
m.levelTo(0, 15);

// and release
// note that on m.free, the synth 'a' is removed also
// freeing the last MixerChannel in the MixingBoard closes the window
m.free;
r.free;



////////////////////////////////////////
//////// Figure 20.3.
//////// Basic Voicer creation; triggering and gating notes.

// Voicer(voices, things, args, bus, target, addAction)
// target may be a Group, Server, or MixerChannel
v = Voicer(10, \default);

v.trigger(440, 1);  // v.trigger(freq, gate, args, latency)
v.release(440);

v.gate(440, 2.0, 1, [pan: -0.5]);  // v.gate(freq, dur, gate, args, latency)

r = fork {
	loop {
			// play over a C major scale
		[60, 62, 64, 65, 67, 69, 71, 72].do({ |midi|
			v.gate(midi.midicps, 0.1, 1, [amp: rrand(0.05, 0.15)],
				lat: 0.1);
			0.125.wait;
		});
	}
};

r.stop;

v.free;



////////////////////////////////////////
//////// Figure 20.4.
//////// Global controls and GUI.

// let's put a pan global control on the voicer

v = Voicer(10, \default);
v.mapGlobal(\pan, nil, 0, \bipolar);	// v.mapGlobal(name, bus, value, spec, allowGUI)

v.gui;

// Pbind works with voicer, using 'voicerNote' event type
(
p = Pbind(
	\type, \voicerNote,
	\voicer, v,
	\degree, Pn(Pseries(0, 1, 8), inf),
	\amp, Pwhite(0.05, 0.15, inf),
	\dur, 0.125,
	\legato, 0.8
).play;
)

// Try moving the slider in the Voicer window

p.stop;

// Note, freeing the Voicer does not close the window
// because you might want to reuse the GUI
// But the Voicer area becomes "inactive"
v.free;



////////////////////////////////////////
//////// Figure 20.5.
//////// VoicerMIDISocket.

v = Voicer(10, \default);

// 0 = device 0, channel 0
// for a different device, use [device index, channel]
// after this, you can play on your keyboard
k = VoicerMIDISocket(0, v);

// modwheel to control pan
k.addControl(1, \pan, 0, \bipolar);
v.gui;	// pan is identified by '1' in the gui - MIDI controller ID

// a homegrown variety of just intonation
// release all notes before executing this!
k.midiToFreq = TuningRatios(12, tunings: [1, 135/128, 9/8, 6/5, 5/4, 4/3, 45/32, 3/2, 14/9, 27/16, 16/9, 15/8]);

// If some notes got stuck by changing the tuning, do this:
v.panic;

// per-note argument generation using a Pbind
// here used to map velocity data onto the amp input
k.noteOnArgsPat = Pbind(\amp, Pkey(\velocity).linlin(0, 127, 0.01, 0.2));

// if you have a footswitch (controller number 64), this handles it properly
// make sure to use the same device:
// if you used [1, 0] for the channel ID before, use [1, 0] here
l = VoicerSusPedal(0, 64, v);

// by default, freeing the voicer automatically frees the socket and all attached MIDI controllers
v.free;



////////////////////////////////////////
//////// Figure 20.6.
//////// Proto for prototypes.

// standard "Hello World" greeter classes

(
~greeter = Proto({
	~sayhi = { |name|
		"%, %.\n".postf(~greeting.value, name ? ~name);
	};
	~name = "Monique";		// default name
	~greeting = "Hello";		// default greeting
});

// make a subclass with .clone
~frenchGreeter = ~greeter.clone({
	~greeting = "Bonjour";
});

~timeAwareFrenchGreeter = ~frenchGreeter.clone({
	~greeting = {
		var	hour;
		if(thisProcess.platform.name != \windows) {
			hour = Date.getDate.hour;
			if(hour < 18) { ~dayGreeting } { ~eveningGreeting };
		} { ~dayGreeting };
	};
	~dayGreeting = "Bonjour";
	~eveningGreeting = "Bon soir";
});
)

// Use the objects:
~greeter.sayhi;
~greeter.sayhi("Bob");
~frenchGreeter.sayhi("Isabelle");
	// note: Date does not work in Windows
	// this code ignores time check in Windows
~timeAwareFrenchGreeter.sayhi("Eric");



////////////////////////////////////////
//////// Figure 20.7.
//////// Greeter as a PR prototype, and usage through BP instances.

(
	// define PR prototype - Proto(...) => PR(\name)
Proto({
	~sayhi = { |name|
			// ~greeting.value is an internal pseudomethod call
		"%, %.\n".postf(~greeting.value, name ? ~name);
	};
	~name = "Monique";		// default name
	~greeting = "Hello";		// default greeting
}) => PR(\greeter);
)

// make working instance as BP
PR(\greeter) => BP(\greeter);
BP(\greeter).sayhi("Jacqueline");
BP(\greeter).name = "Zsa Zsa";
BP(\greeter).sayhi;
	// changing name in BP does not affect PR
PR(\greeter).name;

// override default at chuck time
// now this greeter belongs just to Bob
PR(\greeter).chuck(BP(\greetBob), parms: (name: "Bob"));
BP(\greetBob).name;	// ~name variable is overridden
BP(\greetBob).sayhi;

// remove both instances from the repository
BP([\greeter, \greetBob]).free;



////////////////////////////////////////
//////// Figure 20.9.
//////// Interactive session to build a soundfile slicer.

(
SynthDef(\bufGrainPan, { |start, time, bufnum, pan, rate = 1, amp = 1,
		attack = 0.001, decay = 0.02, outbus|
	var sig;
	sig = PlayBuf.ar(1, bufnum, rate * BufRateScale.kr(bufnum), 1, start, 0)
		* EnvGen.kr(Env.linen(attack, time, decay), doneAction:2);
	Out.ar(outbus, Pan2.ar(sig, pan, amp));
}).add;

PR(\abstractProcess).clone({
		// BEHAVIORAL components
		// eventKey refers to ProtoEvent(\singleSynthPlayer)
	~event = (eventKey: \singleSynthPlayer);
	~quant = 0;
		// here, manufacture the pattern to play
	~asPattern = {
		Pbind(
			\chan, ~chan,
			\instrument, \bufGrainPan,
			\bufnum, ~buf.bufnum,
			\delta, BPStream(\delta),	// reference to ~delta stream
			\time, BPStream(\tfactor) * Pkey(\delta),
			\start, BPStream(\startSec) * ~buf.sampleRate,
			\pan, BPStream(\pan),
			\amp, BPStream(\amp)
		)
	};
		// default Pbind streams
	~delta = Pwhite(1, 5, inf) * 0.1;
	~tfactor = 1;
	~maxStart = Pfunc({ ~buf.duration }) - Pkey(\time);
	~startSec = Pwhite(0.0, BPStream(\maxStart), inf);
	~pan = Pwhite(-1.0, 1.0, inf);
	~amp = 1;

		// ARCHITECTURAL components
		// default soundfile
	~path = Platform.case(
		\linux, { Platform.systemAppSupportDir +/+ "sounds/a11wlk01.wav" },
		{ "sounds/a11wlk01.wav" }
	);

	~startFrame = 0;
	~numFrames = -1;
		// constructor: auto-load soundfile and create mixer
	~prep = {
		~chan = MixerChannel(~collIndex, s, 2, 2);
		"loading %\n".postf(~path);
		~buf = Buffer.read(s, ~path, ~startFrame, ~numFrames,
			action: { "done loading buffer".postln });
	};
		// destructor, called on .free
	~freeCleanup = {
		[~chan, ~buf].free;
	};
}) => PR(\bufSlicer);
)

// That was the definition. In performance you only need this to play it.

PR(\bufSlicer) => BP(\columbia);
BP(\columbia).play;

// change process's stream references while it is playing
BP(\columbia).tfactor = 0.25;

BP(\columbia).tfactor = sin(Pseries(0, 0.1, inf)) * 0.45 + 0.55;

BP(\columbia).delta = Pstutter(Pwhite(4, 12, inf), Pxrand((1..6) * 0.05, inf));

BP(\columbia).startSec = Pclutch(Pwhite(0.0, BPStream(\maxStart), inf), Pdiff(Pkey(\delta)).abs > 0);

// also valid to chuck patterns into a BP
// ".pan" is an adverb indicating which variable to replace
sin(Ptime(inf)) =>.pan BP(\columbia);

BP(\columbia).stop;
BP(\columbia).free;	// MixerChannel and Buffer go away also



////////////////////////////////////////
//////// Figure 20.10.
//////// Factories for two variants of the buffer slicer process.

// In the definition file:
(
(make: { |name|
	PR(\bufSlicer) => BP(name);
}, type: \bp) => Fact(\basic);

(make: { |name|
	PR(\bufSlicer).chuck(BP(name), parms: (
		path: PR(\bufSlicer)[\path].dirname +/+ "a11wlk01-44_1.aiff",
		tfactor: sin(Pseries(0, 0.1, inf)) * 0.45 + 0.55,
		delta: Pstutter(Pwhite(4, 12, inf), Pxrand((1..6) * 0.05, inf)),
		startSec: Pclutch(Pwhite(0.0, Pfunc({ ~buf.duration }) - Pkey(\time)), Pdiff(Pkey(\delta)).abs > 0),
		pan: sin(Ptime(inf)),
		quant: 1	// quantize to next beat
	))
}, type: \bp) => Fact(\fancy);
)

// In the performance script:
Fact(\basic) => BP(\basic);

BP(\basic).play;

Fact(\fancy) => BP(\fancy);

BP(\fancy).play;

BP([\basic, \fancy]).stop;

BP([\basic, \fancy]).free;



// set up guis etc. for composition development

var	masterLayout, chuckKeyCtl, composeDocKeyResp,
	originalDocInit;	// must maintain independent of environment

var	path;

Library.at(\mixer, \smallskin).isNil.if({
	Library.put(\mixer, \smallskin, MixerSkin.new.maxAcross_(1));
});

~toolbarFlow.isNil.if({

AbstractChuckArray.loadFromChuckDirectories("devPreMIDIcfg.scd");

MIDIPort.init(~srcInports);
MIDIPort.resetAll;
MIDIPort.autoFreeSockets = false;	// protect midi controllers from being destroyed accidentally

s.boot;

~statusW = GUI.window.new("Building GUI, please wait...",
	Rect(GUI.window.screenBounds.width - 250 div: 2,
	GUI.window.screenBounds.height - 40 div: 2,
	250, 40));
~statusSl = GUI.rangeSlider.new(~statusW, Rect(10, 15, 230, 10))
	.lo_(0).hi_(0);
~numUpdates = (~voicerRows * ~voicerColumns) + 6;
~currentUpdate = 0;
~advanceStatus = {
	~currentUpdate = ~currentUpdate + 1;
	~statusSl.hi_(~currentUpdate / ~numUpdates);
};
~statusW.front;


~masterLayout = ResizeFlowWindow("control panel");
masterLayout = ~masterLayout;

~toolbarFlow = FlowView(~masterLayout.view, Rect(0, 0, 290, GUI.window.screenBounds.height-5), margin: 2@2);
(~useScroll ? false).if({
	~voicerScroll = GUI.scrollView.new(~masterLayout.view, Rect(0, 0, 450 * ~voicerColumns,
		GUI.window.screenBounds.height-50)).hasHorizontalScroller_(false);
}, {
	~voicerScroll = ~masterLayout.view;
});
~voicerFlow = FlowView(~voicerScroll, Rect(0, 0, 450 * ~voicerColumns, 20000), margin: 2@2);

GUI.staticText.new(~toolbarFlow, Rect(0, 0, 280, 20)).string_("Toolbar").align_(\center);

// voicerproxies -- creating this gui is time sensitive
// thus the remainder of the gui building is wrapped in a routine that is run on AppClock
Routine({
	var	count = 0;
	(~voicerRows * ~voicerColumns).do({ |i|
		VoicerProxy.new => VP.prNew(i);
			// first proxy has 4 controls, the rest have 3
		(3 + (count < ~voicersWith4Controls).binaryValue).do({
			VP(i).v.addControlProxy(nil, true)
		});
		count = count + 1;
		VP(i).v.maxControlProxies = VP(i).v.controlProxies.size;
		VP(i).v.smallGui(~voicerFlow, nil, nil, nil, nil, false);
		0.2.wait;
		~advanceStatus.();
		(i+1 % ~voicerColumns == 0).if({ ~voicerFlow.startRow; });
	});

~voicerFlow.recursiveResize;


// MIDI bufs

MIDIBufManager(nil, 0) => MBM.prNew(0);
MBM(0).v.gui(~toolbarFlow, Rect(0, 0, 290, 300));

// midi trigger
~toolbarFlow.startRow;
MT(1).gui(~toolbarFlow);

0.2.wait;
~advanceStatus.();

~midiControlFlow = FlowView.new(~toolbarFlow, Rect(0, 0, 80, 250), margin: 2@2);
VoicerMIDIController.defaultDest = VoicerGCDummy;
((\knob ! 8) ++ #[\mw, \pb, \touch, \xtouch, \ytouch]).do({ |type|
	var mc;
	mc = VoicerMIDIController(\omni, type);
	GUI.dragBoth.new(~midiControlFlow, Rect(0, 0, 30, 20))
		.align_(\center)
		.object_(mc).string_(mc.ccnum.shortName)
		.beginDragAction_({ |drag| drag.object })
		.action_({ |drag|
			try { drag.string_(mc.ccnum.shortName) }
		});
	mc => CC.prNew(mc.ccnum.shortName.asSymbol);
});

~midiControlFlow.startRow;

GUI.dragSink.new(~midiControlFlow, 80@20).string_("reset").align_(\center)
	.background_(Color.new255(190, 198, 225)).stringColor_(Color.new255(191, 0, 0))
	.action_({ |drag|
		try { drag.object.reset };
		drag.string = "reset";
	});

GUI.dragSink.new(~midiControlFlow, 80@20).string_("free").align_(\center)
	.background_(Color.new255(190, 198, 225)).stringColor_(Color.new255(191, 0, 0))
	.action_({ |drag|
		var	vc, vp;
		(drag.object.class == VoicerProxy).if({
			vp = drag.object;
			vc = VC.collection.detect({ |vc| vc.v === vp.voicer });
			try { vc.free }
		}, {
			try { drag.object.free };
		});
		drag.string = "free";
	});

GUI.button.new(~midiControlFlow, 80@20)
	.states_([
		["use VProxy", Color.new255(191, 0, 0), Color.new255(190, 198, 225)],
		["use Voicer", Color.new255(191, 0, 0), Color.new255(190, 198, 225)],
	])
	.value_(1)
	.action_({ |view|
		BP.useVoicerProxy = (view.value == 0);
	});
BP.useVoicerProxy = false;

0.2.wait;
~advanceStatus.();

~toolbarFlow.startRow;
s.gui(~toolbarFlow);

~toolbarFlow.startRow;

~chuckBrowser = ChuckableBrowser(~toolbarFlow);
~chuckKeyCtl = ChuckBrowserKeyController(~chuckBrowser);
chuckKeyCtl = ~chuckKeyCtl;

	// ctrl-` from gui switches focus to current document
	// any other key, if not caught by a view, switches focus back to the chuck key controller
	// and passes key thru
~masterLayout.view.keyDownAction_({ |view, char, mods, unicode, keycode|
	(unicode == 30 and: { (mods bitAnd: 0x40000) > 0 }).if({
		Document.current.front;
	}, {
		chuckKeyCtl.focus.doKey(view, char, mods, unicode, keycode);
	});
});

0.2.wait;
~advanceStatus.();

// fix views with nil keyDownActions so that bubbling will be right
// defaultKeyDownAction returns nil if it should bubble, so func should just pass the return thru
f = { |view|
		// MIDIBufManager gui uses a toggletextfield - this change to key down action breaks it
	(view.class.name != 'ToggleTextField').if({
		(view.respondsTo(\keyDownAction) and: { view.keyDownAction.isNil }).if({
			view.keyDownAction = { |view, char, modifiers, unicode, keycode|
				view.defaultKeyDownAction(char, modifiers, unicode, keycode)
			};
		});
			// nil-do is its own nil check
		view.tryPerform(\children).do(f.value(_));
	});
};

f.value(~masterLayout.view);
f = nil;

~toolbarFlow.recursiveResize;

0.2.wait;
~advanceStatus.();

//~masterLayout.recursiveResize.front;

// mixer gui slots
~board = MixingBoard("mixer control pool", Library.at(\mixer, \smallskin));
8.do({ |i| MixerChannelGUI(nil, ~board) => MCG.prNew(i);
	MixerMIDIControl(\omni, nil, MCG(i).v);
	~board.add(MCG(i).v);
});
1.0.wait;
~advanceStatus.();
~board.refresh;
1.0.wait;
~advanceStatus.();

~masterLayout.window.bounds = ~controlpanelBounds;
	// test scrollability
(~voicerScroll.respondsTo(\visibleOrigin)).if({
	~voicerScroll.bounds = ~voicerScroll.bounds.width_(305)
});
~board.w.bounds = ~mixerBounds;

Library.put(\codeBounds, ~codedocBounds);

// if Document.current is nil, then you can't do anything programmatic with documents
// so this whole bit should be skipped

if(Document.current.notNil) {
	~codedoc = Document.new("type code").bounds_(~codedocBounds);
	Document.listener.bounds = ~postwindowBounds;
	
	composeDocKeyResp = { |doc|
		var	oldKeyResp;
		oldKeyResp = doc.keyDownAction;
		doc.keyDownAction = { |doc, char, modifiers, keycode|
			(char.ascii == 30 and: { modifiers.bitAnd(0x40000) > 0 }).if({
				masterLayout.front;
			}, {
				oldKeyResp.value(doc, char, modifiers, keycode);
			});
		};
	};
	
	// enable ctrl-` for all open documents
	Document.allDocuments.do({ |doc|
		doc.isListener.not.if({
			composeDocKeyResp.(doc);
		});
	});
	
	// enable ctrl-` for new documents
	originalDocInit = Document.initAction;
	Document.initAction_({ |doc|
		originalDocInit.value(doc);
	//	doc.autoComplete;
		composeDocKeyResp.(doc);
	});
};

~statusW.close;
~statusW = ~statusSl = ~numUpdates = ~currentUpdate = ~advanceStatus = nil;
~masterLayout.front.refresh;

}).play(AppClock);

}, {
	"gui already loaded".warn;
});



// runs before initializing default midi responders
// must make sure the right device is set up as the first port

var	index;

MIDIClient.initialized.not.if({
	MIDIClient.init(MIDIPort.numPorts, MIDIPort.numPorts);

	if(Library.at(\chucklib, \midiSearches).isNil) {
		Library.put(\chucklib, \midiSearches, #["ultralite", "828"]);
	};

	block { |break|
		Library.at(\chucklib, \midiSearches).do({ |string|
			index = MIDIClient.sources.detectIndex({ |item|
				item.device.find(string, true).notNil
			});
			if(index.notNil) { break.(index) };
		});
	};
	
	index.notNil.if({
		~srcInports = [index];
	}, {
		~srcInports = nil;
	});
	
	~srcInports.debug("Index of default MIDI device");
}, {
	"MIDIClient already initialized.".postln;
});

~srcInports ?? { [] };

// General-use synthdefs
// I will keep them in a separate SynthDescLib as well as the global one

SynthDescLib(\ddwSynths, { Server.default });

~mylib = SynthDescLib.all[\ddwSynths];

SynthDef(\ctlPoint, { |outbus, value, time, curve|
	var	start = In.kr(outbus, 1);
	ReplaceOut.kr(outbus, EnvGen.kr(Env([start, value], [time], curve), doneAction: 2));
}).add(\ddwSynths);

// formerly stock synthdefs were written into the synthdefs/ folder
// but it's better to send synthdefs on demand
// so now they are stored in SynthDescLib.global
// and recalled by name when needed

SynthDef(\bufGrain, { |start, time, bufnum, rate = 1, amp = 1,
		attack = 0.001, decay = 0.02, outbus|
	var sig;
	sig = PlayBuf.ar(1, bufnum, rate * BufRateScale.kr(bufnum), 1, start, 0)
		* EnvGen.kr(Env.linen(attack, time, decay), doneAction:2);
	Out.ar(outbus, sig * amp);
}).add(\ddwSynths);

SynthDef(\bufGrainPan, { |start, time, bufnum, pan, rate = 1, amp = 1,
		attack = 0.001, decay = 0.02, outbus|
	var sig;
	sig = PlayBuf.ar(1, bufnum, rate * BufRateScale.kr(bufnum), 1, start, 0)
		* EnvGen.kr(Env.linen(attack, time, decay), doneAction:2);
	Out.ar(outbus, Pan2.ar(sig, pan, amp));
}).add(\ddwSynths);

SynthDef(\bufGrain2, { |start, time, bufnum, rate = 1, amp = 1,
		attack = 0.001, decay = 0.02, outbus|
	var sig;
	sig = PlayBuf.ar(2, bufnum, rate * BufRateScale.kr(bufnum), 1, start, 0)
		* EnvGen.kr(Env.linen(attack, time, decay), doneAction:2);
	Out.ar(outbus, sig * amp);
}).add(\ddwSynths);

SynthDef(\bufGrainPan2, { |start, time, bufnum, rate = 1, pan, amp = 1,
		attack = 0.001, decay = 0.02, outbus|
	var l, r;
	#l, r = PlayBuf.ar(2, bufnum, rate * BufRateScale.kr(bufnum), 1, start, 0)
		* EnvGen.kr(Env.linen(attack, time, decay), doneAction:2);
	Out.ar(outbus, Balance2.ar(l, r, pan, amp));
}).add(\ddwSynths);

// use a pair of enveloped PlayBufs to avoid clicks when looping back on the sample

SynthDef(\bufRoll, { |start, time = 1, bufnum, rate = 1, amp = 1, strokesPerSec = 18,
		attack = 0.002, decay = 0.01,	// attack and decay of individual stroke
		outbus|
	var	sig, envDefault, env,
		trig = Impulse.ar(strokesPerSec),
		trigs = PulseDivider.ar(trig, 2, (0..1)),
		strokeEnv = EnvGen.ar(Env.linen(attack, strokesPerSec.reciprocal - attack - decay, decay), trigs);
		// time of this env must add up to 1.0 sec
	envDefault = Env(#[0, 1, 0], #[0.001, 0.999], -4);
		// 40 == 10 possible envelope segments (which is a lot, really)
	env = Control.names(\env).kr((0 ! 40).overWrite(envDefault.asArray, 0));
	sig = (PlayBuf.ar(1, bufnum, rate * BufRateScale.kr(bufnum), trigs, start, 1) * strokeEnv).sum
		* EnvGen.ar(env, timeScale: time, doneAction:2);
	Out.ar(outbus, sig * amp);
}).add(\ddwSynths);

SynthDef(\bufRollPan, { |start, time = 1, bufnum, rate = 1, amp = 1, strokesPerSec = 18, pan = 0,
		attack = 0.002, decay = 0.01,	// attack and decay of individual stroke
		outbus|
	var	sig, envDefault, env,
		trig = Impulse.ar(strokesPerSec),
		trigs = PulseDivider.ar(trig, 2, (0..1)),
		strokeEnv = EnvGen.ar(Env.linen(attack, strokesPerSec.reciprocal - attack - decay, decay), trigs);
		// time of this env must add up to 1.0 sec
	envDefault = Env(#[0, 1, 0], #[0.001, 0.999], -4);
		// 40 == 10 possible envelope segments (which is a lot, really)
	env = Control.names(\env).kr((0 ! 40).overWrite(envDefault.asArray, 0));
	sig = (PlayBuf.ar(1, bufnum, rate * BufRateScale.kr(bufnum), trigs, start, 1) * strokeEnv).sum
		* EnvGen.ar(env, timeScale: time, doneAction:2);
	Out.ar(outbus, Pan2.ar(sig, pan, amp));
}).add(\ddwSynths);

SynthDef(\bufRollPanMove, { |start, time = 1, bufnum, rate = 1, amp = 1, strokesPerSec = 18,
		attack = 0.002, decay = 0.01,	// attack and decay of individual stroke
		panStart = 0, panEnd = 0,	outbus|
	var	sig, envDefault, env,
		trig = Impulse.ar(strokesPerSec),
		trigs = PulseDivider.ar(trig, 2, (0..1)),
		strokeEnv = EnvGen.ar(Env.linen(attack, strokesPerSec.reciprocal - attack - decay, decay), trigs);
		// time of this env must add up to 1.0 sec
	envDefault = Env(#[0, 1, 0], #[0.001, 0.999], -4);
		// 40 == 10 possible envelope segments (which is a lot, really)
	env = Control.names(\env).kr((0 ! 40).overWrite(envDefault.asArray, 0));
	sig = (PlayBuf.ar(1, bufnum, rate * BufRateScale.kr(bufnum), trigs, start, 1) * strokeEnv).sum
		* EnvGen.ar(env, timeScale: time, doneAction:2);
	Out.ar(outbus, Pan2.ar(sig, Line.kr(panStart, panEnd, time), amp));
}).add(\ddwSynths);

SynthDef(\bufRollPanChangeRate, { |start, time = 1, bufnum, rate = 1, amp = 1,
		strokeRateStart = 18, strokeRateEnd = 18,
		attack = 0.002, decay = 0.01,	// attack and decay of individual stroke
		panStart = 0, panEnd = 0,	outbus|
	var	sig, envDefault, env,
		strokesPerSec = XLine.kr(strokeRateStart, strokeRateEnd, time),
		trig = Impulse.ar(strokesPerSec),
		trigs = PulseDivider.ar(trig, 2, (0..1)),
		strokeEnv = EnvGen.ar(Env.linen(attack, strokesPerSec.reciprocal - attack - decay, decay), trigs);
		// time of this env must add up to 1.0 sec
	envDefault = Env(#[0, 1, 0], #[0.001, 0.999], -4);
		// 40 == 10 possible envelope segments (which is a lot, really)
	env = Control.names(\env).kr((0 ! 40).overWrite(envDefault.asArray, 0));
	sig = (PlayBuf.ar(1, bufnum, rate * BufRateScale.kr(bufnum), trigs, start, 1) * strokeEnv).sum
		* EnvGen.ar(env, timeScale: time, doneAction:2);
	Out.ar(outbus, Pan2.ar(sig, Line.kr(panStart, panEnd, time), amp));
}).add(\ddwSynths);


SynthDef(\bufGrainRLPF, { |start, time, bufnum, rate = 1, amp = 1,
		attack = 0.001, decay = 0.02, ffreq = 2000, rq = 1, outbus|
	var sig;
	sig = PlayBuf.ar(1, bufnum, rate * BufRateScale.kr(bufnum), 1, start, 0)
		* EnvGen.kr(Env.linen(attack, time, decay), doneAction:2);
	sig = RLPF.ar(sig, ffreq, rq);
	Out.ar(outbus, sig * amp);
}).add(\ddwSynths);

SynthDef(\bufGrainRLPF2, { |start, time, bufnum, rate = 1, amp = 1,
		attack = 0.001, decay = 0.02, ffreq = 2000, rq = 1, outbus|
	var sig;
	sig = PlayBuf.ar(2, bufnum, rate * BufRateScale.kr(bufnum), 1, start, 0)
		* EnvGen.kr(Env.linen(attack, time, decay), doneAction:2);
	sig = RLPF.ar(sig, ffreq, rq);
	Out.ar(outbus, sig * amp);
}).add(\ddwSynths);

SynthDef(\bufGrainRLPFPan, { |start, time, bufnum, rate = 1, amp = 1,
		attack = 0.001, decay = 0.02, pan = 0, ffreq = 2000, rq = 1, outbus|
	var sig;
	sig = PlayBuf.ar(1, bufnum, rate * BufRateScale.kr(bufnum), 1, start, 0)
		* EnvGen.kr(Env.linen(attack, time, decay), doneAction:2);
	sig = RLPF.ar(sig, ffreq, rq);
	Out.ar(outbus, Pan2.ar(sig, pan, amp));
}).add(\ddwSynths);


// figure out rollPan and 2-channel versions later

SynthDescLib.all[\ddwSynths].synthDescs.do({ |desc|
	SynthDescLib.global.add(desc);		// copy into the global lib
});


// Initially my idea is that the user would be responsible for sending the defs
// to the server when needed. But this broke too many of my tracks,
// so I'm adding a dependant to servers to send the synthdefs on boot.
// Feel free to comment this out if you don't like it.

Updater(Server, { |obj, what, newServer|
	if(what == \serverAdded) {
		Updater(newServer, { |obj, what|
			if(what == \serverRunning and: { obj.serverRunning }) {
				SynthDescLib.all[\ddwSynths].synthDescs.do({ |desc|
					desc.def.send(obj);
				});
			};
		});
	};
});

Server.named.do({ |svr| Server.changed(\serverAdded, svr) });



// check SynthDescLib behavior for polySynthPlayer
// polysynthplayer / trigger support for array args
// voicer note must either have delta, length, gate specified or a single note as input - trying to get parms from array notes breaks
// add repetition-factor metric to adaptSeg
// note for doc: asNotePattern is needed because sometimes I want streams that return SequenceNotes,
// not events


// process prototypes

// start with the abstract

Proto({
	// environment variables supplied by "subclasses"
	// ~event, ~prep, ~stopCleanup, ~freeCleanup, ~preparePlay

	~event = (eventKey: \default);

	~bindPatDefault = \a;	// aPattern, aStream -- clones should override

		// mainly used for adaptPattern, but other uses are conceivable
	~bindPattern = #{ |pat, adverb|
		adverb = adverb ? ~bindPatDefault;
		currentEnvironment.put(adverb.asSymbol, pat = pat.asPattern);
		currentEnvironment.put((adverb ++ "Stream").asSymbol, pat.asStream);
		currentEnvironment
	};

	~bindSymbol = #{ |sym, adverb|
		var	pat;
		((pat = Pdefn(sym)).pattern != Pdefn.default).if({
				// asPattern gets called in ~bindPattern
			~bindPattern.value(pat, adverb)
		}, {
			~bindPattern.value(sym, adverb)
		});
		currentEnvironment
	};
	
		// special case for Synth Args
	~bindSA = #{ |sa, adverb|
		~argsStream = sa.asPattern.asStream;
		~argKeys = sa.argKeys;
		currentEnvironment
	};

		// these next two are deprecated -- BPStream(key) is a better solution
		// retained for backward compatibility

	~makeStreamForKey = #{ |key, streamKey|
			// output, and stream gets replaced so that playing stream picks it up:
		(streamKey = streamKey ?? { key ++ "Stream" }).asSymbol.envirPut(key.envirGet.asStream)
	};

	~makeProut = #{ |key, reset|
		var	streamKey;
			// create stream if it doesn't exist
		streamKey = (key ++ "Stream").asSymbol;
		(streamKey.envirGet.isNil or: { reset ? true }).if({
			~makeStreamForKey.value(key, streamKey);
		});

		Prt({ |inEvent|
			{ inEvent = streamKey.envirGet.next(inEvent).yield }.loop
		});
	};
	
		// temporary override of a pattern used with BPStream
		// ref means, if the pattern returns a symbol, look up the target stream
		// revertAction is run when control returns to the main stream
	~override = { |key, pat, ref = true, revertAction|
		var	streamkey = (key ++ "Stream").asSymbol,
			savekey = ("save" ++ streamkey).asSymbol,
			overkey = ("override" ++ streamkey).asSymbol,
			overstream;

		savekey.envirGet.isNil.if({
			savekey.envirPut(streamkey.envirGet);
		});
		
		overkey.envirPut(pat.asStream);

			// need a variant on cleanupstream that will seamlessly hand control back
			// to the original stream; cleanupstream returns nil and stops the parent stream
		overstream = Routine({ |inval|
			var	nextval;
			while { (nextval = overkey.envirGet.next(inval)).notNil }
				{	ref.if({
						(nextval.isSymbol and: { nextval.envirGet.notNil }).if({
							inval = nextval.envirGet.next(inval).yield;
						}, { inval = nextval.yield; });
					}, {
						inval = nextval.yield;
					});
				};
					// end of the line; restore the original stream
					// and return 1 valid value so that the main pattern doesn't die
					// after substitution, this routine will not get called again
			streamkey.envirPut(savekey.envirGet);
			savekey.envirPut(nil);
			overkey.envirPut(nil);
			revertAction.value;
			streamkey.envirGet.next(inval).yield;
		});
		
		streamkey.envirPut(overstream);

		currentEnvironment
	};

	~midiParse = true;		// flag whether to group notes together or use the midi buf as is
						// parsing is better for adaptive sequencing objects

	~canWrap = false;
	
	~isPlaying = false;
	~isWaiting = false;
	~isDriven = false;

}) => PR(\abstractProcess);


// one shot PR - sets a base barline in the global library

Proto({
	~barLength = 4;
	~path = #[baseBeat];	// may override
		// run this action when resuming rhythmic patterns
	~doAction = { |path|
		var	beats = ~barLength.nextTimeOnGrid(thisThread.clock);
		Library.global.putAtPath(path ? ~path, beats);
		thisThread.clock.setMeterAtBeat(~barLength, beats);
	};
	~freeCleanup = { 
		Library.global.removeAtPath(~path)
	};
}) => PR(\setBase);


// basic events first

(play:0) => ProtoEvent(\dummy);

// the default event handles latency differently from BP
Event.default.copy => ProtoEvent(\default);

// Event uses functions to schedule message sends according to timingOffset
// copy these functions into Func repository for these events

Event.default[\schedBundle] => Func(\basicSchedBundle).subType_(\eventHelper);
Event.default[\schedBundleArray] => Func(\basicSchedBundleArray).subType_(\eventHelper);
Event.default[\schedStrummedNote] => Func(\basicSchedStrummedNote).subType_(\eventHelper);


{ |lag, offset, server ...bundle|
	(~immediateOSC ? false).if({
		server.sendBundle(nil, *bundle)
	}, {
		Func(\basicSchedBundleArray).value(lag, offset, server, bundle)
	});
} => Func(\schedEventBundle).subType_(\eventHelper);

{ |lag, offset, server, bundleArray|
	(~immediateOSC ? false).if({
		server.sendBundle(nil, *bundleArray)
	}, {
		Func(\basicSchedBundleArray).value(lag, offset, server, bundleArray)
	});
} => Func(\schedEventBundleArray).subType_(\eventHelper);

Event.default[\schedStrummedNote] => Func(\schedEventStrummedNote).subType_(\eventHelper);


(grain: false,
timingOffset: 0,
setTarget: {
	~chan.notNil.if({
		~target = (~isFx ? false).if({ ~chan.effectgroup },
			{ ~chan.synthgroup });
		~server = ~target.server;
		~bus = ~chan.inbus;
		~busindex = ~bus.index;
	}, {
		~target.isNil.if({
			~target = Server.default.asTarget;
		});
		~server = ~target.server;
		~bus.notNil.if({
			~bus = ~bus.asBus;
			~busindex = ~bus.index;
		}, {
			~busindex = 0;
		});
	});
},
setArgs: {
	var	args, soloargs, polyargs, lib, desc;
	((lib = SynthDescLib.all[~lib ? \global]).notNil
			and: { (desc = lib[~instrument.asSymbol]).notNil }).if({
		~hasGate = desc.hasGate;
		args = desc.msgFunc.valueEnvir;	// not .flopping because this is SINGLE synth player
	}, {
		args = Array.new(currentEnvironment.size*2);
		currentEnvironment.keysValuesDo({ |key, value|
			value.isValidSynthArg.if({ args.add(key).add(value) });
		});
	});
	~args = args.asOSCArgArray;
},
makeNode: {
	var	args, nodeID, server, sustain,
		tempo = ~clock.tryPerform(\tempo) ? 1.0,
		bundle,
		lag = ~lag ? 0,
		offset = ~timingOffset ? 0,
		releaseGate = ~releaseGate ? 0;
	((~instrument != \rest) and: { ~freq != \rest and: { ~type != \rest } }).if({
		~setTarget.value;
		~busindex.notNil.if({
			server = ~server;	// for ~trace == true
			~setArgs.value;
(~debug == true).if({
//thisThread.clock.debug("my clock");
 thisThread.clock.beats.debug("\nnow"); ~args.debug("singleSynthPlayer"); });
			~grain = ~grain ? false;
			nodeID = ~grain.if({ -1 }, { ~server.nextNodeID });
			~node = Synth.basicNew(~instrument, ~server, nodeID);
			bundle = [~node.newMsg(~target, ~args ++ [\outbus, ~busindex, \out, ~busindex,
				\i_out, ~busindex], \addToTail)];
			Func(\schedEventBundleArray).doAction(lag, offset, server, bundle);
(~trace == true).if({
	Func(\schedEventBundle).doAction(lag + 0.05, ~timingOffset, server, [\n_trace, nodeID]);
});
			(~grain.not and: { ~hasGate ? false and: { (sustain = ~sustain.value).notNil } }).if({
				thisThread.clock.sched(sustain, {
					Func(\schedEventBundle).doAction(lag, offset, server,
						[\n_set, nodeID, \gate, releaseGate]);
				});
			});
		});
	});
},
play: {
	~makeNode.value;
	(~collIndex.notNil and: { ~grain.not }).if({
		~notifyDependents.value;
	});
}) => ProtoEvent(\singleSynthPlayer);

ProtoEvent(\singleSynthPlayer).v.copy.putAll((
	notifyDependents: {
		BP(~collIndex).v.recvEventNotify(~node, currentEnvironment);
	}
)) => ProtoEvent(\singleSynthPlayNotify);

	// backward compatibility
ProtoEvent(\singleSynthPlayNotify).v => ProtoEvent(\bufStatusUpdate);


ProtoEvent(\singleSynthPlayer).v.copy.putAll((play: {
	var args, nodeID, msg, bundle, tempo = ~clock.tryPerform(\tempo) ? 1.0;
		// the full condition is needed for Ppar which uses ~freq == \rest
	(~node != \rest and: { ~instrument != \rest and: { ~freq != \rest and: { ~type != \rest } } }).if({
		~lag ?? { ~lag = 0 };
		~node = ~node.value;
		~instrument = ~node.defName;
		~setArgs.value;
		msg = [~node.setMsg(*~args)];
		Func(\schedEventBundleArray).doAction(~lag, ~timingOffset, ~node.server, msg);
		(~debug ? false).if({
			msg.debug("singleSynthTrigger")
		});
	})
})) => ProtoEvent(\singleSynthTrigger);

ProtoEvent(\singleSynthPlayer).v.copy.putAll((
setArgs: {
	var	args, lib, desc;
	((lib = SynthDescLib.all[~lib ? \global]).notNil
			and: { (desc = lib[~instrument.asSymbol]).notNil }).if({
		~args = desc.msgFunc.valueEnvir.clump(2);
	}, {
		args = Array.new(currentEnvironment.size);
			// note that this is a clumped array --
			// that's necessary for flopping (multichannel expanding) the args out in makeNode
		currentEnvironment.keysValuesDo({ |key, value|
			value.isValidVoicerArg.if({ args.add([key, value]) });
		});
		~args = args;
	});
},
play: { var args, nodeID;
	(~node != \rest and: { ~instrument != \rest and: { ~freq != \rest and: { ~type != \rest } } }).if({
		~lag ?? { ~lag = 0 };
		~node = ~node.value;
			// assumed to be the same synthdef for each
			// maybe not a safe assumption but a reasonable limitation for now
		~instrument ?? { ~instrument = ~node.asArray.first.defName };
		~setArgs.value;
		~args = ~args.collect(_.flop).flop.collect({ |subarray| subarray.flatten(1).asOSCArgArray });
		~node.do({ |node, i|
			Func(\schedEventBundle).doAction(~lag, ~timingOffset, node.server,
				node.setMsg(*~args.wrapAt(i)));
		});
	})
})) => ProtoEvent(\polySynthTrigger);


// Seems to work but might need some more testing
// currently does not support multiple output buses - maybe it does now?
// but there should be just 1 instrument

ProtoEvent(\singleSynthPlayer).v.copy.putAll((
	setTarget: {
		~chan.notNil.if({
			~chan = ~chan.asArray;
			~target = ~chan.collect({ |chan|
				(~isFx ? false).if({ chan.effectgroup },
					{ chan.synthgroup });
			});
			~server = ~target.collect(_.server);
			~bus = ~chan.collect(_.inbus);
		}, {
			~target.isNil.if({
				~target = Server.default.asTarget;
			});
			~target = ~target.asArray;
			~server = ~target.collect(_.server);
			~bus.notNil.if({
				~bus = ~bus.asArray.collect(_.asBus);
			}, {
				~bus = ~server.collect({ |server| Bus(\audio, 0, 2, server) });
			});
		});
	},
	checkbuses: {
		block { |break|
			~bus.do({ |bus|
				bus.tryPerform(\index).isNumber.not.if({ break.(false) });
			});
			true
		}
	},
	setArgs: {
		var	args, lib, desc;
		((lib = SynthDescLib.all[~lib ? \global]).notNil
				and: { (desc = lib[~instrument.asSymbol]).notNil }).if({
			~args = desc.msgFunc.valueEnvir.clump(2);
			~hasGate = desc.hasGate;
		}, {
			args = Array.new(currentEnvironment.size);
				// note that this is a clumped array --
				// that's necessary for flopping (multichannel expanding) the args out in makeNode
			currentEnvironment.keysValuesDo({ |key, value|
				value.isValidVoicerArg.if({ args.add([key, value]) });
			});
			~args = args;
		});
	},
	makeOneNode: { |i, strum|
		var	instr, nodeID, latency, sustain, server = ~server.wrapAt(i), offset = ~timingOffset ? 0,
			releaseGate = ~releaseGate ? 0;
		((instr = ~instrument/*.wrapAt(i)*/) != \rest).if({
			nodeID = ~grain.if({ -1 }, { server.nextNodeID });
			~node[i] = Synth.basicNew(instr, server, nodeID);
			latency = (strum*i) + ~lag;
			Func(\schedEventBundle).doAction(latency, offset, server,
				~node[i].newMsg(~target.wrapAt(i), 
					~args.wrapAt(i) ++ [\out, ~bus.wrapAt(i).index,
					\i_out, ~bus.wrapAt(i).index, \outbus, ~bus.wrapAt(i).index],
					\addToTail)
			);
			(~grain.not and: { (~hasGate ? false) and: { (sustain = ~sustain.value).notNil } }).if({
				thisThread.clock.sched(sustain, {
					Func(\schedEventBundle).doAction(latency, offset, server,
						[\n_set, nodeID, \gate, releaseGate]);
				});
			});
		});
	},
	makeNode: {
		var args, instr, nodeID, strum, latency;
		(~instrument != \rest and: { ~type != \rest }).if({
			~lag ?? { ~lag = 0 };
			~setTarget.value;
			~checkbuses.value.if({
//				~instrument = ~instrument.asArray;
				~setArgs.value;
				~args = ~args.collect(_.flop).flop.collect({ |subarray| subarray.flatten(1).asOSCArgArray });
				strum = ~strum ? 0;
				~grain = ~grain ? false;
				~node = Array.newClear([/*~instrument.size,*/ ~args.size, ~bus.size,
					~target.size].maxItem);
					// ~makeOneNode populates the right slot in ~node array
				~node.size.do({ |i| ~makeOneNode.(i, strum) });
			});
		});
	}
)) => ProtoEvent(\polySynthPlayer);

ProtoEvent(\polySynthPlayer).v.copy.putAll((
	notifyDependents: {
		BP(~collIndex).v.recvEventNotify(~node, currentEnvironment);
	}
)) => ProtoEvent(\polySynthPlayNotify);

// voicer events (for ai sequencing):

(	timingOffset: 0,
	stretch: 1.0,
	// args: [],
		// maybe you want to use non-equal-temperament. override this func
		// or, if you are using modally-mapped values, include the cpsFunc or EqualTemperament derivative
		// in the ModalSpec itself
	midiNoteToFreq: #{ |notenum|
		~mode.notNil.if({ ~mode.asMode.cpsFunc.value(notenum) },
			{ notenum.midicps });
	},
	
	prepNote: #{
		var i, args, argval, thisEvent = currentEnvironment;
		~newFreq = ~freq ?? { ~note.asFloat };
		~mtranspose.notNil.if({ ~newFreq = ~newFreq + ~mtranspose });
		(~midi ? false).not.if({ ~newFreq = ~newFreq.unmapMode(~mode.asMode) });
		~ctranspose.notNil.if({ ~newFreq = ~newFreq + ~ctranspose });

		~newFreq = ~midiNoteToFreq.value(~newFreq).asArray;
		~dur = ~dur ?? { ~delta ?? { ~note.dur } };
		~length = (~length ?? { ~note.length }).asArray;
		
			// some patterns (e.g. Pfindur) might shorten the delta
			// in which case length could be too long
			// but this really applies only to MonoPortaVoicers,
			// hence the adjust... test
		if(~adjustLengthToRealDelta.value and: { ~dur != currentEnvironment.delta }) {
			~length = ~length * currentEnvironment.delta / ~dur;
		};
		
		~args = ~args ?? { [~note.tryPerform(\args)].tryPerform(\flatten, 1) } ?? { [] };
		i = 0;	// args should be key value pairs, but might be an array of velocities
				// drop pairs that are not \symbol, value
		{ i < ~args.size }.while({
			~args[i].isSymbol.not.if({
				try { ~args.removeAt(i); ~args.removeAt(i); };
			}, {
				i = i + 2;	// should increment only if not removing an item
			});
		});
		
		~gate = (~gate ?? { ~note.gate }).asArray;
		
			// for args array to be valid (argName, value pairs), must have at least 2 items
		(~args.size < 2).if({ ~args = nil });
		~voicer !? {
			~nodes = ~voicer.prGetNodes(max(~newFreq.size, max(~length.size, ~gate.size)));
			~voicer.setArgsInEvent(currentEnvironment);
		};
		~bassID.notNil.if({
			~note ?? { ~note = SequenceNote(~freq, ~dur, ~length[0], ~gate[0]) };
			Library.put(~bassID, ~note);
				// allow this thread to finish before alerting dependents
			thisThread.clock.sched(0, { BP.changed(thisEvent[\bassID], thisEvent); });
		});
	},
	
	play: #{
		var	lag = ~lag ? 0,  // ~timingOffset !? { ~timingOffset / ~clock.tempo };
			timingOffset = ~timingOffset ? 0,
			clock = ~clock,
			voicer = ~voicer,
			bundle, releaseGate;
		(~debug == true).if({
			"\n".debug;
			["voicerNote event", ~clock.beats, ~clock.tempo].debug;
			currentEnvironment.collect({ |value| value.isFunction.not.if(value, nil) }).postcs;
		});
		~prepNote.value;
		~finish.value;	// user-definable
		releaseGate = (~releaseGate ? 0).asArray;
		~nodes.do({ |node, i|
			var	freq = ~newFreq.wrapAt(i), length = ~length.wrapAt(i);
			Func(\schedEventBundleArray).doAction(lag, ~timingOffset, node.server,
				node.server.makeBundle(false, {
					node.trigger(freq, ~gate.wrapAt(i), ~args.wrapAt(i), node.server.latency);
				}));
			(length.notNil and: { length != inf }).if({
					// can't use schedEventBundle
					// because you must not release the VoicerNode
					// until the proper time comes
				thisThread.clock.sched(length + timingOffset, {
					voicer.releaseNode(node, freq, releaseGate.wrapAt(i),
						lag + (node.server.latency ? 0));
				});
			});
		});
	},
		// for live midi input -- assumes midi note has been put into ~note
	releaseNote: #{
		((~immediateOSC ? false) or: { ~voicer.target.server.latency.isNil }).if({
			~voicer.release(~newFreq);
		}, {
			~voicer.release(~newFreq,
				((~lag + ~timingOffset) / ~clock.tempo) + ~voicer.target.server.latency);
		});
	},
	
		// you could override this
	adjustLengthToRealDelta: { ~voicer.isKindOfByName(\MonoPortaVoicer) },
	
	keysToPropagate: #[\voicer, \midi, \mode, \timingOffset, \argKeys, \immediateOSC]
) => ProtoEvent(\voicerNote);

// synthNote
ProtoEvent(\voicerNote).v.copy.putAll((
	play: #{
		var	synthLib;
			// cribbed from Event.default
		if (~msgFunc.isNil) {
			synthLib = ~synthLib ?? { SynthDescLib.global };
			~desc = synthLib.synthDescs[~instrument];
			if (~desc.notNil) { 
				~hasGate = ~desc.hasGate;
				~msgFunc = ~desc.msgFunc;
			}{
				~hasGate = ~hasGate ? true;
				~msgFunc = ~defaultMsgFunc;
			};
		}{
			~hasGate = ~hasGate ? true;
		};	// end crib
		~prepNote.value;
		~finish.value;	// user-definable
		~lag ?? { ~lag = 0 };
		(~freq.isSymbol.not and: { ~desc.notNil }).if({
			(~freq.size > 0).if({
				(~gate.size == 0).if({ ~gate = [~gate] });
				(~length.size == 0).if({ ~length = [~length] });
				~freq.do({ |freq, i|
					~playOneNote.value(freq, ~gate.wrapAt(i), ~length.wrapAt(i));
				});
			}, {
				~playOneNote.value(~freq, ~gate, ~length)
			});
		});
	},
	
	playOneNote: #{ |freq, gate, length|
		var	synth, server, groupbus;
		server = ~server ? ~target.server;
		synth = Synth.basicNew(~instrument, server);
			// if groupbus is not nil, then ~target is a MixerChannel
		(groupbus = ~target.tryPerform(\groupBusInfo)).notNil.if({
			Func(\schedEventBundle).doAction(~lag, ~timingOffset, server, synth.newMsg(groupbus[0],
					~args ++ [\outbus, groupbus[1], \out, groupbus[1],
					\freq, freq, \gate, gate], \addToTail));
		}, {
			Func(\schedEventBundle).doAction(~lag, ~timingOffset, server, synth.newMsg(~target,
					~args ++ [\outbus, ~out, \out, ~out, \freq, freq, \gate, gate], \addToTail));
		});
		~hasGate.if({
			Func(\schedEventBundle).doAction(~lag + length, ~timingOffset, synth.server,
				synth.setMsg(\gate, ~releaseGate ? 0));
		});
	},
	
	releaseNote: nil,
	
	keysToPropagate: #[\instrument, \target, \midi, \mode, \timingOffset]
)) => ProtoEvent(\synthNote);


// event for a melody wrapper
(	play: #{
		(~debug == true).if({
			thisThread.beats.debug("\nchord trigger event"); currentEnvironment.debug;
		});
		~preAction.value;	// maybe some kind of cleanup?
		~getTopNoteNum.value;
			// nil is legit if there is no topnote pattern
		(~topNoteNum.isNumber or: { ~topNoteNum.isNil }).if({
			(~midi ? false).if({
				~length = inf;	// should not terminate except by midi note
			}, {
					// not needed here but included for subclasses
					// if previous child stream needs to be stopped, do it in ~finish
				~finish.value;
				~length = ~length ? ~delta;
			});
				// start it at the current logical time
			~clock.sched(0, ~makeChildStream.value);
			NotificationCenter.notify(~child, \runChild, currentEnvironment);
		});
	},
	getTopNoteNum: {
		~topNoteNum = ~top.tryPerform(\at, \freq)
			?? { ~top.tryPerform(\at, \note).tryPerform(\freq) };
	},
	makeChildStream: {
		var childStreamTemp, childEvent, child = ~child;
			// create a new stream and put it in the environment
			// child stream needs to know the current event, so it's passed to asPattern

			// downward propagation - responsibility of wrapper
		~propagateDownward.value;
		(childEvent = ~child[\event]).parent = ProtoEvent(childEvent[\eventKey]).v;

		~child.preparePlay;
		childStreamTemp = ~wrapPattern.value(~child.asPattern(currentEnvironment));
			// child stream should run within the child environment
		~child.use({ childStreamTemp = childStreamTemp.asStream });
		~child.put(\eventStream, CleanupStream(childStreamTemp,
				// maybe somebody else needs to know that you stopped?
				// this doesn't handle manual stop, but parent should stop too
			{ NotificationCenter.notify(child, \childStop); }
		));

		~child.put(\eventStreamPlayer, childStreamTemp = EventStreamPlayer(
			~child.eventStream,
			childEvent
		).refresh);
		childStreamTemp	// return new ESP
	},
	finish: #{
		(~stopChild ? true).if({
			~child.eventStreamPlayer.stop;
		});
	},
	wrapPattern: #{ |pattern|
		pattern	// simply return pattern, unmodified
	},
	keysToPropagate: #[\midi]
) => ProtoEvent(\melWrap);


// melody wrapper event that pauses the parent
// the parent must register a notification for the childStop event so that it can resume when the child is done
// this supports wrapping a melody whose length is not known at play start time

ProtoEvent(\melWrap).v.copy.make({
	~finishSuper = ~finish;
	~finish = {
		~finishSuper.value;
			// user must supply eventstreamplayer
			// this breaks the contract vis-a-vis circular references
		~myThread.pause;
	};
}) => ProtoEvent(\melWrapEmbed);


// macrorhythm protoevent
// dur and length should be populated
// note may contain topNote, but it's up to the child process to use it
// how to use inheritance on a protoevent:
ProtoEvent(\melWrap).v.copy.make({
		// should only be called inside the event
	~wrapPattern = #{ |pattern|
		(~length != inf).if({
			pattern = Pfindur(~length-0.01, pattern);
		}, {
			pattern
		});
	};
	
	~getChord = true;	// default; midi input may override -- used??
	
	~keysToPropagate = #[\mode, \midi];
}) => ProtoEvent(\macroRh);


// a general-purpose singleSynthPlayer process

PR(\abstractProcess).v.clone({
	~event = (eventKey: \singleSynthPlayer);

	~inChannels = 2;
	~outChannels = 2;
		// you may specify a server at chuck time
		// but DO NOT save a server into a prototype
		// because, when you do PR => BP, the server gets copied
		// and that messes up a whole lot of stuff
		// to avoid that trouble, give the server as a Function
		// because a Function's return value isn't copied
		// this is used for initialization only,
		// and not used if you give a MixerChannel as ~master
//	~server = { Server.default };

		// synthdef preparation might depend on the mixerchannel and user-defined resources
		// note the order of initialization carefully
	~prep = {
		var	server = ~master.tryPerform(\server) ?? {
				~server.value ?? { Server.default } };
		if(SynthDescLib.global.servers.value.asArray.includes(server).not) {
			SynthDescLib.global.addServer(server);
		};
		if(~chan.isNil) {
			~chan = MixerChannel(~collIndex, server, ~inChannels, ~outChannels,
				outbus: ~master, completionFunc: { |chan|
					~userpreps.do(_.value);
					~userprep.value;		// preparation specified in chuck parameters
					~makeSynthDefs.value;
				});
		} {
			~iMadeChan = false;
			~userpreps.do(_.value);
			~userprep.value;		// preparation specified in chuck parameters
			~makeSynthDefs.value;
		};
	};

	~delta = 1.0;
		// by default, delta and sustain will have the same value
	~sustain = Pkey(\delta);
	~synth = Pfunc({ ~objects.keys.choose });
	
		// when you clone, if you need extra preparation, do ~userpreps = ~userpreps.copy.add({  ... });
	~userpreps = List.new;
	
		// chuck-time parameter for user preparation
	~userprep = nil;
	
		// ~objects is a dictionary
		// key --> dict; outer key is the identifier for the synth that will be used in the synth pattern
		// dict = (def: definition, args: [arg1: Pattern1, arg2: pattern2...])
		// definition is a function, Patch or SynthDef
	~objects = (
		default: (def: \default, args: [
			freq: PdegreeToKey(Pwhite(35, 50, inf), #[0, 2, 4, 5, 7, 9, 11], 12).midicps
		])
	);

		// support code follows
	~makeSynthDefs = { 
		~objects = ~objects.value;
		~objects.keysValuesDo({ |id, def|
			def[\synthdef].isNil.if({
				~makeOneSynthDef.(id, def);
			});
		});
	};

	~makeOneSynthDef = { |id, def|
		var	sdef, reference;
			// allow references to other items in ~objects
			// that is, you can reuse a patch but supply a different argument array
		if(def[\def].isSymbol
				and: { (reference = ~objects[def[\def]]).notNil
				and: { reference !== def } }) {
				// has the reference already been prepared?
			reference[\synthdef].isNil.if({
				~makeOneSynthDef.(def[\def], reference);
			});
			def[\synthdef] = reference[\synthdef];
			def[\name] = reference[\name];
				// no need to resend synthdef
		} {
			sdef = ~makeDefForObject.(def[\def], id);
			def[\synthdef] = sdef;
			def[\name] = sdef.tryPerform(\name) ? sdef;
			sdef.tryPerform(\send, ~chan.server);
			sdef.tryPerform(\add);
		};
		~prepareArgsForOneDef.(id);
	};

	~makeDefForObject = #{ |obj, id|
		var return, reference;
		(return = ~classActions[obj.class.name]).notNil.if({
			return = return.envirGet.(obj, id)
		});
		return ?? { obj }	// if nothing, return the object itcurrentEnvironment
	};
	~makeFnDef = #{ |fn|
		fn.asSynthDef(outClass: (~isFx ? false).if({ \ReplaceOut }, { \Out }));
	};
	~makePatchDef = #{ |patch, id|
		var	sdef; // = patch.asSynthDef;
		sdef = patch.asSynthDef;
			// I saw a scenario where InstrSynthDef did not come up with a unique name based on args
			// dictionary id must be unique to this BP
			// might have the same ID with different args in different BPs, so add the BP's ID
		sdef.name = ~collIndex ++ id;
		sdef
	};
	~makeSynthDef = #{ |def| def };
	~classActions = IdentityDictionary[
		'SynthDef' -> \makeSynthDef,
		'Function' -> \makeFnDef,
		'Patch' -> \makePatchDef,
		'WrapPatch' -> \makePatchDef,
		'FxPatch' -> \makePatchDef
	];

	~prepareArgsForOneDef = { |id|
		var	streamarray = Array.new(~objects[id][\args].size), fullname;
		~objects[id][\args].pairsDo({ |name, pattern|
				// assigning a Pattern to a BP environment variable automatically creates the stream
			fullname = (id ++ name).asSymbol;
			fullname.envirPut(pattern.asPattern);
			streamarray.add(name).add(BPStream(fullname).asStream);
		});
		~objects[id][\argStreams] = streamarray;
	};

	~basePattern = { 
		(~debug ? false).if(DebugPbind, Pbind)
		.new(
			\synthKey, BPStream(\synth),
			\delta, BPStream(\delta),
			\sustain, BPStream(\sustain),
			\instrument, Pfunc({ |ev|
				(ev[\synthKey] == \rest).if({ \rest },
					{ ~objects[ev[\synthKey]].tryPerform(\at, \name) ? \rest })
			}),
			\chan, ~chan
		)
	};

	~asPattern = { 
		~basePattern.value.collect({ |ev|
			(ev[\synthKey] != \rest).if({
				~getUserArgs.(ev);
			}, { ev });
		});
	};
	
	~getUserArgs = { |event|
		var key = event[\synthKey], streamout;
		block { |break|
			~objects[key][\argStreams].pairsDo({ |name, stream|
				(streamout = stream.next(event)).isNil.if({
					if(~debug ? false) {
						"% stream was nil, stopping".format(name.asCompileString).warn;
					};
					break.(nil);	// early exit with nil result to stop main stream
				}, {
					(~debug ? false).if({
						[name, streamout].debug("user arg");
					});
					(name.isSequenceableCollection).if({
						name.do({ |n, i| event[n] = streamout[i] })
					}, {
						event[name] = streamout;
					});
				});
			});
			event
		}
	};
	
		// when you clone, if you need extra preparation, do ~userfrees = ~userfrees.copy.add({  ... });
	~userfrees = List.new;
	
		// chuck-time parameter for user preparation
	~userfree = nil;
	
	~freeCleanup = { 
		if(~iMadeChan ? true) { ~chan.free };
			// should free patches
		~objects.do({ |def|
			try {
				def[\def].isKindOf(AbstractPlayer).if({ def[\def].free });
			};
		});
		~userfree.value;
		~userfrees.do(_.value);
	};

}) => PR(\basicSynthChooser);



// framework for adaptive processes

var saveSubType = AbstractChuckArray.defaultSubType;
AbstractChuckArray.defaultSubType = \melodyStorage;

// first, handler for a single segment -- this will be analyzed modally
Proto({
		// canPauseAfter is deprecated for a more OO solution
	~prepare = #{ |notes, nextNote, storage, parms, rawMIDI = true|
			// notes should be in the format [note, note, note]
		var	mode = parms.atBackup(\mode, storage) ? \default;
		~notes = notes.asArray;
		~nextNote = nextNote;	// final interval should be calculated relative to the next note
		{ (rawMIDI ? true).if({ ~mapToMode.value(mode) }, {
			~mode = (mode.size > 0).if({ mode[0] }, { mode });
			});
		}.try({ |error|
			Error("Error translating MIDI to modal. Check to see if default mode is defined.")
				.throw;
		});
		~modeSubstitution = parms.atBackup(\modeSub, storage);
		~analyzeNotes.value(rawMIDI);	// collect stats on chord -- user definable
		currentEnvironment
	};
	
	~mapToMode = #{ |mode|
		var	bestMode, bestFit = -1e10, bestMap, modeFit, notesTemp, modeObj;
		mode = mode ? \default; 	// keep symbol for storage
		modeObj = mode.asMode;
			// is it a single mode, or a mode pool?
		if(modeObj.size > 0) {
			modeObj.do({ |mode, i|
				notesTemp = ~notes.mapMode(mode);
				((modeFit = Func(\chModeFit).doAction(notesTemp)) > bestFit).if({
					bestMode = mode;
					bestFit = modeFit;
					bestMap = notesTemp;
				});
			});
			~mode = bestMode;
			~notes = bestMap;
			~nextNote = ~nextNote.mapMode(bestMode)
		}{
			~notes = ~notes.mapMode(mode);
			~nextNote = ~nextNote.mapMode(mode);
			~mode = mode;
		};
		currentEnvironment
	};
	
	~mapToMIDI = #{ |mode|
		~notes = ~notes.unmapMode(mode ?? { ~mode ? \default });
		~nextNote = ~nextNote.unmapMode(mode ?? { ~mode ? \default });
		currentEnvironment
	};
	
// subclasses must implement:
//	~analyzeNotes (if needed)
//	~asPattern
}) => PR(\abstractModeSeg);

PR(\abstractModeSeg).v.clone({
	~analyzeNotes = #{ |rawMIDI|
		currentEnvironment
	};

		// rhythm profile must act on grace notes before the notes are embedded in the stream
		// thus, PseqFunc
		
		// change in ~useRh will take effect only at segment boundaries
		
	~asNotePattern = #{ |passInValue|
		var dur, length, rhy, out;
		out = (passInValue[\useRh] and: { (rhy = passInValue[\rhythmStream]).notNil }).if({
			PseqFunc(~notes, 1, func: { |note|
				#dur, length = rhy.next(note);
				note.copy.dur_(dur).length_(length);
			})
		}, { Pseq(~notes, 1) });
	};

		// all modal patterns must return modally-mapped notes
		// conversion to midinotes will be made in the note event
	~asPattern = #{ |passInValue|
		var	pat;
		pat = Pbind([\note, \delta], ~asNotePattern.value(passInValue)
				.collect({ |n| [n, n.dur] }));
		~mode.notNil.if({
			pat.patternpairs = pat.patternpairs ++
				[\mode, ~modeSubstitution.notNil.if({ ~modeSubstitution.value }, { ~mode })];
		});
		pat
	};

		// combine a series of metrics to compare different segments
		// ~qkeys and ~qnormals should be populated in the subclass
		// usage: seg1.qualities.sum.absdif(seg2.qualities.sum) -- lower absdif, more similar
	~qualities = #{
		(~qkeys.collect({ |k, i| k.envirGet * ~qnormals[i] })) ? 0
	};
}) => PR(\melModeSeg);

PR(\melModeSeg).v.clone({
	~analyzeNotes = #{ |rawMIDI|
		var notes, temp, tempdur;	// temp variable for calculations
			// some analysis funcs in here
			// start with pitch material

		temp = ~notes
			.reject({ |item| item.isSymbol or: { item.tryPerform(\freq).isSymbol } })
			.collect(_.asFloat)
			.select({ |item| item.isNumber });

		~intervals = Array.new(temp.size);

		temp.doAdjacentPairs({ |note1, note2, i|
			~intervals.add(note2 - note1)
		});
		(temp.size > 1).if({
			~intervals.add(~nextNote.asFloat - temp.last);
			~angularity = ~intervals.abs.mean / (~intervals.mean.abs.nz(1));
		}, {
			~angularity = 0;	// 1 note, can't be angular
		});

		~hiNote = temp.maxItem;
		~loNote = temp.minItem;
		~range = ~hiNote - ~loNote;
			// 0 = lowest, 1 = highest for center (ratio of median to range)
		~center = (temp.copy.median - temp.minItem) / ~range.nz(1);
		~lastNote = temp.last;
		~firstNote = temp.first;
		~direction = ~lastNote - ~firstNote;
		
			// lots of notes shorter than their deltas will drive this metric down
		~rhythmSustain = ~notes.sum(_.length) / ~notes.sum(_.dur);
// add repetition factor? how to compute quickly?
		
		~metric = ~qualities.value.sum;
		
		currentEnvironment
	};

	~qkeys = #[\angularity, \direction, \range, \center, \hiNote, \loNote];
	~qnormals = #[1, 1, 1, 8, 0.25, 0.25];	// factors used for normalizing analysis values

}, nil, #[\qkeys, \qnormals]) => PR(\melAdaptSeg);


// holds a single melodic segment along with its adaptations
PR(\abstractProcess).v.clone({
	~segProto = \melAdaptSeg;
	~adaptable = true;		// can specify some segments never to adapt
	
	~prepare = #{ |notes, nextNote, storage, parms, rawMIDI = true|
		~segs = List.with(PR(~segProto).v.copy
			.prepare(notes, nextNote, storage, parms, rawMIDI));
		~nextNote = nextNote;
		~mode = parms.atBackup(\mode, storage) ? \default;
		currentEnvironment
	};
	
	~main = #{  ~segs[0] };
	
	~addAdapt = #{ |notes, parms, rawMIDI = false|
			// if there is no mode in parms, use the one given at creation
		parms[\mode].isNil.if({ parms[\mode] = ~mode });
		~segs.add(PR(~segProto).v.copy
			.prepare(notes, ~nextNote, nil, parms, rawMIDI));  // not passing in storage object
		currentEnvironment
	};
	
	~removeAt = #{ |index| ~segs.removeAt(index) 
	};
	
	~asPattern = #{ |rhythmProfile|
		~segs.choose.asPattern(rhythmProfile)
	};

	~asNotePattern = #{ |rhythmProfile|
		~segs.choose.asNotePattern(rhythmProfile)
	};
	
	~clearAdapt = #{
		(~segs.size > 0).if({
			~segs = List.with(~segs[0]);
		});
	};
	
}, nil, #[\segProto]) => PR(\melSegWithAdapt);

PR(\abstractProcess).v.clone({
	~segProto = \melSegWithAdapt;
	~segFunc = \defaultMelSegmenter;
	~minSegSize = 4;
	
	~prepare = #{ |notes, nextNote, rawMIDI = true,
			intervals, avgInterval, avgDelta, storage, parms|
		var subsegs;
		
		~parms = parms;	// save for adding variations

			// these are needed to analyze future input materials
		~avgInterval = avgInterval;
		~avgDelta = avgDelta;

		notes = Func(parms.atBackup(\segFunc, currentEnvironment))
			.doAction(notes, /*currentEnvironment,*/ nextNote, intervals, 
				parms.atBackup(\minSegSize, storage, currentEnvironment), parms);

		subsegs = Array.new(notes.size);
		notes.do({ |seg, i|
			subsegs.add(PR(~segProto).v.copy.prepare(seg,
					// if there's a later segment, give first note of next segment
					// if this is the last, give first for wraparound interval
				(i < (notes.size-1)).if({ notes[i+1][0] }, { notes[0][0] }),
				storage, parms
			));
		});
		~mel = subsegs;
		currentEnvironment
	};
	
	~patternBase = #{ 
		Pseq(~mel, 1)
	};
	
	~asPattern = #{ |passInValue|
		~addAdaptCollect.value(~patternBase.value, passInValue, \asPattern)
	};

	~asNotePattern = #{ |passInValue|
		~addAdaptCollect.value(~patternBase.value, passInValue, \asNotePattern)
	};
	
	~addAdaptCollect = #{ |pattern, passInValue, asPatSelector = \asPattern|
		pattern.collect(e { |seg|
			passInValue[\adaptProb].coin.if({
				~doAdapt.value(seg, passInValue);
				(seg.segs.size > passInValue[\variantThreshold]).if({
					~eugenicize.value(seg, passInValue);
				});
			});
			seg.perform(asPatSelector, passInValue);
		})
	};

		// source and cross are Lists ([0] is original, [1..x] are variants)
	~doAdapt = #{ |source, passInValue|
		var srcSeg, crsSeg, fitness, fitnessmean, qtemp, result, adaptTemp;
			// choose source segment -- if too different from original, don't adapt further
			// source is melSegWithAdapt
		srcSeg = source.segs.choose;
		(~adaptMel.size > 0 and: { source.adaptable ? true }).if({
			crsSeg = ~adaptMel.choose;
			fitness = passInValue[\adaptStream].next(srcSeg);
			Func.exists(fitness).if({
				(result = Func(fitness).doAction(srcSeg, crsSeg, passInValue)).notNil.if({
					source.addAdapt(
						result,
						~parms,	// uses parms from creation time (no subsequent updates)
						false  // rawmidi should now be false
					);
						// it may be a bad adaptation -- kill it preemptively if so
					Func(passInValue[\eugTest])
						.doAction(source.segs[0], source.segs.last, passInValue).notNil.if({
							source.removeAt(source.segs.size-1)
					});
				});
			}, {
				fitness.notNil.if({
					format("Func(%) does not exist. No adaptation.",
						fitness.asCompileString).warn;
				});
			});
		});
	};
	
	~tryEugenicize = #{ |variantThreshold|
		var	seg;
		(seg = ~mel.select({ |seg| seg.mel.size > variantThreshold }).choose)
			!? { ~eugenicize.value(seg); };
	};
	
		// choose worst fit (or oldest) out of source and kill it
		// ok to have this in phrase b/c it doesn't involve adapt material
	~eugenicize = #{ |source, passInValue|
		var	fits, orig;

		orig = source.segs[0];
		fits = Array.newClear(source.segs.size-1);
		for(1, source.segs.size-1, { |i|
			fits.put(i-1, [Func(passInValue[\eugTest])
				.doAction(orig, source.segs[i], passInValue), i]);
		});
		fits = fits.reject({ |fit| fit[0].isNil });	// nil values are OK by test func
			// if any segment is left, kill the worst of them
		(fits.size > 0).if({
				// sort descending order of fit
			fits = fits.sort({ |a, b| a[0] > b[0] });
			source.removeAt(fits[0][1])
		}, {		// otherwise use age to determine which to drop
				// nature of list is that earliest items should be older
				// keep the original [0] and drop the oldest
			source.removeAt(1)
		});
	};
	
		// returns flat array of original segments -- used for adaptation
	~asSegArray = #{  ~mel.collect({ |seg| seg.segs[0] }) };
	
	~clearAdapt = #{
		~mel.do(_.clearAdapt);
		~adaptMel = nil;
	};

}, nil, #[\segProto]) => PR(\melAdaptPhrase);

// container to hold a number of melodic segments
// this maintains segments, adaptation, and holds current playback state (which seg)
// pattern to retrieve segments will be user-definable
// no need to hold index anymore -- if you want to change melodies,
// save this object and pop in a new \melodyStorage object

Proto({
	~segProto = \melAdaptPhrase;
	~midiParse = true;
	~splitFunc = \noSplit;
	~rhythmQuant = 0.25;	// default, quantize to 16th
	~adaptProb = 1; //0.4;
	~variantThreshold = 4;	// when more than 4 variants, drop some; see ~eugenicize
	~useRh = false;
	
		// these are keys that will be chucked into BP but need to be passed into mel
		// range is used for eug testing: NumericRange(lo, hi)
	~keysFromParent = #[\mode, \rhythmStream, \adaptStream, \adaptProb,
		\variantThreshold, \repeats, \preSplitFunc, \useRh, \adTest, \eugTest, \splitFunc,
		\resetSeg, \resetPhr, \range];
	
	~repeats = inf;
	~adaptPattern = \absSplice;		// this may be a pattern

	~preSplitFunc = #{ |notes| notes };

	~clearParms = { ~parms = nil; };
	
	~prepareSequence = #{ |key, buf, storage, parms|
			// maintain an aggregate of passed-in parameters
		~parms = (~parms ?? { () }).putAll(parms);
		key.envirPut((key ++ "PrepareSequence").asSymbol.envirGet
			.value(buf, storage, ~parms));
		currentEnvironment
	};

		// generate metrics for adaptation segments
	~melPrepareSequence = #{ |buf, storage, parms|
		var	notes, temp, intervals;
		notes = buf.notes;
			// calc this for splitting the phrases into subsegments
		intervals = Array.new(notes.size - 1);
		notes.doAdjacentPairs({ |note1, note2|
			intervals = intervals.add(note2 - note1);
		});

		~avgInterval = intervals.abs.mean;
		~avgDelta = buf.durs.mean;	// also need note deltas

			// function composition: maybe you want to do mode or some other conversion here
		temp = ~preSplitFunc.value(buf.notes);

		notes = Func(parms.atBackup(\splitFunc, storage, currentEnvironment).debug("splitfunc"))
			.doAction(temp, /*currentEnvironment,*/ parms);

			// must be array now because eventually, this will be a collection of phrases
		(temp == notes).if({ notes = [notes] });

			// return value
		notes.collect({ |phrNotes, i|
			PR(~segProto).v.copy.prepare(phrNotes, 
				(i == (notes.size-1)).if({ notes[0][0] }, { notes[i+1][0] }), 
				true, intervals, ~avgInterval, ~avgDelta, storage, parms)
		});
	};

	~adaptPrepareSequence = #{ |buf, storage, parms|
		var temp;
			// adaptation should just be a set of segments, so change split type
		parms[\splitFunc].isNil.if({
			parms = parms.copy.put(\splitFunc, \noSplit)
		});
		~melPrepareSequence.value(buf, storage, parms)
			.collect({ |phr, i|
				phr.mel.collect({ |seg, i| seg.main })
			}).flat;
	};
	
	~clearAdapt = #{
		~adapt = nil;
		~mel.do(_.clearAdapt);
	};

		// pattern maker needs to be modularized so you can override
	~makePhrPattern = #{ |passInValue|
		passInValue = passInValue ?? { ~passInValue };
		~phrPattern = Pseq(~mel, passInValue[\repeats] ? inf)
	};
	
		// run each melody segment successively
	~asSegPattern = #{ |asPatSelector, passInValue|
		passInValue = passInValue ?? { ~passInValue };
		~makePhrPattern.value(passInValue).collect(e { |phr|
			phr.notNil.if({
						// populate adaptation values in phrase, to simplify API
				phr.putAll((adaptMel: ~adapt));
			}, {
				nil
			});
		});
	};
	
	~asSegStream = #{ |asPatSelector, passInValue|
		passInValue = passInValue ?? { ~passInValue };
		(~segStream.isNil or: { passInValue[\resetPhr] ? true }).if({
			~segStream = CleanupStream(~asSegPattern.value(asPatSelector, passInValue)
				.asStream, e {
					currentEnvironment.put(\segStream, nil);  // allow reset next time
				});
		});
		~segStream
	};

}, nil, #[\segProto]) => PR(\melodyStorage);

// subclass that plays phrases in random order
PR(\melodyStorage).v.clone({
	~makePhrPattern = #{ |passInValue|
		~phrPattern = Pxrand(~mel, passInValue[\repeats] ? ~repeats ? inf)
//.collect({ |val| "\nmelstore-phrase pattern".postln; val.postcs })
	};
}) => PR(\melRandStorage);

AbstractChuckArray.defaultSubType = saveSubType;





var saveSubType = AbstractChuckArray.defaultSubType;

// rhythm profiles
// each return value from the pattern should be of the form [delta, length]
// rhythm is applied in PR(\melModeSeg).v[\asNotePattern]
// calls to the pattern with next will be passed the SequenceNote object
AbstractChuckArray.defaultSubType = \rhythmProfile;

PR(\abstractProcess).v.clone({
		// getQuant calls a method
	~keysFromParent = #[rhythmQuant, getQuant, midiParse, rhythmProfileReset, beatsPerBar];

	~prepare = #{ |buf, passInValue, parms, melBP|
		var 	quant = parms.atBackup(\rhythmQuant, passInValue),
			beatsPerBar = passInValue[\beatsPerBar] ??
				{ (parms[\quant] ?? { passInValue[\getQuant] }).quant },
			needToParse = parms.atBackup(\midiParse, passInValue).not,
			reset = parms.atBackup(\rhythmProfileReset, passInValue);

		(needToParse ? false).if({ buf = buf.parse });  // assumes buffer has already been parsed
		buf = buf.quantize(quant, beatsPerBar);  // simple quantize; deal w/ flexQuantize later?
		~durLen = [buf.durs, buf.lengths].flop;
		currentEnvironment
	};

	~asPattern = { 
		Prand(~durLen, inf)
	};
}) => PR(\randRhythm);

PR(\randRhythm).v.clone({
	~prepare = #{ |buf, passInValue, parms|
		var 	quant = parms.atBackup(\rhythmQuant, passInValue),
			beatsPerBar = passInValue[\beatsPerBar] ??
				{ (parms[\quant] ?? { passInValue[\getQuant] }).quant },
			needToParse = parms.atBackup(\midiParse, passInValue).not,
			reset = parms.atBackup(\rhythmProfileReset, passInValue);

		(needToParse ? false).if({ buf = buf.parse });  // assumes buffer has already been parsed
		buf = buf.quantize(quant, beatsPerBar);  // simple quantize; deal w/ flexQuantize later?

			// may chuck in new material without overwriting previous analyses
		(~durMarkov.isNil or: { reset ? false }).if({
			~durMarkov = MarkovSet.new(updateSeeds: true);
			~lenMarkov = MarkovSet.new(updateSeeds: true);
		});

		~durMarkov.parse(Pseq(buf.durs, inf), buf.size+1);
			// associate dur to length
		buf.notes.do({ |note| 
			~lenMarkov.read(note.dur, note.length)
		});
		~durStream = ~durMarkov.asStream;
		currentEnvironment
	};

	~asPattern = #{ 
		var dur;
		Pfunc(e {
			[dur = ~durStream.next, ~lenMarkov.next(dur)]  // .debug("markovRhythm output")
		})
	};
	
}) => PR(\markovRhythm);


AbstractChuckArray.defaultSubType = saveSubType;



var saveSubType = AbstractChuckArray.defaultSubType;
AbstractChuckArray.defaultSubType = \melodyPlayer;

// simple, raw-midi melody player, no adaptive functionality
PR(\abstractProcess).v.clone({
	~event = (midi: true, eventKey: \voicerNote);
	~requiredKeys = #[\sequence];
	~index = 0;

		// each sequence type is responsible for its own code to receive a sequence
		// should not mix types: if a chord sequence needs to own a melody sequence,
		// it should contain a separate object and delegate melody functions to it
	~acceptMIDIBuf = #{ |buf, adverb|
		~sequence = buf;
			// necessary because buf can change while sequence is playing
		(~index >= buf.size).if({
			~index = ~index % buf.size;	// or should this just be 0?
		});
		currentEnvironment
	};
	
	~asNotePattern = #{ 
		~index = 0;
			// Pfunc is roughly 6.7 times SLOWER than Proutine
		Proutine({ |inval|
			{	inval = ~sequence[~index].embedInStream(inval);  // output
				((~index = ~index+1) >= ~sequence.size).if({ ~index = 0 });
			}.loop;
		});
	};
	
	~asPattern = #{ 
		Pbind([\note, \delta], ~asNotePattern.value.collect({ |n| [n, n.dur] }));
	};
}, nil, #[\requiredKeys]) => PR(\mel1);

// melodic process that uses melAdaptSegs
PR(\abstractProcess).v.clone({
	~storageProto = \melodyStorage;
	~useRh = false;	// useRhythmProfile -- but this is a performance parm so I'm shortening it
	~rhythmProfileProto = nil; // \randRhythm;
	~rhythmProfileReset = false;
	~rhythmQuant = 0.25;	// default, quantize to 16th
	~event = ~event.copy.put(\eventKey, \voicerNote);
	~resetSeg = true;	// by default, when resetting, start from the beginning
	~requiredKeys = #[\mel];
	~adTest = \adTest;		// this is a default, can change -- currently unused
	~eugTest = \dummyEugTest;
	~adaptProb = 1; //0.4;
	~variantThreshold = 4;	// when more than 4 variants, drop some; see ~eugenicize
	~splitFunc = \noSplit;	// specify using buf.chuck(aBP, mel, (splitFunc: \xxx))
	~defaultMIDIType = \mel;
	
	~newMelFlag = false;	// internal flag: when a new melody is given, this becomes true

	~acceptMIDIBuf = #{ |buf, adverb, parms|
		var	result, temp;
		parms.isNil.if({
			parms = buf.tryPerform(\properties).copy ?? { () };
		}, {
			(temp = buf.tryPerform(\properties)).notNil.if({
					// should not overwrite parms for values already populated in parms
					// if properties includes a mode, this allows you to override the mode
					// at chuck time
				parms = temp.copy.putAll(parms);	// is this functionally equivalent?
			});
		});
			// not entirely sure about this for splitFunc
		parms.keysValuesDo({ |k, v|
			v.notNil.if({ currentEnvironment.put(k, v) });
		});
		
			// get the proper action, either from supplied adverb or buf type
		adverb = adverb ?? { parms[\type] ? \mel };

		(adverb != \rhythm).if({
			result = (adverb ++ "PrepareSequence").asSymbol.envirGet
				.value(~midiParse.if({ buf = buf.parse }, { buf }), parms);
				// boy, this is an ugly workaround -
				// but without it, adaptation data were incorrectly stored in this rather than storage obj
			(adverb == \mel).if({
				adverb.envirPut(result);
			});
		}, {
			~rhythm = ~rhythmPrepareSequence.value(buf, parms);
		});			

			// populate rhythm profile if there isn't one and I'm receiving a melody
		(~rhythmProfileProto.notNil and: ~rhythm.isNil and: (adverb == \mel)).if({
			~rhythm = ~rhythmPrepareSequence.value(buf, parms);
		});
		
		currentEnvironment
	};
	
		// should always return a new mel object, but should keep adapt (and other stuff?)
		// why always a new object? -- to save mel and reuse it
	~melPrepareSequence = #{ |buf, parms|
		var	saveMel = ~mel;
		(~mel = PR(~storageProto).v.copy)
			.prepareSequence(\mel, buf, currentEnvironment, parms);
		saveMel.tryPerform(\adapt).notNil.if({
			~mel[\adapt] = saveMel[\adapt];
		});
		~passInValue !? { ~mel[\passInValue] = ~passInValue };
		~newMelFlag = true;
		~mel
	};
	
		// add adaptation data to current melody if it exists
	~adaptPrepareSequence = #{ |buf, parms|
		~mel.isNil.if({
			~mel = PR(~storageProto).v.copy;
		});
		~mel.prepareSequence(\adapt, buf, currentEnvironment, parms);
	};
	
	~rhythmPrepareSequence = #{ |buf, parms|
			// create a new rhythm profiler only if needed
		(~rhythm ?? { PR(~rhythmProfileProto).v.copy })
			.prepare(buf, ~getPassInValue.(PR(~rhythmProfileProto).v.keysFromParent, false),
				parms, currentEnvironment)
	};
	
	~dumpSegments = { 
		~mel.mel.do({ |phr, i|
			"Phrase %\n".postf(i);
			phr.mel.do({ |seg, j|
				"\tSegment %\n".postf(j);
				seg.segs.do({ |adapt, k|
					"\t\tAdaptation %\n".postf(k);
					adapt.notes.do({ |note|
						"\t\t%\n".postf(note.asCompileString);
					});
					$\n.post;
				});
				$\n.post;
			});
			$\n.post;
			$\n.post;
		});
	};				
	
// potential problem: do some numeric parms belong to melodyStorage?
// yes: repeats, adaptProb, eugenicizeProb, variantThreshold, rhythmQuant
	~bindSimpleNumber = #{ |num, adverb|
		adverb.envirPut(num);
	};
	
	~clearAdapt = #{
		~mel.clearAdapt;
	};

	~getMode = #{  ~mode ? \default };
	~mode_ = #{ |mode|
		mode = mode.tryPerform(\collIndex) ? mode ? \default;  // pass a symbol in as the mode
		currentEnvironment.put(\mode, mode);
		~mel !? { ~mel.mode = mode };
		~event.put(\mode, ~mode.value);
		currentEnvironment
	};
	
// function test breaks the possibility of passing a function as such
	~getPassInValue = #{ |keys, save = false|
		var	out;
		out = ();
		keys.do({ |key|
			out.put(key, key.envirGet.isFunction.if({ key.envirGet.value }, { key.envirGet }));
		});
		(save ? false).if({ ~passInValue = out; });
		out
	};
	
	~asPattern = #{ 
		var rhythm;
		~event.put(\mode, ~mode.value);  // ensure event knows its mode
		~rhythmStream = ~rhythm.asPattern.asStream;
			// need to pass in repeats among other parms
			// true = save the passinvalue in the main BP environment
		~mel.asSegStream(\asPattern, ~getPassInValue.(~mel.keysFromParent, true));
		~newMelFlag = false;
		Prt({ |inval|
			var phrase, phraseStream, seg, rhy;
				// try to get phrase; if nil, is this a new melody object?
			{ ((phrase = ~mel[\segStream].next).isNil and: { ~newMelFlag }).if({
						// new melody object -- make the phrase stream
					~mel.asSegStream(\asPattern,
						~getPassInValue.(~mel.keysFromParent, true));
					~newMelFlag = false;
					phrase = ~mel[\segStream].next;
				});
				phrase.notNil  // if that fails, nothing to do
			}.while({
				phraseStream = phrase  //.asStream(~getPassInValue.value);
					.perform(\asPattern,
						~getPassInValue.(~mel[\keysFromParent])).asStream;
				{ (seg = phraseStream.next).notNil }.while({
					inval = seg.embedInStream(inval)
				});
					// stick in rest if available
					// passing in currentEnvironment so pattern can get clock
					// passing in phr because (sometime) phrase will contain metric alignment
					// last bit is not implemented now
				(rhy = ~macroStream.next(phrase)).notNil.if({
					(type: \rest, delta: rhy).yield
				});
			});
		})
		.collect(e { |ev|	// apply extra synth args, if available
			~argsStream.notNil.if({
				~argsStream.next(ev).put(\argKeys, ~argKeys)
			}, { ev })
		})
	};

// asNotePattern MIGHT BE BROKEN, pretty much deprecated

	~asNotePattern = #{ 
		~mel.asSegStream(\asNotePattern);
		~newMelFlag = false;
		Prt({ |inval|
			var phrase, phraseStream, seg;
			{ ((phrase = ~mel[\segStream].next).isNil and: { ~newMelFlag }).if({
						// new melody object -- make the phrase stream
					~mel.asSegStream(\asPattern/*, ~rhythmStream*/);
					~newMelFlag = false;
					phrase = ~mel[\segStream].next;
				});
				phrase.notNil  // if that fails, nothing to do
			}.while({
				phraseStream = phrase
					.perform(\asNotePattern, ~getPassInValue.value)
					.asStream;
				{ (seg = phraseStream.next).notNil }.while({
					seg.embedInStream(inval)
				});
			});
		})
	};		

	~bindPatDefault = \adapt;
}) => PR(\aiMel);

PR(\aiMel).v.clone({
	~event = ~event.copy.put(\eventKey, \synthNote);
}) => PR(\aiMelSynth);

PR(\aiMel).v.clone({
	~storageProto = \melRandStorage;
}, nil, #[\storageProto]) => PR(\aiMelRand);

PR(\aiMel).v.clone({
		// rename some methods (effectively, to allow super.asPattern)
	~asBasePattern = ~asPattern;
	~asBaseNotePattern = ~asNotePattern;

		// defaults
	~bassID = \currentBassNote;
	~bassIDStream = \currentBassNote;

		// ProtoEvent(\voicerNote) issues the dependency notification
	~asPattern = #{ 
		~asBasePattern.value
			.collect(e { |ev| ev.put(\bassID, ~bassIDStream.next(ev)) });
	};
}) => PR(\aiBass);


AbstractChuckArray.defaultSubType = saveSubType;



var saveSubType = AbstractChuckArray.defaultSubType;
AbstractChuckArray.defaultSubType = \chordStorage;

// chord processes

// chord segment
// no modal stuff, just raw midi notes
PR(\abstractProcess).v.clone({
	~prepare = #{ |notes, modeOverride|
			// notes should be in the format [note, note, note]
			// but they might come in as [SeqChordNote(..., [....]), ...]
		~modeOverride = modeOverride;
		~notes = notes.asArray.collect({ |n| n.asNoteArray }).flat;
		currentEnvironment
	};
	
		// subclasses will use keys in inEvent to adapt to topnote, etc.
	~asPattern = #{ |inEvent|
		ArpegPat(inEvent[\arpegType]).asPattern(~notes, inEvent)
	};
}) => PR(\basicChordSeg);

// modal chord segment that adapts itcurrentEnvironment to bass and topnote

// fitnesses of chord notes, assuming root is 0
// you can set this in a chordsegment instance to override.
// To change the default, put something else in the library.

Library.put(\fitFactors, Dictionary[
	0 -> 10,
	1.0 -> 6,  // 2nd
	2.0 -> 10, // 3rd -- note, privileging triadic notes
	3.0 -> 4,
	4.0 -> 10,
	5.0 -> -10,	// 6th degree makes chord root perception ambiguous; thus, it's punished
	6.0 -> 3,
	0.5 -> -5,	// non-diatonic notes
	1.5 -> -5,
	2.5 -> -5,
	3.5 -> 3,		// #4 or b5 OK
	4.5 -> -1,	// not preferred, but not completely evil either
	5.5 -> 0,		// b7 neutral
	6.5 -> 0,		// #7 neutral
]);

PR(\abstractModeSeg).v.clone({
		// by default, use the mode of the calling event
		// set to true to force the notes to play back using the mode analyzed here
	~useOwnMode = false;
	~prepare = #{ |notes, mode, rawMIDI = true, parms|
			// notes should be in the format [note, note, note]
		~rawNotes = ~notes = notes.asArray;
		~rawMIDI = rawMIDI ? true;
		~rawMIDI.if({ ~mapToMode.value(mode) });
		~analyzeNotes.value(~rawMIDI);	// collect stats on chord -- user definable
		~useOwnMode = parms.atBackup(\useOwnMode, currentEnvironment);
		currentEnvironment
	};
	
	~mapToMode = #{ |mode|
		var	bestMode, bestFit = -1e10, bestMap, modeFit, notesTemp, modeObj;
			// is it a single mode, or a mode pool?
		mode = mode ? \default;
		modeObj = mode.asMode.value;
		if(modeObj.size > 0) {
			modeObj.do({ |mode, i|
				notesTemp = ~rawNotes.mapMode(mode);
				((modeFit = Func(\chModeFit).doAction(notesTemp)) > bestFit).if({
					bestMode = mode;
					bestFit = modeFit;
					bestMap = notesTemp;
				});
			});
			~mode = bestMode;
			~notes = bestMap;
		}{
			~notes = ~notes.mapMode(mode);
			~mode = mode;
		};
		currentEnvironment
	};
	
	~mapToMIDI = #{ |mode|
		~notes = ~notes.unmapMode(mode);
		currentEnvironment
	};
	
	~analyzeNotes = #{ 
		~hiNote = ~notes.maxItem;
		~loNote = ~notes.minItem;
		currentEnvironment
	};
	
	~modeForEvent = { |ev|
		~modeOverride ?? { ~useOwnMode.if({ ~mode }, { ev[\mode] }) };
	};
	
	~modeOverride_ = { |mode|
		(mode !== ~modeOverride).if({
			~modeOverride = mode;
			~mapToMode.(mode ? ~mode);
		});
	};

	~getFit = #{ ~fitFactors ? Library.at(\fitFactors); };

	~asPattern = #{ |inEvent, fitFunc|
		var result = Func(fitFunc).doAction(currentEnvironment, inEvent,
			inEvent[\fitnessOverride] ?? { ~getFit.value });
		result.notNil.if({
			~lastFitNotes = result;
			ArpegPat(inEvent[\arpegType]).asPattern(result, inEvent)
		}, {
			Error("Fatal error arpeggiating chord: Func(%) returned nil."
				.format(fitFunc.asCompileString)).throw
		});
	};
}) => PR(\chordModeSeg);

// for more flexible analysis: user provides a "modepool" (array of ModalSpecs)
// each individual chord tries each option and chooses the one that fits best
// allows sensible chromatic inflections of minor modes, for instance

// deprecated -- chordModeSeg handles this on its own
// stub retained for backward compatibility

PR(\chordModeSeg).v.clone(nil) => PR(\chordModePoolSeg);

// first, basic arpeggiator (child process)

AbstractChuckArray.defaultSubType = \chordChildProc;

PR(\abstractProcess).v.clone({
		// give keys for prototypes
	~chordProto = \chordModeSeg;
	~mode = \default;
	
	~event = (eventKey: \voicerNote);
	
	~preparePlay = #{ 
		~chordStream = ~chordStream ?? { ~makeChordPattern.value.asStream };
		currentEnvironment
	};
	
	~reset = #{ 
		~chordStream = nil;
		~preparePlay.value;	// should return currentEnvironment
	};

	~getFit = #{ ~fitFactors ? Library.at(\fitFactors); };

	~makeChordPattern = #{ Pseq(~chords, inf) };
	~makeChordPattern_ = { |func|
		~makeChordPattern = func;
		~reset.value;
		currentEnvironment
	};

		// you can change fitToBassAndTop behavior by changing this symbol
		// funcs are defined in Func()
		// this may also be a function, which is passed the chord Proto
		// ~fitFunc = { |chordProto| ... return fitFunc symbol ... };
	~fitFunc = \asis;

// what if this is in response to a bass note (no inEvent)? address in subclass
// update method should modify the value of ~noteStream without updating anything else
	~nextNotePattern = #{ |inEvent|
			// if there is an event, we need to move to the next chord
		(inEvent.size > 0).if({
			~currentChord = ~chordStream.next(inEvent);
		});
	};
	
	~updateNoteStream = #{ |inEvent, bassID|
		bassID !? { inEvent.put(\bassID, bassID) };
		~noteStream = (~notePattern = ~currentChord.asPattern(inEvent, ~fitFunc.value(~currentChord)))
			.asStream;
	};
	
	~updateBass = #{ |lastEvent, bassID|
			// maybe you don't want the process to update every bass note
		(lastEvent.tryPerform(\at, \updateOnBass) ? true).if({
			~updateNoteStream.value(lastEvent, bassID)
		});
	};
	
	~nextNoteStream = #{ |inEvent|
		~nextNotePattern.value(inEvent);
		~updateNoteStream.value(inEvent);
		Prt({ |event|
			{ event = ~noteStream.next(event).yield }.loop
		});
	};

	~asPattern = #{ |inEvent|
		var	out, argPairs;
		if(~fitFactors.notNil) {
			inEvent = inEvent.copy.put(\fitnessOverride, ~fitFactors);
		};
		out = Pbind(
			\note, inEvent[\chNotes].isNil.if({
				(~chords.size == 0).if({
					Error("Cannot play -- no chords have been provided to arpeg process").throw;
				}, {
					~nextNoteStream.value(inEvent)
				});
			}, {
					// fall back for midi input
				out = (notes:~notes);
				ArpegPat(inEvent[\arpegType]).asPattern(
					Func(~fitFunc.value(out)).doAction(out, inEvent, ~getFit.value),
					inEvent)
			}),
			#[\dur, \length, \gate], MicRh(inEvent[\microRhythm])
				.asPattern(~notePattern, inEvent),
			\mode, (Pfunc({
				~currentChord.modeForEvent(inEvent)
			}))
		);
			// note, argpairs will reset every chord -- is that a good idea?
		argPairs = ~argPairs.(inEvent);		// if simple array, this will have no effect
		(argPairs.size > 0).if({
			out = Pbindf(out, \argKeys, argPairs[0, 2..], *argPairs)
		});
		out
	};
	
	~acceptMIDIBuf = #{ |buf, adverb, parms|
		~chords = ~prepareSequence.value(buf, parms);
		~chordStream = ~makeChordPattern.value.asStream;   // reset the chord stream
	};
	
	~prepareSequence = #{ |buf, parms|
		var 	notes, avgDur;
			// why I'm using a parms dictionary: grab more parameters without changing method args
		parms.tryPerform(\at, \fitFunc).notNil.if({ ~fitFunc = parms[\fitFunc] });
			// partition on rhythm - in general, notes belonging to the same chord will have
			// a duration less than the mean
		avgDur = buf.durs.mean;
			// if note is a SeqChordNote, it's a chord unto itself
			// otherwise, use average duration to determine when to break
			// should be possible to play slowly arpeggiated chords with some gracenotes
			// and have them preserved
		notes = buf.notes.separate({ |a, b| a.isChord or: { a.dur > avgDur } });
			// now make a chord object for each set of notes - this is function output
		notes.collect({ |ch|
				// true = unmap notes to mode
			PR(~chordProto).v.copy.prepare(ch.asNoteArray,
				parms.atBackup(\mode, buf.properties, currentEnvironment),
				parms.tryPerform(\at, \rawMIDI) ? true, parms)
		})
	};
}, nil, #[\chordProto]) => PR(\arpeg1);

// behaves the same as \arpeg1 but uses the synthNote event instead of voicerNote
PR(\arpeg1).v.clone({
	~event = ~event.copy.put(\eventKey, \synthNote);
}) => PR(\arpegSynth);

// uses modepool
PR(\arpeg1).v.clone({
	~chordProto = \chordModePoolSeg;
}, nil, #[\chordProto]) => PR(\arpeg2);

PR(\arpegSynth).v.clone({
	~chordProto = \chordModePoolSeg;
}, nil, #[\chordProto]) => PR(\arpeg2Synth);

// macrorhythm process - no topnote

AbstractChuckArray.defaultSubType = \chordPlayer;

PR(\abstractProcess).v.clone({
	~canWrap = true;
	~respondsToBass = false;
	~updaters = ();		// see ~update below -- for user-extensible notifications

	~acceptMIDIBuf = #{ |buf, adverb, parms|
		(#[\ch, nil].includes(adverb)).if({
				// true == rawMIDI
			~child.acceptMIDIBuf(buf, adverb, parms);
		}, {
			"This process does not accept a melody sequence.".warn;
		});
		currentEnvironment
	};
	
	~update = #{ |obj, changer ... args|
		if(~updaters.tryPerform(\at, changer).notNil) {
			~updaters[changer].value(obj, changer, *args)
		};
		currentEnvironment
	};

	~updateBassID = { |obj, changer|
		(~isPlaying and: { changer == ~bassID and: { ~lastEvent.notNil } })
		.if({
			~child.updateBass(~lastEvent, changer);
		});
	};
	
	~bassID_ = { |bassID|
		if(~updaters.tryPerform(\at, ~bassID).notNil) {
			~updaters.removeAt(~bassID);
		};
		~bassID = bassID;
		if(bassID.notNil) {
			~updaters[bassID] = ~updateBassID;
		};
		currentEnvironment
	};
	
	~bindSimpleNumber = #{ |num, adverb|
		adverb.envirPut(num);
	};
	
	~makeStreamForKey = #{ |key, streamKey, envir|
		var	stream = key.envirGet;
		envir.notNil.if({
			stream = envir.use({ stream = stream.asStream });
		}, {
			stream = stream.asStream
		});
			// output, and stream gets replaced so that playing stream picks it up:
		(streamKey = streamKey ?? { key ++ "Stream" }).asSymbol.envirPut(stream)
	};

		// to allow streams to be changed behind the scenes
	~makeProut = #{ |key, protoEvent, envir|
		var	streamKey;
			// create stream if it doesn't exist
		~makeStreamForKey.value(key, streamKey = (key ++ "Stream").asSymbol, envir);
			// if a protoevent is supplied, use it in next()
			// that's for topNote (not in this process, but subclasses)
			// otherwise use the event passed at evaluation time
		protoEvent.notNil.if({
			Prt({
				{ streamKey.envirGet.next(protoEvent).yield }.loop
			});
		}, {
			Prt({ |inEvent|
				{ inEvent = streamKey.envirGet.next(inEvent).yield }.loop
			});
		});
	};
	
	~preparePlay = #{ 
		~child.tryPerform(\preparePlay);
		currentEnvironment
	};
	~reset = #{ 
		~child.reset;
		currentEnvironment
	};
	
	~event = (eventKey: \macroRh);

	~requiredKeys = #[\macro, \micro, \arpeg];
	~rewrapKeys = ~requiredKeys;
	
	~asPattern = #{ |inEvent|
		var	out;
			// if length is nil, it picks up delta; sim. for arpegType
		PbindMultiChan(#[\delta, \length], ~makeProut.value(\macro),
			#[\microRhythm, \arpegType], Ptuple([
				~makeProut.value(\micro),
				~makeProut.value(\arpeg)], inf))
		.collect(e { |ev| currentEnvironment.put(\lastEvent, ev); ev });
		(~argPairs.size > 0).if({
			Pbindf(out, \argKeys, ~argPairs[0, 2..], * ~argPairs)
		}, { out });
	};
	
}, nil, #[\rewrapKeys, \requiredKeys]) => PR(\basicMacroRh);

	// macrorhythm with topnote and bass
PR(\basicMacroRh).v.clone({
	~melodyProto = \aiMel;
	~respondsToBass = true;
	~bassUpdate = true;

	~acceptMIDIBuf = #{ |buf, adverb, parms|
		var	parmsplus;
			// buffer properties are base parms; can override with chuck parms
		buf.properties.respondsTo(\putAll).if({
			parmsplus = buf.properties.copy.tryPerform(\putAll, parms ?? { () });
		}, {
			parmsplus = parms;
		});
		adverb = adverb ?? { parmsplus.tryPerform(\at, \type) ? \ch };
		case { adverb.isNil or: (adverb == \ch) }
				{ ~child.acceptMIDIBuf(buf, adverb, parmsplus) }
			{ #[\mel, \adapt].includes(adverb) }
				{	~topNote.isNil.if({ ~topNote = PR(~melodyProto).v.copy });
					~topNote.mode = parms.atBackup(\mode, currentEnvironment);
					~topNote.acceptMIDIBuf(buf, adverb, parmsplus)
				}
			{ "Invalid adverb.".warn; };
		currentEnvironment
	};

	~bindPattern = #{ |pattern, adverb|
		case { adverb == \adapt } { ~topNote.notNil.if({ ~topNote.bindPattern(pattern, adverb) }) }
			{	adverb.envirPut(pattern.asPattern);
				~makeStreamForKey.value(adverb);
			};
		currentEnvironment		// return
	};
	
	~getMode = PR(\aiMel).v[\getMode];
	~mode_ = #{ |mode|
		mode = mode.tryPerform(\collIndex) ? mode ? \default;  // pass a symbol in as the mode
		~child !? { ~child.mode = mode };
		currentEnvironment.put(\mode, mode);
	};
	
	~rewrapKeys = ~requiredKeys ++ [\topNote];
	
	~clearAdapt = #{ ~topNote.clearAdapt };

		// more modularization
		// sans top is to allow MIDI input when top melody is not already given
	~patternSansTop = #{
		PbindMultiChan(#[\delta, \length], ~makeProut.value(\macro),
			\arpegType, ~makeProut.value(\arpeg),
			\microRhythm,	~makeProut.value(\micro),
			\bassID, Pfunc({ ~bassID ? \currentBassNote }),
			\updateOnBass, Pfunc({ ~bassUpdate }),
			\convertTopFunc, Pfunc({ ~convertTopFunc ? \convertMode }),
			\mode, Pfunc({ ~getMode.value }))
		.collect(e { |ev| currentEnvironment.put(\lastEvent, ev); ev });
	};
	
	~patternAvecTop = #{
		~topNotePattern = ~topNote.asPattern;
		PbindMultiChan(#[\delta, \length], ~makeProut.value(\macro),
			\arpegType, ~makeProut.value(\arpeg),
			\microRhythm,	~makeProut.value(\micro),
			\top, ~makeProut.value(\topNotePattern, ~topNote[\event], ~topNote),
			\bassID, Pfunc({ ~bassID ? \currentBassNote }),
			\updateOnBass, Pfunc({ ~bassUpdate }),
			\convertTopFunc, Pfunc({ ~convertTopFunc ? \convertMode }),
			\mode, Pfunc({ ~getMode.value }))
		.collect(e { |ev|
			~lastEvent = ev;
			ev
		});
	};

	~asPattern = #{
		var	out;
			// topNote may be supplied by MIDI; in that case, don't include in Pbind
		~topNote.isNil.if({
			out = ~patternSansTop.value
		}, {
			out = ~patternAvecTop.value
		});
		(~argPairs.size > 0).if({
				// ~argPairs[0, 2..] gets every even index (e.g. symbolic keys)
			Pbindf(out, \argKeys, ~argPairs[0, 2..], * ~argPairs)
		}, { out })
	};
	
}, nil, #[\rewrapKeys, \requiredKeys]) => PR(\macroRh);

PR(\macroRh).v.clone({
	~requiredKeys = ~requiredKeys.copy;
	~requiredKeys.remove(\macro);
	~patternSansTop = #{
		PbindMultiChan(#[\delta, \length], [0.1, inf],	// for midi input, we don't know the length yet
			\arpegType, ~makeProut.value(\arpeg),
			\microRhythm,	~makeProut.value(\micro),
			\bassID, Pfunc({ ~bassID ? \currentBassNote }),
			\updateOnBass, Pfunc({ ~bassUpdate }),
			\convertTopFunc, Pfunc({ ~convertTopFunc ? \convertMode }),
			\mode, Pfunc({ ~getMode.value }))
		.collect(e { |ev| currentEnvironment.put(\lastEvent, ev); ev });
	};
	
	~patternAvecTop = #{
		~topNotePattern = ~topNote.asPattern;
		PbindMultiChan(
			#[\top, \delta, \length], ~makeProut.value(\topNotePattern,
				~topNote[\event], ~topNote)
				.collect({ |ev|	// from topEvent, make an array with delta and length
					[ev, ev[\delta], ev[\length] ?? { ev[\note].length }]
				}),
			\arpegType, ~makeProut.value(\arpeg),
			\microRhythm,	~makeProut.value(\micro),
			\bassID, Pfunc({ ~bassID ? \currentBassNote }),
			\updateOnBass, Pfunc({ ~bassUpdate }),
			\convertTopFunc, Pfunc({ ~convertTopFunc ? \convertMode }),
			\mode, Pfunc({ ~getMode.value }))
		.collect(e { |ev| currentEnvironment.put(\lastEvent, ev); ev });
	};			
}) => PR(\chTop);

AbstractChuckArray.defaultSubType = saveSubType;


// this guy interrupts a playing stream to allow midi input
var saveSubType = AbstractChuckArray.defaultSubType;
AbstractChuckArray.defaultSubType = \midiInputWrapper;

PR(\abstractProcess).v.clone({
		// if true, using this as a wrapper will stop the child immediately
		// really what you want it to do is wait for the first MIDI event before overriding
	~event = (eventKey: \dummy);
	~doReplay = false;
	~canWrap = true;
	~replayTimeSpec = BasicTimeSpec(1);
	~parseBuf = true;

	~postRecFunc = #{ |buf, process|
		(buf.properties.tryPerform(\at, \parse) ? ~parseBuf).if({ buf = buf.parse; });
			// output:
		buf.hasQuantizeProperties.if({ buf.quantize },
			{ buf });
	};
}) => PR(\abstractMIDIInput);

PR(\abstractMIDIInput).v.clone({
	~defaultMIDIType = \mel;
	~preparePlay = #{
		~midiNotesOn = IdentitySet.new;
	};
	~getMIDIParser = #{ |socket|
		~parser = MelodyParser(nil, currentEnvironment, socket, ~child.clock)
	};

	~midiCleanup = #{ 
		var	bp = BP(~collIndex), buf, quant;
		bp.unwrap(false);
			// insert your own processing here -- parsing, quantization
		buf = ~postRecFunc.value(~parser.recSocket.buf, bp);
		bp.bindMIDIRecBuf(buf, ~defaultMIDIType);
		quant = ~replayTimeSpec.asTimeSpec;
		bp.clock.schedAbs(
			quant.adjustTimeForLatency(quant.nextTimeOnGrid(bp.clock), bp.leadTime, bp.clock) - 0.05,
			{ bp.stopNow });
		(~doReplay ? false).if({
			bp.clock.schedAbs(quant.adjustTimeForLatency(quant.nextTimeOnGrid(bp.clock),
					bp.leadTime, bp.clock), {
				bp.play(NilTimeSpec.new, doReset:true);
			});
		});
	};
	
	~melNoteOn = #{ |note|
		~child.eventStreamPlayer.stop;
			// save this note -- when a note is released, this goes into that event
			// so that event can check for overlapping notes
		~midiNotesOn.add(note.asFloat);
		~lastMIDINoteOn = note.asFloat;
			// let child process determine how to handle the note
			// by setting length to nil, we tell child process the note will be terminated later
		~preparePlayEvent.value(note);
	};

	~preparePlayEvent = #{ |note|
		~child.event.copy.put(\note, note.copy.length_(nil))
			.put(\midi, true)
			.put(\immediateOSC, true)
			.play;
	};
		// should be able to receive an array of notes
	~melNoteOff = #{ |note|
		~midiNotesOn.remove(note.asFloat);
		~child.event.copy
			.put(\note, note)
			.put(\immediateOSC, true)
			.use({ ~releaseNote.value; });
	};
}, nil, #[\defaultMIDIType]) => PR(\melMIDI);

PR(\melMIDI).v.clone({
	~defaultMIDIType = \adapt;
}, nil, #[\defaultMIDIType]) => PR(\adaptMIDI);

PR(\abstractMIDIInput).v.clone({
	~defaultMIDIType = \ch;
	~preparePlay = #{  currentEnvironment };
	~getMIDIParser = #{ |socket|
		~parser = ChordParser(nil, currentEnvironment, socket, ~child.clock,
			~deltaThresh ? 0.1, ~lengthThresh ? 0.1)
	};
	~chordNoteOn = #{ |note|
		~child.eventStreamPlayer.notNil.if({
			BP(~collIndex).stopNow;
		});
			// let child process determine how to handle the note

			// get additional parameters from child (wrapper) process
			// this assumes child is already playing
		~preparePlayEvent.value(note);
	};
	~preparePlayEvent = #{ |note|
		~child.eventStream.next(~child.event.copy)
			.put(\chNotes, note.mapMode(~child.mode))
			.put(\length, inf)		// child should not cut off on its own
			.put(\midi, false)		// this only works on mapped data
			.play;
	};
		// should be able to receive an array of notes
	~chordNoteOff = #{ |note|
		~child.event.copy.put(\chNotes, note).use({
			~releaseNote.value;
		});
	};
}).import((melMIDI: \midiCleanup)) => PR(\chMIDI);

PR(\melMIDI).v.clone({
	~defaultMIDIType = \mel;	// chord processes place mel into topNote
	~preparePlayEvent = #{ |note|
		var	mode = ~parser.recSocket.buf.properties.tryPerform(\at, \mode) ?? { ~child.mode ? \default };
		~melNoteOff.(note);	// polyphony is not allowed
		~child.eventStream.next(~child.event.copy)
			.put(\delta, 0.1)
			.put(\length, inf)
			.put(\immediateOSC, true)
			.put(\top, (note: note.copy.mapMode(mode), mode: mode))
			.put(\midi, false)
			.play;
	};

		// this one should only stop the stream if releasing the last played note
	~melNoteOff = #{ |note|
		var	currentChord = ~child.child.currentChord, notes;
		currentChord.notNil.if({
			notes = currentChord.lastFitNotes.asFloat
				.unmapMode(currentChord.modeForEvent(~child.lastEvent));
			(~lastMIDINoteOn == note.asFloat).if({
				~child.child.event.copy
					.put(\freq, notes)
					.put(\immediateOSC, true)
					.use({ ~releaseNote.value; });
			});
		});
		~midiNotesOn.remove(note.asFloat);
	};
}) => PR(\topMIDI);

// chord and topnote melody input simultaneously
PR(\chMIDI).v.clone({
	~preparePlayEvent = #{ |note|
		~child.eventStream.next(~child.event.copy)
			.put(\chNotes, note.mapMode(~child.mode))
			.put(\top, note.maxItem.postln.mapMode(~child.mode).postln)
			.put(\length, inf)		// child should not cut off on its own
			.put(\midi, false)		// this only works on mapped data
			.put(\getChord, false)
			.play;
	};

	~midiCleanup = #{ 
		var	bp, buf;
		bp = BP(~collIndex);
		bp.unwrap(false);
			// insert your own processing here -- parsing, quantization
		buf = ~postRecFunc.value(~parser.recSocket.buf, bp);
		bp.bindMIDIRecBuf(buf, \ch);
		bp.bindMIDIRecBuf(buf.copyTopNotes, \mel);
		bp.stopNow;
		bp.play(~replayTimeSpec.applyLatency(bp.latency), doReset:true);
	};
	
}) => PR(\chmelMIDI);

AbstractChuckArray.defaultSubType = saveSubType;



// adaptation functions
var saveSubType = AbstractChuckArray.defaultSubType;

// first, evaluate fitness
// these are very basic defaults, user can customize them for certain materials

// write adTest later

#{ |orig, test|
	var	out;
	out = orig.metric.absdif(test.metric);
	(out > (orig.metric*0.25)).if(out);	// otherwise nil
} => Func(\eugTest).subType_(\eugTest);

#{ nil } => Func(\dummyEugTest).subType_(\eugTest);

// first checks range as a hard limit
// BP(\melodicProcess).v.range = NumericRange(lo, hi)
{ |orig, test, passInValue|
	var	range;
	((range = passInValue[\range]).notNil and: {
			test.loNote < range.lo or: { test.hiNote > range.hi } }).if(100);
} => Func(\eugRangeOnlyTest).subType_(\eugTest);

// if in range, returns result of eugTest; otherwise, 100 to guarantee failure
{ |orig, test, passInValue|
	var	out;
	(out = Func(\eugRangeOnlyTest).doAction(orig, test, passInValue)).isNil.if({
		out = Func(\eugTest).doAction(orig, test, passInValue)
	});
	out
} => Func(\eugRangeTest).subType_(\eugTest);


// design may change if I need to pass extra args in

// material should always be in array form -- make those changes later

AbstractChuckArray.defaultSubType = \melAdapt;

#{ |source, cross|	// absolute splice
	var	s1, s2, newSeg, splice, spl2size, spl2;
	s1 = source.notes;		// not worrying about weighting b/c poor adaptations
	s2 = cross.notes;		// will die after a few generations
	splice = ((s1.size-2).rand + 1).max(1);	// splice coordinates
	spl2size = rrand(3, (s2.size * 0.7).roundUp.asInteger);
	spl2 = (s2.size - spl2size).rand;
	newSeg = s1.copyRange(0, splice-1);
	newSeg = newSeg ++ s2.copyRange(spl2, spl2 + spl2size);
	newSeg ++ s1.copyRange(splice, s1.size - 1);
} => Func(\absSplice);

#{ |source, cross|
	// diatonic splice -- take part of s1 as is, insert intervals from part of s2,
	// and finish with s1
	var s1, s2, temp, s1ang, splice, current, new, spl2, spl2size;
	splice = ((source.notes.size-2).rand + 1).max(1);
	spl2size = rrand(3, (cross.notes.size * 0.7).round.asInteger);
	spl2 = (cross.notes.size - spl2size).rand.max(1);
	(spl2size + spl2 >= cross.notes.size).if({ spl2size = cross.notes.size - spl2 });
	
	(spl2size >= 2).if({
		new = source.notes.copyRange(0, splice-1);
			// last diatonically mapped note + first spliced interval - s2 dia map note
		current = (source.notes[splice-1] + cross.intervals[spl2 - 1] - 
			cross.notes[spl2].freq).asFloat;
		new = new ++ (cross.notes.copyRange(spl2, spl2 + spl2size - 1) + current);
			// last note copied + transposition + next interval from source - next note (source)
			// algebraically simplifies to last note(s2) + transposition - last note (source)
		current = cross.notes[spl2 + spl2size - 1].freq + current - source.notes[splice-1].freq;
		new ++ (source.notes.copyRange(splice, source.notes.size - 1) + current);
	});
} => Func(\intSplice);

// delete some notes randomly from the segment
#{ |source|
	var	halfSize, deleteFrom, deleteTo;
	(source.notes.size > 6).if({
		halfSize = source.notes.size >> 1;
		deleteFrom = halfSize.rand;
		deleteTo = halfSize.rand + halfSize;
		source.notes[0..deleteFrom] ++ source.notes[deleteTo..source.notes.size-1]
	});	// else return nil (failed)
} => Func(\delete);

// delete some notes, keeping the segment duration the same
// issue: how to determine whether to sustain the previous note, or leave a rest?
// for now just leave a rest
#{ |source|
	var	lo, hi, numToDrop, newNote;
	source = source.notes.copy;	// must copy array before modifying
	lo = rand(source.size-1)+1;	// can't drop first note
	numToDrop = rand((source.size - 1).min((source.size * 0.25).asInteger));
	hi = (lo + numToDrop).min(source.size-1);
		// copy the note before modifying
	source.put(lo-1, source[lo-1].copy);
		// add the deleted notes' deltas to the new note's delta
	for(lo, hi, { |i|
		source[lo-1].dur = source[lo-1].dur + source[i].dur;
	});
	(source[0..lo-1] ++ source[hi+1..source.size-1])
} => Func(\delHoldDur);

// fixed-duration splice: output will be exactly as long as source.notes
{ |source, cross|
	var	s1, s2, newSeg, splice, spl2size, spl2, dur1, dur2, i, notetemp;
	s1 = source.notes;
	s2 = cross.notes;
	splice = ((s1.size-2).rand + 1).max(1);
	spl2size = rrand((s2.size * 0.2).round.asInteger, (s2.size * 0.7).round.asInteger);
	spl2 = (s2.size - spl2size).rand.max(0);
	dur2 = s2[spl2 .. spl2 + spl2size].collect(_.dur).sum;
	
		// calc coordinates in s1 matching that dur
	dur1 = 0;
	i = splice;
	{ (i < s1.size) and: { dur1 < dur2 } }.while({
		dur1 = dur1 + s1[i].dur;
		i = i + 1;
	});
		// if durs are equal, no problem
		// if dur1 is shorter, remove notes from spl2 until dur1 is longer or only one note is left
	(dur1 < dur2).if({
		{ spl2size > 0 and: { dur2 > dur1 } }.while({
			dur2 = dur2 - s2[spl2 + spl2size].dur;
			spl2size = spl2size - 1;
		});
	});

		// if dur1 is longer, adjust length of last splice note
	(dur1 != dur2).if({
		s2 = s2.copy.put(spl2 + spl2size, (notetemp = s2[spl2 + spl2size].copy).dur_(notetemp.dur + dur1 - dur2));
	});
	
	newSeg = s1.copyRange(0, splice-1);
	newSeg = newSeg ++ s2.copyRange(spl2, spl2 + spl2size);
	(i < s1.size).if({
		newSeg = newSeg ++ s1.copyRange(i, s1.size - 1);
	}, { newSeg });
} => Func(\fixedSplice);

// a few simple ones
{ |source| var size = source.notes.size, i, notes;
	notes = source.notes.copy.swap(i = size.rand, (i + (size-1).rand).wrap(0, size-1));
} => Func(\noteSwap);

// delete 1 note
{ |source| var i = (source.notes.size - 1).rand, out;
	(source.notes.size > 4).if({
		(out = source.notes.copy).put(i, out[i].copy.dur_(out[i].dur + out[i+1].dur));
		out.removeAt(i+1);
		out
	}, { nil })
} => Func(\dropNote);

// pick a note, split it in 2 (choose a note randomly in range of source)
{ |source| var i = source.notes.size.rand, out, dur;
	out = source.notes.copy;
	dur = out[i].dur;
	out[i] = out[i].copy.dur_(rrand(0.25, dur).round(0.25));
	(out[i].dur != dur).if({
		out = out.insert(i+1, SequenceNote(rrand(source.loNote, source.hiNote).round, dur = dur - out[i].dur, dur + rrand(-0.1, 0.1), out[i].args));
		out
	}, { nil });	// nil == no adaptation
} => Func(\splitNote);

// variation: choose note just outside range
{ |source| var i = source.notes.size.rand, out, dur;
	out = source.notes.copy;
	dur = out[i].dur;
	out[i] = out[i].copy.dur_(rrand(0.25, dur).round(0.25));
	(out[i].dur != dur).if({
		out = out.insert(i+1, SequenceNote(rrand(source.loNote - 3, source.hiNote + 3).round, dur = dur - out[i].dur, dur + rrand(-0.1, 0.1), out[i].args));
		out
	}, { nil });	// nil == no adaptation
} => Func(\splitNote2);


// chordal adaptation -- currently only fitToBassAndTop and support funcs

AbstractChuckArray.defaultSubType = \chordFit;

// couple of very simple cases
// return notes, no modification
#{ |source| source[\notes] } => Func(\asis);

// return notes transposed to topnote
#{ |source, inEvent|
	var	sourceTop, inTop, mode, topEvent, top, topMode, root, notes;
	#mode, topEvent, top, topMode, root, notes =
		Func(\getValuesFromEvent).doAction(source, inEvent);
	inEvent[\top].notNil.if({
		sourceTop = source[\notes].maxItem;
		source[\notes] + (top.asFloat - sourceTop.asFloat)
	}, {
		source[\notes]	// no topnote given, return input notes
	});
} => Func(\fitToTop);

{ |source, inEvent|
		// see Func(\getValuesFromEvent) - I don't need all the values so I take only this one
	var	root = (Library.[inEvent[\bassID] ? \currentBassNote].value(inEvent) ? 0).asFloat,
		notes = source[\notes],
		lowNote = notes.minItem.asFloat;
	notes + (root - lowNote);
} => Func(\fitToBass);

	// caller should supply the correct mode, for speed
#{ |noteArray, top, root, mode, fitFactors|
	var	degreesPerOctave, lowNote, fitIndex;
	mode = mode.asMode;
	degreesPerOctave = mode.scale.size;
	lowNote = noteArray.minItem.asFloat;
	noteArray.collect({ |n, i|
			// this should handle all floats
			// if not, the note will be sorely punished (-20)
			// multiply by a scaling factor to reduce the influence of higher notes
		fitIndex = ((n = n.asFloat) - root).round(0.1) % degreesPerOctave;
			// needed b/c you may get fitIndex === -0.0
		(fitIndex == 0).if({ fitFactors[0] }, {
			(fitFactors[fitIndex] ? -20)
		}) * ((1 - ((n-lowNote) / 14)).clip(0, 1));
	}).mean;	// use mean so that chords with lots of notes won't overwhelm thinner chords
} => Func(\chPitchFit).subType_(\chFitAnalysis);

// measures whether a set of notes belong to the mode into which they were mapped
// chromatic notes are punished
#{ |noteArray|
	noteArray.collect({ |n, i|
		((n = n.asFloat) == n.asInteger).if({ 1 }, { -1 });
	}).mean;	// use mean so that chords with lots of notes won't overwhelm thinner chords
} => Func(\chModeFit).subType_(\chFitAnalysis);
	
#{ |notes, top, mode|
	var degreesPerOctave, numBelowTop, numAboveTop, transposeBelow;
	mode = mode.asMode;
	degreesPerOctave = mode.scale.size;
	numAboveTop = numBelowTop = 0;
	notes.do({ |n| 
		(n > top).if({ numAboveTop = numAboveTop + 1 });
		(n < top).if({ numBelowTop = numBelowTop + 1 });
	});
		// if more notes are above than below top, notes below top need to be dropped 1 oct.
	transposeBelow = (numAboveTop > numBelowTop).if(degreesPerOctave, 0);
	notes.collect({ |n|
		(n > top).if({
			n - (degreesPerOctave *   // notes in an octave *
				(((n - top) / degreesPerOctave).roundUp))  // octaves to transpose
		}, {
			(n < top).if({ n - transposeBelow }, { n });
		});
	});
} => Func(\fixNotesAboveTop).subType_(\chFitAnalysis);

// convert a note from mode1 to mode2
#{ |note, mode1, mode2|
	(note.unmapMode(mode1) - mode1.asMode.tuning).mapMode(mode2)
} => Func(\convertMode).subType_(\chFitAnalysis);

#{ |note, mode1, mode2|
	(Func(\convertMode).doAction(note, mode1, mode2) /*+ 0.1.rand2*/).round
} => Func(\convertNearestInMode).subType_(\chFitAnalysis);

// returns an array with important values for chord fitting
#{ |source, inEvent|
	var	mode, topEvent, top, topMode, root, notes, chordMode;

	mode = (inEvent[\mode] ? \default)/*.asMode*/;

		// mode might be a mode pool (array of Mode IDs) -- if so, revert to the mode stored in the chord
	(mode.asMode.value.size > 0).if({
		mode = source[\mode];
	});

		// midi input will be in the event - use it if present
	notes = inEvent[\chNotes] ? source[\notes];
	(topEvent = inEvent[\top]).notNil.if({
		top = topEvent[\freq] ?? { topEvent[\note].asFloat };
		topMode = topEvent[\mode]/*.asMode*/;
	}, {
		top = notes.asFloat.maxItem;
		topMode = mode;
	});
	(mode != topMode).if({
		top = Func(inEvent[\convertTopFunc] ? \convertMode).doAction(top, topMode, mode);
	});
		
		// .value(inEvent) means that the Library item can generate a new root when called
	root = (Library.at(inEvent[\bassID] ? \currentBassNote).value(inEvent) ? 0).asFloat;

	[mode, topEvent, top, topMode, root, notes]	// return val
} => Func(\getValuesFromEvent).subType_(\chFitAnalysis);

		// should return notes array
		// "match by notes" strategy: calculate all possible transpositions of this chord
		// containing the top note; measure the fitness of each, and choose one of the
		// best fitting chords
#{ |source, inEvent, fitFactors|
	var	transposeStats,  // [[xpose1, fitness1], [xpose2, fitness2]...]
		xposeBy, mode, topEvent, top, topMode, root, notes;

	#mode, topEvent, top, topMode, root, notes =
		Func(\getValuesFromEvent).doAction(source, inEvent);

		// transpose and evaluate for each note
	transposeStats = notes.collect({ |n|
		[xposeBy = (top - n).asFloat,
		 Func(\chPitchFit).doAction(notes + xposeBy, top, root, mode, fitFactors)];
	}).sort({ |a, b| a[1] > b[1] });  // sort fitnesses descending
		// transpose the whole chord
	Func(\fixNotesAboveTop).doAction(notes + transposeStats[0][0], top, mode);
} => Func(\chordFitNotes);

// interval strategy -- produce final chord forms by traversing the intervals in a tree structure
#{ |source, inEvent, fitFactors|
	var resultList = Func(\collectChordsByInt).doAction(source, inEvent, fitFactors),
		fitness,		// [[0, fitness0], [1, fitness1]]
		mode, topEvent, top, topMode, root, notes;

	#mode, topEvent, top, topMode, root, notes =
		Func(\getValuesFromEvent).doAction(source, inEvent);

	fitness = resultList.collect({ |ch, i|
		[i, Func(\chPitchFit).doAction(ch, top, root, mode, fitFactors)]
	}).sort({ |a, b| a[1] > b[1] });
	
		// output -- fitness[0] is best fit, second [0] gets index into resultList
		// dur and length should be replaced by microrhythm
	resultList[fitness[0][0]].collect({ |freq| SequenceNote(freq, 1, 1) })
} => Func(\chordFitInt);

// more code, but faster...
#{ |source, inEvent, fitFactors|
	var	parms = Func(\getValuesFromEvent).doAction(source, inEvent),
		sortedNotes = parms[5].copy.sort({ |a, b| a > b }),	// descending order by pitch
		intervals = Array.new(sortedNotes.size-1),
		result,
		current = parms[2];

	sortedNotes.asFloat.doAdjacentPairs({ |a, b| intervals.add((b - a)) });
	intervals = intervals.scramble;
	
	result = Array(sortedNotes.size).add(SequenceNote(current, 1, 1));
	intervals.do({ |int|
		current = current + int;  // intervals are negative so this is actually descending
		result.add(SequenceNote(current, 1, 1));
	});
	result
} => Func(\chordRandInt);

{ |source, inEvent, fitFactors|
	var	resultList,	// chords resulting from tree traversal
		notes, sortedNotes, intervals,
		mode, topEvent, top, topMode, root;

	#mode, topEvent, top, topMode, root, notes =
		Func(\getValuesFromEvent).doAction(source, inEvent);

		// define traverse function
	resultList = List.new;
	sortedNotes = notes.copy.sort({ |a, b| a > b });	// descending order by pitch
	intervals = Array.new(sortedNotes.size-1);
		// .asFloat is needed to be sure removeDups in traverse func works
	sortedNotes.asFloat.doAdjacentPairs({ |a, b| intervals.add((b - a)) });
	Func(\traverseIntervalTree).doAction([top], intervals, resultList);
	resultList
} => Func(\collectChordsByInt);

{ |current, intervals, resultList|
	var	tempIntervals;
	(intervals.size > 0).if({
			// removeDups because it isn't necessary to process the same interval
			// multiple times in the same recursion level
		intervals.removeDups.do({ |interval|
			(tempIntervals = intervals.copy).remove(interval);
			Func(\traverseIntervalTree).doAction(current.copy.add(current.last + interval),
				tempIntervals, resultList);
		});
	}, {
		resultList.add(current)
	});
} => Func(\traverseIntervalTree);



// convenience stuff

// making a chord process is too hard, requiring 7 or more chucks
// this sets the basic parameters in one go, puts in a BP, and returns the BP
#{ |newBPname, childName, parentName, chordMIDIBuf, topMelodyMIDIBuf, macrorhythm, microrhythmSelector, arpegPatSelector, adaptKeysForTopMelody, mode, parms|
	var	new;
	BP.exists(newBPname).not.if({
		new = PR(parentName).chuck(PR(childName).chuck(BP(newBPname), nil, parms), nil, parms);
			// short form for ch.notNil.if({ ... })
		mode.asMode !? { mode.asMode => new };
		chordMIDIBuf !? { chordMIDIBuf =>.ch new };
		topMelodyMIDIBuf !? { topMelodyMIDIBuf =>.mel new };
		macrorhythm !? { macrorhythm =>.macro new };
		microrhythmSelector !? { microrhythmSelector =>.micro new };
		arpegPatSelector !? { arpegPatSelector =>.arpeg new };
		adaptKeysForTopMelody !? { adaptKeysForTopMelody =>.adapt new };
		new
	}, {
		("BP(" ++ newBPname.asCompileString ++ ") already exists. Using existing BP.").warn;
	});
	BP(newBPname)
} => Func(\makeCh).subType_(\factory);

// same as makeCh, but frees the BP first
#{ |newBPname, childName, parentName, chordMIDIBuf, topMelodyMIDIBuf, macrorhythm, microrhythmSelector, arpegPatSelector, adaptKeysForTopMelody, mode, parms|
	var	new;
	BP.exists(newBPname).if({ BP(newBPname).free });
	Func(\makeCh).doAction(newBPname, childName, parentName, chordMIDIBuf, topMelodyMIDIBuf, macrorhythm, microrhythmSelector, arpegPatSelector, adaptKeysForTopMelody, mode, parms);
} => Func(\newCh).subType_(\factory);


// for melodic processes
// intra-phrase segmenter
// notes, currentEnvironment is a bit odd, but necessary for error protection
#{ |notes, nextNote, intervals, minSegSize, parms|
		var	durs;
		var	lastTrueIndex, largeInterval;

		minSegSize = minSegSize ? 4;
		durs = notes.collect(_.dur);

			// split phrase into segments
		lastTrueIndex = -1;		// to ensure that true isn't returned too often
								// has to be -1 because separate splits AFTER it sees true
		largeInterval = { |i|		// determine if this is a large interval
			(i < intervals.size).if({
				(intervals[i].abs > ~avgInterval) or: { durs[i] > ~avgDelta }
			}, {
				true		// maybe this should be false?
			});
		};

		notes = notes.separate({ |note1, note2, i|
				// do not start a new segment if less than minsegsize
			(i - lastTrueIndex < minSegSize).if({ false }, {
					// start a new seg if this is a big interval and next is not
					// otherwise, keep rollin'
				(largeInterval.value(i) and: largeInterval.value(i+1).not).if({
					lastTrueIndex = i;
					true
				}, { false });
			});
		});
} => Func(\defaultMelSegmenter).subType_(\melPartition);

// phrase splitter
{ |notes|
	var subsegs, phraseScores, avgScore, splitIndices;
			// partition the melody into phrases
			// metric is (delta - avgDelta) * (rest / delta)
		phraseScores = notes.collect({ |n|
			(n.dur < ~avgDelta or: { n.length > n.dur }).if({ -inf },
				{ (n.dur - ~avgDelta) * ((n.dur - n.length) / n.dur) });
		});
		avgScore = phraseScores.reject(_ < 0).mean;
		splitIndices = Array.new(notes.size).add(0);
		phraseScores.do({ |score, i|
			(score > avgScore).if({ splitIndices.add(i) });
		});
		splitIndices.add(notes.size-1);
			// do you want to join with the preceding or following phrase? dunno, assuming earlier
		splitIndices.doAdjacentPairs({ |a, b, i|
			(b-a < 3).if({ phraseScores[a] = -inf });
		});
		notes = notes.separate({ |a, b, i| phraseScores[i] > avgScore });
} => Func(\defaultMelSplit).subType_(\melPartition);

// split notes into equal-length phrases
// corner case not covered: if last phrase is too short, what do we do?
// or, if last note exceeds bar length, there will be no compensation
{ |notes, parms|
	var	elapsed = 0, result = List.with(List.new),
		barlength = parms.atBackup(\barLength, currentEnvironment) ? 4.0,
		overflow;
	notes.do({ |note, i|
		result.last.add(note);
		elapsed = elapsed + note.dur;
		(elapsed >= barlength and: { i < (notes.size - 1) }).if({
			result.add(List.new);
			elapsed = elapsed - barlength;
		});
	});
	result.doAdjacentPairs({ |a, b|
		((overflow = a.collect(_.dur).sum - barlength) > 0).if({
			a[a.size-1] = a.last.copy.dur_(a.last.dur - overflow);
				// empty array is how to indicate a rest to a voicer
				// will update later for symbols e.g. \rest
			b.insert(0, SequenceNote(\rest, overflow, 0.1, 0.5));
		});
	});
		// more efficient to call asArray first on the outer list, saves an object
	result.asArray.collect(_.asArray);
} => Func(\barMelSplit).subType_(\melPartition);

{ |notes| [notes] } => Func(\noSplit).subType_(\melPartition);

// user-defined phrase splits
// give the size of each clump of notes
{ |notes, parms|
	var	splitsizes = parms.atBackup(\phrSplits, currentEnvironment);
	(splitsizes.size > 0).if({
		notes.clumps(splitsizes)
	});	// ok to return nil on failure; Func will substitute the original note array
} => Func(\userSplit).subType_(\melPartition);


// helper functions to use drum sequencers with a coordinator
// that produces keys to choose generators

AbstractChuckArray.defaultSubType = \drumgenhelpers;

{	var	result, shortIndex;
	~usedKeys.do({ |key|
		(key != \amps).if({
			result = Array.fill(~amps.size, -1);
			shortIndex = 0;
			~amps.do({ |amp, longIndex|
				(amp > 0).if({
					result[longIndex] = key.envirGet.wrapAt(shortIndex);
					shortIndex = shortIndex + 1;
				});
			});
			key.envirPut(result);
		});
	});
} => Func(\expandKeys);

{	var	nonrests = ~amps.collectIndices(_ > 0);
	~usedKeys.do({ |key|
		(key != \amps).if({
			key.envirPut(key.envirGet.asArray.wrapAt(nonrests));
			(key.envirGet.size == 0).if({
				key.envirPut(#[0]);
			});
		});
	});
} => Func(\shrinkKeys);

{ |i, override|
	var	temp;
	~usedKeys.do({ |key|
		(temp = (override ?? { (key ++ "genStream").asSymbol.envirGet }).value(i)).notNil.if({
			key.envirGet[i] = temp;
		});
	});
} => Func(\insertIntoKeys);

{	var	basekey;
	~usedKeys.do({ |key|
		(basekey = (key ++ "base").asSymbol).envirGet.notNil.if({
			key.envirPut(basekey.envirGet.copy)
		}, {
			~base.notNil.if({
				key.envirPut(~base.copy)
			}, {
				key.envirPut(Array.fill(0, ~ampsSize.value))
			});
		});
	});
} => Func(\initKeys);

{ ~amps.collectIndicesOfItem(0) } => Func(\getRests);

{  ~genBase.value; } => Func(\drumBasicPre);

{ 
	var	action = ~driverEvent.tryPerform(\at, ~collIndex), func;
	~genBase.value;
	Func.exists(action).if({
		Func(action).doAction;
	});
	~driverEvent = nil;
} => Func(\drumRespDriver);



// for a rhythmic-adaptation prototype
// this func assumes your process is modeled after flutefx and has the required variables

{ |source, cross|
	var	new, adaptKey;
	(adaptKey = ~adaptStream.next(source)).notNil.if({
		(new = Func(adaptKey).doAction(source, cross)).notNil.if({
			~rhythms.add(new);
			(~rhythms.size > (3 * ~originalRhythms)).if({
				~rhythms.removeAt(((~rhythms.size * 0.25).asInteger.rand
					+ ~originalRhythms).clip(~originalRhythms, ~rhythms.size-1));
			});
		});
	});
	new
} => Func(\adaptRhythmArray);

{ |source, cross|
	var	new, spliceIndex, spliceStart, spliceEnd, temp;
	source = source;
	cross = cross;
	spliceIndex = source.size.rand;
	spliceStart = cross.size.rand;
	spliceEnd = (spliceStart + (spliceStart * 0.3).asInteger.rand2).clip(0, cross.size-1);
	(spliceIndex > 0).if({
		new = source[0..spliceIndex-1];
	});
	new = new ++ cross[spliceStart .. spliceEnd] ++ source[spliceIndex..];
	new
} => Func(\spliceRhythmArray);

{ |source|
	var	new, spliceStart, spliceEnd, temp;
	(source.size > 4).if({
		source = source;
		spliceStart = source.size.rand;
		temp = source.size.rand;
		spliceEnd = max(spliceStart, temp);
		spliceStart = min(spliceStart, temp);
		(spliceStart > 0).if({
			new = source[0..spliceStart-1];
		});
		(spliceEnd < (source.size - 1)).if({
			new = new ++ source[spliceEnd+1..];
		});
		new
	});
} => Func(\deleteRhythmArray);


AbstractChuckArray.defaultSubType = saveSubType;



// need iMadeDef for defPerc -- per def

// percussion process templates
// first, generic synthdefs

var saveSubType = AbstractChuckArray.defaultSubType;



// abstract process based on buffers
// the process generates a new Pbind per cycle
// amp pattern is specified in terms of subdivisions:
// #[0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0] will sound on beats 2 and 4
// if ~division = 0.25

// other arrays are per event, using wrapAt
AbstractChuckArray.defaultSubType = \drumSequencer;

PR(\abstractProcess).v.clone({
		// grain: true means don't generate a new node id each time (use -1)
	~event = (grain: true, eventKey: \singleSynthPlayer);
	~requiredKeys = #[\amps, \bufPaths];
	~inChannels = 1;
	~outChannels = 2;
	
//	~bufPaths = #[path0, path1...];	// files to load
//	~bufCoords = #[[start0, len0], [start1, len1]...];	// which portions

	~bufCoords = #[[0, -1]];	// default load whole soundfile for each file
	
	~bufs = #[0];		// default: use only first buffer
	~rates = #[1];	// default: play at normal speed
	~deltaAdjust = #[0];	// push samples ahead (-) or behind (+) to compensate for transient time
						// this array's elements correspond to buffers
						// adjustments given in seconds
						// adjustment.neg <= thisBP.leadTime - MUST BE TRUE
	~divCycle = 0.25;	// or #[0.3, 0.2] for swing
	~beatsPerBar = { (~clock ?? { BP.defaultClock }).beatsPerBar };
	~def = \bufGrain;
	~argPairs = nil;	// you may specify other arg keys as an array: [key, value, key, value]
					// if the key's value is not a pattern, a pattern will be made for it
					// using makePattern

	~attack = 0.001;
	~decay = 0.02;
	~mono = false;	// true = automatically prevent note overlaps
	~compensateEnv = false;		// true = subtract attack and decay time from time value
							// so that the synth plays for exactly "time" seconds
		// compensate sensitivity: 1.0 = subtract whole attack/decay duration
		// 0.0 = subtract none (just like ~compensateEnv = false)
		// 0.5 = subtract *half* of attack + decay
	~compensateAmount = 1.0;

	~compactPatterns = true;

	~iMadeMixer = false;

	~prep = #{ 
			// user may supply a mixerchannel
			// if so, ~iMadeMixer flag means the channel won't be freed
		~chan.isNil.if({
			~iMadeMixer = true;
			~chan = MixerChannel(~collIndex, ~master.tryPerform(\server) ?? { Server.default },
				~inChannels ? 1, ~outChannels ? 2, outbus:~master);
		});
			// this func is environment safe
			// loadbufs is here for defPerc, which may need resources from postMCCreation
		~chan.doWhenReady({ |chan|
			~postMCCreation.(chan);
			~loadBufs.value;
		});
		currentEnvironment
	};
	~postMCCreation = nil;	// pre-buffer exit point to put in your own initialization
	~postBufferLoad = nil;	// post-buffer exit point
	~loadBufs = #{ 
		~buffers.notNil.if({ ~buffers.free });
		~bufTimes = Array.newClear(~bufPaths.size);
		~buffers = ~bufPaths.collect({ |path, i|
			Buffer.readAndQuery(~chan.server, path, 
				~bufCoords.wrapAt(i)[0], ~bufCoords.wrapAt(i)[1],
				completionFunc: e { |buf|
					~fixBufTime.(i, buf);
					if(i == (~bufPaths.size - 1)) { ~postBufferLoad.() };
			});
		});
	};
	
	~listBufs = { 
		~buffers.do({ |buf, i| "%: %\n".postf(i, buf) })
	};
	
	~replaceBuf = { |i, path, startFrame, numFrames|
		(i >= ~buffers.size).if({
			~addBuf.(path, startFrame, numFrames);
		}, {
			~buffers[i].free;
			~buffers[i] = Buffer.readAndQuery(~chan.server, path, startFrame, numFrames, e { |buf|
				~fixBufTime.(i, buf)
			});
			~buffers[i]
		});
	};
	
	~addBuf = {  "Not yet implemented.".warn; };
	
	~fixBufTime = { |i, buf|
			// try b/c a failure here shouldn't kill the buffer queue
		try { ~bufTimes[i] = buf.numFrames / buf.sampleRate }
			{ |error| error.reportError; }  // display error but continue
	};
	
	~ampsSize = {
		var	divCycleArray = ~divCycle.asArray;
		~beatsPerBar.value / divCycleArray.sum * divCycleArray.size
	};
	
	~makeDeltaPattern = #{ 
		var	current = 0, thisDelta, totalDelta, dStream, deltas;
		~compactPatterns.if({
			deltas = Array.new(~amps.size);
			dStream = Pn(~divCycle.asPattern, inf).asStream;
			thisDelta = totalDelta = 0;
			~amps.do({ |step, i|
				(step > 0).if({	// there's a note here
					(thisDelta > 0).if({
						deltas.add(thisDelta);
						totalDelta = totalDelta + thisDelta;
						thisDelta = 0;
						current = current + 1;
					});
				});
				thisDelta = thisDelta + dStream.next;
			});
			(totalDelta < ~beatsPerBar.value).if({
				deltas.add(~beatsPerBar.value - totalDelta);
			});
			Pseq(deltas, 1)
		}, { Pfinval(~amps.size, Pn(~divCycle.asPattern, inf)) });
	};
	~makeAmpPattern = #{ 
		~compactPatterns.if({
			Pseq(((~amps[0] == 0).if({ #[0] })) ++ ~amps.select(_ > 0), 1);
		}, {
			Pseq(~amps, 1)
		});
	};
	~makeDefPattern = #{ |repeats = 1|
		var	outArray = Array.new(~amps.size), array = ~def.asArray;
		~amps.do({ |amp, i|
			(amp > 0).if({
				outArray.add(array.wrapAt(i));
			});
		});
		if(outArray.size == 0) { outArray.add(\rest) };
		Pseq(outArray, repeats)
	};
	~makePatternFromArray = #{ |array, repeats, sourceKey|
		var amps, outArray, i = 0;
		(~compactPatterns or: { sourceKey == \def }).if({
			amps = ~amps;
			outArray = Array.new(amps.size);
				// if first is a rest, need a placeholder
			(sourceKey != \def and: { amps[0] == 0 }).if({ outArray.add(0) });
			amps.do({ |amp|
				(amp > 0).if({
					outArray.add(array.wrapAt(i));
					i = i + 1;
				});
			});
			Pseq(outArray, repeats)
		}, {
			Pseq(array, repeats)
		});
	};
	~makePattern = #{ |sourceKey, repeats|
//[sourceKey, ~collIndex, currentEnvironment[sourceKey].asArray].debug("making pattern for");
		~makePatternFromArray.(currentEnvironment[sourceKey].asArray, repeats ? 1, sourceKey);
	};
	~addArgPairs = { |out|
		var	argPairs = ~argPairs.value(out);
		if(argPairs.size > 0) {
			out = out.grow(argPairs.size);
			argPairs.pairsDo({ |key, value|
				out.add(key);
					// if you say nil, look for the key in the envir
				value.isNil.if({ value = key.envirGet });
					// temporarily removing this
					// it prevents use of asMap
//				value.isSymbol.if({ value = value.envirGet });
					// this is the only way to get values from the environment
					// while the pattern is running
				value.isFunction.if({ value = value.(out) });
				(value.size > 0).if({	// assume it's an array, use makePattern
					value = ~makePatternFromArray.(value, 1)
				});
				out.add(value);
			});
		};
		out
	};
	
	~makePbindArray = { 
//		~def = ~def.asArray;
		[\amp, ~makeAmpPattern.value,
			\bufIndex, ~makePattern.(\bufs, inf),
			\bufnum, Pfunc({ |ev|
				~buffers.wrapAt(ev[\bufIndex]).bufnum
			}),
			\rate, ~makePattern.(\rates, inf),
// if user specifies times, they should be in beats. default (whole-buffer) times are in seconds
			\time, ~times.notNil.if({
				(~makePattern.(\times, inf) / thisThread.clock.tempo)
			}, {
				Pfunc({ |ev|
					~bufTimes.wrapAt(ev[\bufIndex]) / ev[\rate]
				});
			}),
				// rest if 0, else give synthdef name
//			\instrument, Pif(Pkey(\amp) > 0, ~makePattern.(\def, inf), \rest),
			\instrument, Pif(Pkey(\amp) > 0, ~makeDefPattern.(inf), \rest),
			\chan, Pfunc({ ~chan }),
			\latencyAdjust, Pfunc({ |ev| ~deltaAdjust.wrapAt(ev[\bufIndex])
				* thisThread.clock.tempo }),
			\timingOffset, Pfunc({ |ev| (ev[\timingOffset] ? 0) + (ev[\latencyAdjust] ? 0) }),
			\delta, ~makeDeltaPattern.value,
			\attack, ~makePattern.(\attack, inf), // Pfunc({ ~attack }),
			\decay, ~makePattern.(\decay, inf), // Pfunc({ ~decay }),
			\time, Pfunc({ |ev|	// check for overlap if mono flag is true
				var time = ev[\time];
					// negative time value defaults to entire buffer dur
				(time < 0).if({ time = ~bufTimes.wrapAt(ev[\bufIndex]) / ev[\rate] });
					// compensate for env ramp in/out
				~mono.if({
					time = min(time, ev[\delta] / thisThread.clock.tempo)
				});
				~compensateEnv.if({
					(time - ((ev[\attack] - ev[\decay]) * ~compensateAmount)).max(0.001)
				}, { time });
			})
		]
	};
	
	~pbindPreAction = nil;		// custom action to run before building Pbind can be written here
	~pbindPostAction = nil;		// same, after building Pbind

	~doPreAction = { 
		Func.exists(~pbindPreAction).if({
			Func(~pbindPreAction).doAction
		}, {
			~pbindPreAction.value
		});
	};

	~doPostAction = { |out|
		Func.exists(~pbindPostAction).if({
			Func(~pbindPostAction).doAction(out)
		}, {
			~pbindPostAction.(out)
		});
	};
	
	~sendSynthDef = {
		var	synthdesc;
		~def.do({ |def|
			if((synthdesc = SynthDescLib.global[def]).notNil) {
				synthdesc.send(s);
			};
		});
	};

	~asPattern = { 
		var	out;
		~prepareForPlay.value;	// one use is streams that must persist past 1 bar
		~sendSynthDef.value;
		PnNilSafe(Plazy(e {
			~doPreAction.value;
			out = ~makePbindArray.value;
			out = ~addArgPairs.(out);
			out = ~doPostAction.(out) ? out;	// do postprocessing on pbind pairs
			Pbind(*out);
		}), inf);
	};
	
	~freeCleanup = #{ 
		~iMadeMixer.if({ ~chan.free });
		~buffers.free;
		~free.value	// did you make any other resources?
	};	
}) => PR(\bufPerc);


// use functions to make a pack of synthdefs
// alternately, supply synthdef names for preexisting defs
// can also supply Patches (compound Patches are not supported yet)
// it's assumed that the def contains a fixed-length envelope that will free the node (doneAction:2)

PR(\bufPerc).v.clone({
	~defs = #[0];
	~requiredKeys = #[\objects, \amps];
		// user extensible: define your own functions to add objects as synthdefs
		// String and Symbol are supported by nil
	~classActions = IdentityDictionary[
		'SynthDef' -> \makeSynthDef,		// as it happens, these can be the same b/c of asSynthDef
		'Function' -> \makeFnDef,
		'Patch' -> \makePatchDef,
		'WrapPatch' -> \makePatchDef,
		'FxPatch' -> \makePatchDef
	];
	~patchesToFree = List.new;
		// now, instead of loading buffers, we load synthdefs
		// using names defined in bufPerc, though
	~loadBufs = #{ 
		~buffers.notNil.if({ ~buffers.free });
			// .value allows function to create objects array dynamically
		~buffers = ~objects.value.collect({ |obj| 
			~makeDefForObject.(obj).asSymbol
		});
	};
	~makeDefForObject = #{ |obj|
		var return;
		(return = ~classActions[obj.class.name]).notNil.if({
			return = return.envirGet.(obj)
		});
		return ?? { obj }	// if nothing, return the object itself
	};
	~makeFnDef = #{ |fn|
		var def;
		def = fn.asSynthDef(outClass: 
			(~isFx ? false).if({ \ReplaceOut }, { \Out })).add;
		def.name
	};
	~makePatchDef = #{ |patch|
		var def;
		def = patch.asSynthDef.add;
		~patchesToFree.add(patch);
		def.name
	};
	~makeSynthDef = #{ |def| def.add.name };
	~replaceDef = { |i, obj|
		(i >= ~buffers.size).if({
			~addBuf.(obj);
		}, {
			~chan.server.sendMsg(\d_free, ~buffers[i]);
			~buffers[i] = ~makeDefForObject.(obj).asSymbol;
			~buffers[i]
		});
	};
	
	~addBuf = {  "Not yet implemented.".warn; };

	~makePbindArray = { 
		[\amp, ~makeAmpPattern.value,
				// rest if 0, else give synthdef name
			\defIndex, ~makePattern.(\defs),
			\instrument, Pfunc({ |ev|
				(ev[\amp] > 0).if({
					~buffers.wrapAt(ev[\defIndex])
				}, { \rest });
			}),
			\chan, Pfunc({ ~chan }),
			\delta, ~makeDeltaPattern.value
		]
	};

	~superfree = ~freeCleanup;
	~freeCleanup = { 
		~patchesToFree.do(_.free);
		~superfree.value;
	};

}) => PR(\defPerc);

ProtoEvent.composite(#[singleSynthTrigger, singleSynthPlayNotify]) => ProtoEvent(\defTrigEvent);

PR(\defPerc).v.clone({
	~event = (eventKey: \defTrigEvent);
	~alwaysReset = true;
	~isFx = false;
	~superprep = ~prep;
	~prep = {
		~superprep.();
			// synthdefs are inited after MixerChannel is ready, so...
		~chan.doWhenReady({
			~eventInitArgs = { () } ! (~buffers.size);
		});
	};
	~makePbindArray = { 
		[\trig, ~makeAmpPattern.value,
				// rest if 0, else give synthdef name
			\defIndex, ~makePattern.(\defs),
			\instrument, Pfunc({ |ev| ~buffers[ev[\defIndex]] }),
			\node, Pfunc({ |ev|
				(ev[\trig] > 0).if({
					~nodes.wrapAt(ev[\defIndex]) ?? { \dummy }
				}, { \rest });
			}),
			\chan, Pfunc({ ~chan }),
			\delta, ~makeDeltaPattern.value
		]
	};
		// SynthDesc msgFunc expects args to exist in the event
		// for simplicity they'll go in the event's proto
		// but you might have different inits for different synths
		// so the protos are kept in an array -- see the .collect
		// in asPattern for their use in playing events
	~setInitArgsInEvent = { |node, i|
		var	proto = ~eventInitArgs[i] ?? { () },
			return;
		(return = ~initArgs.value(node, i)).pairsDo({ |key, val|
			proto.put(key, val.value);
		});
		proto.put(\outbus, ~chan.inbus.index)
			.put(\out, ~chan.inbus.index)
			.put(\i_out, ~chan.inbus.index);
		~eventInitArgs[i] = proto;
		return
	};

	~recvEventNotify = { |node, event|
		~nodes[event[\defIndex]] = node;
		~nodeEventKeys[event[\defIndex]] = \singleSynthTrigger;
	};

	~asPattern = {
		Pseq([
			Pfuncn({	// first, initialize node arrays
				var latency;
				(~nodes.size == 0).if({
						// first event for each index must be to play the node,
						// then notify me
					~nodeEventKeys = \singleSynthPlayNotify ! ~buffers.size;
					~nodes = Array.newClear(~buffers.size);
				});
				(play: 0, delta: 0)
			}, 1),
			PnNilSafe(Plazy(e {
				var	out;
				~doPreAction.value;
				out = ~makePbindArray.value;
				out = ~addArgPairs.(out);
				out = ~doPostAction.(out) ? out;	// do postprocessing on pbind pairs
				Pbind(*out);
			}), inf).collect({ |ev|
				ev.proto = ~eventInitArgs[ev[\defIndex]];
					// which one of the composite events to use?
				ev.protoEvent = ~nodeEventKeys[ev[\defIndex]];
				ev
			});
		]);
	};
	
	~stopCleanup = {
		var	latency, hasGate;
		(~nodes.size > 0).if({
			latency = (~leadTime !? { ~leadTime / ~clock.tempo })
				+ ~chan.server.latency;
			~nodes.do({ |node, i|
				if(node.notNil) {
					hasGate = SynthDescLib.global[~buffers[i]].tryPerform(\hasGate);
					~chan.server.sendBundle(latency,
						(~hasGate ? false).if({ node.setMsg(\gate, 0) }, { node.freeMsg }))
				};
			});
			~nodes = nil;
		});
	};
}) => PR(\defTrig);

// loads the whole beat into 1 buffer; user specifies start positions for segments and times (beats)
// multiple files are supported -- use bufs to select file
PR(\bufPerc).v.clone({
	~requiredKeys = #[bufPaths, amps, start];
	~segStart = #[[0]];	// default, 1 segment encompassing the whole file
	~start = #[0];
	~mono = true;
	~compensateEnv = true;
	
	~makeStartTimes = { 
		~makePatternFromArray.(~start, 1).collect(e { |st, event|
			~segStart.wrapAt(event[\bufIndex]).wrapAt(st)
		});
	};
		
	~makePbindArray = { 
		[\amp, ~makeAmpPattern.value,
			\bufIndex, ~makePattern.(\bufs),
			\bufnum, Pfunc({ |ev|
				~buffers[ev[\bufIndex]].bufnum
			}),
			\rate, ~makePattern.(\rates),
// if user specifies times, they should be scaled by tempo. default times are in seconds
			\start, ~makeStartTimes.value,
			\time, ~times.notNil.if({
				~makePattern.(\times) / thisThread.clock.tempo
			}, {
				Pfunc({ |ev|
					~bufTimes[ev[\bufIndex]]
				});
			}),
				// rest if 0, else give synthdef name
			\instrument, Pfunc({ |ev|
				(ev[\amp] > 0).if({ ~def }, { \rest });
			}),
			\chan, Pfunc({ ~chan }),
			\latencyAdjust, Pfunc({ |ev| ~deltaAdjust.wrapAt(ev[\bufIndex]) }),
			\latency, Pfunc({ |ev| (ev[\latency] ? 0) + (ev[\latencyAdjust] ? 0) }),
			\delta, ~makeDeltaPattern.value,
			\attack, ~makePattern.(\attack), // Pfunc({ ~attack }),
			\decay, ~makePattern.(\decay), // Pfunc({ ~decay }),
			\time, Pfunc({ |ev|	// check for overlap if mono flag is true
				var time = ev[\time];
					// negative time value defaults to entire buffer dur
				(time < 0).if({ time = ~bufTimes.wrapAt(ev[\bufIndex]) / ev[\rate] });
					// compensate for env ramp in/out
				~mono.if({
					time = min(time, ev[\delta] / thisThread.clock.tempo)
				});
				~compensateEnv.if({
					(time - ((ev[\attack] - ev[\decay]) * ~compensateAmount)).max(0.001)
				}, { time });
			})
		]
	};
}) => PR(\break);

AbstractChuckArray.defaultSubType = saveSubType;

// a simple soundfile-segment player
// uses bufPerc's buffer management methods but constructs events from streams, not arrays

PR(\abstractProcess).v.clone({
	~event = (eventKey: \singleSynthPlayer);
	~requiredKeys = #[bufPaths];
	~def = \bufGrain;
	~bufCoords = #[[0, -1]];
	~attack = 0.005;
	~decay = 0.02;
	~argPairs = [];	// there must be a default or ~argPairsStream fails
	~postMCCreation = nil;		// put in your own user preparation func here
	~timeConversion = { |time, ev| time };
	~argPairs_ = { |args|
		~argPairs = args;
		~argPairsStream = Pbind(*~argPairs).asStream;
	};
		// required: put in a pattern factory here
	~asPattern = {
			// assume that if we're calling asPattern, we want to reset all streams
		~sendSynthDef.value;
		~argPairsStream = Pbind(*~argPairs).asStream;
		Pbind(\instrument, BPStream(\def),
			\bufIndex, BPStream(\bufIndex),
			\bufnum, Pfunc({ |ev| ~buffers[ev[\bufIndex]].bufnum }),
			\time, BPStream(\time).collect({ |time, ev| ~timeConversion.(time, ev) }),
			\rate, BPStream(\rate),
			\start, BPStream(\start),
			\amp, BPStream(\amp),
			\attack, BPStream(\attack),
			\decay, BPStream(\decay),
			\chan, ~chan,
			\delta, BPStream(\delta),
			\time, Pkey(\time) / Pfunc({ thisThread.clock.tempo })
		).collect({ |ev|
			~argPairsStream !? { ev = ~argPairsStream.next(ev) };
			ev
		});
	};
}).import((bufPerc: #[prep, loadBufs, fixBufTime, replaceBuf, addBuf, freeCleanup]))
	=> PR(\basicBufferPlayer).subType_(\bufPlayer);



// Basically deprecated. This scheme was too complicated and prone to break.
// Use at your own risk. Good luck!

var saveSubtype = AbstractChuckArray.defaultSubType;

AbstractChuckArray.defaultSubType = \contrapunct;

// converts event stream into event pattern so that other wrappers like Pfindur can be used
{ |holder, driverEvent|
	Prt({ |inEvent|
		var	event;
		loop {
			event = holder.getEvent(inEvent, driverEvent);
			inEvent = event.yield;
		}
	})
} => Func(\defaultStreamWrapper).subType_(\contrapunct);

{ |pattern| pattern } => Func(\defaultPatternWrapper);

{ |pattern| Pfin(1, pattern) } => Func(\oneChildEvent);

// args: child event, bpholder, driver event
{ |event| event } => Func(\defaultEventUpdater);

// a holder for a process that is being driven by another
// most important parms:
// modifyDriver -- a func to parse the driver event before wrapping
// swrapPattern -- wrap the bp's stream to make it a pattern
// pwrapPattern -- wrap the pattern to modify its output (Pfindur is applied automatically)
// updatePattern -- modify each child event before returning
// quant -- when to start child if coordinator is playing and child is not
PR(\abstractProcess).v.clone({
	~prepare = { |bp, parms|
		var	parmsToInsert;
		~bp = bp;
			// scorched-earth handling of parms; eventually I'll add safety checks?
		parmsToInsert = bp.v.coordParms ?? { IdentityDictionary.new };
		parms.respondsTo(\keysValuesDo).if({ parmsToInsert.putAll(parms); });
		currentEnvironment.putAll(parmsToInsert);
		(bp.v.alwaysReset == true).if({ ~doReset = true });
		~makeStreamForKey.(\swrap);
		~makeStreamForKey.(\pwrap);
		~makeStreamForKey.(\update);
		bp.v.isDriven = true;
		~wasPlaying = bp.isPlaying;
		bp.v.isPlaying = false;
		~inited = false;
		bp.addDependant(currentEnvironment);	// get notifications from child process
		bp.changed(\driven);
		currentEnvironment
	};

	~prepForPlay = { 
		~inited.not.if({
			~bp.v.eventStreamPlayer.isNil.if({
				~bp.prepareForPlay;
			}, {
				~bp.populateAdhocVariables;
			});
		});
		~inited = true;
		currentEnvironment
	};

	
	~update = \defaultEventUpdater.asPattern;
	~swrap = \defaultStreamWrapper.asPattern;
	~pwrap = \defaultPatternWrapper.asPattern;
	
		// =>.swrap for func to wrap the child stream in a pattern
	~wrapChildStream = { |driverEvent|
		var	pattern = Func(~swrapStream.next(driverEvent)).doAction(driverEvent);
			// if the next child event was supposed to happen some time after the sync point,
			// add a dummy event to compensate
			// nextSync is unchanged from the last driver event
		(~autoOffset and: { 
				~nextChildEventTime.isNumber and: {
				~nextSync.isNumber and: {
				~nextChildEventTime > ~nextSync } } }).if({
			Pseq([(play: 0, delta: ~nextChildEventTime - ~nextSync), pattern], 1)
		}, {
			pattern
		});
	};
	
		// user hook to provide a Pbindf or other processing
	~wrapPattern = { |pattern, driverEvent|
		pattern
	};
	
		// =>.pwrap for func to wrap the pattern holding the stream
		// modifyDriver should set offset
	~prWrapPattern = { |pattern, driverEvent|
		var	deltaToNextSync = driverEvent.deltaToNextSync;
		pattern = Func(~pwrapStream.next(driverEvent)).doAction(pattern, driverEvent)
			? pattern;
		pattern = ~wrapPattern.(pattern, deltaToNextSync);
//		((~truncatePattern ? true) and: { deltaToNextSync.notNil }).if({
		deltaToNextSync.notNil.if({
			Pfindur(deltaToNextSync, pattern)
		}, {
			pattern
		});
	};
	
	~event = { ~bp.v.event };

	~getEvent = { |inEvent, driverEvent|
		var	event = ~bp.v.eventStream.next(~event.value);
//thisThread.clock.beats.debug("bpholder-getEvent");
//event.debug("bpholder-getEvent");
//event[\note].postcs;
//event[\play].postcs;
		event = event !? { Func(~updateStream.next(driverEvent))
			.doAction(event, /*currentEnvironment,*/ driverEvent)/*.debug("return value from func")*/ ? event };
		~nextChildEventTime = event.notNil.if({ thisThread.clock.beats + event.delta }, { nil });
//event.debug("output event");
		event
	};
	
//	~nextSync = ~nextChildEventTime = 0;
	~autoOffset = true;
	~wasTriggeredExternally = false;
	~offset = 0;
	~lastOffset = 0;	// this is the offset from the previous event

	~doEvent = { |driverEvent, childMetaEvent|
		var	inEvent, /*event, */pattern;

			// processDriverEvent goes false when the child is released by .stop or .play
			// in that case, we should ignore the driver event
		(~processDriverEvent ? true)/*.debug("child event for %".format(~bp.collIndex))*/.if({
			~prepForPlay.value;
				// modifyDriver must set the offset
			~lastDriverEventID = driverEvent[\ID];
			driverEvent = ~modifyDriver.(driverEvent.copy, childMetaEvent) ? driverEvent;
//[thisThread.clock.beats, driverEvent.delta, ~offset, ~lastOffset, driverEvent.delta + ~offset - ~lastOffset].debug("now, delta, offset, lastOffset, deltaToNextSync");
			driverEvent.put(\deltaToNextSync, driverEvent.delta + ~offset - ~lastOffset);
//driverEvent.debug("driverEvent");
			(driverEvent.skipChildren.tryPerform(\includes, ~bp.collIndex) ? false).not.if({
				inEvent = ~bp.v.event.copy.put(\driver, driverEvent);
				~bp.v.driverEvent = driverEvent;
//inEvent.debug("inEvent");

				pattern = ~wrapChildStream.(driverEvent, childMetaEvent);
//pattern.asCompileString.debug("wrapChildStream result");
				pattern = ~prWrapPattern.(pattern, driverEvent, childMetaEvent);
//pattern.asCompileString.debug("prWrapPattern result");

// what is the termination condition? may have to use CleanupStream
// no -- register as dependent of bp
	
					// play the child until the next sync point
				thisThread.clock.sched(0,
					~eventStreamPlayer = PausableEventStreamPlayer(pattern.asStream, inEvent)
						.refresh);
			});
			
			~lastOffset = ~offset;
			~nextSync = thisThread.clock.beats + driverEvent[\deltaToNextSync];

			(process: ~bp.collIndex, delta: driverEvent.deltaToNextSync);
		});
	};
	
	~abortStream = {
		~eventStreamPlayer.stop;
	};

	~update = { |obj, changer|
//this.dumpBackTrace;
//[obj.asCompileString, changer].debug("bpholder-update");
		case { #[\play, \stop].includes(changer) } {
						// set flag to return a nil metaevent next time
					~processDriverEvent = false;
					~wasPlaying = (changer == \play);
					~wasTriggeredExternally = true;
					currentEnvironment.changed(\lostChild);
				}
			{ changer == \driven } {
					~processDriverEvent = true;
				}
			{ changer == \free } {
					~abortStream.value;
					~wasPlaying = false;
					~wasTriggeredExternally = true;
					~processDriverEvent = false;
					currentEnvironment.changed(\lostChild);
				}
	};
	
	// more...
}) => PR(\bpHolder).subType_(\contrapunct);

PR(\abstractProcess).v.clone({
	~childProto = \bpHolder;
	~alwaysReset = true;	// once I stop, my event stream is invalid
	~event = (eventKey: \dummy);
		// using PQ because children may offset their sync points
		// and occur earlier or later than the next driver event
	~prep = { 
		~children = IdentityDictionary.new;
		~queue = PriorityQueue.new;
		~driverEventID = 0;
	};
	
		// what else? prepare for play?
	~driver_ = { |bp|
		var syncTime;
		(~driver !== bp).if({
			~driver.notNil.if({
				~releaseDriver.value;
			});
			~driver = bp;
			~clock.isNil.if({
				~clock = ~driver.v.clock;
			}, {
				(~clock != ~driver.v.clock).if({
					"Clocks do not match. There may be scheduling problems.".warn;
				});
			});
			bp.v.isDriven = true;
			~driverWasPlaying = bp.isPlaying;
			bp.v.eventStreamPlayer.isNil.if({
				bp.prepareForPlay;
			}, {
				bp.populateAdhocVariables;
			});
				// automatically play coordinator if the driver was playing and I am not
				// so that the driver proceeds seamlessly
			((syncTime = bp.v[\eventStreamPlayer].tryPerform(\nextBeat)).notNil 
					and: { ~isPlaying.not }).if({
				BP(~collIndex).play(argQuant: AbsoluteTimeSpec(syncTime));
				bp.v.eventStreamPlayer.stop;
	//			bp.stopNow(notify: false, doCleanup: false);
			});
			bp.changed(\driven);
			bp.addDependant(currentEnvironment);
		});
		currentEnvironment
	};
	
		// release driver from control -- should not be called directly by user
	~releaseDriver = { |doReplay|
		var	syncTime, nextEvent, oldStream;
		~driver.notNil.if({
			~driver.removeDependant(currentEnvironment);
			~driver.v.isDriven = false;
			~driver.v.eventStream = Pevent(Pseq([~nextEvent, ~driver.v.eventStream], 1),
				~driver.v.event).asStream;
			~driver.v.eventStreamPlayer = PausableEventStreamPlayer(~driver.v.eventStream,
				~driver.v.event).refresh;
			((doReplay ? true) and: { ~driver.v.eventStream.notNil
				and: { (syncTime = ~nextSyncTime.(~saveCurrentEvent)).notNil
				and: { syncTime >= ~driver.v.clock.beats } } }).if({
//~nextEvent[\note].asString.debug("nextevent's note");
//"making new event stream".debug;
				~driver.v.clock.schedAbs(syncTime, ~driver.v.eventStreamPlayer);
				~driver.v.isPlaying = true;
			}, {
				~driver.v.isPlaying = false;
			});
			~driver.changed(#[stop, play][~driver.isPlaying.binaryValue]);
			~driver = nil;
		});
		currentEnvironment
	};
	
	~add = { |bp, parms|
		var	nextSync, childObj, proto = parms.atBackup(\childProto, currentEnvironment);
		(bp.exists and: { bp !== ~driver }).if({
			~children.put(bp.collIndex, childObj = PR(proto).v.copy.prepare(bp, parms));
			childObj.addDependant(currentEnvironment);
			(~clock != bp.v.clock).if({
				"Clocks do not match. There may be scheduling problems.".warn;
			});
				// if I am playing and I know when I am going to fire next
			(~isPlaying and: { (nextSync = ~nextSyncTime.value).notNil }).if({
					// is the bp playing? if so, help it make the transition
				childObj.wasPlaying.if({
					~clock.schedAbs(nextSync - 0.05, {
						childObj.nextSync = nextSync;
						childObj.nextChildEventTime = bp.v.eventStreamPlayer
							.tryPerform(\nextBeat);
						nil
					});
//nextSync.debug("nextSync");
//thisThread.clock.beats.debug("current LT");
					~addChildToQueue.(childObj, nextSync);
				}, {		// else start the child on its normal quant
						// run normally until the following sync point
//bp.eventSchedTime(childObj.quant).debug("starting % play at".format(bp.collIndex));
					bp.play(childObj.quant, ~clock, childObj.doReset, notify: false);
					~clock.schedAbs(bp.eventSchedTime(childObj.quant) - 0.05, e {
//						currentEnvironment.use({
							(nextSync = ~nextSyncTime.value).notNil.if({
//thisThread.clock.beats.debug("now");
//nextSync.debug("adding child to queue for sync time");
								~addChildToQueue.(childObj, nextSync);
							}, {
								bp.stopNow;
							});
//						});
					});
				});
			});
		}, {
			"% is already the driver, can't add as child.".format(bp.asCompileString).warn;
		});
	};
	
		// this is sufficient because routine will not refresh the child in the queue
		// if it can't find it in the ~children dictionary
	~removeChild = { |key, freeing|
		var bpwrap = ~children.removeAt(key), syncTime, esp;
		bpwrap.notNil.if({
			bpwrap.bp.removeDependant(bpwrap);
			bpwrap.removeDependant(currentEnvironment);
			bpwrap.bp.v.isDriven = false;
				// to restart the child's native stream,
				// - I must be playing (or been freed at this logical time)
				// - the child must have been playing before becoming my slave
				//   or it must have been .played directly
			((~isPlaying ? false) or: { ~wasPlayingWhenFreed ? false }).if({
				(bpwrap.wasPlaying/*.debug("removechild-wasplaying")*/).if({
						// wasTriggeredExternally == true on .play or .stop on the child BP
					bpwrap.wasTriggeredExternally/*.debug("wasTriggeredExternally")*/.if({
							// there's some time left before the .play kicks in
						((syncTime = ~nextSyncTime.value/*.debug("nextSync")*/) < bpwrap.bp.eventSchedTime/*.debug("eventSchedTime")*/)
						/*.debug("there is time remaining")*/.if({
								// run the stream in the interim
								// by copying the eventstreamplayer, I ensure that the
								// "real" eventstreamplayer can be restarted in BP-play
// some of this should be delegated to bpholder
							~clock.schedAbs(syncTime - 0.03, {
//bpwrap.nextChildEventTime.debug("running filler stream");
								bpwrap.bp.v.clock.schedAbs(bpwrap.nextChildEventTime,
									esp = bpwrap.bp.v.eventStreamPlayer.refresh.copy);
//(bpwrap.bp.eventSchedTime - 0.03).debug("will stop filler stream");
								bpwrap.bp.v.clock.schedAbs(bpwrap.bp.eventSchedTime - 0.03,
									{ esp.stop; nil });
								nil
							});
						}, {
//(bpwrap.bp.eventSchedTime - 0.03).debug("scheduling abortStream for");
							bpwrap.bp.v.clock.schedAbs(bpwrap.bp.eventSchedTime - 0.03,
								{ bpwrap.abortStream; nil });
						});
					}, {		// removeChild was called directly
						bpwrap.abortStream;
						bpwrap.bp.v.clock.schedAbs(bpwrap.nextChildEventTime,
							bpwrap.bp.v.eventStreamPlayer.refresh);
						bpwrap.bp.v.isPlaying = true;
							// this is ok b/c child dependencies are already gone
						bpwrap.bp.changed(\play);
					});
				});
			});
				
			bpwrap.bp.changed(#[stop, play][bpwrap.bp.isPlaying.binaryValue]);
		});
		currentEnvironment
	};
	
	~bindBP = { |bp, adverb, parms|
		(adverb == \driver).if({
			~driver_.(bp);
		}, {
			~add.(bp, parms);
		});
		currentEnvironment
	};
	
	~nextSyncTime = { |event|
		event = event ? ~currentEvent;
		event !? {
			event.nextSyncTime
				?? { ~eventStreamPlayer.tryPerform(\nextBeat) }
//				?? { event.delta + ~eventStreamPlayer.clock.beats }
		};
	};
	
	~addChildToQueue = { |child, time|
		var	nextChildEventTime;
			// take the bp out of the clock's queue; don't notify dependents
			// but only do it if the child is still accepting events
		time/*.debug("calling addChildToQueue for time")*/.notNil.if({
			(child.processDriverEvent/*.debug("child.processDriverEvent")*/ != false).if({
				~clock.schedAbs(time - 0.03, {
//thisThread.clock.beats.debug("updating nextSync at time");
					(nextChildEventTime = child.bp.v.eventStreamPlayer
							.tryPerform(\nextBeat))/*.debug("nextChildEventTime")*/.notNil.if({
						child.nextChildEventTime = nextChildEventTime;
						child.nextSync = time;
					});
					(child.wasPlaying ? false).if({
//thisThread.clock.beats.debug("stopping child ESP at");
						child.bp.stopNow(notify: false, doCleanup: false);
						nil
					});
					(child.doReset ? false).if({ child.bp.reset });
				});
			});
		}, {
			(child.wasPlaying ? false).if({
//thisThread.clock.beats.debug("stopping child ESP at");
				child.bp.stopNow(notify: false, doCleanup: false);
			});
		});
//(time ? thisThread.clock.beats).debug("child is added for sync time");
		child.bp.v.eventSchedTime = time ? thisThread.clock.beats;
		~queue.put(child.bp.v.eventSchedTime, (process: child.bp.collIndex));
	};

		// should be called only in the context of my event stream
	~prepareQueue = { |time|
		~children.keysValuesDo({ |key, bp|
			~addChildToQueue.(bp, time ? ~nextSyncTime.value ? thisThread.clock.beats);
		});
		~stream = (~driver.v.eventStream ?? { ~driver.asStream });
//(time ? thisThread.clock.beats).debug("adding driver to queue");
		~queue.put(time ? thisThread.clock.beats, (process:\driver));
		(play:0, delta:0)
	};
	
	~popEvents = { 
		var	out = List.new, time;
		~queue.notEmpty/*.debug("queue has items")*/.if({
				// if there are stray events in the queue, drop them
			{ thisThread.clock.beats > ~queue.topPriority }.while({
				~queue.pop/*.debug("dropped event")*/;
			});
			time = ~queue.topPriority/*.debug("top priority")*/;
			{ time == ~queue.topPriority }.while({
				out.add(~queue.pop);
			});
//"\n".post;
//out.do(_.postln);
				// driver must execute first
			out.sort({ |a, b|
				(a.process == \driver).binaryValue > (b.process == \driver).binaryValue
			});
		});	// if queue is empty, return nil
	};
	
	~nextDriverID = { ~driverEventID = ~driverEventID + 1 };
	
	~doDriverEvent = { 
		var	event;
		(~driver.notNil and: { (event = ~stream.next(
				~driver.v.event.copy.put(\children, ~children.copy))).notNil }).if({
			event.put(\ID, ~nextDriverID.value);
			~nextEvent.isNil.if({
				~currentEvent = event;
				~nextEvent = ~stream.next(~driver.v.event.copy.put(\children, ~children.copy))
					.put(\ID, ~nextDriverID.value);
			}, {
				~currentEvent = ~nextEvent;
				~nextEvent = event;
			});
		});
//~currentEvent[\note].asString.debug("currentevent note");
//~nextEvent[\note].asString.debug("nextevent note");
		~currentEvent.notNil.if({
			~currentEvent.play;
			~currentEvent.put(\process, \driver)
				.put(\now, thisThread.clock.beats)
				.put(\nextSyncTime, thisThread.clock.beats + ~currentEvent.delta);
//~currentEvent.debug("\ndriver event");
//thisThread.clock.beats.debug("now");
//~currentEvent.nextSyncTime.debug("nextSyncTime");
			~currentEvent
		}, {
			nil.yield;	// stop immediately when driver returns nil
		});
	};
	
	~doChildEvent = { |evt|
		var	child = ~children[evt.process];
		child.notNil.if({
				// child's job to return the metaevent for my PQ, including offset
			child.tryPerform(\doEvent,
				(child.lastDriverEventID == ~currentEvent[\ID]).if(~nextEvent, ~currentEvent),
				evt);
		});
	};

	~asPattern = { 
		// how to initialize the child streams just before play?
		~eventSchedTime/*.debug("bpdriver-aspattern-eventschedtime")*/.notNil.if({
			~clock.schedAbs(~eventSchedTime - 0.05, e {
//"calling prepareQueue".debug;
				~prepareQueue.(~eventSchedTime/*.debug("eventSchedTime")*/);
			});
		});
		Prt({
			var	queueList, event;
//			~driverWasPlaying = true;
			loop {
				((queueList = ~popEvents.value).size > 0).if({
//queueList.postcs;
					queueList.do({ |evt|
						(evt.process == \driver).if({
							event = ~doDriverEvent.value;
						}, {
							event = ~doChildEvent.(evt);
							event.isNil.if({
"removing child % because event was nil".debug(evt.process.tryPerform(\at, \bp).value.tryPerform(\at, \collIndex));
								~removeChild.(evt.process);
							});
						});
						
							// not stopping on nil event here because
							// the end of a child stream shouldn't affect other children
						event.notNil.if({
								// put continuation in the queue
							~queue.put(thisThread.clock.beats + event.delta, event);
						});
					});
				}, {
					~queue.isEmpty.if({
						nil.yield		// terminate if nothing is in the queue
					});
				});
				
				(~queue.topPriority > thisThread.clock.beats).if({
					(play:0, delta: ~queue.topPriority - thisThread.clock.beats).yield;
				}, {		// something is wrong with the queue, so abort
					"Queue top priority is %, before current time %. Aborting."
						.format(~queue.topPriority, thisThread.clock.beats).warn;
					nil.yield;
				});
			}
		});
	};
	
	~stopCleanup = { |auto|
//"bpdriver-stopCleanup".debug;
//		auto.if({
//			~resumeChildren.value;
//		});
		~children.do(_.abortStream);
		~queue.clear;  // events in the queue are now invalid
		~stopAction.value;	// user-definable
		~saveCurrentEvent = ~currentEvent;	// for restarting driver & children upon free
		~currentEvent = nil;
		currentEnvironment
	};
	
	~freeCleanup = { 
"bpdriver-freeCleanup".debug;
		~children.keys.do({ |key|
//key.debug("setting wasPlaying, removing child");
			~children[key].wasPlaying = ~wasPlayingWhenFreed;
			~removeChild.(key, true);	// true == removing child on free
		});
//"releasing driver".debug;
		~releaseDriver.value;
		currentEnvironment
	};
	
	~update = { |changer, what|
		switch(what)
			{ \lostChild } { 
"removing child because of lostChild".debug(changer.bp.collIndex);
			~removeChild.(changer.bp.collIndex) }
			{ \reset } {   // resync current/next events
				(changer === ~driver).if({	// but only if the driver was reset
					~nextEvent = nil
				})
			}
			{ \free } {
				(changer === ~driver).if({
					~releaseDriver.value;
				});
			}
	};
}) => PR(\bpDriver).subType_(\contrapunct);


PR(\bpHolder).v.clone({
		// child processes should not have .prepareForPlay called on them
	~prepForPlay = {
		(~inited ? false).not.if({
			~bp.v.event = ~bp.prepareEvent;
			~bp.populateAdhocVariables(thisThread.clock);
		});
		~inited = true;
	};
	
	~doEvent = { |driverEvent, childMetaEvent|
		var	inEvent, pattern;

			// processDriverEvent goes false when the child is released by .stop or .play
			// in that case, we should ignore the driver event
		(~processDriverEvent ? true).if({
			~prepForPlay.value;
				// modifyDriver must set the offset
			~lastDriverEventID = driverEvent[\ID];
			driverEvent = ~modifyDriver.(driverEvent.copy, childMetaEvent) ? driverEvent;
			driverEvent.put(\deltaToNextSync, driverEvent.delta + ~offset - ~lastOffset);
			(driverEvent.skipChildren.tryPerform(\includes, ~bp.collIndex) ? false).not.if({
				inEvent = ~bp.v.event.copy.put(\driver, driverEvent);
				~bp.v.driverEvent = driverEvent;
				
				~bp.v.preparePlay;
				~bp.v.eventStream = ~bp.v.asPattern(driverEvent).asStream;

				pattern = ~wrapChildStream.(driverEvent, childMetaEvent);
				pattern = ~prWrapPattern.(pattern, driverEvent, childMetaEvent);

					// play the child until the next sync point
				thisThread.clock.sched(0,
					~eventStreamPlayer = PausableEventStreamPlayer(pattern.asStream, inEvent)
						.refresh);
			});
			
			~lastOffset = ~offset;
			~nextSync = thisThread.clock.beats + driverEvent[\deltaToNextSync];

			(process: ~bp.collIndex, delta: driverEvent.deltaToNextSync);
		});
	};
}) => PR(\bpArpegHolder).subType_(\contrapunct);


AbstractChuckArray.defaultSubType = saveSubtype;



// other basic functions

// make a set of wavetables for vosc3map to avoid aliasing
// user's responsibility to set numbufs and lowMidi appropriately

{ |numbufs, server, numFrames, lowMidi, spectrumFunc|
	numbufs = numbufs ? 8;
	server = server ? Server.default;
	numFrames = numFrames ? 2048;
		// default is sawtooth
	spectrumFunc = spectrumFunc ? { |numharm| (1..numharm).reciprocal };
	lowMidi = (lowMidi ? 48) / 12;
	
	Buffer.allocConsecutive(numbufs, server, numFrames, 1, { |buf, i|
		var	base = (i + lowMidi) * 12,
			numharm = (20000 / base.midicps).asInteger;
		buf.sine1Msg(spectrumFunc.(numharm));
	});
} => Func(\makeWavetables);


// basic arpeggiators, macro- and micro-rhythms

// C major
ModalSpec(#[0, 2, 4, 5, 7, 9, 11], 12, 0) => Mode(\default);
ModalSpec(#[0, 2, 3, 5, 7, 8, 10], 12, 0) => Mode(\cmin);

// arpeggiation patterns

#{ |notes| Pseq(notes, inf) } => ArpegPat(\asis);
#{ |notes|
	notes.isArray.if({
		Pn(notes.asChord, 1)
	}, {
		Pn(notes, 1)
	});
} => ArpegPat(\block);
#{ |notes| Pxrand(notes, inf) } => ArpegPat(\xrand);
#{ |notes| Pseq(notes.sort, inf) } => ArpegPat(\up);
#{ |notes| Pseq(notes.sort({ |a, b| a > b }), inf) } => ArpegPat(\down);
#{ |notes| Pseq([notes.sort, notes+7, notes+7, notes+14, notes+14].flat, 1) } => ArpegPat(\bubbleup);
#{ |notes| Pseq([(notes = notes.sort.reverse) + 14, notes+7, notes].flat, 1) } => ArpegPat(\bubbledown);

#{ |notes| Pseq(notes.sort, 1) } => ArpegPat(\up1);
#{ |notes| Pseq(notes.sort({ |a, b| a > b }), 1) } => ArpegPat(\down1);

{ |notes| Pshuf(notes, 1) } => ArpegPat(\shuf1);
{ |notes| Pshuf(notes, inf) } => ArpegPat(\shuf);

// microrhythms

#{ |notes, event|
	var topNote, gateIndex, gate;
	topNote = event[\top];
	Pn([event.delta, event[\length], topNote.tryPerform(\gate) ? 0.5], 1)
} => MicRh(\blockFollow);

#{ |notepat| Pn(#[0.25, 0.2, 0.5], notepat.estimateLength) } => MicRh('16th');
#{ |notepat| Proutine({
	var delta;
	notepat.estimateLength.do({ |i|
		[delta = 0.2 - ((i * 2pi/25).sin * 0.125), delta, 0.75-delta].yield;
	});
}) } => MicRh(\sine);

// macrorhythms
Pn(12, inf) => MacRh(\m3);


// pattern-based topnote process
// usage:
// ... make chord process in BP(\ch) ...
// BP(\ch).v.topNote = PR(\patternTop).v.copy.make({
//	~deg = pattern;
//	~delta = pattern;	// may be omitted if you use macrorhythm
//	~length = pattern;	// may be omitted if you use macrorhythm
// });

PR(\abstractProcess).v.clone({
	~mode = \default;
	~delta = 1;	// need defaults (will be ignored for macrorhythm chord processes)
	~length = 1;
	~gate = 0.5;
	~asPattern = { 
		Pbind(
			\freq, BPStream(\deg),
			\delta, BPStream(\delta),
			\length, BPStream(\length),
			\mode, Pfunc({ ~mode }),
			\gate, BPStream(\gate)
		);
	};
}) => PR(\patternTop);




var	subtype = AbstractChuckArray.defaultSubType;
AbstractChuckArray.defaultSubType = \fftTransient;

Proto({
	~keysFromParent = #[checkMinPeak, minPeak, window, imag, cos, melfreqsize, melmap,
		fftsmooth, slopedist, slopesmooth, halffft];
	
		// note, parent must NOT be stored in this environment
		// it's used only to get the shared variables
	~prep = { |audio, index, parent|
		~audio = audio;
		~index = index;
		~keysFromParent.do({ |key| key.envirPut(parent[key]) });
		currentEnvironment
	};
	
		// buf will be used in the buffer-based version
	~getfft = { 
		var	srcfft, peak, melfft;

		~peak = ~audio.abs.maxItem;
		((~checkMinPeak and: { ~peak >= ~minPeak }) or:
				{ ~checkMinPeak.not and: { ~peak > 0 } }).if({
			~fhzfft = ~audio / ~peak * ~window;
			~fhzfft = ~fhzfft.as(Signal).fft(~imag, ~cos);
			~fhzfft = ~fhzfft.magnitude[..~halffft-1];
			~srcfft = Array(~melfreqsize);
			~melmap.doAdjacentPairs({ |a, b|
				~srcfft.add(~fhzfft[a..b-1].mean);
			});
			~srcfft = ~srcfft.avgsmooth(~fftsmooth);
			
			currentEnvironment
		});	// returns nil if peak condition not met
	};
	
	~fftPostProcessing = { 
		var	fft = ~srcfft,
			slopes = Array.new(fft.size - ~slopedist),
			peaks = List.new,	// stores index and magnitude of peak
			peakIndices = List.new;

			// (crudely) differentiate the fft magnitudes and smooth the curve
		(fft.size - ~slopedist).do({ |i|
			slopes.add(fft[i + ~slopedist-1] - fft[i]);
		});
		slopes = slopes.avgsmooth(~slopesmooth);

			// identify where slope changes from + to -
			// a peak will be roughly around that index + (slopediff+slopesmooth / 2)
			// if i == 0, compareData will return inf no matter what the comparand
		slopes.doAdjacentPairs({ |a, b, i|
			((a >= 0) and: { b < 0 and: { i > 0 } }).if({
				peaks.add((index: i, magnitude: fft[i .. i+~slopedist+~slopesmooth].maxItem));
				peakIndices.add(i);
			});
		});
		
			// save data in the right place
		~slopes = slopes;
		~peaks = peaks.array;
		~peakIndices = peakIndices.array;
		currentEnvironment
	};
	
	~absRatio = { |a, b|
		(a.abs > b.abs).if({ a / b }, { b / a });
	};

		// a replacement for nearestInList that does not permit repeated matches
		// returns elements in b that are closest to elements in a
		// a.size <= b.size or the method will fail
	~nearInListExclusive = { |a, b|
		var	out, index;
		(a.size <= b.size).if({
			out = Array.new(a.size);
			b = b.copy;	// array will be changed
			a.do({ |item|
				(index = b.indexIn(item)).notNil.if({
					out.add(b[index]);
					b.removeAt(index);
				}, {
					Error("nearInListExclusive failed, no match for % in %."
						.format(item, b)).throw;
				});
			});
			out
		}, {
			Error("nearInListExclusive failed, a must be shorter than b.").throw;
		});
	};

	~compareData = { |comparisonfft|
		var	data1, data2, matchedIndices, matchedPeaks, out = 0;

			// which is shorter?
		(~peaks.size <= comparisonfft.peaks.size).if({
			data1 = currentEnvironment;
			data2 = comparisonfft;
		}, {
			data1 = comparisonfft;
			data2 = currentEnvironment;
		});

			// peak indices in data2 that are closest to the indices in data1
		matchedIndices = ~nearInListExclusive.(data1.peakIndices, data2.peakIndices);
			// peak objects at those indices
		matchedPeaks = data2.peaks[matchedIndices.collectIndicesFromArray(data2.peakIndices)];

			// now some numeric hackery
			// divide larger by smaller and take average of quotients
			// weight by quotient of peak magnitudes
		data1.peaks.do({ |p1, i|
			var	ind = ~absRatio.(p1.index, matchedPeaks[i].index),
				mag = ~absRatio.(p1.magnitude, matchedPeaks[i].magnitude);
			out = out + (ind * mag * (data1.peaks.size - i));
		});
		
			// if no peaks, this will be 0 / 0, replace with inf
			// just return, parent's job to save into the matrix
		(out = (out / matchedPeaks.size * ~absRatio.(data1.peaks.size, data2.peaks.size)))
			.isNaN.if(inf, out);
	};
	
		// remove most expensive memory consumers
		// preserve data (peaks, peakIndices) needed for comparison
		// usually you should collect garbage UNLESS you are debugging
	~collectGarbage = { |doGC|
		(doGC ? true).if({
			~fhzfft = nil;
			~srcfft = nil;
			~slopes = nil;
			~audio = nil;
			~keysFromParent.do({ |key|
				currentEnvironment.removeAt(key);
			});
		});
	};

}) => PR(\fftDataProto);

PR(\abstractProcess).v.clone({
	~event = (eventKey: \dummy);

		// can add stuff here
	~dataProto = \fftDataProto;

	~fftsmooth = 8;
	~slopedist = 3;
	~slopesmooth = 5;
	
	~minPeak = 0.1;
		// this is, checkMinPeak of each time point -- the peak of the whole buffer is always checked
	~checkMinPeak = false;
	
	~postProgress = false;	// post status updates?
	~garbageCollection = true;

		// getfft converts to mel frequencies for better analysis
	~freqToMel = { |fhz|
		1127.01048 * log(1 + (fhz/700))
	};
	
	~melToFreq = { |mel|
		exp(mel / 1127.01048) - 1 * 700
	};

	~fftwait = 0.001;
	~cmpwait = 0.0000001;
	~clock = AppClock;		// do not need musical precision
	~quant = NilTimeSpec.new;
	~reuseCleanup = true;
	
	~startAnalysis = { |path, pts, fftsize|
		~isPlaying.if({
			"BP(%) is still analyzing %. Cannot start a new file."
				.format(~collIndex.asCompileString, ~path);
		}, {
			~path = path;
			~pts = pts;
			~fftsize = fftsize ? 2048;
			BP(~collIndex).play(doReset: true);
		});
	};
	
	~asyncHang = { 
		~saveEventStreamPlayer = ~eventStreamPlayer;
		nil.yield;
	};
	
	~asyncUnhang = { 
		~eventStreamPlayer = ~saveEventStreamPlayer;
		~clock.sched(0, ~eventStreamPlayer.refresh);
		~isPlaying = true;
	};

		// SoundFile-based is synchronous but buffers might be async
		// getAudioData should send the messages to get the data, then call ~asyncHang
		// the following method is synchronous
	~getAudioData = { |time|
		var	result;
		~file.seek(time * ~sampleRate.value, 0);
		result = FloatArray.newClear(~fftsize);
		~file.readData(result);
		(result.size == ~fftsize).if({
			result
		}, {
			"Soundfile read failed, asked for % samples and got %."
				.format(~fftsize, result.size).warn;
			nil
		});
	};

	~initIndexPair = {
		~indexpair = Routine({
			(~pts.size - 1).do({ |i|
				(i+1 .. ~pts.size - 1).do({ |j|
					[i, j].yield;
				});
			});
		});
	};

	~makeWindow = {  Signal.hanningWindow(~fftsize) };

	~sampleRate = {  ~file.sampleRate };

	~preparePlay = { 
		var	resolution, melreso, mel, fhz, melNyquist;

		~path !? { ~file = SoundFile.openRead(~path) };

		~fftsize = nextPowerOfTwo(~fftsize);
		~halffft = ~fftsize div: 2;
		~imag = Signal.fill(~fftsize, 0);
		~cos = Signal.fftCosTable(~fftsize);
		
		resolution = ~sampleRate.value / ~fftsize;
		~melfreqsize = (~fftsize * 0.125).nextPowerOfTwo.asInteger;
		melreso = ~freqToMel.(~sampleRate.value * 0.5) / ~melfreqsize;
		
			// melmap[mel_bin_index] == first bin index into fft
		~melmap = Array.fill(~melfreqsize+1, { |i|
			fhz = ~melToFreq.(melreso * i);
			((fhz + (resolution * 0.5)) / resolution).asInteger
		});
		
		~window = ~makeWindow.value;
		
		~analysisComplete = false;
	};

	~initMatrix = { 
		~matrix = Array.fill(~pts.size, { Array.newClear(~pts.size) });
	};
	
	~addToMatrix = { |metric, refindex, cmpindex, matrix, ffts, pts|
		matrix = matrix ? ~matrix;
		ffts = ffts ? ~ffts;
		pts = pts ? ~pts;
		matrix[refindex][cmpindex] = (metric: metric, peak: ffts[cmpindex].peak,
			time: pts[cmpindex], refindex: refindex, index: cmpindex);
		matrix[cmpindex][refindex] = (metric: metric, peak: ffts[refindex].peak,
			time: pts[refindex], refindex: cmpindex, index: refindex);
	};		

		// by now matrix is mostly built, need to fill in the [i, i] diagonal
	~buildMatrix = { 
		~matrix.size.do({ |i|
			~matrix[i][i] = (metric: 1, index: i, refindex: i, peak: ~ffts[i].peak,
				time: ~pts[i]);
		});
		~matrix
	};

	~asPattern = { 
			// normally this should be a pattern but routines made from patterns
			// can't be hung and unhung for async use
			// Routine().asStream === Routine() so it should be OK
		Routine({
			var	audio, srcfft, pair, metric, failed = 0, lastPair0;

			~postProgress.if({
				"BP(%): Calculating ffts and peaks\n".postf(~collIndex.asCompileString);
			});
			~ffts = Array.new(~pts.size);
			~pts = ~pts.copy;
			~pts.copy.do({ |time, i|
				(play: 0, delta: ~fftwait).yield;
					// ~buffer is nil in the file version, but won't be in the buffer version
				audio = ~getAudioData.(time, ~buffer);
				audio.notNil.if({
					srcfft = PR(~dataProto).v.copy.prep(audio, i-failed, currentEnvironment);
						// nil indicates peak check for the clip failed
					srcfft.getfft.notNil.if({
						~ffts.add(srcfft.fftPostProcessing);
						srcfft.collectGarbage(~garbageCollection);
					}, {
						~postProgress.if({
							"BP(%): Timepoint % is not valid.\n"
								.postf(~collIndex.asCompileString, time)
						});
						~pts.removeAt(i - failed);
						failed = failed + 1;
					});
				}, {
					~postProgress.if({
						"BP(%): Timepoint % is not valid.\n"
							.postf(~collIndex.asCompileString, time)
					});
					~pts.removeAt(i - failed);
					failed = failed + 1;
				});
			});

			~postProgress.if({
				"BP(%): % onsets did not meet threshold.\n".postf(~collIndex.asCompileString,
					failed);
			});

			~postProgress.if({
				"BP(%): Comparing ffts\n".postf(~collIndex.asCompileString);
			});
			~initIndexPair.value;
			~initMatrix.value;
			{ (pair = ~indexpair.next).notNil }.while({
					// this func must store comparison in matrix
				(~postProgress and: { pair[0] != lastPair0 }).if({
					"BP(%): Comparing index %, % comparisons.\n".postf(
						~collIndex.asCompileString, pair[0], ~ffts.size - pair[0] - 1);
					lastPair0 = pair[0];
				});
				metric = ~ffts[pair[0]].compareData(~ffts[pair[1]]);
				~addToMatrix.(metric, pair[0], pair[1]);
				(play: 0, delta: ~cmpwait).yield;
			});

			~buildMatrix.value;
			~garbageCollection.value;	// since these run in a routine, they may .wait
			~analysisComplete = true;
				// pattern will stop, control passes to ~stopCleanup
		})
	};

	~userStop = { 
		~file.close;
	};

		// if this is called when analysisComplete is false, the thread is hanging,
		// waiting for async reply
	~stopCleanup = { |streamStopped|
		streamStopped.if({
			(~analysisComplete ? false).if({
				"Analysis complete. Executing action.".postln;
				~userStop.value;
				~clearAsyncResponder.value;
				~action.(~path, ~pts, ~matrix);
			});
		}, {
			"Analysis was aborted. Call .play to resume.".warn;
		});
	};
	
	~freeCleanup = { 
		~clearAsyncResponder.value;
		~userFree.value;
	};
	
		// be careful -- this is NOT threaded and will block other threads until complete
		// it's very fast, though, can write over 180,000 numbers in 1-2 seconds
		// (on a MacBook Pro :)
		// if matrix is size n, first n rows contain the metrics sequentially
		// 2 additional rows for time points and peak amplitudes

		// to restore, do:
		//		(PR(\transient_analysis_file) => BP(\reader)).v.readMatrixFromCSV(path);

	~saveMatrixToCSV = { |path|
		var	file = File(path = path.standardizePath, "w");
		file.isOpen.if({
			~pts.do({ |pt, i|
				file.write(pt.asCompileString);
				(i < (~matrix.size-1)).if({ file.write($,); });
			});
			file.write($\n);
			~matrix[0].do({ |col, i|
				file.write(col.peak.asCompileString);
				(i < (~matrix.size-1)).if({ file.write($,); });
			});
			file.write($\n);
			~matrix.do({ |row|
				row.do({ |col, i|
					file.write(col.metric.asCompileString);
					(i < (row.size-1)).if({ file.write($,); });
				});
				file.write($\n);
			});
			file.close;
		}, {
			Error("saveMatrixToCSV: Could not open % for writing.".format(path)).throw;
		});
	};

	~readMatrixFromCSV = { |path|
		var	raw = CSVFileReader.read(path.standardizePath, true, true, _.asFloat),
			peaks, pts;
		raw.notNil.if({
			~pts = raw[0];
			peaks = raw[1];
			~matrix = { Array.newClear(raw.size-2) } ! (raw.size-2);
			(2..raw.size-1).do({ |i, row|
				raw[i].do({ |col, j|
					~matrix[row][j] = (refindex: row, index: j, metric: col, peak: peaks[j],
						time: ~pts[j]);
				});
			});
			~matrix
		});
	};
	
	~readMatrixFromCSVOldFormat = { |path|
		var	raw = CSVFileReader.read(path.standardizePath, true, true, _.asFloat),
			peaks, pts;
		raw.notNil.if({
			peaks = raw.removeAt(raw.size-1);
			~pts = raw.removeAt(raw.size-1);
			~matrix = { Array.newClear(raw.size) } ! (raw.size);
			raw.do({ |row, i|
				row.do({ |col, j|
					~matrix[i][j] = (refindex: i, index: j, metric: col, peak: peaks[j],
						time: ~pts[j]);
				});
			});
		});
	};
	
	~readRowFromCSV = { |file|
		var	out = List.new,
			char, string = String.new;

		{	char = file.getChar;
			char.notNil and: { "\n\r".includes(char).not }
		}.while({
			case { char == $, } {
				(string.size > 0).if({
					out.add(string.asFloat);
					string = String.new;
				});
			}
			{ string = string.add(char) };
		});
		(string.size > 0).if({
			out.add(string.asFloat);
		});
		out.asArray
	};
	
	~asyncReadFromCSV = { |path, action|
		var file, raw, peaks, size;
		path = path.standardizePath;
		(file = File.new(path, "r")).isOpen.if({
			AppClock.sched(0, Routine({
				protect {
					~pts = ~readRowFromCSV.(file);
					0.01.yield;
					peaks = ~readRowFromCSV.(file);
					size = ~pts.size;
					~matrix = Array.new(size);
					size.do({ |i|
						0.01.yield;
						raw = ~readRowFromCSV.(file);
						~matrix.add(
							raw.collect({ |col, j|
								(refindex: i, index: j, metric: col, peak: peaks[j],
									time: ~pts[j])
							})
						);
					});
					action.value(~matrix);
				} {
					file.close;
				};
			}))
		}, {
			"% could not be opened.".format(path).error
		});
	};
}) => PR(\transient_analysis_file);

PR(\transient_analysis_file).v.clone({
	~sampleRate = {  ~buffer.sampleRate };

	~startAnalysis = { |buffer, pts, fftsize|
		~isPlaying.if({
			"BP(%) is still analyzing %. Cannot start a new file."
				.format(~collIndex.asCompileString, ~buffer);
		}, {
			~buffer = buffer;
			~pts = pts;
			~fftsize = fftsize ? 2048;
			BP(~collIndex).play(doReset: true);
		});
	};

		// asynchronous version to read from a buffer
		// note, if getToFloatArray fails, the thread will stop with error
	~getAudioData = { |time, buffer|
		var	result, startFrame = (time * buffer.sampleRate).asInteger;
		(startFrame < (buffer.numFrames - ~fftsize)).if({
			buffer.getToFloatArray(startFrame, ~fftsize, action: e { |v|
				result = v;
				~asyncUnhang.value;	// getToFloatArray action is not environment-safe
			});
			~asyncHang.value;
			(result.size == ~fftsize).if({
				result
			}, {
				"Buffer read failed, asked for % samples and got %."
					.format(~fftsize, result.size).warn;
				nil
			});
		});
	};

	~userStop = 0;
}) => PR(\transient_analysis_buffer);

// an incremental version for live analysis
// simultaneously receives audio from file or mic, records to a buffer,
// runs a feature detector to get triggers, and queues fft and comparison analyses
// in theory, after recording stops, the matrix should be ready within moments
// used a lot of code from my track "Got an itch to scratch" for multi-buffer support
// "clients" for these buffers can register as dependents of the BP
// and get status updates on the bufs

PR(\transient_analysis_buffer).v.clone({
	~fftID = 0;		// queue elements must have a sequential ID
	~cmpID = 0;
	~errorRecovery = true;		// if an error occurs during comparisons, find and fix afterward
	~iMadeMixer = false;
	~numBufs = 5;
	~bufDur = 10;
	~recording = false;
	~quant = 1;
	~onsetRejectLimit = 0.15;
	~minPeak = 0.175;			// reject a recording if its peak <= this
	~recordActive = true;
	~audioThru = false;		// allow audio from another bus when not recording
							// (always plays thru during recording)
	~audioThruLevel = 1;		// level of audio allowed through (0 will suppress)
	~mixerOutChannels = 2;
	
	~midiTriggerChan = \omni;
	~midiTriggerCtlNum = 64;

	~bufStateProto = (status: \idle, dur: nil, peak: nil, recTime: 0, playCount: 0,
		actionDone: false)
		.parent_(
			(status_: { |thisBufState, status|
				thisBufState[\status] = status;
				thisBufState.changed(\status, status);  // dependents should know when status changes
			})
		);

//////// INITIALIZATION ////////
	
	~sampleRate = {  ~bufs[0].buf.sampleRate };

	~prep = { 
		~chan.isNil.if({
			~chan = MixerChannel(~collIndex, s, 1, ~mixerOutChannels, postSendReady: true,
				outbus: ~master);
			~iMadeMixer = true;
		});

		~bufs = { ~bufStateProto.copy
			.put(\buf, Buffer.alloc(s, (~bufDur ? 10) * s.sampleRate, 1))
			.put(\status, \idle) } ! ~numBufs;

		~fftqueue = PriorityQueue.new;
		~cmpqueue = PriorityQueue.new;
		
		~fftbuf = Buffer.alloc(s, 256, 1);

		~watcher = NodeWatcher.newFrom(s);

		~resp = OSCresponderNode(s.addr, '/tr', e { |t, r, m|
			var	buf;
				// ignore if I don't know about the node
			buf = ~bufs.detect({ |buf| m[1] == buf.node.tryPerform(\nodeID) });
			buf.notNil.if({
				switch(m[2])	// switch is based on SendTrig id arg
					{ -1 } {
						buf.status = \record;
						buf.dur = nil;	// set flags so we know when all messages
						buf.peak = nil;	// have come in
						buf.ontimes = List.new;
						~doOnRecord.(buf);
					}
					{ 0 } {
						buf.status = \stopRec;
						buf.peak = m[3].max(0.01);
						buf.dur.notNil.if({ ~closeRecording.(buf) });
					}
					{ 1 } {
						buf.status = \stopRec;
						buf.dur = m[3];
						buf.recTime = Main.elapsedTime;
						buf.peak.notNil.if({ ~closeRecording.(buf) });
					}
			}, {
				buf = ~bufs.detect({ |buf| m[1] == buf.detectnode.tryPerform(\nodeID) });
				(buf.notNil and: { m[2] == 32 and: { buf.status == \record
						and: { m[3] > 0 } } }).if({
					buf.ontimes.add(m[3]);
					~queueOnsetTime.(buf, m[3], buf.ontimes.size-1);
				});
			});
		}).add;

		~featuredef = ~makeFeatureDetector.value.send(s);
		~inputdef = ~makeInputSource.value.send(s);

		~userprep.value;

		~initFFT.value;

		~triggerdevice = ~makeTrigger.value;
		~startRecord.(~recordActive);
		~lastTrigTime = 0;
	};

	~makeTrigger = { 
			// asClass is used here because you might not have installed the ddwMIDI quark
			// rather than make chucklib depend on the whole MIDI framework,
			// I will use this technique to avoid an error on recompile
		'BasicMIDIControl'.asClass.new(~midiTriggerChan, ~midiTriggerCtlNum, e { |value|
				// seems we need to trap very rapid triggers
			(value > 0 and: { (Main.elapsedTime - ~lastTrigTime) > 1.0 }).if({
				~sendTrigger.value;
			});
		});
	};
	
	~sendTrigger = { 
		s.makeBundle(nil, {
			~recNode !? { ~recNode.set(\t_trig, 1) };
			~detectNode !? { ~detectNode.set(\t_trig, 1) };
		});
		~lastTrigTime = Main.elapsedTime;
	};

	~makeFeatureDetector = {
		SynthDef(\pv_jensen, { |outbus, fftbuf, bufnum, t_trig, faststop = 0,
			propsc = 0.75581395348837, prophfe = 0.43023255813953, prophfc = 0.63953488372093,
				propsf = 0.54651162790698, threshold = 0.058139534883721,
				waittime = 0.15116279069767,
				i_fftwait = 0.05|  // can't do fft analysis until the whole frame is recorded

			var	pc = PulseCount.kr(t_trig),
				start = BinaryOpUGen.new1(\control, '==', pc, 1),
				stop = BinaryOpUGen.new1(\control, '==', pc, 2),
				started = (pc > 0),
				sig = In.ar(outbus, 1),
				fft = FFT(fftbuf, sig),
				dur = Phasor.ar(start, SampleDur.ir, 0, 1000),
				onsettrig;

				// event onset
			onsettrig = PV_JensenAndersen.ar(fft, propsc, prophfe, prophfc, propsf,
				threshold, waittime);
					// delayed to allow entire client fft frame to be recorded before analysis
					// BufDur.kr(fftbuf) * 0.5 is a correction for PV_Jensen's trigger lag
			SendTrig.kr(DelayN.kr(onsettrig, i_fftwait, i_fftwait), 32,
				dur - i_fftwait - (BufDur.kr(fftbuf) * 0.5));

			stop = stop + (started * A2K.kr(dur > BufDur.ir(bufnum))) + faststop;
			FreeSelf.kr(stop);
		});
	};
	
	~detectParms = { |buf| 
		[bufnum: buf.buf.bufnum, fftbuf: ~fftbuf.bufnum, 
			i_fftwait: ~fftsize / ~sampleRate.value, waittime: ~onsetRejectLimit]
	};
	
	~makeInputSource = {
		SynthDef(\trigrecfft, { |bufnum, t_trig, inbus, outbus,
				cmpgain = 1, cmpclamp = 0.02, cmprelax = 0.1, cmpthresh = 0.4,
				cmpratio = 1.0, cmpgateratio = 1.0, hardgate = 0.01,
				audiothru = 0, faststop = 0|
			var	pc = PulseCount.kr(t_trig),
				start = BinaryOpUGen.new1(\control, '==', pc, 1),
				stop = BinaryOpUGen.new1(\control, '==', pc, 2),
				started = (pc > 0),
				sig = In.ar(inbus, 1),
				peak = Peak.ar(sig * started),
				dur;
			
			sig = sig * (Amplitude.kr(sig, cmpclamp, cmprelax) >= hardgate);
			sig = CompanderD.ar(sig, cmpthresh, cmpgateratio, cmpratio, cmpclamp, cmprelax,
				cmpgain);
			
				// trigger should ensure recording waits until trigger rec'd
			RecordBuf.ar(sig, bufnum, 0, 1, 0, started - stop, 0, 0);
		
			dur = Phasor.ar(start, SampleDur.ir, 0, 1000);
			stop = stop + (started * A2K.kr(dur > BufDur.ir(bufnum))) + faststop;
			
			SendTrig.kr(start, -1, 1);		// "started recording" message
			SendTrig.kr(stop, 0, peak);		// "stopped recording"
			SendTrig.kr(stop, 1, dur);		// "how long recording?"

				// delay the stop trigger in the EnvGen to avoid glitch
			Out.ar(outbus, sig
				* EnvGen.kr(Env.asr(0.05, 1, 0.05),
					DelayN.kr((started + audiothru) * (1 - stop), cmpclamp, cmpclamp),
					doneAction:2)
			);
		});

	};
	
	~inputParms = [];

		// call from outside when a new node is using one of my buffers
		// watch for the node to stop and allow the buf to be reused when no one is using it
		// if node is nil, it's the user's responsibility to release the buffer (next method)
	~bufferPlayingNewNode = { |buffer, node|
		buffer.status = \play;
		buffer.playCount = buffer.playCount + 1;
		node.notNil.if({
			~watcher.register(node);
			Updater(node, e { |node, msg|
				(msg == \n_end).if({
					node.releaseDependants;
					~releaseBufferFromPlay.(buffer);
				});
			});
		});
	};

		// should be called from outside to release a buffer from play
	~releaseBufferFromPlay = { |buffer|
		buffer.playCount = buffer.playCount - 1;
		(buffer.playCount == 0).if({
			buffer.status = \ready;
			~startRecord.(~recordActive);	// if already recording, this will not fire
		});
	};
	
//////// RECORDING CONTROL ////////

	~inputBusIndex = s.options.numOutputBusChannels;

	~startRecord = { |recActive|
		var	buf = ~oldestBuffer.(#[idle, ready]),  // ready means not playing
			bundle;
		recActive = recActive ? true;	// if nil, start every time (if user calls directly)
		(recActive and: { ~recording.not and: { buf.notNil } }).if({
			buf.status = \recordPending;
			buf.actionDone = false;
			buf.ontimes = List.new;
			buf.ffts = List.new;
			buf.matrix = Array.new;
			bundle = s.makeBundle(false, {
				buf.node = ~chan.play(~inputdef.name, [\bufnum, buf.buf.bufnum,
					\inbus, ~inputBusIndex, \t_trig, 0, \audiothru, ~audioThru.binaryValue]
					++ ~inputParms.(buf));
				buf.detectnode = ~chan.playfx(~featuredef.name, [t_trig: 0]
					++ ~detectParms.(buf));
			});
			~recNode = buf.node;
			~detectNode = buf.detectnode;
			~chan.doWhenReady({
				s.listSendBundle(nil, bundle);
			});
			~recording = true;
			~recordActive = true;
			~currentBuf = buf;
			"\n\n\nRecording is paused.".postln;
			BP(~collIndex).changed(\bufRecord, buf);
		});
	};

	~oldestBuffer = { |status|
		~bufs.sort({ |a, b| a.recTime < b.recTime })
			.detect({ |buf| status.matchItem(buf.status) })
	};
	
	~closeRecording = { |buf, startRec|
			// update gui status if I'm in an MT
		~isPlaying = false;
		BP(~collIndex).changed(\stop);

			// if nothing was recorded on stopRecord, buf.peak is nil so guarantee failure with -1
		((buf.peak ? -1) >= ~minPeak).if({
			buf.status = switch(buf.status)
				{ \recordPending } { \idle }
				{ \record } { \ready }
				{ \stopRec } { \ready }
				{ \idle };
		}, {
			"Recording rejected, amplitude (%) didn't meet threshold (%)."
				.format(buf.peak, ~minPeak)
				.warn;
			buf.status = \idle;
			buf.recTime = -1;	// force next record to use this buffer
		});
		buf.node = nil;

			// kindly release the node -- buf.node is already nil so oscresp won't match
		(startRec ? true).not.if({
			~recNode.set(\faststop, 1);
		});
		~recNode = nil;
		~detectNode.free;	// detectNode should not be outputting audio, can kill brutally
		~detectNode = nil;
		~recording = false;
		~lastTrigTime = Main.elapsedTime;  // to avoid accidental record restart
		(startRec ? true).if({
			~startRecord.(~recordActive);
		});
		~cmpqueue.isEmpty.if({
			~doAction.(buf);
		});
	};

	~doOnRecord = { |buf|
		"\n\n\n>>>>> RECORDING IS ACTIVE. <<<<<".postln;
			// update gui status if I'm in an MT
		~isPlaying = true;
		BP(~collIndex).changed(\play);
	};
	
		// dummy action, replace to call another BP to use the buffer
	~doAction = { |buf|
		(buf.actionDone.not and: { buf.peak >= ~minPeak }).if({
			"Analysis complete. Last buffer stored in BP(%).v.lastBuf.\n"
				.postf(~collIndex.asCompileString);
			~lastBuf = buf;
			buf.actionDone = true;
			BP(~collIndex).changed(\bufReady, buf);
		});
		currentEnvironment
	};

//////// FFT ANALYSIS CONTROL ////////

	~fftThreadActive = false;
	~fftThreadWaiting = false;
	~cmpThreadActive = false;

	~queueOnsetTime = { |buf, time|
		~fftID = ~fftID + 1;
		~fftqueue.put(~fftID, (buf: buf, time: time, index: buf.ffts.size));
		~activateFFTThread.value;
	};
	
	~activateFFTThread = { 
		~fftThread.isNil.if({ ~makeFFTThread.value });
		~fftThreadActive.not.if({
			AppClock.sched(0, ~fftThread);
			~fftThreadActive = true;
		});
	};
	
	~makeFFTThread = { 
		~fftThread = HJHCleanupStream(
			Routine({
				var	audio, srcfft, spec;
				loop {
					spec = ~fftqueue.pop;
					spec.notNil.if({
							// spec.buf.ffts.size == index of next fft to add
							// spec has an index but if a previous fft failed, it may be wrong
						spec.index = spec.buf.ffts.size;
						audio = ~getAudioData.(spec.time, spec.buf.buf);
						audio.notNil.if({
							srcfft = PR(~dataProto).v.copy
								.prep(audio, spec.index, currentEnvironment);
							srcfft.getfft.notNil.if({
								~postProgress.if({
									"BP(%): got valid time %\n".postf(
										~collIndex.asCompileString, spec.time);
								});
								~ffts.add(srcfft.fftPostProcessing);
								srcfft.collectGarbage(~garbageCollection);
								spec.buf.ffts.add(srcfft);
								~queueComparisons.(spec);
							}, {
								spec.buf.ontimes.removeAt(spec.index);
							});
						}, {
							spec.buf.ontimes.removeAt(spec.index);
						});
						~fftwait.wait;
					}, {
						nil.yield;
					});
				}
			}),
			e { ~fftThreadWaiting.not.if({ ~fftThreadActive = false }); },
			true);
	};
	
	~queueComparisons = { |fftspec|
		var	matrix = fftspec.buf.matrix, index = fftspec.index;
			// make sure matrix is large enough to handle the comparisons
		(matrix.size < (index+1)).if({
			matrix = matrix.extend(index+1, Array.new(index+1));
			matrix.do({ |row, i|
				(row.size < (index+1)).if({ matrix[i] = row.extend(index+1); });
			});
		});
			// no comparison needed for diagonal
		matrix[index][index] = (metric: 1, refindex: index, index: index,
			peak: fftspec.buf.ffts[index].peak, time: fftspec.time);
		fftspec.buf.matrix = matrix;

		(index > 0).if({
			index.do({ |i|
				~cmpID = ~cmpID + 1;
				~cmpqueue.put(~cmpID, fftspec.copy.put(\cmpindex, i));
			});
			~activateCmpThread.value;
		});
	};

	~activateCmpThread = { 
		~cmpThread.isNil.if({ ~makeCmpThread.value });
		~cmpThreadActive.not.if({
			AppClock.sched(0, ~cmpThread);
			~cmpThreadActive = true;
		});
	};
	
	~makeCmpThread = { 
		~cmpThread = HJHCleanupStream(
			Routine({
				var	spec, lastspec, errors = 0, recoveredFrom;
				loop {
					spec = ~cmpqueue.pop;
					spec.notNil.if({
						lastspec = spec;
						try {
							~doComparison.(spec);
						} { |error|
							"\n\n\nERROR IN COMPARISON\n\n".postln;
							error.reportError;
							spec.postln;
							errors = errors + 1;
							"\n\nComparison error noted. % error% so far.\n"
								.postf(errors, (errors != 1).if($s, ""));
						};
						~cmpwait.wait;
					}, {
						(~errorRecovery and: { errors > 0 }).if({
							~postProgress.if({
								"BP(%): Recovering from % error%.\n"
									.postf(~collIndex.asCompileString, errors,
										(errors != 1).if($s, ""));
							});
							recoveredFrom = ~recoverErrors.(lastspec.buf);
							errors = errors - recoveredFrom;
						});
						(errors > 0).if({
							"BP(%): Did not recover from % error%.\n"
								.postf(~collIndex.asCompileString, errors,
									(errors != 1).if($s, ""));
						});
							// if recording is over and cmpqueue is empty,
							// pass to the play action
						(lastspec.buf.status == \ready).if({
							~doAction.(lastspec.buf);
						});
						nil.yield;
					});
				}
			}),
			e { ~cmpThreadActive = false; },
			true);
	};
	
	~recoveryTests = 100;	// number of tests to perform in one wake of the recovery thread
	
		// PRIVATE METHOD -- must be called only in the context of the comparison thread
		// can't think of a better way than brute force -- but, the nil check is very fast
	~recoverErrors = { |buf|
		var	success = 0, matrix, matrixsize, testsdone = 0, ok;
		(matrix = buf.tryPerform(\at, \matrix)).notNil.if({
			matrixsize = matrix.size;	// matrix may be extended while this is running
			(matrixsize - 1).do({ |row|
				for(row + 1, matrixsize - 1, { |col|
					matrix[row][col].tryPerform(\at, \metric).isNil.if({
						try {
							~doComparison.((buf: buf, index: row, cmpindex: col));
							success = success + 1;
						};	// if comparison fails again, second error is swallowed
						testsdone = 0;	// reset and yield
						~cmpwait.wait;
					}, {
						((testsdone = testsdone + 1) == ~recoveryTests).if({
							testsdone = 0;
							~cmpwait.wait;
						});
					});
				});
			});
		});
		success	// return value
	};

		// note, this should be called only within the fftThread
	~asyncHang = { 
		~saveFFTThread = ~fftThread;
		~fftThreadWaiting = true;
		nil.yield;
	};
	
	~asyncUnhang = { 
		~fftThread = ~saveFFTThread;
		~clock.sched(0, ~fftThread);
		~fftThreadWaiting = false;
	};

//////// FFT ANALYSIS ////////

	~initFFT = { 
		var	resolution, melreso, mel, fhz, melNyquist;

		~fftsize = nextPowerOfTwo(~fftsize ? 2048);
		~halffft = ~fftsize div: 2;
		~imag = Signal.fill(~fftsize, 0);
		~cos = Signal.fftCosTable(~fftsize);
		
		resolution = ~sampleRate.value / ~fftsize;
		~melfreqsize = (~fftsize * 0.125).nextPowerOfTwo.asInteger;
		melreso = ~freqToMel.(~sampleRate.value * 0.5) / ~melfreqsize;
		
			// melmap[mel_bin_index] == first bin index into fft
		~melmap = Array.fill(~melfreqsize+1, { |i|
			fhz = ~melToFreq.(melreso * i);
			((fhz + (resolution * 0.5)) / resolution).asInteger
		});
		
		~window = ~makeWindow.value;
	};

	~doComparison = { |cmpspec|
		var	metric = cmpspec.buf.ffts[cmpspec.index]
			.compareData(cmpspec.buf.ffts[cmpspec.cmpindex]);
		~addToMatrix.(metric, cmpspec.index, cmpspec.cmpindex, cmpspec.buf.matrix,
			cmpspec.buf.ffts, cmpspec.buf.ontimes);
	};

//////// DESTRUCTOR ////////

	~freeCleanup = { 
		~clearAsyncResponder.value;
		~iMadeMixer.if({ ~chan.free });
		~userFree.value;
		~bufs.do({ |b| b.buf.free });
		[~fftbuf, ~triggerdevice].free;
		~resp.remove;
	};
}) => PR(\transient_analysis_incr);


AbstractChuckArray.defaultSubType = subtype;



// set gui window bounds for old 1024x768 layout

~controlpanelBounds = Rect(428, 11, 762, 713);
~mixerBounds = Rect(-7, -26, 435, 262);
~codedocBounds = Rect(2, 259, 432, 316);
~postwindowBounds = Rect(2, 574, 712, 172);

// mixing board gui def

// replace default definition with small skin (horizontal)
MixerChannelGUI.defaultDef = MixerGUIDef(Point(440, 25),
	[MixerMuteWidget, MixerRecordWidget, MixerNameWidget, MixerPresendWidget,
		MixerPanWidget, MixerLevelSliderH, MixerLevelNumber, MixerPostsendWidget,
		MixerOutbusWidget],
	[	Rect(5, 5, 15, 20),
		Rect(25, 5, 15, 20),
		Rect(45, 10, 50, 15),
		Rect(100, 0, 50, 20),
		Rect(155, 10, 40, 15),
		Rect(200, 10, 65, 15),
		Rect(270, 10, 40, 15),
		Rect(315, 0, 50, 20),
		Rect(370, 10, 50, 15)
	]);

MixerChannelDef.at(\mix1x1).guidef = MixerGUIDef(Point(440, 25),
	[MixerMuteWidget, MixerRecordWidget, MixerNameWidget, MixerPresendWidget,
		MixerLevelSliderH, MixerLevelNumber, MixerPostsendWidget,
		MixerOutbusWidget],
	[	Rect(5, 5, 15, 20),
		Rect(25, 5, 15, 20),
		Rect(45, 10, 50, 15),
		Rect(100, 0, 50, 25),
		Rect(200, 10, 65, 15),
		Rect(270, 10, 40, 15),
		Rect(315, 0, 50, 20),
		Rect(370, 10, 50, 15)
//		Rect(200, 10, 80, 15),	// old, deprecated
//		Rect(285, 10, 40, 15),
//		Rect(330, 0, 50, 25),
//		Rect(385, 10, 50, 15)
	]);

MixerPresendWidget.defaultSliderBounds = Rect(0, 2, 50, 5);
MixerPresendWidget.defaultMenuBounds = Rect(0, 10, 50, 15);


// parameterize VP creation: multiple columns?

~voicerColumns = 1;
~voicerRows = 6;
~voicersWith4Controls = 1;



// set gui window bounds for acer 1280x1024 layout

~controlpanelBounds = Rect(676, 4, 650, 976);
~mixerBounds = Rect(-1, -26, 676, 264);	// change
~codedocBounds = Rect(1, 261, 674, 450);
~postwindowBounds = Rect(1, 712, 674, 290);

// replace default definition with small skin (horizontal)
MixerChannelGUI.defaultDef = MixerGUIDef(Point(685, 25),
	[MixerMuteWidget, MixerRecordWidget, MixerNameWidget, MixerPresendWidget,
		MixerPanWidget, MixerLevelSliderH, MixerLevelNumber, MixerPostsendWidget,
		MixerOutbusWidget],
	[	Rect(5, 5, 20, 20),
		Rect(30, 5, 20, 20),
		Rect(55, 10, 70, 15),  // 115
		Rect(130, 0, 75, 20),  // 190
		Rect(210, 10, 80, 15), // 245
		Rect(295, 10, 160, 15), // 340
		Rect(460, 10, 50, 15), // 395
		Rect(515, 0, 75, 20),  // 470
		Rect(595, 10, 80, 15)  // 535
	]);

MixerChannelDef.at(\mix1x1).guidef = MixerGUIDef(Point(685, 25),
	[MixerMuteWidget, MixerRecordWidget, MixerNameWidget, MixerPresendWidget,
		MixerLevelSliderH, MixerLevelNumber, MixerPostsendWidget,
		MixerOutbusWidget],
	[	Rect(5, 5, 20, 20),
		Rect(30, 5, 20, 20),
		Rect(55, 10, 70, 15),  // 115
		Rect(130, 0, 75, 20),  // 190
		Rect(295, 10, 160, 15), // 340
		Rect(460, 10, 50, 15), // 395
		Rect(515, 0, 75, 20),  // 470
		Rect(595, 10, 80, 15)  // 535
	]);

MixerPresendWidget.defaultSliderBounds = Rect(0, 2, 75, 5);
MixerPresendWidget.defaultMenuBounds = Rect(0, 10, 75, 15);


// parameterize VP creation: multiple columns?

//~voicerColumns = 1;
//~voicerRows = 8;
//~voicersWith4Controls = 4;


// experimental, using scroll view

~voicerColumns = 1;
~voicerRows = 14;
~voicersWith4Controls = 6;
~useScroll = true;



// set gui window bounds for mbp 1440x900 layout

~controlpanelBounds = Rect(534, 4, 916, 852);
~mixerBounds = Rect(-6, -27, 546, 264);	// change
~codedocBounds = Rect(1, 260, 534, 397);
~postwindowBounds = Rect(1, 658, 675, 220);

// replace default definition with small skin (horizontal)
MixerChannelGUI.defaultDef = MixerGUIDef(Point(540, 25),
	[MixerMuteWidget, MixerRecordWidget, MixerNameWidget, MixerPresendWidget,
		MixerPanWidget, MixerLevelSliderH, MixerLevelNumber, MixerPostsendWidget,
		MixerOutbusWidget],
	[	Rect(5, 5, 20, 20),
		Rect(30, 5, 20, 20),
		Rect(55, 10, 60, 15),  // 115
		Rect(120, 0, 60, 20),  // 190
		Rect(185, 10, 50, 15), // 245
		Rect(240, 10, 100, 15), // 340
		Rect(345, 10, 50, 15), // 395
		Rect(400, 0, 70, 20),  // 470
		Rect(475, 10, 60, 15)  // 535
	]);

MixerChannelDef.at(\mix1x1).guidef = MixerGUIDef(Point(440, 25),
	[MixerMuteWidget, MixerRecordWidget, MixerNameWidget, MixerPresendWidget,
		MixerLevelSliderH, MixerLevelNumber, MixerPostsendWidget,
		MixerOutbusWidget],
	[	Rect(5, 5, 20, 20),
		Rect(30, 5, 20, 20),
		Rect(55, 10, 60, 15),  // 115
		Rect(120, 0, 60, 20),  // 190
		Rect(240, 10, 100, 15), // 340
		Rect(345, 10, 50, 15), // 395
		Rect(400, 0, 70, 20),  // 470
		Rect(475, 10, 60, 15)  // 535
	]);

MixerPresendWidget.defaultSliderBounds = Rect(0, 2, 60, 5);
MixerPresendWidget.defaultMenuBounds = Rect(0, 10, 60, 15);


// parameterize VP creation: multiple columns?

~voicerColumns = 2;
~voicerRows = 7;
~voicersWith4Controls = 6;


// need a way for iterator to tell bpcmd whether it stopped automatically or is manually killed

// setcmd doesn't handle synthdesc right

// h. james harkins - jamshark70@dewdrop-world.net
// not ready for prime time!

// important safety tip: setDoneSignal should not populate the doneSignal variable in a deferred function

var	saveSubType = AbstractChuckArray.defaultSubType;

AbstractChuckArray.defaultSubType = \tlCmd;

protect {

Proto({
	// subclasses should have methods
	// ~prep
	// ~fire
	// ~done
	// ~setDoneSignal (optional)
	// ~clearDoneSignal (optional)
	// ~free (optional)
	
	~isRunning = false;
	
		// parameters that one might want to override must be included in parentKeys below
	~isTLCommand = true;
		// if true, this command will be included in \sync or \cmdSync instructions
	~shouldSync = true;
	
	~play = { |parms|
//thisThread.clock.beats.debug(">> %: play".format(~collIndex));
		if(~isRunning.not) {
			~setParms.(parms);
			~isRunning = true;
//~setDoneSignal.postcs;
//"calling setDoneSignal".debug;
			~setDoneSignal.(parms);
//"calling fire".debug;
			~fire.(parms);
//			currentEnvironment.changed(\play, parms);
			NotificationCenter.notify(currentEnvironment, \play, [parms]);
			~schedDone.(parms);
		};
//thisThread.clock.beats.debug("<< abstractcmd: play");
		currentEnvironment
	};
	~schedDone = { |parms|
		if(~doneSignal.isNil) {
			thisThread.clock.sched((~dur.value(parms) ? 0), e { ~stop.value });
		};
	};
	~stop = { |parms|
		var	notifyTime;

//currentEnvironment.env.debug("abstractcmd: stop");

		if(~isRunning) {
			~done.(parms);
			~clearDoneSignal.(parms);
//"setting isRunning false".debug;
			~isRunning = false;
//"\nsending done notification".debug;
//currentEnvironment.listVars;

			if((notifyTime = parms.tryPerform(\at, \notifyTime)).notNil) {
				thisThread.clock.schedAbs(notifyTime, e {
					NotificationCenter.notify(currentEnvironment, \done, [parms]);
				});
			} {
				NotificationCenter.notify(currentEnvironment, \done, [parms]);
			};
//			currentEnvironment.changed(\done, parms);
		};
		currentEnvironment
	};
	~setParms = { |parms|
		var	e = currentEnvironment.env;
		if(e.proto.isNil) {
			e.proto = ();
		};
		parms.respondsTo(\keysValuesDo).if({
			e.proto.putAll(parms);
		});
	};
}, parentKeys: #[isTLCommand, shouldSync]) => PR(\abstractTLCommand);

PR(\abstractTLCommand).clone({
	~id = 0;
	~fire = { |parms|
		thisThread.clock.beats.debug("firing %".format(~id));
		currentEnvironment
	};
	~done = { |parms|
		thisThread.clock.beats.debug("done %".format(~id));
		currentEnvironment
	};
}, parentKeys: #[id]) => PR(\testTLCmd);

// run an arbitrary function
PR(\abstractTLCommand).clone({
	~fire = { |parms|
//		~setParms.(parms);
		currentEnvironment.env.use({ ~func.valueEnvir });
	};
}) => PR(\funcCmd);

PR(\abstractTLCommand).clone({
	~fire = { |parms|
//		~setParms.(parms);
		var	schedTime;
		~server ?? { ~server = Server.default };
		~node = Synth.basicNew(~name, ~server, ~id);
		~id = ~node.nodeID;		// nil is replaced in basicNew
		~latency ?? { ~latency = ~server.latency };
		~args = ~getArgs.value(parms);
		~quant ?? { ~quant = 0 };
		~schedTime = ~quant.nextTimeOnGrid(thisThread.clock);
		thisThread.clock.schedAbs(~schedTime, e {
			if(~latency == 0) {
				s.sendBundle(nil, ~node.newMsg(~target, ~args, ~addAction ? \addToHead))
			} {
				s.sendBundle(~latency, ~node.newMsg(~target, ~args, ~addAction ? \addToHead))
			};
		});
		NodeWatcher.register(~node, true);  // true == assumePlaying
		~node.addDependant(currentEnvironment);
	};
	~getArgs = { |parms|
		var	result;
		~synthDesc ?? {
			~synthDesc = (~descLib ?? SynthDescLib.global).at(~name.asSymbol);
		};
		~synthDesc.notNil.if({
			currentEnvironment.env.use({ ~synthDesc.msgFunc.valueEnvir });
		}, {
			parms.tryPerform(\keysValuesDo, { |key, value|
				if(value.isValidUGenInput) {
					result = result.add(key).add(value);
				};
			});
			result
		});
	};
	~schedDone = { |parms|
		if(~dur.notNil and: { ~synthDesc.tryPerform(\hasGate) ? false }) {
//"synthCmd scheduling release".debug;
			thisThread.clock.schedAbs(~schedTime + ~dur, e { ~stop.(parms) });
		};	// else -- node had better end on its own and trigger ~update
	};
	~done = { |parms|
		var	msg;
//">> synthCmd:done".debug;
		if(~node.isPlaying) {
//"sending release message".debug;
			if(~synthDesc.notNil and: { ~synthDesc.hasGate }) {
				msg = ~node.setMsg(\gate, 0);
			} {
				msg = ~node.freeMsg;
			};
			if(~latency != 0) {
				s.sendBundle(~latency, msg);
			} {
				s.sendBundle(nil, msg);
			};
		};
		~node.removeDependant(currentEnvironment);
//"<< synthCmd:done".debug;
	};
	~update = { |obj, msg|
		if(obj == ~node and: { msg == \n_end }) {
			~stop.value;
		};
	};
	~isSynth = true;
}) => PR(\synthCmd);

PR(\abstractTLCommand).clone({
	~fire = { |parms|
		var	synthDesc;
//		~setParms.(parms);
		~nodes = ~iterator.activeCmds.select({ |cmd|
			cmd.tryPerform(\isSynth) ? false
		});
		if(~nodes.size > 0) {
			~nodes.do({ |node|
				synthDesc = node.synthDesc;
				~args = ~getArgs.(parms);
				if(node.latency == 0) {
					node.node.set(*~args);
				} {
					node.server.sendBundle(node.latency, node.node.setMsg(*~args))
				};
			});
		};
		~dur = 0;
	};
}).import((synthCmd: #[getArgs, setParms])) => PR(\setCmd);


// Pdef player

PR(\abstractTLCommand).clone({
	~quant = Quant(0);
	~fire = { |parms|
//		~setParms.(parms);
		~name = ~name.asArray;
		~pdefs = Array(~name.size);
		~players = Array(~name.size);
		~name.do({ |name|
			if(Pdef(name).isActive) {
				"Pdef(%) is already playing; ignored".format(name.asCompileString).warn;
			} {
				~pdefs.add(Pdef(name));
				if(Pdef(name).clock !== thisThread.clock) {
					Pdef(name).clock = thisThread.clock;
				};
					// user hook to manipulate Pdef before play
				~preparePdef.(Pdef(name));
//name.debug("Pdefcmd - playing");
//[thisThread.clock.beats, Pdef(name).eventSchedTime(~quant)].debug("now, go time");
//~quant.dump;
				Pdef(name).play(thisThread.clock, ~protoEvent, ~quant, ~doReset ? false);
				~players.add(Pdef(name).player);
			};
		});
		if(~waitForStop == nil) {
			~waitForStop = ~pdefs.collect(_.key);
		} {
				// could be immutable as input
			~waitForStop = ~waitForStop.copy;
		};
	};
	~schedDone = { |parms|
		var	stopTime;
			// nothing played
		if(~pdefs.size == 0) {
			~stop.value;
		} {
			~pdefs.do({ |pdef| pdef.player.addDependant(currentEnvironment) });
			if(~dur.isNumber and: { ~dur.isStrictlyPositive }) {
				stopTime = thisThread.clock.beats + ~dur;
				thisThread.clock.sched(~dur - 0.001, e {
					~stop.value((notifyTime: stopTime));
				});
			};
		};
	};
	~done = { |parms|
			// if iterator stops automatically and this command should NOT sync,
			// then we don't want the pdefs to stop
//[~name, parms].debug("Pdefcmd:done");
		if(~shouldSync or: { parms.tryPerform(\at, \manualStop) == true }) {
//"stopping pdefs".debug;
				// pdefs will be removed from this array on each stopNow
				// so copying the array is necessary
				// also at end, this process might be responsible for stopping everything
			if(~stopAll == true, { Pdef.all }, { ~pdefs.copy })
			.do({ |pdef| pdef.stop });
		}
	};
	~update = { |obj, what, how|
		var	index;
//[obj, what, how].debug("Pdefcmd got update");
		if(what == \stopped and: { (index = ~players.indexOf(obj)).notNil }) {
				// user hook to reset Pdef after completion
			~pdefs[index].stop;
			~resetPdef.(obj);
				// the Pdef has already forgotten about its player
				// but I haven't
			~players[index].removeDependant(currentEnvironment);
			~waitForStop.remove(~pdefs[index].key);
			~pdefs.removeAt(index);
			~players.removeAt(index);
			if(~waitForStop.size == 0) {
				~stop.value;
			};
		};
	};	
}) => PR(\pdefCmd);


// bp command

PR(\abstractTLCommand).clone({
	~quant = NilTimeSpec.new;
	~fire = { |parms|
//		~setParms.(parms);
		~name = ~name.asArray;
		~bps = Array(~name.size);
		~name.do({ |name|
			if(BP(name).isPlaying) {
				"BP(%) is already playing; ignored".format(name.asCompileString).warn;
			} {
				~bps.add(BP(name));
				if(BP(name).clock !== thisThread.clock) {
					thisThread.clock => BP(name);
				};
					// user hook to manipulate BP before play
				~prepareBP.(BP(name));
//name.debug("bpcmd - playing");
//[thisThread.clock.beats, thisThread.clock.baseBarBeat, BP(name).eventSchedTime(~quant)].debug("now, basebar, go time");
//~quant.dump;
				thisThread.clock.schedAbs(BP(name).eventSchedTime(~quant), e {
						// if not running, cmd was stopped before BP fired
						// so skip the .play
					if(~isRunning) {
//[~name, thisThread.clock.beats].debug("playing bps now");
						BP(name).play(NilTimeSpec.new, nil, doReset: ~doReset ? false);
					} {
						BP(name).removeDependant(currentEnvironment);
					};
				});
			};
		});
		if(~waitForStop == nil) {
			~waitForStop = ~bps.collect(_.collIndex);
		} {
				// could be immutable as input
			~waitForStop = ~waitForStop.copy;
		};
	};
	~schedDone = { |parms|
		var	stopTime;
			// nothing played
		if(~bps.size == 0) {
			~stop.value;
		} {
			~bps.do({ |bp| bp.addDependant(currentEnvironment) });
			if(~dur.isNumber and: { ~dur.isStrictlyPositive }) {
				stopTime = thisThread.clock.beats + ~dur;
				thisThread.clock.sched(~dur - 0.001, e {
					~bps.copy.do({ |bp| bp.stopNow(notifyTime: stopTime); });
				});
			};
		};
	};
	~done = { |parms|
			// if iterator stops automatically and this command should NOT sync,
			// then we don't want the bps to stop
		var	timeSpecForStop = if(~stopAll != true) { NilTimeSpec.new };
//[~name, parms].debug("\n\nbpcmd:done");
//thisThread.dumpBackTrace;
		if(~shouldSync or: { parms.tryPerform(\at, \manualStop) == true }) {
//"stopping bps".debug;
				// bps will be removed from this array on each stopNow
				// so copying the array is necessary
				// also at end, this process might be responsible for stopping everything
			if(~stopAll == true, { BP.all }, { ~bps.copy })
			.do({ |bp| bp.stopNow(quant: timeSpecForStop) });
		}
	};
	~update = { |obj, what, how|
//[obj.tryPerform(\collIndex), what, how].debug("bpcmd got update");
		if(what == \stop and: { how == \stopped and: { ~bps.includes(obj) } }) {
				// user hook to reset BP after completion
			~resetBP.(obj);
			~bps.remove(obj);
			~waitForStop.remove(obj.collIndex);
			obj.removeDependant(currentEnvironment);
			if(~waitForStop.size == 0) {
				~stop.value;
			};
		};
	};	
}, parentKeys: #[quant]) => PR(\bpCmd);

// this command triggers one event in the registered bp's
// it must be non-syncing and have a cleanup function saved in ~done
PR(\abstractTLCommand).clone({
	~shouldSync = false;
	~fire = { |parms|
//		~setParms.(parms);
		~name = ~name.asArray;
		~bps = Array(~name.size);
		~name.do({ |name|
			if(BP(name).isPlaying) {
				"BP(%) is playing; can't trigger one event".format(name.asCompileString).warn;
			} {
				~bps.add(BP(name));
				BP(name).addDependant(currentEnvironment);
				if(BP(name).clock !== thisThread.clock) {
					thisThread.clock => BP(name);
				};
					// user hook to manipulate BP before play
				~prepareBP.(BP(name));
				thisThread.clock.schedAbs(BP(name).eventSchedTime(~quant), {
					BP(name).triggerOneEvent(NilTimeSpec.new, nil, doReset: ~doReset ? false);
				});
			};
		});
	};
	~done = { |parms|
		~cleanup.(parms);
		if(parms.tryPerform(\at, \manualStop) ? false) {
			~bps.do(_.stopNow);
		};
		~bps.do({ |bp| bp.removeDependant(currentEnvironment) });
	};
	~update = { |obj, what, how|
//[obj.tryPerform(\collIndex), what, how].debug("bp1eventCmd got update");
		obj.removeDependant(currentEnvironment);
		switch(what)
				// triggerOneEvent failed
			{ \oneEventEmpty } { ~stop.value }
				// somebody else started playing the process - this guy is dead now
			{ \play } { ~stop.value };
	};	
}, #[shouldSync]) => PR(\bp1eventCmd);

PR(\abstractTLCommand).clone({
	~fire = { |parms|
//		~setParms.(parms);
		thisThread.clock.setMeterNextBar(~beatsPerBar);
		~stop.();
	};
}) => PR(\meterCmd);

// REALLY experimental: flow-of-control commands

// looping over a whole array
// how to stop: same as others, set a user signal or specify a duration

PR(\abstractTLCommand).clone({
	~fire = { |parms|
//		~setParms.(parms);
		~myIterator = TLSequenceIterator(~cmds, autoSync: true);
			// looping works by receiving "stop" signal, then restarting upon that signal
		~myIterator.addDependant(currentEnvironment);
		~myIterator.play;
	};
	~done = { |parms|
		~myIterator.stop;
	};
	~update = { |obj, what|
		if((~isRunning ? false) and: { what == \done }) {
			"got done notification; looping back".postln;
			~myIterator.play;
		};
	};
}) => PR(\loopCmd);

// send user-defined notification from the iterator
PR(\abstractTLCommand).clone({
	~fire = { |parms|
//[~iterator, parms.atBackup(\notification, currentEnvironment), parms].debug("notifyCmd");
		parms[\iterator].changed(parms.atBackup(\notification, currentEnvironment),
			parms ?? ~parms);
	};
}) => PR(\notifyCmd);


// SECTION object
// responsible for saving bp states and selecting sequences (if needed) by user input

Proto({
	~name = "";		// to display in GUI
	~autoRestoreStates = true;
	~bps = nil;	// fill in with an array of BP names (symbols)
	~status = \idle;
	~autoSync = true;	// passed into TLSequenceIterator

	~isLoaded = false;

		// parent will call this one
	~prInitProc = {
		if(~isLoaded.not) {
			~initProcesses.();
			~isLoaded = true;
		};
	};
	
	~prUnload = {
		if(~isLoaded) {
			~unloadProcesses.();
			~isLoaded = false;
		};
	};

	~initProcesses = nil;		// user-supplied function to load resources
	~unloadProcesses = nil;

	~play = { |savedCmds|
		if(~isRunning.().not) {
			~savedCmds = savedCmds;
//savedCmds.debug("section:play - savedcmds");
			~clock ?? { ~clock = TempoClock.default };
			~initStates.();
			~preparePlay.();
			~seqPlayer = ~makeSeqPlayer.();
			~clock.sched(0, ~seqPlayer);
			~status = \running;
			currentEnvironment.changed(\play);
			~schedDone.();
		};
	};
	~schedDone = {
		var	now = thisThread.clock.beats;
		if(~dur.notNil) {
			~clock.sched(~dur - 0.001, e { ~stop.(now + ~dur) });
		}	// else, there should be a user input trigger to move to the next section
	};
	~stop = { |notifyTime, manualStop = true|
		if(~isRunning.()) {
			~status = \idle;
			~currentIterator.stop((manualStop: manualStop ? true));
			~done.();
			~clearDoneSignal.();
			~clock.schedAbs((notifyTime ?? { ~clock.beats }), e {
//~clock.beats.debug("sending done notification at");
//~savedCmds.debug("with these saved commands");
				currentEnvironment.changed(\done, ~savedCmds);
			});
			if(thisThread === ~seqPlayer) {
				nil.yield
			} {
				~seqPlayer.stop;
			};
		};
		currentEnvironment
	};
	~done = {
	};
	
	~isRunning = { ~status != \idle };
	
//	~saveStates = {
//		var	bps;
//		bps = ~bps ?? { BP.keys };
//		~states ?? { ~states = IdentityDictionary.new };
//		bps.do({ |bp|
//			~states.put(bp, BP(bp).archiveState);
//		});
//	};
//	~restoreStates = {
//		if(~states.notNil) {
//			~states.keysValuesDo({ |bpname, archive|
//				BP(bpname).restoreArchive(archive);
//			})
//		};
//	};
//	
//	~initStates = {
//		if(~states.isNil) {
//			~saveStates.()
//		} {
//			if(~autoRestoreStates) {
//				~restoreStates.();
//			};
//		};
//	};

	~makeSeqPlayer = {
//		~seqStream ?? { ~seqStream = ~seqPattern.().asStream };
			// should always reset: start from beginning of section every time you play
		~seqStream = ~seqPattern.().asStream;
			// ~condition is used elsewhere, not here, but needs to exist
		~condition ?? { ~condition = Condition.new };
		Routine({ |inval|
			var	item, delta;
			loop {
				item = ~seqStream.next(~seqEventProto);
				if(item.notNil) {
					delta = ~playItem.(item);
					delta.yield;	// playItem returns time to wait
				} {
					~stop.(nil, false)
				};
			}
		})
	};
	
	~update = { |obj, what, args|
//[obj, what, args].debug("section % received update".format(~name));
		if(obj === ~currentIterator) {
			switch(what)
				{ \done } {
					obj.removeDependant(currentEnvironment);
						// iterator might remove commands after this happens
					~savedCmds = args.copy;
//args.debug("section:update - savedcmds");
//~savedCmds.debug("savedCmds variable");
					if(~status == \sync) { ~condition.unhang };
				}
		};
			// a command might send a notification that's really meant for the section sequencer
			// it can set the passthru flag
			// try returns nil if there's an error
		if(try { args[\passthru] } == true) {
//"passing notification thru".debug;
			currentEnvironment.changed(what, args)
		};
	};
	
	~playItem = { |item|
		var	seq = item[\sequence], dur = item[\dur],
			iterator, /*updater, */quant;
		if(seq.size > 0) {
			~currentIterator = iterator = TLSequenceIterator(seq, currentEnvironment,
				autoSync: ~autoSync).play(0, ~clock, ~savedCmds);
			~savedCmds = nil;
//"section playItem: set savedCmds to nil".debug;
			iterator.addDependant(currentEnvironment);
		};
		case
			{ dur.isNumber and: { dur >= 0.001 } } {
				~clock.sched(dur - 0.001, {
					iterator.removeDependant(currentEnvironment);
					iterator.stop;
				});
				dur	// return value
			}
				// cannot sync if there's nothing to play
			{ dur == \sync and: { iterator.notNil } } {
				~status = \sync;
				~condition.hang;
				~status = \running;
				0	// after waking up, go immediately
			}
			{ dur == \trigger } {
				~setTrigger.(item);
				~status = \waitForTrigger;
				~condition.hang;
				~status = \running;
				item[\quant].asQuant.nextTimeOnGrid(~clock) - ~clock.beats
//				0	// after waking up, go immediately
			}
			{ (quant = dur.tryPerform(\asQuant)).notNil } {
				quant = quant.nextTimeOnGrid(~clock) - ~clock.beats;
				~clock.sched(quant - 0.001, {
					iterator.removeDependant(currentEnvironment);
					iterator.stop;
				});
				quant
			}
			{ seq == \initNext } {
				currentEnvironment.changed(\initNext);
				dur
			}
				// default case: invalid object - stop rather than loop infinitely
			{
				MethodError("Invalid item in section", item).throw
			}
	};

	~setTrigger = { |item|
		if(~currentTriggerItem.isNil) {
			~currentTriggerItem = item;
			item[\init].(item);
		} {
			"Another trigger is already active. Ignored.".warn;
		};
	};
	~cleanupTrigger = { |triggerID, parms|
		if(~currentTriggerItem.notNil) {
			~currentIterator.stop;
			~currentTriggerItem[\clear].(~currentTriggerItem, triggerID, parms);
			~currentTriggerItem = nil;
		};
	};
	~doTrigger = { |triggerID, parms|
		if(~status == \waitForTrigger) {
			if(~receivedTrigger.(triggerID, parms)) {
				~status = \running;
				~cleanupTrigger.(triggerID, parms);
				~condition.unhang;
			} {
				"Received inactive trigger %; ignored.".format(triggerID).warn;
			};
		} {
			"Section is not waiting for user trigger. Cannot ~doTrigger now.".warn;
		};
	};
	~receivedTrigger = { |triggerID, parms|
		~currentTriggerItem[\id].matchItem(triggerID)
			and: { ~currentTriggerItem[\verify].(~currentTriggerItem, parms) ? true }
	};
		// SEQUENCE SELECTION
		// up to you to decide how to store sequences
		// pattern must return events (i.e., you can use Pbind) with
		// (sequence: array for TLSeqIt, dur: timing info)
		// sequence = nil means pause based on timing
		// dur = number, run sequence for exactly dur beats (Quant OK too)
		// dur = \sync, resume section when sequence stops
		// dur = \trigger (or nil), wait for some user signal - user's responsibility to maintain
	~seqPattern = {};	// you supply!
	~seqEventProto = ();
}) => PR(\tlSection);

Proto({
		// should send .changed(\section, sectionIndex) when moving to a new section

	~sections = [];	// supply array of sections
	~status = \idle;
	
	~currentSection = 0;
	
	~countOffBeats = 4;
	~clock = TempoClock.default;
	~quant = Quant(1);	// start (to count off) on next whole bar
	~sectionLeadTime = 0.9;	// how many beats before barline to kick off the section
	
	~autoReset = true;	// automatically reset all BPs?
	~doNotReset = nil;	// collection of bp names NOT to reset
	
	~condition = Condition.new;
	
	~isRunning = { ~status != \idle };
	
	~recvPlayButton = { |section|
		if(~isRunning.()) { ~stop.() }
			{ ~currentSection = section ?? { ~currentSection }; ~play.() };
	};
	
	~play = {
//">> sectionSequencer:play".debug;
		if(~autoReset) {
			~doReset.();
		};
		~startingSection = ~currentSection;
		~loadResources.(~currentSection);
		~countOffAndGo.();
//		~status = \playing;
		currentEnvironment.changed(\play);
//"<< sectionSequencer:play".debug;
	};
	
	~stop = { |lastSection = false|
//lastSection.debug(">> sectionSequencer:stop");
		if(~status == \countingOff) {
			~status = \idle;
			~countOffRoutine.stop;
			currentEnvironment.changed(\stop);
			currentEnvironment.changed(\countoff, nil);
		} {
			~sections[~currentSection].stop/*(nil, manualStop)*/;
				// must force manual stop for last section at end of piece
				// but this didn't work
			if(lastSection ? false) { ~sections.last.stop(nil, true) };
//			if(thisThread === ~sectionRoutine) { nil.yield }
//				{ ~sectionRoutine.stop };
			~status = \idle;
			~currentSection = ~startingSection;
			currentEnvironment.changed(\stop);
			currentEnvironment.changed(\section, ~currentSection);
			~savedCmds = nil;
			~sectionRoutine.stop;
			~sectionRoutine = nil;
		};
//"<< sectionSequencer:stop".debug;
	};
	
	~loadResources = { |section|
//section.debug(">> loadResources");
			// must add 1 because do runs from 0 to n-1
		(section+1).do({ |sect|
			if(~sections[sect].isLoaded.not.debug("section % needs to load".format(sect))) {
				~sections[sect].prInitProc;
			};
		});
//debug("<< loadResources");
	};
	
	~countOffAndGo = {
		var	goTime = ~quant.nextTimeOnGrid(~clock) + ~countOffBeats - ~sectionLeadTime,
			started = false;

//[~clock.baseBarBeat, ~clock.beats, ~quant.nextTimeOnGrid(~clock), goTime].debug("starting countoff - base beat, now, quant time, go time");

		~status = \countingOff;
		~clock.schedAbs(~quant.nextTimeOnGrid(~clock), ~countOffRoutine = Routine({
			currentEnvironment.changed(\countoff, \init);
				// count off first
			~countOffBeats.do({ |count|
				currentEnvironment.changed(\countoff, count + 1);
				if(started.not and: { goTime - thisThread.clock.beats < ~sectionLeadTime }) {
					started = true;

//[~clock.beats, goTime].debug("starting section player - now, go time");

					thisThread.clock.schedAbs(goTime, ~sectionRoutine = Routine({
						~status = \playing;
						while { ~isRunning.() and: { ~currentSection < ~sections.size } } {
//~savedCmds.debug("playing section % with saved cmds".format(~sections[~currentSection].name));
							~sections[~currentSection].play(~savedCmds);
//"section sequencer: set savedCmds to nil".debug;
							~savedCmds = nil;
								// ~update method below will catch notifications
							~sections[~currentSection].addDependant(currentEnvironment);
							~condition.hang;
						};
						~stop.(true);	// stop last section
					}));
				};
				1.0.wait;
			});
			~countOffRoutine = nil;
			currentEnvironment.changed(\countoff, nil);
				// removing initial meter
				// section should run its own conductor slightly in advance of the true barline
			
//				// in theory nothing should be playing now
//				// so it should be OK to set this even off the barline
//			thisThread.clock.setMeterAtBeat(~sections[~currentSection].startBeatsPerBar,
//				thisThread.clock.beats);
//[~clock.beatsPerBar, ~clock.baseBar, ~clock.baseBarBeat].debug("after setting initial meter");
		}));
	};
	
	~doReset = {
		(BP.keys - ~doNotReset.as(IdentitySet)).do({ |name|
			BP(name).reset;
		});
	};
	
	~gotoSection = { |section|
		if(~isRunning.()) {
			MethodError("Cannot change section while playing", currentEnvironment).throw;
		} {
			~currentSection = section;
			currentEnvironment.changed(\section, section);
		};
	};
	~currentSection_ = { |section| ~gotoSection.(section) };
	
	~countOffBeats_ = { |beats|
		~countOffBeats = beats;
		currentEnvironment.changed(\countOffBeats, beats);
	};
	
	~autoReset_ = { |autoReset|
		~autoReset = autoReset;
		currentEnvironment.changed(\autoReset, autoReset);
	};
	
	~update = { |obj, what, args|
//[obj, what, args].debug("section sequencer got update");
		var	section;
		if(obj === ~sections[~currentSection]) {
			switch(what)
				{ \done } {
//args.debug("section sequencer update - savedCmds");
					~savedCmds = args;
					obj.removeDependant(currentEnvironment);
					if(~isRunning.()) {
						~currentSection = ~currentSection + 1;
//~currentSection.debug("section done, moving to");
						currentEnvironment.changed(\section, ~currentSection);
						~condition.unhang;
					};
				}
				{ \initNext } {
					if(~sections[~currentSection + 1].notNil) {
						~sections[~currentSection + 1].prInitProc;
					}
				}
				{ \unload } {
//[obj, what, args].debug("got unload message");
					args.tryPerform(\at, \name).asArray.do { |sectName|
//sectName.debug("checking");
						if((section = ~sections.detect { |sct| sct.name == sectName }).notNil) {
//sectName.debug("unloading one");
							section.prUnload;
						}
					};
				}
		};
	};
	~sectionNames = { ~sections.collect({ |sect, i| "%: %".format(i+1, sect.name) }) };
}) => PR(\sectionSequencer);

PR.allOfType(\tlCmd).do({ |pr|
	pr.value.put(\collIndex, pr.collIndex)
});

} { AbstractChuckArray.defaultSubType = saveSubType; };



//////// Algorithmic Noodling - H. James Harkins
//////// Definition file - load once at beginning of performance



// For ease of clean-up, all these objects will be identified with the subType \noodle
// future object creation should not be affected, so I have to save the current subType
var	saveSubtype = AbstractChuckArray.defaultSubType, master;

AbstractChuckArray.defaultSubType = \noodle;

protect {	// to reset the subType even in case of error

// I always keep a single master MixerChannel
// a previous piece in the same performance might have created it,
// so check before making a new one
master = ~master = ~master ?? { MixerChannel(\master, s, 2, 2, level: 1) };

// The separate environment is for shared resources.
// See the performance script file to see how it's used.
~noodle = Environment.make({

~master = master;	// master needs to be in this environment as well as topEnvironment

~rvbmc = MixerChannel(\reverb, s, 2, 2, level: 1, outbus: ~master, completionFunc: { |chan|
	chan.playfx({ |outbus|
		var	l, r;
		#l, r = In.ar(outbus, 2);
		FreeVerb2.ar(l, r, 1.0, 0.6, 0.5)
	});
});

// I know the path of the audio files relative to this file
// this gets the directory where this file is located
~root = PathName(thisProcess.nowExecutingPath).pathOnly;

TempoClock.default.tempo = 76/60;

//////// VOICER FACTORIES

/***
The factory contains an environment. When you instantiate the factory, the environment is copied and new resources, such as ~target, ~cbuf, ~mbuf in the first factory here, are saved into this environment. Both the voicer and the environment go into the VC storage object. When the voicer is no longer needed, the VC can enter its unique environment and call the ~free function to clean up these other objects as well.
***/

// "keys" are environment variables in the current environment to pass into the factory at creation time
(keys: #[master, rvbmc], make: {
	var	out;
		// ~master, one of the keys, is used here
		// the Voicer's output MixerChannel should always be called ~target in the factory
	~target = MixerChannel(\bass, s, 1, 2, level: -11.dbamp, outbus: ~master);
	~target.newPostSend(~rvbmc, 0.368);
		// other resources stored in the factory environment
	~cbuf = Buffer.alloc(s, 1024, 1, completionMessage: { |buf|
		buf.sine1Msg(#[1]);
	});
	~mbuf = Buffer.alloc(s, 1024, 1, completionMessage: { |buf|
		buf.sine1Msg(#[1, 1]);
	});
		// fm is more pronounced in a higher register
		// this SynthDef compensates by scaling mod_lev according to note frequency
		// if f = frequency, b = base frequency, m = mod lev, and k = scaling sensitivity,
		// scaled modulation is m / (((f / b) - 1) * k + 1)
		// fewer UGens as the algebraic equivalent m * b / ((f * k) + (b * (1-k)))
		// here b=102.2 and k=0.5 are hardcoded
	SynthDef(\fmbass, { |freq, gate, freqlag, cbuf, mbuf, mod_ratio, mod_lev, detune, car_vs, mod_vs, outbus|
		var sig, mod, car_amp, mod_amp;
		freq = Lag.kr(freq, freqlag);	// for monophonic portamento
		mod_lev = mod_lev * 102.2 / ((freq * 0.5) + (102.2*0.5));
			// "sensitivity" formula - scaling relative to 1.0, not 0
			// see the ddwSensitivity quark
		car_amp = Latch.kr((gate-1) * car_vs + 1, gate);
		mod_amp = Latch.kr((gate-1) * mod_vs + 1, gate)
			* EnvGen.kr(Env.adsr(0.01, 0.2, 0.4, 0.21), gate);
		mod = Osc.ar(mbuf, freq * mod_ratio + detune, 0, mod_amp * mod_lev);
		sig = Osc.ar(cbuf, freq + (mod * freq), 0, car_amp)
			* EnvGen.kr(Env.adsr(0.01, 1, 0.9, 0.05), gate, doneAction:2);
		Out.ar(outbus, sig);
	}).add;
	out = MonoPortaVoicer(1, \fmbass, [cbuf: ~cbuf, mbuf: ~mbuf, mod_ratio: 0.5,
		detune: 0.35, car_vs: 0.37, mod_vs: 0.56], target: ~target)
		.portaTime_(0.08);
	out.mapGlobal(\mod_lev, nil, 3.3, #[1.0, 12.0, \exp]);
	out	// ~make function must return the Voicer itself
}, free: { [~target, ~cbuf, ~mbuf].free }, type: \voicer) => Fact(\bass_v);


(keys: #[master, rvbmc], make: {
	var	f;
	~target = MixerChannel(\jumpy, s, 2, 2, -14.dbamp, outbus: ~master, completionFunc: nil);
	~target.newPostSend(~rvbmc, 0.9);
	
	f = { |i| (i / 14) * 0.3pi - 0.2 };
	~bufs = Buffer.allocConsecutive(6, s, 2048, 1, completionMessage: { |buf, j|
		buf.sine1Msg({ |i| (i%6 == j).if(0, { cos(f.(i)) }) } ! 14);
	});
	
	SynthDef(\jumpy, { arg freq, gate, bufbase, bufmod, vsens, detune, pan,
			ffreq, rq, lag = 0.1, outbus;
		var sig, amp, buf;
		amp = Latch.kr((gate-1) * vsens + 1, gate);
			// the bufenv should know how many buffers it's covering
		buf = bufbase + bufmod;
		sig = VOsc3.ar(buf, freq/detune, freq, freq*detune, amp)
			* EnvGen.kr(Env.adsr(0.01, 0.07, 0.4, 0.08), gate, doneAction:2);
		ffreq = Lag.kr(ffreq, lag);
		rq = Lag.kr(rq, lag);
		pan = Lag.kr(pan, lag);
		Out.ar(outbus, Pan2.ar(RLPF.ar(sig, ffreq, rq), pan));
	}).add;
	
	MonoPortaVoicer(1, \jumpy, [bufbase: ~bufs.first, vsens: 0.677, detune: 0.99606], target:~target).portaTime_(0.1);
}, free: { [~target, ~bufs].free }, type: \voicer) => Fact(\jumpy_v);


(keys: #[master, rvbmc], make: {
	var	out;
	~target = MixerChannel(\pad, s, 2, 2, level: -20.dbamp, outbus: ~master, completionFunc: { |chan|
//		chan.playfx(Instr("busfx.chorus2"), [20, 1, 2, 3, 0.0099076721080885, 0.12388629239938, 0.0026448039935914, 0.7306029426953, 0.4]);
				// standard mono-to-stereo chorusing technique
		var	chorus = chan.playfx({ |outbus|
			var	sig = In.ar(outbus, 1) * 0.4,
				mods = { |i|
					SinOsc.kr(0.12388629239938 * rrand(0.9, 1.1),
						0.7306029426953 * i,
						0.0026448039935914, 0.0099076721080885);
				} ! (3 * 2);
			sig = DelayC.ar(sig, 0.5, mods);
			Mix(sig.clump(2))
		});
		chan.newPostSend(~rvbmc, 0.6);
			// "set it and forget it" multiband EQ class in my library
			// there is also MultiEQ for EQs whose parameters you'll need to change
		StaticEQ.new(2, \eq, 551.972, -6.383.dbamp, 1.054, \hishelf, 1944.083, 4.681.dbamp, 1)
			.play(chan);
			// make sure chorus precedes EQ
		SystemClock.sched(0.5, { chorus.moveToHead(chan.effectgroup) });
	});
	
		// This is a trick I like to use to save CPU for pads.
		// Usually you play thick chords on pads, and band limited oscillators 
		// are not CPU cheap. But, wavetable oscillators alias at higher
		// frequencies. This technique uses an array of wavetables, with
		// successively decreasing harmonic content. Note frequency
		//maps onto the buffer with the right number of partials,
		// so you get speed and a clean sound.
	~bufs = Buffer.allocConsecutive(8, s, 2048, 1, completionMessage: { |buf, i|
		var	base = 48 + (i * 12),		// max here is 132, just above highest MIDI note number
			numHarmonics = (20000 / base.midicps).asInteger;
		buf.sine1Msg((1..numHarmonics).reciprocal)
	});
	
	SynthDef(\padmap, { |freq, gate, bufbase, numbufs, vsens, detune,
			ffreq, rq, outbus|
		var	amp = Latch.kr((gate-1) * vsens + 1, gate),
			top = (127.midicps / 48.midicps).log2,
			freqmap = (freq / 48.midicps).log2,
			bufmod = LinLin.kr(freqmap, 0, top, 0, numbufs-1).clip(0, numbufs-1.01),
			buf = bufbase + bufmod,
			sig;
		sig = VOsc3.ar(buf, freq/detune, freq, freq*detune, amp);
		sig = RLPF.ar(sig, ffreq, rq)
			* EnvGen.kr(Env.adsr(0.4, 0.5, 0.8, 1.8), gate, doneAction:2);
		Out.ar(outbus, sig)
	}).add;
	
	out = Voicer(20, \padmap, [bufbase: ~bufs.first, numbufs: ~bufs.size, vsens: 0.3,
		detune: 1.00394], target: ~target);
	out.mapGlobal(\ffreq, nil, 1200, \freq);
	out.mapGlobal(\rq, nil, 1.0, [1.0, 0.05, \exp]);
	
	out
}, free: { [~target, ~bufs].free }, type: \voicer) => Fact(\pad_v);



//////// PROCESS FACTORIES

// silent process to determine harmonic context
// writes current bass note into Library under key \currentBassNote
// also sends notification -- we'll use this for a bass arpeggiator
(make: { |name|
	PR(\aiBass) => BP(name);
	MBM(0)[\roots] => BP(name);	// source melody data
	MBM(0)[\rootsadp] => BP(name);	// data for generating variations
	BP(name).useRh = true;
		// Normally in a melodic process, you want to preserve the original rhythm.
		// Here, the rhythm determines harmonic rhythm,
		// which I want to generate randomly within a specific range.
		// So I supply a rhythm profile, which is a Proto object that defines
		// a pattern to return durations and lengths.
	BP(name).rhythm = PR(\abstractProcess).copy.make({
		~asPattern = {
			~deltaStream ?? { ~deltaStream = ~delta.asStream };
			Pfunc(e { ~deltaStream.next.dup });
		};
		~delta = Pwhite(5, 14, inf) * 0.5;	// (2.5, 3.0 .. 7.0)
	});
		// the adaptation techniques to use
	Prand(#[absSplice, intSplice], inf) =>.adapt BP(name);
		// validation: all notes in a new variation must be between
		// scale degrees 17 and 28
	BP(name).eugTest = \eugRangeOnlyTest;
	BP(name).range = NumericRange(17, 28);
		// timing correction for data sharing - see readme
	BP(name).leadTime = 0.1;	// roots must fire before everyone else
	BP(name)
}, type: \bp) => Fact(\roots);


// The bassline is technically an arpeggiator process that spins out figuration over the last root note chosen by the \roots process. It is a nested process -- the inner layer, PR(\arpeg1), generates the notes, and the outer layer, PR(\macroRh), populates data per harmony event that \arpeg1 needs.

(make: { |name|
	BP(name).free;
	PR(\arpeg1) => BP(name);	// child process (inner layer)
		// Func(\fitToBass) defines how to fit figuration to harmonic context
	BP(name).fitFunc = \fitToBass;
	PR(\macroRh) => BP(name);	// wrap inner layer inside outer layer
	BP(name).bassUpdate = false;
	MBM(0)[\bassfigs] => BP(name);	// source "chords"
		// a dummy "macrorhythm" that reads the data from the last root note
	Pfunc({ [~parentDelta, ~parentLength] }) =>.macro BP(name);
	\bass1 =>.micro BP(name);	// per-note rhythm
	\xrand =>.arpeg BP(name);	// order to arpeggiate notes
	\gdor.asMode => BP(name);	// mode, or "key"
	BP(name).leadTime = 0.1;	// schedules the same as roots
	BP(name)
}, type: \bp) => Fact(\bass);

// This defines the observer process that listens for new root notes, and passes the information to the bass process.
(make: { |name|
		// BP(\roots) is the process whose events we're listening for
		// it must exist before initializing the link process
	BP(\roots).exists.not.if({
		Fact(\roots).makev;
	});
	PR(\basslink).chuck(BP(name), parms: (
		driver: \roots,	// I'm listening to \roots
		children: (
				// I could have any number of child processes
				// here there is just one, for the bass
				// quant: 0 means to trigger the base event immediately
				// when receiving the notification
				// func declares how to pass information from parent to child
			bass: (quant: 0, func: { |name, parentEvent|
					// func communicates parent event data into child
				BP(name).parentDelta = parentEvent[\delta];
				BP(name).parentLength = parentEvent[\delta];
			})
		)
	));
}, type: \bp) => Fact(\basslink);

// Pad process -- Func(\makeCh) is a shortcut that sets the most important arpeggiator properties in one step. (I do this whole lot, so it makes sense to have a macro.)

// This is not so directly tied to the root process, but it uses special techniques to make sure it starts on the next root note and remains in sync thereafter.
(make: { |name|
	Func('makeCh').doAction(name, \arpeg1, \macroRh, MBM(0)[\padch], nil, MacRh(\lagger), \pad2, \reshuf, nil, \gdor);

		// Harmonies can, if desired, follow the contour of a top note melody
		// this can be an instance of PR(\aiMel) for variations on given note data,
		// or, as here, a process that generates the pitches from a pattern
	BP(name).topNote = PR(\patternTop).v.copy.make({
		~deg = Pvbrown(37, 52, Pwhite(1, 3, inf), inf);
		~mode = \gdor;
	});

		// Func(\chordFitInt) rearranges chord intervals against the top note
		// for best consonance over the current bass note
	BP(name).child.fitFunc = \chordFitInt;
		// a function that calculates when to start based on the root's next event time
	BP(name).quant = Func(\syncToRoot).v;
		// since the lead time is smaller than that of roots,
		// this will execute later than the root process and can use its information
		// since it's nonzero, other processes can also grab information from the pad
	BP(name).leadTime = 0.05;
	BP(name)
}, type: \bp) => Fact(\pad);


// More special techniques, not only to stay synchronized with the root, but also to play the same notes as the pad.
(make: { |name|
	Func('makeCh').doAction(name, \arpeg1, \macroRh, MBM(0)[\padch], nil, MacRh(\lagger), \jumpy, \xrand, nil, \gdor);
	BP(name).quant = Func(\syncToRoot).v;
		// Since the child process generates the notes,
		// we can attach arbitrary parameters for the Voicer
	BP(name).child.argPairs = [\bufmod, Pwhite(0.0, 4.99, inf), \ffreq, Pexprand(1200, 14000, inf), \rq, Pexprand(0.05, 0.5, inf)];

		// look to the pad for the chord object to use
		// if that isn't populated or isn't being updated,
		// choose randomly from my own chord pool
	BP(name).child[\makeChordPattern] = {
		Pfunc({
			BP(\pad).isPlaying.if({ BP(\pad).child.currentChord }) ?? { ~chords.choose }
		})
	};
	BP(name).child.chordStream = nil;	// ... and make sure it takes effect
	BP(name).child.reset;

		// to get the same notes, the top note has to match also
		// the top note pattern is kept as a fallback in case the pad isn't running
	BP(name).topNote = PR(\patternTop).clone({
		~basePattern = ~asPattern;
		~deg = Pvbrown(37, 52, Pwhite(1, 3, inf), inf);
		~mode = \gdor;
		~asPattern = {
			var	base = ~basePattern.value.asStream;
			Pfunc({ |inevent|
				BP(\pad).isPlaying.if({ BP(\pad).lastEvent.top },
					{ base.next(inevent) })
			});
		};
	});
	BP(name)
}, type: \bp) => Fact(\jumpy);


// A couple of generative drum machines to round out the ensemble.
// All the setup takes place using the chuck operation's parameter list!
(keys: #[master, root], make: { |name|
	PR(\bufPerc).chuck(BP(name), parms: (
		master: ~master,
			// which sound file to play
			// one drum machine process can choose between several buffers
		bufPaths: [~root ++ "samples/mellowbd.aif"],
			// user specific initialization takes place when the MixerChannel is ready
		postMCCreation: { |chan|
			StaticEQ(1, \eq, 1879.042, 5.532.dbamp, 0.405, \eq, 82.098, 4.681.dbamp, 1).play(chan);
			chan.level = -8.4.dbamp;
		},
		amps: 0,
			// used as the basic rhythm for the generator function
			// the loudest stroke will be on the first beat of the bar
		ampBase: [1] ++ (0 ! 15),
			// This executes once per bar to generate a new rhythm.
		pbindPreAction: {
			var	pool = (1..15).scramble;
			~amps = ~ampBase.copy;
			rrand(1, 5).do({ |i|
				~amps[pool[i]] = rrand(0.2, 0.7);
			});
		}
	));
}, type: \bp) => Fact(\kik);

(keys: #[master, root, rvbmc], make: { |name|
	PR(\bufPerc).chuck(BP(name), parms: (
		master: ~master,
		rvbmc: ~rvbmc,
		bufPaths: [~root ++ "samples/springverb-rimshot.aif"],
		rates: [1.15],
		postMCCreation: { |chan|
			StaticEQ(1, \eq, 180.488, -14.61.dbamp, 0.052, \eq, 287.845, -15.745.dbamp, 0.052,
				\eq, 4180.489, 3.262.dbamp, 0.589).play(chan);
			chan.newPostSend(~rvbmc, 0.6);
			chan.level = -7.6.dbamp;
		},
		amps: 0,
		ampBase:
			#[	[0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0.4, 0, 0.8, 0, 0],
				[0, 0, 0, 0, 0, 0.4, 0, 0, 1, 0, 0, 0, 0, 0.5, 0, 0],
				[0, 0, 0, 0, 0.7, 0, 1, 0, 0, 0.4, 0, 0, 0, 0, 0, 0]
			],
		pbindPreAction: {
			var	pool;
			~amps = ~ampBase.choose.copy;
				// locate rests in the base rhythm
			pool = ~amps.collectIndicesOfItem(0).scramble;
				// then put extra notes only in the rests
			rrand(0, 3).do({ |i|
				~amps[pool[i]] = rrand(0.2, 0.7);
			});
		}
	));
}, type: \bp) => Fact(\stick);


//////// PROCESS PROTOTYPES

// bass needs to follow root process exactly
// this listens for the notification from \roots and transmits info to the bass process
// this implements the Observer design pattern
Proto({
		// set at chuck time
	~bassID = \currentBassNote;	// bass ID to listen for
	~children = ();	// e.g., (childBPName: (quant: 0, func: {}), ...)
	~clock = TempoClock.default;
	
	~niltime = NilTimeSpec.new;	// you should not change this
	
	~prep = {
		~clock = BP(~driver).tryPerform(\clock) ?? { ~clock };  // clocks must match
		~registerNotify.value;
	};
	
	~registerNotify = {
			// bass note notifications go through BP class
			// adding currentEnvironment means ~update below will respond
		BP.addDependant(currentEnvironment);
	};
	
	~unregisterNotify = {
		BP.removeDependant(currentEnvironment);
	};

		// This is what makes this process into an Observer
	~update = { |obj, changeID, parentEvent|
			// notification might be from something else
			// reject if not the right bassID
		(changeID == ~bassID).if({
			~playChildren.(parentEvent);
		});
	};

	~playChildren = { |parentEvent|
		~children.keysValuesDo({ |bpname, spec|
				// for each child, find out when it should trigger
				// at that time, pass information across and run exactly one event
			~clock.schedAbs(spec[\quant].asTimeSpec.nextTimeOnGrid(~clock), e {
				spec[\func].value(bpname, parentEvent);
				BP(bpname).triggerOneEvent(~niltime);
				nil
			});
		});
	};

		// dependents should not be left around when not in use
	~freeCleanup = {
		~unregisterNotify.value;
	};
}) => PR(\basslink);


//////// PROCESS COMPONENTS

// The arpeggiator prototype (used above for bass, pad and jumpy) uses other objects, pulled by name from their respective repositories.

// A "microrhythm" pattern supplies the note delta, length (for staccato or overlap) and gate (velocity) as a three element array.
Pwrand([1.0, 0.75, 0.5, Pn(0.25, 2), Pseq(#[0.25, 0.5, 0.25], 1)], #[2, 3, 2, 0.5, 0.4].normalizeSum, inf)
.collect({ |delta|
	[delta,
	delta * #[0.2, 0.5, 0.9, 1.001].wchoose(#[1, 2, 4, 6].normalizeSum),
	rrand(0.2, 0.8)]
}) => MicRh(\bass1);

{ |notes, event| [event.delta, event[\length], 0.5] } => MicRh(\pad);
{ |notepat, event| Ptuple([Pwhite(0.2, 0.6, inf), Pwhite(1.0, 3.0, inf), 0.5], inf) } => MicRh(\pad2);

{ Pwrand([
	Pn(0.125, 4),
	Pseq(#[0.125, 0.25, 0.125], 1),
	Pn(0.125, 2),
	0.25,
	Pseq(#[0.375, 0.125], 1)
], #[1, 2, 3, 4, 2].normalizeSum, inf).collect({ |delta|
	[delta, #[0.4, 0.9, 1.1].wchoose(#[1, 3, 5].normalizeSum) * delta, exprand(0.2, 0.8)]
})
} => MicRh(\jumpy);


// "Macrorhythm" supplies the time between chords in the arpeggiator.
// [delta, length], where length is the amount of time to arpeggiate:
// if length < delta, the arpeggiation will stop early and wait for the next parent event
Pfunc({ [~parentDelta, ~parentLength] }) => MacRh(\depn);
// This macrorhythm looks at the last bass note and returns the same amount of time
// so that a harmony process will run in lockstep with the root changes
Pfunc({ (Library.at(\currentBassNote).tryPerform(\dur) ?? { rrand(8, 16) * 0.5 }).dup }) => MacRh(\lagger);


// This pattern determines the order in which chord notes will play out.
{ |notes| Pn(Pshuf(notes, 1), inf) } => ArpegPat(\reshuf);


// Since I use this function in a couple of places, I save it in the function repository for convenience.
// This calculates when process should start to sound in sync with the next root change.
{ |bp|
	var	rootbeat = BP(\roots).nextBeat ?? { BP(\roots)[\eventSchedTime] };
	(rootbeat.notNil and: { rootbeat >= bp.clock.beats }).if({
		AbsoluteTimeSpec(rootbeat + BP(\roots).leadTime - bp.leadTime)
	}, {
		NilTimeSpec.new	// start now, but results might be unpredictable
	});
} => Func(\syncToRoot);


//////// SOURCE MIDI DATA

// What key?
ModalSpec(#[0, 2, 3, 5, 7, 9, 10], 12, 7) => Mode(\gdor);

// Global repository for MIDIRecBuf objects
MBM(0) ?? { MIDIBufManager.new => MBM.prNew(0) };

// given in MIDI note numbers
// when used in a BP, the process converts them to their modal representation
MIDIRecBuf(\roots, [
		// midi note numbers
	#[31, 38, 34, 41, 36, 26, 29, 31, 24, 33, 36] + 12,
		// note deltas
	#[6, 4, 2, 5, 1, 6, 3, 2, 4, 5, 3],
		// note lengths
	#[6, 4, 2, 5, 1, 6, 3, 2, 4, 5, 3],
		// velocities/gates
	0.5
		// parameters:
		// mode: \gdor --> Mode(\gdor) for modal conversion
		// splitFunc: divides raw note stream into phrases using Func(...)
].asNotes, (mode: \gdor, splitFunc: \defaultMelSplit)) => MBM(0);

MIDIRecBuf(\rootsadp, [
	#[36, 34, 33, 31, 33, 29, 31, 33, 38, 36] + 12,
	1, 1, 0.5
		// parameter type specifies how these data will be used
		// \adapt means this is not meant to play directly,
		// but will crossbreed with the main material for new variations
].asNotes, (mode: \gdor, type: \adapt)) => MBM(0);

MIDIRecBuf(\bassfigs, [
	#[31, 38, 41, 43,  31, 34, 36, 41,  31, 36, 38, 43], 
	#[1, 1, 1, 2,  1, 1, 1, 2,  1, 1, 1, 2],
	1,
	1
		// type: \ch means these are chord data
].asNotes, (mode: \gdor, type: \ch)) => MBM(0);

MIDIRecBuf(\padch, [
	#[55, 60, 62, 65, 70,  55, 58, 64, 65, 72,  61, 65, 70, 72,  57, 67, 70, 72, 77],
	#[1, 1, 1, 1, 2,  1, 1, 1, 1, 2,  1, 1, 1, 2,  1, 1, 1, 1, 2],
	1, 1
].asNotes, (mode: \gdor, type: \ch)) => MBM(0);

~cleanup = { |self|
	self[\rvbmc].free;
};
});

} {
	AbstractChuckArray.defaultSubType = saveSubtype;
};

~noodle.know = true;	// to facilitate cleanup, see script file


//////// Algorithmic Noodling - H. James Harkins
//////// Performance script

//////// INITIALIZATION

// where am I on the hard disk?
// Windows users: See noodle-readme.html
~root = PathName(thisProcess.nowExecutingPath).pathOnly;

// open gui if desired
// this has some MIDI dependencies so if MIDI doesn't work in your system, omit this
(~root ++ "support/noodle-gui.scd").loadPath;

// loading the gui takes a few seconds
// after gui is finished loading, run this to move this window to a better location
BP.openCodeDoc(~root ++ "noodle-script.scd");

// if you are NOT using the gui, make sure to start the server
s.boot;

// run initialization
(~root ++ "noodle-init.scd").loadPath;

~noodle.push;

~hasGui = VP.exists(0);

// only if you have the GUI - you can put the things in the mixingboard
~hasGui.if({ ~master => MCG(7) });

// load drums
(
Fact(\kik) => BP(\kik);
Fact(\stick) => BP(\stick);

~hasGui.if({
	BP(\kik) => MT(1);
	BP(\stick) => MT(1);
	BP(\kik) => MCG(3);
	BP(\stick) => MCG(4);
});
)

// play both at once
BP(#[stick, kik]).play;


// load bass voicer and process
(
Fact(\bass_v) => VC(\bass);
Fact(\roots) => BP(\roots);
Fact(\basslink) => BP(\basslink);
Fact(\bass) => BP(\bass);
BP(\bass) => VC(\bass);

~hasGui.if({
	VC(\bass) => VP(0);
	BP(\roots) => MT(1);
	VC(\bass) => MCG(0);
});
)

BP(\roots).play;


// load pad
(
Fact(\pad_v) => VC(\pad);
Fact(\pad) => BP(\pad);
BP(\pad) => VC(\pad);

~hasGui.if({
	VC(\pad) => VP(1);
	BP(\pad) => MT(1);
	VC(\pad) => MCG(1);
});
)

BP(\pad).play;

// load jumpy
(
Fact(\jumpy_v) => VC(\jumpy);
Fact(\jumpy) => BP(\jumpy);
BP(\jumpy) => VC(\jumpy);

~hasGui.if({
	VC(\jumpy) => VP(2);
	BP(\jumpy) => MT(1);
	VC(\jumpy) => MCG(2);
});
)

// play with fadein
VC(\jumpy).env.target.level = 0;
BP(\jumpy).play;

VC(\jumpy).env.target.levelTo(-14.dbamp, 20);


/***
Here, you can play with starting and stopping processes.
With the GUI, you have more options for realtime tweaking.
	- You can change the mix.
	- A couple of synth parameters are exposed in the Voicer GUIs at right.
Or just sit back and listen.
***/


// fade out jumpy
VC(\jumpy).env.target.levelTo(0, 20);

// when done, stop it
BP(\jumpy).stop;

// fade out bass, but keep it playing to drive the chord changes
VC(\bass).env.target.levelTo(0, 20);

// (to save cpu, after bass is silent, you can suppress its synths by setting the process voicer to nil)
BP(\bass).event.voicer = nil;


// fade it all out with master
~master.levelTo(0, 40);

BP.all.stop;


// wipe everything for this track only out of the workspace
// if you're using the GUI, lots of things will disappear!
AbstractChuckArray.freeTypeAll(\noodle);

// reverb still exists because it didn't belong to a chucklib object
Event.pop;
~noodle.cleanup;

// only ~master MixerChannel is left
~master.free;



// set up guis etc. for composition development

var	masterLayout, chuckKeyCtl, composeDocKeyResp,
	originalDocInit;		// must maintain independent of environment

var	path;

~toolbarFlow.isNil.if({

Library.at(\mixer, \smallskin).isNil.if({
	Library.put(\mixer, \smallskin, MixerSkin.new.maxAcross_(1));
});

AbstractChuckArray.loadWindowBounds;

MIDIPort.init;
MIDIPort.resetAll;
MIDIPort.autoFreeSockets = false;	// protect midi controllers from being destroyed accidentally

s.boot;

~statusW = GUI.window.new("Building GUI, please wait...",
	Rect(GUI.window.screenBounds.width - 250 div: 2,
	GUI.window.screenBounds.height - 40 div: 2,
	250, 40));
~statusSl = GUI.rangeSlider.new(~statusW, Rect(10, 15, 230, 10))
	.lo_(0).hi_(0);
~numUpdates = (~voicerRows * ~voicerColumns) + 6;
~currentUpdate = 0;
~advanceStatus = {
	~currentUpdate = ~currentUpdate + 1;
	~statusSl.hi_(~currentUpdate / ~numUpdates);
};
~statusW.front;

~masterLayout = ResizeFlowWindow("control panel");
masterLayout = ~masterLayout;

~toolbarFlow = FlowView(~masterLayout.view, Rect(0, 0, 290, GUI.window.screenBounds.height-5));
(~useScroll ? false).if({
	~voicerScroll = GUI.scrollView.new(~masterLayout.view, Rect(0, 0, 450 * ~voicerColumns,
		GUI.window.screenBounds.height-50)).hasHorizontalScroller_(false);
}, {
	~voicerScroll = ~masterLayout.view;
});
~voicerFlow = FlowView(~voicerScroll, Rect(0, 0, 450 * ~voicerColumns, 20000));

GUI.staticText.new(~toolbarFlow, Rect(0, 0, 280, 20)).string_("Toolbar").align_(\center);

// voicerproxies -- creating this gui is time sensitive
// thus the remainder of the gui building is wrapped in a routine that is run on AppClock
Routine({
	var	count = 0;
	(~voicerRows * ~voicerColumns).do({ |i|
		VoicerProxy.new => VP.prNew(i);
			// first proxy has 4 controls, the rest have 3
		(3 + (count < ~voicersWith4Controls).binaryValue).do({
			VP(i).v.addControlProxy(nil, true)
		});
		count = count + 1;
		VP(i).v.maxControlProxies = VP(i).v.controlProxies.size;
		VP(i).v.smallGui(~voicerFlow, nil, nil, nil, nil, false);
		0.2.wait;
		~advanceStatus.();
		(i+1 % ~voicerColumns == 0).if({ ~voicerFlow.startRow; });
	});

~voicerFlow.recursiveResize;


// MIDI bufs

MIDIBufManager(nil, 0) => MBM.prNew(0);
MBM(0).v.gui(~toolbarFlow, Rect(0, 0, 290, 300));

// midi trigger
~toolbarFlow.startRow;
MT(1).gui(~toolbarFlow);

0.2.wait;
~advanceStatus.();

// make draggable modwheel and pitchbend controls
~midiControlFlow = FlowView.new(~toolbarFlow, Rect(0, 0, 80, 250));
VoicerMIDIController.defaultDest = VoicerGCDummy;
#[mw, pb].do({ |type|
	var mc;
	mc = VoicerMIDIController(\omni, type);
	GUI.dragSource.new(~midiControlFlow, Rect(0, 0, 30, 20))
		.align_(\center)
		.object_(mc).string_(mc.ccnum.shortName)
		.beginDragAction_({ |drag| drag.object });
//		.action_({ |drag|
//			try { drag.string_(mc.ccnum.shortName) }
//		});
	mc => CC.prNew(mc.ccnum.shortName.asSymbol);
});

~midiControlFlow.startRow;

GUI.dragSink.new(~midiControlFlow, 80@20).string_("reset").align_(\center)
	.background_(Color.new255(190, 198, 225)).stringColor_(Color.new255(191, 0, 0))
	.action_({ |drag|
		try { drag.object.reset };
		drag.string = "reset";
	});

GUI.dragSink.new(~midiControlFlow, 80@20).string_("free").align_(\center)
	.background_(Color.new255(190, 198, 225)).stringColor_(Color.new255(191, 0, 0))
	.action_({ |drag|
		var	vc, vp;
		(drag.object.class == VoicerProxy).if({
			vp = drag.object;
			vc = VC.collection.detect({ |vc| vc.v === vp.voicer });
			try { vc.free }
		}, {
			try { drag.object.free };
		});
		drag.string = "free";
	});

GUI.button.new(~midiControlFlow, 80@20)
	.states_([
		["use VProxy", Color.new255(191, 0, 0), Color.new255(190, 198, 225)],
		["use Voicer", Color.new255(191, 0, 0), Color.new255(190, 198, 225)],
	])
	.value_(1)
	.action_({ |view|
		BP.useVoicerProxy = (view.value == 0);
	});
BP.useVoicerProxy = false;

0.2.wait;
~advanceStatus.();

~toolbarFlow.startRow;
s.gui(~toolbarFlow);

~toolbarFlow.startRow;

~chuckBrowser = ChuckableBrowser(~toolbarFlow);
~chuckKeyCtl = ChuckBrowserKeyController(~chuckBrowser);
chuckKeyCtl = ~chuckKeyCtl;

	// ctrl-` from gui switches focus to current document
	// any other key, if not caught by a view, switches focus back to the chuck key controller
	// and passes key thru
if(thisProcess.platform.name == \osx) {
	~masterLayout.view.keyDownAction_({ |view, char, mods, unicode, keycode|
	//view.dumpBackTrace;
	//[char, mods, unicode, keycode].debug("bubbled up to masterlayout");
		(unicode == 30 and: { (mods bitAnd: 0x40000) > 0 }).if({
			Document.current.front;
		}, {
			chuckKeyCtl.focus.doKey(view, char, mods, unicode, keycode);
		});
	});
};

0.2.wait;
~advanceStatus.();

// fix views with nil keyDownActions so that bubbling will be right
// defaultKeyDownAction returns nil if it should bubble, so func should just pass the return thru
f = { |view|
		// MIDIBufManager gui uses a toggletextfield - this change to key down action breaks it
	(view.class.name != 'ToggleTextField').if({
		(view.respondsTo(\keyDownAction) and: { view.keyDownAction.isNil }).if({
			view.keyDownAction = { |view, char, modifiers, unicode, keycode|
				view.defaultKeyDownAction(char, modifiers, unicode, keycode)
			};
		});
			// nil-do is its own nil check
		view.tryPerform(\children).do(f.value(_));
	});
};

f.value(~masterLayout.view);
f = nil;

~toolbarFlow.recursiveResize;

0.2.wait;
~advanceStatus.();

//~masterLayout.recursiveResize.front;

// mixer gui slots
~board = MixingBoard("mixer control pool", Library.at(\mixer, \smallskin));
8.do({ |i| MixerChannelGUI(nil, ~board) => MCG.prNew(i);
	~board.add(MCG(i).v);
});
1.0.wait;
~advanceStatus.();
~board.refresh;
1.0.wait;
~advanceStatus.();

~masterLayout.window.bounds = ~controlpanelBounds;
	// test scrollability
~voicerScroll.respondsTo(\visibleOrigin).if({
	~voicerScroll.bounds = ~voicerScroll.bounds.width_(305)
});
~board.w.bounds = ~mixerBounds;
if(thisProcess.platform.name == \osx) {
	~codedoc = Document.new("type code");
	~codedoc.bounds_(~codedocBounds);
	Document.listener.bounds = ~postwindowBounds;
};

Library.put(\codeBounds, ~codedocBounds);

~statusW.close;
~statusW = ~statusSl = ~numUpdates = ~currentUpdate = ~advanceStatus = nil;
~masterLayout.front.refresh;

}).play(AppClock);

}, {
	"gui already loaded".warn;
});



// Chapter 23. Dialects, Constraints, and Systems within Systems

// 1 Dialects

// not a Figure
// a quine in SC3
(_ + '.(*' +  quote(_)  + '! 2)').(*"(_ + '.(*' +  quote(_)  + '! 2)')" ! 2)


// not a Figure
// ensure VagueList.sc in in the enxtensions folder 
// VagueList has a vague 'at' method 
a�=�VagueList[0,�1,�2,�3];  
a.at(2); 	// may return 1, 2, or 3 
a.at(2); 
a.at(2); 


// not a Figure
// Eniac Cycling Unit with adjustable clock speed
(
{	var clockspeed = MouseX.kr(1, 300, 1);
	var clocksignal = LFSaw.ar(clockspeed).range(0, 80);
 	var timingPulses = CU_PulseLookUpTables.ar(clocksignal); // 10 channels.
 	timingPulses * 0.2
}.scope;
)

// Figure 23.1 The ENIAC Cycling Unit (graphic image).


// not a Figure
// two ways of coupling parameters

{ var freq = MouseX.kr(20, 2000, 1); Pulse.ar(freq, freq.explin(20, 2000, 0.95, 0.05)) }.play;


// more intricate dependency
{ var freq = MouseX.kr(20, 2000, 1);  Pulse.ar(freq,  freq.explin(20, 2000, 0, 5pi).sin * 0.45 + 0.5) }.play;


// Figure 23.2: Two ways of constraining parameters
(
{	var f = { | a, b | [a.min(1 - b), b.min(1 - a)] };
	var freq = f.value(MouseX.kr, MouseY.kr) * 400 + 500;
	SinOsc.ar(freq) * 0.1
}.play;
)


(
a = { |freq=100, width=0.5|
	var df, dw;
	df = freq - LastValue.kr(freq);
	dw = width - LastValue.kr(width);
	freq = freq + (dw * 100);
	width = width + (df / 100);
	Pulse.ar(freq, width.clip(0.01, 0.99).poll) * 0.1
}.play;
)

a.set(\freq, exprand(200.0, 600.0));
a.set(\width, 1.0.rand);


//  Figure 23.3 � Pokey registers (graphic image)



// Figure 23.4:  Modulating Pokey inputs
// modulating the frequency input to a Pokey UGen results in great variance
(
{ 
	var rate = MouseX.kr(0, 255);
	var mod = LFPulse.kr(1);
	var amp = 2r1100; // 12 of 16
	Pokey.ar(rate + mod, audc1: 2r01000000 + amp);
}.play
);

// modulating the pure tone bit
(
{ 
	var rate = MouseX.kr(0, 255);
	var mod = LFPulse.kr(1);
	var amp = 2r1100; // 12 of 16
	Pokey.ar(rate, audc1: 2r00100000 + (mod * 2r00100000) + amp);
}.play
);




// Figure 23.5: Setting up rd_clt and mapping Ctls to a Synth's controls. 
// You may need to install the rd_clt Quark. See the Quarks help file.
(
	SynthDef("FreqMod", { |car=440, carFine=1, mod=100, modFine=1, index=4, amp=0.3, pan=0| 
		Out.ar(0, Pan2.ar(PMOsc.ar(car * carFine, mod * modFine, index), pan, amp)); 
	}).add; 		
	
	c = Controller.new(s, 256);
	c.makeInterface(2, 3, 0, "Freq Mod controller");
	
	c[0].setup("carFreq", [50, 4800, \exp].asSpec, 440);
	c[1].setup("carFreqFine", [0.95, 1.05, \exp].asSpec, 1);
	c[2].setup("modFreq", [10, 4800, \exp].asSpec, 10);
	c[3].setup("modFreqFine", [0.95, 1.05, \exp].asSpec, 1);
	c[4].setup("mIndex", [0, 24, \lin].asSpec, 1);
	c[5].setup("amp", [0, 1, \lin].asSpec, 0.2);
);


a = Synth("FreqMod") // start the synth
6.do({|i| a.map(i, c[i].index)}); // map the synth control to the controller.

a.free


//  3 Scheduling constraints: HierSch


// Figure 23.6 HierSch scheduling constraints and priority levels (graphic image)


// Figure 23.7: Priority-based HierSch scheduling.
// You may need to install the HierSch Quark. See the Quarks help file. 

(
SynthDef(\ping, {
	arg out = 0, mfreq = 69, pan = 0, gain = 0.2, dur = 0.25;
	Out.ar(out, Pan2.ar(
	SinOsc.ar(mfreq.midicps, 0, 
	EnvGen.kr(envelope: (Env.perc(0.01, dur)), doneAction: 2)),
	pan, gain));
}).add;

// function to play a synth
m = {|f, d=0.3, g=0.2, p=0| Synth(\ping, [\mfreq, f + 45, \pan, p, \gain, g, \dur, d])};

// function to make a chord
c = {|a, b, c| [a, b, c].do{|i| m.value(i, 1.2, 0.075, rrand(-1.0, 1.0))}};

t = TempoClock.default.tempo_(116 / 60); // assign clock to t
b = HierSch.new(t); // start new HierSch, pass in clock
)

(
// HierSch schedules
b.schedAbs(t.beats.ceil + 48, 1, { var offset = [0, 5, 7, 12]; c.value(*[12, 16, 19]+ offset.choose)}, Prand(#[1.5, 3], 30)); // enters last, priority highest

b.schedAbs(t.beats.ceil + 14, 2, {|b, p, d, c| m.value([0, 0, 7, 5, 4].at(c % 5) + [12, 24].choose, 0.4, 0.15, rrand(-1.0, 1.0))}, Pseq(#[2, 2, 2, 1], 15)); // enters middle, priority middle

b.schedAbs(t.beats.ceil, 3, { |b, p, d, c| m.value(VagueList[0, 12, 4, 7, 10, 10, 9, 9, 7].at(c % 9))}, Pseq(#[0.5, 0.5, 0.5, 0.5, 0.25, 0.75, 1, 0.5, 0.5], 17)); // enters first, priority lowest
)


// 	4 Object Systems: Redirections and Constraints


// 	4.1 Redirecting Assignment: Maybe and LazyEnvir

// not a Figure

x = 1;	// assigment

~x = 1;	// environment put
\x.envirPut(1);
currentEnvironment.put(\x, 1); 




// Figure 23.8: Maybe yes.

p = LazyEnvir.push;
~a = ~b * ~c;
~a.value; 	// => nil
~b = Pseq([1, 2, 3]).asStream;
~c = 10;
~a.value; 	// => 10
~a.value; 	// => 20
~b = [1, 2, 3];
~a.value; 	// => [10, 20, 30];
~a.postcs;	// => Maybe((Maybe([ 1, 2, 3 ]) * Maybe(10)))
p.pop


//	4.2 Declaring Constraints: List Comprehensions

// not a Figure
_ + 1 ! 7  // => [ 1, 2, 3, 4, 5, 6, 7 ]

Array.fill(7, { |i| i + 1 })  // => [ 1, 2, 3, 4, 5, 6, 7 ]


// not a Figure
// list comprehensions example 
	
f�=�{:[x, y], x <- (2..10), y <- (x..10), gcd(x, y) == 1  }; 

f.next; // [2, 3] 
f.next; 

f.all;

f�=�{:[x, y], x<-(2..10), y<-(x + 1..10), gcd(x, y) == 1; x.isPrime.not and: y.isPrime.not  }; 
f.next; // [2, 3] 
f.next;  


// Figure 23.9: Coprimes as frequency and trigger rates
(
var x;
x = { |rates=#[1, 1]| Ringz.ar(Impulse.ar(rates) * 0.1, rates * 80, 1 / rates) }.play;
fork {
	var str = {:[x, y], 
		x<-(40..2), 
		y<-(x + 1..40),
		gcd(x, y) == 1,
		x.isPrime.not and: y.isPrime.not
	};
	0.5.wait;
	str.do { |primes|
		x.setn(\rates, primes.postln);
		(primes.product / primes.sum / 20).wait;
	}
};
)

// 5 Text Systems


// not a Figure
a = Pseq("aggaca").collect(_.ascii)
a.asStream.all // => [ 97, 103, 103, 97, 99 ]


// Figure 23.10: A very simple notation translater

(
var dict, maxLength = 0;
dict = (
	ab: { (note: [4, 0, 7], legato: 0.1, dur: 1) },
	ba: { (note: [4, 9, 8], legato: 0.3, dur: 0.3) },
	aaa: { (note: 5, legato:1.5) },
	bbb: { (note: 0, legato:2.5, dur: 0.25) }
);

dict.keys.do { |key| maxLength = max(maxLength, key.asString.size) };

f = { |str|
	var i = 0, n = 0, substr, event;
	while { i < str.size } {
		substr = str[i..i + n];
		event = dict[substr.asSymbol].value;
		if(event.notNil) {
			substr.postln;
			i = i + n + 1;
			n = 0;
			event.postln.play;
			event.delta.wait;
		} {
			if(n + 1 < maxLength) { n = n + 1 } { n = n - 1; i = i + 1 }
		};
	};
};
)

// play some sequences
fork { f.value("abbbbaab"); }
fork { f.value("aaabbbabbaaaabbabaaaaba"); };



// not a Figure
	
x = "1 + 2";
x.interpret�/�3;�//�1
x�=�x.replace("+", "-"); 
x.interpret�/�3;�//�-0.33333


this.preProcessor = { |str| str.replace("+", "-") } 
1 + 2 // -1
this.preProcessor = nil 
1 + 2 // 3



// brainfuck, urban mueller 1993
// for its universality, see also http://www.hevanet.com/cristofd/brainfuck/utm.b
/*
>	Move the pointer to the right
<	Move the pointer to the left
+	Increment the memory cell under the pointer
-	Decrement the memory cell under the pointer
.	Output the character signified by the cell at the pointer
,	Input a character and store it in the cell at the pointer
[	Jump past the matching ] if the cell under the pointer is 0
]	Jump back to the matching [
*/

(
var findBrack = { |str, offset|
		var count = 0, i = offset;
		while {
			if(str[i] == $[ /*]*/) { count = count + 1 };
			if(str[i] == /*[*/$]) { count = count - 1 };
			i < str.size and: { count > 0 }
		} {
			i = i + 1;
		};
		if(i == str.size and: { count > 0 }) { nil } { i }	
};

e = (
	'>': { ~ptr = ~ptr + 1 },
	'<': { ~ptr = ~ptr - 1 },
	'+': { ~mem[~ptr] = ~mem[~ptr] + 1;  },
	'-': { ~mem[~ptr] = ~mem[~ptr] - 1; },
	'.': { ~mem[~ptr].asAscii.post; },
	',': { |char| ~mem[~ptr] = char.ascii },
	'['/*]*/ : {   
			
			if(~mem[~ptr] <= 0) {
				~codePtr = findBrack.(~code, ~codePtr);
				if(~codePtr.isNil) { Error("syntax error!").throw };
				
			};
			~stack = ~stack.add(~codePtr);
		},
	/*[*/']': {
		~codePtr = ~stack.pop;
		if(~codePtr.isNil) { Error("syntax error closing br!").throw } { ~codePtr = ~codePtr - 1 };
	}
);

x = (
	reg: e,
	memsize: 1024,
	codePtr: 0,
	
	interpret: { |x, code, verbose = false, dt = 0.01|
		x.use {
			if(dt.notNil) {
				fork { x.pr_interpret(code, verbose, dt) }
			} {
				x.pr_interpret(code, verbose);
			}
		};"";
	},
	pr_interpret: { |x, code, verbose = false, dt|
			var func, sym, count = 0, max = 1e5, overrun;
			
			~code = code;
			~codePtr = 0;
			~ptr = 0;
			~mem = 0.dup(~memsize);
			~stack = nil;
			
			while {
				sym = ~code[~codePtr].asSymbol;
				func = ~reg[sym];
				
				if(verbose) { 
					postf("\nptr: % char: % stack: %\nmem: % \n", 
						~codePtr, sym, ~stack, ~mem.join($ )) 
				};
				count = count + 1;
				overrun = dt.isNil and: { count >= max };
				if(overrun) { "time overrun (t > %).\n".format(max).warn };
				func.notNil and: { ~codePtr < ~code.size } and: { overrun.not }
			} {
				func.value;
				if(~ptr >= ~memsize) { "memory overrun (i > %).\n".format(~memsize).throw };
				~codePtr = ~codePtr + 1;
				if(dt.notNil) { dt.yield };
			};
			
	}

);

);


x.interpret("++++----", true, 0.4); 
x.interpret("----++++", true, 0.4);
x.interpret(join($+ ! 100) ++ ".+.+.+.", false, 0.4);

x.interpret("++>+++><---<--", true);
x.interpret("+>+>>+>+>>+", true);

x.interpret("[+]>+", true); // jump first to +>

x.interpret("+[-]", true); // go in first first, then jump out
x.interpret("+[-]", true); // go in first first, then jump out


x.interpret("+[+-]+++", true);

x.interpret("++[++-.]+");

// hello world
(
x.interpret(">+++++++++[<++++++++>-]<.>+++++++[<++++>-]<+.+++++++..+++.>>>++++++++[<++++>-]
<.>>>++++++++++[<+++++++++>-]<---.<<<<.+++.------.--------.>>+."); "";
)




// quines????
// takes long..
(
x.interpret("->++>+++>+>+>++>>+>+>+++>>+>+>++>+++>+++>+>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>+>+>++>>>+++>>>>>+++>+>>>>>>>>>>>>>>>>>>>>>>+++>>>>>>>++>+++>+++>+>>+++>>>+++>+>+++>+>++>+++>>>+>+>+>+>++>+++>+>+>>+++>>>>>>>+>+>>>+>+>++>+++>+++>+>>+++>+++>+>+++>+>++>+++>++>>+>+>++>+++>+>+>>+++>>>+++>+>>>++>+++>+++>+>>+++>>>+++>+>+++>+>>+++>>+++>>+[[>>+[>]+>+[<]<-]>>[>]<+<+++[<]<<+]>>+[>]+++[++++++++++>++[-<++++++++++++++++>]<.<-<]", false, 0.001); 
)

(
x.interpret(">+++++>+++>+++>+++++>+++>+++>+++++>++++++>+>++>+++>++++>++++>+++>+++>+++++>+>+>++++>+++++++>+>+++++>+>+>+++++>++++++>+++>+++>++>+>+>++++>++++++>++++>++++>+++>+++++>+++>+++>++++>++>+>+>+>+>++>++>++>+>+>++>+>+>++++++>++++++>+>+>++++++>++++++>+>+>+>+++++>++++++>+>+++++>+++>+++>++++>++>+>+>++>+>+>++>++>+>+>++>++>+>+>+>+>++>+>+>+>++++>++>++>+>+++++>++++++>+++>+++>+++>+++>+++>+++>++>+>+>+>+>++>+>+>++++>+++>+++>+++>+++++>+>+++++>++++++>+>+>+>++>+++>+++>+++++++>+++>++++>+>++>+>+++++++>++++++>+>+++++>++++++>+++>+++>++>++>++>++>++>++>+>++>++>++>++>++>++>++>++>++>+>++++>++>++>++>++>++>++>++>+++++>++++++>++++>+++>+++++>++++++>++++>+++>+++>++++>+>+>+>+>+++++>+++>+++++>++++++>+++>+++>+++>++>+>+>+>++++>++++[[>>>+<<<-]<]>>>>[<<[-]<[-]+++++++[>+++++++++>++++++<<-]>-.>+>[<.<<+>>>-]>]<<<[>>+>>>>+<<<<<<-]>++[>>>+>>>>++>>++>>+>>+[<<]>-]>>>-->>-->>+>>+++>>>>+[<<]<[[-[>>+<<-]>>]>.[>>]<<[[<+>-]<<]<<]");
);


// cadavre exquis no. 2, from sc-users list, October 2005.
// Archives at http://lists.create.ucsb.edu/mailman/listinfo/sc-users


// On 22 Oct 2005, at 22:50, Julian Rohrhuber wrote:

// cadavre exquis no. 2

(
z = { var x = 1.0.rand; { |i, j| (x * i) + (x * j) % 5 } };

y = { |q=0.1|
	Formlet.ar(
		Dust.ar(LFPulse.kr(20 * q, [0.2, 0.2]) * 1000 + 10), 
		q * 400 + 800, 
		0.08, 
		0.1
	)
};

fork {
	var d = y.play;
	var q;
	1.wait;
	3.do {
		3.do {|i|
			q = z.value;
			3.do {|j|
				d.set(\q, q.(i, j));
				2.wait
			}
		}
	};
	d.free;
}
)


//////////////

// On 22 Oct 2005, Tom Hall wrote:

// "curried" cadavre exquis no. 2
// y has got places to go?

(
z = { var x = 1.0.rand; { |i, j| (x * i) + (x * j) % 5 } };

y = { |q=0.1|
	var  distance, pitchRatio, amp;    // see hypot help
	distance = hypot(9, LFSaw.kr(1/6, 0, 100));
	pitchRatio = (344 - Slope.kr(distance)) / 344;
	amp = 300 / distance.squared;
	Formlet.ar(Dust.ar(LFPulse.kr(20 * q, [0.2, 0.2]) * 1000 + 10),
			(q * pitchRatio * 1000) + 750, 0.08, 0.1, amp)
};

fork {
	var d = y.play;
	var q;
	1.wait;
	3.do {
		3.do {|i|
			q = z.value;
			3.do {|j|
				d.set(\q, q.(i, j));
				2.wait
			}
		}
	};
	d.free;
}
)


////////////

// On 25 Oct 2005, kernal wrote:

// cadavre exquis no. 2
// reminds me of YOU ;-)

(
z = { var x = 1.0.rand; { |i, j| (x * i) + (x * j) % 9 } };

y = { |q=0.1|
	
	Limiter.ar(
		Formlet.ar(
			CombC.ar(SinOsc.ar(232+(q*183) + {LFNoise2.ar(q*2332+0.45,9)}.dup,0,1),
				1,q,q*202), q * 808 + 50, 0.02, 0.1,0.5),
		0.9,0.01
	)
};

fork {
	var d = y.play;
	var q;
	1.wait;
	3.do {
		3.do {|i|
			q = z.value;
			3.do {|j|
				d.set(\q, q.(i, j));
				2.wait
			}
		}
	};
	d.free;
}
)


/////////////

// On 28 Oct 2005, Tim Walters wrote:

// cadavre exquis no. 2
// another round

(
z = { var x = 1.0.rand; { |i, j| (x * i) + (x * j) % 9 } };

y = { |q=0.1|

    var a;
    a = SinOsc.ar(232+(q*183)+{LFNoise2.ar(q*q+0.45,9)}.dup,0,1);
    LPF.ar(
        CombC.ar(a,1,Lag.kr(q, q.squared),q*808) * 0.25
    , Lag.kr(q, q.squared) * 808 + 50, (q + 1).reciprocal.squared, 0.1, a)
};

fork {
    var d = y.play;
    var q;
    (1.0.rand + 0.1).wait;
    3.do {
        3.do {|i|
            q = z.value;
            3.do {|j|
                d.set(\q, q.(i, j));
                (2.0.rand + 0.2).wait
            }
        }
    };
    d.free;
}
)


/////////////

// On 28 Oct 2005, Julian Rohrhuber wrote:

// cadavre exquis no. 2
// some more curry

(
z = { var x = 1.0.rand;
	{ |i|
		{ |j| (x * i) + (x * j) % 5 }
	}
};

y = { |q=0.1|

    var a, f;
    var  distance, pitchRatio, amp;    // see hypot help
	distance = hypot(9, LFSaw.kr(1/6, 0.5, 100));
	pitchRatio = (344 - Slope.kr(distance)) / 344;
	amp = 300 / distance.squared;
	f = q * pitchRatio * 1000 + 200;
 	a = SinOsc.ar(f + { LFNoise2.ar(q * q + 0.45, 9) }.dup) * amp * 0.1;
    RHPF.ar(
       	CombC.ar(a, 1, Lag.kr(q, q.squared), q * 808) * 0.25,
   		Lag.kr(q, q.squared) * 808 + 50,
   		(q + 1).reciprocal.squared,
   		0.1,
   		a
   	)
};

fork {
	var d = y.play;
	var q, b;
	(1.0.rand + 0.1).wait;
		3.do {
		b = z.value;
		3.do {|i|
			q = b.(i);
			3.do {|j|
				d.set(\q, q.(j));
				2.wait
			}
		}
	};
	d.free;
}
)


////////////

// On 29 Oct 2005, Jonathan Segal wrote:

// cadavre exquis no. 2
// chunks in the sauce

(
z = { var x = 1.0.rand;
    { |i|
        { |j| (x * i) + (x * j) % 5 }
    }
};

y = { |q=0.1|

    var a, f;
    var  distance, pitchRatio, amp, pulser, ratio;    // see hypot help
        pulser = LFNoise0.kr(q.reciprocal).range (0.125, 8);
    distance = hypot(9, LFCub.kr(pulser, 0.5, 100));
    pitchRatio = (distance.squared - Slope.kr(distance)) / distance.squared;
    amp = 300 / distance.squared;
    f = q * Slope.kr(pitchRatio, 0.002).squared  + 150;
     a = (SinOsc.ar(f + { LFNoise0.ar(q.reciprocal*2, 27) }.dup) * amp).distort;
     ratio=LFNoise2.kr(q).range(0,1);
     CombC.ar(a*ratio, 1, Lag.kr(q/500, q).max(0.0001),q, a*ratio.reciprocal).softclip

};

fork {
    var d = y.play;
    var q, b;
    (1.0.rand + 0.1).wait;
        4.do {
        b = z.value;
        5.do {|i|
            q = b.(i);
            3.do {|j|
                d.set(\q, q.(j));
                0.5.wait
            }
        }
    };
    d.free;
}
)


////////////

// On 29 Oct 2005, Tim Walters wrote:

// cadavre exquis no. 2
// the curry eats itself

(
z = { var x = 1.0.rand;
    { |i|
        { |j| (x * i) + (x * j) % 5 }
    }
};

y = { |q=0.1|

    var a, f, z, c;
    var  distance, pitchRatio, amp, pulser, ratio;    // see hypot help
        pulser = LFNoise0.kr(q.reciprocal).range (0.125, 8);
    distance = hypot(9, LFCub.kr(pulser, 0.5, 100)).reciprocal * 0.001;
    pitchRatio = (distance.squared - Slope.kr(distance)) / distance.squared;
    amp = 300 / distance.squared;
    f = q * Slope.kr(pitchRatio, 0.002).squared  + 150;
     a = (SinOsc.ar(f + { LFNoise0.ar(q.reciprocal*2, 27) }.dup) * amp).distort;
     z = Saw.ar(ZeroCrossing.ar(a) * 0.125).range(0.5, 1);

     ratio=LFNoise2.kr(q).range(0,1);
     c = CombC.ar(a*ratio * z, 1, Lag.kr(q/500, q).max(0.0001) * z, q * z,
     a*ratio.reciprocal * 0.1).clip(-0.25, 0.25);
    Normalizer.ar(Formlet.ar(c, q * 400 + 400, 
    	(q + 1).reciprocal * z * 0.01, z * 0.01), 0.75, 0.1)

};

fork {
    var d = y.play;
    var q, b;
    (1.0.rand + 0.1).wait;
        4.do {
        b = z.value;
        5.do {|i|
            q = b.(i);
            3.do {|j|
                d.set(\q, q.(j));
                ((q.(j) + 1).reciprocal + 0.5).wait
            }
        }
    };
    d.free;
}
)


///////////

// On 29 Oct 2005, Fredrik Olofsson wrote:

// cadavre exquis no. 2
// the country&western curry that ate itself?

(
z = { var x = 1.0.rand;
    { |i|
        { |j| (x * i) + (x * j) % 5 }
    }
};

y = { |q=0.1|
	var a, f, z, c, i, o;
	var  distance, pitchRatio, amp, pulser, ratio;    // see hypot help
	i= LocalIn.ar(2);
	pulser = (Amplitude.kr(i)+q).range(0.15, 2);
	distance = hypot(9, LFCub.kr(pulser, 0.5, 100)).reciprocal * 0.001;
	pitchRatio = (distance.squared - Slope.kr(distance)) / distance.squared;
	amp = 300 / distance.squared;
	f = q * Slope.kr(pitchRatio, 0.002).squared  + 150;
	a = (SinOsc.ar(f + { LFNoise0.ar(q.reciprocal*2, 27) }.dup) * amp).distort;
	z = Saw.ar(ZeroCrossing.ar(a) * 0.125).range(0.5, 1);

	ratio=LFNoise2.kr(q).range(0,1);
	c = CombC.ar(a*ratio * z, 1, Lag.kr(q/500, q).max(0.0001) * z, q * z,
	a*ratio.reciprocal * 0.1).clip(-0.25, 0.25);
	o= Normalizer.ar(Formlet.ar(c, q * 400 + 400, 
		(q + 1).reciprocal * z * 0.01, z * 0.01), 0.75, 0.1);
	LocalOut.ar(DelayN.ar(o, 0.1, 0.1));
	o
};

fork {
	var d = y.play;
	var q, b;
	(1.0.rand + 0.1).wait;
		4.do {
		b = z.value;
		5.do {|i|
			q = b.(i);
			3.do {|j|
				d.set(\q, q.(j));
				((q.(j) + 1).reciprocal + 0.5).wait
			}
		}
	};
	d.free;
}
)

// (couldn't get the banjo sound quite right)
// _f


////////////

// On 29 Oct 2005, John Thompson wrote:

// cadavre exquis no. 2
// the country&western pigeon curry that ate itself?

(
Routine({
7.do({
~zed = { var x = 1.0.rand;
        { |i|
                { |j| (x * i) + (x * j) % 5 }
        }
};

~yed = { |q=0.1|

     var a, f;
     var  distance, pitchRatio, amp;   
        distance = hypot(9, LFSaw.kr(1/6, 0.5, 1000 + 1000.rand));
        pitchRatio = (344 - Slope.kr(distance)) / 344;
        amp = 300 / distance.squared;
        f = q * pitchRatio * 1000 + 200;
        a = SinOsc.ar(f + { LFNoise2.ar(q * q + 0.45, 9) }.dup) * amp * 0.1;
     Pan2.ar(LeakDC.ar(PitchShift.ar(RHPF.ar(
                CombC.ar(a, 0.15, Lag.kr(q, q.squared) 
                	* 0.5, 5 + (q * LFNoise0.kr(15, 100, 808))) * 0.25,
                Lag.kr(q, q.squared) * LFNoise1.kr(15, 1000, 1808) + 50,
                LFNoise1.kr(13, 1.1, (q + 1).reciprocal.squared),
                0.1,
                a
        ), 0.4, 0.5, 2.0, SinOsc.kr(0.1, 0, 0.2,
0.2))), -1.0 + LFNoise1.kr(5, 1, 0))
};

fork {
        var d = ~yed.play;
        var q, b;
        (1.0.rand + 0.1).wait;
                3.do {
                b = ~zed.value;

                3.do {|i|
                        q = b.(i);
                        3.do {|j|
                                d.set(\q, q.(j));
                                2.wait
                        }
                }
        };
        d.free;
};

});

// [code block contniues]
(
z = { var x = 1.0.rand;
     { |i|
         { |j| (x * i) + (x * j) % 5 }
     }
};

y = { |q=0.1|
        var a, f, z, c, i, o;
        var  distance, pitchRatio, amp, pulser, ratio;

        i= LocalIn.ar(2);
        pulser = (Amplitude.kr(i)+q).range(0.15, 2);
        distance = hypot(9, LFCub.kr(pulser, 0.5, 100)).reciprocal * 0.001;
        pitchRatio = (distance.squared - Slope.kr(distance)) / distance.squared;
        amp = 300 / distance.squared;
        f = q * Slope.kr(pitchRatio, 0.002).squared  + 150;
        a = (SinOsc.ar(f + { LFNoise0.ar(q.reciprocal*2, 27) }.dup) * amp).distort;
        z = Saw.ar(ZeroCrossing.ar(a) * 0.125).range(0.5, 1);

        ratio=LFNoise2.kr(q).range(0,1);
        c = CombC.ar(a*ratio * z, 1, Lag.kr(q/500, q).max(0.0001) * z, q * z,
        a*ratio.reciprocal * 0.1).clip(-0.25, 0.25);
        o= Normalizer.ar(
        	Formlet.ar(c, q * 400 + 400, (q + 1).reciprocal * z * 0.01, z * 0.01), 0.75, 0.1
        );
        LocalOut.ar(DelayN.ar(o, 0.1, 0.1));
        o
};

fork {
        var d = y.play;
        var q, b;
        (1.0.rand + 0.1).wait;
                4.do {
                b = z.value;
                5.do {|i|
                        q = b.(i);
                        3.do {|j|
                                d.set(\q, q.(j));
                                ((q.(j) +1).reciprocal + 0.5).wait
                        }
                }
        };
        d.free;
}
);

}).play
)


////////////////////////

// On 31 Oct 2005, Julian Rohrhuber wrote:

// cadavre exquis no. 2
// the country&western pigeon curry that ate itself but the rubbersnake ?

(
var zed, yed, led;
var f1, f2;

zed = { var x = 1.0.rand;
		{ |i|
				{ |j| (x * i) + (x * j) % 5 }
		}
};

yed = { |q=0.1|

	 var a, f;
	 var  distance, pitchRatio, amp;
		distance = hypot(9, LFSaw.kr(1/6, 0.5, 1000 + 1000.rand));
		pitchRatio = (344 - Slope.kr(distance)) / 344;
		amp = 300 / distance.squared;
		f = q * pitchRatio * 1000 + 200;
		a = SinOsc.ar(f + { LFNoise2.ar(q * q + 0.45, 9) }.dup) * amp * 0.1;
	 Pan2.ar(
		LeakDC.ar(
			PitchShift.ar(RHPF.ar(
				CombC.ar(a, 0.15, Lag.kr(q, q.squared) * 0.5, 
					5 + (q * LFNoise0.kr(15, 100, 808))) * 0.25,
				Lag.kr(q, q.squared) * LFNoise1.kr(15, 1000, 1808) + 50,
				LFNoise1.kr(13, 1.1, (q + 1).reciprocal.squared),
				0.1,
				a
		),
		0.4, 0.5, 2.0, SinOsc.kr(0.1, 0, 0.2, 0.2))),
	  -1.0 + LFNoise1.kr(5, 1, 0))
};

led = { |q=0.1| Pan2.ar(BPF.ar(Impulse.ar(10 * (q+1), 3), 
	q * 1000 + 3000, 0.05) * q.lag(1), q * 2 - 1) };

f1 = { |synthFunc, wait=({2.0 + 0.2.rand}), repeat=3|
			var d = synthFunc.play;
			var q, b;
			wait.value.wait;
		 repeat.do {
				b = zed.value;
				3.do {|i|
						q = b.(i);
						3.do {|j|
	d.set(\q, q.(j));
	wait.value.wait;
						}
				}
		};
		d.free;
};

2.do {
		fork { f1.(yed);  f1.(led, { #[1, 2].choose }, 8); };
		fork {
			6.wait;
			f1.(led, { 0.1.rand + 0.1 }, 18);
		};
	};
)

// End of submissions

// Controller.help.sc - (c) rohan drape, 2004-2007

// Initialise as required, ie. boot
// scsynth & interface engine.

s.boot;
SwingOSC.default.initTree;

// Create a new <Controller> value, and create
// a window to monitor and edit <Ctl> status.
// A <Ctl> interface has three components, a
// NameView, a DialView and a ValueView.

(
c = Controller.new(s, 256) ;
c.makeInterface(rows: 4, columns: 3, offset: 0);
)

// There is a trivial midi initializer to set
// up some standard midi mappings, if it does
// not do what you want you will need to do
// this yourself - if you are not using midi
// skip this...

c.midiInitialize;

// Setup the first <Ctl> with a non-zero depth
// value.  Editing the DialView modifies the
// <Ctl> value.  Pressing the NameView
// increments the <Ctl> state, using the shift
// modifier decrements.  Note that modifying
// the state modifies the value, and also the
// reverse.  The display method prints the
// <Ctl> status.

(
c[0].setup("Frequency", ControlSpec.new(220, 440, ExponentialWarp), 330, 4);
c[0].display;
c[0].addRecv({
	arg index, spec, value, state;
	[index, spec, value, state].postln;});
)

// Make the state modification follow a
// constrained map.  The array is given in
// 'value' space and mapped immediately to
// 'internal' space, subsequent changes to the
// <Ctl> spec will keep the same 'shape'
// stateMap.  Note that the map is only
// consulted when the state is modified,
// changing the value modifies the state in
// the same unit linear manner.

c[0].stateMap = [330, 360];

// The state modification map need not be
// linear.

c[0].stateMap = [220, 221, 400];

// If the state modification map has the same
// number of elements as the depth of the
// <Ctl> the values are located exactly.

c[0].depth = 4;
c[0].stateMap = [220, 230, 240, 420];
c[0].state = 1;
c[0].value;            // => 230
c[0].increment(-2);
c[0].value;            // => 420

// Assigning nil as the map reinstates the
// default linear map.

c[0].stateMap = nil;

// The <Ctl> value can be updated from the
// server.  The ValueView at a <Ctl> interface
// is a button that can be pressed to update
// that value in this manner.

(
s.sendMsg("/c_set", 0, 345);
c[0].update;
c[0].value;
)

// Make an interface with a color scheme.  The
// colorChooser argument should be a procedure
// that returns a <Color> value based on an
// <Integer> index.

(
c.makeInterface(colorChooser: {
	arg index;
	[Color.yellow, Color.white].wrapAt(index);});
)

// Replace the default midi controller map.
// This map makes the following sixteen
// controller arrangement:

//         .---.---.---.---.---.---.---.---.
//         | 0 | 8 | 1 | 9 | 2 | 10| 3 | 11|
//         .---.---.---.---.---.---.---.---.
//         | 4 | 12| 5 | 13| 6 | 14| 7 | 15|
//         .---.---.---.---.---.---.---.---.

(
MIDIIn.control = {
	arg source, channel, number, value;
	var index ;
	index = [(0..7),(8..15)].lace(16).at(number);
	c[index].internal = value / 127.0;
};
)

// Make two Sine oscillators.

(
c[0].setup("Frequency", ControlSpec.new(220, 240, ExponentialWarp), 221);
c[1].setup("Gain", ControlSpec.new(0, 1/5, LinearWarp), 1/7);
c[8].setup("Frequency", ControlSpec.new(220, 240, ExponentialWarp), 229);
c[9].setup("Gain", ControlSpec.new(0, 1/5, LinearWarp), 1/9);
{SinOsc.ar(In.kr([0, 8]), 0, In.kr([1, 9]))}.play
)

// A test instrument.

(
SynthDef.new("ping", {
	arg out = 0, freq = 440, pan = 0, gain = 1;
	Out.ar(out, Pan2.ar(
		SinOsc.ar(freq, 0,
			EnvGen.kr(envelope: (Env.perc), doneAction: 2)),
		pan, gain));}).send(s);
)

// Use <Ctl> values for scheduling nodes
// (pings).

(
c[0].setup("DelayTime", ControlSpec.new(0.05, 0.75, LinearWarp), 0.18);
c[1].setup("FreqScalar", ControlSpec.new(0.5, 2, LinearWarp), 1.75);
c[2].setup("PanLocation", ControlSpec.new(-1, 1, LinearWarp), 0);
c[3].setup("BasicGain", ControlSpec.new(0, 1, LinearWarp), 0.1);
c[4].setup("Scale", ControlSpec.new(0, 1, LinearWarp), 0.0, 3);
Routine.new({
	var d;
	d = [[0, 2, 4, 5, 7, 9, 11],
		[0, 2, 3, 5, 6, 8, 9, 11],
		[0, 2, 4, 6, 8, 10]];
	inf.do({
		arg n;
		var f;
		f = (d[c[4].state].choose + 48 + [-12,0,12].choose).midicps;
		[n,f].postln;
		s.sendMsg("/s_new", "ping", -1, 0, 0,
			"freq", f * c[1].value,
			"pan", c[2].value,
			"gain", c[3].value + 0.25.rand);
		c[0].value.yield;
		c[0].value.postln;
	});
}).play(SystemClock);
)

// Add a language level oscillator to the pan
// <Ctl>.  This runs at the same rate as the
// node instantiation routine, though it is
// not synchronized.  Note that the interface
// reflects changes at the <Ctl>.

Routine.new({inf.do({c[2].value = 2.0.rand - 1.0; c[0].value.yield;})}).play;

// Setup midi NoteOn messages to increment and
// decrement state as if Midi Controllers
// (ie. 7bit signal).

(
c[0].depth = 127;
MIDIIn.noteOn = {
	arg src, chan, num, vel;
	var step;
	if(num==60, {step = -1}, {step = 1});
	c[0].increment(step);
};
)

// A single sawtooth oscillator with NoteOn
// and NoteOff messages setting C values.

(
c[16].setup("Note", ControlSpec.new(0, 127, LinearWarp));
c[17].setup("Gain", ControlSpec.new(0, 0.1, LinearWarp));
MIDIIn.noteOn = {
	arg src, chan, num, vel;
	c[16].internal = num/127.0;
	c[17].internal = vel/127.0;
};
MIDIIn.noteOff = {
	arg src, chan, num, vel;
	c[17].internal = 0.0;
};
{LFSaw.ar(In.kr(16).midicps, 0, In.kr(17))}.play
)

// Find out where the audio input bus is.

s.options.dump;

// Two comb filters, one tuned using a delay
// time, the other a note input.

(
c[0].setup("DelayTime", ControlSpec.new(0.001, 0.18, LinearWarp));
c[1].setup("DecayTime", ControlSpec.new(0.01, 9.0, LinearWarp));
c[2].setup("Gain", ControlSpec.new(0, 1, LinearWarp));
c[3].setup("Note", ControlSpec.new(0, 127, LinearWarp));
c[4].setup("DecayTime", ControlSpec.new(0.01, 9.0, LinearWarp));
c[5].setup("Gain", ControlSpec.new(0, 1, LinearWarp));
{[
 CombC.ar(In.ar(8), 0.2, In.kr(0), In.kr(1), In.kr(2)),
  CombC.ar(In.ar(8), 0.2, 1.0 / (In.kr(3).floor.midicps), In.kr(4), In.kr(5))
];}.play;
)

// Make an interface with non default numbers
// of rows and columns and name each <ctl>
// according to index.

(
n = 36;
c = Controller.new(s, n);
c.makeInterface(6, 6);
n.do({
	arg i;
	c[i].setup("Ctl:" ++ i.asString);
});
)

// Dump information about a <Ctl>

c[0].dump;

// <Controller> implements the copySeries
// method, allowing expressions like.

c[10..13].collect(_.value).sum

// There is a snapshot mechanism that collects
// the current values.

~preset = c.snapshot(0,15);

// Scramble the values just stored...

c[0..15].do(_.internal = 1.0.rand);

// Restore values from snapshot.

c.restore(~preset);

// Non-default interfaces.  Make a trivial
// multi-slider to set <Ctl> values.

(
w = GUI.window.new("c.Sliders", Rect(200 , 200, 200, 200)).front;
s = GUI.multiSliderView.new(w, Rect(0, 0, 200, 200));
s.action = {arg e; c[e.index].value = e.currentvalue;};
)


// Demonstrates the effect of using checkSameRateAsFirstInput
s.boot;
x = {LPF.ar(WhiteNoise.kr) }.play(s); // Error
x = {LPF.ar(WhiteNoise.ar) }.play(s); // OK
x.free;
x = {LPF.kr(WhiteNoise.ar) }.play(s); // Error
x = {LPF.kr(WhiteNoise.kr) }.play(s); // OK
x.free;



///////////////////////////////////////////////////////////////
// Clock examples

SystemClock.sched(2, {"foo".postln; }); 

// "foo" repeats every second
SystemClock.sched(0, {"foo".postln; 1.0 }); 

// "bar" repeats at a random delay
SystemClock.sched(0, {"bar".postln; 1.0.rand }); 

// clear all scheduled events 
SystemClock.clear; 

// causes an "operation cannot be called from this Process" error
SystemClock.sched(1, { SCWindow.new.front });

// defer reschedules GUI code on the AppClock, so this works
SystemClock.sched(1, { { SCWindow.new.front }.defer });

//TempoClock
(
t = TempoClock.new; // make a new TempoClock
t.sched(0, {"Hello!".postln; 1});
)
t.tempo = 2; // twice as fast
t.clear;

// Routine
(
r = Routine({
"foo".yield;
"bar".yield;
});
)
r.value; // foo
r.value; // bar
r.value; // we've reached the end, so it returns nil

// Routine in a Clock
(
r = Routine({
	"foo".postln;
	1.yield; // reschedule after 1 second
	"bar".postln;
	1.yield;
	"foobar".postln;
});
SystemClock.sched(0, r);
) 

///////////////////////////////////////////////////////////////
// Figure 3.1 A simple routine illustrating a musical use of yield
// Fermata
s.boot;
(
r = Routine({	
	x = Synth(\default, [freq: 76.midicps]);
	1.wait;
	
	x.release(0.1);
	y = Synth(\default, [freq: 73.midicps]);
	"Waiting...".postln;
	nil.yield;// fermata
	
	y.release(0.1);
	z = Synth(\default, [freq: 69.midicps]);
	2.wait;
	z.release;
});
)
// do this then wait for the fermata
r.play;
// feel the sweet tonic... 
r.play; 







/////////////////////////////////////////////////////////////// 
// Figure 3.2 Using Task so you can pause the sequence
(
t = Task({	
	loop({	 // loop the whole thing
		3.do({	 // do this 3 times
			x.release(0.1);
			x = Synth(\default, [freq: 76.midicps]);
			0.5.wait;
			x.release(0.1);
			x = Synth(\default, [freq: 73.midicps]);
			0.5.wait;
		});
		"I'm waiting for you to press resume".postln;
		nil.yield;// fermata
		x.release(0.1);
		x = Synth(\default, [freq: 69.midicps]);
		1.wait;
		x.release;
	});
});

w = Window.new("Task Example", Rect(400, 400, 200, 30)).front;
w.view.decorator = FlowLayout(w.view.bounds);
Button.new(w, Rect(0, 0, 100, 20)).states_([["Play/Resume", Color.black, Color.clear]])
	.action_({ t.resume(0);});
Button.new(w, Rect(0, 0, 40, 20)).states_([["Pause", Color.black, Color.clear]])
	.action_({ t.pause;});
Button.new(w, Rect(0, 0, 40, 20)).states_([["Finish", Color.black, Color.clear]])
	.action_({ 
		t.stop; 
		x.release(0.1);
		w.close;
	});
)








///////////////////////////////////////////////////////////////
// Figure 3.3 Nesting tasks inside routines
(
r = Routine({	
	c = TempoClock.new; // make a TempoClock
	// start a 'wobbly' loop
	t = Task({	
		loop({	
			x.release(0.1);
			x = Synth(\default, [freq: 61.midicps, amp: 0.2]);
			0.2.wait;
			x.release(0.1);
			x = Synth(\default, [freq: 67.midicps, amp: 0.2]);
			rrand(0.075, 0.25).wait; // random wait from 0.1 to 0.25 seconds
		});
	}, c); // use the TempoClock to play this Task
	t.start;
	nil.yield;
	
	// now add some notes
	y = Synth(\default, [freq: 73.midicps, amp: 0.3]);
	nil.yield;
	y.release(0.1);
	y = Synth(\default, [freq: 79.midicps, amp: 0.3]);
	c.tempo = 2; // double time
	nil.yield;
	t.stop; y.release(1); x.release(0.1); // stop the Task and Synths
});
)

r.next; // start loop
r.next; // first note
r.next; // second note; loop goes 'double time'
r.next; // stop loop and fade








///////////////////////////////////////////////////////////////
// Figure 3.4 Using patterns within a task

(// random notes from lydian b7 scale
p = Pxrand([64, 66, 68, 70, 71, 73, 74, 76], inf).asStream; 
// ordered sequence of durations
q = Pseq([1, 2, 0.5], inf).asStream; 
t = Task({	
	loop({	
		x.release(2);
		x = Synth(\default, [freq: p.value.midicps]);
		q.value.wait;
	});
});
t.start;
)
t.stop; x.release(2);






///////////////////////////////////////////////////////////////
// Figure 3.5 Thanks to polymorphism we can substitute objects that understand the same message
(
p = 64; // a constant note
q = Pseq([1, 2, 0.5], inf).asStream; // ordered sequence of durations
t = Task({	
	loop({	
		x.release(2);
		x = Synth(\default, [freq: p.value.midicps]);
		q.value.wait;
	});
});
t.start;
)
// now change p
p = Pseq([64, 66, 68], inf).asStream; // to a Pattern: do re mi
p = { rrand(64, 76) }; // to a Function: random notes from a chromatic octave
t.stop; x.release(2);






///////////////////////////////////////////////////////////////
// Figure 3.6 Using 'messaging style': Score

(
SynthDef("ScoreSine",{ arg freq = 440;
Out.ar(0,
	SinOsc.ar(freq, 0, 0.2) * Line.kr(1, 0, 0.5, doneAction: 2)
)
}).add;
x = [
// args for s_new are synthdef, nodeID, addAction, targetID, synth args ...
[0.0, [ \s_new, \ScoreSine, 1000, 0, 0,  \freq, 1413 ]],
[0.5, [ \s_new, \ScoreSine, 1001, 0, 0,  \freq, 712 ]],
[1.0, [ \s_new, \ScoreSine, 1002, 0, 0,  \freq, 417 ]],
[2.0, [\c_set, 0, 0]] // dummy command to mark end of NRT synthesis time
];
z = Score(x);
)
z.play;





///////////////////////////////////////////////////////////////
// Figure 3.7 Executing one line at a time

(
// here's a synthdef that allows us to play from a buffer, with a fadeout
SynthDef("playbuf", { arg out = 0, buf, gate = 1;
	Out.ar(out,
		PlayBuf.ar(1, buf, BufRateScale.kr(buf), loop: 1.0) 
			* Linen.kr(gate, doneAction: 2); // release synth when fade done
	)
}).add;
// load all the paths in the sounds/ folder into buffers
~someSounds = "sounds/*".pathMatch.collect{ |path |  Buffer.read(s, path)}; 
)
// now here's the score, so to speak
// execute these one line at a time
~nowPlaying = Synth("playbuf", [buf: ~someSounds[0]]);
~nowPlaying.release; ~nowPlaying = Synth("playbuf", [buf: ~someSounds[1]]);
~nowPlaying.release; ~nowPlaying = Synth("playbuf", [buf: ~someSounds[2]]);
~nowPlaying.release;
// free the buffer memory
~someSoundsBuffered.do(_.free);
 
 
 
 
 
 
 
///////////////////////////////////////////////////////////////
// Figure 3.8 Play cues with a simple GUI

(
SynthDef("playbuf", { arg out = 0, buf, gate = 1;
	Out.ar(out,
		PlayBuf.ar(1, buf, BufRateScale.kr(buf), loop: 1.0) 
		* Linen.kr(gate, doneAction: 2) * 0.6; 
		// with 'doneAction: 2' we release synth when fade is done	
) }).add;
~someSounds = "sounds/*".pathMatch.collect{ |path |  Buffer.read(s, path)}; 
n = 0; // a counter
// here's our GUI code
w = Window.new("Simple CuePlayer", Rect(400, 400, 200, 30)).front;
w.view.decorator = FlowLayout(w.view.bounds);
//this will play each cue in turn
Button.new(w, Rect(0, 0, 80, 20)).states_([["Play Cue", Color.black, Color.clear]]).action_({ 
	if(n < ~someSounds.size, {
		if(n != 0, {~nowPlaying.release;}); 
		~nowPlaying = Synth("playbuf", [buf: ~someSounds[n]]); n=n+1;
	});
}); 
//this sets the counter to the first cue
Button.new(w, Rect(0, 0, 80, 20)).states_([["Stop / Reset", Color.black, Color.clear]]).action_({ n=0; ~nowPlaying.release; }); 
// free the buffers when the window is closed
w.onClose = { ~someSounds.do(_.free); };
)










///////////////////////////////////////////////////////////////
// Figure 3.9 Gathering up files for multichannel cues 

// gather all your folder paths
//this will path match each folder in the collection, i.e. we will have a collection of collections of paths

~groupOfindivCueFolders = "sounds/*".pathMatch.collect{ | item |  (item.asSymbol++"*").pathMatch };

Post << ~groupOfindivCueFolders;  //see them all !

//check how many cues you will have in the end
~groupOfindivCueFolders.size; 

//automate the buffering process for all cues:
~bufferedCues = ~groupOfindivCueFolders.collect{|item, i| item.collect{| path |  Buffer.read(s,  path)}}; //now all our cue files are sitting in their buffers ! 

~bufferedCues[0];  //here is cue 1

// see it in the post window:
Post << ~bufferedCues[0];

// play them all in a Group, using our previous synthdef
// we use bind here to ensure they start simultaneously
(
s.bind({	
	~nowPlaying = Group.new(s); // a group to put all the channel synths in
	~bufferedCues[0].do({|cue| Synth("playbuf", [buf: cue], ~nowPlaying)})
});
)
// fade them out together by sending a release message to the group
~nowPlaying.release;








///////////////////////////////////////////////////////////////
// Figure 3.10 Recording the results of making sounds with supercollider

s.boot; // make sure the server is running
(  	// first evaluate this section
b = Buffer.read(s, "sounds/a11wlk01.wav"); // a source
s.prepareForRecord; // prepare the server to record (you must do this first)
)
(	// simultaneously start the processing and recording
s.bind({
	// here's our funky effect
	x = { var columbia, amp; 
		columbia = PlayBuf.ar(1, b, loop: 1);
		amp = Amplitude.ar(columbia, 0.5, 0.5, 4000, 250); // 'sticky' amp follower
		Out.ar(0, Resonz.ar(columbia, amp, 0.02, 3)) // filter; freq follows amp
		}.play;
s.record;
});
)
s.pauseRecording; // pause
s.record // start again
s.stopRecording; // stop recording and close the resulting sound file









///////////////////////////////////////////////////////////////

// Thinking in the Abstract examples
(
{
Resonz.ar(Dust2.ar(5), 300, 0.001, 100)  +
Resonz.ar(Dust2.ar(5), 600, 0.001, 100)  +
Resonz.ar(Dust2.ar(5), 900, 0.001, 100) * 3.reciprocal; // scale to ensure no clipping
}.play
)

(
f = 300;
n = 3;
{
Mix.fill(n, {|i| Resonz.ar(Dust2.ar(5), f * (i + 1), 0.001, 100)})
* n.reciprocal; // scale to ensure no clipping
}.play
)

(
f = 40;
n = 50;
{
Mix.fill(n, {|i| Resonz.ar(Dust2.ar(5), f * (i + 1), 0.001, 300)})
* n.reciprocal; // scale to ensure no clipping
}.play
)






///////////////////////////////////////////////////////////////
// Figure 3.12 A variable number of resonators with an automatically created GUI       
(
f = 300;
n = 30; // number of resonators
t = Array.fill(n, { |i|
{
Resonz.ar(Dust2.ar(5), f * (i + 1), 0.001, 300)
* n.reciprocal; // scale to ensure no clipping
}.play;
});

// now make a GUI
// a scrolling window so we don't run out of space
w = Window.new("Buttons", Rect(50, 100, 290, 250), scroll:true);
w.view.decorator = FlowLayout.new(w.view.bounds); // auto layout the widgets
n.do({|i|
Button.new(w, Rect(0, 0, 130, 30)).states_([
["Freq" + (f * (i + 1)) + "On", Color.black, Color.white],
["Freq" + (f * (i + 1)) + "Off", Color.white, Color.black]
])
.action_({ arg butt;
t[i].run(butt.value == 0);
});
});
w.front;
)
  



///////////////////////////////////////////////////////////////
// Empty Gestures

( //you will be able to add multiple soundfiles, just shift click when selecting !
var file, soundPath;
~buffers = List[];
Dialog.getPaths({ arg paths;
paths.do({|soundPath|
//post the path to verify that is the one you expect!
    soundPath.postln; 
//adds the recently selected buffer to your list 
    ~buffers.add(Buffer.read(s, soundPath);); })
});
)

~buffers.size;
~buffers[0];
~buffers[0].play;


(
// buffer player with done action and control of envelope and panning
SynthDef(\samplePlayer, { arg out=0, buf = 0,
rate = 1, at =0.01, rel= 0.1, pos =0, pSpeed = 0, lev = 0.5;
var sample, panT,  amp, aux;
sample = PlayBuf.ar(1, buf, rate*BufRateScale.kr(buf), 1, 0, 0);
panT= FSinOsc.kr(pSpeed);
amp = EnvGen.ar(Env.perc(at, rel, lev), doneAction: 2);
Out.ar(out, Pan2.ar(sample, panT, amp));
}).memStore;
)

Synth(\samplePlayer,[\out, 0, \bufnum, ~buffers[0], \rel, 0.25]);
Synth(\samplePlayer,[\out, 0, \bufnum, ~buffers[~buffers.size.rand], \rel, 0.25]); 






///////////////////////////////////////////////////////////////
// Figure 3.13 Making a stuttering gesture using a geometric pattern

(/* a routine for creating a ritardando stutter with panning, you must have
run the code in fig 3.9 so that this routine may find some sounds already loaded into buffers, you can change the index of ~bufferedCues to test the routine on different sounds */


~stut = Routine( { var dur, pos;
~stutPatt = Pseq([Pgeom(0.01, 1.1707, 18), Pn(0.1, 1),Pgeom(0.1, 0.94, 200) ]);
~str= ~stutPatt.asStream;
100.do{
    dur =  ~str.next;
    dur.postln; 	//so we can check values on the post window
    ~sample = Synth("samplePlayer",[\out, 0, \buf,  ~bufferedCues[0], \at, 0.1, \rel, 0.05,\pSpeed, 0.5]);
    dur.wait;
}
});
)

//now play it
~stut.play;
// reset before you play again!
~stut.reset; 
 


///////////////////////////////////////////////////////////////
// More Empty Gestures

// randomly selected frequency, duration 0.1 seconds
Pbind(\freq, Prand([300, 500, 231.2, 399.2], 30), \dur, 0.1).play;

~gest1 = Pbind(\instrument, \samplePlayer, \dur, 2, \rel, 1.9);
~player = ~gest1.play; //make it play
~player.stream = Pbind(\instrument, \samplePlayer, \dur, 1/8, \rate, Pxrand([1/2,1,2/3,4],inf), \rel, 0.9).asStream; //substitute the stream
~player.stop;


~gest1 = Pbind(\instrument, \samplePlayer, \dur, Pgeom(0.01, 1.1707, 20), \rel, 1.9);
~gest1.play;

Pbind(\instrument, \samplePlayer, \dur, Pseq([Pgeom(0.01, 1.1707, 20), Pgeom(0.01, 0.93, 20)], 1), \rel, 1.9, \pSpeed, 0.5).play;

Pbind(\instrument, \samplePlayer, \dur, Pseq([Pgeom(0.01, 1.1707, 20), Pgeom(0.01, 0.93, 20)], 1),\rate, Pxrand([1/2,1,2/3,4],inf), \rel, 1.9, \pSpeed, 0.5).play;

~rhythm1 = Pseq([1/4, 1/4, 1/8, 1/12, 1/24, nil]); //the nil is so it will stop !

~gest1 = Pdef(\a, Pbind(\instrument, \samplePlayer, \dur, ~rhythm1, \rel, 1.9, \pSpeed, 0.5) );
~gest1.play;

~rhythm1 = Pseq([1/64,1/64,1/64, 1/32, 1/32, 1/32, 1/32, 1/24, 1/16, 1/12, nil]);
~gest1 = Pdef(\a, Pbind(\instrument, \samplePlayer, \dur, ~rhythm1, \rel, 1.9, \pSpeed, 0.5) );

~gest1 = Pdef( \a , Pbind(\instrument, \samplePlayer, \att, 0.5, \rel, 3, \lev, {rrand(0.1,0.2)}, \dur, 0.05, \rate, Pseq([ Pbrown(0.8, 1.01, 0.01, 20) ]) ) );




/*
 * Part of the SuperCollider Book
 * Author of code: Till Bovermann
 * for more information, see http://tuio.lfsaw.de/seto.shtml
 */

/* 
	Basic example for controlling sound rendering with SETO 
	We use Objects of "_ixya" style.
*/

SynthDef(\testTUIO, {|freq = 400, out = 0, amp = 0, vol = 0.25, famp=1|
	Out.ar([out, out+1], SinOsc.ar(freq, 0, (amp.lag(0.01)*vol*famp)))
}).send(s);

q = ();
(
q.synths = IdentityDictionary.new; // a storage for synths

JITseto.action = {|me|
	s.bind{
		// make sure there is a synth
		q.synths[me].isNil.if{
			q.synths[me] = Synth(\testTUIO, [\vol, 0.2, \amp, 0])
		};
		s.sync;
		me.visible.if({
			q.synths[me].set(
				\freq, me.rotEuler[0].wrap(0, 2pi).linexp(0, 2pi, 400, 800),
				\amp, 1
			)
		}, {
			q.synths[me].set(
				\amp, 0
			)
		})
	}
}
)

// instantiate SETOServer
t = SETO_OSCServer('_ixya', setoClass: JITseto);
t.gui;
t.start;
t.stop;

/*
 * Part of the SuperCollider Book
 * Author of code: Till Bovermann
 * for more information, see http://tuio.lfsaw.de/seto.shtml
 */

/* 
	Basic example for controlling sound rendering with TUIO 
	Given a fixed set of Objects, each having i,x,y,a and the object ids are 0..numObj-1.
*/

SynthDef(\testTUIO, {|freq = 400, out = 0, amp = 0, vol = 0.25|
	Out.ar(out, SinOsc.ar(freq, 0, amp*vol)!2)
}).send(s);

(
var synths, numObj = 4, resp;

// Create a Synth for each object. make sure it will not play.
synths = Array.fill(numObj, {
	Synth(\testTUIO, [\vol, numObj.reciprocal, \amp, 0])
});

// set up OSC responder
resp = OSCresponder(nil, "/tuio/_ixya", {|time, resp, msg|
	var id, classID, x, y, a, pos, amps;
	
	// if object state is updated, change frequency of corresponding synth 
	(msg[1] == \set).if{
		# id, classID, x, y, a = msg[2..6];
		synths[id].set(
			\freq, a.wrap(0, 2pi).linexp(0, 2pi, 400, 800)
		)
	};
	
	// only play synths for alive (i.e. visible) objects
	(msg[1] == \alive).if{
		amps = Array.fill(numObj, 0);
		msg[2..].do{|i|
			amps[i] = 1;
		};
		synths.do{|synth, i|
			synth.set(\amp, amps[i])
		}
	};
}).add;
)

(
w = Window.new( "Key Example", Rect( 0,0, 150,150 ));
c = UserView( w, Rect( 0, 0, 150, 150 )).background_( Color.white );
c.keyDownAction = { arg view,char,modifiers,unicode,keycode;
	[ char, modifiers, unicode, keycode ].postln;
};
w.front;
)


(
    w = Window( "Mouse Actions", Rect( 200, 400, 350, 180 ), resizable: false );
    a = StaticText( w, Rect( 10, 10, 160, 160 ))
        .string_( "Mouse Pad" )
        .stringColor_( Color.white )
        .align_( \center )
        .background_( Color.blue );
    b = Slider2D( w, Rect( 180, 10, 160, 160 ))
        .canFocus_( false );
    f = { arg view, x, y, modif; var bounds = view.bounds;
		b.setXY( x / bounds.width, 1.0 - (y / bounds.height) );
    };
    a.mouseMoveAction = f;
    a.mouseDownAction = { arg ... args; b.knobColor = Color.red; f.value( *args )};
    a.mouseUpAction = { arg ... args; b.knobColor = Color.clear; f.value( *args )};
    w.front;
)

a.mouseOverAction = f;
w.acceptsMouseOver = true;  // otherwise mouseOverAction won't be called
        
// Mouse events are only fired if the component is enabled.

a.enabled = false;
a.enabled = true;


Ins and Outs - MIDI

MidiIn

// connects one input, to the first available output from a device or program
MIDIIn.connect;
MIDIIn.connect(0,3);
// assigns a function to incoming noteOn messages
MIDIIn.noteOn = { |port, chan, note, vel|	[port, chan, note, vel].postln};

// first unassign the noteOn method:
MIDIIn.noteOn = nil;
// create a NoteOnResponder and assign it to the variable n
n = NoteOnResponder( { |src, chan, num, vel|	[src, chan, num, vel].postln},nil,nil,(0..127), (0..127) );

// create a NoteOnResponder and assign it to the variable m
m = NoteOnResponder( { |src, chan, num, vel| "responder m ".post;[src, chan, num, vel].postln},nil,nil,[64], (0..127) );

// remove the NoteOnResponder n:
n.remove;

// Hit note 64 again, and you'll get only one post.

// remove the NoteOnResponder m:
m.remove;

// Now you've removed all the responders.

NoteOnResponder.removeAll;

// now a Sound example:

s.boot;
// create a NoteOnResponder that makes a sound:
m = NoteOnResponder( { |src, chan, num, vel| 
	var x = Synth.new(\default,[\freq, num.midicps,\out,0,\amp,0.2,\gate,1,\dur,1,\pan,0]);
	Task({ 1.0.wait; x.free }).play;
},nil,nil,(0..127), (0..127) );


m.remove;


Ins and Outs - MIDI

// initialize the MIDI client:
MIDIClient.init;

// create a MIDI out connection:
m = MIDIOut(0, MIDIClient.destinations.at(0).uid);

// On linux, you may just want to use:
m = MIDIOut(0);
// and connect SC's first port to your device's port with for example QJackCtl, or use:
m.connect(1);
// to connect to the second port

// a task which will play a little melody:
(
t = Task( {
	[60, 64, 61, 60, 65, 61].do{ |it|
		m.noteOn(16, it, 60);
		1.0.wait;
		m.noteOff(16, it, 60);
	};
	[64, 65, 67].dup(4).flatten.do{ |it|
		m.noteOn(16, it, 120);
		0.25.wait;
		m.noteOff(16, it, 120);
	};
	[61, 65, 60, 61, 64, 60].do{ |it|
		m.noteOn(16, it, 60);
		1.0.wait;
		m.noteOff(16, it, 60);
	};
	m.noteOn(16, 60, 40); m.noteOn(16, 52, 40);
	2.0.wait;
	m.noteOff(16, 60, 40); m.noteOff(16, 52, 40);
	m.noteOn(16, 57, 40); m.noteOn(16, 52, 40);
	2.0.wait;
	m.noteOff(16, 57, 40); m.noteOff(16, 52, 40);
	m.noteOn(16, 53, 40);
	2.0.wait;
	m.noteOff(16, 53, 40);
	m.noteOn(16, 52, 40);
	4.0.wait;
	m.noteOff(16, 52, 40);
});
);

// play the task:
t.play;

// stop it:
t.stop;

// free any hung notes if necessary:
m.allNotesOff(16);



// using a pattern to send a MIDI event:
a = Pbind(\degree, Prand([1, 2, 3, [0, 5]], inf), \bend, Pwhite(0, 76, inf));
// chain a midi event into the pattern and play it (see Pchain)
(a <> (type: \midi, midiout: m)).play;

// stop the pattern with Cmd-. , Alt-., C-c C-s, F12 or ESC

// free any hung notes if necessary:
m.allNotesOff(16);


// Figure 4.1
//
// Create two OSC responders for the same command
~r1 = OSCresponderNode(
	~host, "/testMsg",
	{ | time, responder, message, address |
		fork {
			(time - thisThread.seconds).wait;
			[\responder1, time, message, address].postln;
		};
	}
).add;
~r2 = OSCresponderNode(
	~host, "/testMsg",
	{ | time, responder, message, address |
		fork {
			(time - thisThread.seconds).wait;
			[\responder2, time, message, address].postln;
		};
	}
).add;


// Create a network address representing sclang itself
~host = NetAddr("localhost", NetAddr.langPort);

// Send an OSC message
~host.sendMsg("/testMsg", "OSCresponderNode test");

// Send an OSC message
~host.sendMsg( "/testMsg", 42, "string", pi);

// Send an OSC bundle and execute its contents
// 200 ms from 'now'
~host.sendBundle(0.2,
	["/testMsg", 42, "string", pi],
	["/testMsg", 183]);


// Remove responders
~r1.remove;
~r2.remove;



// serialport setup
SerialPort.devicePattern = "/dev/tty.usbserial*"; // osx usb serial
SerialPort.devices;	// look if the device is there
(
~serial = SerialPort(
	SerialPort.devices.first,
	baudrate: 115200,
	crtscts: true
);
)


// minimal example
~serial.putAll("A120"); // red component
~serial.putAll("B255"); // green component
~serial.putAll("C100"); // blue component

// function example with values between 0..1
a = {|char, val, serial|
  serial.putAll(char ++ ((val*255).asInt + 1000).asString[1..3]);
}

// test it
a.("A", 0.1, ~serial)

// complete example
a = {|which, color, serial|
  // create an empty message
  var msg = "";

  // is there a color defined in the arguments?
  color = color ? Color.black;

  // convert color into an array
  color = color.asArray;

  // convert number of used orb into its corresponding ASCII character (determining colors)
  // convert light value [0..1] into a value between ["000" .. "255"]
  // collect al values in the message
  (65 + #[0, 1, 2] + (which * 3)).collect{|val, i|
    val.asAscii ++ ((color[i]*255).asInt + 1000).asString[1..3]
  }.do{|elem|
    msg = msg ++ elem;
  };

  // send it to the serial port
  serial.putAll(msg);
}

// Ins and Outs - Gamepad example
// This example was made with an Impact Gamepad, but can easily be adapted to work with gamepads of other vendors.


// General structure to access a device
// Look for the devices that are attached:
GeneralHID.buildDeviceList;
// Get the list of devices:
d = GeneralHID.deviceList;
// Check which devices have been found:
GeneralHID.postDevices;

// The impact has vendor number 1973, so look for it:
a = GeneralHID.findBy( 1973 );
// If you have a different gamepad, just look in the list that is posted. The first entry in the arrays that are posted is the index into the list, so if your device shows up as [ 5, device description ], you can do:
a = d[5];


// Pick the right device and open it and create an instance of it:
a = GeneralHID.open( a );
// Get info on the device (double check whether you have the right one):
a.info;
// if you did not know the vendorID and product yet, you can use
a.info.findArgs;
// to find out which args we could use to automatically find the gamepad in future sessions:


// Start eventloop:
GeneralHID.startEventLoop
// Get the capabilities of the device in a readable format:
a.caps;
// See if data is coming in:
a.debug_( true );
// Stop it:
a.debug_( false );

// find the joysticks

// on OSX:
a.slots[3][48].debug_(true); // right x
a.slots[3][48].debug_(false); // right x

a.slots[3][49].debug_(true); // right y
a.slots[3][49].debug_(false); // right y

a.slots[3][50].debug_(true); // left y
a.slots[3][50].debug_(false); // left y

a.slots[3][53].debug_(true); // left x
a.slots[3][53].debug_(false); // left x

// on linux:
a.slots[3][0].debug_(true); // left x
a.slots[3][0].debug_(false); // left x

a.slots[3][1].debug_(true); // left y
a.slots[3][1].debug_(false); // left y

a.slots[3][2].debug_(true); // right x
a.slots[3][2].debug_(false); // right x

a.slots[3][5].debug_(true); // right y
a.slots[3][5].debug_(false); // right y

/// We could also use a GUI:
a.makeGui;

// Note the Impact Gamepad has a button in the middle (above the LED), which changes the function of the arrow button on the left from being an alternative to the left joystick axes, or its own two axes.

// Now that we know which slot is which, we can name them:

( // using the OSX mapping
a.add( \lx, [3,48]);
a.add( \ly, [3,49]);
a.add( \rx, [3,50]);
a.add( \ry, [3,53]);
// buttons
(1..8).do{ |it,i| a.add( (i+1).asSymbol, [1,it]) }
)

( // using the linux mapping
a.add( \lx, [3,0]);
a.add( \ly, [3,1]);
a.add( \rx, [3,2]);
a.add( \ry, [3,5]);
a.add( \hatx, [3,16] );
a.add( \haty, [3,17] );
// buttons
(288..299).do{ |it,i| a.add( (i+1).asSymbol, [1,it]) }
)



// view the spec:
a.spec.map

// save the spec:
a.spec.save( "GamepadExample");

// now we can find it:
b = a.findSpec;

// so in future session we can reload it with:
a.setSpec( b[0] );

// Now that we have given the slots symbolic names, there is no difference anymore for using the HID device between OSX and Linux.

// The impact gamepad has two joysticks and a whole lot of buttons.
// In this example we will create a setup, where we can record movements of the joysticks, which are then used as wavetable for a synthesizer.

// on OSX, use the internal server:
s = Server.internal.boot;
// otherwise, use the local server (and SwingOSC)
s = Server.local.boot;

// GUI's
s.makeGui;
s.scope( 2 );

(
// synth to write the waveform to a buffer:
SynthDef( \wavewriteb2, { |input=0,buffer=0,dur=5,speed=1,offset=0.5,mul=1,gate=0|
	EnvGen.kr( Env.sine, gate, timeScale: dur ) *
	BufWr.kr( In.kr( input, 1 ) * mul - offset, buffer, Phasor.kr( gate, speed, 0, BufFrames.kr(buffer)), 0 );
}).send(s);
// synth to play back the waveform:
SynthDef( \waveplayb, { |buffer=0, speed=0.5, out=0, amp=1, vol = 0.5|
	Out.ar( out,
		vol * amp * BufRd.ar( 1, buffer, LFSaw.ar(BufDur.ir(buffer).reciprocal * speed * 2).range(0, BufFrames.ir(buffer)) )
		);
	}).add;
)

(
// create busses for each of the joystick axes:
[\rx,\ry,\ly,\lx].do{ |key| a.at( key ).createBus( s ); };
// create busses for eight of the buttons:
(1..8).do{ |id| a.at( id.asSymbol ).createBus( s ); };
)

(
// assign 4 Buffers for four wavetables:
~buffers = 4.collect{ Buffer.alloc( s, 4096, 1 ); };
)

( // create a window to view the buffer contents:
w = Window.new( "Gamepad Buffer play" );
~bufwins = 4.collect{ |i| CompositeView.new( w, Rect( 0, 100*i, w.bounds.width, 100 ) ) };
w.front;

Tdef( \updateplot, {
	loop {
		~bufwins.do{ |it| it.children.do{ |jt| jt.remove; } };
		~buffers.do{ |it,i| it.plot( "buffer "++i, parent: ~bufwins[i] ) };
		1.0.wait;
		}
	});
)


( // start the synths and window update routine:
Tdef( \updateplot ).play;
~writers = [ \lx, \ly, \lx, \ly ].collect{ |it,i|
	Synth.new( \wavewriteb2, [ \input, a.at(it).bus, \buffer, ~buffers[i], \offset, 1, \mul, 2 ], s ).busMap( \speed, a.at( (i+1).asSymbol).bus ).busMap( \gate, a.at( (i+1).asSymbol).bus );
	};
~players = [\rx, \rx, \ry, \ry ].collect{ |it,i|
	Synth.new( \waveplayb, [ \buffer, ~buffers[i], \out, (i/2).floor ], s).busMap( \amp, a.at( (i+5).asSymbol).bus ).busMap( \speed, a[it].bus );
	};
)


// Buttons 1 to 4 select to which buffer is recorded
// Buttons 5 to 8 (on the front), select which buffer is played back
// Left joystick determines recording
// Right joystick determines playback speed

// change volume:
~players.do{ |it| it.set( \vol, 0.5 ) };


// clean up:

(
~writers.do{ |it| it.free };
~players.do{ |it| it.free };

~buffers.do{ |it| it.free };

Tdef( \updateplot ).stop;

// free all the busses for each of the joystick axes:
a.freeAllBuses;

// Close the device after use:
a.close;
// stop the eventloop;
GeneralHID.stopEventLoop

)

// =========================================
// Wacom tablet example
// =========================================

// Note: this example only works on Linux. The OSX Wacom drivers unfortunately do not give you access to the HID layer of the Wacom device. Look at the osx example for how to do the same thing with the GUI utilities.)

// find the Wacom tablet:
GeneralHID.buildDeviceList;
d = GeneralHID.deviceList;
GeneralHID.postDevices;
// suppose this is the tablet, so open it (mine is a Wacom PenPartner2, so I look for that name in the device list. The first entry in the array that is posted on each line is the index into the deviceList)
w = GeneralHID.open( d[6] );
// check whether it was the right one:
w.info;
// get which args we could use to automatically find the tablet in future sessions:
w.info.findArgs;
// usually the first two are sufficient to get the device (the others are version numbers, or are related to which USB port the device is connected to)
// So in future sessions we can open the device with:
w = GeneralHID.open( GeneralHID.findBy( 1386, 100 ) );

// grab it, so we don't fuck up our mouse (linux only):
w.grab;
// create a GUI, so we can see whether it works:
GeneralHIDDeviceGUI.new( w );
// or:
w.makeGui;

// we can also use:
w.debug = true;
w.debug = false;

// my PenPartner2 seems to have several things which are defined, but do not seem to do anything. Probably the manufacturer uses the same firmware for several devices, but doesn't hook up the same hardware functions to all of them.

// create names for different functions (look at the gui to see which action causes which buttons or sliders to move)
(
w.add( \x, [3,0]);
w.add( \y, [3,1]);
w.add( \pressure, [3,24]);
w.add( \topbutton, [1,331]);
w.add( \botbutton, [1,332]);
w.add( \inrange, [1,320]);
w.add( \touch, [1,330] );
);

// view the spec:
w.spec.map

// save the spec:
w.spec.save( "WacomExample");

// now we can find it:
w.findSpec;

// so in future session we can reload it with:
w.setSpec( w.findSpec.first );
w.spec.map

s = Server.local.boot;

// we use q as our holder for synths
q = ();

// create buses for the defined slots:
(
w.createAllBuses( s );
)

// create actions for two of the "buttons"
(
q.active = false;
// when the pen hits the tablet, spawn a synth and map the buses:
w[\touch].action_( { |v| 
	if ( v.value == 1 and: q.active.not, {
		q.active = true;
		q.synthi = Synth.new( \wacotheremin ); 
		q.synthi.map( \freq, w[\y].bus );
		q.synthi.map( \mod, w[\x].bus );
		q.synthi.map( \amp, w[\pressure].bus );
		q.synthi.map( \room, w[\x].bus );
		q.synthi.map( \damp, w[\y].bus );
		q.synthi.map( \roomset, w[\topbutton].bus );
		q.synthi.map( \dampset, w[\botbutton].bus );

	});
});
// when the pen leaves the sensitive range, free the synth:
w[\inrange].action_( { |v| 
	if ( v.value == 0 and: q.active, {
		q.synthi.free;
		q.active = false;
	});
});
)

/// and here's the synth:

( // freely derived from the Theremin example:
SynthDef(\wacotheremin, { arg freq=0, amp=1, mod = 7, detune = 0, roomset=0, dampset=0, room=0.5, damp=0.2;
	var f, a, z;
	f = [4000, 200, 'exponential'].asSpec.map( freq.lag(0.1) )*0.8 + detune;
	a = SinOsc.ar(f + (f * SinOsc.ar( [2,20].asSpec.map(mod.lag(0.1)),0,0.02)), mul: amp.lag(0.1));
	z = FreeVerb.ar( Mix.ar(a), 0.5, Gate.kr( room.lag(0.1), roomset ), Gate.kr( damp.lag(0.1), dampset ) );
	Out.ar(0, z) + Out.ar(1, z)
}).add;
)

// the frequency and modulation are modulated with x and y, the pressure controls the amplitude
// the room and damp of the reverb are only changed when the buttons are pushed.


// cleanup

w.freeAllBuses;
w.close;


// =========================================
// Wacom tablet example
// =========================================

(
// Unfortunately, OS X does allow to use a graphics-tablet with HID.
// So, here you find the HID example adapted to use a tablet-enabled GUI element (TabletSlider2D)

// The frequency and modulation are modulated with x and y, the pressure controls the amplitude.
// The room and damp of the reverb are only changed when pen is tilted to a positive amount towards  x resp. y-axises. You may want to adapt this behavior according to your specific tablet.

w = Window.new;
t = TabletSlider2D(w,Rect(40,40,300,300));
t.background = Color.white;
w.front;

// we use q as our holder for synths
q = ();
q.active = false;

t.mouseDownAction = { arg view,x,y,pressure,tiltx,tilty,deviceID, buttonNumber,clickCount,absoluteZ,rotation;
	if ( q.active.not, {
		q.active = true;
		q.synthi = Synth.new( \wacotheremin ); 

	});
	view.action.value(view,x,y,pressure,tiltx,tilty,deviceID, buttonNumber,clickCount,absoluteZ,rotation)
};

t.action = { arg view,x,y,pressure,tiltx,tilty,deviceID, buttonNumber,clickCount,absoluteZ,rotation;
	q.synthi.set( \freq, y);
	q.synthi.set( \mod, x );
	q.synthi.set( \amp, pressure );
	q.synthi.set( \room, x );
	q.synthi.set( \damp, y );
	q.synthi.set( \roomset, (tiltx > 0.1).binaryValue );
	q.synthi.set( \dampset, (tilty > 0.1).binaryValue );
};

t.mouseUpAction = { arg view,x,y,pressure,tiltx,tilty,deviceID, buttonNumber,clickCount,absoluteZ,rotation;
	if (q.active, {
		q.synthi.free;
		q.active = false;
	});
};
)


/// and here's the synth:

( // freely derived from the Theremin example:
SynthDef(\wacotheremin, { arg freq=0, amp=1, mod = 7, detune = 0, roomset=0, dampset=0, room=0.5, damp=0.2;
	var f, a, z;
	f = [4000, 200, 'exponential'].asSpec.map( freq.lag(0.1) )*0.8 + detune;
	a = SinOsc.ar(f + (f * SinOsc.ar( [2,20].asSpec.map(mod.lag(0.1)),0,0.02)), mul: amp.lag(0.1));
	z = FreeVerb.ar( Mix.ar(a), 0.5, Gate.kr( room.lag(0.1), roomset ), Gate.kr( damp.lag(0.1), dampset ) );
	Out.ar(0, z) + Out.ar(1, z)
}).add;
)


  //Figure 5.1
1					// the Integer number 1 
1.234 				// the floating-point (Float) number 1.234
$a 					// the character (Char) a
"hello"				// a String (an array of characters) 
\alpha				// a Symbol (a unique identifier) 
'alpha 1'				// another notation for a Symbol
100@150 				// a Point defined by coordinates x, y 
[1, \A, $b] 				// an Array containing 3 elements
(a: 1, b: 0.2) 			// an Event 
{ 10.rand }				// a Function
String 				// the Class String 
Meta_String 			// the Class of Class String



//Figure 5.3
// Boot the default server first:
Server.default.boot;
// Then select all lines between the outermost parentheses and run: 
( 	
{
	Resonz.ar(GrayNoise.ar,
		XLine.kr(100, 1000, 10, doneAction: 2), 
		XLine.kr(0.5, 0.01, [4, 7], doneAction: 0)
	)
}.play
)
// further examples:
{ WhiteNoise.ar(EnvGen.kr(Env.perc, timeScale: 3, doneAction: 2)) }.play;
{ WhiteNoise.ar(EnvGen.kr(Env.perc, timeScale: 0.3, doneAction: 2))}.play;



 //Figure 5.4
((1 + 2).asString).interpret 		// = 3
"1" ++ "2". interpret			// 12: 2 is translated to string by ++
("1" ++ "2").interpret			// 12
(1.asString ++ 2.asString).interpret 	// 12
"1+2". interpret 				// 3
(1.asString ++ "+2"). interpret		// 3
(1 + 2).interpret				// error: interpret not understood by Integer 3





 //Figure 5.5
(
a = 5;
5 do: { a = a + 10; a.postln };
Post << "The value of variable 'a' is now " << a << "\n";
)

//Figure 5.8
(
// A window with a button that posts: "hello there!"
var window, button;
// create a GUI window and store it in variable window
window = Window.new("OLA!", Rect(200, 200, 120, 120)); 
// create a button in the window and store it in variable button
button = Button.new(window, Rect(10, 10, 100, 100));
button.states = [["'ALLO"]];	// set one single label for the button
button.action = { "hello there!".postln }; // set the action of the button
window.front;		  	  // show the window
)
 
//Figure 5.9

( 
// execute this first to boot the server and load the synth definition
Server.default.waitForBoot({ 
	SynthDef("ping", { | freq = 440 |
		Out.ar(0, 
			SinOsc.ar([freq, freq * (4/3)], 0,
				EnvGen.kr(Env.perc(0.05, 0.3, 0.1, -4), doneAction: 2)
			)
		)
	}).send(Server.default);
});
)

(
// execute this next to create the sounds
var countdown = 100;
var note = 50;
var increment_func, decrement_func;
var action;
increment_func = {
	note = note + [2, 5, 7, 12].choose;
	if (note > 100) { action = decrement_func };
};
decrement_func = {
	note = note - [1, 2, 5, 7, 12].choose;
	if (note < 50) { action = increment_func };
};
action = increment_func;
{
	countdown do: { 
		Synth("ping", [\freq, note.midicps]);
		action.value;
		0.1.wait;
	}
}.fork;
)


 //Figure 5.11
// run each line separately: 
currentEnvironment;	// empty if no environment variables have been set
~alpha = pi;			// set env. variable ~alpha to pi
currentEnvironment;	// see current Environment again: ~alpha is set
~freq = 800;			// set another environment variable
Server.local.boot;
{ LFNoise0.ar(~freq, 0.1) }.play; // use an environment variable
// setting an environment variable to nil is equivalent to removing it: 
~alpha = nil;
currentEnvironment;	// alpha is no longer set


 //Figure 5.12
(
~q = "TOP";							// store "TOP" in ~a, top environment
(a: "INNER") use: { // run function in environment with ~a = "INNER"
	currentEnvironment.postln; // show the current environment
	topEnvironment.postln;		// show the top environment (different!)
	~a.postln				// show ~a's value in current environment
};	
~a;						// show ~a's value in top environment
)


 //Figure 5.13
(
var alpha, beta, gamma;
gamma = alpha;	// storing variable alpha in gamma only stores nil 
alpha = 10; 	// store 10 in alpha ...
gamma.postln;	// but the value of gamma remains unchanged
alpha = beta;	// so one cannot use gamma as 'joker'
beta = 20;		// to switch between variables alpha and beta.
gamma.postln;	// gamma is still nil.
)


 //Figure 5.15
Server.default.boot; 		// (boot Server before running example)
(
// Define a function and call it in different contexts
var synth;				// Synth creating the sound that is changed
var freq = 220; 			// frequency of the sound
var change_freq;			// function that changes the frequency of the sound
var window;			// window holding buttons for changing the sound
var button1, button2, button3; // buttons changing the sound

// Create a synth that plays the sound to be controlled:
synth = { | freq = 220 | LFTri.ar([freq, freq * 2.01], 0, 0.1) }.play;
// Create frequency changing function and store it in variable change_freq
change_freq = {						// start of function definition
		freq = freq * [0.9, 0.9.reciprocal].choose; // change freq value
		synth.set(\freq, freq);			// set synth's frequency to new value
};								// end of function definition

// Create 3 buttons that call the example function in various ways
window = Window("Buttons Archaic", Rect(400, 400, 340, 120));
//  ------------------------- Example 1 -------------------------
button1 = Button(window, Rect(10, 10, 100, 100));
button1.states = [["I"]]; // set the label of button1
// button1 calls the function each time that it is pressed 
button1.action = change_freq;	// make button1 change freq once
//  ------------------------- Example 2 -------------------------
button2 = Button(window, Rect(120, 10, 100, 100));
button2.states = [["III"]];
// Button2 creates a routine that calls the example function 3 times
button2.action = { 			// make button2 change freq 3 times
	{ 3 do: { change_freq.value; 0.4.wait } }.fork; // play as routine
};
//  ------------------------- Example 3 -------------------------
button3 = Button(window, Rect(230, 10, 100, 100));
button3.states = [["VIII"]];
button3.action = { 			// like example 2, but 8 times
	{ 8 do: { change_freq.value; 0.1.wait } }.fork; // play as routine
};
// use large size font for all buttons:
[button1, button2, button3] do: _.font_(Font("Times", 32));
// stop the sound when the window closes: 
window.onClose = { synth.free };
window.front; // show the window
)




 //Figure 5.18
(
// a function that calculates the square of the mean of two numbers
var sq_mean;
sq_mean = { arg a, b; 	// arguments a, b defined in arg statement form
	(a + b / 2).squared;
};
// calculate the square of the mean of 3 and 1:
sq_mean.value(3, 1);
)


 //Figure 5.19
(
// a function that calculates the square of the mean of any numbers
var sq_mean_all;
sq_mean_all = { | ... numbers | // using ellipsis and | | argument form
	(numbers.sum / numbers.size).squared;
};
// calculate the square of the mean of [1, 3, 5, -7]:
sq_mean_all.(1, 3, 5, -7); // short form: omit message 'value'
)


 //Figure 5.20
(
var w_func;
w_func = { arg message = "warning!", bounds = Rect(200, 500, 500, 100);
	var window;
	window = Window("message window", bounds).front;
	TextView(window, window.view.bounds.insetBy(10, 10))
		.string = message;	
};
 // provide text, use default bounds
w_func.(String.new.addAll(Array.new.addAll(" Major news! ").pyramid(7)));
)


 //Figure 5.21
(
var window, button; 
window = Window("Server Button", Rect(400, 400, 200, 200));
button = Button(window, Rect(5, 5, 190, 190));
button.states = [["boot!"], ["quit!"]];
button.action = { |me| Server.default perform: [\quit, \boot][me.value] };
window.front;
)


 //Figure 5.22
(
var window, button; 
window = Window("Server Button", Rect(400, 400, 200, 200));
button = Button(window, Rect(5, 5, 190, 190));
button.states = [["boot"], ["quit"]];
button.action = { | me | 
	[{ "QUITTING THE DEFAULT SERVER".postln;
		Server.default.quit;
	},{ "BOOTING THE DEFAULT SERVER".postln;
		Server.default.boot;
	}][me.value].value;
};
window.front;
)



 //Figure 5.23
Server.default.boot // boot default server before running example
(
var buffer;
buffer = Buffer.read(path: "sounds/a11wlk01.wav",
	action: { | buffer |
		format("loaded % at: %", buffer, Main.elapsedTime).postln;
	});
format("Reached this after 'Buffer.read' at: %", Main.elapsedTime).postln;
buffer;
)


 //Figure 5.24
Server.default.boot;  // do this first
(						// then the rest of the program
var window, routine;
window = Window("close me to stop").front;
window.onClose = { routine.stop };
routine = { 
	loop {
		(degree: -10 + 30.xrand, dur: 0.05, amp: 0.1.rand).play;
		0.05.rand.wait;
	}
}.fork;
)


 //Figure 5.25
_.isPrime ! 10
_.squared ! 10
_@_.(30, 40) // equivalent to: { | a, b | Point(a, b) }.value(30, 40)
Array.rand(12, 0, 1000).clump(4) collect: Rect(*_)
(1..8).collect([\a, \b, _]);
(a: _, b: _, c: _, d: _, e: _).(*Array.rand(5, 0, 100));


 //Figure 5.26
(
var iterative_factorial;
iterative_factorial = { | n |
	var factorial = 1;	// initialize factorial as factorial of 1
	// calculate factorial n times, updating its value each time
	n do: { | i | factorial = factorial * (i + 1) };
	factorial;	// return the final value of factorial;
};
iterative_factorial.(10).postln;	// 10 factorial: 3628800
)



//Figure 5.27
// Define the factorial function and store it in variable f:
f = { | x | if ( x > 1) { x * thisFunction.value(x - 1) } { x } };
 f.value(10);			// 10 factorial: 3628800


 //Figure 5.28
(
/* a function that recursively prints all folders and files
   found in a path and its subfolders */
{ | path |
	// store function here for use inside the if's {}:
	var thisFunc = thisFunction;
	format("====== now exploring: %", path).postln;
	// for all items in the path:
	path.pathMatch do: { | p | 
		// if the item is a folder, run this function on its contents
		// otherwise print the file found
		if (p.last == $/) { thisFunc.(p ++ "*") }{ p.postln }
	}
}.("*") // run function on home path of SuperCollider
)


//Figure 5.29
(
// a function that creates a function that counts to any number
var counter_maker;
var window, button1, button2; // gui for testing the function

// the function that makes the counting function
counter_maker = { | max_count |
	// current_count is used by the function created below
	// to store the number of times that it has run
	var current_count = 0;  
	{	// start of definition of the counting function
		if (current_count == max_count) {
			format("finished counting to %", max_count).postln; 
			max_count;		// return max count for eventual use
		}{
			current_count = current_count + 1; // increment count
			format("counting % of %", current_count, max_count).postln; 
			current_count	// return current count for eventual use
		}
	}	// end of definition of the counting function 
};

//  ----- Test application for the counter_maker function ----- 
// window displaying 2 buttons counting to different numbers
window = Window("Counters", Rect(400, 400, 200, 80));
// make a button for triggering the counting: 
button1 = Button(window, Rect(10, 10, 180, 20));
button1.states = [["counting to 10"]];	// labels for button1
// make a function that counts to 10 and store it as action in button1
button1.action = counter_maker.(10);
button2 = Button(window, Rect(10, 40, 180, 20));
button2.states = [["counting to 5"]];	// labels for button2
// make a function that counts to 5 and store it as action in button2
button2.action = counter_maker.(5);
window.front;			// show the window
)


//Figure 5.31
(
var counter_maker;		// creator of counters
var make_counters_gui;	// function making counters + a gui
/* a function that creates an event that counts to any number, 
   and resets: */ 
counter_maker = { | max_count |
	var current_count = 0; 
	(	// the counter object is an event with 3 functions: 
		count1: // function 1: increment count (stored as count1)
		{	// start of definition of the counting function
			if (current_count == max_count) {
				format("finished counting to %", max_count).postln; 
			}{
				current_count = current_count + 1; // increment count
				format("counting % of %", current_count, max_count).postln; 
			}
		},	// end of definition of the counting function
		reset_count: { // function 2: reset count (stored as reset_count)
			format("resetting % counter", max_count).postln;
			current_count = 0
		},
		max_count: { max_count } // function 3: return value of max_count
	)
};
// Function that makes several counters and a GUI to control them
make_counters_gui = { | ... counts |
	var window, counter;
	window = Window("Counters", 
			Rect(400, 400, 200, 50 * counts.size + 10));
	// enable automatic placement of new items in window: 
	window.view.decorator = FlowLayout(window.view.bounds, 5@5, 5@5);
	counts collect: counter_maker.(_) do: { | counter |  
		Button(window, Rect(0, 0, 190, 20))
			.states_([["Counting to: " ++ counter.max_count.asString]])
			.action = { counter.count1 };
		Button(window, Rect(0, 0, 190, 20))
			.states_([["Reset"]])
			.action = { counter.reset_count };
	};
	window.front;
};
make_counters_gui.(5, 10, 27); // example use of the GUI test function
)




//Figure 5.32
Server.default.boot;	// boot the server first;
(
var degrees, window, button;
window = Window("melodies?", Rect(400, 400, 200, 200));
button = Button(window, window.view.bounds.insetBy(10, 10));
button.states = [["click me to add a note"]];
button.action = { 
	degrees = degrees add: 0.rrand(15);
	Pbind(\degree, Pseq(degrees), \dur, Prand([0.1, 0.2, 0.4], inf)).play;
};
window.front;
)


 //Figure 5.34
1.class 		// the class of Integer 1: Integer
1.class.class 	// the Class of the Class of Integer 1: Meta_Integer
// the Class of the Class of the Class of Integer 1: 
1.class.class.class  					// Class
// the Class of the Class of the Class of the Class of Integer 1
1.class.class.class.class				// Meta_Class
// the Class of the Class of the Class of the Class of the Class of 1
1.class.class.class.class.class 		// Class 
Class.class				// the Class of Class is Meta_Class
Meta_Class.class		// the Class of Meta_Class is Class



 //Figure 5.36
Counter { 
	// variables: maximum count, current count
	var <>max_count, <>current_count = 1;
	// class method for creating a new instance
	*new { | max_count = 10 |
		^super.new.max_count_(max_count)
	}
	// if maximum count not reached, increment count by 1
	count1 {
		if (current_count >= max_count) {
			this.changed(\max_reached)
		}{
			current_count = current_count + 1;
			this.changed(\count, current_count);
		}
	}
	// reset count
	reset {
		current_count = 1;
		this.changed(\reset);
	}
}


 //Figure 5.37
Server.default.boot;
(
SynthDef("ping", { | freq = 440 | 
	Out.ar(0, 
		SinOsc.ar(freq, 0, 
			EnvGen.kr(Env.perc(level: 0.1), doneAction: 2)
	))
}).send(Server.default);

SynthDef("wham", {
	Out.ar(0, BrownNoise.ar(
		EnvGen.kr(Env.perc(level: 0.1), doneAction: 2)
	))
}).send(Server.default); 
)


 //Figure 5.38
(
~sound_adapter =  { | counter, what, count |
	switch (what, 
		\reset, { Synth("wham"); },
		\max_reached, { counter.reset },
		\count, { Synth("ping", 
			[\freq, count.postln * 10 + counter.max_count * 20]
			)
		}
	)
};
)
 //Figure 5.39
(
~make_display = { | counter |
	var window, label, adapter, stagger;
	window = Window(
		"counting to " ++ counter.max_count.asString, 
		Rect(stagger = UniqueID.next % 20 * 20 + 400, stagger, 200, 50)
	);
	label = StaticText(window, window.view.bounds.insetBy(10, 10));
	adapter = { | counter, what, count |
			{ label.string = counter.current_count.asString }.defer
	};
	counter addDependant: adapter;
	/* remove the adapter when window closes to prevent error in 
	   updating non-existent views: */
	window.onClose = { counter removeDependant: adapter };
	window.front
};
)












Figure 6.1.  Example of a SynthDef
SynthDef(					
	"sine", 				// name of SynthDef	
	{				// function begins with a brace
	 arg gate = 1, out = 0, 		// arguments serve as Control declarations
 freq = 400, amp = 0.4,
 pan = 0, ar = 1, dr = 1;

	var audio;			
	audio = SinOsc.ar(freq, 0, amp);		// start with a SinOsc
	audio = audio * Linen.kr(gate, ar, 1, dr, 2);	// apply an envelope
	audio = Pan2.ar(audio, pan);			// stereo pan, 
	OffsetOut.ar(out,audio);			// to bus out and out+1 
	}
).add;				// make and store a SynthDesc and SynthDef

Figure 6.2. Example of a key/value Array and a note Event=
a = [ 
	type:			\note,		
	instrument: 		'sine', 
	freq:			400, 
	amp:			0.1, 
	pan:			0, 
	ar: 			2, 
	dr: 			4, 
	sustain:		2
];

e = (
	type:			\note,		
	instrument: 		'sine', 
	freq:			400, 
	amp:			0.1, 
	pan:			0, 
	ar: 			2, 
	dr: 			4, 
	sustain:		2
);
e.play;					// play the note

Figure  6.3. The OSC commands created by the note event
e.asOSC.do{ | osc | osc.postcs };

// the result that would be posted:		
//  [ 0.0, ['s_new', 'sine', 1000, 0, 1, 'out', 0, 'freq', 400.0, 'amp', 0.1, 'pan', 0, 'ar', 2, 'dr', 4] ]
//  [ 2.0, [ 'n_set', 1000, 'gate', 0 ] ] 



Figure 6.4. Two ways of writing the same Event Pattern
	1. Pbind( *[ 
		dur:	0.2,
freq: 	Pseq([100, 200, 300, 400, 500, 600, 700, 800]) 
	] );

	2. Pbind( 
		\dur, 0.2,
		\freq, 	Pseq([100, 200, 300, 400, 500, 600, 700, 800]) 
	);

Figure 6.5. A more elaborate Event Pattern
p = Pbind(*[ 
		instrument:	\default,
		detune:		[0,1,3],
		freq: 		Pseq( (1..11) * 100,  4 * 5 * 7),
		db:		Pseq([-20, -40, -30, -40], inf),
		pan:		Pseq([-1,0,1,0], inf),
		dur:		Pseq([0.2,0.2,0.2,0.2, 0.4,0.4,0.8], inf),
		legato:		Pseq([2,0.5,0.75,0.5,0.25], inf)	
	] );
// render 40 seconds of the pattern in the file named "sf.aif"	
	p.render("sounds/sf.aif", 40)	
// now play the pattern in real-time
	p.play;									
Figure 6.6.  Using Event types
(
	(type: 	\group, 	
id: 2
).play;					// create a group with nodeID 2

	(	type:		\note, 		// play note		
	 	sustain:	100, 		// lasting 100 seconds				
	 	group: 		2		// in group 2

	 ).play;	
	 										
)
(
	(type: 	\off, 	id: 2).play;		// release all notes in the group
	(type:	 \kill,	id: 2,  lag: 3).play;	// and free the group  3 seconds later	
)

Figure 6.7. Chord events
// 2nd inversion - e loudest
( degree:  [-3,0,2],	sustain: 2, 	db: [-20, -20, -10] ).play			
// 2nd inversion - c loudest
 ( degree:  [-3,0,2],	sustain: 2, 	db: [-20, -10, -20] ).play	
// note "fattened" by three detuned copies
 ( degree: 0,		sustain: 2, 	detune: [0,3, 5] ).play			
// each detune is assigned to a different pitch, fat free.
 ( degree:  [-3,2,4],	sustain: 2, 	detune: [0,3, 5] ).play			
// detune rotates through each note in the chord
 ( degree:  [-3,2,4],	sustain: 2, 	detune: [0,0,0,3,3,3,5,5,5] ).play 	

Figure 6.8.  Interdependent key values in a Pattern
	Pbind(*[
		stretch:		Pseg([0,0.1,0.2,1],8).linexp(0,1, 1,0.125),
		midinote: 		100.cpsmidi,
		harmonic:		Pwhite(1, 16),
		legato:			Pkey(\stretch) * Pkey(\harmonic)/2 ,
		db:			-10 - Pkey(\harmonic),
		detune:			Pwhite(0.0,3.0),
		dur:			0.2,
	]).play

Figure 6.9. Chaining Event Patterns
	a = Pbind(*[
		scale: 	Pn( Pstep([[0,2,4,5,7,9,11], [0,1,3,5,6,8,11] ], 5 ) ),
		db:	Pn(Pseg([-20, -30, -25, -30], 0.4))
	]);
	b = Pbind(*[ 
degree: Pbrown(0, 6, 1), 
mtranspose: Prand([\rest, Pseq([0], 5.rand)],inf), 
dur: 0.2, 
octave: 6
]);
	c = Pbind(*[ 
degree: [0,2,4],  
mtranspose: Pbrown(0, 6, 1), 
dur: 0.4, 
db: -35
]);
	d = Pchain(Ppar([b, c]),a);
d.play;

Figure 6.10. Using Proutine to define and play patterns on the fly
	Proutine({| ev |
		var pat, refPat;

		refPat = Pbind(*[dur: 0.2, note: Pseq([0,0, 0, 7,0, 7])]);

		loop {
			ev = refPat.embedInStream(ev);

			pat = Pbind(*[
				dur: [0.2, 0.4].choose,
				note: Pseq(Array.fill(5, { 10.rand }), 3.rand )
			]);	
ev = pat.embedInStream(ev);
		}
	
}).play



Figure 6.11.  Using Proutine to define value and event patterns
~patA = Pbind(*[
	dur:	0.2,
	degree: Proutine({ | ev |
		var noteArray  = (0..5);
		loop {
			ev = Pseq(noteArray ).embedInStream(ev);
			noteArray[6.rand] = 7.rand;
		}		
	})
]);


~patB = Proutine({ | ev |
	var pat, pats= [
	 	Pbind(*[ degree: Pseq([  0, 7]), dur: 0.2   ]),
	 	Pbind(*[ degree: Pseq([11, 7]), dur: 0.2 ]),
		Pbind(*[ degree: Pseq([16, 7]), dur: 0.2 ]).
		(type: \rest, delta: 1)
	];
			
	loop {
		pat = pats.choose;
		ev = pat.embedInStream(ev);
	}
});

Pchain(
	Pbind(*[
		db: 	Pn(Pstep([-15, -25,-25, -20, -30, -25], 0.2) )
			+ Pseg([-30, -5,-10, -40], 12)
	]), 
	Ptpar([
		0, ~patA, 
		0,  ~patA, 
		12,  ~patB
	]) 
).play;

Figure 6.12.  Rendering and playing a pattern
	~pattern = Pbind(*[ 
		instrument:	"default",
		freq: 	Pseq([100, 200, 300, 400, 500, 600, 700, 800, 900, 1000, 1100], 5),
		db:	Pseq([-10, -30, -20, -30], inf),
		dur:	Pseq([0.2,0.2,0.2,0.2, 0.4,0.4,0.8],inf),
		legato: Pseq([2,0.5,0.75,0.5,0.25], inf)	
	] );

	~score = ~pattern.asScore(24 * 11/7);
	~score.render("recordings/test.aif");
	SoundFile("recordings/test.aif").play;
Figure 6.13. Soundfile granulation with a Pattern 
SynthDef("playbuf", { | out=0, bufnum = 0, rate = 1, 
startPos = 0, amp = 0.1, sustain = 1, 
pan = 0, gate = 1|
	var audio, env;
	rate = rate * BufRateScale.kr(bufnum);
	startPos = startPos * BufFrames.kr(bufnum);
	env = EnvGen.ar(Env.sine, 1, timeScale: sustain, doneAction: 2);
	audio = PlayBuf.ar(1, bufnum, rate, 1, startPos, 0);
	audio = env * audio;
	audio = Pan2.ar(audio, pan, amp);
	OffsetOut.ar(out, audio);
}).add;
		
	Pseq([
		(	type:		\load,
			filename:	"sounds/a11wlk01.wav",
			bufnum:	1,
			delta:		0
		),
		
		Pbind(*[
			instrument:	"playbuf",
			type:		\on,
			id:		-1,
			dur:		 Pseg([0,1],21).linexp(0,1,0.01,2),
			legato:		4,
			startPos:	Pn(Pseg([0,1], 10)),
			bufnum:	1,		
		]),
		(	type:		\free, 
			bufnum: 	1
		)
	]).play(quant: 0) 
// the result: [ ( 'midinote': 60 ), ( 'midinote': 64 ), ( 'midinote': 67 ) ]
Figure 6.14.  Yield versus EmbedInStream
	r = Routine{ 
		Pseq([1,2,3]).yield; 
		Pseq([1,2,3]).embedInStream;
		123445.embedInStream; 
		123445.embedInStream; 
	};

	[next(r), next(r), next(r), next(r), next(r), next(r)];
	// the result: [ a Pseq, 1, 2, 3, 123445, 123445, nil]

Figure 6.15. The definition of the stream created by Pseq.
	Routine({
		repeats.value.do({
			list.size.do({ arg i;
				item = list.wrapAt(i + offsetValue);
				inval = item.embedInStream(inval);
			});
		});
	});

 Figure 6.16.  The definition of Event�s play method.
	play {
		if (parent.isNil) { parent = defaultParentEvent };
		this.use { ~play.value };
	}

Figure 6.17. Definition of the key \play in the default event
{
	var tempo, server;
	
	~finish.value;						// user callback 
	server = ~server ?? { Server.default };	 
	tempo = ~tempo;					// assigning to a variable
									// saves repeated look ups
	if (tempo.notNil) {					// if not nil, change tempo of
		thisThread.clock.tempo = tempo;	// the clock playing the pattern
	};
	~eventTypes[~type].value(server);		// select play function from ~type
}

Figure 6.18.  Implementation of the event type \bus.
	{ |server|
		var lag, array;
		lag = ~lag + server.latency;
		array = ~array.asArray;
		server.sendBundle(lag, 
			[\c_setn, ~out.asUGenInput, array.size] ++ array);
	}	





/*
The methods asScore, render, and asOSC do not work in SuperCollider 3.4.
Evaluating the following code corrects the problem.  
This patch is incorporated into SuperCollider 3.4.2

*/
(
Event.default.parent[\eventTypes][\note] =��#{|server|
	var freqs, lag, strum, sustain;
	var bndl, addAction, sendGate, ids;
	var msgFunc, instrumentName, offset, strumOffset;
	
	// var schedBundleArray;

	freqs = ~detunedFreq.value;
	if (freqs.isKindOf(Symbol).not) {	
		
		// msgFunc gets the synth's control values from the Event
		msgFunc = ~getMsgFunc.valueEnvir;
		instrumentName = ~synthDefName.valueEnvir;
			
		// determine how to send those commands
		// sendGate == false turns off releases
		
		sendGate = ~sendGate ? ~hasGate;
					
		// update values in the Event that may be determined by functions
		
		~freq = freqs;
		~amp = ~amp.value;
		~sustain = sustain = ~sustain.value;
		lag = ~lag;
		offset = ~timingOffset;
		strum = ~strum;
		~server = server;
		~isPlaying = true;
		addAction = Node.actionNumberFor(~addAction);
	
		// compute the control values and generate OSC commands
		bndl = msgFunc.valueEnvir;
		bndl = [\s_new, instrumentName, ids, addAction, ~group] ++ bndl;
		
		
		if(strum == 0 and: { (sendGate and: { sustain.isArray })�
			or: { offset.isArray } or: { lag.isArray } }) {�
				bndl = flopTogether(
							bndl,
							[sustain, lag, offset]
				);
				#sustain, lag, offset = bndl[1].flop;
				bndl = bndl[0];
		} {�
				bndl = bndl.flop�
		};
		
		// produce a node id for each synth
		
		~id = ids = Array.fill(bndl.size, { server.nextNodeID });
		bndl = bndl.collect { | msg, i |�
				msg[2] = ids[i];�
				msg.asOSCArgArray
		};
	
		// schedule when the bundles are sent
		if (strum == 0) {
			~schedBundleArray.(lag, offset, server, bndl, ~latency);
			if (sendGate) {
				~schedBundleArray.(
					lag,
					sustain + offset,
					server,
					[\n_set, ids, \gate, 0].flop,�
					~latency
				);
			}
		} {
			
			if (strum < 0) { bndl = bndl.reverse };
			strumOffset = offset + Array.series(bndl.size, 0, strum.abs);
			~schedBundleArray.(
				lag, strumOffset, server, bndl, ~latency
			);
			if (sendGate) {
				if (~strumEndsTogether) {
						strumOffset = sustain + offset
				} {
						strumOffset = sustain + strumOffset
				};
				~schedBundleArray.(
					lag, strumOffset, server,
					[\n_set, ids, \gate, 0].flop,�
					~latency
				);
			}
		}	
	}
};
)


// in the following examples, all code that needs to be evaluated as one block is set in parentheses
// any such part can be evaluated in any order, e.g. starting from the middle or the end,
// and it may usually be rewritten at runtime.


//////////////////////////////////////////////////////////////////////////////
///////////////////////////// 1 Changing state   ////////////////////////////
////////////////////////////////////////////////////////////////////////////

// Figure 7.1: A modulo algorithm that operates over states of variables
(
Task {
	x = 4; y = 13;
	loop {
		x = (x * y) % 11;
		(note: x.postln, dur: 0.125).play;
		0.125.wait;
	}
}.play
);		// creates a loop of values

// change x and y
x = 5;	// new initial value
y = 4;	// new multiplication factor



// Figure 7.2: Synthesis graph

(
{
	x = SinOsc.kr(4); 
	y = SinOsc.kr(13);
	SinOsc.ar(x * y % 0.4 * 500 + 600) * 0.2
}.play;
)

// change x and y?
x = SinOsc.kr(4); // no effect.
y = SinOsc.kr(4); // no effect either.


// Figure 7.3: Dynamic synthesis graph

p = ProxySpace.push;
~x = { SinOsc.kr(4) }; 
~y = { SinOsc.kr(13) };
~z = { SinOsc.ar(~x * ~y % 0.4 * 500 + 600) * 0.2 };
~z.play;

	
// now ~x and ~y can be replaced
~x = { SinOsc.kr(0.4) }; 
~y = { SinOsc.kr(1.3) }; 

p.clear(2).pop; // release environment (2 sec fadeout)




//////////////////////////////////////////////////////////////////////////////
///////////////////  3 ProxySpace, Ndef, and NodeProxy  /////////////////////
////////////////////////////////////////////////////////////////////////////


// Figure 7.4: Refactoring a synthesis graph at runtime

p = ProxySpace.push;	// if needed

~a = { Lag.ar(LFClipNoise.ar(2 ! 2, 0.5, 0.5), 0.2) };
(
~b = {
	var c, d;
	c = Dust.ar(20 ! 2);
	d = Decay2.ar(c, 0.01, 0.02, SinOsc.ar(11300));
	d + BPF.ar(c * 5, ~a.ar * 3000 + 1000, 0.1)
}
);

~b.play;

// the refactored code from above

(
~a = { 
	var a;
	a =  Lag.ar(LFClipNoise.ar(2 ! 2, 0.5, 0.5), 0.2);
	BPF.ar(~c.ar * 5, a * 3000 + 1000, 0.1) 
}
);
~c = { Dust.ar(20 ! 2) };
~d = { Decay2.ar(~c.ar, 0.01, 0.02, SinOsc.ar(11300)) };
~b = ~a + ~d;

~b.play;



// Figure 7.6: A dynamic graph of a chaotic linear congruence. 
// self reference (~x) constructs a loop at control rate 

~out.play;
~x = 0.2; ~a = 1.1; ~c = 0.13;
~x = (~a * ~x) + ~c % 1.0;  // leaving out the .kr message assumes a control rate ugen.

~out = { Pan2.ar(SinOsc.ar(~x * 4000 + 200) * 0.1, ~x) };



// Figure 7.7: Creating a proxy object explicitly and changing its source
n = NodeProxy.new;
x = { SinOsc.ar(n.kr * 200 + 300) * 0.1 }.play;
n.source = { LFPulse.kr([1.3, 2.1, 3.2]).sum };
n.clear; x.free;

// Figure 7.8: Unified creation and access syntax with Ndef

Ndef(\out, { SinOsc.ar(Ndef.kr(\x) * 200 + 300) * 0.1 }).play;
Ndef(\x, { LFPulse.kr([1.3, 2.1, 3.2]).sum });
Ndef.clear;

// Figure 7.9: Unified creation and access syntax within an environment
p = ProxySpace.push; // if needed
~out = { SinOsc.ar(~x.kr * 200 + 300) * 0.1 }
~out.play;
~x = { LFPulse.kr([1.3, 2.1, 3.2]).sum };
p.clear.pop;



// Figure 7.10: Initialisation of node proxies in the proxy space

p.clear; // neutralize space, free all buses and synths
p.push; // if needed
~a.ar(3); // 3 channels, audio rate
~b.kr(8); // 8 channels, control rate
~c.play; // playing an uninitialized proxy assumes (per default) 2 channels, audio rate
~d = { LFNoise0.kr([1, 1, 1, 1]) }; // 4 channels, control rate




// Figure 7.11: Parameter mapping and setting

~out.play; ~out.fadeTime = 3;
(
// name with a_ represents audio rate argument
~out = { |freq=440, mod=0.4, detune=0.1, a_in = #[1,1]|
	freq = freq * ([0, detune] + 1);
	LFTri.ar(LFTri.ar(mod * freq).range(freq * mod, freq)) * a_in * 0.2
}
);

~mod2 = { LFNoise1.kr(1).range(0, 1) };
~mod1 =  { LFPulse.kr(~mod2.kr * 30 + 1, 0, 0.3) };
~freq1 = { ~mod1.kr * 13100 + 100 };
~freq2 = { LFTri.kr(30) * 200 + 300 };
~audio1 = { BrownNoise.ar(LFClipNoise.kr(10.dup), 1) };
~audio2 = { SinOsc.ar(LFNoise2.kr(1.dup).exprange(4, 1000)) };

~out.map(\freq, ~freq2, \mod, ~mod1);
~out.set(\detune, 0.01);
~out.map(\freq, ~freq1, \mod, ~mod1);
~out.xmap(\freq, ~freq1, \mod, ~mod2); // xmap crossfades over fade time to new value.
~out.xmap(\freq, ~freq2, \mod, ~mod1, \a_in, ~audio2);
~out.map(\a_in, ~audio1);


//////////////////////////////////////////////////////////////////////////////
//////////  4 Structured waiting and rewriting: TaskProxy, Tdef  ////////////
////////////////////////////////////////////////////////////////////////////



// Figure 7.12: Rewriting a synth def and a task def while running
// this synthdef is used in the subsequent figures
(
SynthDef(\wave, { |out, freq=440, amp=0.1, sustain=0.1, mod=0.2|
	OffsetOut.ar(out,
		EnvGen.ar(Env.perc(ExpRand(0.001, 0.05), sustain, amp), doneAction: 2)
		*
		SinOsc.ar(freq, SinOsc.ar(sustain.reciprocal * 8, [0, Rand(0, pi)], mod))
	)
}).add
);
(
Tdef(\x, {
	x = 4; y = 13;
	loop {
		x = (x * y) % 11;
		(instrument: \wave, note: x.postln, sustain: 0.5, octave: 6).play;
		0.125.wait;
	}
}).play
);


// Figure 7.13: Embed and fork of different tasks

(

Tdef(\a, { 10.do { (instrument: \wave, freq: 50.rand + 1500).play; 0.03.wait } });
Tdef(\b, { [1, 5, 1, 2, 8, 4, 12].do { |x| (instrument: \wave, note: x + 8).play; 0.1.wait } });
Tdef(\c, { "c is just a waiting message".postln; 2.wait; });


Tdef(\x, {
	loop {
		Tdef(\a).embed; // play in sequence
		1.wait;
		Tdef(\b).embed;
		2.wait;
		Tdef(\a).fork; // play in parallel
		Tdef(\b).fork;
		Tdef(\c).embed;
	}
}).play
);

// rewrite with infinite loop
Tdef(\a, { inf.do { (instrument: \wave, freq: 50.rand + 500).play; 0.1.wait } }); 
// rewrite with finite loop
Tdef(\a, { 10.do { (instrument: \wave, freq: 50.rand + 500).play; 0.1.wait } });


// Figure 7.14: Passing an environment into a task proxy when embedding
(
Tdef(\a, { |in|
	in.at(\n).do { |i| 
		in = (instrument: \wave, detune: 5.rand2).putAll(in);
		in.postln.play; 
		in.delta.wait;
	} 
})
);

(
Tdef(\x, { |inevent|
	loop {
		Tdef(\a).embed((note: [15, 17], dur: 0.01, n: 13));
		1.wait;
		Tdef(\a).embed((note: 9, dur: 0.4, n: 4));
		1.wait;
	}
}).play;
)



//////////////////////////////////////////////////////////////////////////////
/////////////////////   5 Empty Patterns    /////////////////////////////////
////////////////////////////////////////////////////////////////////////////


// Figure 7.15: A pattern proxy as an entry point into a stream

Pdefn(\x, Pseq([0, 2, 0, 7, 6, 5, 4, 3], inf));
(
Task {
	var stream = Pdefn(\x).asStream;
	var val;
	loop { 
		val = stream.next; 
		(instrument: \wave, note: val).play; 
		0.2.wait 
	}
}.play
);

Pdefn(\x, Pseq([0, 2, 0, 8, 6, 5, 2, 3, 4, 5], inf)); // rewrite the definition at runtime.
Pdefn(\x, Pseq([0, 2, 0, 7, 6, 5, 4, 3].scramble + 4, inf));



// Figure 7.16: Deriving variations fom nonexisting streams by mathematical operations

Pdefn(\y, Pdefn(\x) + 2); // derive a transposition
Pdefn(\z, Pdefn(\x) + Pseq([0, 5, 0, 7, 2], inf)); // derive a variation
Pdefn(\a, Ptuple([Pdefn(\y), Pdefn(\z)])); // combine them in a stream of arrays
(
Task {
	var stream = Pdefn(\a).asStream;
	var val;
	loop { 
		val = stream.next.postln; 
		(instrument: \wave, note: val, sustain: rrand(0.5, 0.9)).play; 
		0.2.wait 
	}
}.play
);

// rewriting the definitions causes all derivations to vary
Pdefn(\x, Pseq([0, 11], inf));
Pdefn(\x, Pseq([0, 2, 0, 7, 6, 5, 4, 3].scramble + 5, inf));
Pdefn(\z, Pdefn(\x) + Pseq([1, 5, 1, 11, 1], inf)); // change a variation

Pdefn(\a, 5); // a number as a source
Pdefn.clear; // clearing all - the empty pattern returns a series of 1. 



// Figure 7.17: Pdef - play, pause and resume.

Pdef(\a).play; // play silence in sequence
Pdef(\a, Pbind(\instrument, \wave)); // insert a sequence of notes
Pdef(\a, Pbind(\instrument, \wave, \dur, Pseq([1, 3, 2, 3], inf) / 6)); // add some rhythm
Pdef(\a).pause;
Pdef(\a).resume;
Pdef(\a).stop;



// Figure 7.18: A larger combination of Pdefs
(
(
Pdef(\x,
	Pbind(
		\instrument, \wave,
		\mod, Pseq([1, 0, 1, 0], inf), 
		\dur, Pn(1/2, 8),
		\note, 7
	)
)
);

(
Pdef(\y,
	Pbindf(
		Pdef(\x),
		\amp, 0.2,
		\note, Pshuf([0, 2, 3, 5], 2) + Prand([0, 5, [0, 4]], inf),
		\dur, Pseq([1, 3, 2, 3], inf) / 6
	)
)
);

(
Pdef(\z, Pbindf(Pdef(\y), \dur, 1/4))
);

// the combination of all placeholders into a new placeholder
(
Pdef(\a,
	Pmul(\dur, Pwhite(-0.02, 0.02) + 1,
		Pseq([
			Ppar([Pdef(\x), Pdef(\y)]),
			Pdef(\x),
			Pdef(\y),
			Pdef(\z),
			Ppar([Pdef(\x), Pbindf(Pdef(\y), \ctranspose, 2)])
		], inf)
	)
);
))

Pdef(\a).play; // play it

// go into a looping vamp
(
Pdef(\x,
	Pbind(
		\instrument, \wave, 
		\dur, Pseq([1, 3, 2, Prand([3, 2])], inf) / 6,
		\octave, [6, 4]
	)
)
);

// release a break
(
Pdef(\x,
	Pbind(
		\instrument, \wave, 
		\dur, Pseq([1, 3, 2, Prand([3, 2])], 1) / 6,
		\octave, [6, 4]
	)
)
);

Pdef(\a).stop; // stop the player


//////////////////////////////////////////////////////////////////////////////
/////////////////  6 Symbol streams and recursive patterns  /////////////////
////////////////////////////////////////////////////////////////////////////


// Figure 7.19: Simplifying the code in Figure 12.18 using Psym

// the combination of all placeholders into a new placeholder
(
Pdef(\b, Pbindf(Pdef(\y), \ctranspose, 2));
Pdef(\a,
	Pmul(\dur, Pwhite(-0.02, 0.02) + 1,
		Psym(Pseq([[\x, \y], \x, \y, \z, [\x, \b]], inf).trace) // trace it to post which
	)
).play;
)

// Figure 7.20: Using a Pdefn for the sequence of symbols itself
(
Pdefn(\sequence, Pseq([[\x, \y], \x, \y, \z, [\x, \b]], inf));
Pdef(\a,
	Pmul(\dur, Pwhite(-0.02, 0.02) + 1,
		Psym(Pdefn(\sequence).trace)
	)
).play;
)

// rewrite the sequence
Pdefn(\sequence, Pseq([\x], inf));
Pdefn(\sequence, Pseq([\x, \y, \x, [\x, \y]], inf));

Pdef(\a).stop; // stop playing


// Figure 7.21: Event type 'phrase'

(instrument: \x, type: \phrase).play; // a single phrase from Pdef(\x)

// a pattern of overlapping phrases
(
Pbind(
	\type, \phrase, 
	\instrument, \x, 
	\legato, 2.5, 
	\note, Pseq([0, 5, 7], inf)
).play
);


// Figure 7.22: Recursive phrasing
(
Pdef(\x, { |note=0, n=6, step=3, modulo=15, sustain=1|  
	Pbind(
		\instrument, \wave,
		\note, note.value + (Pseries(1, step, n) % modulo) + 7, 
		\dur, sustain.value / n
	) 
})
);

(
Pdef(\a, 
	Pbind(
		\type, \phrase,
		\instrument, \x,
		\note, Pseq([0, 5, 4, 8, 0], inf),
		\n, 5,
		\modulo, Pseq([3, [4, 3, 5], [13, 15]], inf),
		\dur, Pseq([1, 2, 0.5, 1.5], inf)
	)
).play
);

(
Pdef(\a, 
	Pbind(
		\type, \phrase,
		\instrument, \x,
		\note, Pseq([0, 5, 4, 8, 0], inf),
		\n, 5,
		\modulo, Prand([3, [4, 3, 5], [13, 15]], inf),
		\recursionLevel, 1,
		\dur, Pseq([1, 2, 0.5, 1.5], inf) * 2
	)
).play
);




//////////////////////////////////////////////////////////////////////////////
/////////////////////////  8 Combinatorics  /////////////////////////////////
////////////////////////////////////////////////////////////////////////////


// Figure 7.25: Combinations between patterns and ugen graphs


(
SynthDef(\train, { |out, xfreq=15, sustain=1.0, amp=0.1, pan|
	Line.ar(1, 1, sustain, doneAction:2);
	OffsetOut.ar(out, Pan2.ar(Impulse.ar(xfreq), pan, amp));
}).add
);

p = ProxySpace.push;
~z.play;

// A pattern in an audio rate node proxy ...
(
~x = Pbind(
	\instrument, \train, 
	\xfreq, Pseq([50, Pwhite(30, 800, 1), 5, 14, 19], inf), // only non-standard keys, i.e. xfreq 
	\sustain, Pseq([Pwhite(0.01, 0.1, 1), 0.1, 1, 0.5, 0.5], inf),
	\pan, Prand([-1, 1], inf) * 0.1
)
);
~y = { Ringz.ar(~x.ar, 5000 * [1, 1.2], 0.01) }; // resonant filter on the impulses from ~x
~mod = { LFNoise1.kr(0.1).exprange(200, 5000) }; // a modulator
~z = { ~y.ar * (SinOsc.ar(~mod.kr) + 1) }; // ring modulation with frequency ~mod

// ... and a control rate node proxy in a pattern.
// To pass on modulation like this, the standard event parameters like freq cannot be used.
// Here, we use xfreq instead.

(
~x = Pbind(
	\instrument, \train, 
	\xfreq, Pseq([50, ~mod, 5, ~mod, 19], inf), // read from the ~mod proxy bus. 
	\sustain, Pseq([Pwhite(0.01, 0.1, 1), 0.1, 1, 0.5, 0.5], inf),
	\pan, Prand([-1, 1], inf) * 0.1
)
);

// Figure 7.26 The same functionality, using Ndef instead of ProxySpace.
(
SynthDef(\train, { |out, xfreq=15, sustain=1.0, amp=0.1, pan|
	Line.ar(1, 1, sustain, doneAction:2);
	OffsetOut.ar(out, Pan2.ar(Impulse.ar(xfreq), pan, amp));
}).add
);

Ndef(\z).play;

// a pattern in an audio rate node proxy ...
(
Ndef(\x, Pbind(
	\instrument, \train, 
	\xfreq, Pseq([50, Pwhite(30, 800, 1), 5, 14, 19], inf), 
	\sustain, Pseq([Pwhite(0.01, 0.1, 1), 0.1, 1, 0.5, 0.5], inf),
	\pan, Prand([-1, 1], inf) * 0.1
))
);
Ndef(\y, { Ringz.ar(Ndef(\x).ar, 5000 * [1, 1.2], 0.01) });
Ndef(\mod, { LFNoise1.kr(0.1).exprange(200, 5000) });
Ndef(\z, { Ndef(\y).ar * (SinOsc.ar(Ndef(\mod).kr) + 1) }); // ring modulation with Ndef(\mod)

// ... and a control rate node proxy in a pattern

(
Ndef(\x, Pbind(
	\instrument, \train, 
	\xfreq, Pseq([50, Ndef(\mod), 5, Ndef(\mod), 19], inf), // read from the Ndef(\mod) proxy bus
	\sustain, Pseq([Pwhite(0.01, 0.1, 1), 0.1, 1, 0.5, 0.5], inf),
	\pan, Prand([-1, 1], inf) * 0.1
))
);


// Figure 7.27: Using a Tdef to create overlapping synths within a node proxy


Ndef(\x).play; // here an Ndef is used, the same can be done within a ProxySpace
Ndef(\x, { |freq=5, detune=0| Impulse.ar(freq * [detune, 1 - detune]) * 0.2 });
(
Tdef(\c, {
	loop {
		 Ndef(\x).fadeTime = rrand(0.1, 3.5);
		 Ndef(\x).send([\freq, exprand(2, 400), \detune, [0.0, 1.0].choose.rand]);
		2.wait;
	}
}).play
);









// eternal return. 
// nonlinear history for live and experimental just in time programming.
// Julian Rohrhuber 2007

/*


This program will give access to any ProxySpace (or subclass of LazyEnvir / EnvironmentRedirect) that is present as current environment. If none is present, it will create a ProxySpace and push it.

It creates a document window with some temporal navigations. 
This document is a throw away GUI, it can be closed anytime.

- the black stripe is the current time. here the edits become visible.
- the first number box is the current time
- the last number box represents the length of history, after which we return to beginning

Buttons:
_	navigate in time without entering it (toggles)
->	start time / stop time (toggles)
<<	rewind to beginning of time
:<	step back to previous edit
>:	step forward to next edit	
<	backward 0.25 sec in time
>	forward 0.25 sec in time
p	post the complete history
rm	remove the current entry
ld	load an appropriate history


*/


(
	var w, txt, value = 0, mapVal, valMap, b2, loadFunc, scaledValue = 0, tmax = 4 * 60 + 33, delta = 0.25;
	var ff, fne, fla, fba, fne2, fla2, m,  v, vv, mmax, task, changed, running = false;
	var drawLine, playRout, windowFollow,toggleHistory, dispatch, onTime = false;
	var browseBut, browseMode = false;
	var nietzsche, temporaryPseudoEnvironment, proxyspace;
	var width = 700;
	temporaryPseudoEnvironment = EnvironmentRedirect.new;
	
	b2 = Rect(10, 10, 350, 20);
	w = Window.new("---", Rect(128, 64, width, 30));
	w.view.decorator = FlowLayout( w.view.bounds ).gap_(2 @ 2);
	
	
	running = { task.isPlaying };
	toggleHistory = {
		if(running.value) { task.play(AppClock) } { task.stop };
	};
	
	
	
	// get the next appropriate point in time,
	// either the next delta step, or, if closer, the next timepoint
	task = Task {
		var nextDelta, nextIndex;
		loop {
			nextIndex = dispatch.timepoints.indexOfGreaterThan(scaledValue);
			if(nextIndex.isNil) {
				if(dispatch.timepoints.last.notNil 
					and: {dispatch.timepoints.last >= (scaledValue + delta)}) {
					nextDelta = tmax - scaledValue;
				} {
					nextDelta = delta
				}
			} {
				nextDelta = min(delta, dispatch.timepoints.at(nextIndex) - scaledValue);
			};
			scaledValue = (scaledValue + nextDelta % tmax);
			valMap.(scaledValue);
			nextDelta.wait;
		}
	
	};
	if(currentEnvironment.isKindOf(EnvironmentRedirect).not) {
		proxyspace = p = ProxySpace.push(s.boot);
	} {
		proxyspace = currentEnvironment;
	};
	dispatch = proxyspace.dispatch;
	if(dispatch.isNil) {
		proxyspace.dispatch = dispatch = HistoryDispatch.new;
	};
	dispatch.manual = true;
	dispatch.alwaysReplace = false;
	
	changed = { |time|
		var str, envir, changed, pairs;
		envir = dispatch.envir;
		if(browseMode) {
			pairs = dispatch.getPairsForTime(time);
			if(pairs.isNil) { d.string = "" } {
				d.string = pairs.collect { |pair|
						format("\n~% = %;\n\n", pair[0], pair[1].asCompileString)
					}.join;
			};
		} {
			changed = dispatch.setTime(time);
			if(changed) {
				str = dispatch.envir.asCompileString;
				d. string_( String.streamContents { arg str; 
					envir.storeOn(str, includeSettings: false); 
				});
			}
		};
	};
	
	drawLine = { |x, inset=0|
			Pen.beginPath;
			Pen.moveTo(x @ (5 + inset));
			Pen.lineTo(x @ (vv.bounds.height + 5 - inset));
			Pen.stroke;
	};
	
	w.drawHook_{
		Pen.use {	
			Pen.smoothing = false;
			Pen.width = 1;
			
			Color.white.set;
			drawLine.(value, 0);
			
			Color.new255(230, 123, 155).set;
			dispatch.timepoints.do {|x=(0)|
				x = x.clip(0, tmax);
				drawLine.(x / tmax * vv.bounds.width + vv.bounds.left, 3);
			};

		};
	};
	
	mapVal = {|x|
			if(x.inclusivelyBetween(vv.bounds.left, vv.bounds.left + vv.bounds.width)) {
				value = x;
				scaledValue = x - vv.bounds.left / vv.bounds.width * tmax;
				m.value = scaledValue;
				//onTime = dispatch.timepoints.includes(scaledValue);
				w.refresh;
			}
	};
	
	valMap = {|x|
			if(x.notNil) {
				x = x.clip(0, tmax);
				m.value = scaledValue = x;
				value = x / tmax * vv.bounds.width + vv.bounds.left;
				changed.value(scaledValue);
			//	onTime = timepoints.includes(scaledValue);
				w.refresh;
			}
	};
	
	loadFunc = { |path|
		var file, str, delim;
		protect {
			file = File(path.standardizePath, "r");
			str = file.readAllString;
		} {
			file.close;
		};
		str = str.stripRTF;
		delim = str.findAll("// -").add(str.size - 1);

		str = str.clumps(delim.differentiate).drop(1).drop(-1);
		
		proxyspace.awake = false;
			str.do { |substr|
				var time = History.getTimeFromString(substr);
				changed.(time);
				substr.interpret;
			};
		proxyspace.awake = true;
		tmax = max(tmax, History.getTimeFromString(str.last));
		mmax.value = tmax;
		valMap.(0.0);
		d.front;
	};
	
	vv = CompositeView.new(w, b2).background_(Color.black);
	v = UserView.new(vv, Rect(0, 0, w.bounds.width, w.bounds.height))
		
		.mouseMoveAction_({|v,x| mapVal.value(x) })
		.mouseUpAction_({|v,x| mapVal.value(x); changed.value(scaledValue); })
		.mouseDownAction_({|v,x| mapVal.value(x); });
	
	
	m = NumberBox.new(w, Rect(0, 0, 40, 20));
	m.value = 0;
	m.action = { valMap.value(m.value) };
	
	vv.keyDownAction = { |v, char|
		char.postln;
		if(char == $ , toggleHistory);
	};

	browseBut = Button.new(w, Rect(0, 0, 20, 20))
		.states_([["_", Color.black], ["-", Color.black]])
		.action_({|b| 
			browseMode = b.value == 1;
			if(b.value == 0) {
				valMap.(scaledValue);
			};
			d.background = [Color.white, Color.grey(0.8)][b.value];
		});
	

	ff = Button.new(w, Rect(0, 0, 20, 20)).states_([["->", Color.black], ["||", Color.red]]);
	
	fba = Button.new(w, Rect(0, 0, 20, 20)).states_([["<<", Color.black]]);
	
	fla = Button.new(w, Rect(0, 0, 20, 20)).states_([[":<", Color.black]]);
	fne = Button.new(w, Rect(0, 0, 20, 20)).states_([[">:", Color.black]]);
	
	fla2 = Button.new(w, Rect(0, 0, 20, 20)).states_([["<", Color.black]]);
	fne2 = Button.new(w, Rect(0, 0, 20, 20)).states_([[">", Color.black]]);
	
	ff.action = { if(ff.value == 1) { task.play(AppClock);  } { task.stop } };
	fba.action = { valMap.(0.0) };
	fne.action = { 
		i = dispatch.timepoints.indexOfGreaterThan(scaledValue) ? 0; 
		valMap.(dispatch.timepoints.at(i))
	 };
	fla.action = { 
		i = dispatch.timepoints.indexOfGreaterThan(scaledValue - 0.01);
		i = i ? dispatch.timepoints.lastIndex;
		if(i.notNil and: { i > 0 }) {
			valMap.(dispatch.timepoints.wrapAt(i-1))
		}
	};
	
	fne2.action = { 
		valMap.(scaledValue + delta % tmax)
	 };
	fla2.action = {
		valMap.(scaledValue - delta  % tmax)
	};
	
	mmax = NumberBox.new(w, Rect(0, 0, 40, 20));
	mmax.value = tmax;
	mmax.action = { tmax = mmax.value; valMap.(scaledValue); };
	
	
	
	Button.new(w, Rect(0, 0, 20, 20)).states_([["p", Color.black]])
		.action_({dispatch.document});
	
	
	Button.new(w, Rect(0, 0, 20, 20)).states_([["rm", Color.black]])
		.action_({ 
				dispatch.removeAllAtTime(scaledValue);
				changed.(scaledValue);
				w.refresh;
		});
		
	Button.new(w, Rect(0, 0, 20, 20)).states_([["ld", Color.black]])
		.action_({ 
				Dialog.getPaths({ |paths| paths.do(loadFunc.(_)) });
		});
		
	w.front;
	d = Document.new("history doc").bounds_(Rect(20, 280, width, 481));
	d.onClose = { w.close; windowFollow.stop; CmdPeriod.remove(playRout); };
	w.onClose = { windowFollow.stop; CmdPeriod.remove(playRout); };
	d.toFrontAction = d.toFrontAction.addFunc {
		if(w.isClosed.not) { ff.valueAction = 0 };
	};
	nietzsche = #["Alles Laufenkoennen muss gelaufen sein", "Der Torweg muss auch gelaufen sein", "Der Augenblick zieht alles nach sich, auch sich selbst", "Alles Laufenkoennen muss noch laufen", "Out of damp and gloomy days, out of solitude, out of loveless words directed at us, conclusions grow in us like fungus: one morning they are there, we do not know how, and they gaze upon us.", "Woe to the thinker who is not the gardener but only the soil of the plants that grow up in him!"];
	windowFollow = Routine { 
		var x;
		loop {
		0.06.wait;
		if(d.bounds != x) {
		 	w.bounds = 
		 	Rect(d.bounds.left, d.bounds.top + d.bounds.height, d.bounds.width, w.bounds.height);
		 	if(0.3.coin) { nietzsche.choose.postln };
		 	 
		 	 w.front;
		 	 0.01.wait;
		 	 d.front;
			
		 };
		 x = d.bounds;
		
		  0.3.wait;
		}
	
	};
	playRout = { windowFollow.play(AppClock) };
	CmdPeriod.add(playRout);
	
	playRout.value;
	valMap.value(0);
	

)



/////////////////////// Object Modeling code figures /////////////////// 



	//	figure 8.1 - a Puppet class, and tests for it.
	
Puppet { 
	var <>myfreq; // an instance variable with a getter and a setter method
	
		// a method for creating a new object of this kind
	*new { |myfreq=50| ^super.new.myfreq_(myfreq) }
	
		// a simple method that uses 'myfreq' for something audible.
	blip { { Blip.ar(myfreq, 11) * XLine.kr(1, 0.01, 0.6, doneAction: 2) }.play; }
}

	// tests for the behavior implemented so far:
m = Puppet.new(50);// make an instance of Puppet, pass in myfreq

m.dump;			// test that myfreq is set correctly
m.myfreq;			// test accessing myfreq
m.blip;			// should sound
m.myfreq_(100);	// test setting myfreq
m.blip;		 // should sound differently







	// figure  8.2 - a puppet modeled as an event.

m = (); 			// make an empty event
m.myfreq_(50);	// put something in it with a setter method: a pseudo-instance variable
m.myfreq;			// look it up with a getter method
				// put a function into it with a setter: 
				// this becomes a pseudo-method
m.blip_({ |ev| { Blip.ar(ev.myfreq, 11) * XLine.kr(1, 0.01, 0.6, doneAction: 2) }.play; });
m.blip;		// execute the function with a pseudo-method call (same name)





	// figure  8.3 - add more instance variables, change the blip method.
(
m.numHarms_(20); 	// a new instvar
m.decay_(0.3); 	// and another
				// update the blip method to use them:
m.blip_({ |ev| 
	{ Blip.ar(ev.myfreq, ev.numHarms) 
	* XLine.kr(1, 0.01, ev.decay, doneAction: 2) }.play; 
});
)
m.blip;	// test






	//	figure 8.4 - A minimal shout window sketch.

z = z ? (); 	// make an empty event as a pseudo-object
z.win = Window("Shout", Rect(0, 900,1200, 100)).front;
z.txtView = TextView(z.win, Rect(0, 0,1200, 100));
z.txtView.string_("Shout this!");
z.txtView.font_(Font("Monaco", 32));

	// tune appearances
z.win.alpha_(0.7);		// make the window slightly transparent
z.win.view.background_(Color.clear);	// make the window's top view,
z.txtView.background_(Color.clear);	// and textview fully transparent
z.win.alwaysOnTop_(true);	// make sure it is always on top .

z.win.close;	// close when done



	// figure 8.5 - add a pseudo-method.
(
z.makeWin = { |z, message="Shout this!"|
	z.win = Window("Shout", Rect(0, 900,1200, 100)).front;
	z.win.alpha_(0.7);	
	z.win.view.background_(Color.clear);	
	z.win.alwaysOnTop_(true);

	z.txtView = TextView(z.win, Rect(0, 0,1200, 100));
	z.txtView.string_(message);
	z.txtView.font_(GUI.font.new("Monaco", 32));
	z.txtView.background_(Color.clear);
};
)
z.makeWin; 
z.makeWin("Try showing that."); 





	// figure 8.6 - more pseudo-methods.

z.setMessage = { |z, str| z.txtView.string_(str) };

z.setMessage("Does this update?");	// test
(
z.shout = { |z, str|
	if (z.win.isNil or: { z.win.isClosed }) { z.makeWin };
	z.setMessage(str);
};
)
z.shout("Do we get this?"); // test

z.win.close;
z.shout("Do we get this too?"); // also when window has closed?





	// figure 8.7 - text color animation

z.txtView.stringColor_(Color.red);	// try a single color
(
z.animate = { |z, dt=0.2, n = 6| 
	var colors = [Color.red, Color.green, Color.black];
	Task { 
		n.do { |i|�
			dt.wait; 
			z.txtView.stringColor_(colors.wrapAt(i))
		}
	}.play(AppClock)
};
)
z.animate;			// test with default values 
z.animate(0.1, 24); 	// and test with arguments given





	// figure 8.8 is an image - "c6_ObjMod_fig8.8_shoutWin.png"





	// figure 8.9 - using codeDump to shout 

this.codeDump = { |str, result, func| [str, result, func].printAll };

a = 1 + 2;	// code appears in post window

z.shoutTag = "//!!";
this.codeDump = { |str| if (str.beginsWith(z.shoutTag)) { z.shout(str.drop(z.shoutTag.size)) } };

//!! a comment with a 'shout tag' now gets shouted!





	//	figure 8.10 - updated setMessage flashes text.
(
z.setMessage = { |z, str| 
	var messSize = str.size; 
	var fontsize = (1.64 * z.txtView.bounds.width) / max(messSize, 32);
	z.txtView.font_(GUI.font.new("Monaco", fontsize));
	z.txtView.string_(str);
	z.animate;
};
)
//!! a long comment gets scaled down to a rather smaller font size, minimally fontsize 32! 

//!! short is big!
(
z.makeWin = { |q, message="Shout this!"|
	z.win = Window("Shout", Rect(0, 900,1200, 100)).front;
	z.win.alpha_(0.7);	
	z.win.view.background_(Color.clear);	
	z.win.alwaysOnTop_(true);

	z.txtView = TextView(z.win, Rect(0, 0,1200, 100));
	z.txtView.background_(Color.clear);
	z.setMessage(message);
};
)
z.makeWin("shout.");






	//	figure 8.11 - a Shout class

// begin of file - Shout.sc
Shout {
	classvar <>tag="//!!";
	var <win, <txtView;
	
	*new { ^super.new }
} 
// end of file - Shout.sc

// tests: 
Shout.tag;
Shout.tag_("//SHOUT");

a = Shout.new; 
a.win;
a.txtView;




	// figure 8.12 - more class variables and initClass method.

// begin of file - Shout.sc
Shout {
	classvar <>tag="//!!", <>width=1250, <>defaultCodeDumpFunc; 
	var <win, <txtView;
	
	*initClass { 
		defaultCodeDumpFunc = { |str| if (str.beginsWith(tag)) { Shout(str.drop(tag.size)) } };
	}
	*new { ^super.new }
} 
// end of Shout.sc

Shout.width;
Shout.defaultCodeDumpFunc;




	// figure 8.13 - converting makeWin.

z.makeWin = { |message="Shout this!"|
	z.win = GUI.window.new("Shout", Rect(0, 900,1200, 100)).front;
	z.win.alpha_(0.7);	
	z.win.view.background_(Color.clear);	
	z.win.alwaysOnTop_(true);

	z.txtView = GUI.textView.new(z.win, Rect(0, 0,1200, 100));
	z.txtView.background_(Color.clear);
	z.setMessage(message);
};


Shout {	
	...
	*new { |message| ^super.new.makeWin(message); }
	
	makeWin { |message="Shout this!"| 
	
		win = Window("Shout'er", Rect(20, 800, width, 80)).front;
		win.alpha_(0.7);
		win.view.background_(Color.clear);
		win.alwaysOnTop_(true);
		
		txtView = TextView(win, win.bounds.moveTo(0,0));
		txtView.background_(Color.clear);
		txtView.font_(Font.new("Monaco", 32));
		this.setMessage(message);
	}

	setMessage { |message| 
		txtView.string_(message.asString)
	}
}

// tests:
Shout.new;
a = Shout.new("Blabla");
a.setMessage("Otto");






	//	figure 8.14 - converting z.shout to Shout.new.

z.shout = { |z, str|
	if (z.win.isNil or: { z.win.isClosed }) { z.makeWin };
	z.setMessage(str);
};

Shout { 
	classvar <top;
	...
	*new { |message="�Shout'er!"| 

		if (top.isNil or: { top.win.isClosed }) { 
			top = this.basicNew(message); 
		} {
			top.setMessage(message);
		};
	}
		// the method formerly known as *new
	*basicNew { |message="Shout this!"| ^super.new.makeWin(message) } 

	*close { try { top.win.close } }
	
	...
}

// tests: 
Shout("Test 1, 2");
Shout("Test 1, 2, 3, 4");	// same window
Shout.close;

Shout("Test 1, 2");		// new window






	//	figure 8.15 - converting animate to a class method.

z.animate = { |z, dt=0.2, n = 6| 
	var colors = [Color.red, Color.green, Color.black];
	Task { 
		n.do { |i|�
			dt.wait; 
			z.txtView.stringColor_(colors.wrapAt(i))
		}
	}.play(AppClock)
};

Shout { 
	...
	animate { |dt=0.2, n=6|
		var colors = [Color.red, Color.green, Color.black]; 
		Task { 
			n.do { |i| 
				txtView.stringColor_(colors.wrapAt(i)); 
				dt.wait 
			};
			txtView.stringColor_(Color.black); // make sure we end black
		}.play(AppClock);
	}
	...	
}

// tests: 
a = Shout("Test 1, 2");
Shout.top.animate;





 
	// figure 8.16 - converting setMessage

z.setMessage = { |z, str| 
	var messSize = str.size; 
	var fontsize = (1.64 * z.txtView.bounds.width) / max(messSize, 32);
	z.txtView.font_(GUI.font.new("Monaco", fontsize));
	z.txtView.string_(str);
	z.animate;
};

Shout { 
	...
	setMessage { |message| 
		var messSize, fontSize;
		messSize = message.size;
		fontSize = (1.64 * width) / max(messSize, 32);
		
		defer { 
			txtView.font_(Font("Monaco", fontSize))
				.string_(message.asString);
		};
		this.animate;
	}
	...	
}

Shout("Test 1, 2");
Shout("Test" + (1..16));







	//	figure 8.17 - codeDump tests and usage in Shout

this.codeDump.postcs;	// anything there yet? by default, this is nil.
this.codeDump = this.codeDump.addFunc(Shout.defaultCodeDumpFunc); // add Shout
this.codeDump.postcs	// should be there now
//!! test whether Shout works now
this.codeDump = this.codeDump.removeFunc(Shout.defaultCodeDumpFunc);
this.codeDump.postcs	// should be gone now

//!! should be off again

Shout { 
	...
	*add { var interp = thisProcess.interpreter; 
		interp.codeDump = interp.codeDump
			.removeFunc(defaultCodeDumpFunc) // remove it first so it will 
										// only be in the list once
			.addFunc(defaultCodeDumpFunc); 
	}
	*remove { var interp = thisProcess.interpreter; 
		interp.codeDump = interp.codeDump.removeFunc(defaultCodeDumpFunc); 
	}
	...	
}

// tests
Shout.add;
//!! test whether Shout works now - it should!
Shout.remove;
//!! test whether Shout works now - should be off.






	//	figure 8.18 - keeping Shout out of the way

Shout.close;
Shout("blabla");	// now typing is impossible, because the new window is in front.

Shout("blabla blabla");	// now one can type, because Shout window was already there.
Shout.close; 

	// this does not work, because the shout window gets put in front later:
d = Document.current; Shout(\bla); d.front; 
 

	// This can be wrapped around the call to this.makeWin in Shout:new:
Shout { 
	...
	*new { |message="�Shout'er!"| 
		var currDoc;

		if (win.isNil or: { win.isClosed }) { 
			currDoc = Document.current;
			top = this.basicNew(message); 
				// wait a little before restoring front window
			defer ({ currDoc.front }, 0.1);
		} {
			top.setMessage(message);
		};
	}
	...	
}






	// figure 8.19 - a fixed serialization method.

serialize {|index, pos, extent = 8|
	var ranges, slice;

	// get ranges
	ranges = pos.collect{|pos, i| 
		((pos-(extent*0.5))..(pos+(extent*0.5)-1)) % this.shape[i] 
	};
	// get sub-slice
	slice = this.slice(index, *ranges);
	// trivial serialization of multidim. slice
	^slice.flat
}






	// figure 8.20 - flexible  serialization by lookup.

serialize {|index, pos, extent = 8, how = \hilbert|
	// [...]
	slice = this.slice(index, *ranges);
	// call function in serTypes dictionary
	^serTypes[how].(slice.asArray, extent)
}







// figure 8.21 � some initial serialization methods, and adding an alternative. 

	*initClass {|numDims = 4|
		...
		// slice here is a 4d hypercube of extent <extent>
		serTypes = (
			hilbert: {|slice, extent|
				extent.isPowerOfTwo.not.if({
					"QCD:serialize: extent has to be a power of two".error
				});
				HilbertIndices.serialize(slice)
			},
			torus: {|slice, extent|
				slice.flat;
			},
			scramble: {|slice|
				slice.flat.scramble;
			}
		);
	}

	// add a new serialization type at runtime
QCD.serTypes.put(\star, {|slice|
	var starSize = slice.size div:2;
	var numDims = 4;
	var starShape;

	starShape = neighbours1.collect({ |nb|  
		(0..starSize).collect(_ * nb) 
	}).flatten(1).collect {|indexN| 
		indexN + (starSize.div(2)+1).dup(numDims) 
	};
	
	starShape.collect{|iA| slice.slice(*iA)}
});





///////// continued in ObjMod2_codefigures.rtf ///// 






	// figure 8.23 - two granular synthdefs and tests
(
	// a gabor (approx. gaussian-shaped) grain
SynthDef(\gab1st, { |out, amp=0.1, freq=440, sustain=0.01, pan| 
	var snd = FSinOsc.ar(freq);
	var env = EnvGen.ar(Env.sine(sustain, amp * AmpComp.ir(freq) * 0.5), doneAction: 2);
	OffsetOut.ar(out, Pan2.ar(snd * env, pan));
}, \ir ! 5).memStore;


			// a simple percussive envelope
SynthDef(\percSin, { |out, amp=0.1, freq=440, sustain=0.01, pan| 
	var snd = FSinOsc.ar(freq);
	var env = EnvGen.ar(
		Env.perc(0.1, 0.9, amp * AmpComp.ir(freq) * 0.5), 
			timeScale: sustain, doneAction: 2
		);
	OffsetOut.ar(out, Pan2.ar(snd * env, pan));
}, \ir ! 5).memStore;


/*	
	// tests for the synthdefs:
Synth(\gab1st);
Synth(\percSin);
Synth(\percSin, [\amp, 0.2, \sustain, 0.1]);
Synth(\gab1st, [\out, 0, \amp, 0.2, \freq, 2000, \sustain, 0.05, \pan, 0.5] );
*/
);





	// figure 8.24 - global setup and a player Tdef for the cloud.
(
q = q ? (); 

	// some globals
q.paramRNames = [\freqRange, \durRange, \densRange, \ampRange, \panRange]; 
q.paramNames = [\freq, \grDur, \dens, \amp, \pan]; 
q.syndefNames = [\gab1st, \gabWide, \percSin, \percSinRev, \percNoise];

	// specs for some parameters
Spec.add(\xfadeTime, [0.001, 1000, \exp]);
Spec.add(\ring, [0.03, 30, \exp]);
Spec.add(\grDur, [0.0001, 1, \exp]);
Spec.add(\dens, [1, 1000, \exp]);

	// make an empty tdef that plays it, 
	// and put the cloud parameter ranges in the tdef's environment
Tdef(\cloud0)
	.set(
	\synName, \gab1st,
	\vol, 0.25,
	\current, (
		freqRange: [200, 2000],
		ampRange: [0.1, 1],
		durRange: [0.001, 0.01], 
		densRange: [1, 1000],
		panRange: [-1.0, 1.0] 
	)
); 
		
		// make the tdef that plays the cloud of sound particles here, 
		// based on parameter range settings.
Tdef(\cloud0, { |e| 

	loop {
		s.sendBundle(s.latency, [
			"/s_new", e.synName ? \gab1st, 
			-1, 0, 0,
			\freq, 	exprand(e.current.freqRange[0], e.current.freqRange[1]),
			\amp,	exprand(e.current.ampRange[0], e.current.ampRange[1]) * e.vol,
			\sustain,	exprand(e.current.durRange[0], e.current.durRange[1]),
			\pan, 	rrand(e.current.panRange[0], e.current.panRange[1])
		]);
		exprand(e.current.densRange[0].reciprocal, e.current.densRange[1].reciprocal).wait; 
	}
}).quant_(0);	
);





	// figure  8.25	-  tests for the cloud
	
Tdef(\cloud0).play;

	// try changing various things from outside the loop. 
	// change its playing settings 

Tdef(\cloud0).envir.current.put('densRange', [ 50, 200 ]); // dense, async
Tdef(\cloud0).envir.current.put('densRange', [ 1, 10 ]);  // sparse, async
Tdef(\cloud0).envir.current.put('densRange', [ 30, 30 ]); // synchronous

	// for faster access, call the tdef's envir d
d = Tdef(\cloud0).envir;
d.current.put('freqRange', [ 800, 1200 ]);
d.current.put('durRange', [ 0.02, 0.02 ]);

d.current.put('ampRange', [ 0.1, 0.1 ]);

d.current.put('panRange', [ 1.0, 1.0 ]);
d.current.put('panRange', [ -1.0, 1.0 ]);

d.current.put('densRange', [ 30, 60 ]);
d.synName = \percSin;
d.synName = \gab1st;
d.synName = \gabWide;
d.synName = \percSinRev;
d.synName = \percNoise;
d.synName = \percSinRev;
d.synName = \gab1st;
d.current.put('durRange', [ 0.001, 0.08 ]);







	// figure 8.26 - making random settings, and 8 random presets to switch between
(
	// make the Tdef's envir a global variable for easier experimenting
d = Tdef(\cloud0).envir;
	// a pseudo-method to make random settings, kept in the Tdef's environment
		// randomize could also do limited variation on existing setting. 
d.randSet = { |d|
	var randSet = ();	
	q.paramRNames.do { |pName, i| 
		randSet.put(pName, 
			q.paramNames[i].asSpec.map([1.0.rand, 1.0.rand].sort)
		);
	};
	randSet;
};

/* 	test randSet: 
d.current = d.randSet;
*/

// make 8 sets of parameter range settings: 
d.setNames = (1..8).collect { |i| ("set" ++ i).asSymbol };
d.setNames.do { |key| d[key] = d.randSet; }

/*	test switching to the random presets
d.current = d.set1.copy;	// copy to avoid writing into a stored setting when it is current.
d.current = d.set3.copy;	
d.current = d.set8.copy;
*/
);




	// ex. 8.27 - crossfading between different settings with a taskproxy
	
(
	// and some parameters for controlling the fade
d.stopAfterFade = false;
d.xfadeTime = 5; 

d.morphtask = TaskProxy({
	var startSet = d[\current], endSet = d[\target];
	var stepsPerSec = 20;
	var numSteps = d.xfadeTime * stepsPerSec;
	var blendVal, morphSettings;
	
	if (d.target.notNil) { 
		(numSteps).do { |i| 
		//	["numSteps", i].postln;
			blendVal = (i + 1) / numSteps; 
			morphSettings = endSet.collect({ |val, key| 
				(startSet[key] ? val).blend(val, blendVal) 
			});
			d.current_(morphSettings);
			(1/stepsPerSec).wait;
		};
		d.current_(d.target.copy);
		"morph done.".postln;
		if (d.stopAfterFade) { Tdef(\cloud0).stop; };
	};
}).quant_(0);		// no quantization so the task starts immediately

/* test morphing
(
Tdef(\cloud0).play;
d.target = d.set6.copy;
d.morphtask.play;
)
Tdef(\cloud0).stop;

	// playing a finite cloud with tendency mask: 
(
Tdef(\cloud0).play;		// begin playing
d.stopAfterFade = true; 	// end cloud when crossfade ends
d.xfadeTime = 10; 			// set fade time
d.target = d.set8.copy;		// and target
d.morphtask.play;			// and start crossfade.
)
*/

	// put fading into its own method, with optional stop.
d.fadeTo = { |d, start, end, time, autoStop| 
	d.current = d[start] ? d.current;
	d.target = d[end]; 
	d.xfadeTime = time ? d.xfadeTime;
	if (autoStop.notNil) { d.stopAfterFade = autoStop };
	d.morphtask.stop.play;
};

/* 	// tests fadeTo:
Tdef(\cloud0).play;
d.fadeTo(\current, \set2, 20);
d.fadeTo(\current, \set6, 10);
d.fadeTo(\current, \set5, 3, true);

Tdef(\cloud0).play;
d.fadeTo(\current, \set1, 3, false);
*/ 
);



	// figure 8.28 is an image: the CloudGenMini GUI, file "c8_ObjMod_8.29_cloudGenGui.png"  //




	// figure 8.29 - a lightweight graphical user interface for CloudGenMini 
(
q.makeCloudGui = { |q, tdef, posPoint| 
	var w, ezRangers, fdBox; 
	var setMinis, skipjack; 
	
	posPoint = posPoint ? 400@400;	// where to put the gui window
	
	w = Window.new("CloudGen_mini_sc3", 
		Rect.fromPoints(posPoint, (posPoint + (400@300)))).front;
	w.view.decorator_(FlowLayout(w.bounds.copy.moveTo(0, 0)));
		
	w.view.decorator.nextLine; 
		// the range sliders display the current values
	ezRangers = ();
	
	q.paramRNames.do { |name, i| 
		ezRangers.put(name, 
		EZRanger(w, 400@20, name, q.paramNames[i], 
			{ |sl| tdef.envir.current[name] = sl.value; }, 
			tdef.envir.current[name], labelWidth: 70, numberWidth: 50, unitWidth: 10)
			.round_([0.1, 0.00001, 0.0001, 0.0001, 0.01][i])
		);
	};
		// a just in time - gui for the Tdef
	TdefEditor(tdef, height: 20, w: w); 
	
	Button.new(w, 80@20).states_([[\randomize]])
		.action_({ 
			tdef.envir.target_(d.randSet);
			tdef.envir.morphtask.stop.play;
		});
	
	fdBox = EZNumber.new(w, 110@20, \xFadeTime, [0, 100, \amp], 
		{ |nbx| tdef.envir.xfadeTime = nbx.value }, 
		 tdef.envir.xfadeTime, false, 65); 

			// skipjack is a task that survives cmd-period:
			// used here for lazy-updating the control views.
	skipjack = SkipJack({  
		q.paramRNames.do { |name| ezRangers[name].value_(tdef.envir.current[name]) };
		fdBox.value_(tdef.envir.xfadeTime); 
		
		// mark last settings that were used by color? 
		// a separate color when changed? 
		
	}, 0.5, { w.isClosed }, name: tdef.key);
	
	w.view.decorator.nextLine;

	// make a new layoutView for the 8 presets; 
	// put button to switch to that preset, 
	// a button to save current settings to that place, 
	// and a miniview of the settings as a visual reminder in it.
	
		// make 8 setButtons
	tdef.envir.setNames.do { |setname, i|	
		var minisliders, setMinis;
		var zone = CompositeView.new(w, Rect(0,0,45, 84));
		zone.decorator = FlowLayout(zone.bounds, 0@0, 5@0); 
		zone.background_(Color.white); 
		
		Button.new(zone, Rect(0,0,45,20)).states_([[setname]])
			.action_({ 
				// just switch: // tdef.envir.current.putAll(d[setname] ? ()) 
				tdef.envir.target = tdef.envir[setname];
				tdef.envir.morphtask.stop.play;
			});
		
		Button.new(zone, Rect(0,0,45,20))
			.states_([["save" ++ (i + 1)]])
			.action_({ 
				d[setname] = tdef.envir.current.copy; 
				setMinis.value;
			});
		
		minisliders = q.paramRNames.collect { |paramRname| 
			RangeSlider.new(zone, 45@8).enabled_(false);
		};
		setMinis = { 
			q.paramRNames.do { |paramRname, i| 
				var paramName = q.paramNames[i];
				var myrange = d[setname][paramRname];
				var unmapped = paramName.asSpec.unmap(myrange); 
				minisliders[i].lo_(unmapped[0]).hi_(unmapped[1]);
			} 
		};
		setMinis.value;
	};

/* 	Some extras: 
	a volume slider for simple mixing, 
	a popup menu for switching syndefnames; 
	a button to stop/start the skipjack for refreshing, 
	so one can use numberboxes to enter values.
*/
	EZSlider(w, 245@20, "vol", \amp, { |sl|tdef.set(\vol, sl.value) }, 
		0.25, false, 20, 36);

	StaticText.new(w, 55@20).string_("synthdef:").align_(\right); 
	PopUpMenu.new(w, Rect(0,0,80,20))
		.items_([\gab1st, \gabWide, \percSin, \percSinRev, \percNoise])
		.action_({ |pop| tdef.envir.synName = pop.items[pop.value] });
	
	Button.new(w, 80@20).states_([[\continuous], [\fadeStops]])
		.value_(tdef.envir.stopAfterFade.binaryValue)
		.action_({ |btn|
			tdef.set(\stopAfterFade, btn.value == 1)
		});

	Button.new(w, 80@20).states_([[\skipWatching], [\skipWaiting]])
		.action_({ |btn|
			[ { skipjack.play }, { skipjack.stop }][btn.value].value
		});

};
q.makeCloudGui(Tdef(\cloud0))
);





/////////////////////// Object Modeling code figures /////////////////// 



	// error and doesNotUnderstand
{ SinOsc.ar }.pay; 


q = ( ); 	
q[\melA] = [0, 2, 3];
q[\melA] + 10;

	// Equivalently, put and at operations can be written like getter and setter messages: 
q.melA_([0, 2, 3]); 	
	// Or also:
q.melA = [0, 2, 3];
q.melA + 7; 

	// One can organize repositories of objects hierarchically as well:
q.mels = ();
q.mels.melA = [0, 2, 3];

	// functions are special:
q.playMel = { |ev| Pbind(\note, Pseq(ev.melA), \dur, 0.2).play };
q.playMel;



	//	figure 8.1 - a Puppet class, and tests for it.
	
Puppet { 
	var <>myfreq; // an instance variable with a getter and a setter method
	
		// a method for creating a new object of this kind
	*new { |myfreq=50| ^super.new.myfreq_(myfreq) }
	
		// a simple method that uses 'myfreq' for something audible.
	blip { { Blip.ar(myfreq, 11) * XLine.kr(1, 0.01, 0.6, doneAction: 2) }.play; }
}

	// tests for the behavior implemented so far:
m = Puppet.new(50);// make an instance of Puppet, pass in myfreq

m.dump;			// test that myfreq is set correctly
m.myfreq;			// test accessing myfreq
m.blip;			// should sound
m.myfreq_(100);	// test setting myfreq
m.blip;		 // should sound differently







	// figure  8.2 - a puppet modeled as an event.

m = (); 			// make an empty event
m.myfreq_(50);	// put something in it with a setter method: a pseudo-instance variable
m.myfreq;			// look it up with a getter method
				// put a function into it with a setter: 
				// this becomes a pseudo-method
m.blip_({ |ev| { Blip.ar(ev.myfreq, 11) * XLine.kr(1, 0.01, 0.6, doneAction: 2) }.play; });
m.blip;		// execute the function with a pseudo-method call (same name)




	// figure  8.3 - add more instance variables, change the blip method.
(
m.numHarms_(20); 	// a new instvar
m.decay_(0.3); 	// and another
				// update the blip method to use them:
m.blip_({ |ev| 
	{ Blip.ar(ev.myfreq, ev.numHarms) 
	* XLine.kr(1, 0.01, ev.decay, doneAction: 2) }.play; 
});
)
m.blip;	// test





////////////////////// Shout Window ///////////////////////

	//	figure 8.4 - A minimal shout window sketch.

z = z ? (); 	// make an empty event as a pseudo-object
z.win = Window("Shout", Rect(0, 900,1200, 100)).front;
z.txtView = TextView(z.win, Rect(0, 0,1200, 100));
z.txtView.string_("Shout this!");
z.txtView.font_(Font("Monaco", 32));

	// tune appearances
z.win.alpha_(0.7);		// make the window slightly transparent
z.win.view.background_(Color.clear);	// make the window's top view,
z.txtView.background_(Color.clear);	// and textview fully transparent
z.win.alwaysOnTop_(true);	// make sure it is always on top .

z.win.close;	// close when done



	// figure 8.5 - add a pseudo-method.

(
z.makeWin = { |z, message="Shout this!"|
	z.win = Window("Shout", Rect(0, 900,1200, 100)).front;
	z.win.alpha_(0.7);	
	z.win.view.background_(Color.clear);	
	z.win.alwaysOnTop_(true);

	z.txtView = TextView(z.win, Rect(0, 0,1200, 100));
	z.txtView.string_(message);
	z.txtView.font_(GUI.font.new("Monaco", 32));
	z.txtView.background_(Color.clear);
};
)
z.makeWin; 
z.makeWin("Try showing that."); 





	// figure 8.6 - more pseudo-methods.

z.setMessage = { |z, str| z.txtView.string_(str) };

z.setMessage("Does this update?");	// test
(
z.shout = { |z, str|
	if (z.win.isNil or: { z.win.isClosed }) { z.makeWin };
	z.setMessage(str);
};
)
z.shout("Do we get this?"); // test

z.win.close;
z.shout("Do we get this too?"); // also when window has closed?





	// figure 8.7 - text color animation

z.txtView.stringColor_(Color.red);	// try a single color
(
z.animate = { |z, dt=0.2, n = 6| 
	var colors = [Color.red, Color.green, Color.black];
	Task { 
		n.do { |i|�
			dt.wait; 
			z.txtView.stringColor_(colors.wrapAt(i))
		}
	}.play(AppClock)
};
)
z.animate;			// test with default values 
z.animate(0.1, 24); 	// and test with arguments given





	// figure 8.8 is an image // 





	// figure 8.9 - using codeDump to shout 

this.codeDump = { |str, result, func| [str, result, func].printAll };

a = 1 + 2;	// code appears in post window

z.shoutTag = "//!!";
this.codeDump = { |str| if (str.beginsWith(z.shoutTag)) { z.shout(str.drop(z.shoutTag.size)) } };

//!! a comment with a 'shout tag' now gets shouted!





	//	figure 8.10 - updated setMessage flashes text.
(
z.setMessage = { |z, str| 
	var messSize = str.size; 
	var fontsize = (1.64 * z.txtView.bounds.width) / max(messSize, 32);
	z.txtView.font_(GUI.font.new("Monaco", fontsize));
	z.txtView.string_(str);
	z.animate;
};
)
//!! a long comment gets scaled down to a rather smaller font size, minimally fontsize 32! 

//!! short is big!
(
z.makeWin = { |q, message="Shout this!"|
	z.win = Window("Shout", Rect(0, 900,1200, 100)).front;
	z.win.alpha_(0.7);	
	z.win.view.background_(Color.clear);	
	z.win.alwaysOnTop_(true);

	z.txtView = TextView(z.win, Rect(0, 0,1200, 100));
	z.txtView.background_(Color.clear);
	z.setMessage(message);
};
)
z.makeWin("shout.");




	// class files can be put into one of these locations:
Platform.userExtensionDir; 
Platform.systemExtensionDir;


	//	figure 8.11 - a Shout class

// begin of file - Shout.sc
Shout {
	classvar <>tag="//!!";
	var <win, <txtView;
	
	*new { ^super.new }
} 
// end of file - Shout.sc

// tests: 
Shout.tag;
Shout.tag_("//SHOUT");

a = Shout.new; 
a.win;
a.txtView;




	// figure 8.12 - more class variables and initClass method.

// begin of file - Shout.sc
Shout {
	classvar <>tag="//!!", <>width=1250, <>defaultCodeDumpFunc; 
	var <win, <txtView;
	
	*initClass { 
		defaultCodeDumpFunc = { |str| if (str.beginsWith(tag)) { Shout(str.drop(tag.size)) } };
	}
	*new { ^super.new }
} 
// end of Shout.sc

Shout.width;
Shout.defaultCodeDumpFunc;




	// figure 8.13 - converting makeWin.

z.makeWin = { |message="Shout this!"|
	z.win = GUI.window.new("Shout", Rect(0, 900,1200, 100)).front;
	z.win.alpha_(0.7);	
	z.win.view.background_(Color.clear);	
	z.win.alwaysOnTop_(true);

	z.txtView = GUI.textView.new(z.win, Rect(0, 0,1200, 100));
	z.txtView.background_(Color.clear);
	z.setMessage(message);
};


Shout {	
	...
	*new { |message| ^super.new.makeWin(message); }
	
	makeWin { |message="Shout this!"| 
	
		win = Window("Shout'er", Rect(20, 800, width, 80)).front;
		win.alpha_(0.7);
		win.view.background_(Color.clear);
		win.alwaysOnTop_(true);
		
		txtView = TextView(win, win.bounds.moveTo(0,0));
		txtView.background_(Color.clear);
		txtView.font_(Font.new("Monaco", 32));
		this.setMessage(message);
	}

	setMessage { |message| 
		txtView.string_(message.asString)
	}
}

// tests:
Shout.new;
a = Shout.new("Blabla");
a.setMessage("Otto");






	//	figure 8.14 - converting z.shout to Shout.new.

z.shout = { |z, str|
	if (z.win.isNil or: { z.win.isClosed }) { z.makeWin };
	z.setMessage(str);
};

Shout { 
	classvar <top;
	...
	*new { |message="�Shout'er!"| 

		if (top.isNil or: { top.win.isClosed }) { 
			top = this.basicNew(message); 
		} {
			top.setMessage(message);
		};
	}
		// the method formerly known as *new
	*basicNew { |message="Shout this!"| ^super.new.makeWin(message) } 

	*close { try { top.win.close } }
	
	...
}

// tests: 
Shout("Test 1, 2");
Shout("Test 1, 2, 3, 4");	// same window
Shout.close;

Shout("Test 1, 2");		// new window




	//	figure 8.15 - converting animate to a class method.

z.animate = { |z, dt=0.2, n = 6| 
	var colors = [Color.red, Color.green, Color.black];
	Task { 
		n.do { |i|�
			dt.wait; 
			z.txtView.stringColor_(colors.wrapAt(i))
		}
	}.play(AppClock)
};

Shout { 
	...
	animate { |dt=0.2, n=6|
		var colors = [Color.red, Color.green, Color.black]; 
		Task { 
			n.do { |i| 
				txtView.stringColor_(colors.wrapAt(i)); 
				dt.wait 
			};
			txtView.stringColor_(Color.black); // make sure we end black
		}.play(AppClock);
	}
	...	
}

// tests: 
a = Shout("Test 1, 2");
Shout.top.animate;



 
	// figure 8.16 - converting setMessage

z.setMessage = { |z, str| 
	var messSize = str.size; 
	var fontsize = (1.64 * z.txtView.bounds.width) / max(messSize, 32);
	z.txtView.font_(GUI.font.new("Monaco", fontsize));
	z.txtView.string_(str);
	z.animate;
};

Shout { 
	...
	setMessage { |message| 
		var messSize, fontSize;
		messSize = message.size;
		fontSize = (1.64 * width) / max(messSize, 32);
		
		defer { 
			txtView.font_(Font("Monaco", fontSize))
				.string_(message.asString);
		};
		this.animate;
	}
	...	
}

Shout("Test 1, 2");
Shout("Test" + (1..16));





	//	figure 8.17 - codeDump tests and usage in Shout

this.codeDump.postcs;	// anything there yet? by default, this is nil.
this.codeDump = this.codeDump.addFunc(Shout.defaultCodeDumpFunc); // add Shout
this.codeDump.postcs	// should be there now
//!! test whether Shout works now
this.codeDump = this.codeDump.removeFunc(Shout.defaultCodeDumpFunc);
this.codeDump.postcs	// should be gone now

//!! should be off again

Shout { 
	...
	*add { var interp = thisProcess.interpreter; 
		interp.codeDump = interp.codeDump
			.removeFunc(defaultCodeDumpFunc) // remove it first so it will 
										// only be in the list once
			.addFunc(defaultCodeDumpFunc); 
	}
	*remove { var interp = thisProcess.interpreter; 
		interp.codeDump = interp.codeDump.removeFunc(defaultCodeDumpFunc); 
	}
	...	
}

// tests
Shout.add;
//!! test whether Shout works now - it should!
Shout.remove;
//!! test whether Shout works now - should be off.




	//	figure 8.18 - keeping Shout out of the way

Shout.close;
Shout("blabla");	// now typing is impossible, because the new window is in front.

Shout("blabla blabla");	// now one can type, because Shout window was already there.
Shout.close; 

	// this does not work, because the shout window gets put in front later:
d = Document.current; Shout(\bla); d.front; 
 

	// This can be wrapped around the call to this.makeWin in Shout:new:
Shout { 
	...
	*new { |message="�Shout'er!"| 
		var currDoc;

		if (win.isNil or: { win.isClosed }) { 
			currDoc = Document.current;
			top = this.basicNew(message); 
				// wait a little before restoring front window
			defer ({ currDoc.front }, 0.1);
		} {
			top.setMessage(message);
		};
	}
	...	
}



///////////////////////////////// QCD /////////////////////////


	// no figure - converting QCD data files (text) to soundfiles.
(
q = q ? ();
q.data = "~/data/share/QCD/data/*.nojunk".pathMatch.collect{|path|
	a = FileReader.read((path), true, true, _.asFloat * 0.03125 ).flat.as(Signal);
	b = SoundFile.new;
	b.openWrite(path.replace("txt.nojunk", "aiff"));
	b.writeData(a).postln;
	b.close; 
	a;	
}
)




	// figure 8.19 - a fixed serialization method.

serialize {|index, pos, extent = 8|
	var ranges, slice;

	// get ranges
	ranges = pos.collect{|pos, i| 
		((pos-(extent*0.5))..(pos+(extent*0.5)-1)) % this.shape[i] 
	};
	// get sub-slice
	slice = this.slice(index, *ranges);
	// trivial serialization of multidim. slice
	^slice.flat
}



	// figure 8.20 - flexible  serialization by lookup.

serialize {|index, pos, extent = 8, how = \hilbert|
	// [...]
	slice = this.slice(index, *ranges);
	// call function in serTypes dictionary
	^serTypes[how].(slice.asArray, extent)
}




// figure 8.21 here � some initial serialization methods, and adding an alternative. 

	*initClass {|numDims = 4|
		...
		// slice here is a 4d hypercube of extent <extent>
		serTypes = (
			hilbert: {|slice, extent|
				extent.isPowerOfTwo.not.if({
					"QCD:serialize: extent has to be a power of two".error
				});
				HilbertIndices.serialize(slice)
			},
			torus: {|slice, extent|
				slice.flat;
			},
			scramble: {|slice|
				slice.flat.scramble;
			}
		);
	}

	// add a new serialization type at runtime
QCD.serTypes.put(\star, {|slice|
	var starSize = slice.size div:2;
	var numDims = 4;
	var starShape;

	starShape = neighbours1.collect({ |nb|  
		(0..starSize).collect(_ * nb) 
	}).flatten(1).collect {|indexN| 
		indexN + (starSize.div(2)+1).dup(numDims) 
	};
	
	starShape.collect{|iA| slice.slice(*iA)}
});





///////// continued in ObjMod2_CloudGenMini.scd ///// 




// CloudGenMini is based on CloudGenerator, a granular synthesis program 
// by Curtis Roads and John Alexander. 
// This partial miniature version was implemented by Alberto de Campo, 2007. 




	// figure 8.23 - some granular synthdefs and tests
(
	// a gabor (approx. gaussian-shaped) grain
SynthDef(\gab1st, { |out, amp=0.1, freq=440, sustain=0.01, pan| 
	var snd = FSinOsc.ar(freq);
	var env = EnvGen.ar(Env.sine(sustain, amp * AmpComp.ir(freq) * 0.5), doneAction: 2);
	OffsetOut.ar(out, Pan2.ar(snd * env, pan));
}, \ir ! 5).memStore;

			// wider, quasi-gaussian envelope, with a hold time in the middle. 
SynthDef(\gabWide, { |out, amp=0.1, freq=440, sustain=0.01, pan, width=0.5| 
	var holdT = sustain * width;
	var fadeT = 1 - width * sustain * 0.5;
	var snd = FSinOsc.ar(freq);
	var env = EnvGen.ar(Env([0, 1, 1, 0], [fadeT, holdT, fadeT], \sin), 
		levelScale: amp * AmpComp.ir(freq) * 0.5, 
		doneAction: 2);
	OffsetOut.ar(out, Pan2.ar(snd * env, pan));
}, \ir ! 5).memStore;

			// a simple percussive envelope
SynthDef(\percSin, { |out, amp=0.1, freq=440, sustain=0.01, pan| 
	var snd = FSinOsc.ar(freq);
	var env = EnvGen.ar(
		Env.perc(0.1, 0.9, amp * AmpComp.ir(freq) * 0.5), 
			timeScale: sustain, doneAction: 2
		);
	OffsetOut.ar(out, Pan2.ar(snd * env, pan));
}, \ir ! 5).memStore;

			// a reversed  percussive envelope
SynthDef(\percSinRev, { |out, amp=0.1, freq=440, sustain=0.01, pan| 
	var snd = FSinOsc.ar(freq);
	var env = EnvGen.ar(
		Env.perc(0.9, 0.1, amp * AmpComp.ir(freq) * 0.5, 4), 
			timeScale: sustain, doneAction: 2
		);
	OffsetOut.ar(out, Pan2.ar(snd * env, pan));
}, \ir ! 5).memStore;

		// a noise band grain with percussive envelope
SynthDef(\percNoise, { |out, amp=0.2, freq=440, sustain=0.01, pan, rq=0.1| 
	var snd = BPF.ar(GrayNoise.ar, freq, rq, 3);
	var env = EnvGen.ar(Env.perc, timeScale: sustain, doneAction: 2);
	OffsetOut.ar(out, 
		Pan2.ar(snd * env, pan, amp)
	);
}, \ir ! 6).memStore

/*	
	// tests for the synthdefs:
Synth(\gab1st);
Synth(\gabWide);
Synth(\percSin);
Synth(\percSinRev);

Synth(\percSin, [\amp, 0.2, \sustain, 0.1]);
Synth(\percNoise, [\amp, 0.2, \sustain, 0.1]);

Synth(\gab1st, [\out, 0, \amp, 0.2, \freq, 2000, \sustain, 0.05, \pan, 0.5] );
*/
);





	// figure 8.24 - global setup and a player Tdef for the cloud.
(
q = q ? (); 

	// some globals
q.paramRNames = [\freqRange, \durRange, \densRange, \ampRange, \panRange]; 
q.paramNames = [\freq, \grDur, \dens, \amp, \pan]; 
q.syndefNames = [\gab1st, \gabWide, \percSin, \percSinRev, \percNoise];

	// specs for some parameters
Spec.add(\xfadeTime, [0.001, 1000, \exp]);
Spec.add(\ring, [0.03, 30, \exp]);
Spec.add(\grDur, [0.0001, 1, \exp]);
Spec.add(\dens, [1, 1000, \exp]);

	// make an empty tdef that plays it, 
	// and put the cloud parameter ranges in the tdef's environment
Tdef(\cloud0)
	.set(
	\synName, \gab1st,
	\vol, 0.25,
	\current, (
		freqRange: [200, 2000],
		ampRange: [0.1, 1],
		durRange: [0.001, 0.01], 
		densRange: [1, 1000],
		panRange: [-1.0, 1.0] 
	)
); 
		
		// make the tdef that plays the cloud of sound particles here, 
		// based on parameter range settings.
Tdef(\cloud0, { |e| 

	loop {
		s.sendBundle(s.latency, [
			"/s_new", e.synName ? \gab1st, 
			-1, 0, 0,
			\freq, 	exprand(e.current.freqRange[0], e.current.freqRange[1]),
			\amp,	exprand(e.current.ampRange[0], e.current.ampRange[1]) * e.vol,
			\sustain,	exprand(e.current.durRange[0], e.current.durRange[1]),
			\pan, 	rrand(e.current.panRange[0], e.current.panRange[1])
		]);
		exprand(e.current.densRange[0].reciprocal, e.current.densRange[1].reciprocal).wait; 
	}
}).quant_(0);	
);




/*
	// figure  8.25	-  tests for the cloud
	
Tdef(\cloud0).play;

	// try changing various things from outside the loop. 
	// change its playing settings 

Tdef(\cloud0).envir.current.put('densRange', [ 50, 200 ]); // dense, async
Tdef(\cloud0).envir.current.put('densRange', [ 1, 10 ]);  // sparse, async
Tdef(\cloud0).envir.current.put('densRange', [ 30, 30 ]); // synchronous

	// for faster access, call the tdef's envir d
d = Tdef(\cloud0).envir;
d.current.put('freqRange', [ 800, 1200 ]);
d.current.put('durRange', [ 0.02, 0.02 ]);

d.current.put('ampRange', [ 0.1, 0.1 ]);

d.current.put('panRange', [ 1.0, 1.0 ]);
d.current.put('panRange', [ -1.0, 1.0 ]);

d.current.put('densRange', [ 30, 60 ]);
d.synName = \percSin;
d.synName = \gab1st;
d.synName = \gabWide;
d.synName = \percSinRev;
d.synName = \percNoise;
d.synName = \percSinRev;
d.synName = \gab1st;
d.current.put('durRange', [ 0.001, 0.08 ]);


*/




	// figure 8.26 - making random settings, and 8 random presets to switch between
(
	// make the Tdef's envir a global variable for easier experimenting
d = Tdef(\cloud0).envir;
	// a pseudo-method to make random settings, kept in the Tdef's environment
		// randomize could also do limited variation on existing setting. 
d.randSet = { |d|
	var randSet = ();	
	q.paramRNames.do { |pName, i| 
		randSet.put(pName, 
			q.paramNames[i].asSpec.map([1.0.rand, 1.0.rand].sort)
		);
	};
	randSet;
};

/* 	test randSet: 
d.current = d.randSet;
*/

// make 8 sets of parameter range settings: 
d.setNames = (1..8).collect { |i| ("set" ++ i).asSymbol };
d.setNames.do { |key| d[key] = d.randSet; }

/*	test switching to the random presets
d.current = d.set1.copy;	// copy to avoid writing into a stored setting when it is current.
d.current = d.set3.copy;	
d.current = d.set8.copy;
*/
);




	// ex. 8.27 - crossfading between different settings with a taskproxy
	
(
	// and some parameters for controlling the fade
d.stopAfterFade = false;
d.xfadeTime = 5; 

d.morphtask = TaskProxy({
	var startSet = d[\current], endSet = d[\target];
	var stepsPerSec = 20;
	var numSteps = d.xfadeTime * stepsPerSec;
	var blendVal, morphSettings;
	
	if (d.target.notNil) { 
		(numSteps).do { |i| 
		//	["numSteps", i].postln;
			blendVal = (i + 1) / numSteps; 
			morphSettings = endSet.collect({ |val, key| 
				(startSet[key] ? val).blend(val, blendVal) 
			});
			d.current_(morphSettings);
			(1/stepsPerSec).wait;
		};
		d.current_(d.target.copy);
		"morph done.".postln;
		if (d.stopAfterFade) { Tdef(\cloud0).stop; };
	};
}).quant_(0);		// no quantization so the task starts immediately

/* test morphing
(
Tdef(\cloud0).play;
d.target = d.set6.copy;
d.morphtask.play;
)
Tdef(\cloud0).stop;

	// playing a a finite cloud with tendency mask: 
(
Tdef(\cloud0).play;		// begin playing
d.stopAfterFade = true; 	// end cloud when crossfade ends
d.xfadeTime = 10; 			// set fade time
d.target = d.set8.copy;		// and target
d.morphtask.play;			// and start crossfade.
)
*/

	// put fading into its own method, with optional stop.
d.fadeTo = { |d, start, end, time, autoStop| 
	d.current = d[start] ? d.current;
	d.target = d[end]; 
	d.xfadeTime = time ? d.xfadeTime;
	if (autoStop.notNil) { d.stopAfterFade = autoStop };
	d.morphtask.stop.play;
};

/* 	// tests fadeTo:
Tdef(\cloud0).play;
d.fadeTo(\current, \set2, 20);
d.fadeTo(\current, \set6, 10);
d.fadeTo(\current, \set5, 3, true);

Tdef(\cloud0).play;
d.fadeTo(\current, \set1, 3, false);
*/ 
);



	// figure 8.28 is an image, the CloudGenMini GUI //




	// figure 8.29 - a lightweight graphical user interface for CloudGenMini 
(
q.makeCloudGui = { |q, tdef, posPoint| 
	var w, ezRangers, fdBox; 
	var setMinis, skipjack; 
	
	posPoint = posPoint ? 400@400;	// where to put the gui window
	
	w = Window.new("CloudGen_mini_sc3", 
		Rect.fromPoints(posPoint, (posPoint + (400@300)))).front;
	w.view.decorator_(FlowLayout(w.bounds.copy.moveTo(0, 0)));
		
	w.view.decorator.nextLine; 
		// the range sliders display the current values
	ezRangers = ();
	
	q.paramRNames.do { |name, i| 
		ezRangers.put(name, 
		EZRanger(w, 400@20, name, q.paramNames[i], 
			{ |sl| tdef.envir.current[name] = sl.value; }, 
			tdef.envir.current[name], labelWidth: 70, numberWidth: 50, unitWidth: 10)
			.round_([0.1, 0.00001, 0.0001, 0.0001, 0.01][i])
		);
	};
		// a just in time - gui for the Tdef
	TdefEditor(tdef, height: 20, w: w); 
	
	Button.new(w, 80@20).states_([[\randomize]])
		.action_({ 
			tdef.envir.target_(d.randSet);
			tdef.envir.morphtask.stop.play;
		});
	
	fdBox = EZNumber.new(w, 110@20, \xFadeTime, [0, 100, \amp], 
		{ |nbx| tdef.envir.xfadeTime = nbx.value }, 
		 tdef.envir.xfadeTime, false, 65); 

			// skipjack is a task that survives cmd-period:
			// used here for lazy-updating the control views.
	skipjack = SkipJack({  
		q.paramRNames.do { |name| ezRangers[name].value_(tdef.envir.current[name]) };
		fdBox.value_(tdef.envir.xfadeTime); 
		
		// mark last settings that were used by color? 
		// a separate color when changed? 
		
	}, 0.5, { w.isClosed }, name: tdef.key);
	
	w.view.decorator.nextLine;

	// make a new layoutView for the 8 presets; 
	// put button to switch to that preset, 
	// a button to save current settings to that place, 
	// and a miniview of the settings as a visual reminder in it.
	
		// make 8 setButtons
	tdef.envir.setNames.do { |setname, i|	
		var minisliders, setMinis;
		var zone = CompositeView.new(w, Rect(0,0,45, 84));
		zone.decorator = FlowLayout(zone.bounds, 0@0, 5@0); 
		zone.background_(Color.white); 
		
		Button.new(zone, Rect(0,0,45,20)).states_([[setname]])
			.action_({ 
				// just switch: // tdef.envir.current.putAll(d[setname] ? ()) 
				tdef.envir.target = tdef.envir[setname];
				tdef.envir.morphtask.stop.play;
			});
		
		Button.new(zone, Rect(0,0,45,20))
			.states_([["save" ++ (i + 1)]])
			.action_({ 
				d[setname] = tdef.envir.current.copy; 
				setMinis.value;
			});
		
		minisliders = q.paramRNames.collect { |paramRname| 
			RangeSlider.new(zone, 45@8).enabled_(false);
		};
		setMinis = { 
			q.paramRNames.do { |paramRname, i| 
				var paramName = q.paramNames[i];
				var myrange = d[setname][paramRname];
				var unmapped = paramName.asSpec.unmap(myrange); 
				minisliders[i].lo_(unmapped[0]).hi_(unmapped[1]);
			} 
		};
		setMinis.value;
	};

/* 	Some extras: 
	a volume slider for simple mixing, 
	a popup menu for switching syndefnames; 
	a button to stop/start the skipjack for refreshing, 
	so one can use numberboxes to enter values.
*/
	EZSlider(w, 245@20, "vol", \amp, { |sl|tdef.set(\vol, sl.value) }, 
		0.25, false, 20, 36);

	StaticText.new(w, 55@20).string_("synthdef:").align_(\right); 
	PopUpMenu.new(w, Rect(0,0,80,20))
		.items_([\gab1st, \gabWide, \percSin, \percSinRev, \percNoise])
		.action_({ |pop| tdef.envir.synName = pop.items[pop.value] });
	
	Button.new(w, 80@20).states_([[\continuous], [\fadeStops]])
		.value_(tdef.envir.stopAfterFade.binaryValue)
		.action_({ |btn|
			tdef.set(\stopAfterFade, btn.value == 1)
		});

	Button.new(w, 80@20).states_([[\skipWatching], [\skipWaiting]])
		.action_({ |btn|
			[ { skipjack.play }, { skipjack.stop }][btn.value].value
		});

};
q.makeCloudGui(Tdef(\cloud0))
);




﻿1.1 Additive synthesis example

play({
	var sines = 5, speed = 6;
	Mix.fill(sines, 
		{arg x; 
			Pan2.ar(
				SinOsc.ar(x+1*100, 
					mul: max(0, 
						LFNoise1.kr(speed) +
						Line.kr(1, -1, 30)
					)
				), rand2(1.0))})/sines})



﻿1.2 Nested Commands for Fortuitous Robot

serve(
	toss(
		wash(lettuce, water, 10),
		dice(tomato, small),
		sprinkle(choose([blue, feta, gouda]))
	),
	bake(catch(lagoon, hook, bamboo), 400, 20),
	mix(
		slice(peel(banana), 20),
		cook(mix(milk, sugar, starch), 200, 10)
	)
)		





﻿1.3 Forbidden Planet 

(
play(
	{
		CombN.ar(
			SinOsc.ar(
				midicps(
					LFNoise1.ar(3, 24, 
						LFSaw.ar([5, 5.123], 0, 3, 80)
					)
				), 
				0, 0.4), 
			1, 0.3, 2)
	}
)
)





﻿1.4 VCO, VCF, VCA

(
{
	Blip.ar(
		TRand.kr( // frequency or VCO
			100, 1000, // range
			Impulse.kr(Line.kr(1, 20, 60))), // trigger
		TRand.kr( // number of harmonics or VCF
			1, 10, // range
			Impulse.kr(Line.kr(1, 20, 60))), // trigger
		Linen.kr( // mul, or amplitude, VCA
			Impulse.kr(Line.kr(1, 20, 60)), // trigger
			0, // attack
			0.5, // sustain level
			1/Line.kr(1, 20, 60)) // trigger
		)
}.play
)





﻿1.5 Variables

(
// run this first
p = { // make p equal to this function
r = Line.kr(1, 20, 60); // rate
// r = LFTri.kr(1/10) * 3 + 7;
t = Impulse.kr(r); // trigger
// t = Dust.kr(r);
e = Linen.kr(t, 0, 0.5, 1/r); // envelope uses r and t
f = TRand.kr(1, 10, t); // triggered random also uses t
// f = e + 1 * 4;
Blip.ar(f*100, f, e) // f, and e used in Blip
}.play
)

p.free;  // run this to stop it




﻿1.6 Phase Modulation With Modulator as Ratio

(
{ // carrier and modulator not linked
	r = Impulse.kr(10);
	c = TRand.kr(100, 5000, r);
	m = TRand.kr(100, 5000, r);
	PMOsc.ar(c, m, 12)*0.3
}.play
)
 
(
{
	var rate = 4, carrier, modRatio; // declare variables
	carrier = LFNoise0.kr(rate) * 500 + 700;
	modRatio = MouseX.kr(1, 2.0);
	// modulator expressed as ratio, therefore timbre
	PMOsc.ar(carrier, carrier*modRatio, 12)*0.3
}.play
)
 




﻿1.7 Synth Definition

(
//run this first
SynthDef("PMCrotale", {
arg midi = 60, tone = 3, art = 1, amp = 0.8, pan = 0; 
var env, out, mod, freq;

freq = midi.midicps;
env = Env.perc(0, art);
mod = 5 + (1/IRand(2, 6));

out = PMOsc.ar(freq, mod*freq, 
	pmindex: EnvGen.kr(env, timeScale: art, levelScale: tone), 
	mul: EnvGen.kr(env, timeScale: art, levelScale: 0.3));

out = Pan2.ar(out, pan);

out = out * EnvGen.kr(env, timeScale: 1.3*art, 
	levelScale: Rand(0.1, 0.5), doneAction:2);  
Out.ar(0, out); //Out.ar(bus, out);

}).add;
)

//Then run this a bunch of times:

Synth("PMCrotale", ["midi", rrand(48, 72).round(1), "tone", rrand(1, 6)])


﻿1.8 Playback Buffers

[~houston.bufnum, ~houston.numChannels, ~houston.path, ~houston.numFrames];

[~chooston.bufnum, ~chooston.numChannels, ~chooston.path, ~chooston.numFrames];

(  // phasing
{
	var rate, trigger, frames;
	frames = ~houston.numFrames; // or use ~chooston.numFrames

	rate = [1, 1.01];
	trigger = Impulse.kr(rate);
	PlayBuf.ar(1, ~houston, 1, trigger, frames * Line.kr(0, 1, 60)) * 
	EnvGen.kr(Env.linen(0.01, 0.96, 0.01), trigger) * rate;
}.play;
)




﻿1.9 Connecting controls with a bus

 (
// if these haven't been used they will hold 0
~kbus1 = Bus.control; // a control bus
~kbus2 = Bus.control; // a control bus
{
	var speed, direction;
	speed = In.kr(~kbus1, 1) * 0.2 + 1;
	direction = In.kr(~kbus2);
	PlayBuf.ar(1, ~chooston, (speed * direction), loop: 1);
}.play;
)
(
// now start the controls
{Out.kr(~kbus1, LFNoise0.kr(12))}.play;

{Out.kr(~kbus2, LFClipNoise.kr(1/4))}.play;
)
// Now start the second buffer with the same control input buses, 
// but send it to the right channel using Out.ar(1 etc.

(
{
	var speed, direction;
	speed = In.kr(~kbus1, 1) * 0.2 + 1;
	direction = In.kr(~kbus2);
	Out.ar(1, PlayBuf.ar(1, ~houston, (speed * direction), loop: 1));
}.play;
)



﻿1.10 Buffer Modulation

(
{
	Out.ar(0,
		Pan2.ar( PlayBuf.ar(1, ~houston, loop: 1) * 
			SinOsc.ar(LFNoise0.kr(12, mul: 500, add: 600)),
		0.5)
	)
}.play
)

(
{
var source, delay; 
	source = PlayBuf.ar(1, ~chooston, loop: 1);
	delay =  AllpassC.ar(source, 2, [0.65, 1.15], 10);
	Out.ar(0,
	Pan2.ar(source) + delay
	)
}.play
)





﻿1.11 FX Routing using Buses

// Create and name buses 
~delay = Bus.audio(s, 2);
~mod = Bus.audio(s, 2);
~gate = Bus.audio(s, 2);
~k5 = Bus.control;

~controlSyn= {Out.kr(~k5, LFNoise0.kr(4))}.play; // start the control

// Start the last item in the chain, the delay
~delaySyn = {Out.ar(0, AllpassC.ar(In.ar(~delay, 2), 2, [0.65, 1.15], 10))}.play(~controlSyn, addAction: \addAfter) 

// Start the next to last item, the modulation
~modSyn = {Out.ar(~delay, In.ar(~mod, 2) * SinOsc.ar(In.kr(~k5)*500 + 1100))}.play(~delaySyn, addAction: \addBefore);

// Start the third to last item, the gate
~gateSyn = {Out.ar([0, ~mod], In.ar(~gate, 2) * max(0, In.kr(~k5)))}.play(~modSyn, addAction: \addBefore);

// make a group for the PlayBuf synths at the head of the chain
~pbGroup = Group.before(~controlSyn);

// Start one buffer. Since we add to the group, we know where it will go
{Out.ar(~gate, Pan2.ar(PlayBuf.ar(1, ~houston, loop: 1), 0.5))}.play(~pbGroup);

// Start the other
{Out.ar(~gate, Pan2.ar(PlayBuf.ar(1, ~chooston, loop: 1), -0.5))}.play(~pbGroup);





﻿1.12 Random MIDI Walk

Task({
a = ["C", "C#", "D",  "Eb", "E", "F", "F#", "G", "Ab", "A", "Bb", "B"];
"count, midi, pitch, octave".postln;
	do(50, {arg count;
		p = rrand(36, 72);
		[count, p, a.wrapAt(p), (p/12).round(1) - 1].postln;
	1.wait;
	})
}).play



﻿1.13 Random Crotale Walk

// This uses the PMCrotale synth definition
(
a = ["C", "C#", "D",  "Eb", "E", "F", "F#", "G", "Ab", "A", "Bb", "B"];
"event, midi, pitch, octave".postln;
r = Task({
	inf.do({ arg count;
		var midi, oct, density;
		density = 1.0; // 100% of the time. Uncomment below for 70%, etc.
		// density = 0.7; 
		// density = 0.3;
		midi = [0, 2, 4, 7, 9].choose;
		// midi = [0, 2, 4, 5, 7, 9, 11].choose;
		// midi = [0, 2, 3, 5, 6, 8, 9, 11] .choose; 
		// midi = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] .choose;
		oct = [48, 60, 72].choose;
		if(density.coin, 
			{ // true action
				"".postln;
				[midi + oct, a.wrapAt(midi), 
				(oct/12).round(1)].post;
				Synth("PMCrotale", 
					["midi", midi + oct, "tone", rrand(1, 7), 
					"art", rrand(0.3, 2.0), "amp", rrand(0.3, 0.6), "pan", 1.0.rand2]);
			}, {["rest"].post}); // false action
		0.2.wait; 
	}); 
}).start
)

r.stop; // run this to stop



﻿1.14 Nested do to Generate a 12-Tone Matrix

(
var row, inversion, pitchClass;
row = Array.series(11, 1).scramble.insert(0, 0); 
// or enter your own row, e.g. Webern's Op 27
// row = [0, 11, 8, 2, 1, 7, 9, 10, 4, 3, 5, 6]; 
row.postln;
inversion = 12 - row;
// I add spaces to the strings for a tidy row
pitchClass = ["C  ", "C# ", "D  ", "Eb ", 
	"E  ", "F  ", "F# ", "G  ", "Ab ", "A  ", "Bb ", "B  "];
inversion.do({arg eachInv;
	var trans;
	trans = (row + eachInv); 
	// prints just pitch class
	trans.do({arg scaleDegree; pitchClass.wrapAt(scaleDegree).post});
	//"".postln; // uncomment these line if you want to do both
	// prints just numbers
	//trans.do({arg scaleDegree; (scaleDegree%12).post; " ".post});
	"".postln;
	});
"".postln
)



﻿1.15 Additive Synthesis Examples

// Mix down a few of them tuned to harmonics:

(
{
var fund = 220;
Mix.ar(
	[
	SinOsc.ar(220, mul: max(0, LFNoise1.kr(12))),
	SinOsc.ar(440, mul: max(0, LFNoise1.kr(12)))*1/2,
	SinOsc.ar(660, mul: max(0, LFNoise1.kr(12)))*1/3,
	SinOsc.ar(880, mul: max(0, LFNoise1.kr(12)))*1/4,
	SinOsc.ar(1110, mul: max(0, LFNoise1.kr(12)))*1/5,
	SinOsc.ar(1320, mul: max(0, LFNoise1.kr(12)))*1/6
	]
)*0.3
}.play
)



﻿1.16 Additive Synthesis Example

// Try this first
Array.fill(20, {arg cnt; cnt + 1*110}); // harmonics built on 110

// And a patch
(
{Mix.ar(
	Array.fill(12, 
		{arg count; 
		var harm;
		harm = count + 1 * 110; // remember precedence; count + 1, then * 110
			SinOsc.ar(harm, 
				mul: max([0, 0], SinOsc.kr(count+1/4))
				)*1/(count+1)
		})
)*0.7}.play
)



﻿1.18 Physically Modeled Bells
// Try this first, to illustrate the array of arrays.
Array.fill(3, {Array.fill(10, {rand(1000)})})	
// Then this patch.
(
{
var scale, specs, freqs, amps, rings, 
	numRes = 5, bells = 20, pan; 
scale = [60, 62, 64, 67, 69].midicps;
	Mix.fill(bells, {
		freqs = Array.fill(numRes, {rrand(1, 15)*(scale.choose)});
		amps = Array.fill(numRes, {rrand(0.3, 0.9)});
		rings = Array.fill(numRes, {rrand(1.0, 4.0)});
		specs = [freqs, amps, rings].round(0.01);
		// specs.postln;
		pan = (LFNoise1.kr(rrand(3, 6))*2).softclip;
		Pan2.ar( 
			Klank.ar(`specs, 
				Dust.ar(1/6, 0.03)), 
				pan)
	})
}.play;
) 



﻿1.19 Generative Sequences using Arrays

( // first define the synth

SynthDef.new("SimpleBlip", { 
arg midi = 60, tone = 10, art = 0.125, amp = 0.2, pan = -1;
var out, temper;	
out =	Pan2.ar(
			Blip.ar( // play the sequence
				midi.midicps,
				tone
				) * EnvGen.kr(Env.perc(0.01, art)),
		pan // pan left, center, or right
	);
DetectSilence.ar(out, doneAction:2);
amp = amp - ((midi - 60) * 0.02);
Out.ar(0, out*amp)
	}).add;
)
 
(
// Then run this Task
~inst = [0, 0, 0]; // Three containers for tasks
~pSeq = [0, 0, 0]; // Three containers for sequences
~scaleAdd = [4, 5, 11, nil, 10, 3, 6, nil]; // 
~notes = 
[" C", " C#", " D", " Eb", " E", " F", 
	" F#", " G", " Ab", " A", " Bb", " B"]; 
~rout = Task({
	inf.do({
		arg cnt1; 
		var steps, durSeq, harmSeq;
		steps = rrand(6, 12);
		if(cnt1%6 == 0, // every sixth iteration, add a degree
			{~scale = ~scale.add(~scaleAdd.wrapAt((cnt1/6).round(1) - 1));}); 
		"\nIteration: ".post; cnt1.post; 
		[" (center) ", " (right) ", " (left) "].wrapAt(cnt1).postln;
		if(cnt1%24 == 0, // reset all three
			{~scale = [0, 2, 7, 9]; 
			3.do({arg cnt2; 
				~pSeq.wrapPut(cnt2, 
					Array.fill(steps, 
						{~scale.choose + [48, 60].choose}))})});
		"scale: ".post; ~scale.postln;
		~pSeq.wrapPut(cnt1, // fill array with scale steps
			Array.fill(steps, {~scale.choose + [48, 60].choose}));
		"MIDI seq: ".post; (~pSeq.wrapAt(cnt1)%12).postln;
		"Sequence (notes): ".post; 
		~pSeq.wrapAt(cnt1).do( // print the sequence using note names
			{arg thisItem; ~notes.at(thisItem%12).post}); 
		"".postln;
		// create harmonic and duration arrays
		harmSeq = Array.fill(steps, {rrand(1.0, 5.0)});
		durSeq = Array.fill(steps - 1, {rrand(0.01, 0.9)});
		// stop the previous task at this array position
		~inst.wrapAt(cnt1).stop;
		~inst.wrapPut(cnt1, 
			Task({
				inf.do({arg cnt3; // each sequence
					Synth("SimpleBlip", 
						[\midi, ~pSeq.wrapAt(cnt1).wrapAt(cnt3), 
						\tone, harmSeq.wrapAt(cnt3), 
						\art, durSeq.wrapAt(cnt3), 
						\amp, rrand(0.1, 0.3), 
						\pan, cnt1.wrap(-1, 2)]);
					0.125.wait; // tempo of each note
				})}).start;
		);
		12.wait;})
}).start; // time between each new sequence
)

~rout.stop; // stop new sequences
~inst.at(0).stop; // at any time, stop center sequence
~inst.at(1).stop; // stop right sequence
~inst.at(2).stop; // stop center sequence



﻿1.20 Offset and Scale

(
	{
	var trigger, wave, label, scale, offset;
	trigger = Impulse.kr(10);
	wave = SinOsc.kr(1/10) ; // change to 400
	scale = 1; offset = 0;
//	wave = wave * scale + offset; 
	label = "scale = " ++ scale.asString ++ ", offset = " ++ offset.asString;
	wave.round(0.01).poll(label: label);
	}.scope(1)
)
 



﻿1.21 SinOsc Offset and Scaled for Control

(
	{
	var trigger, control, scale, offset;
	scale = 300; // try other values, but not greater than offset
	offset = 600; // try other values
	trigger = Impulse.kr(10);
	control = SinOsc.ar(1/4).scope("control"); // LFO
	control = control  * scale + offset;
	SinOsc.ar(freq: abs(control).poll).scope("audio")
	}.play
) 

// Speaking of vibrato, I can't resist this faux Theremin: 

{SinOsc.ar(SinOsc.ar(8, 0, 10, MouseX.kr(440, 1760, 1)))}.play




﻿1.22 Test Your Skills

(
{
	var carrier, rate, trigger, modRatio, index, control, env;
	rate = 3;
	trigger = Impulse.kr(rate);
	control = LFNoise0.kr(rate);
	carrier = 62;
	modRatio = 4.125;
	index = 10;
	carrier = carrier.midicps;
	carrier.poll(trigger, "carrier"); 
	index.poll(trigger, "index"); 
	modRatio.poll(trigger, "modRatio");
	PMOsc.ar(carrier, carrier*modRatio, index)
}.play
)




﻿1.23 PMOsc With Offset and Scale

(
a = SynthDef("PMOsc_ex", 
{
	arg left = 10, right = 10, indexLow = 4, indexHigh = 12;
	var pitch, timbre, trigger, env, index, out;
	trigger = Impulse.kr([left, right]); // trigger
	pitch = TRand.kr(36, 72, trigger).round(1); // C2 to C6
	timbre = LFNoise0.kr(1/20, mul: 0.2, add: 2); // mod control
	env = Linen.kr(trigger, releaseTime: 1/[left, right]); // envelope
	index = env * indexHigh + indexLow; // env scaled and offset for index
	pitch = pitch.midicps; // midi converted to freq
	out = PMOsc.ar(pitch, pitch*timbre, index, mul: env);
	Out.ar(0, out);
}).play
)

a.set("left", 4)

a.set("right", 5)

a.set("indexLow", 1)

a.set("indexHigh", 4)



﻿1.24 PMOsc With Sample and Hold (Latch) 

(
// run this first
a = SynthDef("Latch_demo",
{
arg rate = 9; 
var freq, latchrate, index, ratio, env, out;
latchrate = rate*LFNoise0.kr(1/10, mul: 0.03, add: 1.6);
index = Latch.kr(
	LFSaw.kr(latchrate, mul: 5, add: 6),
	Impulse.kr(rate)
	);
freq = Latch.kr(
	LFSaw.kr(latchrate, 
	mul: max(0, LFNoise1.kr(1/5, mul: 24, add: 10)), 
	add: LFNoise0.kr(1/7, mul: 12, add: 60)),
	Impulse.kr(rate)
	).round(1).midicps;

ratio = LFNoise1.kr(1/10, mul: 2.0, add: 5.0);

env = EnvGen.kr(
	Env.perc(0, LFNoise0.kr(rate, mul: 1, add: 1.5)/rate), 
	Impulse.kr(rate), 
	LFNoise1.kr([5, 5], 2, 1).max(0).min(0.8));
out = PMOsc.ar(
	[freq, freq * 1.5],
	freq*ratio,
	index,
	mul: env
);
Out.ar(0, out);
}
).play
)

a.set("rate", 10)

a.set("rate", 15)

a.set("rate", 6)

a.free;




﻿1.25 It's Just a Bell

(
{ // it's just a bell
var burst, burstEnv, bell, delay, dry, 
burstFreq = 500, freqs, amps, rings;
burstEnv = EnvGen.kr(Env.perc(0, 0.05),
				Dust.kr(1/5), 0.1);
// burstEnv.poll(100, "env");
burst = SinOsc.ar(freq: burstFreq,
	mul: burstEnv);
// burst.poll(100, "burst");
freqs = Array.fill(10, {exprand(100, 1000)});
amps = Array.fill(10, {rrand(0.01, 0.1)});
rings = Array.fill(10, {rrand(1.0, 6.0)});
// [freqs, amps, rings].round(0.01).postln;
// "safe" values
// freqs = [100, 200, 300, 400];
// amps = [1, 1, 1, 1];
// rings = [1, 1, 1, 1];

bell = Pan2.ar(
	Klank.ar(`[freqs, amps, rings], burst), 
	rrand(-1.0, 1.0)
);

delay = AllpassN.ar(bell, 2.5, 
	[LFNoise1.kr(7, 1.5, 1.6), LFNoise1.kr(7, 1.5, 1.6)], 
	1, mul: 0.8);
bell 
+ delay
// + SinOsc.ar(mul: LFPulse.kr(1) * 0.05);
}.play
)



﻿
/* Figure 2.1 */
Server.default = s = Server.internal;

s.boot;

z = s.scope(4);

// a) mono output
(
SynthDef(\UGen_ex1a, {
	Out.ar(0, SinOsc.ar(440, 0, 0.1))
}).add
)	

a= Synth(\UGen_ex1a);

a.free;

// b) freq input is an Array of 4 items - outputs to busses 0-3
(
SynthDef(\UGen_ex1b, {
	Out.ar(0, SinOsc.ar([440, 446, 448.5, 882], 0, 0.1))
}).add
)	

a= Synth(\UGen_ex1b);

a.free;

// c) Array is added to the 'mul' arg to show mapping
(
SynthDef(\UGen_ex1c, {
	Out.ar(0, SinOsc.ar([440, 446, 448.5, 882], 0, [0.1, 0.2, 0.3, 0.4]))
}).add;
)	

a= Synth(\UGen_ex1c);

a.free;

// d) The output of the SinOsc above is actually an Array of four SinOscs. Sum them       // together for an additive synthesis example.
(
SynthDef(\UGen_ex1d, {
	Out.ar(0, SinOsc.ar([440, 446, 448.5, 882], 0, [0.1, 0.2, 0.3]).sum);
}).add
)	

a= Synth(\UGen_ex1d);

a.free;

z.window.close;




﻿/* Figure 2.2 */

Server.default = s = Server.internal.boot;

z = s.scope;
(
SynthDef(\UGen_ex2, {arg freq = 440;
	var src, compressor, limiter, out;
	// 10 SinOsc's, mixed together. Output amplitude is controlled with an Dust UGen
 	// wrapped in a Decay2 UGen to create a spike with an Exponential Decay
	src = SinOsc.ar(
		// a harmonic series based on freq
		Array.series(10, freq, freq),
		0, // phase
		Array.fill(10, {Decay2.ar( 
			// Dust will create an impulse about every 2 seconds, with values between 0
			// and 5
			Dust.ar(0.1, 5),
			// Decay2, attach time of 0.01 seconds and a decay time of 5 seconds to
			// allow for a build up of signal
			0.01, 5)});
		).sum;
	// compress signal about 0.5
	compressor = Compander.ar(src, src, 0.5, 1, 0.1);
	limiter = Limiter.ar(compressor, 0.5);
	// out is the compressed only signal on the left, the compressed and limited on the 
	// right
	out = [DelayN.ar(compressor, 0.02, 0.02), limiter];
	// use Peak and poll to track the highest output values. Updates every second
	Peak.ar(out ++  src, Impulse.kr(1)).poll(1, ["compressed", "limited", "src"]);
	Out.ar(0, out);
}).add;
)	
a = Synth(\UGen_ex2, [\freq, 440]);

a.free; z.window.close;




﻿/* Figure 2.3 */
(
SynthDef(\UGen_ex3, {arg gate = 1, amp = 1, rate = 10;
	var trigger, dur, carfreq, modfreq, index, pan, env;
	trigger = Impulse.ar(rate);
	dur = rate.reciprocal;
	carfreq = LFNoise2.kr.range(100, 110);
	modfreq = LFTri.kr(0.1).exprange(200, 840);
	index = LFCub.kr(0.2).range(4, 10);
	pan = WhiteNoise.ar.range(-0.1, 0.1);
	env = EnvGen.kr(
		Env([0, 1, 0], [1, 1], \sin, 1),
		gate,
		levelScale: amp,
		doneAction: 2);
	Out.ar(0,
		GrainFM.ar(2, trigger, dur, carfreq, modfreq, index,
			pan, -1) * env)
}).add;
)
a = Synth(\UGen_ex3, [\rate, 80, \amp, 0.2]);

b = Synth(\UGen_ex3, [\rate, 42, \amp, 0.2]);

c = Synth(\UGen_ex3, [\rate, 121, \amp, 0.2]);

[a, b, c].do({arg thisSynth; thisSynth.set(\gate, 0)});




﻿/* Figure 2.4 */

(
SynthDef(\UGen_ex4a, {arg id, limit = 1;
	var src, pitch, hasPitch, keynum, outOfTune;
	// read input
	src = SoundIn.ar(0);
	// analyze the frequency of the input
	#pitch, hasPitch = Pitch.kr(src);
	// convert to a midi keynum, but don't round! This value will be used later.
	pitch = pitch.cpsmidi;
	// if you are within an eighth tone of an equal tempered pitch, send a trigger
	outOfTune = (pitch - pitch.round).abs < 0.25;
	// if outOfTune is true, send a trigger. Limit to 1 trigger every 'limit' seconds  
	SendTrig.kr(Trig.kr(outOfTune, limit), id, pitch.round);
}).add;
	
SynthDef(\UGen_ex4b, {arg id1, id2, limit = 1, thresh = 0.5;
	var src, amp, amptrig, timer;
	src = SoundIn.ar(0);
	// analyze the amplitude input, cause a trigger if the output is over the thresh
	amp = Amplitude.kr(src);
	amptrig = Trig.kr(amp > thresh, limit);
	// use amptrig to see how long it is between triggers.
	timer = Timer.kr(amptrig);
	// send the values back with two different ids
	SendTrig.kr(amptrig, id1, amp);
	SendTrig.kr(amptrig, id2, timer);
}).add;

// plays a SinOsc of the pitch you were closest to
SynthDef(\UGen_ex4c, {arg freq;
	Out.ar(1, SinOsc.ar(freq, 0, XLine.kr(0.1, 0.00001, 0.5, doneAction: 2)))
}).add;

// modulated noise to respond to amp spikes
SynthDef(\UGen_ex4d, {arg freq;
	Out.ar(1, LFNoise1.ar(200) * SinOsc.ar(freq, 0, 
		XLine.kr(0.1, 0.00001, 0.5, doneAction: 2)));
}).add;

// allocate three unique ids for the trigger ids
a = UniqueID.next;
b = UniqueID.next;
c = UniqueID.next;	

// an envelope to poll for amp values later
e = Env([440, 880], [1], \exp);

// add the responder
o = OSCresponderNode(s.addr, '/tr', {arg time, responder, msg;
	// the msg is an array with 4 values... post them
	msg.postln;
	// the id sent back from the SendTrig is msg[2]... use it to decide what to do
	case 
		// pitch trigger
		{msg[2] == a}
		// msg[3] is the rounded keynum
		{Synth(\UGen_ex4c, [\freq, msg[3].midicps])}
		// amp trigger
		{msg[2] == b}
		// play a noise burst, higher the amp value, higher the freq (polls the 
		// Env 'e')
		{Synth(\UGen_ex4d, [\freq, e[msg[3]]])}
		// use the Timer value to play a delayed noise burst at 2000 Hz
		{msg[2] == c}
		{SystemClock.sched(msg[3], {
			Synth(\UGen_ex4d, [\freq, 2000]);
			})}
}).add;

// schedule the start our listening synths...
// then sing or tap away on the input.
SystemClock.sched(1.0, {
	Synth(\UGen_ex4a, [\id, a, \limit, 1]);
	Synth(\UGen_ex4b, [\id1, b, \id2, c, \limit, 0.2, \thresh, 0.25]);
});
	
// add a command period function to stop the synths and remove the responder
CmdPeriod.doOnce({
	o.remove; "Removed the responder".postln;
})
)



﻿/* Figure 2.5 */
(
SynthDef(\UGen_ex5, {arg gate = 1, seed = 0, id = 1, amp = 1;
	var src, pitchbase, freq, rq, filt, trigger, env;
	RandID.ir(id);
	RandSeed.ir(1, seed);
	env = EnvGen.kr(Env([0, 1, 0], [1, 4], [4, -4], 1), gate, doneAction: 2);
	src = WhiteNoise.ar;
	trigger = Impulse.kr(Rand.new(2, 5));
	pitchbase = IRand.new(4, 9) * 12;
	freq = TIRand.kr(pitchbase, pitchbase + 12, trigger).midicps;
	rq = LFDNoise3.kr(Rand.new(0.3, 0.8)).range(0.01, 0.005);
	filt = Resonz.ar(src, Lag2.kr(freq), rq);
	Out.ar(0, Pan2.ar(filt, LFNoise1.kr(0.1)) * env * amp)
}).add;
)	
a = Synth(\UGen_ex5, [\seed, 123]);

a.release;

// Using the same seed, we get the same gesture
b = Synth(\UGen_ex5, [\seed, 123]);

b.release;

// passing in different seeds
(
r = Routine.run({
	thisThread.randSeed_(123);
	10.do({
		a = Synth(\UGen_ex5, [\seed, 10000.rand.postln, \amp, 3.dbamp]);
		1.wait;
		a.release;
	})
});
)		



﻿/* Figure 2.6 */
(
SynthDef(\UGen_ex6, {arg gate = 1, roomsize = 200, revtime = 450;
	var src, env, gverb;
	env = EnvGen.kr(Env([0, 1, 0], [1, 4], [4, -4], 1), gate, doneAction: 2);
	src = Resonz.ar(
			Array.fill(4, {Dust.ar(6)}),
			1760 * [1, 2.2, 3.95, 8.76] + 
				Array.fill(4, {LFNoise2.kr(1, 20)}), 
			0.01).sum * 30.dbamp;
	gverb = GVerb.ar(
		src,
		roomsize, 
		revtime, 
		// feedback loop damping
		0.99,
		// input bw of signal
		LFNoise2.kr(0.1).range(0.9, 0.7),
		// spread 
		LFNoise1.kr(0.2).range(0.2, 0.6),
		// almost no direct source 
		-60.dbamp,
		// some early reflection
		-18.dbamp, 
		// lots of the tail
		3.dbamp,
		roomsize);
	Out.ar(0, gverb * env)
}).add;
)	
a = Synth(\UGen_ex6);

a.release;



﻿/* Figure 2.7 */
(
SynthDef(\UGen_ex7a, {arg gate = 1, freq = 440, amp = 0.1, rate = 0.2;
	var src, pos, env;
	src = SinOsc.ar(freq, 0);
	pos = LFNoise2.ar(rate);
	env = EnvGen.kr(
		Env([0, 1, 0], [1, 1], \sin, 1), gate, levelScale: amp, doneAction: 2);
	Out.ar(0, Pan2.ar(src, pos) * env);
}).add;
			
SynthDef(\UGen_ex7b, {arg gate = 1, freq = 440, amp = 0.1, rate = 0.2;
	var src, pos, env;
	src = SinOsc.ar(freq, 0);
	pos = LFNoise2.kr(rate);
	env = EnvGen.kr(
		Env([0, 1, 0], [1, 1], \sin, 1), gate, levelScale: amp, doneAction: 2);
	Out.ar(0, Pan2.ar(src, pos) * env);
}).add;
	
SynthDef(\UGen_ex7c, {arg gate = 1, freq = 440, amp = 0.1, rate = 0.2;
	var src, pos, env;
	src = SinOsc.ar(freq, 0);
	pos = LFNoise2.kr(rate);
	env = EnvGen.kr(
		Env([0, 1, 0], [1, 1], \sin, 1), gate, levelScale: amp, doneAction: 2);
	Out.ar(0, Pan2.ar(src * env, pos));
}).add;
)

// 56% on my machine
(
a = Group.new;
250.do({
	Synth(\UGen_ex7a, [\freq, 440.0.rrand(1760.0), \amp, 0.001, \rate, 0.2], a)
});
)
a.release;

// 39%
(
a = Group.new;
250.do({
	Synth(\UGen_ex7b, [\freq, 440.0.rrand(1760.0), \amp, 0.001, \rate, 0.2], a)
});
)
a.release;

// 35%
(
a = Group.new;
250.do({
	Synth(\UGen_ex7c, [\freq, 440.0.rrand(1760.0), \amp, 0.001, \rate, 0.2], a)
});
)
a.release;



﻿/* Figure 2.8 */
(
SynthDef(\UGen_ex8a, {arg gate = 1, freq = 440, amp = 0.1, rate = 0.2;
	var w, x, y, out, env, decode;
	#w, x, y = PanB2.ar(
		SinOsc.ar(freq, 0), LFNoise2.kr(rate));
	env = EnvGen.kr(
		Env([0, 1, 0], [1, 1], \sin, 1), gate, levelScale: amp, doneAction: 2);
	decode = DecodeB2.ar(2, w, x, y);
	Out.ar(0, decode * env)
}).add;
			
SynthDef(\UGen_ex8b, {arg outbus, freq = 440, rate = 0.2;
	var w, x, y;
	#w, x, y = PanB2.ar(
		SinOsc.ar(freq, 0), LFNoise2.kr(rate));
	Out.ar(outbus, [w, x, y])
}).add;
			
SynthDef(\UGen_ex8c, {arg inbus, gate = 1, amp = 0.1;
	var w, x, y, env, decode;
	#w, x, y = In.ar(inbus, 3);
	env = EnvGen.kr(
		Env([0, 1, 0], [1, 1], \sin, 1), gate, levelScale: amp, doneAction: 14);
	decode = DecodeB2.ar(2, w, x, y) * env;
	ReplaceOut.ar(0, decode);
}).add;
)

(
a = Group.new;
250.do({
	Synth(\UGen_ex8a, [\freq, 440.0.rrand(1760.0), \amp, 0.001, \rate, 0.2], a)
});
)
a.release;

(
a = Group.new;
z = Bus.audio(s, 3);

// the 'catch-all' synth for decoding and enveloping
Synth(\UGen_ex8c, [\inbus, z, \amp, 0.001], a, \addToTail); // add it to the tail of the Group containing the encoding synths

250.do({
	Synth(\UGen_ex8b, [\freq, 440.0.rrand(1760.0), \outbus, z, \rate, 0.2], a)
});
)

a.release;	



﻿
/* Figure 2.9 */
(
// pass in amp in db
SynthDef(\UGen_ex9a, {arg gate = 1, freq = 440, amp = 0;
	var src, pos, env;
	src = SinOsc.ar(freq, 0, amp.dbamp);
	env = EnvGen.kr(
		Env([0, 1, 0], [1, 1], \sin, 1), gate, doneAction: 2);
	Out.ar(0, Pan2.ar(src * env, Rand(-1.0, 1.0)));
}).add;
	
// pass in linear amplitude
SynthDef(\UGen_ex9b, {arg gate = 1, freq = 440, amp = 1;
	var src, env;
	src = SinOsc.ar(freq, 0, amp);
	env = EnvGen.kr(
		Env([0, 1, 0], [1, 1], \sin, 1), gate, doneAction: 2);
	Out.ar(0, Pan2.ar(src * env, Rand(-1.0, 1.0)));
}).add;
	
SynthDef(\UGen_ex9c, {arg gate = 1, freq = 440, amp = -3, pos = 0;
	var src, env;
	src = SinOsc.ar(freq, 0, amp);
	env = EnvGen.kr(
		Env([0, 1, 0], [1, 1], \sin, 1), gate, doneAction: 2);
	Out.ar(0, Pan2.ar(src * env, pos));
}).add;
)	

// 45% on my machine
(
a = Group.new;
250.do({
	Synth(\UGen_ex9a, [\freq, 440.0.rrand(1760.0), \amp, -60], a)
});
)
a.release;

// 36%
(
a = Group.new;
250.do({
	Synth(\UGen_ex9b, [\freq, 440.0.rrand(1760.0), \amp, -60.dbamp], a)
});
)
a.release;

// 36% (no difference from b)
(
a = Group.new;
250.do({
	Synth(\UGen_ex9c, [\freq, 440.0.rrand(1760.0), \amp, -60.dbamp, \pos, 1.0.rand2], a)
});
)
a.release;




﻿
/* Figure 2.10 */
(
SynthDef(\UGen_ex10a, {arg gate = 1;
	var src, delay, env;
	env = EnvGen.kr(
		Env([0, 1, 0], [1, 1], \sin, 1), gate, doneAction: 2);
	src = Decay.ar(Impulse.ar(1), 1.0, PinkNoise.ar(0.1));
	delay = CombN.ar(src, 0.1, Line.kr(0.0001, 0.001, 10));
	Out.ar(0, (delay * env).dup);
}).add;

SynthDef(\UGen_ex10b, {arg gate = 1;
	var src, delay, env;
	env = EnvGen.kr(
		Env([0, 1, 0], [1, 1], \sin, 1), gate, doneAction: 2);
	src = Decay.ar(Impulse.ar(1), 1.0, PinkNoise.ar(0.1));
	delay = CombL.ar(src, 0.1, Line.kr(0.0001, 0.001, 10));	
	Out.ar(0, (delay * env).dup);
}).add;

SynthDef(\UGen_ex10c, {arg gate = 1;
	var src, delay, env;
	env = EnvGen.kr(
		Env([0, 1, 0], [1, 1], \sin, 1), gate, doneAction: 2);
	src = Decay.ar(Impulse.ar(1), 1.0, PinkNoise.ar(0.1));
	delay = CombC.ar(src, 0.1, Line.kr(0.0001, 0.001, 10));	
	Out.ar(0, (delay * env).dup);
}).add;
)

a = Synth(\UGen_ex10a); // no interpolation
a.release;

a = Synth(\UGen_ex10b); // linear interpolation
a.release;

a = Synth(\UGen_ex10c); // cubic interpolation
a.release;

(
SynthDef(\UGen_ex10d, {arg gate = 1, deltime = 0.001;
	var src, delay, env;
	env = EnvGen.kr(
		Env([0, 1, 0], [1, 1], \sin, 1), gate, doneAction: 2);
	src = Decay.ar(Impulse.ar(1), 1.0, PinkNoise.ar(0.1));
	delay = CombN.ar(src, 0.1, deltime);
	Out.ar(0, (delay * env).dup);
}).add;

SynthDef(\UGen_ex10e, {arg gate = 1, deltime = 0.001;
	var src, delay, env;
	env = EnvGen.kr(
		Env([0, 1, 0], [1, 1], \sin, 1), gate, doneAction: 2);
	src = Decay.ar(Impulse.ar(1), 1.0, PinkNoise.ar(0.1));
	delay = CombL.ar(src, 0.1, deltime);
	Out.ar(0, (delay * env).dup);
}).add;
	
SynthDef(\UGen_ex10f, {arg gate = 1, deltime = 0.001;
	var src, delay, env;
	env = EnvGen.kr(
		Env([0, 1, 0], [1, 1], \sin, 1), gate, doneAction: 2);
	src = Decay.ar(Impulse.ar(1), 1.0, PinkNoise.ar(0.1));
	delay = CombC.ar(src, 0.1, deltime);
	Out.ar(0, (delay * env).dup);
}).add;
)

// tune to a specific pitch
a = Synth(\UGen_ex10d, [\deltime, 100.midicps.reciprocal]); // no interpolation
a.release;

a = Synth(\UGen_ex10e, [\deltime, 100.midicps.reciprocal]); // linear interpolation
a.release;

a = Synth(\UGen_ex10f, [\deltime, 100.midicps.reciprocal]); // cubic interpolation
a.release;

// a much longer delay
a = Synth(\UGen_ex10d, [\deltime, 0.1]); // no interpolation
a.release;

a = Synth(\UGen_ex10e, [\deltime, 0.1]); // linear interpolation
a.release;

a = Synth(\UGen_ex10f, [\deltime, 0.1]); // cubic interpolation
a.release;



﻿Figure 3.1 A simple routine illustrating a musical use of yield
// Fermata
s.boot;
(
r = Routine({	
	x = Synth(\default, [freq: 76.midicps]);
	1.wait;
	
	x.release(0.1);
	y = Synth(\default, [freq: 73.midicps]);
	"Waiting...".postln;
	nil.yield;// fermata
	
	y.release(0.1);
	z = Synth(\default, [freq: 69.midicps]);
	2.wait;
	z.release;
});
)
// do this then wait for the fermata
r.play;
// feel the sweet tonic... 
r.play; 




﻿Figure 3.2 Using Task so you can pause the sequence
(
t = Task({	
	loop({	 // loop the whole thing
		3.do({	 // do this 3 times
			x.release(0.1);
			x = Synth(\default, [freq: 76.midicps]);
			0.5.wait;
			x.release(0.1);
			x = Synth(\default, [freq: 73.midicps]);
			0.5.wait;
		});
		"I'm waiting for you to press resume".postln;
		nil.yield;// fermata
		x.release(0.1);
		x = Synth(\default, [freq: 69.midicps]);
		1.wait;
		x.release;
	});
});

w = Window.new("Task Example", Rect(400, 400, 200, 30)).front;
w.view.decorator = FlowLayout(w.view.bounds);
Button.new(w, Rect(0, 0, 100, 20)).states_([["Play/Resume", Color.black, Color.clear]])
	.action_({ t.resume(0);});
Button.new(w, Rect(0, 0, 40, 20)).states_([["Pause", Color.black, Color.clear]])
	.action_({ t.pause;});
Button.new(w, Rect(0, 0, 40, 20)).states_([["Finish", Color.black, Color.clear]])
	.action_({ 
		t.stop; 
		x.release(0.1);
		w.close;
	});
)







﻿
// Figure 3.3 Nesting tasks inside routines
(
r = Routine({	
	c = TempoClock.new; // make a TempoClock
	// start a 'wobbly' loop
	t = Task({	
		loop({	
			x.release(0.1);
			x = Synth(\default, [freq: 61.midicps, amp: 0.2]);
			0.2.wait;
			x.release(0.1);
			x = Synth(\default, [freq: 67.midicps, amp: 0.2]);
			rrand(0.075, 0.25).wait; // random wait from 0.1 to 0.25 seconds
		});
	}, c); // use the TempoClock to play this Task
	t.start;
	nil.yield;
	
	// now add some notes
	y = Synth(\default, [freq: 73.midicps, amp: 0.3]);
	nil.yield;
	y.release(0.1);
	y = Synth(\default, [freq: 79.midicps, amp: 0.3]);
	c.tempo = 2; // double time
	nil.yield;
	t.stop; y.release(1); x.release(0.1); // stop the Task and Synths
});
)

r.next; // start loop
r.next; // first note
r.next; // second note; loop goes 'double time'
r.next; // stop loop and fade









﻿// Figure 3.4 Using patterns within a task

(// random notes from lydian b7 scale
p = Pxrand([64, 66, 68, 70, 71, 73, 74, 76], inf).asStream; 
// ordered sequence of durations
q = Pseq([1, 2, 0.5], inf).asStream; 
t = Task({	
	loop({	
		x.release(2);
		x = Synth(\default, [freq: p.value.midicps]);
		q.value.wait;
	});
});
t.start;
)
t.stop; x.release(2);



﻿
// Figure 3.5 Thanks to polymorphism we can substitute objects that understand the same message
(
p = 64; // a constant note
q = Pseq([1, 2, 0.5], inf).asStream; // ordered sequence of durations
t = Task({	
	loop({	
		x.release(2);
		x = Synth(\default, [freq: p.value.midicps]);
		q.value.wait;
	});
});
t.start;
)
// now change p
p = Pseq([64, 66, 68], inf).asStream; // to a Pattern: do re mi
p = { rrand(64, 76) }; // to a Function: random notes from a chromatic octave
t.stop; x.release(2);





﻿
// Figure 3.6 Using 'messaging style': Score

(
SynthDef("ScoreSine",{ arg freq = 440;
Out.ar(0,
	SinOsc.ar(freq, 0, 0.2) * Line.kr(1, 0, 0.5, doneAction: 2)
)
}).add;
x = [
// args for s_new are synthdef, nodeID, addAction, targetID, synth args ...
[0.0, [ \s_new, \ScoreSine, 1000, 0, 0,  \freq, 1413 ]],
[0.5, [ \s_new, \ScoreSine, 1001, 0, 0,  \freq, 712 ]],
[1.0, [ \s_new, \ScoreSine, 1002, 0, 0,  \freq, 417 ]],
[2.0, [\c_set, 0, 0]] // dummy command to mark end of NRT synthesis time
];
z = Score(x);
)
z.play;




﻿// Figure 3.7 Executing one line at a time

(
// here's a synthdef that allows us to play from a buffer, with a fadeout
SynthDef("playbuf", { arg out = 0, buf, gate = 1;
	Out.ar(out,
		PlayBuf.ar(1, buf, BufRateScale.kr(buf), loop: 1.0) 
			* Linen.kr(gate, doneAction: 2); // release synth when fade done
	)
}).add;
// load all the paths in the sounds/ folder into buffers
~someSounds = "sounds/*".pathMatch.collect{ |path |  Buffer.read(s, path)}; 
)
// now here's the score, so to speak
// execute these one line at a time
~nowPlaying = Synth("playbuf", [buf: ~someSounds[0]]);
~nowPlaying.release; ~nowPlaying = Synth("playbuf", [buf: ~someSounds[1]]);
~nowPlaying.release; ~nowPlaying = Synth("playbuf", [buf: ~someSounds[2]]);
~nowPlaying.release;
// free the buffer memory
~someSoundsBuffered.do(_.free);
 
 



﻿
 // Figure 3.8 Play cues with a simple GUI

(
SynthDef("playbuf", { arg out = 0, buf, gate = 1;
	Out.ar(out,
		PlayBuf.ar(1, buf, BufRateScale.kr(buf), loop: 1.0) 
		* Linen.kr(gate, doneAction: 2) * 0.6; 
		// with 'doneAction: 2' we release synth when fade is done	
) }).add;
~someSounds = "sounds/*".pathMatch.collect{ |path |  Buffer.read(s, path)}; 
n = 0; // a counter
// here's our GUI code
w = Window.new("Simple CuePlayer", Rect(400, 400, 200, 30)).front;
w.view.decorator = FlowLayout(w.view.bounds);
//this will play each cue in turn
Button.new(w, Rect(0, 0, 80, 20)).states_([["Play Cue", Color.black, Color.clear]]).action_({ 
	if(n < ~someSounds.size, {
		if(n != 0, {~nowPlaying.release;}); 
		~nowPlaying = Synth("playbuf", [buf: ~someSounds[n]]); n=n+1;
	});
}); 
//this sets the counter to the first cue
Button.new(w, Rect(0, 0, 80, 20)).states_([["Stop / Reset", Color.black, Color.clear]]).action_({ n=0; ~nowPlaying.release; }); 
// free the buffers when the window is closed
w.onClose = { ~someSounds.do(_.free); };
)







﻿
// Figure 3.9 Gathering up files for multichannel cues 

// gather all your folder paths
//this will path match each folder in the collection, i.e. we will have a collection of collections of paths

~groupOfindivCueFolders = "sounds/*".pathMatch.collect{ | item |  (item.asSymbol++"*").pathMatch };

Post << ~groupOfindivCueFolders;  //see them all !

//check how many cues you will have in the end
~groupOfindivCueFolders.size; 

//automate the buffering process for all cues:
~bufferedCues = ~groupOfindivCueFolders.collect{|item, i| item.collect{| path |  Buffer.read(s,  path)}}; //now all our cue files are sitting in their buffers ! 

~bufferedCues[0];  //here is cue 1

// see it in the post window:
Post << ~bufferedCues[0];

// play them all in a Group, using our previous synthdef
// we use bind here to ensure they start simultaneously
(
s.bind({	
	~nowPlaying = Group.new(s); // a group to put all the channel synths in
	~bufferedCues[0].do({|cue| Synth("playbuf", [buf: cue], ~nowPlaying)})
});
)
// fade them out together by sending a release message to the group
~nowPlaying.release;






﻿// Figure 3.10 Recording the results of making sounds with supercollider

s.boot; // make sure the server is running
(  	// first evaluate this section
b = Buffer.read(s, "sounds/a11wlk01.wav"); // a source
s.prepareForRecord; // prepare the server to record (you must do this first)
)
(	// simultaneously start the processing and recording
s.bind({
	// here's our funky effect
	x = { var columbia, amp; 
		columbia = PlayBuf.ar(1, b, loop: 1);
		amp = Amplitude.ar(columbia, 0.5, 0.5, 4000, 250); // 'sticky' amp follower
		Out.ar(0, Resonz.ar(columbia, amp, 0.02, 3)) // filter; freq follows amp
		}.play;
s.record;
});
)
s.pauseRecording; // pause
s.record // start again
s.stopRecording; // stop recording and close the resulting sound file




﻿
// Figure 3.12 A variable number of resonators with an automatically created GUI       
(
f = 300;
n = 30; // number of resonators
t = Array.fill(n, { |i|
{
Resonz.ar(Dust2.ar(5), f * (i + 1), 0.001, 300)
* n.reciprocal; // scale to ensure no clipping
}.play;
});

// now make a GUI
// a scrolling window so we don't run out of space
w = Window.new("Buttons", Rect(50, 100, 290, 250), scroll:true);
w.view.decorator = FlowLayout.new(w.view.bounds); // auto layout the widgets
n.do({|i|
Button.new(w, Rect(0, 0, 130, 30)).states_([
["Freq" + (f * (i + 1)) + "On", Color.black, Color.white],
["Freq" + (f * (i + 1)) + "Off", Color.white, Color.black]
])
.action_({ arg butt;
t[i].run(butt.value == 0);
});
});
w.front;
)



﻿
// Figure 3.13 Making a stuttering gesture using a geometric pattern

(/* a routine for creating a ritardando stutter with panning, you must have
run the code in fig 3.9 so that this routine may find some sounds already loaded into buffers, you can change the index of ~bufferedCues to test the routine on different sounds */


~stut = Routine( { var dur, pos;
~stutPatt = Pseq([Pgeom(0.01, 1.1707, 18), Pn(0.1, 1),Pgeom(0.1, 0.94, 200) ]);
~str= ~stutPatt.asStream;
100.do{
    dur =  ~str.next;
    dur.postln; 	//so we can check values on the post window
    ~sample = Synth("samplePlayer",[\out, 0, \buf,  ~bufferedCues[0], \at, 0.1, \rel, 0.05,\pSpeed, 0.5]);
    dur.wait;
}
});
)

//now play it
~stut.play;
// reset before you play again!
~stut.reset; 
 



﻿Figure 4.1
Create a network address representing sclang itself
~host = NetAddr("localhost", NetAddr.langPort);
// Create two OSC responders for the same command
~r1 = OSCresponderNode(
	~host, "/testMsg",
	{ | time, responder, message, address |
		[\responder1, time, message, address].postln;
	}
).add;
~r2 = OSCresponderNode(
	~host, "/testMsg",
	{ | time, responder, message, address |
		[\responder2, time, message, address].postln;
	}
).add;

// Send an OSC message
~host.sendMsg("/testMsg", "OSCresponderNode test");

// Remove responders
~r1.remove;
~r2.remove;




﻿  Figure 5.1
1					// the Integer number 1 
1.234 				// the floating-point (Float) number 1.234
$a 					// the character (Char) a
"hello"				// a String (an array of characters) 
\alpha				// a Symbol (a unique identifier) 
'alpha 1'				// another notation for a Symbol
100@150 				// a Point defined by coordinates x, y 
[1, \A, $b] 				// an Array containing 3 elements
(a: 1, b: 0.2) 			// an Event 
{ 10.rand }				// a Function
String 				// the Class String 
Meta_String 			// the Class of Class String





﻿Figure 5.3
// Boot the default server first:
Server.default.boot;
// Then select all lines between the outermost parentheses and run: 
( 	
{
	Resonz.ar(GrayNoise.ar,
		XLine.kr(100, 1000, 10, doneAction: 2), 
		XLine.kr(0.5, 0.01, [4, 7], doneAction: 0)
	)
}.play
)
// further examples:
{ WhiteNoise.ar(EnvGen.kr(Env.perc, timeScale: 3, doneAction: 2)) }.play;
{ WhiteNoise.ar(EnvGen.kr(Env.perc, timeScale: 0.3, doneAction: 2))}.play;




﻿Figure 5.4
((1 + 2).asString).interpret 		// = 3
"1" ++ "2". interpret			// 12: 2 is translated to string by ++
("1" ++ "2").interpret			// 12
(1.asString ++ 2.asString).interpret 	// 12
"1+2". interpret 				// 3
(1.asString ++ "+2"). interpret		// 3
(1 + 2).interpret				// error: interpret not understood by Integer 3




﻿Figure 5.5
(
a = 5;
5 do: { a = a + 10; a.postln };
Post << "The value of variable 'a' is now " << a << "\n";
)


﻿Figure 5.8
(
// A window with a button that posts: "hello there!"
var window, button;
// create a GUI window and store it in variable window
window = Window.new("OLA!", Rect(200, 200, 120, 120)); 
// create a button in the window and store it in variable button
button = Button.new(window, Rect(10, 10, 100, 100));
button.states = [["'ALLO"]];	// set one single label for the button
button.action = { "hello there!".postln }; // set the action of the button
window.front;		  	  // show the window
)
 


﻿Figure 5.9

( 
// execute this first to boot the server and load the synth definition
Server.default.waitForBoot({ 
	SynthDef("ping", { | freq = 440 |
		Out.ar(0, 
			SinOsc.ar([freq, freq * (4/3)], 0,
				EnvGen.kr(Env.perc(0.05, 0.3, 0.1, -4), doneAction: 2)
			)
		)
	}).add
});
)

(
// execute this next to create the sounds
var countdown = 100;
var note = 50;
var increment_func, decrement_func;
var action;
increment_func = {
	note = note + [2, 5, 7, 12].choose;
	if (note > 100) { action = decrement_func };
};
decrement_func = {
	note = note - [1, 2, 5, 7, 12].choose;
	if (note < 50) { action = increment_func };
};
action = increment_func;
{
	countdown do: { 
		Synth("ping", [\freq, note.midicps]);
		action.value;
		0.1.wait;
	}
}.fork;
)



﻿Figure 5.11
// run each line separately: 
currentEnvironment;	// empty if no environment variables have been set
~alpha = pi;			// set env. variable ~alpha to pi
currentEnvironment;	// see current Environment again: ~alpha is set
~freq = 800;			// set another environment variable
Server.local.boot;
{ LFNoise0.ar(~freq, 0.1) }.play; // use an environment variable
// setting an environment variable to nil is equivalent to removing it: 
~alpha = nil;
currentEnvironment;	// alpha is no longer set



﻿Figure 5.12
(
~q = "TOP";							// store "TOP" in ~a, top environment
(a: "INNER") use: { // run function in environment with ~a = "INNER"
	currentEnvironment.postln; // show the current environment
	topEnvironment.postln;		// show the top environment (different!)
	~a.postln				// show ~a's value in current environment
};	
~a;						// show ~a's value in top environment
)




﻿Figure 5.13
(
var alpha, beta, gamma;
gamma = alpha;	// storing variable alpha in gamma only stores nil 
alpha = 10; 	// store 10 in alpha ...
gamma.postln;	// but the value of gamma remains unchanged
alpha = beta;	// so one cannot use gamma as 'joker'
beta = 20;		// to switch between variables alpha and beta.
gamma.postln;	// gamma is still nil.
)




﻿Figure 5.15
Server.default.boot; 		// (boot Server before running example)
(
// Define a function and call it in different contexts
var synth;				// Synth creating the sound that is changed
var freq = 220; 			// frequency of the sound
var change_freq;			// function that changes the frequency of the sound
var window;			// window holding buttons for changing the sound
var button1, button2, button3; // buttons changing the sound

// Create a synth that plays the sound to be controlled:
synth = { | freq = 220 | LFTri.ar([freq, freq * 2.01], 0, 0.1) }.play;
// Create frequency changing function and store it in variable change_freq
change_freq = {						// start of function definition
		freq = freq * [0.9, 0.9.reciprocal].choose; // change freq value
		synth.set(\freq, freq);			// set synth's frequency to new value
};								// end of function definition

// Create 3 buttons that call the example function in various ways
window = Window("Buttons Archaic", Rect(400, 400, 340, 120));
//  ------------------------- Example 1 -------------------------
button1 = Button(window, Rect(10, 10, 100, 100));
button1.states = [["I"]]; // set the label of button1
// button1 calls the function each time that it is pressed 
button1.action = change_freq;	// make button1 change freq once
//  ------------------------- Example 2 -------------------------
button2 = Button(window, Rect(120, 10, 100, 100));
button2.states = [["III"]];
// Button2 creates a routine that calls the example function 3 times
button2.action = { 			// make button2 change freq 3 times
	{ 3 do: { change_freq.value; 0.4.wait } }.fork; // play as routine
};
//  ------------------------- Example 3 -------------------------
button3 = Button(window, Rect(230, 10, 100, 100));
button3.states = [["VIII"]];
button3.action = { 			// like example 2, but 8 times
	{ 8 do: { change_freq.value; 0.1.wait } }.fork; // play as routine
};
// use large size font for all buttons:
[button1, button2, button3] do: _.font_(Font("Times", 32));
// stop the sound when the window closes: 
window.onClose = { synth.free };
window.front; // show the window
)






﻿Figure 5.18
(
// a function that calculates the square of the mean of two numbers
var sq_mean;
sq_mean = { arg a, b; 	// arguments a, b defined in arg statement form
	(a + b / 2).squared;
};
// calculate the square of the mean of 3 and 1:
sq_mean.value(3, 1);
)




﻿Figure 5.19
(
// a function that calculates the square of the mean of any numbers
var sq_mean_all;
sq_mean_all = { | ... numbers | // using ellipsis and | | argument form
	(numbers.sum / numbers.size).squared;
};
// calculate the square of the mean of [1, 3, 5, -7]:
sq_mean_all.(1, 3, 5, -7); // short form: omit message 'value'
)



﻿Figure 5.20
(
var w_func;
w_func = { arg message = "warning!", bounds = Rect(200, 500, 500, 100);
	var window;
	window = Window("message window", bounds).front;
	TextView(window, window.view.bounds.insetBy(10, 10))
		.string = message;	
};
 // provide text, use default bounds
w_func.(String.new.addAll(Array.new.addAll(" Major news! ").pyramid(7)));
)



﻿Figure 5.21
(
var window, button; 
window = Window("Server Button", Rect(400, 400, 200, 200));
button = Button(window, Rect(5, 5, 190, 190));
button.states = [["boot!"], ["quit!"]];
button.action = { |me| Server.default perform: [\quit, \boot][me.value] };
window.front;
)



﻿Figure 5.22
(
var window, button; 
window = Window("Server Button", Rect(400, 400, 200, 200));
button = Button(window, Rect(5, 5, 190, 190));
button.states = [["boot"], ["quit"]];
button.action = { | me | 
	[{ "QUITTING THE DEFAULT SERVER".postln;
		Server.default.quit;
	},{ "BOOTING THE DEFAULT SERVER".postln;
		Server.default.boot;
	}][me.value].value;
};
window.front;
)





﻿Figure 5.23
Server.default.boot // boot default server before running example
(
var buffer;
buffer = Buffer.read(path: "sounds/a11wlk01.wav",
	action: { | buffer |
		format("loaded % at: %", buffer, Main.elapsedTime).postln;
	});
format("Reached this after 'Buffer.read' at: %", Main.elapsedTime).postln;
buffer;
)



﻿Figure 5.24
Server.default.boot;  // do this first
(						// then the rest of the program
var window, routine;
window = Window("close me to stop").front;
window.onClose = { routine.stop };
routine = { 
	loop {
		(degree: -10 + 30.xrand, dur: 0.05, amp: 0.1.rand).play;
		0.05.rand.wait;
	}
}.fork;
)




﻿Figure 5.25
_.isPrime ! 10
_.squared ! 10
_@_.(30, 40) // equivalent to: { | a, b | Point(a, b) }.value(30, 40)
Array.rand(12, 0, 1000).clump(4) collect: Rect(*_)
(1..8).collect([\a, \b, _]);
(a: _, b: _, c: _, d: _, e: _).(*Array.rand(5, 0, 100));



﻿Figure 5.26
(
var iterative_factorial;
iterative_factorial = { | n |
	var factorial = 1;	// initialize factorial as factorial of 1
	// calculate factorial n times, updating its value each time
	n do: { | i | factorial = factorial * (i + 1) };
	factorial;	// return the final value of factorial;
};
iterative_factorial.(10).postln;	// 10 factorial: 3628800
)



﻿Figure 5.27
// Define the factorial function and store it in variable f:
f = { | x | if ( x > 1) { x * thisFunction.value(x - 1) } { x } };
 f.value(10);			// 10 factorial: 3628800



﻿Figure 5.28
(	
/* a function that recursively prints all folders and files
   found in a path and its subfolders */
{ | path |
	// store function here for use inside the if's {}:
	var thisFunc = thisFunction;
	format("====== now exploring: %", path).postln;
	// for all items in the path:
	path.pathMatch do: { | p | 
		// if the item is a folder, run this function on its contents
		// otherwise print the file found
		if (p.last == $/) { thisFunc.(p ++ "*") }{ p.postln }
	}
}.("*") // run function on home path of SuperCollider
)




﻿Figure 5.29
(
// a function that creates a function that counts to any number
var counter_maker;
var window, button1, button2; // gui for testing the function

// the function that makes the counting function
counter_maker = { | max_count |
	// current_count is used by the function created below
	// to store the number of times that it has run
	var current_count = 0;  
	{	// start of definition of the counting function
		if (current_count == max_count) {
			format("finished counting to %", max_count).postln; 
			max_count;		// return max count for eventual use
		}{
			current_count = current_count + 1; // increment count
			format("counting % of %", current_count, max_count).postln; 
			current_count	// return current count for eventual use
		}
	}	// end of definition of the counting function 
};

//  ----- Test application for the counter_maker function ----- 
// window displaying 2 buttons counting to different numbers
window = Window("Counters", Rect(400, 400, 200, 80));
// make a button for triggering the counting: 
button1 = Button(window, Rect(10, 10, 180, 20));
button1.states = [["counting to 10"]];	// labels for button1
// make a function that counts to 10 and store it as action in button1
button1.action = counter_maker.(10);
button2 = Button(window, Rect(10, 40, 180, 20));
button2.states = [["counting to 5"]];	// labels for button2
// make a function that counts to 5 and store it as action in button2
button2.action = counter_maker.(5);
window.front;			// show the window
)



﻿Figure 5.31
(
var counter_maker;		// creator of counters
var make_counters_gui;	// function making counters + a gui
/* a function that creates an event that counts to any number, 
   and resets: */ 
counter_maker = { | max_count |
	var current_count = 0; 
	(	// the counter object is an event with 3 functions: 
		count1: // function 1: increment count (stored as count1)
		{	// start of definition of the counting function
			if (current_count == max_count) {
				format("finished counting to %", max_count).postln; 
			}{
				current_count = current_count + 1; // increment count
				format("counting % of %", current_count, max_count).postln; 
			}
		},	// end of definition of the counting function
		reset_count: { // function 2: reset count (stored as reset_count)
			format("resetting % counter", max_count).postln;
			current_count = 0
		},
		max_count: { max_count } // function 3: return value of max_count
	)
};
// Function that makes several counters and a GUI to control them
make_counters_gui = { | ... counts |
	var window, counter;
	window = Window("Counters", 
			Rect(400, 400, 200, 50 * counts.size + 10));
	// enable automatic placement of new items in window: 
	window.view.decorator = FlowLayout(window.view.bounds, 5@5, 5@5);
	counts collect: counter_maker.(_) do: { | counter |  
		Button(window, Rect(0, 0, 190, 20))
			.states_([["Counting to: " ++ counter.max_count.asString]])
			.action = { counter.count1 };
		Button(window, Rect(0, 0, 190, 20))
			.states_([["Reset"]])
			.action = { counter.reset_count };
	};
	window.front;
};
make_counters_gui.(5, 10, 27); // example use of the GUI test function
)






﻿Figure 5.32
Server.default.boot;	// boot the server first;
(
var degrees, window, button;
window = Window("melodies?", Rect(400, 400, 200, 200));
button = Button(window, window.view.bounds.insetBy(10, 10));
button.states = [["click me to add a note"]];
button.action = { 
	degrees = degrees add: 0.rrand(15);
	Pbind(\degree, Pseq(degrees), \dur, Prand([0.1, 0.2, 0.4], inf)).play;
};
window.front;
)




﻿Figure 5.34
1.class 		// the class of Integer 1: Integer
1.class.class 	// the Class of the Class of Integer 1: Meta_Integer
// the Class of the Class of the Class of Integer 1: 
1.class.class.class  					// Class
// the Class of the Class of the Class of the Class of Integer 1
1.class.class.class.class				// Meta_Class
// the Class of the Class of the Class of the Class of the Class of 1
1.class.class.class.class.class 		// Class 
Class.class				// the Class of Class is Meta_Class
Meta_Class.class		// the Class of Meta_Class is Class




﻿Figure 5.36
Counter { 
	// variables: maximum count, current count
	var <>max_count, <>current_count = 1;
	// class method for creating a new instance
	*new { | max_count = 10 |
		^super.new.max_count_(max_count)
	}
	// if maximum count not reached, increment count by 1
	count1 {
		if (current_count >= max_count) {
			this.changed(\max_reached)
		}{
			current_count = current_count + 1;
			this.changed(\count, current_count);
		}
	}
	// reset count
	reset {
		current_count = 1;
		this.changed(\reset);
	}
}




﻿Figure 5.37
Server.default.boot;
(
SynthDef("ping", { | freq = 440 | 
	Out.ar(0, 
		SinOsc.ar(freq, 0, 
			EnvGen.kr(Env.perc(level: 0.1), doneAction: 2)
	))
}).add;

SynthDef("wham", {
	Out.ar(0, BrownNoise.ar(
		EnvGen.kr(Env.perc(level: 0.1), doneAction: 2)
	))
}).add; 
)




﻿Figure 5.38
(
~sound_adapter =  { | counter, what, count |
	switch (what, 
		\reset, { Synth("wham"); },
		\max_reached, { counter.reset },
		\count, { Synth("ping", 
			[\freq, count.postln * 10 + counter.max_count * 20]
			)
		}
	)
};
)
 



﻿Figure 5.39
(
~make_display = { | counter |
	var window, label, adapter, stagger;
	window = Window(
		"counting to " ++ counter.max_count.asString, 
		Rect(stagger = UniqueID.next % 20 * 20 + 400, stagger, 200, 50)
	);
	label = StaticText(window, window.view.bounds.insetBy(10, 10));
	adapter = { | counter, what, count |
			{ label.string = counter.current_count.asString }.defer
	};
	counter addDependant: adapter;
	/* remove the adapter when window closes to prevent error in 
	   updating non-existent views: */
	window.onClose = { counter removeDependant: adapter };
	window.front
};
)


﻿Figure 6.1.  Example of a SynthDef
SynthDef(					
	"sine", 				// name of SynthDef	
	{				// function begins with a brace
	 arg gate = 1, out = 0, 		// arguments serve as Control declarations
 freq = 400, amp = 0.4,
 pan = 0, ar = 1, dr = 1;

	var audio;			
	audio = SinOsc.ar(freq, 0, amp);		// start with a SinOsc
	audio = audio * Linen.kr(gate, ar, 1, dr, 2);	// apply an envelope
	audio = Pan2.ar(audio, pan);			// stereo pan, 
	OffsetOut.ar(out,audio);			// to bus out and out+1 
	}
).add;				// make and store a SynthDesc and SynthDef




﻿Figure 6.2. Example of a key/value Array and a note Event=
a = [ 
	type:			\note,		
	instrument: 		'sine', 
	freq:			400, 
	amp:			0.1, 
	pan:			0, 
	ar: 			2, 
	dr: 			4, 
	sustain:		2
];

e = (
	type:			\note,		
	instrument: 		'sine', 
	freq:			400, 
	amp:			0.1, 
	pan:			0, 
	ar: 			2, 
	dr: 			4, 
	sustain:		2
);
e.play;					// play the note



﻿
Figure  6.3. The OSC commands created by the note event
e.asOSC.do{ | osc | osc.postcs };

// the result that would be posted:		
//  [ 0.0, ['s_new', 'sine', 1000, 0, 1, 'out', 0, 'freq', 400.0, 'amp', 0.1, 'pan', 0, 'ar', 2, 'dr', 4] ]
//  [ 2.0, [ 'n_set', 1000, 'gate', 0 ] ] 



﻿Figure 6.4. Two ways of writing the same Event Pattern
	1. Pbind( *[ 
		dur:	0.2,
freq: 	Pseq([100, 200, 300, 400, 500, 600, 700, 800]) 
	] );

	2. Pbind( 
		\dur, 0.2,
		\freq, 	Pseq([100, 200, 300, 400, 500, 600, 700, 800]) 
	);



﻿Figure 6.5. A more elaborate Event Pattern
p = Pbind(*[ 
		instrument:	\default,
		detune:		[0,1,3],
		freq: 		Pseq( (1..11) * 100,  4 * 5 * 7),
		db:		Pseq([-20, -40, -30, -40], inf),
		pan:		Pseq([-1,0,1,0], inf),
		dur:		Pseq([0.2,0.2,0.2,0.2, 0.4,0.4,0.8], inf),
		legato:		Pseq([2,0.5,0.75,0.5,0.25], inf)	
	] );
// render 40 seconds of the pattern in the file named "sf.aif"	
	p.render("sounds/sf.aif", 40)	
// now play the pattern in real-time
	p.play;									



﻿Figure 6.6.  Using Event types
(
	(type: 	\group, 	
id: 2
).play;					// create a group with nodeID 2

	(	type:		\note, 		// play note		
	 	sustain:	100, 		// lasting 100 seconds				
	 	group: 		2		// in group 2

	 ).play;	
	 										
)
(
	(type: 	\off, 	id: 2).play;		// release all notes in the group
	(type:	 \kill,	id: 2,  lag: 3).play;	// and free the group  3 seconds later	
)




﻿Figure 6.7. Chord events
// 2nd inversion - e loudest
( degree:  [-3,0,2],	sustain: 2, 	db: [-20, -20, -10] ).play			
// 2nd inversion - c loudest
 ( degree:  [-3,0,2],	sustain: 2, 	db: [-20, -10, -20] ).play	
// note "fattened" by three detuned copies
 ( degree: 0,		sustain: 2, 	detune: [0,3, 5] ).play			
// each detune is assigned to a different pitch, fat free.
 ( degree:  [-3,2,4],	sustain: 2, 	detune: [0,3, 5] ).play			
// detune rotates through each note in the chord
 ( degree:  [-3,2,4],	sustain: 2, 	detune: [0,0,0,3,3,3,5,5,5] ).play 	




﻿Figure 6.8.  Interdependent key values in a Pattern
	Pbind(*[
		stretch:		Pseg([0,0.1,0.2,1],8).linexp(0,1, 1,0.125),
		midinote: 		100.cpsmidi,
		harmonic:		Pwhite(1, 16),
		legato:			Pkey(\stretch) * Pkey(\harmonic)/2 ,
		db:			-10 - Pkey(\harmonic),
		detune:			Pwhite(0.0,3.0),
		dur:			0.2,
	]).play




﻿Figure 6.9. Chaining Event Patterns
	a = Pbind(*[
		scale: 	Pn( Pstep([[0,2,4,5,7,9,11], [0,1,3,5,6,8,11] ], 5 ) ),
		db:	Pn(Pseg([-20, -30, -25, -30], 0.4))
	]);
	b = Pbind(*[ 
degree: Pbrown(0, 6, 1), 
mtranspose: Prand([\rest, Pseq([0], 5.rand)],inf), 
dur: 0.2, 
octave: 6
]);
	c = Pbind(*[ 
degree: [0,2,4],  
mtranspose: Pbrown(0, 6, 1), 
dur: 0.4, 
db: -35
]);
	d = Pchain(Ppar([b, c]),a);
d.play;



﻿Figure 6.10. Using Prout to define and play patterns on the fly
	Prout({| ev |
		var pat, refPat;

		refPat = Pbind(*[dur: 0.2, note: Pseq([0,0, 0, 7,0, 7])]);

		loop {
			ev = refPat.embedInStream(ev);

			pat = Pbind(*[
				dur: [0.2, 0.4].choose,
				note: Pseq(Array.fill(5, { 10.rand }), 3.rand )
			]);	
ev = pat.embedInStream(ev);
		}
	
}).play




﻿Figure 6.11.  Using Prout to define value and event patterns
~patA = Pbind(*[
	dur:	0.2,
	degree: Prout({ | ev |
		var noteArray  = (0..5);
		loop {
			ev = Pseq(noteArray ).embedInStream(ev);
			noteArray[6.rand] = 7.rand;
		}		
	})
]);


~patB = Prout({ | ev |
	var pat, pats= [
	 	Pbind(*[ degree: Pseq([  0, 7]), dur: 0.2   ]),
	 	Pbind(*[ degree: Pseq([11, 7]), dur: 0.2 ]),
		Pbind(*[ degree: Pseq([16, 7]), dur: 0.2 ]).
		(type: \rest, delta: 1)
	];
			
	loop {
		pat = pats.choose;
		ev = pat.embedInStream(ev);
	}
});

Pchain(
	Pbind(*[
		db: 	Pn(Pstep([-15, -25,-25, -20, -30, -25], 0.2) )
			+ Pseg([-30, -5,-10, -40], 12)
	]), 
	Ptpar([
		0, ~patA, 
		0,  ~patA, 
		12,  ~patB
	]) 
).play;



﻿Figure 6.12.  Rendering and playing a pattern
	~pattern = Pbind(*[ 
		instrument:	"default",
		freq: 	Pseq([100, 200, 300, 400, 500, 600, 700, 800, 900, 1000, 1100], 5),
		db:	Pseq([-10, -30, -20, -30], inf),
		dur:	Pseq([0.2,0.2,0.2,0.2, 0.4,0.4,0.8],inf),
		legato: Pseq([2,0.5,0.75,0.5,0.25], inf)	
	] );

	~score = ~pattern.asScore(24 * 11/7);
	~score.render("recordings/test.aif");
	SoundFile("recordings/test.aif").play;



﻿Figure 6.13. Soundfile granulation with a Pattern 
SynthDef("playbuf", { | out=0, bufnum = 0, rate = 1, 
startPos = 0, amp = 0.1, sustain = 1, 
pan = 0, gate = 1|
	var audio, env;
	rate = rate * BufRateScale.kr(bufnum);
	startPos = startPos * BufFrames.kr(bufnum);
	env = EnvGen.ar(Env.sine, 1, timeScale: sustain, doneAction: 2);
	audio = PlayBuf.ar(1, bufnum, rate, 1, startPos, 0);
	audio = env * audio;
	audio = Pan2.ar(audio, pan, amp);
	OffsetOut.ar(out, audio);
}).add;
		
	Pseq([
		(	type:		\load,
			filename:	"sounds/a11wlk01.wav",
			bufnum:	1,
			delta:		0
		),
		
		Pbind(*[
			instrument:	"playbuf",
			type:		\on,
			id:		-1,
			dur:		 Pseg([0,1],21).linexp(0,1,0.01,2),
			legato:		4,
			startPos:	Pn(Pseg([0,1], 10)),
			bufnum:	1,		
		]),
		(	type:		\free, 
			bufnum: 	1
		)
	]).play(quant: 0) 
// the result: [ ( 'midinote': 60 ), ( 'midinote': 64 ), ( 'midinote': 67 ) ]



﻿Figure 6.14.  Yield versus EmbedInStream
	r = Routine{ 
		Pseq([1,2,3]).yield; 
		Pseq([1,2,3]).embedInStream;
		123445.embedInStream; 
		123445.embedInStream; 
	};

	[next(r), next(r), next(r), next(r), next(r), next(r)];
	// the result: [ a Pseq, 1, 2, 3, 123445, 123445, nil]




﻿Figure 6.15. The definition of the stream created by Pseq.
	Routine({
		repeats.value.do({
			list.size.do({ arg i;
				item = list.wrapAt(i + offsetValue);
				inval = item.embedInStream(inval);
			});
		});
	});




﻿Figure 6.16.  The definition of Event’s play method.
	play {
		if (parent.isNil) { parent = defaultParentEvent };
		this.use { ~play.value };
	}




﻿Figure 6.17. Definition of the key \play in the default event
{
	var tempo, server;
	
	~finish.value;						// user callback 
	server = ~server ?? { Server.default };	 
	tempo = ~tempo;					// assigning to a variable
									// saves repeated look ups
	if (tempo.notNil) {					// if not nil, change tempo of
		thisThread.clock.tempo = tempo;	// the clock playing the pattern
	};
	~eventTypes[~type].value(server);		// select play function from ~type
}




﻿Figure 6.18.  Implementation of the event type \bus.
	{ |server|
		var lag, array;
		lag = ~lag + server.latency;
		array = ~array.asArray;
		server.sendBundle(lag, 
			[\c_setn, ~out.asUGenInput, array.size] ++ array);
	}


﻿
Figure 7.1
(
Task {
	x = 4; y = 13;
	loop {
		x = (x * y) % 11;
		(note: x.postln, dur: 0.125).play;
		0.125.wait;
	}
}.play
);		// creates a loop of values

// change x and y
x = 5;	// new initial value
y = 4;	// new multiplication factor





﻿Figure 7.2
(
{
	x = SinOsc.kr(4); 
	y = SinOsc.kr(13);
	SinOsc.ar(x * y % 0.4 * 500 + 600) * 0.2
}.play;
)

// change x and y?
x = SinOsc.kr(4); // no effect.
y = SinOsc.kr(4); // no effect either.





﻿

 Figure 7.3

p = ProxySpace.push;
~x = { SinOsc.kr(4) }; 
~y = { SinOsc.kr(13) };
~z = { SinOsc.ar(~x * ~y % 0.4 * 500 + 600) * 0.2 };
~z.play;

	
// now ~x and ~y can be replaced
~x = { SinOsc.kr(0.4) }; 
~y = { SinOsc.kr(1.3) }; 

p.clear(2).pop; // release environment (2 sec fadeout)




﻿

Figure 7.4

p = ProxySpace.push;	// if needed

~a = { Lag.ar(LFClipNoise.ar(2 ! 2, 0.5, 0.5), 0.2) };
(
~b = {
	var c, d;
	c = Dust.ar(20 ! 2);
	d = Decay2.ar(c, 0.01, 0.02, SinOsc.ar(11300));
	d + BPF.ar(c * 5, ~a.ar * 3000 + 1000, 0.1)
}
);

~b.play;

// the refactored code from above

(
~a = { 
	var a;
	a =  Lag.ar(LFClipNoise.ar(2 ! 2, 0.5, 0.5), 0.2);
	BPF.ar(~c.ar * 5, a * 3000 + 1000, 0.1) 
}
);
~c = { Dust.ar(20 ! 2) };
~d = { Decay2.ar(~c.ar, 0.01, 0.02, SinOsc.ar(11300)) };
~b = ~a + ~d;

~b.play;






﻿Figure 7.6

// self reference (~x) constructs a loop at control rate 

~out.play;
~x = 0.2; ~a = 1.1; ~c = 0.13;
~x = (~a * ~x) + ~c % 1.0;  // leaving out the .kr message assumes a control rate ugen.

~out = { Pan2.ar(SinOsc.ar(~x * 4000 + 200) * 0.1, ~x) };




﻿Figure 7.7

n = NodeProxy.new;
x = { SinOsc.ar(n.kr * 200 + 300) * 0.1 }.play;
n.source = { LFPulse.kr([1.3, 2.1, 3.2]).sum };
n.clear; x.free;




﻿Figure 7.8

Ndef(\out, { SinOsc.ar(Ndef.kr(\x) * 200 + 300) * 0.1 }).play;
Ndef(\x, { LFPulse.kr([1.3, 2.1, 3.2]).sum });
Ndef.clear;



﻿Figure 7.9

p = ProxySpace.push; // if needed
~out = { SinOsc.ar(~x.kr * 200 + 300) * 0.1 }
~out.play;
~x = { LFPulse.kr([1.3, 2.1, 3.2]).sum };
p.clear.pop;




﻿Figure 7.10

p.clear; // neutralize space, free all buses and synths
p.push; // if needed
~a.ar(3); // 3 channels, audio rate
~b.kr(8); // 8 channels, control rate
~c.play; // playing an uninitialized proxy assumes (per default) 2 channels, audio rate
~d = { LFNoise0.kr([1, 1, 1, 1]) }; // 4 channels, control rate




﻿
Figure 7.11

~out.play; ~out.fadeTime = 3;
(
// name with a_ represents audio rate argument
~out = { |freq=440, mod=0.4, detune=0.1, a_in = #[1,1]|
	freq = freq * ([0, detune] + 1);
	LFTri.ar(LFTri.ar(mod * freq).range(freq * mod, freq)) * a_in * 0.2
}
);

(
~mod2 = { LFNoise1.kr(1).range(0, 1) };
~mod1 =  { LFPulse.kr(~mod2.kr * 30 + 1, 0, 0.3) };
~freq1 = { ~mod1.kr * 13100 + 100 };
~freq2 = { LFTri.kr(30) * 200 + 300 };
~audio1 = { BrownNoise.ar(LFClipNoise.kr(10.dup), 1) };
~audio2 = { SinOsc.ar(LFNoise2.kr(1.dup).exprange(4, 1000)) };
);

~out.map(\freq, ~freq2, \mod, ~mod1);
~out.set(\detune, 0.01);
~out.map(\freq, ~freq1, \mod, ~mod1);
~out.xmap(\freq, ~freq1, \mod, ~mod2); // xmap crossfades over fade time to new value.
~out.xmap(\freq, ~freq2, \mod, ~mod1, \a_in, ~audio2);
~out.map(\a_in, ~audio1);




﻿
Figure 7.12

// this synthdef is used in the subsequent figures
(
SynthDef(\wave, { |out, freq=440, amp=0.1, sustain=0.1, mod=0.2|
	OffsetOut.ar(out,
		EnvGen.ar(Env.perc(ExpRand(0.001, 0.05), sustain, amp), doneAction: 2)
		*
		SinOsc.ar(freq, SinOsc.ar(sustain.reciprocal * 8, [0, Rand(0, pi)], mod))
	)
}).add
);
(
Tdef(\x, {
	x = 4; y = 13;
	loop {
		x = (x * y) % 11;
		(instrument: \wave, note: x.postln, sustain: 0.5, octave: 6).play;
		0.125.wait;
	}
}).play
);




﻿Figure 7.13

(

Tdef(\a, { 10.do { (instrument: \wave, freq: 50.rand + 1500).play; 0.03.wait } });
Tdef(\b, { [1, 5, 1, 2, 8, 4, 12].do { |x| (instrument: \wave, note: x + 8).play; 0.1.wait } });
Tdef(\c, { "c is just a waiting message".postln; 2.wait; });


Tdef(\x, {
	loop {
		Tdef(\a).embed; // play in sequence
		1.wait;
		Tdef(\b).embed;
		2.wait;
		Tdef(\a).fork; // play in parallel
		Tdef(\b).fork;
		Tdef(\c).embed;
	}
}).play
);

// rewrite with infinite loop
Tdef(\a, { inf.do { (instrument: \wave, freq: 50.rand + 500).play; 0.1.wait } }); 
// rewrite with finite loop
Tdef(\a, { 10.do { (instrument: \wave, freq: 50.rand + 500).play; 0.1.wait } });




﻿
Figure 7.14
(
Tdef(\a, { |in|
	in.at(\n).do { |i| 
		in = (instrument: \wave, detune: 5.rand2).putAll(in);
		in.postln.play; 
		in.delta.wait;
	} 
})
);

(
Tdef(\x, { |inevent|
	loop {
		Tdef(\a).embed((note: [15, 17], dur: 0.01, n: 13));
		1.wait;
		Tdef(\a).embed((note: 9, dur: 0.4, n: 4));
		1.wait;
	}
}).play;
)





﻿

Figure 7.15

Pdefn(\x, Pseq([0, 2, 0, 7, 6, 5, 4, 3], inf));
(
Task {
	var stream = Pdefn(\x).asStream;
	var val;
	loop { 
		val = stream.next; 
		(instrument: \wave, note: val).play; 
		0.2.wait 
	}
}.play
);

Pdefn(\x, Pseq([0, 2, 0, 8, 6, 5, 2, 3, 4, 5], inf)); // rewrite the definition at runtime.
Pdefn(\x, Pseq([0, 2, 0, 7, 6, 5, 4, 3].scramble + 4, inf));




﻿Figure 7.16

Pdefn(\y, Pdefn(\x) + 2); // derive a transposition
Pdefn(\z, Pdefn(\x) + Pseq([0, 5, 0, 7, 2], inf)); // derive a variation
Pdefn(\a, Ptuple([Pdefn(\y), Pdefn(\z)])); // combine them in a stream of arrays
(
Task {
	var stream = Pdefn(\a).asStream;
	var val;
	loop { 
		val = stream.next.postln; 
		(instrument: \wave, note: val, sustain: rrand(0.5, 0.9)).play; 
		0.2.wait 
	}
}.play
);

// rewriting the definitions causes all derivations to vary
Pdefn(\x, Pseq([0, 11], inf));
Pdefn(\x, Pseq([0, 2, 0, 7, 6, 5, 4, 3].scramble + 5, inf));
Pdefn(\z, Pdefn(\x) + Pseq([1, 5, 1, 11, 1], inf)); // change a variation

Pdefn(\a, 5); // a number as a source
Pdefn.clear; // clearing all - the empty pattern returns a series of 1. 




﻿Figure 7.17

Pdef(\a).play; // play silence in sequence
Pdef(\a, Pbind(\instrument, \wave)); // insert a sequence of notes
Pdef(\a, Pbind(\instrument, \wave, \dur, Pseq([1, 3, 2, 3], inf) / 6)); // add some rhythm
Pdef(\a).pause;
Pdef(\a).resume;
Pdef(\a).stop;




﻿
Figure 7.18

(
(
Pdef(\x,
	Pbind(
		\instrument, \wave,
		\mod, Pseq([1, 0, 1, 0], inf), 
		\dur, Pn(1/2, 8),
		\note, 7
	)
)
);

(
Pdef(\y,
	Pbindf(
		Pdef(\x),
		\amp, 0.2,
		\note, Pshuf([0, 2, 3, 5], 2) + Prand([0, 5, [0, 4]], inf),
		\dur, Pseq([1, 3, 2, 3], inf) / 6
	)
)
);

(
Pdef(\z, Pbindf(Pdef(\y), \dur, 1/4))
);

// the combination of all placeholders into a new placeholder
(
Pdef(\a,
	Pmul(\dur, Pwhite(-0.02, 0.02) + 1,
		Pseq([
			Ppar([Pdef(\x), Pdef(\y)]),
			Pdef(\x),
			Pdef(\y),
			Pdef(\z),
			Ppar([Pdef(\x), Pbindf(Pdef(\y), \ctranspose, 2)])
		], inf)
	)
);
))

Pdef(\a).play; // play it

// go into a looping vamp
(
Pdef(\x,
	Pbind(
		\instrument, \wave, 
		\dur, Pseq([1, 3, 2, Prand([3, 2])], inf) / 6,
		\octave, [6, 4]
	)
)
);

// release a break
(
Pdef(\x,
	Pbind(
		\instrument, \wave, 
		\dur, Pseq([1, 3, 2, Prand([3, 2])], 1) / 6,
		\octave, [6, 4]
	)
)
);

Pdef(\a).stop; // stop the player





﻿Figure 7.19

// the combination of all placeholders into a new placeholder
(
Pdef(\b, Pbindf(Pdef(\y), \ctranspose, 2));
Pdef(\a,
	Pmul(\dur, Pwhite(-0.02, 0.02) + 1,
		Psym(Pseq([[\x, \y], \x, \y, \z, [\x, \b]], inf).trace) // trace it to post which
	)
).play;
)



﻿
Figure 7.20

(
Pdefn(\sequence, Pseq([[\x, \y], \x, \y, \z, [\x, \b]], inf));
Pdef(\a,
	Pmul(\dur, Pwhite(-0.02, 0.02) + 1,
		Psym(Pdefn(\sequence).trace)
	)
).play;
)

// rewrite the sequence
Pdefn(\sequence, Pseq([\x], inf));
Pdefn(\sequence, Pseq([\x, \y, \x, [\x, \y]], inf));

Pdef(\a).stop; // stop playing






﻿Figure 7.21

(instrument: \x, type: \phrase).play; // a single phrase from Pdef(\x)

// a pattern of overlapping phrases
(
Pbind(
	\type, \phrase, 
	\instrument, \x, 
	\legato, 2.5, 
	\note, Pseq([0, 5, 7], inf)
).play
);



﻿
Figure 7.22
(
Pdef(\x, { |note=0, n=6, step=3, modulo=15, sustain=1|  
	Pbind(
		\instrument, \wave,
		\note, note.value + (Pseries(1, step, n) % modulo) + 7, 
		\dur, sustain.value / n
	) 
})
);

(
Pdef(\a, 
	Pbind(
		\type, \phrase,
		\instrument, \x,
		\note, Pseq([0, 5, 4, 8, 0], inf),
		\n, 5,
		\modulo, Pseq([3, [4, 3, 5], [13, 15]], inf),
		\dur, Pseq([1, 2, 0.5, 1.5], inf)
	)
).play
);

(
Pdef(\a, 
	Pbind(
		\type, \phrase,
		\instrument, \x,
		\note, Pseq([0, 5, 4, 8, 0], inf),
		\n, 5,
		\modulo, Prand([3, [4, 3, 5], [13, 15]], inf),
		\recursionLevel, 1,
		\dur, Pseq([1, 2, 0.5, 1.5], inf) * 2
	)
).play
);





﻿
Figure 7.25

(
SynthDef(\train, { |out, xfreq=15, sustain=1.0, amp=0.1, pan|
	Line.ar(1, 1, sustain, doneAction:2);
	OffsetOut.ar(out, Pan2.ar(Impulse.ar(xfreq), pan, amp));
}).add
);

p = ProxySpace.push;
~z.play;

// A pattern in an audio rate node proxy ...
(
~x = Pbind(
	\instrument, \train, 
	\xfreq, Pseq([50, Pwhite(30, 800, 1), 5, 14, 19], inf), // only non-standard keys, i.e. xfreq 
	\sustain, Pseq([Pwhite(0.01, 0.1, 1), 0.1, 1, 0.5, 0.5], inf),
	\pan, Prand([-1, 1], inf) * 0.1
)
);
~y = { Ringz.ar(~x.ar, 5000 * [1, 1.2], 0.01) }; // resonant filter on the impulses from ~x
~mod = { LFNoise1.kr(0.1).exprange(200, 5000) }; // a modulator
~z = { ~y.ar * (SinOsc.ar(~mod.kr) + 1) }; // ring modulation with frequency ~mod

// ... and a control rate node proxy in a pattern.
// To pass on modulation like this, the standard event parameters like freq cannot be used.
// Here, we use xfreq instead.

(
~x = Pbind(
	\instrument, \train, 
	\xfreq, Pseq([50, ~mod, 5, ~mod, 19], inf), // read from the ~mod proxy bus. 
	\sustain, Pseq([Pwhite(0.01, 0.1, 1), 0.1, 1, 0.5, 0.5], inf),
	\pan, Prand([-1, 1], inf) * 0.1
)
);







﻿
Figure 7.26

(
SynthDef(\train, { |out, xfreq=15, sustain=1.0, amp=0.1, pan|
	Line.ar(1, 1, sustain, doneAction:2);
	OffsetOut.ar(out, Pan2.ar(Impulse.ar(xfreq), pan, amp));
}).add
);

Ndef(\z).play;

// a pattern in an audio rate node proxy ...
(
Ndef(\x, Pbind(
	\instrument, \train, 
	\xfreq, Pseq([50, Pwhite(30, 800, 1), 5, 14, 19], inf), 
	\sustain, Pseq([Pwhite(0.01, 0.1, 1), 0.1, 1, 0.5, 0.5], inf),
	\pan, Prand([-1, 1], inf) * 0.1
))
);
Ndef(\y, { Ringz.ar(Ndef(\x).ar, 5000 * [1, 1.2], 0.01) });
Ndef(\mod, { LFNoise1.kr(0.1).exprange(200, 5000) });
Ndef(\z, { Ndef(\y).ar * (SinOsc.ar(Ndef(\mod).kr) + 1) }); // ring modulation with Ndef(\mod)

// ... and a control rate node proxy in a pattern

(
Ndef(\x, Pbind(
	\instrument, \train, 
	\xfreq, Pseq([50, Ndef(\mod), 5, Ndef(\mod), 19], inf), // read from the Ndef(\mod) proxy bus
	\sustain, Pseq([Pwhite(0.01, 0.1, 1), 0.1, 1, 0.5, 0.5], inf),
	\pan, Prand([-1, 1], inf) * 0.1
))
);




﻿
Figure 7.27

Ndef(\x).play; // here an Ndef is used, the same can be done within a ProxySpace
Ndef(\x, { |freq=5, detune=0| Impulse.ar(freq * [detune, 1 - detune]) * 0.2 });
(
Tdef(\c, {
	loop {
		 Ndef(\x).fadeTime = rrand(0.1, 3.5);
		 Ndef(\x).send([\freq, exprand(2, 400), \detune, [0.0, 1.0].choose.rand]);
		2.wait;
	}
}).play
);




﻿//	figure 8.1 - a Puppet class, and tests for it.
	
Puppet { 
	var <>myfreq; // an instance variable with a getter and a setter method
	
		// a method for creating a new object of this kind
	*new { |myfreq=50| ^super.new.myfreq_(myfreq) }
	
		// a simple method that uses 'myfreq' for something audible.
	blip { { Blip.ar(myfreq, 11) * XLine.kr(1, 0.01, 0.6, doneAction: 2) }.play; }
}

	// tests for the behavior implemented so far:
m = Puppet.new(50);// make an instance of Puppet, pass in myfreq

m.dump;			// test that myfreq is set correctly
m.myfreq;			// test accessing myfreq
m.blip;			// should sound
m.myfreq_(100);	// test setting myfreq
m.blip;		 // should sound differently






﻿// figure  8.2 - a puppet modeled as an event.

m = (); 			// make an empty event
m.myfreq_(50);	// put something in it with a setter method: a pseudo-instance variable
m.myfreq;			// look it up with a getter method
				// put a function into it with a setter: 
				// this becomes a pseudo-method
m.blip_({ |ev| { Blip.ar(ev.myfreq, 11) * XLine.kr(1, 0.01, 0.6, doneAction: 2) }.play; });
m.blip;		// execute the function with a pseudo-method call (same name)




﻿// figure  8.3 - add more instance variables, change the blip method.
(
m.numHarms_(20); 	// a new instvar
m.decay_(0.3); 	// and another
				// update the blip method to use them:
m.blip_({ |ev| 
	{ Blip.ar(ev.myfreq, ev.numHarms) 
	* XLine.kr(1, 0.01, ev.decay, doneAction: 2) }.play; 
});
)
m.blip;	// test




﻿//	figure 8.4 - A minimal shout window sketch.

z = z ? (); 	// make an empty event as a pseudo-object
z.win = Window("Shout", Rect(0, 900,1200, 100)).front;
z.txtView = TextView(z.win, Rect(0, 0,1200, 100));
z.txtView.string_("Shout this!");
z.txtView.font_(Font("Monaco", 32));

	// tune appearances
z.win.alpha_(0.7);		// make the window slightly transparent
z.win.view.background_(Color.clear);	// make the window's top view,
z.txtView.background_(Color.clear);	// and textview fully transparent
z.win.alwaysOnTop_(true);	// make sure it is always on top .

z.win.close;	// close when done





﻿// figure 8.5 - add a pseudo-method.
(
z.makeWin = { |z, message="Shout this!"|
	z.win = Window("Shout", Rect(0, 900,1200, 100)).front;
	z.win.alpha_(0.7);	
	z.win.view.background_(Color.clear);	
	z.win.alwaysOnTop_(true);

	z.txtView = TextView(z.win, Rect(0, 0,1200, 100));
	z.txtView.string_(message);
	z.txtView.font_(GUI.font.new("Monaco", 32));
	z.txtView.background_(Color.clear);
};
)
z.makeWin("Try showing that."); 



﻿// figure 8.6 - more pseudo-methods.

z.setMessage = { |z, str| z.txtView.string_(str) };

z.setMessage("Does this update?");	// test
(
z.shout = { |z, str|
	if (z.win.isNil or: { z.win.isClosed }) { z.makeWin };
	z.setMessage(str);
};
)
z.shout("Do we get this?"); // test

z.win.close;
z.shout("Do we get this too?"); // also when window has closed?




﻿// figure 8.7 - text color animation

z.txtView.stringColor_(Color.red);	// try a single color
(
z.animate = { |z, dt=0.2, n = 6| 
	var colors = [Color.red, Color.green, Color.black];
	Task { 
		n.do { |i| 
			dt.wait; 
			z.txtView.stringColor_(colors.wrapAt(i))
		}
	}.play(AppClock)
};
)
z.animate;			// test with default values 
z.animate(0.1, 24); 	// and test with arguments given





﻿// figure 8.9 - using codeDump to shout 

this.codeDump = { |str, result, func| [str, result, func].printAll };

a = 1 + 2;	// code appears in post window

z.shoutTag = "//!!";
this.codeDump = { |str| if (str.beginsWith(z.shoutTag)) { z.shout(str.drop(z.shoutTag.size)) } };

//!! a comment with a 'shout tag' now gets shouted!






﻿
	//	figure 8.10 - updated setMessage flashes text.
(
z.setMessage = { |z, str| 
	var messSize = str.size; 
	var fontsize = (1.64 * z.txtView.bounds.width) / max(messSize, 32);
	z.txtView.font_(GUI.font.new("Monaco", fontsize));
	z.txtView.string_(str);
	z.animate;
};
)
//!! a long comment gets scaled down to a rather smaller font size, minimally fontsize 32! 

//!! short is big!
(
z.makeWin = { |q, message="Shout this!"|
	z.win = Window("Shout", Rect(0, 900,1200, 100)).front;
	z.win.alpha_(0.7);	
	z.win.view.background_(Color.clear);	
	z.win.alwaysOnTop_(true);

	z.txtView = TextView(z.win, Rect(0, 0,1200, 100));
	z.txtView.background_(Color.clear);
	z.setMessage(message);
};
)
z.makeWin("shout.");




﻿	//	figure 8.11 - a Shout class

// begin of file - Shout.sc
Shout {
	classvar <>tag="//!!";
	var <win, <txtView;
	
	*new { ^super.new }
} 
// end of file - Shout.sc

// tests: 
Shout.tag;
Shout.tag_("//SHOUT");

a = Shout.new; 
a.win;
a.txtView;




﻿
	// figure 8.12 - more class variables and initClass method.

// begin of file - Shout.sc
Shout {
	classvar <>tag="//!!", <>width=1250, <>defaultCodeDumpFunc; 
	var <win, <txtView;
	
	*initClass { 
		defaultCodeDumpFunc = { |str| if (str.beginsWith(tag)) { Shout(str.drop(tag.size)) } };
	}
	*new { ^super.new }
} 
// end of Shout.sc

Shout.width;
Shout.defaultCodeDumpFunc;



﻿
	// figure 8.13 - converting makeWin.

z.makeWin = { |message="Shout this!"|
	z.win = GUI.window.new("Shout", Rect(0, 900,1200, 100)).front;
	z.win.alpha_(0.7);	
	z.win.view.background_(Color.clear);	
	z.win.alwaysOnTop_(true);

	z.txtView = GUI.textView.new(z.win, Rect(0, 0,1200, 100));
	z.txtView.background_(Color.clear);
	z.setMessage(message);
};


Shout {	
	...
	*new { |message| ^super.new.makeWin(message); }
	
	makeWin { |message="Shout this!"| 
	
		win = Window("Shout'er", Rect(20, 800, width, 80)).front;
		win.alpha_(0.7);
		win.view.background_(Color.clear);
		win.alwaysOnTop_(true);
		
		txtView = TextView(win, win.bounds.moveTo(0,0));
		txtView.background_(Color.clear);
		txtView.font_(Font.new("Monaco", 32));
		this.setMessage(message);
	}

	setMessage { |message| 
		txtView.string_(message.asString)
	}
}

// tests:
Shout.new;
a = Shout.new("Blabla");
a.setMessage("Otto");





﻿
	//	figure 8.14 - converting z.shout to Shout.new.

z.shout = { |z, str|
	if (z.win.isNil or: { z.win.isClosed }) { z.makeWin };
	z.setMessage(str);
};

Shout { 
	classvar <top;
	...
	*new { |message="¡Shout'er!"| 

		if (top.isNil or: { top.win.isClosed }) { 
			top = this.basicNew(message); 
		} {
			top.setMessage(message);
		};
	}
		// the method formerly known as *new
	*basicNew { |message="Shout this!"| ^super.new.makeWin(message) } 

	*close { try { top.win.close } }
	
	...
}

// tests: 
Shout("Test 1, 2");
Shout("Test 1, 2, 3, 4");	// same window
Shout.close;

Shout("Test 1, 2");		// new window








﻿	//	figure 8.15 - converting animate to a class method.

z.animate = { |z, dt=0.2, n = 6| 
	var colors = [Color.red, Color.green, Color.black];
	Task { 
		n.do { |i| 
			dt.wait; 
			z.txtView.stringColor_(colors.wrapAt(i))
		}
	}.play(AppClock)
};

Shout { 
	...
	animate { |dt=0.2, n=6|
		var colors = [Color.red, Color.green, Color.black]; 
		Task { 
			n.do { |i| 
				txtView.stringColor_(colors.wrapAt(i)); 
				dt.wait 
			};
			txtView.stringColor_(Color.black); // make sure we end black
		}.play(AppClock);
	}
	...	
}

// tests: 
a = Shout("Test 1, 2");
Shout.top.animate;





﻿
	// figure 8.16 - converting setMessage

z.setMessage = { |z, str| 
	var messSize = str.size; 
	var fontsize = (1.64 * z.txtView.bounds.width) / max(messSize, 32);
	z.txtView.font_(Font.new("Monaco", fontsize));
	z.txtView.string_(str);
	z.animate;
};

Shout { 
	...
	setMessage { |message| 
		var messSize, fontSize;
		messSize = message.size;
		fontSize = (1.64 * width) / max(messSize, 32);
		
		defer { 
			txtView.font_(Font("Monaco", fontSize))
				.string_(message.asString);
		};
		this.animate;
	}
	...	
}

Shout("Test 1, 2");
Shout("Test" + (1..16));




﻿//	figure 8.17 - codeDump tests and usage in Shout

this.codeDump.postcs;	// anything there yet? by default, this is nil.
this.codeDump = this.codeDump.addFunc(Shout.defaultCodeDumpFunc); // add Shout
this.codeDump.postcs	// should be there now
//!! test whether Shout works now
this.codeDump = this.codeDump.removeFunc(Shout.defaultCodeDumpFunc);
this.codeDump.postcs	// should be gone now

//!! should be off again

Shout { 
	...
	*add { var interp = thisProcess.interpreter; 
		interp.codeDump = interp.codeDump
			.removeFunc(defaultCodeDumpFunc) // remove it first so it will 
										// only be in the list once
			.addFunc(defaultCodeDumpFunc); 
	}
	*remove { var interp = thisProcess.interpreter; 
		interp.codeDump = interp.codeDump.removeFunc(defaultCodeDumpFunc); 
	}
	...	
}

// tests
Shout.add;
//!! test whether Shout works now - it should!
Shout.remove;
//!! test whether Shout works now - should be off.









﻿//	figure 8.18 - keeping Shout out of the way

Shout.close;
Shout("blabla");	// now typing is impossible, because the new window is in front.

Shout("blabla blabla");	// now one can type, because Shout window was already there.
Shout.close; 

	// this does not work, because the shout window gets put in front later:
d = Document.current; Shout(\bla); d.front; 
 

	// This can be wrapped around the call to this.makeWin in Shout:new:
Shout { 
	...
	*new { |message="¡Shout'er!"| 
		var currDoc;

		if (win.isNil or: { win.isClosed }) { 
			currDoc = Document.current;
			top = this.basicNew(message); 
				// wait a little before restoring front window
			defer ({ currDoc.front }, 0.1);
		} {
			top.setMessage(message);
		};
	}
	...	
}





﻿
	// figure 8.19 - a fixed serialization method.

serialize {|index, pos, extent = 8|
	var ranges, slice;

	// get ranges
	ranges = pos.collect{|pos, i| 
		((pos-(extent*0.5))..(pos+(extent*0.5)-1)) % this.shape[i] 
	};
	// get sub-slice
	slice = this.slice(index, *ranges);
	// trivial serialization of multidim. slice
	^slice.flat
}




﻿
	// figure 8.20 - flexible  serialization by lookup.

serialize {|index, pos, extent = 8, how = \hilbert|
	// [...]
	slice = this.slice(index, *ranges);
	// call function in serTypes dictionary
	^serTypes[how].(slice.asArray, extent)
}





﻿

// figure 8.21 — some initial serialization methods, and adding an alternative. 

	*initClass {|numDims = 4|
		...
		// slice here is a 4d hypercube of extent <extent>
		serTypes = (
			hilbert: {|slice, extent|
				extent.isPowerOfTwo.not.if({
					"QCD:serialize: extent has to be a power of two".error
				});
				HilbertIndices.serialize(slice)
			},
			torus: {|slice, extent|
				slice.flat;
			},
			scramble: {|slice|
				slice.flat.scramble;
			}
		);
	}

	// add a new serialization type at runtime
QCD.serTypes.put(\star, {|slice|
	var starSize = slice.size div:2;
	var numDims = 4;
	var starShape;

	starShape = neighbours1.collect({ |nb|  
		(0..starSize).collect(_ * nb) 
	}).flatten(1).collect {|indexN| 
		indexN + (starSize.div(2)+1).dup(numDims) 
	};
	
	starShape.collect{|iA| slice.slice(*iA)}
});




﻿// figure 8.23 - two granular synthdefs and tests
(
	// a gabor (approx. gaussian-shaped) grain
SynthDef(\gab1st, { |out, amp=0.1, freq=440, sustain=0.01, pan| 
	var snd = FSinOsc.ar(freq);
	var env = EnvGen.ar(Env.sine(sustain, amp * AmpComp.ir(freq) * 0.5), doneAction: 2);
	OffsetOut.ar(out, Pan2.ar(snd * env, pan));
}, \ir ! 5).add;


			// a simple percussive envelope
SynthDef(\percSin, { |out, amp=0.1, freq=440, sustain=0.01, pan| 
	var snd = FSinOsc.ar(freq);
	var env = EnvGen.ar(
		Env.perc(0.1, 0.9, amp * AmpComp.ir(freq) * 0.5), 
			timeScale: sustain, doneAction: 2
		);
	OffsetOut.ar(out, Pan2.ar(snd * env, pan));
}, \ir ! 5).add;


/*	
	// tests for the synthdefs:
Synth(\gab1st);
Synth(\percSin);
Synth(\percSin, [\amp, 0.2, \sustain, 0.1]);
Synth(\gab1st, [\out, 0, \amp, 0.2, \freq, 2000, \sustain, 0.05, \pan, 0.5] );
*/
);



﻿
	// figure 8.24 - global setup and a player Tdef for the cloud.
(
q = q ? (); 

	// some globals
q.paramRNames = [\freqRange, \durRange, \densRange, \ampRange, \panRange]; 
q.paramNames = [\freq, \grDur, \dens, \amp, \pan]; 
q.syndefNames = [\gab1st, \gabWide, \percSin, \percSinRev, \percNoise];

	// specs for some parameters
Spec.add(\xfadeTime, [0.001, 1000, \exp]);
Spec.add(\ring, [0.03, 30, \exp]);
Spec.add(\grDur, [0.0001, 1, \exp]);
Spec.add(\dens, [1, 1000, \exp]);

	// make an empty tdef that plays it, 
	// and put the cloud parameter ranges in the tdef's environment
Tdef(\cloud0)
	.set(
	\synName, \gab1st,
	\vol, 0.25,
	\current, (
		freqRange: [200, 2000],
		ampRange: [0.1, 1],
		durRange: [0.001, 0.01], 
		densRange: [1, 1000],
		panRange: [-1.0, 1.0] 
	)
); 
		
		// make the tdef that plays the cloud of sound particles here, 
		// based on parameter range settings.
Tdef(\cloud0, { |e| 

	loop {
		s.sendBundle(s.latency, [
			"/s_new", e.synName ? \gab1st, 
			-1, 0, 0,
			\freq, 	exprand(e.current.freqRange[0], e.current.freqRange[1]),
			\amp,	exprand(e.current.ampRange[0], e.current.ampRange[1]) * e.vol,
			\sustain,	exprand(e.current.durRange[0], e.current.durRange[1]),
			\pan, 	rrand(e.current.panRange[0], e.current.panRange[1])
		]);
		exprand(e.current.densRange[0].reciprocal, e.current.densRange[1].reciprocal).wait; 
	}
}).quant_(0);	
);





﻿// figure  8.25	-  tests for the cloud
	
Tdef(\cloud0).play;

	// try changing various things from outside the loop. 
	// change its playing settings 

Tdef(\cloud0).envir.current.put('densRange', [ 50, 200 ]); // dense, async
Tdef(\cloud0).envir.current.put('densRange', [ 1, 10 ]);  // sparse, async
Tdef(\cloud0).envir.current.put('densRange', [ 30, 30 ]); // synchronous

	// for faster access, call the tdef's envir d
d = Tdef(\cloud0).envir;
d.current.put('freqRange', [ 800, 1200 ]);
d.current.put('durRange', [ 0.02, 0.02 ]);

d.current.put('ampRange', [ 0.1, 0.1 ]);

d.current.put('panRange', [ 1.0, 1.0 ]);
d.current.put('panRange', [ -1.0, 1.0 ]);

d.current.put('densRange', [ 30, 60 ]);
d.synName = \percSin;
d.synName = \gab1st;
d.current.put('durRange', [ 0.001, 0.08 ]);




﻿
	// figure 8.26 - making random settings, and 8 random presets to switch between
(
	// make the Tdef's envir a global variable for easier experimenting
d = Tdef(\cloud0).envir;
	// a pseudo-method to make random settings, kept in the Tdef's environment
		// randomize could also do limited variation on existing setting. 
d.randSet = { |d|
	var randSet = ();	
	q.paramRNames.do { |pName, i| 
		randSet.put(pName, 
			q.paramNames[i].asSpec.map([1.0.rand, 1.0.rand].sort)
		);
	};
	randSet;
};

/* 	test randSet: 
d.current = d.randSet;
*/

// make 8 sets of parameter range settings: 
d.setNames = (1..8).collect { |i| ("set" ++ i).asSymbol };
d.setNames.do { |key| d[key] = d.randSet; }

/*	test switching to the random presets
d.current = d.set1.copy;	// copy to avoid writing into a stored setting when it is current.
d.current = d.set3.copy;	
d.current = d.set8.copy;
*/
);




﻿
	// ex. 8.27 - crossfading between different settings with a taskproxy
	
(
	// and some parameters for controlling the fade
d.stopAfterFade = false;
d.xfadeTime = 5; 

d.morphtask = TaskProxy({
	var startSet = d[\current], endSet = d[\target];
	var stepsPerSec = 20;
	var numSteps = d.xfadeTime * stepsPerSec;
	var blendVal, morphSettings;
	
	if (d.target.notNil) { 
		(numSteps).do { |i| 
		//	["numSteps", i].postln;
			blendVal = (i + 1) / numSteps; 
			morphSettings = endSet.collect({ |val, key| 
				(startSet[key] ? val).blend(val, blendVal) 
			});
			d.current_(morphSettings);
			(1/stepsPerSec).wait;
		};
		d.current_(d.target.copy);
		"morph done.".postln;
		if (d.stopAfterFade) { Tdef(\cloud0).stop; };
	};
}).quant_(0);		// no quantization so the task starts immediately

/* test morphing
(
Tdef(\cloud0).play;
d.target = d.set6.copy;
d.morphtask.play;
)
Tdef(\cloud0).stop;

	// playing a finite cloud with tendency mask: 
(
Tdef(\cloud0).play;		// begin playing
d.stopAfterFade = true; 	// end cloud when crossfade ends
d.xfadeTime = 10; 			// set fade time
d.target = d.set8.copy;		// and target
d.morphtask.play;			// and start crossfade.
)
*/

	// put fading into its own method, with optional stop.
d.fadeTo = { |d, start, end, time, autoStop| 
	d.current = d[start] ? d.current;
	d.target = d[end]; 
	d.xfadeTime = time ? d.xfadeTime;
	if (autoStop.notNil) { d.stopAfterFade = autoStop };
	d.morphtask.stop.play;
};

/* 	// tests fadeTo:
Tdef(\cloud0).play;
d.fadeTo(\current, \set2, 20);
d.fadeTo(\current, \set6, 10);
d.fadeTo(\current, \set5, 3, true);

Tdef(\cloud0).play;
d.fadeTo(\current, \set1, 3, false);
*/ 
);





﻿// figure 8.29 - a lightweight graphical user interface for CloudGenMini 
(
q.makeCloudGui = { |q, tdef, posPoint| 
	var w, ezRangers, fdBox; 
	var setMinis, skipjack; 
	
	posPoint = posPoint ? 400@400;	// where to put the gui window
	
	w = Window.new("CloudGen_mini_sc3", 
		Rect.fromPoints(posPoint, (posPoint + (400@320))), false).front;	w.view.decorator_(FlowLayout(w.bounds.copy.moveTo(0, 0)));
		
	w.view.decorator.nextLine; 
		// the range sliders display the current values
	ezRangers = ();
	
	q.paramRNames.do { |name, i| 
		ezRangers.put(name, 
		EZRanger(w, 400@20, name, q.paramNames[i], 
			{ |sl| tdef.envir.current[name] = sl.value; }, 
			tdef.envir.current[name], labelWidth: 70, numberWidth: 50, unitWidth: 10)
			.round_([0.1, 0.00001, 0.0001, 0.0001, 0.01][i])
		);
	};
		// a just in time - gui for the Tdef
	TdefGui(tdef, parent: w); 

	w.view.decorator.nextLine;
	
	Button.new(w, 80@20).states_([[\randomize]])
		.action_({ 
			tdef.envir.target_(d.randSet);
			tdef.envir.morphtask.stop.play;
		});
	
	fdBox = EZNumber.new(w, 110@20, \xFadeTime, [0, 100, \amp], 
		{ |nbx| tdef.envir.xfadeTime = nbx.value }, 
		 tdef.envir.xfadeTime, false, 65); 

			// skipjack is a task that survives cmd-period:
			// used here for lazy-updating the control views.
	skipjack = SkipJack({  
		q.paramRNames.do { |name| ezRangers[name].value_(tdef.envir.current[name]) };
		fdBox.value_(tdef.envir.xfadeTime); 
		
		// mark last settings that were used by color? 
		// a separate color when changed? 
		
	}, 0.5, { w.isClosed }, name: tdef.key);
	
	w.view.decorator.nextLine;

	// make a new layoutView for the 8 presets; 
	// put button to switch to that preset, 
	// a button to save current settings to that place, 
	// and a miniview of the settings as a visual reminder in it.
	
		// make 8 setButtons
	tdef.envir.setNames.do { |setname, i|	
		var minisliders, setMinis;
		var zone = CompositeView.new(w, Rect(0,0,45, 84));
		zone.decorator = FlowLayout(zone.bounds, 0@0, 5@0); 
		zone.background_(Color.white); 
		
		Button.new(zone, Rect(0,0,45,20)).states_([[setname]])
			.action_({ 
				// just switch: // tdef.envir.current.putAll(d[setname] ? ()) 
				tdef.envir.target = tdef.envir[setname];
				tdef.envir.morphtask.stop.play;
			});
		
		Button.new(zone, Rect(0,0,45,20))
			.states_([["save" ++ (i + 1)]])
			.action_({ 
				d[setname] = tdef.envir.current.copy; 
				setMinis.value;
			});
		
		minisliders = q.paramRNames.collect { |paramRname| 
			RangeSlider.new(zone, 45@8).enabled_(false);
		};
		setMinis = { 
			q.paramRNames.do { |paramRname, i| 
				var paramName = q.paramNames[i];
				var myrange = d[setname][paramRname];
				var unmapped = paramName.asSpec.unmap(myrange); 
				minisliders[i].lo_(unmapped[0]).hi_(unmapped[1]);
			} 
		};
		setMinis.value;
	};

/* 	Some extras: 
	a volume slider for simple mixing, 
	a popup menu for switching syndefnames; 
	a button to stop/start the skipjack for refreshing, 
	so one can use numberboxes to enter values.
*/
	EZSlider(w, 245@20, "vol", \amp, { |sl|tdef.set(\vol, sl.value) }, 
		0.25, false, 20, 36);

	StaticText.new(w, 55@20).string_("synthdef:").align_(\right); 
	PopUpMenu.new(w, Rect(0,0,80,20))
		.items_([\gab1st, \gabWide, \percSin, \percSinRev, \percNoise])
		.action_({ |pop| tdef.envir.synName = pop.items[pop.value] });
	
	Button.new(w, 80@20).states_([[\continuous], [\fadeStops]])
		.value_(tdef.envir.stopAfterFade.binaryValue)
		.action_({ |btn|
			tdef.set(\stopAfterFade, btn.value == 1)
		});

	Button.new(w, 80@20).states_([[\skipWatching], [\skipWaiting]])
		.action_({ |btn|
			[ { skipjack.play }, { skipjack.stop }][btn.value].value
		});

};
q.makeCloudGui(Tdef(\cloud0))
);





﻿figure 9.2

(
var window, slider, mySynth;
mySynth = Synth(\default);
window = SCWindow("myWindow", Rect(100,100, 220, 40));
slider = SCSlider(window, Rect(8,4, 200, 20))
		.value_(440.explin(20,20000,0,1))
		.action_({|view| 
			mySynth.set(\freq,
				view.value.linexp(0,1,20,20000).postln
			)	
		})
		.onClose_({mySynth.release;});
window.front;
CmdPeriod.doOnce({window.close});
)



﻿
figure 9.3

(
var window, slider, mySynth, spec;
mySynth = Synth(\default);
spec = \freq.asSpec;
window = SCWindow("myWindow", Rect(100,100, 220, 40));
slider = SCSlider(window, Rect(8,4, 200, 20))
		.value_(spec.unmap(440))
		.action_({|view| 
			mySynth.set(\freq,			
				spec.map(view.value).postln
			)
		})
		.onClose_({mySynth.release;});
window.front;
CmdPeriod.doOnce({window.close});
)



﻿figure 9.5

// simple MVC example
(
var window, slider, level, updater, model, numberbox, setValueFunction;

//model
model = (myValue: 1);
setValueFunction = {|value| 
			model [\myValue] = value; 
			model.changed(\value, value);
};

//view
window = SCWindow("myWindow", Rect(100, 100, 288, 80));
numberbox = SCNumberBox(window, Rect(20, 20, 44, 20))
			.value_(model[\myValue])
			.action_({|view| setValueFunction.value(view.value)}); 
slider = SCSlider(window, Rect(68, 20, 200, 20))
			.value_(model[\myValue])
			.action_({|view| setValueFunction.value(view.value)}); 

level = SCLevelIndicator(window, Rect(272, 20, 5, 20))
			.warning_(0.8)
			.critical_(1.0);

window.front;
window.onClose_({model.removeDependant(updater);});

//updater
updater = {|theChanger, what, val| 
					if(what == \value, {
						numberbox.value_(val);
						slider.value_(val);
						level.value_(val);
					});
				};
model.addDependant(updater);

setValueFunction.value(0.4);
)




﻿figure 9.6

(
var window;
window = SCWindow("AppClock").front;
Task({
	100.do{|i|
		window.view.background_(Color.grey(i/100));
		0.04.wait;
	}
}).play(AppClock);
)



﻿figure 9.7

(
var window, slider, updater, model, level, numberbox, setValueFunction, oscresponder;

//model
model = (myValue: 1);
setValueFunction = {|value| 
			model [\myValue] = value; 
			model.changed(\value, value);
};

//view
window = SCWindow("myWindow", Rect(100,100, 288, 80));
numberbox = SCNumberBox(window, Rect(20, 20, 44,20))
			.value_(model[\myValue])
			.action_({|view| setValueFunction.value(view.value)}); 
slider = SCSlider(window, Rect(68,20, 200, 20))
			.value_(model[\myValue])
			.action_({|view| setValueFunction.value(view.value)}); 
level = SCLevelIndicator(window, Rect(272, 20, 5, 20))
			.warning_(0.8)
			.critical_(1.0);
	
window.front;
window.onClose_({model.removeDependant(updater); oscresponder.remove;});

//updater
updater = {|theChanger, what, val| 
					{
					if(what == \value, {
						numberbox.value_(val);
						slider.value_(val);
						level.value_(val);
					});
					}.defer;
				};
model.addDependant(updater);

// play a Synth on the server
SynthDef("send_trig",{
	SendTrig.kr(Dust.kr(2.0), 0, LFNoise1.kr(1, 0.5, 0.5));
}).play(s);

// register to receive the message from the Synth above and let it set the model
oscresponder = OSCresponderNode(s.addr, '/tr', { arg time, responder, msg;
	setValueFunction.value(msg[3]);
}).add;

)



﻿
figure 9.8

(
var window, button, composite, slider, numberbox;
window = SCWindow("myWindow", Rect(100,100, 288, 80));
button = SCButton(window, Rect(4,4, 100, 20))
			.states_([["hide"], ["show"]])
			.action_({|v| 
				if(v.value==0){
					composite.visible_(true)	
				}{
					composite.visible_(false)
				}
			});

composite = SCCompositeView(window, Rect(0, 40, 268, 28))
			.background_(Color.blue);
numberbox = SCNumberBox(composite, Rect(4, 4, 40,20));
slider = SCSlider(composite, Rect(48,4, 200, 20));
	
window.front;
)



﻿
figure 9.10

(
var window, listView, updater, changeItemGui, model;

model = [\item1, \item2, \item3];

window = SCWindow("double click example", Rect(200,200,180, 320)).front;
listView = SCListView(window, Rect(4,4,172, 310))
				.items_(model)
				.mouseDownAction_({|view, x, y, modifiers, buttonNumber, clickCount|
					if(clickCount == 2){
						changeItemGui.value(view)
					}
				})
				.onClose_({model.removeDependant(updater)});

changeItemGui = {|view|
	var win;
	win = SCWindow("chnage item", Rect(200,250, 150, 30)).front;
	SCTextField(win, Rect(4,4, 142, 20))
		.string_(view.item.asString)
		.action_({|v|
			model[view.value] = v.string.asSymbol;
			model.changed(\value);
			win.close;
		})
		.focus;
};

updater = {|theChanger, what, moreArgs|
	listView.items_(theChanger)
};
model.addDependant(updater);

)



﻿
figure 9.11

(
	var window, listViews, model, updater;
	
	model = (	left: [ "SinOsc", "Saw", "LFSaw", "WhiteNoise", "PinkNoise", "BrownNoise", "Osc" ], 
				right: []);
	
	window = SCWindow("list view drag & drop", Rect(200,200, 255, 100)).front;
	window.view.decorator_(FlowLayout(window.view.bounds));
	
	listViews = [\left, \right].collect{|it|
		SCListView(window, Rect(10,10,120,70))
			.items_(model[it])
			.canReceiveDragHandler_{ SCView.currentDrag.isKindOf(Symbol) or: SCView.currentDrag.isKindOf(String)}
			.receiveDragHandler_{|v| 
				var index;
				index = model[it].indexOfEqual(SCView.currentDrag);
				if(index.notNil){
					v.value_(index);
				}{
					model[it] = model[it].add(SCView.currentDrag);
					model.changed(it);
					v.value_(v.items.size-1);
				}
			}
			.beginDragAction_{|v| v.item}
			.action_({|view|
				[view.value, view.item].postln;
			})
			.onClose_({model.removeDependant(updater)});
	};
	
	updater = {|theChanger, what, moreArgs| 
			switch(what, 
				\left, {listViews[0].items_(model[\left])},
				\right, {listViews[1].items_(model[\right])}
			)
			};
	model.addDependant(updater);
)


﻿
figure 9.13


(
var window, userView, value=false;
window = SCWindow("toggle view", Rect(200,200, 166, 66)).front;
userView = SCUserView(window, Rect(10,10, 40,40))
				.drawFunc_({|v|
					var width, height, offset=2;
					width =  v.bounds.width;
					height = v.bounds.height;
					SCPen.use{
						//draw outline and background
						SCPen.strokeRect(Rect(offset, offset, width-(offset*2), height-(offset*2)));
						SCPen.fillColor_(Color.white);
						SCPen.fillRect(Rect(offset, offset, width-(offset*2), height-(offset*2)));

						if(value){
							//draw the toggle cross
							SCPen.line(Point(offset, height-offset), Point(width-offset, offset));
							SCPen.line(Point(offset, offset), Point(width-offset, height-offset));
							SCPen.stroke;

						};
					}
				})
				//switch states on mouse-down
				.mouseDownAction_({|view|
					value = value.not;
					view.refresh;
				});
~win = window;
)





﻿figure 9.14

TToggle : SCUserView{
	var <> value=false;
	
	init{ arg argParent, argBounds;
		super.init(argParent, argBounds);
		background = Color.white
	}
	
	*viewClass{
		^SCUserView
	}
	
	draw{
		var width, height, offset=2;
		width =  this.bounds.width;
		height = this.bounds.height;
		SCPen.use{
			//draw outline and background
			SCPen.strokeRect(Rect(offset, offset, width-(offset*2), height-(offset*2)));
			SCPen.fillColor_(Color.white);				
			SCPen.fillRect(Rect(offset, offset, width-(offset*2), height-(offset*2)));

			if(value){
				//draw the toggle cross
				SCPen.line(Point(offset, height-offset), Point(width-offset, offset));
				SCPen.line(Point(offset, offset), Point(width-offset, height-offset));
				SCPen.stroke;

			};
		}
	}
	
	//override 
	mouseDown{arg x, y, modifiers, buttonNumber, clickCount;
		value = value.not;
		this.refresh;
		mouseDownAction.value(this, x, y, modifiers, buttonNumber, clickCount);	
	}
}


﻿
figure 9.16

(
var createGUIFor, synthDefName, eventForSynthDef;
synthDefName = \default;
SynthDescLib.global.read;

//create a custom ControlSpec if necessary:
ControlSpec.specs.put(\out, ControlSpec(0, 128, \lin, 1, 0));

//model 

eventForSynthDef = {|synthDefName|
	var event, node;
	event = (
			instrument: synthDefName,
			play: {
				var args = event.select{|it| it.isKindOf(Number)}.asKeyValuePairs;
				node = Synth(~instrument, args);
					OSCpathResponder(Server.default.addr, ["/n_end", node.nodeID], 
						{|time, resp, msg| 
							node = nil;
							event.changed(\play, 0); 
							resp.remove;
						} 
					).add;		
				event.changed(\play, 1);
				
			},
			stopPlaying:{
				if( SynthDescLib.global[synthDefName].hasGate) {
					node.release;
				}{
					node.free;					
				};
				node = nil;
				event.changed(\play, 0);
				
			},
			setArg: {|inevent, argName, value|
				inevent.use{
					if(node.notNil){
						node.set(argName, value);
					};
					inevent.put(argName.asSymbol, value);
					inevent.changed(argName.asSymbol);					
				}
			}
	);
	SynthDescLib.global[synthDefName.asSymbol].controls.do{|it|
		event.put(it.name.asSymbol, it.defaultValue);
	};
	event
};

createGUIFor = {|event, window|
	var controlNames, playButton, height, updater, funcDict;

	//GUI
		
	controlNames = SynthDescLib.global[event[\instrument]].controls;
	
	height = controlNames.size * 24 +40;
	
	window = SCWindow("myWindow", Rect(100,100, 328, height));
	window.view.decorator_(FlowLayout(window.view.bounds));
	
	SCStaticText(window, 80@20).string_(event[\instrument].asString);
	
	playButton = SCButton(window, 120@20)
			.states_([["play"],["stop"]])
			.action_({|view| 
				if(view.value==1){
					event.play;	
				}{
					event.stopPlaying;
				}
			});
	
	funcDict = IdentityDictionary.new;
	
	//register button in funcDict
	funcDict.put(\play, {|value| {playButton.value_(value)}.defer});	
	
	window.view.decorator.nextLine;
	
	//create sliders
	
	controlNames.do{|control, i| 
		var spec, name, action, initValue, slider;
		name = control.name;
		spec = name.asSymbol.asSpec ? [0,1].asSpec;
		action = {|view| event.setArg(name, view.value)};
		initValue = control.defaultValue;
		slider = EZSlider(window, 300@20, name, spec, action, initValue);
		window.view.decorator.nextLine;
		
		//register slider at controller
		
		funcDict.put(control.asSymbol, {|value|
			{
				slider.value_(spec.unmap(value));
			}.defer
		})
	};
	
	// updater
	updater = {|theChanger, what, value|
		funcDict[what].value(value);
	};
	event.addDependant(updater);
	
	window.front;
	window.onClose_{event.stopPlaying; event.removeDependant(updater)};
	

};

//evaluate the GUI function 

createGUIFor.value(eventForSynthDef.(synthDefName));
)



﻿
figure 9.18

(
var window, button, createSingletonFunc, singletonWindow;

createSingletonFunc = {|view|
	if(singletonWindow.isNil){
		singletonWindow = SCWindow("singleton").front
			.onClose_({singletonWindow = nil});
	}{
		singletonWindow.front;
	}
};

window = SCWindow("open Singleton", Rect(300,300, 200, 40)).front;
button = SCButton(window, Rect(4,4,192, 30))
			.states_([["singleton"]])
			.action_(createSingletonFunc);
)



﻿
figure 9.20

(
var k;
k= KeyCodeResponder.new;
//  shift control p
k.register(   35  ,   true, false, false, true, {
	CocoaDialog.getPaths({|paths|
		Document.current.selectedString_(paths[0].asCompileString);
	});
});
Document.globalKeyDownAction_(k)
)



﻿Figure 10.1

// boot the sound synthesis server and prepare a SynthDef for buffer playback
(
s.waitForBoot({
    SynthDef( \bufPlay, { arg buf, amp = 1.0, speed = 1.0;
        Out.ar( 0, Pan2.ar( 
PlayBuf.ar( 1, buf, speed * BufRateScale.kr( buf ), loop: 1 ) * amp )
);
    }).add;
    ~buf = Buffer.read( s, "sounds/a11wlk01.wav" );
});
)

// now replace the action function
(
~playButton.action = { arg view;
    if( view.value == 1, {
        ~node = Synth( \bufPlay, [ \buf, ~buf ]);
    }, {
        ~node.free; ~node = nil;
    })
};
)



﻿Figure 10.2

~amp   = 0.5;  // initial amplitude
~speed = 1.0;  // initial speed (1.0 is normal, 0.5 is half-speed, etc.)
(
~playButton.action = { arg view;
    if( view.value == 1, {
        ~node = Synth( \bufPlay, [ \buf, ~buf, \amp, ~amp, \speed, ~speed ]);
    }, {
        ~node.free; ~node = nil;
    })};
)
~win.setInnerExtent( 370, 72 );  // more suitable dimensions for the window
~win.resizable = false;
JSCStaticText( ~win, Rect( 56, 4, 50, 25 )).align_( \right ).string_( "Amp:" );
(
~ampSlider = JSCSlider( ~win, Rect( 110, 4, 200, 25 ))
    .value_( ~amp ) // initial slider position
    .action_({ arg view;
        ~amp = view.value;
        ~node.set( \amp, ~amp );
    });
)
JSCStaticText( ~win, Rect( 56, 32, 50, 25 )).align_( \right ).string_( "Speed:" );
~speedSpec = ControlSpec( 1/8, 8, \exp );
(
~speedSlider = JSCSlider( ~win, Rect( 110, 32, 200, 25 ))
    .value_( ~speedSpec.unmap( ~speed ))  // initial slider position
    .action_({ arg view;
        ~speed = ~speedSpec.map( view.value );
        ~node.set( \speed, ~speed );
    });
) 



﻿Figure 10.4

~node.free; ~node = nil;

(
~model        = Event.new;
~model.amp    = ~amp;
~model.speed  = ~speed;
~model.node   = ~node;
~model.buf    = ~buf;
~model.adjust = { arg mod, key, value, source;
    mod.put( key, value );
    mod.changed( key, value, source )};

UpdateListener.newFor( ~model, { arg upd, mod, value;
    mod.node.set( \amp, value )}, \amp );
UpdateListener.newFor( ~model, { arg upd, mod, value;
    mod.node.set( \speed, value )}, \speed );

~playButton.action = { arg view;
    if( view.value == 1, {
        ~model.node = Synth( \bufPlay, [
            \buf, ~model.buf, \amp, ~model.amp, \speed, ~model.speed ]);
    }, {
        ~model.node.free; ~model.node = nil;
    })};
~ampSlider.action   = { arg view;
    ~model.adjust( \amp, view.value, view )};
~speedSlider.action = { arg view;
    ~model.adjust( \speed, ~speedSpec.map( view.value ), view )};
)



﻿Figure 10.5

(
~ampText = JSCStaticText( ~win, Rect( ~ampSlider.bounds.right + 2, 4, 50, 25 ));
~ampTextUpd = UpdateListener.newFor( ~model, { arg upd, mod, value;
    ~ampText.string = "% dB".format( value.ampdb.round( 0.1 ))}, \amp );
~speedText = JSCStaticText( ~win, Rect( ~speedSlider.bounds.right + 2, 32, 50, 25 ));
~speedTextUpd = UpdateListener.newFor( ~model, { arg upd, mod, value;
    ~speedText.string = "%\\%".format( (value * 100).round( 0.1 ))}, \speed );
)
// note: the sliders must be initially dragged to cause view updates!



﻿Figure 10.7

(
~ampSliderUpd = UpdateListener.newFor( ~model, { arg upd, mod, value, source;
    if( source !== ~ampSlider, {
        ~ampSlider.value = value;
    })}, \amp );
~speedSliderUpd = UpdateListener.newFor( ~model, { arg upd, mod, value, source;
    if( source !== ~speedSlider, {
        ~speedSlider.value = ~speedSpec.unmap( value );
    })}, \speed );
)



﻿Figure 10.10

// ~win = JSCWindow.new;
[ "/local", 1000, "[", "/new", "de.sciss.swingosc.Frame", "panel", "[", "/new", "java.awt.Rectangle", 128, 64, 400, 400, "]", 0, "]" ]
[ "/local", "ac1000", "[", "/new", "de.sciss.swingosc.WindowResponder", 
1000, "]", 1001, "[", "/method", 1000, "getContentPane", "]" ]]
[ "/local", "key1001", "[", "/new", "de.sciss.swingosc.KeyResponder", 1001,
"]" ]
[ "/local", "cmp1001", "[", "/new", "de.sciss.swingosc.ComponentResponder",
1001, "]" ]]
		
// ~win.front;
[ "/set", 1000, "visible", 1 ]
[ "/method", 1000, "toFront" ]]

// ~playButton = JSCButton( ~win, Rect( 4, 4, 40, 56 ));
[ "/local", 1002, "[", "/new", "de.sciss.gui.MultiStateButton", "]", 
"ac1002", "[", "/new", "de.sciss.swingosc.ActionResponder", 1002, "[",
"/array", "selectedIndex", "lastModifiers", "]", "]" ]
[ "/set", 1002, "bounds", "[", "/new", "java.awt.Rectangle", 1, 1, 46, 62,
"]", "font", "[", "/ref", "font", "]" ]
[ "/local", "dnd1002", "[", "/new", 
"de.sciss.swingosc.DummyTransferHandler", 1002, 2, "]" ]
[ "/local", "key1002", "[", "/new", "de.sciss.swingosc.KeyResponder", 1002,
"]" ]
[ "/local", "cmp1002", "[", "/new", "de.sciss.swingosc.ComponentResponder",
1002, "]" ]]
[ "/method", 1001, "add", "[", "/ref", 1002, "]" ]
[ "/method", 1001, "revalidate" ],
[ "/method", 1001, "repaint" ]]

// ~playButton.states = [[ "Play", Color.white, Color.green( 0.4 )],
//                       [ "Stop", Color.white, Color.red ]];
[ "/method", 1002, "removeAllItems" ]
[ "/method", 1002, "addItem", "Play", "[", "/new", "java.awt.Color", 1.0, 
1.0, 1.0, 1.0, "]", "[", "/new", "java.awt.Color", 0.0, 0.4, 0.0, 1.0,
"]" ]
[ "/method", 1002, "addItem", "Stop", "[", "/new", "java.awt.Color", 1.0, 
1.0, 1.0, 1.0, "]", "[", "/new", "java.awt.Color", 1.0, 0.0, 0.0, 1.0,
"]" ]]



﻿Figure 10.11

[ "/component", 1001, "resized", 0, 0, 400, 400 ]
[ "/window", 1000, "opened" ]
[ "/window", 1000, "activated" ]
[ "/window", 1000, "gainedFocus" ]
[ "/window", 1000, "resized", 128, 414, 400, 421 ]
[ "/component", 1001, "resized", 0, 0, 400, 399 ]
[ "/window", 1000, "moved", 128, 414, 400, 421 ]
[ "/window", 1000, "lostFocus" ]
[ "/window", 1000, "deactivated" ]



﻿Figure 10.13

(
~mySlider            = Event.new;
~mySlider.view       = JSCUserView( ~win, Rect( 110, 32, 200, 145 )).focusVisible_( false );
~mySlider.pos        = ~speedSpec.unmap( ~model.speed );
// these will be used in the final draw func:
~mySlider.pressed    = false;
~mySlider.project    = false;
// this will update the slider position and refresh the view:
~mySlider.adjustPos  = { arg slid, pos;
    slid.pos         = pos;
    slid.view.action.value( slid );
    slid.view.refresh };
// these will set the slider track curve and refresh the view:
~mySlider.adjustCurve= { arg slid, curve;
    slid.curve       = curve;
    slid.lines       = curve.slide( 2, 1 ).clump( 2 );
    slid.lineLens    = slid.lines.collect({ arg pair; pair[ 0 ].dist( pair[ 1 ])}).normalizeSum; 
    slid.projections = nil;
    slid.view.refresh };
// a primary draw function just to indicate the view's bounds:
~mySlider.view.drawFunc = { arg view; var b = view.bounds;
    JPen.line( 0 @ 0, b.width @ b.height );
    JPen.line( 0 @ b.height, b.width @ 0 );
    JPen.stroke };
// make the window a little bigger:
~win.setInnerExtent( 370, 180 );
)



﻿Figure 10.14

(
~mySlider.adjustCurve([ 0 @ 0, 0.25 @ 1, 0.5 @ 0, 1.0 @ 0.5 ]);
~mySlider.view.drawFunc = { arg view;
    var b, scale, lnP1, lnP2, linePos, proj, inner, sum = 0;
    b     = view.bounds;
    // scaling factor for coordinates normalized to 0...1
    scale = b.width @ b.height;
    // set the initial curve coordinate
    JPen.moveTo( ~mySlider.curve[ 0 ] * scale );
    (1..(~mySlider.curve.size-1)).do({ arg i;
        // create the curve by adding successive line segments
        JPen.lineTo( ~mySlider.curve[ i ] * scale );
    });
    // stroke the curve with a 2-pixel wide black pen
    JPen.width = 2;
    JPen.color = Color.black;
    JPen.stroke;
    // draw the knob: iterate over the line segments until
    // the one is found inside which the knob (read from ~mySlider.pos)
    // is located.
    block { arg break;
        ~mySlider.lineLens.do({ arg len, i;
            // if we have found the line segment...
            if( sum + len >= ~mySlider.pos, {
                // calucate the point inside this segment
                // (proj) and draw a filled circle around it
                #lnP1, lnP2    = ~mySlider.lines[ i ];
                linePos        = (~mySlider.pos - sum) / len;
                proj           = lnP1 + ((lnP2 - lnP1) * linePos);
                JPen.fillOval( Rect.aboutPoint( proj * scale, 8, 8 ));
                // if this view is focused, use blue color, otherwise grey
                JPen.fillColor = Color.hsv( 0.7, view.hasFocus.if( 0.7, 0.0 ), 1.0 );
                // if the mouse is pressed, the outline should be thicker
                inner          = if( ~mySlider.pressed, 5, 7 );
                JPen.fillOval( Rect.aboutPoint( proj * scale, inner, inner ));
                break.value;
            });
            sum = sum + len;
        });
    };
    
    // a debugging utility to visualize the point projections
    // of the mouse dragging
    if( ~mySlider.project, {
        ~mySlider.projections.do({ arg pt;
            pt = pt * scale;
            JPen.line( pt + (-5 @ -5), pt + (5 @  5) );
            JPen.line( pt + (-5 @  5), pt + (5 @ -5) );
        });
        JPen.width = 1; JPen.stroke;
    });
};
)



﻿Figure 10.15

(
var mouseFunc = { arg view, x, y, modifiers, buttonNumber, clickCount;
    var b, nx, ny, dx, dy, lnP1, lnP2, linePos, lineLenSq,
        proj, dist, sum = 0, minDist = inf, newValue;
    
    b  = view.bounds;
    nx = x / b.width;
    ny = y / b.height;
    ~mySlider.projections = Array( ~mySlider.lines.size );
    // look up the line segment which is closest to the mouse
    ~mySlider.lines.do({ arg pair, i;
        #lnP1, lnP2 = pair;
        dx          = lnP2.x - lnP1.x;
        dy          = lnP2.y - lnP1.y;
        lineLenSq   = (dx*dx) + (dy*dy);
        dist        = (((nx - lnP1.x) * dx) + ((ny - lnP1.y) * dy)) / lineLenSq;
        proj        = (lnP1.x + (dist * dx)) @ (lnP1.y + (dist * dy));
        if( lnP1.x != lnP2.x, {
            linePos = (proj.x - lnP1.x) / dx;
        }, {
            linePos = (proj.y - lnP1.y) / dy;
        });
        if( linePos < 0, {
            proj = lnP1;
        }, { if( linePos > 1, {
            proj = lnP2;
        })});
        ~mySlider.projections.add( proj );
        dist = proj.dist( nx @ ny );
        if( dist < minDist, {
            newValue = sum + (linePos.clip( 0, 1 ) * ~mySlider.lineLens[i]);
            minDist  = dist;
        });
        sum = sum + ~mySlider.lineLens[ i ];
    });
    ~mySlider.pressed = true;
    ~mySlider.adjustPos( newValue );
};
~mySlider.view.mouseDownAction = mouseFunc;
~mySlider.view.mouseMoveAction = mouseFunc;
~mySlider.view.mouseUpAction   = { arg view; ~mySlider.pressed = false; view.refresh };
~mySlider.view.action          = { arg view;
    ~model.adjust( \speed, ~speedSpec.map( ~mySlider.pos ), ~mySlider )};
)



﻿Figure 10.17

(
~action = { arg fileName; "Selected file is '%'\n".postf( fileName )};
~sResp  = JavaObject( "de.sciss.swingosc.ActionResponder", nil, ~fileChooser.id );
~cResp  = OSCpathResponder( g.addr, [ '/action', ~fileChooser.id ], {
    fork { var file, fileName;
        file     = ~fileChooser.getSelectedFile__;
        fileName = file.getAbsolutePath_;
        file.destroy;
        ~action.value( fileName.asString );
    };
}).add;
)



﻿Figure 10.18

(
~cp.remove( ~fileChooser );
~frame.dispose;
~cp.destroy; ~frame.destroy;
~win.setInnerExtent( 760, 340 );   // again a bit bigger
~plug = JSCPlugView( ~win, Rect( 370, 2, 386, 336 ), ~fileChooser );
~action = { arg fileName; var sf, oldBuf;
    // try to open as a sound file. returns nil if it could not be opened
    if( (sf = SoundFile.openRead( fileName )).notNil, {
        sf.close;  // the header info was read, we can close the file
        if( sf.numChannels == 1, {  // allow mono files only
            oldBuf = ~model.buf;
            if( ~model.node.notNil, {  // free old buffer when synth is freed
                UpdateListener.newFor( ~model.node, { arg upd;
                    upd.remove; oldBuf.free }, \n_end );
                ~model.node.register;
            }, {
                oldBuf.free;
            });
            ~model.buf = Buffer.read( s, fileName );  // replace buffer
        }, {
            "Sound file must be mono".error;
        });
    });
};
)



﻿Figure 10.19

import java.io.File;
import javax.swing.filechooser.FileFilter;
import javax.swing.event.ChangeEvent;
import javax.swing.event.ChangeListener;

public class SoundFileChooser extends javax.swing.JFileChooser
implements java.beans.PropertyChangeListener
{
    private final java.util.List listeners = new java.util.ArrayList();
    
    public SoundFileChooser() {
        super();        
        final FileFilter filter = new FileFilter() {            
            public boolean accept( File f ) {
                if( f.isDirectory() ) return true;
                try {
                    return( de.sciss.io.AudioFile.retrieveType( f ) !=
                            de.sciss.io.AudioFileDescr.TYPE_UNKNOWN );
                }
                catch( java.io.IOException e ) { return false; }
            }
        
            public String getDescription() { return "Audio Files"; }
        };
        addChoosableFileFilter( filter );
        setFileFilter( filter );
        setControlButtonsAreShown( false );
        addPropertyChangeListener( SELECTED_FILE_CHANGED_PROPERTY, this );
        addPropertyChangeListener( DIRECTORY_CHANGED_PROPERTY, this );
    }
    
    public String getSelectedPath() {
        final File f = getSelectedFile();
        return f == null ? "" : f.getAbsolutePath();
    }
    
    public void setSelectedPath( String path ) {
        setSelectedFile( new File( path ));
    }
    
    public String getCurrentDirectoryPath() {
        return getCurrentDirectory().getAbsolutePath();
    }
    
    public void setCurrentDirectoryPath( String path ) {
        setCurrentDirectory( new File( path ));
    }
    
    public void addChangeListener( ChangeListener l ) { listeners.add( l ); }
    public void removeChangeListener( ChangeListener l ) { listeners.remove( l ); }

    public void propertyChange( java.beans.PropertyChangeEvent pce ) {
        final ChangeEvent ce = new ChangeEvent( this );
        for( int i = 0; i < listeners.size(); i++ ) {
            ((ChangeListener) listeners.get( i )).stateChanged( ce );
        }
    }
}



﻿Figure 10.20

JSCSoundFileChooser : JSCView {
    var <path;       // String : current file selection (or nil)
    var <directory;  // String : currently visible directory
    var chResp;      // OSCpathResponder for ChangeResponder

    path_ { arg value;
        path = value;
        server.sendMsg( '/set', this.id, \selectedPath, value );
    }

    directory_ { arg value;
        directory = value;
        server.sendMsg( '/set', this.id, \currentDirectoryPath, value );
    }

    prSCViewNew {
        chResp = OSCpathResponder( server.addr, [ '/change', this.id ], {
            arg time, resp, msg; var oldPath = path;
            path        = if( msg[ 4 ] !== '', { msg[ 4 ].asString });
            directory   = msg[ 6 ].asString;
            if( oldPath != path, {{ this.doAction }.defer });
        }).add;
        ^super.prSCViewNew([[ '/local', this.id, '[', '/new', "SoundFileChooser", ']', "ch" ++ this.id, '[', '/new', "de.sciss.swingosc.ChangeResponder", this.id, '[', '/array', \selectedPath, \currentDirectoryPath, ']', ']' ]]);
    }

    prClose {
        chResp.remove;
        ^super.prClose([[ '/method', "ch" ++ this.id, \remove ],
                        [ '/free', "ch" ++ this.id ]]);
    }
}



﻿Figure 10.21

(
~plug.remove;	// this implicitly calls ~fileChooser.destroy!
~soundChooser        = JSCSoundFileChooser( ~win, Rect( 370, 2, 386, 306 ));
~soundChooser.path   = "sounds/a11wlk01.wav".absolutePath;
~loadButton          = JSCButton( ~win, Rect( 370, 312, 60, 24 )).states_([[ "Load" ]]).enabled_( false );
~infoText            = JSCStaticText( ~win, Rect( 438, 312, 318, 24 ));
~soundChooser.action = { arg view; var enabled = false, info = "", sf;
    if( view.path.notNil and: { (sf = SoundFile.openRead( view.path )).notNil }, {
        sf.close;
        enabled         = sf.numChannels == 1;
        info            = "% audio, %-chan. % % kHz, %".format( sf.headerFormat, sf.numChannels, sf.sampleFormat, sf.sampleRate/1000, (sf.numFrames/sf.sampleRate).asTimeString );
    });
    ~loadButton.enabled = enabled;
    ~infoText.string    = info;
};
~loadButton.action   = { ~action.value( ~soundChooser.path )};
)



﻿Figure 10.22

(
~ampSlider.resize     = 2;
~mySlider.view.resize = 5;
~ampText.resize       = 3;
~speedText.resize     = 3;
~soundChooser.resize  = 6;
~loadButton.resize    = 9;
~infoText.resize      = 9;
~win.resizable        = true;
) 



﻿Figure 11.3
// Tasks 
(
SynthDef("task", { arg out=0, freq=2000;
	var env = EnvGen.kr(Env.perc, 1.0, 0.2, doneAction:2);
	var source = DynKlank.ar(`[ [0.5, 0.8, 1, 1.2, 2, 4]*freq, nil, nil ], PinkNoise.ar(0.007));
	Out.ar(out, source * env ! 2);
}).add;

t = Task({
	var freq;
	loop {
		freq = ((1..10)*220).choose;
		Synth("task", [\freq, freq]);
		0.3.wait;
	}
})
)

t.start;
t.stop;




﻿Figure 11.4
// Patterns
(
SynthDef("pattern", { arg out=0, freq=220, pan=0, gate=1;
	var ctl = RLPF.ar(Saw.ar(5, 1.0, 2), 25, 0.03);
 	var source = SinOsc.ar(ctl * freq) * 0.1;
	var env = EnvGen.kr(Env.adsr, gate, doneAction: 2);
	Out.ar(out, Pan2.ar(source * env, pan));
}).add;

e = Pbind(
	\midinote, Pxrand(#[60, 61, 63, 65, 72], 20), 
	\dur, 0.4,
	\pan, Pwhite(-1.0, 1.0, 20),
	\instrument, \pattern
);
)

e.play;




﻿Figure 11.5
// ProxySpace
p = p ?? ProxySpace.push(s);

~ctl = { SinOsc.kr(1) * 110 + 440 };
~out = { arg freq=220, amp=0.5; Ringz.ar(Dust.ar(2, 0.4), freq, 0.8) ! 2 };

~out.play;

~out.map(\freq, ~ctl);

~ctl = { SinOsc.kr(LFSaw.kr(5, add: 2.0) * 10) * 220 + 440 };

ProxyMixer(p);

~out.stop;
~out.clear;



﻿Figure 11.7
// MIDI Example
(
SynthDef(\midi, { arg out=0, midinote=60, dur=0.1;
	var source = Blip.ar(midinote.midicps, 4, 0.2);
	var env = EnvGen.kr(Env.perc(0.1, dur), 1.0, doneAction: 2);
	Out.ar(out, (source * env) ! 2);

}).add;

c = NoteOnResponder( { |src, chan, num, vel|
	[num, vel].postln;
	Synth.new(\midi, [\midinote, num, \dur, vel/512]);
});
)
c.remove;



﻿Figure 11.8
// NetAddr and OSCresponder example
n = NetAddr("localhost", 57120); 
r = OSCresponder(n, '/good/news', { arg time, resp, msg; [time, msg].postln }).add;

n.sendMsg("/good/news", "you", "not you");

r.remove;
n.disconnect;



﻿Figure 11.9
// GUI Example
(
	SynthDef(\gui, { arg out=0, freq=8, decay=0.11;
		var in = Formlet.ar(Impulse.ar(freq, 0, 0.4), 800, 0.01, decay);
		Out.ar(out, in ! 2);
	}).add;
)
(
	a = Synth.newPaused(\gui);
	w = Window.new( "A GUI window", Rect( 128, 64, 340, 250 ));
	w.view.decorator = FlowLayout( w.view.bounds );

	b = Button.new( w, Rect( 50, 20, 75, 24 ));
	b.states = [[ "Start"],[ "Stop"]];
	b.action_({ arg butt;
		if (butt.value == 1, { a.run }, { a.run(false) });	
	});

	c = Slider2D.new( w, Rect(50, 120, 330, 200));
	c.x_(0.5).y_(0.5).action_({|sl|
			a.setn(\freq, [sl.x * 10 + 3, sl.y / 5 + 0.01]);
	});
	w.front;
)



﻿//Figure 12.1
//#!/usr/local/bin/sclang
if (thisProcess.argv.isEmpty) {
	"Missing arguments!".postln;
	exit(1);
};
thisProcess.argv.do { | argu, i |
	"% : %\n".postf(i, argu);
};
exit(0);



﻿Figure 12.3
// select the following lines and type C-c C-d
// stop synthesis with C-c C-s
{
	var trem = LFTri.kr(3).range(-12.dbamp, 0.dbamp);
	SinOsc.ar(
		{ rrand(60, 80).midicps } ! 6,
		mul: -10.dbamp * trem
	).clump(2).sum
}.play



﻿Figure 12.4
// evaluate the following lines by double-clicking on the
// first paranthesis when `transient-mark-mode' is enabled
// and pressing C-c C-c
(
x = {
Saw.ar(
XLine.kr(20, [400,403,407], 20),
mul: 0.7
).clump(2).sum
}.play; "scel";
)
// evaluate this line by pressing C-c C-c
x.free; "rocks";




﻿// figure 13.1 - Loading the data
(
q = q ? ();
q.execdata = ();
q.execdata.years = (1977 .. 2008); 
	// data is: [total for each region, 1977 ... 2007];
q.execdata.regions = (
	Total: [1099,1,0,2,0,1,2,5,21,18,18,25,11,16,23,14,31,38,31,
			56,45,74,68,98,85,66,71,65,59,60,53,42,37],
	Northeast: [4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,0,0,0,1,0,0,0,0,0,1,0,0,0],
	Midwest: [129,0,0,0,0,1,0,0,0,1,0,0,0,1,5,1,1,4,3,11,9,10,5,12,5,10,9,7,7,14,6,5,2],
	South: [933,0,0,1,0,0,2,5,21,16,18,24,10,13,17,13,26,30,26,41,29,60,
		55,74,76,50,61,57,50,43,44,36,35],
	West: [67,1,0,1,0,0,0,0,0,1,0,1,1,2,1,0,4,4,2,2,7,4,8,11,4,4,1,0,2,2,3,1,0],
	Texas: [423,0,0,0,0,0,1,0,3,6,10,6,3,4,4,5,12,17,14,19,3,37,20,35,40,17,33,24,23,19,24,26,18]
);
q.getReg = { |q, regName| q.execdata.regions[regName].drop(1) };
)



﻿// figure 13.2 - Mapping the data to pitch in discrete events
(
Pbindef(\exec, 
	\note, Pseq(q.getReg(\Midwest)), 
	\octave, 3, 
	\dur, 5 / q.execdata.years.size
).play;
)
	// the different regions
Pbindef(\exec, \note, Pseq(q.getReg(\Northeast)));
Pbindef(\exec, \note, Pseq(q.getReg(\West)));
Pbindef(\exec, \note, Pseq(q.getReg(\South)));



﻿			// figure 13.3 - Continuous data sonification
 
b = Buffer.sendCollection(s, q.getReg(\Northeast), 1); 
(
Ndef(\exec, { |dur = 5, scale=50, offset=200| 
	var vals = PlayBuf.ar(1, b, dur / SampleRate.ir );
	Pan2.ar(
		SinOsc.ar(vals  * scale + offset), 0, 
		EnvGen.kr(Env.linen(0.01, dur, 0.01, 0.2), doneAction: 2)
	);
}).play;
)
	// load other regions into buffer
b.sendCollection(q.getReg(\Midwest));   Ndef(\exec).send;
b.sendCollection(q.getReg(\West));   Ndef(\exec).send;
b.sendCollection(q.getReg(\South));   Ndef(\exec).send;



﻿// figure 13.4 - Sound design with noise pulses 
(
SynthDef( "noisepulses", { arg out = 0, sustain=1.0, numPulses = 0, pan = 0.0, amp = 0.2; 
	Out.ar(out, 
		PanAz.ar(4, 
			PinkNoise.ar 
			* Decay2.ar(Impulse.ar(numPulses / sustain, 0, numPulses.sign), 0.001, 0.2),
			pan, 
			EnvGen.kr( Env.linen(0.0, 0.995, 0.0), levelScale: amp, timeScale: sustain, doneAction: 2)
		)
	);
}).add;
SynthDef(\tick, { |out, amp=0.2, pan| 
	OffsetOut.ar(out, Pan2.ar(Impulse.ar(0) * Line.kr(amp, amp, 0.001, doneAction: 2), pan)) 
}).add;
)
(instrument: \noisepulses, numPulses: 10, legato: 1, dur: 2).play;
(instrument: \tick).play;



﻿		// figure 13.5 - Four regions in sequence
(
Tdef(\execs, { 
	var yearDur = 2;	// one year is 2 seconds
	var region, numExecs, numyears = q.execdata.years.size; 
	[\Northeast, \Midwest, \West, \South].do { |regName, i| 

		region = q.execdata.regions[regName].postln; 
		q.execdata.years.do { |year, i| 
			numExecs = region[i + 1]; 
			[regName, year, numExecs].postln;
			(instrument: \tick).play;
			if (numExecs > 0) {
				(instrument: \noisepulses, legato: 1, 
numPulses: numExecs, dur: yearDur).play;
			};
			yearDur.wait;
		};
		yearDur.wait;
	};
}).play;
)



﻿// figure 13.6 - Four regions in parallel
(
// four channels playing, ordered by total number. 
// On stereo systems, only the first 2 channels play.
Tdef(\execs, { 
	var yearDur = 2;	// one year is 2 seconds
	q.execdata.years.do { |year, i| 
	var region, numExecs, numyears = q.execdata.years.size; 
		// ordered by total number, on stereo, only first 2 play.
	[\South, \Midwest,  \West, \Northeast ].do { |regName, j| 

		region = q.execdata.regions[regName].postln; 
			numExecs = region[i + 1]; 
			[regName, year, numExecs].postln;
			(instrument: \tick).play;
			if (numExecs > 0) {
				(instrument: \noisepulses, legato: 1, 
dur: yearDur, 
					numPulses: numExecs, 
					pan: j * 0.5 - 0.25 	// to 4 channels
				).play;
			};
		};
		yearDur.wait;
	};
}).play;
)




﻿	// figure 13.7 - Sonification of tag systems
(
// compare two axioms on left and right channels
// ? = 4 (size of alphabet)
// v (deletion number) varies [1..6] with horizontal cursor position
{
	var tag, rules, val;
	rules = [[0, 1, 1], [1, 3, 2, 0], [1, 2], [3, 1, 1]]; // same rule for both
	v = MouseX.kr(1, 6);
	val = dup {
		var axiom = Array.fill(14, { #[0, 1, 2, 3].choose }); axiom.join.postln;
		Duty.ar(1 / SampleRate.ir, 0,  Dtag(7e5, v, axiom, rules), doneAction:2);
	} * 0.1
}.play;
)



﻿// figure 13.12 - Rotational Grain Train
(
~rotater = {|amp = 1|
	var rotVel = ~rotVel.kr;	// rotVel and height from tracking data proxies
	BPF.ar(
		Impulse.ar((rotVel > 0.5) * rotVel * 5).lag(0.0001),
		(~height.kr * 120 + 36 + [[0, 7], [0, 12], [0, 16]]).midicps, 
		0.2
	).collect({ |pair| (pair * [1, 0.125]).sum }) 	* 6 * amp
};
)



﻿// figure 13.13 - Rotation Trigger
(
~planeTicker = {|saw2sin = 1, filterFreq = 2000, fSpread = 0.4, amp = 0.1|
	
	var freq = 3000 * fSpread * (~height.kr * 4 - 1).range(0.5, 2);

	var src = SelectX.ar(
		saw2sin, 
		[LFSaw.ar(freq) , SinOsc.ar(freq)]
	) 
	* Decay2.ar(
		Trig1.ar(~zeroCrossing.ar, 0.001) * 0.1, 
		0.001,
		0.3
	);

	LPF.ar(src, filterFreq, mul: amp * 0.1)
};
)




﻿// figure 13.14 - Distances to the Head
(
~backCross = {|amp = 1|
	var 	numObj = 3;
	var 	in = ~isLeft.kr(numObj);
	var 	height = ~height.kr(numObj), 
		front = ~isFront.kr(numObj); 
	var aEnv, fEnv, aEnvNoise;

	var trig = Trig1.ar((in - Delay1.kr(in)).abs - 1, 0.00001) > 0.5;
	// only trigger if behind the body and near ground
	trig = trig * (front < 0) * (height < 0.26);
	aEnv = EnvGen.kr(Env.perc(0.05, 2), gate: trig);
	aEnvNoise = EnvGen.kr(Env.perc(0.01, 0.1), gate: trig);
	fEnv = EnvGen.kr(
		Env.perc(0.01, 0.1), gate: trig, 
		levelScale: 900, levelBias: 50
	);
	
	aEnv * ((0.2 * WhiteNoise.ar * aEnvNoise) + 
	SinOsc.ar(fEnv * (height * 8).squared * 0.4, 0, 1.5).softclip) * amp
};
)


﻿// figure 13.15 -  Left-right Trigger
(
~distances = {|amp = 0.2795| 
	LFSaw.ar(min((~dist.kr * 2.5 * 90 + 20).midicps, 44100)) * amp
};
)




﻿// figure 13.16 - Rain on Bells
(

~clackUp = { |amp = 0.1|
	Formlet.ar(
		~trigsUp.ar.lag(0.0004), 
		(~height.kr).exprange(25, 2500), 
		0.002,
		0.05
	)
	* (~height.kr * 4 ** 2) 
	* amp
};
)



﻿/// figure 13.18: Navegar – sound design for a single country
(
~single = { |rootFreq = 220, outProp = 4.5, inProp = 2.2, attack=0.00, decay = 1.0, 
	dens = 2, amp=0.2, x=1, y = 0, step=0.33333| 
	
	var numChans = 4; 
	
	var freqs = rootFreq * [ 1/outProp, 1/inProp, 1, inProp, outProp]; 
	
	var exciter = (Dust2.ar(dens * [ 1,2,4,2,1] * 0.07)  	// five individual rd triggers for 
										// each component, weighted for center
			+ Dust2.ar(dens * 0.3))				// + some common attacks
				.clip2(0.5)	
				.lag(0.0003) 				// slightly filtered
				* (dens ** -0.5)				// amplitude comp for dust density
			+ PinkNoise.ar(0.002)				// some fused background noise
			* (decay ** -0.5);				// amplitude comp. for decay
				
	var resonator = Formlet.ar( exciter, freqs, 
		Ramp.kr(attack, step), decay, 
		AmpComp.kr(freqs.max(50))
	).softclip.sum; 
	
	var pos = atan2(Ramp.kr(y, step), Ramp.kr(x, step)) * (pi.reciprocal) + 1; // look west.

	PanAz.ar(numChans, LeakDC.ar(resonator, 0.95), pos, Ramp.kr(amp, step));
};
~single.play;
)



﻿Figure 14.1

(
/// basic setup
s = Server.local.boot;

s.doWhenBooted({
	SynthDef( \nicepoc, { |out=0,freq=440,amp=0.1,dur=0.3|
		Out.ar( out, SinOsc.ar( freq, mul: amp )*EnvGen.kr( Env.perc(0.05,1), timeScale: dur, doneAction:2 ) )
	}).add;
});
)

// mono, 1 channel:
(
p = Pbind(
     \degree, Pseq([0, 3, 5, 6, 7],5),
     \dur, 0.2,
     \instrument, \nicepoc
).play;
)

p.stop;

// multiple mono:
// the melody gets played on both channels, the second note in the pattern differs,
// so when listening to it, the space "spreads" out
(
p = Pbind(
     \degree, Pseq([0 ,[3,4], 5, 6, 7],5),
     \out, [0,1],
     \dur, 0.2,
     \instrument, \nicepoc
).play;
)

p.stop;



﻿Figure 14.3


// 2 channel panners:
 Pan2.ar( in, pos, level );
 LinPan2.ar( in, pos, level );
 Balance2.ar( left, right, pos, level );
 Rotate2.ar( x, y, pos );

// 4-channel panner:
 Pan4.ar( in, xpos, ypos, level );

// N-channel panner:
 PanAz.ar( numChans, in, pos, level, width, orientation );

// spread M channels over a stereo field:
 Splay.ar( inArray, spread, level, center, levelComp );

// spread M channels over N channels:
 SplayAz.ar( numChans, inArray, spread, level, width, center, orientation, levelComp );





﻿Figure 14.5

// single tap delay lines
DelayN.ar(in, maxdelaytime, delaytime, mul, add)
DelayL.ar(in, maxdelaytime, delaytime, mul, add)
DelayC.ar(in, maxdelaytime, delaytime, mul, add)

// allpass filters:
AllpassN.ar(in, maxdelaytime, delaytime, decaytime, mul, add)
AllpassL.ar(in, maxdelaytime, delaytime, decaytime, mul, add)
AllpassC.ar(in, maxdelaytime, delaytime, decaytime, mul, add)

// comb filters (delaylines with feedback):
CombN.ar(in, maxdelaytime, delaytime, decaytime, mul, add)
CombL.ar(in, maxdelaytime, delaytime, decaytime, mul, add)
CombC.ar(in, maxdelaytime, delaytime, decaytime, mul, add)

// buffer versions:

BufDelayN.ar(buf, in, delaytime, mul, add)
BufDelayL.ar(buf, in, delaytime, mul, add)
BufDelayC.ar(buf, in, delaytime, mul, add)

BufAllpassN.ar(buf, in, delaytime, decaytime, mul, add)
BufAllpassL.ar(buf, in, delaytime, decaytime, mul, add)
BufAllpassC.ar(buf, in, delaytime, decaytime, mul, add)

BufCombN.ar(buf, in, delaytime, decaytime, mul, add)
BufCombL.ar(buf, in, delaytime, decaytime, mul, add)
BufCombC.ar(buf, in, delaytime, decaytime, mul, add)


// special delay lines utilising PlayBuf:
Tap.ar(bufnum, numChannels, delaytime)
PingPong.ar(bufnum, inputArray, delayTime, feedback, rotate)




﻿Figure 14.6

 // Create a buffer.
b=Buffer.alloc(s, s.sampleRate, 1); //enough space for one second of mono audio 

// Write to the Buffer with BufWr, read using several taps and mix them together:
(
SynthDef(\helpTap, {|bufnum|
 var source, capture;
 source= Impulse.ar(1);
 capture= BufWr.ar(source, bufnum, Phasor.ar(0,1, 0, BufFrames.ir(bufnum),1));
	 Out.ar(0, Mix.new([1,0.95,0.94,0.93,0.8,0.4,0.4]*Tap.ar(bufnum, 1, [0.04,0.1,0.22,0.88,0.9,0.91,0.93])));
}).add;
)

x=Synth(\helpTap,[\bufnum, b.bufnum]);
x.free;

( // alternate source; use headphones to avoid feedback
SynthDef(\helpTap2, {|bufnum|
 var source, capture;
 source= SoundIn.ar(0);
 capture= BufWr.ar(source, bufnum, Phasor.ar(0,1, 0, BufFrames.ir(bufnum),1));
	 Out.ar(0, Mix.new([1,0.95,0.94,0.93,0.8,0.4,0.4]*Tap.ar(bufnum, 1, [0.04,0.1,0.22,0.88,0.9,0.91,0.93])));
}).add;
)

x=Synth(\helpTap2,[\bufnum, b.bufnum]);
x.free;

// free buffer:
b.free;




﻿Figure 14.7


// convolving two signals with each other:
Convolution.ar( in, kernel, framesize, mul, add )

// convolving one signal with a buffer:
Convolution2.ar( in, kernel, trigger, framesize, mul, add )
// as above with linear interpolation:
Convolution2L.ar( in, kernel, trigger, framesize, crossfade, mul, add )
// as above, with two buffers:
StereoConvolution2L.ar( in, kernelL, kernelR, trigger, framesize, crossfade, mul, add )

// time based convolution (highly inefficient for audio rate)
Convolution3.ar( in, kernel, trigger, framesize, mul, add )
Convolution3.kr( in, kernel, trigger, framesize, mul, add )

// partitioned convolution
PartConv.ar(in, fftsize, irbufnum, mul, add)



﻿   Figure 14.8


// one channel input:
FreeVerb.ar(in, mix, room, damp, mul, add)
// 2 channel input and output:
FreeVerb2.ar(in, in2, mix, room, damp, mul, add)

// stereo reverb
#left, right = GVerb.ar(in, roomsize, revtime, damping, inputbw,
 spread, drylevel, earlyreflevel, taillevel, maxroomsize, mul, add)





﻿Figure 14.10


// 5.1 array (subwoofer must be treated separately)
VBAPSpeakerArray.new(2, [ -30, 30, 0, -110, 110 ]);

// 16 channel partial dome
VBAPSpeakerArray.new(3, [[-22.5, 14.97], [22.5, 14.97], [-67.5, 14.97], [67.5, 14.97], [-112.5, 14.97], [112.5, 14.97], [-157.5, 14.97], [157.5, 14.97], [-45, 0], [45, 0], [-90, 0], [90, 0], [-135, 0], [135, 0], [0, 0], [180, 0]]); 




﻿Figure 14.11


a = VBAPSpeakerArray.new(3, [[-22.5, 14.97], [22.5, 14.97], [-67.5, 14.97], [67.5, 14.97], [-112.5, 14.97], [112.5, 14.97], [-157.5, 14.97], [157.5, 14.97], [-45, 0], [45, 0], [-90, 0], [90, 0], [-135, 0], [135, 0], [0, 0], [180, 0]]); // zig zag partial dome

b = a.loadToBuffer; // send speaker config to the server

(
// pan around the circle up and down
x = { |azi = 0, ele = 0, spr = 10|
var source;
source = PinkNoise.ar(0.2);
VBAP.ar(16, source, b, LFSaw.kr(0.5, 0).range(-180, 180) * -1, SinOsc.kr(3, 0).range(0, 14.97), spr);
}.play;
)




﻿Figure 14.12


// 3D encoding:
PanB.ar(in, azimuth, elevation, gain)
// 2D encoding:
PanB2.kr(in, azimuth, gain)
// 2D encoding of a stereo signal:
BiPanB2.kr(inA, inB, azimuth, gain)

// decoding (2D):
DecodeB2.kr(numChans, w, x, y, orientation)

// rotating (in the horizontal plane):
Rotate2.kr(x, y, pos)


/** From AmbisonicUGens in sc3-plugins: **/

// encoding (3D):
BFEncode1.ar(in, azimuth, elevation, rho, gain, wComp)
BFEncode2.ar(in, point_x, point_y, elevation, gain, wComp)

// encoding of a stereo signal (3D)
BFEncodeSter.ar(l, r, azimuth, width, elevation, rho, gain, wComp)

// decoding (3D):
BFDecode1.ar(w, x, y, z, azimuth, elevation, wComp, mul, add)

// manipulating (3D):
BFManipulate.ar(w, x, y, z, rotate, tilt, tumble)
// rotate is rotation around the z-axis, tilt around the x-axis, and tumble around the y-axis




﻿Figure 14.16


// no interpolation
*arBufN { arg sound = 0, bufnum, location, speakerSpec, speedOfSound = 334, ampType = 'ws'; 
 var numChannels, distArray;

// WFSPoint is a 3D representation of a point in cartesian space

 speakerSpec = speakerSpec ? [WFSPoint.new(-2.7, 1.8, 0), WFSPoint.new(2.7,1.8, 0)]; //default 2 speakers

 if( speakerSpec.class == WFSConfiguration )
  { speakerSpec = speakerSpec.allSpeakers; };

 numChannels = speakerSpec.size; // speakerSpec = Array of WFSPoint objects

 location = location ? WFSPoint.new(0,0,0); // the location of the sound source

 distArray = Array.fill(numChannels, { |i| speakerSpec.at(i).dist(location)}); // distance of the sound source to each speaker (r_0)

 cosPhiArray = Array.fill(numChannels, { |i| speakerSpec.at(i).cosphi(location)}); // cosine phi_0 of the sound source to each speaker (cos phi_0)
 ^BufDelayN.ar(bufnum, sound, 
  distArray / speedOfSound, // delay
  WFSPan.wfsAmp(distArray,cosPhiArray);
 }

*wfsAmp{ arg inDist, inCosPhi, refDist=4.0, minDist = 0.1;
 // refDist is the reference line distance
 // minDist is the minimal distance to the speaker array (to avoid explosion at /0)

 // avoid explosion:
 inDist = inDist.max( minDist );

 ^(ampFactor * ((refDist/(refDist + inDist)).sqrt)*(inCosPhi/(inDist.sqrt)))
}





﻿Figure 14.17


s.boot;
(
b = Buffer.alloc(s,2048,1);
c = Buffer.read(s,"sounds/a11wlk01.wav");
d = Buffer.alloc(s,2048,1);
)

(
//make stereo from mono
// MouseX controls decorrelation
x = SynthDef("PV_DecorrelateStereo", { arg out=0, bufnum=0, bufnum2, soundBufnum=2;
 var in, chain, chain2;
 in = PlayBuf.ar(1, soundBufnum, BufRateScale.kr(soundBufnum), loop: 1);
 chain = FFT(bufnum, in);
 chain2 = PV_Copy(chain, bufnum2);
 chain = PV_Decorrelate([chain, chain2], 1,  MouseX.kr);
 Out.ar(out, 0.5 * IFFT(chain));
}).play(s,[\out, 0, \bufnum, b, \bufnum2, d, \soundBufnum, c]);
)

x.free; [b, c, d].do(_.free);





﻿Figure 14.18

(
b = Buffer.read(s, "sounds/a11wlk01.wav");
SynthDef("grain",{ arg i_out=0, i_sampbufnum, dur = 0.05, 
 pointer, offset = 0.005, amp = 1.0, loop = 1;
 var thisStart, thisDur, grain;
 thisStart = pointer + IRand(0, offset); // adds random time offset
 grain = EnvGen.ar(Env.sine, 1.0, amp, 0.0, dur, 2) 
  * PlayBuf.ar(1,i_sampbufnum, BufRateScale.ir(i_sampbufnum),
   1, thisStart,loop);
 OffsetOut.ar(i_out,grain); // use OffsetOut for precise sub-block timing
}).add;
)

(
x = {
var numGrains = 32; // approximate number of simultaneous grains
var numChannels = 2; // adjust for your setup
var dur = 0.05, durRand = 0.05, thisDur;
var start, now;
var numGrainsRecip;
numGrainsRecip = numGrains.reciprocal; // save some divides by converting to reciprocal

start = Main.elapsedTime;
loop({ 
 now = Main.elapsedTime - start;
 thisDur = dur + durRand.rand;
 s.bind({Synth("grain", [i_out: numChannels.rand, i_sampbufnum: b, dur: thisDur, 
  pointer: now * b.sampleRate, amp: numGrainsRecip]);
 }); // send as a bundle for precise sub-block timing
 (thisDur * numGrainsRecip).wait;
})
}.fork;
)

x.stop; b.free;




﻿Figure 14.19


Server.default = s = Server.internal;
s.boot;
(
n = 512; // number of bins
b = Buffer.alloc(s, n, 1);
c = Buffer.alloc(s, n, 1);

// create arrays of magnitude scalars and load them to buffers
d = Array.fill(n, {1.0.linrand});
e = 1.0 - d;
d = Buffer.loadCollection(s, d);
e = Buffer.loadCollection(s, e);

f = Buffer.read(s,"sounds/a11wlk01.wav");
)

(
x = SynthDef("spectral diffusion", { arg out=0, analBuf, analBufCopy, scalBuf1, scalBuf2, soundBuf;
 var chain1, chain2;
 chain1 = FFT(analBuf, PlayBuf.ar(1, soundBuf, BufRateScale.kr(soundBuf), loop: 1));
 chain2 = PV_Copy(chain1, analBufCopy); // copy the initial analysis
 chain1 = PV_MagMul(chain1, scalBuf1);
 chain2 = PV_MagMul(chain2, scalBuf2); 
 Out.ar(out,  0.5 * IFFT([chain1, chain2]));
}).play(s,[out: 0, analBuf: b, analBufCopy: c, scalBuf1: d, scalBuf2: e, soundBuf: f]);
s.scope; // compare the two channels
)

// execute this multiple times to change the distribution
(
g = Array.fill(n, {1.0.linrand});
h = 1 - g;
d.loadCollection(g);
e.loadCollection(h);
)

x.free; [b, c, d, e, f].do(_.free);




﻿Figure 15.1
(
x={
	var in, amp, freq, hasFreq, out;
	in = SoundIn.ar(0);
	amp = Amplitude.ar(in);
	# freq, hasFreq = Pitch.kr(in);
	LFTri.ar(freq*[1,2]) * amp;
}.play
)

x.free;



﻿Figure 15.2
b = Buffer.alloc(s,1024,1);   //for sampling rates 44100 and 48000
//b = Buffer.alloc(s,2048,1); //for sampling rates 88200 and 96000
	
(  //analyse loudness and poll result
x={
	var in, fft, loudness;
	
	in = SoundIn.ar(0); 
	
	fft = FFT(b.bufnum, in);
	
	loudness = Loudness.kr(fft); 
	
	loudness.poll(20); //poll for testing 20 times per second
	
	Out.ar(0,Pan2.ar(in)); 
}.play
)

x.free;
b.free;



﻿Figure 15.3
b = Buffer.alloc(s,1024,1); //for sampling rates 44100 and 48000
//b = Buffer.alloc(s,2048,1); //for sampling rates 88200 and 96000

//d=Buffer.read(s,"sounds/a11wlk01.wav");


(
x= {
	var in, fft, array;
	
	//in= PlayBuf.ar(1,d.bufnum,BufRateScale.kr(d.bufnum),1,0,1);
	
	in = SoundIn.ar(0); 
	
	fft = FFT(b.bufnum, in);
	
	array = MFCC.kr(fft); 
	
	array.size.postln; 
	
	Out.kr(0,array); 
	
	Out.ar(0,Pan2.ar(in)); 
}.play
)


c= Bus.new('control', 0, 13); 

//poll coefficients
c.getn(13,{arg val; {val.plot;}.defer}); 


//Continuous graphical display of MFCC values; free routine before closing window

(
var ms; 

w = Window("Thirteen MFCC coefficients", Rect(200,400,300,300));

ms = MultiSliderView(w, Rect(10,10,260,280));

ms.value_(Array.fill(13,0.0));
ms.valueThumbSize_(20.0);
ms.indexThumbSize_(20.0);
ms.gap_(0);

w.front;

r = {
	
	inf.do{
		
		c.getn(13,{arg val; {ms.value_(val*0.9)}.defer}); 
		
		0.04.wait; //25 frames per second
	};

}.fork;

)


//tidy up
(
r.stop;
b.free;
c.free;
x.free;
w.close;
)





﻿Figure 15.4
// Prepare the buffer
b = Buffer.alloc(s, 512);

(
x = {
	var sig, chain, onsets, pips, trigger;
	
	sig = SoundIn.ar(0); 
	
	chain = FFT(b, sig);
	
	// - move the mouse left/right to change the threshold:
	onsets = Onsets.kr(chain, MouseX.kr(0,1), \complex);
	
	trigger= SendTrig.kr(onsets);
	
	pips = SinOsc.ar(880, 0, EnvGen.kr(Env.perc(0.001, 0.1, 0.2), onsets));
	
	Out.ar(0, ((sig * 0.1) + pips).dup);
}.play;
)

(
// register to receive message
a= OSCresponder(s.addr,'/tr',{ arg time,responder,msg;
	[time,responder,msg].postln;
}).add;
)

a.remove; //Free the OSCresponder
x.free; // Free the synth
b.free; // Free the buffer






﻿Figure 15.5
b = Buffer.alloc(s,1024,1); //for sampling rates 44100 and 48000
//b = Buffer.alloc(s,2048,1); //for sampling rates 88200 and 96000

//track audio in (try clapping a beat or beatboxing, but allow up to 6 seconds for tracking to begin); events will be spawned at quarter, eighth and sixteenth note rates
(
SynthDef(\beattrack,{	
	var trackb,trackh,trackq,tempo;
	var source;
	var bsound,hsound,qsound;
	
	source = SoundIn.ar(0);
	
	#trackb,trackh,trackq,tempo = BeatTrack.kr(FFT(b.bufnum, source));
	
	bsound = Pan2.ar(LPF.ar(WhiteNoise.ar*(Decay.kr(trackb,0.05)),1000),0.0);
	
	hsound = Pan2.ar(BPF.ar(WhiteNoise.ar*(Decay.kr(trackh,0.05)),3000,0.66),-0.5);
	
	qsound = Pan2.ar(HPF.ar(WhiteNoise.ar*(Decay.kr(trackq,0.05)),5000),0.5);
	
	Out.ar(0, bsound+hsound+qsound);
}).add;
)

x = Synth(\beattrack); // Go!

x.free;
b.free; // Free the buffer



﻿Figure 15.6
//straight forward test file with few transients; training set in e minor from MIREX2006 
//You will need to substitute your own soundfile to load here
d=Buffer.read(s,"/Users/nickcollins/Desktop/ML/training_wav/78.wav")


b = Buffer.alloc(s,4096,1); //for sampling rates 44100 and 48000
//b = Buffer.alloc(s,8192,1); //for sampling rates 88200 and 96000

(
x= {
	var in, fft; 
	var key;
	
	in = PlayBuf.ar(1,d.bufnum,BufRateScale.kr(d.bufnum),1,0,1);
	
	fft = FFT(b.bufnum, in);
	
	key = KeyTrack.kr(fft, 2.0, 0.5);
	
	key.poll; //write out detected key
	
	Out.ar(0,Pan2.ar(in)); 
}.play
)

x.free;
b.free;





﻿Figure 15.7
//Example uses internal server to demonstrate shared busses

(
s=Server.internal; 
Server.default=s; 

s.doWhenBooted({

b = Buffer.alloc(s, 512);

//this SynthDef will make no sound, just analyses input
SynthDef(\pitchandonsets,
{
	var in, amp, freqdata, chain, onsets, trigger;
	
	in = SoundIn.ar(0);
	amp = RunningSum.rms(in, 64); //get rms amplitude value per control block
	freqdata = Pitch.kr(in); 
	
	//allow synchronous polling, Internal Server only
	SharedOut.kr(0,freqdata);	
	SharedOut.kr(2,amp);
	
	chain = FFT(b, in);
	
	// - move the mouse left/right to change the threshold:
	onsets = Onsets.kr(chain, MouseX.kr(0,1), \complex);
	
	trigger = SendTrig.kr(onsets);

}).send(s); 
});

)



(
var freqlist=List(), amplist=List(); 
var notelist= List(), numnotes=10; //will hold the last 10 notes 
var lasttime, started=false; 
var maxlength=0.5, maxkperiods, waittime;

maxkperiods = ((maxlength*(s.sampleRate))/(s.options.blockSize)).asInteger;
waittime = (s.options.blockSize)/(s.sampleRate);


// register to receive message
a= OSCresponder(s.addr,'/tr',{ arg time,responder,msg;
	var newnote;
		
	if(started,{	
		
	//finalise previous note as [starttime, ioi= inter onset interval, dur, medianpitch, maxamp]	
	newnote = 	[lasttime, time-lasttime, (time-lasttime).min(maxlength), if(freqlist.notEmpty, {freqlist.median.cpsmidi},{nil}),amplist.maxItem.ampdb];
	
	newnote.postln;
		
	notelist.addFirst(newnote);
	
	//remove oldest note if over size
	if(notelist.size>numnotes,{notelist.pop}); 
	
	},{started = true;}); 
	
	//reset lists for collection
	freqlist = List();
	amplist = List(); 
	lasttime = time;
		
}).add;

x= Synth(\pitchandonsets); 

//poll values
{	
	
	inf.do{  
		var freq, hasfreq, rmsamp;
		 
		freq = s.getSharedControl(0);
		hasfreq = s.getSharedControl(1);
		rmsamp = s.getSharedControl(2);
		
		//don't allow notes of longer than 500 control periods or so
		if((hasfreq>0.5) and: (amplist.size<maxkperiods), {freqlist.add(freq)});
		
		if(amplist.size<maxkperiods, {amplist.add(rmsamp)});
		 
		//poll every control period, intensive
		(waittime).wait;
	}; 
	
}.fork;

)



(
a.remove; //Free the OSCresponder
x.free; // Free the synth
b.free; // Free the buffer
)






﻿Figure 15.8
//do this first: 
MIDIIn.connect; 	// init for one port midi interface


//now:
m = OnlineMIDI();

m.analyse(3,1.0); //3 seconds window, step size of 1.0 seconds

m.data //poll current data

m.status = true; //prints analysis data as it goes
m.status= false;

//use analysis data to formulate responses

(
SynthDef(\beep2,{arg freq=440,amp=0.1, pan=0.0, dur=0.1; 
var source; 

source= SinOsc.ar(freq*[1,1.007],0,amp*0.5);

Out.ar(0,Pan2.ar(Mix(source)*Line.kr(1,0,dur, doneAction:2),pan))}).add;
)

//to echo each note you play on a MIDI keyboard with a sound; your SynthDef must have freq and amp arguments, and deal with duration and freeing the Synth itself.  
(
m.playinput= true; 
m.inputsynthdef= \beep2; 
)

//set a function that gets called after each window is analysed, to schedule events over the next second 
(
m.response = {|analysis|  
	var number;
	number= analysis.density; 
	//number= max(0,(10-(analysis.density))); //inverting number of notes playing
	
	if(analysis.iois.notEmpty, {
		{
		
		number.do{
		
		Synth(\beep2, [\freq, analysis.pitches.choose.midicps, \amp, 0.2*(rrand(analysis.volumemin, analysis.volumemax))]);
		
		analysis.iois.choose.wait; //could last longer than the next second, but still fun! 
		
		}; 
		
		}.fork;
	}); 
	
};
)


m.response= nil; //stop





﻿Figure 16.1: Short grain durations, pitch to colored click 

(	// a gabor grain, gaussian-shaped envelope
SynthDef(\gabor, { |out, freq = 440, sustain = 1, pan, amp = 0.1, width = 0.25 |
	var env = LFGauss.ar(sustain, width, loop: 0, doneAction: 2);
	var son = FSinOsc.ar(freq, 0.5pi, env);
	OffsetOut.ar(out, Pan2.ar(son, pan, amp));

}, \ir ! 6).add;

	// or an approximation with a sine-shaped envelope
SynthDef(\gabor1, { |out, amp=0.1, freq=440, sustain=0.01, pan| 
	var snd = FSinOsc.ar(freq);
	var env = EnvGen.ar(Env.sine(sustain, amp), doneAction: 2);
	OffsetOut.ar(out, Pan2.ar(snd * env, pan));
}, \ir ! 5).add;
)

(
Pbindef(\grain,
	\instrument, \gabor, \freq, 1000, 
	\dur, 0.5, \sustain, 20/1000, \amp, 0.2
).play;
)
Pbindef(\grain, \sustain, 10/Pkey(\freq));
Pbindef(\grain, \sustain, 5/Pkey(\freq));
Pbindef(\grain, \sustain, 3/Pkey(\freq));
Pbindef(\grain, \sustain, 2/Pkey(\freq));
Pbindef(\grain, \sustain, 1/Pkey(\freq));

	// successively shorter, end
Pbindef(\grain, \sustain, Pseq((10..1)) / Pkey(\freq)).play;

	// random drift of grain duration
Pbindef(\grain, \sustain, Pbrown(1, 10, 3) / Pkey(\freq), \dur, 0.1).play



﻿Figure 16.2: Perception of short silences.

(
p = ProxySpace.push;

~source = { SinOsc.ar * 0.1 };
~silence = { |silDur=0.01| 
	EnvGen.ar(
		Env([0, 1, 1, 0, 0, 1, 1, 0], [0.01, 2, 0.001, silDur, 0.001, 2, 0.01]), 
		doneAction: 2) ! 2
};
~listen = ~source * ~silence;
~listen.play;
)

~silence.spawn([\silDur, 0.001]); // sounds like an added pulse 
~silence.spawn([\silDur, 0.003]);
~silence.spawn([\silDur, 0.01]);
~silence.spawn([\silDur, 0.03]);	  // a pause in the sound

	// try the same examples with noise:
~source = { WhiteNoise.ar * 0.1 };	

p.pop



﻿Figure 16.3: Order confusion with sounds in fast succession. 
	As grains move closer and closer together, their order becomes ambiguous. 

(
			// a simple percussive envelope
SynthDef(\percSin, { |out, amp=0.1, freq=440, sustain=0.01, pan| 
	var snd = FSinOsc.ar(freq);
	var env = EnvGen.ar(
		Env.perc(0.1, 0.9, amp), timeScale: sustain, doneAction: 2);
	OffsetOut.ar(out, Pan2.ar(snd * env, pan));
}, \ir ! 5).add;
)
(
Pbindef(\lo, 
	\instrument, \percSin, \sustain, 0.05, 
	\freq, 250, \amp, 0.2, \dur, 0.5, \lag, 0
).play;
Pbindef(\hi, 
	\instrument, \percSin, \sustain, 0.05, 
	\freq, 875, \amp, 0.1, \dur, 0.5, \lag, 0
).play;
)
	// try different lag times between them
Pbindef(\hi, \lag, 0.1);
Pbindef(\hi, \lag, 0.03);
Pbindef(\hi, \lag, 0.01);
Pbindef(\hi, \lag, 0.003);

	// hi too early or too late by a fixed time - which one is first?
Pbindef(\hi, \lag, ([-1, 1].choose * 0.01).postln).play;
Pbindef(\hi, \lag, ([-1, 1].choose * 0.02).postln);

	// is it easier to hear when the sounds are panned apart?
Pbindef(\hi, \pan, 0.5); Pbindef(\lo, \pan, -0.5);
Pbindef(\hi, \pan, 0);   Pbindef(\lo, \pan, 0);




﻿Figure 16.4: multiple grains fuse into one composite.
	// when the order changes, the sound is subtly different.
(
Pbindef(\grain4, 
	\instrument, \percSin, \sustain, 0.03, \amp, 0.2,
	\freq, Pshuf([1000, 600, 350, 250]), // random every each time
	\dur, 0.005
).play;
				// repeat grain cluster 
Tdef(\grain, { loop { Pbindef(\grain4).play; 1.wait } }).play;
)
	// fixed order
Pbindef(\grain4, \freq, Pseq([1000, 600, 350, 250].scramble));

	// different order every time
Pbindef(\grain4, \freq, Pshuf([1000, 600, 350, 250]));




﻿Figure 16.6 – Making different envelope shapes

Env.sine.plot2;		// approx. gaussian 
Env([0, 1, 1, 0], [0.25, 0.5, 0.25] * 0.1, \sin).test.plot2; // quasi-gaussian
Env([0, 1, 1, 0], [0.25, 0.5, 0.25] * 0.1, \lin).test.plot2; // 3 stage line segments.
Env([0, 1, 1, 0], [0.25, 0.5, 0.25] * 0.1, \welch).test.plot2; // welch curve interpolation
Env([1, 0.001], [0.1], \exp).test.plot2;	// expoDec (exponential decay);
Env([0.001, 1], [0.1], \exp).test.plot2;	// revExpoDec (reverse exponential decay);
Env.perc(0.01, 0.09).test.plot2;

(	// a sinc function envelope 
q = q ? ();
q.makeSinc = { |q, num=1, size=400| 
	dup({ |x| x = x.linlin(0, size-1, -pi, pi) * num; sin(x) / x }, size);
}; 
a = q.makeSinc(6);
a.plot(bounds: Rect(0,0,409,200), minval: -1, maxval: 1);
)



﻿// figure 16.9 - SynthDefs with different envelopes

(	// a gabor (approx. gaussian-shaped) grain
SynthDef(\gabor1, { |out, amp=0.1, freq=440, sustain=0.01, pan| 
	var snd = FSinOsc.ar(freq);
	var amp2 = amp * AmpComp.ir(freq.max(50)) * 0.5;
	var env = EnvGen.ar(Env.sine(sustain, amp2), doneAction: 2);
	OffsetOut.ar(out, Pan2.ar(snd * env, pan));
}, \ir ! 5).add;

			// wider, quasi-gaussian envelope, with a hold time in the middle. 
SynthDef(\gabWide, { |out, amp=0.1, freq=440, sustain=0.01, pan, width=0.5| 
	var holdT = sustain * width;
	var fadeT = 1 - width * sustain * 0.5;
	var snd = FSinOsc.ar(freq);
	var amp2 = amp * AmpComp.ir(freq.max(50)) * 0.5;
	var env = EnvGen.ar(Env([0, 1, 1, 0], [fadeT, holdT, fadeT], \sin), 
		levelScale: amp2, 
		doneAction: 2);
	OffsetOut.ar(out, Pan2.ar(snd * env, pan));
}, \ir ! 5).add;

			// a simple percussive envelope
SynthDef(\percSin, { |out, amp=0.1, freq=440, sustain=0.01, pan| 
	var snd = FSinOsc.ar(freq);
	var amp2 = amp * AmpComp.ir(freq.max(50)) * 0.5;
	var env = EnvGen.ar(
		Env.perc(0.1, 0.9, amp2), 
			timeScale: sustain, 
			doneAction: 2);
	OffsetOut.ar(out, Pan2.ar(snd * env, pan));
}, \ir ! 5).add;

			// a reversed  percussive envelope
SynthDef(\percSinRev, { |out, amp=0.1, freq=440, sustain=0.01, pan| 
	var snd = FSinOsc.ar(freq);
	var amp2 = amp * AmpComp.ir(freq.max(50)) * 0.5;
	var env = EnvGen.ar(
		Env.perc(0.9, 0.1, amp2), 
			timeScale: sustain, 
			doneAction: 2
		);
	OffsetOut.ar(out, Pan2.ar(snd * env, pan));
}, \ir ! 5).add;

			// an exponential decay envelope
SynthDef(\expodec, { |out, amp=0.1, freq=440, sustain=0.01, pan| 
	var snd = FSinOsc.ar(freq);
	var amp2 = AmpComp.ir(freq.max(50)) * 0.5 * amp;
	var env = XLine.ar(amp2, amp2 * 0.001, sustain, doneAction: 2);
	OffsetOut.ar(out, Pan2.ar(snd * env, pan));
}, \ir ! 5).add;

			// a reversed exponential decay envelope
SynthDef(\rexpodec, { |out, amp=0.1, freq=440, sustain=0.01, pan| 
	var snd = FSinOsc.ar(freq);
	var amp2 = amp * AmpComp.ir(freq.max(50)) * 0.5;
	var env = XLine.ar(amp2 * 0.001, amp2, sustain, doneAction: 2) 
		* (AmpComp.ir(freq) * 0.5);
	OffsetOut.ar(out, Pan2.ar(snd * env, pan));
}, \ir ! 5).add;
)


﻿Figure 16.10: Changing grain duration, frequency, envelope.

	// figure 16.10 - changing grain duration, frequency, envelope
(
Pbindef(\grain0,
	\instrument, \gabor1, \freq, 500, 
	\sustain, 0.01, \dur, 0.2	
).play;
)
	// change grain durations
Pbindef(\grain0, \sustain, 0.1);
Pbindef(\grain0, \sustain, 0.03);
Pbindef(\grain0, \sustain, 0.01);
Pbindef(\grain0, \sustain, 0.003);
Pbindef(\grain0, \sustain, 0.001);
Pbindef(\grain0, \sustain, Pn(Pgeom(0.1, 0.9, 60)));
Pbindef(\grain0, \sustain, Pfunc({ exprand(0.0003, 0.03) }));
Pbindef(\grain0, \sustain, 0.03);

	// change grain waveform (sine) frequency
Pbindef(\grain0, \freq, 300);
Pbindef(\grain0, \freq, 1000);
Pbindef(\grain0, \freq, 3000);
Pbindef(\grain0, \freq, Pn(Pgeom(300, 1.125, 32)));
Pbindef(\grain0, \freq, Pfunc({ exprand(300, 3000) }));
Pbindef(\grain0, \freq, 1000);

	// change synthdef for different envelopes
Pbindef(\grain0, \instrument, \gabor1);
Pbindef(\grain0, \instrument, \gabWide);
Pbindef(\grain0, \instrument, \percSin);
Pbindef(\grain0, \instrument, \percSinRev);
Pbindef(\grain0, \instrument, \expodec);
Pbindef(\grain0, \instrument, \rexpodec);
Pbindef(\grain0, \instrument, Prand([\gabWide, \percSin, \percSinRev], inf));



﻿Figure 16.11: Different control strategies applied to density.

(	// synchronous - regular time intervals
Pbindef(\grain0).clear;
Pbindef(\grain0).play;
Pbindef(\grain0, 
	\instrument, \expodec, 
	\freq, Pn(Penv([200, 1200], [10], \exp), inf),
	\dur, 0.1, \sustain, 0.06
);
)
	// different fixed values
Pbindef(\grain0, \dur, 0.06) 	// rhythm
Pbindef(\grain0, \dur, 0.035)	
Pbindef(\grain0, \dur, 0.02)	// fundamental frequency 50 Hz

	// time-changing values: accelerando/ritardando
Pbindef(\grain0, \dur, Pn(Penv([0.1, 0.02], [4], \exp), inf));
Pbindef(\grain0, \dur, Pn(Penv([0.1, 0.02, 0.06, 0.01].scramble, [3, 2, 1], \exp), inf));

	// repeating values: rhythms or tones
Pbindef(\grain0, \dur, Pstutter(Pwhite(2, 15), Pfunc({ exprand(0.01, 0.3) })));

	// introducing irregularity - quasi-synchronous
Pbindef(\grain0, \dur, 0.03 * Pwhite(0.8, 1.2))
Pbindef(\grain0, \dur, 0.03 * Pbrown(0.6, 1.4, 0.1)) // slower drift
Pbindef(\grain0, \dur, 0.03 * Pwhite(0.2, 1.8))

	// average density constant, vary degree of irregularity  
Pbindef(\grain0, \dur, 0.02 * Pfunc({ (0.1.linrand * 3) + 0.9 }));
Pbindef(\grain0, \dur, 0.02 * Pfunc({ (0.3.linrand * 3) + 0.3 }));
Pbindef(\grain0, \dur, 0.02 * Pfunc({ (1.0.linrand * 3) + 0.0 }));
Pbindef(\grain0, \dur, 0.02 * Pfunc({ 2.45.linrand.squared })); // very irregular


(	// coupling - duration depends on freq parameter
Pbindef(\grain0, 
	\freq, Pn(Penv([200, 1200], [10], \exp), inf),
	\dur, Pfunc({ |ev| 20 / ev.freq  })
);
)

	// different freq movement, different timing
Pbindef(\grain0, \freq, Pbrown(48.0, 96.0, 12.0).midicps);

(	// duration depends on freq, with some variation - tendency mask
Pbindef(\grain0, 
	\freq, Pn(Penv([200, 1200], [10], \exp), inf),
	\dur, Pfunc({ |ev| 20 / ev.freq * rrand(0.5, 1.5)  })
);
)




﻿Figure 16.12: Control strategies applied to different parameters

(
Pbindef(\grain0).clear;
Pbindef(\grain0, 
	\instrument, \expodec, 
	\freq, 200,
	\sustain, 0.05, \dur, 0.07
).play;
)
	// time-varying freq with envelope pattern
Pbindef(\grain0, \freq, Pn(Penv([200, 1200], [10], \exp), inf));
	// random freq
Pbindef(\grain0, \freq, 400 * Pwhite(-24.0, 24).midiratio);
	// timechanging with random variation
Pbindef(\grain0, \freq, Pn(Penv([400, 2400], [10], \exp), inf) * Pwhite(-24.0, 24).midiratio);

	// panning
Pbindef(\grain0, \pan, Pwhite(-0.8, 0.8));  // random
Pbindef(\grain0, \pan, Pn(Penv([-1, 1], [2]), inf)); // tendency
Pbindef(\grain0, \pan, Pfunc({ |ev| ev.freq.explin(50, 5000, -1, 1) })); // coupled to freq

	// time scattering variants
Pbindef(\grain0, \dur, 0.1 * Pwhite(0.5, 1.5));	// random range
Pbindef(\grain0, \dur, 0.05 * Prand([0, 1, 1, 2, 4], inf)); // rhythmic random

	// amplitude - randomized
Pbindef(\grain0, \amp, Pwhite(0.01, 0.2));	// linear
Pbindef(\grain0, \amp, Pwhite(-50, -14).dbamp); // exponential - more depth
Pbindef(\grain0, \dur, 0.025 * Prand([0, 1, 1, 2, 4], inf)); // could be denser now

	// random amplitude envelopes with Pseg
(
Pbindef(\grain0, 
	\amp, Pseg(
		Pxrand([-50, -20, -30, -40] + 10, inf), // level pattern
		Pxrand([0.5, 1, 2, 3], inf), 		// time pattern
		Prand([\step, \lin], inf)			// curve pattern
	).dbamp
); 
)
	// grain sustain time coupled to freq
Pbindef(\grain0, \sustain, Pkey(\freq).reciprocal * 20).play;



﻿	Figure 16.13: GrainFM with individual control proxies

	// figure 16.13   - GrainFM with individual control proxies
p = ProxySpace.push;

(
~trig = { |dens=10| Impulse.kr(dens) };
~freq = { MouseX.kr(100, 2000, 1) * LFNoise1.kr(1).range(0.25, 1.75) };
~moddepth = { LFNoise1.kr(20).range(1, 10) };
~modfreq = 200;
~graindur = 0.1;

~grain = { arg envbuf = -1;
	GrainFM.ar(2, ~trig.kr, ~graindur.kr, 
		~freq.kr, ~modfreq.kr, ~moddepth.kr, 
		pan: WhiteNoise.kr, envbufnum: envbuf) * 0.2
};
~grain.play;
)
	// change control ugens: 
~modfreq = { ~freq.kr * LFNoise2.kr(1).range(0.5, 2.0) }; // modfreq roughly follows freq
~trig = { |dens=10| Dust.kr(dens)};	// random triggering, same density
~freq = { LFNoise0.kr(0.3).range(200, 800) };
~moddepth = 3; 	// fixed depth
~graindur = { LFNoise0.kr.range(0.01, 0.1) };



﻿Figure 16.14: GrainBuf with control proxies

b = Buffer.read(s, "sounds/a11wlk01-44_1.aiff");
(
~grain.set(\wavebuf, b.bufnum);
~trig = { |dens=10| Impulse.kr(dens) };
~graindur = 0.1;
~filepos = {LFNoise2.kr(0.2).range(0, 1) };
~rate = { LFNoise1.kr.range(0.5, 1.5) };

~grain = { arg envbuf = -1, wavebuf = 0;
	GrainBuf.ar(2, ~trig.kr, ~graindur.kr, wavebuf, 
	~rate.kr, ~filepos.kr, 2, WhiteNoise.kr, envbuf) * 0.2
};
~grain.play;
)

	// experiment with control proxies
~trig = { |dens=20| Impulse.kr(dens) };
~rate = { LFNoise1.kr.range(0.99, 1.01) };
~filepos = { MouseX.kr + LFNoise0.kr(100, 0.03) };
~graindur = 0.05;
~trig = { |dens=50| Dust.kr(dens) };

c = Buffer.sendCollection(s, Env.perc(0.01, 0.99).discretize, 1);
~grain.set(\envbuf, c.bufnum); 
~grain.set(\envbuf, -1);

~trig = { |dens=50| Impulse.kr(dens) }; ~graindur = 0.05;




﻿Figure 16.15: Glisson synthesis

(
b = Buffer.read(s, "sounds/a11wlk01-44_1.aiff");

SynthDef("glisson", 
	{ arg out = 0, envbuf, freq=800, freq2=1200, sustain=0.001, amp=0.2, pan = 0.0;
		var env = Osc1.ar(envbuf, sustain, 2);
		var freqenv = XLine.ar(freq, freq2, sustain);
		OffsetOut.ar(out, 
			Pan2.ar(SinOsc.ar(freqenv) * env, pan, amp)
		)
}, \ir!7).add;
)

(
Tdef(\gliss0, { |e|
	100.do({ arg i;
		s.sendBundle(s.latency, ["/s_new", "glisson", -1, 0, 0, 
			\freq, i % 10 * 100 + 1000,
			\freq2, i % 13 * -100 + 3000,
			 \sustain, 0.05, 
			 \amp, 0.1,
			 \envbuf, b.bufnum
		]);
		(3 / (i + 10)).wait;
	});
}).play;
)





﻿Figure 16.16: Pulsar basics – a set of waveform and control tables

	// figure 16.16 - Pulsar basics - make a set of waveform and control tables
(
q = ();
q.curr = (); 	// make a dict for the set of tables
q.curr.tab = ();
				// random tables for pulsaret  and envelope waveforms:
q.curr.tab.env = Env.perc.discretize; 
q.curr.tab.pulsaret = Signal.sineFill(1024, { 1.0.rand }.dup(7));

			// random tables for the control parameters:
q.curr.tab.fund = 200 ** Env({1.0.rand}!8, {1.0.rand}!7, \sin).discretize.as(Array);
q.curr.tab.form = 500 ** ( 0.5 + Env({rrand(0.0, 1.0)}!8, {1.0.rand}!7, \sin).discretize.as(Array));
q.curr.tab.amp = 0.2.dup(1024);
q.curr.tab.pan = Signal.sineFill(1024, { 1.0.rand }.dup(7));

			// make buffers from all of them:
q.bufs = q.curr.tab.collect({ |val, key| Buffer.sendCollection(s, val, 1) });
)
		// plot one of them
q.bufs.pulsaret.plot2("a pulsaret");




﻿Figure 16.17: Pulsars as nodeproxies using GrainBuf

(
p = ProxySpace.push; 

		// fund, form, amp, pan
~controls = [ 16, 100, 0.5, 0]; 
~pulsar1.set(\wavebuf, q.bufs.pulsaret.bufnum);
~pulsar1.set(\envbuf, q.bufs.env.bufnum);

~pulsar1 = { |wavebuf, envbuf = -1| 
	var ctls = ~controls.kr;
	var trig = Impulse.ar(ctls[0]);
	var grdur = ctls[1].reciprocal;
	var rate = ctls[1] * BufDur.kr(wavebuf);
		
	GrainBuf.ar(2, trig, grdur, wavebuf, rate, 0, 4, ctls[3], envbuf);
};
~pulsar1.play;
)

	// crossfade between control settings
~controls.fadeTime = 3; 
~controls = [ 16, 500, 0.5, 0]; 	// change formfreq
~controls = [ 50, 500, 0.5, 0]; 	// change fundfreq
~controls = [ 16, 100, 0.5, 0]; 	// change both
~controls = [ rrand(12, 100), rrand(100, 1000)]; 

(	// control parameters from looping tables
~controls = { |looptime = 10| 
	var rate = BufDur.kr(q.bufs.pulsaret.bufnum) / looptime; 
	A2K.kr(PlayBuf.ar(1, [\fund, \form, \amp, \pan].collect(q.bufs[_]), 
		rate: rate, loop: 1));
};
)



﻿Figure 16.18: Making new tables and sending them to buffers

q.bufs.pulsaret.sendCollection(Array.linrand(1024, -1.0, 1.0)); // noise burst
q.bufs.pulsaret.read("sounds/a11wlk01.wav", 44100 * 1.5);       // sample
q.bufs.pulsaret.sendCollection(Pbrown(-1.0, 1.0, 0.2).asStream.nextN(1024));

	// make a new random fundfreq table, and send it
q.curr.tab.fund = 200 ** Env({1.0.rand}!8, {1.0.rand}!7, \sin).discretize.as(Array);
q.bufs.fund.sendCollection(q.curr.tab.fund);

	// and a new random formfreq table
q.curr.tab.form = 500 ** ( 0.5 + Env({rrand(0.0, 1.0)}!8, {1.0.rand}!7, \sin).discretize.as(Array));
q.bufs.form.sendCollection(q.curr.tab.form);




﻿Figure 16.19: A nodeproxy for time-pitch changing

p = ProxySpace.push(s.boot);
b = Buffer.read(s, "sounds/a11wlk01-44_1.aiff");
(
~timepitch = {arg sndbuf, pitchRatio=1, pitchRd=0.01, grainRate=10, overlap=2, 
	posSpeed=1, posRd=0.01;
	
	var graindur = overlap / grainRate;
	var pitchrate = pitchRatio + LFNoise0.kr(grainRate, pitchRd);
	var position = LFSaw.kr(posSpeed / BufDur.kr(sndbuf)).range(0, 1) 
		+ LFNoise0.kr(grainRate, posRd);
		
	GrainBuf.ar(2, Impulse.kr(grainRate), graindur, sndbuf, pitchrate,
			position, 4, 0, -1)
};
~timepitch.set(\sndbuf, b.bufnum);
~timepitch.play;
);

Spec.add(\pitchRatio, [0.25, 4, \exp]);
Spec.add(\pitchRd, [0, 0.5, \amp]);
Spec.add(\grainRate, [1, 100, \exp]);
Spec.add(\overlap, [0.25, 16, \exp]);
Spec.add(\posSpeed, [-2, 2]);
Spec.add(\posRd, [0, 0.5, \amp]);
NodeProxyEditor(~timepitch, 10);

	// reconstruct original
~timepitch.set(\pitchRatio, 1, \pitchRd, 0, \grainRate, 20, \overlap, 4, \posSpeed, 1, \posRd, 0);

	// four times as long: tweak pitchRd and posJitter to reduce artifacts
~timepitch.set(\pitchRatio, 1, \pitchRd, 0, \grainRate, 20, \overlap, 4, \posSpeed, 0.25, \posRd, 0);

	// random read position, random pitch
~timepitch.set(\pitchRatio, 1, \pitchRd, 0.5, \grainRate, 20, \overlap, 4, \posSpeed, 0.25, \posRd, 0.5);



﻿Figure 16.20: A constant-Q Synthdef.

b = Buffer.read(s, "sounds/a11wlk01-44_1.aiff");
(
SynthDef(\constQ, { |out, bufnum=0, amp=0.5, pan, centerPos=0.5, sustain=0.1, 
	rate=1, freq=400, rq=0.3| 

	var ringtime = (2.4 / (freq * rq) * 0.66).min(0.5); // estimated
	var ampcomp = (rq ** -1) * (400 / freq ** 0.5);	
	var envSig = EnvGen.ar(Env([0, amp, 0], [0.5, 0.5] * sustain, \welch));
	var cutoffEnv = EnvGen.kr(Env([1, 1, 0], [sustain+ringtime,0.01]), doneAction: 2);
	var grain = PlayBuf.ar(1, bufnum, rate, 0, 
		centerPos - (sustain * rate * 0.5) * BufSampleRate.ir(bufnum), 
		1) * envSig;	
	var filtered = BPF.ar( grain, freq, rq, ampcomp ); 

	OffsetOut.ar(out, Pan2.ar(filtered, pan, cutoffEnv))
}, \ir.dup(8)).add;
)

Synth(\constQ, [\bufnum, b, \freq, exprand(100, 10000), \rq, exprand(0.01, 0.1), \sustain, 0.01]);



﻿Figure 16.21: A stream of constant-Q grains
(
Pbindef(\gr1Q, 
	\instrument, \constQ, \bufnum, b.bufnum,
	\sustain, 0.01, \amp, 0.2,
	\centerPos, Pn(Penv([1, 2.0], [10], \lin)), 
	\dur, Pn(Penv([0.01, 0.09, 0.03].scramble, [0.38, 0.62] * 10, \exp)),
	\rate, Pwhite(0.95, 1.05), 
	\freq, Pbrown(64.0, 120, 8.0).midicps,
	\pan, Pwhite(-1, 1, inf),
	\rq, 0.03
).play;
)
	// changing parameters while playing
Pbindef(\gr1Q, \rq, 0.1);
Pbindef(\gr1Q, \rq, 0.01);
Pbindef(\gr1Q, \sustain, 0.03, \amp, 0.08);
Pbindef(\gr1Q, \freq, Pbrown(80, 120, 18.0).midicps);

Pbindef(\gr1Q, \rq, 0.03);

Pbindef(\gr1Q, \rate, Pn(Penv([1, 2.0], [6], \lin)));

	// variable duration
Pbindef(\gr1Q, \dur, Pwhite(0.01, 0.02));

	// a rhythm that ends
Pbindef(\gr1Q, \dur, Pgeom(0.01, 1.1, 40));





﻿Figure 16.22: A Wavesets object

w = Wavesets.from("sounds/a11wlk01.wav");

w.xings;			// all integer indices of the zero crossings found
w.numXings;		// the total number of zero crossings
w.lengths;		// lengths of all wavesets
w.amps;			// peak amplitude of every waveset
w.maxima;			// index of positive maximum value in every waveset
w.minima;			// index of negative minimum value in every waveset

w.fracXings;		// fractional zerocrossing points
w.fracLengths;	// and lengths: allows more precise looping.
				
w.lengths.plot;	// show distribution of lengths
w.amps.plot;

	// get data for a single waveset: frameIndex, length (in frames), dur
w.frameFor(140, 1);	
w.ampFor(140, 1);		// peak amplitude of that waveset or group
	
	// extract waveset by hand
w.signal.copyRange(w.xings[150], w.xings[151]).plot("waveset 150");
w.plot(140, 1);	// convenience plotting
w.plot(1510, 1);	

	// plot a group of 5 adjacent wavesets
w.plot(1510, 5)	




﻿Figure 16.25: Playing Wavesets from buffers.

(
	// A wavesets loads the file into a buffer by default.
		b = w.buffer;		
	// Wavesets.prepareSynthDefs loads this synthdef: 
		SynthDef(\wvst0, { arg out = 0, buf = 0, start = 0, length = 441, playRate = 1, sustain = 1, amp=0.2, pan; 
			var phasor = Phasor.ar(0, BufRateScale.ir(buf) * playRate, 0, length) + start;
			var env = EnvGen.ar(Env([amp, amp, 0], [sustain, 0]), doneAction: 2);
			var snd = BufRd.ar(1, buf, phasor) * env;
			
			OffsetOut.ar(out, Pan2.ar(snd, pan));
		}, \ir.dup(8)).add;
)

// play from frame 0 to 440, looped for 0.1 secs, so ca 10 repeats. 
(instrument: \wvst0, bufnum: b.bufnum, start: 0, length: 440, amp: 1, sustain: 0.1).play;

	// get data from waveset
(
var start, length, sustain, repeats = 20; 
#start, length, sustain = w.frameFor(150, 5);

(	instrument: \wvst0, bufnum: b.bufnum, amp: 1, 
	start: start, length: length, sustain: sustain * repeats
).play;
)

	// or even simpler: 
w.eventFor(startWs: 150, numWs: 5, repeats: 20, playRate: 1).put(\amp, 0.5).play;



﻿Figure 16.26: A pattern to play wavesets

	// by default, this pattern reconstructs a soundfile segment as is.
(
Pbindef(\ws1).clear;
Pbindef(\ws1, 
	\instrument, \wvst0,
	\startWs, Pn(Pseries(0, 1, 3000), 1), 
	\numWs, 1, 
	\playRate, 1, 
	\bufnum, b.bufnum, 
	\repeats, 1, 
	\amp, 0.4,
	[\start, \length, \sustain], Pfunc({ |ev| 
		var start, length, wsDur; 

		#start, length, wsDur = w.frameFor(ev[\startWs], ev[\numWs]);
		[start, length, wsDur * ev[\repeats] / ev[\playRate].abs]
	}), 
	\dur, Pkey(\sustain)
).play;
)



﻿Figure 16.27: Some of Trevor Wishart's transforms

	// waveset transposition: every second waveset, half speed
Pbindef(\ws1, \playRate, 0.5, \startWs, Pn(Pseries(0, 2, 500), 1)).play;

	// reverse every single waveset 
Pbindef(\ws1, \playRate, -1, \startWs, Pn(Pseries(0, 1, 1000), 1)).play;
	// reverse every 2 wavesets
Pbindef(\ws1, \numWs, 2, \playRate, -1, \startWs, Pn(Pseries(0, 2, 1000), 1)).play;
	// reverse every 20 wavesets
Pbindef(\ws1, \numWs, 20, \playRate, -1, \startWs, Pn(Pseries(0, 20, 1000), 1)).play;
	// restore
Pbindef(\ws1, \numWs, 1, \playRate, 1, \startWs, Pn(Pseries(0, 1, 1000), 1)).play;

	// time stretching
Pbindef(\ws1, \playRate, 1, \repeats, 2).play;
Pbindef(\ws1, \playRate, 1, \repeats, 4).play;
Pbindef(\ws1, \playRate, 1, \repeats, 6).play;
Pbindef(\ws1, \repeats, 1).play;	// restore

	// waveset omission: drop every second
Pbindef(\ws1, \numWs, 1, \freq, Pseq([1, \], inf) ).play;
Pbindef(\ws1, \numWs, 1, \freq, Pseq([1,1, \, \], inf) ).play;
Pbindef(\ws1, \numWs, 1, \freq, Pfunc({ if (0.25.coin, 1, \) }) ).play; // drop randomly
Pbindef(\ws1, \numWs, 1, \freq, 1, \startWs, Pn(Pseries(0, 1, 1000)) ).play; // restore

	// waveset shuffling (randomize waveset order +- 5, 25, 125)
Pbindef(\ws1, \startWs, Pn(Pseries(0, 1, 1000), 1) + Pfunc({ 5.rand2 })).play;
Pbindef(\ws1, \startWs, Pn(Pseries(0, 1, 1000), 1) + Pfunc({ 25.rand2 })).play;
Pbindef(\ws1, \startWs, Pn(Pseries(0, 1, 1000), 1) + Pfunc({ 125.rand2 })).play;	



﻿Figure 16.28: Waveset substitution
	
	// the waveform to substitute
c = Buffer.alloc(s, 512); c.sendCollection(Signal.sineFill(512, [1]));
(
Pbindef(\ws1).clear;
Pbindef(\ws1, 
	\instrument, \wvst0,
	\startWs, Pn(Pseries(0, 1, 1000), 5), 
	\numWs, 1, \playRate, 1, 
	\buf, c.bufnum, // sine wave
	\repeats, 1, 
	\amp, 1,
	[\start, \length, \sustain], Pfunc({ |ev| 
		var start, length, wsDur, origRate; 
		origRate = ev[\playRate];
		
			// get orig waveset specs
		#start, length, wsDur = w.frameFor(ev[\startWs], ev[\numWs]);

			// adjust playrate for different length of substituted wave
		ev[\playRate] = origRate * (512 / length); 

			// get amplitude from waveset, to scale full volume sine wave
		ev[\amp] = ev[\amp] * w.ampFor(ev[\startWs], ev[\numWs]);
		
		[0, 512, wsDur * ev[\repeats] / origRate.abs]
	}), 
	\dur, Pkey(\sustain)
).play;
)
	// clearer sinewave-ish segments
Pbindef(\ws1, \playRate, 1, \repeats, 2).play;
Pbindef(\ws1, \playRate, 1, \repeats, 6).play;
Pbindef(\ws1).stop;

	// different waveforms
c.sendCollection(Signal.sineFill(512, 1/(1..4).squared.scramble));
c.sendCollection(Signal.rand(512, -1.0, 1.0));
c.sendCollection(Signal.sineFill(512, [1]));

c.plot;



﻿Figure 16.29: Wavesets played with a Tdef 
	
	// very simple first pass, fixed repeat time
(
Tdef(\ws1).set(\startWs, 400);
Tdef(\ws1).set(\numWs, 5);
Tdef(\ws1).set(\repeats, 5);

Tdef(\ws1, { |ev|
	var startFrame, length, wsSustain; 

	loop { 
		#startFrame, length, wsSustain = w.frameFor(ev.startWs.next, ev.numWs);

		(instrument: \wvst0, bufnum: b.bufnum, amp: 1, 
			start: startFrame, length:  length, 
			sustain: wsSustain * ev.repeats;
		).play;
		
		0.1.wait;	
	}
}).play;
)

Tdef(\ws1).set(\startWs, 420);
Tdef(\ws1).set(\repeats, 3);
Tdef(\ws1).set(\numWs, 2);

		// drop in a pattern for starting waveset 		
Tdef(\ws1).set(\startWs, Pn(Pseries(0, 5, 400) + 500, inf).asStream);


﻿Figure 16.30: Waittime derived from waveset duration and an added gap 
(
Tdef(\ws1).set(\gap, 3);
Tdef(\ws1, { |ev|
	var startFrame, length, wsSustain, reps; 

	loop { 
		reps = ev.repeats.next;

		#startFrame, length, wsSustain = 
			w.frameFor(ev.startWs.next, ev.numWs.next);			
		
		(instrument: \wvst0, bufnum: b.bufnum, amp: 1, 
			start: startFrame, length:  length, 
			sustain: wsSustain * reps,
			pan: 1.0.rand2
		).play;
		
			// derive waittime from waveset sustain time
			// add gap based on waveset sustain time 
		(wsSustain * (reps + ev.gap.next)).wait;
	}
}).play;
)
	// experiment with dropping in patterns:
	// very irregular gaps
Tdef(\ws1).set(\gap, { exprand(0.1, 20) });
	// sometimes continuous, sometimes gaps
Tdef(\ws1).set(\gap, Pbrown(-10.0, 20, 2.0).max(0).asStream);

	// random repeats
Tdef(\ws1).set(\repeats, { exprand(1, 20).round });
	// randomize number of wavesets per group
Tdef(\ws1).set(\numWs, { exprand(3, 20).round });
Tdef(\ws1).set(\numWs, 3, \repeats, { rrand(2, 5) });

Tdef(\ws1).stop;



﻿Figure 16.31: Wavesets with pitch contour and dropout rate
(
Tdef(\ws1).set(\startWs, Pn(Pseries(0, 5, 400) + 500, inf).asStream);

Tdef(\ws1).set(\gap, 0);
Tdef(\ws1).set(\pitchContour, 0);
Tdef(\ws1).set(\keepCoin, 1.0);
Tdef( 'ws1' ).set( 'repeats' , 5 );
Tdef( 'ws1' ).set( 'numWs' , 3 );

Tdef(\ws1, { |ev|
	var startFrame, length, wsSustain, reps, numWs, len2Avg; 
	var squeezer, playRate;
	loop { 
		reps = ev.repeats.next;
		numWs = ev.numWs.next;
		
		#startFrame, length, wsSustain = 
			w.frameFor(ev.startWs.next, numWs);			
		
		len2Avg = length / numWs / w.avgLength;		
		squeezer = len2Avg ** ev.pitchContour.next;
		wsSustain = wsSustain / squeezer; 
		playRate = 1 * squeezer;

		if (ev.keepCoin.next.coin) { 
			(instrument: \wvst0, bufnum: b.bufnum, amp: 1, 
				start: startFrame, length:  length, 
				sustain: wsSustain * reps,
				playRate: playRate, 
				pan: 1.0.rand2
			).play;
		};
		
		(wsSustain * (reps + ev.gap.next)).wait;
	}
}).play;
)

	// try different pitch Contours:
Tdef(\ws1).set(\pitchContour, 0); 	// original pitch

Tdef(\ws1).set(\pitchContour, 0.5); // flattened contour

		// waveset overtone singing - all equal length
Tdef(\ws1).set(\pitchContour, 1.0); 

		// inversion of contour
Tdef(\ws1).set(\pitchContour, 1.5);
Tdef(\ws1).set(\pitchContour, 2);
Tdef(\ws1).set(\repeats, 3); 

	// waveset omission
Tdef(\ws1).set(\keepCoin, 0.75);
Tdef(\ws1).set(\keepCoin, 1);

	// fade out by omission over 13 secs, pause 2 secs 
Tdef(\ws1).set(\keepCoin, Pn(Penv([1, 0, 0], [13, 2])).asStream).play;

	// add a pitch contour envelope
Tdef(\ws1).set(\pitchContour, Pn(Penv([0, 2, 0], [21, 13])).asStream);



﻿(
// read a whole sound into memory
s = Server.local;
b = Buffer.read(s,"sounds/a11wlk01.wav"); // remember to free the buffer later.
)
(
SynthDef("help_PlayBuf", { arg out=0,bufnum=0, rate=1;
Out.ar(out,
Pan2.ar(
PlayBuf.ar(1, bufnum, BufRateScale.kr(bufnum)*rate, loop: 1),
0)
)
}).add;
)
p=Synth(\help_PlayBuf, [\rate, 0.midiratio,\out, 0, \bufnum, b.bufnum]); // original pitch
p.set(\rate, 12.midiratio);	// one octave up
p.set(\rate, 7.midiratio);	// seven semitones up (fifth interval)

p.free;
p=nil;
b.free;
b=nil;



﻿Figure  17.2 

(
Pbind(
\midinote, Pseq([0, 2, 3, 5, 7]+60, inf),
\dur, 0.3
).play
)
//////////////////////////////////////////////////////



﻿  Figure  17.3 

(
Pbind(
\midinote, Pseq([0, 2, 3, 5.25, 7.5]+60, inf),
\dur, 0.3
).play
)
//////////////////////////////////////////////////////



﻿Figure  17.4 

(
Pbind(
\note, Pseq([0,2,4,5,7,9,11,12], inf),
\dur, 0.3,
\octave, 5
).play
)
//////////////////////////////////////////////////////



﻿  Figure  17.5 

(
Pbind(
\degree, Pseq([0,1,2,3,4,5,6,7], inf),
\dur, 0.3,
\octave, 5
).play
)
//////////////////////////////////////////////////////



﻿Figure  17.6 

(
Pbind(
\degree, Pseq([0,1,2,3,4,5,6,7], inf),
\dur, 0.3,
\octave, 5,
\scale, (0..11)
).play
)
//////////////////////////////////////////////////////



﻿Figure  17.7 

(
Pbind(
\degree, Pseq([0, 2, 2.1, 2.05], inf),
\dur, 0.3,
\scale, (0..11),
\octave, 5
).play
)
//////////////////////////////////////////////////////



﻿Figure  17.8 

(
Pbind(
\note, Pwhite(-6,9),
\dur, 0.3,
\sustain, 1.1,
\stepsPerOctave, 7
).play
)
//////////////////////////////////////////////////////



﻿    Figure  17.9 
(
e=Pbind(
\degree, Pwhite(-3, 7),
\dur, 0.25,
\stepsPerOctave, 21,
\sustain, 1.1,
\scale, [0, 4, 8, 11, 14, 17]
).play;
)
//////////////////////////////////////////////////////



﻿Figure  17.10 

(
// previous example should still be running
e.stream=Pbind(
\degree, Pwhite(-3, 7),
\dur, 0.25,
\stepsPerOctave, 21,
\sustain, 1.1,
\scale, [0, 3, 5, 8, 10, 13]
).asStream;
)
//////////////////////////////////////////////////////



﻿  Figure  17.11 

(
var stepsperoctave=3;
Array.fill(stepsperoctave, {arg i; 2.pow(i/stepsperoctave)});
)

//Using a function to calculate the value at a chosen degree
(
f = {|degree, steps|
2.pow(degree/steps)
};
)
// 	degree 0
f.(0, 3);
// 	degree 1
f.(1, 3);
// 	degree 2
f.(2, 3);

//The function is modified to multiply the value by a root frequency in Hertz
(
f = {|degree, steps, root=440|
2.pow(degree/steps)*root
};
)
//	12 notes per octave, degrees 0,1 and 12
f.(0,12)
f.(1, 12)
f.(12, 12)

//	14 notes per octave, degrees 0,1, 12 and 14
f.(0,14)
f.(1, 14)
f.(12, 14)
f.(14,14)
//////////////////////////////////////////////////////




﻿Figure 17.12 

(
SynthDef("tone2", { arg freq = 440, amp=0.5, gate=1, envdur=1.5;
var sound, env;
env = EnvGen.kr(Env.perc(0.01, envdur), doneAction:2);
sound = Pan2.ar(SinOsc.ar(freq, 0, amp)*env, 0);
Out.ar(0, sound);
}).add;
)
(
a=[ 1, 1.030303030303, 1.0606060606061, 1.1212121212121, 1.3636363636364, 1.6060606060606, 2 ]*220;

// Play the all the notes of the tuning
e=Pbind(
\freq, Pseq( a, inf),
\dur, 0.2,
\amp, 0.5,
\sustain, 0.6,
\instrument, \tone2
).play
)
// Choose the notes randomly
(
e.stream=Pbind(
\freq, Pn(Prand( a, 1)),
\dur, 0.2,
\amp, 0.5,
\sustain, 0.6,
\instrument, \tone2
).asStream
)
//////////////////////////////////////////////////////



﻿Figure 17.13 

(
~rationames=[1/1, 8/7, 7/6, 6/5, 5/4, 4/3, 7/5, 10/7, 3/2, 8/5, 5/3, 12/7, 7/4];
~scale=[0,3,5,8,10,12];
e = Pbind(
\freq, Pseq([
Pfunc({
(~rationames.wrapAt(~scale).[~scale.size.rand])*440
})
],inf),
\dur, 0.25,
\amp, 0.5,
\instrument, \tone2
).play; // returns an EventStream
)
// set a new scale
~scale=[0,2,5,7,9,11];
~scale=[0,1,3,5,6,8,9];
~scale=[0,3,5,8,10,12];
//////////////////////////////////////////////////////



﻿Figure 17.14 

(
var n, buts, synths, ratios, rationames;
w = Window("tonality diamond", Rect(200,500,420,150));
w.view.decorator = FlowLayout(w.view.bounds);

rationames=[
"7/4", "3/2","5/4","1/1",
"7/5","6/5","1/1","8/5",
"7/6","1/1","5/3","4/3",
"1/1","12/7","10/7","8/7"
];

n=rationames.size;

n.do({ |i|
Button(w, Rect(20,20+(i*30),100,30))
.states_([[rationames[i], Color.black, 
if((rationames[i])=="1/1", {Color.red},{Color.yellow})
]
])
.action_({ arg butt;
Synth(\tone2, [\freq, ((rationames[i]).interpret)*440]);

})
});
w.front;
)
//////////////////////////////////////////////////////



﻿Figure 17.16 

(
a=Pbind(
\degree, Pwhite(0, 12),
\dur, 0.5,
\octave, 5,
\amp, 0.4,
\stepsPerOctave, 12,
\instrument, \tone2
);
b=Pbind(
\degree, Pwhite(0, 14),
\dur, 0.25,
\octave, 4,
\amp, 0.4,
\stepsPerOctave, 14,
\instrument, \tone2
);
Ppar([a, b]).play;
)
//////////////////////////////////////////////////////



﻿Figure 17.17 

(
a=Pbind(
\degree, Pfunc({
[
[0, 6, 12].choose, 12.rand
].choose;
}),
\dur, 0.5,
\octave, 4,
\amp, 0.4,
\stepsPerOctave, 12,
\instrument, \tone2
);
b=Pbind(
\degree, Pfunc({
[
[0, 7, 14].choose, 14.rand
].choose;
}),
\dur, 0.25,
\octave, 5,
\amp, 0.3,
\stepsPerOctave, 14,
\instrument, \tone2
);
Ppar([a, b]).play;
)
//////////////////////////////////////////////////////



﻿Figure 17.18 

(
~tolerance={|a, b, t, max|
var c, d;
c=[];
d=[];
a.do({ |aitem, aindex|
b.do({ |bitem, bindex|
var x;
x = (aitem-bitem).abs;
if( (x > t) && (x < max),
{
c=c.add(aindex);
d=d.add(bindex);
//[aitem, bitem].post; " out of tune ".post; [aindex, bindex].postln;
//" ".postln;
})
})
});
[(0..a.size).difference(c), (0..b.size).difference(d)];
};
)

(
// use the function function with two tunings
var mintreshold, maxtreshold, int;

// two different equal tunings expressed linearly
a=Array.fill(12, { |i| (1/12)*(i) });
b=Array.fill(21, { |i| (1/21)*(i) });

int=1/21;				// smallest interval
mintreshold=int*0.15;
maxtreshold=int*0.85;
/*
intervals inferior to mintreshold are in tune
intervals between mintreshold and maxtreshold are out of tune
intervals superior to maxtreshold are in tune
*/

// print a list of notes from the two tunings which form a dissonant interval
~tolerance.value(a, b, mintreshold, maxtreshold);
)
//////////////////////////////////////////////////////



﻿Figure 17.19 

(
a=Pbind(
\degree, Pfunc({
// notes which clash with the other tuning have been removed
[0,4,8,12].choose
}),
\dur, 0.5,
\octave, 5,
\amp, 0.4,
\sustain, 0.85,
\stepsPerOctave, 12,
\instrument, \tone2
).play;
b=Pbind(
// notes which clash with the other tuning have been removed
\degree, Pfunc({
[0,7,14,21].choose
}),
\dur, 0.25,
\octave, 4,
\amp, 0.35,
\sustain, 0.85,
\stepsPerOctave, 21,
\instrument, \tone2
).play;
)

(
a.stream=Pbind(
// introducing more notes from that tuning after having changed the threshold
\degree, Pfunc({
[ 0, 1, 4, 7, 8, 9, 9, 12 ].choose
}),
\dur, 0.75,
\octave, 5,
\amp, 0.4,
\sustain, 0.85,
\stepsPerOctave, 12,
\instrument, \tone2
).asStream;
)
//////////////////////////////////////////////////////



﻿Figure 17.20 

(
f = {|steps| Array.fill(steps, { |i| 2.pow(i/steps) }) };
//	Calculation of the twelve equal-note temperament
x =  f.(12);
//	mapping the tuning to a new range beyond an octave
y = x.linlin(1, 2, 1, 2.25);
//	multiplying by a root frequency
a=y*440;

Pbind(
\freq, Pfunc({ a.choose }),
\dur, 0.25,
\octave, 5,
\amp, 0.5,
\sustain, 1.1,
\instrument, \tone2
).play
)
//////////////////////////////////////////////////////



﻿Figure 17.21 

(
Pbind(
\degree, Pwhite(0, 18),
\dur, 0.3,
\sustain, 1.0,
\amp, 0.5,
\sustain, 1.1,
\instrument, \tone2,
\stepsPerOctave,  18.809
).play;
)
//////////////////////////////////////////////////////




﻿Figure 17.22 

(
a=[ 1, 1.09375, 1.1875, 1.28125, 1.375, 1.46875, 1.5625, 1.65625];
b=a*440;
e=Pbind(
\freq, Pseq( b, inf),
\dur, 0.2,
\amp, 0.5,
\instrument, \tone2,
\sustain, 0.6
).play
)
// play in a different order
(
e.stream=Pbind(
\freq, Pn(Pshuf( b, 1)),
\dur, 0.2,
\amp, 0.5,
\instrument, \tone2,
\sustain, 0.6
).asStream
)
//////////////////////////////////////////////////////



﻿   Figure 17.23 

(
// F. Mogini pattern-based Tuning - 2000.
x=880;

Pbind(
\freq, Pn(
Plazy({
if(x<=150, {x=x*2});
if(x>=2000, {x=x/2});
x=[

x*[1.1428,  1.36, 1.26].choose,
x/[1.1428,  1.36, 1.26].choose

].choose
})
),
\dur, 0.14,
\sustain, 0.8,
\cutoff, Pfunc({ 1.0.rand})
).play;
)
//////////////////////////////////////////////////////




﻿Figure 17.24 

a=(1..16)*100
(
e=Pbind(
\freq, Pseq( a, inf),
\dur, 0.2
).play
)

// a beautiful tuning system can be created from the harmonic series.
(
e.stream=Pbind(
\freq, Pn(Pshuf( a, 1)),
\dur, 0.2,
\sustain, 0.8
).asStream
)
//////////////////////////////////////////////////////



﻿Figure 17.25

a=(1..11);
(
a.size.do({ |i|
var x=a[i];
while({x>2},{x=x/2});
a.put(i, x)
});
)

b=a.asSet.asArray.sort;
(
e=Pbind(
\freq, Pn(Pshuf( b*440, 1)),
\dur, 0.2,
\sustain, 0.8
).play
)
//////////////////////////////////////////////////////



﻿Figure 17.26 

a=(1..8);
b=(9..16);
(
a.size.do({ |i|
var x=a[i];
var y=b[i];
// harmonics below 8 remain in the first octave
while({x>2},{x=x/2});
// harmonics above 9 remain in the second octave
while({y>4},{y=y/2});
a.put(i, x);
b.put(i, y);
});
)
a;
b;
c=(a++b).asSet.asArray.sort;
c;

(
e=Pbind(
\freq, Pn(Pshuf( c*200, 1)),
\dur, 0.2,
\sustain, 1.1
).play
)
//////////////////////////////////////////////////////



﻿  Figure 17.27 

(
// 	a function to expand the tuning from one octave to four octaves
~harmsfunc={arg stepsperoctave=7;
var harms;
// calculate each note from the tuning
harms=Array.fill(stepsperoctave, {arg i; 2.pow(i/stepsperoctave)});
harms.size.do({ |i|
if( 0.6.coin, {
// multiply some of the notes to create higher harmonics
harms.put(i, (harms[i])*[1,2,4,8].choose )
})
});
harms.sort;
};
)

//  create an array of virtual harmonics, seven equal-note temperament
~harms=~harmsfunc.value(7);

(
// send a synth definition with some partials and the current value of ~harms

SynthDef(\cfstring1, { arg out=0, freq = 360, gate = 1, pan, amp=0.8;
var sound, eg, fc, osc, a, b, w;
var harms, amps;

// use the harmonics previously calculated
harms=~harms;
//	create new amplitudes for each harmonic
amps=Array.fill(harms.size,{1.0.rand}).normalizeSum*0.1;

osc = Array.fill(harms.size, { |i|
SinOsc.ar(freq * harms[i], 0, amps[i] );
})++[SinOsc.ar(freq , 0, amp*(0.5.rand+0.2) ), SinOsc.ar(freq*2 , 0, amp*(0.5.rand+0.15) )];

eg = EnvGen.kr(Env.asr(0.02,1,1), gate, doneAction:2);

sound = Pan2.ar(eg * Mix.ar(osc), pan);
Out.ar(0, sound);
}).add;
)

(
e=Pbind(
\instrument, \cfstring1,
// frequencies are rpeated so we can notice the effect of harmonics
\degree, Pseq([0,1,2,3,4,5,6,7],inf),
\dur, 0.25,
\stepsPerOctave, 7,
\octave, 4,
\pan, Pfunc({0.5.rand2 })
).play;
)

Send the SynthDef function again to obtain new amplitudes for each harmonic
(
// send a synth definition with some partials and the current value of ~harms

SynthDef(\cfstring1, { arg out=0, freq = 360, gate = 1, pan, amp=0.8;
var sound, eg, fc, osc, a, b, w;
var harms, amps;

// use the harmonics previously calculated
harms=~harms;
//	create new amplitudes for each harmonic
amps=Array.fill(harms.size,{1.0.rand}).normalizeSum*0.1;

osc = Array.fill(harms.size, { |i|
SinOsc.ar(freq * harms[i], 0, amps[i] );
})++[SinOsc.ar(freq , 0, amp*(0.5.rand+0.2) ), SinOsc.ar(freq*2 , 0, amp*(0.5.rand+0.15) )];

eg = EnvGen.kr(Env.asr(0.02,1,1), gate, doneAction:2);

sound = Pan2.ar(eg * Mix.ar(osc), pan);
Out.ar(0, sound);
}).add;
)

// re-evalute the function to create new harmonics (update the SynthDef afterwards)
~harms=~harmsfunc.value(7);
//Send the SynthDef function again, as we have done earlier to obtain new amplitudes for each harmonic

// finally playing a random melody to make it less repetitive
(
e.stream=Pbind(
\instrument, \cfstring1,
// frequencies are repeated so we can notice the effect of harmonics
\degree,  Pwhite(0, 7),
\dur, 0.25,
\stepsPerOctave, 7,
\octave, 4,
\pan, Pfunc({0.5.rand2 })
).asStream;
)
// we could develop further and re-write the SynthDef with a partial argument 
// and also change the partials directly from Pbind

//////////////////////////////////////////////////////



﻿Figure 17.28 

(
var w, keys, steps, octaves;

w = Window.new.name="Custom keyboard: 7 steps per octave";
steps = 7;
octaves= 2;
// seven steps per octave;
a=Array.fill(7, { |i| (1/7)*(i) })+1;
b= a++(a*2);

c=Synth(\default, [\amp, 0]);

keys=Array.fill(steps*octaves,{ |i|

Button(w, Rect(20+(i*22),20,20,50))
.states_([
if(i.mod(steps)==0,{
[i.asString, Color.black, Color.red]},{
[i.asString, Color.black, Color.yellow]});

])
.action_({ arg butt;
c.set(\freq,b[i]*220, \amp, 0.25)
});
});

w.front;
)
//////////////////////////////////////////////////////




﻿Figure 18.1
/*
This example is adapted and extracted from the Non-Realtime Synthesis helpfile itself, accessible from the Main SuperCollider help page.
*/
(
var f, c, d;
// open a file for writing raw OSC data to
f = File("~/test.osc".standardizePath,"w");
// start a sine oscillator at 0.2 seconds.
c = [ 0.2, [\s_new, \default, 1001, 0, 0]];
// convert the bundle to raw OSC
d = c.asRawOSC;
f.write(d.size); // each bundle is preceded by a 32 bit size.
f.write(d); // write the bundle data.
f.close;
)




﻿Figure 18.2
s = Server.local;
s.boot;

// a sample SynthDef
SynthDef(\NRT_beep, {arg freq, dur, amp = 0.1;
	var half;
	half = dur * 0.5;
	Out.ar(0, SinOsc.ar(freq, 0, 
		EnvGen.kr(Env.new([0, amp, 0], [half, half], [4, -4]))));
	}).load(s);

(
var score;

// A Score, created from a note-list of time-stamped events.
score = Score.new([
    [0.0,
        [\g_new, 1000],
        [\s_new, \NRT_beep, 1001, 0, 1000, \freq, 75.midicps, \dur, 0.2]
    ], 
    [0.2,
        [\n_free, 1001],
        [\s_new, \NRT_beep, 1001, 0, 1000, \freq, 75.midicps, \dur, 0.2]
    ], 
    [0.4,
        [\n_free, 1001],
        [\s_new, \NRT_beep, 1001, 0, 1000, \freq, 75.midicps, \dur, 0.2]
    ], 
    [0.6,
        [\n_free, 1001],
        [\s_new, \NRT_beep, 1001, 0, 1000, \freq, 75.midicps, \dur, 0.2]
    ], 
    [0.8,
        [\n_free, 1001],
        [\s_new, \NRT_beep, 1001, 0, 1000, \freq, 71.midicps, \dur, 0.2]
    ], 
    [1.0,
        [\n_free, 1001],
        [\s_new, \NRT_beep, 1001, 0, 1000, \freq, 71.midicps, \dur, 0.2]
    ], 
    [1.2,
        [\n_free, 1001],
        [\s_new, \NRT_beep, 1001, 0, 1000, \freq, 82.midicps, \dur, 0.2]
    ], 
    [1.4,
        [\n_free, 1001],
        [\s_new, \NRT_beep, 1001, 0, 1000, \freq, 82.midicps, \dur, 0.2]
    ], 
    [1.6,
        [\n_free, 1001],
        [\s_new, \NRT_beep, 1001, 0, 1000, \freq, 82.midicps, \dur, 0.2]
    ], 
    [1.8,
        [\n_free, 1001],
        [\s_new, \NRT_beep, 1001, 0, 1000, \freq, 82.midicps, \dur, 0.2]
    ], 
    [2.0,
        [\n_free, 1001, 1000]
    ],
	[2.00001, [0]]
]);

score.play(s); // play the Score in real-time...

// ... or render in Non-Real-Time
score.recordNRT("/tmp/trashme", "~/test.aiff".standardizePath, 
	options: ServerOptions.new.numOutputBusChannels_(1));
)


﻿Figure 18.3
(
//In this example, we use the higher-level server abstraction classes, Group and Synth to handle the
// node IDs. At least as important though is the use of variables. Now that the relationships are
// specified rather than the specific values, we can change the gesture dramatically by changing
// just one or two variables. To transpose everything, we only need to change the value of 
// ~baseNote. To adjust the duration, we only need to change the ~dur variable, and this is now 
// independent of the deltaOn (i.e. independent of the amount of time between the start of one
// note and the start of the next note).
var score;
var deltaOn = 0.2;  //amount of time between the start of one note and the start of the next note
var dur = 0.4;      //try changing dur to 0.3, 1.4, 3.4, or whatever you like
var baseNote = 75;  //transpose the entire fragment up or down
var firstPitch  = (baseNote + 0).midicps;  //alter the relationship between any of the pitches
var secondPitch = (baseNote - 4).midicps;  // without effecting the others
var thirdPitch  = (baseNote + 7).midicps;

score = Score.new([
	[t =  0.0,
		(g = Group.basicNew(s)).newMsg,
		//we use environment variables here (identified by the preceding ~) 
		// since we might add or remove events; hence we don't know ahead of 
		// time how many events we have, and therefore how many variables we'll need
		(~s01 = Synth.basicNew(\NRT_beep, s))
			.newMsg(g, [\freq, firstPitch, \dur, dur], \addToHead)
	], 
	[t + dur,
		~s01.freeMsg
	],
	[t = t + deltaOn,
		(~s02 = Synth.basicNew(\NRT_beep, s))
			.newMsg(g, [\freq, firstPitch, \dur, dur], \addToHead)
	], 
	[t + dur,
		~s02.freeMsg
	],
	[t = t + deltaOn,
		(~s03 = Synth.basicNew(\NRT_beep, s))
			.newMsg(g, [\freq, firstPitch, \dur, dur], \addToHead)
	],
	[t + dur,
		~s03.freeMsg
	],
	[t = t + deltaOn,
		(~s04 = Synth.basicNew(\NRT_beep, s))
			.newMsg(g, [\freq, firstPitch, \dur, dur], \addToHead)
	], 
	[t + dur,
		~s04.freeMsg
	],
	[t = t + deltaOn,
		(~s05 = Synth.basicNew(\NRT_beep, s))
			.newMsg(g, [\freq, secondPitch, \dur, dur], \addToHead)
	], 
	[t + dur,
		~s05.freeMsg
	],
	[t = t + deltaOn,
		(~s06 = Synth.basicNew(\NRT_beep, s))
			.newMsg(g, [\freq, secondPitch, \dur, dur], \addToHead)
	], 
	[t + dur,
		~s06.freeMsg
	],
	[t = t + deltaOn,
		(~s07 = Synth.basicNew(\NRT_beep, s))
			.newMsg(g, [\freq, thirdPitch, \dur, dur], \addToHead)
	], 
	[t + dur,
		~s07.freeMsg
	],
	[t = t + deltaOn,
		(~s08 = Synth.basicNew(\NRT_beep, s))
			.newMsg(g, [\freq, thirdPitch, \dur, dur], \addToHead)
	], 
	[t + dur,
		~s08.freeMsg
	],
	[t = t + deltaOn,
		(~s09 = Synth.basicNew(\NRT_beep, s))
			.newMsg(g, [\freq, thirdPitch, \dur, dur], \addToHead)
	], 
	[t + dur,
		~s09.freeMsg
	],
	[t = t + deltaOn,
		(~s10 = Synth.basicNew(\NRT_beep, s))
			.newMsg(g, [\freq, thirdPitch, \dur, dur], \addToHead)
	], 
	[t + dur,
		~s10.freeMsg,
		g.freeMsg
	],
]
);

score.sort;
score.play(s);
)




﻿
Figure 18.4
(
var score, graingest;

// seed the randomness
thisThread.randSeed_(123);

// a sample SynthDef
SynthDef(\NRT_grain, {arg freq, dur, amp, pan;
	OffsetOut.ar(0, Pan2.ar(
		SinOsc.ar(freq, 0, 
			EnvGen.ar(Env.sine(dur, amp), doneAction: 2)),
		pan)
		);
	}).load(s);

score = Score.new;

// envelope times are scaled to 1.
graingest = {arg score, starttime, duration, windur, overlaps, freqenv, ampenv, panenv;
	var ratio, curfreq, curamp, curpan, notestart, now = 0.0, note;
	while({
		ratio = now / duration;
		curfreq = freqenv[ratio];
		curamp = ampenv[ratio];
		curpan = panenv[ratio];
		notestart = now + starttime;
		note = Synth.basicNew(\NRT_grain);
		score.add([notestart, 
			note.newMsg(1, [\freq, curfreq,\amp, curamp, \dur, windur, \pan, curpan], \addToHead)]
			);
		// check the current event's endtime against the global endtime
		now = now + (windur / overlaps);
		now < duration;
		});
	};

// call the above function to populate the Score

graingest.value(score, 1.0, 10.0, 100.reciprocal, 1, Env([440, 550], [1]), 
	Env([0, 0.2, 0], [0.3, 0.7], [4, -4]), Env([0, 0], [1]));
graingest.value(score, 3.0, 3.0, 130.reciprocal, 2, Env([700, 400], [1]),
	Env([0, 0.2, 0], [0.1, 0.9], [4, -1]), Env([-0.7, 0.7], [1]));

// create a number of short gestures
10.do({arg i;
	graingest.value(score, 5.0.rrand(10.0), 3.0.rrand(5.0), (100 * i).reciprocal, [1, 2, 4].choose,
		Env([1000, 800], [1]), Env([0, 0.2, 0], [0.5, 0.5]), Env([0.5.rand2, 0.5.rand2], [1]));
	});

// save the endtime to the Score to tell NRT when to stop rendering. The above gestures won't
// be more the 16 seconds

score.add([16, [0]]);

// sort the score to ensure events are in the correct order

score.sort;

// render the Score to the users home folder

score.recordNRT("/tmp/trashme", "~/test.aiff".standardizePath, 
	options: ServerOptions.new.numOutputBusChannels_(1));
	
// also save the Score to a file
score.saveToFile("~/test.sc".standardizePath);
)	




﻿
Figure 18.5
(
var score, sndbuf, starttime, synth, options;

SynthDef(\NRT_playback, {arg buffer, dur, startPos, amp;
	OffsetOut.ar(0, PlayBuf.ar(1, buffer, BufRateScale.kr(buffer), 
			startPos: startPos * BufSampleRate.kr(buffer)) *
		EnvGen.ar(
			Env.sine(dur, amp),
			doneAction: 2))
	}).load(s);

score = Score.new;

// create a Buffer object for adding to the Score
sndbuf = Buffer.new;

// for NRT rendering, the buffer messages must be added to the Score
score.add([0, sndbuf.allocReadMsg("sounds/a11wlk01-44_1.aiff")]);

starttime = 0.0;

// a small function to create a series of small notes based on the Buffer
while({
	synth = Synth.basicNew(\NRT_playback);
	score.add([starttime, 
		synth.newMsg(s, [\buffer, sndbuf, \dur, 0.1, \startPos, 0.0.rrand(1.0), \amp, 0.1])]);
	starttime = starttime + 0.05;
	starttime < 10.0;
	});

// the dummy command. The soundfile will be 11 seconds long
score.add([11, 0]);

score.sort;

// the ServerOptions for rendering the soundfile
options = ServerOptions.new.numOutputBusChannels_(1);

// write the soundfile out to disk
score.recordNRT("/tmp/trashme", "~/test.aiff".standardizePath, options: options);
)




﻿Figure 18.6
(
var score, sndbuf, starttime, synth, options, cond;

SynthDef(\NRT_playback, {arg buffer, dur, startPos, amp;
	OffsetOut.ar(0, PlayBuf.ar(1, buffer, BufRateScale.kr(buffer), 
			startPos: startPos * BufSampleRate.kr(buffer)) *
		EnvGen.ar(
			Env.sine(dur, amp),
			doneAction: 2))
	}).load(s);

score = Score.new;

// set up a Condition to check for when asynchronous events are finished.

cond = Condition.new;

// wrap the code that will run in real-time in a Routine, to allow for the Server to sync
Routine.run({
	// load the buffer
	sndbuf = Buffer.read(s, "sounds/a11wlk01-44_1.aiff");
	
	// pause while the buffer is loaded
	s.sync(cond);
	
	// fill the Score with notes
	
	starttime = 0.0;
	
	while({
		synth = Synth.basicNew(\NRT_playback);
		score.add([starttime, 
			synth.newMsg(s, [\buffer, sndbuf, \dur, 0.1, \startPos, 0.0.rrand(1.0), \amp, 0.1])]);
		starttime = starttime + 0.05;
		starttime < 10.0;
		});
	
	// the last command is NOT needed, since no soundfile is being rendered
//	score.add([11, 0]);
	
	score.sort;
	
	// again, options won't be needed for real time performance
//	options = ServerOptions.new.numOutputBusChannels_(1);
	
	score.play;
	// schedule the freeing of the buffer after the Score is done playing
	SystemClock.sched(11, {sndbuf.free; "Buffer resources freed".postln;});
	})
)





﻿Figure 18.7


// environment variables are used for real-time examples of Ctk objects

n = CtkNoteObject(
	SynthDef(\NRT_grain, {arg gate = 1, freq, amp;
		var src, env;
		src = SinOsc.ar(freq, 0, amp);
		env = EnvGen.kr(Env([0, 1, 0], [1, 1], \sin, 1), gate, doneAction:2);
		OffsetOut.ar(0, src * env);
		})
	);
	
// create a new note based on 'n', start to play it in 0.1 seconds
a = n.new(0.1).freq_(440).amp_(0.1).gate_(1).play;
// the release method will set 'gate' to 0.0, and free this node
a.release;

// create another note
a = n.new(0.1).freq_(440).amp_(0.1).play;
// alter the freq argument in real time
a.freq_(550);
// alter the freq with a CtkControl that describes an Env
// CtkControl.env(Env)
a.freq_(CtkControl.env(Env([550, 440, 550], [1, 2], \exp)));
// apply a random control to the amp parameter, with an envelope applied to the range. All 
// parameters to the CtkControl can themselves be CtkControls
// CtkControl.lfo(KRUGen, freq, low, high, phase)
a.amp_(CtkControl.lfo(LFNoise2, 0.5, CtkControl.env(Env([0.1, 0.9], [5])), 0.1));
a.amp_(0.1);

// release the note
a.release;




﻿Figure 18.8
// melodic expander
(
var note, keys, durs, now, score, chunk, expander, rangemap;

// 
thisThread.randSeed_(123);

// a simple note player

note = CtkSynthDef(\NRT_dut, {arg key, amp, dur;
		Out.ar(0, SinOsc.ar(key.midicps, 0, XLine.kr(amp, 0.00001, dur)))
		});

// first, make a melody - these will be used as midikeynums (easier to alter later)

keys = [ 72, 72, 79, 79, 81, 81, 79, 77, 77, 76, 76, 74, 74, 72 ];

// a list of durations

durs = [0.25, 0.25, 0.25, 0.25, 0.25, 0.25, 0.5, 0.25, 0.25, 0.25, 0.25, 0.25, 0.25, 0.5];

// create a var to store 'now' in

now = 0.0;

// create a CtkScore with the above melody

score = CtkScore.new;

keys.do({arg thiskey, inc;
	var thisdur;
	thisdur = durs[inc];
	score.add(note.new(now, thisdur).key_(thiskey).amp_(0.2).dur_(thisdur));
	now = now + thisdur;
	});

// first, create a function that will return a chunk of the melody the duration of the chunk
// sets the starttimes of the notes to a base of 0.0

chunk = {arg offset = 0;
	var size, start, end, duration = 0, chunk, copies;
	// the size of the current melody - 1 (for array access)
	size = score.notes.size;
	// the beginning of the chunk can come from the beginning of the melody to the second to 
	// last note
	start = 0.rrand(size-1);
	end = start.rrand(size);
	chunk = score.notes[start..end].collect({arg anote; 
		var newnote;
		newnote = anote.copy(duration + offset);
		duration = duration + anote.duration;
		newnote;
		});
	[chunk, duration];
	};

// now, create a function that will add those chunks to the score, and will keep doing this
// until the score is at least the desired length. Then check the score size, and truncate to 
// desired size.

expander = {arg len;
	var curchunk, chunkdur, insert, inserttime, insertdur, cursize, newnotes;	cursize = score.notes.size;
	while({
		cursize < len
		}, {		
		insert = 0.rrand(cursize - 1);
		inserttime = score.notes[insert].starttime;
		insertdur = score.notes[insert].duration;
		#curchunk, chunkdur = chunk.value(inserttime + insertdur);
		score.notes[(insert+1)..(cursize-1)].do({arg me; 
			me.setStarttime(me.starttime + chunkdur)});
		score = score.add(curchunk);
		(score.notes.size > len).if({
			score.notes.do({arg me, i;
				(i > (len - 1)).if({score.notes.remove(me)});
				})
			});
		cursize = score.notes.size;
		});
	};

// rangemap will place the melodic material within a certain range. The user passes 
// in an envelope that will describe the center pitch in an octave range

rangemap = {arg center;
	score.notes.do({arg me;
		me.key_(me.key.mapIntoRange(12, center[me.starttime]));
		})
	};
		
// expand it to 100 notes
expander.value(100);

// describe a new range of pitches
rangemap.value(Env([60, 96], [20]));

// finally, play the CtkScore

score.play;
)



﻿Figure 18.9

(
var score, grain, now, thisdur;
var ampmap, double;

grain = CtkNoteObject(
	SynthDef(\NRT_grain, {arg freq, amp, dur, pan = 0;
		var src, env;
		env = EnvGen.ar(
			Env([0, 1, 0], [0.5, 0.5], \sin),
			timeScale: dur, doneAction: 2, levelScale: amp);
		src = SinOsc.ar(freq, 0, env);
		OffsetOut.ar(0, Pan2.ar(src, pan));
		})
	);
	
score = CtkScore.new;

now = 0;

// create a 3 second granular gesture

while({
	thisdur = 0.05.rrand(0.1);
	score.add(
		grain.new(now, thisdur).freq_(440.rrand(880)).amp_(0.05).dur_(thisdur).pan_(0));
	now = now + 0.01;
	now < 3;
	});

// a function to later map the amplitude to a given shape
// envtimes should be scaled to 1
ampmap = {arg aScore, env;
	// scaled the envs times by the CtkScore's duration
	env.times = env.times * aScore.endtime;
	aScore.notes.do({arg thisNote;
		var curtime;
		curtime = thisNote.starttime;
		thisNote.amp_(env[curtime]);
		});
	};

// returns a new copy of the CtkScore with notes
// double an octave higher
double = {arg aScore, shift = 2;
	var thisScore;
	thisScore = aScore.copy;
	thisScore.notes.do({arg thisNote;
		thisNote.freq_(thisNote.freq * shift)
		});
	thisScore;
	};
		
// a Routine to play the examples
Routine.run({
	var scoreDouble;
	// play the CtkScore;
	score.play;
	score.endtime.wait;
	// remap the amplitudes
	ampmap.value(score, Env([0, 0.2, 0], [0.1, 0.9], [4, -2]));
	1.wait; // pause for a moment
	// play it again!
	score.play;
	score.endtime.wait;
	// add the CtkScore that octaveDouble returns
	scoreDouble = double.value(score, 19.midiratio);
	ampmap.value(scoreDouble, Env([0, 0.25, 0], [0.6, 0.4], [4, -2]));
	score.add(scoreDouble);
	1.wait;
	score.play;
	score.endtime.wait;
	// don't like the second version? remove double
	score.ctkscores.remove(scoreDouble);
	ampmap.value(score, Env([0.15, 0.05], [1]));
	1.wait;
	score.play;
	}).randSeed_(123)
)




﻿Figure 18.10
s = Server.local;
s.boot;

~sinosc = CtkSynthDef.new(\NRT_sinosc, 
	{arg outbus = 0, freq = 622.254, phase = 0, amp = 1, offSet = 0;
		Out.ar(outbus, SinOsc.ar(freq, phase, amp, offSet));
	}
);

(
var score;
var baseNote = 75;
var slopeTime = 0.25;
var curve = \sine;
var firstPitch = (baseNote + 0).midicps;
var firstStart = 0.0;
var firstDur = 5.0;
var firstAttackTime = slopeTime * 0.5;
var firstDecayTime  = slopeTime - firstAttackTime;
var firstVibDepth = 0.21;
var firstVibRate = 2.3;
var firstPeakAmp = 0.25;
var firstDecayAmp = 0.01;
var secondPitch = (baseNote - 4).midicps;
var secondStart = 2.2;
var secondDur = 4.0;
var secondAttackTime = slopeTime * 0.5;
var secondDecayTime  = slopeTime - secondAttackTime;
var secondVibDepth = 0.15;
var secondVibRate = 1.7;
var secondPeakAmp = 0.25;
var secondDecayAmp = 0.01;
var thirdPitch = (baseNote + 7).midicps;
var thirdStart = 3.1;
var thirdDur = 3.75;
var thirdAttackTime = slopeTime * 0.5;
var thirdDecayTime  = slopeTime - thirdAttackTime;
var thirdVibDepth = 0.21;
var thirdVibRate = 4;
var thirdPeakAmp = 0.2;
var thirdDecayAmp = 0.25;

score = CtkScore.new(
	~firstGroup = CtkGroup.new(firstStart, firstDur, server: s),
	~sinosc.new(firstStart, firstDur, \tail, ~firstGroup, server: s)
		.freq_(CtkControl.lfo(SinOsc, firstVibRate, 
			(firstPitch - ((firstPitch / (firstPitch.log2)) * (firstVibDepth * (1/3)))), 
			(firstPitch + ((firstPitch / (firstPitch.log2)) * (firstVibDepth * (2/3)))), 
			duration: firstDur, addAction: \head, target: ~firstGroup, server: s))
		.amp_(CtkControl.env(
			Env.new([0, firstPeakAmp, firstDecayAmp, 0], [firstAttackTime, 
				firstDur - (firstAttackTime + firstDecayTime), firstDecayTime], curve), 
			addAction: \head, target: ~firstGroup, server: s)),
	~secondGroup = CtkGroup.new(secondStart, secondDur, server: s),
	~sinosc.new(secondStart, secondDur, \tail, ~secondGroup, server: s)
		.freq_(CtkControl.lfo(SinOsc, secondVibRate, 
			(secondPitch - ((secondPitch / (secondPitch.log2)) * (secondVibDepth * (1/3)))), 
			(secondPitch + ((secondPitch / (secondPitch.log2)) * (secondVibDepth * (2/3)))), 
			duration: secondDur, addAction: \head, target: ~secondGroup, server: s))
		.amp_(CtkControl.env(
			Env.new([0, secondPeakAmp, secondDecayAmp, 0], [secondAttackTime, 
				secondDur - (secondAttackTime + secondDecayTime), secondDecayTime], curve), 
			addAction: \head, target: ~secondGroup, server: s)),
	~thirdGroup = CtkGroup.new(thirdStart, thirdDur, server: s),
	~sinosc.new(thirdStart, thirdDur, \tail, ~thirdGroup, server: s)
		.freq_(CtkControl.lfo(SinOsc, thirdVibRate, 
			(thirdPitch - ((thirdPitch / (thirdPitch.log2)) * (thirdVibDepth * (1/3)))), 
			(thirdPitch + ((thirdPitch / (thirdPitch.log2)) * (thirdVibDepth * (2/3)))), 
			duration: thirdDur, addAction: \head, target: ~thirdGroup, server: s))
		.amp_(CtkControl.env(
			Env.new([0, thirdPeakAmp, thirdDecayAmp, 0], [thirdAttackTime, 
				thirdDur - (thirdAttackTime + thirdDecayTime), thirdDecayTime], curve), 
			addAction: \head, target: ~thirdGroup, server: s))
);

score.play;
)



﻿Figure 18.11
VSO_Vib {

	var <pitch, <depth, <rate, <control;

	*new {arg start = 0.0, dur = nil, freq = 1, vibDepth = 0.21, vibRate = 1, 
		addAction = 0, target = 1, server;
		^super.new.initVSO_Vib(start, dur, freq, vibDepth, vibRate, addAction, 
			target, server);
	}
	
	initVSO_Vib {arg start, dur, freq, vibDepth, vibRate, add = 0, tgt = 1, server;
		server = server ?? {Server.default};
		pitch = freq;
		depth = vibDepth;
		rate = vibRate;
		control = CtkControl.lfo(SinOsc, rate, this.getLowerValue,
			this.getUpperValue, 0, start, dur, add, tgt, server: server);
	
	}
	
	getLowerValue {
		^(pitch - ((pitch / (pitch.log2)) * (depth * (1/3))));
	}

	getUpperValue {
		^(pitch + ((pitch / (pitch.log2)) * (depth * (2/3))));
	}
}




﻿Figure 18.12
VSO_ADR {

	var <control, <attackDur, <releaseDur, <totalDur;

	*new {arg start = 0.0, dur =  nil, peak = 0.707, decay = 0.01, attackDur = 0.125, 
		releaseDur = 0.125, addAction = 0, target = 1, server;
		^super.new.initVSO_ADR(start, dur, peak, decay, attackDur, releaseDur, addAction,
			target, server);
	}
	
	initVSO_ADR {arg start = 0.0, dur =  nil, peak = 0.707, decay = 0.01, aDur = 0.125, 
		rDur = 0.125, addAction = 0, target = 1, server;
		server = server ?? {Server.default};
		attackDur = aDur;
		releaseDur = rDur;
		totalDur = dur;
		control = CtkControl.env(Env.new([0, peak, decay, 0], 
			[attackDur, this.decayDur, releaseDur], \sine), 
			start, addAction, target, server: server, doneAction: 0);
	}
	
	decayDur {
		^(totalDur - (attackDur + releaseDur));
	}

}




﻿Figure 18.13
	initVSO {arg start = 0.0, dur = nil, freq = 622.254, ampPeakLevel = 0.707, 
		ampDecayLevel = 0.01, vibDepth = 0.21, vibRate = 3, addAction = 0, target = 1, 
			server;
		server = server ?? {Server.default};
		group = CtkGroup.new(start, dur, addAction: addAction, target: target, 
			server: server);
		freqCntl = VSO_Vib.new(start, dur, freq, vibDepth, vibRate, \head, group, server);
		ampCntl = VSO_ADR.new(start, dur, ampPeakLevel, ampDecayLevel, addAction: \head, 
			target: group, server: server);
		oscil = sinoscdef.new(start, dur, \tail, group, server)
			.freq_(freqCntl.control).amp_(ampCntl.control);
		score = CtkScore.new(group, oscil);
	}







﻿Figure 18.14
VSO {

	classvar <sinoscdef;
	var <score, group, oscil, freqCntl, <ampCntl;
	
	*new {arg start = 0.0, dur = nil, freq = 622.254, ampPeakLevel = 0.707, ampDecayLevel = 0.01, 
		vibDepth = 0.21, vibRate = 3, addAction = 0, target = 1, server;
		^super.new.initVSO(start, dur, freq, ampPeakLevel, ampDecayLevel, 
			vibDepth, vibRate, addAction, target, server);
	}

	*initClass {
		sinoscdef.isNil.if({
			sinoscdef = CtkSynthDef.new(\NRT_sinosc, 
				{arg outbus = 0, freq = 622.254, phase = 0, amp = 1, offSet = 0;
					Out.ar(outbus, SinOsc.ar(freq, phase, amp, offSet));
				})
			});
	}

	initVSO {arg start = 0.0, dur = nil, freq = 622.254, ampPeakLevel = 0.707, 
		ampDecayLevel = 0.01, vibDepth = 0.21, vibRate = 3, addAction = 0, target = 1, 
			server;
		server = server ?? {Server.default};
		group = CtkGroup.new(start, dur, addAction: addAction, target: target, 
			server: server);
		freqCntl = VSO_Vib.new(start, dur, freq, vibDepth, vibRate, \head, group, server);
		ampCntl = VSO_ADR.new(start, dur, ampPeakLevel, ampDecayLevel, addAction: \head, 
			target: group, server: server);
		oscil = sinoscdef.new(start, dur, \tail, group, server)
			.freq_(freqCntl.control).amp_(ampCntl.control);
		score = CtkScore.new(group, oscil);
	}

}




﻿Figure 18.15
s = Server.local;
s.boot;

(
var score;
var baseNote = 75;
var firstPitch = (baseNote + 0).midicps;
var secondPitch = (baseNote - 4).midicps;
var thirdPitch = (baseNote + 7).midicps;

score = CtkScore.new(
	(a = VSO.new(0.0, 5.0, firstPitch, 0.25, 0.01, 0.21, 2.3, server: s)).score,
	(b = VSO.new(2.2, 4.0, secondPitch, 0.25, 0.01, 0.15, 1.7, server: s)).score,
	(c = VSO.new(3.1, 3.75, thirdPitch, 0.15, 0.3, 0.21, 4, server: s)).score
);
score.play;
)






﻿
Figure 18.16
s = Server.local;
s.boot;

(
var score;
var baseNote = 75;
var firstPitch = (baseNote + 0).midicps;
var secondPitch = (baseNote - 4).midicps;
var thirdPitch = (baseNote + 7).midicps;

d = [2.4, 1.7];
a = NRT_TimeFrame.new(0.0, 11);
b = NRT_TimeFrame.new(a.starttime + d.at(0), a.endtime - (a.starttime + d.at(0)));
c = NRT_TimeFrame.new(b.starttime + d.at(1), b.endtime - (b.starttime + d.at(1)));

score = CtkScore.new(
	(a = VSO.new(a.starttime, a.duration, firstPitch, 0.25, 0.01, 0.21, 2.3, server: s)).score,
	(b = VSO.new(b.starttime, b.duration, secondPitch, 0.25, 0.01, 0.15, 1.7, server: s)).score,
	(c = VSO.new(c.starttime, c.duration, thirdPitch, 0.15, 0.3, 0.21, 4, server: s)).score
);
score.play;
//N.B. You may notice three "Node not found" warnings.
// This is expected behavior for this version of Ctk
)




﻿Figure 18.17
NRT_TimeFrame {

	var >starttime, >duration;
	
	*new {arg starttime, duration;
		^super.newCopyArgs(starttime, duration);
	}

	starttime {
		^ starttime.value;
	}

	duration {
		^ duration.value;
	}

	endtime {
		^(this.starttime != nil).if({
				(this.duration != nil).if({
					//call the getter methods rather than accessing
					// the variables directly
					this.starttime + this.duration;
				}, {nil})
		}, {nil});

	}

}



﻿Figure 20.1
// create the mixer: one channel in, two channels out
m = MixerChannel(\fig1, s, 1, 2);

// bring up a mixing board -- you can play with the level and panning controls
// closing the window, or freeing all of its channels, removes the MixingBoard
b = MixingBoard(\Fig1, nil, m);

// a SynthDef should include an outbus argument
// so that the MixerChannel can tell it where to write its output
(
SynthDef(\fig1, { |outbus, lowfreq = 220, hifreq = 1200, decay = 0.05|
	var	trig = Impulse.kr(8);
		// Do not hard-code the outbus here!
		// Out.ar(0, ...) is not OK. Out.ar(outbus, ...) is good.
	Out.ar(outbus, SinOsc.ar(TExpRand.kr(lowfreq, hifreq, trig)) * Decay2.kr(trig, 0.01, decay));
}).add;
)

a = m.play(\fig1, [lowfreq: 100, hifreq: 2000, decay: 0.1]);

// automate panning - this is done with a control-rate synth
m.automate(\pan, { SinOsc.kr(LFNoise1.kr(0.5).exprange(0.4, 5.0)) });

// the GUI can show the automation
m.watch(\pan);

// add reverb using post-fader send
// auto-play the reverb synth in the completion function
(
r = MixerChannel(\rvb, s, 2, 2, level:1, completionFunc: { |chan|
	"creating reverb synth".postln;
	chan.playfx({ |outbus|
		var	sig = In.ar(outbus, 2);  // read from channel's bus
		FreeVerb2.ar(sig[0], sig[1], 1, 0.6, 0.5)
	});
});

b.add(r);  // add to MixingBoard
)

// feed the signal into the reverb
m.newPostSend(r, 0.6);

// prints out current state of all mixers in the board
// the board is accessible also through the MixingBoard.boards array
b.postSettings;

// fade to black
m.levelTo(0, 15);

// and release
// note that on m.free, the synth 'a' is removed also
// freeing the last MixerChannel in the MixingBoard closes the window
m.free;
r.free;




﻿Figure 20.3
// Voicer(voices, things, args, bus, target, addAction)
// target may be a Group, Server, or MixerChannel
v = Voicer(10, \default);

v.trigger(440, 1);  // v.trigger(freq, gate, args, latency)
v.release(440);

// v.gate(freq, dur, gate, args, lat) -- lat = latency
v.gate(440, 2.0, 1, [pan: -0.5]);

r = fork {
	loop {
			// play over a C major scale
		[60, 62, 64, 65, 67, 69, 71, 72].do({ |midi|
			v.gate(midi.midicps, 0.1, 1, [amp: rrand(0.05, 0.15)],
				lat: 0.1);
			0.125.wait;
		});
	}
};

r.stop;

v.free;



﻿Figure 20.4
// let's put a pan global control on the voicer

v = Voicer(10, \default);

// v.mapGlobal(name, bus, value, spec)
// \bipolar is a ControlSpec for the range -1..+1
v.mapGlobal(\pan, nil, 0, \bipolar);

v.gui;

// Pbind works with voicer, using 'voicerNote' event type
p = Pbind(
	\type, \voicerNote,
	\voicer, v,
	\degree, Pn(Pseries(0, 1, 8), inf),
	\amp, Pwhite(0.05, 0.15, inf),
	\dur, 0.125,
	\legato, 0.8
).play;

p.stop;

v.free;




﻿Figure 20.5
v = Voicer(10, \default);

// 0 = device 0, channel 0
// for a different device, use [device index, channel]
k = VoicerMIDISocket(0, v);

// modwheel to control pan
k.addControl(1, \pan, 0, \bipolar);
v.gui;

// a homegrown variety of just intonation
// release all notes before executing this!
k.midiToFreq = TuningRatios(12, tunings: [1, 135/128, 9/8, 6/5, 5/4, 4/3, 45/32, 3/2, 14/9, 27/16, 16/9, 15/8]);

// per-note argument generation using a Pbind
// here used to map velocity data onto the amp input
k.noteOnArgsPat = Pbind(\amp, Pkey(\velocity).linlin(0, 127, 0.01, 0.2));

// if you have a footswitch (controller number 64), this handles it properly
l = VoicerSusPedal(0, 64, v);

// by default, freeing the voicer automatically frees the socket and all attached MIDI controllers
v.free;




﻿Figure 20.6
// "Hello World" greeter classes

(
~greeter = Proto({
	~sayhi = { |name|
		"%, %.\n".postf(~greeting.value, name ? ~name);
	};
	~name = "Monique";		// default name
	~greeting = "Hello";		// default greeting
});

// make a subclass with .clone
~frenchGreeter = ~greeter.clone({
	~greeting = "Bonjour";
});

~timeAwareFrenchGreeter = ~frenchGreeter.clone({
	~greeting = {
		var	hour = Date.getDate.hour;
		if(hour < 18) { ~dayGreeting } { ~eveningGreeting };
	};
	~dayGreeting = "Bonjour";
	~eveningGreeting = "Bon soir";
});
)

// Use the objects:
~greeter.sayhi;
~greeter.sayhi("Bob");
~frenchGreeter.sayhi("Isabelle");
~timeAwareFrenchGreeter.sayhi("Eric");




﻿Figure 20.7
(
	// define PR prototype - Proto(...) => PR(\name)
Proto({
	~sayhi = { |name|
			// ~greeting.value is an internal pseudomethod call
		"%, %.\n".postf(~greeting.value, name ? ~name);
	};
	~name = "Monique";		// default name
	~greeting = "Hello";		// default greeting
}) => PR(\greeter);
)

// make working instance as BP
PR(\greeter) => BP(\greeter);
BP(\greeter).sayhi("Jacqueline");
BP(\greeter).name = "Zsa Zsa";
BP(\greeter).sayhi;
	// changing name in BP does not affect PR
PR(\greeter).name;

// override default at chuck time
// now this greeter belongs just to Bob
PR(\greeter).chuck(BP(\greetBob), parms: (name: "Bob"));
BP(\greetBob).name;	// ~name variable is overridden
BP(\greetBob).sayhi;

// remove both instances from the repository
BP([\greeter, \greetBob]).free;




﻿Figure 20.9
(
SynthDef(\bufGrainPan, { |start, time, bufnum, pan, rate = 1, amp = 1,
		attack = 0.001, decay = 0.02, outbus|
	var sig;
	sig = PlayBuf.ar(1, bufnum, rate * BufRateScale.kr(bufnum), 1, start, 0)
		* EnvGen.kr(Env.linen(attack, time, decay), doneAction:2);
	Out.ar(outbus, Pan2.ar(sig, pan, amp));
}).add;

PR(\abstractProcess).clone({
		// BEHAVIORAL components
		// eventKey refers to ProtoEvent(\singleSynthPlayer)
	~event = (eventKey: \singleSynthPlayer);
		// here, manufacture the pattern to play
	~asPattern = {
		Pbind(
			\chan, ~chan,
			\instrument, \bufGrainPan,
			\bufnum, ~buf.bufnum,
			\delta, BPStream(\delta),	// reference to ~delta stream
			\time, BPStream(\tfactor) * Pkey(\delta),
			\start, BPStream(\startSec) * ~buf.sampleRate,
			\pan, BPStream(\pan),
			\amp, BPStream(\amp)
		)
	};
		// default Pbind streams
	~delta = Pwhite(1, 5, inf) * 0.1;
	~tfactor = 1;
	~maxStart = Pfunc({ ~buf.duration }) - Pkey(\time);
	~startSec = Pwhite(0.0, BPStream(\maxStart), inf);
	~pan = Pwhite(-1.0, 1.0, inf);
	~amp = 1;

		// ARCHITECTURAL components
	~path = "sounds/a11wlk01.wav";	// default soundfile
	~startFrame = 0;
	~numFrames = -1;
		// constructor: auto-load soundfile and create mixer
	~prep = {
		~chan = MixerChannel(~collIndex, s, 2, 2);
		"loading %\n".postf(~path);
		~buf = Buffer.read(s, ~path, ~startFrame, ~numFrames,
			action: { "done loading buffer".postln });
	};
		// destructor, called on .free
	~freeCleanup = {
		[~chan, ~buf].free;
	};
}) => PR(\bufSlicer);
)

// That was the definition. In performance you only need this to play it.

PR(\bufSlicer) => BP(\columbia);
BP(\columbia).play;

// change process’s stream references while it is playing

BP(\columbia).tfactor = 0.25;

BP(\columbia).tfactor = sin(Pseries(0, 0.1, inf)) * 0.45 + 0.55;

BP(\columbia).delta = Pstutter(Pwhite(4, 12, inf), Pxrand((1..6) * 0.05, inf));

BP(\columbia).startSec = Pclutch(Pwhite(0.0, BPStream(\maxStart), inf), Pdiff(Pkey(\delta)).abs > 0);


// also valid to chuck patterns into a BP
// ".pan" is an adverb indicating which variable to replace
sin(Ptime(inf)) =>.pan BP(\columbia);

BP(\columbia).stop;
BP(\columbia).free;	// MixerChannel and Buffer go away also




﻿Figure 20.10
// In the definition file:
(
(make: { |name|
	PR(\bufSlicer) => BP(name);
}, type: \bp) => Fact(\basic);

(make: { |name|
	PR(\bufSlicer).chuck(BP(name), parms: (
		path: "sounds/a11wlk01-44_1.aiff",
		tfactor: sin(Pseries(0, 0.1, inf)) * 0.45 + 0.55,
		delta: Pstutter(Pwhite(4, 12, inf), Pxrand((1..6) * 0.05, inf)),
		startSec: Pclutch(Pwhite(0.0, Pfunc({ ~buf.duration }) - Pkey(\time)), Pdiff(Pkey(\delta)).abs > 0),
		pan: sin(Ptime(inf)),
		quant: 1	// quantize to next beat
	))
}, type: \bp) => Fact(\fancy);
)

// In the performance script:
Fact(\basic) => BP(\basic);

BP(\basic).play;

Fact(\fancy) => BP(\fancy);

BP(\fancy).play;

BP([\basic, \fancy]).stop;

BP([\basic, \fancy]).free;




﻿
// Figure 2. A Synth Definition with the first 16 harmonics
(
SynthDef(\simpleSynth, {|freq, amp|
	var signal, harmonics;
	harmonics = 16;
	signal = Mix.fill(harmonics, {|i| 
				SinOsc.ar(freq*(i+1), 1.0.rand, amp * harmonics.reciprocal/(i+1)) 
			});
	Out.ar(0, signal ! 2);
}, [0.15, 0.15]).add// lag times so the slider "sounds" better
)

// A line of code testing the synth definition that we created
Synth(\simpleSynth, [\freq, 440, \amp, 1])



﻿
// Figure 3. A GUI to control the frequency and amplitude of our synth
(
var synth, win;
// we initialize the synth
synth = Synth(\simpleSynth, [\freq, 100, \amp, 0]);
// specify the GUI window
win = Window("simpleSynth", Rect(100,100, 230, 90), false);
// and place the frequency and amplitude sliders in the window
StaticText(win, Rect(10,10, 160, 20)).font_(Font("Helvetica", 9)).string_("freq");
Slider(win, Rect(40,10, 160, 24))
	.action_({|sl| synth.set(\freq, [100, 2000, \exp].asSpec.map(sl.value)) });
StaticText(win, Rect(10,46, 160, 20)).font_(Font("Helvetica", 9)).string_("amp");
Slider(win, Rect(40,46, 160, 24))
	.action_({|sl| synth.set(\amp, [0, 1.0, \amp].asSpec.map(sl.value)) });
win.onClose_({ synth.free }).front; // we add a "onClose" message to the window and "front" it.
)



﻿
// Figure 5. A GUI with vertical sliders controlling the frequency and amplitude
(
var synth, win;
synth = Synth(\simpleSynth, [\freq, 100, \amp, 0]);
win = Window("", Rect(100, 100, 94, 200), false);
StaticText(win, Rect(20, 170, 160, 20)).font_(Font("Helvetica", 9)).string_("freq");
Slider(win, Rect(10, 10, 30, 160))
	.action_({|sl| synth.set(\freq, [100, 2000, \exp].asSpec.map(sl.value)) });
StaticText(win, Rect(60, 170, 160, 20)).font_(Font("Helvetica", 9)).string_("amp");
Slider(win, Rect(50, 10, 30, 160))
	.action_({|sl| synth.set(\amp, [0, 1.0, \amp].asSpec.map(sl.value)) });
win.onClose_({ synth.free }).front; // we add a "onClose" message to the window and "front" it.
)



﻿

// Figure 7. Irritia. A stochastic patch playing with the envelope view. The mouse can be used to interact with the patch
(
var nNodes, envView, startStop, myWait, timeSlider, mouseTracker;
var xLoc, yLoc, mousedown = false;
var randLoc = 0.12.rand;

SynthDef(\irritia, { arg out=0, gate=1, freq=440, pan=0.0; 
	Out.ar(out, Pan2.ar(LFSaw.ar(freq,0.4,0.05) * EnvGen.kr(Env.sine, gate, doneAction:2), pan))
}).add;

nNodes = 10;
myWait = 0.033;

w = Window("irritia", Rect(200 , 450, 400, 400)).front;

envView = EnvelopeView(w, Rect(20, 20, 355, 300))
			.thumbHeight_(6.0)
			.thumbWidth_(6.0)
			.fillColor_(Color.grey)
			.background_(Color.white)
			.drawLines_(true)
			.selectionColor_(Color.red)
			.drawRects_(true)
			.resize_(5) // can be resized and stretched
			.value_([{1.0.rand}!nNodes, {1.0.rand}!nNodes]);
			
// connect all the nodes in the envelope view to each other
nNodes.do({arg i; envView.connect(i, {|j|j}!nNodes); });

// create a little interaction where mouseactions affect the activity
UserView(w, Rect(20, 20, 355, 300))
	.mouseDownAction_({|view, x, y| mousedown = true; xLoc = x/355; yLoc = (-1+(y/300)).abs; })
	.mouseMoveAction_({|view, x, y| xLoc = x/355; yLoc = (-1+(y/300)).abs; })
	.mouseUpAction_({mousedown = false});

r = Routine({
	inf.do({ |i|
		envView.select(envView.size.rand);
		if(mousedown.not, {
			0.05.coin.if({
				0.5.coin.if({
					myWait = rrand(0.028, 0.042);
					xLoc = 1.0.rand; 
					yLoc = 1.0.rand;
				}); 
				randLoc = 0.12.rand2; 
			});
			xLoc = envView.x+rand2(randLoc); 
			yLoc = envView.y+rand2(randLoc);
		}, {
			xLoc = (xLoc + envView.x+rand2(0.1.rand))/2;
			yLoc = (yLoc + envView.y+rand2(0.1.rand))/2;
		});
		envView.x_(xLoc);
		envView.y_(yLoc);
		Synth(\irritia, [\freq, (yLoc*200)+50, \pan, (xLoc*2)-1]);
		myWait.wait;
	});
}).play(AppClock);

w.onClose_({ r.stop });

)



﻿
// Figure 12. A sketch of snow triggering a bell sound on landing
(
SynthDef(\snowBell, { | freq=440, amp=0.4, pan=0 |
	var x, env;
	env = EnvGen.kr(Env.perc(0.001, Rand(550,650)/freq, amp), doneAction:2);
	x = Mix.fill(6, {SinOsc.ar(freq*Rand(-10,10), 0, Rand(0.1,0.2))});
	x = Pan2.ar(x, pan, env);
	Out.ar(0, x);
}).add;
)

(
var win, msl, trigAction, snowloc, speeds, speed, layers=4, snowcount = 62;

// fill an array with arrays (number of layers) of locations
snowloc = {{rrand(0.38,1.5)} ! snowcount} ! layers;
// fill an array with arrays (number of layers) of step size (speed)
speeds = {{rrand(0.01,0.018)} ! snowcount} ! layers;

speed = 0.1;

win = Window("snow", Rect(11, 311, 520, 240), border: false).front;
win.view.background = Color(0.14,0.17,0.24);

msl = Array.fill(layers, {|i|
		MultiSliderView(win, Rect(-1, -1, 522, 242))
			.strokeColor_( Color.new255(rrand(22,35),rrand(22,35),rrand(22,35)) )
			.fillColor_( Color.new255(rrand(222,255),rrand(222,255),rrand(222,255)) )
			.valueThumbSize_(rrand(2.8,3.8))
			.indexThumbSize_(rrand(2.8,3.8))
			.gap_(5)
	});

// when the snow falls this happens. (pitch is mapped to index and amplitude to speed)
trigAction = {arg drop, amp; Synth(\snowBell, [\freq, 400+(drop*20), \amp, amp, \pan, rrand(-0.8, 0.8)])};

t = Task({
	loop({
		snowloc = snowloc.collect({|array, i| 
			array = array.collect({|val, j| 
				val = val-speeds[i][j]; 
				if(val< 0.0, {val = 1.0; trigAction.(j, speeds[i][j]*10 )});
				val
			});
			array
		});
		/* 
		Task uses the TempoClock by default so we need to "defer" the GUI updating 
		(Function:defer uses AppClock) This means that the Task is essentially using 
		the SystemClock and therefore the timing is better on the sound front. 
		The AppClock (used for GUI updates) has worse timing.
		*/
		{ layers.do({|i| msl[i].value_(snowloc[i]) }) }.defer;
		speed.wait;
	});
}).start;

// on stopping the program (Command/Ctrl + dot) the task will stop and the window close
CmdPeriod.add({ t.stop; win.close; });
)



﻿Figure 23.2
 (
{	var f = { | a, b | [a.min(1 - b), b.min(1 - a)] };
	var freq = f.value(MouseX.kr, MouseY.kr) * 400 + 500;
	SinOsc.ar(freq) * 0.1
}.play;
)


(
a = { |freq=100, width=0.5|
	var df, dw;
	df = freq - LastValue.kr(freq);
	dw = width - LastValue.kr(width);
	freq = freq + (dw * 100);
	width = width + (df / 100);
	Pulse.ar(freq, width.clip(0.01, 0.99).poll) * 0.1
}.play;
)

a.set(\freq, exprand(200.0, 600.0));
a.set(\width, 1.0.rand);



﻿Figure 23.4

// modulating the frequency input to a Pokey UGen results in great variance
(
{ 
	var rate = MouseX.kr(0, 255);
	var mod = LFPulse.kr(1);
	var amp = 2r1100; // 12 of 16
	Pokey.ar(rate + mod, audc1: 2r01000000 + amp);
}.play
);

// modulating the pure tone bit
(
{ 
	var rate = MouseX.kr(0, 255);
	var mod = LFPulse.kr(1);
	var amp = 2r1100; // 12 of 16
	Pokey.ar(rate, audc1: 2r00100000 + (mod * 2r00100000) + amp);
}.play
);




﻿Figure 23.5 
(
SynthDef(\FreqMod, { |car=440, carFine=1, mod=100, modFine=1, index=4, amp=0.3, pan=0| 
	Out.ar(0, Pan2.ar(PMOsc.ar(car * carFine, mod * modFine, index), pan, amp)); 
}).add; 		

c = Controller.new(s, 256);
c.makeInterface(2, 3, 0, "Freq Mod controller");

c[0].setup("carFreq", [50, 4800, \exp].asSpec, 440);
c[1].setup("carFreqFine", [0.95, 1.05, \exp].asSpec, 1);
c[2].setup("modFreq", [10, 4800, \exp].asSpec, 10);
c[3].setup("modFreqFine", [0.95, 1.05, \exp].asSpec, 1);
c[4].setup("mIndex", [0, 24, \lin].asSpec, 1);
c[5].setup("amp", [0, 1, \lin].asSpec, 0.2);
);

a = Synth(\FreqMod) // start the synth
6.do({|i| a.map(i, c[i].index)}); // map the synth control to the controller.
a.free // when finished




﻿Figure 23.7 
(
SynthDef(\ping, {
	arg out = 0, mfreq = 69, pan = 0, gain = 0.2, dur = 0.25;
	Out.ar(out, Pan2.ar(
	SinOsc.ar(mfreq.midicps, 0, 
	EnvGen.kr(envelope: (Env.perc(0.01, dur)), doneAction: 2)),
	pan, gain));
}).add;

// function to play a synth
m = {|f, d=0.3, g=0.2, p=0| Synth(\ping, [\mfreq, f + 45, \pan, p, \gain, g, \dur, d])};

// function to make a chord
c = {|a, b, c| [a, b, c].do{|i| m.value(i, 1.2, 0.075, rrand(-1.0, 1.0))}};

t = TempoClock.default.tempo_(116 / 60); // assign clock to t
b = HierSch.new(t); // start new HierSch, pass in clock
)

(
// HierSch schedules
b.schedAbs(t.beats.ceil + 48, 1, { var offset = [0, 5, 7, 12]; c.value(*[12, 16, 19]+ offset.choose)}, Prand(#[1.5, 3], 30)); // enters last, priority highest

b.schedAbs(t.beats.ceil + 14, 2, {|b, p, d, c| m.value([0, 0, 7, 5, 4].at(c % 5) + [12, 24].choose, 0.4, 0.15, rrand(-1.0, 1.0))}, Pseq(#[2, 2, 2, 1], 15)); // enters middle, priority middle

b.schedAbs(t.beats.ceil, 3, { |b, p, d, c| m.value(VagueList[0, 12, 4, 7, 10, 10, 9, 9, 7].at(c % 9))}, Pseq(#[0.5, 0.5, 0.5, 0.5, 0.25, 0.75, 1, 0.5, 0.5], 17)); // enters first, priority lowest
)




﻿// Figure 23.8

p = LazyEnvir.push;
~a = ~b * ~c;
~a.value; 	// => nil
~b = Pseq([1, 2, 3]).asStream;
~c = 10;
~a.value; 	// => 10
~a.value; 	// => 20
~b = [1, 2, 3];
~a.value; 	// => [10, 20, 30];
~a.postcs;	// => Maybe((Maybe([ 1, 2, 3 ]) * Maybe(10)))
p.pop




﻿Figure 23.9

(
var x;
x = { |rates=#[1, 1]| Ringz.ar(Impulse.ar(rates) * 0.1, rates * 80, 1 / rates) }.play;
fork {
	var str = {:[x, y], 
		x<-(40..2), 
		y<-(x + 1..40),
		gcd(x, y) == 1,
		x.isPrime.not and: y.isPrime.not
	};
	0.5.wait;
	str.do { |primes|
		x.setn(\rates, primes.postln);
		(primes.product / primes.sum / 20).wait;
	}
};
)



﻿
// Figure 23.10

(
var dict, maxLength = 0;
dict = (
	ab: { (note: [4, 0, 7], legato: 0.1, dur: 1) },
	ba: { (note: [4, 9, 8], legato: 0.3, dur: 0.3) },
	aaa: { (note: 5, legato:1.5) },
	bbb: { (note: 0, legato:2.5, dur: 0.25) }
);

dict.keys.do { |key| maxLength = max(maxLength, key.asString.size) };

f = { |str|
	var i = 0, n = 0, substr, event;
	while { i < str.size } {
		substr = str[i..i + n];
		event = dict[substr.asSymbol].value;
		if(event.notNil) {
			substr.postln;
			i = i + n + 1;
			n = 0;
			event.postln.play;
			event.delta.wait;
		} {
			if(n + 1 < maxLength) { n = n + 1 } { n = n - 1; i = i + 1 }
		};
	};
};
)

// play some sequences
fork { f.value("abbbbaab"); }
fork { f.value("aaabbbabbaaaabbabaaaaba"); };



﻿Figure 24.2
union PyrSlot
{
	double f;					// double
	struct {
		int tag;
		union {
			int		c;		// character
			int		i;		// integer
			void		*ptr;	// raw pointer
			PyrObject	*o;		// object pointer
			PyrSymbol	*s;		// symbol pointer
			...				// other object pointers
		} u;
	} s;
};



﻿Figure 24.4	
PyrObjectHdr
{
	// garbage collector links
	PyrObjectHdr	*prev;
	PyrObjectHdr	*next;
	// class pointer
	PyrClass	*classptr;
	// object size
	int		size;			

	// indexable object format
	unsigned char obj_format;
	// object size class (power of two)
	unsigned char obj_sizeclass;
	// object flags
	unsigned char obj_flags;
	// garbage collector color
	unsigned char gc_color;
	...
};



﻿Figure 24.6
PyrSymbol
{
	// symbol name
	char	*name;
	// hash value
	long	hash;
	// special selector index
	short	specialIndex;
	// symbol flags
	uint8	flags;
	// length of symbol name
	uint8	length;
	union {
		// index in method table or primitive table
		long index;
		// pointer to class with this name
		struct PyrClass *classobj; name.
		....
	} u;
	// class dependancy (used during compilation)
	ClassDependancy *classdep;	
};



﻿Figure 24.7

VMGlobals
{
	// global context

	AllocPool	*allocPool;
	// main thread context
	PyrProcess	*process;
	// global symbol table
	SymbolTable	*symbolTable;
	// garbage collector for this process
	PyrGC		*gc;
	// class variable array
	PyrObject	*classvars;

	// next byte code is a tail call
	int		tailCall;

	// true when in 'main' thread
	bool		canCallOS;

	// thread context
	
	PyrThread	*thread;
	PyrMethod	*method;
	PyrBlock	*block;
	PyrFrame	*frame;
	PyrMethod	*primitiveMethod;

	// current instruction pointer
	unsigned char	*ip;
	// current stack pointer
	PyrSlot		*sp;

	// argument pointer for primitive
	PyrSlot		*args;
	// current receiver
	PyrSlot		receiver;
	// interpretation result
	PyrSlot		result;
	// number of args to pop for primitive
	int		numpop;
	// current index into primitive table
	long		primitiveIndex;
	// random number generator state
	RGen		*rgen;
	// handler for unwinding C stack
	jmp_buf		escapeInterpreter;

	// scratch context
	long		execMethod;
};


﻿Figure 24.8

ClassDependancy
{
	// next link in list
	ClassDependancy	*next;
	// superclass dependency
	ClassDependancy	*superClassDep;
	// subclass list (linked via 'next')
	ClassDependancy	*subclasses;
	// class name symbol
	PyrSymbol		*className;
	// superclass name symbol
	PyrSymbol		*superClassName;
	// file name symbol
	PyrSymbol		*fileSym;
	// start character position of definition
	int			startPos;
	// end character position of definition
	int			endPos;
	// line number of definition
	int			lineOffset;
};



﻿Figure 24.9

PyrBlock : PyrObjectHdr
{
	// pointer to PyrMethodRaw
	PyrSlot rawData1;			
	// byte codes, nil if inlined
	PyrSlot code;
	// method selectors, class names, closures table
	PyrSlot selectors;
	// literal constants table
	PyrSlot constants;
	// temporary variable default values
	PyrSlot prototypeFrame;
	// defining block context
	// (nil for methods and toplevel)
	PyrSlot contextDef;
	// arguments to block
	PyrSlot argNames;
	// variables in block
	PyrSlot varNames;
	// source code (for closed functions)
	PyrSlot sourceCode;
};


﻿Figure 24.10
PyrMethodRaw
{
	// special method index
	unsigned specialIndex;
	// method type
	unsigned methType;
	// prototype frame size
	unsigned frameSize;

	// number of arguments
	unsigned numargs;
	// 1 if has variable number of arguments
	unsigned varargs;
	// number of keyword and variable defaults
	unsigned numvars;
	// number of temporary (local) variables
	unsigned numtemps;
	// true when frame needs to be heap-allocated
	unsigned needsHeapContext;
	// numargs + varargs
	unsigned posargs;
};



﻿Figure 24.11

PyrMethod : PyrBlock
{
	PyrSlot ownerclass;
	PyrSlot name;
	PyrSlot primitiveName;
	PyrSlot filenameSym;
	PyrSlot charPos;
};



﻿Figure 24.13

PyrFrame : PyrObjectHdr
{
	// defining method
	PyrSlot method;
	// calling context
	PyrSlot caller;
	// closure context
	PyrSlot context;
	// method context
	PyrSlot homeContext;
	// instruction pointer
	PyrSlot ip;
	// temporary variable storage
	PyrSlot vars[1];
};



﻿Figure 24.16
#include <math.h>
#include "GC.h"
#include "PyrKernel.h"
#include "PyrPrimitive.h"

// Primitive implementation of atan2,
// calling the function from libm.
static int prAtan2(struct VMGlobals *g, int numArgsPushed)
{
	// Pointer to arguments
	PyrSlot *args = g->sp - numArgsPushed + 1;
	// Pointer to receiver (self)
	PyrSlot* self = args + 0;
	// Pointer to argument
	PyrSlot* arg  = args + 1;

	double x, y;
	int err;
	
	// Get receiver value
err = slotDoubleVal(self, &x);
// Signal error for invalid input type
	if (err != errNone) return err;
	
	// Get argument value
	err = slotDoubleVal(arg, &y);
// Signal error for invalid input type
	if (err != errNone) return err;
	
	// Compute result
double result = atan2(x, y);

	// Set top of stack to return value
	SetFloat(self, result);
	
	// Signal success
	return errNone;
}

// Call this function during initialization,
// e.g. from initPrimitives() in PyrPrimitive.cpp
void initMyPrimitives()
{
	// Initialize primitive indices
	int base = nextPrimitiveIndex(), index = 0;

	// Define primitive with two arguments (self, operand)
	definePrimitive(base, index++, "_MyFloatAtan2", prAtan2, 2, 0);
	// ... define more primitives here ...
}




﻿Figure 25.1
#include "SC_PlugIn.h"
			
static InterfaceTable *ft;

// the struct will hold data which we want to "pass" from one function to another
// e.g. from the constructor to the calc func, 
// or from one call of the calc func to the next
struct Flanger : public Unit  {
	float rate, delaysize, fwdhop, readpos;
	int writepos;
};

// function declarations, exposed to C
extern "C" {  
	void load(InterfaceTable *inTable);
	void Flanger_Ctor(Flanger *unit);
	void Flanger_next(Flanger *unit, int inNumSamples);
}


void Flanger_Ctor( Flanger *unit ) {
	
	// Here we must initialise state variables in the Flanger struct.
	unit->delaysize = SAMPLERATE * 0.02f; // Fixed 20ms max delay
	// Typically with reference to control-rate/scalar-rate inputs.
	float rate  = IN0(1);
	// Rather than using rate directly, we're going to calculate the size of 
	// jumps we must make each time to scan through the delayline at "rate"
	float delta = (unit->delaysize * rate) / SAMPLERATE;
	unit->fwdhop = delta + 1.0f;
	unit->rate  = rate;
	
	// IMPORTANT: This tells scsynth the name of the calculation function
	// for this UGen.
	SETCALC(Flanger_next);
	
	// Should also calc 1 sample's worth of output – 
	//ensures each ugen's "pipes" are "primed"
	Flanger_next(unit, 1);
}

void Flanger_next( Flanger *unit, int inNumSamples ) {
	
	float *in = IN(0);
	float *out = OUT(0);
	
	float depth = IN0(2);
	
	float rate    = unit->rate;
	float fwdhop  = unit->fwdhop;
	float readpos = unit->readpos;
	int writepos  = unit->writepos;
	int delaysize = unit->delaysize;

	float val, delayed;
	
	for ( int i=0; i<inNumSamples; ++i) {
		val = in[i];
		
		// Do something to the signal before outputting
		// (not yet done)
		
		out[i] = val;
	}
	
	unit->writepos = writepos;
	unit->readpos = readpos;
}	


void load(InterfaceTable *inTable) {
	
	ft = inTable;
	
	DefineSimpleUnit(Flanger);
}




﻿Figure 25.2
#include "SC_PlugIn.h"

static InterfaceTable *ft;

// the struct will hold data which we want to "pass" from one function to another
// e.g. from the constructor to the calc func, 
// or from one call of the calc func to the next
struct Flanger : public Unit  {
	float rate, delaysize, fwdhop, readpos;
	int writepos;
	
	// a pointer to the memory we'll use for our internal delay
	float *delayline;
};

// function declarations, exposed to C
extern "C" {  
	void load(InterfaceTable *inTable);
	void Flanger_Ctor(Flanger *unit);
	void Flanger_next(Flanger *unit, int inNumSamples);
	void Flanger_Dtor(Flanger *unit);
}


void Flanger_Ctor( Flanger *unit ) {
	
	// Here we must initialise state variables in the Flanger struct.
	unit->delaysize = SAMPLERATE * 0.02f; // Fixed 20ms max delay
	// Typically with reference to control-rate/scalar-rate inputs.
	float rate  = IN0(1);
	// Rather than using rate directly, we're going to calculate the size of 
	// jumps we must make each time to scan through the delayline at "rate"
	float delta = (unit->delaysize * rate) / SAMPLERATE;
	unit->fwdhop = delta + 1.0f;
	unit->rate = rate;
	unit->writepos = 0;
	unit->readpos = 0;
	
	// Allocate the delay line
	unit->delayline = (float*)RTAlloc(unit->mWorld, unit->delaysize * sizeof(float));
	// Initialise it to zeroes
	memset(unit->delayline, 0, unit->delaysize * sizeof(float));
	
	// IMPORTANT: This tells scsynth the name of the calculation function 
	//for this UGen.
	SETCALC(Flanger_next);
	
	// Should also calc 1 sample's worth of output – 
	//ensures each ugen's "pipes" are "primed"
	Flanger_next(unit, 1);
}

void Flanger_next( Flanger *unit, int inNumSamples ) {
	
	float *in = IN(0);
	float *out = OUT(0);
	
	float depth = IN0(2);
	
	float rate    = unit->rate;
	float fwdhop  = unit->fwdhop;
	float readpos = unit->readpos;
	float *delayline = unit->delayline;
	int writepos  = unit->writepos;
	int delaysize = unit->delaysize;

	float val, delayed, currate;
	
	currate = IN0(1);
	
	if(rate != currate){
		// rate input needs updating
		rate = currate;
		fwdhop = ((delaysize * rate * 2) / SAMPLERATE) + 1.0f;
	}
	
	for ( int i=0; i<inNumSamples; ++i) {
		val = in[i];
		
		// Write to the delay line
		delayline[writepos++] = val;
		if(writepos==delaysize)
			writepos = 0;
		
		// Read from the delay line
		delayed = delayline[(int)readpos];
		readpos += fwdhop;
		// Update position, NB we may be moving forwards or backwards 
		//(depending on input)
		while((int)readpos >= delaysize)
			readpos -= delaysize;
		while((int)readpos < 0)
			readpos += delaysize;
		
		// Mix dry and wet together, and output them
		out[i] = val + (delayed * depth);
	}
	
	unit->rate = rate;
	unit->fwdhop = fwdhop;
	unit->writepos = writepos;
	unit->readpos = readpos;
}	

void Flanger_Dtor( Flanger *unit ) {
	RTFree(unit->mWorld, unit->delayline);
}	

void load(InterfaceTable *inTable) {
	
	ft = inTable;
	
	DefineDtorUnit(Flanger);
}


