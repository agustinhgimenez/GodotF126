class_name BindingsPanel
extends VBoxContainer
## Pantalla "Asignar controles" (Paso 37; se abre desde el panel de Controles). Una fila por
## acción de data/input.json con su tecla y su control del mando: Enter (o A) en la celda
## espera la tecla / el botón / el eje nuevo (Esc cancela; a los 6 s se cancela sola) y Supr
## la deja vacía. Lo que se asigna se saca de las otras acciones que lo usaban. Debajo:
## pedales (gatillos 0 a 1 o volante −1 a 1), zona muerta y curva de la dirección y
## vibración. Todo se guarda al instante en Settings (user://settings.json).

signal closed

const NAME_WIDTH := 232.0
const KEY_SIZE := Vector2(160, 28)
const PAD_SIZE := Vector2(180, 28)
const LIST_HEIGHT := 214.0
const DIM := Color(0.7, 0.72, 0.78)
const WAITING := Color(1.0, 0.85, 0.3)
## [clave de Settings, texto, [valores], [textos]]
const CHOICES := [
	["pedal_range", "Pedales", ["half", "full"], ["Gatillos (0 a 1)", "Volante (−1 a 1)"]],
	["steer_deadzone", "Zona muerta dirección", [0, 4, 8, 12, 16, 20, 25, 30], []],
	["steer_curve", "Curva de dirección", [1.0, 1.5, 2.0], ["Lineal", "Suave", "Muy suave"]],
	["vibration", "Vibración", [0, 25, 50, 75, 100], []],
]

var accent: Color = Color("#FF87BC")

var _status: Label
var _scroll: ScrollContainer
var _buttons: Array[Button] = []
var _key_buttons: Dictionary = {}     ## acción → Button
var _pad_buttons: Dictionary = {}     ## acción → Button
var _choice_buttons: Dictionary = {}  ## clave → Button
var _first: Button
var _capture_action: String = ""
var _capture_slot: String = ""
var _capture_left: float = 0.0
var _axis_start: Dictionary = {}      ## dispositivo → PackedFloat32Array con los ejes al empezar
var _message: String = ""


func _ready() -> void:
	add_theme_constant_override("separation", 3)
	add_child(UiKit.make_label("Asignar controles", 26))
	_status = UiKit.make_label("", 15)
	_status.add_theme_color_override("font_color", DIM)
	add_child(_status)

	var header := _make_row()
	add_child(header)
	for column in [["Acción", NAME_WIDTH], ["Teclado", KEY_SIZE.x], ["Mando", PAD_SIZE.x]]:
		var label := UiKit.make_label(str(column[0]), 15)
		label.add_theme_color_override("font_color", DIM)
		label.custom_minimum_size = Vector2(float(column[1]), 0)
		header.add_child(label)

	_scroll = ScrollContainer.new()
	_scroll.custom_minimum_size = Vector2(NAME_WIDTH + KEY_SIZE.x + PAD_SIZE.x + 40, LIST_HEIGHT)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.follow_focus = true
	add_child(_scroll)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 2)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(list)
	for entry in InputBindings.actions():
		_add_action_row(list, str(entry["id"]), str(entry.get("name", entry["id"])))

	for choice in CHOICES:
		_add_choice(choice)

	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 10)
	add_child(footer)
	var reset := _make_button("Por defecto", Vector2(150, 38), 19)
	reset.pressed.connect(func() -> void:
		Settings.reset_input()
		_message = "Controles por defecto"
		refresh())
	footer.add_child(reset)
	var back := _make_button("Volver", Vector2(150, 38), 19)
	back.pressed.connect(func() -> void: closed.emit())
	footer.add_child(back)
	var hint := UiKit.make_label("Enter asignar · Supr borrar\nEsc volver · se guarda solo", 14)
	hint.add_theme_color_override("font_color", DIM)
	hint.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	footer.add_child(hint)

	Input.joy_connection_changed.connect(func(_device: int, _connected: bool) -> void: refresh())
	refresh()


