class_name CarController
extends RigidBody3D
## Monoplaza con modelo de 4 ruedas (Paso 25): cuerpo rígido con masa, centro de masa e
## inercia; cada rueda (CarWheel) es un rayo con resorte y amortiguador, y su neumático
## (TyreModel, Pacejka, Paso 26) empuja en el punto de contacto según la deriva y el
## deslizamiento. Motor y caja son componentes (Pasos 3 y 4): el par llega a las ruedas
## traseras según la marcha (adelante en 1–8, atrás en R, nada en N) a través del
## diferencial y del control de tracción (Paso 31), y las RPM salen del giro de esas ruedas.
## El ERS (Paso 32) suma la potencia del MGU-K y recupera energía frenando. El agarre de
## cada rueda depende del compuesto, su temperatura y su desgaste (TyreCompounds, Paso 33).
## El combustible (Fuel, Paso 34) se quema según la potencia del motor y pesa: la masa y la
## precarga de las ruedas bajan a medida que se vacía el tanque.
## El setup (CarSetup, Paso 35) cambia alerones, altura, resortes, barras, presiones y la
## relación final sobre los valores base de car.json (apply_setup()); si la suspensión se
## comprime más que la altura del piso, el piso toca y pierde carga (floor_factor()).
## Daños (CarDamage, Paso 36): los golpes con la trompa rompen el alerón delantero (menos
## carga adelante) y los de costado pinchan la rueda más cercana; reset_to_spawn() repara.
## El auto avanza sobre su eje -Z. En caja automática S con el auto quieto pone R.

signal was_reset
signal camera_changed(mode_name: String)
## Choque contra un muro; strength 0–1 según la velocidad perdida (puede repetirse cada frame).
signal wall_hit(strength: float)

## Cámara del auto (o de la pista) activa: true = cámaras de TV de la pista (Paso 18).
signal camera_mode_applied(external: bool)
## Nuevo reparto de frenada (fracción adelante, Paso 30).
signal brake_bias_changed(front_share: float)
## Nuevo nivel del control de tracción (0 = apagado, Paso 31).
signal traction_control_changed(level: int)

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
		"travel": "suspension_travel"},
	"tyres": {"mu": "tyre_mu", "rear_grip_factor": "rear_grip_factor"},
	"brakes": {"force": "brake_force", "front_share": "brake_front_share", "bias_min": "brake_bias_min",
		"bias_max": "brake_bias_max", "bias_step": "brake_bias_step"},
	"steering": {"max_deg": "max_steer_deg", "min_deg": "min_steer_deg"},
}

@export_group("Motor")
@export var max_speed: float = 55.0            ## m/s; se recalcula en configure() desde la última marcha
@export var max_reverse_speed: float = 12.0
@export var mass_kg: float = 800.0
@export var wheel_radius: float = 0.36
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
## Por eje: x = delantero, y = trasero.
@export var spring_stiffness := Vector2(75000.0, 65000.0)  ## N/m
@export var damper := Vector2(4000.0, 3600.0)              ## N·s/m
## N/m de la barra estabilizadora: fuerza = rigidez × diferencia de compresión izq./der.
@export var anti_roll := Vector2(40000.0, 30000.0)
## Fracción de la transferencia longitudinal que va por los brazos de la suspensión y no
## por el resorte (anti-hundimiento adelante, anti-levantamiento / anti-agache atrás).
@export var anti_pitch := Vector2(0.35, 0.25)

@export_group("Aerodinámica")
@export var air_density: float = 1.225         ## kg/m³
## m²: coeficiente × área. Carga = ½ · ρ · ClA · v² (hacia abajo); arrastre = ½ · ρ · CdA · v².
@export var cla: float = 3.2
@export var cda: float = 1.57
@export var aero_balance: float = 0.44         ## fracción de la carga en el eje delantero
@export var pressure_height: float = 0.35      ## m sobre el piso donde empuja el arrastre
## Setup (Paso 35): m que se baja (−) o sube (+) el auto; el piso queda a floor_clearance del
## asfalto con el auto quieto. Si la suspensión de un eje se comprime más que eso, la carga
## cae hasta floor_stall_loss a floor_stall_depth m por debajo.
@export var ride_height: float = 0.0
@export var floor_clearance: float = 1.0
@export var floor_stall_depth: float = 0.005
@export var floor_stall_loss: float = 0.3

