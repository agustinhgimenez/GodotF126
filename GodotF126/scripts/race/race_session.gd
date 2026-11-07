class_name RaceSession
extends Node
## Carrera con la grilla 2026 completa (Paso 47): el jugador y 21 autos de la IA.
## - Grilla: el puesto p (0 = pole) va `grid_distance` + p × `slot_gap` m detrás de la línea,
##   siguiendo el trazado, a `slot_side` m del centro (alterna de lado).
## - Largada: con `start()` (el semáforo se apaga) cada auto de la IA suelta el freno después de
##   su reacción (entre `reaction_min` y `reaction_max` s, con la semilla de la sesión).
## - Posiciones: metros recorridos desde la largada (con los de RaceTraffic, que cuentan desde la
##   meta) y vueltas. Distancia al líder = tiempo desde que el primero pasó por ese punto (marcas
##   cada `mark_step` m). Cuando el líder completa `laps` vueltas sale la bandera a cuadros y cada
##   auto termina al cruzar la meta.
## - Resultado: tiempo desde el apagado + penalizaciones (comisarios y largada en falso); los que
##   siguen en pista cierran su vuelta con su velocidad media (estimado).
## - Costo: los autos de la IA a más de `far_distance` m del jugador usan `substeps_far`
##   sub-pasos de neumáticos y los cercanos `substeps_near`.
## - Boxes (Paso 48): en carreras de `pit_min_laps` vueltas o más cada auto de la IA tiene una
##   parada planeada en una vuelta al azar dentro de `pit_window` (fracción de la carrera; semilla
##   de la sesión); con el alerón roto o un pinchazo entra en la próxima pasada (salvo en la
##   última vuelta). En la torre, los que están en la calle dicen "BOX".
## - Estrategia (Paso 49, con `strategy` y `prepare()`): en carreras de `strategy.min_laps`
##   vueltas o más, todos gastan los neumáticos `wear_scale` veces más rápido; cada auto de la IA
##   larga con el compuesto de su plan, para en la vuelta del plan con el segundo compuesto (o
##   antes, si su neumático pasa el límite) y rehace sus velocidades con el desgaste. Al terminar,
##   el que usó un solo compuesto suma `rule_penalty` s (señal `rule_broken`). Cada entrada
##   guarda los compuestos que usó ("compounds"); el plan del jugador queda en "plan".
## Bloque "race" de data/modes.json (grilla y torre) y de data/ai.json (ritmo, costo y boxes).

signal checkered_flag(leader: CarController)
signal car_finished(car: CarController, position: int)
signal rule_broken(car: CarController, seconds: float)

var grid_distance: float = 6.0
var slot_gap: float = 8.0
var slot_side: float = 2.0
var reaction_min: float = 0.18
var reaction_max: float = 0.45
var mark_step: float = 20.0
var tower_refresh: float = 0.25
var substeps_near: int = 4
var substeps_far: int = 2
var far_distance: float = 150.0
var lod_refresh: float = 0.5
var think_far: int = 2
var detail_size: float = 0.8
var detail_range: float = 60.0
var draw_range: float = 0.0
var pit_min_laps: int = 8
var pit_window := Vector2(0.35, 0.65)
## Paso 48: calle de boxes (null = sin boxes).
var pit_lane: PitLane
## Paso 49: estrategia (null = como en el Paso 48) y si esta carrera la usa.
var strategy: RaceStrategy
var strategy_on: bool = false

var laps: int = 3
var running: bool = false
## s desde el apagado del semáforo.
var clock: float = 0.0
var checkered: bool = false
## Un diccionario por auto: car, driver, team, ai (AiDriver o null), grid (0 = pole), quali (s),
## progress (m desde la meta, negativo en la grilla), lap (vueltas completas), last_lap,
## best_lap, finished, finish_time, reaction, extra_penalty, code (3 letras), pit_lap (vueltas
## completas con las que pide boxes, −1 sin parada planeada), compounds (ids usados), plan.
var entries: Array[Dictionary] = []
var player: CarController
var finish_order: Array[CarController] = []

