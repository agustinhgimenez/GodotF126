class_name RaceControl
extends Node
## Dirección de carrera (Paso 50; datos en data/race_control.json): banderas y Safety Car.
## - Auto lento: en pista (no en la calle de boxes), pasados `start_grace` s de la largada, a
##   menos de `slow_speed` durante `slow_time` s, sin otro auto a menos de `queue_gap` m adelante
##   (los que hacen fila detrás de uno parado no cuentan).
## - Todo se revisa cada `check_every` s (el Safety Car se mueve en cada cuadro).
## - Amarilla: cada auto lento abre una zona desde `yellow_before` m antes hasta `yellow_after` m
##   después de él, que dura mientras siga lento y `yellow_hold` s más. En la zona la IA va al
##   `yellow_pace` de su objetivo y nadie puede ganar un lugar (salvo sobre un auto lento o en
##   boxes): `pass_penalty` s.
## - Azul: al que tiene a menos de `blue_time` s detrás un auto con una vuelta más. La IA
##   levanta (`blue_lift`) y no defiende; el jugador que no deja pasar `blue_penalty_time` s
##   seguidos recibe `blue_penalty` s.
## - Safety Car: con un auto lento `sc_after` s seguidos (o `sc_cars` a la vez) sale delante del
##   líder y anda a `sc_speed` (en curva, `sc_corner` × la velocidad de la línea). Cada auto de
##   la IA tiene un tope (`AiDriver.flag_cap`): el que lo tiene adelante lo sigue a `sc_follow`
##   m; los que están lejos del de adelante se acercan con `sc_catchup` más. Nadie pasa (ni a los
##   otros ni al Safety Car). Con `sc_min_time` s afuera y la pista libre `sc_clear_time` s,
##   "entra esta vuelta": desaparece en la entrada de boxes, sigue invisible marcando el ritmo
##   hasta la meta y ahí vuelve la bandera verde.
## Las posiciones son las de RaceSession (metros recorridos): una pasada es un cambio de orden
## entre dos autos que venían uno detrás del otro.

signal flag_changed(kind: String)
signal safety_car_changed(state: String)

const DATA_PATH := "res://data/race_control.json"
const SC_OUT := "out"
const SC_IN_LAP := "in_lap"
const SC_RESTART := "restart"

var start_grace: float = 8.0
var slow_speed: float = 30.0 / 3.6
var slow_time: float = 1.5
var queue_gap: float = 20.0
var check_every: float = 0.1
var yellow_before: float = 220.0
var yellow_after: float = 40.0
var yellow_hold: float = 4.0
var yellow_pace: float = 0.8
## La IA ya no empieza ni sigue una pasada a estos metros antes de la zona.
var yellow_lookahead: float = 150.0
var pass_penalty: float = 5.0
var blue_time: float = 1.0
var blue_range: float = 80.0
var blue_lift: float = 0.9
var blue_penalty_time: float = 10.0
var blue_penalty: float = 5.0
var sc_after: float = 6.0
var sc_cars: int = 2
var sc_speed: float = 130.0 / 3.6
var sc_corner: float = 0.75
var sc_spawn_ahead: float = 80.0
var sc_follow: float = 25.0
var sc_queue_gap: float = 30.0
var sc_catchup: float = 60.0 / 3.6
var sc_min_time: float = 40.0
var sc_clear_time: float = 4.0
var sc_pit_advance: int = 2
## Frenada con la que el primero se acomoda detrás del Safety Car (m/s²).
var sc_brake: float = 10.0
var texts: Dictionary = {}

