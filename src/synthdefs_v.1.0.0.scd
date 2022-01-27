SynthDef(\PlayBuf, { | buf, pitch=60, shift=1.0, amp=0.5, dur=2, gate=1, out=0, attack=0.01 |  //tolto gate
	var env, play;
	var freq = pitch.midicps;
	play = PlayBuf.ar(2, buf);
	amp = amp * AmpCompA.ir(freq);
	amp = amp + (amp * 0.05).rand2;
	env = EnvGen.ar(Env.adsr(attackTime: attack, decayTime: 0.01, sustainLevel: 1, releaseTime: 6, curve: -2), gate, levelScale: amp);
	//((freq * 16 * amp * 12.23) + freq).poll;
	play = BLowPass4.ar(play, ((freq * amp * 195) + freq).clip(200, 20000), 1);
	play = HPF.ar(play, 100);
	play = play * env;
	//DetectSilence.ar(play, doneAction: 2);
	Out.ar(out, play);
}).add;


SynthDef(\PlayBufBass, { | buf, pitch=60, shift=1.0, amp=0.5, dur=2, gate=1, out=0, attack=0.01 | //tolto gate
	var env, play;
	var freq = pitch.midicps;
	play = PlayBuf.ar(2, buf);
	amp = amp * AmpCompA.ir(freq);
	amp = amp + (amp * 0.05).rand2;
	env = EnvGen.ar(Env.adsr(attackTime: attack, decayTime: 0.01, sustainLevel: 1, releaseTime: 1, curve: -2), gate,   levelScale: amp);
	//((freq * 16 * amp * 12.23) + freq).poll;
	play = BLowPass4.ar(play, ((freq * amp * 195) + freq).clip(200, 20000), 1);
	play = HPF.ar(play, 40);
	play = play * env;
	//DetectSilence.ar(play, doneAction: 0);
	Out.ar(out, play);
}).add;


SynthDef(\PlayBufDrum, { | buf, pitch=60, shift=1.0, amp=0.5, dur=2, gate=1, out=0 |
	var env, play;
	var freq = pitch.midicps;
	play = DiskIn.ar(2, buf);
	env = EnvGen.ar(Env.adsr(attackTime: 0, decayTime: 0.01, sustainLevel: 1, releaseTime: 0.5, curve: -2), gate,   levelScale: amp);
	play = play * env;
	//play = play * amp;
	//DetectSilence.ar(play, doneAction: 5);
	Out.ar(out, play);
}).add;


SynthDef(\PlayBufDrumDelay, { | buf, pitch=60, shift=1.0, amp=0.5, dur=2, gate=1, out=0, delT=0.5, delD=0.8 |
	var env, play;
	var freq = pitch.midicps;
	play = DiskIn.ar(2, buf);
	env = EnvGen.ar(Env.new([0, 1, 1, 0], [0.005, 10, 5]), levelScale: amp, doneAction: 2);
	play = play * env;
	play = play + AllpassC.ar(play, 1, delT, delD) - AllpassC.ar(play, 1, delT * 1.5, delD);
	play = play + AllpassC.ar(play, 1, delT * 0.75, delD);
	//play = GVerb.ar(play, 70, 7, 0.2, 0.5, 50, 0.85, 0.6, 0.2, 100);
	Out.ar(out, play);
}).add;


SynthDef(\PlayBufADS, { | buf, pitch=60, shift=1.0, amp=0.5, dur=2, gate=1, out=0, attack=0.01 |
	var env, play;
	var freq = pitch.midicps;
	play = DiskIn.ar(2, buf);
	amp = amp * AmpCompA.ir(freq);
	env = EnvGen.ar(Env.adsr(attackTime: attack, decayTime: 0.01, sustainLevel: 1, releaseTime: 1), gate, levelScale: amp);
	play = play * env;
	EnvGen.ar(Env.new([0, 0],  [BufDur.ir(buf)]), doneAction: 2);
	Out.ar(out, play);
}).add;


