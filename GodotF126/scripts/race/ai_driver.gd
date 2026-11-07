class_name AiDriver
extends Node
## Piloto de la IA (Paso 44): maneja un CarController con `ai_controlled` siguiendo la línea de
## trazada (RacingLine). Dirección: apunta a un punto de la línea `lookahead_min` m o
## `lookahead_time` s adelante (lo que sea más). Velocidad: la objetivo de la línea (curvatura
## con el agarre del auto y la frenada hacia atrás) un poco más adelante, con pedales
## proporcionales al error; `pace` (0,5–1) baja la velocidad en curvas y frenadas (no en las
## rectas). Cuenta vueltas, tiempos, salidas de pista y golpes, y si queda trabado o de
## contramano vuelve a la línea. Bloque "driver" de data/ai.json.
## Paso 45: niveles (bloque "levels": ritmo, errores al azar por curva con semilla fija, ganas de
## pasar y si defiende) y tráfico (RaceTraffic): no se le acerca de atrás al auto que tiene en
## su carril a menos de `follow_gap` m; si el de adelante es más lento se corre al costado
## (mejor por adentro de la próxima curva, nunca por afuera si todavía no está al lado) y vuelve
## a la línea al pasarlo; con alguien al lado le deja `lane_clear` m; con un auto a menos de
## `defend_time` s atrás hace una sola defensa por recta hacia el lado de adentro.
## Paso 48: con `pit_requested` entra a boxes en la próxima pasada por la calle (PitLane): sigue
## el camino de la calle a la velocidad del limitador, se para en la caja de su equipo y vuelve
## a la línea; mientras tanto no pasa, no defiende y no cuenta como trabado ni afuera.
## Paso 49: con `wear_aware` baja sus velocidades objetivo a medida que gasta los neumáticos.
## Paso 50: banderas (los campos los escribe RaceControl): `flag_pace` multiplica su objetivo
## (amarilla, azul), `flag_cap` lo limita (Safety Car), con `no_pass` no empieza ni sigue una
## pasada salvo sobre los autos de `pass_exempt`, y con `blue_for` (el que lo dobla) no defiende.

signal lap_completed(lap: int, time: float)

const LEVELS := ["easy", "medium", "hard", "expert"]

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

## Nivel: cada vuelta cada curva sale con un factor al azar entre 1 − mistake y 1 + mistake / 4
## sobre la velocidad objetivo (semilla `seed_value` + vuelta). Intenta pasar si en el lugar del
## de adelante iría `pass_margin` m/s más rápido que él.
var level: String = "expert"
var mistake: float = 0.0
var pass_margin: float = 1.0
var defend: bool = true
var seed_value: int = 0

## Tráfico: mira al de adelante a menos de `overtake_range` m. Si está en su carril (a menos de
## un ancho de auto + 0,4 m de costado de donde va a pasar él por ese punto) no se le acerca a
## menos de `follow_gap` m + `follow_time` s: con más lugar, la velocidad desde la que frenaría
## hasta la del otro con `follow_decel` m/s² en ese lugar; con menos, la del otro − lo que falta ×
## `follow_gain`. Ganas de pasar = cuánto más rápido doblaría él donde está el de adelante,
## mientras el otro frena o dobla (promedio de ~2 s). Para pasar
## se pone a `lane_clear` m de costado del otro, con el centro a no menos de `edge_margin` m de la
## línea blanca, moviéndose `lane_rate` m/s de costado; fuera de la línea en curvas va al
## `off_line_pace` de la objetivo. Si abandona, espera `pass_cooldown` s. El que está siendo
## pasado y ya tiene al otro al lado le cede: no pasa de la velocidad del otro − `yield_margin`.
## Mientras no está al lado, cuenta que el otro va a seguir su línea los próximos
## `follow_predict` s. Pasando por adentro, frena `pass_brake_bonus` más tarde (objetivo × factor
## en la frenada, no en la curva). Tirándose por adentro a menos de `dive_gap` m de otro auto de
## la IA sigue aunque empiece la curva: el otro le deja lugar.
var overtake_range: float = 60.0
var follow_gap: float = 8.0
var follow_time: float = 0.1
var follow_decel: float = 10.0
var follow_gain: float = 1.0
var lane_clear: float = 2.6
var edge_margin: float = 1.2
var lane_rate: float = 1.5
var off_line_pace: float = 0.97
var pass_cooldown: float = 2.0
var yield_margin: float = 1.5
var follow_predict: float = 0.8
var pass_brake_bonus: float = 1.04
var dive_gap: float = 14.0
## Con el volante a tope y a más de 0,5 m de donde quiere ir (a 8 m/s o más): objetivo =
## velocidad − esto, hasta que vuelve a doblar.
var understeer_lift: float = 2.5
## Con otro auto adelante superpuesto (o a menos de 3 m) que ahora o en `squeeze_time` s (con
## las velocidades de costado) queda a menos de 0,6 m de costado, no pasa de su velocidad − esto.
var squeeze_margin: float = 5.0
var squeeze_time: float = 0.4
## Paso 46: metros que mira adelante la velocidad de curva de su carril (0 = no la mira).
var lane_look: float = 40.0
## Paso 47: cuántos autos adelante mira para no acercarse de atrás.
var follow_count: int = 3
## Paso 47: m/s debajo de los cuales sólo sigue al que ya está en su carril (largada).
var start_follow_speed: float = 8.0
## Paso 47: deja su fila de la largada a `hold_release_time` s de la primera frenada.
var hold_release_time: float = 2.5
## La maniobra empieza en recta, con el de adelante a menos de `pass_start_gap` m y la frenada
## a menos de `pass_start_time` s (hasta ahí aprovecha el rebufo).
var pass_start_gap: float = 30.0
var pass_start_time: float = 2.5
var defend_time: float = 1.0
## Paso 47: decide cada tantos cuadros de física (los autos lejos del jugador, 2) y mientras
## tanto mantiene los pedales y el volante.
var think_every: int = 1

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
## Toques con otros autos (Paso 46; los golpes contra muros no los cuentan).
var car_hits: int = 0
var recoveries: int = 0
var max_lateral: float = 0.0