## "" (sin Safety Car), SC_OUT, SC_IN_LAP o SC_RESTART.
var sc_state: String = ""
## Metros desde la meta (como RaceTraffic.distance) y velocidad del Safety Car.
var sc_distance: float = 0.0
var sc_velocity: float = 0.0
var sc_time: float = 0.0
var sc_deployments: int = 0
## Zonas de amarilla: {car, s (metros desde la meta), until (s del reloj de la carrera)}.
var yellow_zones: Array[Dictionary] = []
var yellows_opened: int = 0
var blue_flags: int = 0
## Sanciones dadas por tipo ("yellow", "safety_car", "sc_pass", "blue").
var penalties_by_kind: Dictionary = {}
## Bandera que ve el jugador ("", "yellow", "blue", SC_OUT, SC_IN_LAP, SC_RESTART, "green").
var player_flag: String = ""
## Para las pruebas: {time, event, name}.
var history: Array[Dictionary] = []
## Costo del último cuadro (µs).
var update_us: float = 0.0

var _race: RaceSession
var _traffic: RaceTraffic
var _track: BakuTrack
var _line: RacingLine
var _pit: PitLane
var _stewards: RaceStewards
var _player: CarController
var _radio: EngineerRadio
var _clock: float = 0.0
var _slow_for: Dictionary = {}
var _slow_now: Dictionary = {}
var _clear_for: float = 0.0
var _blue_of: Dictionary = {}
var _player_blue_time: float = 0.0
var _player_blue_name: String = ""
var _prev_order: Array[CarController] = []
var _penalized: Dictionary = {}
var _passed: Dictionary = {}
var _sc_gap: Dictionary = {}
var _green_until: float = -INF
var _ai_flags_on: bool = false
var _sc_node: Node3D
var _sc_lights: Array[StandardMaterial3D] = []
var _blink: float = 0.0
var _tick: float = 0.0


func configure(data: Dictionary) -> void:
	for key in ["start_grace", "slow_time", "queue_gap", "check_every", "yellow_lookahead", "yellow_before", "yellow_after", "yellow_hold", "pass_penalty",
			"blue_time", "blue_range", "blue_penalty_time", "blue_penalty", "sc_after", "sc_spawn_ahead", "sc_follow",
			"sc_queue_gap", "sc_min_time", "sc_clear_time", "sc_brake"]:
		if data.has(key):
			set(key, maxf(float(data[key]), 0.0))
	slow_speed = maxf(float(data.get("slow_speed_kmh", slow_speed * 3.6)), 1.0) / 3.6
	yellow_pace = clampf(float(data.get("yellow_pace", yellow_pace)), 0.3, 1.0)
	blue_lift = clampf(float(data.get("blue_lift", blue_lift)), 0.3, 1.0)
	sc_cars = maxi(int(data.get("sc_cars", sc_cars)), 1)
	sc_speed = maxf(float(data.get("sc_speed_kmh", sc_speed * 3.6)), 20.0) / 3.6
	sc_corner = clampf(float(data.get("sc_corner", sc_corner)), 0.3, 1.0)
	sc_catchup = maxf(float(data.get("sc_catchup_kmh", sc_catchup * 3.6)), 0.0) / 3.6
	sc_pit_advance = maxi(int(data.get("sc_pit_advance", sc_pit_advance)), 0)
	var text_data = data.get("texts", {})
	texts = text_data if text_data is Dictionary else {}


func setup(race: RaceSession, traffic: RaceTraffic, track: BakuTrack, line: RacingLine, pit: PitLane,
		stewards: RaceStewards, player: CarController, radio: EngineerRadio = null) -> void:
	_race = race
	_traffic = traffic
	_track = track
	_line = line
	_pit = pit
	_stewards = stewards
	_player = player
	_radio = radio
	if radio != null:
		radio.extra_texts = texts
	_sc_node = _build_safety_car()
	add_child(_sc_node)


func text(key: String, values: Dictionary = {}) -> String:
	return str(texts.get(key, "")).format(values)


## Texto de la franja del HUD para la bandera del jugador ("" sin bandera).
func player_flag_text() -> String:
	match player_flag:
		"yellow":
			return text("flag_yellow")
		"blue":
			return text("flag_blue", {"name": _player_blue_name.to_upper()})
		SC_OUT:
			return text("flag_sc")
		SC_IN_LAP:
			return text("flag_sc_in")
		SC_RESTART:
			return text("flag_restart")
		"green":
			return text("flag_green")
	return ""


