class_name SteeringWheel
extends Node3D
## Volante 3D del cockpit (Paso 6), armado por código con formas simples.
## Gira ±max_turn_deg con la dirección del auto, tiene LEDs de cambio arriba y una
## pantalla (SubViewport con WheelScreen) en el centro. Sólo se ve en la cámara Cockpit.
## El volante mira hacia +Z (hacia el piloto); la rotación de dirección es sobre su Z local.

const BODY_SIZE := Vector3(0.24, 0.11, 0.035)
const GRIP_SIZE := Vector3(0.045, 0.15, 0.055)
const PADDLE_SIZE := Vector3(0.05, 0.07, 0.006)
const SCREEN_SIZE := Vector2(0.1, 0.05)
const LED_ROW_WIDTH := 0.17
const LED_SIZE := 0.008

@export var max_turn_deg: float = 180.0
@export var shift_light_count: int = 15
@export var shift_light_start_rpm: float = 9000.0

var _car: CarController = null
var _rim: Node3D
var _viewport: SubViewport
var _screen: WheelScreen
var _led_root: Node3D
var _led_materials: Array[StandardMaterial3D] = []


func _ready() -> void:
	_car = get_parent() as CarController
	_build()
	visibility_changed.connect(_on_visibility_changed)
	_on_visibility_changed()


func configure(data: Dictionary) -> void:
	shift_light_start_rpm = float(data.get("shift_light_start_rpm", shift_light_start_rpm))
	var count := maxi(int(data.get("shift_light_count", shift_light_count)), 1)
	if count != shift_light_count:
		shift_light_count = count
		_build_leds()
	_screen.shift_light_start_rpm = shift_light_start_rpm


func bind_lap_timer(timer: LapTimer) -> void:
	_screen.bind_lap_timer(timer)


func _process(_delta: float) -> void:
	if _car == null or not is_visible_in_tree():
		return
	_rim.rotation.z = _car.get_steer() * deg_to_rad(max_turn_deg)
	for i in _led_materials.size():
		var color := HudDraw.shift_light_color(i, shift_light_count, _car, shift_light_start_rpm)
		_led_materials[i].albedo_color = color


func _on_visibility_changed() -> void:
	if _viewport == null:
		return
	_viewport.render_target_update_mode = (
		SubViewport.UPDATE_ALWAYS if is_visible_in_tree() else SubViewport.UPDATE_DISABLED)


func _build() -> void:
	_rim = Node3D.new()
	_rim.name = "Rim"
	add_child(_rim)

	var carbon := _material(Color(0.07, 0.07, 0.08), 0.5)
	var rubber := _material(Color(0.03, 0.03, 0.03), 0.95)

	_add_box(_rim, BODY_SIZE, Vector3.ZERO, carbon)
	_add_box(_rim, GRIP_SIZE, Vector3(-(BODY_SIZE.x + GRIP_SIZE.x) * 0.5, -0.01, 0.0), rubber)
	_add_box(_rim, GRIP_SIZE, Vector3((BODY_SIZE.x + GRIP_SIZE.x) * 0.5, -0.01, 0.0), rubber)
	# Levas de cambio detrás de los grips (el Paso 7 las anima).
	var paddle_left := _add_box(_rim, PADDLE_SIZE, Vector3(-0.085, 0.0, -0.03), carbon)
	paddle_left.name = "PaddleLeft"
	var paddle_right := _add_box(_rim, PADDLE_SIZE, Vector3(0.085, 0.0, -0.03), carbon)
	paddle_right.name = "PaddleRight"
	# Columna de dirección hacia el chasis.
	_add_box(self, Vector3(0.03, 0.03, 0.25), Vector3(0.0, 0.0, -0.14), carbon)

	_viewport = SubViewport.new()
	_viewport.name = "ScreenViewport"
	_viewport.size = WheelScreen.SIZE
	_viewport.transparent_bg = false
	_viewport.disable_3d = true
	add_child(_viewport)
	_screen = WheelScreen.new()
	_screen.name = "WheelScreen"
	_screen.shift_light_start_rpm = shift_light_start_rpm
	_viewport.add_child(_screen)
	_screen.bind(_car)

	var screen_material := StandardMaterial3D.new()
	screen_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	screen_material.albedo_texture = _viewport.get_texture()
	var quad := QuadMesh.new()
	quad.size = SCREEN_SIZE
	var screen_mesh := MeshInstance3D.new()
	screen_mesh.name = "Screen"
	screen_mesh.mesh = quad
	screen_mesh.material_override = screen_material
	screen_mesh.position = Vector3(0.0, -0.008, BODY_SIZE.z * 0.5 + 0.001)
	_rim.add_child(screen_mesh)

	_led_root = Node3D.new()
	_led_root.name = "ShiftLeds"
	_led_root.position = Vector3(0.0, BODY_SIZE.y * 0.5 - 0.012, BODY_SIZE.z * 0.5 + 0.002)
	_rim.add_child(_led_root)
	_build_leds()


func _build_leds() -> void:
	for child in _led_root.get_children():
		child.queue_free()
	_led_materials.clear()
	var box := BoxMesh.new()
	box.size = Vector3(LED_SIZE, LED_SIZE, 0.004)
	var spacing := LED_ROW_WIDTH / shift_light_count
	for i in shift_light_count:
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.albedo_color = HudDraw.COLOR_OFF
		_led_materials.append(material)
		var led := MeshInstance3D.new()
		led.mesh = box
		led.material_override = material
		led.position = Vector3(-LED_ROW_WIDTH * 0.5 + spacing * (i + 0.5), 0.0, 0.0)
		_led_root.add_child(led)


func _add_box(parent: Node3D, box_size: Vector3, pos: Vector3, material: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = box_size
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = pos
	parent.add_child(instance)
	return instance


func _material(color: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material
