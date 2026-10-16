# GodotF126 — ROADMAP (versión pro)

Desarrollo iterativo e incremental: **un paso por vez**, y cada paso termina con algo jugable que se prueba abriendo Godot 4.7 y apretando F5.

Los pasos están agrupados en **fases**. El orden prioriza primero lo que más cambia la sensación de manejar un F1 (motor, caja manual, tablero, cockpit), después la física de simulador y recién después el contenido (modos, rivales, más pistas).

## Hitos

| Hito | Se alcanza al terminar | Qué se puede mostrar |
|---|---|---|
| **H1 — Demo de cursada** | Paso 24 | Elegir escudería/piloto, caja manual, cockpit con volante y manos, sonido, vuelta cronometrada, resultado |
| **H2 — Simulador** | Paso 38 | Física de neumáticos, aero activa 2026, ERS, setup, telemetría para entrenar |
| **H3 — Juego completo** | Paso 52 | Rivales con IA, carrera con largada, fantasma, replays |
| **H4 — Entrega final** | Paso 60 | Tests, optimización, `.exe`, documentación y defensa |

Para la materia alcanza con **H1** (1 auto, 1 pista, física jugable, HUD, flujo menú → pista → resultado). El resto suma nivel.

---

## Fase A — Base ✅

| Paso | Contenido | Estado |
|---|---|---|
| 0 | Esqueleto: `project.godot`, carpetas, grilla 2026 y pistas en JSON, input map | ✅ |
| 1 | Auto arcade con WASD, pista Bakú generada por código, HUD de velocidad y piloto | ✅ |
| 2 | Cronómetro por sectores, mejor vuelta, récord guardado, cámaras TV / cercana / cockpit (C) | ✅ |

## Fase B — Motor, caja manual, cockpit y sonido ✅

| Paso | Contenido | Estado |
|---|---|---|
| 3 | **Motor con RPM**: ralentí ~4.000, limitador ~12.500 rpm, curva de torque, las RPM salen de marcha + velocidad | ✅ |
| 4 | **Caja manual de 8 marchas + N + R** con levas: **E** sube, **Q** baja. Corte de potencia al cambiar, rebote en limitador, bloqueo de rebaje que pasaría de vueltas. **M** alterna manual / automática | ✅ |
| 5 | **Tablero en el HUD**: marcha grande (R, N, 1–8), RPM en barra con **luces de cambio** tipo F1 (verde → rojo → azul), velocímetro digital + **aguja analógica** | ✅ |
| 6 | **Volante 3D** en el cockpit: gira con la dirección (±180°), pantalla con marcha / RPM / velocidad / delta, LEDs de cambio arriba | ✅ |
| 7 | **Manos y brazos del piloto** sobre el volante: siguen el giro; los dedos accionan la leva al cambiar | ✅ |
| 8 | Cockpit detallado: halo, casco con visor, **espejos retrovisores** con imagen real (`SubViewport`), vibración de cámara con velocidad y pianos | ✅ |
| 9 | **Sonido de motor** generado por código en capas según RPM y acelerador; sonido de cambio, limitador y petardeo al soltar | ✅ |
| 10 | Sonidos de neumáticos (chirrido por deslizamiento), viento por velocidad, golpes contra muros | ✅ |

## Fase C — Menús y flujo de juego (cierra H1) ⏳

| Paso | Contenido | Estado |
|---|---|---|
| 11 | Menú principal con fondo 3D del auto girando y música | ✅ |
| 12 | **Selección de escudería → piloto** con tarjetas (color del equipo, número, bandera) desde `grid_2026.json` | ✅ |
| 13 | Livery de dos colores por equipo y número del piloto en el auto | ✅ |
| 14 | Opciones: caja manual / automática, ayudas, cámara por defecto, volumen, calidad gráfica; guardado en `user://settings.json` | ✅ |
| 15 | Pausa con Esc (Continuar / Reiniciar / Menú / Salir) | ✅ |
| 16 | Modo **Contrarreloj**: N vueltas y después pantalla de resultado con tiempos por vuelta y sectores | ⏳ Siguiente |
| 17 | **Semáforo de largada** con 5 luces y detección de salto | |
| 18 | Cámaras extra: T-cam sobre el airbox, cámara de capot, cámaras de TV fijas en la pista | |
| 19 | Pianos y zonas de escape; **límites de pista** con vuelta invalidada al salirse | |
| 20 | Carteles de frenado 150 / 100 / 50 m antes de cada curva | |
| 21 | Bakú mejorado: trazado más parecido (aproximado, sin datos oficiales FIA), **sector del castillo estrecho**, elevación suave | |
| 22 | Ciudad: tribunas, edificios, barreras con publicidad, LOD para rendimiento | |
| 23 | Iluminación de atardecer, sombras, reflejos en el mar | |
| 24 | Pulido de H1: tutorial de controles, pantalla de carga, prueba en PC del laboratorio | |