func safety_car_active() -> bool:
	return not sc_state.is_empty()


## El auto del Safety Car (oculto cuando no está en pista); lo graba y lo mueve el replay.
func safety_car_node() -> Node3D:
	return _sc_node


## Saca el Safety Car ya (también lo usan las pruebas).
func deploy_safety_car() -> void:
	if safety_car_active() or _race == null or not _race.running or _race.checkered:
		return
	var list := _race.standings()
	var leader: CarController = null
	for entry in list:
		if not entry["finished"]:
			leader = entry["car"]
			break
	var k := _traffic.slot(leader) if leader != null else -1
	if k < 0:
		return
	sc_state = SC_OUT
	sc_distance = fposmod(_traffic.distance[k] + sc_spawn_ahead, _traffic.lap_length())
	sc_velocity = _sc_speed_at(_index_at(sc_distance))
	sc_time = 0.0
	sc_deployments += 1
	_clear_for = 0.0
	_sc_gap.clear()
	_penalized.clear()
	_passed.clear()
	_race.safety_car = true
	_race.pit_advance = sc_pit_advance
	_race.status_tag = "SC"
	_sc_node.visible = true
	_place_safety_car()
	_log("safety_car", RaceStewards.short_name(leader))
	_say("safety_car", {}, true)
	if _radio != null:
		_radio.check_box()
	safety_car_changed.emit(sc_state)


func is_slow(car: CarController) -> bool:
	return float(_slow_for.get(car, 0.0)) >= slow_time


## La posición `d` (metros desde la meta) está dentro de una zona de amarilla.
func in_yellow(d: float) -> bool:
	var total := _traffic.lap_length()
	for zone in yellow_zones:
		var s := float(zone["s"])
		if fposmod(s - d, total) <= yellow_before or fposmod(d - s, total) <= yellow_after:
			return true
	return false


func _physics_process(delta: float) -> void:
	if _race == null or _traffic == null or not _race.running:
		return
	var t0 := Time.get_ticks_usec()
	_clock = _race.clock
	if _race.checkered:
		if safety_car_active() or not yellow_zones.is_empty() or _ai_flags_on or not player_flag.is_empty():
			_end_all()
		return
	_move_safety_car(delta)
	_tick += delta
	if _tick >= check_every:
		var step := _tick
		_tick = 0.0
		_update_slow(step)
		_update_yellows()
		_update_safety_car(step)
		_update_blue(step)
		_apply_ai()
		_check_passes()
		_update_player_flag()
	update_us = Time.get_ticks_usec() - t0


func _process(delta: float) -> void:
	if _sc_node == null or not _sc_node.visible:
		return
	_blink += delta
	var on := fmod(_blink, 0.5) < 0.25
	for k in _sc_lights.size():
		_sc_lights[k].emission_energy_multiplier = 3.0 if on == (k % 2 == 0) else 0.2


func _update_slow(delta: float) -> void:
	for entry in _race.entries:
		var car: CarController = entry["car"]
		var k := _traffic.slot(car) if is_instance_valid(car) else -1
		var slow := false
		if k >= 0 and not entry["finished"] and _clock > start_grace and float(entry["progress"]) >= 0.0:
			var in_lane := _pit != null and _pit.in_lane(car)
			slow = not in_lane and car.controls_enabled and _traffic.speed[k] < slow_speed \
				and _traffic.nearest(k, true, queue_gap) < 0
		_slow_now[car] = slow
		_slow_for[car] = float(_slow_for.get(car, 0.0)) + delta if slow else 0.0