## Tráfico: autos en pista (null = maneja solo, como en el Paso 44).
var traffic: RaceTraffic
## Paso 48: calle de boxes (null = sin boxes), si pidió entrar y si está en el camino de boxes
## (desde `PitLane.ai_approach` m antes de la entrada hasta `ai_merge` m después de la salida).
var pit_lane: PitLane
var pit_requested: bool = false
var pitting: bool = false
## Paso 49: en carreras con estrategia rehace sus velocidades objetivo en cada vuelta con el
## agarre que perdieron los neumáticos (RacingLine.speeds_for con desgaste).
var wear_aware: bool = false
## Paso 50: banderas (ver arriba).
var flag_pace: float = 1.0
var flag_cap: float = INF
var no_pass: bool = false
var pass_exempt: Array[CarController] = []
var blue_for: CarController = null
## Carril propio (para pasar o defender): lateral absoluto al que apunta (+ derecha), hacia
## dónde se mueve y cuánto pesa contra la línea (1 = va por el carril; al terminar baja a 0 en
## ~1,5 s y vuelve a la línea). `shift` = cuánto se aparta de la línea donde está el auto.
var lane_now: float = 0.0
var lane_goal: float = 0.0
var lane_weight: float = 0.0
var shift: float = 0.0
## Paso 47: en la largada sigue por su fila de la grilla hasta la primera frenada.
var _holding: bool = false
var _hold_lateral: float = 0.0
## Auto que está intentando pasar (null si ninguno) y de qué lado (−1 izq., +1 der.).
var passing: CarController = null
var pass_side: float = 0.0
var passes: int = 0
var aborted_passes: int = 0
var defences: int = 0
## s que pasó frenado por el auto de adelante (velocidad limitada por debajo de la objetivo).
var held_time: float = 0.0

var car: CarController
var _track: BakuTrack
var _line: RacingLine
## Velocidad objetivo por índice y máxima con el setup y el compuesto de su auto.
var _speeds: PackedFloat32Array = PackedFloat32Array()
var _top: float = 0.0
var _start: int = 0
var _total: float = 0.0
var _last_lap_distance: float = -1.0
var _off: bool = false
var _window: float = 0.0
var _window_start: float = 0.0
var _wrong_for: float = 0.0
var _slot: int = -1
var _ahead_car: CarController = null
var _deficit: float = 0.0
var _cooldown: float = 0.0
var _defending: bool = false
var _defended: bool = false
var _defend_lateral: float = 0.0
## La pasada va por adentro de la curva que venía; ya entró a una curva; ya salió (se terminó
## el tirarse por adentro).
var _pass_inside: bool = false
var _pass_cornered: bool = false
var _dive_done: bool = false
var _rng := RandomNumberGenerator.new()
## Por índice: curva a la que pertenece (la más cercana por índice; −1 sin curvas) y lado de
## adentro de la próxima curva (−1 izquierda, +1 derecha).
var _corner_of: PackedInt32Array = PackedInt32Array()
var _corner_factor: PackedFloat32Array = PackedFloat32Array()
var _inside: PackedFloat32Array = PackedFloat32Array()
var _apexes: PackedInt32Array = PackedInt32Array()
var _frame: int = 0
var _pending_delta: float = 0.0


