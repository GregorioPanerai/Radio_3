~f

/*
\section{Lettura dei database}
\subsection{Lettura del database campioni}
\begin{verbatim}
*/
.put("read_sampleDB_v2", {
	var root = PathName(~v.at("sampleDB_folder")); // root del database
	root.folders.do({ | genreFolder |
		var genre = genreFolder.folderName.asString;
		~v["sampleDB"].put(genre, Dictionary.new); // Inserisco livello genere
		genreFolder.folders.do({ | typeFolder |
			var type = typeFolder.folderName.asString;
			~v["sampleDB"][genre].put(type, Dictionary.new); // Inserisco livello tipo strumento
			typeFolder.folders.do({ | instrFolder |
				var instr = instrFolder.folderName.asString; // trovo il nome dello strumento
				~v["sampleDB"][genre][type].put(instr, Dictionary.new); // aggiungo al DB il livello singolo strumento
				instrFolder.files.collect({|file, index|
					if( ( file.extension == "wav" ) || ( file.extension == "aiff" ) || ( file.extension == "aif" ), { // leggo solo file .wav, .aif o .aiff
						~v["sampleDB"][genre][type][instr].put(  file.fileNameWithoutExtension.asString, file.asAbsolutePath  );
					});
				});
			});
		});

		if( genre == "ads", { // Gli ads vengono gestiti separatamente rispetto agli altri campioni
			genreFolder.files.do({ | ads_file |
				~v["sampleDB"][genre].put(  ads_file.fileNameWithoutExtension.asString, ads_file.asAbsolutePath  );
			});
		});
	});
})
/*
\subsection{Lettura del database MIDI}
*/

.put("read_midiDB", {
	PathName(~v.at("midiDB_folder")).folders.do( { | genreFolder |
		var genre = genreFolder.folderName.asString;
		// Aggiungo il livello del genere
		~v["midiDB"].put(genre, Dictionary.new);
		// Aggiungo nel livello del genere i vari tipi di strumento
		["bass", "drum", "pad", "key", "lead", "sampler"].do({ | type |
			~v["midiDB"][genre].put(type, Dictionary.new);
		});
		// Itero i brani presenti all'interno del genere
		genreFolder.folders.do({ | pieceFolder, pieceID |
			// Nome del brano
			var piece = pieceFolder.folderName.asString;
			// Feature e MetaData
			var eot, tempo, division, scale, key, timeSignature, chords = [];
			// Per prima cosa trovo leggo il file pad_*, che contiene le informazioni di tonalità ed accordi
			pieceFolder.filesDo({|instrMIDIFile |
				if((instrMIDIFile.extension == "mid") && instrMIDIFile.fileNameWithoutExtension.contains("pad"), {
					// Counter per n_events e avg_velocity
					var nevents=0, avg_vel=0, avg_vel_counter=0, events, noteOn_counter=0, noteOnSum=0;
					// Nome del file
					var fileName = instrMIDIFile.fileNameWithoutExtension.asString.postln; // ************************************QUESTO è PAD 33
					// Tipo di strumento (prima parola del nome del file separato dal carattere "_")
					var type = fileName.split($_)[0];
					// MIDI raw data
					var midi = SimpleMIDIFile.read(instrMIDIFile.asAbsolutePath);

					var division_change_ratio = (midi.division / ~v["tpqn"]);
					midi.timeMode = \ticks;
					midi.midiEvents = midi.midiEvents.collect({ | event | event[1] = (event[1] / division_change_ratio).asInteger; event });
					midi.division = ~v["tpqn"];

					midi.convertNoteOns(0);
					midi.correctTempoEvents(true, true);
				//midi.division.postln;
					// Cambio la timeMode del  file MIDI in ticks
                  midi.metaEvents.postln;   //MESSO IO
					// Trova metadati
					//eot =  midi.endOfTrack[0][1];
					eot = ~v["average_8bar_dur"];
					tempo =  midi.getTempo;
				tempo .postln;   /////// ci sa il tempo!!!!
					division = midi.division;
					timeSignature = midi.timeSignatures[0][1][0].asSymbol.asInteger;
//timeSignature.postln;
					midi.metaEvents.do({ | metaEvent |
						// Trova key e scale
						if((metaEvent[2].asString == "keySignature"), {
							key = metaEvent[3];
							if(key[1].asInteger == 0, { scale = "major"; }, { scale = "minor"; });
							key = ~f["keySig2Fund"].value(key);
						});
						// Trova gli accordi
						if(metaEvent[2] == \text, {
							chords = chords ++ [[(metaEvent[1].asInteger / division_change_ratio).asInteger, (metaEvent[3].split($ )[0].asInteger - 1).asString ++ " " ++ metaEvent[3].split($ )[1]]];
						});
					});
					// Trova le progressioni
					chords = chords.collect({ | chord, chordID |
						chord ++ [chords.wrapAt(chordID-1)[1][0].asString ++ chord[1][0].asString ++ chords.wrapAt(chordID+1)[1][0].asString];
					});

					// Trova i noteOn e noteOff
					events = midi.noteEvents;
					events = events.collect({|event, event_id|
						var next_note_tick_diff = ~v["tpqn"] * 4;
						if(event[2] == \noteOn, {
							nevents = nevents + 1;
							noteOnSum = noteOnSum + event[4].asInteger;
							noteOn_counter = noteOn_counter + 1;
							avg_vel = avg_vel + event[5].asInteger;
							avg_vel_counter = avg_vel_counter + 1;
						});
						if(event[2] == \noteOff, { // Trova la distanza tra noteOff e next noteOn della stessa nota (max 6 eventi in avanti)
							block { | break |
								16.do({ | id |
									id = id + 1;
									if( events.wrapAt(event_id + id)[4] == event[4], { next_note_tick_diff = (events.wrapAt(event_id + id)[1] -  event[1]).abs;  break.value; });
								});
							};
						});
						next_note_tick_diff = (next_note_tick_diff.abs.clip(0, ~v["tpqn"] * 8) * ~v["release_time_mul_key"] / (~v["tpqn"] * 8)) + ~v["release_time_add_key"];
						if( (genre == "trap") || (genre == "House"), { next_note_tick_diff = next_note_tick_diff / 3 });
						//"\t".post; next_note_tick_diff.postln
						if(event[2] == \noteOn, {
							[event[1], event[2], ~f["transpose"].value(event[4], key.neg).asInteger,  event[5], next_note_tick_diff];
						}, {
							[event[1], event[2], ~f["transpose"].value(event[4], key.neg).asInteger,  event[5], next_note_tick_diff];
						});
					});
					avg_vel = avg_vel / avg_vel_counter;

					// Se ancora \noteOn con velocity=0, convertili in \noteOff
					events.do({  | event_0, event_0_id |
						if( (event_0[1] == \noteOn) && (event_0[3].asInteger == 0), {
							//var new_event = [ event_0[0], \noteOff, event_0[2], event_0[3], event_0[4] ];
							//events[event_0_id] = new_event;
							events[event_0_id][1] = \noteOff;
						});
					});

					// ELIMINA ERRORI noteOn prima noteOff in stesso tick
					events.collect({  | event_0, event_0_id |
						events[event_0_id..].collect({ |  event_02, event2_id |
							event2_id = event2_id + event_0_id;
							if( event_0[0] == event_02[0], { // Stesso tick?
								if( event_0[2] == event_02[2], { // Stessa nota?
									//[event[1], event_02[1]].postln;
									if( (event_0[1] == \noteOn) && (event_02[1] == \noteOff), { // Prima noteOn e poi noteOff?
										//"Same note in same tick with error".postln;
										//[event_id, event2_id].postln;
										events[event_0_id][1] = \noteOff;
										events[event2_id][1] = \noteOn;
									});

								});
							});
						});
					});

					// INSERISCI DURATA IN TICK DELLE NOTE AL POSTO DI noteOn/noteOff (mantenendo i noteOff al momento)
					events.do({ | event, event_ID |
						if( event[1] == \noteOn, {
							block{ | break |
								events[(event_ID+1)..].do({ | next_event, next_event_ID |
									if( (event[2] == next_event[2]) && (next_event[1] == \noteOff), {
										events[event_ID] = event ++ ( next_event[0] - event[0] );
										break.value;
									});
								});
							};
						});
					});

					// RIMUOVI EVENTI DUPLICATI
					20.do({
						events[0..(events.size-2)].do({ | event, event_ID |
							block{ | break |
								if( event == events[event_ID + 1], { events.removeAt(event_ID); break.value; });
							};
						});
					});

					// Inserisci nel database
					~v["midiDB"][genre][type].put(pieceID.asString, Dictionary.new
						.put("instr", fileName)
						.put("notes", events)
						.put("chords", chords)
						.put("eot", eot)
						.put("tempo", tempo)
						.put("division", division)
						.put("timeSignature", timeSignature)
						.put("scale", scale)
						.put("nevents", nevents)
						.put("avg_vel", avg_vel)
						.put("nchords", chords.size)
						.put("avg_pitch", noteOnSum / noteOn_counter)
						.put("num_recalls", 0)
					);
					// Post per il debug
					if(~v.at("debug") && true, {
						("\t\t\tPiece: "++piece).postln;
						("\tFile: "++fileName).postln;
					});
				});
			});



			// Itero gli altri file midi presenti all'interno del brano
			pieceFolder.filesDo({|instrMIDIFile |
				if((instrMIDIFile.extension == "mid") && instrMIDIFile.fileNameWithoutExtension.contains("pad").not, {
					// Variabili per variazioni
					var n_variations, nnotes;
					// Counter per n_events e avg_velocity
					var nevents=0, avg_vel=0, avg_vel_counter=0, events, noteOn_counter=0, noteOnSum=0;
					// Nome del file
					var fileName = instrMIDIFile.fileNameWithoutExtension.asString;
					// Tipo di strumento (prima parola del nome del file separato dal carattere "_")
					var type = fileName.split($_)[0];
					// MIDI raw data
					var midi = SimpleMIDIFile.read(instrMIDIFile.asAbsolutePath);
					// Cambio la timeMode del  file MIDI in ticks
					midi.timeMode = \ticks;
					midi.midiEvents = midi.midiEvents.collect({ | event | event[1] = (event[1] / (midi.division / ~v["tpqn"])).asInteger; event });
					midi.division = ~v["tpqn"];
					// Trova metadati
					//eot =  midi.endOfTrack[0][1];
					eot = ~v["average_8bar_dur"];
					// Trova i noteOn e noteOff
					events = midi.noteEvents;
					events = events.collect({|event, event_id|
						var next_note_tick_diff = ~v["tpqn"] * 4; // default max a 1920 tick
						if(event[2] == \noteOn, {
							nevents = nevents + 1;
							noteOnSum = noteOnSum + event[4].asInteger;
							noteOn_counter = noteOn_counter + 1;
							avg_vel = avg_vel + event[5].asInteger;
							avg_vel_counter = avg_vel_counter + 1;
						});
						if(event[2] == \noteOff, { // Trova la distanza tra noteOff e next noteOn della stessa nota (max 6 eventi in avanti)
							block { | break |
								16.do({ | id |
									id = id + 1;
									if( events.wrapAt(event_id + id)[4] == event[4], { next_note_tick_diff = (events.wrapAt(event_id + id)[1] -  event[1]); break.value; });
								});
							};
						});
						if(fileName.contains("drum"), {
							next_note_tick_diff = (next_note_tick_diff.abs.clip(0, ~v["tpqn"] * 8) * ~v["release_time_mul_drum"] / (~v["tpqn"] * 8)) + ~v["release_time_add_drum"];
							next_note_tick_diff = next_note_tick_diff.clip(0, 4.0);
						}, {
							next_note_tick_diff = (next_note_tick_diff.abs.clip(0, ~v["tpqn"] * 8) * ~v["release_time_mul_key"] / (~v["tpqn"] * 8)) + ~v["release_time_add_key"];
							if( (genre == "House") && fileName.contains("bass").not, { next_note_tick_diff = next_note_tick_diff / 3.5 });
						});
						if(fileName.contains("bass"), {
							next_note_tick_diff = next_note_tick_diff / 7;
						});
						if( (genre == "trap") && fileName.contains("bass"), { next_note_tick_diff = next_note_tick_diff * 3; });
						if( (genre == "synthwave") && fileName.contains("pad"), { next_note_tick_diff = next_note_tick_diff * 2; });
						if( (genre == "synthwave") && fileName.contains("sampler"), { next_note_tick_diff = next_note_tick_diff / 4; });
						if( (genre == "synthwave") && fileName.contains("key"), { next_note_tick_diff = next_note_tick_diff / 15;});
						if( (genre == "synthwave") && fileName.contains("lead"), { next_note_tick_diff = next_note_tick_diff / 6;});

						("" ++ next_note_tick_diff ++ "\t").post;
						// Se drum non traspongo, altrimenti si
						if( instrMIDIFile.fileNameWithoutExtension.contains("drum").not, {
							if(event[2] == \noteOn, {
								[event[1], event[2], ~f["transpose"].value(event[4], key.neg).asInteger,  event[5], next_note_tick_diff];
							}, {
								[event[1], event[2], ~f["transpose"].value(event[4], key.neg).asInteger,  event[5], next_note_tick_diff];
							});
						}, {
							if(event[2] == \noteOn, {
								[event[1], event[2], event[4].asInteger,  event[5], next_note_tick_diff];
							}, {
								[event[1], event[2], event[4].asInteger,  event[5], next_note_tick_diff];
							});
						});
					});
					avg_vel = avg_vel / avg_vel_counter;

					// Se ancora \noteOn con velocity=0, convertili in \noteOff
					events.do({  | event_0, event_0_id |
						if( (event_0[1] == \noteOn) && (event_0[3].asInteger == 0), {
							//var new_event = [ event_0[0], \noteOff, event_0[2], event_0[3], event_0[4] ];
							//events[event_0_id] = new_event;
							events[event_0_id][1] = \noteOff;
						});
					});

					// ELIMINA ERRORI noteOn prima noteOff in stesso tick
					events.collect({  | event_0, event_0_id |
						events[event_0_id..].collect({ |  event_02, event2_id |
							event2_id = event2_id + event_0_id;
							if( event_0[0] == event_02[0], { // Stesso tick?
								if( event_0[2] == event_02[2], { // Stessa nota?
									//[event[1], event_02[1]].postln;
									if( (event_0[1] == \noteOn) && (event_02[1] == \noteOff), { // Prima noteOn e poi noteOff?
										//"Same note in same tick with error".postln;
										//[event_id, event2_id].postln;
										events[event_0_id][1] = \noteOff;
										events[event2_id][1] = \noteOn;
									});

								});
							});
						});
					});

					// INSERISCI DURATA IN TICK DELLE NOTE AL POSTO DI noteOn/noteOff (mantenendo i noteOff al momento)
					events.do({ | event, event_ID |
						if( event[1] == \noteOn, {
							block{ | break |
								events[(event_ID+1)..].do({ | next_event, next_event_ID |
									if( (event[2] == next_event[2]) && (next_event[1] == \noteOff), {
										events[event_ID] = event ++ ( next_event[0] - event[0] );
										break.value;
									});
								});
							};
						});
					});

					// RIMUOVI EVENTI DUPLICATI
					20.do({
						events[0..(events.size-2)].do({ | event, event_ID |
							block{ | break |
								if( event == events[event_ID + 1], { events.removeAt(event_ID); break.value; });
							};
						});
					});

					/* QUI DIVIDI LE NOTE PER VARIAZIONI */
					n_variations = (events.last[0].roundUp(3072) / 3072).asInteger;
					nnotes = {[]} ! n_variations;
					events.do({ | event, event_id |
						var variation_id = (event[0] / 3072).asInteger;
						if( ((event[0] % 3072) == 0) && (event[1] == \noteOff) && (variation_id > 0), {variation_id = variation_id - 1});
						event[0] = event[0] - ( variation_id * 3072 );
						nnotes[variation_id] = nnotes[variation_id].add( event );
					});

					// Inserisci nel database
					~v["midiDB"][genre][type].put(pieceID.asString, Dictionary.new
						.put("instr", fileName)
						.put("notes", nnotes[0])
						.put("variations", nnotes)
						.put("chords", chords)
						.put("eot", eot)
						.put("tempo", tempo)
						.put("division", division)
						.put("timeSignature", timeSignature)
						.put("scale", scale)
						.put("nevents", nevents)
						.put("avg_vel", avg_vel)
						.put("nchords", chords.size)
						.put("avg_pitch", noteOnSum / noteOn_counter)
						.put("num_recalls", 0)
					);
					// Post per il debug
					if(~v.at("debug") && false, {
						("\t\t\tPiece: "++piece).postln;
						("\tFile: "++fileName).postln;
					});

				});

			});
		});
	});
})

