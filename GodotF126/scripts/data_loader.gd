class_name DataLoader
extends RefCounted
## Lectura de los JSON de data/, compartida por las escenas.

const GRID_PATH := "res://data/grid_2026.json"
const TRACKS_PATH := "res://data/tracks.json"
const CAR_PATH := "res://data/car.json"
const MENU_PATH := "res://data/menu.json"
const MODES_PATH := "res://data/modes.json"


## Devuelve {} (y avisa) si el archivo falta o no es un objeto JSON.
static func load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("No se encontró %s" % path)
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed is Dictionary:
		return parsed
	push_error("JSON inválido en %s" % path)
	return {}


static func team_primary(team: Dictionary, fallback: Color = Color("#FF87BC")) -> Color:
	return Color.html(str(team.get("color", fallback.to_html())))


## Si el equipo no trae "secondary_color", una versión oscura del principal.
static func team_secondary(team: Dictionary) -> Color:
	if team.has("secondary_color"):
		return Color.html(str(team["secondary_color"]))
	return team_primary(team).darkened(0.55)


## Busca un piloto en la grilla. Devuelve {"driver": ..., "team": ...} o {} si no está.
static func find_driver(grid: Dictionary, driver_id: String) -> Dictionary:
	for team in grid.get("teams", []):
		for driver in team.get("drivers", []):
			if str(driver.get("id", "")) == driver_id:
				return {"driver": driver, "team": team}
	return {}


## Busca un modo en data/modes.json. Devuelve {} si no está.
static func find_mode(modes: Dictionary, mode_id: String) -> Dictionary:
	for mode in modes.get("modes", []):
		if str(mode.get("id", "")) == mode_id:
			return mode
	return {}
