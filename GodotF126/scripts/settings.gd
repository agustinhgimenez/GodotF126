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
const QUALITY_LEVELS := ["low", "medium", "high"]
const TIMES_OF_DAY := ["sunset", "day"]
const MSAA_MODES := {0: Viewport.MSAA_DISABLED, 2: Viewport.MSAA_2X, 4: Viewport.MSAA_4X, 8: Viewport.MSAA_8X}

var values: Dictionary = {}
var _data: Dictionary = {}


func _ready() -> void:
	_data = DataLoader.load_json(DATA_PATH)
	_ensure_buses()
	load_settings()
	apply_global()


func get_value(key: String):
	return values.get(key, get_default(key))


func get_default(key: String):
	return _data.get("defaults", {}).get(key)


func set_value(key: String, value) -> void:
	values[key] = _sanitize(key, value)
	apply_global()
	save_settings()
	changed.emit(key)


## No vuelve a mostrar el tutorial: tutorial_seen no es una opción del jugador.
func reset_to_defaults() -> void:
	var seen = get_value("tutorial_seen")
	values = _data.get("defaults", {}).duplicate()
	values["tutorial_seen"] = seen
	apply_global()
	save_settings()
	changed.emit("")


func load_settings() -> void:
	values = _data.get("defaults", {}).duplicate()
	if not FileAccess.file_exists(USER_PATH):
		return
	var saved = JSON.parse_string(FileAccess.get_file_as_string(USER_PATH))
	if not saved is Dictionary:
		push_warning("user://settings.json inválido; uso los valores por defecto.")
		return
	for key in values.keys():
		if saved.has(key):
			values[key] = _sanitize(key, saved[key])


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


## Caja, dirección, cámara inicial y espejos del auto de carrera.
## Con `include_camera` en false (opciones desde la pausa) se respeta la cámara actual.
func apply_to_car(car: CarController, include_camera: bool = true) -> void:
	car.gearbox.manual = str(get_value("gearbox")) == "manual"
	var steering: Dictionary = _data.get("steering", {})
	var profile = steering.get("assisted" if bool(get_value("steering_assist")) else "direct", {})
	if profile is Dictionary:
		car.steer_response = float(profile.get("steer_response", car.steer_response))
		car.steer_limit = float(profile.get("steer_limit", car.steer_limit))
	if include_camera:
		car.set_camera_mode(int(get_value("camera")))
	car.cockpit_detail.set_resolution_scale(float(quality().get("mirror_scale", 1.0)))


func _sanitize(key: String, value):
	var fallback = get_default(key)
	match key:
		"gearbox":
			return value if str(value) in GEARBOX_MODES else fallback
		"quality":
			return value if str(value) in QUALITY_LEVELS else fallback
		"time_of_day":
			return value if str(value) in TIMES_OF_DAY else fallback
		"camera":
			if not (value is int or value is float):
				return int(fallback)
			return clampi(int(value), 0, CarController.CAMERA_MODES.size() - 1)
		"steering_assist", "fullscreen", "tutorial_seen":
			return value if value is bool else fallback
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
