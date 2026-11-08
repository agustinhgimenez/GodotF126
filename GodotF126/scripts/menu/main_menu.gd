extends Node3D
## Menú principal (Paso 11) y selección de piloto (Paso 12).
## El auto real (car.tscn en modo exhibición) gira sobre una plataforma, con música
## generada por código. Jugar abre ModeSelect (práctica libre / contrarreloj, Paso 16) y
## después DriverSelect (escudería → piloto); mientras se recorren las tarjetas el auto, el
## aro y la luz toman el color del equipo. Al confirmar se guardan el modo, el compuesto de
## neumáticos (Paso 33) y el piloto en GameState y se carga la carrera a través de la pantalla de carga (Paso 24).
## Desde ModeSelect se abre el setup del auto (SetupPanel, Paso 35; se guarda solo).

const LOADING_SCENE := "res://scenes/loading.tscn"
const FALLBACK_TEAM_COLOR := Color("#FF87BC")
const RING_RADIUS := 3.85

var turntable_speed_deg: float = 18.0

var _grid: Dictionary = {}
var _selected_id: String = ""
var _ring_material: StandardMaterial3D
var _main_panel: VBoxContainer
var _modes: ModeSelect
var _modes_scroll: ScrollContainer
var _select: DriverSelect
var _options: OptionsPanel
var _controls: ControlsPanel
var _setup_panel: SetupPanel
var _car_setup: CarSetup
## Paso 55: temporada guardada (null si no hay).
var _season: Championship
var _play_button: Button
var _options_button: Button
var _controls_button: Button
var _quit_button: Button
var _title_stripe: ColorRect
var _card_stripe: ColorRect
var _card_title: Label
var _card_subtitle: Label

@onready var _turntable: Node3D = $Turntable
@onready var _car: CarController = $Turntable/Car
@onready var _camera: Camera3D = $Camera3D
@onready var _rim_light: OmniLight3D = $RimLight
@onready var _key_light: DirectionalLight3D = $KeyLight
@onready var _music: MenuMusic = $Music


func _ready() -> void:
	var menu := DataLoader.load_json(DataLoader.MENU_PATH)
	turntable_speed_deg = float(menu.get("turntable_speed_deg", turntable_speed_deg))
	_grid = DataLoader.load_json(DataLoader.GRID_PATH)
	_selected_id = GameState.selected_driver_id
	if _selected_id.is_empty():
		_selected_id = str(_grid.get("default_driver_id", "colapinto"))

	_car.set_showcase(true)
	_build_ring()
	_setup_camera(menu.get("camera", {}))

	var music_data = menu.get("music", {})
	if music_data is Dictionary:
		_music.configure(music_data)
	_music.play()

	_build_ui()
	_show_selected()
	_show_main()
	_apply_quality()
	Settings.changed.connect(func(_key: String) -> void: _apply_quality())


func _process(delta: float) -> void:
	_turntable.rotate_y(deg_to_rad(turntable_speed_deg) * delta)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	get_viewport().set_input_as_handled()
	if _select.visible:
		_select.back()
	elif _setup_panel.visible:
		_close_setup()
	elif _modes.visible:
		_modes.back()
	elif _options.visible:
		_show_main()
		_options_button.grab_focus()
	elif _controls.visible:
		_show_main()
		_controls_button.grab_focus()
	else:
		get_tree().quit()


func _show_main() -> void:
	_modes.visible = false
	_setup_panel.visible = false
	_select.visible = false
	_options.visible = false
	_controls.visible = false
	_main_panel.visible = true
	_play_button.grab_focus()


func _on_options_pressed() -> void:
	_main_panel.visible = false
	_options.visible = true
	_options.open()


func _on_controls_pressed() -> void:
	_main_panel.visible = false
	_controls.visible = true
	_controls.open()


func _apply_quality() -> void:
	_key_light.shadow_enabled = Settings.shadows_enabled()


func _on_play_pressed() -> void:
	_main_panel.visible = false
	_show_modes()


func _show_modes() -> void:
	_select.visible = false
	_modes.visible = true
	_modes.open()
	# El foco puede caer en una tarjeta de abajo (Campeonato) antes de que el panel recién
	# mostrado tenga tamaño: follow_focus no la alcanza.
	await get_tree().process_frame
	var focused := get_viewport().gui_get_focus_owner()
	if focused != null and _modes_scroll.is_ancestor_of(focused):
		_modes_scroll.ensure_control_visible(focused)


