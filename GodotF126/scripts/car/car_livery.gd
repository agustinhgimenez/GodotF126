class_name CarLivery
extends Node3D
## Livery del auto (Paso 13): dos colores por equipo y número del piloto.
## - Color principal: mallas del grupo "team_paint" (carrocería, pontones, airbox, buzo).
## - Color secundario: grupo "team_paint_secondary" (alerones y las franjas que arma este nodo).
## - Número: Label3D sobre el morro, arriba de la cubierta del motor y a sus costados.
##   El color del número se elige para que contraste con el principal.
## Coordenadas en el espacio del auto (-Z adelante), igual que car.tscn.

const PRIMARY_GROUP := "team_paint"
const SECONDARY_GROUP := "team_paint_secondary"
const MIN_CONTRAST := 0.35   ## diferencia de luminancia mínima para usar el secundario en el número

## [posición, tamaño] de cada franja.
const STRIPES := [
	[Vector3(0.0, 0.448, -2.5), Vector3(0.16, 0.008, 1.2)],      # sobre el morro
	[Vector3(0.0, 0.648, -1.45), Vector3(0.22, 0.008, 1.1)],     # carrocería delante del cockpit
	[Vector3(-0.803, 0.4, 0.5), Vector3(0.008, 0.1, 1.8)],       # costado del pontón izquierdo
	[Vector3(0.803, 0.4, 0.5), Vector3(0.008, 0.1, 1.8)],        # costado del pontón derecho
]
## [posición, rotación en grados, píxel] de cada número.
const NUMBERS := [
	[Vector3(0.0, 0.455, -2.3), Vector3(-90, 0, 0), 0.0035],     # morro, acostado
	[Vector3(0.0, 0.98, 0.75), Vector3(-90, 0, 0), 0.0035],      # arriba de la cubierta del motor
	[Vector3(-0.205, 0.8, 0.75), Vector3(0, -90, 0), 0.0028],    # costado izquierdo de la cubierta
	[Vector3(0.205, 0.8, 0.75), Vector3(0, 90, 0), 0.0028],      # costado derecho de la cubierta
]

var _car: Node3D
var _numbers: Array[Label3D] = []


func _ready() -> void:
	_car = get_parent() as Node3D
	for stripe in STRIPES:
		_add_stripe(stripe[0], stripe[1])
	for entry in NUMBERS:
		_add_number(entry[0], entry[1], entry[2])


## number vacío = sin número (por ejemplo, eligiendo escudería en el menú).
func apply(primary: Color, secondary: Color, number: String) -> void:
	_paint(PRIMARY_GROUP, primary, 0.3, 0.4)
	_paint(SECONDARY_GROUP, secondary, 0.4, 0.35)
	var text_color := number_color(primary, secondary)
	var outline := Color.BLACK if text_color.get_luminance() > 0.5 else Color.WHITE
	for label in _numbers:
		label.text = number
		label.visible = not number.is_empty()
		label.modulate = text_color
		label.outline_modulate = outline


## Secundario si se distingue del principal; si no, blanco o negro según el principal.
static func number_color(primary: Color, secondary: Color) -> Color:
	if absf(secondary.get_luminance() - primary.get_luminance()) >= MIN_CONTRAST:
		return secondary
	return Color(0.06, 0.06, 0.06) if primary.get_luminance() > 0.55 else Color.WHITE


func _paint(group: String, color: Color, metallic: float, roughness: float) -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = roughness
	for node in _car.find_children("*", "MeshInstance3D", true, false):
		if node.is_in_group(group):
			(node as MeshInstance3D).material_override = material


func _add_stripe(pos: Vector3, box_size: Vector3) -> void:
	var mesh := BoxMesh.new()
	mesh.size = box_size
	var stripe := MeshInstance3D.new()
	stripe.mesh = mesh
	stripe.position = pos
	stripe.add_to_group(SECONDARY_GROUP)
	add_child(stripe)


func _add_number(pos: Vector3, rotation_deg: Vector3, pixel: float) -> void:
	var label := Label3D.new()
	label.position = pos
	label.rotation_degrees = rotation_deg
	label.pixel_size = pixel
	label.font_size = 64
	label.outline_size = 10
	label.alpha_cut = Label3D.ALPHA_CUT_DISCARD
	label.visible = false
	add_child(label)
	_numbers.append(label)
