class_name ModeSelect
extends VBoxContainer
## Elección del modo de juego (Paso 16), armada por código desde data/modes.json.
## Una tarjeta por modo; en las que tienen "lap_options" (contrarreloj) ← → cambian la
## cantidad de vueltas. Enter confirma y Esc vuelve al menú.

signal confirmed(mode_id: String, laps: int)
signal cancelled

const CARD_SIZE := Vector2(540, 78)

var accent: Color = Color("#FF87BC")

var _modes: Array = []
var _laps: Dictionary = {}           ## id de modo → vueltas elegidas
var _buttons: Dictionary = {}        ## id de modo → Button
var _titles: Dictionary = {}         ## id de modo → Label del título
var _current_mode: String = ""


func _ready() -> void:
	add_theme_constant_override("separation", 14)
	add_child(UiKit.make_label("Elegí modo", 26))


func setup(data: Dictionary, current_mode: String, current_laps: int) -> void:
	_modes = data.get("modes", [])
	_current_mode = current_mode if not current_mode.is_empty() else str(data.get("default_mode", ""))
	for mode in _modes:
		var id := str(mode.get("id", ""))
		var options: Array = mode.get("lap_options", [])
		if not options.is_empty():
			var laps := int(mode.get("default_laps", options[0]))
			if id == current_mode and current_laps > 0:
				laps = current_laps
			_laps[id] = laps
		add_child(_make_card(mode))
	var hint := UiKit.make_label("← → cambian las vueltas · Enter para confirmar · Esc para volver", 16)
	hint.add_theme_color_override("font_color", Color(0.7, 0.72, 0.78))
	add_child(hint)


## Muestra los modos con el foco en el último elegido.
func open() -> void:
	var button: Button = _buttons.get(_current_mode)
	if button == null and not _buttons.is_empty():
		button = _buttons.values()[0]
	if button != null:
		button.grab_focus()


func back() -> void:
	cancelled.emit()


func set_accent(color: Color) -> void:
	accent = color
	for button in _buttons.values():
		UiKit.apply_button_style(button, color)


func _make_card(mode: Dictionary) -> Button:
	var id := str(mode.get("id", ""))
	var button := UiKit.make_button("", accent, CARD_SIZE)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiKit.place(box, Vector4(0, 0, 1, 1), Vector4(22, 8, -12, -8))
	button.add_child(box)
	var title := UiKit.make_label("", 24)
	box.add_child(title)
	var description := UiKit.make_label(str(mode.get("description", "")), 15)
	description.add_theme_color_override("font_color", Color(0.75, 0.77, 0.82))
	box.add_child(description)
	_buttons[id] = button
	_titles[id] = title
	_refresh_title(mode)

	button.pressed.connect(func() -> void:
		_current_mode = id
		confirmed.emit(id, int(_laps.get(id, 0))))
	if _laps.has(id):
		button.gui_input.connect(func(event: InputEvent) -> void:
			if event.is_action_pressed("ui_right"):
				_cycle_laps(mode, 1)
				button.accept_event()
			elif event.is_action_pressed("ui_left"):
				_cycle_laps(mode, -1)
				button.accept_event())
	return button


func _cycle_laps(mode: Dictionary, direction: int) -> void:
	var id := str(mode.get("id", ""))
	var options: Array = mode.get("lap_options", [])
	var index := 0
	for i in options.size():
		if int(options[i]) == int(_laps[id]):
			index = i
	_laps[id] = int(options[posmod(index + direction, options.size())])
	_refresh_title(mode)


func _refresh_title(mode: Dictionary) -> void:
	var id := str(mode.get("id", ""))
	var text := str(mode.get("name", id))
	if _laps.has(id):
		var laps := int(_laps[id])
		text += "   ‹ %d %s ›" % [laps, "vuelta" if laps == 1 else "vueltas"]
	_titles[id].text = text