.put("generate_midi_combinations", {
	~v["midi_combinations"] = Dictionary.new;
	~v["midiDB"].keysDo({ | genre, genre_id |
		~v["midi_combinations"].put(genre, Dictionary.new);
		~v["midi_combinations"][genre].put("combinations", ~v["midiDB"][genre]["pad"].keys.collect({ | pad |
			~v["midiDB"][genre]["key"].keys.collect({ | key |
				~v["midiDB"][genre]["drum"].keys.collect({ | drum |
					[pad, key, drum ];
				}).asArray;
			}).asArray;
		}).asArray.flatten(2).scramble;
		);
		~v["midi_combinations"][genre].put("combination_id", (~v["midi_combinations"][genre]["combinations"].size - 1).rand);
	});
})

//~v["midi_combinations"][2]

/*
\subsection{Lettura del database convoluzioni}
\begin{verbatim}
*/

.put("read_convDB", { | convDB_folder |
	var root = PathName(~v.at("convDB_folder")); // root del database
	root.folders.do({ | folder1 |
		folder1.filesDo({ | ir |
			var bufsize, irspec, irbuf = Buffer.readChannel(s, ir.asAbsolutePath, action: {
				bufsize = PartConv.calcBufSize(~v.at("convfftsize"), irbuf);
				irspec = Buffer.alloc(s, bufsize, 1);
				irspec.preparePartConv(irbuf, ~v.at("convfftsize"));
				~v.at("convDB").put(ir.fileNameWithoutExtension, irspec);
			});
		});
	});
})


/*
\subsection{Creazione degli spazi N-dimensionali mediante kdtree}
\begin{verbatim}
*/
.put("create_kd_trees", {
	~v["kd_trees"] = Dictionary.new;
	// Creo un KDTree per ogni strumento di ogni genere
	~v["midiDB"].keys.do({ | genre |
		var kdtree_data, normalized_data;
		~v["kd_trees"][genre] = Dictionary.new;
		~v["midiDB"][genre].keysValuesDo({ | instr, dict |
			kdtree_data = ~v["midiDB"][genre][instr].keys.as(Array).collect({ | track |
				[ dict[track]["avg_pitch"],  dict[track]["nevents"], dict[track]["nchords"], track ];
				//[ dict[track]["nchords"],  dict[track]["nevents"], track ];
			});
			kdtree_data = kdtree_data.flop;
			normalized_data = kdtree_data[0..2].collect({ | data | data.normalize });
			(kdtree_data.size-1).do({ | feature_id | kdtree_data[feature_id] = normalized_data[feature_id]; });
			kdtree_data = kdtree_data.flop;
			~v["kd_trees"][genre][instr] = KDTree(array: kdtree_data, lastIsLabel: true);
		});
	});
})

/*
\section{Composizione assistita}

\subsection{Da MIDI key a indice di modulazione}
\begin{verbatim}
*/
.put("keySig2Fund", { | keySignature |
	var result = nil;
	if(keySignature[1] == 0, { // se la scala è maggiore
		if(keySignature[0] == 0, {result = 0}); // Cmaj
		if(keySignature[0] == 1, {result = -5}); // Gmaj
		if(keySignature[0] == 2, {result = 2}); // Dmaj
		if(keySignature[0] == 3, {result = -3}); // Amaj
		if(keySignature[0] == 4, {result = 4}); // Emaj
		if(keySignature[0] == 5, {result = -1}); // Bmaj
		if(keySignature[0] == 6, {result = 6}); // F#maj
		if(keySignature[0] == 7, {result = 1}); // C#maj
		if(keySignature[0] == -1, {result = 5}); // Fmaj
		if(keySignature[0] == -2, {result = -2}); // Bbmaj
		if(keySignature[0] == -3, {result = 3}); // Ebmaj
		if(keySignature[0] == -4, {result = -4}); // Abmaj
		if(keySignature[0] == -5, {result = 1}); // Dbmaj
		if(keySignature[0] == -6, {result = -6}); // Gbmaj
		if(keySignature[0] == -7, {result = -1}); // Cbmaj
	}, { // se la scala è minore
		if(keySignature[0] == 0, {result = -3}); // Amin
		if(keySignature[0] == 1, {result = 4}); // Emin
		if(keySignature[0] == 2, {result = -1}); // Bmin
		if(keySignature[0] == 3, {result = 6}); // F#min
		if(keySignature[0] == 4, {result = 1}); // C#min
		if(keySignature[0] == 5, {result = -4}); // G#min
		if(keySignature[0] == 6, {result = 3}); // D#min
		if(keySignature[0] == 7, {result = -2}); // A#min
		if(keySignature[0] == -1, {result = 2}); // Dmin
		if(keySignature[0] == -2, {result = -5}); // Gmin
		if(keySignature[0] == -3, {result = 0}); // Cmin
		if(keySignature[0] == -4, {result = 4}); // Fmin
		if(keySignature[0] == -5, {result = -2}); // Bbmin
		if(keySignature[0] == -6, {result = 3}); // Ebmin
		if(keySignature[0] == -7, {result = -4}); // Abmin
	});
	if(result == nil, {"NO KEY FOUND IN MIDI FILE!!!!!!".postln});
	result
})

/*
\subsection{Correzione \\noteOn prima di \\noteOff}
\begin{verbatim}
*/
// ELIMINA ERRORI noteOn prima noteOff in stesso tick
.put("correct_noteOff", { | events |
	events.collect({  | event_0, event_0_id |
		events[event_0_id..].collect({ |  event_02, event2_id |
			event2_id = event2_id + event_0_id;
			if( event_0[0] == event_02[0], { // Stesso tick?
				if( event_0[2] == event_02[2], { // Stessa nota?
					//[event[1], event_02[1]].postln;
					if( (event_0[1] == \noteOn) && (event_02[1] == \noteOff), { // Prima noteOn e poi noteOff?
						//"Same note in same tick with error".postln;
						//[event_id, event2_id].postln;
						events[event_0_id][1] = \noteOff;
						events[event2_id][1] = \noteOn;
					});

				});
			});
		});
	});
	events
})

/*
\subsection{Cambio da modo maggiore a modo minore}
\begin{verbatim}
*/
.put("MajorToMinor", { | note |
	var newNote;
	var bias = (note / 12).asInteger;
	var note12 = note % 12;
	if(note12 == 4, {note12 = 3});
	if(note12 == 9, {note12 = 8});
	if(note12 == 11, {note12 = 10});
	newNote = note12 + (bias * 12);
	newNote
})

/*
\subsection{Trasposizione di singola nota}
\begin{verbatim}
*/
.put("transpose", { | pitch, semitones |
	var result, bias, note_no_bias;
	bias = (pitch / 12).trunc;
	note_no_bias = pitch % 12;
	semitones = semitones.asInteger;
	result = (note_no_bias + semitones);// % 12;
	result = result + (bias * 12);
	result.copy.asString;
})

/*
\subsection{Trasposizione di sequenza di note}
\begin{verbatim}
*/
.put("transpose_notes", { | notes, semitones |
	var result, bias, note_no_bias;
	var new_notes = notes.deepCopy;
	new_notes = new_notes.collect({ | note |
		note[2] = if(~v["change_to_minor"], { ~f["MajorToMinor"].value(note[2]) }, { note[2] });
		note[2] = note[2] + semitones;
		note
	});
})

/*
\subsection{Cambio progressione di accordi}
Attualmente solamente sul modo maggiore
\begin{verbatim}
*/
.put("change_chords", { | chords, num_alterations=1, imposta_cadenza=true, genre="prog_1" |
	var new_chords = chords.deepCopy;
	var cambi_grado = [];
	var cambi_grado_prob = 0.25;
	var cadenza;
	var chord_size = new_chords.size;
	var pp = [];
	while( {(chord_size.isPrime.not && (chord_size != 1)) || (chord_size > 7)} ) {
		var sq = 1000;
		while( {sq >= chord_size} ) {sq = [2, 3, 4].choose; };
		chord_size = chord_size - sq;
		pp = pp ++ [sq.asString];
	};
	if( chord_size == 5, { pp = pp ++ ["3", "2"] });
	if( chord_size == 7, { pp = pp ++ ["3", "4"] });
	if( chord_size == 3, { pp = pp ++ ["3"] });
	if( chord_size == 2, { pp = pp ++ ["2"] });

	if( genre != "House", {
		5.do({
			block{ | break |
				var indexes = pp.findAll(["2"]);
				if( indexes.size > 2, {
					pp.removeAt(indexes[0]);
					pp.removeAt(indexes[1] - 1); // tolgo 1 per il resize del vettore causato da .removeAt
				});
			};
		});
		pp = pp.scramble;
	});


	pp.postln;   ////////COSA è
	if( genre != "House", {
		cadenza = pp.collect({ | ppp | ppp.class.postln; if( ppp == "3", { ~v["cadenze3"][genre].choose }, { if( ppp == "2", { ~v["cadenze2"][genre].choose }, { if( ppp == "4", { ~v["cadenze4"][genre].choose }) }) }); }).join("");
	}, {
		var cadenza2 = ~v["cadenze2"][genre].choose;
		var cadenza3 = ~v["cadenze3"][genre].choose;
		var cadenza4 = ~v["cadenze4"][genre].choose;
		cadenza = pp.collect({ | ppp | ppp.class.postln; if( ppp == "3", { cadenza3 }, { if( ppp == "2", { cadenza2 }, { if( ppp == "4", { cadenza4 }) }) }); }).join("");

	});
	//cadenza.postln;   //******************************POST CADENZA

	// IMPOSIZIONE DI CADENZE:
	if( imposta_cadenza && (~v["generi_con_cadenza"].find([genre]) != nil), {
		new_chords.wrapAt(new_chords.size - cadenza.size)[2][2] = cadenza[0];
		cadenza.do({ | accordo, accordo_id |
			var indice_da_cambiare = (chords.size + 1) - (cadenza.size - accordo_id);
			var stringa_accordo = accordo ++ " " ++ chords.wrapAt(indice_da_cambiare)[1].split($ )[1]; // Non cambia il rivolto
			var stringa_progressione = new_chords.wrapAt(indice_da_cambiare)[2];
			stringa_progressione[1] = accordo;
			if(accordo_id == 0, { stringa_progressione[2] = cadenza.wrapAt(accordo_id + 1); });
			if(accordo_id == (cadenza.size - 1), { stringa_progressione[0] = cadenza.wrapAt(accordo_id - 1); });
			if((accordo_id == 0).not && (accordo_id == (cadenza.size - 1)).not, { stringa_progressione[0] = cadenza.wrapAt(accordo_id - 1); stringa_progressione[2] = cadenza.wrapAt(accordo_id + 1); });
			new_chords.wrapAt(indice_da_cambiare)[1] = stringa_accordo;
			new_chords.wrapAt(indice_da_cambiare)[2] = stringa_progressione;
			new_chords.wrapAt(chords.size + 1)[2][0] = accordo;
		});
	});



	new_chords.collect({ | ch | "dd"; ch });//**************************************************************************** ACCORDI POSTLN FINALE
	//"READY TO START".postln;
	new_chords
})


.put("change_modality", { | chords, mode=0 |
	var new_chords = chords.deepCopy;
	chords.size.do({ | selected_chord_id |
		block{ | break |
			var possible_chord_changes;
			var thischord = chords.wrapAt(selected_chord_id)[1].split($ )[0].asInteger;
			var newchord = (thischord + mode).wrap(0, 6).asString ++ " " ++ new_chords.wrapAt(selected_chord_id)[1].split($ )[1]; // Non cambia il rivolto
			var newprog = new_chords.wrapAt(selected_chord_id)[2];

			if( (mode == 1) && ((thischord == 4) || (thischord == 5) || (thischord == 6)), { break.value; });
			if( (mode == 2) && ((thischord == 2) || (thischord == 3) || (thischord == 4) || (thischord == 5) || (thischord == 6)), { break.value; });
			if( (mode == 3) && ((thischord == 0) || (thischord == 1) || (thischord == 3) || (thischord == 4) || (thischord == 5) || (thischord == 6)), { break.value; });
			if( (mode == 4) && ((thischord == 2) || (thischord == 4)), { break.value; });
			if( (mode == 5) && ((thischord == 1) || (thischord == 3) || (thischord == 5)), { break.value; });
			if( (mode == 6), { break.value; });

			new_chords.wrapAt(selected_chord_id)[1] = newchord;
			newprog = newprog[0] ++ newchord[0] ++ newprog[2];
			new_chords.wrapAt(selected_chord_id)[2] = newprog;
			new_chords.wrapAt(selected_chord_id-1)[2] = new_chords.wrapAt(selected_chord_id-1)[2][0] ++ new_chords.wrapAt(selected_chord_id-1)[2][1] ++  newchord[0];
			new_chords.wrapAt(selected_chord_id+1)[2] =  newchord[0] ++ new_chords.wrapAt(selected_chord_id-1)[2][1] ++ new_chords.wrapAt(selected_chord_id-1)[2][2];
		};
	});
	new_chords.collect({ | ch | ch.postln });  // leva un sacco di array di accordi
	new_chords
})

/*
\subsection{Cambio accordi in base a progressione}
\begin{verbatim}
*/
.put("change_chords_from_progression", { | pad_chords, instr_chords |
	var altered_instr_chords = [];
	pad_chords = pad_chords.deepCopy;
	instr_chords = instr_chords.deepCopy;
	// SE PAD HA +/= ACCORDI DI STRUMENTO
	if(pad_chords.size >= instr_chords.size, {
		pad_chords.collect({ | pad_chord, pad_chord_id |
			block{ | break |
				instr_chords.do({ | instr_chord, instr_chord_id |
					if(instr_chord[0] > pad_chord[0], {
						//var alteration = pad_chord[1][0].asInteger - instr_chord[1][0].asInteger;
						var alteration =  instr_chord[1][0].asString.asInteger - pad_chord[1][0].asString.asInteger;
						altered_instr_chords = altered_instr_chords ++ [[instr_chord[0], alteration]];
						break.value;
					});
					if(instr_chord[0] == pad_chord[0], {
						//var alteration = pad_chord[1][0].asInteger - instr_chord[1][0].asInteger;
						var alteration =  instr_chord[1][0].asString.asInteger - pad_chord[1][0].asString.asInteger;
						altered_instr_chords = altered_instr_chords ++ [[instr_chord[0], alteration]];
						break.value;
					});
				});
			};
		});
	});
	// SE PAD HA - ACCORDI DI STRUMENTO
	if(pad_chords.size < instr_chords.size, {
		pad_chords.collect({ | pad_chord, pad_chord_id |
			20.do({
				block{ | break |
					instr_chords.do({ | instr_chord, instr_chord_id |
						if(instr_chord[0] <= pad_chord[0], {
							//var alteration = pad_chord[1][0].asInteger - instr_chord[1][0].asInteger;
							var alteration =  instr_chord[1][0].asString.asInteger - pad_chord[1][0].asString.asInteger;
							altered_instr_chords = altered_instr_chords ++ [[instr_chord[0], alteration]];
							instr_chords.removeAt(instr_chord_id);
							break.value;
						});
					});
				};
			});
		});
	});
	100.do({ block { | break | altered_instr_chords.do({|i, id| if(i.class != Array, { altered_instr_chords.removeAt(id); break.value; }); }) } });
	altered_instr_chords
})

/*
\subsection{Cambio note in base ad accordi}
\begin{verbatim}
*/

.put("change_notes_harmonic", { | instr_notes, alterations, scale |
	var tmp_instr_notes = instr_notes.deepCopy;
	var new_instr_notes = [];
	var altered_notes = [];
	var copied_note;
	tmp_instr_notes.collect({ | note, noteID |
		copied_note = note.copy;
		block { | break |
			alterations.do({ | alteration, alterationID |
				if(((note[0] >= alteration[0]) && (note[0] < alterations[(alterationID+1).clip(0, alterations.size-1)][0])) || (note[0] >= alterations.last[0]), {
					if( (note[1] == \noteOn) && (note[3] > 0), {
						var newNote, newIndexOfScale, indexOfScale = ~v.at("scales").at(scale).find([note[2] % 12]); /* METTERE */
						if(indexOfScale.class != Integer, {
							var note_shift = if( note[2] < 5, { -1 }, { 1 });
							indexOfScale = ~v.at("scales").at(scale).find([ (note[2] + note_shift) % 12]);
						});
						newIndexOfScale = indexOfScale + alteration[1];
						newNote = note[2] + ~v.at("scales").at(scale).wrapAt(newIndexOfScale ) - ~v.at("scales").at(scale).wrapAt( indexOfScale );
						if( (alteration[1] > 0) && ( (~v.at("scales").at(scale).wrapAt(newIndexOfScale ) - ~v.at("scales").at(scale).wrapAt( indexOfScale )) < 0), {newNote = newNote + 12});
						if( (alteration[1] < 0) && ( (~v.at("scales").at(scale).wrapAt(newIndexOfScale ) - ~v.at("scales").at(scale).wrapAt( indexOfScale )) > 0), {newNote = newNote - 12});
						//[note[2], newNote, "+", ~v.at("scales").at(scale).wrapAt(newIndexOfScale ), "-", ~v.at("scales").at(scale).wrapAt( indexOfScale )].postln;
						copied_note[2] = newNote;
						altered_notes = altered_notes ++ [[note[2], copied_note[2]]];
						break.value;
					}, {
						var last_note_on_index = altered_notes.flop[0].find([note[2]]);
						if( last_note_on_index.class == Integer, {
							copied_note[2] = altered_notes[last_note_on_index][1];
							altered_notes.removeAt(last_note_on_index);
						}, {
							copied_note;
						});
						break.value;
					});
				}, {});
			});
		};
		new_instr_notes = new_instr_notes ++ [copied_note];
	});
	new_instr_notes
})

