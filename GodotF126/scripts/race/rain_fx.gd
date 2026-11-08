class_name RainFx
extends Node3D
## Lluvia (Paso 56): gotas en una caja que sigue a la cámara activa (data/weather.json,
## "rain_fx"). Las gotas se mueven con la caja; se inclinan contra el movimiento de la cámara
## para que se vean pasar a la velocidad del auto.

## Cuánto se inclinan las gotas por la velocidad de la cámara (como máximo `MAX_TILT`).
const DRIFT := 0.6
const MAX_TILT := deg_to_rad(60.0)

var particles: GPUParticles3D
var height: float = 12.0
var speed: float = 24.0
var _velocity := Vector3.ZERO
var _last := Vector3.ZERO
var _has_last: bool = false


## `intensity` (0–1) escala la cantidad de gotas ("max_drops").
func configure(data: Dictionary, intensity: float) -> void:
	top_level = true
	var box := _vec3(data.get("box", []), Vector3(44.0, 24.0, 44.0))
	height = float(data.get("height", height))
	speed = maxf(float(data.get("speed", speed)), 1.0)
	particles = GPUParticles3D.new()
	particles.name = "Drops"
	particles.amount = maxi(int(float(data.get("max_drops", 5000)) * clampf(intensity, 0.0, 1.0)), 1)
	particles.lifetime = box.y / speed
	particles.preprocess = particles.lifetime
	particles.local_coords = true
	particles.position = Vector3(0.0, height, 0.0)
	particles.visibility_aabb = AABB(Vector3(-box.x, -box.y * 1.5, -box.z), Vector3(box.x * 2.0, box.y * 2.0, box.z * 2.0))
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = Vector3(box.x * 0.5, 0.5, box.z * 0.5)
	process.direction = Vector3.DOWN
	process.spread = 2.0
	process.initial_velocity_min = speed * 0.9
	process.initial_velocity_max = speed * 1.1
	process.gravity = Vector3.ZERO
	particles.process_material = process
	var mesh := QuadMesh.new()
	mesh.size = Vector2(float(data.get("drop_width", 0.02)), float(data.get("drop_length", 0.6)))
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	material.billboard_keep_scale = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	var color := Color.from_string(str(data.get("color", "#C8D2DC")), Color.WHITE)
	color.a = clampf(float(data.get("alpha", 0.35)), 0.0, 1.0)
	material.albedo_color = color
	mesh.material = material
	particles.draw_pass_1 = mesh
	add_child(particles)


func _process(delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var at := camera.global_position
	if _has_last and delta > 0.0:
		var moved := (at - _last) / delta
		moved.y = 0.0
		# Cambio de cámara o reaparición: no es velocidad.
		if moved.length() > 150.0:
			moved = _velocity
		_velocity = _velocity.lerp(moved, clampf(delta * 6.0, 0.0, 1.0))
	_last = at
	_has_last = true
	global_position = at
	var fall := Vector3(0.0, -speed, 0.0) - _velocity * DRIFT
	var angle := minf(Vector3.DOWN.angle_to(fall), MAX_TILT)
	var axis := Vector3.DOWN.cross(fall)
	global_basis = Basis(axis.normalized(), angle) if axis.length() > 0.001 else Basis.IDENTITY


static func _vec3(value, fallback: Vector3) -> Vector3:
	if value is Array and value.size() >= 3:
		return Vector3(float(value[0]), float(value[1]), float(value[2]))
	return fallback
