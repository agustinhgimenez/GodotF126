class_name OnlineRace
extends Node
## Carrera online de 2 jugadores dentro de main.tscn (la crea Main en modo "online").
## Cada PC simula su auto; el del rival es un auto físico (choca de verdad) que recibe los
## pedales y el volante del otro y al que cada cuadro se le corrige la velocidad hacia la
## posición extrapolada de su último estado. Los dos avisan "ready" al terminar de cargar y el
## servidor manda "go" con la semilla del semáforo. Posición: metros recorridos; al llegar, el
## tiempo total (vueltas + penalizaciones) de cada uno.

const ROW_COLOR := Color(1.0, 0.85, 0.2)

var main: Node
var car: CarController
var remote: CarController
## Nombres que eligieron los jugadores (el piloto va aparte).
var remote_name: String = "Rival"
var my_name: String = "Vos"
var remote_team: Dictionary = {}
var remote_driver: Dictionary = {}
## Llegada del rival: {"time", "best"} o vacío.
var remote_finish: Dictionary = {}
var remote_gone: bool = false
var started: bool = false

var _data: Dictionary = {}
var _snapshot: Dictionary = {}
var _snapshot_ms: int = 0
var _send_timer: float = 0.0
var _wait_timer: float = 0.0
var _hint: int = -1
var _last_progress: float = NAN
var _remote_progress: float = 0.0
var _panel_label: Label
var _results_open: bool = false
var _local_finished: bool = false


func setup(main_node: Node, local_car: CarController, data: Dictionary) -> void:
	main = main_node
	car = local_car
	_data = data
	process_mode = Node.PROCESS_MODE_ALWAYS
	var grid := DataLoader.load_json(DataLoader.GRID_PATH)
	var found := DataLoader.find_driver(grid, str(Online.opponent.get("driver_id", "")))
	remote_driver = found.get("driver", {})
	remote_team = found.get("team", {})
	remote_name = str(Online.opponent.get("name", "Rival"))
	my_name = Online.player_name()
	var mine := maxi(Online.slot, 0)
	main.place_on_grid(car, mine)
	remote = main.add_remote_car(remote_driver, remote_team, player_label(Online.opponent))
	remote.tyre_substeps = clampi(int(_data.get("remote_tyre_substeps", 2)), 1, CarController.TYRE_SUBSTEPS)
	main.place_on_grid(remote, 1 - mine)
	_build_panel()
	Online.message.connect(_on_message)
	Online.failed.connect(_on_failed)
	main.lap_timer.session_finished.connect(_on_local_finished)
	main.hud.show_message("Esperando a %s…" % remote_name, 30.0)
	_send_ready()


## "ready" recién cuando la carrera ya se está dibujando: los primeros cuadros (sobre todo en la
## web) tardan, y el semáforo no tiene que arrancar mientras uno todavía no ve la pista.
func _send_ready() -> void:
	for i in int(_data.get("ready_frames", 30)):
		await get_tree().process_frame
	if is_inside_tree() and not started:
		Online.send({"t": "ping", "c": Time.get_ticks_msec()})
		Online.send({"t": "ready"})


## "Nombre (Piloto)" de un jugador como lo manda el servidor.
static func player_label(player: Dictionary) -> String:
	var name := str(player.get("name", "Rival"))
	var driver := str(player.get("driver_name", ""))
	return name if driver.is_empty() else "%s (%s)" % [name, driver]


func _exit_tree() -> void:
	if Online.message.is_connected(_on_message):
		Online.message.disconnect(_on_message)
		Online.failed.disconnect(_on_failed)
	Online.leave()


func _physics_process(delta: float) -> void:
	if get_tree().paused:
		return
	if not started:
		_wait_timer += delta
		if _wait_timer >= float(_data.get("start_timeout", 90.0)):
			_lose_remote("%s no terminó de cargar: corrés solo" % remote_name)
	_send_timer += delta
	if _send_timer >= 1.0 / float(_data.get("send_rate", 20)):
		_send_timer = 0.0
		_send_state()
	_drive_remote()
	_refresh_panel()


func _send_state() -> void:
	var q := Quaternion(car.global_basis.orthonormalized())
	Online.send({"t": "s",
		"p": _round([car.global_position.x, car.global_position.y, car.global_position.z]),
		"q": _round([q.x, q.y, q.z, q.w]),
		"v": _round([car.linear_velocity.x, car.linear_velocity.y, car.linear_velocity.z]),
		"w": _round([car.angular_velocity.x, car.angular_velocity.y, car.angular_velocity.z]),
		"i": _round([car.throttle_input, car.brake_input, car.steer_raw]),
		"g": snappedf(progress(), 0.1)})


func _round(values: Array) -> Array:
	return values.map(func(x: float) -> float: return snappedf(x, 0.001))