## Fase D — Física de simulador (H2)

| Paso | Contenido | Estado |
|---|---|---|
| 25 | Modelo por **4 ruedas**: suspensión por raycast (resorte + amortiguador) en lugar del arcade | |
| 26 | **Neumáticos**: curva tipo Pacejka simplificada, ángulo de deriva y deslizamiento longitudinal por rueda | |
| 27 | Transferencia de peso en frenada, aceleración y curva | |
| 28 | **Aerodinámica**: carga y resistencia que crecen con la velocidad | |
| 29 | **Aero activa 2026**: modo recta (baja resistencia) / modo curva, y **modo adelantamiento** | |
| 30 | Frenos: reparto delantero/trasero ajustable, bloqueo de ruedas, ABS opcional | |
| 31 | Diferencial y **control de tracción** con niveles | |
| 32 | **ERS 2026**: batería, recuperación en frenada, despliegue en aceleración, indicador en volante | |
| 33 | Neumáticos: compuestos blando / medio / duro, temperatura y desgaste | |
| 34 | Combustible: el peso baja vuelta a vuelta | |
| 35 | **Setup del auto**: alerones, altura, rigidez, presiones, relaciones de marcha | |
| 36 | Daños: alerón delantero roto reduce la carga, pinchazos | |
| 37 | Soporte de **joystick y volante** (acelerador y freno analógicos, vibración); remapeo de controles | |
| 38 | Ayudas de manejo: línea de trazada ideal con zonas de frenado en color | |

## Fase E — Telemetría y entrenamiento

| Paso | Contenido | Estado |
|---|---|---|
| 39 | Registro de telemetría por vuelta: velocidad, RPM, marcha, acelerador, freno, dirección, posición | |
| 40 | **Delta en vivo** contra la mejor vuelta (verde / rojo) en HUD y volante | |
| 41 | Pantalla de análisis: gráficos contra distancia, comparando dos vueltas | |
| 42 | Exportación a CSV | |
| 43 | **Auto fantasma** de la mejor vuelta | |

## Fase F — Rivales y carrera (H3)

| Paso | Contenido | Estado |
|---|---|---|
| 44 | IA que sigue la trazada con velocidad objetivo según curvatura | |
| 45 | IA con niveles de dificultad, defensa y adelantamientos | |
| 46 | Colisiones entre autos y penalizaciones | |
| 47 | Clasificación y carrera con la **grilla 2026 completa** (22 autos) | |
| 48 | Pit lane con limitador de velocidad y paradas en boxes | |
| 49 | Estrategia: cambio de compuesto, radio del ingeniero | |
| 50 | Banderas amarilla y azul, **Safety Car** | |
| 51 | **Replays** con cámaras de TV | |
| 52 | Pantalla de resultados de carrera con puntos | |

## Fase G — Contenido extra

| Paso | Contenido | Estado |
|---|---|---|
| 53 | Generador de pistas por puntos de control, reutilizable para otros circuitos | |
| 54 | Segunda pista | |
| 55 | Modo campeonato con varias carreras | |
| 56 | Lluvia y pista mojada | |

## Fase H — Ingeniería y entrega (H4)

| Paso | Contenido | Estado |
|---|---|---|
| 57 | **Tests automáticos** con GUT: caja de cambios, cronómetro, carga de JSON, física básica | |
| 58 | Optimización y perfilado: 60 FPS en PC del laboratorio | |
| 59 | **Export Windows `.exe`** (agregar `*.json` a los filtros de export) | |
| 60 | Manual de usuario, informe final, video demo y defensa | |

---

## Notas técnicas

- **Arte**: las manos, el volante y el auto se hacen primero con formas simples generadas en Godot. Se pueden reemplazar después por modelos 3D (Blender o assets libres) sin cambiar la lógica.
- **Force feedback**: Godot 4 soporta vibración de gamepad, pero no force feedback real de volante. Si se quiere, hace falta un plugin externo (evaluar en el Paso 37).
- **Datos reales**: no se usan trazados oficiales FIA ni datos de telemetría con licencia. Todo es aproximado.
- **Arquitectura prevista**: autoloads `GameState` (selección y modo), `Settings` (opciones) y `AudioManager`; el auto dividido en componentes (`Engine`, `Gearbox`, `Tyres`, `Aero`, `ERS`) comunicados por señales.

## Detalle de lo hecho

### Paso 0 — Esqueleto
`project.godot` (originalmente Godot 4.3; hoy guardado con 4.7. GL Compatibility, 1280x720), `data/grid_2026.json`, `data/tracks.json`, input map WASD / flechas / Espacio / R / C.

