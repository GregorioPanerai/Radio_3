//~v = Dictionary.new
~v

/* PATHS */
/*
.put("midiDB_folder", "".resolveRelative ++ "mididb/")
.put("sampleDB_folder", "".resolveRelative ++ "sampledb/")
.put("convDB_folder", "".resolveRelative ++ "convdb/")
.put("structure_folder", "".resolveRelative ++ "structures/")
.put("main_folder", "".resolveRelative)
*/

.put("wow_conductor", nil)

.put("sesso", "Misto")

.put("WOW_PAD_CHOICE", "0")

/* PRESENTATION */
.put("PRESENTATION_PAD_CHOICE_LOUNGE", "0")
.put("PRESENTATION_PAD_CHOICE_LOFI", "7")
.put("PRESENTATION_PAD_CHOICE_TRAP", "1")
.put("PRESENTATION_PAD_CHOICE_HOUSE", "0")

/* CAMBIO GENERE ISTANTANEO (QUASI) */
.put("genre_changed", false)

/* APPEARENCE */
.put("fontsize", 10)
.put("dsp_channel_width", 80)
/*
.put("font", Font("Chalkboard SE", 10))
.put("bgcolor", Color.new255(50, 50, 50))
.put("subview_bgcolor", Color.new255(50, 50, 50))
.put("slider_bgcolor", Color.new255(50, 50, 50))
.put("button_bgcolor", Color.new255(150, 150, 150))
.put("text_bgcolor", Color.new255(50, 50, 50))
.put("knob_color", Color.new255(50, 50, 50))
*/
//.put("bg_image", "".resolveRelative ++ "img/wood_texture.jpg")

/* INSTRUMENT TYPES */
.put("instrs", ["bass", "drum", "key", "lead", "pad", "sampler"])

/* DATABASES */
.put("midiDB", Dictionary.new)
.put("sampleDB", Dictionary.new)
.put("sampleDB_WoW", Dictionary.new)
.put("convDB", Dictionary.new)

/* MACRO DELLA MACCHINA */
.put("tpqn", 96)
.put("has_to_break", false)
.put("conductor_tick_correction", 0)
.put("buffer_load_time", 128) // in tick
.put("average_8bar_dur", 96 * 8 * 4)

.put("midi_selection", 0)
.put("rand_seed", Main.elapsedTime.ceil)
.put("midi_search_type", "sequence") // "nearest", "random", "walk", "sequence"

/* GENRE & SONG DEFAULT */
.put("all_genres", [ "prog_1", "prog_2","prog_3","prog_4","prog_5" /* , "prog_6", "prog_7","prog_8","prog_9","prog_10", "prog_11", "prog_12","prog_13","prog_14","prog_15", "prog_16", "prog_17","prog_18","prog_19","prog_20", */])


.put("genres_young", ["trap"])
.put("genres_midage", ["Lo-Fi"])
.put("genres_granny", ["lounge"])

.put("next_genre_selection", "prog_1") //era Lo-Fi
.put("next_genre", "prog_1")    //////// ho cambiato questo era in lounge
.put("genre", "prog_1")
.put("track", "piece_100")   ///////vuole 101 sempre presente per questo

/* STRUCTURE DEFAULT */
.put("next_structure", "strut_1")

/* INSTRUMENT SCRAMBLE */
.put("scrambled_instr_keys", Dictionary.new)

/* RILASCIO DEI SYNTH */
.put("release_time_add_drum", 0.5)
.put("release_time_mul_drum", 15)
.put("release_time_add_key", 0.3) // 0.3
.put("release_time_mul_key", 2.7) // 0.8

/* RECORDING */
.put("record_midi", false)

