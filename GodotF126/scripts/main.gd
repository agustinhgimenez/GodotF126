extends Node3D
## Escena principal: carga datos (grilla, pistas, auto, setup), spawnea el auto en la pista
## generada (Paso 53: GameState.selected_track; Bakú por defecto) y arma el HUD.
## Esc abre el menú de pausa (PauseMenu). En contrarreloj, al cerrar la última vuelta se
## sueltan los controles y se muestra el resultado (ResultsScreen).

const MENU_SCENE := "res://scenes/menu.tscn"
const LOADING_SCENE := "res://scenes/loading.tscn"

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
	"aero_mode": [KEY_F],
	"overtake": [KEY_G],
	"brake_bias_rearward": [KEY_Z],
	"brake_bias_forward": [KEY_X],
	"traction_control": [KEY_T],
	"ers_mode": [KEY_V],
	"racing_line": [KEY_L],
	"ghost": [KEY_H],
	"ai_rival": [KEY_I],
	"pit_limiter": [KEY_P],
	"pit_compound": [KEY_O],
}
const CAR_SCENE := preload("res://scenes/car.tscn")
const AI_PATH := "res://data/ai.json"

const FALLBACK_DRIVER := {"id": "colapinto", "name": "Franco Colapinto", "number": 43, "country": "AR"}
const FALLBACK_TEAM := {"id": "alpine", "name": "Alpine", "color": "#FF87BC"}

var selected_driver: Dictionary = {}
var selected_team: Dictionary = {}
var track_name: String = ""
var mode_name: String = ""
var results_delay: float = 2.5
## Setup del auto (Paso 35; user://setup.json). En práctica se puede cambiar desde la pausa.
var car_setup: CarSetup
## Vibración del mando (Paso 37; intensidad = opción "vibration").
var rumble := ControllerRumble.new()
## Línea de trazada (Paso 38; modo = opción "racing_line", tecla L).
var racing_line: RacingLine
## Telemetría por vuelta (Paso 39; se ve en la pausa → Telemetría).
var telemetry: TelemetryRecorder
## Delta en vivo contra la mejor vuelta (Paso 40; HUD y volante).
var live_delta: LiveDelta
## Auto fantasma de la vuelta de referencia (Paso 43; opción "ghost", tecla H).
var ghost: GhostCar
## Rivales de práctica manejados por la IA (Paso 44; tecla I, sólo en práctica, hasta
## practice_rival.max; nivel = opción "ai_level"). ai_car / ai_driver / ai_name: el último que
## se sumó (null si no hay).
var ai_cars: Array[CarController] = []
var ai_drivers: Array[AiDriver] = []
var ai_car: CarController
var ai_driver: AiDriver
var ai_name: String = ""
## Autos en pista (Paso 45): rebufo, distancia al de adelante y contactos.
var traffic: RaceTraffic
## Comisarios (Paso 46): culpa y sanción de cada toque entre autos.
var stewards: RaceStewards
## Carrera con la grilla completa (Paso 47; null fuera del modo carrera).
var race: RaceSession
## Calle de boxes (Paso 48): limitador (tecla P), paradas y sanciones por exceso de velocidad.
var pit_lane: PitLane
## Paso 49: estrategia de neumáticos (data/strategy.json; compuesto de la parada con la tecla O)
## y radio del ingeniero (sólo en carrera; null fuera de ella).
var strategy: RaceStrategy
var radio: EngineerRadio
var race_control: RaceControl
## Paso 51: grabación de la carrera y repetición (sólo en carrera; null fuera de ella).
var recorder: RaceRecorder
var replay: ReplayViewer
## Paso 52: resultado con puntos (se arma al terminar la carrera) y si se pudo guardar.
var results: RaceResults
var results_saved: bool = false
## Paso 55: temporada en curso si la sesión es una fecha del campeonato (null si no) y si la
## carrera ya se sumó.
var championship: Championship
var championship_added: bool = false
## Paso 56: clima de la sesión, lluvia que sigue a la cámara y rocío detrás de cada auto.
var weather: Weather
var rain_fx: RainFx
var sprays: Array[CarSpray] = []
## Clasificación de la sesión (Paso 47): {driver, team, time, pace, player} de la pole al último.
var qualifying: Array[Dictionary] = []
var _car_data: Dictionary = {}
var _laps: int = 0
var _standing_start: bool = false
var _start_data: Dictionary = {}
var _physics_guard: Node
var _replay_from_results: bool = false
var _hud_was_visible: bool = true

@onready var track: TrackGenerator = $Track
@onready var car: CarController = $Car
@onready var hud: RaceHUD = $HUD
@onready var lap_timer: LapTimer = $LapTimer
@onready var pause_menu: PauseMenu = $PauseMenu
@onready var results_screen: ResultsScreen = $ResultsScreen
@onready var start_lights: StartLights = $StartLights
@onready var tv_cameras: TvCameras = $TvCameras
@onready var track_limits: TrackLimits = $TrackLimits
@onready var aero_zones: AeroZones = $AeroZones


