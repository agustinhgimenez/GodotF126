class_name RaceTraffic
extends Node
## Autos en pista (Paso 45): el jugador y los rivales de la IA. Una vez por cuadro de física,
## antes que los AiDriver, ubica a cada auto sobre el trazado (índice, lateral, metros desde la
## meta, velocidad) y calcula:
## - el rebufo: detrás de otro auto y en línea, el CdA baja hasta `slip_max` pegado y nada a
##   `slip_range` m (sólo por encima de `slip_min_speed`);
## - la distancia en segundos al de adelante, que pide el modo adelantamiento (a menos de 1 s);
##   con un solo auto en pista queda en −1 y el modo vale siempre;
## - los contactos: dos autos con los centros a menos de `car_length` hacia adelante y `car_width`
##   de costado, medidos desde uno de ellos (la caja de colisión de car.tscn), se están tocando
##   (cuenta cada contacto nuevo).
## Bloque "traffic" de data/ai.json.

signal contact(a: CarController, b: CarController)

var slip_range: float = 30.0
var slip_max: float = 0.25
var slip_lateral: float = 1.5
var slip_min_speed: float = 120.0 / 3.6
var car_length: float = 6.0
var car_width: float = 1.9
## Hasta cuántos metros adelante se busca al auto de adelante.
var scan_range: float = 150.0

var cars: Array[CarController] = []
var index: PackedInt32Array = PackedInt32Array()
var lateral: PackedFloat32Array = PackedFloat32Array()
var distance: PackedFloat32Array = PackedFloat32Array()
var speed: PackedFloat32Array = PackedFloat32Array()
## Velocidad de costado (m/s, + derecha), del cambio de `lateral` en el último cuadro.
var side_speed: PackedFloat32Array = PackedFloat32Array()
var contacts: int = 0
## Costo del último cuadro (µs).
var update_us: float = 0.0

var _track: BakuTrack
var _line: RacingLine
var _start: int = 0
var _total: float = 0.0
var _touching: Dictionary = {}


func configure(data: Dictionary) -> void:
	slip_range = maxf(float(data.get("slip_range", slip_range)), 1.0)
	slip_max = clampf(float(data.get("slip_max", slip_max)), 0.0, 0.9)
	slip_lateral = maxf(float(data.get("slip_lateral", slip_lateral)), 0.0)
	slip_min_speed = maxf(float(data.get("slip_min_speed_kmh", slip_min_speed * 3.6)), 0.0) / 3.6
	car_length = maxf(float(data.get("car_length", car_length)), 1.0)
	car_width = maxf(float(data.get("car_width", car_width)), 0.5)
	scan_range = maxf(float(data.get("scan_range", scan_range)), 10.0)


func _ready() -> void:
	process_physics_priority = -10


func setup(track: BakuTrack, line: RacingLine) -> void:
	_track = track
	_line = line
	_start = track.checkpoint_indices[0] if not track.checkpoint_indices.is_empty() else track.start_index()
	var n := line.distances.size()
	_total = line.distances[n - 1] + track.centerline[n - 1].distance_to(track.centerline[0])


func add_car(car: CarController) -> void:
	if car in cars:
		return
	cars.append(car)
	index.append(-1)
	lateral.append(0.0)
	distance.append(0.0)
	speed.append(0.0)
	side_speed.append(0.0)
	_locate(cars.size() - 1)


func remove_car(car: CarController) -> void:
	var k := cars.find(car)
	if k < 0:
		return
	cars.remove_at(k)
	index.remove_at(k)
	lateral.remove_at(k)
	distance.remove_at(k)
	speed.remove_at(k)
	side_speed.remove_at(k)
	car.slipstream = 0.0
	car.active_aero.gap_ahead = -1.0
	_touching.clear()
	_refresh_alone()


func slot(car: CarController) -> int:
	return cars.find(car)


func lap_length() -> float:
	return _total


## Metros por la pista de `a` a `b` (+ si b va adelante), entre −media vuelta y +media vuelta.
func gap(a: int, b: int) -> float:
	return fposmod(distance[b] - distance[a] + _total * 0.5, _total) - _total * 0.5


## El auto más cercano adelante (ahead) o atrás de `k` a menos de `within` m; −1 si no hay.
## No cuenta a los que están lejos de la pista (más de 8 m afuera de la línea blanca).
func nearest(k: int, ahead: bool, within: float) -> int:
	var best := -1
	var best_gap := within
	for j in cars.size():
		if j == k or absf(lateral[j]) > _track.half_width(index[j]) + 8.0:
			continue
		var g := gap(k, j) if ahead else -gap(k, j)
		if g >= 0.0 and g < best_gap:
			best_gap = g
			best = j
	return best


func _physics_process(delta: float) -> void:
	if _track == null or cars.is_empty():
		return
	var t0 := Time.get_ticks_usec()
	for k in range(cars.size() - 1, -1, -1):
		if not is_instance_valid(cars[k]):
			cars.remove_at(k)
			index.remove_at(k)
			lateral.remove_at(k)
			distance.remove_at(k)
			speed.remove_at(k)
			side_speed.remove_at(k)
			_touching.clear()
	for k in cars.size():
		var before := lateral[k]
		_locate(k)
		side_speed[k] = clampf((lateral[k] - before) / maxf(delta, 0.001), -20.0, 20.0)
	if cars.size() < 2:
		_refresh_alone()
	else:
		for k in cars.size():
			_update_car(k)
		_check_contacts()
	update_us = Time.get_ticks_usec() - t0


func _locate(k: int) -> void:
	var pos := cars[k].global_position
	var located := _track.locate(pos, index[k])
	var i := int(located.x)
	index[k] = i
	lateral[k] = located.y
	var along := (pos - _track.centerline[i]).dot(_track.flat_tangent(i))
	distance[k] = fposmod(_line.distances[i] - _line.distances[_start] + along, _total)
	speed[k] = cars[k].forward_speed


func _update_car(k: int) -> void:
	var car := cars[k]
	var ahead := nearest(k, true, scan_range)
	if ahead < 0:
		car.slipstream = 0.0
		car.active_aero.gap_ahead = INF
		return
	var g := gap(k, ahead)
	car.active_aero.gap_ahead = g / maxf(speed[k], 10.0)
	var in_line := absf(lateral[ahead] - lateral[k]) < slip_lateral
	if in_line and speed[k] > slip_min_speed and g < slip_range:
		car.slipstream = slip_max * clampf((slip_range - g) / maxf(slip_range - car_length, 0.1), 0.0, 1.0)
	else:
		car.slipstream = 0.0


func _refresh_alone() -> void:
	for car in cars:
		car.slipstream = 0.0
		car.active_aero.gap_ahead = -1.0


func _check_contacts() -> void:
	for a in cars.size():
		for b in range(a + 1, cars.size()):
			var touching := false
			if absf(gap(a, b)) < car_length * 1.5:
				var local := cars[a].global_transform.affine_inverse() * cars[b].global_position
				touching = absf(local.x) < car_width and absf(local.z) < car_length and absf(local.y) < 2.0
			var key := Vector2i(a, b)
			if not touching and not _touching.has(key):
				continue
			if touching and not _touching.has(key):
				contacts += 1
				contact.emit(cars[a], cars[b])
			if touching:
				_touching[key] = true
			else:
				_touching.erase(key)