## Paso 55: en la tarjeta de Campeonato, la temporada guardada (seguirla o, si terminó, el campeón).
func _show_season() -> void:
	if _season == null:
		return
	var standings := _season.driver_standings()
	if _season.is_finished():
		if not standings.is_empty():
			_modes.set_mode_description(GameState.MODE_CHAMPIONSHIP, "Terminada: campeón %s (%d pts) · ← → vueltas para otra" % [
				standings[0]["driver"], standings[0]["points"]])
		return
	var info := _season.current_round()
	var mine := _season.player_standing()
	var description := "%s · %d %s" % [str(info["name"]).trim_prefix("Gran Premio de "), _season.laps,
		"vuelta" if _season.laps == 1 else "vueltas"]
	var driver: Dictionary = DataLoader.find_driver(_grid, _season.player_driver_id).get("driver", {})
	description += " · %s" % str(driver.get("name", _season.player_driver_id))
	if not mine.is_empty():
		description += " P%d, %d pts" % [mine["pos"], mine["points"]]
	_modes.set_continue_option(GameState.MODE_CHAMPIONSHIP,
		"Seguir: fecha %d/%d" % [_season.round_index() + 1, _season.round_count()], description)


## Paso 55: "seguir" (vueltas 0) carga la fecha pendiente con el piloto de la temporada;
## una temporada nueva pasa antes por la elección de piloto.
func _on_championship_confirmed(laps: int, compound_id: String) -> void:
	GameState.tyre_compound = compound_id
	if laps == 0 and _season != null and not _season.is_finished():
		_season.prepare_round()
		get_tree().change_scene_to_file(LOADING_SCENE)
		return
	GameState.selected_mode = GameState.MODE_CHAMPIONSHIP
	GameState.lap_count = laps
	_modes.visible = false
	_select.visible = true
	_select.open()


func _on_mode_confirmed(mode_id: String, laps: int, compound_id: String) -> void:
	if mode_id == GameState.MODE_CHAMPIONSHIP:
		_on_championship_confirmed(laps, compound_id)
		return
	GameState.championship = false
	# Otra pista: la clasificación anterior no vale para la carrera.
	var track_id := _modes.track_id()
	if not track_id.is_empty() and track_id != TrackGenerator.resolve_track_id(GameState.selected_track):
		GameState.qualifying_time = -1.0
	if not track_id.is_empty():
		GameState.selected_track = track_id
	# Clasificación nueva: otra semilla para la IA. La carrera usa la última clasificación.
	if mode_id == GameState.MODE_QUALIFYING or (mode_id == GameState.MODE_RACE and GameState.qualifying_time < 0.0):
		GameState.session_seed = 0
		GameState.qualifying_time = -1.0
	GameState.selected_mode = mode_id
	GameState.lap_count = laps
	GameState.tyre_compound = compound_id
	_modes.visible = false
	_select.visible = true
	_select.open()


func _on_modes_cancelled() -> void:
	_show_main()


func _open_setup() -> void:
	_modes.visible = false
	_setup_panel.visible = true
	_setup_panel.open()


func _close_setup() -> void:
	_setup_panel.visible = false
	_modes.visible = true
	_modes.focus_setup(_car_setup.summary())


func _on_select_cancelled() -> void:
	_show_selected()
	_show_modes()


func _on_driver_confirmed(driver_id: String) -> void:
	GameState.selected_driver_id = driver_id
	if GameState.selected_mode == GameState.MODE_CHAMPIONSHIP:
		_season = Championship.load_default()
		_season.start(driver_id, GameState.lap_count)
		_season.save()
		_season.prepare_round()
	get_tree().change_scene_to_file(LOADING_SCENE)


func _on_quit_pressed() -> void:
	get_tree().quit()


func _show_selected() -> void:
	var found := DataLoader.find_driver(_grid, _selected_id)
	_preview(found.get("team", {}), found.get("driver", {}))