@export_group("Neumáticos y frenos")
@export var tyre_mu: float = 1.75              ## agarre mecánico (la carga aerodinámica se suma a la carga)
@export var rear_grip_factor: float = 1.08
@export var brake_force: float = 30000.0       ## N totales con el freno a fondo (en el piso, sin bloquear)
## Reparto de frenada (fracción adelante); se ajusta en carrera entre brake_bias_min y
## brake_bias_max de a brake_bias_step (Paso 30).
@export var brake_front_share: float = 0.58
@export var brake_bias_min: float = 0.45
@export var brake_bias_max: float = 0.75
@export var brake_bias_step: float = 0.01
## ABS (Paso 30, opción del jugador). Sin ABS las ruedas se pueden bloquear.
@export var abs_enabled: bool = true

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
## Compuesto, temperatura y desgaste (Paso 33; el compuesto lo elige GameState).
var tyres := TyreCompounds.new()
var abs_model := AbsModel.new()
## Diferencial trasero y control de tracción (Paso 31; el nivel lo pone Settings).
var differential := Differential.new()
var traction_control := TractionControl.new()
## Batería y MGU-K (Paso 32).
var ers := Ers.new()
## Combustible (Paso 34; la carga la pone main.gd con fill_fuel()). La masa del cuerpo es
## mass_kg (seco, con el piloto) + fuel.kg.
var fuel := Fuel.new()
## Alerón delantero y pinchazos (Paso 36).
var damage := CarDamage.new()
## Modo recta / curva y modo adelantamiento (Paso 29).
var active_aero := ActiveAero.new()
## m/s² en ejes del auto (x derecha, y arriba, −z adelante), suavizada; la usa el panel de cargas.
var local_acceleration: Vector3 = Vector3.ZERO
## N de carga aerodinámica (total y en el eje delantero) y de arrastre del último cuadro.
var downforce: float = 0.0
var downforce_front: float = 0.0
var drag_force: float = 0.0

var camera_mode: int = 0

var _steer: float = 0.0
var _handbrake: bool = false
var _touching_wall: bool = false
var _last_velocity: Vector3 = Vector3.ZERO
var _accel_velocity: Vector3 = Vector3.ZERO
var _camera_base: Transform3D = Transform3D.IDENTITY
var _shake_noise := FastNoiseLite.new()
var _shake_time: float = 0.0
var _impact: float = 0.0
var _showcase: bool = false
var _applied_fuel: float = 0.0
## Valores de car.json sobre los que trabaja el setup (setup_base()).
var _setup_base: Dictionary = {}
## Centro de cada rueda en coordenadas del auto (para ubicar los pinchazos).
var _wheel_points: Array[Vector3] = []
var _wing_base: Transform3D = Transform3D.IDENTITY

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
@onready var _front_wing: Node3D = $FrontWing


