class_name TelemetryPlots
extends Control
## Gráficos del análisis de telemetría (Paso 41): canales de dos vueltas contra la distancia
## desde la meta, uno debajo del otro (velocidad, delta de B contra A, acelerador, freno,
## marcha, dirección y RPM). Vuelta A en `color_a`, B en `color_b`. Líneas de los sectores y
## un cursor vertical: ← → lo mueven (con foco), y también el mouse. Señal `cursor_moved`.

signal cursor_moved(distance: float)

## Canales: clave en TelemetryLap ("delta" se calcula), nombre, alto (px) y rango fijo
## (min = max = 0 → automático).
const CHANNELS := [
	{"key": "speed", "name": "Velocidad (km/h)", "height": 140, "min": 0.0, "max": 0.0},
	{"key": "delta", "name": "Delta B - A (s)", "height": 80, "min": 0.0, "max": 0.0},
	{"key": "throttle", "name": "Acelerador", "height": 56, "min": 0.0, "max": 1.0},
	{"key": "brake", "name": "Freno", "height": 56, "min": 0.0, "max": 1.0},
	{"key": "gear", "name": "Marcha", "height": 60, "min": 0.0, "max": 8.0},
	{"key": "steer", "name": "Dirección (izq. - / der. +)", "height": 60, "min": -1.0, "max": 1.0},
	{"key": "rpm", "name": "RPM", "height": 60, "min": 4000.0, "max": 13000.0},
]
const GAP := 8.0
const AXIS_HEIGHT := 18.0
## Metros que mueve el cursor cada ← →.
const CURSOR_STEP := 10.0
const COLOR_FASTER := Color(0.2, 0.95, 0.35)
const COLOR_SLOWER := Color(1.0, 0.27, 0.22)
const COLOR_GRID := Color(1, 1, 1, 0.1)

var color_a: Color = Color("#FF87BC")
var color_b: Color = Color(0.85, 0.87, 0.92)
var lap_a: TelemetryLap
var lap_b: TelemetryLap
var track_length: float = 1.0
var sectors: PackedFloat32Array = PackedFloat32Array()
var cursor: float = 0.0
## Delta de B contra A en cada muestra de B (s; negativo = B más rápida).
var delta_b: PackedFloat32Array = PackedFloat32Array()

var _font: Font


func _ready() -> void:
	focus_mode = Control.FOCUS_ALL
	mouse_filter = Control.MOUSE_FILTER_STOP
	_font = ThemeDB.fallback_font
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)


static func total_height() -> float:
	var total := AXIS_HEIGHT
	for channel in CHANNELS:
		total += float(channel["height"]) + GAP
	return total


func show_laps(a: TelemetryLap, b: TelemetryLap, length: float, sector_marks: PackedFloat32Array) -> void:
	lap_a = a
	lap_b = b
	track_length = maxf(length, 1.0)
	sectors = sector_marks
	delta_b = compute_delta(a, b)
	cursor = clampf(cursor, 0.0, track_length)
	queue_redraw()
	cursor_moved.emit(cursor)


## Delta de `b` contra `a` en cada muestra de `b` (lo mismo que LiveDelta: tiempo de b − tiempo
## de a en esa distancia).
static func compute_delta(a: TelemetryLap, b: TelemetryLap) -> PackedFloat32Array:
	var result := PackedFloat32Array()
	if a == null or b == null:
		return result
	var times := b.channel("time")
	var distances := b.channel("distance")
	result.resize(b.size())
	for i in b.size():
		result[i] = times[i] - a.value_at_distance("time", distances[i])
	return result


## Delta de B contra A en `distance` m.
func delta_at(distance: float) -> float:
	if lap_a == null or lap_b == null:
		return NAN
	return lap_b.value_at_distance("time", distance) - lap_a.value_at_distance("time", distance)


func set_cursor(distance: float) -> void:
	var clamped := clampf(distance, 0.0, track_length)
	if is_equal_approx(clamped, cursor):
		return
	cursor = clamped
	queue_redraw()
	cursor_moved.emit(cursor)


func _gui_input(event: InputEvent) -> void:
	var mouse := event as InputEventMouse
	if mouse != null and (mouse is InputEventMouseMotion or (mouse is InputEventMouseButton and mouse.is_pressed())):
		set_cursor(mouse.position.x / maxf(size.x, 1.0) * track_length)
		if mouse is InputEventMouseButton:
			grab_focus()
		accept_event()
	elif event.is_action_pressed("ui_left", true):
		set_cursor(cursor - CURSOR_STEP)
		accept_event()
	elif event.is_action_pressed("ui_right", true):
		set_cursor(cursor + CURSOR_STEP)
		accept_event()


func _x(distance: float) -> float:
	return clampf(distance / track_length, 0.0, 1.0) * size.x


