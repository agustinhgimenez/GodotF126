extends GutTest
## DataLoader y los JSON de data/: se leen, traen sus claves y se referencian bien entre sí.

const DATA_DIR := "res://data/"


func test_archivo_que_falta_devuelve_vacio() -> void:
	assert_eq(DataLoader.load_json("res://data/no_existe.json"), {})
	assert_push_error("No se encontró")


func test_json_roto_devuelve_vacio() -> void:
	var path := "user://gut_json_roto.json"
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string("{\"a\": 1,,}")
	f.close()
	assert_eq(DataLoader.load_json(path), {})
	assert_push_error("JSON inválido")
	assert_engine_error_count(1, "el parser de JSON también avisa")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func test_json_que_no_es_objeto_devuelve_vacio() -> void:
	var path := "user://gut_json_lista.json"
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string("[1, 2, 3]")
	f.close()
	assert_eq(DataLoader.load_json(path), {})
	assert_push_error("JSON inválido")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func test_todos_los_json_de_data_se_leen() -> void:
	var files := Array(DirAccess.get_files_at(DATA_DIR)).filter(func(name: String) -> bool: return name.ends_with(".json"))
	assert_gt(files.size(), 15, "hay %d JSON" % files.size())
	for name in files:
		assert_false(DataLoader.load_json(DATA_DIR + name).is_empty(), "%s se lee y no está vacío" % name)


func test_grilla_2026() -> void:
	var grid := DataLoader.load_json(DataLoader.GRID_PATH)
	var teams: Array = grid["teams"]
	assert_eq(teams.size(), 11, "11 equipos")
	var ids := {}
	for team in teams:
		assert_eq((team["drivers"] as Array).size(), 2, "%s con 2 pilotos" % team["name"])
		for driver in team["drivers"]:
			ids[driver["id"]] = true
	assert_eq(ids.size(), 22, "22 pilotos con id distinto")
	var found := DataLoader.find_driver(grid, str(grid["default_driver_id"]))
	assert_false(found.is_empty(), "el piloto por defecto está en la grilla")
	assert_eq(DataLoader.find_driver(grid, "nadie"), {})


func test_modos() -> void:
	var modes := DataLoader.load_json(DataLoader.MODES_PATH)
	for id in ["practice", "time_trial", "qualifying", "race", "championship"]:
		assert_false(DataLoader.find_mode(modes, id).is_empty(), "modo %s" % id)
	assert_false(DataLoader.find_mode(modes, str(modes["default_mode"])).is_empty(), "el modo por defecto existe")


func test_compuestos_del_auto() -> void:
	var tyres: Dictionary = DataLoader.load_json(DataLoader.CAR_PATH)["tyre_compounds"]
	var ids: Array = (tyres["compounds"] as Array).map(func(c: Dictionary) -> String: return str(c["id"]))
	assert_eq(ids, ["soft", "medium", "hard", "intermediate", "wet"])
	assert_has(ids, str(tyres["default"]), "el compuesto por defecto existe")
	for c in tyres["compounds"]:
		for key in ["name", "short", "color", "grip", "wet_grip", "temp_min", "temp_max", "wear_per_mj"]:
			assert_true(c.has(key), "%s tiene %s" % [c["id"], key])
		assert_lt(float(c["temp_min"]), float(c["temp_max"]), "%s: ventana de temperatura" % c["id"])


func test_clima_usa_compuestos_que_existen() -> void:
	var tyres: Dictionary = DataLoader.load_json(DataLoader.CAR_PATH)["tyre_compounds"]
	var ids: Array = (tyres["compounds"] as Array).map(func(c: Dictionary) -> String: return str(c["id"]))
	for condition in Weather.conditions():
		if condition.has("compound"):
			assert_has(ids, str(condition["compound"]), "el clima %s sugiere un compuesto que existe" % condition["id"])


func test_pistas_jugables_y_calendario() -> void:
	var tracks := DataLoader.load_json(DataLoader.TRACKS_PATH)
	var generable := TrackGenerator.generated_track_ids()
	assert_has(generable, str(tracks["default_track_id"]), "la pista por defecto se puede generar")
	for info in tracks["tracks"]:
		if str(info.get("status", "")) == "jugable":
			assert_has(generable, str(info["id"]), "%s es jugable y se puede generar" % info["id"])
	for item in DataLoader.load_json(Championship.DATA_PATH)["calendar"]:
		assert_has(generable, str(item["track_id"]), "la fecha %s se puede generar" % item["track_id"])


func test_colores_de_equipo() -> void:
	assert_eq(DataLoader.team_primary({"color": "#FF0000"}), Color.RED)
	assert_eq(DataLoader.team_secondary({"color": "#FF0000", "secondary_color": "#00FF00"}), Color.GREEN)
	assert_eq(DataLoader.team_secondary({"color": "#FF0000"}), Color.RED.darkened(0.55), "sin secundario: el principal oscurecido")
