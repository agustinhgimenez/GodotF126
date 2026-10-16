class_name CityBuilder
extends Node3D
## Ciudad alrededor del trazado (Paso 22), generada desde el centerline de BakuTrack:
## - Edificios en filas detrás de los muros, con tamaño, alto y color al azar (semilla fija).
##   Se descartan los que caen cerca de otra parte de la pista, sobre el mar, sobre una
##   tribuna o sobre otro edificio.
## - Tribunas escalonadas con techo en los tramos indicados en los datos.
## - Paneles de publicidad (textos genéricos, sin marcas reales) en la cara interna de los
##   muros de las rectas.
## Rendimiento: los edificios van en MultiMeshInstance3D por zona (una llamada de dibujo por
## zona). Lejos sólo quedan las cajas; las franjas de ventanas, los tanques de las terrazas y
## los textos de publicidad se dejan de dibujar con visibility_range_end (LOD).

const GRID := 40.0   ## celda del índice espacial del centerline (m)

var spacing: float = 30.0
var rows: int = 2
var setback: float = 6.0
var row_gap: float = 4.0
var width_range: Vector2 = Vector2(14, 26)
var depth_range: Vector2 = Vector2(12, 22)
var height_range: Vector2 = Vector2(10, 40)
var min_clearance: float = 3.0
var floor_height: float = 3.5
var seed_value: int = 2026
var palette: Array[Color] = [Color(0.82, 0.74, 0.6), Color(0.76, 0.68, 0.55), Color(0.88, 0.84, 0.76)]
var window_color: Color = Color(0.18, 0.2, 0.25)
var sea_edge: float = 30.0
var fill_spacing: float = 45.0   ## grilla de manzanas que rellena el interior (0 = sin relleno)
var fill_margin: float = 120.0   ## m alrededor del trazado que cubre la grilla
var fill_setback: float = 14.0   ## distancia mínima de la grilla al muro
var chunk_size: float = 160.0
var detail_distance: float = 320.0
var far_distance: float = 1600.0

var stands: Array = []
var stand_gap: float = 3.0
var stand_rows: int = 10
var stand_row_depth: float = 0.9
var stand_row_rise: float = 0.5
var stand_roof_height: float = 3.5
var stand_colors: Array[Color] = [Color(0.12, 0.3, 0.65), Color(0.9, 0.9, 0.92)]

var ad_length: float = 10.0
var ad_gap: float = 2.0
var ad_bottom: float = 0.15
var ad_height: float = 0.9
var ad_texts: PackedStringArray = PackedStringArray(["BAKU CITY CIRCUIT", "F126"])
var ad_colors: Array[Color] = [Color(0.1, 0.2, 0.5), Color(0.75, 0.1, 0.1)]
var ad_label_distance: float = 220.0

## Resultado, para pruebas y para otros sistemas.
var buildings: Array[Dictionary] = []    ## {"center": Vector2, "size": Vector3, "forward": Vector2}
var stand_ranges: Array[Dictionary] = [] ## {"name", "from", "to", "side"} en índices del centerline
var ad_count: int = 0
var chunk_count: int = 0

var _track: BakuTrack
var _grid: Dictionary = {}
var _obstacles: Array[Vector3] = []   ## (x, z, radio)
var _stand_mask_left: PackedByteArray = PackedByteArray()
var _stand_mask_right: PackedByteArray = PackedByteArray()


