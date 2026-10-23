# GodotF126 — ROADMAP (versión pro)

Desarrollo iterativo e incremental: **un paso por vez**, y cada paso termina con algo jugable que se prueba abriendo Godot 4.7 y apretando F5.

Los pasos están agrupados en **fases**. El orden prioriza primero lo que más cambia la sensación de manejar un F1 (motor, caja manual, tablero, cockpit), después la física de simulador y recién después el contenido (modos, rivales, más pistas).

## Hitos

| Hito | Se alcanza al terminar | Qué se puede mostrar |
|---|---|---|
| **H1 — Demo de cursada** ✅ | Paso 24 | Elegir escudería/piloto, caja manual, cockpit con volante y manos, sonido, vuelta cronometrada, resultado |
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

## Fase C — Menús y flujo de juego (cierra H1) ✅

| Paso | Contenido | Estado |
|---|---|---|
| 11 | Menú principal con fondo 3D del auto girando y música | ✅ |
| 12 | **Selección de escudería → piloto** con tarjetas (color del equipo, número, bandera) desde `grid_2026.json` | ✅ |
| 13 | Livery de dos colores por equipo y número del piloto en el auto | ✅ |
| 14 | Opciones: caja manual / automática, ayudas, cámara por defecto, volumen, calidad gráfica; guardado en `user://settings.json` | ✅ |
| 15 | Pausa con Esc (Continuar / Reiniciar / Menú / Salir) | ✅ |
| 16 | Modo **Contrarreloj**: N vueltas y después pantalla de resultado con tiempos por vuelta y sectores | ✅ |
| 17 | **Semáforo de largada** con 5 luces y detección de salto | ✅ |
| 18 | Cámaras extra: T-cam sobre el airbox, cámara de capot, cámaras de TV fijas en la pista | ✅ |
| 19 | Pianos y zonas de escape; **límites de pista** con vuelta invalidada al salirse | ✅ |
| 20 | Carteles de frenado 150 / 100 / 50 m antes de cada curva | ✅ |
| 21 | Bakú mejorado: trazado más parecido (aproximado, sin datos oficiales FIA), **sector del castillo estrecho**, elevación suave | ✅ |
| 22 | Ciudad: tribunas, edificios, barreras con publicidad, LOD para rendimiento | ✅ |
| 23 | Iluminación de atardecer, sombras, reflejos en el mar | ✅ |
| 24 | Pulido de H1: tutorial de controles, pantalla de carga, prueba en PC del laboratorio | ✅ |

## Fase D — Física de simulador (H2)

| Paso | Contenido | Estado |
|---|---|---|
| 25 | Modelo por **4 ruedas**: suspensión por raycast (resorte + amortiguador) en lugar del arcade | ⏳ Siguiente |
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

