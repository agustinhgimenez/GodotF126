class_name WheelLoadsPanel
extends Control
## Panel de cargas por rueda (Paso 27, tecla F3): el auto visto desde arriba con la carga de
## cada rueda (N y % del peso, color según cuánto más o menos que quieto), κ y deriva; abajo
## el reparto por eje y por lado, la aceleración, cabeceo y rolido, la carga aerodinámica y el
## arrastre (Paso 28), y la transferencia de peso medida (sin la carga aerodinámica) contra la
## de la cuenta (CarController.theoretical_transfer()).

const SIZE := Vector2(330, 450)
const BG := Color(0.04, 0.05, 0.07, 0.78)
const TEXT := Color(0.9, 0.92, 0.95)
const DIM := Color(0.6, 0.64, 0.7)
const LIGHT := Color(0.25, 0.5, 1.0)
const HEAVY := Color(1.0, 0.35, 0.25)
const NEUTRAL := Color(0.3, 0.32, 0.36)
## Posición de cada rueda en el dibujo (mismo orden que CarController.wheels: DI, DD, TI, TD).
const WHEEL_SPOTS := [Vector2(85, 70), Vector2(245, 70), Vector2(85, 205), Vector2(245, 205)]
const WHEEL_BOX := Vector2(110, 82)

var _car: CarController


func _ready() -> void:
	custom_minimum_size = SIZE
	size = SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func bind_car(car: CarController) -> void:
	_car = car


func _process(_delta: float) -> void:
	if visible:
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, SIZE), BG)
	var font := get_theme_default_font()
	draw_string(font, Vector2(14, 24), "CARGAS POR RUEDA · F3", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, DIM)
	if _car == null or _car.wheels.size() != 4:
		return
	var weight := _car.mass * 9.8
	# Chasis y ruedas.
	draw_rect(Rect2(Vector2(150, 50), Vector2(30, 205)), NEUTRAL)
	draw_rect(Rect2(Vector2(110, 60), Vector2(110, 12)), NEUTRAL)
	draw_rect(Rect2(Vector2(110, 238), Vector2(110, 12)), NEUTRAL)
	for i in 4:
		var wheel := _car.wheels[i]
		var spot: Vector2 = WHEEL_SPOTS[i]
		var rect := Rect2(spot - WHEEL_BOX * 0.5, WHEEL_BOX)
		var ratio := wheel.wheel_load / maxf(wheel.static_load, 1.0)
		var color := NEUTRAL
		if not wheel.in_contact:
			color = Color(0.1, 0.1, 0.12)
		elif ratio >= 1.0:
			color = NEUTRAL.lerp(HEAVY, clampf((ratio - 1.0) / 1.0, 0.0, 1.0))
		else:
			color = NEUTRAL.lerp(LIGHT, clampf(1.0 - ratio, 0.0, 1.0))
		draw_rect(rect, color)
		draw_rect(rect, Color(1, 1, 1, 0.25), false, 1.0)
		HudDraw.draw_text_centered(self, font, "%d N" % roundi(wheel.wheel_load), spot + Vector2(0, -22), 17, TEXT, 3)
		HudDraw.draw_text_centered(self, font, "%d %%" % roundi(wheel.wheel_load / weight * 100.0), spot + Vector2(0, -2), 14, TEXT, 3)
		HudDraw.draw_text_centered(self, font, "κ %.2f · %.1f°" % [wheel.slip_ratio, rad_to_deg(wheel.slip_angle)],
			spot + Vector2(0, 20), 13, DIM, 3)

	var loads := PackedFloat32Array()
	for wheel in _car.wheels:
		loads.append(wheel.wheel_load)
	var total := maxf(loads[0] + loads[1] + loads[2] + loads[3], 1.0)
	var front := loads[0] + loads[1]
	var right := loads[1] + loads[3]
	var static_front := _car.wheels[0].static_load + _car.wheels[1].static_load
	var accel := _car.local_acceleration
	var theory := _car.theoretical_transfer()
	var front_aero := _car.downforce_front
	var lines := [
		"Ejes: adelante %d %% · atrás %d %%" % [roundi(front / total * 100.0), roundi(100.0 - front / total * 100.0)],
		"Lados: izq. %d %% · der. %d %%" % [roundi(100.0 - right / total * 100.0), roundi(right / total * 100.0)],
		"Acel. long. %+.2f g · lat. %.2f g %s" % [-accel.z / 9.8, absf(accel.x) / 9.8, "izq." if accel.x < 0.0 else "der."],
		"Cabeceo %.2f° · rolido %.2f°" % [_car.get_pitch_deg(), _car.get_roll_deg()],
		"Carga aero %d N · arrastre %d N" % [roundi(_car.downforce), roundi(_car.drag_force)],
		"Transf. adelante %+d N (cuenta %+d)" % [roundi(front - static_front - front_aero), roundi(theory.x)],
		"Transf. derecha %+d N (cuenta %+d)" % [roundi(right - total * 0.5), roundi(theory.y)],
	]
	var y := 280.0
	for line in lines:
		draw_string(font, Vector2(14, y), str(line), HORIZONTAL_ALIGNMENT_LEFT, SIZE.x - 20, 14, TEXT)
		y += 24.0