func _ready() -> void:
	spawn_transform = global_transform
	_wing_base = _front_wing.transform
	damage.wing_damaged.connect(func(_health: float) -> void: _update_wing_mesh())
	damage.punctured.connect(func(_index: int) -> void: _apply_rest_lengths())
	damage.repaired.connect(func() -> void:
		_apply_rest_lengths()
		_update_wing_mesh())
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
	var aero_data = data.get("aero", {})
	if aero_data is Dictionary:
		air_density = float(aero_data.get("air_density", air_density))
		cla = float(aero_data.get("cla", cla))
		cda = float(aero_data.get("cda", cda))
		aero_balance = clampf(float(aero_data.get("balance", aero_balance)), 0.0, 1.0)
		pressure_height = float(aero_data.get("pressure_height", pressure_height))
		var active_data = aero_data.get("active", {})
		if active_data is Dictionary:
			active_aero.configure(active_data)
	var chassis_data = data.get("chassis", {})
	if chassis_data is Dictionary:
		_configure_chassis(chassis_data)
	var ers_data = data.get("ers", {})
	if ers_data is Dictionary:
		ers.configure(ers_data)
	var compounds_data = data.get("tyre_compounds", {})
	if compounds_data is Dictionary:
		tyres.configure(compounds_data)
	var fuel_data = data.get("fuel", {})
	if fuel_data is Dictionary:
		fuel.configure(fuel_data)
	var damage_data = data.get("damage", {})
	if damage_data is Dictionary:
		damage.configure(damage_data)
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
	_setup_base = {}
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
	var suspension = data.get("suspension", {})
	if suspension is Dictionary:
		for axle in ["front", "rear"]:
			var values = suspension.get(axle, {})
			if values is Dictionary:
				var index := 0 if axle == "front" else 1
				spring_stiffness[index] = float(values.get("stiffness", spring_stiffness[index]))
				damper[index] = float(values.get("damping", damper[index]))
				anti_roll[index] = float(values.get("anti_roll", anti_roll[index]))
				anti_pitch[index] = clampf(float(values.get("anti_pitch", anti_pitch[index])), 0.0, 1.0)
	var tyre_data = data.get("tyres", {})
	if tyre_data is Dictionary:
		tyre.configure(tyre_data)
	var brakes = data.get("brakes", {})
	if brakes is Dictionary:
		var abs_data = brakes.get("abs", {})
		if abs_data is Dictionary:
			abs_model.configure(abs_data)
	brake_bias_min = clampf(brake_bias_min, 0.0, 1.0)
	brake_bias_max = clampf(brake_bias_max, brake_bias_min, 1.0)
	brake_front_share = clampf(brake_front_share, brake_bias_min, brake_bias_max)
	var differential_data = data.get("differential", {})
	if differential_data is Dictionary:
		differential.configure(differential_data)
	var traction_data = data.get("traction_control", {})
	if traction_data is Dictionary:
		traction_control.configure(traction_data)


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
	center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
	wheels.clear()
	_wheel_points.clear()
	for spec in WHEEL_NODES:
		var is_front: bool = spec[2]
		var mount := Vector3(float(spec[1]) * half_track, wheel_radius + suspension_travel,
			front_axle_z if is_front else rear_axle_z)
		var wheel := CarWheel.new(mount, is_front, get_node_or_null(str(spec[0])) as Node3D)
		tyres.fit(wheel)
		wheels.append(wheel)
		_wheel_points.append(Vector3(mount.x, wheel_radius, mount.z))
	_apply_rest_lengths()
	for wheel in wheels:
		wheel.reset()
	_apply_mass()


## Largo de reposo de cada suspensión: travel + la altura del setup, menos lo que baja una
## rueda pinchada.
func _apply_rest_lengths() -> void:
	for i in wheels.size():
		wheels[i].rest_length = suspension_travel + ride_height - (damage.puncture_drop if damage.is_punctured(i) else 0.0)


## Alerón delantero: cuelga según el daño y se cae con salud ≤ wing_broken_health.
func _update_wing_mesh() -> void:
	var loss := 1.0 - damage.wing_health
	_front_wing.visible = not damage.is_wing_broken()
	_front_wing.transform = _wing_base * Transform3D(Basis(Vector3.RIGHT, deg_to_rad(-12.0 * loss)), Vector3(0, -0.06 * loss, 0))


## Valores de car.json que cambia el setup (los de configure(), antes de cualquier setup).
func setup_base() -> Dictionary:
	if _setup_base.is_empty():
		_setup_base = {
			"cla": cla, "cda": cda, "balance": aero_balance,
			"stiffness": spring_stiffness, "damper": damper, "anti_roll": anti_roll,
			"top_ratio": gearbox.gear_ratios[gearbox.gear_ratios.size() - 1] if not gearbox.gear_ratios.is_empty() else 1.0,
			"limiter_rpm": engine.limiter_rpm, "wheel_radius": wheel_radius,
		}
	return _setup_base


## Aplica el setup (Paso 35). Cambia la altura sin cambiar los neumáticos (temperatura y
## desgaste siguen); conviene llamarlo con el auto quieto (después va reset_to_spawn()).
func apply_setup(setup: CarSetup) -> void:
	var values := setup.derive(setup_base())
	cla = float(values["cla"])
	cda = float(values["cda"])
	aero_balance = float(values["balance"])
	spring_stiffness = values["stiffness"]
	damper = values["damper"]
	anti_roll = values["anti_roll"]
	ride_height = float(values["ride_height"])
	floor_clearance = float(values["floor_clearance"])
	floor_stall_depth = setup.stall_depth_mm / 1000.0
	floor_stall_loss = setup.stall_loss
	tyres.set_pressures(values["pressure"], setup.default_pressure(), setup.pressure_grip_per_psi, setup.pressure_heat_per_psi)
	gearbox.final_drive = float(values["final_drive"])
	max_speed = get_top_speed()
	_apply_rest_lengths()
	for wheel in wheels:
		wheel.reset()