### Paso 16 — Contrarreloj
- **Modos** en `data/modes.json`: *Práctica libre* (vueltas sin límite, lo de antes) y *Contrarreloj* con `lap_options` (1, 2, 3, 5, 10) y `default_laps` (3). También `default_mode` y `results_delay` (segundos entre la bandera a cuadros y el resultado).
- **Menú**: Jugar → **Elegí modo** → escudería → piloto. Nuevo `scripts/menu/mode_select.gd` (`ModeSelect`): una tarjeta por modo; en Contrarreloj ←/→ cambian las vueltas (`‹ 3 vueltas ›`). Enter confirma, Esc vuelve al menú; Esc desde las escuderías vuelve a los modos. El modo y las vueltas se guardan en `GameState` (`selected_mode`, `lap_count`) y quedan recordados.
- **`LapTimer`**: `lap_limit` (0 = sin límite), historial `lap_history` (vuelta, tiempo, sectores y si fue récord), `total_time()`, `beat_record()` y señal `session_finished`. Al cerrar la última vuelta el cronómetro se detiene (`finished`) y ya no arranca otra al cruzar la línea. Reiniciar el auto con R sigue anulando sólo la vuelta en curso.
- **En la carrera**: el HUD muestra "VUELTA 2 / 3", avisa "¡ÚLTIMA VUELTA!" y "¡BANDERA A CUADROS!", y debajo de la pista el modo. Al terminar se sueltan los controles (el auto sigue rodando y frena solo), se bloquea la pausa y a los 2,5 s se abre el resultado.
- **Pantalla de resultado** (`scripts/ui/results_screen.gd`, `ResultsScreen`, nodo en `main.tscn`, mismo estilo que `PauseMenu` y también `process_mode = ALWAYS`): pausa el juego, oculta el HUD y calla el auto. Tabla con vuelta, S1, S2, S3 y tiempo; la **mejor vuelta y el mejor tiempo de cada sector de la sesión en violeta**. Abajo: tiempo total, mejor vuelta y récord de la pista (con "¡NUEVO RÉCORD!" en amarillo si se batió en la sesión). Botones **Repetir** (recarga la carrera con el mismo modo) y **Menú principal** (también Esc).
- **Verificación**: prueba que abre los modos (foco en Contrarreloj), cambia las vueltas 3 → 5 → 3 → 2, confirma (GameState en `time_trial` / 2), Esc desde escuderías vuelve a los modos, elige Hamilton; en la pista simula los checkpoints de dos vueltas y comprueba `lap_limit = 2`, sesión terminada con 2 vueltas en el historial, controles sueltos, que la línea no arranca otra vuelta, resultado abierto con el juego pausado, HUD oculto y foco en Repetir; Repetir crea una carrera nueva sin pausa e historial vacío; en práctica libre `lap_limit = 0`. Restaura `user://records.json` al final. Capturas: `informes/capturas/paso16-modos.png`, `paso16-resultado.png`.
- **Cómo probar**: F5 → Jugar → Contrarreloj con ← → elegir 1 o 2 vueltas → Enter → elegir piloto → cruzar la línea y completar las vueltas → ver el resultado → Repetir o Menú principal.

### Paso 17 — Semáforo de largada
- **Largada detenida en Contrarreloj** (`"standing_start": true` en `data/modes.json`; Práctica libre sigue con largada lanzada). El auto aparece en la grilla, 6 m detrás de la línea (`BakuTrack.get_grid_transform(distancia)`), y R lo devuelve ahí.
- Nuevo `scripts/race/start_lights.gd` (`StartLights`, nodo en `main.tscn`): espera 1,5 s, enciende las **5 columnas de luces rojas de a una por segundo** y, tras una espera al azar de 0,2 a 3 s, las apaga todas juntas. Avanza en `_process`, así que se congela con la pausa. Señales `lights_changed(count)`, `lights_out`, `jump_start`, `reaction_measured(seconds)`, `finished`.
- **Luces 3D**: panel negro con 2 filas × 5 lámparas emisivas colgado del travesaño del pórtico (`BakuTrack.GANTRY_HEIGHT`), mirando hacia la grilla. **Luces en el HUD** (`scripts/ui/start_lights_display.gd`, `StartLightsDisplay`, dibujado en `_draw()`) al centro de la pantalla, con un texto de ayuda; desaparecen 2 s después de la largada. El cronómetro muestra "LARGADA DETENIDA".
- **Cronómetro**: mientras el semáforo está activo se ignoran los checkpoints. Al apagarse las luces `LapTimer.start_now()` arranca la vuelta 1 (con el auto todavía detrás de la línea, como en una carrera real) y el primer cruce de la meta no la reinicia.
- **Salto**: el auto arranca en 1ª, así que acelerar antes de tiempo lo mueve (en manual se puede pasar a N con Q y acelerar quieto). Si avanza más de 0,3 m antes del apagado aparece "¡LARGADA EN FALSO!" y al apagarse las luces se suman **+5 s** al total (`LapTimer.add_penalty()`; `total_time()` ya los incluye). La vuelta y el récord no se tocan.
- **Reacción**: sin salto, se mide el tiempo desde el apagado hasta que el auto pasa 0,5 m/s y se muestra ("Reacción 0,246 s").
- **Resultado**: muestra la penalización en rojo con el motivo o, si no hubo, el tiempo de reacción.
- **Datos** en `data/modes.json` → `"start_lights"`: distancia de grilla, espera inicial, intervalo entre luces, espera al azar mínima y máxima, distancia de salto, penalización, velocidad de reacción y tiempo en pantalla.
- **Verificación**: prueba que arranca un contrarreloj de 1 vuelta y comprueba el auto a 6,00 m de la línea, la secuencia 1 → 5 luces con el cronómetro quieto, que un checkpoint antes del apagado se ignora, que al apagarse arranca la vuelta 1 sin salto, la reacción medida (0,246 s) y que el primer cruce de meta no reinicia la vuelta; en una segunda largada acelera con 2 luces encendidas y comprueba el salto, +5 s con motivo "Largada en falso" y total = vueltas + 5; en práctica libre no hay semáforo. Restaura `user://records.json` al final. Capturas: `informes/capturas/paso17-semaforo.png`, `paso17-cockpit.png`, `paso17-resultado-reaccion.png`, `paso17-resultado-salto.png`.
- **Cómo probar**: F5 → Jugar → Contrarreloj → elegir piloto → esperar las 5 luces y acelerar cuando se apagan (ver la reacción) → Esc → Reiniciar y esta vez acelerar antes: "¡LARGADA EN FALSO!" y +5 s en el resultado.

