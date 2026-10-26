class_name WheelScreen
extends Control
## Pantalla del volante (Paso 6). Se dibuja dentro de un SubViewport y se muestra
## como textura en el volante 3D: marcha, velocidad, RPM, modo, vuelta y delta.

const SIZE := Vector2i(256, 128)
const COLOR_BG := Color(0.02, 0.02, 0.03)
const COLOR_DIM := Color(1.0, 1.0, 1.0, 0.6)
const COLOR_FASTER := Color(0.2, 1.0, 0.35)
const COLOR_SLOWER := Color(1.0, 0.25, 0.2)
const COLOR_OVERTAKE := Color(0.3, 0.6, 1.0)

var shift_light_start_rpm: float = 9000.0

var _car: CarController = null
var _timer: LapTimer = null
var _font: Font


func _ready() -> void:
	size = Vector2(SIZE)
	_font = ThemeDB.fallback_font


func bind(car: CarController) -> void:
	_car = car


func bind_lap_timer(timer: LapTimer) -> void:
	_timer = timer


func _process(_delta: float) -> void:
	if is_visible_in_tree():
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(SIZE)), COLOR_BG)
	if _car == null:
		return

	var bar := Rect2(8, 6, SIZE.x - 16, 10)
	draw_rect(bar, HudDraw.COLOR_OFF)
	var fill := Vector2(bar.size.x * _car.engine.get_rpm_ratio(), bar.size.y)
	draw_rect(Rect2(bar.position, fill), HudDraw.rpm_bar_color(_car, shift_light_start_rpm))

	_text(_car.get_gear_label(), Vector2(128, 66), 70)
	_text("%d" % roundi(_car.get_speed_kmh()), Vector2(44, 56), 30)
	_text("km/h", Vector2(44, 82), 12, COLOR_DIM)
	_text("%d" % roundi(_car.get_rpm()), Vector2(44, 108), 14, COLOR_DIM)

	var delta_text := "--.---"
	var delta_color := Color.WHITE
	if _timer != null and not is_nan(_timer.split_delta):
		delta_text = "%+.3f" % _timer.split_delta
		delta_color = COLOR_FASTER if _timer.split_delta < 0.0 else COLOR_SLOWER
	_text("DELTA", Vector2(212, 34), 12, COLOR_DIM)
	_text(delta_text, Vector2(212, 56), 20, delta_color)
	_text("MAN" if _car.gearbox.manual else "AUT", Vector2(212, 82), 12, COLOR_DIM)
	var aero_label := _car.active_aero.mode_label()
	if _car.active_aero.overtake_active:
		_text("ADEL", Vector2(212, 98), 12, COLOR_OVERTAKE)
	else:
		_text("CURVA" if aero_label == "CURVA" else "RECTA", Vector2(212, 98), 12,
			COLOR_FASTER if aero_label == "RECTA" else COLOR_DIM)
	if _timer != null:
		_text(LapTimer.format_time(_timer.current_time if _timer.running else -1.0), Vector2(160, 114), 14)


func _text(text: String, center: Vector2, font_size: int, color: Color = Color.WHITE) -> void:
	HudDraw.draw_text_centered(self, _font, text, center, font_size, color, 0)
