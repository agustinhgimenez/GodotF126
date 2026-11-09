class_name OnlineLobby
extends VBoxContainer
## Multijugador online (menú principal): el nombre con el que juega (lo ve el rival; el piloto
## se elige aparte), "Crear sala" (el menú abre las reglas de la sala) y "Unirse a una sala",
## que lista las salas abiertas del servidor y se actualiza sola mientras se mira.
## Enter en una sala la elige (room_chosen); Esc vuelve.

signal create_requested
signal room_chosen(room: Dictionary)
signal cancelled

const CARD_SIZE := Vector2(540, 78)
const LIST_HEIGHT := 360.0

var accent: Color = Color("#FF87BC")

var _heading: Label
var _home: VBoxContainer
var _name_edit: LineEdit
var _create_button: Button
var _join_button: Button
var _rooms_box: VBoxContainer
var _rooms_status: Label
var _rooms_list: VBoxContainer
var _room_buttons: Array[Button] = []
var _track_names: Dictionary = {}
var _weather_names: Dictionary = {}
var _compound_names: Dictionary = {}


func _ready() -> void:
	add_theme_constant_override("separation", 14)
	_read_names()
	_heading = UiKit.make_label("Multijugador online", 26)
	add_child(_heading)

	_home = VBoxContainer.new()
	_home.add_theme_constant_override("separation", 14)
	add_child(_home)
	var name_label := UiKit.make_label("Tu nombre (lo ve el rival; el piloto lo elegís después)", 16)
	name_label.add_theme_color_override("font_color", Color(0.75, 0.77, 0.82))
	_home.add_child(name_label)
	_name_edit = LineEdit.new()
	_name_edit.max_length = Online.MAX_NAME
	_name_edit.placeholder_text = "Escribí tu nombre"
	_name_edit.custom_minimum_size = Vector2(CARD_SIZE.x, 54)
	_name_edit.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_name_edit.add_theme_font_size_override("font_size", 24)
	_name_edit.text_submitted.connect(func(_text: String) -> void: _create_button.grab_focus())
	_name_edit.focus_exited.connect(_save_name)
	_home.add_child(_name_edit)
	_create_button = _card("Crear sala", "Elegís pista, clima, vueltas y neumáticos: valen para los dos")
	_create_button.pressed.connect(func() -> void:
		_confirm_name()
		create_requested.emit())
	_home.add_child(_create_button)
	_join_button = _card("Unirse a una sala", "Las salas abiertas por otros jugadores")
	_join_button.pressed.connect(open_rooms)
	_home.add_child(_join_button)
	_home.add_child(_hint("Flechas para elegir · Enter para confirmar · Esc para volver"))

	_rooms_box = VBoxContainer.new()
	_rooms_box.add_theme_constant_override("separation", 14)
	add_child(_rooms_box)
	_rooms_status = UiKit.make_label("", 18)
	_rooms_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_rooms_status.custom_minimum_size = Vector2(CARD_SIZE.x, 0)
	_rooms_box.add_child(_rooms_status)
	var scroll := ScrollContainer.new()
	scroll.follow_focus = true
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	scroll.custom_minimum_size = Vector2(CARD_SIZE.x + 10, LIST_HEIGHT)
	_rooms_box.add_child(scroll)
	_rooms_list = VBoxContainer.new()
	_rooms_list.add_theme_constant_override("separation", 14)
	scroll.add_child(_rooms_list)
	_rooms_box.add_child(_hint("Enter para entrar · Esc para volver"))

	Online.rooms_changed.connect(_on_rooms_changed)
	Online.status_changed.connect(_on_status)
	Online.failed.connect(_on_failed)


func _exit_tree() -> void:
	if Online.rooms_changed.is_connected(_on_rooms_changed):
		Online.rooms_changed.disconnect(_on_rooms_changed)
		Online.status_changed.disconnect(_on_status)
		Online.failed.disconnect(_on_failed)


## Pantalla inicial con el foco en el nombre si todavía no tiene uno.
func open() -> void:
	_heading.text = "Multijugador online"
	_rooms_box.visible = false
	_home.visible = true
	_name_edit.text = str(Settings.get_value("player_name"))
	if _name_edit.text.is_empty():
		_name_edit.grab_focus()
	else:
		_create_button.grab_focus()


## Lista de salas (pide la lista al servidor y la mantiene al día).
func open_rooms() -> void:
	_confirm_name()
	_heading.text = "Unirse a una sala"
	_home.visible = false
	_rooms_box.visible = true
	_clear_rooms()
	_rooms_status.text = "Buscando salas…"
	Online.browse()