var _traffic: RaceTraffic
var _stewards: RaceStewards
var _marks: Dictionary = {}
var _top_mark: int = 0
var _start_mark: int = 0
var _lod_timer: float = 0.0


func configure(race_data: Dictionary, ai_race_data: Dictionary, start_data: Dictionary = {}) -> void:
	grid_distance = float(start_data.get("grid_distance", grid_distance))
	slot_gap = maxf(float(race_data.get("slot_gap", slot_gap)), 6.5)
	slot_side = maxf(float(race_data.get("slot_side", slot_side)), 0.0)
	reaction_min = maxf(float(race_data.get("reaction_min", reaction_min)), 0.0)
	reaction_max = maxf(float(race_data.get("reaction_max", reaction_max)), reaction_min)
	mark_step = maxf(float(race_data.get("mark_step", mark_step)), 1.0)
	tower_refresh = maxf(float(race_data.get("tower_refresh", tower_refresh)), 0.05)
	substeps_near = clampi(int(ai_race_data.get("substeps_near", substeps_near)), 1, CarController.TYRE_SUBSTEPS)
	substeps_far = clampi(int(ai_race_data.get("substeps_far", substeps_far)), 1, CarController.TYRE_SUBSTEPS)
	far_distance = maxf(float(ai_race_data.get("far_distance", far_distance)), 0.0)
	lod_refresh = maxf(float(ai_race_data.get("lod_refresh", lod_refresh)), 0.05)
	think_far = clampi(int(ai_race_data.get("think_far", think_far)), 1, 4)
	detail_size = maxf(float(ai_race_data.get("detail_size", detail_size)), 0.0)
	detail_range = maxf(float(ai_race_data.get("detail_range", detail_range)), 0.0)
	draw_range = maxf(float(ai_race_data.get("draw_range", draw_range)), 0.0)
	pit_min_laps = maxi(int(ai_race_data.get("pit_min_laps", pit_min_laps)), 2)
	var window = ai_race_data.get("pit_window", [])
	if window is Array and window.size() >= 2:
		pit_window = Vector2(clampf(float(window[0]), 0.0, 1.0), clampf(float(window[1]), 0.0, 1.0))


func setup(traffic: RaceTraffic, stewards: RaceStewards, lap_count: int) -> void:
	_traffic = traffic
	_stewards = stewards
	laps = maxi(lap_count, 1)


## Metros detrás de la línea y lateral (+ derecha) del puesto p de la grilla.
func slot_place(p: int) -> Vector2:
	return Vector2(grid_distance + p * slot_gap, slot_side * (1.0 if p % 2 == 0 else -1.0))


func add_entry(car: CarController, driver: Dictionary, team: Dictionary, ai: AiDriver, grid: int,
		quali_time: float) -> Dictionary:
	var entry := {
		"car": car, "driver": driver, "team": team, "ai": ai, "grid": grid, "quali": quali_time,
		"progress": 0.0, "last": 0.0, "start_progress": 0.0, "lap": 0, "lap_start": 0.0,
		"last_lap": -1.0, "best_lap": -1.0, "finished": false, "finish_time": -1.0,
		"reaction": 0.0, "extra_penalty": 0.0, "code": code_of(str(driver.get("name", "?"))),
		"pit_lap": -1, "compounds": [car.compound_id()], "plan": {},
	}
	entries.append(entry)
	if ai != null:
		car.controls_enabled = false
		_apply_visual_lod(car)
	return entry


func entry_of(car: CarController) -> Dictionary:
	for entry in entries:
		if entry["car"] == car:
			return entry
	return {}


