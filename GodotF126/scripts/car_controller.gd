class_name CarController
extends CharacterBody3D
## Física arcade del monoplaza (Paso 1) con motor y caja como componentes (Pasos 3 y 4).
## El auto avanza sobre su eje -Z. La velocidad "de motor" (forward_speed) se
## separa de la velocidad real para poder simular agarre y derrape.
## El acelerador empuja según la marcha: adelante en 1–8, atrás en R, nada en N.
## En caja automática S con el auto quieto pone R, como en el manejo arcade original.

signal was_reset
signal camera_changed(mode_name: String)
## Choque contra un muro; strength 0–1 según la velocidad perdida (puede repetirse cada frame).
signal wall_hit(strength: float)

## "smooth" = la cámara sigue el giro del auto con retraso; false = pegada al auto.
const CAMERA_MODES := [
	{"name": "Cámara TV", "position": Vector3(0, 2.6, 7.5), "pitch": -12.0, "fov": 70.0, "smooth": true},
	{"name": "Cámara cercana", "position": Vector3(0, 1.7, 4.8), "pitch": -8.0, "fov": 75.0, "smooth": true},
	{"name": "Cockpit", "position": Vector3(0, 0.95, -0.55), "pitch": -2.0, "fov": 80.0, "smooth": false},
]

@export_group("Motor")
@export var max_speed: float = 55.0            ## m/s; se recalcula en configure() desde la última marcha
@export var max_reverse_speed: float = 12.0
@export var mass_kg: float = 800.0
@export var wheel_radius: float = 0.36
@export var traction_limit: float = 16.0       ## m/s² máximos que el agarre deja acelerar
@export var aero_drag: float = 0.0012          ## desaceleración = aero_drag × v²
@export var brake_deceleration: float = 38.0
@export var reverse_acceleration: float = 8.0  ## m/s² máximos en reversa
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

@export_group("Vibración de cámara")
@export var shake_speed_amplitude: float = 0.004   ## m de vibración a velocidad máxima
@export var shake_impact_amplitude: float = 0.03   ## m extra con un golpe de intensidad 1
@export var shake_max_roll_deg: float = 0.4
@export var shake_frequency: float = 14.0
@export var shake_impact_decay: float = 2.5        ## intensidad de golpe que se pierde por segundo
@export var shake_wall_speed: float = 15.0         ## m/s perdidos contra un muro = golpe de intensidad 1
@export var shake_shift_kick: float = 0.25         ## golpe al cambiar de marcha
@export var shake_chase_factor: float = 0.25       ## fracción que llega a las cámaras exteriores

var forward_speed: float = 0.0
var controls_enabled: bool = true
var spawn_transform: Transform3D = Transform3D.IDENTITY

var camera_mode: int = 0

var _steer: float = 0.0
var _handbrake: bool = false
var _touching_wall: bool = false
var _camera_base: Transform3D = Transform3D.IDENTITY
var _shake_noise := FastNoiseLite.new()
var _shake_time: float = 0.0
var _impact: float = 0.0

@onready var _camera_pivot: Node3D = $CameraPivot
@onready var _camera: Camera3D = $CameraPivot/Camera3D
@onready var _helmet: Node3D = $Helmet
@onready var engine: CarEngine = $Engine
@onready var gearbox: Gearbox = $Gearbox
@onready var steering_wheel: SteeringWheel = $SteeringWheel
@onready var driver_arms: DriverArms = $DriverArms
@onready var cockpit_detail: CockpitDetail = $CockpitDetail
@onready var engine_audio: EngineAudio = $EngineAudio
@onready var audio_fx: CarAudioFx = $CarAudioFx


func _ready() -> void:
	spawn_transform = global_transform
	floor_snap_length = 0.5
	_shake_noise.frequency = 1.0
	gearbox.gear_changed.connect(_on_gear_changed)
	_camera_pivot.top_level = true
	_apply_camera_mode()
	_snap_camera()
	gearbox.wheel_radius = wheel_radius
	gearbox.limiter_rpm = engine.limiter_rpm
	max_speed = get_top_speed()


## Carga los datos de data/car.json. Lo que falte queda con el valor del inspector.
func configure(data: Dictionary) -> void:
	mass_kg = float(data.get("mass_kg", mass_kg))
	wheel_radius = float(data.get("wheel_radius", wheel_radius))
	traction_limit = float(data.get("traction_limit", traction_limit))
	aero_drag = float(data.get("aero_drag", aero_drag))
	var engine_data = data.get("engine", {})
	if engine_data is Dictionary:
		engine.configure(engine_data)
	var gearbox_data = data.get("gearbox", {})
	if gearbox_data is Dictionary:
		gearbox.configure(gearbox_data)
	gearbox.wheel_radius = wheel_radius
	gearbox.limiter_rpm = engine.limiter_rpm
	max_speed = get_top_speed()
	var cockpit_data = data.get("cockpit", {})
	if cockpit_data is Dictionary:
		cockpit_detail.configure(cockpit_data)
		var shake_data = cockpit_data.get("shake", {})
		if shake_data is Dictionary:
			_configure_shake(shake_data)
	var audio_data = data.get("audio", {})
	if audio_data is Dictionary:
		engine_audio.configure(audio_data)
	var audio_fx_data = data.get("audio_fx", {})
	if audio_fx_data is Dictionary:
		audio_fx.configure(audio_fx_data)


