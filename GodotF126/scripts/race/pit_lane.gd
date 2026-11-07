class_name PitLane
extends Node
## Calle de boxes (Paso 48), con la geometría que arma BakuTrack desde "pit_lane" en
## data/tracks.json. Cada cuadro de física mira a todos los autos de RaceTraffic:
## - En la calle: entre la entrada y la salida y más allá de la línea blanca de ese lado.
## - Limitador: entre `limit_from` y `limit_to`; pasar de `speed_limit_kmh` +
##   `speed_tolerance_kmh` es una sanción de `speeding_penalty` s (una por pasada; señal
##   `speeding`). Los autos de la IA lo prenden solos; el del jugador se prende con P
##   (CarController.pit_limit) y se apaga solo al pasar `limit_to`.
## - Parada: quieto (menos de `stop_speed` m/s) a menos de `box_tolerance` m de la marca de la
##   caja de su equipo (en el carril de las cajas): el auto queda frenado `stop_time` s
##   (+ `wing_time` con el alerón dañado), recibe neumáticos nuevos y se reparan el alerón y
##   los pinchazos (`stop_started` / `stop_finished`). Paso 49: el compuesto es el elegido con
##   set_next_compound() (si no, el mismo que tenía).
## La IA usa path_lateral() y speed_cap() para entrar, pararse en su caja y salir.

signal entered(car: CarController)
signal exited(car: CarController)
signal stop_started(car: CarController, duration: float)
signal stop_finished(car: CarController, repaired_wing: bool)
signal speeding(car: CarController, kmh: float, penalty: float)
signal limiter_changed(car: CarController, on: bool)

var side: float = -1.0
var entry: float = -470.0
var exit: float = 120.0
var entry_ramp: float = 45.0
var exit_ramp: float = 45.0
var limit_from: float = -400.0
var limit_to: float = 60.0
var fast_lane: float = 2.2
var box_lane: float = 6.0
var first_box: float = -300.0
var box_spacing: float = 18.0
var box_tolerance: float = 2.5
var speed_limit: float = 80.0 / 3.6
var speed_tolerance: float = 1.0 / 3.6
var speeding_penalty: float = 5.0
var stop_speed: float = 1.0
var stop_time: float = 2.4
var wing_time: float = 4.0
var ai_approach: float = 50.0
var ai_merge: float = 40.0
var ai_speed_margin: float = 0.95
var ai_brake: float = 9.0
var ai_stop_decel: float = 5.0

## Id del equipo → número de caja (orden de grid_2026.json).
var boxes: Dictionary = {}
## Paradas completas en la sesión.
var stops: int = 0

var _track: BakuTrack
var _traffic: RaceTraffic
## Por auto: {in_lane, in_limit, served, penalized, service (s que faltan, −1 sin parada),
## wing, max_kmh, stops}.
var _state: Dictionary = {}
## Paso 49: auto → id del compuesto de su próxima parada.
var _next_compound: Dictionary = {}


func configure(data: Dictionary, grid: Dictionary) -> void:
	side = -1.0 if float(data.get("side", side)) < 0.0 else 1.0
	for key in ["entry", "exit", "entry_ramp", "exit_ramp", "limit_from", "limit_to", "fast_lane", "box_lane",
			"first_box", "box_spacing", "box_tolerance", "speeding_penalty", "stop_speed", "stop_time", "wing_time"]:
		if data.has(key):
			set(key, float(data[key]))
	speed_limit = maxf(float(data.get("speed_limit_kmh", speed_limit * 3.6)), 10.0) / 3.6
	speed_tolerance = maxf(float(data.get("speed_tolerance_kmh", speed_tolerance * 3.6)), 0.0) / 3.6
	var ai = data.get("ai", {})
	if ai is Dictionary:
		ai_approach = maxf(float(ai.get("approach", ai_approach)), 10.0)
		ai_merge = maxf(float(ai.get("merge", ai_merge)), 10.0)
		ai_speed_margin = clampf(float(ai.get("speed_margin", ai_speed_margin)), 0.5, 1.0)
		ai_brake = maxf(float(ai.get("brake", ai_brake)), 1.0)
		ai_stop_decel = maxf(float(ai.get("stop_decel", ai_stop_decel)), 1.0)
	boxes.clear()
	var teams = grid.get("teams", [])
	if teams is Array:
		for b in teams.size():
			boxes[str(teams[b].get("id", ""))] = b


