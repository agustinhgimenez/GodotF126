class_name TelemetryAnalysis
extends Control
## Pantalla de análisis de telemetría (Paso 41), a pantalla completa desde Pausa →
## Telemetría → Análisis. Se eligen dos vueltas (A y B, de la sesión o la guardada) y se ven
## sus canales contra la distancia (TelemetryPlots), el mapa con dónde gana o pierde B
## (TelemetryTrackMap) y los valores de las dos en el cursor.

signal closed

const PLOTS_RECT := Rect2(24, 104, 860, 0)
const MAP_RECT := Rect2(904, 104, 352, 290)
const VALUES_POS := Vector2(904, 404)
const DIM := Color(0.7, 0.72, 0.78)
const VALUE_ROWS := ["Tiempo", "Velocidad", "Acelerador", "Freno", "Marcha", "Dirección", "RPM"]

var accent: Color = Color("#FF87BC")
## Índices en `laps` de las vueltas A y B.
var index_a: int = 0
var index_b: int = 0
var laps: Array[TelemetryLap] = []

var _recorder: TelemetryRecorder
var _plots: TelemetryPlots
var _map: TelemetryTrackMap
var _button_a: Button
var _button_b: Button
var _back: Button
var _export_pair: Button
var _export_all: Button
var _export_status: Label
## Rutas user:// de la última exportación.
var last_export := PackedStringArray()
var _cursor_label: Label
var _header_a: Label
var _value_labels: Dictionary = {}   ## "fila:columna" → Label
var _empty: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.03, 0.03, 0.05, 0.96)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var title := UiKit.make_label("Análisis de telemetría", 28)
	UiKit.place(title, Vector4.ZERO, Vector4(24, 14, 420, 54))
	add_child(title)
	_button_a = _make_selector(Vector2(24, 58), func(step: int) -> void: _change(true, step))
	_button_b = _make_selector(Vector2(374, 58), func(step: int) -> void: _change(false, step))
	_back = UiKit.make_button("Volver", accent, Vector2(150, 38), 19)
	_back.position = Vector2(1106, 58)
	_back.pressed.connect(func() -> void: closed.emit())
	add_child(_back)
	_export_pair = UiKit.make_button("CSV A y B", accent, Vector2(180, 38), 17)
	_export_pair.position = Vector2(724, 58)
	_export_pair.pressed.connect(export_pair)
	add_child(_export_pair)
	_export_all = UiKit.make_button("CSV todas", accent, Vector2(180, 38), 17)
	_export_all.position = Vector2(914, 58)
	_export_all.pressed.connect(export_all)
	add_child(_export_all)
	_export_status = UiKit.make_label("", 13)
	_export_status.add_theme_color_override("font_color", DIM)
	_export_status.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	UiKit.place(_export_status, Vector4.ZERO, Vector4(440, 10, 1256, 54))
	add_child(_export_status)

	_plots = TelemetryPlots.new()
	_plots.position = PLOTS_RECT.position
	_plots.size = Vector2(PLOTS_RECT.size.x, TelemetryPlots.total_height())
	_plots.cursor_moved.connect(_on_cursor_moved)
	add_child(_plots)
	var hint := UiKit.make_label("↑ ↓ elegir · ← → cambiar la vuelta o mover el cursor (10 m) · mouse sobre los gráficos · Esc volver", 14)
	hint.add_theme_color_override("font_color", DIM)
	UiKit.place(hint, Vector4.ZERO, Vector4(24, 696, 1256, 716))
	add_child(hint)

	_map = TelemetryTrackMap.new()
	_map.position = MAP_RECT.position
	_map.size = MAP_RECT.size
	add_child(_map)
	var values := GridContainer.new()
	values.columns = 4
	values.add_theme_constant_override("h_separation", 10)
	values.add_theme_constant_override("v_separation", 3)
	values.position = VALUES_POS
	add_child(values)
	_cursor_label = _add_cell(values, "", 120, DIM)
	_header_a = _add_cell(values, "A", 72, accent)
	_add_cell(values, "B", 72, Color.WHITE)
	_add_cell(values, "B - A", 72, DIM)
	for row in VALUE_ROWS:
		_add_cell(values, row, 120, DIM)
		for column in ["a", "b", "d"]:
			_value_labels["%s:%s" % [row, column]] = _add_cell(values, "", 72, Color.WHITE)
	var legend := UiKit.make_label("Mapa: el recorrido de B en verde donde gana tiempo contra A y en rojo donde pierde; puntos = posición en el cursor", 13)
	legend.add_theme_color_override("font_color", DIM)
	legend.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiKit.place(legend, Vector4.ZERO, Vector4(904, 632, 1256, 690))
	add_child(legend)
	_empty = UiKit.make_label("Todavía no hay vueltas completas: dá una vuelta y volvé.", 22)
	UiKit.place(_empty, Vector4.ZERO, Vector4(24, 300, 884, 340))
	add_child(_empty)