## Semáforo apagado: arranca el reloj; los de la IA largan después de su reacción.
func start(seed_value: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([seed_value, "reaction"])
	var total := _traffic.lap_length()
	var top := -INF
	for entry in entries:
		var k := _traffic.slot(entry["car"])
		var d := _traffic.distance[k] if k >= 0 else 0.0
		entry["last"] = d
		entry["progress"] = fposmod(d + total * 0.5, total) - total * 0.5
		entry["start_progress"] = entry["progress"]
		entry["reaction"] = rng.randf_range(reaction_min, reaction_max) if entry["ai"] != null else 0.0
		top = maxf(top, entry["progress"])
	_marks.clear()
	_top_mark = floori(top / mark_step)
	_start_mark = _top_mark
	for b in range(floori(-total * 0.5 / mark_step), _top_mark + 1):
		_marks[b] = 0.0
	clock = 0.0
	running = true
	if strategy == null:
		_plan_pits(seed_value)


## Paso 49: con todos en la grilla, antes del semáforo. Con estrategia: desgaste de carrera, el
## plan de cada uno (la IA con el compuesto de largada de su plan, al azar con la semilla entre
## los buenos; el jugador, el mejor con el compuesto que eligió) y el segundo compuesto para su
## parada. Sin estrategia, como en el Paso 48.
func prepare(seed_value: int, race_strategy: RaceStrategy) -> void:
	strategy = race_strategy
	strategy_on = strategy != null and strategy.applies(laps)
	if strategy == null:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([seed_value, "strategy"])
	for entry in entries:
		var car: CarController = entry["car"]
		var ai: AiDriver = entry["ai"]
		entry["pit_lap"] = -1
		entry["plan"] = {}
		if not strategy_on:
			car.tyres.wear_scale = 1.0
			continue
		car.tyres.wear_scale = strategy.wear_scale
		var plan := strategy.choose(laps, rng) if ai != null else strategy.choose(laps, null, car.compound_id())
		if plan.is_empty():
			continue
		entry["plan"] = plan
		if ai != null:
			car.fit_tyres(str(plan["first"]))
			ai.wear_aware = true
			ai.refresh_speeds()
			entry["pit_lap"] = int(plan["stint"]) - 1
		entry["compounds"] = [car.compound_id()]
		if pit_lane != null:
			pit_lane.set_next_compound(car, str(plan["second"]))


## Paso 49: después de cada parada (PitLane.stop_finished, lo llama Main), el compuesto nuevo
## cuenta para la regla y la IA rehace sus velocidades (compuesto nuevo, sin desgaste).
func on_stop_finished(car: CarController) -> void:
	var entry := entry_of(car)
	if entry.is_empty():
		return
	(entry["compounds"] as Array).append(car.compound_id())
	if entry["ai"] != null:
		(entry["ai"] as AiDriver).refresh_speeds()


## Índice del centerline donde está `car` (0 si no está en el tráfico).
func track_index(car: CarController) -> int:
	var k := _traffic.slot(car) if _traffic != null else -1
	return _traffic.index[k] if k >= 0 else 0


## Vueltas que le faltan (contando la que está corriendo).
func remaining_laps(entry: Dictionary) -> int:
	return maxi(laps - int(entry["lap"]), 0)


## Vuelta de la parada planeada de cada auto de la IA (−1 = sin parada planeada).
func _plan_pits(seed_value: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([seed_value, "pits"])
	for entry in entries:
		entry["pit_lap"] = -1
		if entry["ai"] == null or laps < pit_min_laps:
			continue
		var first := clampi(floori(laps * pit_window.x), 1, laps - 1)
		var last := clampi(ceili(laps * pit_window.y), first, laps - 1)
		entry["pit_lap"] = rng.randi_range(first, last)


## Pide boxes a los de la IA que llegaron a su vuelta de parada o tienen el alerón roto o un
## pinchazo (no en la última vuelta).
func _check_pits() -> void:
	if pit_lane == null or not pit_lane.enabled():
		return
	for entry in entries:
		var ai: AiDriver = entry["ai"]
		var car: CarController = entry["car"]
		if ai == null or not is_instance_valid(car) or entry["finished"] or ai.pit_requested or ai.pitting:
			continue
		if int(entry["lap"]) >= laps - 1:
			continue
		var planned := int(entry["pit_lap"]) >= 0 and int(entry["lap"]) >= int(entry["pit_lap"]) \
			and pit_lane.stops_of(car) == 0
		var damaged := car.damage.is_wing_broken() or car.damage.punctures.has(true)
		var worn := strategy_on and strategy.worn_out(car.max_tyre_wear(), remaining_laps(entry))
		if planned or damaged or worn:
			ai.pit_requested = true
			if strategy_on and not (planned and not entry["plan"].is_empty()):
				pit_lane.set_next_compound(car, strategy.next_compound(remaining_laps(entry) - 1,
					entry["compounds"], true))


func _physics_process(delta: float) -> void:
	if not running or _traffic == null:
		return
	clock += delta
	var total := _traffic.lap_length()
	for entry in entries:
		var car: CarController = entry["car"]
		if not is_instance_valid(car):
			continue
		if entry["ai"] != null and not car.controls_enabled and not entry["finished"] and clock >= entry["reaction"]:
			car.controls_enabled = true
		var k := _traffic.slot(car)
		if k < 0:
			continue
		var d := _traffic.distance[k]
		entry["progress"] += fposmod(d - float(entry["last"]) + total * 0.5, total) - total * 0.5
		entry["last"] = d
		if entry["finished"]:
			continue
		_mark(entry["progress"])
		while not entry["finished"] and entry["progress"] >= (int(entry["lap"]) + 1) * total:
			_complete_lap(entry)
	_lod_timer -= delta
	if _lod_timer <= 0.0:
		_lod_timer = lod_refresh
		_update_lod()
		_check_pits()


func _mark(progress: float) -> void:
	var b := floori(progress / mark_step)
	while _top_mark < b:
		_top_mark += 1
		_marks[_top_mark] = clock


func _complete_lap(entry: Dictionary) -> void:
	entry["lap"] = int(entry["lap"]) + 1
	var time := clock - float(entry["lap_start"])
	entry["lap_start"] = clock
	entry["last_lap"] = time
	if float(entry["best_lap"]) < 0.0 or time < float(entry["best_lap"]):
		entry["best_lap"] = time
	if int(entry["lap"]) >= laps or checkered:
		finish(entry["car"])


## El cronómetro del jugador cerró la carrera al cruzar la meta: el área de la meta lo toca
## antes de que su centro pase la línea, así que esa vuelta se cuenta acá.
func cross_line(car: CarController) -> void:
	var entry := entry_of(car)
	if entry.is_empty() or entry["finished"]:
		return
	if float(entry["progress"]) > (int(entry["lap"]) + 1) * _traffic.lap_length() - 50.0:
		_complete_lap(entry)
	finish(car)


## Termina la carrera de `car` (cruzó la meta con la bandera a cuadros). La primera vez sale
## la bandera.
func finish(car: CarController) -> void:
	var entry := entry_of(car)
	if entry.is_empty() or entry["finished"]:
		return
	entry["finished"] = true
	entry["finish_time"] = clock
	if strategy_on and not RaceStrategy.rule_met(entry["compounds"]):
		entry["extra_penalty"] = float(entry["extra_penalty"]) + strategy.rule_penalty
		rule_broken.emit(car, strategy.rule_penalty)
	finish_order.append(car)
	if not checkered:
		checkered = true
		checkered_flag.emit(car)
	car_finished.emit(car, position_of(car))


func _update_lod() -> void:
	if player == null or not is_instance_valid(player):
		return
	for entry in entries:
		var car: CarController = entry["car"]
		var ai: AiDriver = entry["ai"]
		if ai != null and is_instance_valid(car):
			var near := car.global_position.distance_to(player.global_position) < far_distance
			car.tyre_substeps = substeps_near if near else substeps_far
			ai.think_every = 1 if near else think_far


## Autos de la IA: las piezas chicas (menos de `detail_size` m) se dejan de dibujar a más de
## `detail_range` m de la cámara, y el auto entero a más de `draw_range` (0 = siempre).
func _apply_visual_lod(node: Node) -> void:
	for child in node.get_children():
		if child is GeometryInstance3D:
			var geometry := child as GeometryInstance3D
			var aabb := geometry.get_aabb()
			var small := aabb.size.length() < detail_size
			var range_end := detail_range if small else draw_range
			if range_end > 0.0:
				geometry.visibility_range_end = range_end
		if not child is SubViewport:
			_apply_visual_lod(child)


func penalty_of(entry: Dictionary) -> float:
	var stewards := _stewards.penalty_of(entry["car"]) if _stewards != null else 0.0
	return stewards + float(entry["extra_penalty"])


## Orden de carrera: los que terminaron por vueltas y llegada; los demás por metros recorridos.
func standings() -> Array[Dictionary]:
	var list: Array[Dictionary] = entries.duplicate()
	var total := _traffic.lap_length() if _traffic != null else 1.0
	list.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a["finished"] and b["finished"]:
			if a["lap"] != b["lap"]:
				return a["lap"] > b["lap"]
			return a["finish_time"] < b["finish_time"]
		var pa: float = int(a["lap"]) * total if a["finished"] else float(a["progress"])
		var pb: float = int(b["lap"]) * total if b["finished"] else float(b["progress"])
		if pa != pb:
			return pa > pb
		if a["finished"] != b["finished"]:
			return a["finished"]
		return a["grid"] < b["grid"])
	return list


func position_of(car: CarController) -> int:
	var list := standings()
	for i in list.size():
		if list[i]["car"] == car:
			return i + 1
	return 0


## Segundos detrás del líder (los que terminaron, contra la llegada del líder).
func gap_to_leader(entry: Dictionary, leader: Dictionary) -> float:
	if entry == leader:
		return 0.0
	if entry["finished"] and leader["finished"]:
		return float(entry["finish_time"]) - float(leader["finish_time"])
	var progress := float(entry["progress"])
	if entry["finished"]:
		progress = int(entry["lap"]) * _traffic.lap_length()
	var b := floori(progress / mark_step)
	if b > _start_mark:
		return maxf(clock - float(_marks.get(b, clock)), 0.0)
	# Todavía detrás de donde largó el líder: distancia a su velocidad media.
	var lead := float(leader["progress"])
	var average := maxf((lead - float(leader["start_progress"])) / maxf(clock, 0.1), 10.0)
	return maxf((lead - progress) / average, 0.0)


## Vueltas enteras que le sacó el líder.
func laps_behind(entry: Dictionary, leader: Dictionary) -> int:
	var total := _traffic.lap_length()
	var lead := int(leader["lap"]) * total if leader["finished"] else float(leader["progress"])
	var own := int(entry["lap"]) * total if entry["finished"] else float(entry["progress"])
	return floori((lead - own) / total)


## Filas de la torre de tiempos: {pos, code, color, gap, penalty, player, finished, tyre
## (letra del compuesto), tyre_color}.
func tower_rows() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var list := standings()
	if list.is_empty():
		return rows
	var leader := list[0]
	for i in list.size():
		var entry := list[i]
		var text := ""
		if i == 0:
			text = "Vuelta %d/%d" % [mini(int(entry["lap"]) + (0 if entry["finished"] else 1), laps), laps] if running else "Pole"
		elif not running:
			text = ""
		elif pit_lane != null and pit_lane.in_lane(entry["car"]) and not entry["finished"]:
			text = "BOX"
		else:
			var down := laps_behind(entry, leader)
			if down >= 1 and not (entry["finished"] and leader["finished"] and entry["lap"] == leader["lap"]):
				text = "+%d %s" % [down, "vuelta" if down == 1 else "vueltas"]
			else:
				text = "+%.1f" % gap_to_leader(entry, leader)
		var car: CarController = entry["car"]
		var compound: Dictionary = car.tyres.compound() if is_instance_valid(car) else {}
		rows.append({"pos": i + 1, "code": entry["code"], "color": DataLoader.team_primary(entry["team"]),
			"gap": text, "penalty": penalty_of(entry), "player": car == player,
			"finished": entry["finished"], "tyre": str(compound.get("short", "")),
			"tyre_color": Color.from_string(str(compound.get("color", "#FFFFFF")), Color.WHITE)})
	return rows


## Resultado final: {entry, laps, time, penalty, total, estimated}, ordenado por vueltas y total.
## Los que siguen en pista completan su vuelta con su velocidad media desde la largada.
func classification() -> Array[Dictionary]:
	var total := _traffic.lap_length()
	var rows: Array[Dictionary] = []
	for entry in entries:
		var row := {"entry": entry, "penalty": penalty_of(entry), "estimated": false}
		if entry["finished"]:
			row["laps"] = int(entry["lap"])
			row["time"] = float(entry["finish_time"])
		else:
			var progress := float(entry["progress"])
			var target := (int(entry["lap"]) + 1) * total
			var average := maxf((progress - float(entry["start_progress"])) / maxf(clock, 0.1), 10.0)
			row["laps"] = int(entry["lap"]) + 1
			row["time"] = clock + (target - progress) / average
			row["estimated"] = true
		row["total"] = float(row["time"]) + float(row["penalty"])
		rows.append(row)
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a["laps"] != b["laps"]:
			return a["laps"] > b["laps"]
		return a["total"] < b["total"])
	return rows


