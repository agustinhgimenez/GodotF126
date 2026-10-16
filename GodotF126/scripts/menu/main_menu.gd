extends Node3D
## Menú principal (Paso 11) y selección de piloto (Paso 12).
## El auto real (car.tscn en modo exhibición) gira sobre una plataforma, con música
## generada por código. Jugar abre ModeSelect (práctica libre / contrarreloj, Paso 16) y
## después DriverSelect (escudería → piloto); mientras se recorren las tarjetas el auto, el
## aro y la luz toman el color del equipo. Al confirmar se guardan el modo y el piloto en
## GameState y se carga la carrera.

const RACE_SCENE := "res://scenes/main.tscn"
const FALLBACK_TEAM_COLOR := Color("#FF87BC")
const RING_RADIUS := 3.85

var turntable_speed_deg: float = 18.0

var _grid: Dictionary = {}
var _selected_id: String = ""
var _ring_material: StandardMaterial3D
var _main_panel: VBoxContainer
var _modes: ModeSelect
var _select: DriverSelect
var _options: OptionsPanel
var _play_button: Button
var _options_button: Button
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
	elif _modes.visible:
		_modes.back()
	elif _options.visible:
		_show_main()
		_options_button.grab_focus()
	else:
		get_tree().quit()


func _show_main() -> void:
	_modes.visible = false
	_select.visible = false
	_options.visible = false
	_main_panel.visible = true
	_play_button.grab_focus()


func _on_options_pressed() -> void:
	_main_panel.visible = false
	_options.visible = true
	_options.open()


func _apply_quality() -> void:
	_key_light.shadow_enabled = Settings.shadows_enabled()


func _on_play_pressed() -> void:
	_main_panel.visible = false
	_show_modes()


func _show_modes() -> void:
	_select.visible = false
	_modes.visible = true
	_modes.open()


func _on_mode_confirmed(mode_id: String, laps: int) -> void:
	GameState.selected_mode = mode_id
	GameState.lap_count = laps
	_modes.visible = false
	_select.visible = true
	_select.open()


func _on_modes_cancelled() -> void:
	_show_main()


func _on_select_cancelled() -> void:
	_show_selected()
	_show_modes()


func _on_driver_confirmed(driver_id: String) -> void:
	GameState.selected_driver_id = driver_id
	get_tree().change_scene_to_file(RACE_SCENE)


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
	UiKit.apply_button_style(_quit_button, color)
	_options.set_accent(color)
	_modes.set_accent(color)
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
	_quit_button = UiKit.make_button("Salir", FALLBACK_TEAM_COLOR)
	_quit_button.pressed.connect(_on_quit_pressed)
	_main_panel.add_child(_quit_button)
	var hint := UiKit.make_label("Flechas para elegir · Enter para confirmar · Esc para salir", 16)
	hint.add_theme_color_override("font_color", Color(0.7, 0.72, 0.78))
	_main_panel.add_child(hint)

	_modes = ModeSelect.new()
	_modes.name = "ModeSelect"
	UiKit.place(_modes, Vector4(0, 0, 0, 0), Vector4(80, 210, 640, 560))
	root.add_child(_modes)
	_modes.setup(DataLoader.load_json(DataLoader.MODES_PATH), GameState.selected_mode, GameState.lap_count)
	_modes.confirmed.connect(_on_mode_confirmed)
	_modes.cancelled.connect(_on_modes_cancelled)

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