/* CONTROLS */
.put("scramble_instrs_enable", false)
.put("change_to_minor", false)
.put("chord_alteration", 0)
.put("chord_alteration_prob", 0.0)
.put("transpose_factor", 0)
.put("mod_fifth_enable", false)
.put("mod_diatonic_enable", false)
.put("mod_probability", 0.25)
.put("kdtree_search_X", 0.5)
.put("kdtree_search_Y", 0.5)
.put("kdtree_search_Z", 0.5)
.put("kdtree_index_of_neighbor", 0)
.put("dominanti_secondarie", false)
.put("alter_pad_key_notes", false)
.put("ritornello_velocity_incr", 0)
.put("drum_event_density", 0.6)
.put("bass_event_density", 0.6)
.put("key_event_density", 0.6)
.put("pad_event_density", 0.6)
.put("lead_event_density", 0.6)
.put("sampler_event_density", 0.6)
.put("lead_gen_types", [ "gen_lead_notes_randseed", "gen_lead_notes_arpeggio_ascendente", "gen_lead_notes_arpeggio_dicendente", "gen_lead_notes_nearest" ])
.put("lead_gen_type", "gen_lead_notes_randseed")
.put("no_chorus_genres", ["Lo-Fi"])
.put("minor_7th", false)
.put("major_3rd", false)

.put("drum_delay_8", false)
.put("drum_delay", false)

/* DENSITY OF INSTRUMENTS ( inverse of 1.0 -> (1.0 - density) ) */
.put("drum_event_density", 0.0)
.put("pad_event_density", 0.0)
.put("key_event_density", 0.0)
.put("lead_event_density", 0.0)
.put("sampler_event_density", 0.0)
.put("bass_event_density", 0.0)

/* UMANIZZAZIONE */
.put("generi_con_umanizzazione", ["lounge"])
.put("uman_minimo", 1e-8) // in ticks
.put("uman_massimo", 2.0)// in ticks

/* HARMONY */
.put("keys", Dictionary.new
	.put("C", 0)
	.put("Cs", 1)
	.put("Db", 1)
	.put("D", 2)
	.put("Ds", 3)
	.put("Eb", 3)
	.put("E", 4)
	.put("F", 5)
	.put("Fs", 6)
	.put("Gb", 6)
	.put("G", 7)
	.put("Gs", 8)
	.put("A", 9)
	.put("As", 10)
	.put("Bb", 10)
	.put("B", 11))
.put("scales", Dictionary.new
	.put("major", Scale.major.degrees)
	.put("minor", Scale.minor.degrees))
.put("grades", Dictionary.new
	.put("major", Dictionary.new
		.put("0", [[0, 4, 7]/*fondamentale*/, [0, 7]/*senza 3^*/, [0, 5, 7]/*4^*/])
		.put("1", [[2, 5, 9], [2, 9], [2, 7, 9]])
		.put("2", [[4, 7, 11],[4, 11],[4, 9, 11]])
		.put("3", [[0, 5, 9], [0, 5], [0, 5, 11]])
		.put("4", [[2, 7, 11],[2, 7], [0, 2, 7]])
		.put("5", [[0, 4, 9], [4, 9], [2, 4, 9]])
		.put("6", [[2, 5, 11],[5, 11],[4, 5, 11]]))
	.put("minor", Dictionary.new
		.put("0", [[0, 3, 7]/*fondamentale*/, [0, 7]/*senza 3^*/, [0, 5, 7]/*4^*/])
		.put("1", [[2, 5, 8], [2, 8], [2, 7, 8]])
		.put("2", [[3, 7, 10],[3, 10],[4, 8, 10]])
		.put("3", [[0, 5, 8], [0, 5], [0, 5, 10]])
		.put("4", [[2, 7, 10],[2, 7], [0, 2, 7]])
		.put("5", [[0, 3, 8], [4, 8], [2, 3, 8]])
		.put("6", [[2, 5, 10],[5, 10],[3, 5, 10]])))