## Código de 3 letras del apellido (como en la TV).
static func code_of(full_name: String) -> String:
	var parts := full_name.split(" ", false)
	return (parts[parts.size() - 1] if not parts.is_empty() else "?").left(3).to_upper()


## Ritmo del piloto `id` con el nivel `level`: el del nivel + skill × pace_step (hasta 1).
static func driver_pace(id: String, level: String, ai_data: Dictionary) -> float:
	var level_data = ai_data.get("levels", {}).get(level, {})
	var pace := float(level_data.get("pace", 1.0)) if level_data is Dictionary else 1.0
	var race_data = ai_data.get("race", {})
	if race_data is Dictionary:
		var skill := float(race_data.get("skill", {}).get(id, 0.0))
		pace += skill * float(race_data.get("pace_step", 0.0))
	return clampf(pace, 0.5, 1.0)


## Vuelta lanzada estimada para un ritmo: interpola (o extrapola) el "lap_time" de los niveles.
static func estimate_lap(pace: float, levels: Dictionary) -> float:
	var points: Array[Vector2] = []
	for id in levels:
		var data = levels[id]
		if data is Dictionary and data.has("lap_time"):
			points.append(Vector2(float(data.get("pace", 1.0)), float(data["lap_time"])))
	if points.is_empty():
		return -1.0
	if points.size() == 1:
		return points[0].y
	points.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x)
	var i := 0
	while i < points.size() - 2 and pace > points[i + 1].x:
		i += 1
	var a := points[i]
	var b := points[i + 1]
	return lerpf(a.y, b.y, (pace - a.x) / maxf(b.x - a.x, 0.0001))


