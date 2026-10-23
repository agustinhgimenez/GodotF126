class_name BakuTrack
extends Node3D
## Circuito inspirado en Bakú, generado por código.
## NO es el layout oficial FIA: es una aproximación a escala reducida (recta larga junto al
## mar, ángulos rectos de la ciudad, subida al sector estrecho del castillo y bajada).
## Coordenadas en metros: X / Z en el plano, Y hacia arriba.
## Paso 19: en las curvas (radio menor a corner_radius) hay pianos a los dos lados y
## escapatoria del lado de afuera, con el muro más lejos. La línea blanca es el límite.
## Paso 21: los puntos de control salen de data/tracks.json ("centerline"), cada uno con
## ancho de pista, altura y cuánta escapatoria admite; todo se interpola por el trazado.

## checkpoint 0 = meta; 1..SECTOR_COUNT-1 = fin de cada sector.
signal checkpoint_crossed(checkpoint: int, body: Node3D)

const SECTOR_COUNT := 3

## Respaldo si tracks.json no trae "centerline" (trazado del Paso 2, plano y de ancho fijo).
const FALLBACK_POINTS := [
	Vector2(-250, 0),
	Vector2(320, 0),
	Vector2(345, -25),
	Vector2(345, -85),
	Vector2(320, -110),
	Vector2(250, -110),
	Vector2(225, -135),
	Vector2(225, -175),
	Vector2(200, -200),
	Vector2(140, -200),
	Vector2(115, -175),
	Vector2(85, -175),
	Vector2(60, -200),
	Vector2(-150, -200),
	Vector2(-280, -170),
	Vector2(-330, -110),
	Vector2(-320, -35),
	Vector2(-290, -5),
]

## Altura del travesaño del pórtico de largada (de ahí cuelga el semáforo).
const GANTRY_HEIGHT := 7.2

const ASPHALT_COLOR := Color(0.16, 0.16, 0.18)
const LINE_COLOR := Color(0.95, 0.95, 0.95)
const RUNOFF_COLOR := Color(0.2, 0.21, 0.24)
const KERB_RED := Color(0.85, 0.08, 0.08)
const KERB_WHITE := Color(0.95, 0.95, 0.95)
const BARRIER_RED := Color(0.85, 0.1, 0.1)
const BARRIER_WHITE := Color(0.92, 0.92, 0.92)
const STONE_COLOR := Color(0.72, 0.62, 0.46)
const SEA_SHADER := "res://shaders/sea.gdshader"
## Lado del suelo (y ancho del mar): con la neblina, el borde no se ve desde la pista.
const GROUND_SIZE := 8000.0

@export var track_name: String = "Azerbaiyán — Bakú (placeholder)"
@export var track_width: float = 12.0          ## ancho por defecto de los puntos sin ancho propio
@export var edge_line_width: float = 0.35
@export var wall_height: float = 1.2
@export var wall_thickness: float = 0.6
@export var sample_step: float = 1.4             ## m entre puntos del centerline
@export var default_corner_radius: float = 16.0  ## radio de las esquinas sin radio propio
@export var attribute_smoothing: float = 20.0    ## m para suavizar altura y ancho
@export var barrier_segment_length: float = 6.0
@export var track_id: String = "baku"
@export var start_point: Vector3 = Vector3(-150, 0, 0)
@export var spawn_point: Vector3 = Vector3(-165, 0, 0)
@export var city_enabled: bool = true            ## Paso 22: edificios, tribunas y publicidad

@export_group("Pianos y escapatorias")
@export var corner_radius: float = 120.0       ## por debajo de este radio es curva
@export var curvature_window: float = 8.0      ## m a cada lado para medir la curvatura
@export var kerb_width: float = 1.2
@export var kerb_height: float = 0.05          ## sólo visual: los pianos no tienen colisión
@export var kerb_stripe: float = 2.0
@export var kerb_extend: float = 10.0          ## m de piano antes y después de la curva
@export var verge: float = 1.6                 ## del borde de pista al muro en las rectas
@export var runoff_width: float = 9.0          ## escapatoria extra del lado de afuera
@export var runoff_ramp: float = 25.0          ## m en que el muro se abre y se cierra

@export_group("Carteles de frenado")
@export var board_distances: PackedFloat32Array = PackedFloat32Array([150.0, 100.0, 50.0])
@export var board_min_gap: float = 8.0         ## m mínimos entre el final de la curva anterior y un cartel
@export var board_min_corner_length: float = 8.0  ## curvas más cortas no llevan carteles
@export var board_wall_clearance: float = 0.9  ## m detrás del muro
@export var board_height: float = 2.3          ## altura del centro del panel
@export var board_width: float = 1.6
@export var board_panel_height: float = 1.1

