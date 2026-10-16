class_name TvCameras
extends Node3D
## Cámaras de TV fijas en la pista (Paso 18). Se reparten a lo largo del trazado, del lado
## de afuera de cada curva y por encima de los muros, cada una sobre un poste.
## Una sola Camera3D salta (corte) a la torre más cercana a donde va a estar el auto, lo
## sigue con look_at suavizado y ajusta el zoom para que el auto ocupe siempre lo mismo.
## Se usan cuando la cámara del auto está en el modo "Cámaras de pista" y en los replays
## (Paso 51).

signal camera_cut(index: int)

var count: int = 10
var side_offset: float = 11.0
var height: float = 7.0
var frame_width: float = 18.0     ## metros de escena que entran a lo ancho alrededor del auto
var fov_min: float = 10.0
var fov_max: float = 60.0
var switch_margin: float = 0.8    ## la nueva torre tiene que estar a menos de este % de distancia
var min_hold: float = 1.5         ## segundos mínimos en una torre antes de cortar
var look_ahead: float = 0.8       ## segundos hacia adelante para elegir torre
var look_smoothing: float = 7.0

var positions: PackedVector3Array = PackedVector3Array()
var active: bool = false
var current_index: int = -1

var _car: Node3D
var _camera: Camera3D
var _target: Vector3
var _held: float = 0.0


func _ready() -> void:
	_camera = Camera3D.new()
	_camera.name = "TvCamera"
	_camera.near = 0.5
	_camera.far = 2000.0
	add_child(_camera)


func configure(data: Dictionary) -> void:
	count = int(data.get("count", count))
	side_offset = float(data.get("side_offset", side_offset))
	height = float(data.get("height", height))
	frame_width = float(data.get("frame_width", frame_width))
	fov_min = float(data.get("fov_min", fov_min))
	fov_max = float(data.get("fov_max", fov_max))
	switch_margin = float(data.get("switch_margin", switch_margin))
	min_hold = float(data.get("min_hold", min_hold))
	look_ahead = float(data.get("look_ahead", look_ahead))
	look_smoothing = float(data.get("look_smoothing", look_smoothing))


## Ubica las torres sobre el trazado de la pista (centerline cerrada) y las arma.
func setup(centerline: PackedVector3Array, car: Node3D, start_index: int = 0) -> void:
	_car = car
	positions = PackedVector3Array()
	var n := centerline.size()
	if n < 3 or count <= 0:
		return
	for k in count:
		var i := (start_index + k * n / count) % n
		var tangent := (centerline[(i + 1) % n] - centerline[(i - 1 + n) % n]).normalized()
		var right := tangent.cross(Vector3.UP).normalized()
		# Lado de afuera de la curva: contrario a hacia donde dobla el trazado.
		var span := maxi(n / 40, 2)
		var before := (centerline[i] - centerline[(i - span + n) % n]).normalized()
		var after := (centerline[(i + span) % n] - centerline[i]).normalized()
		var turn := before.cross(after).y   # > 0 dobla a la izquierda
		var side := 1.0 if turn >= 0.0 else -1.0
		positions.append(centerline[i] + right * side * side_offset + Vector3(0, height, 0))
	_build_towers()


func set_active(enabled: bool) -> void:
	active = enabled
	if enabled and not positions.is_empty():
		_cut_to(_best_index())
		_camera.make_current()
	elif _camera.current:
		_camera.current = false


func get_camera() -> Camera3D:
	return _camera


func _process(delta: float) -> void:
	if not active or _car == null or positions.is_empty():
		return
	_held += delta
	var best := _best_index()
	if best != current_index:
		var current_distance := positions[current_index].distance_to(_predicted())
		var best_distance := positions[best].distance_to(_predicted())
		if _held >= min_hold and best_distance < current_distance * switch_margin:
			_cut_to(best)
	var aim := _car.global_position + Vector3(0, 0.5, 0)
	_target = _target.lerp(aim, clampf(look_smoothing * delta, 0.0, 1.0))
	_aim()


func _predicted() -> Vector3:
	var velocity := Vector3.ZERO
	if _car is CharacterBody3D:
		velocity = (_car as CharacterBody3D).velocity
	return _car.global_position + velocity * look_ahead


func _best_index() -> int:
	var point := _predicted()
	var best := 0
	var best_distance := INF
	for i in positions.size():
		var distance := positions[i].distance_to(point)
		if distance < best_distance:
			best_distance = distance
			best = i
	return best


func _cut_to(index: int) -> void:
	current_index = index
	_held = 0.0
	_target = _car.global_position + Vector3(0, 0.5, 0)
	_camera.global_position = positions[index]
	_aim()
	camera_cut.emit(index)


func _aim() -> void:
	var eye := _camera.global_position
	if eye.distance_to(_target) < 0.5:
		return
	_camera.look_at(_target, Vector3.UP)
	var distance := eye.distance_to(_target)
	_camera.fov = clampf(rad_to_deg(2.0 * atan(frame_width * 0.5 / distance)), fov_min, fov_max)


## Poste con una cámara arriba en cada torre (sólo decorado, sin colisión).
func _build_towers() -> void:
	for child in get_children():
		if child != _camera:
			child.queue_free()
	var pole_material := StandardMaterial3D.new()
	pole_material.albedo_color = Color(0.3, 0.32, 0.35)
	var body_material := StandardMaterial3D.new()
	body_material.albedo_color = Color(0.08, 0.08, 0.1)
	for p in positions:
		var pole := MeshInstance3D.new()
		var pole_mesh := CylinderMesh.new()
		pole_mesh.top_radius = 0.12
		pole_mesh.bottom_radius = 0.18
		pole_mesh.height = p.y - 0.6
		pole.mesh = pole_mesh
		pole.material_override = pole_material
		pole.position = Vector3(p.x, (p.y - 0.6) * 0.5, p.z)
		add_child(pole)
		var platform := MeshInstance3D.new()
		var platform_mesh := BoxMesh.new()
		platform_mesh.size = Vector3(1.4, 0.12, 1.4)
		platform.mesh = platform_mesh
		platform.material_override = pole_material
		platform.position = p + Vector3(0, -0.6, 0)
		add_child(platform)
		var body := MeshInstance3D.new()
		var body_mesh := BoxMesh.new()
		body_mesh.size = Vector3(0.35, 0.35, 0.6)
		body.mesh = body_mesh
		body.material_override = body_material
		body.position = p + Vector3(0, -0.35, 0)
		add_child(body)