func _update_yellows() -> void:
	var total := _traffic.lap_length()
	for entry in _race.entries:
		var car: CarController = entry["car"]
		if not is_slow(car):
			continue
		var s := _traffic.distance[_traffic.slot(car)]
		var found := false
		for zone in yellow_zones:
			if zone["car"] == car:
				zone["s"] = s
				zone["until"] = _clock + yellow_hold
				found = true
		if found:
			continue
		yellow_zones.append({"car": car, "s": s, "until": _clock + yellow_hold})
		yellows_opened += 1
		_log("yellow", RaceStewards.short_name(car))
		var k := _traffic.slot(_player)
		if car != _player and k >= 0 and fposmod(s - _traffic.distance[k], total) < yellow_before + 800.0:
			_say("yellow", {"name": RaceStewards.short_name(car)}, true)
	for n in range(yellow_zones.size() - 1, -1, -1):
		if float(yellow_zones[n]["until"]) < _clock or not is_instance_valid(yellow_zones[n]["car"]):
			yellow_zones.remove_at(n)


func _update_safety_car(delta: float) -> void:
	var slow_cars := 0
	var longest := 0.0
	for car in _slow_for:
		if float(_slow_for[car]) >= slow_time:
			slow_cars += 1
		longest = maxf(longest, float(_slow_for[car]))
	if sc_state.is_empty():
		if longest >= sc_after or slow_cars >= sc_cars:
			deploy_safety_car()
		return
	if sc_state == SC_OUT:
		_clear_for = _clear_for + delta if slow_cars == 0 else 0.0
		if sc_time >= sc_min_time and _clear_for >= sc_clear_time:
			sc_state = SC_IN_LAP
			_log("sc_in", "")
			_say("sc_in", {}, true)
			safety_car_changed.emit(sc_state)


## En cada cuadro: avanza el Safety Car; desaparece en la entrada de boxes y en la meta la verde.
func _move_safety_car(delta: float) -> void:
	if sc_state.is_empty():
		return
	sc_time += delta
	var total := _traffic.lap_length()
	var before := sc_distance
	sc_velocity = _sc_speed_at(_index_at(sc_distance))
	sc_distance = fposmod(sc_distance + sc_velocity * delta, total)
	match sc_state:
		SC_IN_LAP:
			var entry := fposmod(_pit.entry, total) if _pit != null else total - 1.0
			if before < entry and sc_distance >= entry:
				sc_state = SC_RESTART
				_sc_node.visible = false
				_log("restart", "")
				safety_car_changed.emit(sc_state)
		SC_RESTART:
			if sc_distance < before:
				_green()
	if _sc_node.visible:
		_place_safety_car()


func _green() -> void:
	sc_state = ""
	_sc_node.visible = false
	_race.safety_car = false
	_race.pit_advance = 0
	_race.status_tag = ""
	_green_until = _clock + 3.0
	_penalized.clear()
	_passed.clear()
	_log("green", "")
	_say("green", {}, true)
	safety_car_changed.emit(sc_state)


func _update_blue(delta: float) -> void:
	var previous := _blue_of.duplicate()
	_blue_of.clear()
	if safety_car_active():
		_player_blue_time = 0.0
		return
	var total := _traffic.lap_length()
	var by_car := {}
	for entry in _race.entries:
		by_car[entry["car"]] = entry
	for entry in _race.entries:
		var car: CarController = entry["car"]
		var k := _traffic.slot(car) if is_instance_valid(car) else -1
		if k < 0 or entry["finished"] or (_pit != null and _pit.in_lane(car)):
			continue
		var j := _traffic.nearest(k, false, blue_range)
		if j < 0:
			continue
		var behind: CarController = _traffic.cars[j]
		var other: Dictionary = by_car.get(behind, {})
		if other.is_empty() or other["finished"]:
			continue
		if float(other["progress"]) - float(entry["progress"]) < total * 0.5:
			continue
		if -_traffic.gap(k, j) / maxf(_traffic.speed[j], 10.0) > blue_time:
			continue
		_blue_of[car] = behind
		if previous.get(car) != behind:
			blue_flags += 1
			if car == _player:
				_player_blue_name = RaceStewards.short_name(behind)
				_say("blue", {"name": _player_blue_name}, true)
	if _blue_of.has(_player):
		_player_blue_time += delta
		if _player_blue_time >= blue_penalty_time:
			_player_blue_time = 0.0
			_penalize(_player, _blue_of[_player], "blue", blue_penalty)
	else:
		_player_blue_time = 0.0