SynthDef(\PlayBufAtmos, { | buf, pitch=60, rate=1.0, amp= 5, dur=2, gate=1, out=0, attack=0.01 |
	var env, play;
	var freq = pitch.midicps;
	env = EnvGen.ar(Env.adsr(attackTime: attack, decayTime: 0.01, sustainLevel: 1, releaseTime: 1), gate, levelScale: amp, doneAction: 3);
	play = DiskIn.ar(2, buf, loop:1);  //COSI però li sovrapponeeeeeeeeeee con 1
	//amp = amp * AmpCompA.ir(freq);  // ho messo amp a 0 per spengere, era 0.5
	play = play * amp;
	play = play * env;
	Out.ar(out, play);  //ATMOS NON SPARISCONO DA PLOT TREE, RIMANGONO IN MEMORIA?!?!?!?!?
}).add;



SynthDef(\PlayBufTransition, { | buf, pitch=60, rate=1.0, amp=20, dur=2, gate=1, out=0, attack=0.01 |
	var env, play;
	var freq = pitch.midicps;
	play = PlayBuf.ar(2, buf, rate, doneAction: 2);  //era VDiskIn
	amp = amp * AmpCompA.ir(freq);
	play = play * amp;
	Out.ar(out, play);
}).add;



////////////////////MIO DRUM DSP  02/12/21///////////////////////////////////////////
SynthDef(\DSP_drum, { |
	in=0, out=0, /*  IN/OUT variables */
	low_shelf_f=20, low_shelf_g=0, low_shelf_q=0.1, low_shelf_e=0, hi_shelf_f=18000, hi_shelf_g=0, hi_shelf_e=0, hi_shelf_q=0.1, bp1_f=440, bp1_g=0, bp1_q=0.1, bp1_e=0, bp2_f=440, bp2_g=0, bp2_q=0.1, bp2_e=0, bp3_f=440, bp3_g=0, bp3_q=0.1, bp3_e=0, bp4_f=440, bp4_g=0, bp4_q=0.1, bp4_e=0,  /* EQ variables */
	comp_t=0.5, comp_sb=1, comp_sa=0.3, comp_e=0, comp_atk=0.03, comp_rel=0.2, /* COMPRESSOR variables */
	limit_l=1.0, limit_e=0, /* LIMITER variables */
	pan=0, /* PAN variables */
	rev_w=0, rev_r=0.4, rev_d=0.2, rev_e=0, irbufnum,/* REVERB variables */
	pre_gain=0, post_gain=0, gate=1 | /* GAIN variables */
	var sig, env;
	env = EnvGen.ar(Env.asr(5, 1, 5), gate, doneAction: 5);
	/* GAIN */
	sig = In.ar(in, 2);
	/* CONV REVERB */
	//sig = sig + (PartConv.ar(sig, 2048, irbufnum) * rev_w);
	/* EQ */

	sig = HPF.ar(sig, 30);
	sig = BLowShelf.ar(sig, 50, 1, -1, 1, 0);
	sig = BPeakEQ.ar(sig, 100, 1, 2);
	sig = BPeakEQ.ar(sig, 5000, 1, 2);
	sig = BHiShelf.ar(sig, 10000, 1, 1);

	sig = SoftKneeCompressor.ar(sig, sig, -11, 4.reciprocal, 6, 0.01, 0.057);   //2:1 di ratio
	//-0.3.dbamp
	//sig = Limiter.ar( sig ,-0.3.dbamp,  0.05);   //50 ms di dur  oppure 20, 0.02
	//rev_w.poll;

	/* REVERB */
	//sig = sig + (VBJonVerb.ar(sig, decay: 0.9, damping: 0.3, inputbw: 0.8, erfl: 0.5, tail: 0.5)* 0.15);

	/* STEREO PANNING */

	sig = Pan2.ar(sig, pan);

	sig = sig * -3.dbamp; // volume

	/* OUT */

	Out.ar(out, sig * env);
}).add;


