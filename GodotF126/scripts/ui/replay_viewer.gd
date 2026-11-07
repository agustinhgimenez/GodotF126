class_name ReplayViewer
extends CanvasLayer
## Repetición de la carrera (Paso 51) con lo que grabó RaceRecorder. Con el árbol en pausa
## mueve los 22 autos y el Safety Car a sus poses grabadas (interpoladas) y, al salir, los
## devuelve a donde estaban. Cámaras: las torres de TV de la pista (TvCameras), persecución y a
## bordo. Torre de posiciones del instante, barra de tiempo con los incidentes (sanciones,
## advertencias, amarillas, Safety Car) y aviso de cada uno al pasar. Controles en
## data/replay.json → description. Este nodo sigue procesando en pausa.

signal closed

const CAMERAS := ["tv", "chase", "onboard"]
const CAMERA_NAMES := {"tv": "TV", "chase": "Persecución", "onboard": "A bordo"}
const COLOR_REC := Color(1.0, 0.25, 0.25)
const COLOR_PENALTY := Color(1.0, 0.35, 0.3)
const COLOR_WARNING := Color(1.0, 0.65, 0.2)
const COLOR_YELLOW := Color(1.0, 0.85, 0.1)
const COLOR_SC := Color(1.0, 0.6, 0.1)
const COLOR_GREEN := Color(0.3, 0.85, 0.35)
const BANNER_TIME := 3.5

var speeds: Array[float] = [0.25, 0.5, 1.0, 2.0, 4.0]
var seek_step: float = 5.0
var incident_lead: float = 4.0
var tower_refresh: float = 0.25
var start_before_end: float = 15.0
var start_before_finish: float = 12.0
var chase_distance: float = 9.0
var chase_height: float = 3.2
var chase_look_ahead: float = 6.0
var chase_smoothing: float = 6.0
var chase_fov: float = 65.0
var onboard_offset: Transform3D = Transform3D(Basis(Vector3.RIGHT, deg_to_rad(-6.0)), Vector3(0, 1.3, 0.75))
var onboard_fov: float = 72.0

## Instante de la grabación que se muestra (reloj de RaceRecorder).
var time: float = 0.0
var playing: bool = false
var speed_index: int = 2
var camera: String = "tv"
## Índice (en RaceRecorder.cars) del auto seguido.
var follow: int = 0
## {time, car (índice o −1), text, color}, por tiempo.
var incidents: Array[Dictionary] = []
var banner_text: String = ""

var _rec: RaceRecorder
var _tv: TvCameras
var _stewards: RaceStewards
var _control: RaceControl
var _player: CarController
var _camera: Camera3D
var _snap: bool = true
var _saved: Array[Dictionary] = []
var _saved_sc: Dictionary = {}
var _prev_camera: Camera3D
var _tv_was_active: bool = false
var _tv_target: Node3D
var _tower_timer: float = 0.0
var _banner_left: float = 0.0

var _root: Control
var _clock_label: Label
var _tower: TimingTower
var _info: Label
var _timeline: Timeline
var _banner: PanelContainer
var _banner_style: StyleBoxFlat
var _banner_label: Label
var _help: Label


## Barra de tiempo: marcas de los incidentes, lo ya visto y la posición; click o arrastre para ir.
class Timeline extends Control:
	var viewer: ReplayViewer

	func _draw() -> void:
		var rec := viewer._rec
		if rec == null or rec.sample_count() < 2:
			return
		var span := maxf(rec.end_time() - rec.start_time(), 0.001)
		draw_rect(Rect2(Vector2(0, 6), Vector2(size.x, size.y - 12)), Color(1, 1, 1, 0.18))
		var played := clampf((viewer.time - rec.start_time()) / span, 0.0, 1.0)
		draw_rect(Rect2(Vector2(0, 6), Vector2(size.x * played, size.y - 12)), Color(1, 1, 1, 0.55))
		for inc in viewer.incidents:
			var x := clampf((float(inc["time"]) - rec.start_time()) / span, 0.0, 1.0) * size.x
			draw_rect(Rect2(Vector2(x - 1.5, 0), Vector2(3, size.y)), inc["color"])
		draw_rect(Rect2(Vector2(size.x * played - 3, -2), Vector2(6, size.y + 4)), ReplayViewer.COLOR_REC)

	func _gui_input(event: InputEvent) -> void:
		var button := event as InputEventMouseButton
		var motion := event as InputEventMouseMotion
		if (button != null and button.pressed and button.button_index == MOUSE_BUTTON_LEFT) \
				or (motion != null and motion.button_mask & MOUSE_BUTTON_MASK_LEFT):
			var rec := viewer._rec
			var f := clampf(get_local_mouse_position().x / maxf(size.x, 1.0), 0.0, 1.0)
			viewer.seek(rec.start_time() + f * (rec.end_time() - rec.start_time()))
			accept_event()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 12
	_build_ui()
	_root.visible = false


