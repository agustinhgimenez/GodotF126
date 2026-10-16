class_name CockpitDetail
extends Node3D
## Detalle del cockpit (Paso 8), armado por código con formas simples.
## - Halo: aro alrededor de la cabeza del piloto con el pilar central adelante.
##   Es parte del auto, así que se ve en todas las cámaras.
## - Espejos retrovisores: cada uno tiene un SubViewport con una Camera3D que mira hacia
##   atrás; la imagen se muestra espejada en el vidrio. Sólo se renderizan en Cockpit.
## - Casco: borde superior (visera) e inferior (mentonera) colgados de la cámara, más un
##   tinte suave del visor. Sólo en Cockpit. Están en la capa VISOR_LAYER, que las
##   cámaras de los espejos no ven.
## Coordenadas en el espacio del auto: -Z adelante, ojos del piloto en (0, 0.95, -0.55).

const VISOR_LAYER := 2

const HALO_THICKNESS := 0.035
const HALO_HOOP_CENTER := Vector3(0.0, 1.1, -0.45)
const HALO_HOOP_RADIUS := Vector2(0.4, 0.45)   ## semiejes del aro en X y Z
const HALO_HOOP_DROP := 0.1                     ## cuánto baja el aro hacia atrás
const HALO_HOOP_END_DEG := 120.0                ## 0° = adelante
const HALO_HOOP_SEGMENTS := 12
const HALO_PILLAR_BASE := Vector3(0.0, 0.65, -1.3)
const HALO_REAR_MOUNT := Vector3(0.3, 0.68, -0.1)   ## x se espeja para cada lado

const MIRROR_POSITION := Vector3(0.5, 0.84, -1.05)  ## x se espeja para cada lado
const MIRROR_SIZE := Vector2(0.16, 0.06)
const MIRROR_TOE_DEG := 15.0        ## el vidrio gira hacia el piloto
const MIRROR_VIEW_OUT_DEG := 12.0   ## la cámara del espejo mira un poco hacia afuera
const MIRROR_VIEW_DOWN := 0.04

const VISOR_DISTANCE := 0.12        ## delante de la cámara (near del Cockpit = 0.1)
const VISOR_HALF_WIDTH := 0.4
const VISOR_OUTER_Y := 0.3
const VISOR_SEGMENTS := 24
const VISOR_EDGE := 0.003
## Ancho visible a VISOR_DISTANCE con 16:9 y fov 80; las curvas del casco se miden con él.
const SCREEN_HALF_WIDTH := 0.18
const BRIM_Y := 0.088
const BRIM_CURVE := -0.022
const CHIN_Y := -0.096
const CHIN_CURVE := 0.016

@export var mirror_resolution: Vector2i = Vector2i(320, 120)
@export var mirror_fov: float = 24.0
@export var visor_tint: float = 0.08

var _camera: Camera3D
var _cockpit_view: bool = false
var _visor: Node3D
var _visor_tint_material: StandardMaterial3D
var _visor_tint_mesh: MeshInstance3D
var _mirror_viewports: Array[SubViewport] = []
var _mirror_cameras: Array[Camera3D] = []
var _mirror_eyes: Array[Node3D] = []
var _mirror_glasses: Array[MeshInstance3D] = []
var _mirror_live_materials: Array[StandardMaterial3D] = []
var _mirror_off_material: StandardMaterial3D


func _ready() -> void:
	_camera = get_node("../CameraPivot/Camera3D") as Camera3D
	var carbon := _material(Color(0.07, 0.07, 0.08), 0.5)
	_build_halo(carbon)
	_mirror_off_material = _material(Color(0.15, 0.17, 0.2), 0.1)
	_mirror_off_material.metallic = 0.8
	for side in [-1, 1]:
		_build_mirror(side, carbon)
	_build_visor()
	set_cockpit_view(false)


func configure(data: Dictionary) -> void:
	var resolution = data.get("mirror_resolution", [])
	if resolution is Array and resolution.size() == 2:
		mirror_resolution = Vector2i(int(resolution[0]), int(resolution[1]))
	mirror_fov = float(data.get("mirror_fov", mirror_fov))
	visor_tint = float(data.get("visor_tint", visor_tint))
	for viewport in _mirror_viewports:
		viewport.size = mirror_resolution
	for camera in _mirror_cameras:
		camera.fov = mirror_fov
	_apply_visor_tint()