### Paso 18 — Cámaras extra
- **C recorre 6 cámaras**: TV, cercana, cockpit, **T-cam**, **capot** y **cámaras de pista**. Los índices 0–2 no cambiaron, así que la "Cámara inicial" guardada sigue valiendo; en Opciones se agregaron T-cam, Capot y De pista.
- `CarController.CAMERA_MODES` pasó de `"smooth"` a `"view"`: `chase` (sigue el giro con retraso), `onboard` (pegada al auto), `cockpit` (pegada, con volante, brazos, espejos y visor) y `external`. Cada cámara pegada tiene su fracción de vibración (`"shake"`: cockpit 1, capot 0,8, T-cam 0,7).
  - **T-cam**: arriba del airbox, mirando adelante por encima del casco y el halo.
  - **Capot**: sobre el morro, delante del cockpit; se ven la franja y el alerón delantero.
  - Nuevos `is_onboard_view()` (cockpit, T-cam y capot: el motor y los efectos suenan "de adentro") y `uses_external_camera()`; señal `camera_mode_applied(external)`.
- **Cámaras de TV fijas** (`scripts/race/tv_cameras.gd`, `TvCameras`, nodo en `main.tscn`): 10 torres repartidas por el trazado desde la línea de largada, del **lado de afuera de cada curva**, a 11 m del centro y 7 m de alto, cada una con poste, plataforma y cámara (decorado). Una sola `Camera3D` **corta** a la torre más cercana a donde va a estar el auto en 0,8 s (con margen del 80 % y al menos 1,5 s por torre para que no salte), lo sigue con `look_at` suavizado y ajusta el **zoom** para que el auto ocupe siempre unos 18 m de ancho (fov entre 10° y 60°). Señal `camera_cut(index)`; se van a reusar en los replays (Paso 51).
- **Datos** en `data/tracks.json` → `"tv_cameras"` de cada pista: cantidad, distancia al costado, altura, encuadre, zoom mínimo y máximo, margen de corte, tiempo mínimo, anticipación y suavizado.
- **Arreglo en `Settings`**: un valor inválido en `user://settings.json` (p. ej. `"camera": null`) hacía fallar `_sanitize` y quedaba guardado; ahora cámara, volúmenes y opciones sí/no vuelven al valor por defecto.
- **Verificación**: prueba que recorre los 6 modos (cámara activa, volante y casco visibles sólo donde corresponde, sonido de adentro en cockpit/T-cam/capot, torres activas sólo en "Cámaras de pista"), maneja 10 s a fondo hasta 198 km/h con las cámaras de pista y registra los cortes a las torres 1, 2 y 3, vuelve con C a la cámara TV del auto y comprueba que "De pista" como cámara inicial arranca en la torre 0. Capturas: `informes/capturas/paso18-tcam.png`, `paso18-capot.png`, `paso18-pista.png`, `paso18-pista-2.png`.
- **Cómo probar**: F5 → Jugar → elegir piloto → C varias veces (T-cam, capot, cámaras de pista) → en cámaras de pista acelerar por la recta y ver los cortes y el zoom.

