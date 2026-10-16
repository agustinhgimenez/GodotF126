# Para el agente local (Cursor u otro)

Leé esto antes de tocar el proyecto.

## Qué es
**GodotF126**: videojuego-simulador de Fórmula 1 en **Godot 4.7 + GDScript** (probado con 4.7.2; `project.godot` declara la feature `"4.7"`). Materia 350, Ingeniería de Software Avanzado.
- **No** es Unity, **no** es análisis de datos con FastF1, **no** es un chatbot.
- El usuario juega abriendo `GodotF126/project.godot` en el editor de Godot y apretando F5. No hace falta correr comandos.

## Estado actual
- Pasos 0 a 13 del [ROADMAP](GodotF126/ROADMAP.md) completos (Fases A y B cerradas; Fase C en curso, cierra el hito H1 en el Paso 24).
- Próximo: **Paso 14 — opciones** (caja, ayudas, cámara por defecto, volumen, calidad) guardadas en `user://settings.json`.
- El juego arranca en `scenes/menu.tscn`; `scenes/main.tscn` es la carrera. El ROADMAP tiene 60 pasos en 8 fases; seguir el orden.
- No existe ningún `.exe` todavía. No afirmes lo contrario hasta completar el Paso 59.

## Reglas
1. Trabajar de a un paso del ROADMAP por vez; al terminar, marcarlo como hecho en `ROADMAP.md` y en el `README.md` raíz, y hacer **commit y push a `main`** con el mensaje `Paso N: descripción breve`.
2. GDScript de Godot 4.7 (no Godot 3): `@export`, `@onready`, `CharacterBody3D`, `move_and_slide()` sin argumentos, `Basis.looking_at`, etc.
3. Tipado estático donde se pueda. Cuidado: `var x := dict.get("k")` **no compila** (no se puede inferir desde Variant); usar `var x: String = ...` o `var x = ...`.
4. Los `.tscn` se escriben a mano: `format=3`, `Transform3D(...)` en orden por filas, `ext_resource` con `path="res://..."`.
5. Los datos van en `data/*.json`, no hardcodeados en scripts.
6. La pista de Bakú es un placeholder: no inventar que es el layout oficial FIA.
7. Documentación en español.