SynthDef(\DSP_bass, { |
	in=0, out=0, /*  IN/OUT variables */
	low_shelf_f=20, low_shelf_g=0, low_shelf_q=0.1, low_shelf_e=0, hi_shelf_f=18000, hi_shelf_g=0, hi_shelf_e=0, hi_shelf_q=0.1, bp1_f=440, bp1_g=0, bp1_q=0.1, bp1_e=0, bp2_f=440, bp2_g=0, bp2_q=0.1, bp2_e=0, bp3_f=440, bp3_g=0, bp3_q=0.1, bp3_e=0, bp4_f=440, bp4_g=0, bp4_q=0.1, bp4_e=0,  /* EQ variables */
	comp_t=0.5, comp_sb=1, comp_sa=0.3, comp_e=0, comp_atk=0.03, comp_rel=0.2, /* COMPRESSOR variables */
	limit_l=1.0, limit_e=0, /* LIMITER variables */
	pan=0, /* PAN variables */
	rev_w=0, rev_r=0.4, rev_d=0.2, rev_e=0, irbufnum,/* REVERB variables */
	pre_gain=0, post_gain=0, gate=1 | /* GAIN variables */
	var sig, env;
	env = EnvGen.ar(Env.asr(5, 1, 5), gate, doneAction: 5);
	/* GAIN */
	sig = In.ar(in, 2); //* pre_gain.dbamp;// * 0.5;
	/* CONV REVERB */
	//sig = sig + (PartConv.ar(sig, 2048, irbufnum) * rev_w);
	sig = HPF.ar(sig, 40);

	sig = BPeakEQ.ar(sig, 165, 30.reciprocal, -3);
	sig = BPeakEQ.ar(sig, 2000, 1, -1);

	sig = SoftKneeCompressor.ar(sig, sig, -11, 4.reciprocal, 6, 0.026, 0.051);   //2:1 di ratio
	//-0.3.dbamp
	//sig = Limiter.ar( sig ,-0.3.dbamp,  0.05);   //50 ms di dur  oppure 20, 0.02
	//rev_w.poll;

	/* REVERB */
	//sig = sig + VBJonVerb.ar( sig * rev_w, decay: 0.6, damping: 0.3, inputbw: 0.8, erfl: 0.5, tail: 0.5);

	/* STEREO PANNING */
	//sig = Pan2.ar(sig, pan) * post_gain.dbamp;

	sig = sig * 0.dbamp; // volume

	/* OUT */

	Out.ar(out, sig * env);
}).add;