var centerline: PackedVector3Array = PackedVector3Array()
var track_length: float = 0.0
var checkpoint_indices: PackedInt32Array = PackedInt32Array()
## Por índice del centerline: 1 si hay pianos, sentido de la curva (+1 izquierda, −1
## derecha) y distancia del centro a la cara interna del muro de cada lado.
var kerb_mask: PackedFloat32Array = PackedFloat32Array()
var turn_sign: PackedFloat32Array = PackedFloat32Array()
var wall_left: PackedFloat32Array = PackedFloat32Array()
var wall_right: PackedFloat32Array = PackedFloat32Array()
## 1 donde el radio es menor a corner_radius (la curva en sí, sin la extensión del piano).
var corner_mask: PackedFloat32Array = PackedFloat32Array()
## Índice donde empieza cada curva, en orden de carrera (Paso 20; la IA del Paso 44 los
## puede usar como puntos de frenado).
var corner_starts: PackedInt32Array = PackedInt32Array()
## Carteles armados: {"index", "distance", "corner"} por cada uno.
var brake_boards: Array[Dictionary] = []
## Por índice: ancho de pista (de línea blanca a línea blanca) y factor de escapatoria (0–1).
var widths: PackedFloat32Array = PackedFloat32Array()
var runoff_scale: PackedFloat32Array = PackedFloat32Array()
var max_width: float = 0.0
## Paso 22: ciudad generada (nodo "City"); null si city_enabled es false.
var city: CityBuilder
var city_data: Dictionary = {}

## Puntos de control: [x, z, ancho, altura, escapatoria, radio de la esquina].
var _control: Array[PackedFloat32Array] = []
var _rights: PackedVector3Array = PackedVector3Array()


func _ready() -> void:
	_load_layout()
	_ensure_centerline()
	_compute_layout()
	_build_ground_and_sea()
	_build_runoff()
	_build_road_collision()
	_build_asphalt()
	_build_kerbs()
	_build_walls()
	_find_corner_starts()
	_build_brake_boards()
	_build_start_line()
	_build_checkpoints()
	_build_scenery()


func get_spawn_transform() -> Transform3D:
	_ensure_centerline()
	var i := _nearest_index(spawn_point)
	var heading := Basis.looking_at(_tangent(i), Vector3.UP)
	return Transform3D(heading, centerline[i] + Vector3(0, 0.6, 0))


func get_start_line_transform() -> Transform3D:
	_ensure_centerline()
	var i := _nearest_index(start_point)
	return Transform3D(Basis.looking_at(_tangent(i), Vector3.UP), centerline[i])


## Lugar de la grilla para largada detenida: `distance` metros detrás de la línea.
func get_grid_transform(distance: float) -> Transform3D:
	var line := get_start_line_transform()
	return Transform3D(line.basis, line.origin + line.basis.z * distance + Vector3(0, 0.6, 0))


## Distancia del centro a la cara interna del muro en el índice i (side −1 izq., +1 der.).
func wall_offset(i: int, side: float) -> float:
	return wall_right[i] if side > 0.0 else wall_left[i]


## Media pista en el índice i (sin índice: la más ancha del trazado).
func half_width(i: int = -1) -> float:
	if i < 0 or i >= widths.size():
		return max_width * 0.5
	return widths[i] * 0.5


func has_kerb(i: int) -> bool:
	return kerb_mask[i] > 0.0


## Índice del centerline más cercano a `pos` y desplazamiento lateral (+ derecha).
## Con `hint` >= 0 busca sólo cerca de ese índice (el auto no salta de lugar).
func locate(pos: Vector3, hint: int = -1) -> Vector2:
	var n := centerline.size()
	var best := 0
	var best_dist := INF
	if hint >= 0:
		for k in range(-40, 41):
			var i := (hint + k + n) % n
			var d := _flat_distance_squared(centerline[i], pos)
			if d < best_dist:
				best_dist = d
				best = i
	# Sin pista o lejos de la zona buscada (el auto fue movido): búsqueda completa.
	var limit := half_width() + verge + runoff_width + 5.0
	if best_dist > limit * limit:
		best_dist = INF
		for i in n:
			var d := _flat_distance_squared(centerline[i], pos)
			if d < best_dist:
				best_dist = d
				best = i
	var offset := pos - centerline[best]
	offset.y = 0.0
	return Vector2(best, offset.dot(_rights[best]))


## Altura del asfalto en el índice i.
func elevation(i: int) -> float:
	return centerline[i].y


## Punto a `offset` m del centro (+ derecha) y `height` m sobre el asfalto en el índice i.
func edge_point(i: int, offset: float, height: float) -> Vector3:
	return _edge(i, offset, height)


func flat_tangent(i: int) -> Vector3:
	return _flat_tangent(i)


## Derecha en planta (sentido de carrera) en el índice i.
func right_vector(i: int) -> Vector3:
	return _rights[i]


func start_index() -> int:
	return _nearest_index(start_point)


## Índice a `distance` m de `from` siguiendo el trazado (negativo = hacia atrás).
func index_at_distance(from: int, distance: float) -> int:
	if distance >= 0.0:
		return _index_after_distance(from, distance)
	var n := centerline.size()
	var travelled := 0.0
	var i := from
	while travelled < -distance:
		var prev := (i - 1 + n) % n
		travelled += centerline[i].distance_to(centerline[prev])
		i = prev
	return i


