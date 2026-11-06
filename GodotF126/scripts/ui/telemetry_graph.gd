class_name TelemetryGraph
extends Control
## Velocidad contra distancia (Paso 39): la vuelta `lap` en el color `accent` y la de
## referencia `reference` en gris; abajo una franja con acelerador (verde) y freno (rojo)
## de `lap`. El análisis completo con más canales es el Paso 41.

const STRIP_HEIGHT := 10.0
const GRID_SPEEDS := [100.0, 200.0, 300.0]
const COLOR_REFERENCE := Color(0.75, 0.77, 0.82, 0.8)
const COLOR_THROTTLE := Color(0.2, 0.85, 0.35)
const COLOR_BRAKE := Color(0.95, 0.2, 0.15)

var accent: Color = Color("#FF87BC")
var lap: TelemetryLap
var reference: TelemetryLap
var track_length: float = 1.0


func show_laps(new_lap: TelemetryLap, new_reference: TelemetryLap, length: float) -> void:
	lap = new_lap
	reference = new_reference
	track_length = maxf(length, 1.0)
	queue_redraw()


func _draw() -> void:
	var area := Rect2(Vector2.ZERO, size)
	draw_rect(area, Color(0, 0, 0, 0.45))
	var plot := Rect2(0, 0, size.x, size.y - STRIP_HEIGHT - 4.0)
	var top := 50.0
	for l in [lap, reference]:
		if l != null:
			for v in (l as TelemetryLap).channel("speed"):
				top = maxf(top, v)
	top = ceilf(top / 50.0) * 50.0
	var font := get_theme_default_font()
	for kmh in GRID_SPEEDS:
		if kmh >= top:
			continue
		var y: float = plot.end.y - kmh / top * plot.size.y
		draw_line(Vector2(0, y), Vector2(size.x, y), Color(1, 1, 1, 0.12))
		draw_string(font, Vector2(4, y - 2), "%d" % kmh, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 1, 1, 0.45))
	if reference != null:
		_draw_speed(reference, plot, top, COLOR_REFERENCE, 1.5)
	if lap != null:
		_draw_speed(lap, plot, top, accent, 2.0)
		_draw_pedals(lap, Rect2(0, size.y - STRIP_HEIGHT, size.x, STRIP_HEIGHT))
	if lap == null and reference == null:
		draw_string(font, Vector2(12, size.y * 0.5), "Sin vueltas completas todavía", HORIZONTAL_ALIGNMENT_LEFT, -1, 16,
			Color(1, 1, 1, 0.6))


func _x(distance: float) -> float:
	return clampf(distance / track_length, 0.0, 1.0) * size.x


func _draw_speed(source: TelemetryLap, plot: Rect2, top: float, color: Color, width: float) -> void:
	var distance := source.channel("distance")
	var speed := source.channel("speed")
	var points := PackedVector2Array()
	for i in source.size():
		points.append(Vector2(_x(distance[i]), plot.end.y - clampf(speed[i] / top, 0.0, 1.0) * plot.size.y))
	if points.size() >= 2:
		draw_polyline(points, color, width, true)


func _draw_pedals(source: TelemetryLap, strip: Rect2) -> void:
	var distance := source.channel("distance")
	var throttle := source.channel("throttle")
	var brake := source.channel("brake")
	for i in range(1, source.size()):
		var x0 := _x(distance[i - 1])
		var x1 := _x(distance[i])
		if x1 <= x0:
			continue
		var color := Color(0, 0, 0, 0)
		if brake[i] >= 0.05:
			color = Color(COLOR_BRAKE, clampf(brake[i], 0.3, 1.0))
		elif throttle[i] > 0.0:
			color = Color(COLOR_THROTTLE, clampf(throttle[i], 0.15, 1.0))
		if color.a > 0.0:
			draw_rect(Rect2(x0, strip.position.y, x1 - x0 + 0.5, strip.size.y), color)
