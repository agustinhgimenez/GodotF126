class_name CarController
extends CharacterBody3D
## Física arcade del monoplaza (Paso 1).
## El auto avanza sobre su eje -Z. La velocidad "de motor" (forward_speed) se
## separa de la velocidad real para poder simular agarre y derrape.

signal was_reset
signal camera_changed(mode_name: String)

## "smooth" = la cámara sigue el giro del auto con retraso; false = pegada al auto.
const CAMERA_MODES := [
	{"name": "Cámara TV", "position": Vector3(0, 2.6, 7.5), "pitch": -12.0, "fov": 70.0, "smooth": true},
	{"name": "Cámara cercana", "position": Vector3(0, 1.7, 4.8), "pitch": -8.0, "fov": 75.0, "smooth": true},
	{"name": "Cockpit", "position": Vector3(0, 0.95, -0.55), "pitch": -2.0, "fov": 80.0, "smooth": false},
]

@export_group("Motor")
@export var max_speed: float = 55.0            ## m/s (~198 km/h)
@export var max_reverse_speed: float = 12.0
@export var acceleration: float = 16.0
@export var brake_deceleration: float = 38.0
@export var reverse_acceleration: float = 8.0
@export var rolling_drag: float = 3.0

@export_group("Dirección")
@export var max_steer_rate: float = 2.4        ## rad/s a baja velocidad
@export var high_speed_steer_factor: float = 0.35
@export var steer_response: float = 8.0

@export_group("Agarre")
@export var grip: float = 9.0
@export var handbrake_grip: float = 1.2
@export var handbrake_deceleration: float = 14.0
@export var gravity: float = 25.0

@export_group("Cámara")
@export var camera_follow: float = 6.0

var forward_speed: float = 0.0
var controls_enabled: bool = true
var spawn_transform: Transform3D = Transform3D.IDENTITY

var camera_mode: int = 0

var _steer: float = 0.0

@onready var _camera_pivot: Node3D = $CameraPivot
@onready var _camera: Camera3D = $CameraPivot/Camera3D
@onready var _helmet: Node3D = $Helmet


func _ready() -> void:
	spawn_transform = global_transform
	floor_snap_length = 0.5
	_camera_pivot.top_level = true
	_apply_camera_mode()
	_snap_camera()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("change_camera"):
		cycle_camera()


func cycle_camera() -> void:
	camera_mode = (camera_mode + 1) % CAMERA_MODES.size()
	_apply_camera_mode()
	_snap_camera()
	camera_changed.emit(str(CAMERA_MODES[camera_mode]["name"]))


func _apply_camera_mode() -> void:
	var mode: Dictionary = CAMERA_MODES[camera_mode]
	var pitch := deg_to_rad(float(mode["pitch"]))
	var offset: Vector3 = mode["position"]
	var is_chase := bool(mode["smooth"])
	_camera.transform = Transform3D(Basis(Vector3.RIGHT, pitch), offset)
	_camera.fov = float(mode["fov"])
	_camera.near = 0.3 if is_chase else 0.1
	_helmet.visible = is_chase


func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("reset_car"):
		reset_to_spawn()
		return

	var throttle := 0.0
	var brake := 0.0
	var steer_input := 0.0
	var handbrake := false
	if controls_enabled:
		throttle = Input.get_action_strength("accelerate")
		brake = Input.get_action_strength("brake")
		steer_input = Input.get_axis("steer_right", "steer_left")
		handbrake = Input.is_action_pressed("handbrake")

	_update_speed(throttle, brake, handbrake, delta)
	_update_steering(steer_input, handbrake, delta)
	_apply_velocity(handbrake, delta)
	move_and_slide()
	_handle_wall_hits()
	_update_camera(delta)

	if global_position.y < -20.0:
		reset_to_spawn()


func _update_speed(throttle: float, brake: float, handbrake: bool, delta: float) -> void:
	if throttle > 0.0:
		if forward_speed < 0.0:
			forward_speed = move_toward(forward_speed, 0.0, brake_deceleration * throttle * delta)
		else:
			var ratio := clampf(forward_speed / max_speed, 0.0, 1.0)
			forward_speed += acceleration * throttle * (1.0 - ratio * 0.7) * delta
	elif brake > 0.0:
		if forward_speed > 0.5:
			forward_speed = move_toward(forward_speed, 0.0, brake_deceleration * brake * delta)
		else:
			forward_speed -= reverse_acceleration * brake * delta
	else:
		forward_speed = move_toward(forward_speed, 0.0, rolling_drag * delta)

	if handbrake:
		forward_speed = move_toward(forward_speed, 0.0, handbrake_deceleration * delta)

	forward_speed = clampf(forward_speed, -max_reverse_speed, max_speed)


func _update_steering(steer_input: float, handbrake: bool, delta: float) -> void:
	_steer = lerpf(_steer, steer_input, clampf(steer_response * delta, 0.0, 1.0))
	var speed_ratio := clampf(absf(forward_speed) / max_speed, 0.0, 1.0)
	var low_speed_factor := clampf(absf(forward_speed) / 6.0, 0.0, 1.0)
	var rate := max_steer_rate * lerpf(1.0, high_speed_steer_factor, speed_ratio) * low_speed_factor
	if handbrake:
		rate *= 1.4
	var direction := 1.0 if forward_speed >= 0.0 else -1.0
	rotate_y(_steer * rate * direction * delta)


func _apply_velocity(handbrake: bool, delta: float) -> void:
	var forward := _flat_forward()
	var desired := forward * forward_speed
	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	var current_grip := handbrake_grip if handbrake else grip
	horizontal = horizontal.lerp(desired, clampf(current_grip * delta, 0.0, 1.0))
	velocity.x = horizontal.x
	velocity.z = horizontal.z
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= gravity * delta


func _handle_wall_hits() -> void:
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		if absf(collision.get_normal().y) < 0.5:
			var actual := velocity.dot(_flat_forward())
			if absf(forward_speed) > absf(actual):
				forward_speed = lerpf(forward_speed, actual, 0.5)


func _update_camera(delta: float) -> void:
	var t := _camera_pivot.global_transform
	t.origin = global_position
	var target_basis := Basis(Vector3.UP, rotation.y)
	var weight := clampf(camera_follow * delta, 0.0, 1.0) if CAMERA_MODES[camera_mode]["smooth"] else 1.0
	t.basis = t.basis.slerp(target_basis, weight).orthonormalized()
	_camera_pivot.global_transform = t


func _snap_camera() -> void:
	_camera_pivot.global_transform = Transform3D(Basis(Vector3.UP, rotation.y), global_position)


func _flat_forward() -> Vector3:
	var forward := -global_transform.basis.z
	forward.y = 0.0
	return forward.normalized()


func reset_to_spawn() -> void:
	global_transform = spawn_transform
	velocity = Vector3.ZERO
	forward_speed = 0.0
	_steer = 0.0
	_snap_camera()
	was_reset.emit()


func get_speed_kmh() -> float:
	return Vector2(velocity.x, velocity.z).length() * 3.6


## Ángulo entre hacia dónde apunta el auto y hacia dónde se mueve (derrape).
func get_slip_angle_deg() -> float:
	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	if horizontal.length() < 3.0:
		return 0.0
	var forward := _flat_forward()
	if forward_speed < 0.0:
		forward = -forward
	return rad_to_deg(forward.angle_to(horizontal.normalized()))


func set_team_color(color: Color) -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = 0.3
	material.roughness = 0.4
	for node in find_children("*", "MeshInstance3D", true, false):
		if node.is_in_group("team_paint"):
			(node as MeshInstance3D).material_override = material