## Masa del cuerpo = seco + combustible, y la precarga de cada rueda (su parte del peso
## según el centro de masa; el tanque está sobre el centro de masa y no lo mueve).
func _apply_mass() -> void:
	mass = mass_kg + fuel.kg
	_applied_fuel = fuel.kg
	var front_share := clampf((rear_axle_z - center_of_mass.z) / (rear_axle_z - front_axle_z), 0.1, 0.9)
	var weight := mass * _gravity()
	for wheel in wheels:
		wheel.static_load = weight * (front_share if wheel.front else 1.0 - front_share) * 0.5


## Carga el tanque con `kg` (hasta la capacidad).
func fill_fuel(kg: float) -> void:
	fuel.fill(kg)
	_apply_mass()


## Juego nuevo del compuesto `id` (vacío = el de por defecto) en las 4 ruedas.
func fit_tyres(id: String) -> void:
	tyres.select(id)
	for wheel in wheels:
		tyres.fit(wheel)


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
	elif event.is_action_pressed("aero_mode"):
		active_aero.toggle_straight()
	elif event.is_action_pressed("overtake"):
		if ers.is_empty() and not active_aero.overtake_active:
			active_aero.overtake_denied.emit("Batería vacía")
		else:
			active_aero.toggle_overtake()
	elif event.is_action_pressed("ers_mode"):
		ers.cycle_mode()
	elif event.is_action_pressed("brake_bias_forward"):
		adjust_brake_bias(1)
	elif event.is_action_pressed("brake_bias_rearward"):
		adjust_brake_bias(-1)
	elif event.is_action_pressed("traction_control"):
		set_traction_control(traction_control.level + 1)


## Mueve el reparto de frenada `steps` pasos (positivo = más adelante).
func adjust_brake_bias(steps: int) -> void:
	var share := clampf(snappedf(brake_front_share + steps * brake_bias_step, 0.001), brake_bias_min, brake_bias_max)
	if share != brake_front_share:
		brake_front_share = share
		brake_bias_changed.emit(share)


## Nivel del control de tracción; después del último vuelve a 0 (apagado).
func set_traction_control(level: int) -> void:
	var new_level := posmod(level, traction_control.level_count())
	if new_level != traction_control.level:
		traction_control.set_level(new_level)
		traction_control_changed.emit(new_level)


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
	var world_accel := (linear_velocity - _accel_velocity) / delta
	_accel_velocity = linear_velocity
	local_acceleration = local_acceleration.lerp(global_transform.basis.orthonormalized().transposed() * world_accel, 0.2)

	var pedals := _map_pedals(throttle, brake)
	if fuel.is_empty():
		pedals.x = 0.0
	_update_powertrain(pedals.x, delta)
	fuel.update(_combustion_power(pedals.x), delta)
	if absf(_applied_fuel - fuel.kg) > 0.05:
		_apply_mass()
	_update_steering(steer_input, delta)
	var overtake := _overtake_power(pedals.x)
	var electric := _ers_deploy(pedals.x) + overtake
	active_aero.update(pedals.x, pedals.y, _steer, forward_speed, overtake, delta)
	_apply_aero()
	var harvest := _apply_wheel_forces(pedals.x, pedals.y, handbrake, electric, delta)
	# Debajo de 10 m/s la fuerza eléctrica está topada (P / 10): entrega F · v, no P.
	ers.update(electric * traction_control.torque_factor * clampf(forward_speed / 10.0, 0.0, 1.0), harvest, delta)
	if ers.is_empty() and active_aero.overtake_active:
		active_aero.toggle_overtake()
	for i in wheels.size():
		tyres.update(wheels[i], forward_speed, delta)
		if damage.wear_puncture and wheels[i].wear >= 1.0:
			damage.puncture(i)
	_update_wheel_meshes()
	_update_camera(delta)

	if global_position.y < -20.0:
		reset_to_spawn()