### Paso 19 — Pianos, escapatorias y límites de pista
- **Curvas detectadas por curvatura**: `BakuTrack._compute_layout()` mide el giro del `centerline` en una ventana de ±8 m; por debajo de 120 m de radio es curva, con su sentido (`turn_sign`: +1 izquierda, −1 derecha). Parámetros en `data/tracks.json` → `"layout"`.
- **Pianos** rojos y blancos (franjas de 2 m, 1,2 m de ancho, 5 cm de alto, sólo visuales) a los dos lados en cada curva, empezando 10 m antes y terminando 10 m después (`kerb_mask`). Cubren el 45 % del trazado de Bakú, que es casi todo curvas.
- **Escapatorias**: la franja entre la línea blanca y el muro (gris azulado) mide 1,6 m en las rectas y se abre **9 m más del lado de afuera de cada curva**, con una rampa de 25 m para que el muro no tenga escalones. Los muros, los checkpoints (ahora de muro a muro), el pórtico, los carteles de sector y las torres de TV (`wall_clearance` = 4 m detrás del muro) usan esas distancias (`wall_left`, `wall_right`, `wall_offset(i, lado)`). La prueba comprueba que ningún muro cae sobre otra parte del trazado.
- **Límites de pista** (`scripts/race/track_limits.gd`, `TrackLimits`, nodo en `main.tscn`): cada frame de física ubica al auto (`BakuTrack.locate()`: índice más cercano, buscando cerca del anterior, y desplazamiento lateral). Si **las cuatro ruedas pasan la línea blanca** del mismo lado (`|lateral| − 1,0 m > 6 m`), invalida la vuelta: `LapTimer.invalidate_lap("Límites de pista")`.
- **Vuelta inválida** (`LapTimer.current_invalid`, señal `lap_invalidated`): se sigue cronometrando y cuenta para el total y para las vueltas del contrarreloj, pero **no para mejor vuelta, mejores sectores ni récord** (los mejores sectores que hubiera marcado se deshacen). En el historial queda `"invalid": true`.
  - HUD: "VUELTA INVALIDADA · límites de pista" en rojo, "VUELTA 2 · INVALIDADA" y el tiempo en gris; al cerrarla, "NO VÁLIDA".
  - Resultado: la fila en gris con `*` y una nota abajo; la mejor vuelta y los sectores en violeta salen sólo de las vueltas válidas.
- **Al pisar un piano**: vibración de cámara (`add_camera_impact(0,18)` mientras dura) y **retumbe** en `CarAudioFx`, una onda triangular con la frecuencia de las estrías (velocidad / 0,3 m) más ruido sordo. `CarController.kerb_contact` (0–1) lo escribe `TrackLimits`.
- **Verificación**: prueba que mide el trazado (1.184 puntos, muros de 7,6 a 16,6 m del centro, 0 muros sobre otra parte de la pista), saca una captura cenital de la curva con más escapatoria, comprueba que con dos ruedas afuera la vuelta sigue válida y con cuatro se invalida, que esa vuelta no marca mejor vuelta, sectores ni récord y la siguiente sí, que sobre un piano `kerb_contact` = 1 con retumbe (pico 0,36, sin valores inválidos) y en el centro de la pista 0. Restaura `user://records.json` al final. Capturas: `informes/capturas/paso19-curva-arriba.png`, `paso19-invalidada.png`, `paso19-piano.png`.
- **Cómo probar**: F5 → Jugar → elegir piloto → en una curva subirse al piano (se siente y se oye) → cortar una curva con las cuatro ruedas por la escapatoria: aviso rojo y vuelta en gris → en Contrarreloj, ver la vuelta con `*` en el resultado.

### Paso 20 — Carteles de frenado
- **Inicio de cada curva**: `BakuTrack._find_corner_starts()` toma los puntos donde `corner_mask` (curvatura por encima del umbral del Paso 19) pasa de 0 a 1 y la curva dura al menos 8 m (`corner_starts`). En Bakú son 12.
- **Carteles** (`_build_brake_boards()`): desde cada inicio se recorre el `centerline` hacia atrás sumando distancia y se pone un cartel a 150, 100 y 50 m: poste gris, panel blanco y el número en negro (`Label3D`), mirando al auto que llega, **del lado de afuera de la curva** y 0,9 m detrás del muro (`wall_offset` + espesor). Quedan en el nodo `BrakeBoards` y en `brake_boards` (`index`, `distance`, `corner`).
- **Curvas seguidas**: si antes de llegar a la distancia aparece otra curva, ese cartel no se pone (tiene que quedar al menos 8 m después del final de la curva anterior). Por eso en la parte sinuosa (rectas de menos de 50 m entre curvas) no hay carteles, y Bakú queda con 8: tres antes de la curva al final de la recta larga, tres antes de la del índice 900 y 100 / 50 m antes de la del 991.
- **Datos** en `data/tracks.json` → `"brake_boards"`: distancias, separación mínima, largo mínimo de curva, distancia al muro y medidas del cartel.
- **Verificación**: prueba que cuenta curvas y carteles, mide sobre el trazado la distancia de cada cartel a su curva (error máximo 1,2 m, el espaciado del `centerline`), comprueba que los 8 quedan del lado de afuera, detrás del muro y a más de 2 m de las torres de TV, y saca capturas llegando a la curva con los tres carteles. Capturas: `informes/capturas/paso20-carteles.png` (cámara TV, cartel de 150), `paso20-cockpit.png` (cartel de 100).
- **Cómo probar**: F5 → Jugar → elegir piloto → recorrer la recta larga: a la derecha, antes de la curva a la izquierda, aparecen 150, 100 y 50.