## Hay tribuna detrás del muro de ese lado (las torres de TV la esquivan).
func is_grandstand(i: int, side: float) -> bool:
	return city != null and city.is_grandstand(i, side)


# --- Trazado -----------------------------------------------------------------

func _load_layout() -> void:
	_control.clear()
	for info in DataLoader.load_json(DataLoader.TRACKS_PATH).get("tracks", []):
		if str(info.get("id", "")) != track_id:
			continue
		var line = info.get("centerline", {})
		if line is Dictionary:
			_load_centerline(line)
		var city_info = info.get("city", {})
		if city_info is Dictionary:
			city_data = city_info
			city_enabled = city_enabled and bool(city_info.get("enabled", true))
		var boards = info.get("brake_boards", {})
		if boards is Dictionary:
			var distances = boards.get("distances", [])
			if distances is Array and not distances.is_empty():
				board_distances = PackedFloat32Array(distances)
			board_min_gap = float(boards.get("min_gap", board_min_gap))
			board_min_corner_length = float(boards.get("min_corner_length", board_min_corner_length))
			board_wall_clearance = float(boards.get("wall_clearance", board_wall_clearance))
			board_height = float(boards.get("height", board_height))
			board_width = float(boards.get("width", board_width))
			board_panel_height = float(boards.get("panel_height", board_panel_height))
		var data = info.get("layout", {})
		if not data is Dictionary:
			return
		corner_radius = float(data.get("corner_radius", corner_radius))
		curvature_window = float(data.get("curvature_window", curvature_window))
		kerb_width = float(data.get("kerb_width", kerb_width))
		kerb_height = float(data.get("kerb_height", kerb_height))
		kerb_stripe = float(data.get("kerb_stripe", kerb_stripe))
		kerb_extend = float(data.get("kerb_extend", kerb_extend))
		verge = float(data.get("verge", verge))
		runoff_width = float(data.get("runoff_width", runoff_width))
		runoff_ramp = float(data.get("runoff_ramp", runoff_ramp))


## Puntos [x, z] o [x, z, ancho, altura, escapatoria, radio]; lo que falte toma el valor
## por defecto.
func _load_centerline(line: Dictionary) -> void:
	track_width = float(line.get("width", track_width))
	sample_step = float(line.get("sample_step", sample_step))
	default_corner_radius = float(line.get("default_corner_radius", default_corner_radius))
	attribute_smoothing = float(line.get("attribute_smoothing", attribute_smoothing))
	var start = line.get("start", [])
	if start is Array and start.size() >= 2:
		start_point = Vector3(float(start[0]), 0.0, float(start[1]))
	var spawn = line.get("spawn", [])
	if spawn is Array and spawn.size() >= 2:
		spawn_point = Vector3(float(spawn[0]), 0.0, float(spawn[1]))
	var points = line.get("points", [])
	if not points is Array:
		return
	for p in points:
		if not p is Array or p.size() < 2:
			continue
		_control.append(PackedFloat32Array([
			float(p[0]), float(p[1]),
			float(p[2]) if p.size() > 2 else track_width,
			float(p[3]) if p.size() > 3 else 0.0,
			float(p[4]) if p.size() > 4 else 1.0,
			float(p[5]) if p.size() > 5 else default_corner_radius,
		]))


## Curvatura por índice → dónde hay curva, hacia qué lado, y a qué distancia va el muro.
func _compute_layout() -> void:
	var n := centerline.size()
	var spacing := track_length / n
	var window := maxi(int(curvature_window / spacing), 1)
	var curvature := PackedFloat32Array()
	curvature.resize(n)
	for i in n:
		var before := _flat_tangent((i - window + n) % n)
		var after := _flat_tangent((i + window) % n)
		curvature[i] = before.signed_angle_to(after, Vector3.UP) / (2.0 * window * spacing)

	var threshold := 1.0 / corner_radius
	var left_turn := PackedFloat32Array()
	var right_turn := PackedFloat32Array()
	left_turn.resize(n)
	right_turn.resize(n)
	for i in n:
		left_turn[i] = 1.0 if curvature[i] > threshold else 0.0
		right_turn[i] = 1.0 if curvature[i] < -threshold else 0.0
	corner_mask = PackedFloat32Array()
	corner_mask.resize(n)
	for i in n:
		corner_mask[i] = maxf(left_turn[i], right_turn[i])

	var extend := int(kerb_extend / spacing)
	var left_kerb := _moving_max(left_turn, extend)
	var right_kerb := _moving_max(right_turn, extend)
	kerb_mask = PackedFloat32Array()
	turn_sign = PackedFloat32Array()
	kerb_mask.resize(n)
	turn_sign.resize(n)
	for i in n:
		kerb_mask[i] = maxf(left_kerb[i], right_kerb[i])
		turn_sign[i] = left_kerb[i] - right_kerb[i]

	# Escapatoria: del lado de afuera (curva a la izquierda → afuera es la derecha).
	var ramp := int(runoff_ramp / spacing)
	var open_right := _moving_average(_moving_max(left_turn, extend), ramp)
	var open_left := _moving_average(_moving_max(right_turn, extend), ramp)
	wall_left = PackedFloat32Array()
	wall_right = PackedFloat32Array()
	wall_left.resize(n)
	wall_right.resize(n)
	for i in n:
		var base := widths[i] * 0.5 + verge
		var runoff := runoff_width * runoff_scale[i]
		wall_left[i] = base + runoff * open_left[i]
		wall_right[i] = base + runoff * open_right[i]


