class_name CarController
extends RigidBody3D
## Monoplaza con modelo de 4 ruedas (Paso 25): cuerpo rígido con masa, centro de masa e
## inercia; cada rueda (CarWheel) es un rayo con resorte y amortiguador, y su neumático
## (TyreModel, Pacejka, Paso 26) empuja en el punto de contacto según la deriva y el
## deslizamiento. Motor y caja son componentes (Pasos 3 y 4): el par llega a las ruedas
## traseras según la marcha (adelante en 1–8, atrás en R, nada en N) y las RPM salen del
## giro de esas ruedas.
## El auto avanza sobre su eje -Z. En caja automática S con el auto quieto pone R.

signal was_reset
signal camera_changed(mode_name: String)
## Choque contra un muro; strength 0–1 según la velocidad perdida (puede repetirse cada frame).
signal wall_hit(strength: float)

## Cámara del auto (o de la pista) activa: true = cámaras de TV de la pista (Paso 18).
signal camera_mode_applied(external: bool)

## "view": chase = sigue el giro del auto con retraso; onboard = pegada al auto (T-cam, capot);
## cockpit = pegada al auto con volante, brazos, espejos y casco; external = cámaras de TV
## fijas de la pista (las maneja TvCameras, la cámara del auto se apaga).
## "shake": fracción de la vibración en las cámaras pegadas (las chase usan shake_chase_factor).
## Los índices 0–2 son los del Paso 2 (quedan guardados en user://settings.json).
const CAMERA_MODES := [
	{"name": "Cámara TV", "position": Vector3(0, 2.6, 7.5), "pitch": -12.0, "fov": 70.0, "view": "chase"},
	{"name": "Cámara cercana", "position": Vector3(0, 1.7, 4.8), "pitch": -8.0, "fov": 75.0, "view": "chase"},
	{"name": "Cockpit", "position": Vector3(0, 0.95, -0.55), "pitch": -2.0, "fov": 80.0, "view": "cockpit", "shake": 1.0},
	{"name": "T-cam", "position": Vector3(0, 1.3, 0.75), "pitch": -6.0, "fov": 72.0, "view": "onboard", "shake": 0.7},
	{"name": "Cámara de capot", "position": Vector3(0, 0.86, -1.95), "pitch": -4.0, "fov": 75.0, "view": "onboard", "shake": 0.8},
	{"name": "Cámaras de pista", "view": "external"},
]
## Par del freno de mano en las traseras: × lo que puede agarrar la rueda (siempre bloquea).
const MAX_HANDBRAKE_FACTOR := 3.0
## Sub-pasos de los neumáticos por cuadro de física: la curva de Pacejka es rígida y a 60 Hz
## el auto oscilaría a baja velocidad.
const TYRE_SUBSTEPS := 8
## Nodo de la rueda, lado (−1 izq., +1 der.), delantera.
const WHEEL_NODES := [["WheelFL", -1.0, true], ["WheelFR", 1.0, true], ["WheelRL", -1.0, false], ["WheelRR", 1.0, false]]
## Bloque "chassis" de data/car.json: grupo → {clave del JSON: propiedad}.
const CHASSIS_KEYS := {
	"suspension": {"front_axle_z": "front_axle_z", "rear_axle_z": "rear_axle_z", "half_track": "half_track",
		"travel": "suspension_travel", "stiffness": "spring_stiffness", "damping": "damper"},
	"tyres": {"mu": "tyre_mu", "rear_grip_factor": "rear_grip_factor"},
	"brakes": {"force": "brake_force", "front_share": "brake_front_share"},
	"steering": {"max_deg": "max_steer_deg", "min_deg": "min_steer_deg"},
}

@export_group("Motor")
@export var max_speed: float = 55.0            ## m/s; se recalcula en configure() desde la última marcha
@export var max_reverse_speed: float = 12.0
@export var mass_kg: float = 800.0
@export var wheel_radius: float = 0.36
@export var aero_drag: float = 0.0012          ## desaceleración = aero_drag × v²
@export var reverse_acceleration: float = 8.0  ## m/s² máximos en reversa
@export var rolling_resistance: float = 0.25   ## m/s² de rodadura

@export_group("Dirección")
@export var max_steer_deg: float = 22.0        ## giro de las ruedas a baja velocidad
@export var min_steer_deg: float = 3.0
## Multiplica el giro máximo según la velocidad (1 = cerca del máximo agarre; Settings).
@export var steer_limit: float = 1.0
@export var steer_response: float = 8.0