### Paso 1 — Manejo + Bakú + HUD
`car_controller.gd` (física arcade, 55 m/s máx.), `baku_track.gd` (pista generada: asfalto, muros con colisión, largada, mar, edificios; **no** es el layout FIA), `main.gd` (piloto desde JSON, color del equipo), `hud.gd`.

### Paso 2 — Cronómetro y cámaras
`lap_timer.gd` (sectores en orden, mejor vuelta, récord en `user://records.json`), checkpoints `Area3D` en la pista, HUD de tiempos, tecla C para 3 cámaras.

### Paso 3 — Motor con RPM
- **Componentes** nuevos como nodos hijos de `Car`: `scripts/car/car_engine.gd` (`class_name CarEngine`; no se llama `Engine` porque choca con el singleton de Godot) y `scripts/car/gearbox.gd` (`class_name Gearbox`).
- **Datos** en `data/car.json`: masa, radio de rueda, límite de tracción, resistencia aerodinámica, curva de torque, RPM de ralentí / limitador / largada y relaciones de las 8 marchas.
- **Cálculo de RPM**: `rpm = (velocidad / radio_rueda) × relación_marcha × diferencial × 60 / 2π`, con piso en el ralentí (4.000). En 1ª, por debajo de 7.500 rpm, el embrague "patina" y el motor sube con el acelerador aunque el auto esté quieto.
- **Aceleración**: `fuerza = torque(rpm) × acelerador × relación × eficiencia / radio_rueda`; `a = fuerza / masa`, recortada por el límite de tracción (16 m/s²). Se restan freno motor (al soltar el acelerador) y resistencia aerodinámica (`k·v²`).
- **Limitador** a 12.500 rpm: corta la potencia 0,06 s y vuelve, así el auto "rebota" contra el limitador en 8ª.
- **Velocidad máxima** ya no está fija: sale de la 8ª marcha en el limitador (~198 km/h con los datos actuales, escalado arcade para la pista de Bakú placeholder).
- **Caja automática provisoria**: sube a 12.000 rpm y baja a 7.000 rpm. El Paso 4 la reemplaza por la manual con levas.
- **HUD**: marcha (R, 1–8) y RPM con barra que se pone roja arriba del 85 %. El tablero completo con luces de cambio queda para el Paso 5.
- **Cómo probar**: F5, acelerar desde parado y mirar que la marcha suba de 1 a 8 y que las RPM caigan en cada cambio; soltar W y ver que las RPM bajan y la caja rebaja; mantener W en la recta larga y ver el rebote en el limitador.

### Paso 4 — Caja manual
- `Gearbox` pasa a ser **secuencial**: R (−1) ↔ N (0) ↔ 1 … 8. Acciones nuevas en el input map y en `DEFAULT_KEYS`: `gear_up` (**E**), `gear_down` (**Q**), `toggle_gearbox` (**M**).
- **Modo por defecto** en `data/car.json` (`"default_mode": "manual"`). En manual solo cambian las levas; en automática la caja usa los umbrales del Paso 3.
- **Corte de potencia**: cada cambio deja el auto sin tracción `shift_time` = 0,08 s.
- **Bloqueo de rebaje**: antes de engranar una marcha se calcula `rpm = velocidad / radio × relación × 60 / 2π`; si supera el limitador, se rechaza con aviso en pantalla. Lo mismo al pasar de N a 1ª yendo rápido.
- **Reversa real**: relación propia (`reverse_ratio`), aceleración limitada a 8 m/s² y solo se engrana con el auto casi detenido (< 1 m/s).
- **Neutro**: el motor gira libre; el acelerador lo lleva del ralentí al limitador sin mover el auto.
- **Limitador**: en manual, si no se sube de marcha, el motor rebota contra las 12.500 rpm (el corte ya existía en el Paso 3).
- **Pedales en automática**: se mantiene el manejo arcade original; S con el auto quieto pone R y pasa a ser el acelerador, W vuelve a 1ª.
- **HUD**: modo (MAN / AUT), marcha (R, N, 1–8) y RPM; mensajes al cambiar de modo y al rechazar un cambio.
- **Cómo probar (Paso 4)**: F5 → largar en 1ª y subir con E mirando las RPM; en una recta a fondo apretar Q varias veces y ver "Rebaje bloqueado"; frenar del todo, Q, Q → N (acelerar sube RPM sin moverse) → R (W va para atrás); M y repetir en automática.

