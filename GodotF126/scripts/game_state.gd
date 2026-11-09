extends Node
## Estado compartido entre escenas (autoload "GameState" en project.godot).

const MODE_PRACTICE := "practice"
const MODE_TIME_TRIAL := "time_trial"
const MODE_QUALIFYING := "qualifying"
const MODE_RACE := "race"
## Paso 55: el modo del menú; en juego cada fecha es clasificación o carrera con championship = true.
const MODE_CHAMPIONSHIP := "championship"
## Carrera de 2 jugadores por internet (Online, scripts/net/).
const MODE_ONLINE := "online"

## Paso 53: pista (id de data/tracks.json); vacío = el default_track_id del archivo.
var selected_track: String = ""
## Piloto elegido en el menú; vacío = el default_driver_id de la grilla.
var selected_driver_id: String = ""
## Modo de juego (data/modes.json); vacío = el default_mode del archivo.
var selected_mode: String = ""
## Vueltas del modo (los que tienen "lap_options"); 0 = la default_laps del modo.
var lap_count: int = 0
## Compuesto de neumáticos ("tyre_compounds" de data/car.json); vacío = el de por defecto.
var tyre_compound: String = ""
## Paso 47: semilla de los tiempos de clasificación de la IA (0 = elegir una al azar) y mejor
## vuelta válida del jugador en la última clasificación (−1 = no corrió; la carrera usa su récord).
var session_seed: int = 0
var qualifying_time: float = -1.0
## Paso 56: clima (id de data/weather.json); vacío = su "default" (seco).
var weather: String = ""
## Paso 55: la sesión es una fecha de la temporada guardada (Championship, user://championship.json).
var championship: bool = false
## Online: id de la sala a la que se une (0 = crea una sala con las reglas elegidas).
var online_room: int = 0
## Online: al volver al menú se abre directo la pantalla de salas.
var open_online_lobby: bool = false


## Paso 59: el .exe exportado no acepta una escena en la línea de comandos; "-- --benchmark"
## abre la prueba de rendimiento del Paso 24 en lugar del menú.
const BENCHMARK_SCENE := "res://scenes/benchmark.tscn"
## En el navegador no hay fuentes del sistema que completen las flechas, ▶ y ●: DejaVu Sans
## (licencia en fonts/DejaVuSans-LICENSE.txt) va de respaldo de la fuente por defecto.
const SYMBOL_FONT := "res://fonts/DejaVuSans.ttf"


## Paso 53: "Godot --path . -- --track prueba" elige la pista hasta que haya selector en el menú.
func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	for k in args.size() - 1:
		if args[k] == "--track":
			selected_track = args[k + 1]
	if "--benchmark" in args:
		get_tree().change_scene_to_file.call_deferred(BENCHMARK_SCENE)
	if OS.has_feature("web"):
		_add_symbol_fallback()


func _add_symbol_fallback() -> void:
	var symbols: Font = load(SYMBOL_FONT)
	var fonts: Array[Font] = [ThemeDB.fallback_font, ThemeDB.get_default_theme().default_font]
	for font in fonts:
		if font != null and not font.fallbacks.has(symbols):
			var chain := font.fallbacks
			chain.append(symbols)
			font.fallbacks = chain


func is_time_trial() -> bool:
	return selected_mode == MODE_TIME_TRIAL


## Contrarreloj, clasificación, carrera u online: sin cambios de setup ni rivales de práctica.
func is_competitive() -> bool:
	return selected_mode in [MODE_TIME_TRIAL, MODE_QUALIFYING, MODE_RACE, MODE_ONLINE]


func is_online() -> bool:
	return selected_mode == MODE_ONLINE


func is_race() -> bool:
	return selected_mode == MODE_RACE


func is_qualifying() -> bool:
	return selected_mode == MODE_QUALIFYING