func _moving_max(values: PackedFloat32Array, radius: int) -> PackedFloat32Array:
	var n := values.size()
	var result := PackedFloat32Array()
	result.resize(n)
	for i in n:
		var m := 0.0
		for k in range(-radius, radius + 1):
			m = maxf(m, values[(i + k + n) % n])
		result[i] = m
	return result


func _moving_average(values: PackedFloat32Array, radius: int) -> PackedFloat32Array:
	var n := values.size()
	var result := PackedFloat32Array()
	result.resize(n)
	var count := 2 * radius + 1
	var sum := 0.0
	for k in range(-radius, radius + 1):
		sum += values[(k + n) % n]
	for i in n:
		result[i] = sum / count
		sum += values[(i + radius + 1) % n] - values[(i - radius + n) % n]
	return result


func _ensure_centerline() -> void:
	if not centerline.is_empty():
		return
	if _control.is_empty():
		_load_layout()
	var points: Array[PackedFloat32Array] = _control.duplicate()
	if points.is_empty():
		for p in FALLBACK_POINTS:
			points.append(PackedFloat32Array([p.x, p.y, track_width, 0.0, 1.0, default_corner_radius]))
	points = _resample_closed(_round_corners(points), sample_step)

	var n := points.size()
	var heights := PackedFloat32Array()
	widths = PackedFloat32Array()
	runoff_scale = PackedFloat32Array()
	for p in points:
		heights.append(p[3])
		widths.append(p[2])
		runoff_scale.append(clampf(p[4], 0.0, 1.0))
	# Sin quiebres de pendiente ni de ancho en los puntos de control.
	heights = _moving_average(heights, maxi(int(attribute_smoothing / sample_step), 1))
	widths = _moving_average(widths, maxi(int(attribute_smoothing * 0.5 / sample_step), 1))
	centerline = PackedVector3Array()
	max_width = 0.0
	for i in n:
		centerline.append(Vector3(points[i][0], heights[i], points[i][1]))
		max_width = maxf(max_width, widths[i])

	_rights = PackedVector3Array()
	track_length = 0.0
	for i in n:
		_rights.append(_tangent(i).cross(Vector3.UP).normalized())
		track_length += centerline[i].distance_to(centerline[(i + 1) % n])


## Los puntos son [x, z, ...]: las distancias se miden en planta y el resto se interpola.
func _resample_closed(points: Array[PackedFloat32Array], step: float) -> Array[PackedFloat32Array]:
	var result: Array[PackedFloat32Array] = [points[0]]
	var n := points.size()
	var dist_since_last := 0.0
	for i in n:
		var a := points[i]
		var b := points[(i + 1) % n]
		var seg := _plan_distance(a, b)
		var t := step - dist_since_last
		while t < seg:
			result.append(_lerp_point(a, b, t / seg))
			t += step
		dist_since_last = seg - (t - step)
	if result.size() > 1 and _plan_distance(result[result.size() - 1], result[0]) < step * 0.5:
		result.pop_back()
	return result


## Cambia cada vértice del polígono de control por un arco de su radio (p[5]), tangente a
## los dos tramos rectos. Si el radio no entra, se achica hasta usar el 45 % de cada tramo.
## El radio tiene que superar la distancia al muro de adentro o el muro se dobla sobre la pista.
func _round_corners(points: Array[PackedFloat32Array]) -> Array[PackedFloat32Array]:
	var result: Array[PackedFloat32Array] = []
	var n := points.size()
	for k in n:
		var prev := points[(k - 1 + n) % n]
		var p := points[k]
		var next := points[(k + 1) % n]
		var a := Vector2(prev[0], prev[1])
		var corner := Vector2(p[0], p[1])
		var b := Vector2(next[0], next[1])
		var len_in := a.distance_to(corner)
		var len_out := corner.distance_to(b)
		var d0 := (corner - a) / len_in
		var d1 := (b - corner) / len_out
		var turn := d0.angle_to(d1)
		if absf(turn) < 0.002:
			result.append(p)
			continue
		var radius := p[5]
		var t := radius * tan(absf(turn) * 0.5)
		var t_max := 0.45 * minf(len_in, len_out)
		if t > t_max:
			t = t_max
			radius = t / tan(absf(turn) * 0.5)
		var from := _lerp_point(prev, p, 1.0 - t / len_in)
		var to := _lerp_point(p, next, t / len_out)
		var arc_start := corner - d0 * t
		var center := arc_start + Vector2(-d0.y, d0.x) * signf(turn) * radius
		var start_angle := (arc_start - center).angle()
		var steps := maxi(int(radius * absf(turn) / (sample_step * 0.5)), 2)
		for s in steps + 1:
			var f := float(s) / steps
			var q := center + Vector2.from_angle(start_angle + turn * f) * radius
			var arc_point := _lerp_point(from, to, f)
			arc_point[0] = q.x
			arc_point[1] = q.y
			result.append(arc_point)
	return result


