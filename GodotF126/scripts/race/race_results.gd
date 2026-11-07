class_name RaceResults
extends RefCounted
## Resultado de la carrera con puntos (Paso 52), a partir de RaceSession.classification().
## - Pilotos: posición, lugares ganados contra la grilla, vueltas, compuestos, paradas, tiempo o
##   diferencia con el ganador ("+1 vuelta" si quedó doblado), sanciones con el motivo, mejor
##   vuelta (la más rápida de la carrera marcada) y puntos de `points`.
## - Equipos: suma de los puntos de sus dos pilotos (empate: el que tiene el mejor puesto).
## - Sanciones: las de los comisarios (penalizaciones y advertencias, con las de banderas) y las
##   que suma RaceSession.add_extra_penalty(), en el orden en que pasaron (reloj de carrera).
## - save() escribe la carrera en `save_path` para el campeonato (Paso 55).
## Datos en data/points.json.

const DATA_PATH := "res://data/points.json"
const DEFAULT_POINTS: Array[int] = [25, 18, 15, 12, 10, 8, 6, 4, 2, 1]

var points: Array[int] = DEFAULT_POINTS.duplicate()
var fastest_lap_points: int = 0
var fastest_lap_top: int = 10
var save_path: String = "user://last_race.json"

## Una fila por piloto, del ganador al último: {pos, grid (1 = pole), change (lugares ganados),
## car, driver, number, driver_id, team, team_id, color, code, laps, laps_down, time, total,
## gap_text, estimated, penalty, reasons (Array de textos), best_lap, fastest, compounds,
## stops, points, player}.
var drivers: Array[Dictionary] = []
## Por equipo, del primero al último: {pos, team, team_id, color, points, best, members
## ([{code, pos, points}])}.
var teams: Array[Dictionary] = []
## {time (s de carrera), car, code, driver, action ("penalty" / "warning"), seconds, label
## ("+5 s" / "Advertencia 1/3"), text (motivo)}.
var penalties: Array[Dictionary] = []
var fastest_lap: float = -1.0
var player_row: Dictionary = {}


static func load_default() -> RaceResults:
	var results := RaceResults.new()
	results.configure(DataLoader.load_json(DATA_PATH))
	return results


func configure(data: Dictionary) -> void:
	var list = data.get("points", [])
	if list is Array and not list.is_empty():
		points.clear()
		for value in list:
			points.append(maxi(int(value), 0))
	fastest_lap_points = maxi(int(data.get("fastest_lap_points", fastest_lap_points)), 0)
	fastest_lap_top = maxi(int(data.get("fastest_lap_top", fastest_lap_top)), 0)
	save_path = str(data.get("save_path", save_path))


## Puntos del puesto `position` (1 = ganador).
func points_for(position: int, fastest: bool = false) -> int:
	var value := points[position - 1] if position >= 1 and position <= points.size() else 0
	if fastest and position <= fastest_lap_top:
		value += fastest_lap_points
	return value


func build(race: RaceSession, stewards: RaceStewards = null, pit: PitLane = null,
		player: CarController = null) -> void:
	drivers.clear()
	teams.clear()
	penalties.clear()
	player_row = {}
	var list := race.classification()
	if list.is_empty():
		return
	fastest_lap = -1.0
	for row in list:
		var best := float(row["entry"]["best_lap"])
		if best > 0.0 and (fastest_lap < 0.0 or best < fastest_lap):
			fastest_lap = best
	_collect_penalties(race, stewards)
	var winner: Dictionary = list[0]
	for p in list.size():
		var row: Dictionary = list[p]
		var entry: Dictionary = row["entry"]
		var car: CarController = entry["car"]
		var driver: Dictionary = entry["driver"]
		var team: Dictionary = entry["team"]
		var down := int(winner["laps"]) - int(row["laps"])
		var gap := LapTimer.format_time(float(row["total"]))
		if p > 0:
			gap = "+%d %s" % [down, "vuelta" if down == 1 else "vueltas"] if down > 0 \
				else "+%.3f" % (float(row["total"]) - float(winner["total"]))
		if row["estimated"]:
			gap = "≈ " + gap
		var best := float(entry["best_lap"])
		var fastest := best > 0.0 and is_equal_approx(best, fastest_lap)
		var reasons: Array[String] = []
		for item in penalties:
			if item["car"] == car and item["action"] == "penalty":
				reasons.append("+%s s %s" % [_seconds(float(item["seconds"])), item["text"]])
		var info := {
			"pos": p + 1, "grid": int(entry["grid"]) + 1, "change": int(entry["grid"]) - p,
			"car": car, "driver": str(driver.get("name", "")), "number": driver.get("number", ""),
			"driver_id": str(driver.get("id", "")), "team": str(team.get("name", "")),
			"team_id": str(team.get("id", "")), "color": DataLoader.team_primary(team),
			"code": str(entry["code"]), "laps": int(row["laps"]), "laps_down": maxi(down, 0),
			"time": float(row["time"]), "total": float(row["total"]), "gap_text": gap,
			"estimated": bool(row["estimated"]), "penalty": float(row["penalty"]), "reasons": reasons,
			"best_lap": best, "fastest": fastest, "compounds": (entry["compounds"] as Array).duplicate(),
			"stops": pit.stops_of(car) if pit != null else maxi((entry["compounds"] as Array).size() - 1, 0),
			"points": points_for(p + 1, fastest), "player": car == player and player != null,
		}
		drivers.append(info)
		if info["player"]:
			player_row = info
	_build_teams()


