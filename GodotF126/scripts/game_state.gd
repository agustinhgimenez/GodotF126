extends Node
## Estado compartido entre escenas (autoload "GameState" en project.godot).

const MODE_PRACTICE := "practice"
const MODE_TIME_TRIAL := "time_trial"

## Piloto elegido en el menú; vacío = el default_driver_id de la grilla.
var selected_driver_id: String = ""
## Modo de juego (data/modes.json); vacío = el default_mode del archivo.
var selected_mode: String = ""
## Vueltas del contrarreloj; 0 = la default_laps del modo.
var lap_count: int = 0


func is_time_trial() -> bool:
	return selected_mode == MODE_TIME_TRIAL
