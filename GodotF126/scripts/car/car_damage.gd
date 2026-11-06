class_name CarDamage
extends RefCounted
## Daños (Paso 36; datos en "damage" de data/car.json). Los golpes contra los muros llegan de
## CarController._integrate_forces() con el punto de contacto (en coordenadas del auto) y su
## intensidad (velocidad perdida contra el muro / shake_wall_speed, la misma de wall_hit):
## - Alerón delantero: un golpe con la trompa (contacto más adelante que wing_zone_z) por
##   encima de wing_min_impact le saca wing_per_impact × (golpe − mínimo) de salud. El eje
##   delantero pierde hasta wing_downforce_loss de su carga aerodinámica (con salud 0); con
##   salud ≤ wing_broken_health el alerón se cae.
## - Pinchazos: un golpe de costado por encima de puncture_min_impact a menos de
##   puncture_radius (en planta) de una rueda la pincha; también un neumático gastado del todo.
##   La rueda pinchada agarra puncture_grip, frena con puncture_drag_n y esa esquina baja
##   puncture_drop.
## repair() (al volver a boxes con reset_to_spawn()) deja todo nuevo.

signal wing_damaged(health: float)
signal punctured(wheel_index: int)
signal repaired

var wing_min_impact: float = 0.25
var wing_per_impact: float = 2.0
var wing_zone_z: float = -2.3
var wing_downforce_loss: float = 0.7
var wing_broken_health: float = 0.25
var puncture_min_impact: float = 0.3
var puncture_radius: float = 0.7
var puncture_grip: float = 0.35
var puncture_drag_n: float = 1500.0
var puncture_drop: float = 0.035
var wear_puncture: bool = true

## Salud del alerón delantero: 1 = nuevo, 0 = destruido.
var wing_health: float = 1.0
## Mismo orden que CarController.wheels (DI, DD, TI, TD).
var punctures: Array[bool] = [false, false, false, false]


func configure(data: Dictionary) -> void:
	wing_min_impact = maxf(float(data.get("wing_min_impact", wing_min_impact)), 0.0)
	wing_per_impact = maxf(float(data.get("wing_per_impact", wing_per_impact)), 0.0)
	wing_zone_z = float(data.get("wing_zone_z", wing_zone_z))
	wing_downforce_loss = clampf(float(data.get("wing_downforce_loss", wing_downforce_loss)), 0.0, 1.0)
	wing_broken_health = clampf(float(data.get("wing_broken_health", wing_broken_health)), 0.0, 1.0)
	puncture_min_impact = maxf(float(data.get("puncture_min_impact", puncture_min_impact)), 0.0)
	puncture_radius = maxf(float(data.get("puncture_radius", puncture_radius)), 0.0)
	puncture_grip = clampf(float(data.get("puncture_grip", puncture_grip)), 0.05, 1.0)
	puncture_drag_n = maxf(float(data.get("puncture_drag_n", puncture_drag_n)), 0.0)
	puncture_drop = maxf(float(data.get("puncture_drop", puncture_drop)), 0.0)
	wear_puncture = bool(data.get("wear_puncture", wear_puncture))


## Golpes contra muros de un cuadro: `points` (coordenadas del auto) con la intensidad de cada
## uno. El alerón toma sólo el golpe más fuerte del cuadro en la trompa (un choque suele
## tener varios puntos de contacto). `wheel_points`: centro de cada rueda (coordenadas del auto).
func on_impacts(points: PackedVector3Array, strengths: PackedFloat32Array, wheel_points: Array[Vector3]) -> void:
	var nose := 0.0
	for k in points.size():
		var point := points[k]
		if point.z < wing_zone_z:
			nose = maxf(nose, strengths[k])
		if strengths[k] <= puncture_min_impact:
			continue
		for i in mini(wheel_points.size(), punctures.size()):
			if Vector2(point.x - wheel_points[i].x, point.z - wheel_points[i].z).length() <= puncture_radius:
				puncture(i)
	if nose > wing_min_impact and wing_health > 0.0:
		wing_health = maxf(wing_health - wing_per_impact * (nose - wing_min_impact), 0.0)
		wing_damaged.emit(wing_health)


func puncture(index: int) -> void:
	if index < 0 or index >= punctures.size() or punctures[index]:
		return
	punctures[index] = true
	punctured.emit(index)


func repair() -> void:
	var was_damaged := is_damaged()
	wing_health = 1.0
	for i in punctures.size():
		punctures[i] = false
	if was_damaged:
		repaired.emit()


func is_damaged() -> bool:
	return wing_health < 1.0 or punctures.has(true)


func is_wing_broken() -> bool:
	return wing_health <= wing_broken_health


func is_punctured(index: int) -> bool:
	return index >= 0 and index < punctures.size() and punctures[index]


## Multiplica la carga aerodinámica del eje delantero.
func front_downforce_factor() -> float:
	return 1.0 - wing_downforce_loss * (1.0 - wing_health)


## Multiplica el μ de la rueda.
func grip_factor(index: int) -> float:
	return puncture_grip if is_punctured(index) else 1.0


## Nombre de la rueda para los mensajes.
static func wheel_name(index: int) -> String:
	return ["delantero izquierdo", "delantero derecho", "trasero izquierdo", "trasero derecho"][clampi(index, 0, 3)]