/*
\subsection{Generazione nota singola in base ad accordo e progressione}
\begin{verbatim}
*/
.put("generate_note", { | scale, grade, progression, kind="bass" |
	var indexes;
	if(kind=="bass", {
		indexes = ~v.at("rivolti").at(scale).at(grade)[1].selectIndicesAs({|item, i|
			~v.at("progressioni").at(scale).at(progression)[0].find([item]) != nil}, Array);
	}, {
		indexes = ~v.at("rivolti").at(scale).at(grade)[2].selectIndicesAs({|item, i| ~v.at("progressioni").at(scale).at(progression)[1].find([item]) != nil}, Array);
	});
	if( (indexes.size == 0) || (indexes == nil), { indexes = [0]});
	indexes
})


/*
\subsection{Concatenazione di informazione accordi a note}
\begin{verbatim}
*/
.put("add_progressions_to_notes", { | chords, notes |
	var lastNoteOn = 1, lastNoteNoBias=1;
	var selectedNote = lastNoteOn;
	// 1) TROVA PROGRESSIONI DA ACCORDI
	chords = chords.collect({ | tickChord, tickChordID |
		[tickChord[0], tickChord[1], chords.wrapAt(tickChordID-1)[1][0].asString++chords.wrapAt(tickChordID)[1][0].asString++chords.wrapAt(tickChordID+1)[1][0].asString];
	});
	// 2) TROVA NOTE IN BASE A PROGRESSIONI ED ACCORDI
	notes.collect({ | note, noteID |
		var selectedChord;
		// 2.1) TROVA L'ACCORDO AFFERENTE ALLA NOTA
		chords.do({ | chord, chordID |
			if(((note[0] >= chord[0]) && (note[0] < chords.wrapAt(chordID+1)[0])) || (note[0] >= chords.last[0]), {
				selectedChord = chord;
			});
		});
		(note[0..5] ++ [selectedChord[1]] ++ [selectedChord[2]]);
	});
})

/*
\subsection{Alterazione di successione di note}
\begin{verbatim}
*/
.put("alter_notes", { | scale,chords, notes, prob |
	var lastNoteOn = 1;
	var selectedNote = lastNoteOn;
	var variedNotes = [];
	var id_to_change = -1;
	chords = chords.collect({ | tickChord, tickChordID |
		[tickChord[0], tickChord[1], chords.wrapAt(tickChordID-1)[1][0].asString++chords.wrapAt(tickChordID)[1][0].asString++chords.wrapAt(tickChordID+1)[1][0].asString];
	});
	notes.collect({ | note, noteID |
		var selectedChord, nextChord;
		var thisChordID, nextChordID;
		var lastNote = notes.wrapAt(noteID - 1);
		chords.do({ | chord, chordID |
			if(((note[0] >= chord[0]) && (note[0] < chords[(chordID+1).clip(0, chords.size-1)][0])) || (note[0] >= chords.last[0]), {
				selectedChord = chord;
				thisChordID = chordID;
				nextChordID = ((chordID + 1) % (chords.size));
				nextChord = chords[nextChordID];
			});
		});
		if(note[1].asString == "noteOn", {
			var indexes = ~f.at("generate_note").value(scale, selectedChord[1], selectedChord[2], "lead");
			var bias = (note[2] / 12).asInteger;
			if( (indexes.size == 0) || (indexes == nil), { indexes = [0] } );
			// Se l'accordo è cambiato, trova la nota più alta (nelle prossime 10)
			if( lastNote.last != note.last, {
				id_to_change = noteID;
				10.do({ | id |
					if( notes.wrapAt(noteID + id)[2].asInteger > note[2].asInteger, {
						id_to_change = noteID + id;
					});
				});
			});
			if( (noteID == id_to_change) && (~v["enrich_chord"]["major"][selectedChord[2]].size > 0) && prob.coin, {
				selectedNote = (bias * 12) + ~v["enrich_chord"]["major"][selectedChord[2]].choose;
			}, { selectedNote = note[2] });
			2.do({
				if(selectedNote < 36, { selectedNote = selectedNote + 12 } );
				if(selectedNote > 96, { selectedNote = selectedNote - 12 } );
			});
			variedNotes = variedNotes ++ [[note[2], selectedNote]];
			lastNoteOn = selectedNote;
		}, {
			selectedNote = lastNoteOn;
			block { | break |
				variedNotes.do({ | noteTuple, id |
					if(note[2] == noteTuple[0], { selectedNote = noteTuple[1]; variedNotes.removeAt(id); break.value; });
				});
			}
		});
		note[2] = selectedNote;
	});
})

/*
\section{Player di eventi}
\subsection{Player di note}
\begin{verbatim}
*/
.put("playMIDIEvent_streaming", { | genre, type, instrName, event, out=0 |
	var kind = event[1].asString;
	var velocity = ( (event[3]) * 127.0.reciprocal );  ///reciproval è come se dividesse per 127
	var real_note = event[2].copy;
	var altered_note, transposed_note, note, hasToPlay = false;
	var manage_hasToPlay;
    ////////////velocity.postln;
	note = real_note.copy.asInteger.asString;

    //("vecchio instr " ++ instrName).postln;


if(instrName.contains("drum").not, {
	instrName =  instrName.split($_)[0] ++ "_" ++ instrName.split($_)[1].asInteger.wrap(100, 130);
});


/*
	if(instrName.contains("drum").not, {
	note = note.asInteger + ~v["transpose_factor"];  //~v["transpose_factor"];
    note = note.asString;
});
*/



//	instrName =  instrName.split($_)[0] ++ "_" ++ instrName.split($_)[1].asInteger.wrap(100, 105);
    //("nuovo instr " ++ instrName).postln;


	//instrName.postln;
/*
	if(instrName == "drum", {velocity =  (event[3]). lin (0, 127, 10, 30);
		("velocity_DRUM" ++ velocity).postln});
*/
	// Clip di registro
		if(instrName.contains("drum"), {velocity = velocity * 0.5});

	if(instrName.contains("key"), { 3.do({  if(note.asInteger < 48, {note = (note.asInteger+12).asString});  if(note.asInteger > 95, { note = (note.asInteger-12).asString}); });       if( ~v["WOW"], { velocity = velocity * ~v["key_vel_scale"]; });    });
	if(instrName.contains("pad"), { 3.do({ if(note.asInteger < 48, {note = (note.asInteger+12).asString});  if(note.asInteger > 83, { note = (note.asInteger-12).asString}); });    });
	if(instrName.contains("sampler"), { 3.do({ if(note.asInteger < 48, {note = (note.asInteger+12).asString});  if(note.asInteger > 83, { note = (note.asInteger-12).asString}); }); if( ~v["WOW"], { velocity = velocity * ~v["sampler_vel_scale"]; });  });
	if(instrName.contains("lead"), { 3.do({ if(note.asInteger < 48, {note = (note.asInteger+12).asString});  if(note.asInteger > 83, { note = (note.asInteger-12).asString});  });      if( ~v["WOW"], { velocity = velocity * ~v["sampler_vel_scale"]; }); });
	if(instrName.contains("bass"), { 3.do({ if(note.asInteger < 40, {note = (note.asInteger+12).asString});  if(note.asInteger > 59, { note = (note.asInteger-12).asString}); });       if( ~v["WOW"], { velocity = velocity * ~v["bass_vel_scale"]; });  });
	if( genre == "synthwave", {
		if(instrName.contains("bass"), { 3.do({ if(note.asInteger < 40, {note = (note.asInteger+12).asString});  if(note.asInteger > 59, { note = (note.asInteger-12).asString}); });       if( ~v["WOW"], { velocity = velocity * ~v["bass_vel_scale"]; });  });
	}, {
		if(instrName.contains("bass"), { 3.do({ if(note.asInteger < 40, {note = (note.asInteger+12).asString});  if(note.asInteger > 59, { note = (note.asInteger-12).asString}); });       if( ~v["WOW"], { velocity = velocity * ~v["bass_vel_scale"]; });  });
	});

	// DRUM enable
	~v["enable_list"].do({ | enable, enable_id |
		var name = enable.split($_)[0];
		var instr_notes = name ++ "_note";
		if( name.contains("kick") || name.contains("snare") || name.contains("clap") || name.contains("hh1") || name.contains("hh2") || name.contains("ride") || name.contains("cymbal") || name.contains("perc") || name.contains("tom") || name.contains("fx"), { name = "drum" });
		//if( ~v["WOW"] && instrName.contains("drum"), { velocity = velocity * ~v["kick_vel_scale"]; });
		//if( ~v["WOW"] && instrName.contains("drum") && (~v.at("kick_note").find([event[2].asString]) != nil), { velocity = velocity * ~v["drum_vel_scale"]; });

		///MIOOOOO

		   // ("VELOCITY" ++ (velocity*127).linlin(0, 127, 48, 72).asInteger).postln; // MIOOOOOOOOOOOOO MI STAMPA VELOCITy?

		//if( instrName.contains(name) && (~v[enable] == true) && (~v[instr_notes].find([event[2].asString]) != nil), { hasToPlay = true; });
		if( instrName.contains(name) && (~v[enable] == true) && (~v[instr_notes].find([note]) != nil), { hasToPlay = true; });
	});
	// NOTE ON
	if( (kind == "noteOn") && (event[3] > 0), {
		Routine{
			var sample, buf, atk, allow_noteOn = true;
			var synth = nil;
			atk = 0.005;

			// Strumenti tranne drum
			if(instrName.contains("drum").not, {
				//[genre, type, instrName, kind.asString, note].postln;
				// Selezione e lettura campione
				sample = ~v["sampleDB"]["audio"][type][instrName][note];
				//sample.postln;
				if( sample != nil, {
					if( sample.extension == "mp3", {
						buf = MP3.readToBuffer(s, sample);
					}, {
						//buf = Buffer.cueSoundFile(s, sample)
						buf = Buffer.read(s, sample);
					});
				});
				~v["buffer_load_time"].wait;
				// Play del campione    //BASSOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
				if(hasToPlay && allow_noteOn && (sample != nil), {
					if(instrName.contains("bass"), {
						synth = Synth.head(s, \PlayBufBass, [\buf, buf, \attack, atk, \amp, velocity, \out, out]);
					}, {
						synth = Synth.head(s, \PlayBuf, [\buf, buf, \attack, atk, \amp, velocity, \out, out]); //fa suonare tutto in PlayBuf ad eccezione di bass e drums
					});
					if(instrName.contains("pad"), {  c.noteOn(0, note,(velocity * 127).asInteger); });
					if(instrName.contains("key"), { c.noteOn(1, note,(velocity * 127).asInteger); });
					if(instrName.contains("sampler"), {  c.noteOn(2, note,(velocity * 127).asInteger); });
					if(instrName.contains("lead"), {  c.noteOn(5, note,(velocity * 127).asInteger); });
					if(instrName.contains("bass"), {  c.noteOn(3, note,(velocity * 127).asInteger); });
				});
			}, {

				// Strumenti drum
				sample = ~v["sampleDB"]["audio"][type][instrName][real_note.asString];
				//sample.postln;
				if( sample != nil, {
					if( sample.extension == "mp3", {
						buf = MP3.readToBuffer(s, sample);
					}, {
						//buf = Buffer.read(s, sample); // *******************************************************
					 buf = Buffer.cueSoundFile(s, sample);
					});
				});

				if( (~v["kick_note"].find([note]) != nil), {
					velocity = velocity * 1.0;
				});

				~v["buffer_load_time"].wait;
				if(hasToPlay && (sample != nil), {
					//if( ~v["drum_delay"] && ((~v["snare_note"].find([note]) != nil) || (~v["fx_note"].find([note]) != nil)), {
					if(false, {
						synth = Synth.head(s, \PlayBufDrumDelay, [\buf, buf, \amp, velocity / 4, \out, out, \delT, 60 / (~v["tmp_song"]["pad"]["tempo"].round), \delD, 1]);
						~v["drum_delay"] = false;
					}, {
						synth = Synth.head(s, \PlayBufDrum, [\buf, buf, \amp, velocity, \out, out]);
					});
					if(instrName.contains("drum"), {  c.noteOn(4, real_note, (velocity * 127).asInteger); });
				});
			});
			// ************************************** Free del buffer del campione e del synth, per essere sicuri di deallocare tutta la memoria non necessaria nel server

// QUESTA ROUTINE GENERA IL PROBLEMA DEI NODI

			Routine{
				try({
					( buf.duration * 1 ).wait;
					buf.free;
					synth.free;
				});
				//synth.free;
			}.play(AppClock);

			if( hasToPlay && (sample != nil), {
				// NOTE OFF dopo N tick da \noteOn
				event[5].wait;
				// Rilascia synth
				synth.release(event[4]);
				// NoteOff MIDI
				if(instrName.contains("pad"), {       c.noteOff(0, note, 0);    });
				if(instrName.contains("key"), {       c.noteOff(1, note,  0);    });
				if(instrName.contains("sampler"), {       c.noteOff(2, note, 0);      });
				if(instrName.contains("bass"), {       c.noteOff(3, note, 0);       });
				if(instrName.contains("drum"), {       c.noteOff(4, real_note, 0);     });
				if(instrName.contains("lead"), {       c.noteOff(5, note,  0);    });
			});
		}.play(~v["clock"]);
	});
})

/*
\subsection{Player di pubblicità}
\begin{verbatim}
*/
.put("play_ADS_streaming", { | out=0 |
	Buffer.read(s, ~v["sampleDB"]["ads"].values.wrapAt(~v["ads_counter"]), action: { | buf |
		Synth.head(s, \PlayBufADS, [\buf, buf, \amp, (~v["ads_volume"]).dbamp, \out, ~v["master_input"]]);
		~v["ads_counter"] = ~v["ads_counter"] + 1;
	})
})

/*
\subsection{Player di suoni di atmosfera}
\begin{verbatim}
*/
/*
.put("play_atmos_streaming", { | volume = 0.5 |   //   ho alzato io era più basso
	Routine{
		var buf = ~bufatmos = Buffer.cueSoundFile(s, ~v["sampleDB"][~v["genre"]]["atmos"]["atmos"].values.choose);
		//var buf = Buffer.read(s, ~v["sampleDB"][~v["genre"]]["atmos"]["atmos"].values.choose);
		~v["buffer_load_time"].wait;
		"ATMOS_ATMOS_ATMOS".postln;
		Synth.head(s, \PlayBufAtmos, [\buf, buf, \amp, (~v["atmos_volume"]).dbamp * volume, \out, ~v["master_input"]]);
	}.play(~v["clock"]);
})
*/


.put("play_atmos_streaming", { | volume = 0.5 |   //   ho alzato io era più basso
	Routine{
		var synth;
		var buf = ~bufatmos = Buffer.cueSoundFile(s, ~v["sampleDB"][~v["genre"]]["atmos"]["atmos"].values.choose);
		//var buf = Buffer.read(s, ~v["sampleDB"][~v["genre"]]["atmos"]["atmos"].values.choose);
		~v["buffer_load_time"].wait;
		"ATMOS_ATMOS_ATMOS".postln;
		 synth = Synth.head(s, \PlayBufAtmos, [\buf, buf, \amp, (~v["atmos_volume"]).dbamp * volume, \out, ~v["master_input"]]);


		Routine{
				try({
					( buf.duration * 1 ).wait;
					buf.free;
					synth.free;
				});
				//synth.free;
			}.play(AppClock);

	}.play(~v["clock"]);

})


/*
\subsection{Player di suoni transitori}
\begin{verbatim}
*/

/*
.put("play_transition_streaming", { | out=0 |
	Routine{
		var buf = Buffer.cueSoundFile(s, ~v["sampleDB"][~v["genre"]]["transition"]["transition"].values.choose);
		//~buffertransition = Buffer.cueSoundFile(s, ~v["sampleDB"][~v["genre"]]["transition"]["transition"].values.choose);
		//QUESTO POTREBBE ESSERE CAMBIATO CON CAMBIO BPM PER ACCESSO A CARTELLE DIVERSE MA FORSE NON SERVE
		//var buf = Buffer.read(s, ~v["sampleDB"][~v["genre"]]["transition"]["transition"].values.choose);

		//IL RATE MODIFICA IL TEMPO DELLE TRANSIZIONI CON IL CAMBIO BPM
		var rate = (~v["tmp_song"]["pad"]["tempo"] + (~v["tmp_song"]["pad"]["tempo"] * ~v["clock_change_perc"])) / ~v["transition_default_bpm"];
		~v["buffer_load_time"].wait;
		"TRANSIZIONE".postln;
		Synth.head(s, \PlayBufTransition, [\buf, buf, \amp, (~v["transition_volume"]).dbamp, \rate, rate, \out, ~v["master_input"]]);


	}.play(~v["clock"]);
})
*/

