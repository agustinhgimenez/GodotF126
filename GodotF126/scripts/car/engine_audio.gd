class_name EngineAudio
extends Node
## Sonido del motor (Paso 9), sintetizado por código con un AudioStreamGenerator.
## Un V6 de 4 tiempos hace 3 explosiones por vuelta: la frecuencia base es rpm / 60 × 3.
## Capas:
## - Tono: armónicas de la explosión; la 3ª crece con el acelerador.
## - Combustión: ruido en pulsos justo después de cada explosión ("rasp"), más fuerte con carga.
## - Mecánica: media orden (rpm / 60 × 1,5) que sigue sonando aunque no haya explosiones.
## - Turbo: silbido agudo que crece con acelerador × RPM.
## - Caja: golpe corto de ruido en cada cambio.
## - Petardeo: estallidos graves al soltar el acelerador alto de vueltas.
## Cuando el motor corta potencia (limitador o cambio) se apagan las explosiones, así el
## limitador suena entrecortado sin un sonido aparte.

@export var volume_db: float = -6.0
@export var chase_volume_db: float = -4.0      ## se suma en las cámaras exteriores
@export var mix_rate: float = 22050.0
@export var buffer_length: float = 0.08        ## segundos; más chico = menos retraso, más riesgo de cortes
@export var firings_per_rev: float = 3.0
@export var rasp_amount: float = 0.6
@export var mechanical_amount: float = 0.25
@export var turbo_volume: float = 0.05
@export var turbo_base_hz: float = 2500.0
@export var turbo_range_hz: float = 4000.0
@export var shift_volume: float = 0.5
@export var pop_volume: float = 0.7
@export var pop_min_rpm_ratio: float = 0.55
@export var pop_count_min: int = 3
@export var pop_count_max: int = 6

var _car: CarController
var _engine: CarEngine
var _gearbox: Gearbox
var _player: AudioStreamPlayer
var _playback: AudioStreamGeneratorPlayback

var _phase: float = 0.0
var _sub_phase: float = 0.0
var _turbo_phase: float = 0.0
## RPM y carga del bloque anterior: dentro de cada bloque se interpola para que no "salte".
var _rpm: float = 0.0
var _load: float = 0.0
var _fire_gain: float = 1.0
var _boost: float = 0.0
var _clack: float = 0.0
var _pop_env: float = 0.0
var _pop_lowpass: float = 0.0
var _pop_times: Array[float] = []   ## segundos que faltan para cada petardo
var _prev_throttle: float = 0.0
var _noise_state: int = 22222


func _ready() -> void:
	_car = get_parent() as CarController
	_engine = get_node("../Engine") as CarEngine
	_gearbox = get_node("../Gearbox") as Gearbox
	_gearbox.gear_changed.connect(_on_gear_changed)
	_rpm = _engine.rpm
	_start()


func configure(data: Dictionary) -> void:
	volume_db = float(data.get("volume_db", volume_db))
	chase_volume_db = float(data.get("chase_volume_db", chase_volume_db))
	mix_rate = float(data.get("mix_rate", mix_rate))
	buffer_length = float(data.get("buffer_length", buffer_length))
	firings_per_rev = float(data.get("firings_per_rev", firings_per_rev))
	rasp_amount = float(data.get("rasp_amount", rasp_amount))
	mechanical_amount = float(data.get("mechanical_amount", mechanical_amount))
	turbo_volume = float(data.get("turbo_volume", turbo_volume))
	turbo_base_hz = float(data.get("turbo_base_hz", turbo_base_hz))
	turbo_range_hz = float(data.get("turbo_range_hz", turbo_range_hz))
	shift_volume = float(data.get("shift_volume", shift_volume))
	pop_volume = float(data.get("pop_volume", pop_volume))
	pop_min_rpm_ratio = float(data.get("pop_min_rpm_ratio", pop_min_rpm_ratio))
	pop_count_min = int(data.get("pop_count_min", pop_count_min))
	pop_count_max = maxi(int(data.get("pop_count_max", pop_count_max)), pop_count_min)
	_start()


func _start() -> void:
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = mix_rate
	stream.buffer_length = buffer_length
	if _player == null:
		_player = AudioStreamPlayer.new()
		_player.name = "Player"
		_player.bus = Settings.BUS_ENGINE
		add_child(_player)
	_player.stream = stream
	_player.volume_db = volume_db
	_player.play()
	_playback = _player.get_stream_playback() as AudioStreamGeneratorPlayback
	_playback.push_buffer(synthesize(_playback.get_frames_available()))