func _ready() -> void:
	_ensure_input_actions()

	var grid := DataLoader.load_json(DataLoader.GRID_PATH)
	var driver_id := GameState.selected_driver_id
	if driver_id.is_empty():
		driver_id = str(grid.get("default_driver_id", "colapinto"))
	_select_driver(grid, driver_id)
	var track_info := track.track_info

	var tv_data = track_info.get("tv_cameras", {})
	if tv_data is Dictionary:
		tv_cameras.configure(tv_data)
	tv_cameras.setup(track.centerline, track.wall_left, track.wall_right, car,
		track.checkpoint_indices[0] if not track.checkpoint_indices.is_empty() else 0,
		track.is_grandstand)
	var limits_data = track_info.get("limits", {})
	if limits_data is Dictionary:
		track_limits.configure(limits_data)
	track_limits.setup(track, car, lap_timer)
	car.camera_mode_applied.connect(tv_cameras.set_active)

	var car_data := DataLoader.load_json(DataLoader.CAR_PATH)
	_car_data = car_data
	car.configure(car_data)
	car_setup = CarSetup.load_saved()
	car.apply_setup(car_setup)
	car.fit_tyres(GameState.tyre_compound)
	weather = Weather.load_default(GameState.weather)
	weather.apply_to_car(car)
	Settings.apply_to_car(car)
	_apply_lighting()
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

	lap_timer.setup(str(track_info.get("records_key", track.track_id)))
	_load_championship()
	_setup_mode()
	aero_zones.configure(track.aero_zone_data())
	aero_zones.setup(track, car, track_limits, lap_timer)
	racing_line = RacingLine.new()
	racing_line.name = "RacingLine"
	var line_data = track_info.get("racing_line", {})
	if line_data is Dictionary:
		racing_line.configure(line_data)
	add_child(racing_line)
	racing_line.mode = str(Settings.get_value("racing_line"))
	racing_line.setup(track, car, track_limits)
	traffic = RaceTraffic.new()
	traffic.name = "RaceTraffic"
	var traffic_data = DataLoader.load_json(AI_PATH).get("traffic", {})
	if traffic_data is Dictionary:
		traffic.configure(traffic_data)
	add_child(traffic)
	traffic.setup(track, racing_line)
	traffic.add_car(car)
	car.set_meta("driver_name", str(selected_driver.get("name", "Jugador")))
	car.set_meta("team_id", str(selected_team.get("id", "")))
	pit_lane = PitLane.new()
	pit_lane.name = "PitLane"
	pit_lane.configure(track.pit_data, grid)
	add_child(pit_lane)
	pit_lane.setup(track, traffic)
	traffic.pit_lane = pit_lane
	track_limits.pit_lane = pit_lane
	pit_lane.speeding.connect(_on_pit_speeding)
	strategy = RaceStrategy.load_default()
	weather.apply_to_strategy(strategy)
	stewards = RaceStewards.new()
	stewards.name = "RaceStewards"
	stewards.configure(DataLoader.load_json(RaceStewards.DATA_PATH))
	add_child(stewards)
	stewards.setup(traffic)
	stewards.decided.connect(_on_incident_decided)
	telemetry = TelemetryRecorder.new()
	telemetry.name = "Telemetry"
	telemetry.configure(DataLoader.load_json(TelemetryRecorder.DATA_PATH))
	add_child(telemetry)
	telemetry.setup(track, car, lap_timer, track_limits, str(track_info.get("records_key", track.track_id)))
	live_delta = LiveDelta.new()
	live_delta.name = "LiveDelta"
	var delta_data = DataLoader.load_json(TelemetryRecorder.DATA_PATH).get("delta", {})
	if delta_data is Dictionary:
		live_delta.configure(delta_data)
	add_child(live_delta)
	live_delta.setup(telemetry, lap_timer)
	ghost = GhostCar.new()
	ghost.name = "GhostCar"
	var ghost_data = DataLoader.load_json(TelemetryRecorder.DATA_PATH).get("ghost", {})
	if ghost_data is Dictionary:
		ghost.configure(ghost_data)
	add_child(ghost)
	ghost.setup(car, lap_timer, live_delta, team_color)
	ghost.enabled = bool(Settings.get_value("ghost"))
	track.checkpoint_crossed.connect(_on_checkpoint_crossed)
	if not GameState.is_race():
		car.was_reset.connect(lap_timer.abort_lap)
	lap_timer.lap_started.connect(func(_lap: int) -> void: car.fuel.new_lap())
	hud.bind_lap_timer(lap_timer)
	hud.bind_delta(live_delta)
	hud.bind_pit(pit_lane)
	car.steering_wheel.bind_lap_timer(lap_timer)
	car.steering_wheel.bind_delta(live_delta)
	if GameState.is_race() or GameState.is_qualifying():
		_setup_qualifying()
	if GameState.is_race():
		_setup_race()
	if _standing_start:
		_setup_start_lights()
	_setup_weather_fx()

	pause_menu.set_accent(team_color)
	if not GameState.is_competitive():
		pause_menu.enable_setup(car_setup, car.setup_base())
		pause_menu.setup_changed.connect(_on_setup_changed)
	pause_menu.bind_telemetry(telemetry)
	pause_menu.paused_changed.connect(_on_paused_changed)
	pause_menu.restart_requested.connect(get_tree().reload_current_scene)
	pause_menu.menu_requested.connect(get_tree().change_scene_to_file.bind(MENU_SCENE))
	results_screen.set_accent(team_color)
	results_screen.repeat_requested.connect(get_tree().reload_current_scene)
	results_screen.menu_requested.connect(get_tree().change_scene_to_file.bind(MENU_SCENE))
	results_screen.next_requested.connect(_on_next_requested)
	lap_timer.session_finished.connect(_on_session_finished)
	Settings.changed.connect(_on_setting_changed)
	var rumble_data = InputBindings.data().get("rumble", {})
	if rumble_data is Dictionary:
		rumble.configure(rumble_data)
	rumble.intensity = float(Settings.get_value("vibration")) / 100.0
	rumble.bind_car(car)
	# El auto ya está en su lugar (grilla o largada): elegir la torre de TV desde ahí.
	tv_cameras.set_active(car.uses_external_camera())
	_physics_guard = Node.new()
	_physics_guard.name = "PhysicsGuard"
	_physics_guard.tree_exiting.connect(_release_physics)
	add_child(_physics_guard)
	child_order_changed.connect(_keep_guard_last)


## Modo elegido en el menú (GameState); en contrarreloj fija las vueltas del cronómetro.
func _setup_mode() -> void:
	var modes := DataLoader.load_json(DataLoader.MODES_PATH)
	results_delay = float(modes.get("results_delay", results_delay))
	var mode_id := GameState.selected_mode
	if mode_id.is_empty():
		mode_id = str(modes.get("default_mode", GameState.MODE_PRACTICE))
	var mode := DataLoader.find_mode(modes, mode_id)
	mode_name = str(mode.get("name", "Práctica libre"))
	car.fill_fuel(car.fuel.practice_kg)
	if mode.has("lap_options"):
		var laps := GameState.lap_count
		if laps <= 0 or not float(laps) in mode.get("lap_options", []):
			laps = int(mode.get("default_laps", 3))
		_laps = laps
		lap_timer.lap_limit = laps
		mode_name = "%s · %d %s" % [mode_name, laps, "vuelta" if laps == 1 else "vueltas"]
		# Clasificación: más la vuelta de salida hasta la meta.
		car.fill_fuel(car.fuel.race_load(laps + (1 if mode_id == GameState.MODE_QUALIFYING else 0)))
	mode_name += " · neumático %s" % str(car.tyres.compound()["name"]).to_lower()
	if not weather.is_dry():
		mode_name += " · %s" % weather.label()
	if championship != null:
		mode_name = "Fecha %d/%d · %s" % [championship.round_index() + 1, championship.round_count(), mode_name]
	hud.set_track_name("%s\n%s" % [track_name, mode_name])
	_standing_start = bool(mode.get("standing_start", false))
	var start_data = modes.get("start_lights", {})
	_start_data = start_data if start_data is Dictionary else {}