.put("cadenze2",
	Dictionary.new
	//.put("Lo-Fi", ["54", "04", "40", "43", "25", "12", "30", "03", "05", "04", "40", "52"])
	.put("prog_1", [])
	.put("prog_2", [])
    .put("prog_3", [])
	.put("prog_4", [])
	.put("prog_5", [])
	.put("prog_6", [])
	.put("prog_7", [])
    .put("prog_8", [])
	.put("prog_9", [])
	.put("prog_10", [])
	.put("prog_11", [])
	.put("prog_12", [])
    .put("prog_13", [])
	.put("prog_14", [])
	.put("prog_15", [])
	.put("prog_16", [])
	.put("prog_17", [])
    .put("prog_18", [])
	.put("prog_19", [])
	.put("prog_20", [])




	.put("Lo-Fi", [])
	.put("lounge", ["54", "14", "04", "40", "20", "30", "43", "25", "44", "12", "30", "03", "33", "00", "04", "40", "52"])
	.put("trap", [])
	.put("synthwave", ["54", "04", "40", "43", "25", "12", "30", "03", "05", "04", "40", "52", "04", "15", "50", "50", "42"]) //levato 41
	.put("House", ["55", "00", "33", "54", "04", "40", "43", "25", "12", "30", "03", "05", "04", "40", "52", "04", "15", "50", "50", "42"])
	.put("Houseee", ["55", "00", "33", "54", "04", "40", "43", "25", "12", "30", "03", "05", "04", "40", "52", "04", "15", "50", "50", "42"])

)
.put("cadenze3",
	Dictionary.new
	//.put("Lo-Fi", ["030", "530", "034", "044", "340", "045", "043", "012", "540"])
	.put("prog_1", [])
	.put("prog_2", [])
    .put("prog_3", [])
	.put("prog_4", [])
	.put("prog_5", [])
	.put("prog_6", [])
	.put("prog_7", [])
    .put("prog_8", [])
	.put("prog_9", [])
	.put("prog_10", [])
	.put("prog_11", [])
	.put("prog_12", [])
    .put("prog_13", [])
	.put("prog_14", [])
	.put("prog_15", [])
	.put("prog_16", [])
	.put("prog_17", [])
    .put("prog_18", [])
	.put("prog_19", [])
	.put("prog_20", [])


	.put("Lo-Fi", [])
	.put("lounge", ["030", "530", "034", "044", "340", "015", "531", "053"])
	.put("trap", [])
	.put("synthwave", ["430", "524", "321", "340", "012", "210", "530", "453", "304"])
	.put("House", ["555", "000", "430", "524", "321", "340", "012", "210", "530", "453", "304"])
	.put("Houseee", ["555", "000", "430", "524", "321", "340", "012", "210", "530", "453", "304"])

)
.put("cadenze4", Dictionary.new
	//.put("Lo-Fi", ["0453" , "0530", "0534", "5210", "0520", "0250", "5310", "0234", "0413", "5453"])

	.put("prog_1", [])
	.put("prog_2", [])
    .put("prog_3", [])
	.put("prog_4", [])
	.put("prog_5", [])
	.put("prog_6", [])
	.put("prog_7", [])
    .put("prog_8", [])
	.put("prog_9", [])
	.put("prog_10", [])
	.put("prog_11", [])
	.put("prog_12", [])
    .put("prog_13", [])
	.put("prog_14", [])
	.put("prog_15", [])
	.put("prog_16", [])
	.put("prog_17", [])
    .put("prog_18", [])
	.put("prog_19", [])
	.put("prog_20", [])


	.put("Lo-Fi", [])
	.put("lounge", ["0453" , "0530", "0534", "5210", "0520", "0252", "5200", "1234", "3450", "4320", "0413", "4152"])
	.put("trap", [])
	.put("synthwave", ["5041", "0415", "4321", "3340", "5240", "3012", "3210", "5430", "1340", "0102", "0403" "3044" "5131" "1534" "5434" "5430" "5423" "5431"])
	.put("House", ["5555", "0000", "3333", "4321", "3340", "5240", "3012", "3210", "5430", "1340", "0102", "0403" "3044" "5131" "1534" "5434" "5430" "5423" "5431"])
	.put("Houseee", ["5555", "0000", "3333", "4321", "3340", "5240", "3012", "3210", "5430", "1340", "0102", "0403" "3044" "5131" "1534" "5434" "5430" "5423" "5431"])

)
//.put("generi_con_cadenza", ["House", "lounge", "Lo-Fi", "synthwave", "Houseee"])
.put("generi_con_cadenza", ["House", "lounge", "synthwave", "Houseee"])
.put("modalities", ["Lidio", "Ionico", "Misolidio", "Dorico", "Eolio ", "Frigio", "Locrio"])
.put("modalities_wrap", [3, 0, 4, 1, 5, 2, 6])
.put("modality", 0)


