class_name Fuel
extends RefCounted
## Combustible (Paso 34). El motor de combustión quema según la potencia que entrega:
## kg/s = P / (rendimiento × poder calorífico). Los kg se suman a la masa del auto
## (CarController.mass_kg es el auto seco con el piloto), así que con el tanque lleno el
## auto acelera, frena y dobla un poco peor y gasta un poco más los neumáticos. Sin
## combustible se apaga la unidad de potencia: no empujan ni el motor ni el MGU-K.
## La carga al salir la decide main.gd: en contrarreloj, lo justo para las vueltas más
## un margen; en práctica, practice_kg.

signal ran_out

var capacity: float = 70.0            ## kg
var heating_value: float = 43.0e6     ## J/kg
var efficiency: float = 0.5           ## del motor de combustión
var practice_kg: float = 20.0
## kg por vuelta para calcular la carga del contrarreloj (lo que gasta el piloto
## automático, redondeado para arriba) y vueltas de margen.
var lap_estimate: float = 0.6
var margin_laps: float = 1.0

var kg: float = 0.0
## kg/s del último cuadro y kg gastados en la vuelta en curso y en la anterior.
var flow: float = 0.0
var lap_used: float = 0.0
var last_lap_used: float = 0.0


func configure(data: Dictionary) -> void:
	capacity = maxf(float(data.get("capacity_kg", capacity)), 0.0)
	heating_value = maxf(float(data.get("heating_value_mj", heating_value / 1.0e6)), 1.0) * 1.0e6
	efficiency = clampf(float(data.get("efficiency", efficiency)), 0.05, 1.0)
	practice_kg = clampf(float(data.get("practice_kg", practice_kg)), 0.0, capacity)
	lap_estimate = maxf(float(data.get("lap_estimate_kg", lap_estimate)), 0.0)
	margin_laps = maxf(float(data.get("margin_laps", margin_laps)), 0.0)


## Carga para un contrarreloj de `laps` vueltas (con el margen, hasta la capacidad).
func race_load(laps: int) -> float:
	return minf((laps + margin_laps) * lap_estimate, capacity)


func fill(amount: float) -> void:
	kg = clampf(amount, 0.0, capacity)
	flow = 0.0
	lap_used = 0.0
	last_lap_used = 0.0


func is_empty() -> bool:
	return kg <= 0.0


## Vueltas que alcanzan con lo que queda (según la vuelta anterior o la estimación).
func laps_left() -> float:
	var per_lap := last_lap_used if last_lap_used > 0.0 else lap_estimate
	return kg / per_lap if per_lap > 0.0 else INF


func new_lap() -> void:
	last_lap_used = lap_used
	lap_used = 0.0


## power: W que entrega el motor de combustión en este cuadro.
func update(power: float, delta: float) -> void:
	if kg <= 0.0:
		flow = 0.0
		return
	flow = maxf(power, 0.0) / (efficiency * heating_value)
	var used := minf(flow * delta, kg)
	kg -= used
	lap_used += used
	if kg <= 0.0:
		kg = 0.0
		ran_out.emit()