## Largada detenida (Paso 17): el auto va a la grilla detrás de la línea y el cronómetro
## arranca cuando se apaga el semáforo, no al cruzar la meta.
func _setup_start_lights() -> void:
	if race == null:
		car.spawn_transform = track.get_grid_transform(float(_start_data.get("grid_distance", 6.0)))
		car.reset_to_spawn()
	start_lights.configure(_start_data)
	start_lights.lights_out.connect(_on_lights_out)
	start_lights.reaction_measured.connect(func(seconds: float) -> void: lap_timer.reaction_time = seconds)
	hud.bind_start_lights(start_lights)
	start_lights.begin(car, track.get_start_line_transform(), TrackGenerator.GANTRY_HEIGHT)


func _on_lights_out() -> void:
	if start_lights.jumped:
		lap_timer.add_penalty(float(_start_data.get("jump_penalty", 5.0)), "Largada en falso")
		if race != null:
			race.add_extra_penalty(car, float(_start_data.get("jump_penalty", 5.0)), "Largada en falso")
	lap_timer.start_now()
	if race != null:
		race.start(GameState.session_seed)


## Clasificación de la sesión (Paso 47): la IA con tiempos estimados por ritmo (semilla de la
## sesión) y el jugador con su vuelta de la clasificación o, si no corrió, con su récord.
func _setup_qualifying() -> void:
	if GameState.session_seed == 0:
		GameState.session_seed = randi() % 1000000 + 1
	var player_time := GameState.qualifying_time
	if GameState.is_race() and player_time < 0.0 and lap_timer.record_lap > 0.0:
		player_time = lap_timer.record_lap * weather.lap_factor()
	var ai_data := weather.ai_data(RaceSession.track_ai_data(DataLoader.load_json(AI_PATH), track.track_info))
	qualifying = RaceSession.qualifying(DataLoader.load_json(DataLoader.GRID_PATH),
		str(selected_driver.get("id", "")), player_time, str(Settings.get_value("ai_level")), ai_data,
		GameState.session_seed)
	if GameState.is_qualifying() and qualifying.size() > 1:
		var pole := qualifying[0] if not qualifying[0]["player"] else qualifying[1]
		hud.show_message("Clasificación: la pole de la IA es %s (%s)" % [
			LapTimer.format_time(float(pole["time"])), str(pole["driver"].get("name", ""))], 4.0)


## Carrera (Paso 47): los 21 rivales en el orden de la clasificación, todos en la grilla.
func _setup_race() -> void:
	var ai_data := DataLoader.load_json(AI_PATH)
	var modes := DataLoader.load_json(DataLoader.MODES_PATH)
	race = RaceSession.new()
	race.name = "RaceSession"
	var race_data = modes.get("race", {})
	var ai_race = ai_data.get("race", {})
	race.configure(race_data if race_data is Dictionary else {}, ai_race if ai_race is Dictionary else {}, _start_data)
	add_child(race)
	race.setup(traffic, stewards, _laps)
	race.player = car
	race.pit_lane = pit_lane
	car.repair_on_reset = false
	var level := str(Settings.get_value("ai_level"))
	var levels: Dictionary = ai_data.get("levels", {})
	for p in qualifying.size():
		var info: Dictionary = qualifying[p]
		var place := race.slot_place(p)
		var at := track.index_at_distance(track.start_index(), -place.x)
		if info["player"]:
			var heading := Basis.looking_at(track.flat_tangent(at), Vector3.UP)
			car.spawn_transform = Transform3D(heading, track.edge_point(at, place.y, 0.0) + Vector3(0, 0.6, 0))
			car.reset_to_spawn()
			race.add_entry(car, selected_driver, selected_team, null, p, float(info["time"]))
			continue
		var driver := _add_ai_car(info["driver"], info["team"], ai_data, p + 1)
		driver.set_level(level, levels)
		driver.set_pace(float(info["pace"]))
		driver.place_at(at, 0.0, place.y)
		driver.hold_lane(place.y)
		race.add_entry(driver.car, info["driver"], info["team"], driver, p, float(info["time"]))
	hud.bind_race(race)
	race.car_finished.connect(func(finished: CarController, _position: int) -> void:
		if finished == car:
			lap_timer.finish_now())
	race.prepare(GameState.session_seed, strategy)
	race.rule_broken.connect(_on_rule_broken)
	pit_lane.stop_finished.connect(func(who: CarController, _wing: bool) -> void: race.on_stop_finished(who))
	radio = EngineerRadio.new()
	radio.name = "EngineerRadio"
	add_child(radio)
	radio.setup(strategy, race, pit_lane, track, car)
	hud.bind_radio(radio, DataLoader.team_primary(selected_team))
	radio.begin()
	race_control = RaceControl.new()
	race_control.name = "RaceControl"
	race_control.configure(DataLoader.load_json(RaceControl.DATA_PATH))
	add_child(race_control)
	race_control.setup(race, traffic, track, racing_line, pit_lane, stewards, car, radio)
	hud.bind_race_control(race_control)
	var replay_data := DataLoader.load_json(RaceRecorder.DATA_PATH)
	recorder = RaceRecorder.new()
	recorder.name = "RaceRecorder"
	recorder.configure(replay_data)
	add_child(recorder)
	recorder.setup(race, race_control, traffic)
	replay = ReplayViewer.new()
	replay.name = "ReplayViewer"
	add_child(replay)
	replay.configure(replay_data)
	replay.setup(recorder, tv_cameras, stewards, race_control, car, self, DataLoader.team_primary(selected_team))
	replay.closed.connect(_on_replay_closed)
	pause_menu.enable_replay()
	pause_menu.replay_requested.connect(_open_replay.bind(false))
	results_screen.replay_requested.connect(_open_replay.bind(true))
	var mine := race.entry_of(car)
	hud.show_message("Largás P%d (%s)" % [int(mine["grid"]) + 1,
		"clasificación %s" % LapTimer.format_time(float(mine["quali"])) if float(mine["quali"]) > 0.0 else "sin tiempo"], 4.0)


