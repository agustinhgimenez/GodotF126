class_name AeroZones
extends Node
## Zonas de modo recta (Paso 29), de "aero_zones" en data/tracks.json: tramos en metros desde
## la línea de largada en sentido de carrera (negativo = antes de la línea; una zona puede
## cruzar la línea). Cada cuadro de física le dice al auto si está dentro de una
## (ActiveAero.in_zone) con el índice del centerline que calcula TrackLimits. Al empezar cada
## vuelta recarga la energía del modo adelantamiento.

## {"name", "from", "to"} con from / to ya entre 0 y el largo de la pista.
var zones: Array[Dictionary] = []
## Por índice del centerline: 1 dentro de una zona.
var zone_mask: PackedByteArray = PackedByteArray()
## Metros desde la línea de largada de cada índice del centerline.
var distances: PackedFloat32Array = PackedFloat32Array()

var _car: CarController
var _limits: TrackLimits
var _raw_zones: Array = []


func configure(data: Dictionary) -> void:
	var list = data.get("zones", [])
	_raw_zones = list if list is Array else []


func setup(track: BakuTrack, car: CarController, limits: TrackLimits, timer: LapTimer) -> void:
	_car = car
	_limits = limits
	timer.lap_started.connect(func(_lap: int) -> void: car.active_aero.refill())
	var n := track.centerline.size()
	var start := track.start_index()
	distances.resize(n)
	var travelled := 0.0
	for k in n:
		var i := (start + k) % n
		distances[i] = travelled
		travelled += track.centerline[i].distance_to(track.centerline[(i + 1) % n])
	zones.clear()
	for zone in _raw_zones:
		if zone is Dictionary:
			zones.append({
				"name": str(zone.get("name", "")),
				"from": fposmod(float(zone.get("from", 0.0)), track.track_length),
				"to": fposmod(float(zone.get("to", 0.0)), track.track_length),
			})
	zone_mask.resize(n)
	for i in n:
		zone_mask[i] = 1 if zone_at(distances[i]) >= 0 else 0


## Índice de la zona que contiene esa distancia desde la línea (−1 si ninguna).
func zone_at(distance: float) -> int:
	for z in zones.size():
		var from: float = zones[z]["from"]
		var to: float = zones[z]["to"]
		var inside := distance >= from and distance <= to if from <= to else distance >= from or distance <= to
		if inside:
			return z
	return -1


func _physics_process(_delta: float) -> void:
	if _car == null:
		return
	var i := _limits.index
	_car.active_aero.in_zone = i >= 0 and i < zone_mask.size() and zone_mask[i] == 1