## Lleva el auto del rival hacia donde debería estar ahora (último estado + velocidad × lo que
## tardó en llegar, que se estima con el ping).
func _drive_remote() -> void:
	if remote == null or _snapshot.is_empty():
		return
	var p := _vec(_snapshot.get("p"))
	var v := _vec(_snapshot.get("v"))
	var w := _vec(_snapshot.get("w"))
	var qa: Array = _snapshot.get("q", [0, 0, 0, 1])
	var q := Quaternion(float(qa[0]), float(qa[1]), float(qa[2]), float(qa[3])).normalized()
	var inputs: Array = _snapshot.get("i", [0, 0, 0])
	remote.ai_inputs = Vector3(float(inputs[0]), float(inputs[1]), float(inputs[2]))
	var age := (Time.get_ticks_msec() - _snapshot_ms) / 1000.0 + Online.rtt
	age = clampf(age, 0.0, float(_data.get("max_extrapolation", 0.5)))
	var target_p := p + v * age
	var target_q := q
	if w.length() > 0.0001:
		target_q = (Quaternion(w.normalized(), w.length() * age) * q).normalized()
	var error := target_p - remote.global_position
	if error.length() > float(_data.get("teleport_distance", 8.0)):
		remote.global_transform = Transform3D(Basis(target_q), target_p)
		remote.linear_velocity = v
		remote.angular_velocity = w
		return
	var blend := float(_data.get("velocity_blend", 0.35))
	var wanted_v := v + error * float(_data.get("position_gain", 5.0))
	remote.linear_velocity = remote.linear_velocity.lerp(wanted_v, blend)
	var dq := (target_q * Quaternion(remote.global_basis.orthonormalized()).inverse()).normalized()
	if dq.w < 0.0:
		dq = -dq
	var angle := 2.0 * acos(clampf(dq.w, -1.0, 1.0))
	var wanted_w := w
	if angle > 0.0001:
		wanted_w += Vector3(dq.x, dq.y, dq.z).normalized() * angle * float(_data.get("rotation_gain", 6.0))
	remote.angular_velocity = remote.angular_velocity.lerp(wanted_w, blend)


func _vec(value) -> Vector3:
	if value is Array and value.size() >= 3:
		return Vector3(float(value[0]), float(value[1]), float(value[2]))
	return Vector3.ZERO


## Metros recorridos desde la largada (negativos en la grilla). Continuo: el cronómetro y el
## índice de la pista no cambian de vuelta exactamente en el mismo punto.
func progress() -> float:
	var length: float = main.traffic.lap_length()
	if length <= 0.0:
		return 0.0
	_hint = int(main.track.locate(car.global_position, _hint).x)
	var distances: PackedFloat32Array = main.racing_line.distances
	var d := fposmod(distances[_hint] - distances[main.track.start_index()], length)
	var raw := (maxi(main.lap_timer.lap, 1) - 1) * length + d
	if is_nan(_last_progress):
		raw -= length if d > length * 0.5 else 0.0
	else:
		while raw < _last_progress - length * 0.5:
			raw += length
		while raw > _last_progress + length * 0.5:
			raw -= length
	_last_progress = raw
	return raw


func _on_message(msg: Dictionary) -> void:
	match str(msg.get("t", "")):
		"s":
			_snapshot = msg
			_snapshot_ms = Time.get_ticks_msec()
			_remote_progress = float(msg.get("g", _remote_progress))
		"go":
			_start(int(msg.get("seed", 1)))
		"fin":
			remote_finish = {"time": float(msg.get("time", 0.0)), "best": float(msg.get("best", -1.0))}
			if not _local_finished:
				main.hud.show_message("%s llegó: %s" % [remote_name, LapTimer.format_time(remote_finish["time"])], 3.0)
			if _results_open:
				open_results()
		"left":
			_lose_remote("%s se desconectó" % remote_name)


func _on_failed(reason: String) -> void:
	_lose_remote(reason)


func _start(seed_value: int) -> void:
	if started:
		return
	started = true
	main.hud.show_message("¡Largada contra %s!" % remote_name, 2.0)
	# El servidor manda "go" a los dos a la vez: cada uno descuenta lo que tardó en llegarle
	# (medio ping) y las luces siguen el reloj desde ese instante común.
	main.begin_start_lights(seed_value, Time.get_ticks_msec() - int(Online.rtt * 500.0))


## El rival ya no está (se fue, se cortó la conexión o no cargó): se saca su auto y, si
## todavía no largó, se larga solo.
func _lose_remote(reason: String) -> void:
	if remote_gone:
		return
	remote_gone = true
	main.hud.show_message(reason, 4.0, RaceHUD.COLOR_WARNING)
	if remote != null:
		remote.queue_free()
		remote = null
	Online.leave()
	if not started:
		started = true
		main.begin_start_lights(0)
	if _results_open:
		open_results()


