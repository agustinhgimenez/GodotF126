class_name SetupPanel
extends VBoxContainer
## Pantalla del setup del auto (Paso 35), armada por código desde data/setup.json. Una fila
## por ajuste (← → o Enter lo cambian, sin dar la vuelta en los extremos) con lo que cambia
## al lado; abajo la descripción del ajuste elegido y el resultado (ClA, CdA, reparto de la
## carga, piso y velocidad máxima). Cada cambio se guarda al instante en user://setup.json.

signal closed
signal changed

const LABEL_WIDTH := 220.0
const CONTROL_SIZE := Vector2(160, 30)
const NOTE_WIDTH := 150.0
const DIM := Color(0.7, 0.72, 0.78)

var accent: Color = Color("#FF87BC")

var _setup: CarSetup
var _base: Dictionary = {}
var _first: Control
var _value_buttons: Dictionary = {}   ## id → Button
var _notes: Dictionary = {}           ## id → Label con lo que cambia
var _buttons: Array[Button] = []
var _description: Label
var _result: Label


func _ready() -> void:
	add_theme_constant_override("separation", 2)
	add_child(UiKit.make_label("Setup del auto", 26))


## base: CarSetup.base_from_car_data() o CarController.setup_base().
func setup(car_setup: CarSetup, base: Dictionary) -> void:
	_setup = car_setup
	_base = base
	for entry in _setup.items:
		_add_row(entry)

	_description = UiKit.make_label("", 15)
	_description.add_theme_color_override("font_color", DIM)
	_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_description.custom_minimum_size = Vector2(LABEL_WIDTH + CONTROL_SIZE.x + NOTE_WIDTH + 24, 40)
	add_child(_description)
	_result = UiKit.make_label("", 16)
	add_child(_result)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	add_child(actions)
	var reset := _make_button("Por defecto", Vector2(170, 40))
	reset.pressed.connect(func() -> void:
		_setup.reset_to_defaults()
		_on_changed())
	reset.focus_entered.connect(func() -> void: _description.text = "Vuelve todos los ajustes a su valor de fábrica")
	actions.add_child(reset)
	var back := _make_button("Volver", Vector2(170, 40))
	back.pressed.connect(func() -> void: closed.emit())
	back.focus_entered.connect(func() -> void: _description.text = "")
	actions.add_child(back)
	var hint := UiKit.make_label("← → cambiar · Esc volver\nse guarda solo", 15)
	hint.add_theme_color_override("font_color", DIM)
	hint.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	actions.add_child(hint)
	refresh()


func open() -> void:
	refresh()
	if _first != null:
		_first.grab_focus()


func set_accent(color: Color) -> void:
	accent = color
	for button in _buttons:
		UiKit.apply_button_style(button, color)


func refresh() -> void:
	if _setup == null:
		return
	var values := _setup.derive(_base)
	for entry in _setup.items:
		var id := str(entry.get("id", ""))
		var low := is_equal_approx(_setup.get_value(id), float(entry.get("min", 0.0)))
		var high := is_equal_approx(_setup.get_value(id), float(entry.get("max", 0.0)))
		_value_buttons[id].text = "%s  %s  %s" % [" " if low else "‹", _setup.value_text(id), " " if high else "›"]
		_notes[id].text = _note(id, values)
	_result.text = "ClA %.2f · CdA %.2f · carga %d %% adelante · máx. %d km/h" % [float(values["cla"]),
		float(values["cda"]), roundi(float(values["balance"]) * 100.0), roundi(float(values["top_speed_kmh"]))]


## Lo que cambia cada ajuste, en la columna de la derecha.
func _note(id: String, values: Dictionary) -> String:
	var stiffness: Vector2 = values["stiffness"]
	var bars: Vector2 = values["anti_roll"]
	var pressure: Vector2 = values["pressure"]
	var reference := _setup.default_pressure()
	match id:
		"front_wing":
			return "ClA adel. %.2f" % (float(values["cla"]) * float(values["balance"]))
		"rear_wing":
			return "ClA atrás %.2f" % (float(values["cla"]) * (1.0 - float(values["balance"])))
		"ride_height":
			return "piso a %d mm" % roundi(float(values["floor_clearance"]) * 1000.0)
		"front_springs":
			return "%d kN/m" % roundi(stiffness.x / 1000.0)
		"rear_springs":
			return "%d kN/m" % roundi(stiffness.y / 1000.0)
		"front_anti_roll":
			return "%d kN/m" % roundi(bars.x / 1000.0)
		"rear_anti_roll":
			return "%d kN/m" % roundi(bars.y / 1000.0)
		"front_pressure":
			return "agarre %+.1f %%" % ((reference.x - pressure.x) * _setup.pressure_grip_per_psi * 100.0)
		"rear_pressure":
			return "agarre %+.1f %%" % ((reference.y - pressure.y) * _setup.pressure_grip_per_psi * 100.0)
		"final_drive":
			return "8ª: %d km/h" % roundi(float(values["top_speed_kmh"]))
	return ""


func _add_row(entry: Dictionary) -> void:
	var id := str(entry.get("id", ""))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	add_child(row)
	var label := UiKit.make_label(str(entry.get("name", id)), 19)
	label.custom_minimum_size = Vector2(LABEL_WIDTH, 0)
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(label)
	var button := _make_button("", CONTROL_SIZE)
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.pressed.connect(func() -> void: _step(id, 1))
	button.gui_input.connect(func(event: InputEvent) -> void:
		if event.is_action_pressed("ui_right"):
			_step(id, 1)
			button.accept_event()
		elif event.is_action_pressed("ui_left"):
			_step(id, -1)
			button.accept_event())
	button.focus_entered.connect(func() -> void: _description.text = str(entry.get("description", "")))
	row.add_child(button)
	var note := UiKit.make_label("", 16)
	note.add_theme_color_override("font_color", DIM)
	note.custom_minimum_size = Vector2(NOTE_WIDTH, 0)
	note.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(note)
	_value_buttons[id] = button
	_notes[id] = note
	if _first == null:
		_first = button


func _make_button(text: String, min_size: Vector2) -> Button:
	var button := UiKit.make_button(text, accent, min_size, 19)
	_buttons.append(button)
	return button


func _step(id: String, direction: int) -> void:
	var before := _setup.get_value(id)
	_setup.step(id, direction)
	if not is_equal_approx(before, _setup.get_value(id)):
		_on_changed()


func _on_changed() -> void:
	_setup.save()
	refresh()
	changed.emit()