static func _lerp_point(a: PackedFloat32Array, b: PackedFloat32Array, t: float) -> PackedFloat32Array:
	var result := PackedFloat32Array()
	result.resize(a.size())
	for k in a.size():
		result[k] = lerpf(a[k], b[k], t)
	return result


static func _plan_distance(a: PackedFloat32Array, b: PackedFloat32Array) -> float:
	return Vector2(a[0], a[1]).distance_to(Vector2(b[0], b[1]))


static func _flat_distance_squared(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x, a.z).distance_squared_to(Vector2(b.x, b.z))


func _tangent(i: int) -> Vector3:
	var n := centerline.size()
	return (centerline[(i + 1) % n] - centerline[(i - 1 + n) % n]).normalized()


## Tangente en planta (sin la pendiente), para curvatura y orientación de carteles.
func _flat_tangent(i: int) -> Vector3:
	var t := _tangent(i)
	t.y = 0.0
	return t.normalized()


func _edge(i: int, offset: float, height: float) -> Vector3:
	return centerline[i] + _rights[i] * offset + Vector3(0, height, 0)


func _index_after_distance(start: int, distance: float) -> int:
	var n := centerline.size()
	var travelled := 0.0
	var i := start
	while travelled < distance:
		var j := (i + 1) % n
		travelled += centerline[i].distance_to(centerline[j])
		i = j
	return i


func _nearest_index(target: Vector3) -> int:
	var best := 0
	var best_dist := INF
	for i in centerline.size():
		var d := _flat_distance_squared(centerline[i], target)
		if d < best_dist:
			best_dist = d
			best = i
	return best


# --- Geometría ---------------------------------------------------------------

func _build_ground_and_sea() -> void:
	var ground := StaticBody3D.new()
	ground.name = "Ground"
	add_child(ground)

	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(GROUND_SIZE, 2, GROUND_SIZE)
	shape.shape = box
	shape.position = Vector3(0, -1, 0)
	ground.add_child(shape)

	var ground_mesh := PlaneMesh.new()
	ground_mesh.size = Vector2(GROUND_SIZE, GROUND_SIZE)
	var ground_visual := MeshInstance3D.new()
	ground_visual.name = "GroundVisual"
	ground_visual.mesh = ground_mesh
	ground_visual.position = Vector3(0, -0.01, 0)
	ground_visual.material_override = _make_material(Color(0.62, 0.58, 0.5))
	ground.add_child(ground_visual)

	# Mar Caspio al sur de la recta principal: shader de agua (colores según la luz, Paso 23).
	var sea_mesh := PlaneMesh.new()
	# Arranca en Z = 40 (la costa) y llega hasta el horizonte.
	sea_mesh.size = Vector2(GROUND_SIZE, GROUND_SIZE * 0.5)
	var sea := MeshInstance3D.new()
	sea.name = "CaspianSea"
	sea.mesh = sea_mesh
	sea.position = Vector3(0, 0.0, 40.0 + GROUND_SIZE * 0.25)
	var water := ShaderMaterial.new()
	water.shader = load(SEA_SHADER)
	sea.material_override = water
	add_child(sea)


func get_sea() -> MeshInstance3D:
	return get_node_or_null("CaspianSea") as MeshInstance3D


func get_ground_visual() -> MeshInstance3D:
	return get_node_or_null("Ground/GroundVisual") as MeshInstance3D


func _build_asphalt() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Franjas en fracciones de media pista: línea blanca, asfalto, línea blanca.
	var n := centerline.size()
	for i in n:
		var j := (i + 1) % n
		var half_i := half_width(i)
		var half_j := half_width(j)
		var strips := [
			[-half_i, -half_i + edge_line_width, -half_j, -half_j + edge_line_width, LINE_COLOR],
			[-half_i + edge_line_width, half_i - edge_line_width,
				-half_j + edge_line_width, half_j - edge_line_width, ASPHALT_COLOR],
			[half_i - edge_line_width, half_i, half_j - edge_line_width, half_j, LINE_COLOR],
		]
		for strip in strips:
			var color: Color = strip[4]
			_add_quad(st,
				_edge(i, strip[0], 0.02), _edge(i, strip[1], 0.02),
				_edge(j, strip[3], 0.02), _edge(j, strip[2], 0.02),
				Vector3.UP, color)

	var visual := MeshInstance3D.new()
	visual.name = "Asphalt"
	visual.mesh = st.commit()
	visual.material_override = _make_material(Color.WHITE, true)
	add_child(visual)


