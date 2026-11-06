class_name LiveDelta
extends Node
## Delta en vivo (Paso 40): segundos de la vuelta en curso menos los de la vuelta de
## referencia en el mismo punto de la pista (negativo = más rápido). La referencia es la
## más rápida entre la mejor vuelta válida de la sesión y la guardada de la pista
## (TelemetryRecorder) y se fija al empezar cada vuelta. Al cerrar la vuelta queda el delta
## final (tiempo − tiempo de la referencia) durante `final_hold` s. Bloque "delta" de
## data/telemetry.json.

## Segundos de la constante de tiempo del suavizado (las muestras de la referencia van
## cada 0,05 s).
var smoothing: float = 0.15
## Segundos que se muestra el delta final al cerrar la vuelta.
var final_hold: float = 3.0
## Rango de la barra del HUD (± s).
var bar_range: float = 1.0

## NAN sin referencia o sin vuelta en curso.
var delta: float = NAN
## Cuánto cambia el delta por segundo (negativo = ganando tiempo).
var trend: float = 0.0
## Delta de la última vuelta cerrada (NAN si no había referencia).
var final_delta: float = NAN
var reference: TelemetryLap

## Delta sin suavizar del último cuadro.
var raw_delta: float = NAN

var _recorder: TelemetryRecorder
var _timer: LapTimer
var _final_until_ms: int = 0


func configure(data: Dictionary) -> void:
	smoothing = maxf(float(data.get("smoothing", smoothing)), 0.0)
	final_hold = maxf(float(data.get("final_hold", final_hold)), 0.0)
	bar_range = maxf(float(data.get("bar_range", bar_range)), 0.05)


func setup(recorder: TelemetryRecorder, timer: LapTimer) -> void:
	_recorder = recorder
	_timer = timer
	timer.lap_started.connect(_on_lap_started)
	timer.lap_completed.connect(_on_lap_completed)
	timer.lap_aborted.connect(_clear)


## La vuelta contra la que se compara: la más rápida entre la mejor de la sesión y la guardada.
func pick_reference() -> TelemetryLap:
	var picked: TelemetryLap = null
	for lap in [_recorder.best, _recorder.saved_best]:
		var candidate := lap as TelemetryLap
		if candidate == null or not candidate.is_complete() or candidate.invalid or candidate.size() < 2:
			continue
		if picked == null or candidate.lap_time < picked.lap_time:
			picked = candidate
	return picked


func has_delta() -> bool:
	return not is_nan(delta)


## Mostrando el delta final de la vuelta que se acaba de cerrar.
func is_showing_final() -> bool:
	return not is_nan(final_delta) and Time.get_ticks_msec() < _final_until_ms


## Lo que muestran el HUD y el volante: el final si se acaba de cerrar la vuelta, si no el
## de la vuelta en curso (NAN si no hay).
func shown_delta() -> float:
	return final_delta if is_showing_final() else delta


## Delta sin suavizar en este instante.
func compute(time: float, distance: float) -> float:
	if reference == null:
		return NAN
	return time - reference.value_at_distance("time", distance)


func _physics_process(delta_time: float) -> void:
	if reference == null or _timer == null or not _timer.running or _recorder.current == null:
		return
	var raw := compute(_timer.current_time, _current_distance())
	if is_nan(delta):
		delta = raw
		trend = 0.0
	else:
		var k := 1.0 - exp(-delta_time / smoothing) if smoothing > 0.0 else 1.0
		var previous := delta
		delta = lerpf(delta, raw, k)
		trend = lerpf(trend, (delta - previous) / maxf(delta_time, 1e-4), k)
	raw_delta = raw


func _current_distance() -> float:
	var distance := _recorder.lap_distance()
	var current := _recorder.current
	var previous := current.value("distance", current.size() - 1) if current.size() > 0 else 0.0
	var total := _recorder.track_length()
	if total > 0.0:
		distance += roundf((previous - distance) / total) * total
	return distance


func _on_lap_started(_lap: int) -> void:
	reference = pick_reference()
	delta = NAN
	trend = 0.0


func _on_lap_completed(_lap: int, time: float, _is_best: bool, _is_record: bool) -> void:
	if reference != null:
		final_delta = time - reference.lap_time
		_final_until_ms = Time.get_ticks_msec() + int(final_hold * 1000.0)
	else:
		final_delta = NAN
	delta = NAN


func _clear() -> void:
	reference = null
	delta = NAN
	trend = 0.0
	final_delta = NAN
