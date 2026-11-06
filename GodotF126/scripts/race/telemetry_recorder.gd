class_name TelemetryRecorder
extends Node
## Registro de telemetría por vuelta (Paso 39). Mientras corre el cronómetro guarda una
## muestra cada `interval` s (TelemetryLap: tiempo, distancia desde la meta, velocidad, RPM,
## marcha, acelerador, freno, dirección y posición). Al cerrar la vuelta la pasa a `laps`
## (las últimas `max_laps`), actualiza `last` y `best` (la más rápida válida de la sesión) y,
## si es más rápida que la guardada, la escribe en `best_path`. Un reinicio (R) descarta la
## vuelta en curso. Datos en data/telemetry.json.

signal lap_recorded(lap: TelemetryLap)

const DATA_PATH := "res://data/telemetry.json"

var interval: float = 0.05
var max_laps: int = 30
var best_path: String = "user://telemetry_best_{track}.json"
var save_best: bool = true
var full_throttle: float = 0.98
var braking: float = 0.05
var panel_rows: int = 8

## Vuelta que se está grabando (null si el cronómetro no corre).
var current: TelemetryLap
var laps: Array[TelemetryLap] = []
var last: TelemetryLap
var best: TelemetryLap
## La mejor vuelta guardada de esta pista (de una sesión anterior o de ésta).
var saved_best: TelemetryLap
var track_id: String = ""

var _track: BakuTrack
var _car: CarController
var _timer: LapTimer
var _limits: TrackLimits
var _cumulative := PackedFloat32Array()
var _start_index: int = 0
var _next_sample: float = 0.0


func configure(data: Dictionary) -> void:
	interval = maxf(float(data.get("interval", interval)), 0.01)
	max_laps = maxi(int(data.get("max_laps", max_laps)), 1)
	best_path = str(data.get("best_path", best_path))
	save_best = bool(data.get("save_best", save_best))
	full_throttle = clampf(float(data.get("full_throttle", full_throttle)), 0.0, 1.0)
	braking = clampf(float(data.get("braking", braking)), 0.0, 1.0)
	panel_rows = maxi(int(data.get("panel_rows", panel_rows)), 1)


func setup(track: BakuTrack, car: CarController, timer: LapTimer, limits: TrackLimits, id: String) -> void:
	_track = track
	_car = car
	_timer = timer
	_limits = limits
	track_id = id
	var n := track.centerline.size()
	_cumulative.resize(n)
	var travelled := 0.0
	for i in n:
		_cumulative[i] = travelled
		travelled += track.centerline[i].distance_to(track.centerline[(i + 1) % n])
	_start_index = track.checkpoint_indices[0] if not track.checkpoint_indices.is_empty() else track.start_index()
	timer.lap_started.connect(_on_lap_started)
	timer.lap_completed.connect(_on_lap_completed)
	timer.lap_aborted.connect(func() -> void: current = null)
	saved_best = load_best()


func track_length() -> float:
	return _track.track_length if _track != null else 0.0


## Metros desde la meta hasta el fin de cada sector intermedio (checkpoints 1, 2…).
func sector_distances() -> PackedFloat32Array:
	var result := PackedFloat32Array()
	if _track == null:
		return result
	for k in range(1, _track.checkpoint_indices.size()):
		result.append(fposmod(_cumulative[_track.checkpoint_indices[k]] - _cumulative[_start_index], track_length()))
	return result


## Vueltas para elegir en el análisis: las de la sesión y la guardada (si es de antes).
func available_laps() -> Array[TelemetryLap]:
	var result: Array[TelemetryLap] = laps.duplicate()
	if saved_best != null and not laps.has(saved_best):
		result.append(saved_best)
	return result


## Centro de la pista en planta (x, z) para dibujar el mapa.
func track_outline() -> PackedVector2Array:
	var result := PackedVector2Array()
	if _track == null:
		return result
	for p in _track.centerline:
		result.append(Vector2(p.x, p.z))
	return result


## Metros desde la meta hasta el auto siguiendo el trazado (0 a largo de la pista).
func lap_distance() -> float:
	var n := _cumulative.size()
	var i := _limits.index
	if n == 0 or i < 0:
		return 0.0
	var along := (_car.global_position - _track.centerline[i]).dot(_track.flat_tangent(i))
	var total := track_length()
	return fposmod(_cumulative[i] + along - _cumulative[_start_index], total)


func _physics_process(_delta: float) -> void:
	if current == null or not _timer.running:
		return
	if _timer.current_time + 1e-6 >= _next_sample:
		_sample(_timer.current_time)
		_next_sample += interval


func _sample(time: float) -> void:
	var distance := lap_distance()
	var total := track_length()
	# Sin saltos de una vuelta entera: negativa antes de cruzar la meta, más que el largo al
	# cerrar la vuelta (se toma la más cercana a la muestra anterior).
	var previous := current.value("distance", current.size() - 1) if current.size() > 0 else 0.0
	if total > 0.0:
		distance += roundf((previous - distance) / total) * total
	current.add_sample({
		"time": time,
		"distance": distance,
		"speed": _car.get_speed_kmh(),
		"rpm": _car.get_rpm(),
		"gear": _car.gearbox.gear,
		"throttle": _car.throttle_input,
		"brake": _car.brake_input,
		"steer": _car.steer_raw,
		"x": _car.global_position.x,
		"z": _car.global_position.z,
	})


func _on_lap_started(lap: int) -> void:
	current = TelemetryLap.new()
	current.lap = lap
	current.compound = str(_car.tyres.compound().get("id", ""))
	current.track_length = track_length()
	_next_sample = 0.0


func _on_lap_completed(_lap: int, time: float, _is_best: bool, _is_record: bool) -> void:
	if current == null:
		return
	_sample(time)
	current.lap_time = time
	current.invalid = not _timer.lap_history.is_empty() and bool(_timer.lap_history.back().get("invalid", false))
	var done := current
	current = null
	laps.append(done)
	while laps.size() > max_laps:
		laps.pop_front()
	last = done
	if not done.invalid and (best == null or done.lap_time < best.lap_time):
		best = done
		if saved_best == null or done.lap_time < saved_best.lap_time:
			saved_best = done
			if save_best:
				_save(done)
	lap_recorded.emit(done)


func best_file() -> String:
	return best_path.replace("{track}", track_id if not track_id.is_empty() else "pista")


func load_best() -> TelemetryLap:
	var path := best_file()
	if not FileAccess.file_exists(path):
		return null
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		return null
	var loaded := TelemetryLap.from_dict(parsed)
	if loaded == null or not loaded.is_complete() or loaded.size() < 2:
		return null
	return loaded


func _save(lap: TelemetryLap) -> void:
	var file := FileAccess.open(best_file(), FileAccess.WRITE)
	if file == null:
		push_warning("No se pudo guardar la telemetría en %s" % best_file())
		return
	file.store_string(JSON.stringify(lap.to_dict()))


func summary(lap: TelemetryLap) -> Dictionary:
	return lap.summary(full_throttle, braking)
