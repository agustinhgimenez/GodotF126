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

## Fase D — Física de simulador (H2) ⏳

| Paso | Contenido | Estado |
|---|---|---|
| 25 | Modelo por **4 ruedas**: suspensión por raycast (resorte + amortiguador) en lugar del arcade | ✅ |
| 26 | **Neumáticos**: curva tipo Pacejka simplificada, ángulo de deriva y deslizamiento longitudinal por rueda | ✅ |
| 27 | Transferencia de peso en frenada, aceleración y curva | ✅ |
| 28 | **Aerodinámica**: carga y resistencia que crecen con la velocidad | ✅ |
| 29 | **Aero activa 2026**: modo recta (baja resistencia) / modo curva, y **modo adelantamiento** | ✅ |
| 30 | Frenos: reparto delantero/trasero ajustable, bloqueo de ruedas, ABS opcional | ✅ |
| 31 | Diferencial y **control de tracción** con niveles | ✅ |
| 32 | **ERS 2026**: batería, recuperación en frenada, despliegue en aceleración, indicador en volante | ✅ |
| 33 | Neumáticos: compuestos blando / medio / duro, temperatura y desgaste | ✅ |
| 34 | Combustible: el peso baja vuelta a vuelta | ✅ |
| 35 | **Setup del auto**: alerones, altura, rigidez, presiones, relaciones de marcha | ✅ |
| 36 | Daños: alerón delantero roto reduce la carga, pinchazos | ✅ |
| 37 | Soporte de **joystick y volante** (acelerador y freno analógicos, vibración); remapeo de controles | ⏳ Siguiente |
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

### Paso 25 — Modelo por 4 ruedas con suspensión por raycast
- **El auto pasa a ser un cuerpo rígido** (`CarController` ahora extiende `RigidBody3D` en vez de `CharacterBody3D`): 800 kg, centro de masa 30 cm sobre el piso y un poco detrás del centro (45 % del peso adelante), inercia propia (cabeceo 1000, giro 1100, rolido 300 kg·m²), sin amortiguación lineal falsa y con detección continua de colisiones para que no atraviese los muros. La caja de colisión subió 10 cm: al piso lo tocan las ruedas, no la carrocería.
- **Cada rueda es un rayo** (`CarWheel`, `scripts/car/car_wheel.gd`) desde su anclaje hacia abajo. La compresión da la fuerza del **resorte** (70.000 N/m, con precarga igual a la carga estática de esa rueda: con el auto quieto la suspensión queda en el medio de su recorrido de ±12 cm y el auto a su altura de diseño) más la del **amortiguador** (3.800 N·s/m), aplicadas en el punto de contacto. Tope de carga (6 × la estática) para que un borde no lo dispare.
- **Neumático simple por rueda** (reemplazado en el Paso 26): fuerza lateral proporcional al ángulo de deriva hasta 6° y constante después; tracción en las traseras con el par del motor y la caja; frenos repartidos 58/42; rodadura y freno motor; todo dentro del **círculo de fricción** (μ = 2,3, que por ahora incluye una carga aerodinámica promedio). Con freno de mano las traseras se bloquean y agarran 40 % de costado.
- **Dirección**: giran las ruedas delanteras. El ángulo máximo baja con la velocidad hasta el que da el máximo agarre (22° a baja velocidad, ~7,5° a 200 km/h) para que se pueda manejar con teclado; "Dirección asistida: No" deja girar 1,6 veces más (`steer_limit` en `data/settings.json`).
- Las **ruedas del modelo** suben y bajan con la suspensión y las delanteras giran. El auto **cabecea y rola** solo, por cómo caen las fuerzas: es la transferencia de peso que se va a ajustar en el Paso 27. Las cámaras pegadas (cockpit, T-cam, capot) siguen al chasis; las de persecución sólo el giro.
- **Motor de física: Jolt** (`physics/3d/physics_engine` en `project.godot`, viene con Godot 4.7). Con el de Godot, un choque a 200 km/h en ángulo contra los muros (mallas finas) hacía saltar el auto por encima del muro; con Jolt roza y sigue.
- Golpes contra muros: velocidad perdida contra la normal de cada contacto (`_integrate_forces`), la usan la vibración y el sonido como antes. En el menú el auto queda congelado (`freeze`).
- Parámetros en el bloque nuevo `"chassis"` de `data/car.json` (centro de masa, inercia, suspensión, neumáticos, frenos, dirección); salió `traction_limit`.
- **Verificación** (prueba con física a 60 Hz):

| Prueba | Resultado |
|---|---|
| Quieto | cargas 1.764 / 1.764 / 2.156 / 2.156 N = el peso (45 % adelante), altura de diseño |
| 0–100 km/h | 2,05 s (72 % del peso atrás, la trompa sube 0,2°); 198 km/h en 400 m |
| Frenada 198 → 0 km/h | 60 m en 2,3 s (24 m/s² promedio); 66 % del peso adelante, la trompa baja 0,4° |
| Curva a 60 / 120 km/h, volante a fondo | 2,06 / 2,15 g laterales, rolido 1,4°, ruedas de adentro casi descargadas |
| Freno de mano en curva | el auto se cruza (91°) |
| Choque a 20° / de frente a 200 km/h | roza el muro y sigue a 157 km/h sin despegarse / se frena contra el muro; golpes detectados |
| Vuelta con piloto automático (Paso 21) | 2 vueltas válidas: **1:38.7 y 1:37.6** (antes 1:42.2 / 1:41.1), sin salidas, golpes ni reinicios, siempre apoyado (±6 cm) |

  Además: el auto del menú no se mueve, la largada detenida no marca salto en falso mientras el auto se asienta, el recorrido menú → carga → carrera del Paso 24 sigue igual y el benchmark da los mismos tiempos (la física nueva no se nota). Capturas: `informes/capturas/paso25-ruedas.png` (ruedas giradas en el castillo), `paso25-frenada.png`.
- **Cómo probar**: F5 → Jugar → en la cámara "Cercana" o "De pista" se ve el auto cabecear al frenar y rolar en las curvas; con freno de mano en una curva lenta se cruza; contra un muro roza en vez de pegarse.

### Paso 26 — Neumáticos con curva de Pacejka
- **"Fórmula mágica" de Pacejka simplificada** (`TyreModel`, `scripts/car/tyre_model.gd`): `F = D · sin(C · atan(B·x − E·(B·x − atan(B·x))))` con D = μ × carga. Hay una curva **lateral** (x = ángulo de deriva) y una **longitudinal** (x = deslizamiento κ). B, C y E están en `"chassis" → "tyres"` de `data/car.json`; el pico de cada curva se calcula de ellos: **6,1° de deriva** (como el neumático provisorio del Paso 25) y **κ = 0,10**. Pasado el pico la fuerza baja: deslizando de costado queda 79 % del pico y con la rueda bloqueada 76 %. Ver `informes/capturas/paso26-curvas.png`.
- **Cada rueda gira por su cuenta** (`CarWheel.spin`, inercia 1,2 kg·m²): el motor (traseras, mitad cada una) y los frenos le aplican par, y el neumático la frena o la arrastra. El **deslizamiento longitudinal** es κ = (ω·r − v) / v: positivo cuando patina acelerando, −1 cuando está bloqueada. Las **RPM del motor salen del giro de las traseras**, así que si patinan suben las RPM.
- **Deriva y deslizamiento combinados**: cada uno se divide por su pico, la curva se evalúa con el largo del vector y la fuerza se reparte en su dirección. El total nunca pasa de μ × carga, y frenar o acelerar a fondo deja menos agarre de costado: con las delanteras bloqueadas el auto deja de doblar.
- **Sensibilidad a la carga**: el μ baja 10 % por cada carga estática de más (una rueda con el doble de peso agarra 1,8 veces, no 2). Por eso, con la rueda de adentro casi descargada, en curva da un poco menos que antes (1,8–1,9 g en vez de 2,1).
- **Cálculo estable a 60 Hz**: la curva de Pacejka es unas dos veces más rígida que la recta del Paso 25 y el auto oscilaba de un cuadro al otro a baja velocidad (quieto en la largada se iba deslizando). Ahora los neumáticos se calculan en **8 sub-pasos por cuadro**: en cada uno se predice cómo cambian la velocidad y el giro del auto con esas fuerzas (masa y tensor de inercia) y al cuerpo se le aplica el promedio. El giro de cada rueda se integra en forma implícita (con la pendiente de la curva) para que no oscile. Cuesta ~0,6 ms de CPU por auto y por cuadro de física.
- **Limitadores provisorios** (`"limiters"` en `car.json`, activados): con teclado el freno y el acelerador van de 0 a 1 de golpe, así que las ruedas se bloquearían en cada frenada y patinarían en cada salida de curva. Hasta el ABS (Paso 30) y el control de tracción (Paso 31) no dejan que κ pase del pico. El freno de mano no pasa por el limitador: bloquea las traseras (κ = −1) y el auto se cruza solo porque una rueda bloqueada casi no agarra de costado (salió el `handbrake_lateral_factor` del Paso 25).
- El **chirrido** también suena con las ruedas bloqueadas o patinando (`squeal_start_slip` / `squeal_full_slip` en `"audio_fx"`). Las ruedas del modelo giran con su velocidad.
- **Verificación** (física a 60 Hz):

