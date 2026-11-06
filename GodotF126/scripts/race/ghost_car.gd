class_name GhostCar
extends Node3D
## Auto fantasma (Paso 43): reproduce la vuelta de referencia del delta en vivo (la mejor entre
## la de la sesión y la guardada, fija al empezar cada vuelta) como un auto semitransparente,
## sin colisiones. Va por tiempo: con el cronómetro de la vuelta en curso toma la posición, la
## altura y el rumbo de la referencia en ese instante. Se atenúa cerca del auto (en cockpit
## taparía la vista) y no se ve sin referencia, fuera de la vuelta o cuando la referencia ya
## terminó. Opción "ghost" (tecla H); bloque "ghost" de data/telemetry.json.

## Opacidad máxima.
var alpha: float = 0.4
## A menos de `fade_near` m del auto no se ve; desde `fade_far` m, opacidad completa.
var fade_near: float = 3.0
var fade_far: float = 12.0
## Mezcla del color del equipo con blanco (0 = color del equipo, 1 = blanco).
var whiten: float = 0.35
var enabled: bool = true
## Opacidad de este cuadro (0 = oculto).
var shown_alpha: float = 0.0
## Vuelta y tiempo con los que se armó la pose actual.
var pose_lap: TelemetryLap
var pose_time: float = 0.0

var _car: CarController
var _timer: LapTimer
var _delta: LiveDelta
var _body_material := StandardMaterial3D.new()
var _dark_material := StandardMaterial3D.new()
var _base_body := Color.WHITE
var _base_dark := Color(0.15, 0.15, 0.18)


func configure(data: Dictionary) -> void:
	alpha = clampf(float(data.get("alpha", alpha)), 0.05, 1.0)
	fade_near = maxf(float(data.get("fade_near", fade_near)), 0.0)
	fade_far = maxf(float(data.get("fade_far", fade_far)), fade_near + 0.1)
	whiten = clampf(float(data.get("whiten", whiten)), 0.0, 1.0)


## Copia las mallas del auto (sin física, audio ni cámaras) con materiales transparentes.
func setup(car: CarController, timer: LapTimer, live_delta: LiveDelta, team_color: Color) -> void:
	_car = car
	_timer = timer
	_delta = live_delta
	for material in [_body_material, _dark_material]:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.cull_mode = BaseMaterial3D.CULL_BACK
	set_team_color(team_color)
	for child in car.get_children():
		var source := child as MeshInstance3D
		if source == null or not source.visible or source.mesh == null:
			continue
		var copy := MeshInstance3D.new()
		copy.name = source.name
		copy.mesh = source.mesh
		copy.transform = source.transform
		copy.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		copy.material_override = _body_material if source.is_in_group("team_paint") else _dark_material
		add_child(copy)
	visible = false


func set_team_color(color: Color) -> void:
	_base_body = color.lerp(Color.WHITE, whiten)
	_apply_alpha(shown_alpha)


func reference() -> TelemetryLap:
	return _delta.reference if _delta != null else null


## Pose de la referencia `time` s después de empezar la vuelta.
static func pose_at(lap: TelemetryLap, time: float) -> Transform3D:
	var origin := Vector3(lap.value_at("time", time, "x"), lap.value_at("time", time, "y"), lap.value_at("time", time, "z"))
	return Transform3D(Basis(Vector3.UP, lap.angle_at("time", time, "yaw")), origin)


func _process(_delta_time: float) -> void:
	var lap := reference()
	if not enabled or lap == null or _timer == null or not _timer.running or _timer.current_time > lap.lap_time:
		_hide()
		return
	pose_lap = lap
	pose_time = _timer.current_time
	global_transform = pose_at(lap, pose_time)
	var gap := global_position.distance_to(_car.global_position)
	var fade := clampf((gap - fade_near) / (fade_far - fade_near), 0.0, 1.0)
	if fade <= 0.0:
		_hide()
		return
	_apply_alpha(alpha * fade)
	visible = true


func _hide() -> void:
	visible = false
	shown_alpha = 0.0


func _apply_alpha(value: float) -> void:
	shown_alpha = value
	_body_material.albedo_color = Color(_base_body, value)
	_dark_material.albedo_color = Color(_base_dark, value)