func _configure_shake(data: Dictionary) -> void:
	shake_speed_amplitude = float(data.get("speed_amplitude", shake_speed_amplitude))
	shake_impact_amplitude = float(data.get("impact_amplitude", shake_impact_amplitude))
	shake_max_roll_deg = float(data.get("max_roll_deg", shake_max_roll_deg))
	shake_frequency = float(data.get("frequency", shake_frequency))
	shake_impact_decay = float(data.get("impact_decay", shake_impact_decay))
	shake_wall_speed = float(data.get("wall_speed", shake_wall_speed))
	shake_shift_kick = float(data.get("shift_kick", shake_shift_kick))
	shake_chase_factor = float(data.get("chase_factor", shake_chase_factor))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("change_camera"):
		cycle_camera()
	if not controls_enabled:
		return
	if event.is_action_pressed("gear_up"):
		gearbox.shift_up(forward_speed)
	elif event.is_action_pressed("gear_down"):
		gearbox.shift_down(forward_speed)
	elif event.is_action_pressed("toggle_gearbox"):
		gearbox.toggle_mode()


func cycle_camera() -> void:
	camera_mode = (camera_mode + 1) % CAMERA_MODES.size()
	_apply_camera_mode()
	_snap_camera()
	camera_changed.emit(str(CAMERA_MODES[camera_mode]["name"]))


## Auto de exhibición para los menús: sin física, sin controles, sin sonido y sin su cámara.
func set_showcase(enabled: bool) -> void:
	controls_enabled = not enabled
	set_physics_process(not enabled)
	set_process_unhandled_input(not enabled)
	engine_audio.set_muted(enabled)
	audio_fx.set_muted(enabled)
	_camera.current = not enabled


func is_cockpit_view() -> bool:
	return not bool(CAMERA_MODES[camera_mode]["smooth"])


func _apply_camera_mode() -> void:
	var mode: Dictionary = CAMERA_MODES[camera_mode]
	var pitch := deg_to_rad(float(mode["pitch"]))
	var offset: Vector3 = mode["position"]
	var is_chase := bool(mode["smooth"])
	_camera_base = Transform3D(Basis(Vector3.RIGHT, pitch), offset)
	_camera.transform = _camera_base
	_camera.fov = float(mode["fov"])
	_camera.near = 0.3 if is_chase else 0.1
	_helmet.visible = is_chase
	steering_wheel.visible = not is_chase
	driver_arms.visible = not is_chase
	cockpit_detail.set_cockpit_view(not is_chase)


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
	_handbrake = handbrake

	var pedals := _map_pedals(throttle, brake)
	_update_powertrain(pedals.x, delta)
	_update_speed(pedals.x, pedals.y, handbrake, delta)
	_update_steering(steer_input, handbrake, delta)
	_apply_velocity(handbrake, delta)
	move_and_slide()
	_handle_wall_hits()
	_update_camera(delta)

	if global_position.y < -20.0:
		reset_to_spawn()


## Devuelve (acelerador, freno) ya interpretados según la caja.
## En automática, S con el auto quieto pone R y pasa a ser el acelerador; W vuelve a 1ª.
func _map_pedals(throttle: float, brake: float) -> Vector2:
	if gearbox.manual:
		return Vector2(throttle, brake)
	if gearbox.gear >= 1 and brake > 0.0 and throttle == 0.0 and forward_speed <= 0.5:
		gearbox.select_gear(Gearbox.REVERSE)
	elif gearbox.gear == Gearbox.REVERSE and throttle > 0.0 and brake == 0.0 and forward_speed >= -0.5:
		gearbox.select_gear(1)
	if gearbox.gear == Gearbox.REVERSE:
		return Vector2(brake, throttle)
	return Vector2(throttle, brake)


func _update_powertrain(throttle: float, delta: float) -> void:
	var gear := gearbox.gear
	engine.update(_wheel_rpm(), throttle, absi(gear) == 1, gear == Gearbox.NEUTRAL, delta)
	gearbox.update(engine.rpm, delta)