@export_group("Suspensión")
@export var front_axle_z: float = -1.8
@export var rear_axle_z: float = 1.6
@export var half_track: float = 0.85
@export var suspension_travel: float = 0.12   ## m de recorrido para cada lado del reposo
@export var spring_stiffness: float = 70000.0 ## N/m
@export var damper: float = 3800.0            ## N·s/m

@export_group("Neumáticos y frenos")
@export var tyre_mu: float = 2.3               ## incluye una carga aerodinámica promedio hasta el Paso 28
@export var rear_grip_factor: float = 1.08
@export var brake_force: float = 30000.0       ## N totales con el freno a fondo (en el piso, sin bloquear)
@export var brake_front_share: float = 0.58
## Provisorios hasta el ABS (Paso 30) y el control de tracción (Paso 31): no dejan que las
## ruedas pasen del deslizamiento de pico al frenar o al acelerar.
@export var brake_limiter: bool = true
@export var traction_limiter: bool = true

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

## m/s a lo largo del auto (negativo = marcha atrás); lo leen la caja, el motor y el audio.
var forward_speed: float = 0.0
var controls_enabled: bool = true
## 0–1: cuánto está pisando un piano (lo escribe TrackLimits; lo usa CarAudioFx).
var kerb_contact: float = 0.0
var spawn_transform: Transform3D = Transform3D.IDENTITY
var wheels: Array[CarWheel] = []
var tyre := TyreModel.new()

var camera_mode: int = 0

var _steer: float = 0.0
var _handbrake: bool = false
var _touching_wall: bool = false
var _last_velocity: Vector3 = Vector3.ZERO
var _camera_base: Transform3D = Transform3D.IDENTITY
var _shake_noise := FastNoiseLite.new()
var _shake_time: float = 0.0
var _impact: float = 0.0
var _showcase: bool = false

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
@onready var livery: CarLivery = $Livery


func _ready() -> void:
	spawn_transform = global_transform
	_shake_noise.frequency = 1.0
	gearbox.gear_changed.connect(_on_gear_changed)
	_camera_pivot.top_level = true
	_apply_camera_mode()
	_snap_camera()
	gearbox.wheel_radius = wheel_radius
	gearbox.limiter_rpm = engine.limiter_rpm
	max_speed = get_top_speed()
	_build_wheels()


## Carga los datos de data/car.json. Lo que falte queda con el valor del inspector.
func configure(data: Dictionary) -> void:
	mass_kg = float(data.get("mass_kg", mass_kg))
	wheel_radius = float(data.get("wheel_radius", wheel_radius))
	aero_drag = float(data.get("aero_drag", aero_drag))
	var chassis_data = data.get("chassis", {})
	if chassis_data is Dictionary:
		_configure_chassis(chassis_data)
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
	_build_wheels()


func _configure_chassis(data: Dictionary) -> void:
	center_of_mass = _vec3(data.get("center_of_mass", []), center_of_mass)
	inertia = _vec3(data.get("inertia", []), inertia)
	rolling_resistance = float(data.get("rolling_resistance", rolling_resistance))
	reverse_acceleration = float(data.get("reverse_acceleration", reverse_acceleration))
	for group in CHASSIS_KEYS:
		var values = data.get(group, {})
		if not values is Dictionary:
			continue
		var keys: Dictionary = CHASSIS_KEYS[group]
		for key in keys:
			if values.has(key):
				set(keys[key], float(values[key]))
	var tyre_data = data.get("tyres", {})
	if tyre_data is Dictionary:
		tyre.configure(tyre_data)
	var limiters = data.get("limiters", {})
	if limiters is Dictionary:
		brake_limiter = bool(limiters.get("brake", brake_limiter))
		traction_limiter = bool(limiters.get("traction", traction_limiter))


func _configure_shake(data: Dictionary) -> void:
	shake_speed_amplitude = float(data.get("speed_amplitude", shake_speed_amplitude))
	shake_impact_amplitude = float(data.get("impact_amplitude", shake_impact_amplitude))
	shake_max_roll_deg = float(data.get("max_roll_deg", shake_max_roll_deg))
	shake_frequency = float(data.get("frequency", shake_frequency))
	shake_impact_decay = float(data.get("impact_decay", shake_impact_decay))
	shake_wall_speed = float(data.get("wall_speed", shake_wall_speed))
	shake_shift_kick = float(data.get("shift_kick", shake_shift_kick))
	shake_chase_factor = float(data.get("chase_factor", shake_chase_factor))