func configure(data: Dictionary) -> void:
	var b = data.get("buildings", {})
	if b is Dictionary:
		spacing = float(b.get("spacing", spacing))
		rows = int(b.get("rows", rows))
		setback = float(b.get("setback", setback))
		row_gap = float(b.get("row_gap", row_gap))
		width_range = _vec2(b.get("width", []), width_range)
		depth_range = _vec2(b.get("depth", []), depth_range)
		height_range = _vec2(b.get("height", []), height_range)
		min_clearance = float(b.get("min_clearance", min_clearance))
		floor_height = float(b.get("floor_height", floor_height))
		seed_value = int(b.get("seed", seed_value))
		palette = _colors(b.get("palette", []), palette)
		window_color = Color.html(str(b.get("window_color", window_color.to_html(false))))
		sea_edge = float(b.get("sea_edge", sea_edge))
		fill_spacing = float(b.get("fill_spacing", fill_spacing))
		fill_margin = float(b.get("fill_margin", fill_margin))
		fill_setback = float(b.get("fill_setback", fill_setback))
	var lod = data.get("lod", {})
	if lod is Dictionary:
		chunk_size = float(lod.get("chunk_size", chunk_size))
		detail_distance = float(lod.get("detail_distance", detail_distance))
		far_distance = float(lod.get("far_distance", far_distance))
		ad_label_distance = float(lod.get("ad_label_distance", ad_label_distance))
	var g = data.get("grandstands", {})
	if g is Dictionary:
		var list = g.get("list", [])
		stands = list if list is Array else []
		stand_gap = float(g.get("gap", stand_gap))
		stand_rows = int(g.get("rows", stand_rows))
		stand_row_depth = float(g.get("row_depth", stand_row_depth))
		stand_row_rise = float(g.get("row_rise", stand_row_rise))
		stand_roof_height = float(g.get("roof_height", stand_roof_height))
		stand_colors = _colors(g.get("colors", []), stand_colors)
	var ads = data.get("ads", {})
	if ads is Dictionary:
		ad_length = float(ads.get("length", ad_length))
		ad_gap = float(ads.get("gap", ad_gap))
		ad_bottom = float(ads.get("bottom", ad_bottom))
		ad_height = float(ads.get("height", ad_height))
		var texts = ads.get("texts", [])
		if texts is Array and not texts.is_empty():
			ad_texts = PackedStringArray(texts)
		ad_colors = _colors(ads.get("colors", []), ad_colors)


## obstacles: (x, z, radio) de lo que ya ocupa lugar (ciudad vieja, Flame Towers).
func build(track: BakuTrack, obstacles: Array[Vector3]) -> void:
	_track = track
	_obstacles = obstacles.duplicate()
	_index_centerline()
	var n := track.centerline.size()
	_stand_mask_left.resize(n)
	_stand_mask_right.resize(n)
	_stand_mask_left.fill(0)
	_stand_mask_right.fill(0)
	_build_grandstands()
	_build_buildings()
	_build_ads()


func is_grandstand(i: int, side: float) -> bool:
	var mask := _stand_mask_right if side > 0.0 else _stand_mask_left
	return i >= 0 and i < mask.size() and mask[i] == 1


# --- Índice espacial ---------------------------------------------------------

func _index_centerline() -> void:
	_grid.clear()
	for i in _track.centerline.size():
		var c := _track.centerline[i]
		var key := Vector2i(floori(c.x / GRID), floori(c.z / GRID))
		if not _grid.has(key):
			_grid[key] = PackedInt32Array()
		var list: PackedInt32Array = _grid[key]
		list.append(i)
		_grid[key] = list


## Distancia en planta de `p` a la cara externa del muro más cercano (INF si está lejos).
func _clearance(p: Vector2) -> float:
	var cell := Vector2i(floori(p.x / GRID), floori(p.y / GRID))
	var best := INF
	for dx in range(-1, 2):
		for dz in range(-1, 2):
			var key := cell + Vector2i(dx, dz)
			if not _grid.has(key):
				continue
			for i in _grid[key]:
				var c := _track.centerline[i]
				var wall := maxf(_track.wall_left[i], _track.wall_right[i]) + _track.wall_thickness
				best = minf(best, Vector2(c.x, c.z).distance_to(p) - wall)
	return best


## Altura del asfalto más cercano en las celdas vecinas (0 si la pista queda lejos).
func _nearby_height(p: Vector2) -> float:
	var cell := Vector2i(floori(p.x / GRID), floori(p.y / GRID))
	var best := INF
	var height := 0.0
	for dx in range(-1, 2):
		for dz in range(-1, 2):
			var key := cell + Vector2i(dx, dz)
			if not _grid.has(key):
				continue
			for i in _grid[key]:
				var c := _track.centerline[i]
				var d := Vector2(c.x, c.z).distance_squared_to(p)
				if d < best:
					best = d
					height = c.y
	return height


func _blocked(center: Vector2, radius: float) -> bool:
	for o in _obstacles:
		if Vector2(o.x, o.y).distance_to(center) < o.z + radius:
			return true
	return false


# --- Edificios ---------------------------------------------------------------