## Franja entre el borde de pista y el muro: angosta en las rectas, ancha afuera de las curvas.
func _build_runoff() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := centerline.size()
	for i in n:
		var j := (i + 1) % n
		for side in [-1.0, 1.0]:
			var a := _edge(i, side * half_width(i), 0.015)
			var b := _edge(j, side * half_width(j), 0.015)
			var c := _edge(j, side * wall_offset(j, side), 0.015)
			var d := _edge(i, side * wall_offset(i, side), 0.015)
			_add_quad(st, a, b, c, d, Vector3.UP, RUNOFF_COLOR)
	var visual := MeshInstance3D.new()
	visual.name = "Runoff"
	visual.mesh = st.commit()
	visual.material_override = _make_material(Color.WHITE, true)
	add_child(visual)


## Piso del auto de muro a muro, siguiendo la altura del trazado (el suelo general queda en Y = 0).
func _build_road_collision() -> void:
	var faces := PackedVector3Array()
	var n := centerline.size()
	for i in n:
		var j := (i + 1) % n
		var a := _edge(i, -wall_left[i], 0.0)
		var b := _edge(i, wall_right[i], 0.0)
		var c := _edge(j, wall_right[j], 0.0)
		var d := _edge(j, -wall_left[j], 0.0)
		faces.append_array([a, b, c, a, c, d])
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(faces)
	shape.backface_collision = true
	var road := StaticBody3D.new()
	road.name = "Road"
	add_child(road)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	road.add_child(collision)


## Pianos rojos y blancos a los dos lados en las curvas, apenas elevados y sin colisión.
func _build_kerbs() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := centerline.size()
	var distance := 0.0
	for i in n:
		var j := (i + 1) % n
		if has_kerb(i) and has_kerb(j):
			var stripe := int(floor(distance / kerb_stripe)) % 2
			var color := KERB_RED if stripe == 0 else KERB_WHITE
			var half_i := half_width(i)
			var half_j := half_width(j)
			for side in [-1.0, 1.0]:
				var in_a := _edge(i, side * half_i, 0.02)
				var in_b := _edge(j, side * half_j, 0.02)
				var top_in_a := _edge(i, side * half_i, kerb_height)
				var top_in_b := _edge(j, side * half_j, kerb_height)
				var top_out_a := _edge(i, side * (half_i + kerb_width), kerb_height)
				var top_out_b := _edge(j, side * (half_j + kerb_width), kerb_height)
				var out_a := _edge(i, side * (half_i + kerb_width), 0.015)
				var out_b := _edge(j, side * (half_j + kerb_width), 0.015)
				var outward: Vector3 = _rights[i] * side
				_add_quad(st, in_a, in_b, top_in_b, top_in_a, -outward, color)
				_add_quad(st, top_in_a, top_in_b, top_out_b, top_out_a, Vector3.UP, color)
				_add_quad(st, top_out_a, top_out_b, out_b, out_a, outward, color)
		distance += centerline[i].distance_to(centerline[j])
	var visual := MeshInstance3D.new()
	visual.name = "Kerbs"
	visual.mesh = st.commit()
	visual.material_override = _make_material(Color.WHITE, true)
	add_child(visual)


func _build_walls() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := centerline.size()
	var distance := 0.0
	for i in n:
		var j := (i + 1) % n
		var stripe := int(floor(distance / barrier_segment_length)) % 2
		var color := BARRIER_RED if stripe == 0 else BARRIER_WHITE
		for side in [-1.0, 1.0]:
			var in_a := _edge(i, side * wall_offset(i, side), 0.0)
			var in_b := _edge(j, side * wall_offset(j, side), 0.0)
			var out_a := _edge(i, side * (wall_offset(i, side) + wall_thickness), 0.0)
			var out_b := _edge(j, side * (wall_offset(j, side) + wall_thickness), 0.0)
			var up := Vector3(0, wall_height, 0)
			var outward: Vector3 = _rights[i] * side
			_add_quad(st, in_a, in_b, in_b + up, in_a + up, -outward, color)
			_add_quad(st, out_a, out_b, out_b + up, out_a + up, outward, color)
			_add_quad(st, in_a + up, in_b + up, out_b + up, out_a + up, Vector3.UP, color)
			# Donde la pista va en alto, murallón de piedra del muro hasta el suelo.
			if out_a.y > 0.05 or out_b.y > 0.05:
				var low_a := Vector3(out_a.x, -0.2, out_a.z)
				var low_b := Vector3(out_b.x, -0.2, out_b.z)
				_add_quad(st, low_a, low_b, out_b, out_a, outward, STONE_COLOR)
		distance += centerline[i].distance_to(centerline[j])

	var mesh := st.commit()
	var walls := StaticBody3D.new()
	walls.name = "Walls"
	add_child(walls)

	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.material_override = _make_material(Color.WHITE, true)
	walls.add_child(visual)

	var shape := mesh.create_trimesh_shape()
	shape.backface_collision = true
	var collision := CollisionShape3D.new()
	collision.shape = shape
	walls.add_child(collision)