func back() -> void:
	if _rooms_box.visible:
		Online.leave()
		open()
		_join_button.grab_focus()
	else:
		_save_name()
		cancelled.emit()


func set_accent(color: Color) -> void:
	accent = color
	for button in [_create_button, _join_button] + _room_buttons:
		UiKit.apply_button_style(button, color)


func _save_name() -> void:
	var name := Online.clean_name(_name_edit.text)
	if name != str(Settings.get_value("player_name")):
		Settings.set_value("player_name", name)


## Al crear o unirse: sin nombre escrito juega como "Jugador NNN".
func _confirm_name() -> void:
	_save_name()
	_name_edit.text = Online.player_name()


func _on_status(text: String) -> void:
	if _rooms_box.visible and _room_buttons.is_empty():
		_rooms_status.text = text


func _on_failed(reason: String) -> void:
	if _rooms_box.visible:
		_clear_rooms()
		_rooms_status.text = "%s · Esc para volver" % reason


func _on_rooms_changed(rooms: Array) -> void:
	if not _rooms_box.visible:
		return
	var focused := -1
	for i in _room_buttons.size():
		if _room_buttons[i].has_focus():
			focused = i
	_clear_rooms()
	if rooms.is_empty():
		_rooms_status.text = "No hay salas abiertas. Creá una o esperá: la lista se actualiza sola."
		return
	_rooms_status.text = "%d %s abierta%s" % [rooms.size(), "sala" if rooms.size() == 1 else "salas", "" if rooms.size() == 1 else "s"]
	for room in rooms:
		var button := _card(_room_title(room), _room_description(room))
		var chosen: Dictionary = room
		button.pressed.connect(func() -> void:
			Online.leave()
			room_chosen.emit(chosen))
		_rooms_list.add_child(button)
		_room_buttons.append(button)
	_room_buttons[clampi(focused, 0, _room_buttons.size() - 1)].grab_focus()


func _clear_rooms() -> void:
	for button in _room_buttons:
		button.queue_free()
	_room_buttons.clear()


func _room_title(room: Dictionary) -> String:
	var track := str(room.get("track", ""))
	return "Sala de %s   ·   %s" % [str(room.get("host", "?")), _track_names.get(track, track)]


func _room_description(room: Dictionary) -> String:
	var laps := int(room.get("laps", 2))
	var parts := PackedStringArray(["%d %s" % [laps, "vuelta" if laps == 1 else "vueltas"]])
	var weather := str(room.get("weather", ""))
	parts.append(str(_weather_names.get(weather, _weather_names.get("", "Seco"))))
	var compound := str(room.get("compound", ""))
	if _compound_names.has(compound):
		parts.append("neumático %s" % str(_compound_names[compound]).to_lower())
	if not str(room.get("driver", "")).is_empty():
		parts.append("con %s" % str(room["driver"]))
	return " · ".join(parts)


func _read_names() -> void:
	for info in DataLoader.load_json(DataLoader.TRACKS_PATH).get("tracks", []):
		if info is Dictionary:
			_track_names[str(info.get("id", ""))] = str(info.get("name", info.get("id", "")))
	var conditions := Weather.conditions()
	for i in conditions.size():
		var condition = conditions[i]
		if condition is Dictionary:
			_weather_names[str(condition.get("id", ""))] = str(condition.get("name", ""))
			if i == 0:
				_weather_names[""] = str(condition.get("name", ""))
	var compounds = DataLoader.load_json(DataLoader.CAR_PATH).get("tyre_compounds", {})
	if compounds is Dictionary:
		for compound in compounds.get("compounds", []):
			if compound is Dictionary:
				_compound_names[str(compound.get("id", ""))] = str(compound.get("name", ""))


func _card(title_text: String, description_text: String) -> Button:
	var button := UiKit.make_button("", accent, CARD_SIZE)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiKit.place(box, Vector4(0, 0, 1, 1), Vector4(22, 8, -12, -8))
	button.add_child(box)
	var title := UiKit.make_label(title_text, 24)
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	box.add_child(title)
	var description := UiKit.make_label(description_text, 15)
	description.add_theme_color_override("font_color", Color(0.75, 0.77, 0.82))
	description.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	box.add_child(description)
	return button


func _hint(text: String) -> Label:
	var hint := UiKit.make_label(text, 16)
	hint.add_theme_color_override("font_color", Color(0.7, 0.72, 0.78))
	return hint