func configure(data: Dictionary) -> void:
	for key in ["lookahead_min", "lookahead_time", "steer_gain", "speed_lookahead", "speed_lookahead_time",
			"throttle_band", "brake_deadband", "brake_band", "stuck_progress", "stuck_time", "wrong_way_time", "off_track_margin",
			"overtake_range", "follow_gap", "follow_time", "follow_decel", "follow_gain", "lane_clear", "edge_margin", "lane_rate",
			"pass_cooldown", "yield_margin", "follow_predict", "dive_gap", "understeer_lift", "squeeze_margin", "squeeze_time", "lane_look", "pass_start_gap", "pass_start_time", "defend_time"]:
		if data.has(key):
			set(key, maxf(float(data[key]), 0.0))
	off_line_pace = clampf(float(data.get("off_line_pace", off_line_pace)), 0.5, 1.0)
	pass_brake_bonus = clampf(float(data.get("pass_brake_bonus", pass_brake_bonus)), 1.0, 1.2)
	follow_count = clampi(int(data.get("follow_count", follow_count)), 1, 5)
	start_follow_speed = maxf(float(data.get("start_follow_speed", start_follow_speed)), 0.0)
	hold_release_time = maxf(float(data.get("hold_release_time", hold_release_time)), 0.0)
	set_pace(float(data.get("pace", pace)))


func set_pace(value: float) -> void:
	pace = clampf(value, 0.5, 1.0)


## Nivel `id` del bloque "levels" de data/ai.json (si no está, queda como estaba).
func set_level(id: String, levels: Dictionary) -> void:
	var data = levels.get(id, {})
	if not data is Dictionary or data.is_empty():
		return
	level = id
	set_pace(float(data.get("pace", pace)))
	mistake = clampf(float(data.get("mistake", mistake)), 0.0, 0.3)
	pass_margin = maxf(float(data.get("pass_margin", pass_margin)), 0.0)
	defend = bool(data.get("defend", defend))
	_new_lap_factors()


static func level_name(id: String, levels: Dictionary) -> String:
	var data = levels.get(id, {})
	return str(data.get("name", id)) if data is Dictionary else id


func setup(driven: CarController, track: BakuTrack, line: RacingLine, cars: RaceTraffic = null) -> void:
	car = driven
	_track = track
	_line = line
	traffic = cars
	car.set_meta("ai", true)
	_frame = seed_value
	_start = track.checkpoint_indices[0] if not track.checkpoint_indices.is_empty() else track.start_index()
	var n := line.distances.size()
	_total = line.distances[n - 1] + track.centerline[n - 1].distance_to(track.centerline[0])
	refresh_speeds()
	_find_corners()
	_new_lap_factors()
	car.wall_hit.connect(func(strength: float) -> void:
		if strength > 0.05:
			wall_hits += 1)
	car.car_hit.connect(_on_car_hit)


## Después de un toque con otro auto deja la pasada y espera `pass_cooldown` s para otra.
func _on_car_hit(_other: CarController, strength: float) -> void:
	if strength <= 0.05:
		return
	car_hits += 1
	if passing != null:
		aborted_passes += 1
		passing = null
	_cooldown = pass_cooldown


## Recalcula sus velocidades objetivo (después de cambiarle el setup o el compuesto).
func refresh_speeds() -> void:
	_speeds = _line.speeds_for(car, wear_aware)
	_top = car.get_top_speed()


## Pone el auto en el índice `i`, mirando hacia adelante, a `speed` m/s: sobre la línea o, con
## `offset`, a esos metros del centro (+ derecha).
func place_at(i: int, speed: float = 0.0, offset: float = NAN) -> void:
	var n := _track.centerline.size()
	i = posmod(i, n)
	var heading := Basis.looking_at(_track.flat_tangent(i), Vector3.UP)
	var side := _line.offsets[i] if is_nan(offset) else offset
	car.spawn_transform = Transform3D(heading, _track.edge_point(i, side, 0.0) + Vector3(0, 0.6, 0))
	car.reset_to_spawn()
	if speed > 0.0:
		car.linear_velocity = -heading.z * speed
	index = i
	_last_lap_distance = lap_distance_at(i)
	_window = 0.0
	_window_start = _last_lap_distance
	_wrong_for = 0.0
	shift = 0.0
	lane_weight = 0.0
	passing = null
	_defending = false
	_holding = false
	pitting = false


