extends Node3D
## Escena principal: carga datos (grilla, pistas, auto), spawnea el auto en Bakú y arma el HUD.
## Esc abre el menú de pausa (PauseMenu).

const MENU_SCENE := "res://scenes/menu.tscn"
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
	"gear_up": [KEY_E],
	"gear_down": [KEY_Q],
	"toggle_gearbox": [KEY_M],
}

const FALLBACK_DRIVER := {"id": "colapinto", "name": "Franco Colapinto", "number": 43, "country": "AR"}
const FALLBACK_TEAM := {"id": "alpine", "name": "Alpine", "color": "#FF87BC"}

var selected_driver: Dictionary = {}
var selected_team: Dictionary = {}
var track_name: String = ""

@onready var track: BakuTrack = $BakuTrack
@onready var car: CarController = $Car
@onready var hud: RaceHUD = $HUD
@onready var lap_timer: LapTimer = $LapTimer
@onready var pause_menu: PauseMenu = $PauseMenu


func _ready() -> void:
	_ensure_input_actions()

	var grid := DataLoader.load_json(DataLoader.GRID_PATH)
	var tracks := DataLoader.load_json(DataLoader.TRACKS_PATH)
	var driver_id := GameState.selected_driver_id
	if driver_id.is_empty():
		driver_id = str(grid.get("default_driver_id", "colapinto"))
	_select_driver(grid, driver_id)
	var track_info := _find_track(tracks, TRACK_ID)

	var car_data := DataLoader.load_json(DataLoader.CAR_PATH)
	car.configure(car_data)
	Settings.apply_to_car(car)
	$Sun.shadow_enabled = Settings.shadows_enabled()
	car.spawn_transform = track.get_spawn_transform()
	car.reset_to_spawn()

	var team_color := DataLoader.team_primary(selected_team)
	car.set_livery(team_color, DataLoader.team_secondary(selected_team),
		UiKit.number_text(selected_driver.get("number", "")))

	hud.bind_car(car)
	var dashboard_data = car_data.get("dashboard", {})
	if dashboard_data is Dictionary:
		hud.configure_dashboard(dashboard_data)
		car.steering_wheel.configure(dashboard_data)
	hud.set_driver_info(selected_driver, selected_team, team_color)
	track_name = str(track_info.get("display_name", track.track_name))
	hud.set_track_name(track_name)

	lap_timer.setup(TRACK_ID)
	track.checkpoint_crossed.connect(_on_checkpoint_crossed)
	car.was_reset.connect(lap_timer.abort_lap)
	hud.bind_lap_timer(lap_timer)
	car.steering_wheel.bind_lap_timer(lap_timer)

	pause_menu.set_accent(team_color)
	pause_menu.paused_changed.connect(_on_paused_changed)
	pause_menu.restart_requested.connect(get_tree().reload_current_scene)
	pause_menu.menu_requested.connect(get_tree().change_scene_to_file.bind(MENU_SCENE))
	Settings.changed.connect(_on_setting_changed)


func _on_checkpoint_crossed(checkpoint: int, body: Node3D) -> void:
	if body == car:
		lap_timer.on_checkpoint(checkpoint)


func _on_paused_changed(paused: bool) -> void:
	car.engine_audio.set_muted(paused)
	car.audio_fx.set_muted(paused)
	hud.visible = not paused
	if paused:
		pause_menu.set_subtitle(_pause_subtitle())


func _on_setting_changed(_key: String) -> void:
	Settings.apply_to_car(car, false)
	$Sun.shadow_enabled = Settings.shadows_enabled()


func _pause_subtitle() -> String:
	var parts: Array[String] = [
		"#%s %s" % [UiKit.number_text(selected_driver.get("number", "")), str(selected_driver.get("name", ""))],
		track_name,
	]
	if lap_timer.running:
		parts.append("Vuelta %d · %s" % [lap_timer.lap, LapTimer.format_time(lap_timer.current_time)])
	if lap_timer.best_lap >= 0.0:
		parts.append("Mejor %s" % LapTimer.format_time(lap_timer.best_lap))
	return "  ·  ".join(parts)


func _select_driver(grid: Dictionary, driver_id: String) -> void:
	var found := DataLoader.find_driver(grid, driver_id)
	if not found.is_empty():
		selected_driver = found["driver"]
		selected_team = found["team"]
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
