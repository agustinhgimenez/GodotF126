class_name LoadingScreen
extends Control
## Pantalla de carga (Paso 24) entre el menú y la carrera (scenes/loading.tscn).
## Carga main.tscn en otro hilo con barra de progreso y muestra piloto, circuito, modo,
## un consejo y los controles. La primera vez (tutorial_seen en Settings) espera Enter
## para que se lean los controles; después pasa sola cuando terminó de cargar.

const RACE_SCENE := "res://scenes/main.tscn"
const TRACK_ID := "baku"
const TIME_NAMES := {"sunset": "Atardecer", "day": "Día"}
## Parte de la barra que ocupa la carga del recurso; el resto es armar la pista.
const RESOURCE_SHARE := 0.85

var min_seconds: float = 1.2
## Con true espera Enter antes de largar (primera carrera).
var wait_for_confirm: bool = false

var _elapsed: float = 0.0
var _loaded: PackedScene
var _confirmed: bool = false
var _starting: bool = false
var _accent: Color = Color("#FF87BC")
var _driver_text: String = ""
var _track_text: String = ""
var _mode_text: String = ""
var _bar: ProgressBar
var _status: Label
var _title: Label
var _subtitle: Label
var _tip: Label
var _controls: ControlsPanel


func _ready() -> void:
	var data := DataLoader.load_json(ControlsPanel.DATA_PATH)
	var loading = data.get("loading", {})
	if loading is Dictionary:
		min_seconds = float(loading.get("min_seconds", min_seconds))
	wait_for_confirm = not bool(Settings.get_value("tutorial_seen"))
	_read_session()
	_build_ui()
	_tip.text = _pick_tip(data.get("tips", []))
	_fill_texts()
	var error := ResourceLoader.load_threaded_request(RACE_SCENE)
	if error != OK:
		push_error("No se pudo empezar a cargar %s (%d)" % [RACE_SCENE, error])


func _process(delta: float) -> void:
	_elapsed += delta
	if _starting:
		return
	if _loaded == null:
		_poll_load()
		return
	if wait_for_confirm and not _confirmed:
		var pulse := 0.65 + 0.35 * sin(_elapsed * 4.0)
		_status.modulate.a = pulse
		return
	if _elapsed >= min_seconds or _confirmed:
		_start_race()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_confirmed = true


func is_loaded() -> bool:
	return _loaded != null


func _poll_load() -> void:
	var progress: Array = []
	var status := ResourceLoader.load_threaded_get_status(RACE_SCENE, progress)
	match status:
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			var amount := float(progress[0]) if not progress.is_empty() else 0.0
			_bar.value = amount * RESOURCE_SHARE
		ResourceLoader.THREAD_LOAD_LOADED:
			_loaded = ResourceLoader.load_threaded_get(RACE_SCENE) as PackedScene
			_bar.value = RESOURCE_SHARE
			if wait_for_confirm:
				_status.text = "Listo · leé los controles y apretá Enter para salir a pista"
			else:
				_status.text = "Listo"
		_:
			push_error("Falló la carga de %s; la cargo de forma directa." % RACE_SCENE)
			_starting = true
			get_tree().change_scene_to_file(RACE_SCENE)


## La pista y la ciudad se arman en el _ready() de la carrera y congelan la pantalla un
## momento: antes se muestra el aviso y se dejan pasar dos cuadros para que se dibuje.
func _start_race() -> void:
	_starting = true
	_status.modulate.a = 1.0
	_status.text = "Armando el circuito y la ciudad…"
	_bar.value = 0.95
	if wait_for_confirm:
		Settings.set_value("tutorial_seen", true)
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().change_scene_to_packed(_loaded)


