class_name RaceStewards
extends Node
## Comisarios (Paso 46; datos en data/stewards.json). Cada toque entre dos autos (el contacto de
## RaceTraffic o el golpe que da la física, CarController.car_hit) abre un incidente; los toques
## del mismo par mientras está abierto, o hasta `repeat_time` s después de juzgarlo, son el
## mismo incidente. A los `judge_delay` s se juzga con cómo venían los autos un poco antes del
## toque (de `before_from` a `before_to` s antes, para que el rebote no cuente):
## Golpe = el mayor entre el que da la física y la velocidad con que se acercaban / `impact_speed`
## (un roce de costado casi no le saca velocidad a ninguno, pero se cerró igual).
## - Golpe más flojo que `min_impact`: un roce, no se investiga.
## - De atrás (los centros a más de `rear_overlap` × largo del auto por la pista): la culpa es
##   del de atrás si venía `rear_closing` m/s o más rápido que el de adelante.
## - De costado (superpuestos): la culpa es del que se movía hacia el otro a `side_speed` m/s o
##   más y `side_margin` m/s más rápido que el otro hacia él.
## - Si no, incidente de carrera, sin acción.
## El culpable recibe una advertencia o, con un golpe de `penalty_impact` o más, `penalty_seconds`
## s de penalización; con `max_warnings` advertencias, también (y vuelve a cero).
## Paso 50: las banderas (RaceControl) sancionan directo con `flag_penalty()`.

signal decided(incident: Dictionary)

const DATA_PATH := "res://data/stewards.json"
const HISTORY := 30

var judge_delay: float = 0.3
var repeat_time: float = 2.0
var min_impact: float = 0.05
var penalty_impact: float = 0.25
var penalty_seconds: float = 5.0
var max_warnings: int = 3
var rear_overlap: float = 0.6
var rear_closing: float = 1.0
var side_speed: float = 0.8
var side_margin: float = 0.5
var before_from: float = 0.3
var before_to: float = 0.05
## m/s de acercamiento = golpe 1 (como CarController.shake_wall_speed).
var impact_speed: float = 15.0

var traffic: RaceTraffic
## Incidentes juzgados, en orden: {"a", "b", "gap", "lat_a", "lat_b", "side_a", "side_b",
## "speed_a", "speed_b", "strength", "kind", "guilty", "victim", "action" ("ignored" / "none" /
## "warning" / "penalty"), "seconds", "warnings", "time"}.
var incidents: Array[Dictionary] = []
## Por auto: segundos de penalización y advertencias pendientes.
var penalties: Dictionary = {}
var warnings: Dictionary = {}

var _open: Array[Dictionary] = []
var _recent: Dictionary = {}
var _watched: Dictionary = {}
## Por auto (id de instancia): laterales y velocidades de los últimos HISTORY cuadros.
var _lateral_log: Dictionary = {}
var _speed_log: Dictionary = {}
var _clock: float = 0.0
var _step: float = 1.0 / 60.0


func configure(data: Dictionary) -> void:
	judge_delay = maxf(float(data.get("judge_delay", judge_delay)), 0.0)
	repeat_time = maxf(float(data.get("repeat_time", repeat_time)), 0.0)
	min_impact = maxf(float(data.get("min_impact", min_impact)), 0.0)
	penalty_impact = maxf(float(data.get("penalty_impact", penalty_impact)), min_impact)
	penalty_seconds = maxf(float(data.get("penalty_seconds", penalty_seconds)), 0.0)
	max_warnings = maxi(int(data.get("max_warnings", max_warnings)), 1)
	rear_overlap = clampf(float(data.get("rear_overlap", rear_overlap)), 0.0, 1.0)
	rear_closing = maxf(float(data.get("rear_closing", rear_closing)), 0.0)
	side_speed = maxf(float(data.get("side_speed", side_speed)), 0.0)
	side_margin = maxf(float(data.get("side_margin", side_margin)), 0.0)
	before_from = clampf(float(data.get("before_from", before_from)), 0.05, HISTORY / 60.0)
	before_to = clampf(float(data.get("before_to", before_to)), 0.0, before_from - 0.02)
	impact_speed = maxf(float(data.get("impact_speed", impact_speed)), 1.0)


func setup(cars: RaceTraffic) -> void:
	traffic = cars
	traffic.contact.connect(func(a: CarController, b: CarController) -> void: report(a, b, 0.0))


