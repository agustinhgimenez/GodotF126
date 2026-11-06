class_name TelemetryLap
extends RefCounted
## Una vuelta de telemetría (Paso 39): un arreglo empaquetado por canal, una muestra cada
## `TelemetryRecorder.interval` s. La distancia es desde la meta (negativa antes de cruzarla
## en una largada detenida).

const CHANNELS := ["time", "distance", "speed", "rpm", "gear", "throttle", "brake", "steer", "x", "y", "z", "yaw"]
## Decimales al guardar cada canal en JSON.
const DECIMALS := {"time": 3, "distance": 2, "speed": 2, "rpm": 0, "gear": 0, "throttle": 3, "brake": 3,
	"steer": 3, "x": 2, "y": 2, "z": 2, "yaw": 3}
## Canales agregados en el Paso 43 (auto fantasma): un archivo anterior sin ellos se carga igual
## y quedan en `missing_channels` para que TelemetryRecorder los reconstruya con la pista.
const OPTIONAL_CHANNELS := ["y", "yaw"]

var lap: int = 0
var lap_time: float = -1.0
var invalid: bool = false
var compound: String = ""
var track_length: float = 0.0
## canal → PackedFloat32Array (km/h, rpm, marcha −1 / 0 / 1–8, pedales 0–1, dirección −1 izq. a 1 der.,
## posición en m, rumbo en rad = `global_rotation.y` del auto).
var channels: Dictionary = {}
## Canales opcionales que faltaban en el archivo (rellenos con ceros hasta reconstruirlos).
var missing_channels := PackedStringArray()


func _init() -> void:
	for channel in CHANNELS:
		channels[channel] = PackedFloat32Array()


func size() -> int:
	return (channels["time"] as PackedFloat32Array).size()


func is_complete() -> bool:
	return lap_time > 0.0


func add_sample(values: Dictionary) -> void:
	for channel in CHANNELS:
		var array: PackedFloat32Array = channels[channel]
		array.append(float(values.get(channel, 0.0)))
		channels[channel] = array


func channel(name: String) -> PackedFloat32Array:
	return channels.get(name, PackedFloat32Array())


func value(name: String, index: int) -> float:
	return channel(name)[index]


## Valor de un canal a `distance` m de la meta (interpolado entre las dos muestras vecinas).
func value_at_distance(name: String, distance: float) -> float:
	return value_at("distance", distance, name)


## Muestras vecinas de `key` en un canal creciente (tiempo o distancia): (índice bajo, índice
## alto, fracción). Fuera de rango, la primera o la última muestra.
func locate(key_channel: String, key: float) -> Vector3:
	var d := channel(key_channel)
	var n := d.size()
	if n == 0:
		return Vector3(-1, -1, 0)
	if key <= d[0]:
		return Vector3(0, 0, 0)
	if key >= d[n - 1]:
		return Vector3(n - 1, n - 1, 0)
	var low := 0
	var high := n - 1
	while high - low > 1:
		var mid := (low + high) / 2
		if d[mid] <= key:
			low = mid
		else:
			high = mid
	var span := d[high] - d[low]
	return Vector3(low, high, (key - d[low]) / span if span > 0.0 else 0.0)


## Valor de `name` donde el canal `key_channel` vale `key` (interpolado).
func value_at(key_channel: String, key: float, name: String) -> float:
	var at := locate(key_channel, key)
	if at.x < 0:
		return 0.0
	var values := channel(name)
	return lerpf(values[int(at.x)], values[int(at.y)], at.z)


## Igual que `value_at` para un ángulo en rad (interpola por el lado corto).
func angle_at(key_channel: String, key: float, name: String) -> float:
	var at := locate(key_channel, key)
	if at.x < 0:
		return 0.0
	var values := channel(name)
	return lerp_angle(values[int(at.x)], values[int(at.y)], at.z)


## Resumen: velocidad máxima / mínima / media, % del tiempo a fondo y frenando, cambios de
## marcha, RPM máximas, metros y muestras.
func summary(full_throttle: float = 0.98, braking: float = 0.05) -> Dictionary:
	var n := size()
	var result := {"samples": n, "max_speed": 0.0, "min_speed": 0.0, "avg_speed": 0.0, "full_throttle": 0.0,
		"braking": 0.0, "gear_changes": 0, "max_rpm": 0.0, "distance": 0.0}
	if n == 0:
		return result
	var speed := channel("speed")
	var throttle := channel("throttle")
	var brake := channel("brake")
	var gear := channel("gear")
	var rpm := channel("rpm")
	var time := channel("time")
	var distance := channel("distance")
	var max_speed := 0.0
	var min_speed := INF
	var full_time := 0.0
	var brake_time := 0.0
	var changes := 0
	var max_rpm := 0.0
	for i in n:
		max_speed = maxf(max_speed, speed[i])
		min_speed = minf(min_speed, speed[i])
		max_rpm = maxf(max_rpm, rpm[i])
		if i > 0:
			var dt := time[i] - time[i - 1]
			if throttle[i - 1] >= full_throttle:
				full_time += dt
			if brake[i - 1] >= braking:
				brake_time += dt
			if gear[i] != gear[i - 1]:
				changes += 1
	var duration := time[n - 1] - time[0]
	var metres := distance[n - 1] - distance[0]
	result["max_speed"] = max_speed
	result["min_speed"] = min_speed
	result["avg_speed"] = metres / duration * 3.6 if duration > 0.0 else 0.0
	result["full_throttle"] = full_time / duration if duration > 0.0 else 0.0
	result["braking"] = brake_time / duration if duration > 0.0 else 0.0
	result["gear_changes"] = changes
	result["max_rpm"] = max_rpm
	result["distance"] = metres
	return result


func to_dict() -> Dictionary:
	var data := {"lap": lap, "time": lap_time, "invalid": invalid, "compound": compound,
		"track_length": track_length, "channels": {}}
	for name in CHANNELS:
		var step := pow(10.0, -int(DECIMALS.get(name, 3)))
		var list := []
		for v in channel(name):
			list.append(snappedf(v, step))
		data["channels"][name] = list
	return data


## null si los datos no sirven (faltan canales obligatorios o largos distintos). Los opcionales
## que falten quedan en cero y en `missing_channels`.
static func from_dict(data: Dictionary) -> TelemetryLap:
	var result := TelemetryLap.new()
	result.lap = int(data.get("lap", 0))
	result.lap_time = float(data.get("time", -1.0))
	result.invalid = bool(data.get("invalid", false))
	result.compound = str(data.get("compound", ""))
	result.track_length = float(data.get("track_length", 0.0))
	var source = data.get("channels", {})
	if not source is Dictionary:
		return null
	var count := -1
	for name in CHANNELS:
		var list = source.get(name, null)
		if not list is Array:
			if name in OPTIONAL_CHANNELS:
				result.missing_channels.append(name)
				continue
			return null
		if count >= 0 and list.size() != count:
			return null
		count = list.size()
		result.channels[name] = PackedFloat32Array(list)
	for name in result.missing_channels:
		var zeros := PackedFloat32Array()
		zeros.resize(count)
		result.channels[name] = zeros
	return result