## Paso 47: largada en fila de a dos; va por `offset` m de costado hasta la primera frenada
## (o hasta que pase o defienda) y después vuelve a la línea.
func hold_lane(offset: float) -> void:
	_holding = true
	_hold_lateral = offset


## Metros desde la meta hasta el índice i (0 a largo de la pista).
func lap_distance_at(i: int) -> float:
	return fposmod(_line.distances[i] - _line.distances[_start], _total)


func lap_distance() -> float:
	return lap_distance_at(index) if index >= 0 else 0.0


func _physics_process(delta: float) -> void:
	if car == null or not car.controls_enabled:
		return
	_pending_delta += delta
	_frame += 1
	if _frame % maxi(think_every, 1) != 0:
		return
	delta = _pending_delta
	_pending_delta = 0.0
	var located := _track.locate(car.global_position, index)
	index = int(located.x)
	lateral = located.y
	max_lateral = maxf(max_lateral, absf(lateral))
	var v := car.forward_speed
	_update_pit()
	_traffic(delta)
	car.ai_inputs = Vector3(0.0, 0.0, _steer(v))
	var pedals := _pedals(v, delta)
	car.ai_inputs.x = pedals.x
	car.ai_inputs.y = pedals.y
	_track_progress(delta)
	_watch(delta)


func _steer(v: float) -> float:
	var look_at := _track.index_at_distance(index, maxf(lookahead_min, v * lookahead_time))
	var aim := _line.points[look_at]
	var wanted := _desired_lateral(look_at)
	if wanted != _line.offsets[look_at]:
		aim = _track.edge_point(look_at, wanted, 0.0)
	var to_target := aim - car.global_position
	to_target.y = 0.0
	var forward := -car.global_transform.basis.z
	forward.y = 0.0
	return clampf(forward.signed_angle_to(to_target, Vector3.UP) * steer_gain, -1.0, 1.0)


## Empieza el camino de boxes al llegar a la entrada con el pedido hecho (si ya la pasó, en la
## vuelta siguiente) y lo termina después de la salida.
func _update_pit() -> void:
	if pit_lane == null or not pit_lane.enabled():
		pitting = false
		return
	var s := _track.start_offset(index)
	if not pitting:
		pitting = pit_requested and s > pit_lane.entry - pit_lane.ai_approach and s < pit_lane.entry - 5.0
	elif s > pit_lane.exit + pit_lane.ai_merge or s < pit_lane.entry - pit_lane.ai_approach - 20.0:
		pitting = false
		pit_requested = false


## Lateral que planea llevar en el índice j: la línea mezclada con su carril, dentro de la pista.
## Paso 48: entrando a boxes, el camino de la calle.
func _planned_lateral(j: int) -> float:
	if pitting:
		return pit_lane.path_lateral(j, _line.offsets[j], car)
	if lane_weight <= 0.0:
		return _line.offsets[j]
	var limit := maxf(_track.half_width(j) - edge_margin, 0.0)
	return clampf(lerpf(_line.offsets[j], lane_now, lane_weight), -limit, limit)


## Lateral al que apunta en el índice j: el planeado, dejándole `lane_clear` m al auto que
## tenga al lado.
func _desired_lateral(j: int) -> float:
	var wanted := _planned_lateral(j)
	if traffic == null or _slot < 0 or pitting:
		return wanted
	var adjusted := wanted
	for k in traffic.cars.size():
		if k == _slot or (absf(traffic.gap(_slot, k)) > traffic.car_length and not _diver(k)):
			continue
		var other := traffic.lateral[k]
		if absf(other - lateral) > lane_clear + 1.0 and not _diver(k):
			continue
		var room := lane_clear + (1.5 if _diver(k) else 0.0)
		if other >= lateral:
			adjusted = minf(adjusted, other - room)
		else:
			adjusted = maxf(adjusted, other + room)
	if adjusted == wanted:
		return wanted
	var edge := _track.half_width(j) - 0.8
	return clampf(adjusted, -edge, edge)


