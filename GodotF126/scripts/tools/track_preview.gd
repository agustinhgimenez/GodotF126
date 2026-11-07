extends Control
## Paso 53: vista en planta de las pistas generadas por TrackGenerator (sin mallas): muros,
## asfalto, curvas, puntos de control numerados, largada, sectores, calle de boxes con las cajas,
## zonas de modo recta, monumentos y los errores / avisos de la validación.
## ←/→ cambia de pista. Desde la consola:
##   Godot --path . res://scenes/track_preview.tscn -- --track prueba --save C:/tmp/prueba.png
## guarda la imagen y sale.

const PANEL_WIDTH := 360.0
const MARGIN := 40.0
const BACKGROUND := Color(0.07, 0.08, 0.1)
const ROAD := Color(0.36, 0.37, 0.4)
const WALL := Color(0.92, 0.92, 0.95)
const CORNER := Color(0.85, 0.15, 0.15)
const AERO := Color(0.2, 0.85, 0.35)
const PIT := Color(1.0, 0.6, 0.1)
const CONTROL := Color(1.0, 0.85, 0.2)
const SECTOR := Color(0.3, 0.7, 1.0)
const LANDMARK := Color(0.65, 0.55, 0.9)

var track: TrackGenerator
var track_ids := PackedStringArray()
var index := 0

var _save_path := ""
var _scale := 1.0
var _origin := Vector2.ZERO
var _min := Vector2.ZERO
var _panel: Label
var _font: Font


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_font = ThemeDB.fallback_font
	_panel = Label.new()
	_panel.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_panel.add_theme_font_size_override("font_size", 15)
	add_child(_panel)
	track_ids = TrackGenerator.generated_track_ids()
	var requested := ""
	var args := OS.get_cmdline_user_args()
	for k in args.size() - 1:
		if args[k] == "--track":
			requested = args[k + 1]
		elif args[k] == "--save":
			_save_path = args[k + 1]
	index = maxi(track_ids.find(requested), 0)
	show_track(index)
	if not _save_path.is_empty():
		for frame in 3:
			await RenderingServer.frame_post_draw
		var error := get_viewport().get_texture().get_image().save_png(_save_path)
		print("Vista previa %s -> %s (%s)" % [track.track_id, _save_path, error_string(error)])
		get_tree().quit()


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.is_pressed() or event.is_echo() or track_ids.is_empty():
		return
	var key := (event as InputEventKey).keycode
	if key == KEY_RIGHT:
		show_track((index + 1) % track_ids.size())
	elif key == KEY_LEFT:
		show_track((index - 1 + track_ids.size()) % track_ids.size())
	elif key == KEY_ESCAPE:
		get_tree().quit()


func show_track(i: int) -> void:
	index = i
	if track != null:
		track.queue_free()
	track = TrackGenerator.new()
	track.preview_only = true
	track.city_enabled = false
	if not track_ids.is_empty():
		track.track_id = track_ids[index]
	add_child(track)
	_panel.text = summary()
	_layout()
	queue_redraw()


## Texto del panel: datos de la pista, errores y avisos.
func summary() -> String:
	var lines := PackedStringArray()
	lines.append("%s  (%s)" % [track.track_name, track.track_id])
	lines.append("Pista %d de %d   ←/→ cambiar   Esc salir" % [index + 1, maxi(track_ids.size(), 1)])
	lines.append("")
	lines.append("Vuelta: %.0f m   Puntos de control: %d" % [track.track_length, track.control_points().size()])
	lines.append("Ancho: %.0f-%.0f m   Sentido: %s" % [_min_width(), track.max_width,
		"antihorario" if track.turning_sense() > 0.0 else "horario"])
	lines.append("Curvas con carteles: %d" % track.corner_starts.size())
	var teams: Array = DataLoader.load_json(DataLoader.GRID_PATH).get("teams", [])
	if track.has_pit_lane():
		lines.append("Calle de boxes: %d cajas cada %.1f m (%s)" % [teams.size(), track.pit_value("box_spacing", 18.0),
			"automática" if bool(track.track_info.get("pit_lane", {}).get("auto", false)) else "de tracks.json"])
	else:
		lines.append("Calle de boxes: no hay")
	var zones: Array = track.aero_zone_data().get("zones", [])
	lines.append("Zonas de modo recta: %d (%s)" % [zones.size(),
		"de tracks.json" if track.track_info.has("aero_zones") else "automáticas"])
	lines.append("Mar: %s   Monumentos: %d" % ["sí" if not track.sea_data.is_empty() else "no", track.landmarks.size()])
	lines.append("")
	if track.errors.is_empty() and track.warnings.is_empty():
		lines.append("Validación: sin errores ni avisos")
	for text in track.errors:
		lines.append("ERROR: " + text)
	for text in track.warnings:
		lines.append("Aviso: " + text)
	lines.append("")
	lines.append("Rojo: curvas   Verde: modo recta   Naranja: boxes")
	lines.append("Amarillo: puntos de control   Celeste: sectores")
	return "\n".join(lines)