func setup(track: BakuTrack, traffic: RaceTraffic) -> void:
	_track = track
	_traffic = traffic


func enabled() -> bool:
	return _track != null and _track.has_pit_lane()


## Metros desde la línea de largada de la caja `b`.
func box_offset(b: int) -> float:
	return first_box + box_spacing * b


## Caja del equipo del auto (meta "team_id"; −1 si no tiene).
func box_of(car: CarController) -> int:
	return int(boxes.get(str(car.get_meta("team_id", "")), -1))


## En la calle: entre la entrada y la salida, del lado de boxes más allá de la línea blanca.
func contains(i: int, lateral: float) -> bool:
	if not enabled():
		return false
	var s := _track.start_offset(i)
	return s > entry and s < exit and lateral * side > _track.half_width(i) + 0.3


func in_lane(car: CarController) -> bool:
	return bool(_state.get(car, {}).get("in_lane", false))


func is_served(car: CarController) -> bool:
	return bool(_state.get(car, {}).get("served", false))


func in_service(car: CarController) -> bool:
	return float(_state.get(car, {}).get("service", -1.0)) >= 0.0


## s que faltan de la parada (−1 sin parada).
func service_left(car: CarController) -> float:
	return float(_state.get(car, {}).get("service", -1.0))


func stops_of(car: CarController) -> int:
	return int(_state.get(car, {}).get("stops", 0))


## Máxima velocidad (km/h) en la zona del limitador en esta pasada (0 si no entró).
func max_kmh(car: CarController) -> float:
	return float(_state.get(car, {}).get("max_kmh", 0.0))


## Lateral (+ derecha) del camino de boxes en el índice i para un auto de la IA que entra:
## se acerca al borde, cruza al carril rápido, se mete en el de las cajas en la suya (si todavía
## no paró), vuelve al rápido, sale y vuelve a `base` (su lateral sin boxes).
func path_lateral(i: int, base: float, car: CarController) -> float:
	var s := _track.start_offset(i)
	var hw := _track.half_width(i)
	var edge := side * (hw - 1.5)
	var fast := side * (_track.pit_lane_start(i) + fast_lane)
	var entry_end := entry + entry_ramp
	var exit_start := exit - exit_ramp
	if s < entry - ai_approach or s > exit + ai_merge:
		return base
	if s < entry:
		return lerpf(base, edge, smoothstep(entry - ai_approach, entry, s))
	if s < entry_end:
		return lerpf(edge, fast, smoothstep(entry, entry_end, s))
	if s > exit:
		return lerpf(edge, base, smoothstep(exit, exit + ai_merge, s))
	if s > exit_start:
		return lerpf(fast, edge, smoothstep(exit_start, exit, s))
	var b := box_of(car)
	if b < 0:
		return fast
	var box_s := box_offset(b)
	var lane := side * (_track.pit_lane_start(i) + box_lane)
	var into := smoothstep(box_s - 25.0, box_s - 6.0, s)
	var out := smoothstep(box_s + 2.0, box_s + 16.0, s)
	return lerpf(fast, lane, into * (1.0 - out))


