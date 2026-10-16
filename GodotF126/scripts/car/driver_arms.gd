class_name DriverArms
extends Node3D
## Manos y brazos del piloto en el cockpit (Paso 7), con formas simples.
## Las manos cuelgan del aro del volante, así siguen el giro sin código extra.
## Cada brazo tiene dos tramos (brazo y antebrazo) que se recalculan cada frame
## con cinemática inversa de dos huesos: hombro fijo en el chasis → codo → muñeca.
## Al cambiar de marcha, el índice tira de la leva: derecha sube, izquierda baja.
## Los tramos de los brazos están en el grupo "team_paint" (buzo con el color del equipo).

const UPPER_ARM_LENGTH := 0.30
const FOREARM_LENGTH := 0.28
const ARM_THICKNESS := 0.075
const SHOULDER_OFFSET := Vector3(0.2, 0.78, -0.5)   ## x se espeja para cada lado
const GLOVE_SIZE := Vector3(0.06, 0.09, 0.07)
const THUMB_SIZE := Vector3(0.018, 0.035, 0.018)
const FINGER_SIZE := Vector3(0.05, 0.016, 0.016)
const FINGER_REST_Z := -0.042   ## justo detrás de la cara trasera de la leva
const PADDLE_PULL := 0.008
const PULL_TIME := 0.05
const RELEASE_TIME := 0.1

@export var glove_color: Color = Color(0.1, 0.1, 0.12)
@export var suit_color: Color = Color(0.3, 0.3, 0.35)   ## lo pisa CarLivery con el color del equipo

var _wheel: SteeringWheel
var _gearbox: Gearbox
var _last_gear: int = 1
## Índice 0 = izquierda, 1 = derecha.
var _wrists: Array[Node3D] = []
var _fingers: Array[Node3D] = []
var _upper_arms: Array[MeshInstance3D] = []
var _forearms: Array[MeshInstance3D] = []
var _tweens: Array[Tween] = [null, null]


func _ready() -> void:
	process_priority = 10   # después de que el volante actualice su giro
	_wheel = get_node("../SteeringWheel") as SteeringWheel
	_gearbox = get_node("../Gearbox") as Gearbox
	_last_gear = _gearbox.gear
	_gearbox.gear_changed.connect(_on_gear_changed)

	var glove := StandardMaterial3D.new()
	glove.albedo_color = glove_color
	glove.roughness = 0.8
	var suit := StandardMaterial3D.new()
	suit.albedo_color = suit_color
	suit.roughness = 0.7

	for side in [-1, 1]:
		var suffix := "Left" if side < 0 else "Right"
		_build_hand(side, glove)
		_upper_arms.append(_make_segment("UpperArm" + suffix, suit))
		_forearms.append(_make_segment("Forearm" + suffix, suit))


func _process(_delta: float) -> void:
	if not is_visible_in_tree():
		return
	for i in 2:
		var side := -1 if i == 0 else 1
		var shoulder := Vector3(SHOULDER_OFFSET.x * side, SHOULDER_OFFSET.y, SHOULDER_OFFSET.z)
		var wrist := to_local(_wrists[i].global_position)
		var pole := Vector3(side * 0.7, -0.7, 0.0).normalized()
		var elbow := _solve_elbow(shoulder, wrist, pole)
		_place_segment(_upper_arms[i], shoulder, elbow)
		_place_segment(_forearms[i], elbow, wrist)


func _build_hand(side: int, material: Material) -> void:
	var anchor := Node3D.new()
	anchor.name = "HandLeft" if side < 0 else "HandRight"
	anchor.position = _wheel.get_grip_position(side) + Vector3(0.0, 0.0, -0.005)
	_wheel.get_rim().add_child(anchor)

	_add_box(anchor, GLOVE_SIZE, Vector3.ZERO, material)
	_add_box(anchor, THUMB_SIZE, Vector3(-side * 0.02, 0.03, 0.035), material)

	var finger := _add_box(anchor, FINGER_SIZE, Vector3(-side * 0.035, 0.0, FINGER_REST_Z), material)
	finger.name = "IndexFinger"
	_fingers.append(finger)

	var wrist := Node3D.new()
	wrist.name = "Wrist"
	wrist.position = Vector3(side * 0.01, -0.04, -0.03)
	anchor.add_child(wrist)
	_wrists.append(wrist)


func _make_segment(segment_name: String, material: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = Vector3(ARM_THICKNESS, ARM_THICKNESS, 1.0)
	var instance := MeshInstance3D.new()
	instance.name = segment_name
	instance.mesh = mesh
	instance.material_override = material
	instance.add_to_group("team_paint")
	add_child(instance)
	return instance


## Caja de largo 1 en Z, estirada y orientada para unir a con b.
func _place_segment(segment: MeshInstance3D, a: Vector3, b: Vector3) -> void:
	var length := a.distance_to(b)
	if length < 0.001:
		return
	var segment_basis := Basis.looking_at((b - a) / length, Vector3.UP)
	segment_basis = segment_basis * Basis.from_scale(Vector3(1.0, 1.0, length))
	segment.transform = Transform3D(segment_basis, (a + b) * 0.5)


## Ley de cosenos: ubica el codo a UPPER_ARM_LENGTH del hombro y FOREARM_LENGTH de la
## muñeca, del lado hacia donde apunta `pole` (afuera y abajo).
func _solve_elbow(shoulder: Vector3, wrist: Vector3, pole: Vector3) -> Vector3:
	var to_wrist := wrist - shoulder
	var reach := clampf(to_wrist.length(), 0.01, UPPER_ARM_LENGTH + FOREARM_LENGTH - 0.001)
	var dir := to_wrist.normalized()
	var along := (UPPER_ARM_LENGTH * UPPER_ARM_LENGTH - FOREARM_LENGTH * FOREARM_LENGTH + reach * reach) / (2.0 * reach)
	var height := sqrt(maxf(UPPER_ARM_LENGTH * UPPER_ARM_LENGTH - along * along, 0.0))
	var bend := (pole - dir * pole.dot(dir)).normalized()
	return shoulder + dir * along + bend * height


func _on_gear_changed(gear: int) -> void:
	if gear != _last_gear:
		_pull_paddle(1 if gear > _last_gear else -1)
	_last_gear = gear


func _pull_paddle(side: int) -> void:
	var i := 0 if side < 0 else 1
	if _tweens[i] != null and _tweens[i].is_valid():
		_tweens[i].kill()
	var paddle := _wheel.get_paddle(side)
	var finger := _fingers[i]
	var paddle_rest := SteeringWheel.PADDLE_REST_Z
	var finger_rest := FINGER_REST_Z
	var tween := create_tween()
	tween.tween_property(paddle, "position:z", paddle_rest + PADDLE_PULL, PULL_TIME)
	tween.parallel().tween_property(finger, "position:z", finger_rest + PADDLE_PULL, PULL_TIME)
	tween.tween_property(paddle, "position:z", paddle_rest, RELEASE_TIME)
	tween.parallel().tween_property(finger, "position:z", finger_rest, RELEASE_TIME)
	_tweens[i] = tween


func _add_box(parent: Node3D, box_size: Vector3, pos: Vector3, material: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = box_size
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = pos
	parent.add_child(instance)
	return instance
