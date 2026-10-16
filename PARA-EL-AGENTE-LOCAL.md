# Para el agente local (Cursor u otro)

Leé esto antes de tocar el proyecto.

## Qué es
**GodotF126**: videojuego-simulador de Fórmula 1 en **Godot 4.7 + GDScript** (probado con 4.7.2; `project.godot` declara la feature `"4.7"`). Materia 350, Ingeniería de Software Avanzado.
- **No** es Unity, **no** es análisis de datos con FastF1, **no** es un chatbot.
- El usuario juega abriendo `GodotF126/project.godot` en el editor de Godot y apretando F5. No hace falta correr comandos.

## Estado actual
- Pasos 0 a 16 del [ROADMAP](GodotF126/ROADMAP.md) completos (Fases A y B cerradas; Fase C en curso, cierra el hito H1 en el Paso 24).
- Próximo: **Paso 17 — semáforo de largada** con 5 luces y detección de salto.
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
| `scripts/main.gd` | Escena de carrera: carga JSON, elige piloto (`default_driver_id`), spawnea auto, configura HUD, aplica `Settings` y el modo de `GameState` (`_setup_mode()` fija `lap_timer.lap_limit` en contrarreloj). Esc abre la pausa; Reiniciar = `reload_current_scene()`. Con `session_finished` suelta los controles, bloquea la pausa y tras `results_delay` abre `ResultsScreen` |
| `scripts/ui/results_screen.gd` | `class_name ResultsScreen` (nodo `ResultsScreen` de `main.tscn`, `process_mode = ALWAYS`, capa 11). `open(timer, subtítulo)` pausa y arma la tabla desde `LapTimer.lap_history` (mejores en violeta), total, mejor vuelta y récord. Señales `repeat_requested`, `menu_requested` |
| `scripts/menu/mode_select.gd` | `class_name ModeSelect`. Tarjetas de modo desde `data/modes.json`; ←/→ cambian las vueltas en los modos con `lap_options`. `setup(data, modo, vueltas)`, `open()`, `back()`, `set_accent()`; señales `confirmed(mode_id, laps)`, `cancelled` |
| `data/modes.json` | Modos (`practice`, `time_trial` con `lap_options` / `default_laps`), `default_mode`, `results_delay` |
| `scripts/ui/pause_menu.gd` | `class_name PauseMenu` (nodo `PauseMenu` de `main.tscn`, `process_mode = ALWAYS`). Pausa el árbol; `main.gd` escucha `paused_changed` para ocultar el HUD y silenciar el auto. Continuar / Reiniciar / Opciones (`OptionsPanel`) / Menú / Salir. `open()`, `close()`, `is_open()`, `set_accent()`, `set_subtitle()`; señales `paused_changed`, `restart_requested`, `menu_requested` |
| `scripts/game_state.gd` | Autoload `GameState`: `selected_driver_id` (vacío = `default_driver_id`), `selected_mode` (vacío = `default_mode` de `modes.json`), `lap_count` (0 = `default_laps`), `is_time_trial()`, constantes `MODE_PRACTICE` / `MODE_TIME_TRIAL`. En scripts `-s` de prueba no se puede nombrar directo: usar `root.get_node("GameState")` |
| `scripts/settings.gd` | Autoload `Settings` (sin `class_name`). Defaults y perfiles en `data/settings.json`, guardado en `user://settings.json`. `get_value`, `set_value` (sanea, aplica, guarda, emite `changed(key)`), `reset_to_defaults`, `apply_to_car(car)`, `shadows_enabled()`, constantes `BUS_ENGINE` / `BUS_FX` / `BUS_MUSIC`. Igual que `GameState`: en scripts `-s` usar `root.get_node("Settings")` y no nombrar clases que dependan de él (p. ej. `OptionsPanel`) |
| `scripts/menu/options_panel.gd` | `class_name OptionsPanel`. Panel de opciones del menú (filas ‹ ›, deslizadores de volumen, Restablecer / Volver). `open()`, `set_accent(color)`, `refresh()`; señal `closed` |
| `scripts/menu/driver_select.gd` | `class_name DriverSelect`. Escudería → piloto con tarjetas. `setup(grid, driver_id)`, `open()`, `back()`; señales `preview_changed`, `confirmed`, `cancelled` |
| `scripts/ui/flag_icon.gd` | `class_name FlagIcon`. Bandera dibujada desde `data/flags.json`. `set_country(code)`, `country_name(code)` |
| `scripts/ui/ui_kit.gd` | `class_name UiKit` (estático). `make_label`, `place`, `make_button`, `apply_button_style`, `number_text` para menús |
| `scripts/data_loader.gd` | `class_name DataLoader` (estático). Rutas de `data/*.json`, `load_json(path)`, `find_driver(grid, id)` |
| `scripts/menu/main_menu.gd` | Menú principal (`scenes/menu.tscn`): plataforma giratoria con el auto en modo exhibición, UI por código, Jugar / Opciones / Salir. Datos en `data/menu.json` |
| `scripts/audio/menu_music.gd` | `class_name MenuMusic`. Música del menú generada por código (bombo, caja, hi-hat, bajo, arpegio, colchón). `configure(data)`, `play()`, `synthesize(frames)` |
| `scripts/car_controller.gd` | `class_name CarController`. Física arcade, 3 cámaras (tecla C), `configure(data)`, `set_showcase(enabled)` (auto quieto, mudo y sin cámara para menús), `set_livery(principal, secundario, número)`, `get_speed_kmh()`, `get_rpm()`, `get_gear_label()`, `get_top_speed()`, `reset_to_spawn()`, `set_camera_mode(mode)`. Señales `was_reset`, `camera_changed`. Accede a los componentes por `engine` y `gearbox` |
| `scripts/car/car_engine.gd` | `class_name CarEngine` (nodo `Engine` del auto). RPM, curva de torque, limitador con corte, freno motor. `update(wheel_rpm, throttle, clutch_can_slip, in_neutral, delta)`, `get_output_torque()`. Señal `limiter_hit` |
| `scripts/car/gearbox.gd` | `class_name Gearbox`. Secuencial R (`REVERSE` = −1), N (`NEUTRAL` = 0), 1–8; `manual` o automática. `shift_up/shift_down(speed)`, `toggle_mode()`, `select_gear()`, `get_ratio_for()`, `is_shifting()`, `get_direction()`. Señales `gear_changed`, `shift_denied(reason)`, `mode_changed(manual)` |
| `data/car.json` | Masa, radio de rueda, tracción, drag, datos de motor y caja |
| `scripts/baku_track.gd` | `class_name BakuTrack`. Genera la pista y 3 `Area3D` de checkpoint; expone `centerline`, `track_length`, `get_spawn_transform()`, `get_start_line_transform()`. Señal `checkpoint_crossed(checkpoint, body)` |
| `scripts/lap_timer.gd` | `class_name LapTimer`. Vueltas, sectores, mejor vuelta, récord en `user://records.json`. `lap_limit` (0 = sin límite), `finished`, `lap_history`, `total_time()`, `beat_record()`, señal `session_finished`. `format_time()` estático |
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