## Velocidad máxima (m/s) de un auto de la IA que entra a boxes en el índice i: frena hasta el
## `ai_speed_margin` del límite antes de la línea, lo respeta hasta `limit_to` y, si todavía
## no paró y no se pasó de su caja, llega a la marca frenando a `ai_stop_decel`.
func speed_cap(i: int, car: CarController) -> float:
	var s := _track.start_offset(i)
	var limit := speed_limit * ai_speed_margin
	var cap := INF
	if s < limit_from and s > entry - ai_approach - 200.0:
		var room := maxf(limit_from - 10.0 - s, 0.0)
		cap = sqrt(limit * limit + 2.0 * ai_brake * room)
	elif s >= limit_from and s <= limit_to:
		cap = limit
	var b := box_of(car)
	if b >= 0 and not is_served(car) and s > entry and s < box_offset(b) + box_tolerance:
		cap = minf(cap, sqrt(2.0 * ai_stop_decel * maxf(box_offset(b) + 0.5 - s, 0.0)))
	return cap


## Paso 49: compuesto que recibe `car` en su próxima parada.
func set_next_compound(car: CarController, id: String) -> void:
	_next_compound[car] = id


func next_compound(car: CarController) -> String:
	return str(_next_compound.get(car, car.compound_id()))


## Limitador del jugador (tecla P).
func toggle_limiter(car: CarController) -> void:
	car.pit_limit = 0.0 if car.pit_limit > 0.0 else speed_limit
	limiter_changed.emit(car, car.pit_limit > 0.0)


func _physics_process(delta: float) -> void:
	if not enabled() or _traffic == null:
		return
	for k in _traffic.cars.size():
		var car := _traffic.cars[k]
		if is_instance_valid(car):
			_update_car(car, _traffic.index[k], _traffic.lateral[k], delta)


func _update_car(car: CarController, i: int, lateral: float, delta: float) -> void:
	var state: Dictionary = _state.get(car, {})
	if state.is_empty():
		state = {"in_lane": false, "in_limit": false, "served": false, "penalized": false, "service": -1.0,
			"wing": false, "max_kmh": 0.0, "stops": 0}
		_state[car] = state
	var s := _track.start_offset(i)
	var inside := contains(i, lateral)
	if inside and not state["in_lane"]:
		state["in_lane"] = true
		state["served"] = false
		state["penalized"] = false
		state["max_kmh"] = 0.0
		entered.emit(car)
	elif not inside and state["in_lane"] and float(state["service"]) < 0.0:
		state["in_lane"] = false
		state["in_limit"] = false
		if car.ai_controlled:
			car.pit_limit = 0.0
		exited.emit(car)
	var in_limit: bool = state["in_lane"] and s >= limit_from and s <= limit_to
	if in_limit != state["in_limit"]:
		state["in_limit"] = in_limit
		if car.ai_controlled:
			car.pit_limit = speed_limit if in_limit else 0.0
		elif not in_limit and car.pit_limit > 0.0 and s > limit_to:
			car.pit_limit = 0.0
			limiter_changed.emit(car, false)
	if in_limit:
		var kmh := car.forward_speed * 3.6
		state["max_kmh"] = maxf(float(state["max_kmh"]), kmh)
		if not state["penalized"] and car.forward_speed > speed_limit + speed_tolerance:
			state["penalized"] = true
			speeding.emit(car, kmh, speeding_penalty)
	if float(state["service"]) >= 0.0:
		state["service"] = float(state["service"]) - delta
		if float(state["service"]) <= 0.0:
			_finish_service(car, state)
		return
	var b := box_of(car)
	if not state["in_lane"] or state["served"] or b < 0:
		return
	var at_box := absf(s - box_offset(b)) < box_tolerance
	var in_box_lane := absf(lateral * side - (_track.pit_lane_start(i) + box_lane)) < 1.6
	if at_box and in_box_lane and absf(car.forward_speed) < stop_speed:
		var wing := car.damage.wing_health < 1.0
		var duration := stop_time + (wing_time if wing else 0.0)
		state["service"] = duration
		state["wing"] = wing
		car.pit_hold = true
		stop_started.emit(car, duration)


func _finish_service(car: CarController, state: Dictionary) -> void:
	state["service"] = -1.0
	state["served"] = true
	state["stops"] = int(state["stops"]) + 1
	stops += 1
	car.fit_tyres(next_compound(car))
	car.damage.repair()
	car.pit_hold = false
	stop_finished.emit(car, bool(state["wing"]))