func _physics_process(delta: float) -> void:
	if traffic == null:
		return
	_step = maxf(delta, 0.001)
	_clock += delta
	for k in traffic.cars.size():
		var car := traffic.cars[k]
		var id := car.get_instance_id()
		if not _watched.has(id):
			_watched[id] = true
			car.car_hit.connect(func(other: CarController, strength: float) -> void: report(car, other, strength))
		_push(_lateral_log, id, traffic.lateral[k])
		_push(_speed_log, id, traffic.speed[k])
	for key in _recent.keys():
		if _clock - float(_recent[key]) > repeat_time:
			_recent.erase(key)
	for n in range(_open.size() - 1, -1, -1):
		var incident := _open[n]
		if _clock - float(incident["time"]) >= judge_delay:
			_open.remove_at(n)
			_recent[_pair(incident["a"], incident["b"])] = _clock
			decide(incident)


## Un toque entre `a` y `b` con un golpe `strength` (0 si sólo se superpusieron).
func report(a: CarController, b: CarController, strength: float) -> void:
	if not is_instance_valid(a) or not is_instance_valid(b) or a == b:
		return
	var key := _pair(a, b)
	for incident in _open:
		if _pair(incident["a"], incident["b"]) == key:
			incident["strength"] = maxf(float(incident["strength"]), strength)
			return
	if _recent.has(key):
		return
	var ka := traffic.slot(a)
	var kb := traffic.slot(b)
	if ka < 0 or kb < 0:
		return
	_open.append({
		"a": a, "b": b, "gap": traffic.gap(ka, kb),
		"lat_a": traffic.lateral[ka], "lat_b": traffic.lateral[kb],
		"side_a": _side_before(a, traffic.side_speed[ka]), "side_b": _side_before(b, traffic.side_speed[kb]),
		"speed_a": _speed_before(a, traffic.speed[ka]), "speed_b": _speed_before(b, traffic.speed[kb]),
		"strength": strength, "time": _clock,
	})


## Juzga un incidente (con las claves de `report`), aplica la sanción y emite `decided`.
## Golpe = el mayor entre el de la física y la velocidad con que se acercaban / `impact_speed`.
func decide(incident: Dictionary) -> Dictionary:
	var verdict := blame(incident)
	incident["kind"] = verdict["kind"]
	incident["guilty"] = verdict["guilty"]
	incident["victim"] = verdict["victim"]
	incident["closing"] = verdict["closing"]
	incident["strength"] = maxf(float(incident["strength"]), clampf(float(verdict["closing"]) / impact_speed, 0.0, 1.0))
	incident["action"] = "ignored" if float(incident["strength"]) < min_impact else "none"
	incident["seconds"] = 0.0
	incident["warnings"] = 0
	var guilty = verdict["guilty"]
	if guilty != null and incident["action"] == "none":
		var count := int(warnings.get(guilty, 0))
		if float(incident["strength"]) >= penalty_impact:
			incident["action"] = "penalty"
		else:
			count += 1
			incident["action"] = "warning"
			if count >= max_warnings:
				incident["action"] = "penalty"
				count = 0
		warnings[guilty] = count
		incident["warnings"] = count
		if incident["action"] == "penalty":
			incident["seconds"] = penalty_seconds
			penalties[guilty] = float(penalties.get(guilty, 0.0)) + penalty_seconds
	incidents.append(incident)
	decided.emit(incident)
	return incident


## Paso 50: sanción directa de la dirección de carrera (RaceControl), sin investigar: `kind`
## "yellow" / "safety_car" (pasó a `victim`), "sc_pass" (pasó al Safety Car) o "blue" (no dejó
## pasar a `victim`).
func flag_penalty(guilty: CarController, victim: CarController, kind: String, seconds: float) -> Dictionary:
	var incident := {
		"a": guilty, "b": victim if victim != null else guilty, "guilty": guilty, "victim": victim,
		"kind": kind, "action": "penalty", "seconds": seconds, "warnings": 0, "strength": 1.0,
		"closing": 0.0, "gap": 0.0, "time": _clock,
	}
	penalties[guilty] = float(penalties.get(guilty, 0.0)) + seconds
	incidents.append(incident)
	decided.emit(incident)
	return incident