### Paso 5 — Tablero en el HUD
- Nuevo `scripts/ui/dashboard.gd` (`class_name Dashboard`, un `Control` que se dibuja entero en `_draw()`). `hud.gd` lo crea abajo a la derecha y le pasa el auto; se sacaron el velocímetro y la barra de RPM viejos.
- **Luces de cambio** (15): se encienden de izquierda a derecha entre `shift_light_start_rpm` (9.000) y el punto de cambio de la caja (`shift_up_rpm`, 12.000). Un tercio verde, un tercio rojo, un tercio azul. Al llegar al punto de cambio quedan **todas azules**; en el limitador **parpadean** a 8 Hz.
- **Marcha grande** (R, N, 1–8), que se pone **roja** un instante cuando la caja rechaza un cambio. Debajo, el modo (MAN / AUT), las RPM en número y una barra de RPM con el mismo código de colores.
- **Velocímetro**: dial de 270° con marcas cada 20 km/h (números cada 40), **aguja analógica** suavizada y velocidad digital en el centro. El máximo del dial se redondea desde la velocidad máxima del auto.
- **Datos** en `data/car.json` → `"dashboard"`: cantidad de luces, RPM a la que empiezan y paso de las marcas del dial.
- **Cómo probar**: F5 → acelerar en 1ª sin cambiar y ver cómo se llenan las luces verde → rojo → azul y parpadean en el limitador; subir con E y ver que se apagan; Q a alta velocidad y ver la marcha en rojo; la aguja tiene que acompañar al número de km/h.

### Paso 6 — Volante 3D
- Nuevo nodo `SteeringWheel` en `car.tscn` (`scripts/car/steering_wheel.gd`), delante de la cámara Cockpit e inclinado 20° hacia el piloto. Se arma por código con formas simples: cuerpo de carbono, dos grips, **levas** detrás (`PaddleLeft` / `PaddleRight`, para animar en el Paso 7) y columna de dirección.
- **Giro**: `rotation.z = get_steer() × 180°`; `CarController.get_steer()` expone la dirección suavizada (−1 a 1).
- **Visibilidad**: sólo en la cámara Cockpit (se maneja en `_apply_camera_mode()`, igual que el casco). Cuando está oculto, el `SubViewport` deja de renderizar.
- **LEDs**: 15 arriba del volante con la misma lógica que el tablero. La lógica de colores y el texto centrado se movieron a `scripts/ui/hud_draw.gd` (`HudDraw`), compartido por `Dashboard` y la pantalla.
- **Pantalla**: `SubViewport` de 256×128 con `WheelScreen` (`scripts/ui/wheel_screen.gd`), mostrado como textura sin sombreado en un `QuadMesh`. Muestra barra de RPM, marcha grande, velocidad, RPM, modo MAN/AUT, tiempo de vuelta y **delta**.
- **Delta por sector**: `LapTimer` guarda los parciales de la mejor vuelta (`best_lap_splits`) y al cerrar cada sector calcula `split_delta` = parcial actual − parcial de la mejor vuelta (verde si es negativo). El delta continuo en vivo queda para el Paso 40.
- **Cómo probar**: F5 → C hasta "Cockpit" → girar con A/D y ver el volante girar; acelerar y mirar LEDs y pantalla; dar dos vueltas y ver el delta en verde o rojo al pasar cada sector.

### Paso 7 — Manos y brazos del piloto
- Nuevo nodo `DriverArms` en `car.tscn` (`scripts/car/driver_arms.gd`), visible sólo en la cámara Cockpit.
- **Manos**: guante, pulgar e índice armados con cajas, colgados del aro del volante (`SteeringWheel.get_rim()`), así giran con él sin código extra. `SteeringWheel` ahora expone `get_grip_position(side)` y `get_paddle(side)`.
- **Brazos**: dos tramos (brazo 0,30 m y antebrazo 0,28 m) desde un hombro fijo en el chasis hasta la muñeca. El codo se calcula cada frame con **cinemática inversa de dos huesos** (ley de cosenos), doblando hacia afuera y abajo. Los tramos están en el grupo `team_paint`, así el buzo toma el color del equipo.
- **Levas**: al recibir `gear_changed` se compara con la marcha anterior; si subió, el índice derecho tira de la leva derecha, si bajó, el izquierdo de la izquierda (`Tween` de 0,05 s ida y 0,1 s vuelta).
- `DriverArms` corre con `process_priority = 10`, después de que el volante actualiza su giro, para que los brazos no queden un frame atrasados.
- Se corrigió el número del piloto en el HUD (se veía "#43.0" porque el JSON lo trae como float).
- **Verificación**: prueba sin ventana (cámara Cockpit, subir y bajar marcha, posición de los brazos) y captura en `informes/capturas/paso7-cockpit.png`.
- **Cómo probar**: F5 → C hasta "Cockpit" → girar con A/D (las manos y brazos siguen al volante) → E y Q (se mueven la leva y el dedo de cada lado).