func _update_speed(throttle: float, brake: float, handbrake: bool, delta: float) -> void:
	var direction := float(gearbox.get_direction())
	if brake > 0.0:
		forward_speed = move_toward(forward_speed, 0.0, brake_deceleration * brake * delta)
	if throttle > 0.0 and direction != 0.0:
		if forward_speed * direction < -0.1:
			# Rodando para el lado contrario a la marcha: el acelerador frena (arcade).
			forward_speed = move_toward(forward_speed, 0.0, brake_deceleration * throttle * delta)
		else:
			forward_speed += direction * _drive_acceleration() * delta
	elif brake == 0.0:
		var coast_decel := rolling_drag
		if direction != 0.0 and forward_speed * direction > 0.0:
			coast_decel += engine.get_engine_brake_accel()
		forward_speed = move_toward(forward_speed, 0.0, coast_decel * delta)

	forward_speed = move_toward(forward_speed, 0.0, aero_drag * forward_speed * forward_speed * delta)

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
	_touching_wall = false
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		if absf(collision.get_normal().y) < 0.5:
			_touching_wall = true
			var actual := velocity.dot(_flat_forward())
			if absf(forward_speed) > absf(actual):
				var strength := (absf(forward_speed) - absf(actual)) / shake_wall_speed
				add_camera_impact(strength)
				wall_hit.emit(clampf(strength, 0.0, 1.0))
				forward_speed = lerpf(forward_speed, actual, 0.5)


func _update_camera(delta: float) -> void:
	var t := _camera_pivot.global_transform
	t.origin = global_position
	var target_basis := Basis(Vector3.UP, rotation.y)
	var weight := clampf(camera_follow * delta, 0.0, 1.0) if CAMERA_MODES[camera_mode]["smooth"] else 1.0
	t.basis = t.basis.slerp(target_basis, weight).orthonormalized()
	_camera_pivot.global_transform = t
	_update_shake(delta)


## Vibración: crece con el cuadrado de la velocidad y suma los golpes (muros, cambios;
## los pianos del Paso 19 también van a llamar a add_camera_impact()).
func _update_shake(delta: float) -> void:
	_shake_time += delta
	_impact = move_toward(_impact, 0.0, shake_impact_decay * delta)
	var speed_part := pow(clampf(absf(forward_speed) / max_speed, 0.0, 1.0), 2.0)
	var impact_part := _impact * _impact
	var factor := shake_chase_factor if CAMERA_MODES[camera_mode]["smooth"] else 1.0
	var amount := (shake_speed_amplitude * speed_part + shake_impact_amplitude * impact_part) * factor
	var roll_amount := deg_to_rad(shake_max_roll_deg) * minf(speed_part * 0.5 + impact_part, 1.0) * factor
	var n := _shake_time * shake_frequency
	var offset := Vector3(_shake_noise.get_noise_2d(n, 0.0), _shake_noise.get_noise_2d(n, 100.0), 0.0) * amount
	var roll := _shake_noise.get_noise_2d(n, 200.0) * roll_amount
	_camera.transform = _camera_base * Transform3D(Basis(Vector3.BACK, roll), offset)


## Golpe de cámara de intensidad 0–1 que se desvanece solo.
func add_camera_impact(strength: float) -> void:
	_impact = clampf(maxf(_impact, strength), 0.0, 1.0)


func _on_gear_changed(_gear: int) -> void:
	if absf(forward_speed) > 3.0:
		add_camera_impact(shake_shift_kick)


func _snap_camera() -> void:
	_camera_pivot.global_transform = Transform3D(Basis(Vector3.UP, rotation.y), global_position)


## RPM que impone la velocidad de las ruedas a través de la marcha actual.
func _wheel_rpm() -> float:
	var wheel_rad_per_s := absf(forward_speed) / wheel_radius
	return wheel_rad_per_s * gearbox.get_total_ratio() * 60.0 / TAU


func _drive_acceleration() -> float:
	if gearbox.is_shifting():
		return 0.0
	var wheel_torque := engine.get_output_torque() * gearbox.get_total_ratio() * gearbox.efficiency
	var force := wheel_torque / wheel_radius
	var limit := traction_limit if gearbox.gear >= 1 else reverse_acceleration
	return minf(force / mass_kg, limit)


func _flat_forward() -> Vector3:
	var forward := -global_transform.basis.z
	forward.y = 0.0
	return forward.normalized()


func reset_to_spawn() -> void:
	global_transform = spawn_transform
	velocity = Vector3.ZERO
	forward_speed = 0.0
	_steer = 0.0
	_impact = 0.0
	engine.reset()
	gearbox.reset()
	_snap_camera()
	was_reset.emit()


func get_speed_kmh() -> float:
	return Vector2(velocity.x, velocity.z).length() * 3.6


## Velocidad (m/s) con el motor en el limitador en la última marcha.
func get_top_speed() -> float:
	var top_ratio := gearbox.get_ratio_for(gearbox.get_gear_count())
	return engine.limiter_rpm * TAU / 60.0 / top_ratio * wheel_radius


func get_rpm() -> float:
	return engine.rpm


## Dirección suavizada: −1 (derecha) a 1 (izquierda).
func get_steer() -> float:
	return _steer


func get_gear_label() -> String:
	return gearbox.get_gear_label()


func is_handbrake_on() -> bool:
	return _handbrake


func is_touching_wall() -> bool:
	return _touching_wall


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