func _read_session() -> void:
	var grid := DataLoader.load_json(DataLoader.GRID_PATH)
	var driver_id := GameState.selected_driver_id
	if driver_id.is_empty():
		driver_id = str(grid.get("default_driver_id", "colapinto"))
	var found := DataLoader.find_driver(grid, driver_id)
	if not found.is_empty():
		var driver: Dictionary = found["driver"]
		var team: Dictionary = found["team"]
		_accent = DataLoader.team_primary(team, _accent)
		_driver_text = "#%s %s · %s" % [UiKit.number_text(driver.get("number", "")),
			str(driver.get("name", "")), str(team.get("name", ""))]

	var tracks := DataLoader.load_json(DataLoader.TRACKS_PATH)
	for info in tracks.get("tracks", []):
		if info is Dictionary and str(info.get("id", "")) == TRACK_ID:
			_track_text = str(info.get("display_name", "Bakú"))
	if _track_text.is_empty():
		_track_text = "Bakú"

	var modes := DataLoader.load_json(DataLoader.MODES_PATH)
	var mode_id := GameState.selected_mode
	if mode_id.is_empty():
		mode_id = str(modes.get("default_mode", GameState.MODE_PRACTICE))
	var mode := DataLoader.find_mode(modes, mode_id)
	_mode_text = str(mode.get("name", "Práctica libre"))
	if mode_id == GameState.MODE_TIME_TRIAL:
		var laps := GameState.lap_count if GameState.lap_count > 0 else int(mode.get("default_laps", 3))
		_mode_text += " · %d %s" % [laps, "vuelta" if laps == 1 else "vueltas"]


func _fill_texts() -> void:
	_title.text = _track_text
	var time_text: String = TIME_NAMES.get(str(Settings.get_value("time_of_day")), "")
	var parts := PackedStringArray()
	for part in [_driver_text, _mode_text, time_text]:
		if not str(part).is_empty():
			parts.append(str(part))
	_subtitle.text = "  ·  ".join(parts)
	_status.text = "Cargando la carrera…"


func _pick_tip(tips) -> String:
	if not tips is Array or tips.is_empty():
		return ""
	return str(tips[randi() % tips.size()])


func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = Color(0.05, 0.05, 0.08)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var band := ColorRect.new()
	band.color = Color(_accent, 0.08)
	UiKit.place(band, Vector4(0, 0, 1, 0), Vector4(0, 0, 0, 190))
	add_child(band)

	var header := VBoxContainer.new()
	header.add_theme_constant_override("separation", 6)
	UiKit.place(header, Vector4(0, 0, 1, 0), Vector4(80, 40, -80, 180))
	add_child(header)
	var caption := UiKit.make_label("PRÓXIMA SESIÓN", 16)
	caption.add_theme_color_override("font_color", _accent)
	header.add_child(caption)
	_title = UiKit.make_label("", 46)
	header.add_child(_title)
	_subtitle = UiKit.make_label("", 22)
	_subtitle.add_theme_color_override("font_color", Color(0.82, 0.84, 0.9))
	header.add_child(_subtitle)
	var stripe := ColorRect.new()
	stripe.color = _accent
	stripe.custom_minimum_size = Vector2(120, 5)
	stripe.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	header.add_child(stripe)

	_controls = ControlsPanel.new()
	_controls.with_back = false
	_controls.accent = _accent
	UiKit.place(_controls, Vector4(0, 0, 0, 0), Vector4(80, 210, 700, 690))
	add_child(_controls)

	var tip_box := VBoxContainer.new()
	tip_box.add_theme_constant_override("separation", 8)
	UiKit.place(tip_box, Vector4(1, 0, 1, 0), Vector4(-500, 240, -80, 480))
	add_child(tip_box)
	var tip_title := UiKit.make_label("Consejo", 22)
	tip_title.add_theme_color_override("font_color", _accent)
	tip_box.add_child(tip_title)
	_tip = UiKit.make_label("", 22)
	_tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tip.custom_minimum_size = Vector2(420, 0)
	tip_box.add_child(_tip)

	_status = UiKit.make_label("", 20)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	UiKit.place(_status, Vector4(1, 1, 1, 1), Vector4(-500, -170, -80, -100))
	add_child(_status)
	_bar = ProgressBar.new()
	_bar.min_value = 0.0
	_bar.max_value = 1.0
	_bar.show_percentage = false
	_bar.add_theme_stylebox_override("background", _bar_style(Color(1, 1, 1, 0.1)))
	_bar.add_theme_stylebox_override("fill", _bar_style(_accent))
	UiKit.place(_bar, Vector4(1, 1, 1, 1), Vector4(-500, -85, -80, -75))
	add_child(_bar)


func _bar_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(3)
	return style