func configure(data: Dictionary) -> void:
	var list = data.get("speeds", [])
	if list is Array and not list.is_empty():
		speeds.clear()
		for s in list:
			speeds.append(clampf(float(s), 0.05, 16.0))
	speed_index = maxi(speeds.find(1.0), 0)
	seek_step = maxf(float(data.get("seek_step", seek_step)), 0.5)
	_update_help()
	incident_lead = maxf(float(data.get("incident_lead", incident_lead)), 0.0)
	tower_refresh = maxf(float(data.get("tower_refresh", tower_refresh)), 0.05)
	start_before_end = maxf(float(data.get("start_before_end", start_before_end)), 0.0)
	start_before_finish = maxf(float(data.get("start_before_finish", start_before_finish)), 0.0)
	var chase = data.get("chase", {})
	if chase is Dictionary:
		chase_distance = float(chase.get("distance", chase_distance))
		chase_height = float(chase.get("height", chase_height))
		chase_look_ahead = float(chase.get("look_ahead", chase_look_ahead))
		chase_smoothing = maxf(float(chase.get("smoothing", chase_smoothing)), 0.1)
		chase_fov = float(chase.get("fov", chase_fov))
	var onboard = data.get("onboard", {})
	if onboard is Dictionary:
		var p = onboard.get("position", [])
		var at := onboard_offset.origin
		if p is Array and p.size() >= 3:
			at = Vector3(float(p[0]), float(p[1]), float(p[2]))
		onboard_offset = Transform3D(Basis(Vector3.RIGHT, deg_to_rad(float(onboard.get("pitch", -6.0)))), at)
		onboard_fov = float(onboard.get("fov", onboard_fov))


## camera_parent: nodo 3D donde va la cámara propia (persecución y a bordo).
func setup(recorder: RaceRecorder, tv: TvCameras, stewards: RaceStewards, control: RaceControl,
		player: CarController, camera_parent: Node3D, accent: Color) -> void:
	_rec = recorder
	_tv = tv
	_stewards = stewards
	_control = control
	_player = player
	_camera = Camera3D.new()
	_camera.name = "ReplayCamera"
	_camera.near = 0.1
	_camera.far = 2000.0
	camera_parent.add_child(_camera)
	_banner_style.border_color = accent


func is_open() -> bool:
	return _root.visible


func can_open() -> bool:
	return _rec != null and _rec.sample_count() >= 2


## Instante donde arranca la repetición desde la pausa (unos segundos antes de ahora).
func default_start() -> float:
	return _rec.end_time() - start_before_end


## Instante donde arranca desde el resultado: un poco antes de la llegada del jugador.
func finish_start() -> float:
	var i := _rec.index_of(_player)
	var entry: Dictionary = _rec.entries[i] if i >= 0 else {}
	if not entry.is_empty() and entry["finished"]:
		return _rec.from_race_time(float(entry["finish_time"])) - start_before_finish
	return default_start()


## Abre la repetición en `start` (el árbol ya tiene que estar en pausa).
func open(start: float) -> bool:
	if not can_open() or is_open():
		return false
	_saved.clear()
	for car in _rec.cars:
		if is_instance_valid(car):
			_saved.append({"car": car, "transform": car.global_transform,
				"linear": car.linear_velocity, "angular": car.angular_velocity})
	var sc := _control.safety_car_node() if _control != null else null
	_saved_sc = {"node": sc, "visible": sc.visible, "transform": sc.global_transform} if sc != null else {}
	_prev_camera = get_viewport().get_camera_3d()
	_tv_was_active = _tv.active
	_tv_target = _tv.target()
	_tv.process_mode = Node.PROCESS_MODE_ALWAYS
	follow = maxi(_rec.index_of(_player), 0)
	_build_incidents()
	time = clampf(start, _rec.start_time(), _rec.end_time())
	playing = true
	speed_index = maxi(speeds.find(1.0), 0)
	_banner_left = 0.0
	_root.visible = true
	_set_camera(camera)
	_apply(0.0)
	_refresh_tower()
	return true


