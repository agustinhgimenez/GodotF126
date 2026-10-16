class_name RaceHUD
extends CanvasLayer
## HUD: velocidad, marcha y RPM, piloto/equipo, pista, tiempos por vuelta y sectores.

const COLOR_RPM_LOW := Color(0.2, 0.85, 0.3)
const COLOR_RPM_HIGH := Color(1.0, 0.2, 0.15)
const RPM_HIGH_RATIO := 0.85
const COLOR_BEST := Color(0.75, 0.35, 1.0)
const COLOR_SLOWER := Color(1.0, 0.85, 0.2)
const COLOR_NEUTRAL := Color.WHITE
const LAP_FREEZE_MS := 3000

var _car: CarController = null
var _timer: LapTimer = null
var _freeze_until_ms: int = 0
var _message_until_ms: int = 0

var _speed_label: Label
var _speed_bar: ProgressBar
var _gear_label: Label
var _rpm_bar: ProgressBar
var _rpm_fill: StyleBoxFlat
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


func _ready() -> void:
	_build_ui()


func bind_car(car: CarController) -> void:
	_car = car
	_speed_bar.max_value = maxf(car.max_speed * 3.6, 1.0)
	_rpm_bar.min_value = car.engine.idle_rpm
	_rpm_bar.max_value = car.engine.limiter_rpm
	car.camera_changed.connect(func(mode_name: String) -> void: show_message(mode_name, 1.2))
	car.gearbox.shift_denied.connect(func(reason: String) -> void: show_message(reason, 1.2, COLOR_SLOWER))
	car.gearbox.mode_changed.connect(_on_gearbox_mode_changed)


func bind_lap_timer(timer: LapTimer) -> void:
	_timer = timer
	timer.lap_started.connect(_on_lap_started)
	timer.sector_completed.connect(_on_sector_completed)
	timer.lap_completed.connect(_on_lap_completed)
	timer.lap_aborted.connect(_on_lap_aborted)
	_reset_sectors()
	_update_summary()


func set_driver_info(driver: Dictionary, team: Dictionary, team_color: Color) -> void:
	_driver_label.text = "#%s  %s" % [str(driver.get("number", "?")), str(driver.get("name", "Piloto"))]
	_team_label.text = str(team.get("name", "Equipo"))
	_team_stripe.color = team_color


func set_track_name(track_name: String) -> void:
	_track_label.text = track_name


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
		_speed_label.text = "%d" % roundi(kmh)
		_speed_bar.value = kmh
		var rpm := _car.get_rpm()
		var mode := "MAN" if _car.gearbox.manual else "AUT"
		_gear_label.text = "%s   %s   %d rpm" % [mode, _car.get_gear_label(), roundi(rpm)]
		_rpm_bar.value = rpm
		var high := _car.engine.get_rpm_ratio() >= RPM_HIGH_RATIO
		_rpm_fill.bg_color = COLOR_RPM_HIGH if high else COLOR_RPM_LOW
		_drift_label.visible = kmh > 30.0 and _car.get_slip_angle_deg() > 12.0

	if _timer != null:
		if not _timer.running:
			_lap_label.text = "CRUZÁ LA LÍNEA PARA CRONOMETRAR"
			_time_label.text = LapTimer.format_time(-1.0)
			_set_color(_time_label, COLOR_NEUTRAL)
		elif now >= _freeze_until_ms:
			_lap_label.text = "VUELTA %d" % _timer.lap
			_time_label.text = LapTimer.format_time(_timer.current_time)
			_set_color(_time_label, COLOR_NEUTRAL)


func _on_gearbox_mode_changed(manual: bool) -> void:
	show_message("Caja manual (E/Q)" if manual else "Caja automática", 1.5)


func _on_lap_started(lap: int) -> void:
	if lap == 1:
		_reset_sectors()
		show_message("¡Cronómetro en marcha!", 1.5)


func _on_sector_completed(sector: int, time: float, is_best: bool) -> void:
	if sector == 0:
		_reset_sectors()
	var label := _sector_labels[sector]
	label.text = "S%d  %.3f" % [sector + 1, time]
	_set_color(label, COLOR_BEST if is_best else COLOR_SLOWER)


func _on_lap_completed(lap: int, time: float, is_best: bool, is_record: bool) -> void:
	_freeze_until_ms = Time.get_ticks_msec() + LAP_FREEZE_MS
	_lap_label.text = "VUELTA %d TERMINADA" % lap
	_time_label.text = LapTimer.format_time(time)
	_set_color(_time_label, COLOR_BEST if is_best else COLOR_SLOWER)
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

	# Abajo a la derecha: velocímetro.
	var speed_box := VBoxContainer.new()
	speed_box.alignment = BoxContainer.ALIGNMENT_END
	_place(speed_box, Vector4(1, 1, 1, 1), Vector4(-324, -210, -24, -20))
	root.add_child(speed_box)

	_speed_label = _make_label(64, HORIZONTAL_ALIGNMENT_RIGHT, "0")
	speed_box.add_child(_speed_label)
	speed_box.add_child(_make_label(20, HORIZONTAL_ALIGNMENT_RIGHT, "km/h"))

	_speed_bar = ProgressBar.new()
	_speed_bar.show_percentage = false
	_speed_bar.custom_minimum_size = Vector2(300, 14)
	speed_box.add_child(_speed_bar)

	_gear_label = _make_label(26, HORIZONTAL_ALIGNMENT_RIGHT, "1   0 rpm")
	speed_box.add_child(_gear_label)

	_rpm_bar = ProgressBar.new()
	_rpm_bar.show_percentage = false
	_rpm_bar.custom_minimum_size = Vector2(300, 14)
	_rpm_fill = StyleBoxFlat.new()
	_rpm_fill.bg_color = COLOR_RPM_LOW
	_rpm_bar.add_theme_stylebox_override("fill", _rpm_fill)
	speed_box.add_child(_rpm_bar)

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

	# Abajo a la izquierda: controles.
	var hint := _make_label(16, HORIZONTAL_ALIGNMENT_LEFT,
		"W acelerar · S frenar · A/D girar · E/Q subir/bajar marcha · M caja man/aut · Espacio freno de mano · C cámara · R reiniciar · Esc salir")
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_place(hint, Vector4(0, 1, 0, 1), Vector4(24, -64, 900, -20))
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