## Paso 51: repetición desde la pausa (unos segundos antes de ahora) o desde el resultado (un
## poco antes de tu llegada). El árbol ya está en pausa; el HUD se esconde mientras dura.
func _open_replay(from_results: bool) -> void:
	if replay == null or not replay.can_open():
		hud.show_message("Todavía no hay nada grabado", 2.0)
		return
	_replay_from_results = from_results
	_hud_was_visible = hud.visible
	if from_results:
		results_screen.hide_for_replay()
	else:
		pause_menu.hide_for_replay()
	hud.visible = false
	replay.open(replay.finish_start() if from_results else replay.default_start())


func _on_replay_closed() -> void:
	hud.visible = _hud_was_visible
	if _replay_from_results:
		results_screen.show_after_replay()
	else:
		pause_menu.show_after_replay()


## Paso 55: la temporada guardada, si esta sesión es su fecha actual (si no, la sesión es suelta).
func _load_championship() -> void:
	if not GameState.championship:
		return
	championship = Championship.load_saved()
	if championship == null or championship.is_finished() \
			or TrackGenerator.resolve_track_id(str(championship.current_round()["track_id"])) != track.track_id:
		championship = null
		GameState.championship = false


## Botón extra del resultado: "Correr la carrera" (clasificación) o, en el campeonato,
## "Siguiente carrera" / "Final de temporada".
func _on_next_requested() -> void:
	if GameState.is_qualifying():
		_go_to_race()
	elif championship != null and championship.is_finished():
		_open_season_final()
	elif championship != null:
		championship.prepare_round()
		get_tree().change_scene_to_file(LOADING_SCENE)


## Botón "Correr la carrera" del resultado de la clasificación.
func _go_to_race() -> void:
	var modes := DataLoader.load_json(DataLoader.MODES_PATH)
	GameState.selected_mode = GameState.MODE_RACE
	GameState.lap_count = championship.laps if championship != null \
		else int(DataLoader.find_mode(modes, GameState.MODE_RACE).get("default_laps", 3))
	get_tree().reload_current_scene()


func _on_checkpoint_crossed(checkpoint: int, body: Node3D) -> void:
	if body == car and not start_lights.is_active():
		lap_timer.on_checkpoint(checkpoint)


func _physics_process(delta: float) -> void:
	if car.controls_enabled:
		rumble.update(car, delta)
	# En carrera, R deja el auto quieto sobre la pista donde está (Main procesa antes que Car).
	if race != null and race.running and car.controls_enabled and Input.is_action_just_pressed("reset_car"):
		var at := int(track.locate(car.global_position, track_limits.index).x)
		var heading := Basis.looking_at(track.flat_tangent(at), Vector3.UP)
		car.spawn_transform = Transform3D(heading, track.edge_point(at, racing_line.offsets[at], 0.0) + Vector3(0, 0.6, 0))


func _exit_tree() -> void:
	rumble.stop()


# Godot saca de la escena primero al último hijo: el guardián va siempre último para que, al
# liberar la escena, todos los autos y áreas salgan del espacio de Jolt antes que cualquier
# superficie que estén tocando (la calle de boxes y los autos de la IA se suman después del
# auto y de la pista; si no, Jolt a veces se cae al liberar).
func _keep_guard_last() -> void:
	if is_instance_valid(_physics_guard) and _physics_guard.get_parent() == self \
			and _physics_guard.get_index() != get_child_count() - 1:
		move_child.call_deferred(_physics_guard, -1)


func _release_physics() -> void:
	if child_order_changed.is_connected(_keep_guard_last):
		child_order_changed.disconnect(_keep_guard_last)
	for node in find_children("*", "RigidBody3D", true, false):
		var body := node as RigidBody3D
		body.contact_monitor = false
		PhysicsServer3D.body_set_space(body.get_rid(), RID())
	for node in find_children("*", "Area3D", true, false):
		PhysicsServer3D.area_set_space((node as Area3D).get_rid(), RID())


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("racing_line") and car.controls_enabled:
		var next := RacingLine.next_mode(str(Settings.get_value("racing_line")))
		Settings.set_value("racing_line", next)
		hud.show_message("Línea de trazada: %s" % RacingLine.mode_name(next), 1.5)
	elif event.is_action_pressed("ghost") and car.controls_enabled:
		var on := not bool(Settings.get_value("ghost"))
		Settings.set_value("ghost", on)
		var note := "" if not on or ghost.reference() != null or live_delta.pick_reference() != null \
			else " (aparece cuando haya una vuelta válida)"
		hud.show_message("Auto fantasma: %s%s" % ["sí" if on else "no", note], 1.5)
	elif event.is_action_pressed("pit_limiter") and car.controls_enabled:
		pit_lane.toggle_limiter(car)
	elif event.is_action_pressed("pit_compound") and car.controls_enabled:
		cycle_pit_compound()
	elif event.is_action_pressed("ai_rival") and car.controls_enabled and not GameState.is_competitive():
		var ai_data := DataLoader.load_json(AI_PATH)
		var most := int(ai_data.get("practice_rival", {}).get("max", 3))
		if ai_cars.size() < most:
			spawn_ai_rival()
			hud.show_message("Rival IA %d/%d: %s · %s%s" % [ai_cars.size(), most, ai_name,
				AiDriver.level_name(ai_driver.level, ai_data.get("levels", {})),
				" (I los saca)" if ai_cars.size() == most else ""], 2.0)
		else:
			remove_ai_rival()
			hud.show_message("Rivales IA fuera", 1.5)


