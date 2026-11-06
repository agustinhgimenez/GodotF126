class_name TelemetryCsv
extends RefCounted
## Exportación de vueltas de telemetría a CSV (Paso 42). Un archivo de datos con una fila por
## muestra (columnas: vuelta, origen, válida y los canales de TelemetryLap con su unidad) y un
## resumen con una fila por vuelta. Los números se escriben siempre igual, sin depender del
## idioma del sistema: separador y signo decimal salen de data/telemetry.json.

## Encabezado de cada canal en el CSV (nombre con unidad).
const HEADERS := {"time": "tiempo_s", "distance": "distancia_m", "speed": "velocidad_kmh", "rpm": "rpm",
	"gear": "marcha", "throttle": "acelerador", "brake": "freno", "steer": "direccion", "x": "x_m", "y": "y_m", "z": "z_m", "yaw": "rumbo_rad"}
const SUMMARY_HEADERS := ["vuelta", "origen", "valida", "compuesto", "tiempo_s", "largo_pista_m", "muestras",
	"vel_max_kmh", "vel_min_kmh", "vel_media_kmh", "a_fondo_pct", "frenando_pct", "cambios", "rpm_max"]

var directory: String = "user://telemetria"
var separator: String = ","
var decimal: String = "."
var write_summary: bool = true


func configure(data: Dictionary) -> void:
	directory = str(data.get("dir", directory)).trim_suffix("/")
	separator = str(data.get("separator", separator))
	if separator.length() != 1:
		separator = ","
	decimal = "," if str(data.get("decimal", decimal)) == "," else "."
	# Con coma decimal, la coma no puede separar columnas.
	if decimal == "," and separator == ",":
		separator = ";"
	write_summary = bool(data.get("summary", write_summary))


## Número con `decimals` decimales, sin separador de miles y con el signo decimal elegido.
func number(value: float, decimals: int) -> String:
	if absf(value) < 0.5 * pow(10.0, -decimals):
		value = 0.0
	if decimals <= 0:
		return str(roundi(value))
	var text: String = ("%." + str(decimals) + "f") % value
	return text.replace(".", decimal) if decimal != "." else text


func header() -> String:
	var columns := PackedStringArray(["vuelta", "origen", "valida"])
	for channel in TelemetryLap.CHANNELS:
		columns.append(HEADERS.get(channel, channel))
	return separator.join(columns)


## Filas de datos de una vuelta (sin encabezado). `origin` = "sesion" o "guardada".
func lap_rows(lap: TelemetryLap, origin: String) -> PackedStringArray:
	var rows := PackedStringArray()
	var prefix := separator.join(PackedStringArray([str(lap.lap), origin, "0" if lap.invalid else "1"]))
	var arrays: Array[PackedFloat32Array] = []
	var decimals: Array[int] = []
	for channel in TelemetryLap.CHANNELS:
		arrays.append(lap.channel(channel))
		decimals.append(int(TelemetryLap.DECIMALS.get(channel, 3)))
	for i in lap.size():
		var fields := PackedStringArray([prefix])
		for c in arrays.size():
			fields.append(number(arrays[c][i], decimals[c]))
		rows.append(separator.join(fields))
	return rows


func data_text(laps: Array[TelemetryLap], origins: PackedStringArray) -> String:
	var lines := PackedStringArray([header()])
	for i in laps.size():
		lines.append_array(lap_rows(laps[i], origins[i]))
	return "\n".join(lines) + "\n"


func summary_text(laps: Array[TelemetryLap], origins: PackedStringArray, full_throttle: float, braking: float) -> String:
	var lines := PackedStringArray([separator.join(PackedStringArray(SUMMARY_HEADERS))])
	for i in laps.size():
		var lap := laps[i]
		var s := lap.summary(full_throttle, braking)
		lines.append(separator.join(PackedStringArray([str(lap.lap), origins[i], "0" if lap.invalid else "1",
			lap.compound, number(lap.lap_time, 3), number(lap.track_length, 1), str(int(s["samples"])),
			number(float(s["max_speed"]), 1), number(float(s["min_speed"]), 1), number(float(s["avg_speed"]), 1),
			number(float(s["full_throttle"]) * 100.0, 1), number(float(s["braking"]) * 100.0, 1),
			str(int(s["gear_changes"])), str(roundi(float(s["max_rpm"])))])))
	return "\n".join(lines) + "\n"


## Escribe `<dir>/<pista>_<fecha>_<sufijo>.csv` (y `..._resumen.csv`). Devuelve las rutas
## escritas (user://…); vacío si no se pudo.
func export_laps(laps: Array[TelemetryLap], origins: PackedStringArray, track_id: String, suffix: String,
		full_throttle: float = 0.98, braking: float = 0.05) -> PackedStringArray:
	var written := PackedStringArray()
	if laps.is_empty():
		return written
	var error := DirAccess.make_dir_recursive_absolute(directory)
	if error != OK and not DirAccess.dir_exists_absolute(directory):
		push_warning("No se pudo crear la carpeta %s" % directory)
		return written
	var stamp := Time.get_datetime_string_from_system(false, true).replace(":", "-").replace(" ", "_")
	var base := "%s/%s_%s_%s" % [directory, track_id if not track_id.is_empty() else "pista", stamp, suffix]
	var serial := 2
	var stem := base
	while FileAccess.file_exists(stem + ".csv"):
		stem = "%s_%d" % [base, serial]
		serial += 1
	if not _write(stem + ".csv", data_text(laps, origins)):
		return written
	written.append(stem + ".csv")
	if write_summary and _write(stem + "_resumen.csv", summary_text(laps, origins, full_throttle, braking)):
		written.append(stem + "_resumen.csv")
	return written


func _write(path: String, text: String) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_warning("No se pudo escribir %s" % path)
		return false
	file.store_string(text)
	return true