### Paso 21 — Bakú mejorado
- **Trazado aproximado** (sigue siendo un placeholder, **no** el layout oficial FIA), a escala reducida: **2,57 km** contra los 6 km reales. Recta larga junto al mar con curvas suaves a fondo, curva 1 a la izquierda, ángulos rectos de la ciudad (curvas 2 a 6), subida hacia el castillo, **sector del castillo** estrecho y sinuoso alrededor de la ciudad vieja, bajada con curvas de 90° y la curva 16 que vuelve a la costa. 15 curvas detectadas.
- **Datos**: los puntos de control pasaron de una constante en el script a `data/tracks.json` → `"centerline"`. Cada punto es `[x, z, ancho, altura, escapatoria 0–1, radio de la esquina]`; también la línea de largada (`start`), el spawn, el paso entre puntos (1,4 m) y el suavizado de altura y ancho (20 m).
- **Esquinas con radio**: `BakuTrack._round_corners()` cambia cada vértice por un arco tangente de su radio (12 m en el castillo, 16–20 m en la ciudad, 400 m en las curvas a fondo de la costa). Reemplaza al suavizado Chaikin anterior, que dejaba radios de 6–8 m: menores que la distancia al muro de adentro, así que el muro se doblaba sobre la pista y frenaba al auto con una pared invisible.
- **Ancho variable**: `widths[i]` y `half_width(i)`; el castillo mide **7,6 m** (12 m en el resto) y no tiene escapatoria (`runoff_scale` = 0). El asfalto, las líneas, los pianos, la escapatoria, los muros y `TrackLimits` usan el ancho de cada punto.
- **Elevación suave**: el `centerline` tiene altura; sube de 0 a **12 m** en el castillo y baja hasta la costa (pendiente máxima 3,9 %). Piso nuevo con colisión de muro a muro (`Road`, `ConcavePolygonShape3D`) que sigue la altura; donde la pista va en alto, los muros tienen un **murallón de piedra** hasta el suelo. `locate()` y `_nearest_index()` miden en planta; la curvatura y la orientación de carteles y marcadores usan `_flat_tangent()`.
- **Escenografía** reubicada para el trazado nuevo: bloques de ciudad en el interior, la ciudad vieja (murallas) dentro de la vuelta del castillo y las Flame Towers en la colina al oeste. 14 torres de TV (antes 10).
- **Récord nuevo**: los tiempos de la pista vieja no son comparables, así que el récord se guarda con la clave `records_key` = `"baku_v2"` (el viejo queda en `"baku"` sin usarse).
- **Verificación**: prueba que mide el trazado (1.832 puntos, ancho 7,6–12 m, altura 0–12 m), comprueba que no hay muros sobre otra parte de la pista ni muros interiores doblados (radio mínimo 12 m), que los edificios quedan a más de 10 m de los muros y que un rayo en el punto más alto pega en el asfalto a 12 m. Después un **piloto automático** (sigue el centerline y frena según la curva que viene) da 2 vueltas completas y válidas: 1:42.2 y 1:41.1, 195 km/h de máxima, 29 km/h en el castillo, el auto sube a 12 m siempre apoyado en el piso, sin salidas de pista ni reinicios. La prueba del Paso 20 sobre el trazado nuevo: 20 carteles en 9 curvas, todos bien ubicados. Capturas: `informes/capturas/paso21-trazado.png` (cenital), `paso21-subida.png`, `paso21-castillo.png`, `paso21-castillo-cockpit.png`.
- **Cómo probar**: F5 → Jugar → elegir piloto → dar una vuelta: después de los ángulos rectos, la subida y el castillo angosto entre muros; con la cámara "De pista" se ve el murallón de piedra.

