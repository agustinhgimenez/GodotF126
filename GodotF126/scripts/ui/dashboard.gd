class_name Dashboard
extends Control
## Tablero del HUD (Paso 5): luces de cambio tipo F1, marcha grande, RPM y
## velocímetro digital con aguja analógica. Todo se dibuja en _draw().
## Luces: se encienden de izquierda a derecha entre shift_light_start_rpm y el
## punto de cambio de la caja (la lógica de colores está en HudDraw).
## Abajo (Paso 29): modo de la aero activa y energía del modo adelantamiento.

const SIZE := Vector2(440, 284)
const COLOR_STRAIGHT := Color(0.2, 0.9, 0.4)
const COLOR_OVERTAKE := Color(0.3, 0.6, 1.0)
const COLOR_PANEL := Color(0.0, 0.0, 0.0, 0.55)
const COLOR_NEEDLE := Color(1.0, 0.3, 0.1)
const COLOR_DIM := Color(1.0, 1.0, 1.0, 0.7)
const DIAL_START_DEG := 135.0
const DIAL_SWEEP_DEG := 270.0
const DENIED_FLASH_MS := 400

@export var shift_light_count: int = 15
@export var shift_light_start_rpm: float = 9000.0
@export var speed_tick_step: float = 20.0      ## km/h entre marcas del dial
@export var needle_smoothing: float = 12.0

var _car: CarController = null
var _max_kmh: float = 200.0
var _shown_kmh: float = 0.0
var _denied_until_ms: int = 0
var _font: Font
var _panel: StyleBoxFlat


func _ready() -> void:
	custom_minimum_size = SIZE
	size = SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_font = ThemeDB.fallback_font
	_panel = StyleBoxFlat.new()
	_panel.bg_color = COLOR_PANEL
	_panel.set_corner_radius_all(14)


func configure(data: Dictionary) -> void:
	shift_light_count = maxi(int(data.get("shift_light_count", shift_light_count)), 1)
	shift_light_start_rpm = float(data.get("shift_light_start_rpm", shift_light_start_rpm))
	speed_tick_step = maxf(float(data.get("speed_tick_step", speed_tick_step)), 1.0)
	if _car != null:
		_update_dial_range()


func bind_car(car: CarController) -> void:
	_car = car
	_update_dial_range()
	car.gearbox.shift_denied.connect(_on_shift_denied)


func _update_dial_range() -> void:
	_max_kmh = maxf(ceilf(_car.max_speed * 3.6 / speed_tick_step) * speed_tick_step, speed_tick_step)


func _on_shift_denied(_reason: String) -> void:
	_denied_until_ms = Time.get_ticks_msec() + DENIED_FLASH_MS


func _process(delta: float) -> void:
	if _car == null:
		return
	_shown_kmh = lerpf(_shown_kmh, _car.get_speed_kmh(), clampf(needle_smoothing * delta, 0.0, 1.0))
	queue_redraw()


func _draw() -> void:
	draw_style_box(_panel, Rect2(Vector2.ZERO, SIZE))
	if _car == null:
		return
	_draw_shift_lights(Rect2(20, 14, SIZE.x - 40, 26))
	_draw_speedometer(Vector2(125, 150), 88.0)
	_draw_gear_panel(Rect2(250, 52, 170, 186))
	_draw_aero_row(Rect2(20, 248, SIZE.x - 40, 24))


