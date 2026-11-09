extends CanvasLayer
## Controles táctiles para jugar desde el celular (autoload "TouchControls").
## Manejando: joystick analógico a la izquierda (aparece donde se apoya el pulgar) para doblar,
## X acelera y □ frena como en un mando de PlayStation (se puede deslizar de uno al otro sin
## levantar el dedo), ▲ / ▼ pasan los cambios (si la caja está en automática la pasan a manual)
## y AUTO / MAN cambia la caja. Arriba a la derecha: pausa, cámara y volver a la pista.
## En los menús hay un botón "Volver" (el celular no tiene Esc).
## En la web, al entrar se elige "Celular" o "PC": sólo con Celular aparecen los controles
## táctiles y se ponen las ayudas al máximo (Settings.apply_mobile_defaults()). El .exe no
## pregunta ni los muestra. Para probar en la PC: `-- --touch` (Celular directo) o `-- --choose`
## (muestra la elección). Todo pasa por las acciones del InputMap: el auto y los menús no saben
## que es táctil.

const STICK_RADIUS := 110.0
const KNOB_RADIUS := 48.0
const STICK_DEADZONE := 0.08
## Parte izquierda de la pantalla donde un toque arranca el joystick.
const STICK_AREA := 0.45
## Margen extra de cada botón para que no haga falta apuntar justo.
const HIT_MARGIN := 1.2
const PEDALS := ["accelerate", "brake"]
const COLORS := {
	"accelerate": Color("#7CB2E8"),
	"brake": Color("#E87CC0"),
}
const CAPTIONS := {"accelerate": "ACELERAR", "brake": "FRENAR"}

var enabled: bool = false
var _driving: bool = false
var _stick_finger: int = -1
var _stick_center: Vector2
var _stick_offset: Vector2
## Dedo (índice del toque) → botón que está apretando.
var _fingers: Dictionary = {}
var _pad: Control
var _back: Button
var _rotate: Control
## Pantalla "¿Desde dónde jugás?" de la web (null cuando ya se eligió).
var _chooser: Control
var _chooser_default: Button


func _ready() -> void:
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	var args := OS.get_cmdline_user_args()
	if OS.has_feature("mobile") or args.has("--touch"):
		choose(true)
	elif OS.has_feature("web") or args.has("--choose"):
		_build_chooser()


func is_choosing() -> bool:
	return _chooser != null


## Elección de la pantalla de entrada: true = Celular (controles táctiles), false = PC.
func choose(mobile: bool) -> void:
	if _chooser != null:
		_chooser.queue_free()
		_chooser = null
	if not mobile:
		return
	enabled = true
	# En los celulares (más anchos que 16:9) la imagen ocupa toda la pantalla, sin bandas.
	get_tree().root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	Settings.apply_mobile_defaults()


func is_driving() -> bool:
	return _driving


func _process(_delta: float) -> void:
	if _chooser != null:
		# El menú de atrás toma el foco al arrancar: la elección lo recupera para Enter / flechas.
		var focused := _chooser.get_viewport().gui_get_focus_owner()
		if focused == null or not _chooser.is_ancestor_of(focused):
			_chooser_default.grab_focus()
	var scene := get_tree().current_scene
	var driving: bool = enabled and scene != null and scene.has_method("is_driving") and scene.is_driving()
	if driving != _driving:
		_driving = driving
		_pad.visible = driving
		if not driving:
			_release_all()
	_back.visible = enabled and not driving and scene != null \
		and (not scene.has_method("can_go_back") or scene.can_go_back())
	var window := DisplayServer.window_get_size()
	_rotate.visible = enabled and window.y > window.x
	if driving:
		_pad.queue_redraw()


func _input(event: InputEvent) -> void:
	if not (event is InputEventScreenTouch or event is InputEventScreenDrag):
		return
	if _driving:
		_handle_drive(event)


func _handle_drive(event: InputEvent) -> void:
	var index: int = event.index
	if event is InputEventScreenTouch:
		if event.pressed:
			var id := _button_at(event.position)
			if not id.is_empty():
				_fingers[index] = id
				_press(id)
			elif event.position.x < _pad.size.x * STICK_AREA and _stick_finger < 0:
				_stick_finger = index
				_stick_center = _clamp_stick(event.position)
				_move_stick(event.position)
			else:
				return
			get_viewport().set_input_as_handled()
		elif index == _stick_finger:
			_stick_finger = -1
			_stick_offset = Vector2.ZERO
			_set_steer(0.0)
		elif _fingers.has(index):
			_release(_fingers[index])
			_fingers.erase(index)
	elif index == _stick_finger:
		_move_stick(event.position)
		get_viewport().set_input_as_handled()
	elif _fingers.get(index, "") in PEDALS:
		var id := _button_at(event.position)
		if id in PEDALS and id != _fingers[index]:
			_release(_fingers[index])
			_fingers[index] = id
			_press(id)


