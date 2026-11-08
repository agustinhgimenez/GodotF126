extends GutTest
## Generador de pistas (TrackGenerator, Paso 53): validación con trazados armados en
## layout_override y preview_only (sin mallas), y las pistas de data/tracks.json.


func _preview(layout: Dictionary, id: String = "") -> TrackGenerator:
	var track := TrackGenerator.new()
	track.preview_only = true
	track.city_enabled = false
	if layout.is_empty():
		track.track_id = id
	else:
		track.layout_override = layout
	add_child_autofree(track)
	return track


func _layout(points: Array, extra: Dictionary = {}) -> Dictionary:
	var data := {"id": "test", "display_name": "Test",
		"centerline": {"width": 12, "default_corner_radius": 25, "start": extra.get("start", points[0].slice(0, 2)),
			"points": points}}
	if extra.has("pit_lane"):
		data["pit_lane"] = extra["pit_lane"]
	return data


func _has(list: PackedStringArray, piece: String) -> bool:
	return Array(list).any(func(text: String) -> bool: return text.contains(piece))


func test_ids_de_pista() -> void:
	assert_eq(TrackGenerator.resolve_track_id(""), "baku")
	assert_eq(TrackGenerator.resolve_track_id("no_existe"), "baku")
	assert_eq(TrackGenerator.resolve_track_id("buenos_aires"), "buenos_aires")


func test_pistas_del_juego_sin_errores() -> void:
	for id in ["baku", "buenos_aires", "prueba"]:
		var track := _preview({}, id)
		assert_eq(track.track_id, id)
		assert_eq(Array(track.errors), [], "%s sin errores" % id)
		assert_eq(Array(track.warnings), [], "%s sin avisos" % id)
		assert_gt(track.track_length, 2000.0, "%s: %.0f m" % [id, track.track_length])


func test_rectangulo_valido_con_boxes() -> void:
	var good := [[0, 0], [700, 0], [700, -300], [0, -300]]
	var track := _preview(_layout(good, {"start": [350, 0], "pit_lane": {"auto": true}}))
	assert_eq(Array(track.errors), [])
	assert_eq(Array(track.warnings), [])
	assert_true(track.has_pit_lane())
	assert_gt(track.turning_sense(), 0.0, "antihorario")
	assert_lt(track.pit_side(), 0.0, "boxes adentro, a la izquierda")
	assert_eq(track.auto_aero_zones().size(), 2, "las dos rectas largas")


func test_sentido_horario_boxes_a_la_derecha() -> void:
	var points := [[0, 0], [0, -300], [700, -300], [700, 0]]
	var track := _preview(_layout(points, {"start": [350, 0], "pit_lane": {"auto": true}}))
	assert_lt(track.turning_sense(), 0.0)
	assert_gt(track.pit_side(), 0.0)


func test_largada_en_una_curva() -> void:
	var track := _preview(_layout([[0, 0], [700, 0], [700, -300], [0, -300]], {"pit_lane": {"auto": true}}))
	assert_true(_has(track.warnings, "la largada está en una curva"))
	assert_false(track.has_pit_lane(), "sin boxes automáticos")


func test_trazado_en_ocho() -> void:
	var track := _preview(_layout([[0, 0], [600, 0], [0, -300], [600, -300]]))
	assert_true(_has(track.errors, "se cruzan"))


func test_rectas_que_se_tocan() -> void:
	var track := _preview(_layout([[0, 0], [700, 0], [700, -14], [0, -14]]))
	assert_true(_has(track.errors, "se toca consigo mismo"))


func test_radios_imposibles() -> void:
	var tight := _preview(_layout([[0, 0], [700, 0, 12, 0, 1, 3], [700, -300], [0, -300]]))
	assert_true(_has(tight.errors, "punto 1: radio de 3.0 m"))
	var big := _preview(_layout([[0, 0], [700, 0, 12, 0, 1, 400], [700, -300], [0, -300]]))
	assert_true(_has(big.warnings, "punto 1: el radio de 400 m no entra"))


func test_pocos_puntos() -> void:
	var track := _preview(_layout([[0, 0], [500, 0]]))
	assert_true(_has(track.errors, "al menos 3 puntos"))
	assert_gt(track.centerline.size(), 100, "trazado de respaldo")


func test_vuelta_corta() -> void:
	var track := _preview(_layout([[0, 0], [300, 0], [300, -120], [0, -120]], {"start": [150, 0]}))
	assert_true(_has(track.warnings, "menos de 1 km"))
