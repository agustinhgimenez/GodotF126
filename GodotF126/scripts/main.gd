extends Node3D
## Escena principal: carga datos (grilla, pistas, auto, setup), spawnea el auto en Bakú y arma el HUD.
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
	"aero_mode": [KEY_F],
	"overtake": [KEY_G],
	"brake_bias_rearward": [KEY_Z],
	"brake_bias_forward": [KEY_X],
	"traction_control": [KEY_T],
	"ers_mode": [KEY_V],
	"racing_line": [KEY_L],
	"ghost": [KEY_H],
	"ai_rival": [KEY_I],
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
## Clasificación de la sesión (Paso 47): {driver, team, time, pace, player} de la pole al último.
var qualifying: Array[Dictionary] = []
var _car_data: Dictionary = {}
var _laps: int = 0
var _standing_start: bool = false
var _start_data: Dictionary = {}

@onready var track: BakuTrack = $BakuTrack
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
	var tracks := DataLoader.load_json(DataLoader.TRACKS_PATH)
	var driver_id := GameState.selected_driver_id
	if driver_id.is_empty():
		driver_id = str(grid.get("default_driver_id", "colapinto"))
	_select_driver(grid, driver_id)
	var track_info := _find_track(tracks, TRACK_ID)

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

	lap_timer.setup(str(track_info.get("records_key", TRACK_ID)))
	_setup_mode()
	var zones_data = track_info.get("aero_zones", {})
	if zones_data is Dictionary:
		aero_zones.configure(zones_data)
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
	telemetry.setup(track, car, lap_timer, track_limits, str(track_info.get("records_key", TRACK_ID)))
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
	car.steering_wheel.bind_lap_timer(lap_timer)
	car.steering_wheel.bind_delta(live_delta)
	if GameState.is_race() or GameState.is_qualifying():
		_setup_qualifying()
	if GameState.is_race():
		_setup_race()
	if _standing_start:
		_setup_start_lights()

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
	results_screen.next_requested.connect(_go_to_race)
	lap_timer.session_finished.connect(_on_session_finished)
	Settings.changed.connect(_on_setting_changed)
	var rumble_data = InputBindings.data().get("rumble", {})
	if rumble_data is Dictionary:
		rumble.configure(rumble_data)
	rumble.intensity = float(Settings.get_value("vibration")) / 100.0
	rumble.bind_car(car)
	# El auto ya está en su lugar (grilla o largada): elegir la torre de TV desde ahí.
	tv_cameras.set_active(car.uses_external_camera())


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
	start_lights.begin(car, track.get_start_line_transform(), BakuTrack.GANTRY_HEIGHT)


func _on_lights_out() -> void:
	if start_lights.jumped:
		lap_timer.add_penalty(float(_start_data.get("jump_penalty", 5.0)), "Largada en falso")
		if race != null:
			race.entry_of(car)["extra_penalty"] = float(_start_data.get("jump_penalty", 5.0))
	lap_timer.start_now()
	if race != null:
		race.start(GameState.session_seed)


## Clasificación de la sesión (Paso 47): la IA con tiempos estimados por ritmo (semilla de la
## sesión) y el jugador con su vuelta de la clasificación o, si no corrió, con su récord.
func _setup_qualifying() -> void:
	if GameState.session_seed == 0:
		GameState.session_seed = randi() % 1000000 + 1
	var player_time := GameState.qualifying_time
	if GameState.is_race() and player_time < 0.0:
		player_time = lap_timer.record_lap
	var ai_data := DataLoader.load_json(AI_PATH)
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
	var mine := race.entry_of(car)
	hud.show_message("Largás P%d (%s)" % [int(mine["grid"]) + 1,
		"clasificación %s" % LapTimer.format_time(float(mine["quali"])) if float(mine["quali"]) > 0.0 else "sin tiempo"], 4.0)


## Botón "Correr la carrera" del resultado de la clasificación.
func _go_to_race() -> void:
	var modes := DataLoader.load_json(DataLoader.MODES_PATH)
	GameState.selected_mode = GameState.MODE_RACE
	GameState.lap_count = int(DataLoader.find_mode(modes, GameState.MODE_RACE).get("default_laps", 3))
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
	ai_car.fit_tyres(str(car_info.get("compound", "medium")))
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
			DataLoader.load_json(AI_PATH), GameState.session_seed)
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


## Resultado de la carrera (Paso 47): posición, piloto, equipo, vueltas, tiempo o distancia
## al ganador, penalización y mejor vuelta. La pantalla completa es del Paso 52.
func _open_race_results() -> void:
	var rows: Array = []
	var list := race.classification()
	var winner: Dictionary = list[0]
	var fastest := -1.0
	for row in list:
		var best := float(row["entry"]["best_lap"])
		if best > 0.0 and (fastest < 0.0 or best < fastest):
			fastest = best
	var mine := 0
	for p in list.size():
		var row: Dictionary = list[p]
		var entry: Dictionary = row["entry"]
		var time_text := LapTimer.format_time(float(row["total"]))
		if p > 0:
			var down := int(winner["laps"]) - int(row["laps"])
			time_text = "+%d %s" % [down, "vuelta" if down == 1 else "vueltas"] if down > 0 \
				else "+%.3f" % (float(row["total"]) - float(winner["total"]))
		if row["estimated"]:
			time_text = "≈ " + time_text
		var best := float(entry["best_lap"])
		var is_player: bool = entry["car"] == car
		if is_player:
			mine = p + 1
		rows.append({"cells": [str(p + 1), "%s  #%s" % [str(entry["driver"].get("name", "")), UiKit.number_text(entry["driver"].get("number", ""))],
			str(entry["team"].get("name", "")), str(row["laps"]), time_text,
			"+%d s" % roundi(float(row["penalty"])) if float(row["penalty"]) > 0.0 else "",
			LapTimer.format_time(best) if best > 0.0 else "--"],
			"color": Color(1.0, 0.85, 0.2) if is_player else (ResultsScreen.COLOR_BEST if best > 0.0 and is_equal_approx(best, fastest) else Color.WHITE),
			"highlight": is_player})
	var summary: Array = [
		["Ganador: %s" % str(winner["entry"]["driver"].get("name", "")), Color.WHITE],
		["Terminaste P%d (largaste P%d)" % [mine, int(race.entry_of(car)["grid"]) + 1], Color(1.0, 0.85, 0.2)],
		["Vuelta más rápida (violeta): %s" % LapTimer.format_time(fastest), ResultsScreen.COLOR_BEST],
	]
	if lap_timer.penalty > 0.0:
		summary.append(["Tus penalizaciones: +%.0f s (%s)" % [lap_timer.penalty, lap_timer.penalty_reason], Color(1.0, 0.35, 0.3)])
	summary.append(["≈ = estimado: seguía en pista al terminar vos", ResultsScreen.COLOR_HEADER])
	results_screen.open_standings("Carrera — Resultado", _session_subtitle(),
		["P", "Piloto", "Equipo", "V", "Tiempo", "Pen.", "Mejor vuelta"],
		[34, 250, 130, 30, 130, 56, 120], rows, summary)


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
func _apply_lighting() -> void:
	LightingRig.apply($WorldEnvironment.environment, $Sun,
		LightingRig.get_preset(str(Settings.get_value("time_of_day"))), Settings.quality(),
		track.get_sea(), track.get_ground_visual())


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