| Prueba | Resultado |
|---|---|
| Quieto | cargas 1.764 / 1.764 / 2.156 / 2.156 N, velocidad 0 (sin los sub-pasos se iba deslizando) |
| Rodando a 150 km/h sin pedales | ω·r = v en las delanteras; las traseras 1,5 % más lentas por el freno motor |
| 0–100 km/h | 2,15 s con limitador (κ ≈ 0,09) · 2,52 s sin limitador (las traseras patinan, κ hasta 28 parado, chirrido a pleno) |
| Frenada 195 → 0 km/h | 59 m en 2,3 s con limitador · 75 m en 2,9 s sin limitador (delanteras bloqueadas, κ = −1) |
| Frenar a fondo en curva a 115 km/h (1 s) | con limitador sigue doblando (8°) · sin limitador sigue derecho (−2°) |
| Curva a 60 / 120 km/h, volante a fondo | 1,82 / 1,91 g laterales |
| Freno de mano | traseras κ = −1, el auto se cruza (90°) |
| Choques contra el muro a 200 km/h | iguales al Paso 25 (roza y sigue a 159 km/h / se frena) |
| Vuelta con piloto automático (Paso 21) | 2 vueltas válidas: **1:39.6 y 1:38.4** (Paso 25: 1:38.7 / 1:37.6), sin salidas, golpes ni reinicios |

  El benchmark del Paso 24 no cambió (en esta corrida recomendó "Alta"; los tiempos varían entre corridas).
- **Cómo probar**: F5 → Jugar. Con los limitadores igual que antes; para sentir el neumático, poner `"limiters": { "brake": false, "traction": false }` en `data/car.json`: arrancando a fondo en 1ª las traseras patinan y chirrían, y frenando a fondo a alta velocidad las delanteras se bloquean y el auto no dobla.

### Paso 27 — Transferencia de peso en frenada, aceleración y curva
- **De dónde sale**: el centro de masa está 0,3 m sobre el piso y los neumáticos empujan en el piso, así que frenar carga el eje delantero, acelerar el trasero y doblar las ruedas de afuera. El cuerpo rígido del Paso 25 ya lo hacía solo; la cuenta es ΔW = m · a · h / L (L = 3,4 m entre ejes) para la longitudinal y ΔW = m · a_lat · h / trocha (1,7 m) para la lateral. Este paso **mide** esa transferencia y agrega lo que en un auto real decide **por dónde pasa**.
- **Suspensión por eje** (`"suspension"` → `"front"` / `"rear"` en `data/car.json`): resortes 75.000 / 65.000 N/m y amortiguadores 4.000 / 3.600 N·s/m (antes 70.000 y 3.800 en las cuatro).
- **Barras estabilizadoras** (`anti_roll`, 40.000 / 30.000 N/m): si una rueda del eje está más comprimida que la otra, la barra la carga con rigidez × diferencia y descarga a la otra. El auto **rola la mitad** (1,29° → 0,63° en una curva a 1,9 g). La transferencia lateral total no cambia (la fija la altura del centro de masa); las barras deciden qué eje se lleva más: con más barra adelante, el eje delantero carga 55 % de la transferencia y, por la sensibilidad a la carga del neumático (Paso 26), agarra un poco menos que el trasero: el auto tiende a **subvirar** (más estable con teclado).
- **Anti-cabeceo** (`anti_pitch`, 35 % adelante / 25 % atrás): esa fracción de la transferencia longitudinal pasa por los brazos de la suspensión y no por el resorte (se calcula con la fuerza del neumático del cuadro anterior). La carga en las ruedas es la misma, pero el auto **cabecea menos**: 0,39° → 0,33° frenando a 2,4 g.
- **Panel de cargas por rueda** (tecla **F3**, `WheelLoadsPanel`, `scripts/ui/wheel_loads_panel.gd`): el auto visto desde arriba con la carga de cada rueda en N y % del peso (rojo = más carga que quieto, azul = menos), κ y deriva; abajo el reparto por eje y por lado, la aceleración en g, cabeceo y rolido, y la **transferencia medida contra la cuenta**. Está en Controles (acción nueva `toggle_telemetry`). Se ajustó el espaciado del panel de Controles para que la fila nueva entre en 720 px.
- `CarController` suma `local_acceleration` (en ejes del auto), `get_pitch_deg()`, `get_roll_deg()` y `theoretical_transfer(aceleración)`.
- **Verificación** (física a 60 Hz; "Paso 26" = resortes iguales, sin barras ni anti-cabeceo):

| Prueba | Paso 26 | Paso 27 |
|---|---|---|
| Frenada a 2,4 g: eje delantero gana (cuenta 1.663 N) | +1.615 N (97 %), cabeceo 0,39° | +1.622 N (97 %), cabeceo 0,33° |
| Aceleración a 1,0 g en 4ª: eje delantero pierde | −620 N, cabeceo 0,17° | −625 N, cabeceo 0,15° |
| Curva a 120 km/h (1,9 g): lado de afuera gana (cuenta ~2.630 N) | +2.677 N (101 %), 50 % adelante, rolido 1,29° | +2.619 N (100 %), 55 % adelante, rolido 0,63° |
| Rueda delantera de adentro en esa curva | 361 N | 258 N |

  Al acelerar, la transferencia coincide con la que da la fuerza de los neumáticos (−639 N, 98 %); contra la aceleración del auto da 89 % porque parte de esa aceleración la come el arrastre, que por ahora actúa en el centro de masa y no hace cabecear (se revisa con la aerodinámica del Paso 28). Además siguen las pruebas de los Pasos 25 y 26 (quieto, 0–100 en 2,15 s, frenada de 58 m, 1,80 / 1,88 g en curva, choques, limitadores) y la vuelta con piloto automático: **1:39.6 y 1:38.6**, sin salidas, golpes ni reinicios. Capturas: `informes/capturas/paso27-curva.png`, `paso27-frenada.png`.
- **Cómo probar**: F5 → Jugar → F3. En una curva rápida se ven las ruedas de afuera en rojo y la delantera de adentro casi sin carga; frenando fuerte, las delanteras con 66 % del peso. Para comparar, cambiar `anti_roll` en `data/car.json` (por ejemplo 0 / 60.000): el auto rola más y cambia el balance.