func close() -> void:
	if not is_open():
		return
	for saved in _saved:
		var car: CarController = saved["car"]
		if is_instance_valid(car):
			car.global_transform = saved["transform"]
			car.linear_velocity = saved["linear"]
			car.angular_velocity = saved["angular"]
	if not _saved_sc.is_empty() and is_instance_valid(_saved_sc["node"]):
		var sc: Node3D = _saved_sc["node"]
		sc.visible = _saved_sc["visible"]
		sc.global_transform = _saved_sc["transform"]
	_tv.follow(_tv_target, Callable())
	_tv.set_active(_tv_was_active)
	_tv.process_mode = Node.PROCESS_MODE_INHERIT
	_camera.current = false
	if is_instance_valid(_prev_camera):
		_prev_camera.make_current()
	_root.visible = false
	closed.emit()


func seek(t: float) -> void:
	time = clampf(t, _rec.start_time(), _rec.end_time())
	_snap = true
	_banner_left = 0.0
	if camera == "tv":
		_tv.follow(_rec.cars[follow], _follow_velocity)
	_apply(0.0)
	_refresh_tower()


func set_speed_index(index: int) -> void:
	speed_index = clampi(index, 0, speeds.size() - 1)
	_update_info()


func cycle_camera() -> void:
	_set_camera(CAMERAS[(CAMERAS.find(camera) + 1) % CAMERAS.size()])


## Sigue al auto que está `step` lugares más atrás (+1) o adelante (−1) en este instante.
func cycle_follow(step: int) -> void:
	var order := _rec.order_at(time)
	var at := order.find(follow)
	set_follow(order[posmod(at + step, order.size())])


func set_follow(index: int) -> void:
	follow = clampi(index, 0, _rec.cars.size() - 1)
	_snap = true
	if camera == "tv":
		_tv.follow(_rec.cars[follow], _follow_velocity)
	_update_info()
	_refresh_tower()


## Va al incidente siguiente (`incident_lead` s antes) y sigue al auto involucrado.
func next_incident() -> bool:
	if incidents.is_empty():
		_show_banner("No hubo incidentes", Color(0.6, 0.62, 0.68))
		return false
	var pick: Dictionary = incidents[0]
	for inc in incidents:
		if float(inc["time"]) - incident_lead > time + 0.5:
			pick = inc
			break
	seek(float(pick["time"]) - incident_lead)
	if int(pick["car"]) >= 0:
		set_follow(int(pick["car"]))
	_show_banner(str(pick["text"]), pick["color"])
	playing = true
	return true


func _unhandled_input(event: InputEvent) -> void:
	if not is_open():
		return
	var key := event as InputEventKey
	var handled := true
	if event.is_action_pressed("ui_cancel"):
		close()
	elif key != null and key.pressed and not key.echo and key.keycode == KEY_SPACE:
		playing = not playing
	elif event.is_action_pressed("ui_accept"):
		playing = not playing
	elif event.is_action_pressed("ui_left", true):
		seek(time - seek_step)
	elif event.is_action_pressed("ui_right", true):
		seek(time + seek_step)
	elif event.is_action_pressed("ui_up"):
		set_speed_index(speed_index + 1)
	elif event.is_action_pressed("ui_down"):
		set_speed_index(speed_index - 1)
	elif event.is_action_pressed("change_camera"):
		cycle_camera()
	elif key != null and key.pressed and not key.echo and key.keycode == KEY_Q:
		cycle_follow(-1)
	elif key != null and key.pressed and not key.echo and key.keycode == KEY_E:
		cycle_follow(1)
	elif key != null and key.pressed and not key.echo and key.keycode == KEY_I:
		next_incident()
	elif key != null and key.pressed and not key.echo and key.keycode == KEY_HOME:
		seek(_rec.start_time())
	else:
		handled = false
	if handled:
		get_viewport().set_input_as_handled()
		_update_info()


func _process(delta: float) -> void:
	if not is_open():
		return
	var before := time
	if playing:
		time = minf(time + delta * speeds[speed_index], _rec.end_time())
		if time >= _rec.end_time():
			playing = false
		for inc in incidents:
			var at := float(inc["time"])
			if at > before and at <= time:
				_show_banner(str(inc["text"]), inc["color"])
	_apply(delta)
	_tower_timer -= delta
	if _tower_timer <= 0.0:
		_refresh_tower()
	_banner_left -= delta
	_banner.visible = _banner_left > 0.0
	_update_info()
	_timeline.queue_redraw()


