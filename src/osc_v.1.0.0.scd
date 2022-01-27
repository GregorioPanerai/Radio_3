
OSCdef(\weather, { | msg, time, addr, recvPort |
	var weather_type=msg[1], temperature=msg[2], pressure=msg[3], wind=msg[4];
	[weather_type, temperature, pressure, wind].postln;

	// CAMBIO MODO E TRASPOSIZIONE IN BASE AL TIPO DI METEO

	if( (weather_type >= 0) && (weather_type <= 7), { ~v["modality"] = ~v["modalities_wrap"].wrapAt(0); ~v["transpose_factor"] = 2; });
	if( (weather_type >= 8) && (weather_type <= 13), { ~v["modality"] = ~v["modalities_wrap"].wrapAt(2); ~v["transpose_factor"] = 0; });
	if( (weather_type >= 14) && (weather_type <= 20), { ~v["modality"] = ~v["modalities_wrap"].wrapAt(6); ~v["transpose_factor"] = -10; });

}, \weather);