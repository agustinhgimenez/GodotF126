class_name ControllerRumble
extends RefCounted
## Vibración del mando (Paso 37). Cada cuadro de física junta lo que siente el auto en los
## dos motores del mando (`weak`: el chico, rápido; `strong`: el grande, lento):
##   golpes contra el muro (strong, se apaga en wall_time) y daños (alerón, pinchazo),
##   piso tocando (strong), pianos, ABS soltando el freno (pulsos a abs_hz), ruedas
##   patinando o bloqueadas, una rueda pinchada (según la velocidad) y el limitador (weak).
## Todo × `intensity` (opción Vibración). Se manda a los mandos conectados cada `refresh` s o
## cuando cambia; con 0 se detiene. Godot no da force feedback de volante: sólo vibración.
## Datos en el bloque "rumble" de data/input.json; main.gd la crea y la actualiza.

var intensity: float = 1.0
## Último valor calculado (0–1).
var weak: float = 0.0
var strong: float = 0.0

var wall_strong: float = 1.0
var wall_time: float = 0.35
var damage_strong: float = 1.0
var damage_time: float = 0.6
var kerb_weak: float = 0.35
var bottoming_strong: float = 0.3
var abs_weak: float = 0.45
var abs_hz: float = 12.0
var slip_weak: float = 0.5
var slip_start: float = 0.12
var slip_full: float = 0.5
var puncture_weak: float = 0.25
var puncture_speed: float = 40.0   ## km/h a los que la rueda pinchada vibra del todo
var limiter_weak: float = 0.15
var refresh: float = 0.1

var _pulse: float = 0.0
var _pulse_length: float = 1.0
var _pulse_left: float = 0.0
var _time: float = 0.0
var _since_sent: float = 0.0
var _sent := Vector2(-1.0, -1.0)


func configure(data: Dictionary) -> void:
	for key in ["wall_strong", "wall_time", "damage_strong", "damage_time", "kerb_weak", "bottoming_strong",
			"abs_weak", "abs_hz", "slip_weak", "slip_start", "slip_full", "puncture_weak", "puncture_speed",
			"limiter_weak", "refresh"]:
		if data.has(key):
			set(key, maxf(float(data[key]), 0.0))
	wall_time = maxf(wall_time, 0.01)
	damage_time = maxf(damage_time, 0.01)
	refresh = maxf(refresh, 0.02)
	slip_full = maxf(slip_full, slip_start + 0.01)


func bind_car(car: CarController) -> void:
	car.wall_hit.connect(func(strength: float) -> void: pulse(strength * wall_strong, wall_time))
	car.damage.wing_damaged.connect(func(_health: float) -> void: pulse(damage_strong, damage_time))
	car.damage.punctured.connect(func(_index: int) -> void: pulse(damage_strong, damage_time))


## Golpe en el motor grande que se apaga en `seconds` (si es más fuerte que el que queda).
func pulse(amount: float, seconds: float) -> void:
	var current := _pulse * _pulse_left / _pulse_length if _pulse_left > 0.0 else 0.0
	if amount < current or amount < 0.02:
		return
	_pulse = clampf(amount, 0.0, 1.0)
	_pulse_length = seconds
	_pulse_left = seconds


## Calcula la vibración de este cuadro y la manda. Devuelve (weak, strong).
func update(car: CarController, delta: float) -> Vector2:
	_time += delta
	_pulse_left = maxf(_pulse_left - delta, 0.0)
	var low := _pulse * _pulse_left / _pulse_length if _pulse_left > 0.0 else 0.0
	var high := kerb_weak * clampf(car.kerb_contact, 0.0, 1.0)
	if car.is_bottoming():
		low = maxf(low, bottoming_strong)
	if car.is_abs_active():
		var on := fmod(_time * abs_hz, 1.0) < 0.5
		high = maxf(high, abs_weak * (1.0 if on else 0.3))
	var slip := clampf(inverse_lerp(slip_start, slip_full, car.get_wheel_slip()), 0.0, 1.0)
	high = maxf(high, slip_weak * slip)
	for i in 4:
		if car.damage.is_punctured(i):
			high = maxf(high, puncture_weak * clampf(car.get_speed_kmh() / maxf(puncture_speed, 1.0), 0.0, 1.0))
	if car.engine.is_cutting() and car.throttle_input > 0.0:
		high = maxf(high, limiter_weak)
	weak = clampf(high * intensity, 0.0, 1.0)
	strong = clampf(low * intensity, 0.0, 1.0)
	_send(delta)
	return Vector2(weak, strong)


## Corta la vibración (pausa, fin de la sesión, salir de la carrera).
func stop() -> void:
	_pulse_left = 0.0
	weak = 0.0
	strong = 0.0
	for device in Input.get_connected_joypads():
		Input.stop_joy_vibration(device)
	_sent = Vector2.ZERO
	_since_sent = 0.0


func _send(delta: float) -> void:
	_since_sent += delta
	var now := Vector2(weak, strong)
	var changed := absf(now.x - _sent.x) > 0.05 or absf(now.y - _sent.y) > 0.05
	if not changed and _since_sent < refresh:
		return
	if now.is_zero_approx() and _sent.is_zero_approx():
		return
	_since_sent = 0.0
	_sent = now
	for device in Input.get_connected_joypads():
		if now.is_zero_approx():
			Input.stop_joy_vibration(device)
		else:
			Input.start_joy_vibration(device, now.x, now.y, refresh * 2.0 + 0.05)