## Suma un auto manejado por la IA detrás del jugador (`practice_rival.spawn_behind` m, o más
## atrás si ahí ya hay otro), sobre la línea y a la velocidad del jugador (sin pasar la objetivo
## de la línea), con el nivel `level` (vacío = la opción "ai_level").
func spawn_ai_rival(level: String = "") -> AiDriver:
	var ai_data := DataLoader.load_json(AI_PATH)
	var rival_data: Dictionary = ai_data.get("practice_rival", {})
	var rival := _pick_rival(str(rival_data.get("driver_id", "")) if ai_cars.is_empty() else "")
	_add_ai_car(rival["driver"], rival["team"], ai_data, ai_cars.size() + 1)
	if level.is_empty():
		level = str(Settings.get_value("ai_level"))
	ai_driver.set_level(level, ai_data.get("levels", {}))
	var here := int(track.locate(car.global_position, track_limits.index).x)
	var behind := float(rival_data.get("spawn_behind", 40.0))
	var at := track.index_at_distance(here, -behind)
	for attempt in 20:
		if not _spot_taken(at):
			break
		behind += 20.0
		at = track.index_at_distance(here, -behind)
	ai_driver.place_at(at, minf(maxf(car.forward_speed, 0.0), racing_line.target_speed[at]))
	return ai_driver


## Auto de la IA con el piloto y el equipo dados (bloques "car" y "driver" de ai.json), ya en
## el tráfico; queda como ai_car / ai_driver. Falta el nivel y el lugar.
func _add_ai_car(driver: Dictionary, team: Dictionary, ai_data: Dictionary, seed_value: int) -> AiDriver:
	var car_info: Dictionary = ai_data.get("car", {})
	ai_car = CAR_SCENE.instantiate() as CarController
	ai_car.name = "AiRival%d" % (ai_cars.size() + 1)
	ai_car.ai_controlled = true
	add_child(ai_car)
	ai_car.configure(_car_data)
	var default_setup := CarSetup.new()
	default_setup.configure(DataLoader.load_json(CarSetup.DATA_PATH))
	var setup_values = car_info.get("setup", {})
	if setup_values is Dictionary:
		for id in setup_values:
			default_setup.set_value(str(id), float(setup_values[id]))
	ai_car.apply_setup(default_setup)
	ai_car.fit_tyres(weather.compound(str(car_info.get("compound", "medium"))))
	weather.apply_to_car(ai_car)
	ai_car.fill_fuel(car.fuel.kg)
	ai_car.gearbox.manual = false
	ai_car.active_aero.automatic = true
	ai_car.abs_enabled = bool(car_info.get("abs", true))
	ai_car.traction_control.set_level(int(car_info.get("traction_control", 3)))
	ai_car.steer_response = float(car_info.get("steer_response", ai_car.steer_response))
	ai_car.steer_limit = float(car_info.get("steer_limit", ai_car.steer_limit))
	ai_car.tyre_substeps = clampi(int(car_info.get("tyre_substeps", CarController.TYRE_SUBSTEPS)), 1, CarController.TYRE_SUBSTEPS)
	ai_name = str(driver.get("name", "IA"))
	ai_car.set_meta("driver_id", str(driver.get("id", "")))
	ai_car.set_meta("team_id", str(team.get("id", "")))
	ai_car.set_meta("driver_name", ai_name)
	ai_car.set_livery(DataLoader.team_primary(team), DataLoader.team_secondary(team),
		UiKit.number_text(driver.get("number", "")))
	ai_driver = AiDriver.new()
	ai_driver.name = "AiDriver%d" % (ai_cars.size() + 1)
	var driver_data = ai_data.get("driver", {})
	if driver_data is Dictionary:
		ai_driver.configure(driver_data)
	ai_driver.seed_value = seed_value
	add_child(ai_driver)
	traffic.add_car(ai_car)
	ai_driver.setup(ai_car, track, racing_line, traffic)
	ai_driver.pit_lane = pit_lane
	ai_cars.append(ai_car)
	ai_drivers.append(ai_driver)
	return ai_driver


## Ya hay un auto a menos de 15 m (por la pista) del índice i.
func _spot_taken(i: int) -> bool:
	var at := racing_line.distances[i]
	for k in traffic.cars.size():
		var d := absf(fposmod(racing_line.distances[traffic.index[k]] - at, traffic.lap_length()))
		if minf(d, traffic.lap_length() - d) < 15.0:
			return true
	return false


## Sanción de los comisarios: la del jugador va al cronómetro; avisa en el HUD lo que toca al
## jugador y las penalizaciones de los demás.
func _on_incident_decided(incident: Dictionary) -> void:
	var action := str(incident["action"])
	if action == "ignored":
		return
	if incident["guilty"] == car and action == "penalty":
		var why := RaceStewards.reason(incident)
		lap_timer.add_penalty(float(incident["seconds"]), why.left(1).to_upper() + why.substr(1))
	if incident["a"] == car or incident["b"] == car or action == "penalty":
		hud.show_message(stewards.describe(incident), 3.0)


## Exceso de velocidad en la calle de boxes: la del jugador va al cronómetro; en carrera, a la
## penalización de cada uno.
func _on_pit_speeding(who: CarController, kmh: float, seconds: float) -> void:
	var reason := "Exceso de velocidad en boxes"
	if who == car:
		lap_timer.add_penalty(seconds, reason)
	if race != null:
		race.add_extra_penalty(who, seconds, reason)
	if who == car or race != null:
		hud.show_message("%s: %s (%d km/h) · +%d s" % [reason, RaceStewards.car_name(who), roundi(kmh), roundi(seconds)],
			3.0, RaceHUD.COLOR_WARNING if who == car else RaceHUD.COLOR_NEUTRAL)


## Paso 49: tecla O, el compuesto siguiente para la próxima parada (en carrera, marca el que
## recomienda el ingeniero).
func cycle_pit_compound() -> void:
	var ids := strategy.ids()
	if ids.is_empty():
		return
	var next := ids[(ids.find(pit_lane.next_compound(car)) + 1) % ids.size()]
	pit_lane.set_next_compound(car, next)
	var note := ""
	if race != null and race.strategy_on:
		var entry := race.entry_of(car)
		var advice := strategy.next_compound(race.remaining_laps(entry) - 1, entry["compounds"], true)
		note = " (recomendado)" if next == advice else ""
		if strategy.two_compound_rule and not RaceStrategy.rule_met(entry["compounds"]) and (entry["compounds"] as Array).has(next):
			note = " (ya lo usaste: hacen falta dos compuestos)"
	hud.show_message("Para la parada: %s%s" % [strategy.compound_name(next).to_lower(), note], 2.0,
		strategy.compound_color(next))