.put("play_transition_streaming", { | out=0 |
	Routine{
		var synth;
		//var buf = Buffer.cueSoundFile(s, ~v["sampleDB"][~v["genre"]]["transition"]["transition"].values.choose);
		//var buf = Buffer.read(s, ~v["sampleDB"][~v["genre"]]["transition"]["transition"].values.choose);
		var buf = Buffer.read(s, ~v["sampleDB"]["audio"]["transition"]["transition"].values.choose);
		//~buffertransition = Buffer.cueSoundFile(s, ~v["sampleDB"][~v["genre"]]["transition"]["transition"].values.choose);
		//QUESTO POTREBBE ESSERE CAMBIATO CON CAMBIO BPM PER ACCESSO A CARTELLE DIVERSE MA FORSE NON SERVE
		//var buf = Buffer.read(s, ~v["sampleDB"][~v["genre"]]["transition"]["transition"].values.choose);

		//IL RATE MODIFICA IL TEMPO DELLE TRANSIZIONI CON IL CAMBIO BPM
		var rate = (~v["tmp_song"]["pad"]["tempo"] + (~v["tmp_song"]["pad"]["tempo"] * ~v["clock_change_perc"])) / ~v["transition_default_bpm"];
		~v["buffer_load_time"].wait;
		"TRANSIZIONEEEEEEEEEEEEEEEEEE".postln;

		 synth = Synth.head(s, \PlayBufTransition, [\buf, buf, \amp, (~v["transition_volume"]).dbamp, \rate, rate, \out, ~v["master_input"]]);

			Routine{
				try({
					( buf.duration * 1 ).wait;
					buf.free;
					synth.free;
				});
				//synth.free;
			}.play(AppClock);


	}.play(~v["clock"]);
})


.put("play_covid_streaming", { | out=0 |
	Routine{
		var buf = Buffer.cueSoundFile(s, ~v["sampleDB_folder"] ++ "ads/pulse_covid.wav", bufferSize: 16384);
		//var buf = Buffer.read(s, ~v["sampleDB_folder"] ++ "ads/pulse_covid.wav");
		~v["buffer_load_time"].wait;
		Synth.head(s, \PlayBufAtmos, [\buf, buf, \amp, ~v["social_sine_amplitude"], \out, ~v["master_input"]]);
	}.play(~v["clock"]);
})

/*
\section{Gestione dei brani}
\subsection{Caricamento player delle tracce singole}
\begin{verbatim}
*/

.put("loadTrack", {
	var players = [];
	~v["tmp_song"].keysValuesDo({ | key, dict |
		var playerObj = ();

		playerObj.noteCounter = 0;

		playerObj.rout = Routine{
			~v["average_8bar_dur"].do({ | tick |
				var eventIDs = dict["notes"].flop[0].findAll( [tick] );
				if( eventIDs != nil, {
					//var tempo = Main.elapsedTime;
					eventIDs.do({ | eventID, eventID_ID |
						var event = dict["notes"][eventID];
						var nextOnEvent, nextOnEventDelta = 0;
						var evento = event;

						if( tick % 16 == 0, { playerObj.noteCounter = 0; });
						playerObj.noteCounter = playerObj.noteCounter + 1;


						Routine{
							block { | break |
								4.do({ | id |
									id = id + 1;
									if( dict["notes"].wrapAt(eventID + id)[1] == \noteOn, {
										nextOnEvent = dict["notes"].wrapAt(eventID + id);
										nextOnEventDelta = (event[0] - nextOnEvent[0]).abs;
										break.value;
									});
								});
							};
							if( (event[1] == \noteOn) && (event[3] > 0), {
								if(key.contains("drum").not, {
									if( ~v["generi_con_umanizzazione"].find([~v["genre"]]) != nil, {
										if(key.contains("key").not, {
											if( (evento[0] - dict["notes"].wrapAt(eventID+1)[0]) == 0, {
											}, {
												exprand(~v["uman_minimo"], ~v["uman_massimo"]).wait;
											});
										}, {
											exprand(~v["uman_minimo"], ~v["uman_massimo"]).wait;
										});
									});
								}, {
									if( (event[0] % ~v["tpqn"]) == 0, {
										nextOnEventDelta = 0;
									}, {
										nextOnEventDelta = ~v["tpqn"] * 4;
									});
								});
							});
							if( event[1] == \noteOn, {
								block{ | break |
									if( ~v["WOW"].not && (~v["genre"] != "trap"), {
										// CONTROLLO PRESENZA (orizzontale)
										["drum", "bass", "pad", "key", "lead", "sampler"].do({ | instr |
											if( ~v[instr ++ "_event_density"] > 0.75, { nextOnEventDelta = ~v["tpqn"] * 4 });
											if( ~v[instr ++ "_event_density"].coin && key.contains(instr) && (nextOnEventDelta > [~v["tpqn"] / 2, ~v["tpqn"]].choose), {          break.value;         });
										});
										// CONTROLLO ACCORDI (verticale)
										//if( (eventID_ID > ( (~v["structure_id"] * 2).fold(0,  ( (~v["structure"].size) - 1 ).abs * 8 ) + 2).clip(2, max(2, ~v["max_eventi_verticale"]))), { break.value });
									});
									// CONTROLLO ACCORDI (verticale)
									if( playerObj.noteCounter > ~v["max_eventi_verticale"], { break.value; });
									// COVID DISTANZIAMENTO SOCIALE (SECCA NOTE SOPRA MIDI 60)
									if( (~v["social_distance_violated"] == true) && (event[2].asInteger < 65) , { break.value; });
									~f.at("playMIDIEvent_streaming").value( ~v["genre"], key, dict["instr"], event, ~v["out_channels"][key] );
								};
							});
						}.play(~v["clock"]);
					});
				});
				1.wait;
			});
		};
		players = players ++ [playerObj];
	});
	players
})

/*
\subsection{Cambio tempo master clock}
\begin{verbatim}
*/
//FORMULA DI CAMBIO TEMPOOOOOOOOOOOOOOOOOOOOOOOOOO

.put("update_clock", { | shift_percent=0.06 | // shift_percent range: [-0.5, 0.5] * song tempo
	~v.at("clock").tempo_( ( 1 / ( ( 60 / (~v["tmp_song"]["pad"]["tempo"] + (~v["tmp_song"]["pad"]["tempo"] * shift_percent)) ) / ~v["tmp_song"]["pad"]["division"] ) ).round(1).asInteger );
})

/*
\subsection{Generazione di brani ( versione statica per inizio play )}
\begin{verbatim}
*/
.put("generate_tmp_song", {
	var pad, pad_choice, drum, drum_choice, new_pad_chords, pad_grade_alteration, choices = [];
	var variation_index = if( ~v["structure_id"].fold(0, ~v["structure"].size / 2) >= 2, { 0 }, { 1 });
	if( ~v["WOW"], { variation_index = 0 });
	~v["genre"] = ~v["next_genre"];
	~v.put("tmp_song", Dictionary.new);
	~v.put("tmp_chunks", Dictionary.new);
	~v["kdtree_index_of_neighbor"] = 0;
	// Trova il midi del pad in base alla ricerca ND

/*
	if( ~v["midi_search_type"] == "nearest", {
		pad_choice = ~v["kd_trees"][~v["genre"]]["pad"].nearest([~v["kdtree_search_X"], ~v["kdtree_search_Y"], ~v["kdtree_search_Y"]])[0].label;
	});
	if( ~v["midi_search_type"] == "random", {
		if( (~v["kd_trees"][~v["genre"]]["pad"].allNearest.size % ~v["midi_selection"]) == 0, {
			~v["rand_seed"] = Main.elapsedTime.ceil;
		});
		thisThread.randSeed_(~v["rand_seed"]);
		pad_choice = ~v["kd_trees"][~v["genre"]]["pad"].allNearest.scramble.wrapAt(~v["midi_selection"]).value[0].label;
	});
	if( ~v["midi_search_type"] == "walk", {
		pad_choice = ~v["kd_trees"][~v["genre"]]["pad"].radiusSearch([1 - ((~v["midi_selection"] % 10) / 10), 1 - ((~v["midi_selection"] % 12) / 12), (~v["midi_selection"] % 10) / 11], 2).keep(8).wrapAt(~v["midi_selection"]).label;
	});
*/

	if( ~v["midi_search_type"] == "sequence", {
		pad_choice = ~v["midi_combinations"][~v["next_genre"]]["combinations"][~v["midi_combinations"][~v["next_genre"]]["combination_id"]][0];
	});


	pad = ~v["midiDB"][~v["genre"]]["pad"][pad_choice].deepCopy;
	// Cambia gli accordi in base alla tabella di chord_change.txt
	new_pad_chords = ~f["change_chords"].value(pad["chords"], pad["num_recalls"], if( ~v["generi_con_cadenza"].find([~v["genre"]]) != nil, {true}, {false}), ~v["genre"] );

	// Aggiorno il numero di volte che è stato chiamato questo pad
	pad["num_recalls"] = pad["num_recalls"] + 1;
	~v["midiDB"][~v["genre"]]["pad"][pad_choice]["num_recalls"] = ~v["midiDB"][~v["genre"]]["pad"][pad_choice]["num_recalls"] + 1;
	// Sistema le note in base ai nuovi accordi
	pad_grade_alteration = ~f["change_chords_from_progression"].value( pad["chords"], new_pad_chords );

	pad["chords"] = new_pad_chords;

	/* CAMBIO DI MODALITA' */
	if( ~v["modality"] != 0,{
		pad["chords"] = ~f["change_modality"].value( pad["chords"], ~v["modality"] );
	});
	/* FINE CAMBIO DI MODALITA' */


	if( ~v["scramble_instrs_enable"], {
		pad["instr"] = ~v["midiDB"][~v["genre"]]["pad"].values.choose["instr"]; // SCAMBIA STRUMENTI
	});
	pad["notes"] = ~f["add_progressions_to_notes"].value(pad["chords"], pad["notes"]);
	pad["notes"] = ~f["change_notes_harmonic"].value( pad["notes"], pad_grade_alteration, pad["scale"] );
	// Correggi noteOn prima di noteOff
	// Trasponi
	pad["notes"] = ~f["transpose_notes"].value(pad["notes"], ~v["transpose_factor"]);
	// Trova il midi della drum in base alla ricerca ND
	/*
	if( ~v["midi_search_type"] == "nearest", {
		drum_choice = ~v["kd_trees"][~v["genre"]]["drum"].nearest([~v["kdtree_search_X"], ~v["kdtree_search_Y"], ~v["kdtree_search_Y"]])[0].label;
	});
	if( ~v["midi_search_type"] == "random", {
		drum_choice = ~v["kd_trees"][~v["genre"]]["drum"].allNearest.scramble.wrapAt(~v["midi_selection"]).value[0].label;
	});
	if( ~v["midi_search_type"] == "walk", {
		drum_choice = ~v["kd_trees"][~v["genre"]]["drum"].radiusSearch([1 - ((~v["midi_selection"] % 10) / 10), 1 - ((~v["midi_selection"] % 12) / 12), (~v["midi_selection"] % 10) / 11], 2).keep(8).wrapAt(~v["midi_selection"]).label;
	});
	*/

		if( ~v["midi_search_type"] == "sequence", {
			drum_choice = ~v["midi_combinations"][~v["next_genre"]]["combinations"][~v["midi_combinations"][~v["next_genre"]]["combination_id"]][2];
		});


	//if( ~v["genre"] == "House", { drum_choice = pad_choice });
	drum = ~v["midiDB"][~v["genre"]]["drum"][drum_choice].deepCopy;
	drum["notes"] = drum["variations"].foldAt(variation_index).deepCopy; //
	("DRUM_____" ++ drum).postln;	//AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
	~v["tmp_song"]["pad"];
	~v["tmp_song"].put("pad", pad);
	~v["tmp_song"].put("drum", drum);
	["key", "sampler", "lead", "bass"].do({ | type |
		var selection, choice, gradeAlteration, newNotes;
		// Trova il midi in base alla ricerca ND
		if( type == "bass", {
			selection = pad_choice;
		}, {
			/*
			if( ~v["midi_search_type"] == "nearest", {
				selection = ~v["kd_trees"][~v["genre"]][type].radiusSearch([~v["kdtree_search_X"], ~v["kdtree_search_Y"], ~v["kdtree_ search_Y"]], 2);
				selection = selection.wrapAt(pad["num_recalls"]).label;
			});

			if( ~v["midi_search_type"] == "random", {
				selection = ~v["kd_trees"][~v["genre"]][type].allNearest.scramble.wrapAt(~v["midi_selection"]).value[0].label;
			});

			if( ~v["midi_search_type"] == "walk", {
				selection = ~v["kd_trees"][~v["genre"]][type].radiusSearch([1 - ((~v["midi_selection"] % 10) / 10), 1 - ((~v["midi_selection"] % 12) / 12), (~v["midi_selection"] % 10) / 11], 2).keep(8).wrapAt(~v["midi_selection"]).label;

				//selection = selection.wrapAt(pad["num_recalls"]).label;
			});

			*/
			if( ~v["midi_search_type"] == "sequence", {
				if( type == "key", {
					selection = ~v["midi_combinations"][~v["next_genre"]]["combinations"][~v["midi_combinations"][~v["next_genre"]]["combination_id"]][1];
				}, {
					selection = ~v["kd_trees"][~v["next_genre"]][type].allNearest.scramble.wrapAt(~v["midi_selection"]).value[0].label;
				});
			});
		});
		//if( ~v["genre"] == "House", { selection = pad_choice });
		choice = ~v["midiDB"][~v["genre"]][type][selection].deepCopy;
		choice["notes"] = choice["variations"].foldAt(variation_index).deepCopy; // AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
		if( ~v["scramble_instrs_enable"] && (type != "sampler"), {
			choice["instr"] = ~v["midiDB"][~v["genre"]][type].values.choose["instr"]; // SCAMBIA STRUMENTI
		});
		// Trova gli accordi aggiustati in base agli accordi del pad
		gradeAlteration = ~f["change_chords_from_progression"].value( choice["chords"], pad["chords"] );
		// Computa le note in base agli accordi aggiustati

		choice["notes"] = ~f["add_progressions_to_notes"].value(pad["chords"], choice["notes"]);
		if( (type == "bass") || (type == "key"), {
			newNotes = ~f["change_notes_harmonic"].value( choice["notes"], gradeAlteration, pad["scale"] );
		}, {
			newNotes = ~f["change_notes_harmonic"].value( choice["notes"], gradeAlteration, pad["scale"] );
		});
		choice["notes"] = newNotes;
		// Correggi noteOn prima di noteOff
		//choice["notes"] = ~f["correct_noteOff"].value(choice["notes"]);
		// Trasponi
		choice["notes"] = ~f["transpose_notes"].value(choice["notes"], ~v["transpose_factor"]);
		~v["tmp_song"].put(type, choice);
	});
	~v["midi_selection"] = ~v["midi_selection"] + 1;
	if( ~v["midi_search_type"] == "sequence", {
		~v["midi_combinations"][~v["next_genre"]]["combination_id"] = (~v["midi_combinations"][~v["next_genre"]]["combination_id"] + 1) % (~v["midi_combinations"][~v["next_genre"]]["combinations"].size - 1);
	});
})

/*
\subsection{Generazione di brani ( versione dinamica per runtime )}
\begin{verbatim}
*/