SynthDef(\DSP_key, { |
	in=0, out=0, /*  IN/OUT variables */
	low_shelf_f=20, low_shelf_g=0, low_shelf_q=0.1, low_shelf_e=0, hi_shelf_f=18000, hi_shelf_g=0, hi_shelf_e=0, hi_shelf_q=0.1, bp1_f=440, bp1_g=0, bp1_q=0.1, bp1_e=0, bp2_f=440, bp2_g=0, bp2_q=0.1, bp2_e=0, bp3_f=440, bp3_g=0, bp3_q=0.1, bp3_e=0, bp4_f=440, bp4_g=0, bp4_q=0.1, bp4_e=0,  /* EQ variables */
	comp_t=0.5, comp_sb=1, comp_sa=0.3, comp_e=0, comp_atk=0.03, comp_rel=0.2, /* COMPRESSOR variables */
	limit_l=1.0, limit_e=0, /* LIMITER variables */
	pan=0, /* PAN variables */
	rev_w=0, rev_r=0.4, rev_d=0.2, rev_e=0, irbufnum,/* REVERB variables */
	pre_gain=0, post_gain=0, gate=1 | /* GAIN variables */
	var sig, env;
	env = EnvGen.ar(Env.asr(5, 1, 5), gate, doneAction: 2);
	/* GAIN */
	sig = In.ar(in, 2) * pre_gain.dbamp;// * 0.5;
	/* CONV REVERB */
	//sig = sig + (PartConv.ar(sig, 2048, irbufnum) * rev_w);


	sig = HPF.ar(sig, 100);

	sig = BLowShelf.ar(sig, 50, 1, -1, 1, 0);
    sig = BPeakEQ.ar(sig, 200, 1, 1);
	sig = BPeakEQ.ar(sig, 400, 1, -2);
	sig = BPeakEQ.ar(sig, 550, 1, -1);
	sig = BPeakEQ.ar(sig, 2300, 1, -1);
	sig = BHiShelf.ar(sig, 7000, 1, 2);

	sig = SoftKneeCompressor.ar(sig, sig, -7, 2.reciprocal, 6, 0.02, 0.097);   //2:1 di ratio
	//-0.3.dbamp
	//sig = Limiter.ar( sig ,-0.3.dbamp,  0.05);   //50 ms di dur  oppure 20, 0.02
	//rev_w.poll;

	/* REVERB */
	//sig = sig + VBJonVerb.ar( sig * rev_w, decay: 0.6, damping: 0.3, inputbw: 0.8, erfl: 0.5, tail: 0.5);

	/* STEREO PANNING */
	sig = Pan2.ar(sig, pan);


	sig = sig * 3.dbamp; // volume

	/* OUT */

	Out.ar(out, sig * env);
}).add;


SynthDef(\DSP_pad, { |
	in=0, out=0, /*  IN/OUT variables */
	low_shelf_f=20, low_shelf_g=0, low_shelf_q=0.1, low_shelf_e=0, hi_shelf_f=18000, hi_shelf_g=0, hi_shelf_e=0, hi_shelf_q=0.1, bp1_f=440, bp1_g=0, bp1_q=0.1, bp1_e=0, bp2_f=440, bp2_g=0, bp2_q=0.1, bp2_e=0, bp3_f=440, bp3_g=0, bp3_q=0.1, bp3_e=0, bp4_f=440, bp4_g=0, bp4_q=0.1, bp4_e=0,  /* EQ variables */
	comp_t=0.5, comp_sb=1, comp_sa=0.3, comp_e=0, comp_atk=0.03, comp_rel=0.2, /* COMPRESSOR variables */
	limit_l=1.0, limit_e=0, /* LIMITER variables */
	pan=0, /* PAN variables */
	rev_w=0, rev_r=0.4, rev_d=0.2, rev_e=0, irbufnum,/* REVERB variables */
	pre_gain=0, post_gain=0, gate=1 | /* GAIN variables */
	var sig, env;
	env = EnvGen.ar(Env.asr(5, 1, 5), gate, doneAction: 2);
	/* GAIN */
	sig = In.ar(in, 2) * pre_gain.dbamp;// * 0.5;
	/* CONV REVERB */
	//sig = sig + (PartConv.ar(sig, 2048, irbufnum) * rev_w);

	sig = HPF.ar(sig, 40);

    sig = BPeakEQ.ar(sig, 100, 1, 1);
	sig = BPeakEQ.ar(sig, 400, 1, -2);
	sig = BPeakEQ.ar(sig, 2500, 1, -1);
    sig = BHiShelf.ar(sig, 15000, 1, 2);



	sig = SoftKneeCompressor.ar(sig, sig, -6, 2.reciprocal, 6, 0.02, 0.097);   //2:1 di ratio
	//-0.3.dbamp
	//sig = Limiter.ar( sig ,-0.3.dbamp,  0.05);   //50 ms di dur  oppure 20, 0.02
	//rev_w.poll;

	/* DELAY */
	//sig = CombN.ar(sig, maxdelaytime: 0.2, delaytime: 0.2, decaytime: 1.5, mul: 1.0, add: 0.0);

	/* REVERB */
	//sig = sig + VBJonVerb.ar( sig * rev_w, decay: 0.6, damping: 0.3, inputbw: 0.8, erfl: 0.5, tail: 0.5);
    //sig = FreeVerb2.ar(sig, sig, mix: 0.40, room: 0.5, damp: 0.8, mul: 1.0, add: 0.0);

	/* STEREO PANNING */
	//sig = Pan2.ar(sig, pan) * post_gain.dbamp;

	sig = sig * -6.dbamp; // volume

	/* OUT */

	Out.ar(out, sig * env);
}).add;

