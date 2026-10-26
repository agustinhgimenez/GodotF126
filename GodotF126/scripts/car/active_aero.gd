class_name ActiveAero
extends RefCounted
## Aerodinámica activa del reglamento 2026 (Paso 29).
## - Modo curva (normal) / modo recta: en recta los alerones se abren y bajan la carga y el
##   arrastre (factores sobre ClA y CdA). Sólo se puede dentro de las zonas de recta de la
##   pista (AeroZones escribe in_zone) y por encima de min_speed: más despacio las ruedas
##   traseras patinan y la carga que se pierde cuesta más tracción que el arrastre que se
##   ahorra. Se cierra solo al frenar, al girar fuerte o al salir de la zona (no al levantar);
##   los alerones tardan transition_time en moverse.
##   Automático: se abre a fondo con el acelerador. Manual: lo abre y cierra la tecla.
## - Modo adelantamiento: potencia eléctrica extra con un presupuesto de energía por vuelta
##   (se recarga al cruzar la línea). En 2026 sólo vale a menos de 1 s del auto de adelante.
##   TODO (rivales, Fase F): pedir esa distancia; la energía saldrá de la batería del ERS (Paso 32).

signal overtake_changed(active: bool)
## No se pudo activar el modo adelantamiento (sin energía).
signal overtake_denied(reason: String)

var cla_factor: float = 0.6        ## ClA en modo recta = cla × factor
var cda_factor: float = 0.7
var transition_time: float = 0.3   ## s que tardan los alerones en abrirse o cerrarse
var close_brake: float = 0.05      ## freno que cierra el modo recta
var close_steer: float = 0.3       ## dirección (0–1) que lo cierra
var open_throttle: float = 0.9     ## acelerador para abrirlo en automático
var min_speed: float = 120.0 / 3.6 ## m/s
var overtake_power: float = 100000.0  ## W extra
var overtake_energy: float = 500000.0 ## J por vuelta

## Lo escriben el auto (opción del jugador) y AeroZones.
var automatic: bool = true
var in_zone: bool = false

## Estado: modo recta pedido, cuánto están abiertos los alerones (0 curva – 1 recta) y
## modo adelantamiento.
var straight: bool = false
var blend: float = 0.0
var overtake_active: bool = false
var energy: float = 500000.0

var _requested: bool = false


func configure(data: Dictionary) -> void:
	var straight_data = data.get("straight_mode", {})
	if straight_data is Dictionary:
		cla_factor = clampf(float(straight_data.get("cla_factor", cla_factor)), 0.0, 1.0)
		cda_factor = clampf(float(straight_data.get("cda_factor", cda_factor)), 0.0, 1.0)
		transition_time = maxf(float(straight_data.get("transition_time", transition_time)), 0.01)
		close_brake = float(straight_data.get("close_brake", close_brake))
		close_steer = float(straight_data.get("close_steer", close_steer))
		open_throttle = float(straight_data.get("open_throttle", open_throttle))
		min_speed = float(straight_data.get("min_speed_kmh", min_speed * 3.6)) / 3.6
	var overtake_data = data.get("overtake", {})
	if overtake_data is Dictionary:
		overtake_power = float(overtake_data.get("extra_power_kw", overtake_power / 1000.0)) * 1000.0
		overtake_energy = float(overtake_data.get("energy_mj", overtake_energy / 1e6)) * 1e6
	energy = overtake_energy


## Tecla del modo recta (sólo en manual): abre si se puede, cierra si está abierto.
func toggle_straight() -> void:
	if not automatic:
		_requested = not _requested and in_zone


func toggle_overtake() -> void:
	if overtake_active:
		_set_overtake(false)
	elif energy <= 0.0:
		overtake_denied.emit("Sin energía para adelantar")
	else:
		_set_overtake(true)


## Un cuadro de física: decide el modo y mueve los alerones; gasta la energía de adelantar.
## steer en −1..1; speed en m/s; power = W que entregó el extra este cuadro.
func update(throttle: float, brake: float, steer: float, speed: float, power: float, delta: float) -> void:
	var allowed := in_zone and speed >= min_speed and brake < close_brake and absf(steer) < close_steer
	if automatic:
		straight = allowed and (straight or throttle >= open_throttle)
	else:
		_requested = _requested and allowed
		straight = _requested
	blend = move_toward(blend, 1.0 if straight else 0.0, delta / transition_time)
	if overtake_active:
		energy = maxf(energy - power * delta, 0.0)
		if energy <= 0.0:
			_set_overtake(false)


func cla_scale() -> float:
	return lerpf(1.0, cla_factor, blend)


func cda_scale() -> float:
	return lerpf(1.0, cda_factor, blend)


func energy_ratio() -> float:
	return energy / overtake_energy if overtake_energy > 0.0 else 0.0


## Nueva vuelta: energía completa para adelantar.
func refill() -> void:
	energy = overtake_energy


func reset() -> void:
	straight = false
	_requested = false
	blend = 0.0
	in_zone = false
	_set_overtake(false)


## "RECTA", "CURVA" o "RECTA LISTA" (en zona y cerrado, para el modo manual).
func mode_label() -> String:
	if blend > 0.5:
		return "RECTA"
	if in_zone:
		return "RECTA LISTA"
	return "CURVA"


func _set_overtake(active: bool) -> void:
	if overtake_active == active:
		return
	overtake_active = active
	overtake_changed.emit(active)
