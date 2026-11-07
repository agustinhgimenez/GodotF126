class_name RaceRecorder
extends Node
## Grabación de la carrera para los replays (Paso 51). Cada `interval` s guarda de cada auto
## la posición, la rotación y una clave de orden (los metros de carrera o, si ya terminó,
## vueltas × largo + 100000 − hora de llegada), y la pose del Safety Car. El reloj es el de la
## escena (como el de RaceStewards: arranca con los autos en la grilla); `race_start` es su
## valor cuando se apagó el semáforo. Hasta `max_minutes` minutos; después deja de grabar.

const DATA_PATH := "res://data/replay.json"
## Floats por auto y por muestra: x, y, z, qx, qy, qz, qw, clave de orden. En el Safety Car el
## último es 1 si está en pista.
const STRIDE := 8
const FINISHED_KEY := 100000.0

var interval: float = 0.1
var max_minutes: float = 60.0

var cars: Array[CarController] = []
var entries: Array[Dictionary] = []
var times: PackedFloat32Array = PackedFloat32Array()
## Muestra s, auto i: desde (s × autos + i) × STRIDE.
var frames: PackedFloat32Array = PackedFloat32Array()
var safety_car: PackedFloat32Array = PackedFloat32Array()
var race_start: float = -1.0
var full: bool = false
var lap_length: float = 1.0
var laps: int = 1
## Microsegundos de la última muestra.
var update_us: float = 0.0

var _race: RaceSession
var _control: RaceControl
var _clock: float = 0.0
var _next: float = 0.0
var _row: PackedFloat32Array = PackedFloat32Array()


func configure(data: Dictionary) -> void:
	interval = clampf(float(data.get("interval", interval)), 0.02, 1.0)
	max_minutes = maxf(float(data.get("max_minutes", max_minutes)), 1.0)


func setup(race: RaceSession, control: RaceControl, traffic: RaceTraffic) -> void:
	_race = race
	_control = control
	lap_length = traffic.lap_length()
	laps = race.laps
	entries = race.entries.duplicate()
	for entry in entries:
		cars.append(entry["car"])
	_row.resize(cars.size() * STRIDE)


func sample_count() -> int:
	return times.size()


func start_time() -> float:
	return times[0] if not times.is_empty() else 0.0


func end_time() -> float:
	return times[times.size() - 1] if not times.is_empty() else 0.0


## Hora de la carrera (reloj del semáforo) de un instante de la grabación.
func race_time(t: float) -> float:
	return t - race_start if race_start >= 0.0 else 0.0


## Instante de la grabación de una hora de RaceControl (reloj de la carrera).
func from_race_time(t: float) -> float:
	return t + maxf(race_start, 0.0)


func memory_bytes() -> int:
	return (times.size() + frames.size() + safety_car.size()) * 4


func _physics_process(delta: float) -> void:
	if _race == null:
		return
	# Las poses que se leen acá son las del final del paso anterior: van con la hora de antes.
	var now := _clock
	_clock += delta
	if race_start < 0.0 and _race.running:
		race_start = now - _race.clock
	if full or now < _next - 0.0001:
		return
	_next = now + interval
	if times.size() >= int(max_minutes * 60.0 / interval):
		full = true
		return
	var t0 := Time.get_ticks_usec()
	var n := cars.size()
	var last := (times.size() - 1) * n * STRIDE
	for i in n:
		var car := cars[i]
		var o := i * STRIDE
		if not is_instance_valid(car):
			for k in STRIDE:
				_row[o + k] = frames[last + o + k] if last >= 0 else (1.0 if k == 6 else 0.0)
			continue
		var p := car.global_position
		var q := car.global_transform.basis.get_rotation_quaternion()
		var entry := entries[i]
		var key := float(entry["progress"])
		if entry["finished"]:
			key = laps * lap_length + FINISHED_KEY - float(entry["finish_time"])
		_row[o] = p.x
		_row[o + 1] = p.y
		_row[o + 2] = p.z
		_row[o + 3] = q.x
		_row[o + 4] = q.y
		_row[o + 5] = q.z
		_row[o + 6] = q.w
		_row[o + 7] = key
	times.append(now)
	frames.append_array(_row)
	var sc := _control.safety_car_node() if _control != null else null
	if sc != null and sc.visible:
		var p := sc.global_position
		var q := sc.global_transform.basis.get_rotation_quaternion()
		safety_car.append_array(PackedFloat32Array([p.x, p.y, p.z, q.x, q.y, q.z, q.w, 1.0]))
	else:
		safety_car.append_array(PackedFloat32Array([0, 0, 0, 0, 0, 0, 1, 0]))
	update_us = Time.get_ticks_usec() - t0