### Paso 28 — Aerodinámica: carga y resistencia que crecen con la velocidad
- **Carga aerodinámica** = ½ · ρ · ClA · v² (ρ = 1,225 kg/m³, ClA = 3,2 m²), hacia abajo del auto, repartida entre los ejes según el **balance** (44 % adelante) y aplicada sobre cada eje. Comprime los resortes (**el auto baja con la velocidad**) y llega a los neumáticos como carga, así que **agarran más cuanto más rápido**: 0,19 × el peso a 100 km/h, 0,77 × a 200 km/h.
- **Arrastre** = ½ · ρ · CdA · v² (CdA = 1,57 m², el mismo que daba el `aero_drag` del Paso 3), contra la velocidad y aplicado en el **centro de presión** (0,35 m sobre el piso, un poco más alto que el centro de masa): a alta velocidad descarga apenas el eje delantero.
- **Agarre mecánico**: `tyre_mu` bajó de 2,3 (que incluía una carga aerodinámica promedio) a **1,75**. Ahora las curvas lentas son más lentas y las rápidas más rápidas que antes; arrancando, las traseras tienen menos para tirar (0–100 km/h en 2,7 s).
- La dirección (`_update_steering()`) calcula el giro máximo con el agarre real, `grip_acceleration()` = μ × (peso + carga) / masa.
- La **transferencia de la cuenta** (`theoretical_transfer()`) ahora sale de las fuerzas de los neumáticos más el momento del arrastre, en vez de la aceleración del auto: así coincide también acelerando (en el Paso 27 daba 89 % porque el arrastre se comía parte de la aceleración). El panel F3 muestra la carga aerodinámica y el arrastre, y descuenta la carga del eje delantero al medir la transferencia.
- Datos en el bloque nuevo `"aero"` de `data/car.json` (`air_density`, `cla`, `cda`, `balance`, `pressure_height`); salió `"aero_drag"`.
- **Verificación** (física a 60 Hz):

| Velocidad | Carga (= la cuenta) | Arrastre | Carga por eje | El auto baja (adelante / atrás) | Agarre disponible |
|---|---|---|---|---|---|
| 0 km/h | 0 N | 0 N | 3.528 / 4.312 N (45 %) | — | 1,75 g |
| 100 km/h | 1.512 N | 742 N | 4.331 / 5.021 N | 0,5 / 0,6 cm | 2,09 g |
| 200 km/h | 6.049 N | 2.968 N | 6.326 / 7.564 N | 1,9 / 2,5 cm | 3,10 g |
| 300 km/h | 13.611 N | 6.678 N | 9.580 / 11.871 N | 4,0 / 5,8 cm | 4,79 g |

| Prueba | Paso 27 | Paso 28 |
|---|---|---|
| Curva con volante a fondo a 60 / 120 / 193 km/h | 1,80 / 1,88 g / — | **1,53 / 1,83 / 2,31 g** |
| Frenada a fondo | ~2,4 g parejo | **3,6 g** a 250 km/h, 2,1 g a 70 km/h; 194 → 0 km/h en 60 m |
| 0–100 km/h | 2,15 s | 2,72 s |
| Transferencia contra la cuenta (frenada / aceleración / curva) | 97 / 89 / 100 % | 99 / 102 / 100 % |
| Vuelta con piloto automático | 1:39.6 / 1:38.6 | 1:41.6 / **1:40.1**, sin salidas, golpes ni reinicios |

  El piloto automático de la prueba frena y dobla con límites fijos (14 y 7 m/s²) y no aprovecha la carga en las rápidas; la vuelta se hace más lenta por las salidas de curva con menos tracción. Siguen bien quieto, choques, limitadores y freno de mano. **Velocidad máxima**: 198 km/h, la corta el limitador en 8ª, no el arrastre (con 446 kW el arrastre recién frenaría el auto a ~269 km/h); alargar la 8ª queda para el setup del Paso 35. Captura: `informes/capturas/paso28-curva-rapida.png` (panel F3 a 190 km/h).
- **Cómo probar**: F5 → Jugar → F3. En la recta la carga aerodinámica sube con la velocidad y las cuatro ruedas se ponen rojas; en las curvas rápidas el auto aguanta mucho más que en el castillo.

### Paso 29 — Aero activa 2026: modo recta / modo curva y modo adelantamiento
- **Modo recta / modo curva** (`ActiveAero`, componente del auto): en modo recta los alerones se abren y la carga y el arrastre bajan (ClA × 0,6 y CdA × 0,7: de 3,2 a 1,92 m² y de 1,57 a 1,10 m²; valores aproximados, no oficiales). Los alerones tardan **0,3 s** en abrirse o cerrarse. El modo curva es el normal.
- **Cuándo se abre**: sólo dentro de las **zonas de recta** (`"aero_zones"` en `data/tracks.json`, en metros desde la línea de largada; un nodo nuevo `AeroZones` le avisa al auto si está en una) y por encima de **120 km/h**. Más despacio las traseras patinan y la carga que se pierde cuesta más tracción que el arrastre que se ahorra (en la largada detenida, con el modo abierto desde 0 km/h la vuelta 1 salía más lenta). En Bakú hay dos zonas: la **recta principal** (de 470 m antes de la línea a 50 m después) y la **recta del oeste** (1.790–1.915 m). Las dos terminan antes del punto de frenado, así los alerones ya están cerrados al frenar.
- **Se cierra solo** al frenar, al girar fuerte (dirección > 30 %) o al salir de la zona; levantar el pie no lo cierra.
- **Automático o manual** (opción nueva "Modo recta (aero activa)", por defecto automático): en automático se abre a fondo con el acelerador; en manual lo abre y lo cierra la tecla **F** (acción `aero_mode`).
- **Modo adelantamiento** (tecla **G**, acción `overtake`): +100 kW con 0,5 MJ de energía por vuelta (unos 5 s a fondo), que se recarga al empezar cada vuelta. En 2026 sólo vale a menos de 1 s del auto de adelante y la energía sale de la batería: queda como `TODO` para cuando haya rivales (Fase F) y ERS (Paso 32). No suma potencia durante el corte del limitador ni en los cambios.
- **HUD**: fila nueva en el tablero con "MODO RECTA" (verde), "MODO CURVA" o "MODO RECTA LISTA" (con borde verde dentro de la zona), y una barra "ADELANTAR %" con la energía (azul fuerte cuando está activo). El volante muestra RECTA / CURVA / ADEL, el panel F3 suma el modo con ClA y CdA, y aparece un mensaje al activar el modo adelantamiento o si no queda energía.
- Para que entrara la fila nueva de Opciones, se juntaron "Subir / bajar marcha" en una sola fila del panel de Controles (sigue terminando en 716 de 720 px) y las filas de Opciones pasaron de 36 a 34 px con menos separación (ahora terminan en 701 px en el menú y en 691 en la pausa).
- Datos: `"active"` dentro de `"aero"` en `data/car.json` (`straight_mode`: `cla_factor`, `cda_factor`, `transition_time`, `close_brake`, `close_steer`, `open_throttle`, `min_speed_kmh`; `overtake`: `extra_power_kw`, `energy_mj`) y `"aero_zones"` en `data/tracks.json`.
- **Verificación** (física a 60 Hz):

| Prueba | Modo curva | Modo recta | Curva + adelantamiento | Recta + adelantamiento |
|---|---|---|---|---|
| 100 → 160 km/h | 1,98 s | 1,92 s | 1,67 s | 1,67 s |
| 100 → 185 km/h | 3,03 s (124 m) | 2,87 s (116 m) | 2,45 s (98 m) | 2,38 s (95 m) |
| A 185 km/h: arrastre / carga | 2.530 / 5.157 N | 1.777 / 3.104 N | — | — |
| Curva a 190 km/h | 2,28 g | 2,00 g (modo mal puesto) | — | — |
| Vuelta con piloto automático (2ª) | 1:40.133 (sin zonas) | 1:40.200 | — | 1:39.800 |

  Los alerones se cierran en 0,30 s al frenar o al salir de la zona y en 0,33 s al girar (la dirección está suavizada). En manual, F fuera de la zona no abre nada; dentro abre y cierra, y al salir se cierra solo. Con la energía en cero el modo adelantamiento no se activa y avisa; al empezar la vuelta vuelve a 0,5 MJ. Siguen igual las pruebas de los Pasos 25–28 (0–100 en 2,72 s, frenada de 60 m, 1,53 / 1,83 / 2,31 g, transferencia 98–102 %, cargas aerodinámicas) y las vueltas no tienen salidas, golpes ni reinicios.

  **En la vuelta casi no se nota** (todas las variantes quedan dentro de ±0,2 s, lo que ya varía entre corridas): el limitador corta en 8ª a ~194 km/h y el auto llega igual a esa velocidad en la recta principal. Con una 8ª más larga (sólo en la prueba: 257 km/h en el limitador), 600 m a fondo desde 150 km/h tardan **9,87 s en modo recta contra 10,23 s** en modo curva: el modo recta va a rendir de verdad cuando se ajuste la caja en el setup del Paso 35. Capturas: `informes/capturas/paso29-modo-recta.png` (recta principal a 181 km/h con los dos modos activos y el panel F3), `paso29-opciones.png`, `paso29-controles.png`.