## Arma las 4 ruedas y reparte el peso entre los ejes según el centro de masa.
func _build_wheels() -> void:
	mass = mass_kg
	center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
	var wheelbase := rear_axle_z - front_axle_z
	var front_share := clampf((rear_axle_z - center_of_mass.z) / wheelbase, 0.1, 0.9)
	var weight := mass * _gravity()
	wheels.clear()
	for spec in WHEEL_NODES:
		var is_front: bool = spec[2]
		var mount := Vector3(float(spec[1]) * half_track, wheel_radius + suspension_travel,
			front_axle_z if is_front else rear_axle_z)
		var wheel := CarWheel.new(mount, is_front, get_node_or_null(str(spec[0])) as Node3D)
		wheel.static_load = weight * (front_share if is_front else 1.0 - front_share) * 0.5
		wheel.reset(suspension_travel)
		wheels.append(wheel)


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


## Cámara inicial (opciones); no muestra el aviso de cambio de cámara.
func set_camera_mode(mode: int) -> void:
	camera_mode = clampi(mode, 0, CAMERA_MODES.size() - 1)
	_apply_camera_mode()
	_snap_camera()


## Auto de exhibición para los menús: congelado, sin controles, sin sonido y sin su cámara.
func set_showcase(enabled: bool) -> void:
	_showcase = enabled
	controls_enabled = not enabled
	freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	freeze = enabled
	set_physics_process(not enabled)
	set_process_unhandled_input(not enabled)
	engine_audio.set_muted(enabled)
	audio_fx.set_muted(enabled)
	_camera.current = not enabled


func _camera_view() -> String:
	return str(CAMERA_MODES[camera_mode]["view"])


func is_cockpit_view() -> bool:
	return _camera_view() == "cockpit"


## Cámaras pegadas al auto (cockpit, T-cam, capot): el sonido se oye "de adentro".
func is_onboard_view() -> bool:
	return _camera_view() == "cockpit" or _camera_view() == "onboard"


func uses_external_camera() -> bool:
	return _camera_view() == "external"


func _apply_camera_mode() -> void:
	var mode: Dictionary = CAMERA_MODES[camera_mode]
	var view := _camera_view()
	var cockpit := view == "cockpit"
	if view != "external":
		var pitch := deg_to_rad(float(mode["pitch"]))
		var offset: Vector3 = mode["position"]
		_camera_base = Transform3D(Basis(Vector3.RIGHT, pitch), offset)
		_camera.transform = _camera_base
		_camera.fov = float(mode["fov"])
		_camera.near = 0.3 if view == "chase" else 0.1
	if not _showcase:
		_camera.current = view != "external"
	_helmet.visible = not cockpit
	steering_wheel.visible = cockpit
	driver_arms.visible = cockpit
	cockpit_detail.set_cockpit_view(cockpit)
	camera_mode_applied.emit(view == "external")


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
	forward_speed = linear_velocity.dot(_flat_forward())

	var pedals := _map_pedals(throttle, brake)
	_update_powertrain(pedals.x, delta)
	_update_steering(steer_input, delta)
	_apply_wheel_forces(pedals.x, pedals.y, handbrake, delta)
	apply_central_force(-linear_velocity * linear_velocity.length() * aero_drag * mass)
	_update_wheel_meshes()
	_update_camera(delta)

	if global_position.y < -20.0:
		reset_to_spawn()


## Golpes contra muros: velocidad perdida contra la normal de cada contacto casi vertical
## desde el paso anterior.
func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	var touching := false
	var strongest := 0.0
	var lost := _last_velocity - state.linear_velocity
	for i in state.get_contact_count():
		var normal := state.get_contact_local_normal(i)
		if absf(normal.y) < 0.5:
			touching = true
			strongest = maxf(strongest, absf(lost.dot(normal)))
	_last_velocity = state.linear_velocity
	_touching_wall = touching
	if strongest > 1.0:
		var strength := strongest / shake_wall_speed
		add_camera_impact(strength)
		wall_hit.emit(clampf(strength, 0.0, 1.0))


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


