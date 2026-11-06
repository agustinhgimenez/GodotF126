class_name DeltaDisplay
extends Control
## Caja del delta en vivo en el HUD (Paso 40), debajo del cronómetro: el delta contra la
## mejor vuelta (verde si vas más rápido, rojo si más lento; gris con la vuelta invalidada)
## y una barra que crece desde el centro (izquierda = ganando) hasta ± `LiveDelta.bar_range`.
## Una flecha chica dice si en este momento ganás o perdés tiempo. Oculta sin referencia.

const SIZE := Vector2(240, 46)
const COLOR_FASTER := Color(0.2, 0.95, 0.35)
const COLOR_SLOWER := Color(1.0, 0.27, 0.22)
const COLOR_INVALID := Color(0.6, 0.6, 0.64)
const BAR_HEIGHT := 6.0
## Por debajo de esto (s/s) no se dibuja la flecha de tendencia.
const TREND_MIN := 0.02

var _delta: LiveDelta
var _timer: LapTimer
var _font: Font


func _ready() -> void:
	custom_minimum_size = SIZE
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_font = ThemeDB.fallback_font


func bind(live_delta: LiveDelta, timer: LapTimer) -> void:
	_delta = live_delta
	_timer = timer


func _process(_d: float) -> void:
	queue_redraw()


static func format_delta(value: float) -> String:
	if is_nan(value):
		return "--.---"
	return "%s%.3f" % ["-" if value < 0.0 else "+", absf(value)]


static func delta_color(value: float, invalid: bool) -> Color:
	if invalid:
		return COLOR_INVALID
	return COLOR_FASTER if value < 0.0 else COLOR_SLOWER


func _draw() -> void:
	if _delta == null:
		return
	var value := _delta.shown_delta()
	if is_nan(value):
		return
	var final := _delta.is_showing_final()
	var invalid := _timer != null and _timer.current_invalid and not final
	var color := delta_color(value, invalid)
	draw_rect(Rect2(Vector2.ZERO, SIZE), Color(0, 0, 0, 0.45))
	var text := format_delta(value)
	var font_size := 26
	var width := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var baseline := Vector2((SIZE.x - width) * 0.5, 28)
	draw_string_outline(_font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 5, Color.BLACK)
	draw_string(_font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
	var label := "FINAL" if final else "DELTA"
	draw_string(_font, Vector2(8, 22), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 1, 1, 0.6))
	if not final and absf(_delta.trend) > TREND_MIN:
		var tip_x := SIZE.x - 18.0
		var up := _delta.trend > 0.0
		var y0 := 12.0 if up else 22.0
		var y1 := 22.0 if up else 12.0
		var arrow := PackedVector2Array([Vector2(tip_x - 6, y1), Vector2(tip_x + 6, y1), Vector2(tip_x, y0)])
		draw_colored_polygon(arrow, COLOR_SLOWER if up else COLOR_FASTER)
	var bar := Rect2(10, SIZE.y - BAR_HEIGHT - 6, SIZE.x - 20, BAR_HEIGHT)
	draw_rect(bar, Color(1, 1, 1, 0.15))
	var center := bar.position.x + bar.size.x * 0.5
	var fraction := clampf(value / _delta.bar_range, -1.0, 1.0)
	var fill := bar.size.x * 0.5 * fraction
	draw_rect(Rect2(minf(center, center + fill), bar.position.y, absf(fill), bar.size.y), color)
	draw_line(Vector2(center, bar.position.y - 2), Vector2(center, bar.end.y + 2), Color.WHITE, 1.0)