func _build_buildings() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var chunks := {}
	var n := _track.centerline.size()
	var travelled := 0.0
	var next := 0.0
	for i in n:
		travelled += _track.centerline[i].distance_to(_track.centerline[(i + 1) % n])
		if travelled < next:
			continue
		next = travelled + spacing * rng.randf_range(0.8, 1.2)
		for side in [-1.0, 1.0]:
			var lateral := _track.wall_offset(i, side) + _track.wall_thickness + setback
			for _row in rows:
				var w := rng.randf_range(width_range.x, width_range.y)
				var d := rng.randf_range(depth_range.x, depth_range.y)
				var h := rng.randf_range(height_range.x, height_range.y)
				var color := palette[rng.randi() % palette.size()]
				var t := _track.flat_tangent(i)
				var c3: Vector3 = _track.centerline[i] + _track.right_vector(i) * side * (lateral + d * 0.5)
				_try_building(chunks, Vector2(c3.x, c3.z), t, Vector3(d, h, w), color,
					_track.centerline[i].y, min_clearance)
				lateral += d + row_gap
	_fill_grid(chunks, rng)
	_flush_chunks(chunks)


## Manzanas alineadas a los ejes en lo que queda libre alrededor y dentro del circuito.
func _fill_grid(chunks: Dictionary, rng: RandomNumberGenerator) -> void:
	if fill_spacing <= 0.0:
		return
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for c in _track.centerline:
		lo = lo.min(Vector2(c.x, c.z))
		hi = hi.max(Vector2(c.x, c.z))
	lo -= Vector2.ONE * fill_margin
	hi += Vector2.ONE * fill_margin
	var x := lo.x
	while x <= hi.x:
		var z := lo.y
		while z <= hi.y:
			var w := rng.randf_range(width_range.x, width_range.y)
			var d := rng.randf_range(depth_range.x, depth_range.y)
			var h := rng.randf_range(height_range.x, height_range.y)
			var color := palette[rng.randi() % palette.size()]
			var jitter := Vector2(rng.randf_range(-4, 4), rng.randf_range(-4, 4))
			_try_building(chunks, Vector2(x, z) + jitter, Vector3.FORWARD, Vector3(d, h, w), color,
				-1.0, fill_setback)
			z += fill_spacing
		x += fill_spacing


## center en planta; forward: hacia dónde mira el lado largo; base_height: altura del asfalto
## cercano (el edificio arranca en Y = 0 y la supera, así se ve desde la subida al castillo);
## negativo = buscarla con locate() una vez aceptado el lugar.
func _try_building(chunks: Dictionary, center: Vector2, forward: Vector3, size: Vector3,
		color: Color, base_height: float, clearance: float) -> void:
	var t := forward
	var r := t.cross(Vector3.UP).normalized()
	var along := Vector2(t.x, t.z) * size.z * 0.5
	var across := Vector2(r.x, r.z) * size.x * 0.5
	for p in [center, center + along + across, center + along - across, center - along + across,
			center - along - across, center + along, center - along, center + across, center - across]:
		if p.y > sea_edge or _clearance(p) < clearance:
			return
	var radius := 0.5 * maxf(size.x, size.z)
	if _blocked(center, radius):
		return
	_obstacles.append(Vector3(center.x, center.y, radius))

	if base_height < 0.0:
		base_height = _nearby_height(center)
	var height := size.y + maxf(base_height, 0.0)
	var basis := Basis.looking_at(t, Vector3.UP)
	var key := Vector2i(floori(center.x / chunk_size), floori(center.y / chunk_size))
	if not chunks.has(key):
		chunks[key] = {"bodies": [], "details": []}
	var chunk: Dictionary = chunks[key]
	chunk["bodies"].append([Transform3D(basis * Basis.from_scale(Vector3(size.x, height, size.z)),
		Vector3(center.x, height * 0.5, center.y)), color])
	# Franjas de ventanas (un poco más anchas que el edificio) y tanque en la terraza.
	var y := 4.0
	var bands := 0
	while y < height - 2.0 and bands < 14:
		chunk["details"].append([Transform3D(basis * Basis.from_scale(Vector3(size.x + 0.2, 1.1, size.z + 0.2)),
			Vector3(center.x, y, center.y)), window_color])
		y += floor_height
		bands += 1
	chunk["details"].append([Transform3D(basis * Basis.from_scale(Vector3(size.x * 0.3, 2.0, size.z * 0.3)),
		Vector3(center.x, height + 1.0, center.y)), color.darkened(0.25)])
	buildings.append({"center": center, "size": Vector3(size.x, height, size.z), "forward": Vector2(t.x, t.z)})


