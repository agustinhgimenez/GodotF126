class_name Gearbox
extends Node
## Caja de cambios secuencial de 8 marchas + N + R (Paso 4).
## Manual: levas E (sube) / Q (baja). Automática: cambia sola según RPM.
## Cada cambio corta la potencia shift_time segundos. Se niega un rebaje que
## dejaría el motor por encima del limitador y la reversa con el auto en movimiento.

signal gear_changed(gear: int)
signal shift_denied(reason: String)
signal mode_changed(manual: bool)

const REVERSE := -1
const NEUTRAL := 0
const MAX_REVERSE_ENGAGE_SPEED := 1.0   ## m/s

@export var gear_ratios: PackedFloat32Array = PackedFloat32Array([9.43, 7.95, 6.70, 5.65, 4.76, 4.02, 3.39, 2.85])
@export var reverse_ratio: float = 9.0
@export var final_drive: float = 3.0
@export var efficiency: float = 0.9
@export var shift_time: float = 0.08           ## segundos sin potencia en cada cambio
@export var manual: bool = true
@export_group("Automática")
@export var shift_up_rpm: float = 12000.0
@export var shift_down_rpm: float = 7000.0
@export var min_shift_interval: float = 0.25   ## evita que la caja "dude" entre dos marchas

var gear: int = 1
## Los pone el auto en configure(); hacen falta para saber si un rebaje pasa de vueltas.
var wheel_radius: float = 0.36
var limiter_rpm: float = 12500.0

var _since_shift: float = 0.0
var _shift_timer: float = 0.0


func configure(data: Dictionary) -> void:
	var ratios = data.get("gear_ratios", [])
	if ratios is Array and not ratios.is_empty():
		var parsed := PackedFloat32Array()
		for ratio in ratios:
			parsed.append(float(ratio))
		gear_ratios = parsed
	reverse_ratio = float(data.get("reverse_ratio", reverse_ratio))
	final_drive = float(data.get("final_drive", final_drive))
	efficiency = float(data.get("efficiency", efficiency))
	shift_time = float(data.get("shift_time", shift_time))
	shift_up_rpm = float(data.get("shift_up_rpm", shift_up_rpm))
	shift_down_rpm = float(data.get("shift_down_rpm", shift_down_rpm))
	min_shift_interval = float(data.get("min_shift_interval", min_shift_interval))
	manual = str(data.get("default_mode", "manual" if manual else "automatic")) == "manual"
	reset()


func reset() -> void:
	_since_shift = 0.0
	_shift_timer = 0.0
	if gear != 1:
		gear = 1
		gear_changed.emit(gear)


func get_gear_count() -> int:
	return gear_ratios.size()


## Relación total (caja × diferencial) de la marcha actual. 0 en neutro.
func get_total_ratio() -> float:
	return get_ratio_for(gear)


func get_ratio_for(for_gear: int) -> float:
	if for_gear == NEUTRAL:
		return 0.0
	if for_gear == REVERSE:
		return reverse_ratio * final_drive
	if gear_ratios.is_empty():
		return final_drive
	return gear_ratios[clampi(for_gear, 1, gear_ratios.size()) - 1] * final_drive


## RPM que tendría el motor en esa marcha a esa velocidad.
func rpm_at_speed(for_gear: int, speed: float) -> float:
	return absf(speed) / wheel_radius * get_ratio_for(for_gear) * 60.0 / TAU


## 1 adelante, -1 en reversa, 0 en neutro.
func get_direction() -> int:
	return signi(gear)


func get_gear_label() -> String:
	if gear == REVERSE:
		return "R"
	if gear == NEUTRAL:
		return "N"
	return str(gear)


func is_shifting() -> bool:
	return _shift_timer > 0.0


func shift_up(speed: float) -> void:
	if not manual or gear >= get_gear_count():
		return
	_try_shift(gear + 1, speed)


func shift_down(speed: float) -> void:
	if not manual or gear <= REVERSE:
		return
	_try_shift(gear - 1, speed)


func toggle_mode() -> void:
	manual = not manual
	if not manual and gear == NEUTRAL:
		_set_gear(1)
	mode_changed.emit(manual)


## Para la automática: el auto decide cuándo pasar entre 1 y R.
func select_gear(new_gear: int) -> void:
	_set_gear(clampi(new_gear, REVERSE, get_gear_count()))


func update(engine_rpm: float, delta: float) -> void:
	_shift_timer = maxf(_shift_timer - delta, 0.0)
	_since_shift += delta
	if manual or _since_shift < min_shift_interval:
		return
	if gear == NEUTRAL:
		_set_gear(1)
	elif gear >= 1:
		if engine_rpm >= shift_up_rpm and gear < get_gear_count():
			_set_gear(gear + 1)
		elif engine_rpm <= shift_down_rpm and gear > 1:
			_set_gear(gear - 1)


func _try_shift(target: int, speed: float) -> void:
	if target == REVERSE and absf(speed) > MAX_REVERSE_ENGAGE_SPEED:
		shift_denied.emit("Detené el auto para poner reversa")
		return
	if target >= 1 and rpm_at_speed(target, speed) > limiter_rpm:
		shift_denied.emit("Rebaje bloqueado: pasaría de vueltas")
		return
	_set_gear(target)


func _set_gear(new_gear: int) -> void:
	_since_shift = 0.0
	if new_gear == gear:
		return
	if new_gear != NEUTRAL:
		_shift_timer = shift_time
	gear = new_gear
	gear_changed.emit(gear)