## Golpes contra muros: velocidad perdida contra la normal de cada contacto casi vertical
## desde el paso anterior. Los que pasan de 1 m/s van a los daños con su punto de contacto.
func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	var touching := false
	var strongest := 0.0
	var lost := _last_velocity - state.linear_velocity
	var to_local := state.transform.affine_inverse()
	var points := PackedVector3Array()
	var strengths := PackedFloat32Array()
	for i in state.get_contact_count():
		var normal := state.get_contact_local_normal(i)
		if absf(normal.y) < 0.5:
			touching = true
			var impact := absf(lost.dot(normal))
			strongest = maxf(strongest, impact)
			if impact > 1.0:
				points.append(to_local * state.get_contact_local_position(i))
				strengths.append(impact / shake_wall_speed)
	if not points.is_empty():
		damage.on_impacts(points, strengths, _wheel_points)
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
	var limit := atan(wheelbase * grip_acceleration() / maxf(speed * speed, 0.01)) + tyre.slip_angle_peak
	limit = clampf(limit * steer_limit, deg_to_rad(min_steer_deg), deg_to_rad(max_steer_deg))
	for wheel in wheels:
		wheel.steer_angle = _steer * limit if wheel.front else 0.0


## Suspensión y neumático de cada rueda. Pares sobre cada rueda: el motor en las traseras
## (mitad cada una, menos lo que corta el control de tracción, más o menos lo que pasa el
## diferencial), los frenos repartidos entre los ejes, rodadura y freno motor; con freno
## de mano las traseras se bloquean (y al patinar casi no agarran de costado).
## Los neumáticos se calculan en TYRE_SUBSTEPS sub-pasos: en cada uno se predice cómo cambian
## la velocidad y el giro del auto con esas fuerzas, y al cuerpo se le aplica el promedio.
## `electric`: W del MGU-K y del modo adelantamiento. Devuelve los W de frenada de las traseras
## que puede recuperar el ERS (los frenos traseros, que el freno por cable reparte entre el
## MGU-K y el hidráulico sin cambiar el total, más lo que frena el MGU-K al levantar el pie).
func _apply_wheel_forces(throttle: float, brake: float, handbrake: bool, electric: float, delta: float) -> float:
	var space := get_world_3d().direct_space_state
	var center := global_transform * center_of_mass
	var corner_mass := mass * 0.25
	var drive_torque := _drive_force(throttle, electric) * wheel_radius * 0.5
	var engine_brake := 0.0
	var direction := float(gearbox.get_direction())
	if throttle == 0.0 and direction != 0.0 and forward_speed * direction > 0.0:
		engine_brake = engine.get_engine_brake_accel() * mass * wheel_radius * 0.5
	var lift_torque := 0.0
	if throttle == 0.0 and brake == 0.0 and not handbrake and direction > 0.0 and forward_speed > 5.0:
		lift_torque = ers.lift_power() * 0.5 / (forward_speed / wheel_radius)
	var harvest := 0.0
	var grounded: Array[CarWheel] = []
	var torques: Array[Vector3] = []
	for wheel in wheels:
		var axle := 0 if wheel.front else 1
		wheel.update_suspension(self, space, suspension_travel, wheel_radius, spring_stiffness[axle], damper[axle], delta)
	_apply_chassis_links()
	for index in wheels.size():
		var wheel := wheels[index]
		var mu := tyre_mu * (1.0 if wheel.front else rear_grip_factor) * tyres.grip_factor(wheel) * damage.grip_factor(index)
		var share := brake_front_share if wheel.front else 1.0 - brake_front_share
		var brake_torque := (brake_force * brake * share * 0.5 + rolling_resistance * corner_mass) * wheel_radius
		if damage.is_punctured(index):
			brake_torque += damage.puncture_drag_n * wheel_radius
		var torque := 0.0
		var locked := false
		if not wheel.front:
			torque = drive_torque
			harvest += (brake_force * brake * share * 0.5 * wheel_radius * wheel.brake_pressure + lift_torque) * absf(wheel.spin)
			brake_torque += engine_brake + lift_torque
			if handbrake:
				brake_torque += mu * wheel.static_load * MAX_HANDBRAKE_FACTOR * wheel_radius
				locked = true
		if not wheel.in_contact:
			wheel.update_free_spin(tyre.wheel_inertia, torque, brake_torque, delta)
			continue
		apply_force(wheel.up * wheel.wheel_load, wheel.contact_point - global_position)
		grounded.append(wheel)
		# (μ, par del motor, par de frenado); el freno de mano no pasa por el ABS.
		torques.append(Vector3(mu, torque, brake_torque if not locked else -brake_torque))
	if grounded.is_empty():
		traction_control.reset()
		return harvest
	var rear_left := grounded.find(wheels[2])
	var rear_right := grounded.find(wheels[3])

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
		var factor := traction_control.modulate(_drive_slip(drive_torque), h)
		var split := 0.0
		if rear_left >= 0 and rear_right >= 0:
			var on_power := drive_torque != 0.0
			var input := drive_torque * factor * 2.0 if on_power else engine_brake * 2.0
			split = differential.transfer(wheels[2].spin, wheels[3].spin, input, on_power, tyre.wheel_inertia, h)
		for i in grounded.size():
			var wheel := grounded[i]
			var arm := wheel.contact_point - center
			wheel.measure(basis_now, velocity + spin.cross(arm), tyre.slip_floor)
			var t := torques[i]
			var drive := t.y * factor
			if i == rear_left:
				drive += split
			elif i == rear_right:
				drive -= split
			var force := wheel.update_tyre(tyre, t.x, drive, absf(t.z), wheel_radius,
				abs_model if abs_enabled and t.z >= 0.0 else null, h)
			step_force += force
			step_torque += arm.cross(force)
		velocity += step_force / mass * h
		spin += inverse_inertia * step_torque * h
		total_force += step_force
		total_torque += step_torque
	apply_central_force(total_force / TYRE_SUBSTEPS)
	apply_torque(total_torque / TYRE_SUBSTEPS)
	return harvest