## Paso 49: terminó la carrera con un solo compuesto.
func _on_rule_broken(who: CarController, seconds: float) -> void:
	if who == car:
		lap_timer.add_penalty(seconds, "Un solo compuesto")


## Saca a todos los rivales de la IA.
func remove_ai_rival() -> void:
	for driver in ai_drivers:
		driver.queue_free()
	for rival in ai_cars:
		traffic.remove_car(rival)
		rival.queue_free()
	ai_drivers.clear()
	ai_cars.clear()
	ai_driver = null
	ai_car = null


## El piloto de `driver_id` o, si está vacío, el primero de un equipo que no sea el del jugador
## ni el de otro rival ya en pista.
func _pick_rival(driver_id: String) -> Dictionary:
	var grid := DataLoader.load_json(DataLoader.GRID_PATH)
	if not driver_id.is_empty():
		var found := DataLoader.find_driver(grid, driver_id)
		if not found.is_empty():
			return found
	var used: Array[String] = [str(selected_team.get("id", ""))]
	for rival in ai_cars:
		used.append(str(rival.get_meta("team_id", "")))
	for team in grid.get("teams", []):
		if str(team.get("id", "")) in used:
			continue
		for driver in team.get("drivers", []):
			return {"driver": driver, "team": team}
	return {"driver": FALLBACK_DRIVER, "team": FALLBACK_TEAM}


func _on_session_finished() -> void:
	car.controls_enabled = false
	rumble.stop()
	pause_menu.set_process_unhandled_input(false)
	if race != null:
		race.cross_line(car)
	if GameState.is_qualifying():
		GameState.qualifying_time = lap_timer.best_lap
		qualifying = RaceSession.qualifying(DataLoader.load_json(DataLoader.GRID_PATH),
			str(selected_driver.get("id", "")), lap_timer.best_lap, str(Settings.get_value("ai_level")),
			weather.ai_data(RaceSession.track_ai_data(DataLoader.load_json(AI_PATH), track.track_info)),
			GameState.session_seed)
	await get_tree().create_timer(results_delay, false).timeout
	car.engine_audio.set_muted(true)
	car.audio_fx.set_muted(true)
	hud.visible = false
	if race != null:
		_open_race_results()
	elif GameState.is_qualifying():
		_open_qualifying_results()
	else:
		results_screen.open(lap_timer, _session_subtitle())


## Resultado de la carrera (Paso 47; con puntos, podio, equipos y sanciones desde el Paso 52).
## La carrera se guarda en `results.save_path` para el campeonato.
func _open_race_results() -> void:
	results = RaceResults.load_default()
	results.build(race, stewards, pit_lane, car)
	var info := {"track_id": track.track_id, "track": track_name, "laps": race.laps,
		"seed": GameState.session_seed, "player_driver_id": str(selected_driver.get("id", ""))}
	results_saved = results.save(info)
	if championship != null and not championship_added:
		championship_added = championship.add_race(results.to_dict(info)) and championship.save()
	var views: Array[Dictionary] = [_driver_view(), _team_view(), _penalty_view()]
	if championship_added:
		views.append(_championship_driver_view())
		views.append(_championship_team_view())
	var podium: Array = []
	for row in results.drivers.slice(0, 3):
		podium.append({"code": row["code"], "detail": "%d pts" % row["points"], "color": row["color"]})
	var mine := results.player_row
	var summary: Array = []
	if not mine.is_empty():
		var points := int(mine["points"])
		summary.append(["P%d (largaste P%d, %s): %d %s" % [mine["pos"], mine["grid"], RaceResults.change_text(int(mine["change"])),
			points, "punto" if points == 1 else "puntos"], Color(1.0, 0.85, 0.2)])
		summary.append(["%s: %d pts" % [mine["team"], results.team_points(str(mine["team_id"]))], Color.WHITE])
	for row in results.drivers:
		if row["fastest"]:
			summary.append(["Vuelta rápida: %s %s" % [row["code"], LapTimer.format_time(float(row["best_lap"]))],
				ResultsScreen.COLOR_BEST])
			break
	if lap_timer.penalty > 0.0:
		summary.append(["Tus sanciones: +%.0f s" % lap_timer.penalty, Color(1.0, 0.35, 0.3)])
	var next_text := ""
	if championship_added:
		var standing := championship.player_standing()
		summary.append(["Campeonato: P%d con %d pts (fecha %d/%d)" % [int(standing.get("pos", 0)),
			int(standing.get("points", 0)), championship.round_index(), championship.round_count()], Color(1.0, 0.85, 0.2)])
		next_text = "Final de temporada" if championship.is_finished() \
			else "Siguiente: %s" % str(championship.current_round()["name"]).trim_prefix("Gran Premio de ")
	elif championship != null:
		summary.append(["No se pudo guardar el campeonato", Color(1.0, 0.35, 0.3)])
	summary.append(["≈ estimado (seguía en pista) · ←/→ tabla", ResultsScreen.COLOR_HEADER])
	if replay != null and replay.can_open():
		results_screen.enable_replay()
	results_screen.open_race("Carrera — Resultado", _session_subtitle(), views, podium, summary, next_text,
		championship == null)