func _apply_ai() -> void:
	var exempt: Array[CarController] = []
	for car in _slow_now:
		if _slow_now[car]:
			exempt.append(car)
	for zone in yellow_zones:
		if not zone["car"] in exempt:
			exempt.append(zone["car"])
	if _pit != null:
		for car in _traffic.cars:
			if _pit.in_lane(car):
				exempt.append(car)
	var any := safety_car_active() or not yellow_zones.is_empty() or not _blue_of.is_empty()
	if not any and not _ai_flags_on:
		return
	_ai_flags_on = any
	for entry in _race.entries:
		var ai: AiDriver = entry["ai"]
		var car: CarController = entry["car"]
		if ai == null or not is_instance_valid(car):
			continue
		var k := _traffic.slot(car)
		var pace := 1.0
		var cap := INF
		var no_pass := false
		if k >= 0 and not entry["finished"] and not ai.pitting:
			if safety_car_active():
				no_pass = true
				cap = _sc_cap(k)
			elif in_yellow(_traffic.distance[k]):
				no_pass = true
				pace = yellow_pace
			elif in_yellow(_traffic.distance[k] + yellow_lookahead):
				no_pass = true
		var blue: CarController = _blue_of.get(car)
		if blue != null:
			pace = minf(pace, blue_lift)
		ai.flag_pace = pace
		ai.flag_cap = cap
		ai.no_pass = no_pass
		ai.pass_exempt = exempt
		ai.blue_for = blue


## Tope de velocidad del auto `k` con el Safety Car en pista. El primero sigue el mismo perfil
## que el Safety Car pero en su propia posición (frena en las mismas curvas), con margen para
## acercarse hasta 'sc_follow' m.
func _sc_cap(k: int) -> float:
	var total := _traffic.lap_length()
	var to_sc := fposmod(sc_distance - _traffic.distance[k], total)
	var ahead := _traffic.nearest(k, true, 1000.0)
	var gap := _traffic.gap(k, ahead) if ahead >= 0 else INF
	if gap < 0.0:
		gap = INF
	var here := _sc_speed_at(_traffic.index[k])
	if to_sc <= gap and to_sc < 800.0:
		var room := to_sc - sc_follow
		if room >= 0.0:
			return sqrt(here * here + 2.0 * sc_brake * room)
		return maxf(here + room * 0.5, 0.0)
	if gap > sc_queue_gap:
		return here + sc_catchup
	return here + 3.0


## Cambios de orden entre dos autos que venían seguidos, con amarilla (en la zona) o con Safety
## Car. No cuenta si el pasado está lento o en boxes, si el que pasa está en boxes o si
## devuelve un lugar que le habían sacado.
func _check_passes() -> void:
	var order: Array[CarController] = []
	var by_car := {}
	for entry in _race.entries:
		if not entry["finished"] and is_instance_valid(entry["car"]) and _traffic.slot(entry["car"]) >= 0:
			order.append(entry["car"])
			by_car[entry["car"]] = entry
	order.sort_custom(func(a: CarController, b: CarController) -> bool:
		return float(by_car[a]["progress"]) > float(by_car[b]["progress"]))
	var flags := safety_car_active() or not yellow_zones.is_empty()
	if flags:
		for p in range(_prev_order.size() - 1):
			var ahead := _prev_order[p]
			var behind := _prev_order[p + 1]
			if not by_car.has(ahead) or not by_car.has(behind):
				continue
			if float(by_car[behind]["progress"]) <= float(by_car[ahead]["progress"]):
				continue
			_judge_pass(behind, ahead)
		if sc_state == SC_OUT or sc_state == SC_IN_LAP:
			_check_sc_pass(order)
	_prev_order = order


