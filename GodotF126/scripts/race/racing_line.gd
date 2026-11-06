class_name RacingLine
extends MeshInstance3D
## Línea de trazada ideal (Paso 38), calculada al cargar la pista.
## Trayectoria: un desplazamiento lateral por punto del centerline que minimiza la curvatura
## (cada punto va hacia (4 · vecinos a `span` − vecinos a 2 · `span`) / 6, de vecinos lejanos
## a cercanos, sin pasar de media pista − `margin`): abre antes de la curva, toca el vértice
## y sale abierta.
## Velocidad objetivo: la de curva con el agarre del auto (`grip_fraction` × μ × (g + carga
## aerodinámica / masa)), hasta la máxima del limitador, y hacia atrás la frenada
## (`brake_fraction` × el mismo agarre + arrastre). Se dibuja como una cinta sobre el
## asfalto; el shader (shaders/racing_line.gdshader) la pinta según la velocidad del auto:
## verde acelerá, amarillo levantá, rojo frená. Modos: "full", "braking" (sólo amarillo y
## rojo) y "off". Datos en el bloque "racing_line" de data/tracks.json.

const SHADER_PATH := "res://shaders/racing_line.gdshader"
const MODES := ["full", "braking", "off"]
## Velocidad que se guarda en los puntos sin límite (rectas al limitador): siempre verde.
const FREE_SPEED := 999.0
const G := 9.8

var margin: float = 1.5
var spans: PackedInt32Array = PackedInt32Array([24, 12, 6, 3])
var iterations: int = 60
var curvature_span: float = 6.0
var grip_fraction: float = 0.8
var brake_fraction: float = 0.85
var width: float = 0.7
var height: float = 0.035
var view_ahead: float = 280.0
var view_behind: float = 12.0
var fade: float = 60.0
var yellow_kmh: float = 15.0
var red_kmh: float = 5.0
var opacity: float = 0.8

var mode: String = "braking"
## Por punto del centerline: desplazamiento lateral (+ derecha), punto de la línea sobre el
## asfalto, curvatura (1/m), velocidad objetivo (m/s) y metros desde el índice 0.
var offsets: PackedFloat32Array = PackedFloat32Array()
var points: PackedVector3Array = PackedVector3Array()
var curvature: PackedFloat32Array = PackedFloat32Array()
var target_speed: PackedFloat32Array = PackedFloat32Array()
var distances: PackedFloat32Array = PackedFloat32Array()
var top_speed: float = 0.0
## ms que tardó el último cálculo de la trayectoria.
var build_ms: float = 0.0

var _track: BakuTrack
var _car: CarController
var _limits: TrackLimits
var _material: ShaderMaterial


func configure(data: Dictionary) -> void:
	for key in ["margin", "curvature_span", "grip_fraction", "brake_fraction", "width", "height", "view_ahead",
			"view_behind", "fade", "yellow_kmh", "red_kmh", "opacity"]:
		if data.has(key):
			set(key, maxf(float(data[key]), 0.0))
	iterations = maxi(int(data.get("iterations", iterations)), 0)
	var span_data = data.get("spans", [])
	if span_data is Array and not span_data.is_empty():
		spans = PackedInt32Array()
		for s in span_data:
			spans.append(maxi(int(s), 1))


func setup(track: BakuTrack, car: CarController, limits: TrackLimits) -> void:
	_track = track
	_car = car
	_limits = limits
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_material = ShaderMaterial.new()
	_material.shader = load(SHADER_PATH)
	material_override = _material
	var start := Time.get_ticks_usec()
	_compute_path()
	build_ms = (Time.get_ticks_usec() - start) / 1000.0
	refresh_speeds()
	set_mode(mode)


## Recalcula la velocidad objetivo (después de cambiar el setup o el compuesto).
func refresh_speeds() -> void:
	_compute_speeds()
	_build_mesh()
	_update_uniforms()


func set_mode(new_mode: String) -> void:
	mode = new_mode if new_mode in MODES else "braking"
	visible = mode != "off"
	if _material:
		_material.set_shader_parameter("braking_only", 1.0 if mode == "braking" else 0.0)


## Siguiente modo de la lista (tecla L).
static func next_mode(current: String) -> String:
	var index := MODES.find(current)
	return MODES[(index + 1) % MODES.size()]


static func mode_name(value: String) -> String:
	return {"full": "completa", "braking": "sólo frenadas", "off": "no"}.get(value, value)


## 0 verde, 1 amarillo, 2 rojo en el punto i con el auto a `speed` m/s (como el shader).
func color_state(i: int, speed: float) -> int:
	var u := _color_amount(shown_speed(i), speed)
	return 0 if u < 0.25 else (1 if u < 0.75 else 2)


## Velocidad objetivo que se dibuja en el punto i (FREE_SPEED cerca del limitador).
func shown_speed(i: int) -> float:
	return target_speed[i] if target_speed[i] < top_speed * 0.98 else FREE_SPEED


## Índice del centerline donde está el auto (−1 si no se sabe).
func car_index() -> int:
	return _limits.index if _limits != null else -1


func _process(_delta: float) -> void:
	if visible and _material != null:
		_update_uniforms()


func _update_uniforms() -> void:
	if _material == null or _car == null:
		return
	var i := car_index()
	_material.set_shader_parameter("car_speed", absf(_car.forward_speed))
	_material.set_shader_parameter("car_distance", distances[i] if i >= 0 and i < distances.size() else -1e6)