### Paso 8 — Cockpit detallado
- Nuevo nodo `CockpitDetail` en `car.tscn` (`scripts/car/cockpit_detail.gd`), armado por código con formas simples. `CarController._apply_camera_mode()` le avisa con `set_cockpit_view()`.
- **Halo**: aro alrededor de la cabeza (12 tramos sobre una elipse que baja un poco hacia atrás), pilar central hasta el chasis delante del volante y dos patas traseras. Es parte del auto, así que se ve en todas las cámaras; en Cockpit queda arriba con el pilar en el centro, como en una cámara onboard.
- **Espejos retrovisores** a cada lado: carcasa, brazo al chasis y vidrio con imagen real. Cada espejo tiene un `SubViewport` con su `Camera3D` que mira hacia atrás y un poco hacia afuera; la cámara copia cada frame la posición de un marcador del auto. La textura se espeja con `uv1_scale = (-1, 1, 1)`. Sólo se renderizan en Cockpit (`UPDATE_ALWAYS`); en las otras cámaras quedan apagados y el vidrio usa un material metálico oscuro.
- **Casco**: visera arriba y mentonera abajo como franjas curvas (`SurfaceTool`) colgadas de la cámara a 0,12 m, con un borde de goma más claro y un tinte suave del visor. Están en la capa visual 2, que las cámaras de los espejos no ven, y no proyectan sombra.
- **Vibración de cámara** en `CarController._update_shake()`: desplazamiento y rolido con ruido (`FastNoiseLite`) que crecen con el cuadrado de la velocidad, más **golpes** que se desvanecen solos: contra muros (según la velocidad perdida) y al cambiar de marcha. `add_camera_impact(intensidad)` queda público para los pianos del Paso 19. Las cámaras exteriores reciben el 25 %.
- **Datos** en `data/car.json` → `"cockpit"`: resolución y fov de los espejos, tinte del visor y parámetros de vibración (`"shake"`).
- **Verificación**: prueba con script (cámara Cockpit, acelerar, cambiar de marcha, volver a TV) y capturas en `informes/capturas/paso8-cockpit.png`, `paso8-espejo-izq.png` y `paso8-tv.png`.
- **Cómo probar**: F5 → C hasta "Cockpit" → mirar el halo arriba y los espejos a los costados (acelerar y ver la pista alejarse en ellos) → a alta velocidad la cámara vibra más; al cambiar con E se siente un golpe; chocar un muro sacude fuerte → C a la cámara TV y ver el halo sobre el auto.

### Paso 9 — Sonido de motor
- Nuevo nodo `EngineAudio` en `car.tscn` (`scripts/car/engine_audio.gd`). No usa archivos de audio: sintetiza cada muestra en GDScript y la empuja a un `AudioStreamGenerator` (22.050 Hz, buffer de 0,08 s) que reproduce un `AudioStreamPlayer`.
- **Frecuencia**: un V6 de 4 tiempos hace 3 explosiones por vuelta, así que el tono base es `rpm / 60 × 3` (200 Hz en ralentí, 625 Hz en el limitador). RPM y acelerador se interpolan dentro de cada bloque para que el tono no salte.
- **Capas**: tono (armónicas 1ª, 2ª y una 3ª que crece con el acelerador), combustión (ruido en pulsos justo después de cada explosión, más fuerte con carga), mecánica (media orden que suena siempre), silbido de turbo (acelerador × RPM, con retardo de soplado). Al final una saturación suave `x / (1 + |x|)` que nunca pasa de ±1.
- **Limitador y cambios**: mientras el motor corta potencia (`CarEngine.is_cutting()` o `Gearbox.is_shifting()`) se apagan las explosiones en 4 ms, así el limitador suena entrecortado y cada cambio tiene su corte sin sonidos aparte. Además, cada `gear_changed` agrega un golpe corto de ruido.
- **Petardeo**: al soltar el acelerador por encima del 55 % del rango de RPM se programan de 3 a 6 estallidos graves (ruido filtrado) separados entre 40 y 140 ms; se cancelan si se vuelve a acelerar.
- **Volumen**: −6 dB en Cockpit y 4 dB menos en las cámaras exteriores (`CarController.is_cockpit_view()`).
- **Datos** en `data/car.json` → `"audio"`: volumen, frecuencia de muestreo, buffer, explosiones por vuelta y la intensidad de cada capa.
- **Verificación**: prueba sin ventana que maneja (acelerar hasta el limitador, tres cambios, soltar, volver a acelerar) y graba el sonido en `informes/audio/paso9-motor.wav`. La síntesis tarda 0,37 ms por frame en promedio, pico 0,55, sin valores inválidos. Con audio real no hay cortes durante el juego (sólo algunos al cargar la escena).
- **Cómo probar**: F5 → escuchar el ralentí → W a fondo en 1ª hasta el limitador (suena entrecortado) → E para subir (corte y golpe) → soltar W alto de vueltas (petardeo) → C a la cámara TV (baja el volumen).

