class_name StartLightsDisplay
extends Control
## Semáforo de largada en el HUD (Paso 17): 5 columnas con 2 luces rojas cada una,
## dibujadas en _draw(). Muestra lo mismo que las luces 3D del pórtico.

const SIZE := Vector2(420, 120)
const COLUMN_GAP := 14.0
const LAMP_RADIUS := 22.0
const COLOR_HOUSING := Color(0.04, 0.04, 0.05, 0.92)
const COLOR_BORDER := Color(0.25, 0.25, 0.28)

var lights_on: int = 0


func _ready() -> void:
	custom_minimum_size = SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_lights(count: int) -> void:
	lights_on = count
	queue_redraw()


func _draw() -> void:
	var count := StartLights.LIGHT_COUNT
	var column_width := (SIZE.x - COLUMN_GAP * (count - 1)) / count
	for i in count:
		var rect := Rect2(Vector2(i * (column_width + COLUMN_GAP), 0), Vector2(column_width, SIZE.y))
		draw_rect(rect, COLOR_HOUSING)
		draw_rect(rect, COLOR_BORDER, false, 2.0)
		var lit := i < lights_on
		for row in StartLights.ROWS:
			var center := rect.position + Vector2(column_width * 0.5, SIZE.y * (0.27 + 0.46 * row))
			if lit:
				draw_circle(center, LAMP_RADIUS + 6.0, Color(StartLights.COLOR_ON, 0.25))
			draw_circle(center, LAMP_RADIUS, StartLights.COLOR_ON if lit else StartLights.COLOR_OFF)
