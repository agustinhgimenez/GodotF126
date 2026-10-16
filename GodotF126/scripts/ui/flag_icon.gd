class_name FlagIcon
extends Control
## Bandera simplificada dibujada en _draw() a partir de data/flags.json (Paso 12).
## Franjas horizontales o verticales y encima figuras: círculo, cruz, aspa (saltire),
## rombo y rectángulo, cada una dentro de una región de la bandera.

const FLAGS_PATH := "res://data/flags.json"

static var _flags: Dictionary = {}

var _flag: Dictionary = {}


func _init() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_country(code: String) -> void:
	_flag = get_flag(code)
	queue_redraw()


static func get_flag(code: String) -> Dictionary:
	if _flags.is_empty():
		_flags = DataLoader.load_json(FLAGS_PATH).get("flags", {})
	var flag = _flags.get(code.to_upper(), {})
	return flag if flag is Dictionary else {}


static func country_name(code: String) -> String:
	return str(get_flag(code).get("name", code))


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	if _flag.is_empty():
		draw_rect(rect, Color(0.3, 0.3, 0.32))
	else:
		_draw_stripes(rect)
		for overlay in _flag.get("overlays", []):
			if overlay is Dictionary:
				_draw_overlay(overlay, rect)
	draw_rect(rect, Color(0, 0, 0, 0.6), false, 1.0)


func _draw_stripes(rect: Rect2) -> void:
	var colors: Array = _flag.get("colors", ["#808080"])
	var weights: Array = _flag.get("weights", [])
	var total := 0.0
	for i in colors.size():
		total += _weight(weights, i)
	var vertical := str(_flag.get("stripes", "h")) == "v"
	var offset := 0.0
	for i in colors.size():
		var fraction := _weight(weights, i) / total
		var stripe := Rect2(rect.position, rect.size)
		if vertical:
			stripe.position.x += offset * rect.size.x
			stripe.size.x = fraction * rect.size.x
		else:
			stripe.position.y += offset * rect.size.y
			stripe.size.y = fraction * rect.size.y
		draw_rect(stripe, Color.html(str(colors[i])))
		offset += fraction


func _draw_overlay(overlay: Dictionary, rect: Rect2) -> void:
	var region := _region(overlay.get("region", []), rect)
	var color := Color.html(str(overlay.get("color", "#FFFFFF")))
	var center_data = overlay.get("center", [0.5, 0.5])
	var center := region.position + Vector2(float(center_data[0]), float(center_data[1])) * region.size
	match str(overlay.get("shape", "")):
		"rect":
			draw_rect(region, color)
		"circle":
			draw_circle(center, float(overlay.get("radius", 0.1)) * region.size.y, color)
		"cross":
			var w := float(overlay.get("width", 0.2)) * region.size.y
			draw_rect(Rect2(region.position.x, center.y - w * 0.5, region.size.x, w), color)
			draw_rect(Rect2(center.x - w * 0.5, region.position.y, w, region.size.y), color)
		"saltire":
			var w := float(overlay.get("width", 0.2)) * region.size.y
			draw_line(region.position, region.end, color, w)
			draw_line(Vector2(region.end.x, region.position.y), Vector2(region.position.x, region.end.y), color, w)
		"diamond":
			var inset := float(overlay.get("inset", 0.1))
			var mid := region.get_center()
			draw_colored_polygon(PackedVector2Array([
				Vector2(mid.x, region.position.y + inset * region.size.y),
				Vector2(region.end.x - inset * region.size.x, mid.y),
				Vector2(mid.x, region.end.y - inset * region.size.y),
				Vector2(region.position.x + inset * region.size.x, mid.y),
			]), color)


func _region(data, rect: Rect2) -> Rect2:
	if not (data is Array and data.size() == 4):
		return rect
	return Rect2(rect.position + Vector2(float(data[0]), float(data[1])) * rect.size,
		Vector2(float(data[2]), float(data[3])) * rect.size)


func _weight(weights: Array, i: int) -> float:
	return float(weights[i]) if i < weights.size() else 1.0