## Mapa del código
| Archivo | Responsabilidad |
|---|---|
| `scripts/main.gd` | Escena de carrera: carga JSON, elige piloto (`default_driver_id`), spawnea auto, configura HUD. Esc vuelve al menú |
| `scripts/game_state.gd` | Autoload `GameState`: `selected_driver_id` (vacío = `default_driver_id`). En scripts `-s` de prueba no se puede nombrar directo: usar `root.get_node("GameState")` |
| `scripts/menu/driver_select.gd` | `class_name DriverSelect`. Escudería → piloto con tarjetas. `setup(grid, driver_id)`, `open()`, `back()`; señales `preview_changed`, `confirmed`, `cancelled` |
| `scripts/ui/flag_icon.gd` | `class_name FlagIcon`. Bandera dibujada desde `data/flags.json`. `set_country(code)`, `country_name(code)` |
| `scripts/ui/ui_kit.gd` | `class_name UiKit` (estático). `make_label`, `place`, `make_button`, `apply_button_style`, `number_text` para menús |
| `scripts/data_loader.gd` | `class_name DataLoader` (estático). Rutas de `data/*.json`, `load_json(path)`, `find_driver(grid, id)` |
| `scripts/menu/main_menu.gd` | Menú principal (`scenes/menu.tscn`): plataforma giratoria con el auto en modo exhibición, UI por código, Jugar / Salir. Datos en `data/menu.json` |
| `scripts/audio/menu_music.gd` | `class_name MenuMusic`. Música del menú generada por código (bombo, caja, hi-hat, bajo, arpegio, colchón). `configure(data)`, `play()`, `synthesize(frames)` |
| `scripts/car_controller.gd` | `class_name CarController`. Física arcade, 3 cámaras (tecla C), `configure(data)`, `set_showcase(enabled)` (auto quieto, mudo y sin cámara para menús), `set_livery(principal, secundario, número)`, `get_speed_kmh()`, `get_rpm()`, `get_gear_label()`, `get_top_speed()`, `reset_to_spawn()`, `set_team_color()`. Señales `was_reset`, `camera_changed`. Accede a los componentes por `engine` y `gearbox` |
| `scripts/car/car_engine.gd` | `class_name CarEngine` (nodo `Engine` del auto). RPM, curva de torque, limitador con corte, freno motor. `update(wheel_rpm, throttle, clutch_can_slip, in_neutral, delta)`, `get_output_torque()`. Señal `limiter_hit` |
| `scripts/car/gearbox.gd` | `class_name Gearbox`. Secuencial R (`REVERSE` = −1), N (`NEUTRAL` = 0), 1–8; `manual` o automática. `shift_up/shift_down(speed)`, `toggle_mode()`, `select_gear()`, `get_ratio_for()`, `is_shifting()`, `get_direction()`. Señales `gear_changed`, `shift_denied(reason)`, `mode_changed(manual)` |
| `data/car.json` | Masa, radio de rueda, tracción, drag, datos de motor y caja |
| `scripts/baku_track.gd` | `class_name BakuTrack`. Genera la pista y 3 `Area3D` de checkpoint; expone `centerline`, `track_length`, `get_spawn_transform()`, `get_start_line_transform()`. Señal `checkpoint_crossed(checkpoint, body)` |
| `scripts/lap_timer.gd` | `class_name LapTimer`. Vueltas, sectores, mejor vuelta, récord en `user://records.json`. `format_time()` estático |
| `scripts/hud.gd` | `class_name RaceHUD`. UI construida por código; crea el `Dashboard`. `bind_car()`, `configure_dashboard(data)`, `show_message()` |
| `scripts/ui/dashboard.gd` | `class_name Dashboard`. Tablero dibujado en `_draw()`: luces de cambio, marcha, RPM, velocímetro con aguja. `configure(data)`, `bind_car(car)` |
| `scripts/ui/hud_draw.gd` | `class_name HudDraw` (estático). `shift_light_color()`, `rpm_bar_color()`, `draw_text_centered()` |
| `scripts/ui/wheel_screen.gd` | `class_name WheelScreen`. Pantalla del volante, dentro de un `SubViewport` |
| `scripts/car/steering_wheel.gd` | `class_name SteeringWheel` (nodo hijo de `Car`). Volante armado por código; nodos `Rim`, `PaddleLeft`, `PaddleRight`, `ShiftLeds`. `configure(data)`, `bind_lap_timer()`, `get_rim()`, `get_grip_position(side)`, `get_paddle(side)` |
| `scripts/car/driver_arms.gd` | `class_name DriverArms`. Manos colgadas del aro, brazos con IK de dos huesos, animación de levas con `Tween` al cambiar de marcha |
| `scripts/car/car_livery.gd` | `class_name CarLivery` (nodo `Livery`). Pinta los grupos `team_paint` / `team_paint_secondary`, arma franjas y números `Label3D`. `apply(principal, secundario, número)`, `number_color()` |
| `scripts/car/engine_audio.gd` | `class_name EngineAudio`. Sonido de motor sintetizado en un `AudioStreamGenerator`: tono por RPM, combustión, turbo, golpe de caja, petardeo. `configure(data)`, `synthesize(frames)` (público para pruebas sin reproducir) |
| `scripts/car/car_audio_fx.gd` | `class_name CarAudioFx`. Chirrido de neumáticos (derrape y freno de mano), viento, golpes y roce contra muros, sintetizados igual que el motor. `configure(data)`, `get_squeal_amount()`, `synthesize(frames)` |
| `scripts/car/cockpit_detail.gd` | `class_name CockpitDetail`. Halo (siempre visible), espejos con `SubViewport` + `Camera3D` (sólo renderizan en Cockpit), visera/mentonera del casco colgadas de la cámara en la capa visual 2. `configure(data)`, `set_cockpit_view(enabled)` |

La vibración de cámara está en `CarController._update_shake()`; `add_camera_impact(0–1)` agrega un golpe (lo usan los muros y los cambios; los pianos del Paso 19 deberían llamarlo).

Si se agrega un script con `class_name` nuevo y se prueba sin abrir el editor, correr antes `Godot_v4.7.2-stable_win64.exe --headless --path GodotF126 --import` para que se registre la clase.

## Sugerencia para el Paso 14
- Autoload `Settings` (`scripts/settings.gd`): diccionario con valores por defecto, `load()` / `save()` en `user://settings.json`, señal `changed`.
- Opciones: caja manual/automática por defecto (`Gearbox.manual`), cámara inicial (`CarController.camera_mode`), volumen general / motor / efectos / música (buses de audio: crear `Engine`, `Fx`, `Music` en un `default_bus_layout.tres` o por código con `AudioServer`), calidad (sombras on/off, resolución de espejos, MSAA) y ayudas (por ahora un placeholder hasta la Fase D).
- Panel "Opciones" en el menú con `UiKit`, entre Jugar y Salir; aplicar en `main.gd` al cargar la carrera.

## Verificación sin abrir el editor
Se puede correr el proyecto sin ventana con `Godot_v4.7.2-stable_win64.exe --headless --path GodotF126 --quit-after 300`, o con un script `-s prueba.gd` que extienda `SceneTree`, instancie `res://scenes/main.tscn` y pruebe cosas (cambiar cámara, cambiar marcha) imprimiendo resultados. Para capturas: mismo script sin `--headless`, `root.get_viewport().get_texture().get_image().save_png(...)`.

## Si la terminal falla en Windows
Crear/editar archivos con el editor igual. Para verificar, pedirle al usuario que abra Godot y copie los errores de la pestaña *Output* / *Debugger*.
