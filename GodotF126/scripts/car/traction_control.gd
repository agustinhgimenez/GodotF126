class_name TractionControl
extends RefCounted
## Control de tracción con niveles (Paso 31, opción del jugador y tecla en carrera): corta
## par del motor para que las ruedas traseras no patinen más que el umbral del nivel.
## El factor de par (0–1) se corrige en cada sub-paso según el error relativo
##   (umbral − deslizamiento) / umbral
## (recortado entre −max_error y 1) por `gain` por segundo: patinando de más baja rápido,
## sin patinar vuelve a 1 en 1 / gain segundos, y en el umbral se queda quieto.
## Nivel 0 = apagado; cuanto más alto, menos deja patinar (el 3 deja κ cerca del pico del
## neumático: la mejor tracción en recta; el 1 deja patinar y cruzar un poco la cola).

## Deslizamiento (κ) que mantiene cada nivel, del 1 en adelante.
var slip_levels: PackedFloat32Array = PackedFloat32Array([0.3, 0.16, 0.09])
var gain: float = 40.0
var max_error: float = 5.0

var level: int = 3
var torque_factor: float = 1.0
var active: bool = false


func configure(data: Dictionary) -> void:
	var levels = data.get("slip_levels", [])
	if levels is Array and not levels.is_empty():
		slip_levels = PackedFloat32Array()
		for value in levels:
			slip_levels.append(maxf(float(value), 0.01))
	gain = maxf(float(data.get("gain", gain)), 0.1)
	max_error = maxf(float(data.get("max_error", max_error)), 0.1)
	set_level(level)


## Niveles posibles contando el apagado (0).
func level_count() -> int:
	return slip_levels.size() + 1


func set_level(value: int) -> void:
	level = clampi(value, 0, slip_levels.size())
	if level == 0:
		reset()


func threshold() -> float:
	return slip_levels[level - 1] if level > 0 else INF


## Actualiza el factor con el deslizamiento de tracción de las traseras (sub-paso de los
## neumáticos) y lo devuelve.
func modulate(drive_slip: float, delta: float) -> float:
	if level == 0:
		return 1.0
	var limit := threshold()
	var error := clampf((limit - drive_slip) / limit, -max_error, 1.0)
	torque_factor = clampf(torque_factor + gain * error * delta, 0.0, 1.0)
	active = torque_factor < 0.999
	return torque_factor


func reset() -> void:
	torque_factor = 1.0
	active = false
