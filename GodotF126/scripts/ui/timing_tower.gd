class_name TimingTower
extends PanelContainer
## Torre de tiempos de la carrera (Paso 47), a la izquierda del HUD: posición, franja del
## equipo, código del piloto, distancia al líder (la fila del líder dice la vuelta) y
## penalización. La fila del jugador va resaltada. Paso 49: letra del compuesto puesto, en su
## color.

const WIDTH := 232.0
const ROW_HEIGHT := 19.0
const COLOR_PLAYER := Color(1, 1, 1, 0.18)
const COLOR_PENALTY := Color(1.0, 0.35, 0.3)
const COLOR_FINISHED := Color(0.75, 0.35, 1.0)

var _list: VBoxContainer
var _rows: Array[Dictionary] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.03, 0.05, 0.72)
	style.set_corner_radius_all(4)
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	add_theme_stylebox_override("panel", style)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 0)
	_list.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_list)


func show_rows(rows: Array[Dictionary]) -> void:
	while _rows.size() < rows.size():
		_rows.append(_make_row())
	for i in _rows.size():
		var row := _rows[i]
		var box: ColorRect = row["box"]
		box.visible = i < rows.size()
		if not box.visible:
			continue
		var data := rows[i]
		row["pos"].text = str(data["pos"])
		row["stripe"].color = data["color"]
		row["code"].text = str(data["code"])
		row["tyre"].text = str(data.get("tyre", ""))
		row["tyre"].add_theme_color_override("font_color", data.get("tyre_color", Color.WHITE))
		row["gap"].text = str(data["gap"])
		row["gap"].add_theme_color_override("font_color", COLOR_FINISHED if data["finished"] else Color(0.85, 0.86, 0.9))
		var penalty := float(data["penalty"])
		row["penalty"].text = "+%ds" % roundi(penalty) if penalty > 0.0 else ""
		box.color = COLOR_PLAYER if data["player"] else Color(0, 0, 0, 0)


func _make_row() -> Dictionary:
	var box := ColorRect.new()
	box.custom_minimum_size = Vector2(WIDTH - 12.0, ROW_HEIGHT)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_list.add_child(box)
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 5)
	line.set_anchors_preset(Control.PRESET_FULL_RECT)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(line)
	var pos := _label(22.0, HORIZONTAL_ALIGNMENT_RIGHT)
	line.add_child(pos)
	var stripe := ColorRect.new()
	stripe.custom_minimum_size = Vector2(4, ROW_HEIGHT - 4.0)
	stripe.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	stripe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_child(stripe)
	var code := _label(40.0)
	line.add_child(code)
	var tyre := _label(14.0, HORIZONTAL_ALIGNMENT_CENTER)
	line.add_child(tyre)
	var gap := _label(84.0, HORIZONTAL_ALIGNMENT_RIGHT)
	line.add_child(gap)
	var penalty := _label(30.0, HORIZONTAL_ALIGNMENT_RIGHT)
	penalty.add_theme_color_override("font_color", COLOR_PENALTY)
	line.add_child(penalty)
	return {"box": box, "pos": pos, "stripe": stripe, "code": code, "tyre": tyre, "gap": gap, "penalty": penalty}


func _label(width: float, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new()
	label.custom_minimum_size = Vector2(width, ROW_HEIGHT)
	label.horizontal_alignment = align
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