- **Cómo probar**: F5 → Jugar. Al salir de la última curva hacia la recta principal, a fondo, la fila del tablero pasa a "MODO RECTA" en verde; al frenar para la curva 1 vuelve a "MODO CURVA". G activa el modo adelantamiento y la barra azul se vacía. En Opciones se puede pasar a manual y abrir los alerones con F.

### Paso 30 — Frenos: reparto ajustable, bloqueo de ruedas y ABS opcional
- **ABS** (`AbsModel`, opción nueva "ABS", por defecto Sí): reemplaza al limitador provisorio de los Pasos 25–26, que era un ABS perfecto e instantáneo. Ahora cada rueda tiene una **presión de freno** (0–1): cuando empieza a bloquearse (deslizamiento de frenada −κ > 0,14) el ABS la suelta a 15 por segundo, y cuando recupera el giro (−κ < 0,08) la vuelve a apretar a 4 por segundo. La rueda cicla alrededor del pico de la curva del neumático: frena un poco menos que el limitador (61–62 m contra 60 m desde 194 km/h) y sigue doblando. Debajo de 2 m/s no actúa, así el auto se detiene. Corre dentro de los sub-pasos de los neumáticos.
- **Sin ABS las ruedas se bloquean**: con teclado el freno va a fondo de golpe y el freno total (30.000 N) es más de lo que agarran los dos ejes, así que se bloquean las cuatro ruedas: el auto frena menos (76 m desde 194 km/h), chirría y casi no dobla.
- **Reparto de frenada ajustable** en carrera: **Z** lo pasa atrás y **X** adelante, de a 1 % entre 45 % y 75 % (arranca en 58 %; vale para la sesión). Con el reparto muy atrás se bloquean primero las traseras y el auto se cruza; muy adelante se bloquean las delanteras y el auto sigue derecho. A fondo con ABS casi no cambia la distancia; se nota frenando a medias o sin ABS.
- **HUD**: arriba del velocímetro el reparto ("BB 58") y una luz "ABS" (naranja cuando actúa, roja si una rueda se bloquea; "SIN ABS" con la opción apagada). El volante muestra "BB58" (en rojo con una rueda bloqueada), el panel F3 marca cada rueda "BLOQUEADA" o con la presión que deja el ABS y suma una línea con el reparto y el ABS, y aparece un mensaje al cambiar el reparto.
- Para que entraran la fila del ABS y la de Z / X, los botones de abajo de Opciones y Controles quedaron en una sola fila con el texto de ayuda al costado: Opciones termina en 717 de 720 px en el menú (707 en la pausa) y Controles en 710 (700 en la pausa).
- Datos en `"brakes"` de `"chassis"` en `data/car.json`: `bias_min`, `bias_max`, `bias_step` y el bloque `"abs"` (`release_slip`, `apply_slip`, `release_rate`, `apply_rate`, `min_speed`). Salió `"brake"` de `"limiters"` (queda `"traction"` hasta el Paso 31).
- **Verificación** (física a 60 Hz):

| Frenada a fondo | Con ABS | Sin ABS |
|---|---|---|
| 194 → 0 km/h, reparto 50 / 58 / 65 / 72 % | 62,2 / 61,9 / 62,3 / 62,8 m | 76,4 / 76,4 / 76,2 / 73,4 m (cuatro ruedas bloqueadas ~2,9 s) |
| 97 → 0 km/h, reparto 58 % | 20,9 m | 24,2 m |
| Frenar en curva a 120 km/h (1 s) | baja a 68 km/h y el auto gira 28° | baja a 62 km/h y gira sólo 8° (bloqueado) |

| Sin ABS, freno a medias | Reparto 45 % | Reparto 58 % | Reparto 72 % |
|---|---|---|---|
| Recta, 50 % de freno desde 150 km/h | se bloquean las traseras (0,78 s); 84 km/h al final | no se bloquea nada; 74 km/h al final | se bloquean las delanteras (0,82 s); 88 km/h al final |
| Curva, 60 % de freno a 120 km/h | **el auto se cruza** (derrape de 40°) | gira 7° | las delanteras bloqueadas: no dobla (0°) |

  El ABS hace unos 20 ciclos por frenada larga, con la presión media adelante entre 43 y 64 % según el reparto. El freno de mano sigue bloqueando las traseras con ABS. Siguen igual las pruebas de los Pasos 25–29 (0–100 en 2,72 s, 1,53 / 1,83 / 2,31 g en curva, transferencia 98–102 %, aero y aero activa) y la vuelta con piloto automático: **1:40.117** sin aero activa y 1:40.167 con modo recta, sin salidas, golpes ni reinicios. Capturas: `informes/capturas/paso30-frenada-abs.png` (ABS actuando a 139 km/h), `paso30-bloqueo.png` (sin ABS y reparto 45 %: ruedas bloqueadas y derrape), `paso30-opciones.png`, `paso30-controles.png`.
- **Cómo probar**: F5 → Jugar → F3. Frenando fuerte se enciende la luz ABS naranja y las ruedas del panel muestran el ABS trabajando. En Opciones poner ABS en No: frenando a fondo las ruedas quedan "BLOQUEADA" y el auto no dobla. Con Z bajar el reparto a 45 % y frenar en una curva: el auto se cruza.

### Paso 31 — Diferencial y control de tracción con niveles
- **Diferencial autoblocante** (`Differential`): antes el par del motor iba mitad y mitad a las traseras y cada una giraba libre (un diferencial abierto ideal). Ahora, si una rueda gira más rápido que la otra, el diferencial le pasa par a la más lenta, hasta una capacidad de **precarga + bloqueo × par de entrada**: 100 N·m más el 25 % del par del motor acelerando, o el 10 % del freno motor sin acelerar. Con todo en 0 queda abierto y con una capacidad enorme, bloqueado. Corre en los sub-pasos de los neumáticos; en la curva lenta pasa hasta ~600 N·m de la rueda de adentro (descargada, patina) a la de afuera.
- **Control de tracción** (`TractionControl`, opción nueva "Control de tracción" y tecla **T** en carrera): reemplaza al limitador provisorio de los Pasos 25–26, que no dejaba a cada rueda pasar del pico. Ahora corta par del motor para mantener el deslizamiento de las traseras en el umbral del nivel: **κ 0,30 / 0,16 / 0,09** para los niveles 1 / 2 / 3 (el pico del neumático está en 0,10); 0 = apagado. El factor de par se corrige en cada sub-paso con el error relativo (umbral − κ) / umbral × 40 por segundo: patinando de más baja rápido y sin patinar vuelve a 100 % en 25 ms. **Por defecto nivel 3**: con teclado (acelerador a fondo) es el más rápido y el más seguro; los niveles bajos dejan cruzar la cola, para dosificar el acelerador.
- **HUD**: luz "TC n" a la derecha de la fila de abajo del tablero (naranja cuando corta; "SIN TC" apagado), "TCn" en el volante, una línea en el panel F3 con el nivel, el par que deja pasar y el par que pasa el diferencial, y un mensaje al cambiar el nivel.
- Para que entraran las filas nuevas: botones de Opciones de 31 px de alto (eran 34) y en Controles separación de 1 px y letra un punto más chica. Opciones termina en 714 de 720 px en el menú (704 en la pausa) y Controles en 709 (699 en la pausa, 678 en la pantalla de carga).
- `Settings` ahora sanea también los valores por defecto (el JSON trae los enteros como float y el selector buscaba "3.0" en vez de "3").
- Datos en `"chassis"` de `data/car.json`: `"differential"` (`preload_nm`, `power_lock`, `coast_lock`) y `"traction_control"` (`slip_levels`, `gain`, `max_error`). Salió `"limiters"`.
- **Verificación** (física a 60 Hz):

| Largada (automática) | TC 0 | TC 1 | TC 2 | TC 3 |
|---|---|---|---|---|
| 0–100 km/h | 3,33 s | 3,32 s | 3,12 s | **2,78 s** |
| 0–160 km/h | 5,20 s | 5,20 s | 5,00 s | 4,75 s |
| κ traseras máx / promedio 2 s | 33 / 6,6 (patinan) | 0,90 / 0,29 | 0,52 / 0,15 | 0,27 / 0,08 |