func bind(recorder: TelemetryRecorder) -> void:
	_recorder = recorder
	_map.set_outline(recorder.track_outline())


func set_accent(color: Color) -> void:
	accent = color
	for button in [_button_a, _button_b, _back, _export_pair, _export_all]:
		UiKit.apply_button_style(button, color)
	_plots.color_a = color
	_map.color_a = color
	_header_a.add_theme_color_override("font_color", color)
	_plots.queue_redraw()
	_map.queue_redraw()


## Abre con A = la vuelta válida más rápida y B = la última (o la anterior a A si son la misma).
func open() -> void:
	if _recorder == null:
		return
	laps = _recorder.available_laps()
	index_a = _fastest_index()
	index_b = laps.find(_recorder.last) if _recorder.last != null else -1
	if index_b < 0 or index_b == index_a:
		index_b = index_a - 1 if index_a > 0 else mini(index_a + 1, laps.size() - 1)
	index_b = maxi(index_b, 0)
	_export_status.text = ""
	_refresh()
	if laps.is_empty():
		_back.grab_focus()
	else:
		_plots.grab_focus()


func lap_a() -> TelemetryLap:
	return laps[index_a] if index_a >= 0 and index_a < laps.size() else null


func lap_b() -> TelemetryLap:
	return laps[index_b] if index_b >= 0 and index_b < laps.size() else null


## Exporta A y B (una sola vez si son la misma). Devuelve las rutas escritas.
func export_pair() -> PackedStringArray:
	var selection: Array[TelemetryLap] = []
	var suffix := ""
	for pair in [["A", lap_a()], ["B", lap_b()]]:
		var lap: TelemetryLap = pair[1]
		if lap != null and not selection.has(lap):
			selection.append(lap)
			suffix += "%s%s-%s" % ["" if suffix.is_empty() else "_", pair[0], _file_tag(lap)]
	return _export(selection, suffix)


func export_all() -> PackedStringArray:
	return _export(laps.duplicate(), "todas")


func _file_tag(lap: TelemetryLap) -> String:
	return "guardada" if _recorder.lap_origin(lap) == "guardada" else "v%d" % lap.lap


func _export(selection: Array[TelemetryLap], suffix: String) -> PackedStringArray:
	if _recorder == null or selection.is_empty():
		_export_status.text = "No hay vueltas para exportar."
		return PackedStringArray()
	last_export = _recorder.export_csv(selection, suffix)
	if last_export.is_empty():
		_export_status.text = "No se pudo escribir el CSV (ver la consola)."
	else:
		var path := ProjectSettings.globalize_path(last_export[0])
		_export_status.text = "Exportado%s (%d vuelta%s): %s\nen %s" % ["" if last_export.size() == 1 else " con resumen",
			selection.size(), "" if selection.size() == 1 else "s", path.get_file(), path.get_base_dir()]
	return last_export


func _fastest_index() -> int:
	var best := -1
	for i in laps.size():
		if laps[i].invalid:
			continue
		if best < 0 or laps[i].lap_time < laps[best].lap_time:
			best = i
	return best if best >= 0 else laps.size() - 1


func _change(is_a: bool, step: int) -> void:
	if laps.is_empty():
		return
	if is_a:
		index_a = (index_a + step + laps.size()) % laps.size()
	else:
		index_b = (index_b + step + laps.size()) % laps.size()
	_refresh()