## Paso 55: tabla de pilotos del campeonato (puesto en cada fecha; ± contra la fecha anterior).
func _championship_driver_view() -> Dictionary:
	var done := championship.round_index()
	var before: Dictionary = {}
	if done > 1:
		for standing in championship.driver_standings(done - 1):
			before[standing["driver_id"]] = int(standing["pos"])
	var colors := _team_colors()
	var headers: Array = ["P", "±", "Piloto", "Equipo"]
	var widths: Array = [28, 30, 200, 130]
	for info in championship.calendar:
		headers.append(info["short"])
		widths.append(44)
	headers.append("Pts")
	widths.append(44)
	var rows: Array = []
	for standing in championship.driver_standings():
		var change := int(before.get(standing["driver_id"], standing["pos"])) - int(standing["pos"])
		var cells: Array = [str(standing["pos"]), RaceResults.change_text(change) if done > 1 else "",
			standing["driver"], standing["team"]]
		var results_list: Array = standing["results"]
		for r in championship.round_count():
			var pos := int(results_list[r]) if r < results_list.size() else 0
			cells.append(str(pos) if pos > 0 else ("—" if r < done else ""))
		cells.append(str(standing["points"]))
		rows.append({"cells": cells, "color": Color(1.0, 0.85, 0.2) if standing["player"] else Color.WHITE,
			"highlight": standing["player"],
			"cell_colors": {1: ResultsScreen.change_color(change), 3: colors.get(standing["team_id"], Color.WHITE)}})
	return {"name": "Campeonato", "left": 4, "headers": headers, "widths": widths, "rows": rows}


## Paso 55: tabla de equipos del campeonato (puntos de cada fecha).
func _championship_team_view() -> Dictionary:
	var colors := _team_colors()
	var my_team := str(selected_team.get("id", ""))
	var headers: Array = ["P", "Equipo"]
	var widths: Array = [28, 220]
	for info in championship.calendar:
		headers.append(info["short"])
		widths.append(60)
	headers.append("Pts")
	widths.append(60)
	var rows: Array = []
	for standing in championship.team_standings():
		var cells: Array = [str(standing["pos"]), standing["team"]]
		var results_list: Array = standing["results"]
		for r in championship.round_count():
			cells.append(str(results_list[r]) if r < results_list.size() else "")
		cells.append(str(standing["points"]))
		var mine: bool = standing["team_id"] == my_team
		rows.append({"cells": cells, "color": Color(1.0, 0.85, 0.2) if mine else Color.WHITE, "highlight": mine,
			"cell_colors": {1: (colors.get(standing["team_id"], Color.WHITE) as Color).lightened(0.2)}})
	return {"name": "Constructores", "left": 2, "headers": headers, "widths": widths, "rows": rows}


## Paso 55: final de la temporada (después de la última carrera): campeón, podio y tablas.
func _open_season_final() -> void:
	var drivers := championship.driver_standings()
	var teams := championship.team_standings()
	if drivers.is_empty():
		return
	var colors := _team_colors()
	var podium: Array = []
	for standing in drivers.slice(0, 3):
		podium.append({"code": standing["code"], "detail": "%d pts" % standing["points"],
			"color": colors.get(standing["team_id"], Color.WHITE)})
	var champion: Dictionary = drivers[0]
	var summary: Array = [
		["Campeón: %s (%s), %d pts y %d %s" % [champion["driver"], champion["team"], champion["points"],
			champion["wins"], "victoria" if int(champion["wins"]) == 1 else "victorias"], Color(1.0, 0.85, 0.2)],
		["Campeón de equipos: %s, %d pts" % [teams[0]["team"], teams[0]["points"]], Color.WHITE],
	]
	var mine := championship.player_standing()
	if not mine.is_empty():
		summary.append(["Terminaste P%d con %d pts" % [mine["pos"], mine["points"]],
			Color(1.0, 0.85, 0.2) if int(mine["pos"]) == 1 else Color.WHITE])
	summary.append(["%d fechas a %d vueltas · ←/→ tabla" % [championship.round_count(), championship.laps],
		ResultsScreen.COLOR_HEADER])
	results_screen.enable_replay(false)
	results_screen.open_race("%s — Campeón" % championship.season_name,
		"#%s %s  ·  %s" % [UiKit.number_text(selected_driver.get("number", "")), str(selected_driver.get("name", "")),
			" · ".join(championship.calendar.map(func(r: Dictionary) -> String: return str(r["name"]).trim_prefix("Gran Premio de ")))],
		[_championship_driver_view(), _championship_team_view()], podium, summary, "", false)


func _team_colors() -> Dictionary:
	var colors: Dictionary = {}
	for team in DataLoader.load_json(DataLoader.GRID_PATH).get("teams", []):
		colors[str(team.get("id", ""))] = DataLoader.team_primary(team)
	return colors


func _driver_view() -> Dictionary:
	var rows: Array = []
	for row in results.drivers:
		var tyres: Array[String] = []
		for id in row["compounds"]:
			tyres.append(strategy.short_name(str(id)))
		var change := int(row["change"])
		var color := Color(1.0, 0.85, 0.2) if row["player"] else (ResultsScreen.COLOR_BEST if row["fastest"] else Color.WHITE)
		var best := float(row["best_lap"])
		rows.append({"cells": [str(row["pos"]), RaceResults.change_text(change),
			"%s  #%s" % [row["driver"], UiKit.number_text(row["number"])], row["team"], str(row["laps"]),
			"-".join(tyres), str(row["stops"]), row["gap_text"],
			"+%d s" % roundi(float(row["penalty"])) if float(row["penalty"]) > 0.0 else "",
			LapTimer.format_time(best) if best > 0.0 else "--", str(row["points"]) if int(row["points"]) > 0 else ""],
			"color": color, "highlight": row["player"],
			"cell_colors": {1: ResultsScreen.change_color(change), 8: Color(1.0, 0.4, 0.35)}})
	return {"name": "Pilotos", "left": 4,
		"headers": ["P", "±", "Piloto", "Equipo", "V", "Neum.", "Par.", "Tiempo", "Pen.", "Mejor", "Pts"],
		"widths": [28, 30, 196, 104, 22, 52, 34, 112, 46, 80, 34], "rows": rows}


func _team_view() -> Dictionary:
	var rows: Array = []
	var my_team := str(selected_team.get("id", ""))
	for team in results.teams:
		var members: Array[String] = []
		for member in team["members"]:
			members.append("%s P%d (%d)" % [member["code"], member["pos"], member["points"]])
		var mine: bool = team["team_id"] == my_team
		rows.append({"cells": [str(team["pos"]), team["team"], "   ·   ".join(members), str(team["points"])],
			"color": Color(1.0, 0.85, 0.2) if mine else Color.WHITE, "highlight": mine,
			"cell_colors": {1: (team["color"] as Color).lightened(0.2)}})
	return {"name": "Equipos", "left": 3, "headers": ["P", "Equipo", "Pilotos (puesto y puntos)", "Pts"],
		"widths": [28, 200, 520, 60], "rows": rows}


