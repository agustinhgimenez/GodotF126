class_name DataLoader
extends RefCounted
## Lectura de los JSON de data/, compartida por las escenas.

const GRID_PATH := "res://data/grid_2026.json"
const TRACKS_PATH := "res://data/tracks.json"
const CAR_PATH := "res://data/car.json"
const MENU_PATH := "res://data/menu.json"


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


## Busca un piloto en la grilla. Devuelve {"driver": ..., "team": ...} o {} si no está.
static func find_driver(grid: Dictionary, driver_id: String) -> Dictionary:
	for team in grid.get("teams", []):
		for driver in team.get("drivers", []):
			if str(driver.get("id", "")) == driver_id:
				return {"driver": driver, "team": team}
	return {}