| Salida de curva lenta (60 km/h en 2ª, a fondo 1,5 s) | TC 0 | TC 1 | TC 2 | TC 3 |
|---|---|---|---|---|
| Diferencial abierto | **trompo** (derrape 90°), 37 km/h | derrape 18°, 57 km/h | 1°, 68 km/h | 1°, 70 km/h |
| Diferencial normal (100 N·m + 25 %) | trompo (93°), 37 km/h | derrape 23°, 54 km/h | 3°, 69 km/h | 1°, 70 km/h |
| Diferencial bloqueado | trompo (91°), 38 km/h | derrape 27°, 52 km/h | 3°, 70 km/h | 1°, 70 km/h |

  Con el diferencial abierto la trasera de adentro patina mucho más que la de afuera (κ 0,94 contra 0,60 con TC 1; 0,36 contra 0,04 con TC 3); cuanto más bloqueado, más parejas y más se cruza la cola con poco TC. En una curva constante a 90 km/h con medio acelerador, el diferencial bloqueado subvira un poco: el auto gira 38° en 1 s (1,49 g) contra 40–41° (1,58–1,60 g) abierto o normal. En la largada en recta el diferencial no cambia nada (las dos ruedas giran igual). La tecla T pasa 2 → 3 → 0 → 1 → 2.
  Siguen igual las pruebas de los Pasos 25–30 (0–100 en 2,78 s con TC 3, frenada de 61,5 m, 1,47 / 1,82 / 2,33 g en curva, transferencia 97–100 %, aero activa, ABS y reparto). **La vuelta con piloto automático** (a todo o nada) da **1:41.35** con TC 3, 1:41.12 con TC 2 y 1:41.75 con TC 1, sin salidas, golpes ni reinicios: ~1,2 s más que con el limitador ideal (1:40.117), que dejaba cada rueda justo en el pico sin cortarle par a la otra. Con diferencial abierto da 1:41.32 y bloqueado 1:41.52. Sin TC el piloto automático se cruza en las salidas lentas (9 salidas de pista): con TC apagado hay que dosificar el acelerador. Capturas: `informes/capturas/paso31-tc-actuando.png` (TC 2 cortando en la salida de una curva, par al 28 %), `paso31-sin-tc.png` (sin TC: la cola se cruza, derrape de 57°), `paso31-opciones.png`, `paso31-controles.png`.
- **Cómo probar**: F5 → Jugar → F3. En una curva lenta, a fondo en 2ª: la luz "TC 3" se pone naranja y el auto sale derecho. Con T pasar a "SIN TC" y repetir: las traseras patinan y la cola se cruza. En TC 1 se puede salir derrapando un poco.

### Paso 32 — ERS 2026: batería, recuperación y despliegue
- **ERS** (`Ers`, datos en `"ers"` de `data/car.json`): batería de **4 MJ** útiles y MGU-K en el eje trasero de **350 kW** desplegando y recuperando, con un tope de **8,5 MJ recuperados por vuelta** (se renueva al cruzar la línea). Arranca con la batería llena.
- **Despliegue**: acelerando, el MGU-K suma potencia (fracción del modo × 350 kW × acelerador) mientras haya energía, sin cambio en curso ni corte del limitador y sólo hacia adelante. Pasa por el control de tracción: lo que el TC corta no se gasta. Debajo de 10 m/s la fuerza está topada (P / 10 m/s, igual que el modo adelantamiento) y se cobra lo que de verdad entrega.
- **Recuperación** con freno por cable: frenando, el MGU-K toma el lugar de una parte del freno hidráulico trasero, así que **el par total no cambia** (la frenada, el reparto y el ABS quedan iguales). Recupera lo que frenan las traseras, hasta 350 kW: si se bloquean (sin ABS) casi no recupera. En modo Recarga además frena al levantar el pie (150 kW, como más freno motor).
- **Modos** (tecla **V**): **Ataque** (despliega 100 %), **Normal** (35 %, unos 120 kW; por defecto) y **Recarga** (no despliega y recupera al levantar). Normal quedó elegido para que en la vuelta la batería quede pareja.
- **Modo adelantamiento** (Paso 29): su potencia extra ahora también sale de la batería; con la batería vacía no se activa ("Batería vacía") y se apaga solo si se vacía. Sigue con su presupuesto de 0,5 MJ por vuelta.
- **HUD**: en el tablero la barra del medio de la fila de abajo pasa a ser la batería ("ERS 48 % NOR"; amarilla, más fuerte desplegando y celeste recuperando) y con el modo adelantamiento activo vuelve a mostrar la energía para adelantar en azul. El volante tiene una barra de batería debajo de la de RPM y abajo a la izquierda el modo y la carga ("NOR 81"). El panel F3 suma una línea con el modo, la carga, la potencia desplegada / recuperada y lo recuperado en la vuelta, y aparece un mensaje al cambiar de modo. La tecla V va en la misma fila que T en Controles (sigue terminando en 709 de 720 px).
- **Verificación** (física a 60 Hz):

| Aceleración (automática, batería llena) | Recarga (sin ERS) | Normal | Ataque |
|---|---|---|---|
| 0–100 km/h | 2,83 s | 2,85 s | 2,83 s |
| 0–160 km/h | 4,80 s | 4,48 s | 4,43 s |
| 0–185 km/h | 5,85 s en 164 m | 5,22 s en 135 m | **4,93 s en 122 m** |
| Potencia máx. / energía gastada | 0 kW | 122 kW / 0,34 MJ | 350 kW / 0,63 MJ |

| Vuelta con piloto automático (sin aero activa) | Vuelta 1 | Vuelta 2 | Vuelta 3 | Batería al final de cada vuelta | Por vuelta |
|---|---|---|---|---|---|
| Sin desplegar (batería llena, Recarga) | 1:42.767 | 1:41.350 | 1:41.367 | 100 % | — |
| **Normal** | 1:42.483 | **1:40.983** | 1:40.917 | 84 / 82 / 81 / 81 % | despliega 2,8 MJ, recupera 2,8 MJ |
| Ataque | 1:42.417 | 1:41.167 | 1:41.217 | 21 / 0 / 0 % | despliega 5,9 → 2,7 MJ, recupera 2,8 MJ |
| Recarga desde 20 % | 1:43.983 | 1:41.333 | | 100 % (recuperó 3,2 MJ) | |

  Frenando a fondo desde 194 km/h la distancia no cambia (61,9 m con ABS) y se recuperan **0,41 MJ** con picos de 350 kW; sin ABS, 76,4 m y sólo 0,05 MJ (traseras bloqueadas). Levantando el pie 2 s a 180 km/h: en Ataque y Normal baja a 148 km/h; en Recarga a 121 km/h y recupera 0,29 MJ. Con el tope de la vuelta cumplido o la batería llena no recupera; en la vuelta siguiente sí. La tecla V pasa Normal → Recarga → Ataque → Normal.
  **El ERS rinde poco en la vuelta (~0,4 s)** por la misma razón que el modo recta del Paso 29: con la caja actual el limitador corta en 8ª a ~194 km/h y en las salidas lentas manda la tracción; donde más se nota es entre 100 y 185 km/h (0–185 en 4,93 s en Ataque contra 5,85 s). Va a pesar más cuando el setup del Paso 35 permita alargar la caja. Una recuperación al levantar el pie en el modo Normal (60 kW) costaba ~1 s por vuelta al piloto automático, que levanta en las curvas largas: quedó sólo en Recarga. Con aero activa y modo adelantamiento: 1:41.067 / 1:41.083 (batería 86 / 76 %). Siguen igual las pruebas de los Pasos 25–31 (0–100 en 2,78 s, frenada 61,0–61,9 m, 1,47 / 1,82 g en curva, ABS, reparto, TC); en la prueba del Paso 29 la aceleración 100–185 km/h ahora es más rápida porque Normal despliega. Capturas: `informes/capturas/paso32-recuperando.png` (frenando a 146 km/h: recupera 332 kW, barra celeste), `paso32-volante.png` (cockpit en Ataque, barra de batería en el volante), `paso32-controles.png`.
