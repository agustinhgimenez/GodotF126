extends GutTest
## Cronómetro (LapTimer, Pasos 7 y 8): vueltas, sectores, vueltas inválidas, límite de vueltas
## y formato. Sin track_id no lee ni guarda récords del usuario.

var timer: LapTimer


func before_each() -> void:
	timer = autofree(LapTimer.new())


## Una vuelta completa con los tiempos acumulados de cada control (s1, s2, meta).
func _lap(s1: float, s2: float, finish: float) -> void:
	timer.current_time = s1
	timer.on_checkpoint(1)
	timer.current_time = s2
	timer.on_checkpoint(2)
	timer.current_time = finish
	timer.on_checkpoint(0)


func test_cruzar_la_meta_arranca_la_vuelta() -> void:
	watch_signals(timer)
	timer.on_checkpoint(0)
	assert_true(timer.running)
	assert_eq(timer.lap, 1)
	assert_signal_emitted_with_parameters(timer, "lap_started", [1])


func test_vuelta_con_sectores() -> void:
	timer.on_checkpoint(0)
	watch_signals(timer)
	_lap(30.0, 65.0, 100.0)
	assert_eq(timer.last_lap, 100.0)
	assert_eq(timer.best_lap, 100.0)
	assert_eq(timer.lap_history.size(), 1)
	assert_eq(timer.lap_history[0]["sectors"], [30.0, 35.0, 35.0])
	assert_eq(timer.best_sectors, [30.0, 35.0, 35.0] as Array[float])
	assert_signal_emit_count(timer, "sector_completed", 3)
	assert_signal_emitted(timer, "lap_completed")
	assert_eq(timer.lap, 2, "la vuelta siguiente ya corre")


func test_controles_fuera_de_orden_no_cuentan() -> void:
	timer.on_checkpoint(0)
	timer.current_time = 20.0
	timer.on_checkpoint(2)
	assert_eq(timer.sector_times.size(), 0)
	timer.on_checkpoint(0)
	assert_eq(timer.lap_history.size(), 0, "la meta sin pasar por los sectores no cierra la vuelta")


func test_vuelta_mas_rapida_y_mejores_sectores() -> void:
	timer.on_checkpoint(0)
	_lap(30.0, 65.0, 100.0)
	_lap(32.0, 64.0, 96.0)
	assert_eq(timer.best_lap, 96.0)
	assert_eq(timer.best_sectors, [30.0, 32.0, 32.0] as Array[float])


func test_vuelta_invalida_no_es_la_mejor() -> void:
	timer.on_checkpoint(0)
	_lap(30.0, 65.0, 100.0)
	timer.invalidate_lap("Cortó la curva")
	_lap(20.0, 40.0, 60.0)
	assert_eq(timer.best_lap, 100.0)
	assert_true(timer.lap_history[1]["invalid"])
	assert_eq(timer.best_sectors, [30.0, 35.0, 35.0] as Array[float], "los sectores de la inválida se deshacen")


func test_limite_de_vueltas_y_tiempo_total() -> void:
	timer.lap_limit = 2
	watch_signals(timer)
	timer.on_checkpoint(0)
	_lap(30.0, 65.0, 100.0)
	_lap(30.0, 65.0, 98.0)
	assert_true(timer.finished)
	assert_false(timer.running)
	assert_signal_emitted(timer, "session_finished")
	timer.add_penalty(5.0, "Largada en falso")
	assert_almost_eq(timer.total_time(), 203.0, 0.0001)
	timer.on_checkpoint(0)
	assert_eq(timer.lap_history.size(), 2, "terminada no cuenta más vueltas")


func test_abortar_descarta_la_vuelta() -> void:
	timer.on_checkpoint(0)
	timer.current_time = 12.0
	timer.abort_lap()
	assert_false(timer.running)
	assert_eq(timer.lap, 0)
	assert_eq(timer.current_time, 0.0)


func test_formato_de_tiempo() -> void:
	assert_eq(LapTimer.format_time(0.0), "0:00.000")
	assert_eq(LapTimer.format_time(83.1234), "1:23.123")
	assert_eq(LapTimer.format_time(59.9996), "1:00.000", "redondea al milésimo")
	assert_eq(LapTimer.format_time(605.5), "10:05.500")
	assert_eq(LapTimer.format_time(-1.0), "--:--.---", "sin tiempo")
