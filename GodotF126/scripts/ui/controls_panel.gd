class_name ControlsPanel
extends VBoxContainer
## Tutorial de controles (Paso 24), armado por código desde data/controls.json.
## Las teclas se leen del InputMap (project.godot), así el panel muestra siempre lo que
## de verdad hace cada tecla. Se usa en el menú, en la pausa y en la pantalla de carga.

signal closed

const DATA_PATH := "res://data/controls.json"
const KEY_COLUMN := 210.0
const KEY_NAMES := {
	"Up": "↑", "Down": "↓", "Left": "←", "Right": "→",
	"Space": "Espacio", "Escape": "Esc", "Enter": "Enter",
}

var accent: Color = Color("#FF87BC")
## Con false no hay botón Volver (pantalla de carga).
var with_back: bool = true

var _back: Button
var _chips: Array[PanelContainer] = []


func _ready() -> void:
	add_theme_constant_override("separation", 2)
	add_child(UiKit.make_label("Controles", 26))
	var data := DataLoader.load_json(DATA_PATH)
	for section in data.get("sections", []):
		if section is Dictionary:
			_add_section(section)
	if not with_back:
		return
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 6)
	add_child(spacer)
	_back = UiKit.make_button("Volver", accent, Vector2(200, 42), 20)
	_back.pressed.connect(func() -> void: closed.emit())
	add_child(_back)
	var hint := UiKit.make_label("Esc para volver", 16)
	hint.add_theme_color_override("font_color", Color(0.7, 0.72, 0.78))
	add_child(hint)


func open() -> void:
	if _back:
		_back.grab_focus()


func set_accent(color: Color) -> void:
	accent = color
	if _back:
		UiKit.apply_button_style(_back, color)
	for chip in _chips:
		chip.add_theme_stylebox_override("panel", _chip_style())


## Nombres de las teclas de una acción del InputMap ("W", "↑"…); vacío si no existe.
static func keys_for(action: String) -> PackedStringArray:
	var names := PackedStringArray()
	if not InputMap.has_action(action):
		return names
	for event in InputMap.action_get_events(action):
		var text := ""
		if event is InputEventKey:
			var key := event as InputEventKey
			var code := key.physical_keycode if key.physical_keycode != KEY_NONE else key.keycode
			text = OS.get_keycode_string(code)
		elif event is InputEventJoypadButton:
			text = "Botón %d" % (event as InputEventJoypadButton).button_index
		if not text.is_empty():
			names.append(KEY_NAMES.get(text, text))
	return names


func _add_section(section: Dictionary) -> void:
	var title := UiKit.make_label(str(section.get("title", "")), 18)
	title.add_theme_color_override("font_color", Color(0.75, 0.77, 0.83))
	add_child(title)
	for row_data in section.get("rows", []):
		if row_data is Dictionary:
			_add_row(row_data)


func _add_row(row_data: Dictionary) -> void:
	var keys := PackedStringArray()
	for action in row_data.get("actions", []):
		keys.append_array(keys_for(str(action)))
	for key in row_data.get("keys", []):
		keys.append(str(key))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	add_child(row)
	var key_box := HBoxContainer.new()
	key_box.add_theme_constant_override("separation", 4)
	key_box.custom_minimum_size = Vector2(KEY_COLUMN, 0)
	row.add_child(key_box)
	if keys.is_empty():
		key_box.add_child(UiKit.make_label("—", 18))
	for key in keys:
		key_box.add_child(_make_chip(key))
	var label := UiKit.make_label(str(row_data.get("text", "")), 19)
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(label)


## Tecla dibujada como un recuadro con borde del color del equipo.
func _make_chip(text: String) -> PanelContainer:
	var chip := PanelContainer.new()
	chip.add_theme_stylebox_override("panel", _chip_style())
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var label := UiKit.make_label(text, 17, HORIZONTAL_ALIGNMENT_CENTER)
	label.custom_minimum_size = Vector2(26, 0)
	chip.add_child(label)
	_chips.append(chip)
	return chip


func _chip_style() -> StyleBoxFlat:
	var style := UiKit.button_style(Color(0, 0, 0, 0.55), Color(accent, 0.8), 1, 1)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 1
	style.content_margin_bottom = 1
	style.set_corner_radius_all(4)
	return style
