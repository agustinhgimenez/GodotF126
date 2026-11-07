class_name EngineerRadio
extends Node
## Radio del ingeniero en carrera (Paso 49): mensajes cortos para el jugador con los textos de
## "radio" en data/strategy.json. Habla a lo sumo cada `min_gap` s (los demás esperan en cola,
## salvo los repetidos) y cada mensaje queda `show_time` s en el HUD (señal `spoke`).
## - En la grilla: el plan (vuelta y compuesto de la parada) o que la carrera es corta.
## - Cada vuelta: posición y distancia con el de adelante y el de atrás; la última vuelta.
## - Box: en la vuelta de la parada del plan, con el neumático gastado, el alerón roto o un
##   pinchazo, o si todavía no usó dos compuestos y quedan pocas vueltas; se repite
##   `box_call_distance` m antes de la entrada.
## - Desgaste: al pasar cada valor de `wear_calls` y al llegar al límite de la estrategia.
## - Al salir de boxes, neumáticos fríos; cuando entra a boxes el de adelante o el de atrás.
## Paso 50: RaceControl agrega sus textos (`extra_texts`) y habla con `urgent` (pasa primero en
## la cola); con Safety Car, "parada barata" hasta `RaceSession.pit_advance` vueltas antes.

signal spoke(text: String, seconds: float)

var min_gap: float = 6.0
var show_time: float = 5.0
var wear_calls: Array[float] = [0.3, 0.5]
var box_call_distance: float = 900.0
## Mensajes dichos (para las pruebas): {time, key, text}.
var history: Array[Dictionary] = []
## Paso 50: textos de otros (clave → texto con {valores}); tienen prioridad sobre los de la estrategia.
var extra_texts: Dictionary = {}

var _strategy: RaceStrategy
var _race: RaceSession
var _pit: PitLane
var _track: BakuTrack
var _car: CarController
var _queue: Array[Dictionary] = []
var _clock: float = 0.0
var _last_spoke: float = -INF
var _last_lap: int = 0
var _wear_index: int = 0
var _worn_called: bool = false
var _box_lap: int = -1
var _reminder_lap: int = -1
var _rule_lap: int = -1
var _last_offset: float = 0.0
var _served_in_lane: bool = false


func setup(strategy: RaceStrategy, race: RaceSession, pit: PitLane, track: BakuTrack, car: CarController) -> void:
	_strategy = strategy
	_race = race
	_pit = pit
	_track = track
	_car = car
	var data := strategy.radio
	min_gap = maxf(float(data.get("min_gap", min_gap)), 0.0)
	show_time = maxf(float(data.get("show_time", show_time)), 0.5)
	box_call_distance = maxf(float(data.get("box_call_distance", box_call_distance)), 0.0)
	var calls = data.get("wear_calls", [])
	if calls is Array:
		wear_calls.clear()
		for value in calls:
			wear_calls.append(float(value))
		wear_calls.sort()
	if pit != null:
		pit.entered.connect(_on_pit_entered)
		pit.exited.connect(_on_pit_exited)
		pit.stop_finished.connect(func(who: CarController, _wing: bool) -> void:
			if who == _car:
				_served_in_lane = true)
	car.damage.wing_damaged.connect(func(_health: float) -> void:
		if car.damage.is_wing_broken():
			_call_box("box_damage"))
	car.damage.punctured.connect(func(_index: int) -> void: _call_box("box_puncture"))


## En la grilla: el plan de la carrera.
func begin() -> void:
	var entry := _entry()
	if _race.strategy_on and not entry.is_empty() and not (entry["plan"] as Dictionary).is_empty():
		var plan: Dictionary = entry["plan"]
		say("plan", {"lap": int(plan["stint"]), "compound": _compound_text(_pit.next_compound(_car))})
		say("rule")
	else:
		say("short_race")


## Encola el texto `key` (no lo repite si ya está en la cola); `urgent` lo pone primero.
func say(key: String, values: Dictionary = {}, urgent: bool = false) -> void:
	var text := str(extra_texts[key]).format(values) if extra_texts.has(key) else _strategy.radio_text(key, values)
	if text.is_empty():
		return
	for item in _queue:
		if item["key"] == key:
			item["text"] = text
			return
	if urgent:
		_queue.push_front({"key": key, "text": text})
	else:
		_queue.append({"key": key, "text": text})


## Paso 50: avisa ya si hay motivo para entrar (lo usa RaceControl al salir el Safety Car).
func check_box() -> void:
	var entry := _entry()
	if entry.is_empty() or entry["finished"]:
		return
	var reason := box_reason(entry)
	if not reason.is_empty():
		_box_lap = int(entry["lap"])
		say(reason, {"compound": _compound_text(_pit.next_compound(_car)), "laps": _race.remaining_laps(entry)}, true)


