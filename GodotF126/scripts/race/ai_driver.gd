class_name AiDriver
extends Node
## Piloto de la IA (Paso 44): maneja un CarController con `ai_controlled` siguiendo la línea de
## trazada (RacingLine). Dirección: apunta a un punto de la línea `lookahead_min` m o
## `lookahead_time` s adelante (lo que sea más). Velocidad: la objetivo de la línea (curvatura
## con el agarre del auto y la frenada hacia atrás) un poco más adelante, con pedales
## proporcionales al error; `pace` (0,5–1) baja la velocidad en curvas y frenadas (no en las
## rectas). Cuenta vueltas, tiempos, salidas de pista y golpes, y si queda trabado o de
## contramano vuelve a la línea. Bloque "driver" de data/ai.json.

signal lap_completed(lap: int, time: float)

var lookahead_min: float = 10.0
var lookahead_time: float = 0.55
var steer_gain: float = 2.5
var speed_lookahead: float = 4.0
var speed_lookahead_time: float = 0.1
## m/s de error para pasar de mantener (acelerador 0,5) a fondo; el freno empieza a
## `brake_deadband` m/s por encima del objetivo y llega a fondo `brake_band` m/s después.
var throttle_band: float = 3.0
var brake_deadband: float = 1.0
var brake_band: float = 3.0
var pace: float = 1.0
## Trabado = avanzó menos de `stuck_progress` m por la pista en `stuck_time` s.
var stuck_progress: float = 5.0
var stuck_time: float = 3.0
var wrong_way_time: float = 2.0
## Afuera de la pista = el centro del auto a más de media pista + `off_track_margin` m.
var off_track_margin: float = 1.0

## Índice del centerline donde está el auto y desplazamiento lateral (+ derecha).
var index: int = -1
var lateral: float = 0.0
## Velocidad objetivo de este cuadro (m/s) y error (objetivo − velocidad).
var target: float = 0.0
var speed_error: float = 0.0
var laps: int = 0
var lap_time: float = 0.0
var lap_times: Array[float] = []
var best_lap: float = -1.0
## La vuelta en curso empezó al cruzar la meta (la primera, desde donde aparece, no cuenta).
var timing: bool = false
var off_tracks: int = 0
var wall_hits: int = 0
var recoveries: int = 0
var max_lateral: float = 0.0

var car: CarController
var _track: BakuTrack
var _line: RacingLine
var _start: int = 0
var _total: float = 0.0
var _last_lap_distance: float = -1.0
var _off: bool = false
var _window: float = 0.0
var _window_start: float = 0.0
var _wrong_for: float = 0.0


func configure(data: Dictionary) -> void:
	for key in ["lookahead_min", "lookahead_time", "steer_gain", "speed_lookahead", "speed_lookahead_time",
			"throttle_band", "brake_deadband", "brake_band", "stuck_progress", "stuck_time", "wrong_way_time", "off_track_margin"]:
		if data.has(key):
			set(key, maxf(float(data[key]), 0.0))
	set_pace(float(data.get("pace", pace)))


func set_pace(value: float) -> void:
	pace = clampf(value, 0.5, 1.0)


func setup(driven: CarController, track: BakuTrack, line: RacingLine) -> void:
	car = driven
	_track = track
	_line = line
	_start = track.checkpoint_indices[0] if not track.checkpoint_indices.is_empty() else track.start_index()
	var n := line.distances.size()
	_total = line.distances[n - 1] + track.centerline[n - 1].distance_to(track.centerline[0])
	car.wall_hit.connect(func(strength: float) -> void:
		if strength > 0.05:
			wall_hits += 1)


## Pone el auto sobre la línea en el índice `i`, mirando hacia adelante, a `speed` m/s.
func place_at(i: int, speed: float = 0.0) -> void:
	var n := _track.centerline.size()
	i = posmod(i, n)
	var heading := Basis.looking_at(_track.flat_tangent(i), Vector3.UP)
	car.spawn_transform = Transform3D(heading, _track.edge_point(i, _line.offsets[i], 0.0) + Vector3(0, 0.6, 0))
	car.reset_to_spawn()
	if speed > 0.0:
		car.linear_velocity = -heading.z * speed
	index = i
	_last_lap_distance = lap_distance_at(i)
	_window = 0.0
	_window_start = _last_lap_distance
	_wrong_for = 0.0