## Quién tuvo la culpa: {"guilty", "victim" (null si nadie), "kind" ("rear" / "side" /
## "racing"), "closing" (m/s con que se acercaban)}.
func blame(incident: Dictionary) -> Dictionary:
	var a = incident["a"]
	var b = incident["b"]
	var gap := float(incident["gap"])
	var length := traffic.car_length if traffic != null else 6.0
	if absf(gap) > length * rear_overlap:
		var a_behind := gap > 0.0
		var closing := float(incident["speed_a"]) - float(incident["speed_b"])
		if not a_behind:
			closing = -closing
		if closing >= rear_closing:
			return {"guilty": a if a_behind else b, "victim": b if a_behind else a, "kind": "rear", "closing": closing}
		return {"guilty": null, "victim": null, "kind": "racing", "closing": maxf(closing, 0.0)}
	var toward := signf(float(incident["lat_b"]) - float(incident["lat_a"]))
	if toward == 0.0:
		toward = 1.0
	var a_in := float(incident["side_a"]) * toward
	var b_in := -float(incident["side_b"]) * toward
	var side_closing := maxf(a_in + b_in, 0.0)
	if a_in >= side_speed and a_in - b_in >= side_margin:
		return {"guilty": a, "victim": b, "kind": "side", "closing": side_closing}
	if b_in >= side_speed and b_in - a_in >= side_margin:
		return {"guilty": b, "victim": a, "kind": "side", "closing": side_closing}
	return {"guilty": null, "victim": null, "kind": "racing", "closing": side_closing}


## Reloj de los incidentes ("time"): s de escena desde setup().
func clock() -> float:
	return _clock


func penalty_of(car: CarController) -> float:
	return float(penalties.get(car, 0.0))


func warnings_of(car: CarController) -> int:
	return int(warnings.get(car, 0))


## Texto para el HUD.
func describe(incident: Dictionary) -> String:
	var guilty = incident["guilty"]
	match str(incident["action"]):
		"penalty":
			return "Penalización %s s a %s: %s" % [_seconds_text(float(incident["seconds"])), short_name(guilty), reason(incident, true)]
		"warning":
			return "Advertencia %d/%d a %s: %s" % [int(incident["warnings"]), max_warnings, short_name(guilty), reason(incident, true)]
		_:
			return "Toque entre %s y %s: sin acción" % [short_name(incident["a"]), short_name(incident["b"])]


## Motivo, para el HUD (`short`: con el apellido) y la penalización del cronómetro.
static func reason(incident: Dictionary, short: bool = false) -> String:
	var victim := short_name(incident.get("victim")) if short else car_name(incident.get("victim"))
	match str(incident.get("kind", "")):
		"rear":
			return "choque por detrás a %s" % victim
		"side":
			return "se cerró sobre %s" % victim
		"yellow":
			return "pasó a %s con bandera amarilla" % victim
		"safety_car":
			return "pasó a %s con Safety Car" % victim
		"sc_pass":
			return "pasó al Safety Car"
		"blue":
			return "no dejó pasar a %s (bandera azul)" % victim
		_:
			return "incidente de carrera"


static func car_name(car) -> String:
	if car == null or not is_instance_valid(car):
		return "?"
	return str(car.get_meta("driver_name", car.name))


## Apellido (la última palabra del nombre).
static func short_name(car) -> String:
	var parts := car_name(car).split(" ", false)
	return parts[parts.size() - 1] if not parts.is_empty() else "?"


static func _seconds_text(s: float) -> String:
	return ("%.1f" % s).replace(".", ",").trim_suffix(",0")


func _pair(a: Object, b: Object) -> String:
	var x := a.get_instance_id()
	var y := b.get_instance_id()
	return "%d:%d" % [mini(x, y), maxi(x, y)]


func _push(history: Dictionary, id: int, value: float) -> void:
	var values: PackedFloat32Array = history.get(id, PackedFloat32Array())
	values.append(value)
	if values.size() > HISTORY:
		values.remove_at(0)
	history[id] = values


## Velocidad de costado media entre `before_from` y `before_to` s antes de ahora.
func _side_before(car: CarController, fallback: float) -> float:
	var values: PackedFloat32Array = _lateral_log.get(car.get_instance_id(), PackedFloat32Array())
	var span := _frames(values.size())
	if span.x <= span.y:
		return fallback
	return (values[values.size() - 1 - span.y] - values[values.size() - 1 - span.x]) / ((span.x - span.y) * _step)


func _speed_before(car: CarController, fallback: float) -> float:
	var values: PackedFloat32Array = _speed_log.get(car.get_instance_id(), PackedFloat32Array())
	var span := _frames(values.size())
	if span.x <= span.y:
		return fallback
	return values[values.size() - 1 - span.x]


## Cuadros hacia atrás (desde, hasta) dentro de lo guardado.
func _frames(size: int) -> Vector2i:
	var from := mini(roundi(before_from / _step), size - 1)
	var to := mini(roundi(before_to / _step), from)
	return Vector2i(from, to)
