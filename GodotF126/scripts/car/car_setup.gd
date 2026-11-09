class_name CarSetup
extends RefCounted
## Setup del auto (Paso 35): alerones, altura del piso, resortes, barras, presiones y relación
## final. Los ajustes y sus efectos están en data/setup.json; lo que elige el jugador se guarda
## en user://setup.json. derive() pasa del setup a los parámetros físicos a partir de los
## valores base de car.json (con todo en su default devuelve los mismos valores base):
## - Alerones: cada paso cambia wing_cla_per_step la carga de su eje (el reparto se mueve
##   solo) y el arrastre (el trasero mucho más que el delantero).
## - Altura: cada mm más abajo suma ride_cla_per_mm de carga (efecto suelo). El piso queda
##   a floor_clearance + altura del asfalto; si la suspensión se comprime más que eso, el piso
##   toca y la carga cae hasta stall_loss (CarController.floor_factor()).
## - Resortes y barras: rigidez × (1 + paso × spring_per_step / anti_roll_per_step); el
##   amortiguador acompaña al resorte (× √factor, misma relación de amortiguamiento).
## - Presiones: van a TyreCompounds (agarre y calor por psi debajo del default).
## - Relación final: va a la caja (cambia todas las marchas y la velocidad máxima).

const DATA_PATH := "res://data/setup.json"
const USER_PATH := "user://setup.json"

var items: Array = []
var values: Dictionary = {}
var wing_cla_per_step: float = 0.05
var front_wing_cda_per_step: float = 0.01
var rear_wing_cda_per_step: float = 0.04
var ride_cla_per_mm: float = 0.006
var spring_per_step: float = 0.075
var anti_roll_per_step: float = 0.15
var floor_clearance_mm: float = 40.0
var stall_depth_mm: float = 5.0
var stall_loss: float = 0.3
var pressure_grip_per_psi: float = 0.005
var pressure_heat_per_psi: float = 0.08


## Setup de data/setup.json con lo que guardó el jugador.
static func load_saved() -> CarSetup:
	var setup := CarSetup.new()
	setup.configure(DataLoader.load_json(DATA_PATH))
	if FileAccess.file_exists(USER_PATH):
		var saved = JSON.parse_string(FileAccess.get_file_as_string(USER_PATH))
		if saved is Dictionary:
			for id in saved:
				if setup.values.has(id) and (saved[id] is float or saved[id] is int):
					setup.set_value(str(id), float(saved[id]))
		else:
			push_warning("user://setup.json inválido; uso el setup por defecto.")
	return setup


func configure(data: Dictionary) -> void:
	var list = data.get("items", [])
	if list is Array:
		items = list
	values.clear()
	for item in items:
		values[str(item.get("id", ""))] = float(item.get("default", 0.0))
	var effects = data.get("effects", {})
	if not effects is Dictionary:
		return
	wing_cla_per_step = float(effects.get("wing_cla_per_step", wing_cla_per_step))
	front_wing_cda_per_step = float(effects.get("front_wing_cda_per_step", front_wing_cda_per_step))
	rear_wing_cda_per_step = float(effects.get("rear_wing_cda_per_step", rear_wing_cda_per_step))
	ride_cla_per_mm = float(effects.get("ride_cla_per_mm", ride_cla_per_mm))
	spring_per_step = float(effects.get("spring_per_step", spring_per_step))
	anti_roll_per_step = float(effects.get("anti_roll_per_step", anti_roll_per_step))
	floor_clearance_mm = maxf(float(effects.get("floor_clearance_mm", floor_clearance_mm)), 0.0)
	stall_depth_mm = maxf(float(effects.get("stall_depth_mm", stall_depth_mm)), 0.1)
	stall_loss = clampf(float(effects.get("stall_loss", stall_loss)), 0.0, 1.0)
	pressure_grip_per_psi = float(effects.get("pressure_grip_per_psi", pressure_grip_per_psi))
	pressure_heat_per_psi = float(effects.get("pressure_heat_per_psi", pressure_heat_per_psi))