- **Cómo probar**: F5 → Jugar → F3. Frenando, la barra "ERS" del tablero se pone celeste y sube; acelerando en Ataque (V) baja rápido. En Recarga, levantar el pie frena más y carga la batería. En la vista cockpit (C) el volante muestra la barra de la batería.

### Paso 33 — Neumáticos: compuestos, temperatura y desgaste
- **Compuestos** (`TyreCompounds`, datos en `"tyre_compounds"` de `data/car.json`): **blando** (agarre × 1,025, ventana 60–105 °C, se gasta rápido), **medio** (× 1,0, 70–120 °C; por defecto) y **duro** (× 0,975, 85–130 °C, dura mucho). Se eligen antes de salir en la pantalla de modo, con una tarjeta "Neumáticos ‹ Medio ›" (← → o Enter); el compuesto queda en `GameState` y se ve en la pantalla de carga, arriba a la derecha en carrera y en los resultados.
- **Temperatura por rueda**: sube con la potencia que disipa el deslizamiento (|Fx × velocidad de patinada| + |Fy × velocidad lateral|, sumada en los sub-pasos de los neumáticos) y con la de rodar (la carcasa), y baja hacia la temperatura de la pista (35 °C), más rápido cuanto más rápido va el auto. Salen de las mantas a 70 °C. Dentro de la ventana el agarre no cambia; afuera baja en forma cuadrática (20 % a 50 °C de la ventana).
- **Desgaste por rueda**: proporcional a la energía de deslizamiento (MJ) según el compuesto, +5 % por cada °C pasado de la ventana; gastado del todo pierde un 15 % de agarre. "Volver a la pista" (R) no cambia los neumáticos; Reiniciar sí (juego nuevo).
- **HUD**: a la izquierda del tablero, el compuesto (círculo con su color y letra) y las 4 ruedas con °C y desgaste, pintadas celeste (fría), verde (en la ventana) o roja (pasada). En el panel F3 cada rueda suma una franja con la temperatura y el desgaste.
- **Verificación** (física a 60 Hz; temperatura y desgaste fijos durante cada medición):

| Agarre | Factor | Frenada 180 → 0 km/h | Curva a 120 km/h |
|---|---|---|---|
| Medio a 90 °C, nuevo | 1,000 | 55,6 m | 1,83 g |
| Blando a 90 °C | 1,025 | **54,2 m** | **1,88 g** |
| Duro a 100 °C | 0,975 | 57,0 m | 1,79 g |
| Medio frío (30 °C) | 0,872 | 63,9 m | 1,61 g |
| Duro frío (50 °C) | 0,879 | 63,3 m | 1,64 g |
| Medio pasado (145 °C) | 0,950 | 58,3 m | 1,74 g |
| Blando pasado (130 °C) | 0,974 | 57,3 m | 1,77 g |
| Medio gastado 50 % / 100 % | 0,925 / 0,850 | 60,4 / 65,3 m | 1,71 / 1,60 g |

| Calor (medio, desde 90 °C) | Delanteras | Traseras |
|---|---|---|
| Largada a fondo 3 s **sin TC** | 89 °C | **131 °C**, 1,7 % gastadas |
| Largada a fondo 3 s con TC 3 | 89 °C | 91 °C |
| Frenada 180 → 0 sin ABS (bloqueadas) | 103 °C, 0,6 % | 105 °C, 0,6 % |
| Frenada 180 → 0 con ABS | 90 °C, 0,1 % | 93 °C, 0,2 % |
| Trompo con freno de mano a 100 km/h | 90–91 °C | 96–100 °C, 0,4 % |

| Tanda de 9 vueltas con piloto automático exigente* | Vuelta 2 | Vuelta 5 | Vuelta 9 | Traseras (vuelta 9) | Gastado por vuelta (traseras) |
|---|---|---|---|---|---|
| Blando | **1:30.367** | 1:30.783 | 1:30.933 | 116 °C (pasado) | 3,7 % |
| Medio | 1:30.783 | 1:30.683 | 1:30.900 | 116 °C | 1,5 % |
| Duro | 1:31.067 | 1:31.150 | 1:31.200 | 116 °C | 0,9 % |

  \*El piloto automático de siempre dobla a 0,7 g; para la tanda dobla a 1,1 g (1:30,7 la vuelta). Las delanteras quedan en 85–88 °C y las traseras en ~116 °C, porque el deslizamiento al acelerar las calienta más. El blando es el más rápido al principio, pero atrás se pasa de su ventana, se gasta casi el triple que el duro y en 7 vueltas pierde ~0,5 s; a la vuelta 9 ya va igual que el medio. El duro es el más lento pero casi no cambia. (La vuelta 1 no está en la tabla: arranca desde la largada, y ya antes de este paso era ~1,5 s más lenta.)
  Con el piloto automático de siempre y el medio: **1:42.450 / 1:41.150 / 1:41.017** (Paso 32: 1:42.483 / 1:40.983 / 1:40.917), sin salidas, golpes ni reinicios; batería en 82 %. Siguen igual las pruebas de los Pasos 25, 30 y 32 (0–100 en 2,78 s, frenada 61,0 m desde 192 km/h, 1,47 g a 60 km/h, tabla de frenadas con y sin ABS, ERS); a 120 km/h la curva da 1,84 g (1,82 g con la temperatura y el desgaste apagados: en esa prueba las traseras llegan algo calientes y gastadas de la aceleración anterior). Las largadas del Paso 31 se corren una tras otra con las mismas gomas y la primera es sin TC, así que ahora las siguientes salen con las traseras calientes: 0–100 en 3,40 / 3,37 / 3,20 / 2,82 s con TC 0 / 1 / 2 / 3. Capturas: `informes/capturas/paso33-neumaticos.png` (blando en tanda larga: delanteras en la ventana, traseras pasadas y gastadas, panel F3 abierto) y `paso33-modos.png` (elección del compuesto).
- **Cómo probar**: F5 → Jugar → en la tarjeta "Neumáticos" elegir con ← → → modo → piloto. En carrera, el panel de neumáticos (a la izquierda del tablero) arranca en 70 °C; en 1–2 vueltas las traseras pasan los 100 °C. Una largada sin TC (T hasta "SIN TC") las pone rojas. Con el duro, las primeras curvas se sienten con menos agarre (frío).

### Paso 34 — Combustible
- **Consumo** (`Fuel`, datos en `"fuel"` de `data/car.json`): el motor de combustión quema según la potencia que entrega, kg/s = P / (rendimiento 0,5 × 43 MJ/kg); sólo con una marcha puesta y sin cambio en curso, y lo que corta el control de tracción no se quema. A fondo, con 446 kW, son **20,7 g/s (75 kg/h)**, cerca del tope de 2026 (3000 MJ/h ≈ 70 kg/h). Tanque de 70 kg.
- **Peso**: `mass_kg` (800) pasa a ser el auto seco con el piloto; la masa del cuerpo es seco + combustible y se actualiza a medida que se quema (cada 0,05 kg), junto con la precarga de cada rueda (así el auto no se hunde con el tanque lleno). El tanque está sobre el centro de masa y no lo mueve.
- **Carga al salir**: en contrarreloj, lo justo para las vueltas elegidas + 1 de margen (0,6 kg por vuelta: 2,4 kg para 3 vueltas, 6,6 kg para 10); en práctica, 20 kg (~40 vueltas). Sin combustible se apaga la unidad de potencia: no empujan ni el motor ni el MGU-K, el motor cae a ralentí y frena ("¡SIN COMBUSTIBLE!").
- **HUD**: barra naranja debajo de los neumáticos con los kg y las vueltas que alcanzan (según la vuelta anterior); en el panel F3, una línea con los kg, el consumo por vuelta y la masa.
- **Verificación** (física a 60 Hz, neumáticos nuevos en cada medición):

| Carga | Masa | 0–100 / 0–160 / 0–180 km/h | Frenada 180 → 0 | Curva a 120 km/h |
|---|---|---|---|---|
| 1 kg | 801 kg | 2,78 / 4,43 / 5,00 s | 55,6 m | 1,83 g |
| 20 kg (práctica) | 820 kg | 2,85 / 4,52 / 5,08 s | 55,6 m | 1,82 g |
| 70 kg (lleno) | 870 kg | 2,85 / 4,55 / **5,17 s** | **56,4 m** | **1,80 g** |

