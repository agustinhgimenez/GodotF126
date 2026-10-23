class_name LightingRig
extends RefCounted
## Iluminación de la carrera (Paso 23): aplica un preset de data/lighting.json (sol, cielo
## procedural, luz ambiente, tonemap, neblina, brillo y colores del mar) y la parte que
## depende de la calidad gráfica (sombras y reflejos en pantalla).

const DATA_PATH := "res://data/lighting.json"
const TONEMAPS := {
	"linear": Environment.TONE_MAPPER_LINEAR,
	"reinhardt": Environment.TONE_MAPPER_REINHARDT,
	"filmic": Environment.TONE_MAPPER_FILMIC,
	"aces": Environment.TONE_MAPPER_ACES,
}


static func load_data() -> Dictionary:
	return DataLoader.load_json(DATA_PATH)


## Preset `id` (vacío o inexistente: el default del JSON).
static func get_preset(id: String) -> Dictionary:
	var data := load_data()
	var presets = data.get("presets", {})
	if not presets is Dictionary:
		return {}
	if not presets.has(id):
		id = str(data.get("default_preset", "sunset"))
	var preset = presets.get(id, {})
	return preset if preset is Dictionary else {}


## Dirección hacia la que viaja la luz del sol.
static func sun_direction(azimuth_deg: float, elevation_deg: float) -> Vector3:
	var az := deg_to_rad(azimuth_deg)
	var el := deg_to_rad(elevation_deg)
	var from := Vector3(sin(az) * cos(el), sin(el), -cos(az) * cos(el))
	return -from


## quality: perfil de data/settings.json ("shadows", "shadow_distance", "shadow_splits").
## Sin SSR: el proyecto usa gl_compatibility (PC del laboratorio); el mar refleja el cielo.
static func apply(env: Environment, sun: DirectionalLight3D, preset: Dictionary, quality: Dictionary,
		sea: GeometryInstance3D = null, ground: GeometryInstance3D = null) -> void:
	var s: Dictionary = _dict(preset, "sun")
	sun.light_color = _color(s, "color", Color.WHITE)
	sun.light_energy = float(s.get("energy", 1.0))
	var direction := sun_direction(float(s.get("azimuth", 200.0)), float(s.get("elevation", 50.0)))
	sun.global_transform = Transform3D(Basis.looking_at(direction, Vector3.UP), sun.global_position)
	sun.shadow_blur = float(s.get("shadow_blur", 1.0))
	apply_quality(env, sun, quality)

	var sky_data: Dictionary = _dict(preset, "sky")
	if env.sky and env.sky.sky_material is ProceduralSkyMaterial:
		var sky := env.sky.sky_material as ProceduralSkyMaterial
		sky.sky_top_color = _color(sky_data, "top_color", sky.sky_top_color)
		sky.sky_horizon_color = _color(sky_data, "horizon_color", sky.sky_horizon_color)
		sky.ground_horizon_color = _color(sky_data, "ground_horizon_color", sky.ground_horizon_color)
		sky.ground_bottom_color = _color(sky_data, "ground_bottom_color", sky.ground_bottom_color)
		sky.sky_curve = float(sky_data.get("curve", sky.sky_curve))
		sky.sky_energy_multiplier = float(sky_data.get("energy", 1.0))
		sky.sun_angle_max = float(sky_data.get("sun_angle_max", sky.sun_angle_max))

	var ambient: Dictionary = _dict(preset, "ambient")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_sky_contribution = float(ambient.get("sky_contribution", 1.0))
	env.ambient_light_energy = float(ambient.get("energy", 1.0))
	# La parte que no viene del cielo toma el color del horizonte.
	env.ambient_light_color = _color(sky_data, "horizon_color", Color.WHITE)

	var tone: Dictionary = _dict(preset, "tonemap")
	env.tonemap_mode = TONEMAPS.get(str(tone.get("mode", "filmic")), Environment.TONE_MAPPER_FILMIC)
	env.tonemap_exposure = float(tone.get("exposure", 1.0))
	env.tonemap_white = float(tone.get("white", 1.0))

	var fog: Dictionary = _dict(preset, "fog")
	env.fog_enabled = float(fog.get("density", 0.0)) > 0.0
	env.fog_density = float(fog.get("density", 0.0))
	env.fog_light_color = _color(fog, "color", Color(0.8, 0.8, 0.85))
	env.fog_light_energy = float(fog.get("energy", 1.0))
	env.fog_sun_scatter = float(fog.get("sun_scatter", 0.0))
	env.fog_aerial_perspective = float(fog.get("aerial_perspective", 0.0))
	env.fog_sky_affect = float(fog.get("sky_affect", 1.0))

	var glow: Dictionary = _dict(preset, "glow")
	env.glow_enabled = float(glow.get("intensity", 0.0)) > 0.0
	env.glow_intensity = float(glow.get("intensity", 0.8))
	env.glow_bloom = float(glow.get("bloom", 0.0))
	env.glow_hdr_threshold = float(glow.get("hdr_threshold", 1.0))

	if sea and sea.material_override is ShaderMaterial:
		var water := sea.material_override as ShaderMaterial
		var sea_data: Dictionary = _dict(preset, "sea")
		water.set_shader_parameter("deep_color", _color(sea_data, "deep_color", Color(0.05, 0.14, 0.2)))
		water.set_shader_parameter("shallow_color", _color(sea_data, "shallow_color", Color(0.11, 0.25, 0.32)))
		for key in ["roughness", "wave_strength", "wave_scale", "wave_speed"]:
			if sea_data.has(key):
				water.set_shader_parameter(key, float(sea_data[key]))
	if ground and ground.material_override is StandardMaterial3D and preset.has("ground_color"):
		(ground.material_override as StandardMaterial3D).albedo_color = Color.html(str(preset["ground_color"]))


## Sombras (distancia y cortes) según el perfil de calidad.
static func apply_quality(_env: Environment, sun: DirectionalLight3D, quality: Dictionary) -> void:
	sun.shadow_enabled = bool(quality.get("shadows", true))
	var distance := float(quality.get("shadow_distance", 250.0))
	if distance > 0.0:
		sun.directional_shadow_max_distance = distance
	var splits := int(quality.get("shadow_splits", 2))
	sun.directional_shadow_mode = (DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS if splits >= 4
		else DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS if splits == 2
		else DirectionalLight3D.SHADOW_ORTHOGONAL)


static func _dict(data: Dictionary, key: String) -> Dictionary:
	var value = data.get(key, {})
	return value if value is Dictionary else {}


static func _color(data: Dictionary, key: String, fallback: Color) -> Color:
	if not data.has(key):
		return fallback
	return Color.html(str(data[key]))