func save() -> void:
	var file := FileAccess.open(USER_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("No se pudo guardar %s" % USER_PATH)
		return
	file.store_string(JSON.stringify(values, "  "))


func item(id: String) -> Dictionary:
	for entry in items:
		if str(entry.get("id", "")) == id:
			return entry
	return {}


func get_value(id: String) -> float:
	return float(values.get(id, item(id).get("default", 0.0)))


## Pasos desde el default (positivo = más).
func offset(id: String) -> float:
	var entry := item(id)
	if entry.is_empty():
		return 0.0
	return (get_value(id) - float(entry.get("default", 0.0))) / maxf(float(entry.get("step", 1.0)), 0.0001)


## Lleva el valor al paso más cercano dentro del rango.
func set_value(id: String, value: float) -> void:
	var entry := item(id)
	if entry.is_empty():
		return
	var low := float(entry.get("min", value))
	var high := float(entry.get("max", value))
	var step_size := maxf(float(entry.get("step", 1.0)), 0.0001)
	var index := roundi((clampf(value, low, high) - low) / step_size)
	values[id] = snappedf(minf(low + index * step_size, high), 0.0001)


## Mueve el ajuste `direction` pasos (sin dar la vuelta en los extremos).
func step(id: String, direction: int) -> void:
	set_value(id, get_value(id) + direction * float(item(id).get("step", 1.0)))


func reset_to_defaults() -> void:
	for entry in items:
		values[str(entry.get("id", ""))] = float(entry.get("default", 0.0))


func is_default() -> bool:
	for entry in items:
		if not is_equal_approx(get_value(str(entry.get("id", ""))), float(entry.get("default", 0.0))):
			return false
	return true


func value_text(id: String) -> String:
	var entry := item(id)
	var value := get_value(id)
	var decimals := int(entry.get("decimals", 0))
	var text := ("%." + str(decimals) + "f") % value
	if bool(entry.get("signed", false)) and value > 0.0:
		text = "+" + text
	var unit := str(entry.get("unit", ""))
	return text if unit.is_empty() else "%s %s" % [text, unit]


## Resumen corto de lo que se cambió (para la tarjeta del menú y la pausa).
func summary() -> String:
	if is_default():
		return "Setup por defecto"
	var parts := PackedStringArray()
	for entry in items:
		var id := str(entry.get("id", ""))
		if not is_equal_approx(get_value(id), float(entry.get("default", 0.0))):
			parts.append("%s %s" % [str(entry.get("name", id)).to_lower(), value_text(id)])
	return " · ".join(parts)


## Valores base del auto en data/car.json (los mismos que CarController.setup_base()).
static func base_from_car_data(car_data: Dictionary) -> Dictionary:
	var aero: Dictionary = car_data.get("aero", {})
	var suspension: Dictionary = car_data.get("chassis", {}).get("suspension", {})
	var front: Dictionary = suspension.get("front", {})
	var rear: Dictionary = suspension.get("rear", {})
	var gearbox: Dictionary = car_data.get("gearbox", {})
	var ratios: Array = gearbox.get("gear_ratios", [1.55])
	return {
		"cla": float(aero.get("cla", 3.2)),
		"cda": float(aero.get("cda", 1.1)),
		"balance": float(aero.get("balance", 0.44)),
		"stiffness": Vector2(float(front.get("stiffness", 75000.0)), float(rear.get("stiffness", 65000.0))),
		"damper": Vector2(float(front.get("damping", 4000.0)), float(rear.get("damping", 3600.0))),
		"anti_roll": Vector2(float(front.get("anti_roll", 40000.0)), float(rear.get("anti_roll", 30000.0))),
		"top_ratio": float(ratios[ratios.size() - 1]) if not ratios.is_empty() else 1.55,
		"limiter_rpm": float(car_data.get("engine", {}).get("limiter_rpm", 12500.0)),
		"wheel_radius": float(car_data.get("wheel_radius", 0.36)),
	}


## Parámetros físicos con este setup sobre los valores base.
func derive(base: Dictionary) -> Dictionary:
	var cla := float(base.get("cla", 3.2))
	var balance := float(base.get("balance", 0.44))
	var front_wing := offset("front_wing")
	var rear_wing := offset("rear_wing")
	var ride_mm := get_value("ride_height")
	var ground := maxf(1.0 - ride_cla_per_mm * ride_mm, 0.1)
	var front_cla := cla * balance * maxf(1.0 + wing_cla_per_step * front_wing, 0.1) * ground
	var rear_cla := cla * (1.0 - balance) * maxf(1.0 + wing_cla_per_step * rear_wing, 0.1) * ground
	var cda := float(base.get("cda", 1.1)) * maxf(1.0 + front_wing_cda_per_step * front_wing + rear_wing_cda_per_step * rear_wing, 0.1)
	var springs := Vector2(_factor(spring_per_step, offset("front_springs")), _factor(spring_per_step, offset("rear_springs")))
	var bars := Vector2(_factor(anti_roll_per_step, offset("front_anti_roll")), _factor(anti_roll_per_step, offset("rear_anti_roll")))
	var final_drive := get_value("final_drive")
	var top_speed := float(base.get("limiter_rpm", 12500.0)) * TAU / 60.0 \
		/ maxf(float(base.get("top_ratio", 1.55)) * final_drive, 0.01) * float(base.get("wheel_radius", 0.36))
	return {
		"cla": front_cla + rear_cla,
		"cda": cda,
		"balance": front_cla / (front_cla + rear_cla),
		"stiffness": (base.get("stiffness", Vector2.ONE) as Vector2) * springs,
		"damper": (base.get("damper", Vector2.ONE) as Vector2) * Vector2(sqrt(springs.x), sqrt(springs.y)),
		"anti_roll": (base.get("anti_roll", Vector2.ONE) as Vector2) * bars,
		"ride_height": ride_mm / 1000.0,
		"floor_clearance": (floor_clearance_mm + ride_mm) / 1000.0,
		"pressure": Vector2(get_value("front_pressure"), get_value("rear_pressure")),
		"final_drive": final_drive,
		"top_speed_kmh": top_speed * 3.6,
	}


## Presión de referencia (la de por defecto) de cada eje.
func default_pressure() -> Vector2:
	return Vector2(float(item("front_pressure").get("default", 23.0)), float(item("rear_pressure").get("default", 23.0)))


func _factor(per_step: float, steps: float) -> float:
	return maxf(1.0 + per_step * steps, 0.1)