.put("generate_tmp_song_at_runtime", {
	Routine{
		var pad, pad_choice=nil, drum, drum_choice=nil, new_pad_chords, pad_grade_alteration, choices = [];
		var variation_index = if( ~v["structure_id"].fold(0, ~v["structure"].size / 2) >= 2, { 0 }, { 1 });
		//if( ~v["WOW"], { variation_index = 0 });
		~v.put("new_tmp_song", Dictionary.new);
		~v.put("new_tmp_chunks", Dictionary.new);
		~v["kdtree_index_of_neighbor"] = ~v["kdtree_index_of_neighbor"] + 1;

		if( ~v["midi_search_type"] == "nearest", {
			pad_choice = ~v["kd_trees"][~v["next_genre"]]["pad"].radiusSearch([~v["kdtree_search_X"], ~v["kdtree_search_Y"], ~v["kdtree_search_Y"]], 1).keep(3).choose.label;
		});

		if( ~v["midi_search_type"] == "random", {
			if( (~v["kd_trees"][~v["next_genre"]]["pad"].allNearest.size % ~v["midi_selection"]) == 0, {
				~v["rand_seed"] = Main.elapsedTime.ceil;
			});
			thisThread.randSeed_(~v["rand_seed"] + rrand(0, 100));
			pad_choice = ~v["kd_trees"][~v["next_genre"]]["pad"].allNearest.scramble.wrapAt(~v["midi_selection"]).value[0].label;
		});

		if( ~v["midi_search_type"] == "walk", {
			pad_choice = ~v["kd_trees"][~v["next_genre"]]["pad"].radiusSearch([1 - ((~v["midi_selection"] % 10) / 10), 1 - ((~v["midi_selection"] % 12) / 12), (~v["midi_selection"] % 10) / 11], 1).keep(8).wrapAt(~v["midi_selection"]).label;
		});

		if( ~v["midi_search_type"] == "sequence", {
			pad_choice = ~v["midi_combinations"][~v["next_genre"]]["combinations"][~v["midi_combinations"][~v["next_genre"]]["combination_id"]][0];
		});

		("PAD_CHOICE" ++ pad_choice).postln;


		while( { (~v["midi_search_type"] != "sequence") && (((pad_choice == ~v["PRESENTATION_PAD_CHOICE_LOUNGE"]) && ~v["next_genre"] == "lounge") || ((pad_choice == ~v["PRESENTATION_PAD_CHOICE_HOUSE"]) && ~v["next_genre"] == "House") || ((pad_choice == ~v["PRESENTATION_PAD_CHOICE_TRAP"]) && ~v["next_genre"] == "trap") || ((pad_choice == ~v["PRESENTATION_PAD_CHOICE_LOFI"]) && ~v["next_genre"] == "Lo-Fi")) }, {
			"blocco in pad".postln;
			[pad_choice, ~v["PRESENTATION_PAD_CHOICE_TRAP"], (pad_choice == ~v["PRESENTATION_PAD_CHOICE_TRAP"]), ((pad_choice == ~v["PRESENTATION_PAD_CHOICE_TRAP"]) && ~v["next_genre"] == "trap")].postln;
			if( ~v["midi_search_type"] == "nearest", {
				pad_choice = ~v["kd_trees"][~v["next_genre"]]["pad"].radiusSearch([~v["kdtree_search_X"], ~v["kdtree_search_Y"], ~v["kdtree_search_Y"]], 2).keep(3).choose.label;
			});
			if( ~v["midi_search_type"] == "random", {
				if( (~v["kd_trees"][~v["next_genre"]]["pad"].allNearest.size % ~v["midi_selection"]) == 0, {
					~v["rand_seed"] = Main.elapsedTime.ceil;
				});
				thisThread.randSeed_(~v["rand_seed"] + rrand(0, 100));
				pad_choice = ~v["kd_trees"][~v["next_genre"]]["pad"].allNearest.scramble.wrapAt(~v["midi_selection"]).value[0].label;
			});
			if( ~v["midi_search_type"] == "walk", {
				pad_choice = ~v["kd_trees"][~v["next_genre"]]["pad"].radiusSearch([1 - ((~v["midi_selection"] % 10) / 10), 1 - ((~v["midi_selection"] % 12) / 12), (~v["midi_selection"] % 10) / 11], 1).keep(8).choose.label;
			});
			if( ~v["midi_search_type"] == "sequence", {
				~v["midi_combinations"][~v["next_genre"]]["combination_id"] = (~v["midi_combinations"][~v["next_genre"]]["combination_id"] + 1) % (~v["midi_combinations"][~v["next_genre"]]["combinations"].size - 1);
				pad_choice = ~v["midi_combinations"][~v["next_genre"]]["combinations"][~v["midi_combinations"][~v["next_genre"]]["combination_id"]][0];
			});

		});

		("questo è il PAD_" ++ pad_choice ).postln; //********************************************** STAMPA PAD
		//"ciao bello".postln;
		pad = ~v["midiDB"][~v["next_genre"]]["pad"][pad_choice].deepCopy;
		//0.02.wait;

		if( ~v["midi_search_type"] == "nearest", {
			drum_choice = ~v["kd_trees"][~v["next_genre"]]["drum"].radiusSearch([~v["kdtree_search_X"], ~v["kdtree_search_Y"], ~v["kdtree_search_Y"]], 1).keep(3).wrapAt(pad["num_recalls"]).label;
		});
		if( ~v["midi_search_type"] == "random", {
			drum_choice = ~v["kd_trees"][~v["next_genre"]]["drum"].allNearest.scramble.wrapAt(~v["midi_selection"]).value[0].label;
		});
		if( ~v["midi_search_type"] == "walk", {
			drum_choice = ~v["kd_trees"][~v["next_genre"]]["drum"].radiusSearch([1 - ((~v["midi_selection"] % 10) / 10), 1 - ((~v["midi_selection"] % 12) / 12), (~v["midi_selection"] % 10) / 11], 2).keep(8).wrapAt(~v["midi_selection"]).label;
		});
		if( ~v["midi_search_type"] == "sequence", {
			drum_choice = ~v["midi_combinations"][~v["next_genre"]]["combinations"][~v["midi_combinations"][~v["next_genre"]]["combination_id"]][2];
		});


		while( { (~v["midi_search_type"] != "sequence") && (((drum_choice == ~v["PRESENTATION_PAD_CHOICE_LOUNGE"]) && ~v["next_genre"] == "lounge") || ((drum_choice == ~v["PRESENTATION_PAD_CHOICE_HOUSE"]) && ~v["next_genre"] == "House") || ((drum_choice == ~v["PRESENTATION_PAD_CHOICE_TRAP"]) && ~v["next_genre"] == "trap") || ((drum_choice == ~v["PRESENTATION_PAD_CHOICE_LOFI"]) && ~v["next_genre"] == "Lo-Fi")) }, {
			"blocco in drum".postln;
			[drum_choice, ~v["PRESENTATION_PAD_CHOICE_TRAP"], (pad_choice == ~v["PRESENTATION_PAD_CHOICE_TRAP"]), ((pad_choice == ~v["PRESENTATION_PAD_CHOICE_TRAP"]) && ~v["next_genre"] == "trap")].postln;
			if( ~v["midi_search_type"] == "nearest", {
				drum_choice = ~v["kd_trees"][~v["next_genre"]]["drum"].radiusSearch([~v["kdtree_search_X"], ~v["kdtree_search_Y"], ~v["kdtree_search_Y"]], 1).keep(3).wrapAt(pad["num_recalls"]).label;
			});
			if( ~v["midi_search_type"] == "random", {
				drum_choice = ~v["kd_trees"][~v["next_genre"]]["drum"].allNearest.scramble.wrapAt(~v["midi_selection"]).value[0].label;
			});
			if( ~v["midi_search_type"] == "walk", {
				drum_choice = ~v["kd_trees"][~v["next_genre"]]["drum"].radiusSearch([1 - ((~v["midi_selection"] % 10) / 10), 1 - ((~v["midi_selection"] % 12) / 12), (~v["midi_selection"] % 10) / 11], 1).keep(8).choose.label;
			});
			if( ~v["midi_search_type"] == "sequence", {
				~v["midi_combinations"][~v["next_genre"]]["combination_id"] = (~v["midi_combinations"][~v["next_genre"]]["combination_id"] + 1) % (~v["midi_combinations"][~v["next_genre"]]["combinations"].size - 1);
				drum_choice = ~v["midi_combinations"][~v["next_genre"]]["combinations"][~v["midi_combinations"][~v["next_genre"]]["combination_id"]][2];
			});
		});

		("questa è la drum" ++ drum_choice).postln;
		// MIXA HOUSE?
		//if( ~v["next_genre"] == "House", { drum_choice = pad_choice });

		drum = ~v["midiDB"][~v["next_genre"]]["drum"][drum_choice].deepCopy;
		drum["notes"] = drum["variations"].foldAt(variation_index).deepCopy; // AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
		// Cambia gli accordi in base alla tabella di chord_change.txt
		new_pad_chords = ~f["change_chords"].value(pad["chords"], pad["num_recalls"],  if( ~v["generi_con_cadenza"].find([~v["next_genre"]]) != nil, {true}, {false}) , ~v["next_genre"]    );
		// Aggiorno il numero di volte che è stato chiamato questo pad
		pad["num_recalls"] = pad["num_recalls"] + 1;
		~v["midiDB"][~v["next_genre"]]["pad"][pad_choice]["num_recalls"] = ~v["midiDB"][~v["next_genre"]]["pad"][pad_choice]["num_recalls"] + 1;
		// Sistema le note in base ai nuovi accordi
		pad_grade_alteration = ~f["change_chords_from_progression"].value( pad["chords"], new_pad_chords );

		pad["chords"] = new_pad_chords;
		~v["tmp_song_initial_chords"] = pad["chords"].deepCopy;
		/* CAMBIO DI MODALITA' */
		if( ~v["modality"] != 0,{
			pad["chords"] = ~f["change_modality"].value( pad["chords"], ~v["modality"] );
		});
		/* FINE CAMBIO DI MODALITA' */

		if( ~v["scramble_instrs_enable"], {
			pad["instr"] = ~v["midiDB"][~v["next_genre"]]["pad"].values.choose["instr"]; // SCAMBIA STRUMENTI
		});
		//0.02.wait;
		pad["notes"] = ~f["add_progressions_to_notes"].value(pad["chords"], pad["notes"]);
		pad["notes"] = ~f["change_notes_harmonic"].value( pad["notes"], pad_grade_alteration, pad["scale"] );
		// Correggi noteOn prima di noteOff
		//pad["notes"] = ~f["correct_noteOff"].value(pad["notes"]);
		// Trasponi
		pad["notes"] = ~f["transpose_notes"].value(pad["notes"], ~v["transpose_factor"]);
		//0.02.wait;
		~v["new_tmp_song"].put("pad", pad);
		~v["new_tmp_song"].put("drum", drum);
		//0.02.wait;
		["key", "sampler", "lead", "bass"].do({ | type |
			var selection, choice, gradeAlteration, newNotes;
			if( type == "bass", {
				selection = pad_choice;
			}, {
				if( ~v["midi_search_type"] == "nearest", {
					selection = ~v["kd_trees"][~v["next_genre"]][type].radiusSearch([~v["kdtree_search_X"], ~v["kdtree_search_Y"], ~v["kdtree_search_Y"]], 1);
					selection = selection.wrapAt(pad["num_recalls"]).label;

					while( { ((selection == ~v["PRESENTATION_PAD_CHOICE_LOUNGE"]) && ~v["next_genre"] == "lounge") || ((selection == ~v["PRESENTATION_PAD_CHOICE_HOUSE"]) && ~v["next_genre"] == "House") || ((selection == ~v["PRESENTATION_PAD_CHOICE_TRAP"]) && ~v["next_genre"] == "trap") || ((selection == ~v["PRESENTATION_PAD_CHOICE_LOFI"]) && ~v["next_genre"] == "Lo-Fi") }, {
						"blocco in selection".postln;
						selection = ~v["kd_trees"][~v["next_genre"]][type].radiusSearch([~v["kdtree_search_X"], ~v["kdtree_search_Y"], ~v["kdtree_search_Y"]], 1);
						selection = selection.wrapAt(pad["num_recalls"]).label;
					});

				});
				if( ~v["midi_search_type"] == "random", {
					selection = ~v["kd_trees"][~v["next_genre"]][type].allNearest.scramble.wrapAt(~v["midi_selection"]).value[0].label;
				});
				if( ~v["midi_search_type"] == "walk", {
					selection = ~v["kd_trees"][~v["next_genre"]][type].radiusSearch([1 - ((~v["midi_selection"] % 10) / 10), 1 - ((~v["midi_selection"] % 12) / 12), (~v["midi_selection"] % 10) / 11], 1).keep(8).wrapAt(~v["midi_selection"]).label;
					//selection = selection.wrapAt(pad["num_recalls"]).label;
				});
				if( ~v["midi_search_type"] == "sequence", {
					if( type == "key", {
						selection = ~v["midi_combinations"][~v["next_genre"]]["combinations"][~v["midi_combinations"][~v["next_genre"]]["combination_id"]][1];

						while( { ((selection == ~v["PRESENTATION_PAD_CHOICE_LOUNGE"]) && ~v["next_genre"] == "lounge") || ((selection == ~v["PRESENTATION_PAD_CHOICE_HOUSE"]) && ~v["next_genre"] == "House") || ((selection == ~v["PRESENTATION_PAD_CHOICE_TRAP"]) && ~v["next_genre"] == "trap") || ((selection == ~v["PRESENTATION_PAD_CHOICE_LOFI"]) && ~v["next_genre"] == "Lo-Fi") }, {
							"blocco in selection".postln;
							~v["midi_combinations"][~v["next_genre"]]["combination_id"] = (~v["midi_combinations"][~v["next_genre"]]["combination_id"] + 1) % (~v["midi_combinations"][~v["next_genre"]]["combinations"].size - 1);
							selection = ~v["midi_combinations"][~v["next_genre"]]["combinations"][~v["midi_combinations"][~v["next_genre"]]["combination_id"]][1];
						});


					}, {
						selection = ~v["kd_trees"][~v["next_genre"]][type].allNearest.scramble.wrapAt(~v["midi_selection"]).value[0].label;
					});
				});
			});

			// MIXA HOUSE?
			//if( ~v["next_genre"] == "House", { selection = pad_choice });

			choice = ~v["midiDB"][~v["next_genre"]][type][selection].deepCopy;
			choice["notes"] = choice["variations"].foldAt(variation_index).deepCopy; // AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
			if( ~v["scramble_instrs_enable"] && (type != "sampler"), {
				choice["instr"] = ~v["midiDB"][~v["next_genre"]][type].values.choose["instr"]; // SCAMBIA STRUMENTI
			});
			//0.02.wait;
			gradeAlteration = ~f["change_chords_from_progression"].value( choice["chords"], pad["chords"] );
			//0.02.wait;

			choice["notes"] = ~f["add_progressions_to_notes"].value(pad["chords"], choice["notes"]);
			if( (type == "bass") || (type == "key"), {
				newNotes = ~f["change_notes_harmonic"].value( choice["notes"], gradeAlteration, pad["scale"] );
			}, {
				newNotes = ~f["change_notes_harmonic"].value( choice["notes"], gradeAlteration, pad["scale"] );
			});
			choice["notes"] = newNotes;
			// Trasponi
			choice["notes"] = ~f["transpose_notes"].value(choice["notes"], ~v["transpose_factor"]);
			//0.02.wait;
			~v["new_tmp_song"].put(type, choice);
		});
		~v["midi_selection"] = ~v["midi_selection"] + 1;
		if( ~v["midi_search_type"] == "sequence", {
			~v["midi_combinations"][~v["next_genre"]]["combination_id"] = (~v["midi_combinations"][~v["next_genre"]]["combination_id"] + 1) % (~v["midi_combinations"][~v["next_genre"]]["combinations"].size - 1);
		});
	}.play(AppClock);
})



/*
\subsection{Inutile? Probabilmente un refuso}
\begin{verbatim}
*/

.put("build_conductor_tick_counter_rout", {
	~f.put("conductor_tick_counter_rout", Routine{
		var tick_counter = 0;
		var currentChord, lastChord = nil, currentProgression;
		~v["has_to_break"] = false;
		8.do({ | id |
			~f.at("update_structure").value(id * ~v["tpqn"] * 4);
			if( id == 7, { ~v["drum_delay"] = true && ~v["drum_delay_8"] });
			(~v["tpqn"] * 4).wait;
		});
		~v["has_to_break"] = true;
	});
})

/*
\subsection{Player di brani}
\begin{verbatim}
*/




//~v.put("structure_popup", ~v["structures"][~v["next_genre_selection"]]);