func open() -> void:
	_message = ""
	_cancel_capture()
	refresh()
	_scroll.scroll_vertical = 0
	_first.grab_focus()


func set_accent(color: Color) -> void:
	accent = color
	for button in _buttons:
		UiKit.apply_button_style(button, color)


func is_capturing() -> bool:
	return not _capture_action.is_empty()


func refresh() -> void:
	var overrides: Dictionary = Settings.get_value("bindings")
	for action in _key_buttons:
		var bound := InputBindings.binding(action, overrides)
		_key_buttons[action].text = InputBindings.keys_text(bound["keys"])
		_pad_buttons[action].text = InputBindings.pad_text(bound["pad"])
	for choice in CHOICES:
		_choice_buttons[choice[0]].text = "‹  %s  ›" % _choice_text(choice, Settings.get_value(choice[0]))
	if is_capturing():
		var button: Button = (_key_buttons if _capture_slot == "keys" else _pad_buttons)[_capture_action]
		button.text = "…"
		var what := "una tecla" if _capture_slot == "keys" else ("un botón o un eje" if InputBindings.is_analog(_capture_action) else "un botón") + " del mando"
		_status.text = "Apretá %s para «%s» · Esc cancela (%d s)" % [what, InputBindings.action_name(_capture_action), ceili(_capture_left)]
		_status.add_theme_color_override("font_color", WAITING)
		return
	_status.add_theme_color_override("font_color", DIM)
	var pads := InputBindings.connected_pads()
	var pads_text := "Mando: %s" % ", ".join(pads) if not pads.is_empty() else "Ningún mando conectado"
	_status.text = pads_text if _message.is_empty() else "%s · %s" % [_message, pads_text]


func _process(delta: float) -> void:
	if not is_capturing():
		return
	var before := ceili(_capture_left)
	_capture_left -= delta
	if _capture_left <= 0.0:
		_end_capture("Sin cambios (no se apretó nada)")
	elif ceili(_capture_left) != before:
		refresh()


func _input(event: InputEvent) -> void:
	if not is_capturing() or not visible:
		return
	if event is InputEventKey:
		var key := event as InputEventKey
		if not key.pressed or key.echo:
			return
		get_viewport().set_input_as_handled()
		var code := key.physical_keycode if key.physical_keycode != KEY_NONE else key.keycode
		if code == KEY_ESCAPE:
			_end_capture("Cancelado")
		elif _capture_slot == "keys":
			_assign([int(code)])
	elif event is InputEventJoypadButton or event is InputEventJoypadMotion:
		get_viewport().set_input_as_handled()
		if _capture_slot != "pad":
			return
		if event is InputEventJoypadButton:
			if (event as InputEventJoypadButton).pressed:
				_assign(InputBindings.pad_from_event(event))
		elif InputBindings.is_analog(_capture_action):
			var motion := event as InputEventJoypadMotion
			var start := 0.0
			var axes: PackedFloat32Array = _axis_start.get(motion.device, PackedFloat32Array())
			if int(motion.axis) < axes.size():
				start = axes[int(motion.axis)]
			var change := motion.axis_value - start
			if absf(change) >= float(InputBindings.data().get("capture_axis_change", 0.5)):
				_assign({"axis": int(motion.axis), "sign": -1 if change < 0.0 else 1})


func _start_capture(action: String, slot: String) -> void:
	_capture_action = action
	_capture_slot = slot
	_capture_left = float(InputBindings.data().get("capture_timeout", 6.0))
	_axis_start.clear()
	for device in Input.get_connected_joypads():
		var axes := PackedFloat32Array()
		for axis in 10:
			axes.append(Input.get_joy_axis(device, axis as JoyAxis))
		_axis_start[device] = axes
	refresh()


func _assign(value) -> void:
	var action := _capture_action
	var slot := _capture_slot
	_cancel_capture()
	_set_binding(action, slot, value)