### Paso 22 — Ciudad
- **`CityBuilder`** (`scripts/track/city_builder.gd`, nodo `City` dentro de la pista): arma la ciudad desde el `centerline` con datos de `data/tracks.json` → `"city"` (se apaga con `"enabled": false` o `BakuTrack.city_enabled`).
- **Edificios**: dos filas detrás de los muros cada ~30 m de los dos lados, orientadas con la pista, más una **grilla de manzanas** cada 45 m que rellena el interior y alrededor del circuito. Tamaño, alto (10–42 m) y color (piedra arenisca y algo de vidrio) al azar con semilla fija, así la ciudad es siempre la misma. Se descarta el edificio que queda a menos de 3 m del muro (14 m en la grilla) de cualquier parte de la pista, sobre el mar, sobre una tribuna, sobre la ciudad vieja, las Flame Towers u otro edificio; para medir rápido hay un índice espacial del `centerline` en celdas de 40 m. Cerca del castillo arrancan en el suelo y suman la altura de la pista. En Bakú quedan **389 edificios**. Reemplazan a los 5 bloques del Paso 21.
- **Tribunas** (3, en `"grandstands"` con tramo en metros desde la línea y lado): principal del lado del mar antes de la largada, otra del lado de la ciudad después y otra afuera de la curva 1. 10 escalones azules y blancos que siguen la forma del muro (y la escapatoria), pared trasera hasta el suelo, techo en voladizo y columnas. Las **torres de TV** las esquivan: `TvCameras.setup()` recibe `BakuTrack.is_grandstand` y si el lado está ocupado pone la torre del otro lado.
- **Publicidad**: **267 paneles** de 10 m en la cara interna de los muros, sólo donde el muro corre paralelo a la pista (sin piano ni escapatoria), con colores y textos genéricos (`"BAKU CITY CIRCUIT"`, `"F126 SIMULATOR"`, `"GODOT 4.7"`…; sin marcas reales). Un solo mesh para todos los paneles y un `Label3D` por panel.
- **LOD / rendimiento**: los edificios van en `MultiMeshInstance3D` agrupados en zonas de 160 m (40 zonas: una llamada de dibujo por zona en vez de una por edificio). Las cajas se ven hasta 1.600 m; las franjas de ventanas y los tanques de las terrazas sólo hasta 320 m, y los textos de publicidad hasta 220 m (`visibility_range_end`). Medido con ventana, sin vsync, 120 cuadros por vista:

| Vista | Sin ciudad | Ciudad sin LOD | Ciudad con LOD |
|---|---|---|---|
| Recta principal | 9,7 ms · 175 llamadas | 10,1 ms · 295 | 11,5 ms · 250 |
| Castillo | 8,5 ms · 241 | 9,9 ms · 308 | 10,6 ms · 304 |
| Cenital (todo el circuito) | 8,9 ms · 197 | 13,0 ms · 546 | 9,4 ms · 239 |

  A ras de pista casi todo queda dentro de la distancia de detalle, así que la ciudad cuesta 1–2 ms y el LOD no cambia mucho (las diferencias de ±1 ms son ruido de la medición); en las vistas largas el LOD corta las llamadas de dibujo a menos de la mitad. La escena carga en ~0,75 s con la ciudad (0,34 s sin).
- **Verificación**: prueba que cuenta edificios, zonas, tribunas y paneles; mide las 4 esquinas y los bordes de cada edificio con `locate()` (ninguno toca la pista; el más cercano queda a 3,7 m del muro); comprueba que ninguna torre de TV queda en una tribuna ni dentro de un edificio y ningún cartel de frenado dentro de un edificio; mide el rendimiento de la tabla. Se volvieron a correr la vuelta con piloto automático del Paso 21 (mismos tiempos, sin salidas) y la prueba de carteles del Paso 20 (20 carteles bien ubicados). Capturas: `informes/capturas/paso22-tribunas.png`, `paso22-publicidad.png`, `paso22-ciudad.png`, `paso22-arriba.png`.
- **Cómo probar**: F5 → Jugar → elegir piloto → en la recta, la tribuna del lado del mar y la publicidad en los muros; la ciudad alrededor de todo el circuito.