func _flush_chunks(chunks: Dictionary) -> void:
	var box := BoxMesh.new()
	box.size = Vector3.ONE
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = 0.9
	box.material = material
	chunk_count = chunks.size()
	for key in chunks:
		var chunk: Dictionary = chunks[key]
		_add_multimesh("Buildings_%d_%d" % [key.x, key.y], box, chunk["bodies"], far_distance)
		_add_multimesh("Details_%d_%d" % [key.x, key.y], box, chunk["details"], detail_distance)


func _add_multimesh(node_name: String, mesh: Mesh, items: Array, range_end: float) -> void:
	if items.is_empty():
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh
	mm.instance_count = items.size()
	for k in items.size():
		mm.set_instance_transform(k, items[k][0])
		mm.set_instance_color(k, items[k][1])
	var instance := MultiMeshInstance3D.new()
	instance.name = node_name
	instance.multimesh = mm
	instance.visibility_range_end = range_end
	instance.visibility_range_end_margin = 20.0
	add_child(instance)


# --- Tribunas ----------------------------------------------------------------

## Cada tribuna: {"name", "from", "to", "side"}; from / to en metros desde la línea de largada
## (negativo = antes de la línea), side 1 = derecha, −1 = izquierda en sentido de carrera.
func _build_grandstands() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := _track.centerline.size()
	var start := _track.start_index()
	var built := 0
	for s in stands:
		if not s is Dictionary:
			continue
		var side := 1.0 if float(s.get("side", 1)) > 0.0 else -1.0
		var from := _track.index_at_distance(start, float(s.get("from", 0.0)))
		var to := _track.index_at_distance(start, float(s.get("to", 50.0)))
		var count := (to - from + n) % n
		stand_ranges.append({"name": str(s.get("name", "")), "from": from, "to": to, "side": side})
		var mask := _stand_mask_right if side > 0.0 else _stand_mask_left
		var post_every := maxi(int(12.0 / _track.sample_step), 1)
		for k in count:
			var i := (from + k) % n
			var j := (i + 1) % n
			mask[i] = 1
			var base_i := _track.wall_offset(i, side) + _track.wall_thickness + stand_gap
			var base_j := _track.wall_offset(j, side) + _track.wall_thickness + stand_gap
			var outward: Vector3 = _track.right_vector(i) * side
			for row in stand_rows:
				var y := 0.4 + row * stand_row_rise
				var color := stand_colors[row % stand_colors.size()]
				var in_i := base_i + row * stand_row_depth
				var in_j := base_j + row * stand_row_depth
				var a := _track.edge_point(i, side * in_i, y)
				var b := _track.edge_point(j, side * in_j, y)
				var c := _track.edge_point(j, side * (in_j + stand_row_depth), y)
				var d := _track.edge_point(i, side * (in_i + stand_row_depth), y)
				_quad(st, a, b, c, d, Vector3.UP, color)
				var down := Vector3(0, stand_row_rise if row > 0 else y, 0)
				_quad(st, a - down, b - down, b, a, -outward, color.darkened(0.3))
			# Pared trasera hasta el suelo y techo en voladizo.
			var back_i := base_i + stand_rows * stand_row_depth
			var back_j := base_j + stand_rows * stand_row_depth
			var top := 0.4 + stand_rows * stand_row_rise + 1.0
			var roof := top + stand_roof_height
			var wall_a := _track.edge_point(i, side * back_i, 0.0)
			var wall_b := _track.edge_point(j, side * back_j, 0.0)
			wall_a.y = -0.2
			wall_b.y = -0.2
			var wall_top := Vector3(0, _track.centerline[i].y + top + 0.2, 0)
			_quad(st, wall_a, wall_b, wall_b + wall_top, wall_a + wall_top, outward, Color(0.55, 0.56, 0.6))
			_quad(st, _track.edge_point(i, side * (base_i - 0.8), roof), _track.edge_point(j, side * (base_j - 0.8), roof),
				_track.edge_point(j, side * (back_j + 0.5), roof + 0.8), _track.edge_point(i, side * (back_i + 0.5), roof + 0.8),
				Vector3.UP, Color(0.85, 0.86, 0.9))
			if k % post_every == 0:
				var post_base := _track.edge_point(i, side * (back_i + 0.2), 0.0)
				_box(st, Vector3(post_base.x, (post_base.y + roof + 0.8) * 0.5, post_base.z),
					Vector3(0.3, post_base.y + roof + 0.8, 0.3), Color(0.4, 0.42, 0.46))
			if k % 4 == 0:
				var mid := _track.edge_point(i, side * (base_i + back_i) * 0.5, 0.0)
				_obstacles.append(Vector3(mid.x, mid.z, (back_i - base_i) * 0.5 + 3.0))
		built += 1
	if built == 0:
		return
	var instance := MeshInstance3D.new()
	instance.name = "Grandstands"
	instance.mesh = st.commit()
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.roughness = 0.9
	instance.material_override = material
	instance.visibility_range_end = far_distance
	add_child(instance)