## Metros desde la meta hasta el índice i (0 a largo de la pista).
func lap_distance_at(i: int) -> float:
	return fposmod(_line.distances[i] - _line.distances[_start], _total)


func lap_distance() -> float:
	return lap_distance_at(index) if index >= 0 else 0.0


func _physics_process(delta: float) -> void:
	if car == null or not car.controls_enabled:
		return
	var located := _track.locate(car.global_position, index)
	index = int(located.x)
	lateral = located.y
	max_lateral = maxf(max_lateral, absf(lateral))
	var v := car.forward_speed
	car.ai_inputs = Vector3(0.0, 0.0, _steer(v))
	var pedals := _pedals(v)
	car.ai_inputs.x = pedals.x
	car.ai_inputs.y = pedals.y
	_track_progress(delta)
	_watch(delta)


func _steer(v: float) -> float:
	var look_at := _track.index_at_distance(index, maxf(lookahead_min, v * lookahead_time))
	var to_target := _line.points[look_at] - car.global_position
	to_target.y = 0.0
	var forward := -car.global_transform.basis.z
	forward.y = 0.0
	return clampf(forward.signed_angle_to(to_target, Vector3.UP) * steer_gain, -1.0, 1.0)


## (acelerador, freno) según el error contra la velocidad objetivo.
func _pedals(v: float) -> Vector2:
	var ahead := _track.index_at_distance(index, speed_lookahead + maxf(v, 0.0) * speed_lookahead_time)
	var line_speed := _line.target_speed[ahead]
	target = line_speed if line_speed >= _line.top_speed * 0.98 else line_speed * pace
	speed_error = target - v
	var throttle := clampf(0.5 + speed_error / maxf(throttle_band, 0.1), 0.0, 1.0)
	var brake := clampf((-speed_error - brake_deadband) / maxf(brake_band, 0.1), 0.0, 1.0)
	if brake > 0.0:
		throttle = 0.0
	return Vector2(throttle, brake)


func _track_progress(delta: float) -> void:
	var distance := lap_distance()
	if timing:
		lap_time += delta
	if _last_lap_distance > _total - 60.0 and distance < 60.0:
		if timing:
			laps += 1
			lap_times.append(lap_time)
			if best_lap < 0.0 or lap_time < best_lap:
				best_lap = lap_time
			lap_completed.emit(laps, lap_time)
		timing = true
		lap_time = 0.0
	_last_lap_distance = distance
	var off := absf(lateral) > _track.half_width(index) + off_track_margin
	if off and not _off:
		off_tracks += 1
	_off = off


## Trabado (no avanza por la pista) o de contramano (más de 90° contra el trazado) demasiado
## tiempo: vuelve a la línea, quieto, y la vuelta en curso no cuenta.
func _watch(delta: float) -> void:
	_window += delta
	if _window >= stuck_time:
		var progress := fposmod(lap_distance() - _window_start + _total * 0.5, _total) - _total * 0.5
		_window = 0.0
		_window_start = lap_distance()
		if progress < stuck_progress:
			_recover()
			return
	var forward := -car.global_transform.basis.z
	var tangent := _track.flat_tangent(index)
	_wrong_for = _wrong_for + delta if forward.x * tangent.x + forward.z * tangent.z < 0.0 else 0.0
	if _wrong_for > wrong_way_time:
		_recover()


func _recover() -> void:
	recoveries += 1
	timing = false
	place_at(index)


func summary() -> String:
	return "%d vueltas · mejor %s · salidas %d · golpes %d · rescates %d" % [laps,
		LapTimer.format_time(best_lap) if best_lap > 0.0 else "--", off_tracks, wall_hits, recoveries]
