class_name TrackLimits
extends Node
## Límites de pista y pianos (Paso 19).
## Cada frame de física ubica al auto respecto del centerline (índice más cercano y
## desplazamiento lateral). Si las cuatro ruedas pasan la línea blanca del mismo lado,
## invalida la vuelta en curso. Si alguna rueda pisa un piano, avisa al auto
## (kerb_contact) para la vibración de cámara y el retumbe de CarAudioFx.

signal exceeded

var car_half_width: float = 1.0   ## del centro del auto al borde exterior de las ruedas
var wheel_track: float = 0.85     ## del centro del auto al centro de cada rueda
var kerb_shake: float = 0.18
var kerb_min_speed: float = 5.0

## Último resultado, para el HUD y las pruebas.
var index: int = -1
var lateral: float = 0.0
var off_track: bool = false
var on_kerb: bool = false

var _track: BakuTrack
var _car: CarController
var _timer: LapTimer


func configure(data: Dictionary) -> void:
	car_half_width = float(data.get("car_half_width", car_half_width))
	wheel_track = float(data.get("wheel_track", wheel_track))
	kerb_shake = float(data.get("kerb_shake", kerb_shake))
	kerb_min_speed = float(data.get("kerb_min_speed", kerb_min_speed))


func setup(track: BakuTrack, car: CarController, timer: LapTimer) -> void:
	_track = track
	_car = car
	_timer = timer
	car.was_reset.connect(func() -> void: index = -1)


func _physics_process(_delta: float) -> void:
	if _car == null:
		return
	var located := _track.locate(_car.global_position, index)
	index = int(located.x)
	lateral = located.y
	var half := _track.half_width(index)

	var was_off := off_track
	off_track = absf(lateral) - car_half_width > half
	if off_track and not was_off:
		exceeded.emit()
		_timer.invalidate_lap("Límites de pista")

	on_kerb = false
	if _track.has_kerb(index):
		for side in [-1.0, 1.0]:
			var wheel := absf(lateral + side * wheel_track)
			if wheel >= half - 0.15 and wheel <= half + _track.kerb_width:
				on_kerb = true
	var speed := _car.get_speed_kmh() / 3.6
	_car.kerb_contact = clampf(speed / 20.0, 0.0, 1.0) if on_kerb and speed > kerb_min_speed else 0.0
	if _car.kerb_contact > 0.0:
		_car.add_camera_impact(kerb_shake * _car.kerb_contact)
