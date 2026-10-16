class_name CarEngine
extends Node
## Motor del monoplaza (Paso 3): RPM, curva de torque y limitador.
## Las RPM salen de la velocidad de las ruedas y la relación total de la marcha.
## Por debajo de launch_rpm en 1ª el embrague patina: el motor sube con el acelerador
## aunque el auto esté quieto. (No se llama "Engine" porque choca con el singleton de Godot.)

signal limiter_hit

@export var idle_rpm: float = 4000.0
@export var limiter_rpm: float = 12500.0
@export var launch_rpm: float = 7500.0
@export var rpm_response: float = 40000.0      ## rpm/s máximos de cambio
@export var limiter_cut_time: float = 0.06     ## segundos sin potencia al tocar el limitador
@export var engine_braking: float = 2.5        ## m/s² de freno motor al limitador sin acelerar
## Puntos (rpm, N·m) ordenados por rpm.
@export var torque_curve: PackedVector2Array = PackedVector2Array([
	Vector2(4000, 180), Vector2(6000, 260), Vector2(8000, 330),
	Vector2(10500, 380), Vector2(11500, 370), Vector2(12500, 330),
])

var rpm: float = 0.0
var throttle: float = 0.0

var _cut_timer: float = 0.0


func _ready() -> void:
	reset()


func configure(data: Dictionary) -> void:
	idle_rpm = float(data.get("idle_rpm", idle_rpm))
	limiter_rpm = float(data.get("limiter_rpm", limiter_rpm))
	launch_rpm = float(data.get("launch_rpm", launch_rpm))
	rpm_response = float(data.get("rpm_response", rpm_response))
	limiter_cut_time = float(data.get("limiter_cut_time", limiter_cut_time))
	engine_braking = float(data.get("engine_braking", engine_braking))
	var curve = data.get("torque_curve", [])
	if curve is Array and not curve.is_empty():
		var points := PackedVector2Array()
		for point in curve:
			points.append(Vector2(float(point[0]), float(point[1])))
		torque_curve = points
	reset()


func reset() -> void:
	rpm = idle_rpm
	throttle = 0.0
	_cut_timer = 0.0


## En neutro el motor gira libre: el acelerador lo lleva del ralentí al limitador.
func update(wheel_rpm: float, throttle_input: float, clutch_can_slip: bool, in_neutral: bool,
		delta: float) -> void:
	throttle = clampf(throttle_input, 0.0, 1.0)
	var target := maxf(wheel_rpm, idle_rpm)
	if in_neutral:
		target = lerpf(idle_rpm, limiter_rpm, throttle)
	elif clutch_can_slip and wheel_rpm < launch_rpm:
		target = maxf(wheel_rpm, lerpf(idle_rpm, launch_rpm, throttle))
	rpm = move_toward(rpm, minf(target, limiter_rpm), rpm_response * delta)

	_cut_timer = maxf(_cut_timer - delta, 0.0)
	if rpm >= limiter_rpm - 1.0 and throttle > 0.0 and _cut_timer <= 0.0:
		_cut_timer = limiter_cut_time
		limiter_hit.emit()


func is_cutting() -> bool:
	return _cut_timer > 0.0


## Torque entregado ahora (N·m), ya escalado por el acelerador.
func get_output_torque() -> float:
	if is_cutting():
		return 0.0
	return get_torque_at(rpm) * throttle


func get_torque_at(at_rpm: float) -> float:
	if torque_curve.is_empty():
		return 0.0
	if at_rpm <= torque_curve[0].x:
		return torque_curve[0].y
	for i in range(1, torque_curve.size()):
		var a := torque_curve[i - 1]
		var b := torque_curve[i]
		if at_rpm <= b.x:
			return lerpf(a.y, b.y, (at_rpm - a.x) / maxf(b.x - a.x, 1.0))
	return torque_curve[torque_curve.size() - 1].y


## Desaceleración por freno motor (m/s²); crece con las RPM y desaparece al acelerar.
func get_engine_brake_accel() -> float:
	var rpm_ratio := clampf(inverse_lerp(idle_rpm, limiter_rpm, rpm), 0.0, 1.0)
	return engine_braking * rpm_ratio * (1.0 - throttle)


## 0 en ralentí, 1 en el limitador.
func get_rpm_ratio() -> float:
	return clampf(inverse_lerp(idle_rpm, limiter_rpm, rpm), 0.0, 1.0)
