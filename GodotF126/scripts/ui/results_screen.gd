class_name ResultsScreen
extends CanvasLayer
## Resultado del contrarreloj (Paso 16), armado por código con el estilo de PauseMenu.
## Tabla con el tiempo y los sectores de cada vuelta; la mejor vuelta y el mejor tiempo de
## cada sector de la sesión van en violeta. Abajo: total, mejor vuelta y récord.
## Pausa el árbol mientras se muestra; este nodo sigue procesando.
## Paso 47: open_standings() muestra una tabla de posiciones (clasificación o carrera de 22
## autos) con el resumen y los botones a la derecha, y un botón extra opcional ("Correr la
## carrera" después de la clasificación). Paso 51: "Ver repetición" después de la carrera.
## Paso 52: open_race() muestra el podio a la derecha y varias vistas de la tabla (pilotos,
## equipos, sanciones) que se cambian con el botón "Ver …" o con ←/→.

signal repeat_requested
signal menu_requested
signal next_requested
## Paso 51: botón "Ver repetición" (sólo después de la carrera).
signal replay_requested

const COLOR_BEST := Color(0.75, 0.35, 1.0)
const COLOR_HEADER := Color(0.7, 0.72, 0.78)
const COLOR_RECORD := Color(1.0, 0.85, 0.2)
const COLOR_INVALID := Color(0.55, 0.55, 0.6)
const COLUMN_WIDTHS := [110.0, 150.0, 150.0, 150.0, 170.0]

var accent: Color = Color("#FF87BC")

var _root: Control
var _title: Label
var _subtitle: Label
var _table: GridContainer
var _bottom: BoxContainer
var _summary: VBoxContainer
var _repeat_button: Button
var _next_button: Button
var _replay_button: Button
var _view_button: Button
var _buttons: Array[Button] = []
var _podium: Podium
## Paso 52: vistas de open_race() ({name, headers, widths, rows, left}) y la que se ve.
var views: Array[Dictionary] = []
var view_index: int = 0
var _left_columns: int = 3


## Podio de los 3 primeros: escalones del color del equipo (2.º, 1.º, 3.º), código y puntos.
class Podium extends Control:
	const STEP_HEIGHTS := [56.0, 40.0, 30.0]
	const ORDER := [1, 0, 2]
	var places: Array = []

	func _draw() -> void:
		var font := get_theme_default_font()
		var width := size.x / 3.0
		for slot in 3:
			var i: int = ORDER[slot]
			if i >= places.size():
				continue
			var place: Dictionary = places[i]
			var color: Color = place.get("color", Color.WHITE)
			var h: float = STEP_HEIGHTS[i]
			var rect := Rect2(slot * width + 4.0, size.y - h, width - 8.0, h)
			draw_rect(rect, color.darkened(0.25))
			draw_rect(Rect2(rect.position, Vector2(rect.size.x, 4.0)), color.lightened(0.25))
			draw_string(font, Vector2(rect.position.x, rect.position.y + h * 0.5 + 10.0), str(i + 1),
				HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 26, Color.WHITE)
			draw_string(font, Vector2(rect.position.x, rect.position.y - 26.0), str(place.get("code", "")),
				HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 20, Color.WHITE)
			draw_string(font, Vector2(rect.position.x, rect.position.y - 8.0), str(place.get("detail", "")),
				HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 14, Color(0.8, 0.82, 0.88))


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 11
	_build_ui()
	_root.visible = false


## Paso 52: verde si ganó lugares, rojo si perdió, gris si quedó igual.
static func change_color(change: int) -> Color:
	if change > 0:
		return Color(0.4, 0.9, 0.45)
	if change < 0:
		return Color(1.0, 0.4, 0.35)
	return COLOR_HEADER


func is_open() -> bool:
	return _root.visible


func set_accent(color: Color) -> void:
	accent = color
	for button in _buttons:
		UiKit.apply_button_style(button, color)


## Arma la tabla desde el historial del cronómetro y pausa el juego.
func open(timer: LapTimer, subtitle: String) -> void:
	_subtitle.text = subtitle
	views.clear()
	_view_button.visible = false
	_podium.visible = false
	_table.columns = COLUMN_WIDTHS.size()
	_fill_table(timer)
	_fill_summary(timer)
	get_tree().paused = true
	_root.visible = true
	_repeat_button.grab_focus()


## Tabla de posiciones: rows = {cells: Array (textos), color: Color, highlight: bool};
## summary = [texto, color] por línea. Con next_text, el botón extra emite next_requested.
func open_standings(title: String, subtitle: String, headers: Array, widths: Array, rows: Array,
		summary: Array, next_text: String = "") -> void:
	_title.text = title
	_subtitle.text = subtitle
	views.clear()
	_view_button.visible = false
	_podium.visible = false
	_show_table(headers, widths, rows)
	_show_summary(summary, 18)
	_next_button.visible = not next_text.is_empty()
	_next_button.text = next_text
	get_tree().paused = true
	_root.visible = true
	(_next_button if _next_button.visible else _repeat_button).grab_focus()


## Paso 52: resultado de la carrera. views = [{name, headers, widths, rows, left (columnas
## alineadas a la izquierda)}], la primera se muestra; podium = [{code, detail, color}] del 1.º
## al 3.º. Las filas pueden traer "cell_colors" ({columna: Color}).
func open_race(title: String, subtitle: String, view_list: Array[Dictionary], podium: Array,
		summary: Array) -> void:
	_title.text = title
	_subtitle.text = subtitle
	views = view_list
	_podium.places = podium
	_podium.visible = not podium.is_empty()
	_podium.queue_redraw()
	_show_summary(summary, 16)
	_next_button.visible = false
	_view_button.visible = views.size() > 1
	show_view(0)
	get_tree().paused = true
	_root.visible = true
	_repeat_button.grab_focus()


