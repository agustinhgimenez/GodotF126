extends Node3D
## Menú principal (Paso 11): el auto real (car.tscn en modo exhibición) gira sobre una
## plataforma, con música generada por código y botones Jugar / Salir.
## La interfaz se arma por código, como el HUD.

const RACE_SCENE := "res://scenes/main.tscn"
const FALLBACK_TEAM_COLOR := Color("#FF87BC")
const RING_RADIUS := 3.85

var turntable_speed_deg: float = 18.0

var _team_color: Color = FALLBACK_TEAM_COLOR
var _play_button: Button

@onready var _turntable: Node3D = $Turntable
@onready var _car: CarController = $Turntable/Car
@onready var _camera: Camera3D = $Camera3D
@onready var _rim_light: OmniLight3D = $RimLight
@onready var _music: MenuMusic = $Music


func _ready() -> void:
	var menu := DataLoader.load_json(DataLoader.MENU_PATH)
	turntable_speed_deg = float(menu.get("turntable_speed_deg", turntable_speed_deg))

	var grid := DataLoader.load_json(DataLoader.GRID_PATH)
	var found := DataLoader.find_driver(grid, str(grid.get("default_driver_id", "colapinto")))
	var driver: Dictionary = found.get("driver", {})
	var team: Dictionary = found.get("team", {})
	_team_color = Color.html(str(team.get("color", FALLBACK_TEAM_COLOR.to_html())))

	_car.set_showcase(true)
	_car.set_team_color(_team_color)
	_rim_light.light_color = _team_color
	_build_ring()
	_setup_camera(menu.get("camera", {}))

	var music_data = menu.get("music", {})
	if music_data is Dictionary:
		_music.configure(music_data)
	_music.play()

	_build_ui(driver, team)
	_play_button.grab_focus()


func _process(delta: float) -> void:
	_turntable.rotate_y(deg_to_rad(turntable_speed_deg) * delta)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file(RACE_SCENE)


func _on_quit_pressed() -> void:
	get_tree().quit()


func _setup_camera(data) -> void:
	if not data is Dictionary:
		data = {}
	var eye := _vec3(data.get("position", []), Vector3(5.4, 1.8, 6.4))
	var target := _vec3(data.get("target", []), Vector3(0, 0.5, 0))
	_camera.look_at_from_position(eye, target)
	_camera.fov = float(data.get("fov", 45.0))
	_camera.h_offset = float(data.get("h_offset", -1.6))
	_camera.make_current()


## Aro luminoso con el color del equipo alrededor de la plataforma.
func _build_ring() -> void:
	var torus := TorusMesh.new()
	torus.inner_radius = RING_RADIUS - 0.04
	torus.outer_radius = RING_RADIUS + 0.04
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = _team_color
	var ring := MeshInstance3D.new()
	ring.name = "Ring"
	ring.mesh = torus
	ring.material_override = material
	ring.position = Vector3(0, 0.1, 0)
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ring)


func _build_ui(driver: Dictionary, team: Dictionary) -> void:
	var layer := CanvasLayer.new()
	layer.name = "UI"
	add_child(layer)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)

	# Izquierda: título y botones.
	var panel := VBoxContainer.new()
	panel.add_theme_constant_override("separation", 14)
	_place(panel, Vector4(0, 0.5, 0, 0.5), Vector4(80, -220, 520, 220))
	root.add_child(panel)

	panel.add_child(_make_label("GodotF126", 72))
	var subtitle := _make_label("Simulador de Fórmula 1 · Temporada 2026", 22)
	subtitle.add_theme_color_override("font_color", Color(0.8, 0.82, 0.88))
	panel.add_child(subtitle)
	var stripe := ColorRect.new()
	stripe.custom_minimum_size = Vector2(120, 5)
	stripe.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	stripe.color = _team_color
	panel.add_child(stripe)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 24)
	panel.add_child(spacer)

	_play_button = _make_button("Jugar")
	_play_button.pressed.connect(_on_play_pressed)
	panel.add_child(_play_button)
	var quit_button := _make_button("Salir")
	quit_button.pressed.connect(_on_quit_pressed)
	panel.add_child(quit_button)

	var hint := _make_label("Flechas para elegir · Enter para confirmar · Esc para salir", 16)
	hint.add_theme_color_override("font_color", Color(0.7, 0.72, 0.78))
	panel.add_child(hint)

	# Abajo a la derecha: piloto en exhibición.
	var card := HBoxContainer.new()
	card.add_theme_constant_override("separation", 12)
	card.alignment = BoxContainer.ALIGNMENT_END
	_place(card, Vector4(1, 1, 1, 1), Vector4(-460, -110, -40, -40))
	root.add_child(card)
	var card_text := VBoxContainer.new()
	card.add_child(card_text)
	var number = driver.get("number", "")
	var number_text := str(int(number)) if number is float else str(number)
	card_text.add_child(_make_label("#%s  %s" % [number_text, str(driver.get("name", "Piloto"))], 28, HORIZONTAL_ALIGNMENT_RIGHT))
	card_text.add_child(_make_label(str(team.get("name", "Equipo")), 20, HORIZONTAL_ALIGNMENT_RIGHT))
	var card_stripe := ColorRect.new()
	card_stripe.custom_minimum_size = Vector2(8, 64)
	card_stripe.color = _team_color
	card.add_child(card_stripe)

	# Abajo a la izquierda: créditos.
	var credits := _make_label("Agustín Giménez · 350 Ingeniería de Software Avanzado", 15)
	credits.add_theme_color_override("font_color", Color(0.6, 0.62, 0.68))
	_place(credits, Vector4(0, 1, 0, 1), Vector4(80, -50, 700, -20))
	root.add_child(credits)


func _make_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(300, 54)
	button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_font_size_override("font_size", 26)
	button.add_theme_color_override("font_color", Color(0.9, 0.9, 0.92))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_focus_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _button_style(Color(0, 0, 0, 0.45), Color(1, 1, 1, 0.15)))
	button.add_theme_stylebox_override("hover", _button_style(Color(0, 0, 0, 0.6), _team_color))
	button.add_theme_stylebox_override("focus", _button_style(Color(0, 0, 0, 0.6), _team_color))
	button.add_theme_stylebox_override("pressed", _button_style(_team_color.darkened(0.4), _team_color))
	button.mouse_entered.connect(button.grab_focus)
	return button


func _button_style(background: Color, accent: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = accent
	style.border_width_left = 6
	style.content_margin_left = 22
	style.content_margin_right = 22
	return style


func _make_label(text: String, font_size: int, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = align
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 6)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


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


func _vec3(value, fallback: Vector3) -> Vector3:
	if value is Array and value.size() == 3:
		return Vector3(float(value[0]), float(value[1]), float(value[2]))
	return fallback