SynthDef(\DSP_lead, { |
	in=0, out=0, /*  IN/OUT variables */
	low_shelf_f=20, low_shelf_g=0, low_shelf_q=0.1, low_shelf_e=0, hi_shelf_f=18000, hi_shelf_g=0, hi_shelf_e=0, hi_shelf_q=0.1, bp1_f=440, bp1_g=0, bp1_q=0.1, bp1_e=0, bp2_f=440, bp2_g=0, bp2_q=0.1, bp2_e=0, bp3_f=440, bp3_g=0, bp3_q=0.1, bp3_e=0, bp4_f=440, bp4_g=0, bp4_q=0.1, bp4_e=0,  /* EQ variables */
	comp_t=0.5, comp_sb=1, comp_sa=0.3, comp_e=0, comp_atk=0.03, comp_rel=0.2, /* COMPRESSOR variables */
	limit_l=1.0, limit_e=0, /* LIMITER variables */
	pan=0, /* PAN variables */
	rev_w=0, rev_r=0.4, rev_d=0.2, rev_e=0, irbufnum,/* REVERB variables */
	pre_gain=0, post_gain=0, gate=1 | /* GAIN variables */
	var sig, env;
	env = EnvGen.ar(Env.asr(5, 1, 5), gate, doneAction: 2);
	/* GAIN */
	sig = In.ar(in, 2) * pre_gain.dbamp;// * 0.5;
	/* CONV REVERB */
	//sig = sig + (PartConv.ar(sig, 2048, irbufnum) * rev_w);
	sig = HPF.ar(sig, 200);


	sig = BPeakEQ.ar(sig, 2000, 1, 2);
    sig = BHiShelf.ar(sig, 15000, 1, 2);



	sig = SoftKneeCompressor.ar(sig, sig, -7, 1.6.reciprocal, 6,  0.047, 0.170);   //2:1 di ratio
	//-0.3.dbamp
	//sig = Limiter.ar( sig ,-0.3.dbamp,  0.05);   //50 ms di dur  oppure 20, 0.02
	//rev_w.poll;

	/* DELAY */
	//sig = CombN.ar(sig, maxdelaytime: 0.2, delaytime: 0.2, decaytime: 1.5, mul: 1.0, add: 0.0);

	/* REVERB */
	//sig = sig + VBJonVerb.ar( sig * rev_w, decay: 0.6, damping: 0.3, inputbw: 0.8, erfl: 0.5, tail: 0.5);
    //sig = FreeVerb2.ar(sig, sig, mix: 0.20, room: 0.5, damp: 0.8, mul: 1.0, add: 0.0);

	/* STEREO PANNING */
	//sig = Pan2.ar(sig, pan) * post_gain.dbamp;

	  sig = sig * -99.dbamp; // volume

	/* OUT */

	Out.ar(out, sig * env );
}).add;