func _process(delta: float) -> void:
	_clock += delta
	if _race != null and _race.running and is_instance_valid(_car):
		_watch()
	if not _queue.is_empty() and _clock - _last_spoke >= min_gap:
		var item: Dictionary = _queue.pop_front()
		_last_spoke = _clock
		history.append({"time": _clock, "key": item["key"], "text": item["text"]})
		spoke.emit(str(item["text"]), show_time)


func _watch() -> void:
	var entry := _entry()
	if entry.is_empty() or entry["finished"]:
		return
	var lap := int(entry["lap"])
	if lap != _last_lap:
		_last_lap = lap
		_on_new_lap(entry, lap)
	var wear := _car.max_tyre_wear()
	if _wear_index < wear_calls.size() and wear >= wear_calls[_wear_index]:
		_wear_index += 1
		say("wear", {"wear": roundi(wear * 100.0)})
	if _race.strategy_on and not _worn_called and wear >= _strategy.wear_limit:
		_worn_called = true
		say("worn", {"wear": roundi(wear * 100.0)})
	var s := _track.start_offset(_race.track_index(_car))
	var mark := _pit.entry - box_call_distance if _pit != null else 0.0
	if _last_offset < mark and s >= mark and s - _last_offset < 100.0 and _reminder_lap != lap:
		var reason := box_reason(entry)
		if not reason.is_empty():
			_reminder_lap = lap
			say(reason, {"compound": _compound_text(_pit.next_compound(_car)), "laps": _race.remaining_laps(entry)})
	_last_offset = s


func _on_new_lap(entry: Dictionary, lap: int) -> void:
	var remaining := _race.remaining_laps(entry)
	if remaining == 1:
		say("last_lap")
	elif lap >= 1:
		_say_gaps()
	var reason := box_reason(entry)
	if not reason.is_empty() and _box_lap != lap:
		_box_lap = lap
		say(reason, {"compound": _compound_text(_pit.next_compound(_car)), "laps": remaining})


## Motivo para entrar a boxes en esta vuelta ("" = ninguno): clave del texto de la radio.
func box_reason(entry: Dictionary) -> String:
	if _pit == null or not _pit.enabled() or _race.remaining_laps(entry) <= 1 or _pit.in_lane(_car):
		return ""
	if _car.damage.is_wing_broken():
		return "box_damage"
	if _car.damage.punctures.has(true):
		return "box_puncture"
	if not _race.strategy_on:
		return ""
	var plan: Dictionary = entry["plan"]
	if _pit.stops_of(_car) == 0 and not plan.is_empty() and int(entry["lap"]) >= int(plan["stint"]) - 1:
		return "box"
	if _race.safety_car and _pit.stops_of(_car) == 0 and not plan.is_empty() \
			and int(entry["lap"]) >= int(plan["stint"]) - 1 - _race.pit_advance:
		return "box_sc"
	if _strategy.worn_out(_car.max_tyre_wear(), _race.remaining_laps(entry)):
		return "box"
	if not RaceStrategy.rule_met(entry["compounds"]) and _race.remaining_laps(entry) <= 3:
		return "rule_late"
	return ""


func _call_box(key: String) -> void:
	var entry := _entry()
	if entry.is_empty() or entry["finished"] or _race.remaining_laps(entry) <= 1:
		return
	say(key)


func _say_gaps() -> void:
	var list := _race.standings()
	var p := -1
	for i in list.size():
		if list[i]["car"] == _car:
			p = i
	if p < 0 or list.size() < 2:
		return
	var leader := list[0]
	var mine := _race.gap_to_leader(list[p], leader)
	var values := {"pos": p + 1}
	if p > 0:
		values["ahead"] = RaceStewards.short_name(list[p - 1]["car"])
		values["gap_ahead"] = _seconds(mine - _race.gap_to_leader(list[p - 1], leader))
	if p < list.size() - 1:
		values["behind"] = RaceStewards.short_name(list[p + 1]["car"])
		values["gap_behind"] = _seconds(_race.gap_to_leader(list[p + 1], leader) - mine)
	say("gaps_leader" if p == 0 else ("gaps_last" if p == list.size() - 1 else "gaps"), values)


func _on_pit_entered(who: CarController) -> void:
	if who == _car or not _race.running:
		return
	var list := _race.standings()
	for i in list.size():
		if list[i]["car"] != _car:
			continue
		if (i > 0 and list[i - 1]["car"] == who) or (i < list.size() - 1 and list[i + 1]["car"] == who):
			say("rival_pit", {"name": RaceStewards.short_name(who)})
		return


func _on_pit_exited(who: CarController) -> void:
	if who == _car and _served_in_lane:
		_served_in_lane = false
		say("cold")


func _entry() -> Dictionary:
	return _race.entry_of(_car) if _race != null else {}


func _compound_text(id: String) -> String:
	return _strategy.compound_name(id).to_lower()


static func _seconds(s: float) -> String:
	return ("%.1f" % maxf(s, 0.0)).replace(".", ",")
