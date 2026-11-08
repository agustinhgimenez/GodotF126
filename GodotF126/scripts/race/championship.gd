class_name Championship
extends RefCounted
## Modo campeonato (Paso 55): una temporada de varias fechas con el mismo piloto.
## - Calendario, vueltas de la clasificación y archivo de guardado en data/championship.json.
## - Cada fecha es clasificación + carrera (Paso 47); al terminar la carrera, main.gd suma su
##   resultado (RaceResults.to_dict(), Paso 52) con add_race() y guarda la temporada.
## - Tablas de pilotos y equipos: suma de los puntos de cada carrera; desempate por mejores
##   resultados (más victorias, después más segundos puestos, …) y, si sigue, por nombre.

const DATA_PATH := "res://data/championship.json"

var season_name: String = "Temporada"
var save_path: String = "user://championship.json"
var qualifying_laps: int = 2
## Fechas: {track_id, name, short, qualifying (bool)}.
var calendar: Array[Dictionary] = []

## Estado de la temporada (lo que se guarda).
var laps: int = 3
var player_driver_id: String = ""
var started: String = ""
## Un resultado por fecha corrida (RaceResults.to_dict() + "round").
var races: Array[Dictionary] = []


static func load_default() -> Championship:
	var championship := Championship.new()
	championship.configure(DataLoader.load_json(DATA_PATH))
	return championship


## La temporada guardada (null si no hay o no se puede leer).
static func load_saved() -> Championship:
	var championship := load_default()
	return championship if championship.load_state() else null


func configure(data: Dictionary) -> void:
	season_name = str(data.get("name", season_name))
	save_path = str(data.get("save_path", save_path))
	qualifying_laps = maxi(int(data.get("qualifying_laps", qualifying_laps)), 1)
	var list = data.get("calendar", [])
	if list is Array:
		_set_calendar(list)


func _set_calendar(list: Array) -> void:
	calendar.clear()
	for item in list:
		if not item is Dictionary or str(item.get("track_id", "")).is_empty():
			continue
		var id := str(item["track_id"])
		var info := TrackGenerator.find_track_info(id)
		calendar.append({"track_id": id, "name": str(item.get("name", info.get("name", id))),
			"short": str(item.get("short", id.left(3).to_upper())),
			"qualifying": bool(item.get("qualifying", true))})


## Temporada nueva (no guarda: eso lo hace save()).
func start(driver_id: String, race_laps: int) -> void:
	player_driver_id = driver_id
	laps = maxi(race_laps, 1)
	started = Time.get_datetime_string_from_system()
	races.clear()


func round_index() -> int:
	return races.size()


func round_count() -> int:
	return calendar.size()


func is_finished() -> bool:
	return races.size() >= calendar.size()


## La fecha que sigue ({} si la temporada terminó).
func current_round() -> Dictionary:
	return {} if is_finished() else calendar[races.size()]


## Deja GameState listo para la fecha que sigue: pista, piloto, clasificación (o carrera si la
## fecha no tiene) y una semilla nueva.
func prepare_round() -> void:
	var info := current_round()
	if info.is_empty():
		return
	# El autoload por el árbol: los scripts con class_name no lo ven al cargarse desde `godot -s`.
	var state := (Engine.get_main_loop() as SceneTree).root.get_node("GameState")
	state.championship = true
	state.selected_track = str(info["track_id"])
	state.selected_driver_id = player_driver_id
	state.session_seed = 0
	state.qualifying_time = -1.0
	if bool(info["qualifying"]):
		state.selected_mode = state.MODE_QUALIFYING
		state.lap_count = qualifying_laps
	else:
		state.selected_mode = state.MODE_RACE
		state.lap_count = laps


## Suma la carrera de la fecha actual. Sólo si es la pista que tocaba (no cuenta dos veces).
func add_race(result: Dictionary) -> bool:
	var info := current_round()
	if info.is_empty() or result.get("drivers", []).is_empty():
		return false
	if str(result.get("track_id", "")) != TrackGenerator.resolve_track_id(str(info["track_id"])):
		return false
	var entry := result.duplicate(true)
	entry["round"] = races.size()
	races.append(entry)
	return true


