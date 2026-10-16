class_name ResultsScreen
extends CanvasLayer
## Resultado del contrarreloj (Paso 16), armado por código con el estilo de PauseMenu.
## Tabla con el tiempo y los sectores de cada vuelta; la mejor vuelta y el mejor tiempo de
## cada sector de la sesión van en violeta. Abajo: total, mejor vuelta y récord.
## Pausa el árbol mientras se muestra; este nodo sigue procesando.

signal repeat_requested
signal menu_requested

const COLOR_BEST := Color(0.75, 0.35, 1.0)
const COLOR_HEADER := Color(0.7, 0.72, 0.78)
const COLOR_RECORD := Color(1.0, 0.85, 0.2)
const COLOR_INVALID := Color(0.55, 0.55, 0.6)
const COLUMN_WIDTHS := [110.0, 150.0, 150.0, 150.0, 170.0]

var accent: Color = Color("#FF87BC")

var _root: Control
var _subtitle: Label
var _table: GridContainer
var _summary: VBoxContainer
var _repeat_button: Button
var _buttons: Array[Button] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 11
	_build_ui()
	_root.visible = false


func is_open() -> bool:
	return _root.visible


func set_accent(color: Color) -> void:
	accent = color
	for button in _buttons:
		UiKit.apply_button_style(button, color)


## Arma la tabla desde el historial del cronómetro y pausa el juego.
func open(timer: LapTimer, subtitle: String) -> void:
	_subtitle.text = subtitle
	_fill_table(timer)
	_fill_summary(timer)
	get_tree().paused = true
	_root.visible = true
	_repeat_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if is_open() and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_leave(menu_requested)


func _leave(request: Signal) -> void:
	_root.visible = false
	get_tree().paused = false
	request.emit()


func _fill_table(timer: LapTimer) -> void:
	for child in _table.get_children():
		child.queue_free()
	var best_sectors := _session_best_sectors(timer.lap_history)
	var best_lap := _session_best_lap(timer.lap_history)

	var headers := ["Vuelta"]
	for i in LapTimer.SECTOR_COUNT:
		headers.append("S%d" % (i + 1))
	headers.append("Tiempo")
	for i in headers.size():
		_add_cell(headers[i], i, 18, COLOR_HEADER)

	# Con muchas vueltas la letra se achica para que la tabla no pise el resumen.
	var row_size := 22 if timer.lap_history.size() <= 5 else 17
	for entry in timer.lap_history:
		var invalid := bool(entry.get("invalid", false))
		var base_color := COLOR_INVALID if invalid else Color.WHITE
		var column := 0
		_add_cell(str(entry["lap"]) + (" *" if invalid else ""), column, row_size, base_color)
		var sectors: Array = entry["sectors"]
		for i in LapTimer.SECTOR_COUNT:
			column += 1
			var sector_time: float = float(sectors[i]) if i < sectors.size() else -1.0
			var is_best := not invalid and sector_time >= 0.0 and is_equal_approx(sector_time, best_sectors[i])
			_add_cell("%.3f" % sector_time if sector_time >= 0.0 else "--.---", column, row_size,
				COLOR_BEST if is_best else base_color)
		var lap_time := float(entry["time"])
		var is_best_lap := not invalid and is_equal_approx(lap_time, best_lap)
		_add_cell(LapTimer.format_time(lap_time), column + 1, row_size,
			COLOR_BEST if is_best_lap else base_color)