func _collect_penalties(race: RaceSession, stewards: RaceStewards) -> void:
	if stewards != null:
		var offset := stewards.clock() - race.clock
		for incident in stewards.incidents:
			var action := str(incident.get("action", ""))
			if action != "penalty" and action != "warning":
				continue
			var guilty = incident.get("guilty")
			var entry := race.entry_of(guilty) if guilty is CarController else {}
			if entry.is_empty():
				continue
			var text := RaceStewards.reason(incident, true)
			var seconds := float(incident.get("seconds", 0.0))
			var label := "+%s s" % _seconds(seconds) if action == "penalty" \
				else "Advertencia %d/%d" % [int(incident.get("warnings", 0)), stewards.max_warnings]
			penalties.append({"time": maxf(float(incident["time"]) - offset, 0.0), "car": guilty,
				"code": str(entry["code"]), "driver": str(entry["driver"].get("name", "")),
				"action": action, "seconds": seconds, "label": label,
				"text": text.left(1).to_upper() + text.substr(1)})
	for entry in race.entries:
		for extra in entry.get("extra_reasons", []):
			penalties.append({"time": float(extra["time"]), "car": entry["car"], "code": str(entry["code"]),
				"driver": str(entry["driver"].get("name", "")), "action": "penalty",
				"seconds": float(extra["seconds"]), "label": "+%s s" % _seconds(float(extra["seconds"])),
				"text": str(extra["reason"])})
	penalties.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["time"] < b["time"])


func _build_teams() -> void:
	var by_id: Dictionary = {}
	for row in drivers:
		var id: String = row["team_id"] if not str(row["team_id"]).is_empty() else str(row["team"])
		if not by_id.has(id):
			by_id[id] = {"team": row["team"], "team_id": row["team_id"], "color": row["color"],
				"points": 0, "best": int(row["pos"]), "members": []}
		var team: Dictionary = by_id[id]
		team["points"] = int(team["points"]) + int(row["points"])
		team["best"] = mini(int(team["best"]), int(row["pos"]))
		(team["members"] as Array).append({"code": row["code"], "pos": row["pos"], "points": row["points"]})
	for team in by_id.values():
		teams.append(team)
	teams.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a["points"] != b["points"]:
			return a["points"] > b["points"]
		return a["best"] < b["best"])
	for i in teams.size():
		teams[i]["pos"] = i + 1


func team_points(team_id: String) -> int:
	for team in teams:
		if team["team_id"] == team_id:
			return int(team["points"])
	return 0


## Lo que se guarda (sin referencias a nodos).
func to_dict(info: Dictionary = {}) -> Dictionary:
	var data := info.duplicate()
	data["date"] = Time.get_datetime_string_from_system()
	data["fastest_lap"] = snappedf(fastest_lap, 0.001)
	var rows: Array = []
	for row in drivers:
		rows.append({"pos": row["pos"], "grid": row["grid"], "driver_id": row["driver_id"],
			"driver": row["driver"], "team_id": row["team_id"], "team": row["team"],
			"laps": row["laps"], "time": snappedf(float(row["time"]), 0.001),
			"total": snappedf(float(row["total"]), 0.001), "estimated": row["estimated"],
			"penalty": row["penalty"], "best_lap": snappedf(float(row["best_lap"]), 0.001),
			"fastest": row["fastest"], "stops": row["stops"], "compounds": row["compounds"],
			"points": row["points"], "player": row["player"]})
	data["drivers"] = rows
	var team_rows: Array = []
	for team in teams:
		team_rows.append({"pos": team["pos"], "team_id": team["team_id"], "team": team["team"],
			"points": team["points"]})
	data["teams"] = team_rows
	return data


func save(info: Dictionary = {}) -> bool:
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(to_dict(info), "  "))
	return true


static func load_saved(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


## "+2" / "-1" / "=".
static func change_text(change: int) -> String:
	if change == 0:
		return "="
	return "%+d" % change


static func _seconds(s: float) -> String:
	return ("%.1f" % s).replace(".", ",").trim_suffix(",0")
