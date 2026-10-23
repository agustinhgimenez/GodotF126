extends Node
## Prueba de rendimiento para la PC del laboratorio (Paso 24), scenes/benchmark.tscn.
## Carga la carrera con cada calidad gráfica, mide 3 vistas (recta, castillo, cenital)
## sin vsync y recomienda la calidad más alta que se sostiene a 60 FPS. El informe (con
## CPU, placa de video y driver) se guarda en user://benchmark.txt.
##   Godot_v4.7.2-stable_win64.exe --path GodotF126 res://scenes/benchmark.tscn
## Con "-- --quit" al final se cierra solo al terminar.

const RACE_SCENE := "res://scenes/main.tscn"
const REPORT_PATH := "user://benchmark.txt"
const VIEWS := ["recta", "castillo", "cenital"]
const WARMUP_FRAMES := 40
const MEASURE_FRAMES := 120
const TARGET_MS := 1000.0 / 60.0
const QUALITY_LEVELS := ["low", "medium", "high"]
const QUALITY_NAMES := {"low": "Baja", "medium": "Media", "high": "Alta"}

## {"quality", "view", "avg_ms", "p95_ms", "calls"} por cada vista medida.
var results: Array[Dictionary] = []
var recommended: String = ""
var report: String = ""

var _status: Label
var _background: ColorRect


func _ready() -> void:
	_build_ui()
	await _run()


func _unhandled_input(event: InputEvent) -> void:
	if report.is_empty():
		return
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
		get_tree().quit()


func _run() -> void:
	await get_tree().process_frame
	var original_quality = Settings.get_value("quality")
	var original_vsync := DisplayServer.window_get_vsync_mode()
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var step := 0
	var total := QUALITY_LEVELS.size() * VIEWS.size()
	for quality in QUALITY_LEVELS:
		Settings.set_value("quality", quality)
		var race: Node = load(RACE_SCENE).instantiate()
		add_child(race)
		await _frames(5)
		race.hud.visible = false
		race.pause_menu.set_process_unhandled_input(false)
		for view in VIEWS:
			step += 1
			_status.text = "Midiendo · calidad %s · %s (%d/%d)" % [QUALITY_NAMES[quality], view, step, total]
			_set_view(race, view)
			var measured := await _measure()
			measured["quality"] = quality
			measured["view"] = view
			results.append(measured)
		race.queue_free()
		await _frames(2)
	Settings.set_value("quality", original_quality)
	DisplayServer.window_set_vsync_mode(original_vsync)

	recommended = recommend(results)
	report = _build_report()
	var file := FileAccess.open(REPORT_PATH, FileAccess.WRITE)
	if file:
		file.store_string(report)
	print(report)
	_background.visible = true
	_status.text = report + "\nGuardado en %s\nEnter o Esc para salir." % ProjectSettings.globalize_path(REPORT_PATH)
	if "--quit" in OS.get_cmdline_user_args():
		get_tree().quit()


## La calidad más alta cuyas vistas quedan todas bajo 16,7 ms en el percentil 95.
static func recommend(measured: Array[Dictionary]) -> String:
	var best := "low"
	for quality in QUALITY_LEVELS:
		var ok := false
		for result in measured:
			if result["quality"] != quality:
				continue
			ok = true
			if float(result["p95_ms"]) > TARGET_MS:
				ok = false
				break
		if ok:
			best = quality
	return best


func _measure() -> Dictionary:
	await _frames(WARMUP_FRAMES)
	var times: Array[float] = []
	var calls := 0
	var last := Time.get_ticks_usec()
	for i in MEASURE_FRAMES:
		await get_tree().process_frame
		var now := Time.get_ticks_usec()
		times.append((now - last) / 1000.0)
		last = now
		calls += int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	var total := 0.0
	for t in times:
		total += t
	times.sort()
	return {
		"avg_ms": total / times.size(),
		"p95_ms": times[int(times.size() * 0.95)],
		"calls": calls / MEASURE_FRAMES,
	}


func _set_view(race: Node, view: String) -> void:
	var track: BakuTrack = race.track
	var car: CarController = race.car
	match view:
		"recta":
			_place_car(track, car, track.index_at_distance(track.start_index(), -120.0))
		"castillo":
			for k in track.centerline.size():
				if track.widths[k] < 8.0:
					_place_car(track, car, (k + 30) % track.centerline.size())
					break
		"cenital":
			var camera := Camera3D.new()
			camera.far = 4000.0
			camera.fov = 55.0
			race.add_child(camera)
			camera.look_at_from_position(Vector3(-110, 950, -270), Vector3(-110, 0, -270.01))
			camera.make_current()


func _place_car(track: BakuTrack, car: CarController, index: int) -> void:
	car.global_transform = Transform3D(Basis.looking_at(track.flat_tangent(index), Vector3.UP),
		track.centerline[index] + Vector3(0, 0.6, 0))
	car.velocity = Vector3.ZERO
	car.set_camera_mode(0)


func _build_report() -> String:
	var lines := PackedStringArray()
	lines.append("GodotF126 · prueba de rendimiento (Paso 24)")
	lines.append("Fecha: %s" % Time.get_datetime_string_from_system(false, true))
	lines.append("Sistema: %s · CPU: %s (%d hilos)" % [OS.get_name(), OS.get_processor_name(), OS.get_processor_count()])
	lines.append("Video: %s · %s · %s" % [RenderingServer.get_video_adapter_name(),
		RenderingServer.get_video_adapter_vendor(), RenderingServer.get_video_adapter_api_version()])
	lines.append("Renderer: %s · ventana %s · pantalla %s" % [
		str(ProjectSettings.get_setting("rendering/renderer/rendering_method")),
		str(DisplayServer.window_get_size()), str(DisplayServer.screen_get_size())])
	lines.append("")
	lines.append("Calidad · vista: promedio / percentil 95 (ms por cuadro) · llamadas de dibujo")
	for result in results:
		lines.append("  %s · %s: %.1f / %.1f ms (%.0f FPS) · %d" % [
			QUALITY_NAMES[result["quality"]], result["view"], result["avg_ms"], result["p95_ms"],
			1000.0 / float(result["avg_ms"]), result["calls"]])
	lines.append("")
	var note := "" if _sustains(recommended) else " (ni la baja llega a 60 FPS en todas las vistas)"
	lines.append("Calidad recomendada: %s%s" % [QUALITY_NAMES[recommended], note])
	return "\n".join(lines)


func _sustains(quality: String) -> bool:
	for result in results:
		if result["quality"] == quality and float(result["p95_ms"]) > TARGET_MS:
			return false
	return true


func _frames(count: int) -> void:
	for i in count:
		await get_tree().process_frame


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 20
	add_child(layer)
	_background = ColorRect.new()
	_background.color = Color(0.04, 0.04, 0.07, 0.92)
	_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	_background.visible = false
	layer.add_child(_background)
	_status = UiKit.make_label("Preparando…", 18)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiKit.place(_status, Vector4(0, 0, 1, 1), Vector4(40, 30, -40, -30))
	layer.add_child(_status)