## Lo llama CarController al cambiar de cámara.
func set_cockpit_view(enabled: bool) -> void:
	_cockpit_view = enabled
	_visor.visible = enabled
	for i in _mirror_viewports.size():
		_mirror_viewports[i].render_target_update_mode = (
			SubViewport.UPDATE_ALWAYS if enabled else SubViewport.UPDATE_DISABLED)
		_mirror_glasses[i].material_override = (
			_mirror_live_materials[i] if enabled else _mirror_off_material)


func _process(_delta: float) -> void:
	if not _cockpit_view:
		return
	for i in _mirror_cameras.size():
		_mirror_cameras[i].global_transform = _mirror_eyes[i].global_transform


func _build_halo(material: Material) -> void:
	var halo := Node3D.new()
	halo.name = "Halo"
	add_child(halo)
	var points: Array[Vector3] = []
	for i in HALO_HOOP_SEGMENTS + 1:
		var angle := deg_to_rad(lerpf(-HALO_HOOP_END_DEG, HALO_HOOP_END_DEG, float(i) / HALO_HOOP_SEGMENTS))
		var back := (1.0 - cos(angle)) * 0.5
		points.append(HALO_HOOP_CENTER + Vector3(
			sin(angle) * HALO_HOOP_RADIUS.x, -HALO_HOOP_DROP * back, -cos(angle) * HALO_HOOP_RADIUS.y))
	for i in points.size() - 1:
		_add_segment(halo, points[i], points[i + 1], HALO_THICKNESS, material)
	var front := HALO_HOOP_CENTER + Vector3(0.0, 0.0, -HALO_HOOP_RADIUS.y)
	_add_segment(halo, front, HALO_PILLAR_BASE, HALO_THICKNESS * 1.3, material)
	var left_mount := Vector3(-HALO_REAR_MOUNT.x, HALO_REAR_MOUNT.y, HALO_REAR_MOUNT.z)
	_add_segment(halo, points[0], left_mount, HALO_THICKNESS, material)
	_add_segment(halo, points[points.size() - 1], HALO_REAR_MOUNT, HALO_THICKNESS, material)


func _build_mirror(side: int, material: Material) -> void:
	var pos := Vector3(MIRROR_POSITION.x * side, MIRROR_POSITION.y, MIRROR_POSITION.z)
	var mirror := Node3D.new()
	mirror.name = "MirrorLeft" if side < 0 else "MirrorRight"
	mirror.position = pos
	mirror.rotation.y = -side * deg_to_rad(MIRROR_TOE_DEG)
	add_child(mirror)
	_add_box(mirror, Vector3(MIRROR_SIZE.x + 0.02, MIRROR_SIZE.y + 0.02, 0.035), Vector3(0.0, 0.0, -0.019), material)
	_add_segment(self, pos + Vector3(-side * 0.04, -0.03, -0.02), Vector3(side * 0.36, 0.63, pos.z + 0.02), 0.025, material)

	var viewport := SubViewport.new()
	viewport.name = "View"
	viewport.size = mirror_resolution
	mirror.add_child(viewport)
	var camera := Camera3D.new()
	camera.fov = mirror_fov
	camera.near = 0.05
	camera.far = 600.0
	camera.cull_mask = 0xFFFFF & ~(1 << (VISOR_LAYER - 1))
	viewport.add_child(camera)
	camera.current = true

	# Punto de vista del espejo: un poco delante del vidrio, mirando hacia atrás y afuera.
	var eye := Node3D.new()
	eye.name = "MirrorEye" + ("Left" if side < 0 else "Right")
	var out := deg_to_rad(MIRROR_VIEW_OUT_DEG)
	var look := Vector3(side * sin(out), -MIRROR_VIEW_DOWN, cos(out)).normalized()
	eye.transform = Transform3D(Basis.looking_at(look, Vector3.UP), pos + Vector3(0.0, 0.0, 0.03))
	add_child(eye)

	var live := StandardMaterial3D.new()
	live.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	live.albedo_texture = viewport.get_texture()
	live.uv1_scale = Vector3(-1.0, 1.0, 1.0)   # espejado horizontal
	live.uv1_offset = Vector3(1.0, 0.0, 0.0)
	var quad := QuadMesh.new()
	quad.size = MIRROR_SIZE
	var glass := MeshInstance3D.new()
	glass.name = "Glass"
	glass.mesh = quad
	glass.position = Vector3(0.0, 0.0, 0.001)
	mirror.add_child(glass)

	_mirror_viewports.append(viewport)
	_mirror_cameras.append(camera)
	_mirror_eyes.append(eye)
	_mirror_glasses.append(glass)
	_mirror_live_materials.append(live)