## El giro máximo de las ruedas baja con la velocidad: el que da el máximo agarre en una
## curva (distancia entre ejes / radio) más el ángulo de deriva de pico.
func _update_steering(steer_input: float, delta: float) -> void:
	_steer = lerpf(_steer, steer_input, clampf(steer_response * delta, 0.0, 1.0))
	var speed := absf(forward_speed)
	var wheelbase := rear_axle_z - front_axle_z
	var limit := atan(wheelbase * tyre_mu * _gravity() / maxf(speed * speed, 0.01)) + tyre.slip_angle_peak
	limit = clampf(limit * steer_limit, deg_to_rad(min_steer_deg), deg_to_rad(max_steer_deg))
	for wheel in wheels:
		wheel.steer_angle = _steer * limit if wheel.front else 0.0


## Suspensión y neumático de cada rueda. Pares sobre cada rueda: el motor en las traseras
## (mitad cada una), los frenos repartidos entre los ejes, rodadura y freno motor; con freno
## de mano las traseras se bloquean (y al patinar casi no agarran de costado).
## Los neumáticos se calculan en TYRE_SUBSTEPS sub-pasos: en cada uno se predice cómo cambian
## la velocidad y el giro del auto con esas fuerzas, y al cuerpo se le aplica el promedio.
func _apply_wheel_forces(throttle: float, brake: float, handbrake: bool, delta: float) -> void:
	var space := get_world_3d().direct_space_state
	var center := global_transform * center_of_mass
	var corner_mass := mass * 0.25
	var drive_torque := _drive_force(throttle) * wheel_radius * 0.5
	var engine_brake := 0.0
	var direction := float(gearbox.get_direction())
	if throttle == 0.0 and direction != 0.0 and forward_speed * direction > 0.0:
		engine_brake = engine.get_engine_brake_accel() * mass * wheel_radius * 0.5
	var grounded: Array[CarWheel] = []
	var torques: Array[Vector3] = []
	for wheel in wheels:
		wheel.update_suspension(self, space, suspension_travel, wheel_radius, spring_stiffness, damper, delta)
		var mu := tyre_mu * (1.0 if wheel.front else rear_grip_factor)
		var share := brake_front_share if wheel.front else 1.0 - brake_front_share
		var brake_torque := (brake_force * brake * share * 0.5 + rolling_resistance * corner_mass) * wheel_radius
		var torque := 0.0
		var locked := false
		if not wheel.front:
			torque = drive_torque
			brake_torque += engine_brake
			if handbrake:
				brake_torque += mu * wheel.static_load * MAX_HANDBRAKE_FACTOR * wheel_radius
				locked = true
		if not wheel.in_contact:
			wheel.update_free_spin(tyre.wheel_inertia, torque, brake_torque, delta)
			continue
		apply_force(wheel.up * wheel.wheel_load, wheel.contact_point - global_position)
		grounded.append(wheel)
		# (μ, par del motor, par de frenado); el freno de mano no pasa por el limitador.
		torques.append(Vector3(mu, torque, brake_torque if not locked else -brake_torque))
	if grounded.is_empty():
		return

	var basis_now := global_transform.basis
	var inverse_inertia := PhysicsServer3D.body_get_direct_state(get_rid()).inverse_inertia_tensor
	var velocity := linear_velocity
	var spin := angular_velocity
	var h := delta / TYRE_SUBSTEPS
	var total_force := Vector3.ZERO
	var total_torque := Vector3.ZERO
	for step in TYRE_SUBSTEPS:
		var step_force := Vector3.ZERO
		var step_torque := Vector3.ZERO
		for i in grounded.size():
			var wheel := grounded[i]
			var arm := wheel.contact_point - center
			wheel.measure(basis_now, velocity + spin.cross(arm), tyre.slip_floor)
			var t := torques[i]
			var force := wheel.update_tyre(tyre, t.x, t.y, absf(t.z), wheel_radius,
				traction_limiter, brake_limiter and t.z >= 0.0, h)
			step_force += force
			step_torque += arm.cross(force)
		velocity += step_force / mass * h
		spin += inverse_inertia * step_torque * h
		total_force += step_force
		total_torque += step_torque
	apply_central_force(total_force / TYRE_SUBSTEPS)
	apply_torque(total_torque / TYRE_SUBSTEPS)


## N de empuje entre las dos ruedas traseras (negativo en R).
func _drive_force(throttle: float) -> float:
	var direction := float(gearbox.get_direction())
	if throttle <= 0.0 or direction == 0.0 or gearbox.is_shifting():
		return 0.0
	if direction < 0.0 and forward_speed < -max_reverse_speed:
		return 0.0
	var wheel_torque := engine.get_output_torque() * gearbox.get_total_ratio() * gearbox.efficiency
	var force := wheel_torque / wheel_radius
	if direction < 0.0:
		force = minf(force, reverse_acceleration * mass)
	return force * direction


