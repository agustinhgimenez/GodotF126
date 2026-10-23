class_name OptionsPanel
extends VBoxContainer
## Panel de opciones del menú (Paso 14), armado por código.
## Selectores (← → o Enter cambian el valor) y deslizadores de volumen. Cada cambio se
## aplica y se guarda al instante a través del autoload Settings.

signal closed

const LABEL_WIDTH := 250.0
const CONTROL_SIZE := Vector2(250, 36)

## [clave, texto, [valores], [textos de cada valor]]
const CHOICES := [
	["gearbox", "Caja de cambios", ["manual", "automatic"], ["Manual (E/Q)", "Automática"]],
	["steering_assist", "Dirección asistida", [true, false], ["Sí", "No"]],
	["camera", "Cámara inicial", [0, 1, 2, 3, 4, 5], ["TV", "Cercana", "Cockpit", "T-cam", "Capot", "De pista"]],
	["quality", "Calidad gráfica", ["low", "medium", "high"], ["Baja", "Media", "Alta"]],
	["time_of_day", "Hora de la carrera", ["sunset", "day"], ["Atardecer", "Día"]],
	["fullscreen", "Pantalla completa", [false, true], ["No", "Sí"]],
]
const VOLUMES := [
	["master_volume", "Volumen general"],
	["engine_volume", "Volumen del motor"],
	["fx_volume", "Volumen de efectos"],
	["music_volume", "Volumen de la música"],
]

var accent: Color = Color("#FF87BC")

var _first: Control
var _choice_buttons: Dictionary = {}   ## clave → Button
var _sliders: Dictionary = {}          ## clave → HSlider
var _slider_labels: Dictionary = {}    ## clave → Label con el porcentaje
var _buttons: Array[Button] = []


func _ready() -> void:
	add_theme_constant_override("separation", 4)
	add_child(UiKit.make_label("Opciones", 26))
	for choice in CHOICES.slice(0, 3):
		_add_choice(choice)
	for volume in VOLUMES:
		_add_volume(volume[0], volume[1])
	for choice in CHOICES.slice(3):
		_add_choice(choice)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	add_child(actions)
	var reset := _make_button("Restablecer", Vector2(200, 42))
	reset.pressed.connect(_on_reset_pressed)
	actions.add_child(reset)
	var back := _make_button("Volver", Vector2(200, 42))
	back.pressed.connect(func() -> void: closed.emit())
	actions.add_child(back)

	var hint := UiKit.make_label("← → para cambiar · Esc para volver · se guarda solo", 16)
	hint.add_theme_color_override("font_color", Color(0.7, 0.72, 0.78))
	add_child(hint)
	refresh()


func open() -> void:
	refresh()
	_first.grab_focus()


func set_accent(color: Color) -> void:
	accent = color
	for button in _buttons:
		UiKit.apply_button_style(button, color)


## Vuelve a leer todos los valores de Settings.
func refresh() -> void:
	for choice in CHOICES:
		var key: String = choice[0]
		var index := _index_of(choice, Settings.get_value(key))
		_choice_buttons[key].text = "‹   %s   ›" % choice[3][index]
	for volume in VOLUMES:
		var key: String = volume[0]
		var value := int(Settings.get_value(key))
		_sliders[key].set_value_no_signal(value)
		_slider_labels[key].text = "%d %%" % value


func _add_choice(choice: Array) -> void:
	var row := _make_row(choice[1])
	var button := _make_button("", CONTROL_SIZE)
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
	if _first == null:
		_first = button


func _add_volume(key: String, text: String) -> void:
	var row := _make_row(text)
	var slider := HSlider.new()
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 5
	slider.custom_minimum_size = Vector2(CONTROL_SIZE.x - 86, CONTROL_SIZE.y)
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.focus_mode = Control.FOCUS_ALL
	slider.mouse_entered.connect(slider.grab_focus)
	slider.value_changed.connect(func(value: float) -> void:
		Settings.set_value(key, int(value))
		_slider_labels[key].text = "%d %%" % int(value))
	row.add_child(slider)
	var label := UiKit.make_label("", 18)
	label.custom_minimum_size = Vector2(64, 0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(label)
	_sliders[key] = slider
	_slider_labels[key] = label


func _make_row(text: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	add_child(row)
	var label := UiKit.make_label(text, 20)
	label.custom_minimum_size = Vector2(LABEL_WIDTH, 0)
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(label)
	return row


func _make_button(text: String, min_size: Vector2) -> Button:
	var button := UiKit.make_button(text, accent, min_size, 20)
	_buttons.append(button)
	return button


func _cycle(choice: Array, direction: int) -> void:
	var options: Array = choice[2]
	var index := _index_of(choice, Settings.get_value(choice[0]))
	Settings.set_value(choice[0], options[posmod(index + direction, options.size())])
	refresh()


func _on_reset_pressed() -> void:
	Settings.reset_to_defaults()
	refresh()


func _index_of(choice: Array, value) -> int:
	var options: Array = choice[2]
	for i in options.size():
		if str(options[i]) == str(value):
			return i
	return 0
