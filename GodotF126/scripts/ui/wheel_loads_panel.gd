class_name WheelLoadsPanel
extends Control
## Panel de cargas por rueda (Paso 27, tecla F3): el auto visto desde arriba con la carga de
## cada rueda (N y % del peso, color según cuánto más o menos que quieto), κ y deriva (o
## "BLOQUEADA" / la presión que deja el ABS, Paso 30) y una franja con la temperatura y el
## desgaste del neumático (Paso 33; celeste frío, verde en la ventana, rojo pasado); abajo
## el reparto por eje y por lado, la altura del piso en cada eje (Paso 35; "TOCA" si roza el
## asfalto y pierde carga), la aceleración, cabeceo y rolido, la carga aerodinámica y el
## arrastre (Paso 28), el modo de la aero activa con ClA y CdA (Paso 29), el reparto de
## frenada y el ABS (Paso 30), el control de tracción y el par que pasa el diferencial
## (Paso 31), el ERS (modo, carga, potencia desplegada / recuperada y energía recuperada en la
## vuelta, Paso 32), el combustible con la masa y el consumo por vuelta (Paso 34), los daños (salud del alerón delantero
## y ruedas pinchadas, Paso 36) y la transferencia de peso medida (sin la carga aerodinámica)
## contra la de la cuenta (CarController.theoretical_transfer()), en una línea.

const SIZE := Vector2(330, 522)
const BG := Color(0.04, 0.05, 0.07, 0.78)
const TEXT := Color(0.9, 0.92, 0.95)
const DIM := Color(0.6, 0.64, 0.7)
const LIGHT := Color(0.25, 0.5, 1.0)
const HEAVY := Color(1.0, 0.35, 0.25)
const NEUTRAL := Color(0.3, 0.32, 0.36)
const LOCKED := Color(1.0, 0.9, 0.2)
## Posición de cada rueda en el dibujo (mismo orden que CarController.wheels: DI, DD, TI, TD).
const WHEEL_SPOTS := [Vector2(85, 80), Vector2(245, 80), Vector2(85, 212), Vector2(245, 212)]
const WHEEL_BOX := Vector2(110, 98)

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
		HudDraw.draw_text_centered(self, font, "%d N" % roundi(wheel.wheel_load), spot + Vector2(0, -30), 17, TEXT, 3)
		HudDraw.draw_text_centered(self, font, "%d %%" % roundi(wheel.wheel_load / weight * 100.0), spot + Vector2(0, -10), 14, TEXT, 3)
		var strip := Rect2(rect.position.x, rect.end.y - 20, rect.size.x, 20)
		draw_rect(strip, TyrePanel.temperature_color(_car.tyres.temperature_state(wheel.temperature)))
		HudDraw.draw_text_centered(self, font, "%d °C · %d %%" % [roundi(wheel.temperature), roundi(wheel.wear * 100.0)],
			strip.get_center() + Vector2(0, 1), 13, TEXT, 3)
		var tag := "BLOQUEADA" if wheel.is_locked() else ("ABS %d %%" % roundi(wheel.brake_pressure * 100.0) if wheel.abs_active else "")
		if tag.is_empty():
			HudDraw.draw_text_centered(self, font, "κ %.2f · %.1f°" % [wheel.slip_ratio, rad_to_deg(wheel.slip_angle)],
				spot + Vector2(0, 10), 13, DIM, 3)
		else:
			HudDraw.draw_text_centered(self, font, tag, spot + Vector2(0, 10), 13,
				LOCKED if wheel.is_locked() else Dashboard.COLOR_ABS, 3)

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
	var tc := _car.traction_control
	var gaps := _car.floor_gaps()
	var lines := [
		"Ejes adel./atrás %d/%d %% · izq./der. %d/%d %%" % [roundi(front / total * 100.0), roundi(100.0 - front / total * 100.0),
			roundi(100.0 - right / total * 100.0), roundi(right / total * 100.0)],
		("Piso %d / %d mm · ¡TOCA! carga %d %%" % [roundi(gaps.x * 1000.0), roundi(gaps.y * 1000.0), roundi(_car.floor_factor() * 100.0)])
			if _car.is_bottoming() else "Piso adel. %d mm · atrás %d mm" % [roundi(gaps.x * 1000.0), roundi(gaps.y * 1000.0)],
		"Acel. long. %+.2f g · lat. %.2f g %s" % [-accel.z / 9.8, absf(accel.x) / 9.8, "izq." if accel.x < 0.0 else "der."],
		"Cabeceo %.2f° · rolido %.2f°" % [_car.get_pitch_deg(), _car.get_roll_deg()],
		"Carga aero %d N · arrastre %d N" % [roundi(_car.downforce), roundi(_car.drag_force)],
		"Modo %s · ClA %.2f · CdA %.2f" % [_car.active_aero.mode_label().to_lower(), _car.get_cla(), _car.get_cda()],
		"Frenos: reparto %d %% adelante · ABS %s" % [roundi(_car.brake_front_share * 100.0), "sí" if _car.abs_enabled else "no"],
		"TC %s · par %d %% · dif. %+d N·m" % [str(tc.level) if tc.level > 0 else "no", roundi(tc.torque_factor * 100.0),
			roundi(_car.differential.transferred)],
		"ERS %s %d %% · +%d / −%d kW · vuelta %.1f MJ" % [_car.ers.mode()["short"], roundi(_car.ers.soc() * 100.0),
			roundi(_car.ers.deploy_power / 1000.0), roundi(_car.ers.harvest_power / 1000.0), _car.ers.lap_harvested / 1e6],
		"Comb. %.1f kg · %.2f kg/vuelta · masa %d kg" % [_car.fuel.kg,
			_car.fuel.last_lap_used if _car.fuel.last_lap_used > 0.0 else _car.fuel.lap_used, roundi(_car.mass)],
		"Daños: alerón %d %% · pinchazos %s" % [roundi(_car.damage.wing_health * 100.0), _punctures_text()],
		"Transf. adel. %+d (%+d) · der. %+d (%+d) N" % [roundi(front - static_front - front_aero), roundi(theory.x),
			roundi(right - total * 0.5), roundi(theory.y)],
	]
	var y := 282.0
	for line in lines:
		draw_string(font, Vector2(14, y), str(line), HORIZONTAL_ALIGNMENT_LEFT, SIZE.x - 20, 14, TEXT)
		y += 21.0


func _punctures_text() -> String:
	var names := PackedStringArray()
	for i in 4:
		if _car.damage.is_punctured(i):
			names.append(["DI", "DD", "TI", "TD"][i])
	return "no" if names.is_empty() else " ".join(names)
