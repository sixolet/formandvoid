Engine_FormAndVoid : CroneEngine {
    const <numVoices = 8;
    var <timbres, <bus, <eoc, <lfoGroup, <lfos, <lfoBusses, <noteGroups, <noteContainer, <noteTracker, <silentBuf, <winBuf, <released;

	*new { arg context, doneCallback;
		^super.new(context, doneCallback);
	}
	
	alloc {
        var win = Signal.hanningWindow(1024);
        released = [];
        winBuf = Buffer.loadCollection(Server.default, win);
        silentBuf = Buffer.loadCollection(Server.default, 0!1024);	
	    bus = Bus.audio(Server.default, 2);
	    lfoGroup = Group.new;
	    noteContainer = Group.after(lfoGroup);
	    noteGroups = nil!numVoices;
	    noteTracker = nil!numVoices;
	    numVoices.do { |i|
	        noteGroups[i] = Group.tail(noteContainer);
	        noteTracker[i] = Dictionary.new;
	    };
	    noteGroups.postln;
	    lfoBusses = numVoices.collect {Bus.control(Server.default, 1)};
	    lfos = numVoices.collect { |i|
	        { |lfoFreq=5, lfoWidth=0.5|
	            Out.kr(lfoBusses[i], VarSaw.kr(lfoFreq, width: lfoWidth));
	        }.play(target: lfoGroup);
	    };
	    timbres = numVoices.collect { |i|
	      ( instrument: \form, pan: 0, out: bus, group: noteGroups[i],
	        a1: 0.1, d1: 0.3, s1: 0.5, r1: 0.4,
	        a2: 0.3, d2: 0.5, s2: 0.8, r2: 0.4,
	        f0Amp: 0.5,
	        lfoBus: lfoBusses[i],
	        f1: 450, f1Amp: 0.5, f1Res: 0.6, f1Modulator: 450, f1Index: 0,
	        f2: 1000, f2Amp: 0.0, f2Res: 0.1, f2Index: 0,
	        e1F0: 0, e1F0Amp: 0, e1F1: 0.5, e1F1Amp: 0, e1F1Index: 0, e1F2: 0, e1F2Amp: 0.5, e1F2Index: 0,
	        e2F0: 0, e2F0Amp: 0, e2F1: 0.3, e2F1Amp: 0, e2F1Index: 0, e2F2: 1, e2F2Amp: 0, e2F2Index: 0,
	        lfoF0: 0, lfoF0Amp: 0, lfoF1:  -0.2, lfoF1Amp: 0, lfoF1Index: 0, lfoF2: 0, lfoF2Amp: 0, lfoF2Index: 0)
	    };
	    [\form, \formAA].do{ |tag|
            SynthDef(tag, { |out, freq=440, amp=1, gate=1, pan=0,
	            a1=0.1, d1=0.3, s1=0.5, r1=0.4,
	            a2=0.3, d2=0.5, s2=0.8, r2=0.4,
        	    lfoBus,	
        	    pres,
	            f0Amp=0.5, 
	            f1=450, f1Amp=0.5, f1Res=4, f1Modulator=450, f1Index=0,
	            f2=1000, f2Amp=0.0, f2Res=3, f2Index=0, f2Gain=1,
	            e1F0=0, e1F0Amp=0, e1F1= 0.5, e1F1Amp=0, e1F1Index=0, e1F2=0, e1F2Amp=0.5, e1F2Index=0,
	            e2F0=0, e2F0Amp=0, e2F1=0.3, e2F1Amp=0, e2F1Index=0, e2F2=1, e2F2Amp=0, e2F2Index=0,
	            lfoF0=0, lfoF0Amp=0, lfoF1= -0.2, lfoF1Amp=0, lfoF1Index=0, lfoF2=0, lfoF2Amp=0, lfoF2Index=0,
	            presF0=0, presF0Amp=0, presF1=0, presF1Amp=0, presF1Index=0, presF2=0, presF2Amp=0, presF2Index=0|
	
        	    var env1 = EnvGen.kr(Env.adsr(a1, d1, s1, r1), gate, doneAction: Done.freeSelf);
	            var env2 = EnvGen.kr(Env.adsr(a2, d2, s2, r2), gate, doneAction: Done.none);
	            var lfo = In.kr(lfoBus);
                var formant1, formant2, fundamental, snd, f0, f0AmpMod, f1AmpMod, f1Mod, f1IndexMod, f2AmpMod, f2Mod, f2IndexMod;
                
                pres = pres.lag(0.05);
	
	            f0 = freq*(1 + (e1F0.lag(0.1)*env1) + (e2F0.lag(0.1)*env2) + (lfoF0.lag(0.1)*lfo) + (presF0.lag(0.1)*pres));
	            f0AmpMod = f0Amp.lag(0.1) + (e1F0Amp.lag(0.1)*env1) + (e2F0Amp.lag(0.1)*env2) + (lfoF0Amp.lag(0.1)*lfo) + (presF0Amp.lag(0.1)*pres);

	            f1AmpMod = f1Amp.lag(0.1) + (e1F1Amp.lag(0.1)*env1) + (e2F1Amp.lag(0.1)*env2) + (lfoF1Amp.lag(0.1)*lfo) + (presF1Amp.lag(0.1)*pres);
	            f1Mod = f1.lag(0.1)*(1 + (e1F1.lag(0.1)*env1) + (e2F1.lag(0.1)*env2) + (lfoF1.lag(0.1)*lfo) + (presF1.lag(0.1)*pres));
	            f1IndexMod = f1Index.lag(0.1) + (e1F1Index.lag(0.1)*env1) + (e2F1Index.lag(0.1)*env2) + (lfoF1Index.lag(0.1)*lfo) + (presF1Index.lag(0.1)*pres);

	            f2AmpMod = f2Amp.lag(0.1) + (e1F2Amp.lag(0.1)*env1) + (e2F2Amp.lag(0.1)*env2) + (lfoF2Amp.lag(0.1)*lfo) + (presF2Amp.lag(0.1)*pres);
	            f2Mod = f2.lag(0.1)*(1 + (e1F2.lag(0.1)*env1) + (e2F2.lag(0.1)*env2) + (lfoF2.lag(0.1)*lfo) + (presF2.lag(0.1)*pres));
	            f2IndexMod = f2Index.lag(0.1) + (e1F2Index.lag(0.1)*env1) + (e2F2Index.lag(0.1)*env2) + (lfoF2Index.lag(0.1)*lfo) + (presF2Index.lag(0.1)*pres);
                
                if (tag == \formAA, {
	                var pulse = Pulse.ar(f0, 0.5, 1, 0.4);
	                var imp = (Slope.ar(pulse)/SampleRate.ir) > 0.25;
	                var impDel = Delay1.ar(imp).sanitize;
	                var phase = Latch.ar(pulse, imp);
	                // var before = Latch.ar(impDel, imp);	
	                // var phase = (1.25*(before + after)).unipolar;
	                formant1 = f1AmpMod*Mix.new(FMGrainI.ar([impDel, imp], f1Res*f1Mod.reciprocal, f1Mod, f1Modulator, f1Index, silentBuf, winBuf, [1-phase, phase]));
	                formant2 = f2AmpMod*Mix.new(SinGrainI.ar([impDel, imp], f2Res*f2Mod.reciprocal, f2Mod, silentBuf, winBuf, [1-phase, phase]));
	            }, {
	                var imp = Impulse.ar(f0);
	                formant1 = f1AmpMod*FMGrain.ar(imp, f1Res*f1Mod.reciprocal, f1Mod, f1Modulator, f1IndexMod);
	                formant2 = f2AmpMod*SinGrain.ar(imp, f2Res*f2Mod.reciprocal, f2Mod);	            
	            });
	            fundamental = f0AmpMod*SinOsc.ar(freq, pi*f2IndexMod*formant2);
	        
	            snd = (fundamental+formant1+(f2Gain*formant2));
	            snd = HPF.ar(snd, 0.7*freq);
	            Out.ar(out, Pan2.ar(0.3*Gate.kr(amp.lag(0.07), gate)*env1*snd, pan));
            }).add;
        };
        
        this.addCommand(\play, "ifff", { |msg|
            var timbre = msg[1].asInteger;
            var freq = msg[2].asFloat;
            var amp = msg[3].asFloat;
            var dur = msg[4].asFloat;
            var proto = timbres[timbre];
            var event = Event.new(proto: proto);
            event.freq = freq;
            event.amp = amp;
            event.dur = dur;
            event.play;
        });
		this.addCommand("tempo_sync", "ff", { arg msg;
			var beats = msg[1].asFloat;
			var tempo = msg[2].asFloat;
			var beatDifference = beats - TempoClock.default.beats;
			var nudge = beatDifference % 4;
			if (nudge > 2, {nudge = nudge - 4});
			if ( (tempo != TempoClock.default.tempo) || (nudge.abs > 1), {
				TempoClock.default.beats = TempoClock.default.beats + nudge;
				TempoClock.default.tempo = tempo;
			}, {
				TempoClock.default.beats = TempoClock.default.beats + (0.05 * nudge);
			});
			// Set M to be the duration of a beat.
			// beatDurBus.set(1/tempo);
		});
		
		this.addCommand(\noteOn, "iiff", { |msg|
		    var timbre = msg[1].asInteger;
		    var note = msg[2].asInteger;
		    var freq = msg[3].asFloat;
		    var amp = msg[4].asFloat;
		    var proto = timbres[timbre];
		    var controls = proto.asPairs;
		    var syn;
		    var inFlight;
		    controls.addAll([\freq, freq, \amp, amp]);
            syn = Synth(proto[\instrument], controls, target: noteGroups[timbre]);
            noteTracker[timbre][note] = syn;
            syn.onFree { 
                released = released.reject { |item, i| item.nodeID == syn.nodeID };
            };
            inFlight = noteTracker.sum(_.size) + released.size;
            inFlight.postln;
            if (inFlight > 5, {
                released.do { |it|
                    if (inFlight > 5, {it.release(0.1); inFlight = inFlight - 1});
                };
            });
		});
        
        this.addCommand(\noteOff, "ii", { |msg|
            var timbre = msg[1].asInteger;
            var note = msg[2].asInteger;
            if (noteTracker[timbre].includesKey(note), {
                var syn;
                noteTracker[timbre][note].set(\gate, 0);
                syn = noteTracker[timbre][note];
                noteTracker[timbre].removeAt(note);
                released.add(syn);
            });
        });
        
        this.addCommand(\setAll, "sf", { |msg|
            var key = msg[1].asString.asSymbol;
            var val = msg[2].asFloat;
            noteContainer.set(key, val);
            timbres.do { |t, i|
                switch (key)
                    {\lfoFreq} {
                        lfos[i].set(key, val);
                    }
                    {\lfoWidth} {
                        lfos[i].set(key, val);
                    }                       
                    {\model} {
                        var model;
                        if( val <= 1, { model = \form }, { model = \formAA });
                        model.postln;
                        t[\instrument] = model;                    
                    }
                    {
                        t[key] = val;
                    };
            };
        });        
        
        this.addCommand(\set, "isf", { |msg|
            var timbre = msg[1].asInteger;
            var key = msg[2].asString.asSymbol;
            var val = msg[3].asFloat;
            switch (key) 
                {\lfoFreq} {
                    lfos[timbre].set(key, val);
                }
                {\lfoWidth} {
                    lfos[timbre].set(key, val);
                }                
                {\model} {
                    var model;
                    if( val <= 1, { model = \form }, { model = \formAA });
                    model.postln;
                    timbres[timbre][\instrument] = model;
                }
                {
                    timbres[timbre][key] = val;
                    noteGroups[timbre].set(key, val);
                };
        });
        
        this.addCommand(\setNote, "iisf", { |msg|
            var timbre = msg[1].asInteger;
            var note = msg[2].asInteger;
            var key = msg[3].asString.asSymbol;
            var val = msg[4].asFloat;
            if (noteTracker[timbre].includesKey(note), {
                noteTracker[timbre][note].set(key, val);
            });
        });
        
        eoc = {
            var snd = In.ar(bus, 2);
            snd = 0.5*snd;
            snd.tanh;
        }.play(addAction: \addAfter, target: noteContainer);
    }
    
    free {
        winBuf.free;
        silentBuf.free;
        lfoGroup.free;
        noteGroups.do { |g| g.free };
        noteContainer.free;
        eoc.free;
        bus.free;
        lfoBusses.do { |b| b.free };
    }
	
}