func _move_stick(position: Vector2) -> void:
	_stick_offset = (position - _stick_center).limit_length(STICK_RADIUS)
	_set_steer(-_stick_offset.x / STICK_RADIUS)


## Positivo dobla a la izquierda (el auto lee Input.get_axis("steer_right", "steer_left")).
func _set_steer(value: float) -> void:
	var amount := 0.0
	if absf(value) > STICK_DEADZONE:
		amount = signf(value) * (absf(value) - STICK_DEADZONE) / (1.0 - STICK_DEADZONE)
	_hold("steer_left", maxf(amount, 0.0))
	_hold("steer_right", maxf(-amount, 0.0))


func _hold(action: String, strength: float) -> void:
	if strength > 0.0:
		Input.action_press(action, strength)
	elif Input.is_action_pressed(action):
		Input.action_release(action)


func _press(id: String) -> void:
	match id:
		"accelerate", "brake":
			Input.action_press(id)
		"gear_up", "gear_down":
			if not _manual_gearbox():
				_send("toggle_gearbox")
			_send(id)
		"gearbox":
			_send("toggle_gearbox")
		"camera":
			_send("change_camera")
		"pause":
			_send(InputBindings.PAUSE_ACTION)
		"reset":
			# reset_car se lee con is_action_just_pressed en el cuadro de física: queda apretada un
			# momento para que lo alcance a ver.
			Input.action_press("reset_car")
			get_tree().create_timer(0.15, true).timeout.connect(Input.action_release.bind("reset_car"))


func _release(id: String) -> void:
	if id in PEDALS:
		Input.action_release(id)


func _release_all() -> void:
	for index in _fingers:
		_release(_fingers[index])
	_fingers.clear()
	_stick_finger = -1
	_stick_offset = Vector2.ZERO
	_set_steer(0.0)


## Una pulsación completa de la acción, como si fuera una tecla.
func _send(action: String) -> void:
	for pressed in [true, false]:
		var event := InputEventAction.new()
		event.action = action
		event.pressed = pressed
		Input.parse_input_event(event)


func _manual_gearbox() -> bool:
	var scene := get_tree().current_scene
	var car = scene.get("car") if scene != null else null
	return car != null and car.gearbox.manual


## Posición y radio de cada botón, medidos desde las esquinas (el ancho cambia según el celular).
func _buttons() -> Dictionary:
	var size := _pad.size
	return {
		"accelerate": [Vector2(size.x - 135, size.y - 125), 74.0],
		"brake": [Vector2(size.x - 300, size.y - 95), 62.0],
		"gear_up": [Vector2(size.x - 80, size.y - 300), 44.0],
		"gear_down": [Vector2(size.x - 190, size.y - 275), 44.0],
		"gearbox": [Vector2(size.x - 300, size.y - 235), 34.0],
		"pause": [Vector2(size.x - 52, 52), 34.0],
		"camera": [Vector2(size.x - 52, 130), 30.0],
		"reset": [Vector2(size.x - 52, 202), 30.0],
	}


func _button_at(position: Vector2) -> String:
	var buttons := _buttons()
	var best := ""
	var best_distance := INF
	for id in buttons:
		var distance := position.distance_to(buttons[id][0])
		if distance <= buttons[id][1] * HIT_MARGIN and distance < best_distance:
			best = id
			best_distance = distance
	return best


func _stick_rest() -> Vector2:
	return Vector2(160, _pad.size.y - 160)


func _clamp_stick(position: Vector2) -> Vector2:
	var edge := STICK_RADIUS + 12.0
	return Vector2(maxf(position.x, edge), clampf(position.y, edge, _pad.size.y - edge))


func _build_ui() -> void:
	_pad = Control.new()
	_pad.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pad.visible = false
	_pad.draw.connect(_draw_pad)
	add_child(_pad)

	_back = UiKit.make_button("← Volver", Color("#FF87BC"), Vector2(150, 56), 24)
	_back.focus_mode = Control.FOCUS_NONE
	UiKit.place(_back, Vector4(1, 0, 1, 0), Vector4(-176, 52, -16, 108))
	_back.pressed.connect(_send.bind("ui_cancel"))
	_back.visible = false
	add_child(_back)

	_rotate = ColorRect.new()
	(_rotate as ColorRect).color = Color(0.03, 0.03, 0.05, 0.96)
	_rotate.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rotate.mouse_filter = Control.MOUSE_FILTER_STOP
	_rotate.visible = false
	var label := UiKit.make_label("Girá el celular para jugar acostado", 40, HORIZONTAL_ALIGNMENT_CENTER)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rotate.add_child(label)
	add_child(_rotate)


