extends Node3D
## Escena principal: carga datos (grilla, pistas, auto), spawnea el auto en Bakú y arma el HUD.
## Esc abre el menú de pausa (PauseMenu). En contrarreloj, al cerrar la última vuelta se
## sueltan los controles y se muestra el resultado (ResultsScreen).

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
var mode_name: String = ""
var results_delay: float = 2.5

@onready var track: BakuTrack = $BakuTrack
@onready var car: CarController = $Car
@onready var hud: RaceHUD = $HUD
@onready var lap_timer: LapTimer = $LapTimer
@onready var pause_menu: PauseMenu = $PauseMenu
@onready var results_screen: ResultsScreen = $ResultsScreen


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
	_setup_mode()
	track.checkpoint_crossed.connect(_on_checkpoint_crossed)
	car.was_reset.connect(lap_timer.abort_lap)
	hud.bind_lap_timer(lap_timer)
	car.steering_wheel.bind_lap_timer(lap_timer)

	pause_menu.set_accent(team_color)
	pause_menu.paused_changed.connect(_on_paused_changed)
	pause_menu.restart_requested.connect(get_tree().reload_current_scene)
	pause_menu.menu_requested.connect(get_tree().change_scene_to_file.bind(MENU_SCENE))
	results_screen.set_accent(team_color)
	results_screen.repeat_requested.connect(get_tree().reload_current_scene)
	results_screen.menu_requested.connect(get_tree().change_scene_to_file.bind(MENU_SCENE))
	lap_timer.session_finished.connect(_on_session_finished)
	Settings.changed.connect(_on_setting_changed)


## Modo elegido en el menú (GameState); en contrarreloj fija las vueltas del cronómetro.
func _setup_mode() -> void:
	var modes := DataLoader.load_json(DataLoader.MODES_PATH)
	results_delay = float(modes.get("results_delay", results_delay))
	var mode_id := GameState.selected_mode
	if mode_id.is_empty():
		mode_id = str(modes.get("default_mode", GameState.MODE_PRACTICE))
	var mode := DataLoader.find_mode(modes, mode_id)
	mode_name = str(mode.get("name", "Práctica libre"))
	if mode_id == GameState.MODE_TIME_TRIAL:
		var laps := GameState.lap_count
		if laps <= 0:
			laps = int(mode.get("default_laps", 3))
		lap_timer.lap_limit = laps
		mode_name = "%s · %d %s" % [mode_name, laps, "vuelta" if laps == 1 else "vueltas"]
	hud.set_track_name("%s\n%s" % [track_name, mode_name])


func _on_checkpoint_crossed(checkpoint: int, body: Node3D) -> void:
	if body == car:
		lap_timer.on_checkpoint(checkpoint)


func _on_session_finished() -> void:
	car.controls_enabled = false
	pause_menu.set_process_unhandled_input(false)
	await get_tree().create_timer(results_delay, false).timeout
	car.engine_audio.set_muted(true)
	car.audio_fx.set_muted(true)
	hud.visible = false
	results_screen.open(lap_timer, _session_subtitle())


func _session_subtitle() -> String:
	return "#%s %s  ·  %s  ·  %s" % [UiKit.number_text(selected_driver.get("number", "")),
		str(selected_driver.get("name", "")), track_name, mode_name]


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
		mode_name,
	]
	if lap_timer.running:
		var lap_text := str(lap_timer.lap)
		if lap_timer.lap_limit > 0:
			lap_text += "/%d" % lap_timer.lap_limit
		parts.append("Vuelta %s · %s" % [lap_text, LapTimer.format_time(lap_timer.current_time)])
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