## Pinta el auto y la escena con el color del equipo y actualiza la tarjeta de abajo.
## Con driver vacío (eligiendo escudería) la tarjeta muestra los pilotos del equipo.
func _preview(team: Dictionary, driver: Dictionary) -> void:
	var color := DataLoader.team_primary(team, FALLBACK_TEAM_COLOR)
	var number := "" if driver.is_empty() else UiKit.number_text(driver.get("number", ""))
	_car.set_livery(color, DataLoader.team_secondary(team), number)
	_rim_light.light_color = color
	_ring_material.albedo_color = color
	_title_stripe.color = color
	_card_stripe.color = color
	UiKit.apply_button_style(_play_button, color)
	UiKit.apply_button_style(_options_button, color)
	UiKit.apply_button_style(_controls_button, color)
	UiKit.apply_button_style(_quit_button, color)
	_options.set_accent(color)
	_controls.set_accent(color)
	_modes.set_accent(color)
	_setup_panel.set_accent(color)
	if driver.is_empty():
		_card_title.text = str(team.get("name", ""))
		var names := PackedStringArray()
		for d in team.get("drivers", []):
			names.append(str(d.get("name", "")))
		_card_subtitle.text = " · ".join(names)
	else:
		_card_title.text = "#%s  %s" % [UiKit.number_text(driver.get("number", "")), str(driver.get("name", "Piloto"))]
		_card_subtitle.text = str(team.get("name", "Equipo"))


func _setup_camera(data) -> void:
	if not data is Dictionary:
		data = {}
	var eye := _vec3(data.get("position", []), Vector3(6.2, 2.1, 7.2))
	var target := _vec3(data.get("target", []), Vector3(0, 0.4, 0))
	_camera.look_at_from_position(eye, target)
	_camera.fov = float(data.get("fov", 45.0))
	_camera.h_offset = float(data.get("h_offset", -1.4))
	_camera.make_current()