| Vuelta con piloto automático (medio) | Vuelta 1 | Vuelta 2 | Vuelta 3 | Consumo por vuelta | Traseras (vuelta 3) |
|---|---|---|---|---|---|
| 5 kg | 1:42.467 | 1:41.083 | 1:41.033 | 0,47–0,51 kg | 112–113 °C, 4,4 % gastadas |
| 70 kg | 1:42.417 | 1:41.050 | 1:41.067 | 0,50–0,54 kg | 117 °C, 4,6 % gastadas |

  El peso extra se nota en la aceleración arriba de 100 km/h, en la frenada y en la curva, pero **con el piloto automático la vuelta casi no cambia**: dobla a 0,7 g y frena con una distancia fija, así que no usa el agarre de más que pierde, y en las rectas largas de Bakú pasa mucho tiempo en el limitador de 8ª (~194 km/h). Con 70 kg los neumáticos calientan y se gastan un poco más. El consumo por vuelta (~0,5 kg) es bajo comparado con un F1 real (~1,5 kg en 5 km) porque la potencia media de la vuelta es baja por lo mismo. Hasta 0–100 casi no cambia: en la largada manda la tracción, que también crece con el peso. Sin combustible (con 0,05 kg) se apagó a los 5 s y 177 km/h, y en 10 s bajó a 78 km/h.
  La práctica (con 20 kg) es la escena de las pruebas viejas: siguen igual o casi (0–100 en 2,78 s, frenada 60,9 m desde 192 km/h, 1,47 / 1,82 g; tabla de frenadas del Paso 30 a 62,4 m con ABS; ERS 0–185 en 4,95 s en Ataque) y la vuelta: **1:42.367 / 1:41.133 / 1:41.100**, sin salidas ni golpes. Capturas: `informes/capturas/paso34-combustible.png` (acelerando con 3,6 kg, 16 g/s, panel F3) y `paso34-sin-combustible.png`.
- **Cómo probar**: F5 → Jugar → contrarreloj. La barra naranja bajo los neumáticos muestra los kg y las vueltas que alcanzan (en la vuelta 1 según la estimación, después según la vuelta anterior). Con F3 se ve la masa bajar.

### Paso 35 — Setup del auto
- **Ajustes** (`CarSetup`, rangos, descripciones y efectos en `data/setup.json`; lo elegido se guarda en `user://setup.json`): alerón delantero y trasero (1–11), altura del piso (−20 a +10 mm), resortes delanteros y traseros (1–9), barras delantera y trasera (1–9), presión delantera y trasera (20–26 psi) y relación final (2,40–3,30). `CarSetup.derive()` los pasa a parámetros físicos sobre los valores base de `car.json`; **con todo en su default el auto es exactamente el de antes**.
- **Efectos**:
  - Alerones: cada paso cambia 5 % la carga de su eje (el reparto se mueve solo: con el delantero en 11 la carga queda 49,5 % adelante) y el arrastre (1 % el delantero, 4 % el trasero).
  - Altura: cada mm más abajo suma 0,6 % de carga (efecto suelo) sin arrastre. El auto baja de verdad (el resorte tiene menos largo de reposo, `CarWheel.rest_length`). El piso queda a 40 mm + la altura; si la suspensión de un eje se comprime más que eso (carga aerodinámica, frenadas, pianos) **el piso toca**: la carga cae hasta 30 % a 5 mm de profundidad (`CarController.floor_factor()`) y suena el roce.
  - Resortes: rigidez × 0,7–1,3 (el amortiguador acompaña con × √factor); no cambian la altura con el auto quieto (precarga), sí cuánto se hunde con la carga. Barras: × 0,4–1,6; más barra en un eje = ese eje se lleva más transferencia en curva y agarra menos.
  - Presiones: cada psi debajo de 23 suma 0,5 % de agarre y 8 % del calor de rodar (`TyreCompounds`).
  - Relación final: cambia todas las marchas; con 2,40 el limitador en 8ª corta a 248 km/h en lugar de 198.
- **Dónde**: en el menú, la tarjeta "Setup del auto" debajo de los neumáticos (muestra lo que se cambió) abre la pantalla de setup; en práctica, también desde la pausa (al cerrarla el auto vuelve a boxes con el setup nuevo; los neumáticos y el combustible siguen). En contrarreloj no se puede tocar desde la pausa (parque cerrado). Cada fila muestra lo que cambia (ClA del eje, mm del piso, kN/m, % de agarre, velocidad máxima) y abajo va la descripción del ajuste y el resultado: ClA, CdA, reparto de la carga y velocidad máxima. En el panel F3, una línea con la altura del piso en cada eje ("¡TOCA!" con la carga que queda).
- **Verificación** (física a 60 Hz, 20 kg de combustible, neumáticos nuevos; la curva es a fondo de dirección manteniendo la velocidad, y en esta prueba el auto es subvirador: manda el agarre del eje delantero):

| Setup | ClA / CdA / carga adelante | Frenada 200 → 0* | Curva 120 / 160 km/h | Otros |
|---|---|---|---|---|
| Por defecto | 3,20 / 1,57 / 44 % | 61,2 m | 1,82 / 2,08 g | piso mín. 16 / 14 mm frenando |
| Alerón delantero 11 | 3,55 / 1,65 / 49,5 % | 60,2 m | **1,89 / 2,20 g** | |
| Alerón delantero 1 | 2,85 / 1,49 / 37 % | 62,2 m | 1,74 / 1,93 g | |
| Alerón trasero 11 | 3,65 / 1,88 / 39 % | **58,5 m** | 1,82 / 2,06 g | más estable, no gira más |
| Alerón trasero 1 | 2,75 / 1,26 / 51 % | 63,5 m | 1,82 / 2,07 g | |
| Altura −15 mm | 3,49 / 1,57 / 44 % | 60,0 m | 1,86 / 2,14 g | **toca** frenando (−1 mm, carga 94 %) |
| Altura −15 mm, resortes 9 / 9 | 3,49 / 1,57 / 44 % | 59,7 m | 1,86 / 2,14 g | no toca (piso mín. 5 / 4 mm) |
| Altura +10 mm | 3,01 / 1,57 / 44 % | 61,9 m | 1,80 / 2,04 g | |
| Barras 9 adelante / 1 atrás | igual | 60,9 m | 1,74 / 1,99 g | más subviraje |
| Barras 1 adelante / 9 atrás | igual | 60,9 m | **1,91 / 2,15 g** | gira más (deriva atrás 3,8° contra 2,8°) |
| Presiones 20 / 20 psi | igual | 59,9 m | 1,85 / 2,10 g | |
| Presiones 26 / 26 psi | igual | 61,8 m | 1,79 / 2,05 g | |
| Relación final 2,40 | igual | 65,0 m (desde 200) | igual | 0–100 2,68 s, **0–200 5,82 s**, máx. 248 km/h |
| Relación final 3,30 | igual | 52,5 m (desde 173) | igual | 0–100 2,95 s, máx. 180 km/h |

  \*Con la caja de serie el auto no llega a 200 km/h (corta a 192): la frenada es desde ahí.

| Vuelta con piloto automático que aprovecha la carga* | Vuelta 2 | Máx. | Piso |
|---|---|---|---|
| Por defecto | 1:31.300 | 193 km/h | no toca (mín. 17 / 12 mm) |
| Relación final 2,70 | 1:30.550 | 215 km/h | no toca |
| Relación final 2,40 | **1:29.667** | 243 km/h | **toca atrás** al final de las rectas (237 cuadros) |
| 2,40 + alerón trasero 3 | 1:29.717 | 243 km/h | no toca |
| 2,40 + alerón trasero 9 | 1:29.600 | 243 km/h | toca atrás (497 cuadros) |
| Altura −10 mm | 1:31.300 | 193 km/h | no toca (mín. 0,6 mm atrás) |

