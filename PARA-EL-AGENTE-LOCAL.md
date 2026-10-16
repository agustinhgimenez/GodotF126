# Para el agente local (Cursor u otro)

Leé esto antes de tocar el proyecto.

## Qué es
**GodotF126**: videojuego-simulador de Fórmula 1 en **Godot 4.7 + GDScript** (probado con 4.7.2; `project.godot` declara la feature `"4.7"`). Materia 350, Ingeniería de Software Avanzado.
- **No** es Unity, **no** es análisis de datos con FastF1, **no** es un chatbot.
- El usuario juega abriendo `GodotF126/project.godot` en el editor de Godot y apretando F5. No hace falta correr comandos.

## Estado actual
- Pasos 0 a 3 del [ROADMAP](GodotF126/ROADMAP.md) completos.
- Próximo: **Paso 4 — caja manual**, luego 5 tablero, 6 volante 3D, 7 manos. El ROADMAP tiene 60 pasos en 8 fases; seguir el orden.
- No existe ningún `.exe` todavía. No afirmes lo contrario hasta completar el Paso 59.

## Reglas
1. Trabajar de a un paso del ROADMAP por vez; al terminar, marcarlo como hecho en `ROADMAP.md` y en el `README.md` raíz.
2. GDScript de Godot 4.7 (no Godot 3): `@export`, `@onready`, `CharacterBody3D`, `move_and_slide()` sin argumentos, `Basis.looking_at`, etc.
3. Tipado estático donde se pueda. Cuidado: `var x := dict.get("k")` **no compila** (no se puede inferir desde Variant); usar `var x: String = ...` o `var x = ...`.
4. Los `.tscn` se escriben a mano: `format=3`, `Transform3D(...)` en orden por filas, `ext_resource` con `path="res://..."`.
5. Los datos van en `data/*.json`, no hardcodeados en scripts.
6. La pista de Bakú es un placeholder: no inventar que es el layout oficial FIA.
7. Documentación en español.

## Mapa del código
| Archivo | Responsabilidad |
|---|---|
| `scripts/main.gd` | Carga JSON, elige piloto (`default_driver_id`), spawnea auto, configura HUD |
| `scripts/car_controller.gd` | `class_name CarController`. Física arcade, 3 cámaras (tecla C), `configure(data)`, `get_speed_kmh()`, `get_rpm()`, `get_gear_label()`, `get_top_speed()`, `reset_to_spawn()`, `set_team_color()`. Señales `was_reset`, `camera_changed`. Accede a los componentes por `engine` y `gearbox` |
| `scripts/car/car_engine.gd` | `class_name CarEngine` (nodo `Engine` del auto). RPM, curva de torque, limitador con corte, freno motor. `update(wheel_rpm, throttle, clutch_can_slip, delta)`, `get_output_torque()`. Señal `limiter_hit` |
| `scripts/car/gearbox.gd` | `class_name Gearbox`. 8 relaciones + diferencial, `get_total_ratio()`, `update_automatic()` (provisorio). Señal `gear_changed(gear)` |
| `data/car.json` | Masa, radio de rueda, tracción, drag, datos de motor y caja |
| `scripts/baku_track.gd` | `class_name BakuTrack`. Genera la pista y 3 `Area3D` de checkpoint; expone `centerline`, `track_length`, `get_spawn_transform()`, `get_start_line_transform()`. Señal `checkpoint_crossed(checkpoint, body)` |
| `scripts/lap_timer.gd` | `class_name LapTimer`. Vueltas, sectores, mejor vuelta, récord en `user://records.json`. `format_time()` estático |
| `scripts/hud.gd` | `class_name RaceHUD`. UI construida por código |

## Sugerencia para el Paso 4
- Extender `Gearbox` (no el controlador): modo manual, N (gear 0) y R (gear -1), corte de potencia al cambiar, bloqueo de rebaje si `rpm × relación_nueva / relación_actual > limiter_rpm`.
- Hoy la marcha atrás es arcade (S con el auto quieto) y `get_gear_label()` devuelve "R" mirando `forward_speed`; en el Paso 4 pasa a ser una marcha real.
- Acciones nuevas en el input map: `gear_up` (E), `gear_down` (Q), `toggle_gearbox` (M). Agregarlas también a `DEFAULT_KEYS` en `main.gd`.

## Si la terminal falla en Windows
Crear/editar archivos con el editor igual. Para verificar, pedirle al usuario que abra Godot y copie los errores de la pestaña *Output* / *Debugger*.
