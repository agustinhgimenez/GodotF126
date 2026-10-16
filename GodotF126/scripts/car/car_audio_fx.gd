class_name CarAudioFx
extends Node
## Sonidos del auto que no son el motor (Paso 10), sintetizados por código con un
## AudioStreamGenerator, igual que EngineAudio.
## - Neumáticos: chirrido = ruido por un filtro pasabanda angosto (casi un tono) con un
##   poco de vibrato; crece con el ángulo de derrape y con el freno de mano.
## - Viento: ruido grave filtrado; volumen con el cuadrado de la velocidad y más agudo rápido.
## - Muros: golpe grave (tono que baja) + crujido de ruido en cada choque, y roce continuo
##   mientras el auto se arrastra contra el muro.

@export var volume_db: float = -8.0
@export var chase_volume_db: float = -3.0      ## se suma en las cámaras exteriores
@export var mix_rate: float = 22050.0
@export var buffer_length: float = 0.08
@export_group("Neumáticos")
@export var squeal_volume: float = 0.5
@export var squeal_start_deg: float = 3.0      ## derrape donde empieza a chirriar
@export var squeal_full_deg: float = 12.0      ## derrape con chirrido a pleno
@export var squeal_handbrake: float = 0.8      ## chirrido extra con freno de mano, a velocidad
@export var squeal_base_hz: float = 950.0
@export var squeal_range_hz: float = 450.0
@export var squeal_q: float = 14.0
@export_group("Viento")
@export var wind_volume: float = 0.35
@export_group("Muros")
@export var impact_volume: float = 0.9
@export var impact_min_strength: float = 0.05
@export var impact_cooldown: float = 0.15      ## s entre golpes, para no repetirlos cada frame
@export var scrape_volume: float = 0.35

var _car: CarController
var _player: AudioStreamPlayer
var _playback: AudioStreamGeneratorPlayback

## Cantidades del bloque anterior, para interpolar dentro de cada bloque.
var _squeal: float = 0.0
var _wind: float = 0.0
var _scrape: float = 0.0
var _squeal_low: float = 0.0
var _squeal_band: float = 0.0
var _vibrato_phase: float = 0.0
var _wind_low1: float = 0.0
var _wind_low2: float = 0.0
var _scrape_low: float = 0.0
var _scrape_band: float = 0.0
var _thump_env: float = 0.0
var _thump_phase: float = 0.0
var _thump_freq: float = 90.0
var _crunch_env: float = 0.0
var _crunch_low: float = 0.0
var _impact_timer: float = 0.0
var _noise_state: int = 777


func _ready() -> void:
	_car = get_parent() as CarController
	_car.wall_hit.connect(_on_wall_hit)
	_start()


func configure(data: Dictionary) -> void:
	volume_db = float(data.get("volume_db", volume_db))
	chase_volume_db = float(data.get("chase_volume_db", chase_volume_db))
	mix_rate = float(data.get("mix_rate", mix_rate))
	buffer_length = float(data.get("buffer_length", buffer_length))
	squeal_volume = float(data.get("squeal_volume", squeal_volume))
	squeal_start_deg = float(data.get("squeal_start_deg", squeal_start_deg))
	squeal_full_deg = maxf(float(data.get("squeal_full_deg", squeal_full_deg)), squeal_start_deg + 0.1)
	squeal_handbrake = float(data.get("squeal_handbrake", squeal_handbrake))
	squeal_base_hz = float(data.get("squeal_base_hz", squeal_base_hz))
	squeal_range_hz = float(data.get("squeal_range_hz", squeal_range_hz))
	squeal_q = maxf(float(data.get("squeal_q", squeal_q)), 0.5)
	wind_volume = float(data.get("wind_volume", wind_volume))
	impact_volume = float(data.get("impact_volume", impact_volume))
	impact_min_strength = float(data.get("impact_min_strength", impact_min_strength))
	impact_cooldown = float(data.get("impact_cooldown", impact_cooldown))
	scrape_volume = float(data.get("scrape_volume", scrape_volume))
	_start()


func _start() -> void:
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = mix_rate
	stream.buffer_length = buffer_length
	if _player == null:
		_player = AudioStreamPlayer.new()
		_player.name = "Player"
		add_child(_player)
	_player.stream = stream
	_player.volume_db = volume_db
	_player.play()
	_playback = _player.get_stream_playback() as AudioStreamGeneratorPlayback
	_playback.push_buffer(synthesize(_playback.get_frames_available()))


func _exit_tree() -> void:
	if _player != null:
		_player.stop()
	_playback = null


