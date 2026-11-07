extends Node
## Estado compartido entre escenas (autoload "GameState" en project.godot).

const MODE_PRACTICE := "practice"
const MODE_TIME_TRIAL := "time_trial"
const MODE_QUALIFYING := "qualifying"
const MODE_RACE := "race"

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


func is_time_trial() -> bool:
	return selected_mode == MODE_TIME_TRIAL


## Contrarreloj, clasificación o carrera: sin cambios de setup ni rivales de práctica.
func is_competitive() -> bool:
	return selected_mode == MODE_TIME_TRIAL or selected_mode == MODE_QUALIFYING or selected_mode == MODE_RACE


func is_race() -> bool:
	return selected_mode == MODE_RACE


func is_qualifying() -> bool:
	return selected_mode == MODE_QUALIFYING
