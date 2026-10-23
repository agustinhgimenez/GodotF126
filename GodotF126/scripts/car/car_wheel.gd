class_name CarWheel
extends RefCounted
## Una rueda del modelo de 4 ruedas (Paso 25): suspensión por rayo y neumático simple.
## La suspensión es un resorte con precarga (la carga estática de esa rueda) más un
## amortiguador: con el auto quieto la rueda queda en `travel` y el auto a su altura de
## diseño, sin importar la rigidez. El neumático da fuerza lateral según el ángulo de deriva
## (lineal hasta `slip_peak`, después constante) y todo queda dentro del círculo de fricción.

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
## N que empuja el piso (carga vertical de la rueda).
var wheel_load: float = 0.0
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
	force = Vector2.ZERO
	slip_angle = 0.0


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


## Fuerza del neumático (N, en el mundo) con el pedido longitudinal `long_request`.
## mu: coeficiente de agarre; lateral_mu: el de costado (menos con freno de mano).
func tyre_force(long_request: float, mu: float, lateral_mu: float, slip_peak: float) -> Vector3:
	var lateral := -lateral_mu * wheel_load * clampf(slip_angle / slip_peak, -1.0, 1.0)
	var total := Vector2(long_request, lateral)
	var limit := mu * wheel_load
	if total.length() > limit:
		total = total.normalized() * limit
	force = total
	return forward * total.x + right * total.y
