class_name ControlsPanel
extends VBoxContainer
## Tutorial de controles (Paso 24), armado por código desde data/controls.json.
## Las teclas se leen del InputMap, así el panel muestra siempre lo que de verdad hace cada
## tecla; con un mando conectado muestra los botones del mando (Paso 37). Se usa en el
## menú, en la pausa y en la pantalla de carga. Con botón Volver también tiene "Asignar
## controles", que cambia el tutorial por la pantalla de asignación (BindingsPanel) dentro
## del mismo panel; Esc vuelve de ahí al tutorial.

signal closed

const DATA_PATH := "res://data/controls.json"
const KEY_COLUMN := 210.0

var accent: Color = Color("#FF87BC")
## Con false no hay botón Volver ni Asignar (pantalla de carga).
var with_back: bool = true

var _tutorial: VBoxContainer
var _rows: VBoxContainer
var _bindings: BindingsPanel
var _back: Button
var _assign: Button
var _chips: Array[PanelContainer] = []
var _showing_pad: bool = false


func _ready() -> void:
	_tutorial = VBoxContainer.new()
	_tutorial.add_theme_constant_override("separation", 1)
	add_child(_tutorial)
	_tutorial.add_child(UiKit.make_label("Controles", 26))
	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 1)
	_tutorial.add_child(_rows)
	_build_rows()
	Input.joy_connection_changed.connect(func(_device: int, _connected: bool) -> void:
		if _showing_pad != _pad_connected():
			_build_rows())
	if not with_back:
		return
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 14)
	_tutorial.add_child(footer)
	_back = UiKit.make_button("Volver", accent, Vector2(200, 40), 20)
	_back.pressed.connect(func() -> void: closed.emit())
	footer.add_child(_back)
	_assign = UiKit.make_button("Asignar controles", accent, Vector2(230, 40), 20)
	_assign.pressed.connect(_open_bindings)
	footer.add_child(_assign)
	var hint := UiKit.make_label("Esc para volver", 16)
	hint.add_theme_color_override("font_color", Color(0.7, 0.72, 0.78))
	hint.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	footer.add_child(hint)

	_bindings = BindingsPanel.new()
	_bindings.visible = false
	_bindings.accent = accent
	_bindings.closed.connect(_close_bindings)
	add_child(_bindings)


func open() -> void:
	if _bindings != null and _bindings.visible:
		_close_bindings()
	elif _showing_pad != _pad_connected():
		_build_rows()
	if _back:
		_back.grab_focus()


func set_accent(color: Color) -> void:
	accent = color
	if _back:
		UiKit.apply_button_style(_back, color)
		UiKit.apply_button_style(_assign, color)
		_bindings.set_accent(color)
	for chip in _chips:
		chip.add_theme_stylebox_override("panel", _chip_style())


## Esc en la pantalla de asignación vuelve al tutorial (y no cierra el panel).
func _unhandled_input(event: InputEvent) -> void:
	if _bindings == null or not _bindings.visible or not is_visible_in_tree():
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close_bindings()


func _open_bindings() -> void:
	_tutorial.visible = false
	_bindings.visible = true
	_bindings.open()


func _close_bindings() -> void:
	_bindings.visible = false
	_tutorial.visible = true
	_build_rows()
	_assign.grab_focus()


## Nombres de las teclas de una acción del InputMap ("W", "↑"…); vacío si no existe.
static func keys_for(action: String) -> PackedStringArray:
	var names := PackedStringArray()
	if not InputMap.has_action(action):
		return names
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			var key := event as InputEventKey
			names.append(InputBindings.key_text(key.physical_keycode if key.physical_keycode != KEY_NONE else key.keycode))
	return names


func _pad_connected() -> bool:
	return not Input.get_connected_joypads().is_empty()


func _build_rows() -> void:
	_showing_pad = _pad_connected()
	for child in _rows.get_children():
		child.queue_free()
	_chips.clear()
	var data := DataLoader.load_json(DATA_PATH)
	for section in data.get("sections", []):
		if section is Dictionary:
			_add_section(section)


func _add_section(section: Dictionary) -> void:
	var title := UiKit.make_label(str(section.get("title", "")), 18)
	title.add_theme_color_override("font_color", Color(0.75, 0.77, 0.83))
	_rows.add_child(title)
	for row_data in section.get("rows", []):
		if row_data is Dictionary:
			_add_row(row_data)


func _add_row(row_data: Dictionary) -> void:
	var keys := PackedStringArray()
	for action in row_data.get("actions", []):
		if _showing_pad:
			keys.append_array(InputBindings.pad_names_for(str(action)))
		else:
			keys.append_array(keys_for(str(action)))
	for key in row_data.get("pad_keys" if _showing_pad else "keys", row_data.get("keys", [])):
		keys.append(str(key))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	_rows.add_child(row)
	var key_box := HBoxContainer.new()
	key_box.add_theme_constant_override("separation", 4)
	key_box.custom_minimum_size = Vector2(KEY_COLUMN, 0)
	row.add_child(key_box)
	if keys.is_empty():
		key_box.add_child(UiKit.make_label("—", 18))
	for key in keys:
		key_box.add_child(_make_chip(key))
	var label := UiKit.make_label(str(row_data.get("text", "")), 18)
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(label)


## Tecla dibujada como un recuadro con borde del color del equipo.
func _make_chip(text: String) -> PanelContainer:
	var chip := PanelContainer.new()
	chip.add_theme_stylebox_override("panel", _chip_style())
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var label := UiKit.make_label(text, 16, HORIZONTAL_ALIGNMENT_CENTER)
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