func _min_width() -> float:
	var low := INF
	for w in track.widths:
		low = minf(low, w)
	return low if low < INF else 0.0


func _layout() -> void:
	var view := get_viewport_rect().size
	_panel.position = Vector2(view.x - PANEL_WIDTH + 10.0, 16.0)
	_panel.size = Vector2(PANEL_WIDTH - 24.0, view.y - 32.0)
	var low := Vector2(INF, INF)
	var high := Vector2(-INF, -INF)
	for i in track.centerline.size():
		for side in [-1.0, 1.0]:
			var p := _world(track.edge_point(i, side * track.wall_offset(i, side), 0.0))
			low = low.min(p)
			high = high.max(p)
	for c in track.control_points():
		low = low.min(Vector2(c[0], c[1]))
		high = high.max(Vector2(c[0], c[1]))
	var area := Vector2(view.x - PANEL_WIDTH - MARGIN * 2.0, view.y - MARGIN * 2.0)
	var extent := (high - low).max(Vector2.ONE)
	_scale = minf(area.x / extent.x, area.y / extent.y)
	_min = low
	_origin = Vector2(MARGIN, MARGIN) + (area - extent * _scale) * 0.5


func _world(p: Vector3) -> Vector2:
	return Vector2(p.x, p.z)


func _screen(p: Vector3) -> Vector2:
	return _origin + (_world(p) - _min) * _scale


func _screen2(p: Vector2) -> Vector2:
	return _origin + (p - _min) * _scale


