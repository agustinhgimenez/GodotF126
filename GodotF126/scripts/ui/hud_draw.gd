class_name HudDraw
extends RefCounted
## Utilidades de dibujo compartidas por el tablero del HUD y la pantalla del volante.

const COLOR_OFF := Color(0.18, 0.18, 0.2)
const COLOR_GREEN := Color(0.15, 0.9, 0.3)
const COLOR_RED := Color(1.0, 0.15, 0.15)
const COLOR_BLUE := Color(0.25, 0.45, 1.0)
const BLINK_HZ := 8.0


## Color de la luz de cambio `index` (de `count`). Un tercio verde, uno rojo, uno azul;
## en el punto de cambio todas azules, y parpadeando en el limitador.
static func shift_light_color(index: int, count: int, car: CarController, start_rpm: float) -> Color:
	var rpm := car.get_rpm()
	var shift_rpm := car.gearbox.shift_up_rpm
	if rpm >= shift_rpm:
		var at_limiter := car.engine.is_cutting() or rpm >= car.engine.limiter_rpm - 50.0
		if at_limiter and fmod(Time.get_ticks_msec() / 1000.0 * BLINK_HZ, 1.0) < 0.5:
			return COLOR_OFF
		return COLOR_BLUE
	var progress := clampf(inverse_lerp(start_rpm, shift_rpm, rpm), 0.0, 1.0)
	if index >= ceili(progress * count):
		return COLOR_OFF
	var t := float(index) / count
	if t < 1.0 / 3.0:
		return COLOR_GREEN
	if t < 2.0 / 3.0:
		return COLOR_RED
	return COLOR_BLUE


## Color de una barra de RPM con el mismo código que las luces.
static func rpm_bar_color(car: CarController, start_rpm: float) -> Color:
	var rpm := car.get_rpm()
	if rpm >= car.gearbox.shift_up_rpm:
		return COLOR_BLUE
	if rpm >= start_rpm:
		return COLOR_RED
	return COLOR_GREEN


static func draw_text_centered(canvas: CanvasItem, font: Font, text: String, center: Vector2,
		font_size: int, color: Color = Color.WHITE, outline: int = 4) -> void:
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var baseline_offset := (font.get_ascent(font_size) - font.get_descent(font_size)) * 0.5
	var pos := Vector2(center.x - text_size.x * 0.5, center.y + baseline_offset)
	if outline > 0:
		canvas.draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, outline, Color.BLACK)
	canvas.draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
