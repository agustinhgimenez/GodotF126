extends Node3D
## Escena principal: carga datos (grilla, pistas, auto), spawnea el auto en Bakú y arma el HUD.

const GRID_PATH := "res://data/grid_2026.json"
const TRACKS_PATH := "res://data/tracks.json"
const CAR_PATH := "res://data/car.json"
const TRACK_ID := "baku"

## Respaldo por si el input map de project.godot se pierde o se edita mal.
const DEFAULT_KEYS := {
	"accelerate": [KEY_W, KEY_UP],
	"brake": [KEY_S, KEY_DOWN],
	"steer_left": [KEY_A, KEY_LEFT],
	"steer_right": [KEY_D, KEY_RIGHT],
	"handbrake": [KEY_SPACE],
	"reset_car": [KEY_R],
	"change_camera": [KEY_C],
}

const FALLBACK_DRIVER := {"id": "colapinto", "name": "Franco Colapinto", "number": 43, "country": "AR"}
const FALLBACK_TEAM := {"id": "alpine", "name": "Alpine", "color": "#FF87BC"}

var selected_driver: Dictionary = {}
var selected_team: Dictionary = {}

@onready var track: BakuTrack = $BakuTrack
@onready var car: CarController = $Car
@onready var hud: RaceHUD = $HUD
@onready var lap_timer: LapTimer = $LapTimer


func _ready() -> void:
	_ensure_input_actions()

	var grid := _load_json(GRID_PATH)
	var tracks := _load_json(TRACKS_PATH)
	_select_driver(grid, str(grid.get("default_driver_id", "colapinto")))
	var track_info := _find_track(tracks, TRACK_ID)

	car.configure(_load_json(CAR_PATH))
	car.spawn_transform = track.get_spawn_transform()
	car.reset_to_spawn()

	var team_color := Color.html(str(selected_team.get("color", "#FF87BC")))
	car.set_team_color(team_color)

	hud.bind_car(car)
	hud.set_driver_info(selected_driver, selected_team, team_color)
	hud.set_track_name(str(track_info.get("display_name", track.track_name)))

	lap_timer.setup(TRACK_ID)
	track.checkpoint_crossed.connect(_on_checkpoint_crossed)
	car.was_reset.connect(lap_timer.abort_lap)
	hud.bind_lap_timer(lap_timer)


func _on_checkpoint_crossed(checkpoint: int, body: Node3D) -> void:
	if body == car:
		lap_timer.on_checkpoint(checkpoint)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()


func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("No se encontró %s" % path)
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed is Dictionary:
		return parsed
	push_error("JSON inválido en %s" % path)
	return {}


func _select_driver(grid: Dictionary, driver_id: String) -> void:
	for team in grid.get("teams", []):
		for driver in team.get("drivers", []):
			if str(driver.get("id", "")) == driver_id:
				selected_driver = driver
				selected_team = team
				return
	push_warning("Piloto '%s' no encontrado en la grilla; uso el de respaldo." % driver_id)
	selected_driver = FALLBACK_DRIVER.duplicate()
	selected_team = FALLBACK_TEAM.duplicate()


func _find_track(tracks: Dictionary, track_id: String) -> Dictionary:
	for info in tracks.get("tracks", []):
		if str(info.get("id", "")) == track_id:
			return info
	return {}


func _ensure_input_actions() -> void:
	for action in DEFAULT_KEYS:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		if InputMap.action_get_events(action).is_empty():
			for key in DEFAULT_KEYS[action]:
				var event := InputEventKey.new()
				event.physical_keycode = key
				InputMap.action_add_event(action, event)