/* STRUCTURE */
.put("structure_id", 0)
.put("bass_enable", true)
.put("key_enable", true)
.put("pad_enable", true)
.put("lead_enable", true)
.put("sampler_enable", true)
.put("kick_enable", true)
.put("snare_enable", true)
.put("hat_enable", true)
.put("tom_enable", true)
.put("cymbal_enable", true)
.put("ride_enable", true)
.put("percussion_enable", true)
.put("fx_enable", true)
.put("enable_list", ["kick_enable", "snare_enable", "hat_enable", "tom_enable", "ride_enable", "cymbal_enable", "percussion_enable", "fx_enable", "pad_enable", "lead_enable", "bass_enable", "key_enable", "sampler_enable"])
.put("kick_note",   (["35", "36"]).collect({|note| note.asString}))
.put("snare_note",  (["37", "38", "39", "40", "41", "42", "43", "44", "75"]).collect({|note| note.asString}))
.put("hat_note",    (["46", "47", "48", "49", "50", "51", "52", "53", "54", "55", "56", "57", "58", "59"]).collect({|note| note.asString}))
.put("tom_note",    (["65", "66", "67", "68", "69", "70", "71", "72"]).collect({|note| note.asString}))
.put("cymbal_note", (["77", "78", "79", "80", "81", "82", "89", "90", "91", "92", "93", "94"]).collect({|note| note.asString}))
.put("ride_note",   (["45", "60", "61", "62", "63", "84", "85", "86", "87", "88"]).collect({|note| note.asString}))
.put("percussion_note",     (["64", "73", "74"]).collect({|note| note.asString}))
.put("fx_note",     (["76" "83", "84"]).collect({|note| note.asString}))
.put("bass_note", (0..127).collect({ | note | note.asString }))
.put("key_note", (0..127).collect({ | note | note.asString }))
.put("pad_note", (0..127).collect({ | note | note.asString }))
.put("lead_note", (0..127).collect({ | note | note.asString }))
.put("sampler_note", (0..127).collect({ | note | note.asString }))


.put("structure_id", 0)
.put("bass_enable", true)
.put("key_enable", true)
.put("pad_enable", true)
.put("lead_enable", true)
.put("sampler_enable", true)
.put("kick_enable", true)
.put("snare1_enable", true)
.put("snare2_enable", true)
.put("clap_enable", true)
.put("hh1closed_enable", true)
.put("hh2closed_enable", true)
.put("hh1open_enable", true)
.put("hh2open_enable", true)
.put("ride1_enable", true)
.put("ride2_enable", true)
.put("cymbal_enable", true)
.put("percussion1_enable", true)
.put("percussion2_enable", true)
.put("percussion3_enable", true)
.put("tom_enable", true)
.put("fx_enable", true)

.put("enable_list", ["kick_enable", "snare1_enable", "snare2_enable", "clap_enable", "hh1closed_enable", "hh2closed_enable", "hh1open_enable", "hh2open_enable", "ride1_enable", "ride2_enable", "cymbal_enable", "percussion1_enable", "percussion2_enable", "percussion3_enable", "tom_enable", "fx_enable", "pad_enable", "lead_enable", "bass_enable", "key_enable", "sampler_enable"])
//.put("enable_prob", [   0.85,                   0.85,                   0.85,                   0.85,                        0.85,                         0.85,                         0.85,                       0.85,                  0.85,                   0.85,                   0.85,                         0.85,                           0.85,                             0.85,                      0.85,                0.85,              0.85,             0.85,                 0.85,                 0.85,                   0.85           ])
.put("enable_prob", 1 ! 21)

.put("kick_note", ["35", "36"])
.put("snare1_note", ["37", "38", "39"])
.put("snare2_note", ["40", "41", "42"])
.put("clap_note", ["43", "44", "45"])
.put("hh1closed_note", ["46", "47", "48"])
.put("hh2closed_note", ["49", "50", "51"])
.put("hh1open_note", ["52", "53", "54"])
.put("hh2open_note", ["55", "56", "57"])
.put("ride1_note", ["58", "59", "60"])
.put("ride2_note", ["61", "62", "63"])
.put("cymbal_note", ["64", "65", "66"])
.put("percussion1_note", ["67", "68"])
.put("percussion2_note", ["69", "70"])
.put("percussion3_note", ["71", "72"])
.put("tom_note", ["73", "74", "75"])
.put("fx_note", ["76", "77", "78"])
.put("bass_note", (0..127).collect({ | note | note.asString }))
.put("key_note", (0..127).collect({ | note | note.asString }))
.put("pad_note", (0..127).collect({ | note | note.asString }))
.put("lead_note", (0..127).collect({ | note | note.asString }))
.put("sampler_note", (0..127).collect({ | note | note.asString }))

