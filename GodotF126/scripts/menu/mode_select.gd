class_name ModeSelect
extends VBoxContainer
## Elección del modo de juego (Paso 16), armada por código desde data/modes.json.
## Una tarjeta por modo; en las que tienen "lap_options" (contrarreloj) ← → cambian la
## cantidad de vueltas. Debajo, la tarjeta de neumáticos (Paso 33): ← → (o Enter) cambian
## el compuesto ("tyre_compounds" de data/car.json). Enter en un modo confirma y Esc
## vuelve al menú.

signal confirmed(mode_id: String, laps: int, compound_id: String)
signal cancelled

const CARD_SIZE := Vector2(540, 78)

var accent: Color = Color("#FF87BC")

var _modes: Array = []
var _laps: Dictionary = {}           ## id de modo → vueltas elegidas
var _buttons: Dictionary = {}        ## id de modo → Button
var _titles: Dictionary = {}         ## id de modo → Label del título
var _current_mode: String = ""
var _compounds: Array = []
var _compound_index: int = 0
var _tyre_button: Button
var _tyre_title: Label
var _tyre_description: Label


func _ready() -> void:
	add_theme_constant_override("separation", 14)
	add_child(UiKit.make_label("Elegí modo", 26))


## compounds: bloque "tyre_compounds" de car.json; current_compound vacío = su "default".
func setup(data: Dictionary, current_mode: String, current_laps: int, compounds: Dictionary = {},
		current_compound: String = "") -> void:
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
	var list = compounds.get("compounds", [])
	if list is Array and not list.is_empty():
		_compounds = list
		var wanted := current_compound if not current_compound.is_empty() else str(compounds.get("default", ""))
		for i in _compounds.size():
			if str(_compounds[i].get("id", "")) == wanted:
				_compound_index = i
		add_child(_make_tyre_card())
	var hint := UiKit.make_label("← → vueltas y neumáticos · Enter para confirmar · Esc para volver", 16)
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
	if _tyre_button != null:
		UiKit.apply_button_style(_tyre_button, color)


## Id del compuesto elegido (vacío si car.json no trae compuestos).
func compound_id() -> String:
	if _compounds.is_empty():
		return ""
	return str(_compounds[_compound_index].get("id", ""))


func _make_card(mode: Dictionary) -> Button:
	var id := str(mode.get("id", ""))
	var parts := _card(str(mode.get("description", "")))
	var button: Button = parts[0]
	_buttons[id] = button
	_titles[id] = parts[1]
	_refresh_title(mode)

	button.pressed.connect(func() -> void:
		_current_mode = id
		confirmed.emit(id, int(_laps.get(id, 0)), compound_id()))
	if _laps.has(id):
		button.gui_input.connect(func(event: InputEvent) -> void:
			if event.is_action_pressed("ui_right"):
				_cycle_laps(mode, 1)
				button.accept_event()
			elif event.is_action_pressed("ui_left"):
				_cycle_laps(mode, -1)
				button.accept_event())
	return button


func _make_tyre_card() -> Button:
	var parts := _card("")
	_tyre_button = parts[0]
	_tyre_title = parts[1]
	_tyre_description = parts[2]
	_refresh_tyre()
	_tyre_button.pressed.connect(_cycle_compound.bind(1))
	_tyre_button.gui_input.connect(func(event: InputEvent) -> void:
		if event.is_action_pressed("ui_right"):
			_cycle_compound(1)
			_tyre_button.accept_event()
		elif event.is_action_pressed("ui_left"):
			_cycle_compound(-1)
			_tyre_button.accept_event())
	return _tyre_button


## [Button, título, descripción] de una tarjeta.
func _card(description_text: String) -> Array:
	var button := UiKit.make_button("", accent, CARD_SIZE)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiKit.place(box, Vector4(0, 0, 1, 1), Vector4(22, 8, -12, -8))
	button.add_child(box)
	var title := UiKit.make_label("", 24)
	box.add_child(title)
	var description := UiKit.make_label(description_text, 15)
	description.add_theme_color_override("font_color", Color(0.75, 0.77, 0.82))
	box.add_child(description)
	return [button, title, description]


func _cycle_laps(mode: Dictionary, direction: int) -> void:
	var id := str(mode.get("id", ""))
	var options: Array = mode.get("lap_options", [])
	var index := 0
	for i in options.size():
		if int(options[i]) == int(_laps[id]):
			index = i
	_laps[id] = int(options[posmod(index + direction, options.size())])
	_refresh_title(mode)


func _cycle_compound(direction: int) -> void:
	_compound_index = posmod(_compound_index + direction, _compounds.size())
	_refresh_tyre()


func _refresh_title(mode: Dictionary) -> void:
	var id := str(mode.get("id", ""))
	var text := str(mode.get("name", id))
	if _laps.has(id):
		var laps := int(_laps[id])
		text += "   ‹ %d %s ›" % [laps, "vuelta" if laps == 1 else "vueltas"]
	_titles[id].text = text


func _refresh_tyre() -> void:
	var compound: Dictionary = _compounds[_compound_index]
	_tyre_title.text = "Neumáticos   ‹ %s ›" % str(compound.get("name", ""))
	_tyre_title.add_theme_color_override("font_color", Color.from_string(str(compound.get("color", "#FFFFFF")), Color.WHITE))
	_tyre_description.text = str(compound.get("description", ""))