### Paso 10 — Neumáticos, viento y muros
- Nuevo nodo `CarAudioFx` en `car.tscn` (`scripts/car/car_audio_fx.gd`), con su propio `AudioStreamGenerator`; mismo esquema que `EngineAudio` (síntesis por bloques, interpolación dentro del bloque, saturación suave, `synthesize(frames)` público).
- **Chirrido de neumáticos**: ruido por un filtro pasabanda angosto de variables de estado (Q = 14, casi un tono) entre 950 y 1.400 Hz, con vibrato de 6 Hz. La cantidad sale del ángulo de derrape (`get_slip_angle_deg()`: empieza a 3°, pleno a 12°), escalada por la velocidad para que no chirríe casi parado, y del **freno de mano** a velocidad.
- **Viento**: ruido por dos pasabajos en serie; volumen con el cuadrado de la velocidad y el filtro se abre (más agudo) cuanto más rápido.
- **Muros**: `CarController` emite la señal nueva `wall_hit(strength)` en el mismo punto donde sacude la cámara. Cada golpe suena como un tono grave que cae de 90 a 45 Hz más un crujido de ruido, con 0,15 s de espera entre golpes (salvo que llegue uno más fuerte). Mientras el auto se arrastra contra el muro (`is_touching_wall()`) suena un **roce** continuo según la velocidad.
- `CarController` expone además `is_handbrake_on()`.
- **Volumen**: −8 dB en Cockpit y 3 dB menos en las cámaras exteriores.
- **Datos** en `data/car.json` → `"audio_fx"`.
- **Verificación**: prueba sin ventana que acelera a 110 km/h, dobla a fondo con freno de mano (derrape de 36°, chirrido a pleno) y termina contra el muro (golpes y roce). Grabaciones en `informes/audio/paso10-efectos.wav` (sólo efectos) y `paso10-motor-y-efectos.wav` (mezcla). 0,2 ms de síntesis por frame, sin valores inválidos. Con audio real no hay cortes durante el juego.
- **Cómo probar**: F5 → acelerar en la recta (el viento sube) → doblar a fondo con Espacio (chirrido) → chocar un muro de frente (golpe) y arrastrarse contra él (roce).

### Paso 11 — Menú principal
- **Escena de arranque** nueva: `scenes/menu.tscn` (`run/main_scene` en `project.godot`), script `scripts/menu/main_menu.gd`. `main.tscn` queda como la carrera.
- **Fondo 3D**: estudio oscuro con piso, plataforma giratoria (`Turntable`) y el **auto real** (`car.tscn`) encima, pintado con el color del equipo del piloto por defecto. Aro luminoso y luz de contorno con ese mismo color. Cámara fija con `h_offset` para dejar el auto a la derecha y los botones a la izquierda.
- **Modo exhibición** del auto: `CarController.set_showcase(true)` apaga física, controles, sonidos (`set_muted()` en `EngineAudio` y `CarAudioFx`) y su cámara. Se va a reusar en la selección de piloto (Paso 12).
- **Interfaz** armada por código como el HUD: título, subtítulo, botones **Jugar** y **Salir** con borde del color del equipo al enfocar, tarjeta del piloto abajo a la derecha y créditos. Se maneja con teclado (foco inicial en Jugar, flechas, Enter) o mouse. Esc sale del juego.
- **Música** generada por código (`scripts/audio/menu_music.gd`, `MenuMusic`): loop de 4/4 a 112 BPM sobre La menor – Fa – Do – Sol, dividido en semicorcheas. Bombo en cada negra, caja en 2 y 4, hi-hat a contratiempo, bajo diente de sierra filtrado en corcheas, arpegio de onda cuadrada suave y colchón de acordes. Entra con un fundido de 2,5 s.
- **Flujo**: Jugar → `change_scene_to_file("res://scenes/main.tscn")`; en la pista **Esc vuelve al menú** (antes cerraba el juego). La pausa completa queda para el Paso 15.
- **Datos**: nuevo `data/menu.json` (velocidad de la plataforma, cámara y música). La lectura de JSON y la búsqueda de piloto se movieron a `scripts/data_loader.gd` (`DataLoader`), que usan el menú y `main.gd`.
- **Verificación**: prueba que abre el menú (cámara del menú activa, auto sin física ni sonido, música sonando, foco en Jugar), aprieta Jugar (carga la pista con el auto manejable y su cámara), manda Esc y vuelve al menú. Captura en `informes/capturas/paso11-menu.png` y música en `informes/audio/paso11-musica.wav` (0,39 ms de síntesis por frame).
- **Cómo probar**: F5 → ver el auto girando y escuchar la música → Enter en Jugar → manejar → Esc para volver al menú → Salir.