/* IMPLEMENTAZIONE PRESENTAZIONE */
.put("struttura_forzata", false)

/* IMPLEMENTAZIONE WOW */
.put("WOW", false)
.put("wow_structure_length", 4)
.put("wow_fade_out", 8)

.put("wow_atmos_debounce_time_seconds", 60)

.put("kick_vel_scale", 1.0)
.put("drum_vel_scale", 1.0)
.put("pad_vel_scale", 1.0)
.put("key_vel_scale", 1.0)
.put("sampler_vel_scale", 1.0)
.put("lead_vel_scale", 1.0)
.put("bass_vel_scale", 1.0)

.put("kick_threshold", 0.2)
.put("bass_threshold", 0.3)
.put("pad_threshold", 0.0)
.put("key_threshold", 0.4)
.put("drum_threshold", 0.5)
.put("sampler_threshold", 0.6)
.put("lead_threshold", 0.7)

.put("soglia_fermo", [0, 24])
.put("soglia_piano", [25, 50])
.put("soglia_veloce", [51, 100])


.put("kick_up", false)
.put("drum_up", false)
.put("pad_up", false)
.put("key_up", false)
.put("sampler_up", false)
.put("lead_up", false)
.put("bass_up", false)

.put("kick_down", false)
.put("drum_down", false)
.put("pad_down", false)
.put("key_down", false)
.put("sampler_down", false)
.put("lead_down", false)
.put("bass_down", false)

.put("speed_scale", 0.025)
.put("wow_speed", 0)
.put("wow_ramp_start_up", 12)
.put("wow_ramp_start_down", 96 * 4)


/* OSC NORMALE */
.put("max_eventi_verticale", 10)


/* MIXER */
.put("out_channels", Dictionary.new
	.put("bass", 20)
	.put("drum", 22)
	.put("key", 24)
	.put("lead", 26)
	.put("pad", 28)
	.put("sampler", 30))
.put("master_input", 40)
.put("master_output", 0)
// SENZA EFFETTISTICA:
/*
.put("out_channels", Dictionary.new
	.put("bass", 0)
	.put("drum", 0)
	.put("key", 0)
	.put("lead", 0)
	.put("pad", 0)
	.put("sampler", 0))
.put("master_input", 40)
.put("master_output", 50)
*/

/* OTHER */
.put("convfftsize", 2048)


/* ATMOS */
.put("atmos_volume", -20) // dB

/* TRANSITIONS */
.put("transition_bar_length", 3)
.put("transition_default_bpm", 90)
.put("transition_volume", -9) // dB


/* ADS */
.put("ads_counter", 0)
.put("ads_rate", 60) // in secondi
.put("ads_volume", 6) // dB
.put("time_since_last_ad", Main.elapsedTime.ceil)

/* MASTER CLOCK */
.put("clock", TempoClock(1, 4, queueSize: 4096).permanent_(true))
.put("clock_change_perc", 0)

/* CONTROL SPECS */
.put("freq_spec", ControlSpec(20.0, 20000, 'exp'))
.put("gain_spec", ControlSpec(-1, 4.0, 'lin'))
.put("q_spec", ControlSpec(0.1,1.0, 'exp'))
.put("thd_spec", ControlSpec(0.001, 0.75, 'lin'))
.put("comp_sa_spec", ControlSpec(0.5, 0.0001, 'lin'))
.put("comp_sb_spec", ControlSpec(1, 0.1, 'lin'))
.put("comp_atk_spec", ControlSpec(0.0001, 0.3, 'exp'))
.put("comp_rel_spec", ControlSpec(0.0001, 0.3, 'exp'))
.put("rev_w_spec", ControlSpec(0.0001, 1.0, 'exp'))
.put("rev_r_spec", ControlSpec(0.0001, 1.0, 'lin'))
.put("rev_d_spec", ControlSpec(0.0001, 1.0, 'exp'))
.put("pan_spec", ControlSpec(-1.0, 1.0, 'lin'))
.put("gain_out_spec", ControlSpec(-64.0, 12.0, 'lin'))

