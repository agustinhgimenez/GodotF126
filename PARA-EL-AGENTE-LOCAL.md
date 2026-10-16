# Para el agente local (Cursor u otro)

Leé esto antes de tocar el proyecto.

## Qué es
**GodotF126**: videojuego-simulador de Fórmula 1 en **Godot 4.7 + GDScript** (probado con 4.7.2; `project.godot` declara la feature `"4.7"`). Materia 350, Ingeniería de Software Avanzado.
- **No** es Unity, **no** es análisis de datos con FastF1, **no** es un chatbot.
- El usuario juega abriendo `GodotF126/project.godot` en el editor de Godot y apretando F5. No hace falta correr comandos.

## Estado actual
- Pasos 0 a 6 del [ROADMAP](GodotF126/ROADMAP.md) completos.
- Próximo: **Paso 7 — manos y brazos del piloto**, luego 8 cockpit detallado, 9 sonido de motor. El ROADMAP tiene 60 pasos en 8 fases; seguir el orden.
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
| `scripts/car/car_engine.gd` | `class_name CarEngine` (nodo `Engine` del auto). RPM, curva de torque, limitador con corte, freno motor. `update(wheel_rpm, throttle, clutch_can_slip, in_neutral, delta)`, `get_output_torque()`. Señal `limiter_hit` |
| `scripts/car/gearbox.gd` | `class_name Gearbox`. Secuencial R (`REVERSE` = −1), N (`NEUTRAL` = 0), 1–8; `manual` o automática. `shift_up/shift_down(speed)`, `toggle_mode()`, `select_gear()`, `get_ratio_for()`, `is_shifting()`, `get_direction()`. Señales `gear_changed`, `shift_denied(reason)`, `mode_changed(manual)` |
| `data/car.json` | Masa, radio de rueda, tracción, drag, datos de motor y caja |
| `scripts/baku_track.gd` | `class_name BakuTrack`. Genera la pista y 3 `Area3D` de checkpoint; expone `centerline`, `track_length`, `get_spawn_transform()`, `get_start_line_transform()`. Señal `checkpoint_crossed(checkpoint, body)` |
| `scripts/lap_timer.gd` | `class_name LapTimer`. Vueltas, sectores, mejor vuelta, récord en `user://records.json`. `format_time()` estático |
| `scripts/hud.gd` | `class_name RaceHUD`. UI construida por código; crea el `Dashboard`. `bind_car()`, `configure_dashboard(data)`, `show_message()` |
| `scripts/ui/dashboard.gd` | `class_name Dashboard`. Tablero dibujado en `_draw()`: luces de cambio, marcha, RPM, velocímetro con aguja. `configure(data)`, `bind_car(car)` |
| `scripts/ui/hud_draw.gd` | `class_name HudDraw` (estático). `shift_light_color()`, `rpm_bar_color()`, `draw_text_centered()` |
| `scripts/ui/wheel_screen.gd` | `class_name WheelScreen`. Pantalla del volante, dentro de un `SubViewport` |
| `scripts/car/steering_wheel.gd` | `class_name SteeringWheel` (nodo hijo de `Car`). Volante armado por código; nodos `Rim`, `PaddleLeft`, `PaddleRight`, `ShiftLeds`. `configure(data)`, `bind_lap_timer()` |

## Sugerencia para el Paso 7
- Manos como hijas de `SteeringWheel/Rim` (así siguen el giro sin código extra); brazos desde un hombro fijo en el chasis hasta la mano, recalculados cada frame (look_at + escala en largo).
- Animar las levas: conectar `gearbox.gear_changed` y comparar con la marcha anterior para saber si fue subida (leva derecha) o bajada (izquierda); rotar `PaddleRight` / `PaddleLeft` y el dedo con un `Tween` corto.
- Sólo visible en la cámara Cockpit, igual que el volante.

## Si la terminal falla en Windows
Crear/editar archivos con el editor igual. Para verificar, pedirle al usuario que abra Godot y copie los errores de la pestaña *Output* / *Debugger*.
