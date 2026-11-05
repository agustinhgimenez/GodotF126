class_name AbsModel
extends RefCounted
## ABS (Paso 30): por rueda, suelta el freno cuando la rueda empieza a bloquearse y lo vuelve
## a apretar cuando recupera el giro. La presión (0–1) baja a release_rate por segundo mientras
## el deslizamiento de frenada pasa release_slip y sube a apply_rate por segundo cuando baja de
## apply_slip; en el medio se mantiene. Así la rueda cicla alrededor del pico de la curva del
## neumático (frena un poco menos que el pico y sigue doblando).

var release_slip: float = 0.14   ## deslizamiento de frenada (−κ) que suelta el freno
var apply_slip: float = 0.08     ## por debajo vuelve a apretar
var release_rate: float = 15.0   ## presión que se suelta por segundo
var apply_rate: float = 4.0      ## presión que se recupera por segundo
var min_speed: float = 2.0       ## m/s; más despacio no actúa (el auto se tiene que poder detener)


func configure(data: Dictionary) -> void:
	release_slip = float(data.get("release_slip", release_slip))
	apply_slip = minf(float(data.get("apply_slip", apply_slip)), release_slip)
	release_rate = maxf(float(data.get("release_rate", release_rate)), 0.1)
	apply_rate = maxf(float(data.get("apply_rate", apply_rate)), 0.1)
	min_speed = float(data.get("min_speed", min_speed))


## Actualiza la presión de esa rueda (sub-paso de los neumáticos) y la devuelve.
func modulate(wheel: CarWheel, delta: float) -> float:
	if absf(wheel.long_speed) < min_speed:
		wheel.brake_pressure = 1.0
	else:
		var lock := -wheel.slip_ratio * signf(wheel.long_speed)
		if lock > release_slip:
			wheel.brake_pressure = maxf(wheel.brake_pressure - release_rate * delta, 0.0)
		elif lock < apply_slip:
			wheel.brake_pressure = minf(wheel.brake_pressure + apply_rate * delta, 1.0)
	wheel.abs_active = wheel.brake_pressure < 0.999
	return wheel.brake_pressure