SynthDef(\DSP_sampler, { |
	in=0, out=0, /*  IN/OUT variables */
	low_shelf_f=20, low_shelf_g=0, low_shelf_q=0.1, low_shelf_e=0, hi_shelf_f=18000, hi_shelf_g=0, hi_shelf_e=0, hi_shelf_q=0.1, bp1_f=440, bp1_g=0, bp1_q=0.1, bp1_e=0, bp2_f=440, bp2_g=0, bp2_q=0.1, bp2_e=0, bp3_f=440, bp3_g=0, bp3_q=0.1, bp3_e=0, bp4_f=440, bp4_g=0, bp4_q=0.1, bp4_e=0,  /* EQ variables */
	comp_t=0.5, comp_sb=1, comp_sa=0.3, comp_e=0, comp_atk=0.03, comp_rel=0.2, /* COMPRESSOR variables */
	limit_l=1.0, limit_e=0, /* LIMITER variables */
	pan=0, /* PAN variables */
	rev_w=0, rev_r=0.4, rev_d=0.2, rev_e=0, irbufnum,/* REVERB variables */
	pre_gain=0, post_gain=0, gate=1 | /* GAIN variables */
	var sig, //env;
	env = EnvGen.ar(Env.asr(5, 1, 5), gate, doneAction: 5);
	/* GAIN */
	sig = In.ar(in, 2) ;//* pre_gain.dbamp;// * 0.5;
	/* CONV REVERB */
	//sig = sig + (PartConv.ar(sig, 2048, irbufnum) * rev_w);

	sig = HPF.ar(sig, 200);

	sig = BPeakEQ.ar(sig, 800, 1, -2);
	sig = BPeakEQ.ar(sig, 2000, 1, 1);

	sig = SoftKneeCompressor.ar(sig, sig, -7, 1.6.reciprocal, 6, 0.047, 0.170);   //2:1 di ratio
	//-0.3.dbamp
	//sig = Limiter.ar( sig ,-0.3.dbamp,  0.05);   //50 ms di dur  oppure 20, 0.02
	//rev_w.poll;


	/* DELAY */
    //sig = CombN.ar(sig, maxdelaytime: 0.2, delaytime: 0.2, decaytime: 1.5, mul: 1.0, add: 0.0);



	/* REVERB */
	//sig = sig + VBJonVerb.ar( sig * rev_w, decay: 0.6, damping: 0.3, inputbw: 0.8, erfl: 0.5, tail: 0.5);
      sig = FreeVerb2.ar(sig, sig, mix: 0.20, room: 0.5, damp: 0.8, mul: 1.0, add: 0.0);

	/* STEREO PANNING */
	//sig = Pan2.ar(sig, pan) * post_gain.dbamp;

	sig = sig * -5.dbamp; // volume

	/* OUT */

	Out.ar(out, sig * env);  //ho rimesso env
}).add;


