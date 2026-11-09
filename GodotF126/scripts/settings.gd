extends Node
## Opciones del jugador (autoload "Settings", Paso 14).
## Valores por defecto en data/settings.json; lo que el jugador cambia se guarda en
## user://settings.json. Crea los buses de audio Engine / Fx / Music (hijos de Master)
## para poder ajustar cada volumen por separado.

signal changed(key: String)

const USER_PATH := "user://settings.json"
const DATA_PATH := "res://data/settings.json"
const BUS_ENGINE := "Engine"
const BUS_FX := "Fx"
const BUS_MUSIC := "Music"
const VOLUME_BUSES := {
	"master_volume": "Master",
	"engine_volume": BUS_ENGINE,
	"fx_volume": BUS_FX,
	"music_volume": BUS_MUSIC,
}
const GEARBOX_MODES := ["manual", "automatic"]
const ACTIVE_AERO_MODES := ["automatic", "manual"]
const QUALITY_LEVELS := ["low", "medium", "high"]
const TIMES_OF_DAY := ["sunset", "day"]
## Niveles del control de tracción contando el apagado (los umbrales están en car.json).
const TRACTION_LEVELS := 4
const MSAA_MODES := {0: Viewport.MSAA_DISABLED, 2: Viewport.MSAA_2X, 4: Viewport.MSAA_4X, 8: Viewport.MSAA_8X}
## Controles (Paso 37): asignaciones, pedales ("half" gatillos 0–1, "full" pedales de volante
## de −1 a 1), zona muerta de la dirección (%), curva de la dirección y vibración (%).
## Restablecer de Opciones no las toca (reset_input() sí).
const INPUT_KEYS := ["bindings", "pedal_range", "steer_deadzone", "steer_curve", "vibration"]
const PEDAL_RANGES := ["half", "full"]
const STEER_CURVES := [1.0, 1.5, 2.0]

var values: Dictionary = {}
var _data: Dictionary = {}


func _ready() -> void:
	_data = DataLoader.load_json(DATA_PATH)
	_ensure_buses()
	load_settings()
	apply_global()
	apply_input()


func get_value(key: String):
	return values.get(key, get_default(key))


func get_default(key: String):
	return _data.get("defaults", {}).get(key)


func set_value(key: String, value) -> void:
	values[key] = _sanitize(key, value)
	apply_global()
	if key in INPUT_KEYS:
		apply_input()
	save_settings()
	changed.emit(key)


## No vuelve a mostrar el tutorial (tutorial_seen no es una opción del jugador) ni toca los
## controles.
func reset_to_defaults() -> void:
	var kept := {"tutorial_seen": get_value("tutorial_seen"), "player_name": get_value("player_name")}
	for key in INPUT_KEYS:
		kept[key] = get_value(key)
	values = _defaults()
	values.merge(kept, true)
	apply_global()
	save_settings()
	changed.emit("")


## Controles por defecto (Paso 37).
func reset_input() -> void:
	var defaults := _defaults()
	for key in INPUT_KEYS:
		values[key] = defaults.get(key)
	apply_input()
	save_settings()
	changed.emit("")


## Arma el InputMap con las asignaciones del jugador (InputBindings).
func apply_input() -> void:
	InputBindings.apply(get_value("bindings"), float(get_value("steer_deadzone")) / 100.0)


## Valores por defecto ya saneados (el JSON trae los enteros como float).
func _defaults() -> Dictionary:
	var result: Dictionary = _data.get("defaults", {}).duplicate()
	if OS.has_feature("web"):
		for key in _web_defaults():
			result[key] = _web_defaults()[key]
		result["web_tuned"] = true
	for key in result.keys():
		result[key] = _sanitize(key, result[key])
	return result


func load_settings() -> void:
	values = _defaults()
	if not FileAccess.file_exists(USER_PATH):
		return
	var saved = JSON.parse_string(FileAccess.get_file_as_string(USER_PATH))
	if not saved is Dictionary:
		push_warning("user://settings.json inválido; uso los valores por defecto.")
		return
	for key in values.keys():
		if saved.has(key):
			values[key] = _sanitize(key, saved[key])
	# Opciones guardadas en el navegador antes de que existieran los valores para la web.
	if OS.has_feature("web") and saved.get("web_tuned") != true:
		for key in _web_defaults():
			values[key] = _sanitize(key, _web_defaults()[key])
		values["web_tuned"] = true
		save_settings()


## Bloque "web_defaults" de data/settings.json sin su descripción.
func _web_defaults() -> Dictionary:
	var result: Dictionary = {}
	var web = _data.get("web_defaults", {})
	if web is Dictionary:
		for key in web:
			if key != "description" and _data.get("defaults", {}).has(key):
				result[key] = web[key]
	return result