## Mayor deslizamiento de las traseras apoyadas en el sentido del par del motor (0 sin par).
func _drive_slip(drive_torque: float) -> float:
	if drive_torque == 0.0:
		return 0.0
	var slip := 0.0
	for wheel in wheels:
		if not wheel.front and wheel.in_contact:
			slip = maxf(slip, wheel.slip_ratio * signf(drive_torque))
	return slip


## Aerodinámica (Paso 28). Carga ½ · ρ · ClA · v² hacia abajo del auto, repartida entre los
## ejes según aero_balance y aplicada sobre cada eje: comprime los resortes (el auto baja con
## la velocidad) y llega a los neumáticos como carga, así que agarran más cuanto más rápido.
## Arrastre ½ · ρ · CdA · v² contra la velocidad, en el centro de presión (pressure_height):
## como está más alto que el centro de masa, a alta velocidad descarga un poco el eje delantero.
## Se calcula antes que las ruedas: la suspensión ya ve la carga en este cuadro.
## En modo recta (Paso 29) ClA y CdA bajan según cuánto están abiertos los alerones.
func _apply_aero() -> void:
	var t := global_transform
	var up := t.basis.y.normalized()
	var air_speed := linear_velocity.dot(-t.basis.z.normalized())
	var pressure := 0.5 * air_density * air_speed * air_speed
	downforce = pressure * get_cla()
	downforce_front = downforce * get_aero_balance()
	apply_force(-up * downforce_front, t.basis * Vector3(0.0, 0.0, front_axle_z))
	apply_force(-up * (downforce - downforce_front), t.basis * Vector3(0.0, 0.0, rear_axle_z))
	var speed := linear_velocity.length()
	drag_force = 0.5 * air_density * get_cda() * speed * speed
	if speed > 0.01:
		apply_force(-linear_velocity / speed * drag_force, t.basis * Vector3(0.0, pressure_height, center_of_mass.z))


## ClA y CdA de ahora (con el modo recta, el piso que toca y el alerón delantero dañado).
func get_cla() -> float:
	return cla * active_aero.cla_scale() * floor_factor() * (aero_balance * damage.front_downforce_factor() + 1.0 - aero_balance)


