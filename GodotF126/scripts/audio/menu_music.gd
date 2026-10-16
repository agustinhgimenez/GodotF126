class_name MenuMusic
extends Node
## Música del menú (Paso 11), generada por código con un AudioStreamGenerator.
## Loop en compás de 4/4 a `bpm`, un acorde por compás (notas MIDI en `chords`).
## Se divide en semicorcheas (16 por compás); en cada una se deciden las notas y golpes:
## - Bombo en cada negra, caja en los tiempos 2 y 4, hi-hat a contratiempo (más suave en semicorcheas).
## - Bajo: fundamental del acorde dos octavas abajo en cada corchea (sube una octava a contratiempo).
## - Arpegio: notas del acorde una octava arriba según `arp_pattern`.
## - Colchón: las tres notas del acorde sostenidas.

const STEPS_PER_BAR := 16

@export var volume_db: float = -12.0
@export var mix_rate: float = 22050.0
@export var bpm: float = 112.0
@export var fade_in: float = 2.5
@export var bass_volume: float = 0.35
@export var arp_volume: float = 0.12
@export var pad_volume: float = 0.08
@export var kick_volume: float = 0.55
@export var snare_volume: float = 0.2
@export var hihat_volume: float = 0.08

var chords: Array = [[57, 60, 64], [53, 57, 60], [48, 52, 55], [55, 59, 62]]
var arp_pattern: Array = [0, 1, 2, 1]

var _player: AudioStreamPlayer
var _playback: AudioStreamGeneratorPlayback
var _step: int = -1
var _bar: int = -1
var _samples_left: float = 0.0
var _master: float = 0.0
var _noise_state: int = 4242

var _bass_freq: float = 55.0
var _bass_phase: float = 0.0
var _bass_env: float = 0.0
var _bass_low: float = 0.0
var _arp_freq: float = 440.0
var _arp_phase: float = 0.0
var _arp_env: float = 0.0
var _pad_freqs: PackedFloat32Array = PackedFloat32Array([220.0, 261.6, 329.6])
var _pad_phases: PackedFloat32Array = PackedFloat32Array([0.0, 0.0, 0.0])
var _kick_env: float = 0.0
var _kick_freq: float = 120.0
var _kick_phase: float = 0.0
var _snare_env: float = 0.0
var _snare_phase: float = 0.0
var _hihat_env: float = 0.0
var _hihat_low: float = 0.0


func configure(data: Dictionary) -> void:
	volume_db = float(data.get("volume_db", volume_db))
	mix_rate = float(data.get("mix_rate", mix_rate))
	bpm = maxf(float(data.get("bpm", bpm)), 30.0)
	fade_in = float(data.get("fade_in", fade_in))
	bass_volume = float(data.get("bass_volume", bass_volume))
	arp_volume = float(data.get("arp_volume", arp_volume))
	pad_volume = float(data.get("pad_volume", pad_volume))
	kick_volume = float(data.get("kick_volume", kick_volume))
	snare_volume = float(data.get("snare_volume", snare_volume))
	hihat_volume = float(data.get("hihat_volume", hihat_volume))
	var chord_data = data.get("chords", [])
	if chord_data is Array and not chord_data.is_empty():
		chords = chord_data
	var pattern = data.get("arp_pattern", [])
	if pattern is Array and not pattern.is_empty():
		arp_pattern = pattern


func play() -> void:
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = mix_rate
	stream.buffer_length = 0.15
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


func _process(_delta: float) -> void:
	if _playback == null:
		return
	var frames := _playback.get_frames_available()
	if frames > 0:
		_playback.push_buffer(synthesize(frames))