func _on_local_finished() -> void:
	_local_finished = true
	Online.send({"t": "fin", "time": main.lap_timer.total_time(), "best": main.lap_timer.best_lap})


## Lo llama Main después del aviso de llegada: si el rival todavía corre, espera hasta
## `finish_wait` s y muestra la tabla con él "en pista".
func open_results() -> void:
	if remote_finish.is_empty() and not remote_gone and not _results_open:
		_results_open = true
		main.hud.visible = true
		main.hud.show_message("Esperando la llegada de %s…" % remote_name, float(_data.get("finish_wait", 60.0)))
		get_tree().create_timer(float(_data.get("finish_wait", 60.0))).timeout.connect(_on_finish_wait_over)
		return
	_results_open = true
	_show_table()


func _on_finish_wait_over() -> void:
	if remote_finish.is_empty() and not remote_gone:
		_show_table()


func _show_table() -> void:
	main.hud.visible = false
	var mine: float = main.lap_timer.total_time()
	var mine_entry := {"name": my_name, "team": main.selected_team,
		"driver": main.selected_driver, "time": mine, "best": main.lap_timer.best_lap, "player": true}
	var theirs := {"name": remote_name, "team": remote_team, "driver": remote_driver,
		"time": float(remote_finish.get("time", -1.0)), "best": float(remote_finish.get("best", -1.0)), "player": false}
	var order := [mine_entry, theirs]
	if theirs["time"] > 0.0 and theirs["time"] < mine:
		order = [theirs, mine_entry]
	var rows: Array = []
	for p in order.size():
		var info: Dictionary = order[p]
		var time := float(info["time"])
		var time_text := LapTimer.format_time(time) if time > 0.0 else ("Abandonó" if remote_gone and remote_finish.is_empty() else "En pista")
		if p == 1 and time > 0.0 and float(order[0]["time"]) > 0.0:
			time_text += "  (+%.3f)" % (time - float(order[0]["time"]))
		rows.append({"cells": [str(p + 1), "%s · %s #%s" % [str(info["name"]), _surname(info["driver"]),
			UiKit.number_text(info["driver"].get("number", ""))], str(info["team"].get("name", "")), time_text,
			LapTimer.format_time(float(info["best"])) if float(info["best"]) > 0.0 else "—"],
			"color": ROW_COLOR if info["player"] else Color.WHITE, "highlight": info["player"]})
	var won: bool = order[0]["player"]
	var summary: Array = [
		["¡Ganaste!" if won else "Ganó %s" % str(order[0]["name"]), ROW_COLOR if won else Color.WHITE],
		["Tiempo total = vueltas + penalizaciones", ResultsScreen.COLOR_HEADER],
		["Repetir vuelve a las salas online", ResultsScreen.COLOR_HEADER],
	]
	if main.lap_timer.penalty > 0.0:
		summary.insert(1, ["Tus penalizaciones: +%d s (%s)" % [roundi(main.lap_timer.penalty), main.lap_timer.penalty_reason], RaceHUD.COLOR_WARNING])
	main.results_screen.open_standings("Online — Resultado", main.session_subtitle(),
		["P", "Jugador", "Equipo", "Tiempo", "Mejor vuelta"], [34, 320, 130, 190, 120], rows, summary)


func _surname(driver: Dictionary) -> String:
	var parts := str(driver.get("name", "")).split(" ", false)
	return parts[parts.size() - 1] if not parts.is_empty() else ""


func _build_panel() -> void:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.03, 0.06, 0.72)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel", style)
	UiKit.place(panel, Vector4(0, 0, 0, 0), Vector4(24, 100, 344, 100))
	_panel_label = UiKit.make_label("", 18)
	panel.add_child(_panel_label)
	main.hud.add_child(panel)


func _refresh_panel() -> void:
	if _panel_label == null:
		return
	var me := my_name
	if remote_gone and remote_finish.is_empty():
		_panel_label.text = "ONLINE\n1. %s\n%s: fuera" % [me, remote_name]
		return
	var mine := progress() if not _local_finished else INF
	var theirs := INF if not remote_finish.is_empty() else _remote_progress
	var ahead := mine >= theirs
	if _local_finished and not remote_finish.is_empty():
		ahead = main.lap_timer.total_time() <= float(remote_finish["time"])
	var gap_text := ""
	if not is_inf(mine) and not is_inf(theirs):
		var trailing_speed := maxf(_remote_speed() if ahead else car.linear_velocity.length(), 15.0)
		gap_text = ("  a %.1f s" % (absf(mine - theirs) / trailing_speed)).replace(".", ",")
	var first := me if ahead else remote_name
	var second := remote_name if ahead else me
	_panel_label.text = "ONLINE · vas %d.º\n1. %s\n2. %s%s" % [1 if ahead else 2, first, second, gap_text]


func _remote_speed() -> float:
	return _vec(_snapshot.get("v")).length() if not _snapshot.is_empty() else 0.0