## (acelerador, freno) según el error contra la velocidad objetivo.
func _pedals(v: float, delta: float = 0.0) -> Vector2:
	var ahead := _track.index_at_distance(index, speed_lookahead + maxf(v, 0.0) * speed_lookahead_time)
	var line_speed := _speeds[ahead]
	var wanted := _desired_lateral(index)
	var off_line := absf(wanted - _line.offsets[index]) > 0.5
	if line_speed >= _top * 0.98:
		target = line_speed
	else:
		target = line_speed * pace * _corner_factor_at(ahead)
		if off_line:
			target *= off_line_pace
		if passing != null and _pass_inside and _track.corner_mask[index] <= 0.0:
			target *= pass_brake_bonus
	target = minf(target * flag_pace, flag_cap)
	if pitting:
		target = minf(target, pit_lane.speed_cap(index, car))
	var limit := minf(minf(_follow_limit(v), _yield_limit()), _lane_limit())
	var drift := absf(lateral - wanted)
	if v < 8.0:
		pass
	elif absf(car.steer_raw) > 0.97 and drift > 0.5:
		limit = minf(limit, maxf(v - understeer_lift, 0.0))
	elif _side_by_side() and drift > 1.0:
		limit = minf(limit, v)
	if limit < target:
		target = limit
		held_time += delta
	speed_error = target - v
	var throttle := clampf(0.5 + speed_error / maxf(throttle_band, 0.1), 0.0, 1.0)
	var brake := clampf((-speed_error - brake_deadband) / maxf(brake_band, 0.1), 0.0, 1.0)
	# Paso 47: si tiene que pararse (fila detrás de otro) no empuja con el acelerador de mantener.
	if brake > 0.0 or target < 1.0:
		throttle = 0.0
	# Casi quieto, frenar pondría reversa (caja automática): suelta el freno.
	if v < 0.6:
		brake = 0.0
	return Vector2(throttle, brake)


## Por su carril (pasando, defendiendo o entrando a boxes) la curva puede ser más cerrada que la de la línea:
## velocidad para llegar a cada punto de los próximos `lane_look` m (cada 5 m) a la de curva del
## camino que planea (curvatura con los puntos 5 m antes y después), frenando como la línea.
func _lane_limit() -> float:
	if (lane_weight <= 0.0 and not pitting) or lane_look <= 0.0:
		return INF
	var count := int(lane_look / 5.0) + 3
	var path := PackedVector3Array()
	var j := _track.index_at_distance(index, -5.0)
	for s in count:
		path.append(_track.edge_point(j, _planned_lateral(j), 0.0))
		j = _track.index_at_distance(j, 5.0)
	var best := INF
	for s in range(1, count - 1):
		var a := Vector2(path[s - 1].x, path[s - 1].z)
		var b := Vector2(path[s].x, path[s].z)
		var c := Vector2(path[s + 1].x, path[s + 1].z)
		var sides := a.distance_to(b) * b.distance_to(c) * c.distance_to(a)
		if sides < 0.001:
			continue
		var k := 2.0 * absf((b - a).cross(c - a)) / sides
		var corner := _line.corner_speed(car, k) * pace
		if corner == INF:
			continue
		var d := (s - 1) * 5.0
		best = minf(best, sqrt(corner * corner + 2.0 * _line.brake_decel(car, corner) * d))
	return best


## Velocidad máxima para no acercarse de atrás al auto que tiene en su carril (el de ahora o
## el que va a llevar al pasar por donde está el otro). Mientras no esté al lado, cuenta que el
## otro puede volver a su línea: también está en el carril si la línea pasa por ahí.
## Paso 47: mira hasta `follow_count` autos adelante (en fila de a dos el más cercano suele
## ir por el otro carril).
func _follow_limit(v: float) -> float:
	if traffic == null or _slot < 0:
		return INF
	var limit := INF
	var j := _slot
	for step in follow_count:
		j = traffic.nearest(j, true, overtake_range)
		if j < 0 or j == _slot or traffic.gap(_slot, j) > overtake_range:
			break
		limit = minf(limit, _follow_limit_to(j, v))
	return limit


func _follow_limit_to(j: int, v: float) -> float:
	var their_i := traffic.index[j]
	var lane := _planned_lateral(their_i)
	var width := traffic.car_width + 0.4
	# En la grilla escalonada (más despacio que `start_follow_speed` o en su fila) sólo cuenta
	# dónde está cada uno.
	var moving := v > start_follow_speed and not _holding
	var near := (moving and absf(traffic.lateral[j] - lane) < width) or absf(traffic.lateral[j] - lateral) < width
	if not near and moving and traffic.gap(_slot, j) >= traffic.car_length and not _diving_on(j):
		var n := _line.offsets.size()
		var span := posmod(_track.index_at_distance(their_i, maxf(traffic.speed[j], 0.0) * follow_predict + 5.0) - their_i, n)
		for step in range(0, span + 1, 3):
			var k := (their_i + step) % n
			if absf(_line.offsets[k] - _planned_lateral(k)) < width:
				near = true
				break
	if not near:
		return INF
	# Paso 47: en una horquilla el de adentro está más cerca que lo que dice la pista.
	var apart := minf(traffic.gap(_slot, j), car.global_position.distance_to(traffic.cars[j].global_position))
	var room := apart - (follow_gap + follow_time * maxf(v, 0.0))
	var their := maxf(traffic.speed[j], 0.0)
	if room >= 0.0:
		return sqrt(their * their + 2.0 * follow_decel * room)
	return maxf(their + room * follow_gain, 0.0)