func _build_chooser() -> void:
	var accent := Color("#FF87BC")
	_chooser = ColorRect.new()
	(_chooser as ColorRect).color = Color(0.05, 0.05, 0.08, 0.97)
	_chooser.set_anchors_preset(Control.PRESET_FULL_RECT)
	_chooser.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_chooser)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_chooser.add_child(center)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 28)
	center.add_child(column)
	column.add_child(UiKit.make_label("GodotF126", 22, HORIZONTAL_ALIGNMENT_CENTER))
	column.add_child(UiKit.make_label("¿Desde dónde jugás?", 46, HORIZONTAL_ALIGNMENT_CENTER))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 40)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_child(row)
	var options := [
		[true, "Celular", "Controles en pantalla: joystick para doblar, X acelera, cuadrado frena y botones para los cambios. Ayudas al máximo."],
		[false, "PC", "Teclado o mando, como siempre."],
	]
	var phone := OS.has_feature("web_android") or OS.has_feature("web_ios")
	for option in options:
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 12)
		row.add_child(box)
		var button := UiKit.make_button(option[1], accent, Vector2(340, 110), 36)
		button.pressed.connect(choose.bind(option[0]))
		box.add_child(button)
		var description := UiKit.make_label(option[2], 18, HORIZONTAL_ALIGNMENT_CENTER)
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		description.custom_minimum_size = Vector2(340, 0)
		description.add_theme_color_override("font_color", Color(0.75, 0.77, 0.83))
		box.add_child(description)
		if option[0] == phone:
			_chooser_default = button


func _draw_pad() -> void:
	var white := Color(1, 1, 1, 0.6)
	var center := _stick_center if _stick_finger >= 0 else _stick_rest()
	_pad.draw_circle(center, STICK_RADIUS, Color(0, 0, 0, 0.25))
	_pad.draw_arc(center, STICK_RADIUS, 0.0, TAU, 48, white, 3.0, true)
	_pad.draw_circle(center + _stick_offset, KNOB_RADIUS, Color(1, 1, 1, 0.55 if _stick_finger >= 0 else 0.3))
	var held := _fingers.values()
	var buttons := _buttons()
	for id in buttons:
		var at: Vector2 = buttons[id][0]
		var radius: float = buttons[id][1]
		var color: Color = COLORS.get(id, white)
		_pad.draw_circle(at, radius, Color(0, 0, 0, 0.5 if id in held else 0.25))
		_pad.draw_arc(at, radius, 0.0, TAU, 40, Color(color, 0.95 if id in held else 0.6), 3.0, true)
		_draw_symbol(id, at, radius * 0.42, Color(color, 0.95))
		if CAPTIONS.has(id):
			_draw_text(CAPTIONS[id], at + Vector2(0, radius + 18), 14, Color(1, 1, 1, 0.55))


func _draw_symbol(id: String, at: Vector2, size: float, color: Color) -> void:
	match id:
		"accelerate":
			_pad.draw_line(at - Vector2(size, size), at + Vector2(size, size), color, 6.0, true)
			_pad.draw_line(at + Vector2(-size, size), at + Vector2(size, -size), color, 6.0, true)
		"brake":
			_pad.draw_rect(Rect2(at - Vector2(size, size), Vector2(size, size) * 2.0), color, false, 5.0)
		"gear_up":
			_pad.draw_colored_polygon(PackedVector2Array([at + Vector2(0, -size), at + Vector2(size, size * 0.7),
				at + Vector2(-size, size * 0.7)]), color)
		"gear_down":
			_pad.draw_colored_polygon(PackedVector2Array([at + Vector2(0, size), at + Vector2(size, -size * 0.7),
				at + Vector2(-size, -size * 0.7)]), color)
		"gearbox":
			_draw_text("MAN" if _manual_gearbox() else "AUTO", at + Vector2(0, 5), 15, color)
		"pause":
			for side in [-1.0, 1.0]:
				_pad.draw_rect(Rect2(at + Vector2(side * size * 0.45 - 3.0, -size * 0.8), Vector2(6, size * 1.6)), color)
		"camera":
			_draw_text("CAM", at + Vector2(0, 5), 14, color)
		"reset":
			_pad.draw_arc(at, size * 0.8, -PI * 0.3, PI * 1.4, 20, color, 3.0, true)
			var tip := at + Vector2.from_angle(-PI * 0.3) * size * 0.8
			_pad.draw_colored_polygon(PackedVector2Array([tip + Vector2(-6, -6), tip + Vector2(6, -2),
				tip + Vector2(-2, 6)]), color)


func _draw_text(text: String, at: Vector2, font_size: int, color: Color) -> void:
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	_pad.draw_string(font, at - Vector2(width / 2.0, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