### Paso 12 — Selección de escudería y piloto
- **Flujo**: Jugar → *Elegí escudería* → *Elegí piloto* → carrera. Esc vuelve una etapa (piloto → escudería → menú). Todo dentro de `menu.tscn`, reusando la plataforma con el auto.
- Nuevo `scripts/menu/driver_select.gd` (`DriverSelect`), armado por código desde `grid_2026.json`:
  - **Escuderías**: 11 tarjetas en 2 columnas con el color del equipo en el borde y los apellidos de sus pilotos.
  - **Pilotos**: tarjeta por piloto con el número grande en el color del equipo, nombre, **bandera** y país.
  - Señales `preview_changed(team, driver)`, `confirmed(driver_id)` y `cancelled`; el foco inicial cae en el equipo/piloto elegido antes.
- **Vista previa**: al recorrer las tarjetas, el auto, el aro, la luz de contorno, las franjas y los botones toman el color del equipo, y la tarjeta de abajo a la derecha muestra el equipo o el piloto con foco.
- **Banderas** dibujadas por código (`scripts/ui/flag_icon.gd`, `FlagIcon`) desde `data/flags.json`: franjas horizontales o verticales con pesos y figuras encima (círculo, cruz, aspa, rombo, rectángulo) dentro de una región; así se arman las 15 banderas de la grilla, incluidas las de Reino Unido, Australia y Nueva Zelanda (cantón con la Union Jack). Son simplificadas: sin escudos ni hoja de arce detallada.
- **Autoload `GameState`** (`scripts/game_state.gd`) con `selected_driver_id`; `main.gd` lo usa (si está vacío, `default_driver_id`), así el HUD y el color del auto en la pista salen del piloto elegido. Al volver al menú queda recordado.
- Ayudantes de interfaz compartidos en `scripts/ui/ui_kit.gd` (`UiKit`): etiquetas, anclas, botones con borde de color y estilos.
- **Verificación**: prueba que entra a la selección, enfoca Ferrari (auto y aro en `#E8002D`), abre los pilotos, vuelve con Esc, elige Hamilton y confirma que la pista muestra "#44 Lewis Hamilton / Ferrari"; al volver al menú sigue elegido y Esc desde escuderías vuelve al menú. Capturas: `informes/capturas/paso12-escuderias.png`, `paso12-pilotos.png` y `paso12-banderas.png` (las 15 banderas).
- **Cómo probar**: F5 → Jugar → recorrer escuderías con flechas (el auto cambia de color) → Enter → elegir piloto → Enter → manejar con ese equipo → Esc → el menú recuerda la elección.

### Paso 13 — Livery y número
- Cada equipo de `grid_2026.json` tiene ahora `"secondary_color"` (aproximado a sus decoraciones, no oficial). `DataLoader.team_primary()` / `team_secondary()` los leen; si falta el secundario se usa el principal oscurecido.
- Nuevo nodo `Livery` en `car.tscn` (`scripts/car/car_livery.gd`, `CarLivery`):
  - **Principal** en el grupo `team_paint` (carrocería, morro, pontones, airbox y buzo del piloto).
  - **Secundario** en el grupo nuevo `team_paint_secondary`: alerón delantero y trasero, y cuatro **franjas** que arma el nodo (sobre el morro, sobre la carrocería delante del cockpit y a los costados de los pontones).
  - **Número** con `Label3D` (sin fuentes extra) acostado sobre el morro y arriba de la cubierta del motor, y parado a los dos costados de la cubierta. Color: el secundario si contrasta lo suficiente con el principal (diferencia de luminancia ≥ 0,35); si no, blanco o negro según el principal, con contorno opuesto.