## Clasificación: la IA con su vuelta estimada ± `quali_spread` s (semilla `seed_value`; el ruido
## no depende de qué piloto maneja el jugador) y el jugador con `player_time` (−1 = sin tiempo,
## al fondo). Devuelve {driver, team, time, pace, player} de la pole al último.
static func qualifying(grid: Dictionary, player_id: String, player_time: float, level: String,
		ai_data: Dictionary, seed_value: int) -> Array[Dictionary]:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([seed_value, "qualifying"])
	var spread := float(ai_data.get("race", {}).get("quali_spread", 0.0))
	var levels: Dictionary = ai_data.get("levels", {})
	var list: Array[Dictionary] = []
	for team in grid.get("teams", []):
		for driver in team.get("drivers", []):
			var id := str(driver.get("id", ""))
			var noise := rng.randf_range(-spread, spread)
			if id == player_id:
				list.append({"driver": driver, "team": team, "time": player_time, "pace": -1.0, "player": true})
				continue
			var pace := driver_pace(id, level, ai_data)
			list.append({"driver": driver, "team": team, "time": estimate_lap(pace, levels) + noise,
				"pace": pace, "player": false})
	list.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var ta := float(a["time"])
		var tb := float(b["time"])
		if (ta < 0.0) != (tb < 0.0):
			return tb < 0.0
		return ta < tb)
	return list
