class_name StartLights
extends Node3D
## Semáforo de largada (Paso 17): 5 columnas de luces rojas que se encienden de a una por
## segundo y, tras una espera al azar, se apagan todas juntas (largada).
## Arma las luces en 3D colgadas del pórtico de la pista y avisa por señales para que el HUD
## dibuje las mismas luces. Si el auto avanza más de jump_distance antes del apagado es
## largada en falso. Después del apagado mide el tiempo de reacción.
## Todo avanza en _process / _physics_process, así que se congela con la pausa.

signal lights_changed(count: int)
signal lights_out
signal jump_start
signal reaction_measured(seconds: float)
signal finished

enum State { IDLE, WAITING, LIGHTING, HOLD, OUT, DONE }

const LIGHT_COUNT := 5
const ROWS := 2
const COLOR_OFF := Color(0.12, 0.02, 0.02)
const COLOR_ON := Color(1.0, 0.08, 0.05)

var pre_delay: float = 1.5
var light_interval: float = 1.0
var hold_min: float = 0.2
var hold_max: float = 3.0
var jump_distance: float = 0.3
var reaction_speed: float = 0.5   ## m/s que cuentan como "ya arrancó"
var hide_after: float = 2.0

var state: State = State.IDLE
var lights_on: int = 0
var jumped: bool = false
var reaction_time: float = -1.0

var _car: CarController
var _grid_origin: Vector3
var _grid_forward: Vector3
var _timer: float = 0.0
var _hold_time: float = 0.0
var _materials: Array[StandardMaterial3D] = []


func configure(data: Dictionary) -> void:
	pre_delay = float(data.get("pre_delay", pre_delay))
	light_interval = float(data.get("light_interval", light_interval))
	hold_min = float(data.get("hold_min", hold_min))
	hold_max = float(data.get("hold_max", hold_max))
	jump_distance = float(data.get("jump_distance", jump_distance))
	reaction_speed = float(data.get("reaction_speed", reaction_speed))
	hide_after = float(data.get("hide_after", hide_after))


## Cuelga las luces del pórtico (line = transform de la línea de largada) y arranca la secuencia
## con el auto parado en su lugar de la grilla.
func begin(car: CarController, line: Transform3D, gantry_height: float) -> void:
	_car = car
	_grid_origin = car.global_position
	_grid_forward = -car.global_transform.basis.z
	_grid_forward.y = 0.0
	_grid_forward = _grid_forward.normalized()
	_build_lamps(line, gantry_height)
	_hold_time = randf_range(hold_min, hold_max)
	_set_lights(0)
	_timer = 0.0
	state = State.WAITING


func is_active() -> bool:
	return state == State.WAITING or state == State.LIGHTING or state == State.HOLD


func _process(delta: float) -> void:
	if state == State.IDLE or state == State.DONE:
		return
	_timer += delta
	match state:
		State.WAITING:
			if _timer >= pre_delay:
				_timer = 0.0
				state = State.LIGHTING
				_set_lights(1)
		State.LIGHTING:
			if _timer >= light_interval:
				_timer = 0.0
				if lights_on < LIGHT_COUNT:
					_set_lights(lights_on + 1)
				if lights_on == LIGHT_COUNT:
					state = State.HOLD
		State.HOLD:
			if _timer >= _hold_time:
				_timer = 0.0
				state = State.OUT
				_set_lights(0)
				lights_out.emit()
		State.OUT:
			if _timer >= hide_after and (reaction_time >= 0.0 or jumped):
				state = State.DONE
				finished.emit()


func _physics_process(_delta: float) -> void:
	if _car == null:
		return
	if is_active() and not jumped:
		var moved := (_car.global_position - _grid_origin).dot(_grid_forward)
		if moved > jump_distance:
			jumped = true
			jump_start.emit()
	elif state == State.OUT and not jumped and reaction_time < 0.0:
		if _car.forward_speed > reaction_speed:
			reaction_time = _timer
			reaction_measured.emit(reaction_time)


func _set_lights(count: int) -> void:
	lights_on = count
	for i in _materials.size():
		var lit := (i % LIGHT_COUNT) < count
		_materials[i].albedo_color = COLOR_ON if lit else COLOR_OFF
		_materials[i].emission_enabled = lit
	lights_changed.emit(count)


## Panel negro bajo el travesaño del pórtico, con las lámparas mirando hacia la grilla.
func _build_lamps(line: Transform3D, gantry_height: float) -> void:
	for child in get_children():
		child.queue_free()
	_materials.clear()
	var back := line.basis.z   # hacia la grilla (el auto mira a -Z)
	var right := line.basis.x
	var center := line.origin + Vector3(0, gantry_height - 1.1, 0) + back * 0.45

	var panel := MeshInstance3D.new()
	var panel_mesh := BoxMesh.new()
	panel_mesh.size = Vector3(LIGHT_COUNT * 0.8 + 0.4, ROWS * 0.5 + 0.4, 0.2)
	panel.mesh = panel_mesh
	var panel_material := StandardMaterial3D.new()
	panel_material.albedo_color = Color(0.03, 0.03, 0.04)
	panel.material_override = panel_material
	panel.transform = Transform3D(line.basis, center)
	add_child(panel)

	var lamp_mesh := SphereMesh.new()
	lamp_mesh.radius = 0.18
	lamp_mesh.height = 0.36
	for row in ROWS:
		for i in LIGHT_COUNT:
			var material := StandardMaterial3D.new()
			material.albedo_color = COLOR_OFF
			material.emission = COLOR_ON
			material.emission_energy_multiplier = 3.0
			_materials.append(material)
			var lamp := MeshInstance3D.new()
			lamp.mesh = lamp_mesh
			lamp.material_override = material
			lamp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			var x := (i - (LIGHT_COUNT - 1) * 0.5) * 0.8
			var y := (0.5 - row) * 0.5
			lamp.position = center + right * x + Vector3(0, y, 0) + back * 0.12
			add_child(lamp)
