class_name RaceHUD
extends CanvasLayer
## HUD: tablero (Dashboard), piloto/equipo, pista, tiempos por vuelta y sectores.

const COLOR_BEST := Color(0.75, 0.35, 1.0)
const COLOR_SLOWER := Color(1.0, 0.85, 0.2)
const COLOR_NEUTRAL := Color.WHITE
const COLOR_INVALID := Color(0.6, 0.6, 0.64)
const COLOR_WARNING := Color(1.0, 0.35, 0.3)
const LAP_FREEZE_MS := 3000

var _car: CarController = null
var _timer: LapTimer = null
var _freeze_until_ms: int = 0
var _message_until_ms: int = 0

var _dashboard: Dashboard
var _driver_label: Label
var _team_label: Label
var _team_stripe: ColorRect
var _track_label: Label
var _drift_label: Label
var _lap_label: Label
var _time_label: Label
var _summary_label: Label
var _sector_labels: Array[Label] = []
var _message_label: Label
var _start_lights: StartLightsDisplay
var _start_hint: Label
var _wheel_loads: WheelLoadsPanel


func _ready() -> void:
	_build_ui()


func bind_car(car: CarController) -> void:
	_car = car
	_dashboard.bind_car(car)
	_wheel_loads.bind_car(car)
	car.camera_changed.connect(func(mode_name: String) -> void: show_message(mode_name, 1.2))
	car.gearbox.shift_denied.connect(func(reason: String) -> void: show_message(reason, 1.2, COLOR_SLOWER))
	car.gearbox.mode_changed.connect(_on_gearbox_mode_changed)


func configure_dashboard(data: Dictionary) -> void:
	_dashboard.configure(data)


func bind_lap_timer(timer: LapTimer) -> void:
	_timer = timer
	timer.lap_started.connect(_on_lap_started)
	timer.sector_completed.connect(_on_sector_completed)
	timer.lap_completed.connect(_on_lap_completed)
	timer.lap_aborted.connect(_on_lap_aborted)
	timer.session_finished.connect(func() -> void: show_message("¡BANDERA A CUADROS!", 3.0, COLOR_BEST))
	timer.lap_invalidated.connect(func(reason: String) -> void:
		show_message("VUELTA INVALIDADA · %s" % reason.to_lower(), 2.5, COLOR_WARNING))
	_reset_sectors()
	_update_summary()


## Largada detenida (Paso 17): muestra el semáforo hasta que termina la secuencia.
func bind_start_lights(lights: StartLights) -> void:
	_start_lights.visible = true
	_start_hint.visible = true
	lights.lights_changed.connect(_start_lights.set_lights)
	lights.lights_out.connect(func() -> void:
		_start_hint.visible = false
		if not lights.jumped:
			show_message("¡LARGADA!", 1.5))
	lights.jump_start.connect(func() -> void:
		show_message("¡LARGADA EN FALSO! Penalización", 3.0, COLOR_SLOWER))
	lights.reaction_measured.connect(func(seconds: float) -> void:
		show_message("Reacción %.3f s" % seconds, 2.5))
	lights.finished.connect(func() -> void: _start_lights.visible = false)


func set_driver_info(driver: Dictionary, team: Dictionary, team_color: Color) -> void:
	var number = driver.get("number", "?")
	var number_text := str(int(number)) if number is float else str(number)
	_driver_label.text = "#%s  %s" % [number_text, str(driver.get("name", "Piloto"))]
	_team_label.text = str(team.get("name", "Equipo"))
	_team_stripe.color = team_color


func set_track_name(track_name: String) -> void:
	_track_label.text = track_name


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_telemetry"):
		set_wheel_loads_visible(not _wheel_loads.visible)


func set_wheel_loads_visible(enabled: bool) -> void:
	_wheel_loads.visible = enabled


func is_wheel_loads_visible() -> bool:
	return _wheel_loads.visible


func show_message(text: String, seconds: float = 2.0, color: Color = COLOR_NEUTRAL) -> void:
	_message_label.text = text
	_message_label.add_theme_color_override("font_color", color)
	_message_label.visible = true
	_message_until_ms = Time.get_ticks_msec() + int(seconds * 1000.0)