## Inicio de cada tramo de curva de al menos board_min_corner_length metros.
func _find_corner_starts() -> void:
	corner_starts = PackedInt32Array()
	var n := centerline.size()
	var spacing := track_length / n
	var min_points := maxi(int(board_min_corner_length / spacing), 1)
	for i in n:
		if corner_mask[i] == 0.0 or corner_mask[(i - 1 + n) % n] > 0.0:
			continue
		var length := 0
		while length < min_points and corner_mask[(i + length) % n] > 0.0:
			length += 1
		if length >= min_points:
			corner_starts.append(i)


## Carteles 150 / 100 / 50 m antes de cada curva, del lado de afuera y detrás del muro,
## mirando al auto que llega. Sólo los que entran en la recta: a más de board_min_gap del
## final de la curva anterior (en la chicana del castillo quedan pocos o ninguno).
func _build_brake_boards() -> void:
	brake_boards.clear()
	var holder := Node3D.new()
	holder.name = "BrakeBoards"
	add_child(holder)
	var n := centerline.size()
	var farthest := 0.0
	for d in board_distances:
		farthest = maxf(farthest, d)

	var panel_mesh := BoxMesh.new()
	panel_mesh.size = Vector3(board_width, board_panel_height, 0.08)
	var pole_mesh := BoxMesh.new()
	pole_mesh.size = Vector3(0.12, board_height, 0.12)
	var white := _make_material(Color(0.97, 0.97, 0.97))
	var grey := _make_material(Color(0.35, 0.36, 0.4))

	for k in corner_starts.size():
		var start := corner_starts[k]
		# Recta disponible antes de la curva: hasta tocar la curva anterior.
		var marks := {}   # distancia → índice
		var travelled := 0.0
		var i := start
		var available := farthest + board_min_gap
		while travelled < farthest + board_min_gap:
			var prev := (i - 1 + n) % n
			travelled += centerline[i].distance_to(centerline[prev])
			i = prev
			if corner_mask[i] > 0.0:
				available = travelled
				break
			for d in board_distances:
				if not marks.has(d) and travelled >= d:
					marks[d] = i
		# Afuera de la curva: a la izquierda (+1) el lado de afuera es la derecha (+1).
		var side := signf(turn_sign[start]) if turn_sign[start] != 0.0 else 1.0
		for d in board_distances:
			if not marks.has(d) or d > available - board_min_gap:
				continue
			var idx: int = marks[d]
			var orientation := Basis.looking_at(_flat_tangent(idx), Vector3.UP)
			var lateral := wall_offset(idx, side) + wall_thickness + board_wall_clearance
			var base := _edge(idx, side * lateral, 0.0)
			var board := Node3D.new()
			board.name = "Board%d_%d" % [k, int(d)]
			board.transform = Transform3D(orientation, base)
			holder.add_child(board)

			var pole := MeshInstance3D.new()
			pole.mesh = pole_mesh
			pole.material_override = grey
			pole.position = Vector3(0, board_height * 0.5, 0.06)
			board.add_child(pole)
			var panel := MeshInstance3D.new()
			panel.mesh = panel_mesh
			panel.material_override = white
			panel.position = Vector3(0, board_height, 0)
			board.add_child(panel)
			var label := Label3D.new()
			label.text = str(int(d))
			label.font_size = 128
			label.pixel_size = board_panel_height * 0.0055
			label.modulate = Color(0.05, 0.05, 0.05)
			label.outline_size = 0
			label.double_sided = false
			label.position = Vector3(0, board_height, 0.045)
			board.add_child(label)
			brake_boards.append({"index": idx, "distance": d, "corner": start})


func _build_start_line() -> void:
	var start := get_start_line_transform()
	var right := start.basis.x
	var forward := -start.basis.z
	var cell := 1.0
	var start_i := _nearest_index(start_point)
	var cols := int(widths[start_i] / cell)
	var white := _make_material(Color.WHITE)
	var black := _make_material(Color(0.05, 0.05, 0.05))
	var cell_mesh := BoxMesh.new()
	cell_mesh.size = Vector3(cell, 0.02, cell)

	var line := Node3D.new()
	line.name = "StartLine"
	add_child(line)
	for row in 2:
		for col in cols:
			var square := MeshInstance3D.new()
			square.mesh = cell_mesh
			square.material_override = white if (row + col) % 2 == 0 else black
			var offset := (col - cols * 0.5 + 0.5) * cell
			var pos := start.origin + right * offset + forward * (row - 0.5) * cell + Vector3(0, 0.03, 0)
			square.transform = Transform3D(start.basis, pos)
			line.add_child(square)

	# Pórtico de largada.
	var gantry_offset := maxf(wall_left[start_i], wall_right[start_i]) + wall_thickness + 1.0
	var gantry_color := Color(0.1, 0.12, 0.2)
	for side in [-1.0, 1.0]:
		_add_box(line, start.origin + right * gantry_offset * side + Vector3(0, 3.5, 0),
			Vector3(0.6, 7, 0.6), start.basis, gantry_color)
	_add_box(line, start.origin + Vector3(0, GANTRY_HEIGHT, 0),
		Vector3(gantry_offset * 2.0 + 0.6, 1.0, 0.8), start.basis, gantry_color)


