class_name Differential
extends RefCounted
## Diferencial autoblocante entre las ruedas traseras (Paso 31). El par del motor llega
## mitad y mitad; si una rueda gira más rápido que la otra, el embrague del diferencial le
## pasa par a la más lenta, hasta su capacidad:
##   capacidad = precarga + bloqueo × |par de entrada|
## con `power_lock` acelerando y `coast_lock` con el freno motor (sin acelerar).
## Con todo en 0 es un diferencial abierto (las ruedas giran libres con el mismo par); con
## una capacidad enorme queda bloqueado (las dos giran igual).

var preload_torque: float = 100.0   ## N·m que pasa siempre (aun sin par del motor)
var power_lock: float = 0.25        ## fracción del par del motor que puede pasar acelerando
var coast_lock: float = 0.1         ## fracción del freno motor que puede pasar sin acelerar

## N·m que pasaron de la derecha a la izquierda en el último sub-paso (negativo = al revés).
var transferred: float = 0.0


func configure(data: Dictionary) -> void:
	preload_torque = maxf(float(data.get("preload_nm", preload_torque)), 0.0)
	power_lock = maxf(float(data.get("power_lock", power_lock)), 0.0)
	coast_lock = maxf(float(data.get("coast_lock", coast_lock)), 0.0)


## N·m que se suman a la rueda izquierda (y se restan a la derecha). `input_torque`: par del
## motor (o del freno motor) entre las dos ruedas; `on_power`: acelerando. Lo que haría
## girar igual a las dos ruedas en este sub-paso se recorta a la capacidad.
func transfer(spin_left: float, spin_right: float, input_torque: float, on_power: bool,
		wheel_inertia: float, delta: float) -> float:
	var capacity := preload_torque + (power_lock if on_power else coast_lock) * absf(input_torque)
	var equalize := (spin_right - spin_left) * wheel_inertia / (2.0 * delta)
	transferred = clampf(equalize, -capacity, capacity)
	return transferred