func _apply(delta: float) -> void:
	for i in _rec.cars.size():
		var car := _rec.cars[i]
		if is_instance_valid(car):
			car.global_transform = _rec.pose(i, time)
	var sc := _control.safety_car_node() if _control != null else null
	if sc != null:
		sc.visible = _rec.safety_car_visible(time)
		if sc.visible:
			sc.global_transform = _rec.safety_car_pose(time)
	var target := _rec.cars[follow]
	if not is_instance_valid(target):
		return
	var t := target.global_transform
	if camera == "chase":
		var forward := -t.basis.z
		forward.y = 0.0
		forward = forward.normalized() if forward.length() > 0.01 else Vector3.FORWARD
		var wanted := t.origin - forward * chase_distance + Vector3.UP * chase_height
		if _snap:
			_camera.global_position = wanted
		else:
			_camera.global_position = _camera.global_position.lerp(wanted, clampf(chase_smoothing * delta, 0.0, 1.0))
		var look := t.origin + forward * chase_look_ahead + Vector3.UP * 0.6
		if _camera.global_position.distance_to(look) > 0.5:
			_camera.look_at(look, Vector3.UP)
	elif camera == "onboard":
		_camera.global_transform = t * onboard_offset
	_snap = false


func _set_camera(mode: String) -> void:
	camera = mode
	_snap = true
	if mode == "tv":
		_tv.follow(_rec.cars[follow], _follow_velocity)
		_tv.set_active(true)
	else:
		_tv.set_active(false)
		_camera.fov = chase_fov if mode == "chase" else onboard_fov
		_camera.near = 0.3 if mode == "chase" else 0.1
		_camera.make_current()
	_apply(0.0)
	_update_info()


func _follow_velocity() -> Vector3:
	return _rec.velocity(follow, time)


func _build_incidents() -> void:
	incidents.clear()
	if _stewards != null:
		for inc in _stewards.incidents:
			var action := str(inc.get("action", ""))
			if action != "penalty" and action != "warning":
				continue
			incidents.append({"time": float(inc["time"]), "car": _rec.index_of(inc["guilty"]),
				"text": _stewards.describe(inc), "color": COLOR_PENALTY if action == "penalty" else COLOR_WARNING})
	if _control != null:
		for h in _control.history:
			var name := str(h["name"])
			var text := ""
			var color := Color.WHITE
			match str(h["event"]):
				"yellow":
					text = "Bandera amarilla: %s lento en la pista" % name
					color = COLOR_YELLOW
				"safety_car":
					text = "Safety Car en pista (%s)" % name if not name.is_empty() else "Safety Car en pista"
					color = COLOR_SC
				"green":
					text = "Bandera verde"
					color = COLOR_GREEN
			if text.is_empty():
				continue
			incidents.append({"time": _rec.from_race_time(float(h["time"])), "car": _car_named(name), "text": text, "color": color})
	incidents.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["time"]) < float(b["time"]))


func _car_named(short: String) -> int:
	if short.is_empty():
		return -1
	for i in _rec.cars.size():
		if RaceStewards.short_name(_rec.cars[i]) == short:
			return i
	return -1


## Filas de la torre (formato de RaceSession.tower_rows()) en el instante mostrado.
func tower_rows() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var order := _rec.order_at(time)
	var started := _rec.race_start >= 0.0 and time >= _rec.race_start
	var leader := order[0]
	var lead_progress := _rec.progress(leader, time)
	var total := _rec.lap_length
	for p in order.size():
		var i := order[p]
		var entry := _rec.entries[i]
		var done := _rec.finished(i, time)
		var text := ""
		if not started:
			text = "Grilla" if p == 0 else ""
		elif p == 0:
			var lap := _rec.laps if done else mini(floori(maxf(lead_progress, 0.0) / total) + 1, _rec.laps)
			text = "Vuelta %d/%d" % [lap, _rec.laps]
		elif done and _rec.finished(leader, time):
			var leader_entry := _rec.entries[leader]
			text = "+%.1f" % (float(entry["finish_time"]) - float(leader_entry["finish_time"]))
		else:
			var progress := _rec.progress(i, time)
			var down := floori((lead_progress - progress) / total)
			if down >= 1:
				text = "+%d %s" % [down, "vuelta" if down == 1 else "vueltas"]
			else:
				var reached := _rec.time_at_progress(leader, progress)
				text = "+%.1f" % maxf(time - reached, 0.0) if reached >= 0.0 else ""
		rows.append({"pos": p + 1, "code": entry["code"], "color": DataLoader.team_primary(entry["team"]),
			"gap": text, "penalty": _penalty_until(_rec.cars[i], time), "player": i == follow,
			"finished": done, "tyre": "", "tyre_color": Color.WHITE})
	return rows