## Fracción de la carga en el eje delantero ahora (baja con el alerón delantero dañado).
func get_aero_balance() -> float:
	var front := aero_balance * damage.front_downforce_factor()
	return front / maxf(front + 1.0 - aero_balance, 0.0001)


## m entre el piso y el asfalto en cada eje (x adelante, y atrás): la altura de reposo menos
## lo que está comprimida la suspensión (promedio de las dos ruedas apoyadas).
func floor_gaps() -> Vector2:
	var gaps := Vector2(floor_clearance, floor_clearance)
	for axle in 2:
		var compression := 0.0
		var count := 0
		for wheel in [wheels[axle * 2], wheels[axle * 2 + 1]]:
			if wheel.in_contact:
				compression += wheel.rest_length - wheel.length
				count += 1
		if count > 0:
			gaps[axle] = floor_clearance - compression / count
	return gaps


## Fracción de la carga aerodinámica que queda: 1 con el piso en el aire, baja hasta
## 1 − floor_stall_loss si el piso toca floor_stall_depth o más.
func floor_factor() -> float:
	if wheels.size() != 4:
		return 1.0
	var gaps := floor_gaps()
	var depth := maxf(-minf(gaps.x, gaps.y), 0.0)
	return 1.0 - floor_stall_loss * minf(depth / floor_stall_depth, 1.0)


## El piso está tocando el asfalto.
func is_bottoming() -> bool:
	if wheels.size() != 4:
		return false
	var gaps := floor_gaps()
	return minf(gaps.x, gaps.y) < 0.0


func get_cda() -> float:
	return cda * active_aero.cda_scale()


## Agarre total disponible en m/s² (μ × (peso + carga aerodinámica) / masa).
func grip_acceleration() -> float:
	return tyre_mu * (mass * _gravity() + downforce) / mass


## Transferencia de peso que no pasa sólo por los resortes (Paso 27), sumada a la carga:
## - Barra estabilizadora: si una rueda del eje está más comprimida que la otra, la barra la
##   empuja con anti_roll × diferencia y descarga a la otra. Más barra en un eje = ese eje se
##   lleva más transferencia lateral (y por la sensibilidad a la carga, agarra menos).
## - Anti-cabeceo: la fuerza longitudinal del neumático (la del cuadro anterior) empuja el
##   chasis hacia arriba o abajo por los brazos: carga la rueda sin comprimir el resorte, así
##   el auto cabecea menos. La transferencia total no cambia (la fija la altura del centro de
##   masa); cambia por dónde pasa.
func _apply_chassis_links() -> void:
	var lever := center_of_mass.y / (rear_axle_z - front_axle_z)
	for axle in 2:
		var left := wheels[axle * 2]
		var right := wheels[axle * 2 + 1]
		var bar := anti_roll[axle] * (right.length - left.length)
		for wheel: CarWheel in [left, right]:
			var side := 1.0 if wheel == left else -1.0
			var direction := -1.0 if wheel.front else 1.0
			wheel.link_force = anti_pitch[axle] * wheel.force.x * lever * direction
			if wheel.in_contact:
				wheel.wheel_load = maxf(wheel.wheel_load + bar * side + wheel.link_force, 0.0)


## N de empuje entre las dos ruedas traseras (negativo en R). `electric`: W del ERS y del
## modo adelantamiento (sólo hacia adelante).
func _drive_force(throttle: float, electric: float) -> float:
	var direction := float(gearbox.get_direction())
	if throttle <= 0.0 or direction == 0.0 or gearbox.is_shifting():
		return 0.0
	if direction < 0.0 and forward_speed < -max_reverse_speed:
		return 0.0
	var wheel_torque := engine.get_output_torque() * gearbox.get_total_ratio() * gearbox.efficiency
	var force := wheel_torque / wheel_radius
	if direction < 0.0:
		force = minf(force, reverse_acceleration * mass)
	else:
		force += electric / maxf(forward_speed, 10.0)
	return force * direction


## W que entrega el motor de combustión (lo que quema combustible): con una marcha puesta y
## sin cambio en curso, menos lo que corta el control de tracción.
func _combustion_power(throttle: float) -> float:
	if throttle <= 0.0 or gearbox.get_direction() == 0 or gearbox.is_shifting():
		return 0.0
	return engine.get_output_torque() * engine.rpm * TAU / 60.0 * traction_control.torque_factor


