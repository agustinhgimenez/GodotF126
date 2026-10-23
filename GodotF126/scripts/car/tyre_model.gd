class_name TyreModel
extends RefCounted
## Neumático con la "fórmula mágica" de Pacejka simplificada (Paso 26), igual para las 4
## ruedas:  F = D · sin(C · atan(B·x − E·(B·x − atan(B·x))))
## - x: ángulo de deriva (rad) para la fuerza lateral y deslizamiento longitudinal
##   κ = (ω·r − v) / v para la de tracción y frenada.
## - D: el pico = μ × carga (con sensibilidad a la carga: más carga, un poco menos de μ).
## - B (rigidez), C (forma) y E (curvatura) salen de data/car.json; el pico de cada curva
##   (`slip_angle_peak`, `slip_ratio_peak`) se calcula de ellos.
## Deriva y deslizamiento juntos se combinan "por semejanza": se normaliza cada uno por su
## pico, la curva se evalúa con el largo del vector y la fuerza se reparte en su dirección,
## así el total nunca supera el pico (círculo de fricción) y frenar o acelerar a fondo
## deja menos agarre de costado.

## Curva lateral (x = deriva en rad) y longitudinal (x = κ).
var lat_b: float = 16.0
var lat_c: float = 1.45
var lat_e: float = -0.5
var long_b: float = 16.0
var long_c: float = 1.5
var long_e: float = -0.3
## Fracción de μ que se pierde por cada carga estática de más (0 = sin sensibilidad).
var load_sensitivity: float = 0.1
## kg·m² de rueda + neumático + disco (lo que hay que acelerar para que patine).
var wheel_inertia: float = 1.2
## m/s mínimos para medir deriva y deslizamiento (estable a baja velocidad).
var slip_floor: float = 5.0

var slip_angle_peak: float = 0.1
var slip_ratio_peak: float = 0.1


func _init() -> void:
	_update_peaks()


func configure(data: Dictionary) -> void:
	load_sensitivity = float(data.get("load_sensitivity", load_sensitivity))
	wheel_inertia = maxf(float(data.get("wheel_inertia", wheel_inertia)), 0.05)
	slip_floor = maxf(float(data.get("slip_floor", slip_floor)), 0.5)
	var lateral = data.get("lateral", {})
	if lateral is Dictionary:
		lat_b = float(lateral.get("B", lat_b))
		lat_c = float(lateral.get("C", lat_c))
		lat_e = float(lateral.get("E", lat_e))
	var longitudinal = data.get("longitudinal", {})
	if longitudinal is Dictionary:
		long_b = float(longitudinal.get("B", long_b))
		long_c = float(longitudinal.get("C", long_c))
		long_e = float(longitudinal.get("E", long_e))
	_update_peaks()


func _update_peaks() -> void:
	lat_b = maxf(lat_b, 0.1)
	long_b = maxf(long_b, 0.1)
	lat_c = clampf(lat_c, 1.05, 1.95)
	long_c = clampf(long_c, 1.05, 1.95)
	lat_e = minf(lat_e, 0.99)
	long_e = minf(long_e, 0.99)
	slip_angle_peak = find_peak(lat_b, lat_c, lat_e)
	slip_ratio_peak = find_peak(long_b, long_c, long_e)


## Fórmula mágica con D = 1 (pico de la curva = 1).
static func magic(x: float, b: float, c: float, e: float) -> float:
	var bx := b * x
	return sin(c * atan(bx - e * (bx - atan(bx))))


## x del pico: donde C · atan(...) llega a 90°. El argumento crece con x (E < 1), así que
## alcanza con bisección.
static func find_peak(b: float, c: float, e: float) -> float:
	var target := tan(PI / (2.0 * c))
	var low := 0.0
	var high := 50.0 / b
	for i in 40:
		var mid := (low + high) * 0.5
		var bx := b * mid
		if bx - e * (bx - atan(bx)) < target:
			low = mid
		else:
			high = mid
	return (low + high) * 0.5


## Multiplica μ según la carga: 1 con la carga estática, menos con más carga.
func load_factor(wheel_load: float, static_load: float) -> float:
	if static_load <= 0.0:
		return 1.0
	return clampf(1.0 - load_sensitivity * (wheel_load / static_load - 1.0), 0.5, 1.3)


## (longitudinal, lateral) en N. grip: pico en N (μ × carga). Lateral positivo = hacia la
## derecha de la rueda; una deriva positiva (resbala a la derecha) empuja a la izquierda.
func forces(slip_ratio: float, slip_angle: float, grip: float) -> Vector2:
	var sx := slip_ratio / slip_ratio_peak
	var sy := slip_angle / slip_angle_peak
	var s := sqrt(sx * sx + sy * sy)
	if s < 1e-6:
		return Vector2.ZERO
	var fx := magic(s * slip_ratio_peak, long_b, long_c, long_e) * sx / s
	var fy := -magic(s * slip_angle_peak, lat_b, lat_c, lat_e) * sy / s
	return Vector2(fx, fy) * grip
