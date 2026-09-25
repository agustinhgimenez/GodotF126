class_name LapTimer
extends Node
## Cronómetro de vueltas por sectores (Paso 2).
## Checkpoint 0 = línea de meta; 1 y 2 = fin del sector 1 y 2.
## Una vuelta sólo cuenta si se pasan los checkpoints en orden.

signal lap_started(lap: int)
signal sector_completed(sector: int, time: float, is_best: bool)
signal lap_completed(lap: int, time: float, is_best: bool, is_record: bool)
signal lap_aborted

const SECTOR_COUNT := 3
const RECORDS_PATH := "user://records.json"

var track_id: String = ""
var running: bool = false
var lap: int = 0
var current_time: float = 0.0
var last_lap: float = -1.0
var best_lap: float = -1.0
var record_lap: float = -1.0
var sector_times: Array[float] = []
var best_sectors: Array[float] = [-1.0, -1.0, -1.0]

var _next_checkpoint: int = 0
var _sector_start: float = 0.0


func setup(id: String) -> void:
	track_id = id
	record_lap = float(_load_records().get(track_id, -1.0))


func _physics_process(delta: float) -> void:
	if running:
		current_time += delta


func on_checkpoint(checkpoint: int) -> void:
	if checkpoint == 0:
		if not running:
			_start_lap()
		elif _next_checkpoint == 0:
			_finish_sector(SECTOR_COUNT - 1)
			_complete_lap()
			_start_lap()
		return
	if running and checkpoint == _next_checkpoint:
		_finish_sector(checkpoint - 1)
		_next_checkpoint = (checkpoint + 1) % SECTOR_COUNT


func abort_lap() -> void:
	if not running:
		return
	running = false
	current_time = 0.0
	lap = maxi(lap - 1, 0)
	lap_aborted.emit()


func _start_lap() -> void:
	running = true
	lap += 1
	current_time = 0.0
	_sector_start = 0.0
	sector_times.clear()
	_next_checkpoint = 1
	lap_started.emit(lap)


func _finish_sector(sector: int) -> void:
	var time := current_time - _sector_start
	_sector_start = current_time
	sector_times.append(time)
	var is_best := best_sectors[sector] < 0.0 or time < best_sectors[sector]
	if is_best:
		best_sectors[sector] = time
	sector_completed.emit(sector, time, is_best)


func _complete_lap() -> void:
	last_lap = current_time
	var is_best := best_lap < 0.0 or last_lap < best_lap
	if is_best:
		best_lap = last_lap
	var is_record := record_lap < 0.0 or last_lap < record_lap
	if is_record:
		record_lap = last_lap
		_save_record()
	lap_completed.emit(lap, last_lap, is_best, is_record)


func _load_records() -> Dictionary:
	if not FileAccess.file_exists(RECORDS_PATH):
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(RECORDS_PATH))
	if parsed is Dictionary:
		return parsed
	return {}


func _save_record() -> void:
	if track_id.is_empty():
		return
	var records := _load_records()
	records[track_id] = record_lap
	var file := FileAccess.open(RECORDS_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("No se pudo guardar el récord en %s" % RECORDS_PATH)
		return
	file.store_string(JSON.stringify(records, "  "))


static func format_time(seconds: float) -> String:
	if seconds < 0.0:
		return "--:--.---"
	var total_ms := roundi(seconds * 1000.0)
	var minutes := total_ms / 60000
	var secs := (total_ms / 1000) % 60
	var ms := total_ms % 1000
	return "%d:%02d.%03d" % [minutes, secs, ms]