## Se puede sumar potencia eléctrica: hacia adelante, sin cambio en curso ni corte del limitador
## y con combustible (sin combustible se apaga toda la unidad de potencia).
func _can_deploy() -> bool:
	return gearbox.get_direction() > 0 and not gearbox.is_shifting() and not engine.is_cutting() and not fuel.is_empty()


## W que despliega el MGU-K según el modo del ERS.
func _ers_deploy(throttle: float) -> float:
	if throttle <= 0.0 or not _can_deploy():
		return 0.0
	return ers.deploy_request(throttle)


## W extra del modo adelantamiento (de la batería del ERS).
func _overtake_power(throttle: float) -> float:
	if not active_aero.overtake_active or ers.is_empty() or not _can_deploy():
		return 0.0
	return active_aero.overtake_power * throttle


## Las ruedas siguen la suspensión y las delanteras giran con la dirección.
func _update_wheel_meshes() -> void:
	for i in wheels.size():
		var wheel := wheels[i]
		if wheel.mesh == null:
			continue
		# La rueda pinchada se dibuja hundida en el piso (aplastada).
		var flat := damage.puncture_drop if damage.is_punctured(i) else 0.0
		var hub := wheel.mount - Vector3(0, minf(wheel.length, suspension_travel * 2.0) + flat, 0)
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
	_accel_velocity = Vector3.ZERO
	local_acceleration = Vector3.ZERO
	global_transform = spawn_transform
	forward_speed = 0.0
	_steer = 0.0
	_impact = 0.0
	kerb_contact = 0.0
	# Un neumático gastado del todo volvería a pinchar: en boxes se cambia ese.
	for wheel in wheels:
		if wheel.wear >= 1.0:
			tyres.fit(wheel)
	damage.repair()
	for wheel in wheels:
		wheel.reset()
	active_aero.reset()
	traction_control.reset()
	ers.reset()
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


## Grados de cabeceo (positivo = trompa arriba) y de rolido (positivo = inclinado a la derecha).
func get_pitch_deg() -> float:
	var forward := -global_transform.basis.z.normalized()
	return rad_to_deg(asin(clampf(forward.y, -1.0, 1.0)))


func get_roll_deg() -> float:
	var right := global_transform.basis.x.normalized()
	return rad_to_deg(asin(clampf(-right.y, -1.0, 1.0)))


## Transferencia de peso de la cuenta (N) con las fuerzas del último cuadro (h = altura del
## centro de masa, L = distancia entre ejes):
## x = la que gana el eje delantero: −ΣFx · h / L por los neumáticos (frenando, positiva)
##     menos −D · (h_cp − h) / L del arrastre, que empuja más arriba que el centro de masa;
## y = la que gana el lado derecho: −ΣFy · h / trocha (en una curva a la izquierda, positiva).
## Sin arrastre y en el plano es lo mismo que m · a · h / L y m · a_lat · h / trocha.
func theoretical_transfer() -> Vector2:
	var height := center_of_mass.y
	var tyre_force := Vector2.ZERO
	for wheel in wheels:
		if wheel.in_contact:
			tyre_force += wheel.force
	var longitudinal := (-tyre_force.x * height - drag_force * (pressure_height - height)) / (rear_axle_z - front_axle_z)
	var lateral := -tyre_force.y * height / (half_track * 2.0)
	return Vector2(longitudinal, lateral)


## Mayor deslizamiento longitudinal |κ| de las ruedas apoyadas (1 = bloqueada o girando el
## doble de rápido que el piso).
func get_wheel_slip() -> float:
	var slip := 0.0
	for wheel in wheels:
		if wheel.in_contact and absf(wheel.long_speed) > 1.0:
			slip = maxf(slip, absf(wheel.slip_ratio))
	return slip


## El ABS está soltando el freno de alguna rueda.
func is_abs_active() -> bool:
	for wheel in wheels:
		if wheel.abs_active:
			return true
	return false


## El control de tracción está cortando par.
func is_tc_active() -> bool:
	return traction_control.active


## Alguna rueda bloqueada (frenando sin ABS o con el freno de mano).
func is_any_wheel_locked() -> bool:
	for wheel in wheels:
		if wheel.is_locked():
			return true
	return false


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