func _process(_delta: float) -> void:
	var now := Time.get_ticks_msec()
	if _message_label.visible and now > _message_until_ms:
		_message_label.visible = false

	if _car != null:
		var kmh := _car.get_speed_kmh()
		_drift_label.visible = kmh > 30.0 and _car.get_slip_angle_deg() > 12.0

	if _timer != null:
		if _start_hint.visible:
			_lap_label.text = "LARGADA DETENIDA"
			_time_label.text = LapTimer.format_time(-1.0)
		elif _timer.finished:
			if now >= _freeze_until_ms:
				_lap_label.text = "SESIÓN TERMINADA"
				_time_label.text = LapTimer.format_time(_timer.total_time())
		elif not _timer.running:
			_lap_label.text = "CRUZÁ LA LÍNEA PARA CRONOMETRAR"
			_time_label.text = LapTimer.format_time(-1.0)
			_set_color(_time_label, COLOR_NEUTRAL)
		elif now >= _freeze_until_ms:
			_lap_label.text = _lap_text(_timer.lap)
			_time_label.text = LapTimer.format_time(_timer.current_time)
			if _timer.current_invalid:
				_lap_label.text += " · INVALIDADA"
			_set_color(_time_label, COLOR_INVALID if _timer.current_invalid else COLOR_NEUTRAL)


func _lap_text(lap: int) -> String:
	if _timer.lap_limit > 0:
		return "VUELTA %d / %d" % [lap, _timer.lap_limit]
	return "VUELTA %d" % lap


func _on_gearbox_mode_changed(manual: bool) -> void:
	show_message("Caja manual (E/Q)" if manual else "Caja automática", 1.5)


func _on_lap_started(lap: int) -> void:
	if lap == 1:
		_reset_sectors()
		show_message("¡Cronómetro en marcha!", 1.5)
	elif _timer.lap_limit > 0 and lap == _timer.lap_limit:
		show_message("¡ÚLTIMA VUELTA!", 2.0, COLOR_SLOWER)


func _on_sector_completed(sector: int, time: float, is_best: bool) -> void:
	if sector == 0:
		_reset_sectors()
	var label := _sector_labels[sector]
	label.text = "S%d  %.3f" % [sector + 1, time]
	_set_color(label, COLOR_INVALID if _timer.current_invalid else (COLOR_BEST if is_best else COLOR_SLOWER))


func _on_lap_completed(lap: int, time: float, is_best: bool, is_record: bool) -> void:
	_freeze_until_ms = Time.get_ticks_msec() + LAP_FREEZE_MS
	_lap_label.text = "VUELTA %d TERMINADA" % lap
	_time_label.text = LapTimer.format_time(time)
	var invalid := not _timer.lap_history.is_empty() and bool(_timer.lap_history.back().get("invalid", false))
	if invalid:
		_lap_label.text += " · NO VÁLIDA"
	_set_color(_time_label, COLOR_INVALID if invalid else (COLOR_BEST if is_best else COLOR_SLOWER))
	if is_record:
		show_message("¡NUEVO RÉCORD DE PISTA!", 3.0, COLOR_BEST)
	elif is_best:
		show_message("¡MEJOR VUELTA!", 3.0, COLOR_BEST)
	_update_summary()


func _on_lap_aborted() -> void:
	_freeze_until_ms = 0
	_reset_sectors()
	show_message("Vuelta anulada", 1.5, COLOR_SLOWER)


func _reset_sectors() -> void:
	for i in _sector_labels.size():
		_sector_labels[i].text = "S%d  --.---" % (i + 1)
		_set_color(_sector_labels[i], COLOR_NEUTRAL)


func _update_summary() -> void:
	if _timer == null:
		return
	_summary_label.text = "Última %s    Mejor %s    Récord %s" % [
		LapTimer.format_time(_timer.last_lap),
		LapTimer.format_time(_timer.best_lap),
		LapTimer.format_time(_timer.record_lap),
	]