### Paso 23 — Iluminación
- **Presets de luz** en `data/lighting.json`: `"sunset"` (atardecer, por defecto) y `"day"`. Cada uno define sol (color, energía, elevación y rumbo), cielo procedural (colores de arriba, horizonte y suelo, tamaño del disco solar), luz ambiente, tonemap (ACES, exposición, blanco), niebla con dispersión del sol y perspectiva aérea, glow, colores y olas del mar y color del suelo. El rumbo es de brújula: 0 = −Z, 90 = +X, 180 = +Z (el mar). Al atardecer el sol queda a 11° sobre el horizonte, anaranjado, hacia el oeste-suroeste, y las sombras largas de los edificios cruzan la pista.
- **`LightingRig`** (`scripts/lighting_rig.gd`, estático): `get_preset(id)`, `sun_direction(rumbo, elevación)`, `apply(environment, sol, preset, calidad, mar, suelo)` y `apply_quality(...)`. `main.gd` lo aplica al cargar y cada vez que cambia una opción. Se fue la imagen **lavada** de los pasos anteriores (tonemap Filmic + ambiente fuerte → ACES con menos ambiente y suelo más oscuro).
- **Sombras según la calidad** (`data/settings.json`, perfiles): baja sin sombras; media a 250 m con 2 cortes (PSSM); alta a 400 m con 4 cortes.
- **Mar** con shader propio (`shaders/sea.gdshader`): plano liso, las olas son 5 ondas que se mueven y sólo cambian la normal. El reflejo del cielo y el camino de luz del sol salen del PBR de Godot (rugosidad baja). Cada onda se apaga cuando un píxel cubre más que su longitud y la rugosidad sube con la distancia (si no, desde arriba o de lejos aparecen rayas de moiré). Más claro cerca de la costa. Suelo y mar pasan a 8 km para que no se vea el borde en el horizonte. **Sin SSR**: el proyecto usa el renderer `gl_compatibility` (para las PC del laboratorio) y ahí los reflejos en pantalla no existen.
- **Opción nueva** "Hora de la carrera" (Atardecer / Día) en Opciones, en el menú y en la pausa; se guarda en `time_of_day`. Para que entre la fila nueva, las filas del panel quedan 2 px más juntas.
- **Rendimiento** al atardecer (con ventana, sin vsync, 120 cuadros por vista, misma sesión):

| Vista | Baja | Media | Alta |
|---|---|---|---|
| Recta principal | 4,9 ms · 164 llamadas | 5,2 ms · 318 | 9,7 ms · 499 |
| Castillo | 3,1 ms · 99 | 5,2 ms · 229 | 8,5 ms · 325 |
| Cenital | 3,9 ms · 239 | 5,2 ms · 239 | 9,5 ms · 239 |

  Las sombras con 4 cortes y el MSAA ×4 de "Alta" casi duplican el costo, pero quedan por encima de 100 FPS. Los tiempos absolutos varían entre sesiones (en el Paso 22 la misma recta dio 11 ms), así que conviene comparar sólo dentro de una misma corrida.
- **Verificación**: prueba que aplica los dos presets y revisa dirección y color del sol, sombras, tonemap y niebla; mide la tabla; saca capturas. Se volvió a correr la vuelta con piloto automático del Paso 21 (1:42.2 y 1:41.1, sin salidas). Capturas: `informes/capturas/paso23-costa.png` (sol sobre el mar), `paso23-recta.png`, `paso23-castillo.png`, `paso23-ciudad-atardecer.png`, `paso23-ciudad-dia.png`, `paso23-opciones.png`, `paso23-menu-opciones.png`.
- **Cómo probar**: F5 → Jugar → elegir piloto → en la recta del mar, el sol bajo y el reflejo en el agua; Esc → Opciones → "Hora de la carrera" cambia a Día al instante.