func _draw() -> void:
	var y := 0.0
	for channel in CHANNELS:
		var height := float(channel["height"])
		_draw_channel(channel, Rect2(0, y, size.x, height))
		y += height + GAP
	# Eje de distancia.
	for metres in range(0, int(track_length) + 1, 500):
		var x := _x(metres)
		draw_string(_font, Vector2(x + 2, y + 13), "%d m" % metres, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 1, 1, 0.5))
	# Sectores y cursor sobre todos los canales.
	for k in sectors.size():
		var sx := _x(sectors[k])
		draw_line(Vector2(sx, 0), Vector2(sx, y), Color(1, 1, 1, 0.25), 1.0)
		draw_string(_font, Vector2(sx + 3, 12), "S%d" % (k + 2), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 1, 1, 0.5))
	var cx := _x(cursor)
	draw_line(Vector2(cx, 0), Vector2(cx, y), Color(1, 1, 1, 0.9 if has_focus() else 0.6), 1.5)
	var label := "%d m" % roundi(cursor)
	var width := _font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
	var lx := clampf(cx - width * 0.5, 0.0, size.x - width)
	draw_rect(Rect2(lx - 3, y + 1, width + 6, 16), Color(0, 0, 0, 0.8))
	draw_string(_font, Vector2(lx, y + 13), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)


func _draw_channel(channel: Dictionary, area: Rect2) -> void:
	draw_rect(area, Color(0, 0, 0, 0.35))
	var key := str(channel["key"])
	var low := float(channel["min"])
	var high := float(channel["max"])
	if key == "speed":
		high = 50.0
		for lap in [lap_a, lap_b]:
			if lap != null:
				for v in (lap as TelemetryLap).channel("speed"):
					high = maxf(high, v)
		high = ceilf(high / 50.0) * 50.0
		for kmh in [100.0, 200.0, 300.0]:
			if kmh < high:
				var gy: float = area.end.y - kmh / high * area.size.y
				draw_line(Vector2(area.position.x, gy), Vector2(area.end.x, gy), COLOR_GRID)
				draw_string(_font, Vector2(area.end.x - 30, gy - 2), "%d" % kmh, HORIZONTAL_ALIGNMENT_LEFT, -1, 11,
					Color(1, 1, 1, 0.4))
	elif key == "delta":
		var span := 0.2
		for v in delta_b:
			span = maxf(span, absf(v))
		span = ceilf(span * 10.0) / 10.0
		low = -span
		high = span
	draw_string(_font, area.position + Vector2(6, 14), str(channel["name"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 13,
		Color(1, 1, 1, 0.65))
	if key == "delta":
		_draw_delta(area, low, high)
		return
	if low < 0.0 and high > 0.0:
		var zy := _y(0.0, area, low, high)
		draw_line(Vector2(area.position.x, zy), Vector2(area.end.x, zy), COLOR_GRID)
	if lap_b != null and lap_b != lap_a:
		_draw_line(lap_b, key, area, low, high, color_b, 1.3)
	if lap_a != null:
		_draw_line(lap_a, key, area, low, high, color_a, 1.6)


func _y(value: float, area: Rect2, low: float, high: float) -> float:
	return area.end.y - clampf((value - low) / maxf(high - low, 1e-6), 0.0, 1.0) * area.size.y


func _draw_line(lap: TelemetryLap, key: String, area: Rect2, low: float, high: float, color: Color, width: float) -> void:
	var distance := lap.channel("distance")
	var values := lap.channel(key)
	var points := PackedVector2Array()
	for i in lap.size():
		points.append(Vector2(_x(distance[i]), _y(values[i], area, low, high)))
	if points.size() >= 2:
		draw_polyline(points, color, width, true)


func _draw_delta(area: Rect2, low: float, high: float) -> void:
	var zy := _y(0.0, area, low, high)
	draw_line(Vector2(area.position.x, zy), Vector2(area.end.x, zy), Color(1, 1, 1, 0.3))
	draw_string(_font, Vector2(area.end.x - 44, area.position.y + 12), "+%.1f" % high, HORIZONTAL_ALIGNMENT_LEFT, -1, 11,
		Color(1, 1, 1, 0.4))
	draw_string(_font, Vector2(area.end.x - 44, area.end.y - 3), "-%.1f" % high, HORIZONTAL_ALIGNMENT_LEFT, -1, 11,
		Color(1, 1, 1, 0.4))
	if lap_b == null or delta_b.size() < 2:
		return
	var distance := lap_b.channel("distance")
	for i in range(1, delta_b.size()):
		var p0 := Vector2(_x(distance[i - 1]), _y(delta_b[i - 1], area, low, high))
		var p1 := Vector2(_x(distance[i]), _y(delta_b[i], area, low, high))
		draw_line(p0, p1, COLOR_FASTER if delta_b[i] < 0.0 else COLOR_SLOWER, 1.6)