func save_settings() -> void:
	var file := FileAccess.open(USER_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("No se pudo guardar %s" % USER_PATH)
		return
	file.store_string(JSON.stringify(values, "  "))


## Perfil de calidad actual: {"shadows": bool, "msaa": int, "mirror_scale": float}.
func quality() -> Dictionary:
	var profiles: Dictionary = _data.get("quality_profiles", {})
	var profile = profiles.get(str(get_value("quality")), {})
	return profile if profile is Dictionary else {}


func shadows_enabled() -> bool:
	return bool(quality().get("shadows", true))


## Volúmenes, pantalla completa y antialiasing (lo que no depende de la escena).
func apply_global() -> void:
	for key in VOLUME_BUSES:
		var index := AudioServer.get_bus_index(VOLUME_BUSES[key])
		if index < 0:
			continue
		var volume := float(get_value(key)) / 100.0
		AudioServer.set_bus_mute(index, volume <= 0.0)
		AudioServer.set_bus_volume_db(index, linear_to_db(maxf(volume, 0.0001)))
	var msaa := int(quality().get("msaa", 0))
	get_tree().root.msaa_3d = MSAA_MODES.get(msaa, Viewport.MSAA_DISABLED)
	var fullscreen := bool(get_value("fullscreen"))
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != mode and DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(mode)


## Caja, dirección, aero activa, ABS, control de tracción, cámara inicial y espejos del
## auto de carrera.
## Con `include_camera` en false (opciones desde la pausa) se respeta la cámara actual.
func apply_to_car(car: CarController, include_camera: bool = true) -> void:
	car.gearbox.manual = str(get_value("gearbox")) == "manual"
	car.active_aero.automatic = str(get_value("active_aero")) == "automatic"
	car.abs_enabled = bool(get_value("abs"))
	car.traction_control.set_level(int(get_value("traction_control")))
	var steering: Dictionary = _data.get("steering", {})
	var profile = steering.get("assisted" if bool(get_value("steering_assist")) else "direct", {})
	if profile is Dictionary:
		car.steer_response = float(profile.get("steer_response", car.steer_response))
		car.steer_limit = float(profile.get("steer_limit", car.steer_limit))
	car.pedal_full_range = str(get_value("pedal_range")) == "full"
	car.steer_curve = float(get_value("steer_curve"))
	if include_camera:
		car.set_camera_mode(int(get_value("camera")))
	car.cockpit_detail.set_resolution_scale(float(quality().get("mirror_scale", 1.0)))


func _sanitize(key: String, value):
	var fallback = get_default(key)
	match key:
		"gearbox":
			return value if str(value) in GEARBOX_MODES else fallback
		"active_aero":
			return value if str(value) in ACTIVE_AERO_MODES else fallback
		"quality":
			return value if str(value) in QUALITY_LEVELS else fallback
		"time_of_day":
			return value if str(value) in TIMES_OF_DAY else fallback
		"racing_line":
			return value if str(value) in RacingLine.MODES else fallback
		"ai_level":
			return value if str(value) in AiDriver.LEVELS else fallback
		"camera":
			if not (value is int or value is float):
				return int(fallback)
			return clampi(int(value), 0, CarController.CAMERA_MODES.size() - 1)
		"traction_control":
			if not (value is int or value is float):
				return int(fallback)
			return clampi(int(value), 0, TRACTION_LEVELS - 1)
		"steering_assist", "abs", "fullscreen", "tutorial_seen", "ghost", "web_tuned":
			return value if value is bool else fallback
		"bindings":
			return value.duplicate(true) if value is Dictionary else {}
		"pedal_range":
			return value if str(value) in PEDAL_RANGES else fallback
		"steer_deadzone":
			if not (value is int or value is float):
				return int(fallback)
			return clampi(int(value), 0, 30)
		"steer_curve":
			if not (value is int or value is float):
				return float(fallback)
			var nearest: float = STEER_CURVES[0]
			for curve in STEER_CURVES:
				if absf(float(value) - curve) < absf(float(value) - nearest):
					nearest = curve
			return nearest
		"vibration":
			if not (value is int or value is float):
				return int(fallback)
			return clampi(int(value), 0, 100)
		"player_name":
			return str(value).strip_edges().left(16) if value is String else fallback
	if key in VOLUME_BUSES:
		if not (value is int or value is float):
			return int(fallback)
		return clampi(int(value), 0, 100)
	return value


func _ensure_buses() -> void:
	for bus_name in [BUS_ENGINE, BUS_FX, BUS_MUSIC]:
		if AudioServer.get_bus_index(bus_name) >= 0:
			continue
		AudioServer.add_bus()
		var index := AudioServer.bus_count - 1
		AudioServer.set_bus_name(index, bus_name)
		AudioServer.set_bus_send(index, "Master")