func _color_amount(target: float, speed: float) -> float:
	var yellow := yellow_kmh / 3.6
	var red := red_kmh / 3.6
	return clampf((speed - target + yellow) / maxf(yellow + red, 0.01), 0.0, 1.0)


func _compute_path() -> void:
	var n := _track.centerline.size()
	var centers := PackedVector2Array()
	var rights := PackedVector2Array()
	var limits := PackedFloat32Array()
	centers.resize(n)
	rights.resize(n)
	limits.resize(n)
	offsets.resize(n)
	distances.resize(n)
	var travelled := 0.0
	for i in n:
		var c := _track.centerline[i]
		var r := _track.right_vector(i)
		centers[i] = Vector2(c.x, c.z)
		rights[i] = Vector2(r.x, r.z)
		limits[i] = maxf(_track.half_width(i) - margin, 0.0)
		offsets[i] = 0.0
		distances[i] = travelled
		travelled += c.distance_to(_track.centerline[(i + 1) % n])
	var path := centers.duplicate()
	for span in spans:
		for iteration in iterations:
			for i in n:
				var wanted := ((path[(i - span + n) % n] + path[(i + span) % n]) * 4.0
					- path[(i - 2 * span + n) % n] - path[(i + 2 * span) % n]) / 6.0
				var offset := clampf((wanted - centers[i]).dot(rights[i]), -limits[i], limits[i])
				offsets[i] = offset
				path[i] = centers[i] + rights[i] * offset
	points.resize(n)
	for i in n:
		points[i] = _track.edge_point(i, offsets[i], 0.0)
	# Curvatura: ángulo entre las cuerdas a ±curvature_span m (en planta) / largo.
	curvature.resize(n)
	var step := maxi(roundi(curvature_span / maxf(travelled / n, 0.01)), 1)
	for i in n:
		var a := points[(i - step + n) % n]
		var b := points[i]
		var c := points[(i + step) % n]
		var ab := Vector2(b.x - a.x, b.z - a.z)
		var bc := Vector2(c.x - b.x, c.z - b.z)
		curvature[i] = absf(ab.angle_to(bc)) / maxf((ab.length() + bc.length()) * 0.5, 0.01)


func _compute_speeds() -> void:
	target_speed = speeds_for(_car)
	top_speed = _car.get_top_speed()


## Velocidad objetivo por índice para el auto `car` (agarre, aero y velocidad máxima de su
## setup y compuesto); la IA del Paso 45 la calcula con su propio auto.
func speeds_for(car: CarController) -> PackedFloat32Array:
	var n := points.size()
	var compound: Dictionary = car.tyres.compound()
	var mu := car.tyre_mu * float(compound.get("grip", 1.0))
	var aero := 0.5 * car.air_density * car.cla / car.mass
	var drag := 0.5 * car.air_density * car.cda / car.mass
	var top := car.get_top_speed()
	var speeds := PackedFloat32Array()
	speeds.resize(n)
	for i in n:
		var lateral := grip_fraction * mu
		var room := curvature[i] - lateral * aero
		var v := top
		if room > 0.0:
			v = minf(sqrt(lateral * G / room), top)
		speeds[i] = v
	# Frenada hacia atrás (dos vueltas: la pista es cerrada).
	for lap in 2:
		for k in n:
			var i := n - 1 - k
			var next := (i + 1) % n
			var v_next := speeds[next]
			var decel := brake_fraction * mu * (G + aero * v_next * v_next) + drag * v_next * v_next
			var ds := Vector2(points[next].x - points[i].x, points[next].z - points[i].z).length()
			speeds[i] = minf(speeds[i], sqrt(v_next * v_next + 2.0 * decel * ds))
	return speeds


func _build_mesh() -> void:
	var n := points.size()
	if n < 3:
		mesh = null
		return
	var vertices := PackedVector3Array()
	var uvs := PackedVector2Array()
	var uvs2 := PackedVector2Array()
	var indices := PackedInt32Array()
	var total := distances[n - 1] + _track.centerline[n - 1].distance_to(_track.centerline[0])
	for k in n + 1:
		var i := k % n
		var speed := shown_speed(i)
		var distance := distances[i] if k < n else total
		for side in [-1.0, 1.0]:
			vertices.append(_track.edge_point(i, offsets[i] + side * width * 0.5, height))
			uvs.append(Vector2(speed, distance))
			uvs2.append(Vector2(0.0 if side < 0.0 else 1.0, 0.0))
		if k < n:
			var base := k * 2
			indices.append_array([base, base + 1, base + 2, base + 1, base + 3, base + 2])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_TEX_UV2] = uvs2
	arrays[Mesh.ARRAY_INDEX] = indices
	var array_mesh := ArrayMesh.new()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh = array_mesh
	_material.set_shader_parameter("track_length", total)
	_material.set_shader_parameter("view_ahead", view_ahead)
	_material.set_shader_parameter("view_behind", view_behind)
	_material.set_shader_parameter("fade", fade)
	_material.set_shader_parameter("yellow_span", yellow_kmh / 3.6)
	_material.set_shader_parameter("red_margin", red_kmh / 3.6)
	_material.set_shader_parameter("opacity", opacity)