static func lap_name(lap: TelemetryLap, saved: TelemetryLap, session: Array[TelemetryLap]) -> String:
	if lap == null:
		return "—"
	var name := "Guardada" if lap == saved and not session.has(lap) else "Vuelta %d" % lap.lap
	return "%s · %s%s" % [name, LapTimer.format_time(lap.lap_time), " inv." if lap.invalid else ""]


func _refresh() -> void:
	var a := lap_a()
	var b := lap_b()
	var saved := _recorder.saved_best
	_button_a.text = "A  ‹ %s ›" % lap_name(a, saved, _recorder.laps)
	_button_b.text = "B  ‹ %s ›" % lap_name(b, saved, _recorder.laps)
	_empty.visible = laps.is_empty()
	_plots.visible = not laps.is_empty()
	_plots.color_a = accent
	_map.color_a = accent
	_plots.show_laps(a, b, _recorder.track_length(), _recorder.sector_distances())
	_map.show_laps(a, b, _plots.delta_b)
	_on_cursor_moved(_plots.cursor)


func _on_cursor_moved(distance: float) -> void:
	_map.set_cursor(distance)
	_cursor_label.text = "En %d m" % roundi(distance)
	var a := lap_a()
	var b := lap_b()
	for row in VALUE_ROWS:
		var va := _value(a, row, distance)
		var vb := _value(b, row, distance)
		_set_value(row, "a", _format(row, va))
		_set_value(row, "b", _format(row, vb))
		var diff := vb - va
		var text := ""
		var color := Color.WHITE
		if row == "Tiempo":
			text = DeltaDisplay.format_delta(diff)
			color = DeltaDisplay.delta_color(diff, false)
		elif row == "Velocidad" and not is_nan(diff):
			text = "%+d" % roundi(diff)
			color = DeltaDisplay.COLOR_FASTER if diff > 0.5 else (DeltaDisplay.COLOR_SLOWER if diff < -0.5 else Color.WHITE)
		_set_value(row, "d", text, color)


func _value(lap: TelemetryLap, row: String, distance: float) -> float:
	if lap == null:
		return NAN
	match row:
		"Tiempo": return lap.value_at_distance("time", distance)
		"Velocidad": return lap.value_at_distance("speed", distance)
		"Acelerador": return lap.value_at_distance("throttle", distance)
		"Freno": return lap.value_at_distance("brake", distance)
		"Marcha": return lap.value_at_distance("gear", distance)
		"Dirección": return lap.value_at_distance("steer", distance)
		"RPM": return lap.value_at_distance("rpm", distance)
	return NAN


static func _format(row: String, value: float) -> String:
	if is_nan(value):
		return "—"
	match row:
		"Tiempo": return LapTimer.format_time(value)
		"Velocidad": return "%d" % roundi(value)
		"Acelerador", "Freno": return "%d %%" % roundi(value * 100.0)
		"Marcha": return "N" if roundi(value) == 0 else ("R" if roundi(value) < 0 else str(roundi(value)))
		"Dirección": return "%+.2f" % value
		"RPM": return "%d" % roundi(value)
	return ""


func _set_value(row: String, column: String, text: String, color: Color = Color.WHITE) -> void:
	var label: Label = _value_labels["%s:%s" % [row, column]]
	label.text = text
	label.add_theme_color_override("font_color", color)


func _add_cell(grid: GridContainer, text: String, width: int, color: Color) -> Label:
	var label := UiKit.make_label(text, 16)
	label.custom_minimum_size = Vector2(width, 0)
	label.add_theme_color_override("font_color", color)
	grid.add_child(label)
	return label


func _make_selector(at: Vector2, on_step: Callable) -> Button:
	var button := UiKit.make_button("", accent, Vector2(340, 38), 18)
	button.position = at
	button.pressed.connect(func() -> void: on_step.call(1))
	button.gui_input.connect(func(event: InputEvent) -> void:
		if event.is_action_pressed("ui_right", true):
			on_step.call(1)
			button.accept_event()
		elif event.is_action_pressed("ui_left", true):
			on_step.call(-1)
			button.accept_event())
	add_child(button)
	return button
