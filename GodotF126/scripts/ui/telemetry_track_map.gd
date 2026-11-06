class_name TelemetryTrackMap
extends Control
## Mapa de la pista del análisis (Paso 41), visto desde arriba: el recorrido de la vuelta B
## pintado según gana (verde) o pierde (rojo) tiempo contra A en ese tramo (lo que cambia el
## delta en ±`WINDOW` muestras), la meta y un punto por vuelta en la distancia del cursor.

## Muestras a cada lado para medir si el delta sube o baja (0,5 s a 20 Hz).
const WINDOW := 10
## Segundos de cambio del delta en la ventana (~1 s) por debajo de los cuales el tramo queda
## gris: dos vueltas casi iguales difieren unas centésimas por segundo.
const THRESHOLD := 0.02
const MARGIN := 14.0
const COLOR_FASTER := Color(0.2, 0.95, 0.35)
const COLOR_SLOWER := Color(1.0, 0.27, 0.22)
const COLOR_EVEN := Color(0.55, 0.57, 0.62)

var color_a: Color = Color("#FF87BC")
var color_b: Color = Color(0.85, 0.87, 0.92)
var outline: PackedVector2Array = PackedVector2Array()
var lap_a: TelemetryLap
var lap_b: TelemetryLap
var delta_b: PackedFloat32Array = PackedFloat32Array()
var cursor: float = 0.0

var _bounds := Rect2()


func set_outline(points: PackedVector2Array) -> void:
	outline = points
	_bounds = Rect2()
	if points.is_empty():
		return
	_bounds = Rect2(points[0], Vector2.ZERO)
	for p in points:
		_bounds = _bounds.expand(p)
	queue_redraw()


func show_laps(a: TelemetryLap, b: TelemetryLap, delta: PackedFloat32Array) -> void:
	lap_a = a
	lap_b = b
	delta_b = delta
	queue_redraw()


func set_cursor(distance: float) -> void:
	cursor = distance
	queue_redraw()


## Tramo de la muestra i de B: −1 gana, 1 pierde, 0 parejo.
func gain_state(i: int) -> int:
	var n := delta_b.size()
	if n < 2:
		return 0
	var change := delta_b[mini(i + WINDOW, n - 1)] - delta_b[maxi(i - WINDOW, 0)]
	if change < -THRESHOLD:
		return -1
	if change > THRESHOLD:
		return 1
	return 0


func _to_screen(world: Vector2) -> Vector2:
	var area := Rect2(Vector2(MARGIN, MARGIN), size - Vector2(MARGIN, MARGIN) * 2.0)
	var scale := minf(area.size.x / maxf(_bounds.size.x, 1.0), area.size.y / maxf(_bounds.size.y, 1.0))
	var offset := area.position + (area.size - _bounds.size * scale) * 0.5
	return offset + (world - _bounds.position) * scale


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.35))
	if outline.size() < 2:
		return
	var screen := PackedVector2Array()
	for p in outline:
		screen.append(_to_screen(p))
	screen.append(screen[0])
	draw_polyline(screen, Color(1, 1, 1, 0.18), 9.0, true)
	draw_circle(screen[0], 4.0, Color.WHITE)
	if lap_b != null and delta_b.size() == lap_b.size() and lap_b != lap_a:
		var xs := lap_b.channel("x")
		var zs := lap_b.channel("z")
		for i in range(1, lap_b.size()):
			var state := gain_state(i)
			var color := COLOR_EVEN if state == 0 else (COLOR_FASTER if state < 0 else COLOR_SLOWER)
			draw_line(_to_screen(Vector2(xs[i - 1], zs[i - 1])), _to_screen(Vector2(xs[i], zs[i])), color, 3.5)
	for pair in [[lap_b, color_b], [lap_a, color_a]]:
		var lap := pair[0] as TelemetryLap
		if lap == null or lap.size() == 0:
			continue
		var point := Vector2(lap.value_at_distance("x", cursor), lap.value_at_distance("z", cursor))
		draw_circle(_to_screen(point), 6.0, Color.BLACK)
		draw_circle(_to_screen(point), 4.5, pair[1])