func _judge_pass(passer: CarController, passed: CarController) -> void:
	var key := "%d:%d" % [mini(passer.get_instance_id(), passed.get_instance_id()), maxi(passer.get_instance_id(), passed.get_instance_id())]
	if _passed.get(key) == passed:
		_passed.erase(key)
		return
	if bool(_slow_now.get(passed, false)) or _has_zone(passed) or (_pit != null and (_pit.in_lane(passed) or _pit.in_lane(passer))):
		return
	var kind := ""
	if safety_car_active():
		kind = "safety_car"
	elif in_yellow(_traffic.distance[_traffic.slot(passed)]):
		kind = "yellow"
	if kind.is_empty():
		return
	_passed[key] = passer
	if _penalized.has(key + kind):
		return
	_penalized[key + kind] = true
	_penalize(passer, passed, kind, pass_penalty)


## El auto que abrió una zona de amarilla (se lo puede pasar hasta que la zona se cierra).
func _has_zone(car: CarController) -> bool:
	for zone in yellow_zones:
		if zone["car"] == car:
			return true
	return false


## Pasar al Safety Car: el auto que lo tenía a menos de 60 m adelante y ahora lo tiene atrás.
func _check_sc_pass(order: Array[CarController]) -> void:
	var total := _traffic.lap_length()
	for car in order:
		var k := _traffic.slot(car)
		var to_sc := fposmod(sc_distance - _traffic.distance[k], total)
		var before := float(_sc_gap.get(car, -1.0))
		_sc_gap[car] = to_sc
		if before >= 0.0 and before < 60.0 and to_sc > total - 60.0 and not (_pit != null and _pit.in_lane(car)):
			_penalize(car, null, "sc_pass", pass_penalty)


func _penalize(guilty: CarController, victim: CarController, kind: String, seconds: float) -> void:
	penalties_by_kind[kind] = int(penalties_by_kind.get(kind, 0)) + 1
	_log("penalty_" + kind, RaceStewards.short_name(guilty))
	if _stewards != null:
		_stewards.flag_penalty(guilty, victim, kind, seconds)


func _update_player_flag() -> void:
	var flag := ""
	var k := _traffic.slot(_player)
	var entry := _race.entry_of(_player)
	if safety_car_active():
		flag = sc_state
	elif _blue_of.has(_player):
		flag = "blue"
	elif k >= 0 and not entry.is_empty() and not entry["finished"] and in_yellow(_traffic.distance[k]):
		flag = "yellow"
	elif _clock < _green_until:
		flag = "green"
	if flag != player_flag:
		player_flag = flag
		flag_changed.emit(flag)


func _end_all() -> void:
	sc_state = ""
	if _sc_node != null:
		_sc_node.visible = false
	_race.safety_car = false
	_race.pit_advance = 0
	_race.status_tag = ""
	yellow_zones.clear()
	_blue_of.clear()
	for entry in _race.entries:
		var ai: AiDriver = entry["ai"]
		if ai != null:
			ai.flag_pace = 1.0
			ai.flag_cap = INF
			ai.no_pass = false
			ai.blue_for = null
	_ai_flags_on = false
	if not player_flag.is_empty():
		player_flag = ""
		flag_changed.emit(player_flag)


func _say(key: String, values: Dictionary = {}, urgent: bool = false) -> void:
	if _radio != null:
		_radio.say(key, values, urgent)


func _log(event: String, who: String) -> void:
	history.append({"time": _clock, "event": event, "name": who})


## Velocidad del Safety Car en el índice i.
func _sc_speed_at(i: int) -> float:
	return minf(sc_speed, _line.target_speed[i] * sc_corner)