## Sugerencia para el Paso 17
- **Semáforo de largada** en contrarreloj (y más adelante en carrera): hoy el auto arranca detrás de la línea y el cronómetro empieza al cruzarla (largada lanzada). Para una largada detenida, ubicar el auto sobre la línea (`BakuTrack.get_start_line_transform()`), poner `car.controls_enabled = false` salvo el acelerador (o permitir acelerar en N/1ª sin avanzar) y encender 5 luces rojas de a una por segundo; al apagarse todas (tras una espera aleatoria de 0,2–3 s) soltar el auto y arrancar el cronómetro a mano (agregar a `LapTimer` algo como `start_now()`).
- **Salto**: si el auto se mueve más de unos centímetros antes del apagado, mostrar "Largada en falso" y sumar una penalización (p. ej. +5 s al total en `ResultsScreen`) o reiniciar la largada.
- Las luces pueden ser un `Control` dibujado en `_draw()` en el HUD (como `Dashboard`) y además un pórtico 3D sobre la línea. Tiempos (luz por segundo, espera aleatoria, penalización) en `data/modes.json`.
- Con la sesión en pausa el semáforo no debe avanzar: usar `create_timer(..., false)` o acumular en `_process` (que se congela con `paused`).

## Verificación sin abrir el editor
Se puede correr el proyecto sin ventana con `Godot_v4.7.2-stable_win64.exe --headless --path GodotF126 --quit-after 300`, o con un script `-s prueba.gd` que extienda `SceneTree`, instancie `res://scenes/main.tscn` y pruebe cosas (cambiar cámara, cambiar marcha) imprimiendo resultados. Para capturas: mismo script sin `--headless`, `root.get_viewport().get_texture().get_image().save_png(...)`.

## Si la terminal falla en Windows
Crear/editar archivos con el editor igual. Para verificar, pedirle al usuario que abra Godot y copie los errores de la pestaña *Output* / *Debugger*.