func _build_ui() -> void:
	var root := Control.new()
	root.name = "Root"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# Arriba a la izquierda: piloto y equipo.
	var driver_box := HBoxContainer.new()
	driver_box.add_theme_constant_override("separation", 12)
	_place(driver_box, Vector4(0, 0, 0, 0), Vector4(24, 20, 400, 90))
	root.add_child(driver_box)

	_team_stripe = ColorRect.new()
	_team_stripe.custom_minimum_size = Vector2(8, 64)
	_team_stripe.color = Color.WHITE
	driver_box.add_child(_team_stripe)

	var driver_text := VBoxContainer.new()
	driver_box.add_child(driver_text)
	_driver_label = _make_label(28)
	_team_label = _make_label(20)
	driver_text.add_child(_driver_label)
	driver_text.add_child(_team_label)

	# Arriba al centro: cronómetro.
	var timing_box := VBoxContainer.new()
	timing_box.add_theme_constant_override("separation", 2)
	_place(timing_box, Vector4(0.5, 0, 0.5, 0), Vector4(-220, 12, 220, 170))
	root.add_child(timing_box)

	_lap_label = _make_label(18, HORIZONTAL_ALIGNMENT_CENTER)
	_time_label = _make_label(44, HORIZONTAL_ALIGNMENT_CENTER, LapTimer.format_time(-1.0))
	timing_box.add_child(_lap_label)
	timing_box.add_child(_time_label)

	var sectors_row := HBoxContainer.new()
	sectors_row.alignment = BoxContainer.ALIGNMENT_CENTER
	sectors_row.add_theme_constant_override("separation", 24)
	timing_box.add_child(sectors_row)
	for i in LapTimer.SECTOR_COUNT:
		var sector_label := _make_label(18, HORIZONTAL_ALIGNMENT_CENTER)
		_sector_labels.append(sector_label)
		sectors_row.add_child(sector_label)

	_summary_label = _make_label(16, HORIZONTAL_ALIGNMENT_CENTER)
	timing_box.add_child(_summary_label)

	# Arriba a la derecha: pista.
	_track_label = _make_label(22, HORIZONTAL_ALIGNMENT_RIGHT)
	_place(_track_label, Vector4(1, 0, 1, 0), Vector4(-380, 24, -24, 60))
	_track_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_track_label)

	# Abajo a la derecha: tablero.
	_dashboard = Dashboard.new()
	_dashboard.name = "Dashboard"
	_place(_dashboard, Vector4(1, 1, 1, 1),
		Vector4(-Dashboard.SIZE.x - 24, -Dashboard.SIZE.y - 20, -24, -20))
	root.add_child(_dashboard)

	# Centro: mensajes y aviso de derrape.
	_message_label = _make_label(30, HORIZONTAL_ALIGNMENT_CENTER)
	_message_label.visible = false
	_place(_message_label, Vector4(0.5, 0, 0.5, 0), Vector4(-300, 200, 300, 240))
	root.add_child(_message_label)

	_drift_label = _make_label(28, HORIZONTAL_ALIGNMENT_CENTER, "DERRAPE")
	_set_color(_drift_label, Color(1, 0.8, 0.2))
	_drift_label.visible = false
	_place(_drift_label, Vector4(0.5, 0, 0.5, 0), Vector4(-200, 250, 200, 290))
	root.add_child(_drift_label)

	# Centro: semáforo de largada (sólo en largada detenida).
	_start_lights = StartLightsDisplay.new()
	_start_lights.name = "StartLights"
	_start_lights.visible = false
	_place(_start_lights, Vector4(0.5, 0, 0.5, 0),
		Vector4(-StartLightsDisplay.SIZE.x * 0.5, 290, StartLightsDisplay.SIZE.x * 0.5, 290 + StartLightsDisplay.SIZE.y))
	root.add_child(_start_lights)
	_start_hint = _make_label(18, HORIZONTAL_ALIGNMENT_CENTER,
		"Esperá que se apaguen las luces · en 1ª acelerar mueve el auto (Q para N y acelerar quieto)")
	_start_hint.visible = false
	_place(_start_hint, Vector4(0.5, 0, 0.5, 0), Vector4(-460, 420, 460, 450))
	root.add_child(_start_hint)

	# A la izquierda, debajo del piloto: panel de cargas por rueda (F3).
	_wheel_loads = WheelLoadsPanel.new()
	_wheel_loads.name = "WheelLoads"
	_wheel_loads.visible = false
	_place(_wheel_loads, Vector4(0, 0, 0, 0),
		Vector4(24, 110, 24 + WheelLoadsPanel.SIZE.x, 110 + WheelLoadsPanel.SIZE.y))
	root.add_child(_wheel_loads)

	# Abajo a la izquierda: controles.
	var hint := _make_label(16, HORIZONTAL_ALIGNMENT_LEFT,
		"W/S acelerar/frenar · A/D girar · E/Q marchas · C cámara · R volver a la pista · Esc pausa y controles")
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_place(hint, Vector4(0, 1, 0, 1), Vector4(24, -84, 760, -20))
	root.add_child(hint)


## anchors = (left, top, right, bottom); offsets en píxeles, mismo orden.
func _place(control: Control, anchors: Vector4, offsets: Vector4) -> void:
	control.anchor_left = anchors.x
	control.anchor_top = anchors.y
	control.anchor_right = anchors.z
	control.anchor_bottom = anchors.w
	control.offset_left = offsets.x
	control.offset_top = offsets.y
	control.offset_right = offsets.z
	control.offset_bottom = offsets.w
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _set_color(label: Label, color: Color) -> void:
	label.add_theme_color_override("font_color", color)


func _make_label(font_size: int, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT,
		text: String = "") -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = align
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 6)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