func _build_visor() -> void:
	_visor = Node3D.new()
	_visor.name = "HelmetVisor"
	_visor.position = Vector3(0.0, 0.0, -VISOR_DISTANCE)
	_camera.add_child(_visor)
	var padding := _unshaded(Color(0.025, 0.025, 0.03))
	var seal := _unshaded(Color(0.12, 0.12, 0.13))
	_add_band(BRIM_Y, BRIM_CURVE, 1.0, padding, seal)
	_add_band(CHIN_Y, CHIN_CURVE, -1.0, padding, seal)

	_visor_tint_material = _unshaded(Color(0.15, 0.2, 0.3))
	_visor_tint_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var quad := QuadMesh.new()
	quad.size = Vector2(VISOR_HALF_WIDTH * 2.0, VISOR_OUTER_Y * 2.0)
	_visor_tint_mesh = MeshInstance3D.new()
	_visor_tint_mesh.name = "Tint"
	_visor_tint_mesh.mesh = quad
	_visor_tint_mesh.material_override = _visor_tint_material
	_visor_tint_mesh.position = Vector3(0.0, 0.0, -0.002)
	_set_visor_flags(_visor_tint_mesh)
	_visor.add_child(_visor_tint_mesh)
	_apply_visor_tint()


## Franja del casco desde un borde interno curvo hasta fuera de la pantalla.
## direction = 1 cubre hacia arriba (visera), -1 hacia abajo (mentonera).
func _add_band(inner_y: float, curve: float, direction: float, material: Material, seal_material: Material) -> void:
	var inner := PackedVector3Array()
	var outer := PackedVector3Array()
	var seal := PackedVector3Array()
	for i in VISOR_SEGMENTS + 1:
		var x := lerpf(-VISOR_HALF_WIDTH, VISOR_HALF_WIDTH, float(i) / VISOR_SEGMENTS)
		var k := minf(absf(x) / SCREEN_HALF_WIDTH, 1.5)
		var y := inner_y + curve * k * k
		inner.append(Vector3(x, y, 0.0))
		outer.append(Vector3(x, direction * VISOR_OUTER_Y, 0.0))
		seal.append(Vector3(x, y - direction * VISOR_EDGE, 0.0))
	_add_strip(inner, outer, material)
	_add_strip(seal, inner, seal_material)


func _add_strip(a: PackedVector3Array, b: PackedVector3Array, material: Material) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in a.size() - 1:
		st.add_vertex(a[i])
		st.add_vertex(b[i])
		st.add_vertex(a[i + 1])
		st.add_vertex(a[i + 1])
		st.add_vertex(b[i])
		st.add_vertex(b[i + 1])
	var instance := MeshInstance3D.new()
	instance.mesh = st.commit()
	instance.material_override = material
	_set_visor_flags(instance)
	_visor.add_child(instance)


func _set_visor_flags(instance: MeshInstance3D) -> void:
	instance.layers = 1 << (VISOR_LAYER - 1)
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _apply_visor_tint() -> void:
	if _visor_tint_material == null:
		return
	_visor_tint_material.albedo_color.a = clampf(visor_tint, 0.0, 1.0)
	_visor_tint_mesh.visible = visor_tint > 0.0


## Caja estirada y orientada para unir a con b (se alarga un grosor para tapar las juntas).
func _add_segment(parent: Node3D, a: Vector3, b: Vector3, thickness: float, material: Material) -> MeshInstance3D:
	var dir := b - a
	var length := dir.length()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(thickness, thickness, length + thickness)
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	var up := Vector3.UP if absf((dir / length).dot(Vector3.UP)) < 0.99 else Vector3.BACK
	instance.transform = Transform3D(Basis.looking_at(dir / length, up), (a + b) * 0.5)
	parent.add_child(instance)
	return instance


func _add_box(parent: Node3D, box_size: Vector3, pos: Vector3, material: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = box_size
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = pos
	parent.add_child(instance)
	return instance


func _material(color: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material


func _unshaded(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.albedo_color = color
	return material