/* BUSSES AND GROUPS */
.put("efx_group", Group.new(s, addAction: 'addToTail'))

/* DEBUG FLAG */
.put("debug", false)

//.put("genre_popup", PopUpMenu())

/* VARIABILI ESTERNE DA API */
.put("api_info", Dictionary.new
	.put("num_tracks", 21)
	.put("weather", "Sunny") // che tempo fa?
	.put("num_people_vec", {0} ! 8)
	.put("num_people", 0) // quante persone ci sono nella stanza?
	.put("gender_vec", {0} ! 15)
	.put("gender_mean", 0) // mediamente di che sesso sono?
	.put("gender_std", 0) // deviazione standard del sesso
	.put("age_vec", {0} ! 15)
	.put("age_mean", 40) // mediamemte di che età sono?
	.put("age_std", 4) // deviazione standard dell'età
	.put("track_positions", {{[Point(0, 0), 0]} ! 10} ! 21 )
)


/* VARIABILI DISTANZIAMENTO SOCIALE */
.put("social_distance_violated", false)
.put("social_sine_amplitude", 0.025)

// FINE AGGIUNTA ELEMENTI A ~v
;


/* LEGGO FILE ARMONIA SUI DIZIONARI */
~tmpfile = File.open(~v["harmony_folder"] ++ "rivolti.txt", "r");
~filecontent = ~tmpfile.readAllString.interpret;

~v.put("rivolti", Dictionary.new.put("minor", Dictionary.new).put("major", Dictionary.new));
~v.at("scales").at("major").size.do({ | grade |
	//~v.at("rivolti").at("major").put(grade.asString, Dictionary.new);
	~filecontent.do({ | vec |
		var tmp;
		tmp = vec[1..3].collect({ | notes |
			notes.collect({ | note |
				~v.at("scales").at("major").wrapAt(~v.at("scales").at("major").find([note]) + grade);
		}).sort;
		});
		~v.at("rivolti").at("major").put(grade.asString + vec[0], tmp);
	});
});
~tmpfile.close;

~v.put("progressioni",  Dictionary.new.put("major", Dictionary.new));
~tmpfile = File.open(~v["harmony_folder"] ++ "progressioni.txt", "r");
~tmpfile.readAllString.interpret.do({ | vec |
	~v.at("progressioni").at("major").put(vec[0][0].asString ++ vec[0][1].asString ++ vec[0][2].asString, [vec[1], vec[2]]);
});
~tmpfile.close;

~v.put("chord_change",  Dictionary.new.put("major", Dictionary.new));
~tmpfile = File.open(~v["harmony_folder"] ++ "chord_change.txt", "r");
~tmpfile.readAllString.interpret.do({ | vec |
	~v.at("chord_change").at("major").put(vec[0], vec[1]);
});
~tmpfile.close;

~v.put("enrich_chord",  Dictionary.new.put("major", Dictionary.new));
~tmpfile = File.open(~v["harmony_folder"] ++ "enrich_chord.txt", "r");
~tmpfile.readAllString.interpret.do({ | vec |
	~v.at("enrich_chord").at("major").put(vec[0], vec[1]);
});
~tmpfile.close;

/* LEGGI STRUTTURE */

~v.put("structures", Dictionary.new);
~tmpdir = ~v["structure_folder"];
PathName(~tmpdir).folders.do({ | folder |
	var genre = folder.folderName;
	~v["structures"].put(genre, []);
	folder.filesDo({ | file |
		if(file.extension == "txt", {
			~v["structures"].put(genre, ~v["structures"][genre] ++ [file.fileNameWithoutExtension]);
		});
	});
});

~v.put("playerSynthDictHardCopy", Ref(Dictionary.new));
~v.put("playerNoteOnDictHardCopy", Ref(Dictionary.new));

127.do({ | id | ~v["playerSynthDictHardCopy"].value.put(id.asString, []);  ~v["playerNoteOnDictHardCopy"].value.put(id.asString, []);  });