## Aro luminoso con el color del equipo alrededor de la plataforma.
func _build_ring() -> void:
	var torus := TorusMesh.new()
	torus.inner_radius = RING_RADIUS - 0.04
	torus.outer_radius = RING_RADIUS + 0.04
	_ring_material = StandardMaterial3D.new()
	_ring_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ring_material.albedo_color = FALLBACK_TEAM_COLOR
	var ring := MeshInstance3D.new()
	ring.name = "Ring"
	ring.mesh = torus
	ring.material_override = _ring_material
	ring.position = Vector3(0, 0.1, 0)
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ring)


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.name = "UI"
	add_child(layer)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)

	# Arriba a la izquierda: título.
	var header := VBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	UiKit.place(header, Vector4(0, 0, 0, 0), Vector4(80, 50, 640, 200))
	root.add_child(header)
	header.add_child(UiKit.make_label("GodotF126", 64))
	var subtitle := UiKit.make_label("Simulador de Fórmula 1 · Temporada 2026", 22)
	subtitle.add_theme_color_override("font_color", Color(0.8, 0.82, 0.88))
	header.add_child(subtitle)
	_title_stripe = ColorRect.new()
	_title_stripe.custom_minimum_size = Vector2(120, 5)
	_title_stripe.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	header.add_child(_title_stripe)

	# Debajo: botones principales o selección de piloto (uno a la vez).
	_main_panel = VBoxContainer.new()
	_main_panel.add_theme_constant_override("separation", 14)
	UiKit.place(_main_panel, Vector4(0, 0, 0, 0), Vector4(80, 260, 640, 560))
	root.add_child(_main_panel)
	_play_button = UiKit.make_button("Jugar", FALLBACK_TEAM_COLOR)
	_play_button.pressed.connect(_on_play_pressed)
	_main_panel.add_child(_play_button)
	_options_button = UiKit.make_button("Opciones", FALLBACK_TEAM_COLOR)
	_options_button.pressed.connect(_on_options_pressed)
	_main_panel.add_child(_options_button)
	_controls_button = UiKit.make_button("Controles", FALLBACK_TEAM_COLOR)
	_controls_button.pressed.connect(_on_controls_pressed)
	_main_panel.add_child(_controls_button)
	_quit_button = UiKit.make_button("Salir", FALLBACK_TEAM_COLOR)
	_quit_button.pressed.connect(_on_quit_pressed)
	_main_panel.add_child(_quit_button)
	var hint := UiKit.make_label("Flechas para elegir · Enter para confirmar · Esc para salir", 16)
	hint.add_theme_color_override("font_color", Color(0.7, 0.72, 0.78))
	_main_panel.add_child(hint)

	# Paso 54: pista + 4 modos + neumáticos + setup no entran en 720 px; el panel se desplaza
	# siguiendo el foco (sin barra visible).
	_modes_scroll = ScrollContainer.new()
	_modes_scroll.name = "ModeScroll"
	_modes_scroll.follow_focus = true
	_modes_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_modes_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	UiKit.place(_modes_scroll, Vector4(0, 0, 0, 0), Vector4(80, 210, 660, 712))
	root.add_child(_modes_scroll)
	_modes = ModeSelect.new()
	_modes.name = "ModeSelect"
	_modes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_modes_scroll.add_child(_modes)
	var car_data := DataLoader.load_json(DataLoader.CAR_PATH)
	var compounds = car_data.get("tyre_compounds", {})
	_season = Championship.load_saved()
	var in_season := GameState.championship and _season != null
	_modes.setup(DataLoader.load_json(DataLoader.MODES_PATH),
		GameState.MODE_CHAMPIONSHIP if in_season else GameState.selected_mode,
		_season.laps if in_season else GameState.lap_count,
		compounds if compounds is Dictionary else {}, GameState.tyre_compound,
		DataLoader.load_json(DataLoader.TRACKS_PATH), GameState.selected_track)
	_show_season()
	_modes.confirmed.connect(_on_mode_confirmed)
	_modes.cancelled.connect(_on_modes_cancelled)
	_modes.setup_requested.connect(_open_setup)

	_car_setup = CarSetup.load_saved()
	_modes.set_setup_summary(_car_setup.summary())
	_setup_panel = SetupPanel.new()
	_setup_panel.name = "Setup"
	_setup_panel.visible = false
	UiKit.place(_setup_panel, Vector4(0, 0, 0, 0), Vector4(80, 200, 680, 710))
	root.add_child(_setup_panel)
	_setup_panel.setup(_car_setup, CarSetup.base_from_car_data(car_data))
	_setup_panel.closed.connect(_close_setup)

	_select = DriverSelect.new()
	_select.name = "DriverSelect"
	UiKit.place(_select, Vector4(0, 0, 0, 0), Vector4(80, 210, 640, 680))
	root.add_child(_select)
	_select.setup(_grid, _selected_id)
	_select.preview_changed.connect(_preview)
	_select.confirmed.connect(_on_driver_confirmed)
	_select.cancelled.connect(_on_select_cancelled)

	_options = OptionsPanel.new()
	_options.name = "Options"
	UiKit.place(_options, Vector4(0, 0, 0, 0), Vector4(80, 200, 640, 710))
	root.add_child(_options)
	_options.closed.connect(func() -> void:
		_show_main()
		_options_button.grab_focus())

	_controls = ControlsPanel.new()
	_controls.name = "Controls"
	UiKit.place(_controls, Vector4(0, 0, 0, 0), Vector4(80, 200, 700, 710))
	root.add_child(_controls)
	_controls.closed.connect(func() -> void:
		_show_main()
		_controls_button.grab_focus())

	# Abajo a la derecha: piloto o escudería en exhibición.
	var card := HBoxContainer.new()
	card.add_theme_constant_override("separation", 12)
	card.alignment = BoxContainer.ALIGNMENT_END
	UiKit.place(card, Vector4(1, 1, 1, 1), Vector4(-560, -110, -40, -40))
	root.add_child(card)
	var card_text := VBoxContainer.new()
	card.add_child(card_text)
	_card_title = UiKit.make_label("", 28, HORIZONTAL_ALIGNMENT_RIGHT)
	_card_subtitle = UiKit.make_label("", 20, HORIZONTAL_ALIGNMENT_RIGHT)
	card_text.add_child(_card_title)
	card_text.add_child(_card_subtitle)
	_card_stripe = ColorRect.new()
	_card_stripe.custom_minimum_size = Vector2(8, 64)
	card.add_child(_card_stripe)

	var credits := UiKit.make_label("Agustín Giménez · 350 Ingeniería de Software Avanzado", 15)
	credits.add_theme_color_override("font_color", Color(0.6, 0.62, 0.68))
	UiKit.place(credits, Vector4(1, 0, 1, 0), Vector4(-620, 24, -40, 50))
	credits.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	root.add_child(credits)


func _vec3(value, fallback: Vector3) -> Vector3:
	if value is Array and value.size() == 3:
		return Vector3(float(value[0]), float(value[1]), float(value[2]))
	return fallback
