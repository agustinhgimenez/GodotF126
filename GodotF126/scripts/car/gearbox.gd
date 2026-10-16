class_name Gearbox
extends Node
## Caja de cambios. En el Paso 3 es automática y simple, para que las RPM del motor
## tengan sentido. El Paso 4 agrega modo manual con levas, N, R y corte al cambiar.

signal gear_changed(gear: int)

@export var gear_ratios: PackedFloat32Array = PackedFloat32Array([9.43, 7.95, 6.70, 5.65, 4.76, 4.02, 3.39, 2.85])
@export var final_drive: float = 3.0
@export var efficiency: float = 0.9
@export var shift_up_rpm: float = 12000.0
@export var shift_down_rpm: float = 7000.0
@export var min_shift_interval: float = 0.25   ## evita que la caja "dude" entre dos marchas

var gear: int = 1

var _since_shift: float = 0.0


func configure(data: Dictionary) -> void:
	var ratios = data.get("gear_ratios", [])
	if ratios is Array and not ratios.is_empty():
		var parsed := PackedFloat32Array()
		for ratio in ratios:
			parsed.append(float(ratio))
		gear_ratios = parsed
	final_drive = float(data.get("final_drive", final_drive))
	efficiency = float(data.get("efficiency", efficiency))
	shift_up_rpm = float(data.get("shift_up_rpm", shift_up_rpm))
	shift_down_rpm = float(data.get("shift_down_rpm", shift_down_rpm))
	min_shift_interval = float(data.get("min_shift_interval", min_shift_interval))
	reset()


func reset() -> void:
	_since_shift = 0.0
	_set_gear(1)


func get_gear_count() -> int:
	return gear_ratios.size()


## Relación total (caja × diferencial) de una marcha; por defecto la actual.
func get_total_ratio(for_gear: int = -1) -> float:
	var g := gear if for_gear < 1 else for_gear
	if gear_ratios.is_empty():
		return final_drive
	return gear_ratios[clampi(g, 1, gear_ratios.size()) - 1] * final_drive


func update_automatic(engine_rpm: float, delta: float) -> void:
	_since_shift += delta
	if _since_shift < min_shift_interval:
		return
	if engine_rpm >= shift_up_rpm and gear < get_gear_count():
		_set_gear(gear + 1)
	elif engine_rpm <= shift_down_rpm and gear > 1:
		_set_gear(gear - 1)


func _set_gear(new_gear: int) -> void:
	_since_shift = 0.0
	if new_gear == gear:
		return
	gear = new_gear
	gear_changed.emit(gear)