.put("build_conductor_v2", {
	// Aggiorna tempo lancio pubblicità da quando ho premuto tasto play

	//potrei mettere lo structure popup qui e applicare uno scramble, così ogni volta che il attivo  server genera un array strutture diverso, dopo inizio a leggerlo dall'indice 0 e muovo la struttura. ~struct farebbe questo
	~v["next_genre"] = ~v["all_genres"].scramble.rotate(-1).choose;

	~array_strutture = ~v["structures"][~v["next_genre_selection"]];
	~array_strutture = ~array_strutture.scramble;
	//~v["clock_tempo_change_knob"] = ~newtime;
    ~new_enable_prob = [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1];
 //~new_enable_prob.size;
	Routine{

/*
		~v["next_genre"] = ~v["next_genre_selection"];
		//~v["next_genre"] = [1,2].scramble[0];
		~v["genre"] = ~v["next_genre"];
*/
		// CAMBIO VOLUMI SERVER
		if( ~v["genre"] == "House", {
			s.volume_( 1 );
		}, {
			if( ~v["genre"] == "lounge", {
				s.volume_( 3 );
			}, {
				s.volume_( 0 );
			});
		});

		//"Genero tmp_song".postln;
		//1.do({ ~f["generate_tmp_song"].value(); });
		//"Genero next_tmp_song".postln;
		1.do({ ~f["generate_tmp_song_at_runtime"].value(); });
		~v["clock"].tempo_(1);
		//"Aspetto 2 sec. circa".postln;
		(1).wait;
		~f["update_clock"].value(~v["clock_change_perc"]);

		inf.do({ | track_id |
			"\t\t\t\tINIZIO".postln;
			// Aggiorna il genere
			~v["genre_changed"] = false;
			~v["genre"] = ~v["next_genre"];
			~v["players"].collect({ | player | player.rout.stop;  });

			~v["tmp_song"] = ~v["new_tmp_song"]; // Aggiorna brano
			~v["players"] = ~f["loadTrack"].value( ~v["genre"], ~v["tmp_song"] ); // Carica player
			// Aggiorna struttura

			~array_strutture = ~array_strutture.rotate(-1);
			~struct = ~array_strutture[0];
			~f["load_structure"].value(~struct);   //CAMBIATA

			//~f["load_structure"].value( ~v["next_structure"] );
			("Caricata struttura: " ++ ~struct).postln;  //CAMBIATA
			~f["update_structure_now"].value(0);
			~v.put("structure_id",0);
			~f["update_clock"].value(~v["clock_change_perc"]); // Aggiorna il clock
			// Carica i preset del DSP per i player
			Routine{ ~v["buffer_load_time"].wait; ~f["recall_DSP_preset"].value(~d); }.play(~v["clock"]);

			// Itera tutte le parti della struttura
			block({ | break |
				var has_to_break = false;
				~v.at("structure").do({ | structure, structure_id |
					var half = (~v["structure"].size / 2).asInteger;
					~v["structure_id"] = structure_id; ~f["flush_structure"].value;
					// Fai partire la routine di conteggio dei tick
					~f.at("conductor_tick_counter_rout").stop;
					~f.at("build_conductor_tick_counter_rout").value;
					~f.at("conductor_tick_counter_rout").play(~v.at("clock"));
					// Carica i nuovi player
					if( structure_id > 0, {
						~v["players"].collect({ | player | player.rout.stop;  });
						~v["players"] = ~v["new_players"];
					});
					// Se in mezzo al brano, lancia suoni atmos


					/* TOLTO IOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
					if( structure_id == (half), {
						~f["play_atmos_streaming"].value ;
					});
*/
					// Fai partire i player correnti
					~v.at("players").collect({ | player | player.rout.play(~v.at("clock")); });

					//if( ~v["genre_changed"] == true, { structure_id = (~v.at("structure").size - 1) });


					if(structure_id < (~v.at("structure").size - 1), {
						//(~v["average_8bar_dur"] * 2 / 3 ).asInteger.do({ 1.wait; });
						( ~v["average_8bar_dur"] - ( 3 * ~v["tpqn"] * ~v["tmp_song"]["pad"]["timeSignature"] ) ).do({ 1.wait; });

						// Carica nuovi player
						Routine{ ~v["new_players"] = ~f["loadTrack"].value( ~v["genre"], ~v["tmp_song"] ); }.play(AppClock);

						if( (structure_id == 0) || (structure_id == (~v.at("structure").size / 2).trunc) || (structure_id == (~v.at("structure").size -1)), { ~v["drum_delay_8"] = true }, { ~v["drum_delay_8"] = false });

						if( ~v["genre_changed"] == true, {
							has_to_break = true;
							~f["play_transition_streaming"].value;  ///TOLTO IOOOOOOOOOOOOOO
							~v["next_genre"] = ~v["next_genre_selection"];
							////////////////////("questo è il nuovo genere PORCODDIO" ++ ~v["next_genre"]).postln;


							Routine{
								if(~v.at("modulation_enable").value == true, {
									~v.put("transpose_factor", (~v.at("transpose_factor") + [-5, 7].choose) % 12  );
									//~v.at("modulation_enable").valueAction_(0);
								});
								~f["generate_tmp_song_at_runtime"].value();
							}.play(AppClock);
						});

						//((~v["average_8bar_dur"] * 1 / 3) - ~v["conductor_tick_correction"]).do({ 1.wait });
						( ( 3 * ~v["tpqn"] * ~v["tmp_song"]["pad"]["timeSignature"] ) - ~v["conductor_tick_correction"] ).do({ 1.wait; });


						/*  TOLTO ARRESTO FORZATOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
						if( (~v["genre_changed"] == true) && (has_to_break == true), {
							var wait_condition = Condition(false);
							Routine{~v["next_structure"] = (~struct);}.play(AppClock); // tolto items prima .wrapAt

							//~v.at("structure_popup")
	//Routine{~v.at("structure_popup").valueAction_( (~v.at("structure_popup").value + 1) %  ~v.at("structure_popup").items.size);}.play(AppClock); tolto items prima di .size
							//  (~v["buffer_load_time"] / 16)
							//Routine{ (~v["buffer_load_time"] / 16).wait; wait_condition.test = true; wait_condition.signal; }.play(~v["clock"]);
							Routine{ 2.wait; wait_condition.test = true; wait_condition.signal; }.play(AppClock);
							wait_condition.wait;
							"\t\t\t\tFINITO forzato".postln;
							break.value;
						});
						*/


					}, {

						( ~v["average_8bar_dur"] - ( 3 * ~v["tpqn"] * ~v["tmp_song"]["pad"]["timeSignature"] ) ).do({ 1.wait; });
						// Suona transizione per nuovo brano
						~f["play_transition_streaming"].value;   //////AVEVO TOLTO **********************************
						// Carica il nuovo genere da selezione GUI
						~v["next_genre"] = ~v["next_genre_selection"];

						~v["next_genre"] = ~v["all_genres"].choose;
						("questo sarà il nuovo genere " ++ ~v["next_genre"]).postln;
						// DEVO GENERARE LA TRACCIA SEGUENTE SU UNA ROUTINE CHE GIRA SU UN THREAD PARALLELO, FINCHE' ASPETTO CHE FINISCA L'ULTIMO GIRO DELLA TRACCIA CORRENTE
						Routine{
							if(~v.at("modulation_enable").value == true, {
								~v.put("transpose_factor", (~v.at("transpose_factor") + [-5, 7].choose) % 12  );
								//~v.at("modulation_enable").valueAction_(0);
							});
							~f["generate_tmp_song_at_runtime"].value();
						}.play(AppClock);
						( ( 3 * ~v["tpqn"] * ~v["tmp_song"]["pad"]["timeSignature"] ) - ~v["conductor_tick_correction"] ).do({ 1.wait; });

						// Aggiorna la struttura
						Routine{

							//POTREI PROVARE A INSERIRE QUI TEMPO CHANGE

							//~v["clock_tempo_change_knob"] = ~v["clock_tempo_change_knob_mio"];
							~v["next_tructure"] = (~struct);
							//~v["transpose_factor"] = [6, 6].choose ;

							//~trasposizione = [ 0, 4].choose;
							//~v["clock_tempo_change_knob"]= ~newtime;  ///qui non cambia nulla


						}.play(AppClock);  ///ECCOLOOOOOOO


						// tolto items prima .wrapAt
	//Routine{~v.at("structure_popup").valueAction_( (~v.at("structure_popup").value + 1) %  ~v.at("structure_popup").size );}.play(AppClock); //tolto items prima di .size
						"\t\t\t\tFINITO normalmente".postln;
					});
				});
			});
		});
	};
})


/*
\section{Gestione delle strutture musicali}
\subsection{Creazione GUI delle strutture}
\begin{verbatim}
*/


/*
\subsection{Caricamento struttura}
\begin{verbatim}
*/
.put("load_structure", { | structure_file_name | // bisogna chiamare build_structure_grid prima!!
	var file;

	///////////////////////////////////////////////////////////////////////////  QUESTO CAMBIA I BPM A TEMPO CON LA STRUTTURA
           //~newtime = 0.5;

	/*
	SE IL TEMPO CADE NELL'ULTIMA FASCIA ORARIA, E NON HO INIZIALIZZATO ~newtime, da un errore relativo al * 0.08.
	Inspiegabile!!!!!!!!!!!
	Inserire una fascia oraria in più?
	anche fittizzia di tipo 1 minuto???
	risolvere o inizializzare la variabile ~newtime!!!!!!!

	*/



	       //CAMBIO DI TEMPO E DI CLOCK SINCRONIZZATO CON NUOVA STRUTTURA
	       //~newtime = 0.5;
	      // ~bufatmos.free;
          // ~v["clock_tempo_change_knob"]= ~newtime;
	       ~v["clock_tempo_change_knob"]= 0.5;
	       ~v["clock_tempo_change_knob"].postln;
	       ~tempo_change = (~v["clock_tempo_change_knob"] * 0.08) - 0.04;
	       ~tempo_change.postln;
		   ~v["clock_change_perc"] = ~tempo_change;
		   ~f["update_clock"].value(~v["clock_change_perc"]);


           //CAMBIO DI STRUMENTI ACCESI O SPENTI CON NUOVA STRUTTURA

	        //~new_enable_prob = []; //INIZIALIZZA
	        ~v["enable_prob"] = ~new_enable_prob;
	        ("Strumenti accesi" ++ ~v["enable_prob"]).postln;

	        //~v["enable_prob"] = ~new_enable_prob;

           //////////// ~f["play_atmos_streaming"].value ;   //MESSO IOOOOOOOOOOOOOO
	//PARTE DA INIZIO STRUTTURA E NE PARTE UN ALTRO CON UNA NUOVA STRUTTURA DEVO TROVARE IL MODO DI NON FARLI SOVRAPPORRE; QUANDO NE PARTE UNO NUOVO FINISCE IL VECCHIO



/*   QUESTO TEORICAMENTE SPOSTA IN MINORE BASTA CAMBIARE ~minore
		~minore = true;
	    ~v["change_to_minor"] = 0;
	  ~v.put("change_to_minor", false);
	   (
	   if( (~minore == true) && (~v["change_to_minor"] == false) , {
			~v["change_to_minor"] = true;
			~v["transpose_factor"] = ~v["transpose_factor"] - 3;   //MINOREEEE
		});
	   );
	   (
		if( (~minore == false) && (~v["change_to_minor"] == true) , {     //MAGGIORe
			~v["change_to_minor"] = false;
			~v["transpose_factor"] = ~v["transpose_factor"] + 3;
		});
	   );
*/
	("questo è il genere " ++ ~v["genre"] ).postln;

			("[debug] structure_file_name: "++structure_file_name).postln;   //****************Che fa?
			file= File.open(~v.at("structure_folder") ++ ~v["genre"] +/+ structure_file_name ++ ".txt", "r+");
			~v.put("structure", file.readAllString.interpret);
			file.close;
	("[debug] ~structure_NORMAL: "++ ~v["structure"]).postln;

	//~v.at("structure_grid").put(0, 0, ~v["structure"][0]);
	~v.put("structure_id", 0);
})

/*
\subsection{Aggiornamento sotto-struttura ( in differita )}
\begin{verbatim}
*/
.put("update_structure", { | current_tick |
	var this_structure_id =~v.at("structure_id").copy;
	var structure_index = (ControlSpec(0, ~v["tmp_song"]["pad"]["eot"]).unmap(current_tick) * (~v.at("structure")[0][0].size)).trunc.asInteger;
	~v.at("structure")[this_structure_id].flop[structure_index].collect({|enable, index| ~v.put(~v.at("enable_list").at(index), enable.asBoolean && ( ~v.at("enable_prob").at(index).coin.asBoolean || ~v["WOW"] ) ); [~v.at("enable_list").at(index), ~v[~v.at("enable_list").at(index)]]; });
})

/*
\section{GUI e controllo DSP}
\subsection{Creazione singolo canale DSP}
\begin{verbatim}
*/