func set_muted(muted: bool) -> void:
	set_process(not muted)
	if _player != null:
		_player.stream_paused = muted


func _exit_tree() -> void:
	if _player != null:
		_player.stop()
	_playback = null


func _process(delta: float) -> void:
	if _playback == null:
		return
	_player.volume_db = volume_db + (0.0 if _car.is_cockpit_view() else chase_volume_db)
	_update_pops(delta)
	var frames := _playback.get_frames_available()
	if frames > 0:
		_playback.push_buffer(synthesize(frames))


## Genera `frames` muestras estéreo con el estado actual del motor.
## Es público para poder probar el sonido sin reproducirlo.
func synthesize(frames: int) -> PackedVector2Array:
	var buffer := PackedVector2Array()
	buffer.resize(frames)
	var target_rpm := _engine.rpm
	var cutting := _engine.is_cutting() or _gearbox.is_shifting()
	var target_load := 0.0 if cutting else _engine.throttle
	var fire_target := 0.0 if cutting else 1.0
	var rpm_ratio := _engine.get_rpm_ratio()
	var block_time := frames / mix_rate
	_boost = lerpf(_boost, target_load * rpm_ratio, clampf(block_time * 3.0, 0.0, 1.0))
	var gain := lerpf(0.45, 1.0, rpm_ratio)
	var turbo_step := (turbo_base_hz + turbo_range_hz * _boost) / mix_rate
	var turbo_amp := turbo_volume * _boost
	var clack_decay := exp(-1.0 / (0.03 * mix_rate))
	var pop_decay := exp(-1.0 / (0.05 * mix_rate))
	var fire_step := 1.0 / (0.004 * mix_rate)

	for i in frames:
		var k := float(i) / frames
		var r := lerpf(_rpm, target_rpm, k)
		var l := lerpf(_load, target_load, k)
		var freq := r / 60.0 * firings_per_rev
		_phase += freq / mix_rate
		if _phase >= 1.0:
			_phase -= 1.0
		_sub_phase += freq * 0.5 / mix_rate
		if _sub_phase >= 1.0:
			_sub_phase -= 1.0
		_turbo_phase += turbo_step
		if _turbo_phase >= 1.0:
			_turbo_phase -= 1.0
		_fire_gain = move_toward(_fire_gain, fire_target, fire_step)
		_noise_state = (_noise_state * 1103515245 + 12345) & 0x7FFFFFFF
		var noise := float(_noise_state) / 1073741823.5 - 1.0

		var p := _phase * TAU
		var tone := sin(p) + 0.55 * sin(2.0 * p) + 0.3 * l * sin(3.0 * p)
		var after_fire := (1.0 - _phase) * (1.0 - _phase)
		after_fire *= after_fire
		var combustion := (tone * 0.45 + noise * after_fire * rasp_amount * (0.4 + 0.6 * l))
		combustion *= lerpf(0.35, 1.0, l) * _fire_gain
		var s := (combustion + mechanical_amount * sin(_sub_phase * TAU)) * gain
		s += sin(_turbo_phase * TAU) * turbo_amp

		_clack *= clack_decay
		s += noise * _clack * shift_volume
		_pop_env *= pop_decay
		_pop_lowpass += (noise - _pop_lowpass) * 0.2
		s += _pop_lowpass * _pop_env * pop_volume * 3.0

		s = s / (1.0 + absf(s))   # saturación suave: nunca pasa de ±1
		buffer[i] = Vector2(s, s)

	_rpm = target_rpm
	_load = target_load
	return buffer


func _update_pops(delta: float) -> void:
	var throttle := _engine.throttle
	if _prev_throttle > 0.6 and throttle < 0.15 and _engine.get_rpm_ratio() > pop_min_rpm_ratio:
		var t := 0.0
		for i in randi_range(pop_count_min, pop_count_max):
			t += randf_range(0.04, 0.14)
			_pop_times.append(t)
	elif throttle > 0.3:
		_pop_times.clear()
	_prev_throttle = throttle
	for i in range(_pop_times.size() - 1, -1, -1):
		_pop_times[i] -= delta
		if _pop_times[i] <= 0.0:
			_pop_env = randf_range(0.6, 1.0)
			_pop_times.remove_at(i)


func _on_gear_changed(_gear: int) -> void:
	_clack = 1.0