func _process(delta: float) -> void:
	_impact_timer = maxf(_impact_timer - delta, 0.0)
	if _playback == null:
		return
	_player.volume_db = volume_db + (0.0 if _car.is_cockpit_view() else chase_volume_db)
	var frames := _playback.get_frames_available()
	if frames > 0:
		_playback.push_buffer(synthesize(frames))


## 0–1: cuánto chirrían los neumáticos ahora.
func get_squeal_amount() -> float:
	var speed := _car.get_speed_kmh() / 3.6
	var slip := inverse_lerp(squeal_start_deg, squeal_full_deg, _car.get_slip_angle_deg())
	var amount := clampf(slip, 0.0, 1.0) * clampf(speed / 8.0, 0.0, 1.0)
	if _car.is_handbrake_on():
		amount = maxf(amount, squeal_handbrake * clampf(speed / 15.0, 0.0, 1.0))
	return amount


## Genera `frames` muestras estéreo con el estado actual del auto.
## Es público para poder probar el sonido sin reproducirlo.
func synthesize(frames: int) -> PackedVector2Array:
	var buffer := PackedVector2Array()
	buffer.resize(frames)
	var speed := _car.get_speed_kmh() / 3.6
	var speed_ratio := clampf(speed / maxf(_car.max_speed, 1.0), 0.0, 1.0)
	var target_squeal := get_squeal_amount()
	var target_wind := speed_ratio * speed_ratio
	var target_scrape := clampf(speed / 30.0, 0.0, 1.0) if _car.is_touching_wall() else 0.0

	var squeal_q_inv := 1.0 / squeal_q
	var vibrato_step := 6.0 / mix_rate
	var wind_coef := lerpf(0.02, 0.12, speed_ratio)
	var scrape_f := 2.0 * sin(PI * 2600.0 / mix_rate)
	var thump_decay := exp(-1.0 / (0.12 * mix_rate))
	var crunch_decay := exp(-1.0 / (0.07 * mix_rate))
	var thump_drop := exp(-1.0 / (0.2 * mix_rate))

	for i in frames:
		var k := float(i) / frames
		var squeal := lerpf(_squeal, target_squeal, k)
		var wind := lerpf(_wind, target_wind, k)
		var scrape := lerpf(_scrape, target_scrape, k)
		_noise_state = (_noise_state * 1103515245 + 12345) & 0x7FFFFFFF
		var noise := float(_noise_state) / 1073741823.5 - 1.0
		var s := 0.0

		if squeal > 0.001 or absf(_squeal_band) > 0.0001:
			_vibrato_phase += vibrato_step
			if _vibrato_phase >= 1.0:
				_vibrato_phase -= 1.0
			var fc := squeal_base_hz + squeal_range_hz * squeal + 60.0 * sin(_vibrato_phase * TAU)
			var f := 2.0 * sin(PI * fc / mix_rate)
			var high := noise - _squeal_low - squeal_q_inv * _squeal_band
			_squeal_band += f * high
			_squeal_low += f * _squeal_band
			s += _squeal_band * squeal * squeal_volume

		_wind_low1 += (noise - _wind_low1) * wind_coef
		_wind_low2 += (_wind_low1 - _wind_low2) * wind_coef
		s += _wind_low2 * wind * wind_volume * 4.0

		if scrape > 0.001 or absf(_scrape_band) > 0.0001:
			var scrape_high := noise - _scrape_low - 0.5 * _scrape_band
			_scrape_band += scrape_f * scrape_high
			_scrape_low += scrape_f * _scrape_band
			s += _scrape_band * scrape * scrape_volume * (0.6 + 0.4 * absf(noise))

		if _thump_env > 0.0005:
			_thump_phase += _thump_freq / mix_rate
			if _thump_phase >= 1.0:
				_thump_phase -= 1.0
			_thump_freq = 45.0 + (_thump_freq - 45.0) * thump_drop
			s += sin(_thump_phase * TAU) * _thump_env * impact_volume
			_thump_env *= thump_decay
		if _crunch_env > 0.0005:
			_crunch_low += (noise - _crunch_low) * 0.35
			s += _crunch_low * _crunch_env * impact_volume * 1.5
			_crunch_env *= crunch_decay

		s = s / (1.0 + absf(s))   # saturación suave: nunca pasa de ±1
		buffer[i] = Vector2(s, s)

	_squeal = target_squeal
	_wind = target_wind
	_scrape = target_scrape
	return buffer


func _on_wall_hit(strength: float) -> void:
	if strength < impact_min_strength:
		return
	if _impact_timer > 0.0 and strength < _thump_env * 1.5:
		return
	_impact_timer = impact_cooldown
	var amount := clampf(sqrt(strength), 0.0, 1.0)
	_thump_env = maxf(_thump_env, amount)
	_thump_freq = 90.0
	_crunch_env = maxf(_crunch_env, amount)
