class_name BakuTrack
extends Node3D
## Circuito placeholder inspirado en Bakú, generado por código.
## NO es el layout oficial FIA: recta larga junto al mar + sector cerrado
## de curvas de 90° y una chicana estrecha tipo "castillo".
## Coordenadas en metros sobre el plano XZ (Y hacia arriba).
## Paso 19: en las curvas (radio menor a corner_radius) hay pianos a los dos lados y
## escapatoria del lado de afuera, con el muro más lejos. Parámetros en data/tracks.json
## ("layout"). La línea blanca es el límite de pista.

## checkpoint 0 = meta; 1..SECTOR_COUNT-1 = fin de cada sector.
signal checkpoint_crossed(checkpoint: int, body: Node3D)

const SECTOR_COUNT := 3

const CONTROL_POINTS := [
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

const START_LINE_POINT := Vector3(-150, 0, 0)
const SPAWN_POINT := Vector3(-165, 0, 0)
## Altura del travesaño del pórtico de largada (de ahí cuelga el semáforo).
const GANTRY_HEIGHT := 7.2

const ASPHALT_COLOR := Color(0.16, 0.16, 0.18)
const LINE_COLOR := Color(0.95, 0.95, 0.95)
const RUNOFF_COLOR := Color(0.2, 0.21, 0.24)
const KERB_RED := Color(0.85, 0.08, 0.08)
const KERB_WHITE := Color(0.95, 0.95, 0.95)
const BARRIER_RED := Color(0.85, 0.1, 0.1)
const BARRIER_WHITE := Color(0.92, 0.92, 0.92)

@export var track_name: String = "Azerbaiyán — Bakú (placeholder)"
@export var track_width: float = 12.0
@export var edge_line_width: float = 0.35
@export var wall_height: float = 1.2
@export var wall_thickness: float = 0.6
@export var resample_step: float = 22.0
@export var smooth_iterations: int = 4
@export var barrier_segment_length: float = 6.0
@export var track_id: String = "baku"

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

var _rights: PackedVector3Array = PackedVector3Array()


func _ready() -> void:
	_load_layout()
	_ensure_centerline()
	_compute_layout()
	_build_ground_and_sea()
	_build_runoff()
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
	var i := _nearest_index(SPAWN_POINT)
	var heading := Basis.looking_at(_tangent(i), Vector3.UP)
	return Transform3D(heading, centerline[i] + Vector3(0, 0.6, 0))


func get_start_line_transform() -> Transform3D:
	_ensure_centerline()
	var i := _nearest_index(START_LINE_POINT)
	return Transform3D(Basis.looking_at(_tangent(i), Vector3.UP), centerline[i])


## Lugar de la grilla para largada detenida: `distance` metros detrás de la línea.
func get_grid_transform(distance: float) -> Transform3D:
	var line := get_start_line_transform()
	return Transform3D(line.basis, line.origin + line.basis.z * distance + Vector3(0, 0.6, 0))


## Distancia del centro a la cara interna del muro en el índice i (side −1 izq., +1 der.).
func wall_offset(i: int, side: float) -> float:
	return wall_right[i] if side > 0.0 else wall_left[i]


func half_width() -> float:
	return track_width * 0.5


func has_kerb(i: int) -> bool:
	return kerb_mask[i] > 0.0


## Índice del centerline más cercano a `pos` y desplazamiento lateral (+ derecha).
## Con `hint` >= 0 busca sólo cerca de ese índice (el auto no salta de lugar).
func locate(pos: Vector3, hint: int = -1) -> Vector2:
	var n := centerline.size()
	var flat := Vector3(pos.x, 0.0, pos.z)
	var best := 0
	var best_dist := INF
	if hint >= 0:
		for k in range(-40, 41):
			var i := (hint + k + n) % n
			var d := centerline[i].distance_squared_to(flat)
			if d < best_dist:
				best_dist = d
				best = i
	# Sin pista o lejos de la zona buscada (el auto fue movido): búsqueda completa.
	var limit := half_width() + verge + runoff_width + 5.0
	if best_dist > limit * limit:
		best_dist = INF
		for i in n:
			var d := centerline[i].distance_squared_to(flat)
			if d < best_dist:
				best_dist = d
				best = i
	return Vector2(best, (flat - centerline[best]).dot(_rights[best]))


# --- Trazado -----------------------------------------------------------------

func _load_layout() -> void:
	for info in DataLoader.load_json(DataLoader.TRACKS_PATH).get("tracks", []):
		if str(info.get("id", "")) != track_id:
			continue
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


## Curvatura por índice → dónde hay curva, hacia qué lado, y a qué distancia va el muro.
func _compute_layout() -> void:
	var n := centerline.size()
	var spacing := track_length / n
	var window := maxi(int(curvature_window / spacing), 1)
	var curvature := PackedFloat32Array()
	curvature.resize(n)
	for i in n:
		var before := _tangent((i - window + n) % n)
		var after := _tangent((i + window) % n)
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
	var base := track_width * 0.5 + verge
	wall_left = PackedFloat32Array()
	wall_right = PackedFloat32Array()
	wall_left.resize(n)
	wall_right.resize(n)
	for i in n:
		wall_left[i] = base + runoff_width * open_left[i]
		wall_right[i] = base + runoff_width * open_right[i]


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
	var points: Array[Vector2] = []
	for p in CONTROL_POINTS:
		points.append(p)
	points = _resample_closed(points, resample_step)
	for _i in smooth_iterations:
		points = _chaikin_closed(points)

	centerline = PackedVector3Array()
	for p in points:
		centerline.append(Vector3(p.x, 0.0, p.y))

	_rights = PackedVector3Array()
	track_length = 0.0
	var n := centerline.size()
	for i in n:
		_rights.append(_tangent(i).cross(Vector3.UP).normalized())
		track_length += centerline[i].distance_to(centerline[(i + 1) % n])


func _resample_closed(points: Array[Vector2], step: float) -> Array[Vector2]:
	var result: Array[Vector2] = [points[0]]
	var n := points.size()
	var dist_since_last := 0.0
	for i in n:
		var a := points[i]
		var b := points[(i + 1) % n]
		var seg := a.distance_to(b)
		var t := step - dist_since_last
		while t < seg:
			result.append(a.lerp(b, t / seg))
			t += step
		dist_since_last = seg - (t - step)
	if result.size() > 1 and result[result.size() - 1].distance_to(result[0]) < step * 0.5:
		result.pop_back()
	return result


func _chaikin_closed(points: Array[Vector2]) -> Array[Vector2]:
	var result: Array[Vector2] = []
	var n := points.size()
	for i in n:
		var a := points[i]
		var b := points[(i + 1) % n]
		result.append(a.lerp(b, 0.25))
		result.append(a.lerp(b, 0.75))
	return result


func _tangent(i: int) -> Vector3:
	var n := centerline.size()
	return (centerline[(i + 1) % n] - centerline[(i - 1 + n) % n]).normalized()


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
		var d := centerline[i].distance_squared_to(target)
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
	box.size = Vector3(3000, 2, 3000)
	shape.shape = box
	shape.position = Vector3(0, -1, 0)
	ground.add_child(shape)

	var ground_mesh := PlaneMesh.new()
	ground_mesh.size = Vector2(3000, 3000)
	var ground_visual := MeshInstance3D.new()
	ground_visual.mesh = ground_mesh
	ground_visual.position = Vector3(0, -0.01, 0)
	ground_visual.material_override = _make_material(Color(0.62, 0.58, 0.5))
	ground.add_child(ground_visual)

	# Mar Caspio al sur de la recta principal.
	var sea_mesh := PlaneMesh.new()
	sea_mesh.size = Vector2(3000, 1400)
	var sea := MeshInstance3D.new()
	sea.name = "CaspianSea"
	sea.mesh = sea_mesh
	sea.position = Vector3(0, 0.0, 740)
	var sea_material := _make_material(Color(0.1, 0.35, 0.55))
	sea_material.roughness = 0.2
	sea_material.metallic = 0.3
	sea.material_override = sea_material
	add_child(sea)


func _build_asphalt() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half := track_width * 0.5
	var inner := half - edge_line_width
	var strips := [
		[-half, -inner, LINE_COLOR],
		[-inner, inner, ASPHALT_COLOR],
		[inner, half, LINE_COLOR],
	]
	var n := centerline.size()
	for i in n:
		var j := (i + 1) % n
		for strip in strips:
			var from: float = strip[0]
			var to: float = strip[1]
			var color: Color = strip[2]
			_add_quad(st,
				_edge(i, from, 0.02), _edge(i, to, 0.02),
				_edge(j, to, 0.02), _edge(j, from, 0.02),
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
	var half := track_width * 0.5
	var n := centerline.size()
	for i in n:
		var j := (i + 1) % n
		for side in [-1.0, 1.0]:
			var a := _edge(i, side * half, 0.015)
			var b := _edge(j, side * half, 0.015)
			var c := _edge(j, side * wall_offset(j, side), 0.015)
			var d := _edge(i, side * wall_offset(i, side), 0.015)
			_add_quad(st, a, b, c, d, Vector3.UP, RUNOFF_COLOR)
	var visual := MeshInstance3D.new()
	visual.name = "Runoff"
	visual.mesh = st.commit()
	visual.material_override = _make_material(Color.WHITE, true)
	add_child(visual)


## Pianos rojos y blancos a los dos lados en las curvas, apenas elevados y sin colisión.
func _build_kerbs() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half := track_width * 0.5
	var n := centerline.size()
	var distance := 0.0
	for i in n:
		var j := (i + 1) % n
		if has_kerb(i) and has_kerb(j):
			var stripe := int(floor(distance / kerb_stripe)) % 2
			var color := KERB_RED if stripe == 0 else KERB_WHITE
			for side in [-1.0, 1.0]:
				var in_a := _edge(i, side * half, 0.02)
				var in_b := _edge(j, side * half, 0.02)
				var top_in_a := _edge(i, side * half, kerb_height)
				var top_in_b := _edge(j, side * half, kerb_height)
				var top_out_a := _edge(i, side * (half + kerb_width), kerb_height)
				var top_out_b := _edge(j, side * (half + kerb_width), kerb_height)
				var out_a := _edge(i, side * (half + kerb_width), 0.015)
				var out_b := _edge(j, side * (half + kerb_width), 0.015)
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
			var orientation := Basis.looking_at(_tangent(idx), Vector3.UP)
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
	var cols := int(track_width / cell)
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
	var start_i := _nearest_index(START_LINE_POINT)
	var gantry_offset := maxf(wall_left[start_i], wall_right[start_i]) + wall_thickness + 1.0
	var gantry_color := Color(0.1, 0.12, 0.2)
	for side in [-1.0, 1.0]:
		_add_box(line, start.origin + right * gantry_offset * side + Vector3(0, 3.5, 0),
			Vector3(0.6, 7, 0.6), start.basis, gantry_color)
	_add_box(line, start.origin + Vector3(0, GANTRY_HEIGHT, 0),
		Vector3(gantry_offset * 2.0 + 0.6, 1.0, 0.8), start.basis, gantry_color)


func _build_checkpoints() -> void:
	var start_i := _nearest_index(START_LINE_POINT)
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
	var orientation := Basis.looking_at(_tangent(i), Vector3.UP)
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

	# Bloques de ciudad en el interior del circuito.
	var heights: Array[float] = [22.0, 35.0, 18.0, 42.0, 26.0]
	var xs: Array[float] = [-200.0, -120.0, -40.0, 40.0, 120.0]
	for k in xs.size():
		var h := heights[k]
		_add_box(scenery, Vector3(xs[k], h * 0.5, -100), Vector3(50, h, 120),
			Basis.IDENTITY, Color(0.78, 0.72, 0.6))

	# Ciudad vieja (murallas) detrás de la chicana del castillo.
	_add_box(scenery, Vector3(110, 6, -250), Vector3(110, 12, 30),
		Basis.IDENTITY, Color(0.82, 0.7, 0.5))

	# Placeholder de las Flame Towers.
	var tower_color := Color(0.25, 0.4, 0.65)
	var tower_positions := [Vector3(-110, 0, -470), Vector3(-60, 0, -490), Vector3(-10, 0, -470)]
	for p in tower_positions:
		var tower := MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.top_radius = 4.0
		mesh.bottom_radius = 16.0
		mesh.height = 150.0
		tower.mesh = mesh
		tower.position = p + Vector3(0, 75, 0)
		tower.material_override = _make_material(tower_color)
		scenery.add_child(tower)


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