## Le cede el lugar al auto que tiene al lado y ya está adelante, o que lo está pasando y ya
## tiene la trompa por la mitad de este. Paso 46: si al lado de otro se le está yendo encima
## (más rápido que el otro hacia él), levanta `squeeze_margin` m/s para cerrar la trayectoria.
func _yield_limit() -> float:
	if traffic == null or _slot < 0:
		return INF
	var limit := INF
	for k in traffic.cars.size():
		if k == _slot:
			continue
		var g := traffic.gap(_slot, k)
		if g > traffic.car_length + 3.0 or g < -traffic.car_length * 0.5:
			continue
		var side := absf(traffic.lateral[k] - lateral)
		var soon := absf(traffic.lateral[k] + traffic.side_speed[k] * squeeze_time
				- lateral - traffic.side_speed[_slot] * squeeze_time)
		var close := minf(side, soon) < traffic.car_width + 0.6
		var toward := signf(traffic.lateral[k] - lateral)
		var mine := traffic.side_speed[_slot] * toward
		var theirs := -traffic.side_speed[k] * toward
		if absf(g) < traffic.car_length and soon < traffic.car_width + 0.6 and mine > 0.5 and mine > theirs and mine + theirs > 0.3:
			limit = minf(limit, maxf(traffic.speed[_slot] - squeeze_margin, 0.0))
			continue
		if g > 0.0 and close:
			limit = minf(limit, maxf(traffic.speed[k] - squeeze_margin, 0.0))
			continue
		if traffic.cars[k] == passing or g > traffic.car_length or side > lane_clear + 0.8:
			continue
		if g <= 0.0 and close:
			continue
		var other := traffic.cars[k]
		if g > 0.0 or (other.has_meta("passing") and other.get_meta("passing") == car):
			var margin := yield_margin * (2.0 if _diver(k) else 1.0)
			limit = minf(limit, maxf(traffic.speed[k] - margin, 0.0))
	return limit


## Hay otro auto al lado (se superponen a lo largo).
func _side_by_side() -> bool:
	if traffic == null or _slot < 0:
		return false
	for k in traffic.cars.size():
		if k != _slot and absf(traffic.gap(_slot, k)) < traffic.car_length \
				and absf(traffic.lateral[k] - lateral) < lane_clear + 1.5:
			return true
	return false


func _corner_factor_at(i: int) -> float:
	var c := _corner_of[i] if i < _corner_of.size() else -1
	return _corner_factor[c] if c >= 0 and c < _corner_factor.size() else 1.0


