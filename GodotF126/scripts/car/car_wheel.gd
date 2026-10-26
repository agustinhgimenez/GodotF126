class_name CarWheel
extends RefCounted
## Una rueda del modelo de 4 ruedas: suspensión por rayo (Paso 25) y neumático (Paso 26).
## La suspensión es un resorte con precarga (la carga estática de esa rueda) más un
## amortiguador: con el auto quieto la rueda queda en `travel` y el auto a su altura de
## diseño, sin importar la rigidez. La rueda tiene su propio giro (`spin`): el motor y los
## frenos le aplican par, el neumático (TyreModel) la frena o la arrastra, y la diferencia
## entre su velocidad y la del piso es el deslizamiento longitudinal.

## Tope de carga (× la estática): un rayo que salta de golpe (borde de un muro, piano) no
## dispara al auto por el aire.
const MAX_LOAD_FACTOR := 6.0

## Coordenadas del auto: anclaje arriba del recorrido de la suspensión.
var mount: Vector3
var front: bool
var mesh: Node3D
## Orientación original del modelo de la rueda (el cilindro acostado).
var mesh_basis: Basis = Basis.IDENTITY
## N que soporta esta rueda con el auto quieto (precarga del resorte).
var static_load: float = 2000.0
## rad; positivo gira a la izquierda (sólo las delanteras).
var steer_angle: float = 0.0

var in_contact: bool = false
## Largo actual de la suspensión: 0 = a tope, travel = reposo, 2 × travel = colgando.
var length: float = 0.0
## N que empuja el piso (carga vertical de la rueda): resorte + amortiguador + barra
## estabilizadora + anti-cabeceo.
var wheel_load: float = 0.0
## N de la carga que llega por los brazos (anti-cabeceo) y no por el resorte.
var link_force: float = 0.0
var contact_point: Vector3 = Vector3.ZERO
var contact_normal: Vector3 = Vector3.UP
## Ejes de la rueda en el mundo (sobre el plano del piso).
var forward: Vector3 = Vector3.FORWARD
var right: Vector3 = Vector3.RIGHT
var up: Vector3 = Vector3.UP
var long_speed: float = 0.0
var lat_speed: float = 0.0
## rad; positivo = la rueda se desliza hacia su derecha.
var slip_angle: float = 0.0
## rad/s de la rueda (positivo = rodando hacia adelante).
var spin: float = 0.0
## Ángulo acumulado del giro (para el modelo).
var spin_angle: float = 0.0
## κ = (ω·r − v) / v: positivo patina acelerando, −1 bloqueada.
var slip_ratio: float = 0.0
## (longitudinal, lateral) en N que el neumático le hizo al auto en el último cuadro.
var force: Vector2 = Vector2.ZERO

var _query: PhysicsRayQueryParameters3D


func _init(mount_point: Vector3, is_front: bool, wheel_mesh: Node3D) -> void:
	mount = mount_point
	front = is_front
	mesh = wheel_mesh
	if mesh:
		mesh_basis = mesh.transform.basis
	_query = PhysicsRayQueryParameters3D.new()


func reset(travel: float) -> void:
	in_contact = false
	length = travel
	wheel_load = 0.0
	link_force = 0.0
	force = Vector2.ZERO
	slip_angle = 0.0
	slip_ratio = 0.0
	spin = 0.0


## Tira el rayo (sin pegarle al propio auto) y calcula la carga.
func update_suspension(body: RigidBody3D, space: PhysicsDirectSpaceState3D, travel: float,
		radius: float, stiffness: float, damping: float, delta: float) -> void:
	var t := body.global_transform
	up = t.basis.y.normalized()
	var from := t * mount
	_query.from = from
	_query.to = from - up * (travel * 2.0 + radius)
	_query.exclude = [body.get_rid()]
	var hit := space.intersect_ray(_query)
	if hit.is_empty():
		in_contact = false
		length = travel * 2.0
		wheel_load = 0.0
		force = Vector2.ZERO
		return
	contact_point = hit["position"]
	contact_normal = hit["normal"]
	var new_length := from.distance_to(contact_point) - radius
	var extension_speed := (new_length - length) / delta if in_contact else 0.0
	in_contact = true
	length = new_length
	wheel_load = static_load + stiffness * (travel - length) - damping * extension_speed
	if length < 0.0:
		wheel_load += stiffness * 10.0 * -length
	wheel_load = clampf(wheel_load, 0.0, static_load * MAX_LOAD_FACTOR)


## Ejes de la rueda y velocidades del punto de contacto. `velocity`: la del auto en ese punto.
func measure(body_basis: Basis, velocity: Vector3, slip_floor: float) -> void:
	var heading := (body_basis * Basis(Vector3.UP, steer_angle)) * Vector3.FORWARD
	forward = (heading - contact_normal * heading.dot(contact_normal)).normalized()
	right = forward.cross(contact_normal).normalized()
	long_speed = velocity.dot(forward)
	lat_speed = velocity.dot(right)
	slip_angle = atan2(lat_speed, maxf(absf(long_speed), slip_floor))


## Integra el giro de la rueda y devuelve la fuerza del neumático (N, en el mundo).
## drive_torque: N·m del motor (con signo); brake_torque: N·m que se oponen al giro (frenos,
## freno motor, rodadura). limit_drive / limit_brake: no dejan pasar κ del pico (provisorio
## hasta los Pasos 30 y 31). La rueda se integra en forma implícita (con la pendiente de la
## curva): una rueda liviana contra un neumático rígido oscilaría.
func update_tyre(tyre: TyreModel, mu: float, drive_torque: float, brake_torque: float, radius: float,
		limit_drive: bool, limit_brake: bool, delta: float) -> Vector3:
	var grip := mu * tyre.load_factor(wheel_load, static_load) * wheel_load
	var v_ref := maxf(absf(long_speed), tyre.slip_floor)
	slip_ratio = (spin * radius - long_speed) / v_ref
	var now := tyre.forces(slip_ratio, slip_angle, grip)
	var ahead := tyre.forces(slip_ratio + 0.01, slip_angle, grip)
	var slope := maxf((ahead.x - now.x) / 0.01, 0.0) * radius * radius / v_ref
	var inertia := tyre.wheel_inertia + slope * delta
	spin += (drive_torque - now.x * radius) * delta / inertia
	spin = move_toward(spin, 0.0, brake_torque * delta / inertia)

	var rolling := long_speed / radius
	var max_slip := tyre.slip_ratio_peak * v_ref / radius
	if limit_drive and drive_torque > 0.0:
		spin = minf(spin, rolling + max_slip)
	elif limit_drive and drive_torque < 0.0:
		spin = maxf(spin, rolling - max_slip)
	if limit_brake and brake_torque > 0.0:
		spin = maxf(spin, rolling - max_slip) if rolling > 0.0 else minf(spin, rolling + max_slip)

	slip_ratio = (spin * radius - long_speed) / v_ref
	var result := tyre.forces(slip_ratio, slip_angle, grip)
	force = result
	spin_angle = wrapf(spin_angle + spin * delta, 0.0, TAU)
	return forward * result.x + right * result.y


## Rueda en el aire: sólo los pares del motor y los frenos.
func update_free_spin(inertia: float, drive_torque: float, brake_torque: float, delta: float) -> void:
	spin += drive_torque * delta / inertia
	spin = move_toward(spin, 0.0, brake_torque * delta / inertia)
	slip_ratio = 0.0
	spin_angle = wrapf(spin_angle + spin * delta, 0.0, TAU)
