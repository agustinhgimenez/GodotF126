class_name Weather
extends RefCounted
## Clima de la sesión (Paso 56), datos en data/weather.json: seco, húmedo o lluvia.
## - Agua en la pista (`wetness`): los neumáticos mezclan su agarre seco con el mojado y se
##   enfrían más (TyreCompounds); desde `rain_threshold` la estrategia usa los compuestos de
##   lluvia y no exige dos.
## - La IA larga con el compuesto de la condición; su vuelta estimada para la clasificación se
##   multiplica por `lap_factor`.
## - Luz más gris (sobre el preset de la hora), asfalto oscuro y brillante, lluvia y rocío.
## Seco no cambia nada.

const DATA_PATH := "res://data/weather.json"

var id: String = "dry"
var condition: Dictionary = {}
var wetness: float = 0.0
## Intensidad de la lluvia que se ve (0–1).
var rain: float = 0.0
var rain_threshold: float = 0.5
var wet_cooling: float = 1.5
var rain_fx: Dictionary = {}
var spray: Dictionary = {}
var road: Dictionary = {}


## Condición `requested` (vacía o desconocida: la "default").
static func load_default(requested: String = "") -> Weather:
	var weather := Weather.new()
	weather.configure(DataLoader.load_json(DATA_PATH), requested)
	return weather


static func conditions() -> Array:
	var list = DataLoader.load_json(DATA_PATH).get("conditions", [])
	return list if list is Array else []


func configure(data: Dictionary, requested: String) -> void:
	rain_threshold = float(data.get("rain_threshold", rain_threshold))
	wet_cooling = maxf(float(data.get("wet_cooling", wet_cooling)), 0.0)
	for key in ["rain_fx", "spray", "road"]:
		var value = data.get(key, {})
		set(key, value if value is Dictionary else {})
	var list = data.get("conditions", [])
	var wanted := requested if not requested.is_empty() else str(data.get("default", "dry"))
	condition = {}
	if list is Array:
		for item in list:
			if item is Dictionary and str(item.get("id", "")) == wanted:
				condition = item
		if condition.is_empty() and not list.is_empty() and list[0] is Dictionary:
			condition = list[0]
	id = str(condition.get("id", "dry"))
	wetness = clampf(float(condition.get("wetness", 0.0)), 0.0, 1.0)
	rain = clampf(float(condition.get("rain", 0.0)), 0.0, 1.0)


func is_dry() -> bool:
	return wetness <= 0.0


func display_name() -> String:
	return str(condition.get("name", id))


## Para los subtítulos ("pista mojada"); sin "label", el nombre en minúsculas.
func label() -> String:
	return str(condition.get("label", display_name().to_lower()))


func needs_rain_tyres() -> bool:
	return wetness >= rain_threshold


## El agua y la temperatura de la pista en los neumáticos del auto.
func apply_to_car(car: CarController) -> void:
	car.tyres.wetness = wetness
	car.tyres.wet_cooling = wet_cooling
	if condition.has("track_temp"):
		car.tyres.track_temp = float(condition["track_temp"])


func apply_to_strategy(strategy: RaceStrategy) -> void:
	strategy.set_weather(wetness, rain_threshold)


## Compuesto para la IA (y el sugerido en el menú): el de la condición o `fallback`.
func compound(fallback: String) -> String:
	return str(condition.get("compound", fallback))


## Cuánto más lenta es una vuelta que en seco.
func lap_factor() -> float:
	return float(condition.get("lap_factor", 1.0))


## Los tiempos de vuelta de cada nivel (para la clasificación estimada) con `lap_factor`.
func ai_data(data: Dictionary) -> Dictionary:
	var factor := lap_factor()
	if is_equal_approx(factor, 1.0):
		return data
	var result := data.duplicate(true)
	var levels = result.get("levels", {})
	if levels is Dictionary:
		for level in levels.values():
			if level is Dictionary and level.has("lap_time"):
				level["lap_time"] = float(level["lap_time"]) * factor
	return result


## El preset de luz de la hora con los cambios de la condición ("light").
func light_preset(preset: Dictionary) -> Dictionary:
	var light = condition.get("light", {})
	if not light is Dictionary or light.is_empty():
		return preset
	var result := preset.duplicate(true)
	var sun: Dictionary = result.get("sun", {})
	sun["energy"] = float(sun.get("energy", 1.0)) * float(light.get("sun_scale", 1.0))
	result["sun"] = sun
	var ambient: Dictionary = result.get("ambient", {})
	ambient["energy"] = float(ambient.get("energy", 1.0)) * float(light.get("ambient_scale", 1.0))
	result["ambient"] = ambient
	for key in ["sky", "fog"]:
		var changes = light.get(key, {})
		if changes is Dictionary:
			var part: Dictionary = result.get(key, {})
			part.merge(changes, true)
			result[key] = part
	return result