.put("build_channel_DSP", { | instr, in=20, out=40 |
	var dsp=();
	var comp_t_s, comp_sa_s, comp_sb_s, comp_atk_s, comp_rel_s, comp_e, pan_s, rev_w_s, rev_r_s, rev_d_s, rev_e, gain_out_pre_s, gain_out_post_s, comp_e_b, rev_conv_p, low_shelf_e, bp1_e, bp2_e, bp3_e, bp4_e, hi_shelf_e, save_button, name_text;



//RIATTIVATA
	dsp[\update_all_params] = {
		[comp_t_s,/* comp_sa_s, comp_sb_s, comp_e, pan_s, rev_w_s, rev_e, gain_out_pre_s, gain_out_post_s, low_shelf_e, bp1_e, bp2_e, bp3_e, bp4_e, hi_shelf_e*/ rev_conv_p].do({ | widget, id |
			if(widget != rev_conv_p, {
				widget.valueAction_(widget.value);
			});
		});
	};

	dsp[\update_all_params] = 1;
    ////////////////////////////////////////////RIATTIVA DSP

		dsp[\update_manual] = {

		//name_text.string_(dsp[\params].at("name")).postln;


		comp_t_s = { | val |
		val = ~v.at("thd_spec").map(val.value).round(0.0001);
		dsp[\synth].set(\comp_t, val);
		dsp[\params].put("comp_t", val);
	    };

		{ | val |
		val = ~v.at("comp_sa_spec").map(val.value).round(0.0001);
		dsp[\synth].set(\comp_sa, val);
		dsp[\params].put("comp_sa", val);
	    };

		{ | val |
		val = ~v.at("comp_sb_spec").map(val.value).round(0.0001);
		dsp[\synth].set(\comp_sb, val);
		dsp[\params].put("comp_sb", val);
	    };

		{ | val |
		val = ~v.at("comp_atk_spec").map(val.value);
		dsp[\synth].set(\comp_atk, val);
		dsp[\params].put("comp_atk", val);
	    };

		{ | val |
		val = ~v.at("comp_rel_spec").map(val.value);
		dsp[\synth].set(\comp_rel, val);
		dsp[\params].put("comp_rel", val);
	    };

		{ | val |
		dsp[\params].put("comp_e", val.value;);
		dsp[\synth].set(\comp_e, dsp[\params].at("comp_e"));
	    };

		{ | val |
		dsp[\params].put("low_shelf_e", val.value);

		dsp[\synth].set(\low_shelf_e, dsp[\params].at("low_shelf_e"));

		    if("low_shelf_e"  == 1, {
			dsp[\synth].set(\low_shelf_f, dsp[\params].at("low_shelf_f"));
			dsp[\synth].set(\low_shelf_g, dsp[\params].at("low_shelf_g"));
			});
	    };

		{ | val |
		dsp[\params].put("bp1_e", val.value);
		dsp[\synth].set(\bp1_e, dsp[\params].at("bp1_e"));
		if(val.value == 1, {
			dsp[\synth].set(\bp1_f, dsp[\params].at("bp1_f"));
			dsp[\synth].set(\bp1_g, dsp[\params].at("bp1_g"));
		});
	    };

		{ | val |
		dsp[\params].put("bp2_e", val.value);
		dsp[\synth].set(\bp2_e, dsp[\params].at("bp2_e"));
		if(val.value == 1, {
			dsp[\synth].set(\bp2_f, dsp[\params].at("bp2_f"));
			dsp[\synth].set(\bp2_g, dsp[\params].at("bp2_g"));
		});
	    };

		{ | val |
		dsp[\params].put("bp3_e", val.value);
		dsp[\synth].set(\bp3_e, dsp[\params].at("bp3_e"));
		if(val.value == 1, {
			dsp[\synth].set(\bp3_f, dsp[\params].at("bp3_f"));
			dsp[\synth].set(\bp3_g, dsp[\params].at("bp3_g"));
		});
	    };

		{ | val |
		dsp[\params].put("bp4_e", val.value);
		dsp[\synth].set(\bp4_e, dsp[\params].at("bp4_e"));
		if(val.value == 1, {
			dsp[\synth].set(\bp4_f, dsp[\params].at("bp4_f"));
			dsp[\synth].set(\bp4_g, dsp[\params].at("bp4_g"));
		});
	    };

		{ | val |
		dsp[\params].put("hi_shelf_e", val.value);
		dsp[\synth].set(\hi_shelf_e, dsp[\params].at("hi_shelf_e"));
		if(val.value == 1, {
			dsp[\synth].set(\hi_shelf_f, dsp[\params].at("hi_shelf_f"));
			dsp[\synth].set(\hi_shelf_g, dsp[\params].at("hi_shelf_g"));
		});
	    };

		//pan_s.valueAction_(~v.at("pan_spec").unmap(dsp[\params].at("pan")));

		//rev_w_s.valueAction_(~v.at("rev_w_spec").unmap(dsp[\params].at("rev_w")));

		//gain_out_pre_s.valueAction_(~v.at("gain_out_spec").unmap(dsp[\params].at("pre_gain")));

        { | val |
		val = ~v.at("gain_out_spec").map(val.value).round(0.0001);
		dsp[\synth].set(\pre_gain, val);
		dsp[\params].put("pre_gain", val);
	    };

		//gain_out_post_s.valueAction_(~v.at("gain_out_spec").unmap(dsp[\params].at("post_gain")));

        { | val |
		val = ~v.at("gain_out_spec").map(val.value).round(0.0001);
		dsp[\synth].set(\post_gain, val);
		dsp[\params].put("post_gain", val);
	    };

	    if(rev_conv_p == 1 , {(dsp[\params].at("convfile"))}, {(0)});
	};

		dsp[\update_manual_no_popup_conv] = {
	{ | val |
		val = ~v.at("thd_spec").map(val.value).round(0.0001);
		dsp[\synth].set(\comp_t, val);
		dsp[\params].put("comp_t", val);
	    };

		{ | val |
		val = ~v.at("comp_sa_spec").map(val.value).round(0.0001);
		dsp[\synth].set(\comp_sa, val);
		dsp[\params].put("comp_sa", val);
	    };

		{ | val |
		val = ~v.at("comp_sb_spec").map(val.value).round(0.0001);
		dsp[\synth].set(\comp_sb, val);
		dsp[\params].put("comp_sb", val);
	    };

		{ | val |
		val = ~v.at("comp_atk_spec").map(val.value);
		dsp[\synth].set(\comp_atk, val);
		dsp[\params].put("comp_atk", val);
	    };

		{ | val |
		val = ~v.at("comp_rel_spec").map(val.value);
		dsp[\synth].set(\comp_rel, val);
		dsp[\params].put("comp_rel", val);
	    };

		{ | val |
		dsp[\params].put("comp_e", val.value);
		dsp[\synth].set(\comp_e, dsp[\params].at("comp_e"));
	    };

		{ | val |
		dsp[\params].put("low_shelf_e", val.value);
		dsp[\synth].set(\low_shelf_e, dsp[\params].at("low_shelf_e"));

		    if("low_shelf_e"  == 1, {
			dsp[\synth].set(\low_shelf_f, dsp[\params].at("low_shelf_f"));
			dsp[\synth].set(\low_shelf_g, dsp[\params].at("low_shelf_g"));
			});
	    };

		{ | val |
		dsp[\params].put("bp1_e", val.value);
		dsp[\synth].set(\bp1_e, dsp[\params].at("bp1_e"));
		if(val.value == 1, {
			dsp[\synth].set(\bp1_f, dsp[\params].at("bp1_f"));
			dsp[\synth].set(\bp1_g, dsp[\params].at("bp1_g"));
		});
	    };

		{ | val |
		dsp[\params].put("bp2_e", val.value);
		dsp[\synth].set(\bp2_e, dsp[\params].at("bp2_e"));
		if(val.value == 1, {
			dsp[\synth].set(\bp2_f, dsp[\params].at("bp2_f"));
			dsp[\synth].set(\bp2_g, dsp[\params].at("bp2_g"));
		});
	    };

		{ | val |
		dsp[\params].put("bp3_e", val.value);
		dsp[\synth].set(\bp3_e, dsp[\params].at("bp3_e"));
		if(val.value == 1, {
			dsp[\synth].set(\bp3_f, dsp[\params].at("bp3_f"));
			dsp[\synth].set(\bp3_g, dsp[\params].at("bp3_g"));
		});
	    };

		{ | val |
		dsp[\params].put("bp4_e", val.value);
		dsp[\synth].set(\bp4_e, dsp[\params].at("bp4_e"));
		if(val.value == 1, {
			dsp[\synth].set(\bp4_f, dsp[\params].at("bp4_f"));
			dsp[\synth].set(\bp4_g, dsp[\params].at("bp4_g"));
		});
	    };

		{ | val |
		dsp[\params].put("hi_shelf_e", val.value);
		dsp[\synth].set(\hi_shelf_e, dsp[\params].at("hi_shelf_e"));
		if(val.value == 1, {
			dsp[\synth].set(\hi_shelf_f, dsp[\params].at("hi_shelf_f"));
			dsp[\synth].set(\hi_shelf_g, dsp[\params].at("hi_shelf_g"));
		});
	    };

		//pan_s.valueAction_(~v.at("pan_spec").unmap(dsp[\params].at("pan")));

		//rev_w_s.valueAction_(~v.at("rev_w_spec").unmap(dsp[\params].at("rev_w")));

		//gain_out_pre_s.valueAction_(~v.at("gain_out_spec").unmap(dsp[\params].at("pre_gain")));


        { | val |
		val = ~v.at("gain_out_spec").map(val.value).round(0.0001);
		dsp[\synth].set(\pre_gain, val);
		dsp[\params].put("pre_gain", val);
	    };

		//gain_out_post_s.valueAction_(~v.at("gain_out_spec").unmap(dsp[\params].at("post_gain")));

        { | val |
		val = ~v.at("gain_out_spec").map(val.value).round(0.0001);
		dsp[\synth].set(\post_gain, val);
		dsp[\params].put("post_gain", val);
	    };
	};

	dsp[\set_params] = { | params |
		dsp[\params] = params;
		dsp[\update_manual].value;
	};

	dsp[\params] = Dictionary.new
	.put("in", in)
	.put("out", out)
	.put("low_shelf_f", 20)
	.put("low_shelf_g", 0)
	.put("low_shelf_q", 1)
	.put("low_shelf_e", 0)
	.put("hi_shelf_f", 18000)
	.put("hi_shelf_g", 0)
	.put("hi_shelf_q", 1)
	.put("hi_shelf_e", 0)
	.put("bp1_f", 220)
	.put("bp1_g", 0)
	.put("bp1_q", 1)
	.put("bp1_e", 0)
	.put("bp2_f", 660)
	.put("bp2_g", 0)
	.put("bp2_q", 1)
	.put("bp2_e", 0)
	.put("bp3_f", 1220)
	.put("bp3_g", 0)
	.put("bp3_q", 1)
	.put("bp3_e", 0)
	.put("bp4_f", 4220)
	.put("bp4_g", 0)
	.put("bp4_q", 1)
	.put("bp4_e", 0)
	.put("comp_t", 0.75)
	.put("comp_sb", 1)
	.put("comp_sa", 1)
	.put("comp_atk", 0.03)
	.put("comp_rel", 0.2)
	.put("comp_e", 0)
	.put("limit_l", 1)
	.put("limit_e", 0)
	.put("pan", 0)
	.put("rev_w", 0)
	.put("rev_r", 0.45)
	.put("rev_d", -8)
	.put("rev_e", 0)
	.put("convfile", 0)
	.put("pre_gain", 0)
	.put("post_gain", 0)
	.put("name", instr);
	dsp[\params_default] = dsp[\params].copy;
	dsp[\instr] = dsp[\params].at("name");
	dsp[\recall_preset] = { | newInstr=nil |
		if( newInstr != nil, { dsp[\instr] = newInstr; dsp[\params]["name"] = newInstr; });
		dsp[\preset_file_path] = (~v.at("sampleDB_folder") ++ "preset" +/+ dsp[\instr] ++ ".sctxar");
		// se non trova il file lo crea
		if(File.exists(dsp[\preset_file_path]).not, {
			dsp[\store_preset].value;
		});
		Archive.read(dsp[\preset_file_path]);
		dsp[\params] = Archive.global.at(\preset)[\preset];
		dsp[\update_manual].value();
	};

	dsp[\store_preset] = {
		var event = ();
		dsp[\preset_file_path] = (~v.at("sampleDB_folder") ++ "preset" +/+ dsp[\params].at("name") ++ ".sctxar");
		event[\preset] = dsp[\params];
		Archive.global.put(\preset, event);
		Archive.write(dsp[\preset_file_path]);
	};


	dsp[\rebuild_synth] = {
		var convfile = ~v.at("convDB").values.as(Array)[dsp[\params].at("convfile")];
		if(convfile == nil, { convfile = ~v.at("convDB").values[0]; });
		try( { dsp[\synth].release(5); dsp[\synth] = nil; }, {} );
		if(instr.contains("master").not, {
			if( (dsp[\synth].class == Synth).not, {
				dsp[\synth] = Synth.tail(~v.at("efx_group"), ("DSP_" ++ instr.split($_)[0]).asSymbol, [\in, in, \out, ~v.at("master_input")/*, \irbufnum, convfile*/]);
			});
		}, {
			if( (dsp[\synth].class == Synth).not, {
				dsp[\synth] =Synth.after(~v.at("efx_group"), \DSP2_FFT, [\in, ~v.at("master_input"), \out, ~v.at("master_output")/*, \irbufnum, convfile*/]);
				if( ~v["genre"] == "House", { dsp[\synth].set(\fft, 0) } ,{ dsp[\synth].set(\fft, 1) });
			});
		});
		dsp[\update_manual_no_popup_conv].value;
	};

  /*
	rev_conv_p = PopUpMenu().
	             items_(~v.at("convDB").keys.as(Array))
	             .action_({ | id |
		         id = 0;
		         // ~v.at("convDB").keys.as(Array)[id];
		         //dsp[\params].put("convfile", id);
		           dsp[\rebuild_synth].value();
		         //dsp[\update_all_params].value();
	                     })
	             .maxWidth_(120);
	*/
   rev_conv_p = 1;
   if(rev_conv_p == 1, {
		dsp[\rebuild_synth].value();
		dsp[\update_all_params].value()
	}, {});

	dsp[\recall_preset].value(instr);
	dsp
})



/*
\subsection{Istanziamento singolo strip DSP}
\begin{verbatim}
*/
.put("build_DSP_single", { | in, out |
	~f.at("build_channel_DSP").value("test", in, out);
})

/*
\subsection{Istanziamento strip DSP dei campionatori}
\begin{verbatim}
*/

.put("build_DSP_strip", {
	var dsp_strip = [];
	~v["tmp_song"].keysValuesDo({ | type, dict |
		dsp_strip = dsp_strip ++ [ ~f.at("build_channel_DSP").value(dict["instr"], ~v["out_channels"][type], ~v["master_input"]) ];
	});
	dsp_strip.postln;
})

/*
\subsection{Istanziamento strip DSP canale master}
\begin{verbatim}
*/
.put("build_DSP_master", {
	~f.at("build_channel_DSP").value( "master", ~v.at("master_input"), ~v.at("master_output"));
})

/*
\subsection{Caricamento DSP}
\begin{verbatim}
*/
.put("load_DSP", {
	var channels, master;
	~v.put("efx_group", Group.new(s, addAction: 'addToTail'));
	channels = ~f.at("build_DSP_strip").value;             /////////////instru drum_102
	master = [~f.at("build_DSP_master").value];            /////////////
	channels ++ master
})

/*
\subsection{Recall preset per DSP}
\begin{verbatim}
*/
.put("recall_DSP_preset", { | dsp_vector |
	Routine{
		dsp_vector.collect({|dsp|
			~v["instrs"].do({ | instr |
				if( dsp[\instr].contains(instr), {
					//("Recall "+ instr).postln; /////////////////////MOSTRA RECALL PRESET
					dsp[\recall_preset].value(~v["tmp_song"][instr]["instr"]);
					//("Fine recall "+ instr).postln;
				});
			});
		});
		if( ~v["genre"] == "House", { ~d.last[\synth].set(\fft, 0) } ,{ ~d.last[\synth].set(\fft, 1) });
	}.play(AppClock);
})

/*
\subsection{Interfaccia grafica generale}
*/