## Muestra anterior a `t` y la fracción hasta la siguiente.
func locate(t: float) -> Vector2:
	var n := times.size()
	if n == 0 or t <= times[0]:
		return Vector2(0, 0)
	if t >= times[n - 1]:
		return Vector2(n - 1, 0)
	var lo := 0
	var hi := n - 1
	while hi - lo > 1:
		var mid := (lo + hi) >> 1
		if times[mid] <= t:
			lo = mid
		else:
			hi = mid
	return Vector2(lo, (t - times[lo]) / maxf(times[hi] - times[lo], 0.0001))


func pose(i: int, t: float) -> Transform3D:
	var at := locate(t)
	var n := cars.size()
	var s := int(at.x)
	return _pose_of(frames, (s * n + i) * STRIDE, (mini(s + 1, times.size() - 1) * n + i) * STRIDE, at.y)


func safety_car_pose(t: float) -> Transform3D:
	var at := locate(t)
	var s := int(at.x)
	return _pose_of(safety_car, s * STRIDE, mini(s + 1, times.size() - 1) * STRIDE, at.y)


func safety_car_visible(t: float) -> bool:
	var a := int(locate(t).x) * STRIDE + 7
	return safety_car.size() > a and safety_car[a] > 0.5


## Clave de orden del auto i (metros de carrera; > vueltas × largo si ya terminó).
func order_key(i: int, t: float) -> float:
	if times.is_empty():
		return 0.0
	var at := locate(t)
	var s := int(at.x)
	var a := _key(s, i)
	var b := _key(mini(s + 1, times.size() - 1), i)
	if a > laps * lap_length + 1000.0 or b > laps * lap_length + 1000.0:
		return b if at.y > 0.5 else a
	return lerpf(a, b, at.y)


func finished(i: int, t: float) -> bool:
	return order_key(i, t) > laps * lap_length + 1000.0


## Metros de carrera del auto i (los que terminaron, vueltas × largo).
func progress(i: int, t: float) -> float:
	var key := order_key(i, t)
	return laps * lap_length if key > laps * lap_length + 1000.0 else key


## Índices de los autos del primero al último en el instante t.
func order_at(t: float) -> Array[int]:
	var order: Array[int] = []
	var keys: Array[float] = []
	for i in cars.size():
		order.append(i)
		keys.append(order_key(i, t))
	order.sort_custom(func(a: int, b: int) -> bool:
		if keys[a] != keys[b]:
			return keys[a] > keys[b]
		return int(entries[a]["grid"]) < int(entries[b]["grid"]))
	return order


## Primer instante en que el auto i llegó a `meters` de carrera (−1 si nunca).
func time_at_progress(i: int, meters: float) -> float:
	var n := times.size()
	if n == 0 or _progress_at(n - 1, i) < meters:
		return -1.0
	if _progress_at(0, i) >= meters:
		return times[0]
	var lo := 0
	var hi := n - 1
	while hi - lo > 1:
		var mid := (lo + hi) >> 1
		if _progress_at(mid, i) >= meters:
			hi = mid
		else:
			lo = mid
	var a := _progress_at(lo, i)
	var b := _progress_at(hi, i)
	return lerpf(times[lo], times[hi], clampf((meters - a) / maxf(b - a, 0.001), 0.0, 1.0))


## Velocidad (m/s) del auto i alrededor de t.
func velocity(i: int, t: float) -> Vector3:
	var a := int(locate(t).x)
	var b := mini(a + 1, times.size() - 1)
	if b == a:
		a = maxi(a - 1, 0)
	if b == a:
		return Vector3.ZERO
	var n := cars.size()
	var oa := (a * n + i) * STRIDE
	var ob := (b * n + i) * STRIDE
	var pa := Vector3(frames[oa], frames[oa + 1], frames[oa + 2])
	var pb := Vector3(frames[ob], frames[ob + 1], frames[ob + 2])
	return (pb - pa) / maxf(times[b] - times[a], 0.0001)


func index_of(car: CarController) -> int:
	return cars.find(car)


func _key(s: int, i: int) -> float:
	return frames[(s * cars.size() + i) * STRIDE + 7]


func _progress_at(s: int, i: int) -> float:
	var key := _key(s, i)
	return laps * lap_length if key > laps * lap_length + 1000.0 else key


func _pose_of(data: PackedFloat32Array, a: int, b: int, f: float) -> Transform3D:
	if data.size() < a + STRIDE:
		return Transform3D.IDENTITY
	if data.size() < b + STRIDE:
		b = a
	var pa := Vector3(data[a], data[a + 1], data[a + 2])
	var pb := Vector3(data[b], data[b + 1], data[b + 2])
	var qa := Quaternion(data[a + 3], data[a + 4], data[a + 5], data[a + 6])
	var qb := Quaternion(data[b + 3], data[b + 4], data[b + 5], data[b + 6])
	return Transform3D(Basis(qa.slerp(qb, f)), pa.lerp(pb, f))