## Genera `frames` muestras estéreo. Público para poder probar sin reproducir.
func synthesize(frames: int) -> PackedVector2Array:
	var buffer := PackedVector2Array()
	buffer.resize(frames)
	var step_samples := mix_rate * 60.0 / bpm / 4.0
	var fade_step := 1.0 / maxf(fade_in * mix_rate, 1.0)
	var bass_decay := exp(-1.0 / (0.18 * mix_rate))
	var arp_decay := exp(-1.0 / (0.09 * mix_rate))
	var kick_decay := exp(-1.0 / (0.14 * mix_rate))
	var kick_drop := exp(-1.0 / (0.03 * mix_rate))
	var snare_decay := exp(-1.0 / (0.1 * mix_rate))
	var hihat_decay := exp(-1.0 / (0.025 * mix_rate))
	var bass_coef := 0.08

	for i in frames:
		_samples_left -= 1.0
		if _samples_left <= 0.0:
			_samples_left += step_samples
			_next_step()
		_master = minf(_master + fade_step, 1.0)
		_noise_state = (_noise_state * 1103515245 + 12345) & 0x7FFFFFFF
		var noise := float(_noise_state) / 1073741823.5 - 1.0

		# Bajo: diente de sierra suavizado por un pasabajos.
		_bass_phase += _bass_freq / mix_rate
		if _bass_phase >= 1.0:
			_bass_phase -= 1.0
		_bass_low += (_bass_phase * 2.0 - 1.0 - _bass_low) * bass_coef
		_bass_env *= bass_decay
		var s := _bass_low * _bass_env * bass_volume

		# Arpegio: onda cuadrada suave (fundamental + 3ª armónica).
		_arp_phase += _arp_freq / mix_rate
		if _arp_phase >= 1.0:
			_arp_phase -= 1.0
		var ap := _arp_phase * TAU
		_arp_env *= arp_decay
		s += (sin(ap) + sin(3.0 * ap) / 3.0) * _arp_env * arp_volume

		for n in 3:
			_pad_phases[n] += _pad_freqs[n] / mix_rate
			if _pad_phases[n] >= 1.0:
				_pad_phases[n] -= 1.0
			s += sin(_pad_phases[n] * TAU) * pad_volume

		if _kick_env > 0.0005:
			_kick_freq = 45.0 + (_kick_freq - 45.0) * kick_drop
			_kick_phase += _kick_freq / mix_rate
			if _kick_phase >= 1.0:
				_kick_phase -= 1.0
			s += sin(_kick_phase * TAU) * _kick_env * kick_volume
			_kick_env *= kick_decay
		if _snare_env > 0.0005:
			_snare_phase += 180.0 / mix_rate
			if _snare_phase >= 1.0:
				_snare_phase -= 1.0
			s += (noise * 0.7 + sin(_snare_phase * TAU) * 0.3) * _snare_env * snare_volume
			_snare_env *= snare_decay
		if _hihat_env > 0.0005:
			_hihat_low += (noise - _hihat_low) * 0.5
			s += (noise - _hihat_low) * _hihat_env * hihat_volume
			_hihat_env *= hihat_decay

		s = s * _master
		s = s / (1.0 + absf(s))
		buffer[i] = Vector2(s, s)
	return buffer


func _next_step() -> void:
	_step += 1
	var in_bar := _step % STEPS_PER_BAR
	if in_bar == 0:
		_bar += 1
	var chord: Array = chords[_bar % chords.size()]
	if in_bar == 0:
		for n in 3:
			_pad_freqs[n] = _midi_to_hz(float(chord[n % chord.size()]))
	if in_bar % 4 == 0:
		_kick_env = 1.0
		_kick_freq = 120.0
	if in_bar % 8 == 4:
		_snare_env = 1.0
	if in_bar % 4 == 2:
		_hihat_env = 1.0
	elif in_bar % 2 == 1:
		_hihat_env = 0.5
	if in_bar % 2 == 0:
		var octave := 12.0 if in_bar % 4 == 2 else 0.0
		_bass_freq = _midi_to_hz(float(chord[0]) - 24.0 + octave)
		_bass_env = 1.0
	var tone: int = int(arp_pattern[_step % arp_pattern.size()])
	_arp_freq = _midi_to_hz(float(chord[tone % chord.size()]) + 12.0)
	_arp_env = 1.0


static func _midi_to_hz(note: float) -> float:
	return 440.0 * pow(2.0, (note - 69.0) / 12.0)