- `CarController.set_team_color(color)` se reemplazó por **`set_livery(principal, secundario, número)`**. La carrera lo llama con el piloto elegido; el menú, en la vista previa (sin número mientras se elige escudería).
- **Verificación**: prueba con capturas del menú (Alpine rosa con alerones y franjas azules, #43 en negro), de la vista previa de Haas (números ocultos) y de la carrera con Verstappen (Red Bull azul con alerones rojos, #1 en blanco) en cámara cercana y cockpit: `informes/capturas/paso13-menu.png`, `paso13-carrera.png`, `paso13-cockpit.png`. El número del morro no se ve desde el cockpit (lo tapa la carrocería) y el de la cubierta se ve mejor desde la cámara TV, que está más alta.
- **Cómo probar**: F5 → mirar el auto girando (franjas, alerones y número) → Jugar y recorrer escuderías (cambian los dos colores) → elegir piloto (aparece su número) → en la pista, C para ver el auto desde atrás.

### Paso 14 — Opciones
- **Autoload `Settings`** (`scripts/settings.gd`): valores por defecto, perfiles de dirección y de calidad en `data/settings.json`; lo que elige el jugador se guarda en **`user://settings.json`** apenas cambia (en Windows: `%APPDATA%\Godot\app_userdata\GodotF126\settings.json`). Los valores leídos se sanean (opciones desconocidas o volúmenes fuera de 0–100 vuelven al valor por defecto). Señal `changed(key)`.
- **Opciones**:
  - **Caja de cambios** inicial: manual o automática (M en la pista sigue alternando).
  - **Dirección asistida**: sí = respuesta suave y menos giro a alta velocidad; no = dirección directa (más rápida y con más giro a fondo). Es la primera ayuda; el resto llega en la Fase D.
  - **Cámara inicial**: TV, cercana o cockpit.
  - **Volúmenes** general, motor, efectos y música, en buses de audio `Engine`, `Fx` y `Music` creados por código con `AudioServer` (el motor, los efectos y la música del menú usan cada uno su bus).
  - **Calidad gráfica**: baja (sin sombras, espejos a media resolución), media (sombras) y alta (sombras, MSAA 4× y espejos a 1,5×).
  - **Pantalla completa**.
- **Panel "Opciones"** en el menú (`scripts/menu/options_panel.gd`, `OptionsPanel`), entre Jugar y Salir: filas con ‹ › que se cambian con ←/→ o Enter, deslizadores para los volúmenes, Restablecer y Volver (o Esc). Toma el color del equipo elegido y se aplica en vivo (las sombras y la música del menú cambian al instante).
- **En la carrera** `main.gd` llama a `Settings.apply_to_car(car)` (caja, dirección, cámara y tamaño de los espejos) y apaga las sombras del sol en calidad baja.
- **Verificación**: prueba que abre Opciones, pasa a caja automática, cámara cockpit, calidad baja y música al 30 %; comprueba el bus `Music` en −10,5 dB, las sombras apagadas, el archivo `user://settings.json` escrito y releído, que Esc vuelve con el foco en "Opciones", y que en la pista el auto arranca en automática, en cockpit, sin sombras y con espejos de 160×60; también que la dirección directa cambia la respuesta de 8 a 14. Al final restaura el archivo del jugador. Captura: `informes/capturas/paso14-opciones.png`.
- **Cómo probar**: F5 → Opciones → cambiar la cámara a Cockpit y la caja a Automática → Volver → Jugar → la carrera arranca así; cerrar y volver a abrir el juego: las opciones siguen guardadas.

### Paso 15 — Pausa
- **Esc en la pista ya no vuelve directo al menú**: abre el menú de pausa (`scripts/ui/pause_menu.gd`, `PauseMenu`, nodo `PauseMenu` en `main.tscn`). Es un `CanvasLayer` con `process_mode = ALWAYS` que pone `get_tree().paused = true`: la física del auto, el cronómetro y las cámaras quedan congelados.
- **Audio**: el motor y los efectos se silencian (`set_muted`) mientras dura la pausa y retoman al continuar.
- **Pantalla**: fondo oscurecido, el HUD de carrera se oculta, título "Pausa" con piloto, pista y vuelta en curso (y mejor vuelta si hay) y botones con el color del equipo:
  - **Continuar** (o Esc otra vez).
  - **Reiniciar**: recarga la carrera desde la largada (los récords guardados se mantienen).
  - **Opciones**: el mismo panel del menú (Paso 14). Los cambios se aplican en vivo al auto y al sol, pero **sin cambiar la cámara actual** (`Settings.apply_to_car(car, false)`); "Cámara inicial" vale para la próxima carrera. Esc vuelve a la pausa.
  - **Menú principal** y **Salir del juego**. Siempre se despausa antes de cambiar de escena.
- **Verificación**: prueba que acelera hasta 60 km/h, aprieta Esc y comprueba pausa activa, foco en "Continuar", audio pausado y que el auto no se mueve; abre Opciones, pasa a calidad baja y caja automática (sombras apagadas, caja automática, cámara cercana conservada); Esc vuelve con el foco en "Opciones", Esc otra vez continúa (audio y movimiento vuelven); Reiniciar crea una carrera nueva quieta en la largada y Menú vuelve a `menu.tscn` sin pausa. Capturas: `informes/capturas/paso15-pausa.png`, `paso15-opciones.png`.
- **Cómo probar**: F5 → Jugar → elegir piloto → acelerar → Esc (todo se congela y se calla) → Opciones → Esc → Continuar; probar Reiniciar y Menú principal.