func _build_checkpoints() -> void:
	var start_i := _nearest_index(start_point)
	checkpoint_indices = PackedInt32Array([start_i])
	for s in range(1, SECTOR_COUNT):
		checkpoint_indices.append(_index_after_distance(start_i, track_length * s / SECTOR_COUNT))

	var holder := Node3D.new()
	holder.name = "Checkpoints"
	add_child(holder)
	for k in checkpoint_indices.size():
		var i := checkpoint_indices[k]
		var area := Area3D.new()
		area.name = "Finish" if k == 0 else "Sector%d" % k
		area.collision_layer = 0
		area.collision_mask = 1
		area.monitorable = false
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		# Cubre de muro a muro, incluida la escapatoria.
		box.size = Vector3(wall_left[i] + wall_right[i], 4.0, 1.5)
		shape.shape = box
		shape.position = Vector3((wall_right[i] - wall_left[i]) * 0.5, 2, 0)
		area.add_child(shape)
		area.transform = Transform3D(Basis.looking_at(_tangent(i), Vector3.UP), centerline[i])
		area.body_entered.connect(_on_checkpoint_body_entered.bind(k))
		holder.add_child(area)
		if k > 0:
			_add_sector_marker(holder, i, "S%d" % k)


func _add_sector_marker(parent: Node3D, i: int, text: String) -> void:
	var orientation := Basis.looking_at(_flat_tangent(i), Vector3.UP)
	for side in [-1.0, 1.0]:
		var base := _edge(i, side * (wall_offset(i, side) + wall_thickness + 0.6), 0.0)
		_add_box(parent, base + Vector3(0, 1.5, 0), Vector3(0.3, 3.0, 0.3), orientation, Color(1, 0.8, 0.1))
		var label := Label3D.new()
		label.text = text
		label.font_size = 64
		label.pixel_size = 0.02
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.position = base + Vector3(0, 3.8, 0)
		parent.add_child(label)


func _on_checkpoint_body_entered(body: Node3D, checkpoint: int) -> void:
	checkpoint_crossed.emit(checkpoint, body)


func _build_scenery() -> void:
	var scenery := Node3D.new()
	scenery.name = "Scenery"
	add_child(scenery)

	# Lo que ocupa lugar para la ciudad generada: (x, z, radio).
	var obstacles: Array[Vector3] = []

	# Ciudad vieja (Icherisheher): murallas dentro de la vuelta del castillo.
	_add_box(scenery, Vector3(-180, 10, -455), Vector3(140, 20, 50),
		Basis.IDENTITY, STONE_COLOR)
	obstacles.append(Vector3(-180, -455, 75))

	# Placeholder de las Flame Towers, en la colina al oeste.
	var tower_color := Color(0.25, 0.4, 0.65)
	var tower_positions := [Vector3(-620, 0, -450), Vector3(-570, 0, -480), Vector3(-520, 0, -450)]
	for p in tower_positions:
		obstacles.append(Vector3(p.x, p.z, 20))
		var tower := MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.top_radius = 4.0
		mesh.bottom_radius = 16.0
		mesh.height = 150.0
		tower.mesh = mesh
		tower.position = p + Vector3(0, 75, 0)
		tower.material_override = _make_material(tower_color)
		scenery.add_child(tower)

	if city_enabled:
		city = CityBuilder.new()
		city.name = "City"
		add_child(city)
		city.configure(city_data)
		city.build(self, obstacles)


# --- Utilidades --------------------------------------------------------------

func _add_quad(st: SurfaceTool, v0: Vector3, v1: Vector3, v2: Vector3, v3: Vector3,
		normal: Vector3, color: Color) -> void:
	for v in [v0, v1, v2, v0, v2, v3]:
		st.set_color(color)
		st.set_normal(normal)
		st.add_vertex(v)


func _add_box(parent: Node3D, pos: Vector3, size: Vector3, orientation: Basis, color: Color) -> void:
	var box := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	box.mesh = mesh
	box.transform = Transform3D(orientation, pos)
	box.material_override = _make_material(color)
	parent.add_child(box)


func _make_material(color: Color, use_vertex_color: bool = false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.vertex_color_use_as_albedo = use_vertex_color
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.roughness = 0.9
	return material