func _set_binding(action: String, slot: String, value) -> void:
	var result := InputBindings.assign(Settings.get_value("bindings"), action, slot, value)
	Settings.set_value("bindings", result["overrides"])
	var bound := InputBindings.binding(action, result["overrides"])
	var text := InputBindings.keys_text(bound["keys"]) if slot == "keys" else InputBindings.pad_text(bound["pad"])
	_message = "%s: %s" % [InputBindings.action_name(action), text]
	var removed: PackedStringArray = result["removed_from"]
	if not removed.is_empty():
		var names := PackedStringArray()
		for other in removed:
			names.append(InputBindings.action_name(other))
		_message += " (se sacó de %s)" % ", ".join(names)
	refresh()
	var button: Button = (_key_buttons if slot == "keys" else _pad_buttons)[action]
	button.grab_focus()


func _end_capture(message: String) -> void:
	var button: Button = (_key_buttons if _capture_slot == "keys" else _pad_buttons)[_capture_action]
	_cancel_capture()
	_message = message
	refresh()
	button.grab_focus()


func _cancel_capture() -> void:
	_capture_action = ""
	_capture_slot = ""


func _add_action_row(list: VBoxContainer, action: String, text: String) -> void:
	var row := _make_row()
	list.add_child(row)
	var label := UiKit.make_label(text, 17)
	label.custom_minimum_size = Vector2(NAME_WIDTH, 0)
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(label)
	for slot in ["keys", "pad"]:
		var button := _make_button("", KEY_SIZE if slot == "keys" else PAD_SIZE, 16)
		button.alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.pressed.connect(func() -> void:
			if not is_capturing():
				_start_capture(action, slot))
		button.gui_input.connect(func(event: InputEvent) -> void:
			if is_capturing() or not event is InputEventKey or not event.pressed:
				return
			var code := (event as InputEventKey).keycode
			if code == KEY_DELETE or code == KEY_BACKSPACE:
				button.accept_event()
				_set_binding(action, slot, [] if slot == "keys" else {}))
		row.add_child(button)
		if slot == "keys":
			_key_buttons[action] = button
		else:
			_pad_buttons[action] = button
		if _first == null:
			_first = button


func _add_choice(choice: Array) -> void:
	var row := _make_row()
	add_child(row)
	var label := UiKit.make_label(str(choice[1]), 18)
	label.custom_minimum_size = Vector2(NAME_WIDTH, 0)
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(label)
	var button := _make_button("", Vector2(KEY_SIZE.x + PAD_SIZE.x + 10, 30), 17)
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.pressed.connect(func() -> void: _cycle(choice, 1))
	button.gui_input.connect(func(event: InputEvent) -> void:
		if event.is_action_pressed("ui_right"):
			_cycle(choice, 1)
			button.accept_event()
		elif event.is_action_pressed("ui_left"):
			_cycle(choice, -1)
			button.accept_event())
	row.add_child(button)
	_choice_buttons[choice[0]] = button


func _cycle(choice: Array, direction: int) -> void:
	var options: Array = choice[2]
	var index := _index_of(choice, Settings.get_value(choice[0]))
	Settings.set_value(choice[0], options[posmod(index + direction, options.size())])
	refresh()


func _choice_text(choice: Array, value) -> String:
	var texts: Array = choice[3]
	var index := _index_of(choice, value)
	if index < texts.size():
		return str(texts[index])
	if choice[0] == "vibration" and int(value) == 0:
		return "No"
	return "%d %%" % int(value)


func _index_of(choice: Array, value) -> int:
	var options: Array = choice[2]
	for i in options.size():
		var option = options[i]
		if option is String:
			if str(value) == option:
				return i
		elif (value is int or value is float) and is_equal_approx(float(option), float(value)):
			return i
	return 0


func _make_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	return row


func _make_button(text: String, min_size: Vector2, font_size: int) -> Button:
	var button := UiKit.make_button(text, accent, min_size, font_size)
	_buttons.append(button)
	return button