## Las ruedas siguen la suspensión y las delanteras giran con la dirección.
func _update_wheel_meshes() -> void:
	for wheel in wheels:
		if wheel.mesh == null:
			continue
		var hub := wheel.mount - Vector3(0, minf(wheel.length, suspension_travel * 2.0), 0)
		var turn := Basis(Vector3.UP, wheel.steer_angle) * Basis(Vector3.RIGHT, -wheel.spin_angle)
		wheel.mesh.transform = Transform3D(turn * wheel.mesh_basis, hub)


func _update_camera(delta: float) -> void:
	var t := _camera_pivot.global_transform
	t.origin = global_position
	if _camera_view() == "chase":
		var weight := clampf(camera_follow * delta, 0.0, 1.0)
		t.basis = t.basis.slerp(Basis(Vector3.UP, rotation.y), weight).orthonormalized()
	else:
		t.basis = global_transform.basis.orthonormalized()
	_camera_pivot.global_transform = t
	_update_shake(delta)


## Vibración: crece con el cuadrado de la velocidad y suma los golpes (muros, cambios, pianos).
func _update_shake(delta: float) -> void:
	_shake_time += delta
	_impact = move_toward(_impact, 0.0, shake_impact_decay * delta)
	var speed_part := pow(clampf(absf(forward_speed) / max_speed, 0.0, 1.0), 2.0)
	var impact_part := _impact * _impact
	var factor := shake_chase_factor if _camera_view() == "chase" else float(CAMERA_MODES[camera_mode].get("shake", 1.0))
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
	var pivot_basis := Basis(Vector3.UP, rotation.y) if _camera_view() == "chase" else global_transform.basis.orthonormalized()
	_camera_pivot.global_transform = Transform3D(pivot_basis, global_position)


## RPM que impone el giro de las ruedas traseras a través de la marcha actual (si patinan,
## suben las RPM).
func _wheel_rpm() -> float:
	var spin := 0.0
	var count := 0
	for wheel in wheels:
		if not wheel.front:
			spin += absf(wheel.spin)
			count += 1
	var wheel_rad_per_s := spin / count if count > 0 else absf(forward_speed) / wheel_radius
	return wheel_rad_per_s * gearbox.get_total_ratio() * 60.0 / TAU


func _flat_forward() -> Vector3:
	var forward := -global_transform.basis.z
	forward.y = 0.0
	return forward.normalized()


func _gravity() -> float:
	return float(ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)) * gravity_scale


func reset_to_spawn() -> void:
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	_last_velocity = Vector3.ZERO
	global_transform = spawn_transform
	forward_speed = 0.0
	_steer = 0.0
	_impact = 0.0
	kerb_contact = 0.0
	for wheel in wheels:
		wheel.reset(suspension_travel)
	engine.reset()
	gearbox.reset()
	_snap_camera()
	was_reset.emit()


func get_speed_kmh() -> float:
	return Vector2(linear_velocity.x, linear_velocity.z).length() * 3.6


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


## Alguna rueda apoyada en el piso.
func is_grounded() -> bool:
	for wheel in wheels:
		if wheel.in_contact:
			return true
	return false


## Mayor deslizamiento longitudinal |κ| de las ruedas apoyadas (1 = bloqueada o girando el
## doble de rápido que el piso).
func get_wheel_slip() -> float:
	var slip := 0.0
	for wheel in wheels:
		if wheel.in_contact and absf(wheel.long_speed) > 1.0:
			slip = maxf(slip, absf(wheel.slip_ratio))
	return slip


## Ángulo entre hacia dónde apunta el auto y hacia dónde se mueve (derrape).
func get_slip_angle_deg() -> float:
	var horizontal := Vector3(linear_velocity.x, 0.0, linear_velocity.z)
	if horizontal.length() < 3.0:
		return 0.0
	var forward := _flat_forward()
	if forward_speed < 0.0:
		forward = -forward
	return rad_to_deg(forward.angle_to(horizontal.normalized()))


## Colores del equipo y número del piloto (vacío = sin número).
func set_livery(primary: Color, secondary: Color, number: String) -> void:
	livery.apply(primary, secondary, number)


func _vec3(value, fallback: Vector3) -> Vector3:
	if value is Array and value.size() == 3:
		return Vector3(float(value[0]), float(value[1]), float(value[2]))
	return fallback