func _penalty_view() -> Dictionary:
	var rows: Array = []
	for item in results.penalties:
		var penalty: bool = item["action"] == "penalty"
		rows.append({"cells": [_clock_text(float(item["time"])), "%s (%s)" % [item["driver"], item["code"]],
			item["label"], item["text"]],
			"color": Color(1.0, 0.85, 0.2) if item["car"] == car else (Color.WHITE if penalty else ResultsScreen.COLOR_HEADER),
			"highlight": item["car"] == car})
	if rows.is_empty():
		rows.append({"cells": ["", "Sin sanciones ni advertencias", "", ""], "color": ResultsScreen.COLOR_HEADER})
	return {"name": "Sanciones", "left": 4, "headers": ["Min.", "Piloto", "Sanción", "Motivo"],
		"widths": [60, 230, 140, 420], "rows": rows}


static func _clock_text(seconds: float) -> String:
	return "%d:%02d" % [floori(seconds / 60.0), floori(fmod(seconds, 60.0))]


## Resultado de la clasificación (Paso 47): la grilla con tu mejor vuelta válida y los tiempos
## estimados de la IA; "Correr la carrera" larga con esa grilla.
func _open_qualifying_results() -> void:
	var rows: Array = []
	var pole := float(qualifying[0]["time"])
	var mine := 0
	for p in qualifying.size():
		var info: Dictionary = qualifying[p]
		var time := float(info["time"])
		if info["player"]:
			mine = p + 1
		rows.append({"cells": [str(p + 1), "%s  #%s" % [str(info["driver"].get("name", "")), UiKit.number_text(info["driver"].get("number", ""))],
			str(info["team"].get("name", "")), LapTimer.format_time(time),
			"" if p == 0 or time < 0.0 else "+%.3f" % (time - pole)],
			"color": Color(1.0, 0.85, 0.2) if info["player"] else Color.WHITE, "highlight": info["player"]})
	var summary: Array = [
		["Pole: %s" % str(qualifying[0]["driver"].get("name", "")), Color.WHITE],
		["Largás P%d" % mine if lap_timer.best_lap > 0.0 else "Sin vuelta válida: largás último", Color(1.0, 0.85, 0.2)],
		["Los tiempos de la IA se estiman por el ritmo de cada piloto (nivel %s)" % AiDriver.level_name(
			str(Settings.get_value("ai_level")), DataLoader.load_json(AI_PATH).get("levels", {})), ResultsScreen.COLOR_HEADER],
	]
	results_screen.open_standings("Clasificación — Resultado", _session_subtitle(),
		["P", "Piloto", "Equipo", "Tiempo", "Dif."], [34, 280, 150, 130, 110], rows, summary, "Correr la carrera")


func _session_subtitle() -> String:
	return "#%s %s  ·  %s  ·  %s" % [UiKit.number_text(selected_driver.get("number", "")),
		str(selected_driver.get("name", "")), track_name, mode_name]


func _on_paused_changed(paused: bool) -> void:
	car.engine_audio.set_muted(paused)
	car.audio_fx.set_muted(paused)
	hud.visible = not paused
	if paused:
		rumble.stop()
		pause_menu.set_subtitle(_pause_subtitle())


## Setup cambiado desde la pausa (sólo práctica): el auto vuelve a boxes con el setup nuevo
## (los neumáticos y el combustible siguen como estaban).
func _on_setup_changed() -> void:
	car.apply_setup(car_setup)
	car.reset_to_spawn()
	hud.refresh_speed_range()
	racing_line.refresh_speeds()
	hud.show_message("Setup aplicado: el auto vuelve a boxes", 3.0)


func _on_setting_changed(key: String) -> void:
	Settings.apply_to_car(car, false)
	rumble.intensity = float(Settings.get_value("vibration")) / 100.0
	racing_line.set_mode(str(Settings.get_value("racing_line")))
	ghost.enabled = bool(Settings.get_value("ghost"))
	if (key == "ai_level" or key.is_empty()) and not ai_drivers.is_empty() and race == null:
		var levels = DataLoader.load_json(AI_PATH).get("levels", {})
		for driver in ai_drivers:
			driver.set_level(str(Settings.get_value("ai_level")), levels)
	if key == "time_of_day" or key.is_empty():
		_apply_lighting()
	else:
		LightingRig.apply_quality($WorldEnvironment.environment, $Sun, Settings.quality())


## Paso 23: preset de luz según la opción "Hora" y sombras / reflejos según la calidad.
## Paso 54: el "ground_color" de los presets es el de Bakú; una pista con "ground" propio lo conserva.
func _apply_lighting() -> void:
	var preset := LightingRig.get_preset(str(Settings.get_value("time_of_day")))
	if track.track_info.has("ground"):
		preset = preset.duplicate()
		preset.erase("ground_color")
	LightingRig.apply($WorldEnvironment.environment, $Sun, weather.light_preset(preset), Settings.quality(),
		track.get_sea(), track.get_ground_visual())
	track.set_wetness(weather.wetness, weather.road)


## Paso 56: lluvia alrededor de la cámara y rocío detrás de cada auto (cantidad según la calidad).
## Sin pantalla (pruebas con --headless) no hay partículas: nadie las ve.
func _setup_weather_fx() -> void:
	if weather.is_dry() or DisplayServer.get_name() == "headless":
		return
	var amount := float(Settings.quality().get("rain_particles", 1.0))
	if weather.rain > 0.0:
		rain_fx = RainFx.new()
		rain_fx.name = "RainFx"
		add_child(rain_fx)
		rain_fx.configure(weather.rain_fx, weather.rain * amount)
	for who: CarController in [car] + ai_cars:
		var spray := CarSpray.new()
		spray.name = "Spray"
		who.add_child(spray)
		spray.configure(weather.spray, weather.wetness, amount)
		spray.bind_car(who)
		sprays.append(spray)


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


func _ensure_input_actions() -> void:
	for action in DEFAULT_KEYS:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		if InputMap.action_get_events(action).is_empty():
			for key in DEFAULT_KEYS[action]:
				var event := InputEventKey.new()
				event.physical_keycode = key
				InputMap.action_add_event(action, event)