## Pilotos ordenados después de las primeras `count` carreras (−1 = todas): {pos, driver_id,
## driver, code, team_id, team, points, results (puesto por fecha, 0 = no corrió), wins,
## player}.
func driver_standings(count: int = -1) -> Array[Dictionary]:
	var done := races.size() if count < 0 else mini(count, races.size())
	var by_id: Dictionary = {}
	for r in done:
		for row in races[r].get("drivers", []):
			var id := str(row.get("driver_id", row.get("driver", "")))
			if not by_id.has(id):
				var results: Array[int] = []
				results.resize(done)
				by_id[id] = {"driver_id": id, "driver": str(row.get("driver", id)), "code": "",
					"team_id": "", "team": "", "points": 0, "results": results, "wins": 0,
					"player": id == player_driver_id}
			var standing: Dictionary = by_id[id]
			var pos := int(row.get("pos", 0))
			standing["code"] = str(row.get("code", str(standing["driver"]).get_slice(" ", 1).left(3).to_upper()))
			standing["team_id"] = str(row.get("team_id", ""))
			standing["team"] = str(row.get("team", ""))
			standing["points"] = int(standing["points"]) + int(row.get("points", 0))
			standing["results"][r] = pos
			if pos == 1:
				standing["wins"] = int(standing["wins"]) + 1
	var list: Array[Dictionary] = []
	for standing in by_id.values():
		list.append(standing)
	list.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return _ahead(a, b, a["results"], b["results"], "driver"))
	for i in list.size():
		list[i]["pos"] = i + 1
	return list


## Equipos ordenados: {pos, team_id, team, points, results (puntos por fecha), finishes
## (puestos de sus pilotos), members (driver_id)}.
func team_standings(count: int = -1) -> Array[Dictionary]:
	var done := races.size() if count < 0 else mini(count, races.size())
	var by_id: Dictionary = {}
	for r in done:
		for row in races[r].get("drivers", []):
			var id := str(row.get("team_id", row.get("team", "")))
			if not by_id.has(id):
				var results: Array[int] = []
				results.resize(done)
				by_id[id] = {"team_id": id, "team": str(row.get("team", id)), "points": 0,
					"results": results, "finishes": [] as Array[int], "members": [] as Array[String]}
			var standing: Dictionary = by_id[id]
			var points := int(row.get("points", 0))
			standing["points"] = int(standing["points"]) + points
			standing["results"][r] = int(standing["results"][r]) + points
			(standing["finishes"] as Array[int]).append(int(row.get("pos", 0)))
			var driver_id := str(row.get("driver_id", ""))
			if not driver_id in standing["members"]:
				(standing["members"] as Array[String]).append(driver_id)
	var list: Array[Dictionary] = []
	for standing in by_id.values():
		list.append(standing)
	list.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return _ahead(a, b, a["finishes"], b["finishes"], "team"))
	for i in list.size():
		list[i]["pos"] = i + 1
	return list


## Más puntos; si empatan, el que tiene más primeros puestos, después más segundos, …
static func _ahead(a: Dictionary, b: Dictionary, a_finishes: Array, b_finishes: Array, name_key: String) -> bool:
	if a["points"] != b["points"]:
		return a["points"] > b["points"]
	var tie := countback(a_finishes, b_finishes)
	if tie != 0:
		return tie > 0
	return str(a[name_key]) < str(b[name_key])


## 1 si `a` tiene mejores resultados que `b`, −1 si peores, 0 si son iguales (los 0 no cuentan).
static func countback(a: Array, b: Array) -> int:
	var worst := 0
	for pos in a + b:
		worst = maxi(worst, int(pos))
	for place in range(1, worst + 1):
		var diff := a.count(place) - b.count(place)
		if diff != 0:
			return 1 if diff > 0 else -1
	return 0


func player_standing() -> Dictionary:
	for standing in driver_standings():
		if standing["player"]:
			return standing
	return {}


func to_dict() -> Dictionary:
	return {"name": season_name, "laps": laps, "player_driver_id": player_driver_id, "started": started,
		"calendar": calendar.duplicate(true), "races": races.duplicate(true)}


func save() -> bool:
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(to_dict(), "  "))
	return true


## Lee la temporada guardada. El calendario guardado manda (otra versión de los datos no
## cambia una temporada empezada).
func load_state() -> bool:
	var data := RaceResults.load_saved(save_path)
	if data.is_empty() or str(data.get("player_driver_id", "")).is_empty():
		return false
	var saved_calendar = data.get("calendar", [])
	if saved_calendar is Array and not saved_calendar.is_empty():
		_set_calendar(saved_calendar)
	if calendar.is_empty():
		return false
	season_name = str(data.get("name", season_name))
	laps = maxi(int(data.get("laps", laps)), 1)
	player_driver_id = str(data["player_driver_id"])
	started = str(data.get("started", ""))
	races.clear()
	for item in data.get("races", []):
		if item is Dictionary:
			races.append(item)
	return true


func delete_saved() -> void:
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
