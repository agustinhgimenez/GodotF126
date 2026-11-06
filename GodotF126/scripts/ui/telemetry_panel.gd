class_name TelemetryPanel
extends VBoxContainer
## Pantalla de telemetría de la pausa (Paso 39): la vuelta que se está grabando, una tabla
## con las últimas vueltas de la sesión (tiempo, velocidad máxima / mínima / media, % a
## fondo y frenando, cambios de marcha) y el gráfico de velocidad de la última vuelta
## contra la mejor (de la sesión o la guardada de la pista).

signal closed

const COLUMNS := [
	{"title": "Vuelta", "width": 90},
	{"title": "Tiempo", "width": 96},
	{"title": "Máx.", "width": 58},
	{"title": "Mín.", "width": 52},
	{"title": "Media", "width": 60},
	{"title": "A fondo", "width": 76},
	{"title": "Freno", "width": 60},
	{"title": "Cambios", "width": 76},
]
const DIM := Color(0.7, 0.72, 0.78)
const INVALID := Color(0.85, 0.45, 0.4)
const GRAPH_SIZE := Vector2(600, 120)

var accent: Color = Color("#FF87BC")

var _recorder: TelemetryRecorder
var _status: Label
var _grid: GridContainer
var _graph: TelemetryGraph
var _legend: Label
var _back: Button


func _ready() -> void:
	add_theme_constant_override("separation", 6)
	add_child(UiKit.make_label("Telemetría", 26))
	_status = UiKit.make_label("", 16)
	_status.add_theme_color_override("font_color", DIM)
	add_child(_status)
	_grid = GridContainer.new()
	_grid.columns = COLUMNS.size()
	_grid.add_theme_constant_override("h_separation", 6)
	_grid.add_theme_constant_override("v_separation", 2)
	add_child(_grid)
	_legend = UiKit.make_label("", 15)
	_legend.add_theme_color_override("font_color", DIM)
	add_child(_legend)
	_graph = TelemetryGraph.new()
	_graph.custom_minimum_size = GRAPH_SIZE
	_graph.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	add_child(_graph)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 12)
	add_child(actions)
	_back = UiKit.make_button("Volver", accent, Vector2(170, 40), 19)
	_back.pressed.connect(func() -> void: closed.emit())
	actions.add_child(_back)
	var hint := UiKit.make_label("Esc volver · el análisis con gráficos llega en el Paso 41", 15)
	hint.add_theme_color_override("font_color", DIM)
	hint.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	actions.add_child(hint)


func bind(recorder: TelemetryRecorder) -> void:
	_recorder = recorder


func set_accent(color: Color) -> void:
	accent = color
	UiKit.apply_button_style(_back, color)
	_graph.accent = color
	_graph.queue_redraw()


func open() -> void:
	refresh()
	_back.grab_focus()


func refresh() -> void:
	for child in _grid.get_children():
		_grid.remove_child(child)
		child.queue_free()
	for column in COLUMNS:
		_cell(str(column["title"]), int(column["width"]), DIM)
	if _recorder == null:
		return
	var current := _recorder.current
	if current != null and current.size() > 0:
		_status.text = "Grabando vuelta %d: %d muestras (cada %.2f s), %d m" % [current.lap, current.size(),
			_recorder.interval, roundi(current.value("distance", current.size() - 1))]
	else:
		_status.text = "Se graba desde que se cruza la meta (cada %.2f s)" % _recorder.interval
	var laps := _recorder.laps
	var first := maxi(laps.size() - _recorder.panel_rows, 0)
	for i in range(first, laps.size()):
		_row(laps[i], str(laps[i].lap))
	var saved := _recorder.saved_best
	if saved != null and not laps.has(saved):
		_row(saved, "Guardada")
	if laps.is_empty() and saved == null:
		_cell("—", int(COLUMNS[0]["width"]), DIM)
		for k in range(1, COLUMNS.size()):
			_cell("", int(COLUMNS[k]["width"]), DIM)
	var reference := _reference()
	var shown := "sin vuelta"
	if _recorder.last != null:
		shown = "vuelta %d" % _recorder.last.lap
	if reference != null and reference == saved and not laps.has(saved):
		shown += " contra la guardada (gris)"
	elif reference != null:
		shown += " contra la %d (gris)" % reference.lap
	_legend.text = "Velocidad (km/h) contra distancia: %s · abajo acelerador y freno" % shown
	_graph.accent = accent
	_graph.show_laps(_recorder.last, reference, _recorder.track_length())


## Contra qué se dibuja la última vuelta: la mejor (de la sesión o la guardada); si la
## última es la mejor, la guardada de antes o la vuelta válida anterior.
func _reference() -> TelemetryLap:
	var last := _recorder.last
	if last == null:
		return _recorder.saved_best
	var candidates: Array[TelemetryLap] = [_recorder.best, _recorder.saved_best]
	var reference: TelemetryLap = null
	for lap in candidates:
		if lap != null and lap != last and (reference == null or lap.lap_time < reference.lap_time):
			reference = lap
	if reference != null:
		return reference
	for i in range(_recorder.laps.size() - 1, -1, -1):
		var lap := _recorder.laps[i]
		if lap != last and not lap.invalid:
			return lap
	return null


func _row(lap: TelemetryLap, name: String) -> void:
	var s := _recorder.summary(lap)
	var color := Color.WHITE
	if lap.invalid:
		color = INVALID
	elif lap == _recorder.best or (name == "Guardada"):
		color = accent.lightened(0.35)
	var values := [
		name + (" inv." if lap.invalid else ""),
		LapTimer.format_time(lap.lap_time),
		"%d" % roundi(float(s["max_speed"])),
		"%d" % roundi(float(s["min_speed"])),
		"%d" % roundi(float(s["avg_speed"])),
		"%d %%" % roundi(float(s["full_throttle"]) * 100.0),
		"%d %%" % roundi(float(s["braking"]) * 100.0),
		"%d" % int(s["gear_changes"]),
	]
	for k in COLUMNS.size():
		_cell(str(values[k]), int(COLUMNS[k]["width"]), color)


func _cell(text: String, width: int, color: Color) -> void:
	var label := UiKit.make_label(text, 17)
	label.custom_minimum_size = Vector2(width, 0)
	label.add_theme_color_override("font_color", color)
	_grid.add_child(label)
