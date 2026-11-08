class_name CarSpray
extends GPUParticles3D
## Rocío detrás de un auto en pista mojada (Paso 56, data/weather.json "spray"): nada debajo
## de `min_speed`, todo desde `full_speed` (m/s), por el agua de la pista y la calidad.

var min_speed: float = 12.0
var full_speed: float = 70.0
## Más lejos de la cámara (m) no emite: casi no se ve y cuesta igual.
var view_distance: float = 80.0
var _scale: float = 1.0
var _car: CarController


func configure(data: Dictionary, wetness: float, quality: float) -> void:
	min_speed = float(data.get("min_speed", min_speed))
	full_speed = maxf(float(data.get("full_speed", full_speed)), min_speed + 1.0)
	view_distance = float(data.get("view_distance", view_distance))
	_scale = clampf(wetness, 0.0, 1.0) * clampf(quality, 0.0, 1.0)
	amount = maxi(int(data.get("amount", 40)), 1)
	lifetime = maxf(float(data.get("lifetime", 0.55)), 0.05)
	local_coords = false
	emitting = false
	amount_ratio = 0.0
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	visibility_aabb = AABB(Vector3(-8.0, -2.0, -4.0), Vector3(16.0, 8.0, 30.0))
	var offset = data.get("offset", [])
	position = Vector3(float(offset[0]), float(offset[1]), float(offset[2])) if offset is Array and offset.size() >= 3 \
		else Vector3(0.0, 0.35, 2.3)
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = Vector3(0.8, 0.15, 0.2)
	process.direction = Vector3(0.0, 0.35, 1.0)
	process.spread = 20.0
	process.initial_velocity_min = 4.0
	process.initial_velocity_max = 9.0
	process.gravity = Vector3(0.0, -3.0, 0.0)
	process.damping_min = 2.0
	process.damping_max = 4.0
	process.set("inherit_velocity_ratio", float(data.get("inherit", 0.6)))
	process.scale_min = 0.6
	process.scale_max = 1.3
	var grow := Curve.new()
	grow.add_point(Vector2(0.0, 0.4))
	grow.add_point(Vector2(1.0, 1.0))
	var grow_texture := CurveTexture.new()
	grow_texture.curve = grow
	process.scale_curve = grow_texture
	var fade := Gradient.new()
	fade.set_color(0, Color(1.0, 1.0, 1.0, 1.0))
	fade.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	var fade_texture := GradientTexture1D.new()
	fade_texture.gradient = fade
	process.color_ramp = fade_texture
	process_material = process
	var size := float(data.get("size", 0.9))
	var mesh := QuadMesh.new()
	mesh.size = Vector2(size, size)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	material.vertex_color_use_as_albedo = true
	var puff := Gradient.new()
	puff.set_color(0, Color(1.0, 1.0, 1.0, 1.0))
	puff.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	var puff_texture := GradientTexture2D.new()
	puff_texture.gradient = puff
	puff_texture.fill = GradientTexture2D.FILL_RADIAL
	puff_texture.fill_from = Vector2(0.5, 0.5)
	puff_texture.fill_to = Vector2(0.5, 0.0)
	puff_texture.width = 32
	puff_texture.height = 32
	material.albedo_texture = puff_texture
	var color := Color.from_string(str(data.get("color", "#D5DBE2")), Color.WHITE)
	color.a = clampf(float(data.get("alpha", 0.22)), 0.0, 1.0)
	material.albedo_color = color
	mesh.material = material
	draw_pass_1 = mesh


func bind_car(car: CarController) -> void:
	_car = car


func _process(_delta: float) -> void:
	if _car == null:
		return
	var ratio := clampf((absf(_car.forward_speed) - min_speed) / (full_speed - min_speed), 0.0, 1.0) * _scale
	var camera := get_viewport().get_camera_3d()
	if camera != null and camera.global_position.distance_squared_to(global_position) > view_distance * view_distance:
		ratio = 0.0
	amount_ratio = ratio
	emitting = ratio > 0.02