# --- Publicidad --------------------------------------------------------------

## Paneles en la cara interna del muro, sólo donde el muro corre paralelo a la pista
## (sin piano ni escapatoria) a lo largo de todo el panel.
func _build_ads() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := _track.centerline.size()
	var panel_points := maxi(int(ad_length / _track.sample_step), 2)
	var gap_points := maxi(int(ad_gap / _track.sample_step), 1)
	for side in [-1.0, 1.0]:
		var run := 0
		var i := 0
		while i < n:
			if _straight_wall(i, side):
				run += 1
			else:
				run = 0
			if run >= panel_points:
				_add_panel(st, (i - panel_points + 1 + n) % n, panel_points, side)
				run = -gap_points
			i += 1
	if ad_count == 0:
		return
	var instance := MeshInstance3D.new()
	instance.name = "AdPanels"
	instance.mesh = st.commit()
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = 0.6
	instance.material_override = material
	add_child(instance)


func _straight_wall(i: int, side: float) -> bool:
	if _track.has_kerb(i):
		return false
	return absf(_track.wall_offset(i, side) - (_track.half_width(i) + _track.verge)) < 0.05


func _add_panel(st: SurfaceTool, first: int, count: int, side: float) -> void:
	var n := _track.centerline.size()
	var color := ad_colors[ad_count % ad_colors.size()]
	for k in count - 1:
		var i := (first + k) % n
		var j := (i + 1) % n
		var lat_i := side * (_track.wall_offset(i, side) - 0.03)
		var lat_j := side * (_track.wall_offset(j, side) - 0.03)
		_quad(st, _track.edge_point(i, lat_i, ad_bottom), _track.edge_point(j, lat_j, ad_bottom),
			_track.edge_point(j, lat_j, ad_bottom + ad_height), _track.edge_point(i, lat_i, ad_bottom + ad_height),
			-_track.right_vector(i) * side, color)
	var mid := (first + count / 2) % n
	var facing := -_track.right_vector(mid) * side
	var label := Label3D.new()
	label.text = ad_texts[ad_count % ad_texts.size()]
	label.font_size = 64
	label.pixel_size = ad_height * 0.6 / 64.0
	label.outline_size = 0
	label.modulate = Color.WHITE
	label.double_sided = false
	label.visibility_range_end = ad_label_distance
	label.transform = Transform3D(Basis(Vector3.UP.cross(facing), Vector3.UP, facing),
		_track.edge_point(mid, side * (_track.wall_offset(mid, side) - 0.06), ad_bottom + ad_height * 0.5))
	add_child(label)
	ad_count += 1


# --- Utilidades --------------------------------------------------------------

func _quad(st: SurfaceTool, v0: Vector3, v1: Vector3, v2: Vector3, v3: Vector3, normal: Vector3, color: Color) -> void:
	for v in [v0, v1, v2, v0, v2, v3]:
		st.set_color(color)
		st.set_normal(normal)
		st.add_vertex(v)


func _box(st: SurfaceTool, center: Vector3, size: Vector3, color: Color) -> void:
	var h := size * 0.5
	var x := Vector3(h.x, 0, 0)
	var y := Vector3(0, h.y, 0)
	var z := Vector3(0, 0, h.z)
	for axis in [[x, y, z], [-x, y, -z], [z, y, -x], [-z, y, x]]:
		var o: Vector3 = center + axis[0]
		_quad(st, o - axis[2] - axis[1], o + axis[2] - axis[1], o + axis[2] + axis[1], o - axis[2] + axis[1],
			axis[0].normalized(), color)


static func _vec2(value, fallback: Vector2) -> Vector2:
	if value is Array and value.size() >= 2:
		return Vector2(float(value[0]), float(value[1]))
	return fallback


static func _colors(value, fallback: Array[Color]) -> Array[Color]:
	if not value is Array or value.is_empty():
		return fallback
	var result: Array[Color] = []
	for c in value:
		result.append(Color.html(str(c)))
	return result