func _fill_summary(timer: LapTimer) -> void:
	for child in _summary.get_children():
		child.queue_free()
	_summary.add_child(UiKit.make_label("Tiempo total   %s" % LapTimer.format_time(timer.total_time()), 26))
	if timer.penalty > 0.0:
		var penalty := UiKit.make_label("Penalización   +%.0f s (%s)" % [timer.penalty, timer.penalty_reason], 20)
		penalty.add_theme_color_override("font_color", Color(1.0, 0.35, 0.3))
		_summary.add_child(penalty)
	elif timer.reaction_time >= 0.0:
		_summary.add_child(UiKit.make_label("Reacción en la largada   %.3f s" % timer.reaction_time, 20))
	var best := UiKit.make_label("Mejor vuelta   %s" % LapTimer.format_time(_session_best_lap(timer.lap_history)), 22)
	best.add_theme_color_override("font_color", COLOR_BEST)
	_summary.add_child(best)
	var invalid_count := 0
	for entry in timer.lap_history:
		if bool(entry.get("invalid", false)):
			invalid_count += 1
	if invalid_count > 0:
		var note := UiKit.make_label("* Vuelta invalidada por límites de pista (no cuenta para mejor vuelta ni récord)", 16)
		note.add_theme_color_override("font_color", COLOR_INVALID)
		_summary.add_child(note)
	var record_text := "Récord de la pista   %s" % LapTimer.format_time(timer.record_lap)
	if timer.beat_record():
		record_text += "   ¡NUEVO RÉCORD!"
	var record := UiKit.make_label(record_text, 20)
	record.add_theme_color_override("font_color", COLOR_RECORD if timer.beat_record() else Color(0.85, 0.86, 0.9))
	_summary.add_child(record)


func _session_best_lap(history: Array[Dictionary]) -> float:
	var best := -1.0
	for entry in history:
		if bool(entry.get("invalid", false)):
			continue
		var time := float(entry["time"])
		if best < 0.0 or time < best:
			best = time
	return best


func _session_best_sectors(history: Array[Dictionary]) -> Array[float]:
	var best: Array[float] = []
	best.resize(LapTimer.SECTOR_COUNT)
	best.fill(-1.0)
	for entry in history:
		if bool(entry.get("invalid", false)):
			continue
		var sectors: Array = entry["sectors"]
		for i in mini(sectors.size(), LapTimer.SECTOR_COUNT):
			var time := float(sectors[i])
			if best[i] < 0.0 or time < best[i]:
				best[i] = time
	return best


func _add_cell(text: String, column: int, font_size: int, color: Color) -> void:
	var align := HORIZONTAL_ALIGNMENT_LEFT if column == 0 else HORIZONTAL_ALIGNMENT_RIGHT
	var label := UiKit.make_label(text, font_size, align)
	label.custom_minimum_size = Vector2(COLUMN_WIDTHS[column], 0)
	label.add_theme_color_override("font_color", color)
	_table.add_child(label)


func _build_ui() -> void:
	_root = Control.new()
	_root.name = "Root"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)

	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.02, 0.04, 0.75)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)

	var header := VBoxContainer.new()
	header.add_theme_constant_override("separation", 4)
	UiKit.place(header, Vector4(0, 0, 0, 0), Vector4(80, 50, 1200, 160))
	_root.add_child(header)
	header.add_child(UiKit.make_label("Contrarreloj — Resultado", 48))
	_subtitle = UiKit.make_label("", 22)
	_subtitle.add_theme_color_override("font_color", Color(0.85, 0.86, 0.9))
	header.add_child(_subtitle)

	_table = GridContainer.new()
	_table.columns = COLUMN_WIDTHS.size()
	_table.add_theme_constant_override("h_separation", 12)
	_table.add_theme_constant_override("v_separation", 6)
	UiKit.place(_table, Vector4(0, 0, 0, 0), Vector4(80, 180, 900, 480))
	_root.add_child(_table)

	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 60)
	UiKit.place(bottom, Vector4(0, 1, 0, 1), Vector4(80, -200, 1200, -40))
	_root.add_child(bottom)

	_summary = VBoxContainer.new()
	_summary.add_theme_constant_override("separation", 4)
	_summary.custom_minimum_size = Vector2(560, 0)
	bottom.add_child(_summary)

	var actions := VBoxContainer.new()
	actions.add_theme_constant_override("separation", 12)
	bottom.add_child(actions)
	_repeat_button = _add_button(actions, "Repetir", func() -> void: _leave(repeat_requested))
	_add_button(actions, "Menú principal", func() -> void: _leave(menu_requested))


func _add_button(parent: Control, text: String, action: Callable) -> Button:
	var button := UiKit.make_button(text, accent)
	button.pressed.connect(action)
	parent.add_child(button)
	_buttons.append(button)
	return button