## Adelantar y defender: decide `shift_goal` y mueve `shift` hacia ahí.
func _traffic(delta: float) -> void:
	_slot = traffic.slot(car) if traffic != null else -1
	if pitting:
		passing = null
		_defending = false
		_holding = false
		lane_weight = 0.0
		car.set_meta("passing", null)
		shift = _planned_lateral(index) - _line.offsets[index]
		_overtake_mode(false)
		return
	if _slot < 0:
		lane_weight = move_toward(lane_weight, 0.0, delta / 1.5)
		shift = _planned_lateral(index) - _line.offsets[index]
		return
	var top := _top * 0.98
	var v := maxf(car.forward_speed, 0.0)
	var on_straight := _speeds[index] >= top
	var in_corner := _track.corner_mask[index] > 0.0
	if in_corner:
		_defended = false
	_cooldown = maxf(_cooldown - delta, 0.0)
	var ahead := traffic.nearest(_slot, true, overtake_range)
	var ahead_car: CarController = traffic.cars[ahead] if ahead >= 0 else null
	if ahead_car != _ahead_car:
		_ahead_car = ahead_car
		_deficit = 0.0
	if ahead >= 0:
		var their_v := maxf(traffic.speed[ahead], 0.0)
		var there := _speeds[_track.index_at_distance(traffic.index[ahead], speed_lookahead + their_v * speed_lookahead_time)]
		if there < top * 0.9:
			_deficit = lerpf(_deficit, there * pace - their_v, clampf(delta / 2.0, 0.0, 1.0))

	if passing != null and not _may_pass(passing):
		passing = null
	if passing != null:
		_continue_pass(in_corner)
	elif ahead >= 0 and _deficit > pass_margin and _cooldown <= 0.0 and on_straight \
			and traffic.gap(_slot, ahead) < pass_start_gap and _may_pass(traffic.cars[ahead]):
		if _speeds[_track.index_at_distance(index, v * pass_start_time + 10.0)] < top:
			_start_pass(ahead)
	car.set_meta("passing", passing)
	if blue_for != null:
		_defending = false
	if passing == null and defend and not _holding and blue_for == null:
		_defend(on_straight)
	if _holding and (passing != null
			or _speeds[_track.index_at_distance(index, v * hold_release_time + 10.0)] < _speeds[index] * 0.95):
		_holding = false
	if _holding:
		lane_goal = _hold_lateral
	var active := passing != null or _defending or _holding
	if passing != null:
		var j := traffic.slot(passing)
		var limit := maxf(_track.half_width(traffic.index[j]) - edge_margin, 0.0)
		var clear := lane_clear + (1.2 if _pass_inside else 0.0)
		lane_goal = clampf(traffic.lateral[j] + pass_side * clear, -limit, limit)
	elif _defending:
		lane_goal = _defend_lateral
	if active:
		if lane_weight < 1.0:
			lane_now = _planned_lateral(index) if lane_weight > 0.0 else lateral
			lane_weight = 1.0
		lane_now = move_toward(lane_now, lane_goal, lane_rate * delta)
	else:
		lane_weight = move_toward(lane_weight, 0.0, delta / 1.5)
	shift = _planned_lateral(index) - _line.offsets[index]
	_overtake_mode(on_straight)


## Paso 50: con amarilla o Safety Car sólo puede pasar a los autos de `pass_exempt`.
func _may_pass(other: CarController) -> bool:
	return not no_pass or other in pass_exempt


## Se tira por adentro a menos de `dive_gap` m de otro auto de la IA (que le va a dejar lugar).
func _diving_on(j: int) -> bool:
	if passing == null or traffic.cars[j] != passing or not passing.has_meta("ai"):
		return false
	return _pass_inside and not _dive_done and traffic.gap(_slot, j) < dive_gap


## El auto que se le tira por adentro a menos de `dive_gap` m (ya lo tiene que respetar).
func _diver(k: int) -> bool:
	var other := traffic.cars[k]
	if not other.has_meta("passing") or other.get_meta("passing") != car:
		return false
	var g := -traffic.gap(_slot, k)
	return g > -traffic.car_length * 1.5 and g < dive_gap


func _pass_lateral_ok(j: int, side: float) -> bool:
	return absf(traffic.lateral[j] + side * lane_clear) <= _track.half_width(traffic.index[j]) - edge_margin


## Lado de pasada: el que tenga lugar junto al otro; si entran los dos, el de adentro de la
## próxima curva.
func _start_pass(j: int) -> void:
	var inside := _inside[traffic.index[j]]
	for side in [inside, -inside]:
		if _pass_lateral_ok(j, side):
			passing = traffic.cars[j]
			pass_side = side
			_pass_inside = side == inside
			_pass_cornered = false
			_dive_done = false
			_defending = false
			return


## Termina al quedar un auto y 2 m adelante. Abandona si se queda atrás, si junto al otro ya no
## hay lugar o si llega a la curva sin estar al lado.
func _continue_pass(in_corner: bool) -> void:
	var j := traffic.slot(passing)
	if j < 0:
		passing = null
		return
	var g := traffic.gap(_slot, j)
	if g < -(traffic.car_length + 2.0):
		passes += 1
		passing = null
		return
	if in_corner:
		_pass_cornered = true
	elif _pass_cornered:
		_dive_done = true
	var alongside := g < traffic.car_length or _diving_on(j)
	var abort := g > overtake_range + 20.0
	abort = abort or (not alongside and (in_corner or not _pass_lateral_ok(j, pass_side)))
	if abort:
		aborted_passes += 1
		passing = null
		_cooldown = pass_cooldown