SynthDef(\DSP2, { | atk=3,
	in=0, out=0, /*  IN/OUT variables */
	low_shelf_f=20, low_shelf_g=0, low_shelf_q=0.1, low_shelf_e=0, hi_shelf_f=18000, hi_shelf_g=0, hi_shelf_e=0, hi_shelf_q=0.1, bp1_f=440, bp1_g=0, bp1_q=0.1, bp1_e=0, bp2_f=440, bp2_g=0, bp2_q=0.1, bp2_e=0, bp3_f=440, bp3_g=0, bp3_q=0.1, bp3_e=0, bp4_f=440, bp4_g=0, bp4_q=0.1, bp4_e=0,  /* EQ variables */
	comp_t=0.5, comp_sb=1, comp_sa=0.3, comp_atk=0.03, comp_rel=0.2, comp_e=0, /* COMPRESSOR variables */
	limit_l=1.0, limit_e=0, /* LIMITER variables */
	pan=0, /* PAN variables */
	rev_w=0.33, rev_r=0.4, rev_d=0.2, rev_e=0, irbufnum,/* REVERB variables */
	pre_gain=0, post_gain=0, gate=1 | /* GAIN variables */
	var sig, env, sig_pre_master;
	var fftsize = 1024, history_size = 4;
	var fft_filter = Array.fill(fftsize, {| id |     ((id/(fftsize-1)).pow(1/1.2) * 0.3) + 0.7     });
	var bin_history = Array.fill( fftsize, { Array.fill( history_size, { 0 } ) } );
	var chainL, chainR;
	env = EnvGen.ar(Env.asr(atk, 1, 3, [-4, -4]), gate, doneAction: 2);
	/* GAIN */
	sig = In.ar(in, 2) * pre_gain.dbamp;
	/* CONV REVERB */
	//sig = sig + (PartConv.ar(sig, 2048, irbufnum) * rev_w);
/*
	/* EQ */
	sig = SelectX.ar(low_shelf_e, [sig, BLowShelf.ar(sig, low_shelf_f, rs:1, db: ((low_shelf_g + 1.00001) / 4.75).ampdb)]);
	sig = SelectX.ar(bp1_e, [sig, sig + BBandPass.ar(sig, bp1_f, bp1_q, bp1_g.clip(-1.0, 4.0))]); // limite a +12dB, per sicurezza...
	sig = SelectX.ar(bp2_e, [sig, sig + BBandPass.ar(sig, bp2_f, bp2_q, bp2_g.clip(-1.0, 4.0))]);
	sig = SelectX.ar(bp3_e, [sig, sig + BBandPass.ar(sig, bp3_f, bp3_q, bp3_g.clip(-1.0, 4.0))]);
	sig = SelectX.ar(bp4_e, [sig, sig + BBandPass.ar(sig, bp4_f, bp4_q, bp4_g.clip(-1.0, 4.0))]);
	sig = SelectX.ar(hi_shelf_e, [sig, BHiShelf.ar(sig, hi_shelf_f, rs: 1, db: ((hi_shelf_g + 1.00001) / 4.75).ampdb)]);

	/* COMPRESSOR */
	comp_sa = comp_sa.reciprocal.reciprocal.clip(-20, 20);
	sig = SelectX.ar(comp_e, [sig, SoftKneeCompressor.ar(sig, sig, comp_t.ampdb, comp_sa, 6, comp_atk, comp_rel)]);
*/
	Out.ar(out, sig * env );
}).add;



///////////////////////////////////////MIO/////////////////////////////////// 02/12/21


SynthDef(\DSP2_FFT, { | atk=3,
	in=0, out=0, /*  IN/OUT variables */
	comp_t=0.5, comp_sb=1, comp_sa=0.3, comp_atk=0.03, comp_rel=0.2, comp_e=0, /* COMPRESSOR variables */
	limit_l=1.0, limit_e=0, /* LIMITER variables */
	pan=0, /* PAN variables */
	rev_w=0.33, rev_r=0.4, rev_d=0.2, rev_e=0, irbufnum,/* REVERB variables */
	pre_gain=0, post_gain=0, gate=1,
	limit = 0.95 | /* GAIN variables */

	var sig, env, sig_pre_master;

	env = EnvGen.ar(Env.asr(atk, 1, 3, [-4, -4]), gate, doneAction: 2);
	/* GAIN */
	sig = In.ar(in, 2) * pre_gain.dbamp;
	/* CONV REVERB */
	//sig = sig + (PartConv.ar(sig, 2048, irbufnum) * rev_w);

	//HIP
	sig = HPF.ar(sig, 20);

	sig = BPeakEQ.ar(sig, 285, 1, -2);
	sig = BPeakEQ.ar(sig, 170, 0.7, -2);
	sig = BPeakEQ.ar(sig, 2300, 0.1, -2);
	sig = BPeakEQ.ar(sig, 4000, 0.1, -2);

	//DOUBLE COMP
	sig = SoftKneeCompressor.ar(sig, sig, -2, 2.reciprocal, 6, 0.01, 0.05,  makeUp: 1.5.dbamp);
	sig = SoftKneeCompressor.ar(sig, sig, -8, 3.reciprocal, 6,  0.0005, 0.8,  makeUp: 2.5.dbamp);

	//AMP
	//sig = sig * 2.3;

	//HI SHELF
	sig = BHiShelf.ar(sig, 20000, 1, 1);

    //LIMITING
	sig = Limiter.ar( sig , -0.5.dbamp,  0.05);
   // sig = Pan2.ar(sig, pan);
	Out.ar(out, sig * env );
}).add;