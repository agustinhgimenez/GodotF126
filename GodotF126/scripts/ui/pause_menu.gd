class_name PauseMenu
extends CanvasLayer
## Menú de pausa de la carrera (Paso 15), armado por código.
## Esc pausa el árbol (física, cronómetro y audio del auto quedan congelados) y muestra
## Continuar / Reiniciar / Opciones / Menú / Salir. Este nodo sigue procesando en pausa.

signal paused_changed(paused: bool)
signal restart_requested
signal menu_requested

var accent: Color = Color("#FF87BC")

var _root: Control
var _main_panel: VBoxContainer
var _subtitle: Label
var _options: OptionsPanel
var _continue_button: Button
var _options_button: Button
var _buttons: Array[Button] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 10
	_build_ui()
	_root.visible = false


func is_open() -> bool:
	return _root.visible


func set_accent(color: Color) -> void:
	accent = color
	for button in _buttons:
		UiKit.apply_button_style(button, color)
	_options.set_accent(color)


## Texto bajo el título (piloto, pista, vuelta).
func set_subtitle(text: String) -> void:
	_subtitle.text = text


func open() -> void:
	if is_open():
		return
	get_tree().paused = true
	_root.visible = true
	_show_main(_continue_button)
	paused_changed.emit(true)


func close() -> void:
	if not is_open():
		return
	_root.visible = false
	get_tree().paused = false
	paused_changed.emit(false)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	get_viewport().set_input_as_handled()
	if not is_open():
		open()
	elif _options.visible:
		_show_main(_options_button)
	else:
		close()


func _show_main(focus: Button) -> void:
	_options.visible = false
	_main_panel.visible = true
	focus.grab_focus()


func _on_options_pressed() -> void:
	_main_panel.visible = false
	_options.visible = true
	_options.open()


func _leave(request: Signal) -> void:
	_root.visible = false
	get_tree().paused = false
	request.emit()


func _build_ui() -> void:
	_root = Control.new()
	_root.name = "Root"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)

	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.02, 0.04, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)

	var header := VBoxContainer.new()
	header.add_theme_constant_override("separation", 4)
	UiKit.place(header, Vector4(0, 0, 0, 0), Vector4(80, 60, 900, 170))
	_root.add_child(header)
	header.add_child(UiKit.make_label("Pausa", 56))
	_subtitle = UiKit.make_label("", 22)
	_subtitle.add_theme_color_override("font_color", Color(0.85, 0.86, 0.9))
	header.add_child(_subtitle)

	_main_panel = VBoxContainer.new()
	_main_panel.add_theme_constant_override("separation", 12)
	UiKit.place(_main_panel, Vector4(0, 0, 0, 0), Vector4(80, 200, 500, 560))
	_root.add_child(_main_panel)
	_continue_button = _add_button("Continuar", close)
	_add_button("Reiniciar", func() -> void: _leave(restart_requested))
	_options_button = _add_button("Opciones", _on_options_pressed)
	_add_button("Menú principal", func() -> void: _leave(menu_requested))
	_add_button("Salir del juego", func() -> void: get_tree().quit())
	var hint := UiKit.make_label("Esc para continuar", 16)
	hint.add_theme_color_override("font_color", Color(0.7, 0.72, 0.78))
	_main_panel.add_child(hint)

	_options = OptionsPanel.new()
	_options.visible = false
	UiKit.place(_options, Vector4(0, 0, 0, 0), Vector4(80, 190, 640, 700))
	_options.closed.connect(func() -> void: _show_main(_options_button))
	_root.add_child(_options)


func _add_button(text: String, action: Callable) -> Button:
	var button := UiKit.make_button(text, accent)
	button.pressed.connect(action)
	_main_panel.add_child(button)
	_buttons.append(button)
	return button
