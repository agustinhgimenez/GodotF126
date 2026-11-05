class_name Ers
extends RefCounted
## ERS del reglamento 2026 (Paso 32): batería y MGU-K en el eje trasero.
## - Despliegue: acelerando, el MGU-K suma potencia eléctrica (hasta max_deploy × la fracción
##   del modo × acelerador) mientras haya energía; el modo adelantamiento (ActiveAero) suma su
##   potencia extra de la misma batería.
## - Recuperación: frenando, el MGU-K frena las traseras en lugar de una parte del freno
##   hidráulico (freno por cable: el par total no cambia), hasta max_harvest; levantando el
##   pie (sin freno) frena un poco más según el modo (lift_kw). Hay un tope de energía
##   recuperada por vuelta (lap_harvest_limit), que se renueva al cruzar la línea.
## El auto calcula las potencias de cada cuadro y llama a update().

signal mode_changed(mode_name: String)

var capacity: float = 4.0e6            ## J útiles de la batería
var max_deploy: float = 350000.0       ## W del MGU-K desplegando
var max_harvest: float = 350000.0      ## W del MGU-K recuperando
var lap_harvest_limit: float = 8.5e6   ## J que se pueden recuperar por vuelta
## Modos de despliegue: {"name", "short", "deploy" (fracción de max_deploy), "lift_kw"}.
var modes: Array[Dictionary] = [
	{"name": "Ataque", "short": "ATQ", "deploy": 1.0, "lift_kw": 0.0},
	{"name": "Normal", "short": "NOR", "deploy": 0.35, "lift_kw": 0.0},
	{"name": "Recarga", "short": "REC", "deploy": 0.0, "lift_kw": 150.0},
]
var mode_index: int = 1

var energy: float = 4.0e6
var lap_harvested: float = 0.0
## W del último cuadro (lo que llegó a las ruedas y lo que se recuperó).
var deploy_power: float = 0.0
var harvest_power: float = 0.0


func configure(data: Dictionary) -> void:
	capacity = maxf(float(data.get("battery_mj", capacity / 1e6)) * 1e6, 1.0)
	max_deploy = maxf(float(data.get("deploy_kw", max_deploy / 1000.0)) * 1000.0, 0.0)
	max_harvest = maxf(float(data.get("harvest_kw", max_harvest / 1000.0)) * 1000.0, 0.0)
	lap_harvest_limit = maxf(float(data.get("lap_harvest_mj", lap_harvest_limit / 1e6)) * 1e6, 0.0)
	var mode_data = data.get("modes", [])
	if mode_data is Array and not mode_data.is_empty():
		modes.clear()
		for entry in mode_data:
			if entry is Dictionary:
				modes.append({
					"name": str(entry.get("name", "Modo")),
					"short": str(entry.get("short", "ERS")),
					"deploy": clampf(float(entry.get("deploy", 0.5)), 0.0, 1.0),
					"lift_kw": maxf(float(entry.get("lift_kw", 0.0)), 0.0),
				})
	mode_index = clampi(int(data.get("default_mode", mode_index)), 0, modes.size() - 1)
	reset()


func mode() -> Dictionary:
	return modes[mode_index]


func cycle_mode() -> void:
	mode_index = (mode_index + 1) % modes.size()
	mode_changed.emit(str(mode()["name"]))


## W que puede desplegar ahora el MGU-K con ese acelerador (0 con la batería vacía).
func deploy_request(throttle: float) -> float:
	if energy <= 0.0:
		return 0.0
	return max_deploy * float(mode()["deploy"]) * clampf(throttle, 0.0, 1.0)


## Todavía puede recuperar (batería no llena y queda tope en la vuelta).
func can_harvest() -> bool:
	return energy < capacity and lap_harvested < lap_harvest_limit


## W que frena el MGU-K al levantar el pie (sin acelerar ni frenar).
func lift_power() -> float:
	return float(mode()["lift_kw"]) * 1000.0 if can_harvest() else 0.0


## Un cuadro: `deployed` W que salieron de la batería, `harvested` W de frenada disponibles
## para recuperar (se recortan a max_harvest y a lo que queda de la vuelta).
func update(deployed: float, harvested: float, delta: float) -> void:
	harvest_power = minf(harvested, max_harvest) if can_harvest() else 0.0
	harvest_power = minf(harvest_power, (lap_harvest_limit - lap_harvested) / delta)
	deploy_power = minf(deployed, energy / delta)
	energy = clampf(energy + (harvest_power - deploy_power) * delta, 0.0, capacity)
	lap_harvested += harvest_power * delta


func soc() -> float:
	return energy / capacity


func is_empty() -> bool:
	return energy <= 0.0


## Nueva vuelta: se renueva el tope de recuperación.
func new_lap() -> void:
	lap_harvested = 0.0


func reset() -> void:
	energy = capacity
	lap_harvested = 0.0
	deploy_power = 0.0
	harvest_power = 0.0