## Una sola defensa por recta: con un auto a menos de `defend_time` s atrás (y todavía no al
## lado) se corre hacia adentro de la próxima curva hasta que empieza a frenar.
func _defend(on_straight: bool) -> void:
	if _defending and not on_straight:
		_defending = false
	if _defending or _defended or not on_straight:
		return
	var behind := traffic.nearest(_slot, false, overtake_range)
	if behind < 0:
		return
	var g := -traffic.gap(_slot, behind)
	if g < traffic.car_length + 1.0 or g / maxf(traffic.speed[behind], 10.0) > defend_time:
		return
	_defending = true
	_defended = true
	defences += 1
	_defend_lateral = _inside[index] * maxf(_track.half_width(index) * 0.45, 0.0)


## Modo adelantamiento mientras pasa en recta (si RaceTraffic dice que está a menos de 1 s).
func _overtake_mode(on_straight: bool) -> void:
	var aero := car.active_aero
	var want := passing != null and on_straight
	if want and not aero.overtake_active and aero.energy > 0.0 and aero.gap_ahead >= 0.0 and aero.gap_ahead <= aero.max_gap:
		aero.toggle_overtake()
	elif not want and aero.overtake_active:
		aero.toggle_overtake()


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
		car.active_aero.refill()
		_new_lap_factors()
		if wear_aware:
			refresh_speeds()
	_last_lap_distance = distance
	var off := absf(lateral) > _track.half_width(index) + off_track_margin
	if off and pit_lane != null and pit_lane.contains(index, lateral):
		off = false
	if off and not _off:
		off_tracks += 1
	_off = off


## Trabado (no avanza por la pista) o de contramano (más de 90° contra el trazado) demasiado
## tiempo: vuelve a la línea, quieto, y la vuelta en curso no cuenta.
func _watch(delta: float) -> void:
	if pitting:
		_window = 0.0
		_window_start = lap_distance()
		_wrong_for = 0.0
		return
	_window += delta
	if _window >= stuck_time:
		var progress := fposmod(lap_distance() - _window_start + _total * 0.5, _total) - _total * 0.5
		_window = 0.0
		_window_start = lap_distance()
		if progress < stuck_progress and not _queued():
			_recover()
			return
	var forward := -car.global_transform.basis.z
	var tangent := _track.flat_tangent(index)
	_wrong_for = _wrong_for + delta if forward.x * tangent.x + forward.z * tangent.z < 0.0 else 0.0
	if _wrong_for > wrong_way_time:
		_recover()


## Paso 47: parado en la fila detrás de otro auto (a menos de `follow_gap` + 2 largos) no
## está trabado.
func _queued() -> bool:
	if traffic == null or _slot < 0:
		return false
	var ahead := traffic.nearest(_slot, true, follow_gap + traffic.car_length * 2.0)
	return ahead >= 0


func _recover() -> void:
	recoveries += 1
	timing = false
	place_at(index)


## Curvas = mínimos locales de la velocidad objetivo (< 85 % de la máxima, a 60+ puntos entre
## sí); cada índice pertenece a la curva más cercana. Lado de adentro de la próxima curva: el
## lado donde la línea toca el vértice (signo de su lateral ahí).
func _find_corners() -> void:
	var n := _speeds.size()
	var minima := PackedInt32Array()
	for i in n:
		var v := _speeds[i]
		if v > _top * 0.85:
			continue
		var is_min := true
		for o in range(-30, 31):
			if _speeds[posmod(i + o, n)] < v:
				is_min = false
				break
		if is_min and (minima.is_empty() or i - minima[minima.size() - 1] > 60):
			minima.append(i)
	_corner_of.resize(n)
	for i in n:
		var best := -1
		var best_d := n
		for c in minima.size():
			var d := absi(posmod(i - minima[c] + n / 2, n) - n / 2)
			if d < best_d:
				best_d = d
				best = c
		_corner_of[i] = best
	_corner_factor.resize(minima.size())
	_corner_factor.fill(1.0)
	_apexes = minima
	_inside.resize(n)
	var side := -1.0
	var is_apex := {}
	for m in minima:
		is_apex[m] = true
	for k in 2 * n:
		var i := n - 1 - (k % n)
		if is_apex.has(i) and _line.offsets[i] != 0.0:
			side = signf(_line.offsets[i])
		_inside[i] = side


func _new_lap_factors() -> void:
	_rng.seed = hash([seed_value, laps])
	for c in _corner_factor.size():
		_corner_factor[c] = 1.0 + mistake * (_rng.randf() * 1.25 - 1.0)


func summary() -> String:
	return "%d vueltas · mejor %s · salidas %d · golpes %d · toques %d · rescates %d" % [laps,
		LapTimer.format_time(best_lap) if best_lap > 0.0 else "--", off_tracks, wall_hits, car_hits, recoveries]
