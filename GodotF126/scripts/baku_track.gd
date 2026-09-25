class_name BakuTrack
extends Node3D
## Circuito placeholder inspirado en Bakú, generado por código.
## NO es el layout oficial FIA: recta larga junto al mar + sector cerrado
## de curvas de 90° y una chicana estrecha tipo "castillo".
## Coordenadas en metros sobre el plano XZ (Y hacia arriba).

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

const ASPHALT_COLOR := Color(0.16, 0.16, 0.18)
const LINE_COLOR := Color(0.95, 0.95, 0.95)
const BARRIER_RED := Color(0.85, 0.1, 0.1)
const BARRIER_WHITE := Color(0.92, 0.92, 0.92)

@export var track_name: String = "Azerbaiyán — Bakú (placeholder)"
@export var track_width: float = 12.0
@export var edge_line_width: float = 0.35
@export var wall_gap: float = 0.4
@export var wall_height: float = 1.2
@export var wall_thickness: float = 0.6
@export var resample_step: float = 22.0
@export var smooth_iterations: int = 4
@export var barrier_segment_length: float = 6.0

var centerline: PackedVector3Array = PackedVector3Array()
var track_length: float = 0.0
var checkpoint_indices: PackedInt32Array = PackedInt32Array()

var _rights: PackedVector3Array = PackedVector3Array()


func _ready() -> void:
	_ensure_centerline()
	_build_ground_and_sea()
	_build_asphalt()
	_build_walls()
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


# --- Trazado -----------------------------------------------------------------

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


func _build_walls() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var inner_offset := track_width * 0.5 + wall_gap
	var outer_offset := inner_offset + wall_thickness
	var n := centerline.size()
	var distance := 0.0
	for i in n:
		var j := (i + 1) % n
		var stripe := int(floor(distance / barrier_segment_length)) % 2
		var color := BARRIER_RED if stripe == 0 else BARRIER_WHITE
		for side in [-1.0, 1.0]:
			var in_a := _edge(i, side * inner_offset, 0.0)
			var in_b := _edge(j, side * inner_offset, 0.0)
			var out_a := _edge(i, side * outer_offset, 0.0)
			var out_b := _edge(j, side * outer_offset, 0.0)
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
	var gantry_offset := track_width * 0.5 + wall_gap + wall_thickness + 1.0
	var gantry_color := Color(0.1, 0.12, 0.2)
	for side in [-1.0, 1.0]:
		_add_box(line, start.origin + right * gantry_offset * side + Vector3(0, 3.5, 0),
			Vector3(0.6, 7, 0.6), start.basis, gantry_color)
	_add_box(line, start.origin + Vector3(0, 7.2, 0),
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
		box.size = Vector3(track_width + wall_gap * 2.0, 4.0, 1.5)
		shape.shape = box
		shape.position = Vector3(0, 2, 0)
		area.add_child(shape)
		area.transform = Transform3D(Basis.looking_at(_tangent(i), Vector3.UP), centerline[i])
		area.body_entered.connect(_on_checkpoint_body_entered.bind(k))
		holder.add_child(area)
		if k > 0:
			_add_sector_marker(holder, i, "S%d" % k)


func _add_sector_marker(parent: Node3D, i: int, text: String) -> void:
	var orientation := Basis.looking_at(_tangent(i), Vector3.UP)
	var offset := track_width * 0.5 + wall_gap + wall_thickness + 0.6
	for side in [-1.0, 1.0]:
		var base := _edge(i, side * offset, 0.0)
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