func show_view(index: int) -> void:
	if views.is_empty():
		return
	view_index = wrapi(index, 0, views.size())
	var view := views[view_index]
	_show_table(view["headers"], view["widths"], view["rows"], int(view.get("left", 3)))
	_view_button.text = "Ver %s" % str(views[(view_index + 1) % views.size()]["name"]).to_lower()


func view_name() -> String:
	return str(views[view_index]["name"]) if not views.is_empty() else ""


func _show_table(headers: Array, widths: Array, rows: Array, left: int = 3) -> void:
	for child in _table.get_children():
		_table.remove_child(child)
		child.queue_free()
	_left_columns = left
	_table.columns = headers.size()
	_table.add_theme_constant_override("v_separation", 1)
	UiKit.place(_table, Vector4(0, 0, 0, 0), Vector4(50, 150, 940, 700))
	for i in headers.size():
		_add_cell(str(headers[i]), i, 16, COLOR_HEADER, widths)
	for row in rows:
		var color: Color = row.get("color", Color.WHITE)
		var cell_colors: Dictionary = row.get("cell_colors", {})
		var cells: Array = row["cells"]
		for i in cells.size():
			var label := _add_cell(str(cells[i]), i, 15, cell_colors.get(i, color), widths)
			if row.get("highlight", false):
				label.add_theme_color_override("font_outline_color", Color(0.35, 0.3, 0.05))
				label.add_theme_constant_override("outline_size", 6)


func _show_summary(summary: Array, font_size: int) -> void:
	for child in _summary.get_children():
		if child != _podium:
			child.queue_free()
	for line in summary:
		var label := UiKit.make_label(str(line[0]), font_size)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_color_override("font_color", line[1])
		_summary.add_child(label)
	_bottom.vertical = true
	_bottom.add_theme_constant_override("separation", 20)
	_summary.custom_minimum_size = Vector2(300, 0)
	UiKit.place(_bottom, Vector4(0, 0, 0, 0), Vector4(955, 150, 1255, 700))


func _unhandled_input(event: InputEvent) -> void:
	if not is_open():
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_leave(menu_requested)
	elif views.size() > 1 and (event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right")):
		get_viewport().set_input_as_handled()
		show_view(view_index + (1 if event.is_action_pressed("ui_right") else -1))


func _leave(request: Signal) -> void:
	_root.visible = false
	get_tree().paused = false
	request.emit()


## Paso 51: muestra el botón de la repetición.
func enable_replay() -> void:
	_replay_button.visible = true


## Paso 51: la repetición tapa el resultado (el árbol sigue en pausa); al cerrarla vuelve.
func hide_for_replay() -> void:
	_root.visible = false


func show_after_replay() -> void:
	_root.visible = true
	_replay_button.grab_focus()


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
		if child != _podium:
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


func _add_cell(text: String, column: int, font_size: int, color: Color, widths: Array = COLUMN_WIDTHS) -> Label:
	var align := HORIZONTAL_ALIGNMENT_LEFT if column == 0 or (widths != COLUMN_WIDTHS and column < _left_columns) \
		else HORIZONTAL_ALIGNMENT_RIGHT
	var label := UiKit.make_label(text, font_size, align)
	label.custom_minimum_size = Vector2(float(widths[column]), 0)
	label.add_theme_color_override("font_color", color)
	label.clip_text = widths != COLUMN_WIDTHS
	_table.add_child(label)
	return label


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
	_title = UiKit.make_label("Contrarreloj — Resultado", 48)
	header.add_child(_title)
	_subtitle = UiKit.make_label("", 22)
	_subtitle.add_theme_color_override("font_color", Color(0.85, 0.86, 0.9))
	header.add_child(_subtitle)

	_table = GridContainer.new()
	_table.columns = COLUMN_WIDTHS.size()
	_table.add_theme_constant_override("h_separation", 12)
	_table.add_theme_constant_override("v_separation", 6)
	UiKit.place(_table, Vector4(0, 0, 0, 0), Vector4(80, 180, 900, 480))
	_root.add_child(_table)

	_bottom = BoxContainer.new()
	_bottom.vertical = false
	_bottom.add_theme_constant_override("separation", 60)
	UiKit.place(_bottom, Vector4(0, 1, 0, 1), Vector4(80, -200, 1200, -40))
	_root.add_child(_bottom)

	_summary = VBoxContainer.new()
	_summary.add_theme_constant_override("separation", 4)
	_summary.custom_minimum_size = Vector2(560, 0)
	_bottom.add_child(_summary)
	_podium = Podium.new()
	_podium.custom_minimum_size = Vector2(300, 106)
	_podium.visible = false
	_summary.add_child(_podium)

	var actions := VBoxContainer.new()
	actions.add_theme_constant_override("separation", 12)
	_bottom.add_child(actions)
	_next_button = _add_button(actions, "", func() -> void: _leave(next_requested))
	_next_button.visible = false
	_view_button = _add_button(actions, "", func() -> void: show_view(view_index + 1))
	_view_button.visible = false
	_replay_button = _add_button(actions, "Ver repetición", func() -> void: replay_requested.emit())
	_replay_button.visible = false
	_repeat_button = _add_button(actions, "Repetir", func() -> void: _leave(repeat_requested))
	_add_button(actions, "Menú principal", func() -> void: _leave(menu_requested))


func _add_button(parent: Control, text: String, action: Callable) -> Button:
	var button := UiKit.make_button(text, accent)
	button.pressed.connect(action)
	parent.add_child(button)
	_buttons.append(button)
	return button