func _draw() -> void:
	var view := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, view), BACKGROUND)
	draw_rect(Rect2(view.x - PANEL_WIDTH, 0.0, PANEL_WIDTH, view.y), Color(0.12, 0.13, 0.16))
	if track == null or track.centerline.is_empty():
		return
	var n := track.centerline.size()
	for i in n:
		var j := (i + 1) % n
		var quad := PackedVector2Array([
			_screen(track.edge_point(i, -track.half_width(i), 0.0)), _screen(track.edge_point(j, -track.half_width(j), 0.0)),
			_screen(track.edge_point(j, track.half_width(j), 0.0)), _screen(track.edge_point(i, track.half_width(i), 0.0))])
		draw_colored_polygon(quad, ROAD)
	_draw_pit_lane()
	for side in [-1.0, 1.0]:
		var wall := PackedVector2Array()
		for i in n + 1:
			var k := i % n
			wall.append(_screen(track.edge_point(k, side * track.wall_offset(k, side), 0.0)))
		draw_polyline(wall, WALL, 1.5, true)
	for i in n:
		if track.corner_mask[i] > 0.0:
			draw_line(_screen(track.centerline[i]), _screen(track.centerline[(i + 1) % n]), CORNER, 2.0)
	_draw_aero_zones()
	_draw_sectors()
	_draw_start()
	_draw_landmarks()
	_draw_control_points()
	for c in track.corner_starts.size():
		var i: int = track.corner_starts[c]
		var side := -track.turn_sign[i] if track.turn_sign[i] != 0.0 else 1.0
		var p := _screen(track.edge_point(i, side * (track.wall_offset(i, side) + 14.0 / _scale), 0.0))
		draw_string(_font, p + Vector2(-8, 5), "C%d" % (c + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, CORNER.lightened(0.4))


func _draw_pit_lane() -> void:
	if not track.has_pit_lane():
		return
	var n := track.centerline.size()
	var side := track.pit_side()
	for i in n:
		var j := (i + 1) % n
		if track.pit_open[i] < 0.99 or track.pit_open[j] < 0.99:
			continue
		var mid_i := (track.pit_lane_start(i) + track.pit_lane_end(i)) * 0.5
		var mid_j := (track.pit_lane_start(j) + track.pit_lane_end(j)) * 0.5
		draw_line(_screen(track.edge_point(i, side * mid_i, 0.0)), _screen(track.edge_point(j, side * mid_j, 0.0)), PIT, 2.0)
	var teams: Array = DataLoader.load_json(DataLoader.GRID_PATH).get("teams", [])
	var first_box := track.pit_value("first_box", -300.0)
	var spacing := track.pit_value("box_spacing", 18.0)
	for b in teams.size():
		var i := track._index_at_offset(first_box + spacing * b)
		var p := _screen(track.edge_point(i, side * track.pit_lane_end(i), 0.0))
		var half := maxf(spacing * _scale * 0.35, 2.0)
		draw_rect(Rect2(p - Vector2(half, half), Vector2(half, half) * 2.0), DataLoader.team_primary(teams[b]))


func _draw_aero_zones() -> void:
	var n := track.centerline.size()
	var length := track.track_length
	for zone in track.aero_zone_data().get("zones", []):
		var from := fposmod(float(zone.get("from", 0.0)), length)
		var to := fposmod(float(zone.get("to", 0.0)), length)
		for i in n:
			var s := fposmod(track.start_offset(i), length)
			var inside := (s >= from and s <= to) if from <= to else (s >= from or s <= to)
			if inside:
				var side := -track.pit_side()
				var off := track.half_width(i) * 0.5
				draw_line(_screen(track.edge_point(i, side * off, 0.0)),
					_screen(track.edge_point((i + 1) % n, side * off, 0.0)), AERO, 3.0)


func _draw_sectors() -> void:
	for c in track.checkpoint_indices.size():
		var i: int = track.checkpoint_indices[c]
		if c == 0:
			continue
		var a := _screen(track.edge_point(i, -track.wall_offset(i, -1.0) - 8.0 / _scale, 0.0))
		var b := _screen(track.edge_point(i, track.wall_offset(i, 1.0) + 8.0 / _scale, 0.0))
		draw_line(a, b, SECTOR, 3.0)
		draw_string(_font, b + Vector2(4, 4), "S%d" % (c + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, SECTOR)


func _draw_start() -> void:
	var i := track.start_index()
	var a := _screen(track.edge_point(i, -track.wall_offset(i, -1.0) - 6.0 / _scale, 0.0))
	var b := _screen(track.edge_point(i, track.wall_offset(i, 1.0) + 6.0 / _scale, 0.0))
	draw_line(a, b, Color.WHITE, 4.0)
	draw_line(a, b, Color.BLACK, 1.5)
	var ahead := _screen(track.centerline[track.index_at_distance(i, 30.0)])
	draw_line(_screen(track.centerline[i]), ahead, Color.WHITE, 2.0)
	draw_circle(ahead, 4.0, Color.WHITE)
	draw_string(_font, b + Vector2(6, 4), "Largada", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)


func _draw_landmarks() -> void:
	for mark in track.landmarks:
		if not mark is Dictionary:
			continue
		var p := _screen(TrackGenerator._vec3(mark.get("position", []), Vector3.ZERO))
		var radius := maxf(float(mark.get("clearance", 10.0)) * _scale, 3.0)
		draw_arc(p, radius, 0.0, TAU, 24, LANDMARK, 1.5)
		draw_circle(p, 3.0, LANDMARK)


func _draw_control_points() -> void:
	var points := track.control_points()
	var m := points.size()
	for k in m:
		var a := _screen2(Vector2(points[k][0], points[k][1]))
		var b := _screen2(Vector2(points[(k + 1) % m][0], points[(k + 1) % m][1]))
		draw_dashed_line(a, b, Color(CONTROL, 0.45), 1.0, 6.0)
	for k in m:
		var p := _screen2(Vector2(points[k][0], points[k][1]))
		draw_circle(p, 5.0, CONTROL)
		draw_string(_font, p + Vector2(7, -6), str(k), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, CONTROL)
