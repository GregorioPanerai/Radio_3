Server.default = s = Server.local;
//Server.killAll;
s.options.memSize = 1048576;
s.options.numPrivateAudioBusChannels = 32768;
s.options.numBuffers_(2097152);  //  alza di più!!!!!!!!!!!!!
s.options.numWireBufs_(65536);
//s.options.blockSize_(512);
s.options.sampleRate_(44100);
s.options.memoryLocking_(true);

~f = Dictionary.new;
~v = Dictionary.new;
~v
/* PATHS */

.put("midiDB_folder", "".resolveRelative ++ "mididb/")
.put("sampleDB_folder", "".resolveRelative ++ "sampledb/")
.put("convDB_folder", "".resolveRelative ++ "convdb/")
.put("structure_folder", "".resolveRelative ++ "structures/")
.put("harmony_folder", "".resolveRelative ++ "harmony/")
.put("src_folder", "".resolveRelative ++ "src/" );

~boot_function = {
	Routine{
		s.waitForBoot{
			File.open(~v["src_folder"] ++ "functions_v.1.0.0.scd", "r").readAllString.interpret;
			File.open(~v["src_folder"] ++ "variables_v.1.0.0.scd", "r").readAllString.interpret;
            File.open(~v["src_folder"] ++ "synthdefs_v.1.0.0.scd", "r").readAllString.interpret;

			Routine{
				MIDIClient.init;
				~f.at("read_convDB").value;
				1.wait;
				c = MIDIOut(0);
				~f.at("read_sampleDB_v2").value;
				~f.at("read_midiDB").value;
				~f.at("generate_midi_combinations").value;
				~v["dominanti_secondaarie"] = false;
				~v["chord_alteration_enable"] = true;
				~f["create_kd_trees"].value;
				~f["generate_tmp_song"].value();   //questa è il primo blocco, primo pad e accordi
				~f["generate_tmp_song_at_runtime"].value();  //questa è il secondo blocco, pad e accordi
				~d = ~f.at("load_DSP").value;
				~f.at("show_GUI").value(~d);
				1.wait;
				~startFunction.value(1);
			}.play(AppClock);
		};
	}.play(AppClock);
};
~boot_function.value;

s.meter;
s.plotTree