func _penalty_until(car: CarController, t: float) -> float:
	var total := 0.0
	if _stewards == null:
		return total
	for inc in _stewards.incidents:
		if inc["guilty"] == car and str(inc.get("action", "")) == "penalty" and float(inc["time"]) <= t:
			total += float(inc.get("seconds", 0.0))
	return total


func _refresh_tower() -> void:
	_tower_timer = tower_refresh
	_tower.show_rows(tower_rows())


func _show_banner(text: String, color: Color) -> void:
	banner_text = text
	_banner_label.text = text
	_banner_style.bg_color = Color(color.r * 0.25, color.g * 0.25, color.b * 0.25, 0.85)
	_banner_style.border_color = color
	_banner_left = BANNER_TIME
	_banner.visible = true


func _update_info() -> void:
	if _rec == null or _rec.sample_count() == 0:
		return
	var race_t := _rec.race_time(time)
	var order := _rec.order_at(time)
	var entry := _rec.entries[follow]
	var lap := mini(floori(maxf(_rec.progress(follow, time), 0.0) / _rec.lap_length) + 1, _rec.laps)
	_clock_label.text = "%s   Vuelta %d/%d" % [LapTimer.format_time(maxf(race_t, 0.0)) if race_t > 0.0 else "Grilla", lap, _rec.laps]
	var speed := _rec.velocity(follow, time).length() * 3.6
	_info.text = "P%d  %s  ·  %d km/h  ·  Cámara: %s  ·  ×%s  %s" % [order.find(follow) + 1,
		str(entry["driver"].get("name", "")), roundi(speed), CAMERA_NAMES[camera], _speed_text(speeds[speed_index]),
		"▶" if playing else "PAUSA"]


static func _speed_text(s: float) -> String:
	return ("%.2f" % s).trim_suffix("0").trim_suffix("0").trim_suffix(".")


func _build_ui() -> void:
	_root = Control.new()
	_root.name = "Root"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 18)
	UiKit.place(header, Vector4(0, 0, 0, 0), Vector4(24, 18, 900, 70))
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(header)
	var rec := UiKit.make_label("● REPETICIÓN", 30)
	rec.add_theme_color_override("font_color", COLOR_REC)
	rec.add_theme_color_override("font_outline_color", Color.BLACK)
	rec.add_theme_constant_override("outline_size", 6)
	header.add_child(rec)
	_clock_label = UiKit.make_label("", 26)
	_clock_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_clock_label.add_theme_constant_override("outline_size", 6)
	header.add_child(_clock_label)

	_tower = TimingTower.new()
	UiKit.place(_tower, Vector4(0, 0, 0, 0), Vector4(24, 80, 24 + TimingTower.WIDTH, 80))
	_root.add_child(_tower)

	_banner_style = StyleBoxFlat.new()
	_banner_style.bg_color = Color(0.1, 0.1, 0.12, 0.85)
	_banner_style.set_border_width_all(0)
	_banner_style.border_width_left = 6
	_banner_style.set_corner_radius_all(4)
	_banner_style.content_margin_left = 16
	_banner_style.content_margin_right = 16
	_banner_style.content_margin_top = 6
	_banner_style.content_margin_bottom = 6
	_banner = PanelContainer.new()
	_banner.add_theme_stylebox_override("panel", _banner_style)
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiKit.place(_banner, Vector4(0.5, 0, 0.5, 0), Vector4(-330, 90, 330, 90))
	_banner.visible = false
	_root.add_child(_banner)
	_banner_label = UiKit.make_label("", 22, HORIZONTAL_ALIGNMENT_CENTER)
	_banner_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_banner.add_child(_banner_label)

	var bottom := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.03, 0.05, 0.72)
	style.set_corner_radius_all(4)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	bottom.add_theme_stylebox_override("panel", style)
	UiKit.place(bottom, Vector4(0, 1, 1, 1), Vector4(24, -112, -24, -16))
	_root.add_child(bottom)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	bottom.add_child(column)
	_info = UiKit.make_label("", 20)
	column.add_child(_info)
	_timeline = Timeline.new()
	_timeline.viewer = self
	_timeline.custom_minimum_size = Vector2(0, 20)
	_timeline.mouse_filter = Control.MOUSE_FILTER_STOP
	column.add_child(_timeline)
	_help = UiKit.make_label("", 15)
	_help.add_theme_color_override("font_color", Color(0.75, 0.77, 0.82))
	column.add_child(_help)
	_update_help()


func _update_help() -> void:
	if _help == null:
		return
	_help.text = "Espacio pausa · ←/→ %s s · flechas arriba/abajo velocidad · C cámara · Q/E auto · I incidente · Inicio largada · Esc salir" % _speed_text(seek_step)