## Índice del centerline a `d` m de la meta (como RaceTraffic.distance).
func _index_at(d: float) -> int:
	var total := _traffic.lap_length()
	var start := _track.checkpoint_indices[0] if not _track.checkpoint_indices.is_empty() else _track.start_index()
	var target := fposmod(d + _line.distances[start], total)
	var i := _line.distances.bsearch(target) - 1
	return clampi(i, 0, _line.distances.size() - 1)


func _place_safety_car() -> void:
	var n := _line.distances.size()
	var i := _index_at(sc_distance)
	var j := (i + 1) % n
	var total := _traffic.lap_length()
	var start := _track.checkpoint_indices[0] if not _track.checkpoint_indices.is_empty() else _track.start_index()
	var here := fposmod(sc_distance + _line.distances[start], total)
	var span := fposmod(_line.distances[j] - _line.distances[i], total)
	var t := clampf((here - _line.distances[i]) / maxf(span, 0.01), 0.0, 1.0)
	var a := _track.edge_point(i, _line.offsets[i], 0.0)
	var b := _track.edge_point(j, _line.offsets[j], 0.0)
	var forward := b - a
	forward.y = 0.0
	if forward.length() < 0.01:
		forward = _track.flat_tangent(i)
	_sc_node.global_transform = Transform3D(Basis.looking_at(forward.normalized(), Vector3.UP), a.lerp(b, t))


## Safety Car armado con cajas: carrocería plateada, franja verde, cabina, ruedas, barra de luces
## naranja que titila y el cartel arriba.
func _build_safety_car() -> Node3D:
	var root := Node3D.new()
	root.name = "SafetyCar"
	root.visible = false
	var paint := StandardMaterial3D.new()
	paint.albedo_color = Color(0.72, 0.74, 0.78)
	paint.metallic = 0.8
	paint.roughness = 0.3
	var stripe := StandardMaterial3D.new()
	stripe.albedo_color = Color(0.0, 0.55, 0.45)
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.05, 0.06, 0.08)
	glass.roughness = 0.1
	var rubber := StandardMaterial3D.new()
	rubber.albedo_color = Color(0.04, 0.04, 0.04)
	_box(root, Vector3(1.9, 0.55, 4.6), Vector3(0, 0.5, 0), paint)
	_box(root, Vector3(1.92, 0.12, 4.62), Vector3(0, 0.55, 0), stripe)
	_box(root, Vector3(1.6, 0.5, 2.0), Vector3(0, 1.0, 0.35), glass)
	for k in 2:
		var light := StandardMaterial3D.new()
		light.albedo_color = Color(1.0, 0.55, 0.05)
		light.emission_enabled = true
		light.emission = Color(1.0, 0.5, 0.0)
		light.emission_energy_multiplier = 3.0
		_sc_lights.append(light)
		_box(root, Vector3(0.55, 0.12, 0.25), Vector3(-0.3 + 0.6 * k, 1.31, 0.4), light)
	for x in [-0.85, 0.85]:
		for z in [-1.45, 1.45]:
			var wheel := MeshInstance3D.new()
			var mesh := CylinderMesh.new()
			mesh.top_radius = 0.34
			mesh.bottom_radius = 0.34
			mesh.height = 0.3
			wheel.mesh = mesh
			wheel.material_override = rubber
			wheel.position = Vector3(x, 0.34, z)
			wheel.rotation = Vector3(0, 0, PI * 0.5)
			root.add_child(wheel)
	var sign := Label3D.new()
	sign.text = "SAFETY CAR"
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sign.font_size = 48
	sign.pixel_size = 0.006
	sign.outline_size = 12
	sign.modulate = Color(1.0, 0.75, 0.2)
	sign.position = Vector3(0, 2.1, 0)
	root.add_child(sign)
	return root


func _box(parent: Node3D, size: Vector3, at: Vector3, material: Material) -> void:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.material_override = material
	node.position = at
	parent.add_child(node)