| Tanda de 3 vueltas (medio) | Vuelta 3 | Traseras | Gastado por vuelta (traseras) |
|---|---|---|---|
| 23 psi (por defecto) | 1:31.350 | 115 °C (en la ventana) | 1,5 % |
| 20 psi | 1:31.167 | **127 °C (pasado)** | 2,1 % |
| 26 psi | 1:31.650 | 106 °C | 1,5 % |
| Duro con 20 / 21 psi | 1:31.483 | 124 °C (en su ventana) | 0,9 % |

  \*El piloto automático de siempre dobla a 0,7 g fijos y no ve la carga aerodinámica; para estas vueltas dobla al 60 % del agarre con la carga del ClA del setup (1:31,3 la vuelta). **Lo que más rinde en Bakú es alargar la caja**: con 2,40 la vuelta baja 1,6 s y el auto llega a 243 km/h; ahora sí rinden el modo recta y el ERS en las rectas. Pero a esa velocidad la carga aerodinámica hunde la cola y el piso toca atrás: hay que sacar alerón trasero, subir el auto o endurecer los resortes traseros. Los alerones casi no cambian la vuelta del piloto automático (±0,1 s; dobla con margen y no aprovecha el balance), pero sí el auto en la curva de prueba. Bajar el piso 10 mm tampoco cambia la vuelta del piloto automático y queda a 0,6 mm de tocar. Con menos presión las traseras se pasan de la ventana del medio y se gastan más; al duro, que cuesta calentar, le sirve.
  Con el setup por defecto siguen exactamente igual las pruebas de los Pasos 25–34 (0–100 en 2,78 s, frenada 60,9 m desde 192 km/h, 1,47 / 1,82 g; ABS 62,4 m; largadas 3,40 / 3,45 / 3,20 / 2,80 s; ERS 0–185 en 4,95 s en Ataque; combustible 20,7 g/s y la tabla de cargas) y la vuelta con el piloto automático de siempre: **1:42.383 / 1:41.017 / 1:41.050**, sin salidas ni golpes. Guardado: sin archivo usa los defaults, los valores fuera de rango van al paso más cercano (−12 mm → −10 mm, relación 9 → 3,30), los extremos no dan la vuelta y un archivo con basura no rompe nada. Desde la pausa: el setup se aplica, el auto vuelve a boxes, el velocímetro pasa a escala de 260 km/h y abrir y cerrar sin cambiar nada no lo mueve. Capturas: `informes/capturas/paso35-menu-setup.png` (pantalla de setup con caja larga), `paso35-modos.png` (tarjeta del setup), `paso35-piso-toca.png` (−20 mm con resortes blandos: frenando a 185 km/h el piso toca atrás, la carga queda al 70 % y el panel F3 lo muestra) y `paso35-pausa-setup.png`.
- **Cómo probar**: F5 → Jugar → tarjeta "Setup del auto": ← → cambia cada ajuste; abajo se ve cómo cambian ClA, CdA, el reparto y la velocidad máxima. Probar relación final 2,40 en práctica: en la recta principal se pasa de 240 km/h. Con F3 abierto y la altura en −20 mm con resortes blandos, el piso toca ("¡TOCA!") y se oye el roce. En práctica, Esc → "Setup del auto" cambia el setup sin volver al menú.

### Paso 36 — Daños
- **Qué se rompe** (`CarDamage`, datos en el bloque `"damage"` de `car.json`): la salud del alerón delantero (0–1) y un pinchazo por rueda. En cada cuadro con contacto contra un muro (`_integrate_forces()`) se juntan los puntos de contacto en coordenadas del auto con su golpe (velocidad perdida / `shake_wall_speed`, 0–1):
  - **Alerón**: los golpes con la trompa (z < −2,3 m) le sacan 2 × (golpe − 0,25) de salud, con el golpe más fuerte del cuadro. Por debajo de 0,25 no pasa nada; la vuelta con el piloto automático no tiene golpes > 0,15. Con menos de 25 % se considera **roto** y desaparece; dañado se ve caído e inclinado.
  - **Pinchazo**: un golpe > 0,3 a menos de 0,7 m (vista de arriba) de una rueda la pincha. También pincha un neumático **gastado del todo** (desgaste ≥ 100 %, Paso 33).
- **Efectos**:
  - Alerón: la carga del eje delantero × (1 − 0,7 × daño), encima del setup (`get_cla()` y el reparto `get_aero_balance()`; no se tocan `cla` ni `aero_balance`). Roto: ClA 3,20 → 2,21 y la carga adelante 44 → 19 %: subvira mucho.
  - Pinchazo: μ de esa rueda × 0,35, 1500 N de arrastre (como par de freno sobre esa rueda) y la rueda 35 mm más baja (`rest_length` y el dibujo). El auto tira para el lado pinchado.
- **Reparar**: R (volver a boxes) repara todo y cambia los neumáticos gastados del todo por uno nuevo del mismo compuesto (los demás siguen como estaban). Volver a boxes con un setup nuevo desde la pausa también repara. Los daños están siempre activos (no hay opción).
- **HUD**: aviso al dañarse ("Alerón delantero dañado: 63 %", "¡ALERÓN DELANTERO ROTO! · R: boxes", "¡PINCHAZO! Neumático trasero derecho · R: boxes"). En el `TyrePanel`, una barra con la salud del alerón arriba (verde sano; dañado, de amarillo a rojo) y la rueda pinchada en bordó con "PINCH.". En el panel F3, la línea "Daños: alerón % · pinchazos"; para que entre, las dos líneas de transferencia quedaron en una.
- **Verificación** (física a 60 Hz, 20 kg de combustible, neumáticos medios nuevos):

| Choque contra el muro de la recta | 5° | 10° | 20° | 45° | 90° |
|---|---|---|---|---|---|
| 100 km/h | nada | nada | nada (golpe 0,16) | alerón 63 % + pinchazo TD | alerón roto |
| 150 km/h | nada | nada | alerón 27 % + pinchazo DD | alerón 20 % | alerón roto |
| 200 km/h | nada | pinchazo TD (golpe 0,35) | alerón 98 % | alerón roto | alerón roto |

| Daño | ClA / carga adelante | 0–160 | Frenada 160 → 0 | Curva 120 / 160 km/h |
|---|---|---|---|---|
| Sano | 3,20 / 44 % | 4,43 s | 46,7 m, gira 0,5° | 1,82 / 2,07 g |
| Alerón 50 % | 2,71 / 34 % | 4,45 s | 48,1 m | 1,71 / 1,87 g |
| Alerón roto | 2,21 / 19 % | 4,45 s | 49,5 m | 1,58 / 1,66 g |
| Pinchazo delantero izquierdo | 3,20 / 44 % | 4,92 s* | 54,6 m, gira −9,7° | 1,55 / 1,74 g |
| Pinchazo delantero derecho | igual | 4,92 s* | 54,5 m, gira +9,6° | **1,14 / 1,27 g** (rueda de afuera) |
| Pinchazo trasero izquierdo / derecho | igual | **7,02 s*** | 54,2 m, **trompo** (gira ∓117°) | trompo |

  \*Corrigiendo con el volante para ir derecho (hasta 0,04 de volante con una delantera pinchada, 0,14 con una trasera). La frenada se mide sin tocar el volante: con una trasera pinchada el auto hace un trompo, y en la curva también (la prueba no corrige).
  Con el control de tracción la trasera pinchada no patina (κ 0,09): el TC limita el par de las dos traseras, por eso el 0–160 tarda 7 s. Desgaste: un neumático trasero derecho al 99,95 % acelerando se pincha (aviso y "PINCH."); con R queda nuevo, sin pinchazo y las 4 ruedas a la altura de reposo. **Sin daños nada cambió**: vuelta con el piloto automático de siempre 1:42.383 / 1:41.017 / 1:41.050 sin daños, salidas ni golpes. En la prueba del Paso 25 el choque a 90° da golpe 0,67 en lugar de 1,00 porque el auto ya llega con el alerón dañado del choque a 20° (la prueba no repara entre choques); reparando antes de cada choque da 1,00 como siempre. Capturas: `informes/capturas/paso36-choque.png` (de trompa a 100 km/h y 45°: alerón 63 %, pinchazo trasero derecho, barra del alerón y panel F3) y `paso36-aleron-pinchazo.png` (alerón al 40 %, caído, y la delantera izquierda pinchada más baja).
- **Cómo probar**: F5 → Jugar → práctica. Pegar de trompa contra un muro a más de ~100 km/h: aparece el aviso, la barra del alerón baja y el auto subvira. Un golpe con la rueda contra el muro la pincha: el auto tira para ese lado. R repara todo. Con F3 se ve la línea "Daños".