## Modo recta / curva (verde abierto; contorno en zona de recta) y barra de energía para
## adelantar (azul cuando está activo).
func _draw_aero_row(rect: Rect2) -> void:
	var aero := _car.active_aero
	var half := (rect.size.x - 12.0) * 0.5
	var mode_rect := Rect2(rect.position, Vector2(half, rect.size.y))
	var label := aero.mode_label()
	var open := label == "RECTA"
	draw_rect(mode_rect, COLOR_STRAIGHT if open else HudDraw.COLOR_OFF)
	if aero.in_zone and not open:
		draw_rect(mode_rect, COLOR_STRAIGHT, false, 2.0)
	_draw_text_centered("MODO " + label, mode_rect.get_center() + Vector2(0, 1), 15,
		Color.BLACK if open else Color.WHITE)

	var energy_rect := Rect2(rect.position + Vector2(half + 12.0, 0), Vector2(half, rect.size.y))
	draw_rect(energy_rect, HudDraw.COLOR_OFF)
	var fill_color := COLOR_OVERTAKE if aero.overtake_active else Color(COLOR_OVERTAKE, 0.45)
	draw_rect(Rect2(energy_rect.position, Vector2(energy_rect.size.x * aero.energy_ratio(), energy_rect.size.y)), fill_color)
	_draw_text_centered("ADELANTAR %d %%" % roundi(aero.energy_ratio() * 100.0), energy_rect.get_center() + Vector2(0, 1), 15)


func _draw_shift_lights(rect: Rect2) -> void:
	var spacing := rect.size.x / shift_light_count
	var radius := minf(spacing * 0.38, rect.size.y * 0.5)
	for i in shift_light_count:
		var color := HudDraw.shift_light_color(i, shift_light_count, _car, shift_light_start_rpm)
		var center := rect.position + Vector2(spacing * (i + 0.5), rect.size.y * 0.5)
		draw_circle(center, radius, color)


func _draw_speedometer(center: Vector2, radius: float) -> void:
	var start := deg_to_rad(DIAL_START_DEG)
	var sweep := deg_to_rad(DIAL_SWEEP_DEG)
	draw_arc(center, radius, start, start + sweep, 64, COLOR_DIM, 3.0, true)

	var steps := maxi(roundi(_max_kmh / speed_tick_step), 1)
	for i in steps + 1:
		var dir := Vector2.from_angle(start + sweep * float(i) / steps)
		var major := i % 2 == 0
		var inner := radius - (14.0 if major else 8.0)
		draw_line(center + dir * inner, center + dir * radius, Color.WHITE, 3.0 if major else 1.5, true)
		if major:
			_draw_text_centered(str(roundi(speed_tick_step * i)), center + dir * (radius - 30.0), 14)

	var needle_t := clampf(_shown_kmh / _max_kmh, 0.0, 1.0)
	var needle_dir := Vector2.from_angle(start + sweep * needle_t)
	draw_line(center - needle_dir * 10.0, center + needle_dir * (radius - 6.0), COLOR_NEEDLE, 4.0, true)
	draw_circle(center, 7.0, COLOR_NEEDLE)

	_draw_text_centered("%d" % roundi(_car.get_speed_kmh()), center + Vector2(0, 36), 34)
	_draw_text_centered("km/h", center + Vector2(0, 60), 14, COLOR_DIM)


func _draw_gear_panel(rect: Rect2) -> void:
	var cx := rect.position.x + rect.size.x * 0.5
	var denied := Time.get_ticks_msec() < _denied_until_ms
	var gear_color := HudDraw.COLOR_RED if denied else Color.WHITE
	_draw_text_centered(_car.get_gear_label(), Vector2(cx, rect.position.y + 55), 96, gear_color)
	_draw_text_centered("MAN" if _car.gearbox.manual else "AUT", Vector2(cx, rect.position.y + 118), 18, COLOR_DIM)

	var rpm := _car.get_rpm()
	_draw_text_centered("%d rpm" % roundi(rpm), Vector2(cx, rect.position.y + 145), 20)

	var bar := Rect2(rect.position.x + 10, rect.position.y + 165, rect.size.x - 20, 12)
	draw_rect(bar, HudDraw.COLOR_OFF)
	var fill_color := HudDraw.rpm_bar_color(_car, shift_light_start_rpm)
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * _car.engine.get_rpm_ratio(), bar.size.y)), fill_color)


func _draw_text_centered(text: String, center: Vector2, font_size: int, color: Color = Color.WHITE) -> void:
	HudDraw.draw_text_centered(self, _font, text, center, font_size, color)