.put("show_GUI", { | dsp_vector |
	var dsp, grid, win, view, bgimage, genre, structures, modulation, minor_enable, scramble_instrs, start, kdtree_2Dslider, event_density_knob, init_win, /*feature_space,*/ mixer, mode_selection /*driver_selection*/;
	var allow_osc_check;
	// Mixer dei vari stream

	// Crea i KDTree
	~f["create_kd_trees"].value;

	// PopUp selezione tipo di generazione Lead
	/*
	~v.put("modality_popup", PopUpMenu().background_(~v["bgcolor"]));
	~v["modality_popup"].items_(~v["modalities"])
	.action_({ | val |
		~v["modality"] = ~v["modalities_wrap"].wrapAt(val.value);
	}).valueAction_(1);

	*/
/*
	~v.put("modality_popup", ~v["modalities"]);

	~v["modalities"][1] = ~v["modalities_wrap"].wrapAt(1);

	~v["modality_popup"] = ~v["modalities"];
	~v["modality"] = ~v["modalities_wrap"].wrapAt(4)
	~v["modalities_wrap"]
	*/
	//~v["modalities_wrap"].wrapAt(5)

    //~v["modality"] = ~v["modalities"][0];

	~v["modality"] = ~v["modalities_wrap"].wrapAt(0);

	// CheckBox modulazione
	/*
	~v.put("modulation_enable",  CheckBox().action_({ | val |
	}).valueAction_(0));
	*/
	~v.put("modulation_enable", true);
	modulation = ~v.at("modulation_enable");

	// CheckBox major/minor
	/*
	~v.put("minor_enable", CheckBox().action_({ | val |
		~v.put("change_to_minor", val.value);
	}).valueAction_(0));
	minor_enable = ~v.at("minor_enable");
	*/
	~v.put("minor_enable", 1);

	// CheckBox relative minor
	/*
	~v.put("relative_minor_enable", CheckBox().action_({ | val |
		if( (val.value == true) && (~v["change_to_minor"] == false) , {
			~v["change_to_minor"] = true;
			~v["transpose_factor"] = ~v["transpose_factor"] - 3;
		});
		if( (val.value == false) && (~v["change_to_minor"] == true) , {
			~v["change_to_minor"] = false;
			~v["transpose_factor"] = ~v["transpose_factor"] + 3;
		});
	}).valueAction_(0));
	*/


	~v.put("relative_minor_enable", 1);

	// CheckBox scambio strumenti
	/*
	~v.put("scramble_instrs_checkbox", CheckBox().action_({ | val |
		~v.put("scramble_instrs_enable", val.value);
	}).valueAction_(0));
	scramble_instrs = ~v.at("scramble_instrs_checkbox");
*/

	// Knob densità degli eventi MIDI
	/*
	~v["density_knobs"] = ["drum", "bass", "pad", "key", "sampler", "lead"].collect({ | instr |
		~v.put(instr ++ "_density_knob", Knob().color_([~v["bgcolor"], Color.white, Color.white, ~v["bgcolor"]]).action_({ | val |
			~v.put("" ++ instr ++ "_event_density", 1.0 - val.value);
		}).valueAction_(1.0));
	});

*/
	~v["density_knobs"] = 1;
	//~v["change_to_wow"] = 0;
/*
	Routine.new(
		{
			loop({
			~minute	= Date.localtime.minute;
            ~minute.postln;
				5.wait;
			})
	}).play(AppClock);
*/
/////////////////////////////////////////////
/*
		Routine.new(
	{
		loop({
			//~hour = Date.localtime.hour;
			//~hour = 8;
				//~hour = ~hour.wrap(0, 24);
			//~hour.postln;

			~minute = Date.localtime.minute; // COMMENTA QUESTA LINEA CON // SE VUOI AZIONARE QUELLA SOTTO
			//~minute = 12; //orario a piacere, puoi selezionare le varie fasce
				//OGNI VOLTA DEVI SALVARE E RI-LANCIARE LA FASE DI INIT

			//~minute.postln;
			//~v["kdtree_search_X"] = rand(0.999);
			//~v["kdtree_search_Y"] = rand(0.999);
			//~v["kdtree_search_Z"] =	rand(0.999);
			//~v["kdtree_2Dslider"].setXYActive(~v["kdtree_search_X"],~v["kdtree_search_Y"] );

    (
	//if( (( ~hour >= 7 ) && ( ~hour < 9)),
	if( (( ~minute >= 0 ) && ( ~minute < 3)),
						{  // [10:00-13:00] & [16:00-19:00] --> maggiore affluenza
		  	            ~new_enable_prob = [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1];

						//~newtime = 0.5;  //era 1, con 1.25 dovre aumentare bpm   -0.28 diminuisce di 5
						//"fascia 7/9".postln;
					    ~newtime = 0.5;
						~v["next_genre_selection"] = ~v["all_genres"][1];
	                    ~v["structures"][~v["next_genre_selection"]];
						~f["create_kd_trees"].value;
						~v["genre_changed"] = true;
						~array_strutture = ~v["structures"][~v["next_genre_selection"]];
	                    ~array_strutture = ~array_strutture.scramble;
	});
	);

		(
		//if( (( ~hour >= 9 ) && ( ~hour < 12)),
		if( (( ~minute >= 3 ) && ( ~minute < 6)),
						{
                         //STRUMENTI ACCESI O SPENTI
						~new_enable_prob = [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1];
                         // STAMPA FASCIA ORARIA
						//"fascia 9/12".postln;
						// VALORE PER CAMBIO BPM CON NUOVA STRUTTURA
					    ~newtime = 0.5;
						//CAMBIO DI GENERE CON NUOVA STRUTTURA
						~v["next_genre_selection"] = ~v["all_genres"][2];
						//CAMBIO DI DATABASE PER LEGGERE STRUTTURE NUOVO GENERE
	                    ~v["structures"][~v["next_genre_selection"]];
						~f["create_kd_trees"].value;
						~v["genre_changed"] = true;
						//SCRAMBLE CASUALE NUOVE STRUTTURE PER LETTURA SENZA RIPETIZIONI STESSA STRUTTURA
						~array_strutture = ~v["structures"][~v["next_genre_selection"]];
	                    ~array_strutture = ~array_strutture.scramble;
	                    });
		);

				//CERTO PROBLEMA CHE è maggiore di 22 il 23, ma non minore di 4, devo fare wrap
			(
						//if( (( ~hour >= 22 ) || ( ~hour < 4)),
						if( (( ~minute >= 6 ) && ( ~minute < 9)),
						{

						~new_enable_prob = [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1];
						//"fascia 22/4".postln;
					    ~newtime = 0.5;
						~v["next_genre_selection"] = ~v["all_genres"][3];
	                    ~v["structures"][~v["next_genre_selection"]];
						~f["create_kd_trees"].value;
						~v["genre_changed"] = true;
						~array_strutture = ~v["structures"][~v["next_genre_selection"]];
	                    ~array_strutture = ~array_strutture.scramble;
	});
	);

				//QUESTO è UN BLOCCO
							(
						//if( (( ~hour >= 4 ) && ( ~hour < 7)),
						if( (( ~minute >= 9 ) && ( ~minute < 12)),
						{  // [10:00-13:00] & [16:00-19:00] --> maggiore affluenza

						~new_enable_prob = [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1];
						//~new_enable_prob.size;

						//~newtime = 0.5;  //era 1, con 1.25 dovre aumentare bpm   -0.28 diminuisce di 5
						//"fascia 4/7".postln;
					    ~newtime = 0.5;
						~v["next_genre_selection"] = ~v["all_genres"][4];
	                    ~v["structures"][~v["next_genre_selection"]];
						~f["create_kd_trees"].value;
						~v["genre_changed"] = true;
						~array_strutture = ~v["structures"][~v["next_genre_selection"]];
	                    ~array_strutture = ~array_strutture.scramble;
	});
	);


						(
						//if( (( ~hour >= 4 ) && ( ~hour < 7)),
						if( (( ~minute >= 12 ) && ( ~minute < 15)),
						{  // [10:00-13:00] & [16:00-19:00] --> maggiore affluenza

						~new_enable_prob = [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1];
						//~new_enable_prob.size;

						//~newtime = 0.5;  //era 1, con 1.25 dovre aumentare bpm   -0.28 diminuisce di 5
						//"fascia 4/7".postln;
					    ~newtime = 0.5;
						~v["next_genre_selection"] = ~v["all_genres"][5];
	                    ~v["structures"][~v["next_genre_selection"]];
						~f["create_kd_trees"].value;
						~v["genre_changed"] = true;
						~array_strutture = ~v["structures"][~v["next_genre_selection"]];
	                    ~array_strutture = ~array_strutture.scramble;
	});
	);
									(
						//if( (( ~hour >= 4 ) && ( ~hour < 7)),
						if( (( ~minute >= 15 ) && ( ~minute < 18)),
						{  // [10:00-13:00] & [16:00-19:00] --> maggiore affluenza

						~new_enable_prob = [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1];
						//~new_enable_prob.size;

						//~newtime = 0.5;  //era 1, con 1.25 dovre aumentare bpm   -0.28 diminuisce di 5
						//"fascia 4/7".postln;
					    ~newtime = 0.5;
						~v["next_genre_selection"] = ~v["all_genres"][1];
	                    ~v["structures"][~v["next_genre_selection"]];
						~f["create_kd_trees"].value;
						~v["genre_changed"] = true;
						~array_strutture = ~v["structures"][~v["next_genre_selection"]];
	                    ~array_strutture = ~array_strutture.scramble;
	});
	);
									(
						//if( (( ~hour >= 4 ) && ( ~hour < 7)),
						if( (( ~minute >= 18 ) && ( ~minute < 21)),
						{  // [10:00-13:00] & [16:00-19:00] --> maggiore affluenza

						~new_enable_prob = [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1];
						//~new_enable_prob.size;

						//~newtime = 0.5;  //era 1, con 1.25 dovre aumentare bpm   -0.28 diminuisce di 5
						//"fascia 4/7".postln;
					    ~newtime = 0.5;
						~v["next_genre_selection"] = ~v["all_genres"][2];
	                    ~v["structures"][~v["next_genre_selection"]];
						~f["create_kd_trees"].value;
						~v["genre_changed"] = true;
						~array_strutture = ~v["structures"][~v["next_genre_selection"]];
	                    ~array_strutture = ~array_strutture.scramble;
	});
	);
									(
						//if( (( ~hour >= 4 ) && ( ~hour < 7)),
						if( (( ~minute >= 21 ) && ( ~minute < 24)),
						{  // [10:00-13:00] & [16:00-19:00] --> maggiore affluenza

						~new_enable_prob = [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1];
						//~new_enable_prob.size;

						//~newtime = 0.5;  //era 1, con 1.25 dovre aumentare bpm   -0.28 diminuisce di 5
						//"fascia 4/7".postln;
					    ~newtime = 0.5;
						~v["next_genre_selection"] = ~v["all_genres"][3];
	                    ~v["structures"][~v["next_genre_selection"]];
						~f["create_kd_trees"].value;
						~v["genre_changed"] = true;
						~array_strutture = ~v["structures"][~v["next_genre_selection"]];
	                    ~array_strutture = ~array_strutture.scramble;
	});
	);
									(
						//if( (( ~hour >= 4 ) && ( ~hour < 7)),
						if( (( ~minute >= 24 ) && ( ~minute < 27)),
						{  // [10:00-13:00] & [16:00-19:00] --> maggiore affluenza

						~new_enable_prob = [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1];
						//~new_enable_prob.size;

						//~newtime = 0.5;  //era 1, con 1.25 dovre aumentare bpm   -0.28 diminuisce di 5
						//"fascia 4/7".postln;
					    ~newtime = 0.5;
						~v["next_genre_selection"] = ~v["all_genres"][4];
	                    ~v["structures"][~v["next_genre_selection"]];
						~f["create_kd_trees"].value;
						~v["genre_changed"] = true;
						~array_strutture = ~v["structures"][~v["next_genre_selection"]];
	                    ~array_strutture = ~array_strutture.scramble;
	});
	);
									(
						//if( (( ~hour >= 4 ) && ( ~hour < 7)),
						if( (( ~minute >= 27 ) && ( ~minute < 30)),
						{  // [10:00-13:00] & [16:00-19:00] --> maggiore affluenza

						~new_enable_prob = [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1];
						//~new_enable_prob.size;

						//~newtime = 0.5;  //era 1, con 1.25 dovre aumentare bpm   -0.28 diminuisce di 5
						//"fascia 4/7".postln;
					    ~newtime = 0.5;
						~v["next_genre_selection"] = ~v["all_genres"][5];
	                    ~v["structures"][~v["next_genre_selection"]];
						~f["create_kd_trees"].value;
						~v["genre_changed"] = true;
						~array_strutture = ~v["structures"][~v["next_genre_selection"]];
	                    ~array_strutture = ~array_strutture.scramble;
	});
	);
									(
						//if( (( ~hour >= 4 ) && ( ~hour < 7)),
						if( (( ~minute >= 30 ) && ( ~minute < 33)),
						{  // [10:00-13:00] & [16:00-19:00] --> maggiore affluenza

						~new_enable_prob = [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1];
						//~new_enable_prob.size;

						//~newtime = 0.5;  //era 1, con 1.25 dovre aumentare bpm   -0.28 diminuisce di 5
						//"fascia 4/7".postln;
					    ~newtime = 0.5;
						~v["next_genre_selection"] = ~v["all_genres"][1];
	                    ~v["structures"][~v["next_genre_selection"]];
						~f["create_kd_trees"].value;
						~v["genre_changed"] = true;
						~array_strutture = ~v["structures"][~v["next_genre_selection"]];
	                    ~array_strutture = ~array_strutture.scramble;
	});
	);
									(
						//if( (( ~hour >= 4 ) && ( ~hour < 7)),
						if( (( ~minute >= 33 ) && ( ~minute < 36)),
						{  // [10:00-13:00] & [16:00-19:00] --> maggiore affluenza

						~new_enable_prob = [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1];
						//~new_enable_prob.size;

						//~newtime = 0.5;  //era 1, con 1.25 dovre aumentare bpm   -0.28 diminuisce di 5
						//"fascia 4/7".postln;
					    ~newtime = 0.5;
						~v["next_genre_selection"] = ~v["all_genres"][2];
	                    ~v["structures"][~v["next_genre_selection"]];
						~f["create_kd_trees"].value;
						~v["genre_changed"] = true;
						~array_strutture = ~v["structures"][~v["next_genre_selection"]];
	                    ~array_strutture = ~array_strutture.scramble;
	});
	);
									(
						//if( (( ~hour >= 4 ) && ( ~hour < 7)),
						if( (( ~minute >= 36 ) && ( ~minute < 39)),
						{  // [10:00-13:00] & [16:00-19:00] --> maggiore affluenza

						~new_enable_prob = [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1];
						//~new_enable_prob.size;

						//~newtime = 0.5;  //era 1, con 1.25 dovre aumentare bpm   -0.28 diminuisce di 5
						//"fascia 4/7".postln;
					    ~newtime = 0.5;
						~v["next_genre_selection"] = ~v["all_genres"][3];
	                    ~v["structures"][~v["next_genre_selection"]];
						~f["create_kd_trees"].value;
						~v["genre_changed"] = true;
						~array_strutture = ~v["structures"][~v["next_genre_selection"]];
	                    ~array_strutture = ~array_strutture.scramble;
	});
	);
									(
						//if( (( ~hour >= 4 ) && ( ~hour < 7)),
						if( (( ~minute >= 39 ) && ( ~minute < 42)),
						{  // [10:00-13:00] & [16:00-19:00] --> maggiore affluenza

						~new_enable_prob = [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1];
						//~new_enable_prob.size;

						//~newtime = 0.5;  //era 1, con 1.25 dovre aumentare bpm   -0.28 diminuisce di 5
						//"fascia 4/7".postln;
					    ~newtime = 0.5;
						~v["next_genre_selection"] = ~v["all_genres"][4];
	                    ~v["structures"][~v["next_genre_selection"]];
						~f["create_kd_trees"].value;
						~v["genre_changed"] = true;
						~array_strutture = ~v["structures"][~v["next_genre_selection"]];
	                    ~array_strutture = ~array_strutture.scramble;
	});
	);
				(
						//if( (( ~hour >= 4 ) && ( ~hour < 7)),
						if( (( ~minute >= 42 ) && ( ~minute < 45)),
						{  // [10:00-13:00] & [16:00-19:00] --> maggiore affluenza

						~new_enable_prob = [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1];
						//~new_enable_prob.size;

						//~newtime = 0.5;  //era 1, con 1.25 dovre aumentare bpm   -0.28 diminuisce di 5
						//"fascia 4/7".postln;
					    ~newtime = 0.5;
						~v["next_genre_selection"] = ~v["all_genres"][5];
	                    ~v["structures"][~v["next_genre_selection"]];
						~f["create_kd_trees"].value;
						~v["genre_changed"] = true;
						~array_strutture = ~v["structures"][~v["next_genre_selection"]];
	                    ~array_strutture = ~array_strutture.scramble;
	});
	);

	(
						//if( (( ~hour >= 4 ) && ( ~hour < 7)),
						if( (( ~minute >= 45 ) && ( ~minute < 48)),
						{  // [10:00-13:00] & [16:00-19:00] --> maggiore affluenza

						~new_enable_prob = [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1];
						//~new_enable_prob.size;

						//~newtime = 0.5;  //era 1, con 1.25 dovre aumentare bpm   -0.28 diminuisce di 5
						//"fascia 4/7".postln;
					    ~newtime = 0.5;
						~v["next_genre_selection"] = ~v["all_genres"][1];
	                    ~v["structures"][~v["next_genre_selection"]];
						~f["create_kd_trees"].value;
						~v["genre_changed"] = true;
						~array_strutture = ~v["structures"][~v["next_genre_selection"]];
	                    ~array_strutture = ~array_strutture.scramble;
	});
	);
				(
						//if( (( ~hour >= 4 ) && ( ~hour < 7)),
						if( (( ~minute >= 48 ) && ( ~minute < 51)),
						{  // [10:00-13:00] & [16:00-19:00] --> maggiore affluenza

						~new_enable_prob = [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1];
						//~new_enable_prob.size;

						//~newtime = 0.5;  //era 1, con 1.25 dovre aumentare bpm   -0.28 diminuisce di 5
						//"fascia 4/7".postln;
					    ~newtime = 0.5;
						~v["next_genre_selection"] = ~v["all_genres"][2];
	                    ~v["structures"][~v["next_genre_selection"]];
						~f["create_kd_trees"].value;
						~v["genre_changed"] = true;
						~array_strutture = ~v["structures"][~v["next_genre_selection"]];
	                    ~array_strutture = ~array_strutture.scramble;
	});
	);
				(
						//if( (( ~hour >= 4 ) && ( ~hour < 7)),
						if( (( ~minute >= 51 ) && ( ~minute < 54)),
						{  // [10:00-13:00] & [16:00-19:00] --> maggiore affluenza

						~new_enable_prob = [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1];
						//~new_enable_prob.size;

						//~newtime = 0.5;  //era 1, con 1.25 dovre aumentare bpm   -0.28 diminuisce di 5
						//"fascia 4/7".postln;
					    ~newtime = 0.5;
						~v["next_genre_selection"] = ~v["all_genres"][3];
	                    ~v["structures"][~v["next_genre_selection"]];
						~f["create_kd_trees"].value;
						~v["genre_changed"] = true;
						~array_strutture = ~v["structures"][~v["next_genre_selection"]];
	                    ~array_strutture = ~array_strutture.scramble;
	});
	);
				(
						//if( (( ~hour >= 4 ) && ( ~hour < 7)),
						if( (( ~minute >= 54 ) && ( ~minute < 57)),
						{  // [10:00-13:00] & [16:00-19:00] --> maggiore affluenza

						~new_enable_prob = [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1];
						//~new_enable_prob.size;

						//~newtime = 0.5;  //era 1, con 1.25 dovre aumentare bpm   -0.28 diminuisce di 5
						//"fascia 4/7".postln;
					    ~newtime = 0.5;
						~v["next_genre_selection"] = ~v["all_genres"][4];
	                    ~v["structures"][~v["next_genre_selection"]];
						~f["create_kd_trees"].value;
						~v["genre_changed"] = true;
						~array_strutture = ~v["structures"][~v["next_genre_selection"]];
	                    ~array_strutture = ~array_strutture.scramble;
	});
	);

				(
						//if( (( ~hour >= 4 ) && ( ~hour < 7)),
						if( (( ~minute >= 57 ) && ( ~minute <= 59)),
						{  // [10:00-13:00] & [16:00-19:00] --> maggiore affluenza

						~new_enable_prob = [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1];
						//~new_enable_prob.size;

						//~newtime = 0.5;  //era 1, con 1.25 dovre aumentare bpm   -0.28 diminuisce di 5
						//"fascia 4/7".postln;
					    ~newtime = 0.5;
						~v["next_genre_selection"] = ~v["all_genres"][5]; /////////Questo
	                    ~v["structures"][~v["next_genre_selection"]];
						~f["create_kd_trees"].value;
						~v["genre_changed"] = true;
						~array_strutture = ~v["structures"][~v["next_genre_selection"]];
	                    ~array_strutture = ~array_strutture.scramble;
	});
	);



	// FINE DEL BLOCCO


			5.wait;
		})
	}
    ).play(AppClock);

	*/

	////////////

	// START/STOP
	// # TODO: startFunction: dirty
	~startFunction = {
		arg val;
	   if(val.value == 1, {
				("[debug] val: Normale").postln;
				//~v["clock_tempo_change_knob"].valueAction_(0.5);
				//try({ ~v["wow_conductor"].stop; });
				~f["conductor_tick_counter_rout"].stop;
				~v.put("kick_vel_scale", 0.0)
				.put("drum_vel_scale", 0.0)
				.put("pad_vel_scale", 1.0)
				.put("key_vel_scale", 0.0)
				.put("sampler_vel_scale", 0.0)
				.put("lead_vel_scale", 0.0)
				.put("bass_vel_scale", 0.0);
				~v["genre"] = ~v["next_genre"];
				~v["player"] = ~f["build_conductor_v2"].value();
				~v["player"].play(~v.at("clock"));
			}, {
				~v["player"].stop;
				~f.at("conductor_v2").stop;
				~f.at("conductor_tick_counter_rout").stop;
				~v.at("players").collect({ | player | player.rout.stop });
				if(~v["record_midi"], {
					m.adjustTracks;
					m.adjustEndOfTrack;
					m.write;
				});
			});
	};

//LASCIAREEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE
	    mode_selection = 0;
		if( mode_selection == 0, { // MODALITA' NORMALE
		var tmp = File.open(~v["src_folder"] ++ "osc_v.1.0.0.scd", "r");
			//OSCdef.freeAll();
			//////~v["enable_prob"] = 1 ! ~v["enable_list"].size;
			~v["max_eventi_verticale"] = 50;
			~v["transpose_factor"] =  0;
			~v["struttura_forzata"] = false;
			tmp.readAllString.interpret;
			tmp.close;
		});
});
/*