### Paso 24 — Pulido de H1 (cierra el hito H1)
- **Tutorial de controles** (`ControlsPanel`, `scripts/ui/controls_panel.gd`): panel con las teclas dibujadas como recuadros y lo que hace cada una, en tres secciones (Manejo, Caja de cambios, Carrera). Los textos están en `data/controls.json` y **las teclas se leen del InputMap** de `project.godot`, así que si se cambia una tecla el panel se actualiza solo. Se abre con el botón nuevo **"Controles"** del menú principal y de la pausa, y aparece en la pantalla de carga. La línea de ayuda del HUD quedó más corta ("Esc pausa y controles").
- **Pantalla de carga** (`scenes/loading.tscn`, `LoadingScreen`): al confirmar el piloto, el menú pasa a esta pantalla en vez de cargar la carrera de golpe. Carga `main.tscn` en otro hilo (`ResourceLoader.load_threaded_request`) con barra de progreso y muestra circuito, piloto, escudería, modo, hora de la carrera, un consejo al azar (de `controls.json`) y los controles, con el color del equipo. La ciudad se arma en el `_ready()` de la carrera y congela la pantalla un momento: antes se muestra "Armando el circuito y la ciudad…".
  - **Primera carrera**: espera **Enter** ("leé los controles y apretá Enter para salir a pista") y guarda `tutorial_seen` en `Settings` (no se borra con Restablecer).
  - **Después**: pasa sola apenas termina de cargar (mínimo 1,2 s para que se lea el consejo; Enter lo saltea). Menú → carrera en ~1,8 s.
- **Prueba en PC tipo laboratorio** (`scenes/benchmark.tscn`, `scripts/tools/benchmark.gd`): carga la carrera con cada calidad gráfica, mide 3 vistas sin vsync (promedio y percentil 95 de 120 cuadros) y recomienda la calidad más alta que se sostiene a 60 FPS en todas. Escribe un informe con CPU, placa de video, driver, renderer y resolución en `user://benchmark.txt` (en Windows: `%APPDATA%\Godot\app_userdata\GodotF126\benchmark.txt`). Se corre sin abrir el editor:
  `Godot_v4.7.2-stable_win64.exe --path GodotF126 res://scenes/benchmark.tscn` (con `-- --quit` se cierra solo).
  Corrida en una notebook con gráficos integrados, como las del laboratorio (i5-1334U, Intel UHD Graphics, OpenGL 3.3, ventana 1280×720):

| Vista | Baja | Media | Alta |
|---|---|---|---|
| Recta principal | 4,9 / 8,6 ms | 7,5 / 13,7 ms | 13,7 / 19,9 ms |
| Castillo | 3,8 / 6,1 ms | 6,5 / 11,6 ms | 10,2 / 16,8 ms |
| Cenital | 7,1 / 12,5 ms | 5,7 / 9,8 ms | 10,5 / 14,9 ms |

  (promedio / percentil 95 por cuadro). **Recomendada: Media**, que ya es la calidad por defecto; "Alta" pasa los 16,7 ms en los cuadros más pesados de la recta. **Pendiente**: correr el mismo comando en una PC del laboratorio y anotar el resultado; si recomienda "Baja", cambiar `"quality"` en `data/settings.json`.
- **Verificación**: prueba que lee las teclas del InputMap (W/↑, A/←, D/→, E, Q, C; una acción inexistente da lista vacía), abre Controles en el menú y en la pausa (entran en 1280×720), recorre menú → carga → carrera: la primera vez la carga queda esperando Enter (sigue ahí 2,5 s después), con Enter entra a la carrera y guarda `tutorial_seen`; la segunda vez pasa sola y el auto aparece en la largada. Se volvió a correr la vuelta con piloto automático del Paso 21 (mismos tiempos). Capturas: `informes/capturas/paso24-menu.png`, `paso24-menu-controles.png`, `paso24-carga.png`, `paso24-pausa-controles.png`.
- **Cómo probar**: F5 → Controles (en el menú) → Jugar → modo → piloto → la pantalla de carga espera Enter la primera vez; en carrera, Esc → Controles. Para ver el tutorial de nuevo, borrar `tutorial_seen` de `user://settings.json`.

**Hito H1 alcanzado**: menú con auto 3D y música → modo → escudería y piloto → carga con tutorial → carrera en Bakú con caja manual, cockpit con volante y manos, sonido sintetizado, cronómetro por sectores, límites de pista, semáforo, cámaras de TV, ciudad e iluminación de atardecer → resultado → menú.
