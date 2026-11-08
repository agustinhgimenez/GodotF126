# GodotF126 — ROADMAP (versión pro)

Desarrollo iterativo e incremental: **un paso por vez**, y cada paso termina con algo jugable que se prueba abriendo Godot 4.7 y apretando F5.

Los pasos están agrupados en **fases**. El orden prioriza primero lo que más cambia la sensación de manejar un F1 (motor, caja manual, tablero, cockpit), después la física de simulador y recién después el contenido (modos, rivales, más pistas).

## Hitos

| Hito | Se alcanza al terminar | Qué se puede mostrar |
|---|---|---|
| **H1 — Demo de cursada** ✅ | Paso 24 | Elegir escudería/piloto, caja manual, cockpit con volante y manos, sonido, vuelta cronometrada, resultado |
| **H2 — Simulador** ✅ | Paso 38 | Física de neumáticos, aero activa 2026, ERS, setup, telemetría para entrenar |
| **H3 — Juego completo** ✅ | Paso 52 | Rivales con IA, carrera con largada, fantasma, replays |
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

## Fase D — Física de simulador (cierra H2) ✅

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
| 37 | Soporte de **joystick y volante** (acelerador y freno analógicos, vibración); remapeo de controles | ✅ |
| 38 | Ayudas de manejo: línea de trazada ideal con zonas de frenado en color | ✅ |

## Fase E — Telemetría y entrenamiento ✅

| Paso | Contenido | Estado |
|---|---|---|
| 39 | Registro de telemetría por vuelta: velocidad, RPM, marcha, acelerador, freno, dirección, posición | ✅ |
| 40 | **Delta en vivo** contra la mejor vuelta (verde / rojo) en HUD y volante | ✅ |
| 41 | Pantalla de análisis: gráficos contra distancia, comparando dos vueltas | ✅ |
| 42 | Exportación a CSV | ✅ |
| 43 | **Auto fantasma** de la mejor vuelta | ✅ |

## Fase F — Rivales y carrera (H3) ✅

| Paso | Contenido | Estado |
|---|---|---|
| 44 | IA que sigue la trazada con velocidad objetivo según curvatura | ✅ |
| 45 | IA con niveles de dificultad, defensa y adelantamientos | ✅ |
| 46 | Colisiones entre autos y penalizaciones | ✅ |
| 47 | Clasificación y carrera con la **grilla 2026 completa** (22 autos) | ✅ |
| 48 | Pit lane con limitador de velocidad y paradas en boxes | ✅ |
| 49 | Estrategia: cambio de compuesto, radio del ingeniero | ✅ |
| 50 | Banderas amarilla y azul, **Safety Car** | ✅ |
| 51 | **Replays** con cámaras de TV | ✅ |
| 52 | Pantalla de resultados de carrera con puntos | ✅ |

## Fase G — Contenido extra

| Paso | Contenido | Estado |
|---|---|---|
| 53 | Generador de pistas por puntos de control, reutilizable para otros circuitos | ✅ |
| 54 | Segunda pista | ✅ |
| 55 | Modo campeonato con varias carreras | ✅ |
| 56 | Lluvia y pista mojada | ⏳ Siguiente |

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
- **Force feedback**: Godot 4 soporta vibración de gamepad, pero no force feedback real de volante. Si se quiere, hace falta un plugin externo. Evaluado en el Paso 37: quedó sólo la vibración (`Input.start_joy_vibration()`, que en muchos volantes no hace nada); force feedback real queda fuera del alcance.
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

### Paso 37 — Joystick, volante y controles
- **Mando por defecto** (`data/input.json`, distribución Xbox de SDL; las teclas siguen en `project.godot`): RT acelera y LT frena (analógicos), palanca izquierda dobla, RB / LB marchas, A adelantamiento, X modo recta, Y cámara, Back volver a la pista, L3 freno de mano, R3 panel F3, cruceta ↑ ERS / ↓ control de tracción / ← → reparto de frenada, **Start pausa**. La caja manual / automática no tiene botón por defecto. En los menús, A acepta, B vuelve y la cruceta navega: los `ui_*` de Godot 4.7 sólo traían teclas en aceptar y volver. Corriendo, B no pausa (sólo Esc o Start), así se puede asignar a otra cosa.
- **Analógico**: el acelerador y el freno usan cuánto se aprieta el gatillo (zona muerta 5 %) y la dirección cuánto se mueve la palanca (zona muerta 8 %, ajustable de 0 a 30 %). **Curva de dirección**: giro = entrada^curva (lineal 1, suave 1,5, muy suave 2); con teclado no cambia nada. **Pedales de volante** que van de −1 (suelto) a 1 (a fondo): con "Pedales: Volante (−1 a 1)" se leen en todo su recorrido. Solo se activa en los mandos donde ese eje ya pasó por debajo de −0,5, así un gatillo suelto (en 0) nunca da medio pedal.
- **Vibración** (`ControllerRumble`, bloque `"rumble"` de `input.json`, intensidad 0–100 %): golpes contra el muro y daños en el motor grande, que se apaga en 0,35 / 0,6 s; el piso tocando en el motor grande; pianos, ABS soltando (pulsos a 12 Hz), ruedas patinando, rueda pinchada (según la velocidad) y limitador en el motor chico. Se corta en la pausa y al terminar la sesión. Godot no da force feedback de volante.
- **Asignar controles** (botón nuevo en el panel de Controles del menú y de la pausa; `BindingsPanel`): una fila por acción con su tecla y su control del mando. Enter (o A) espera la tecla / el botón / el eje nuevo. Para un eje hay que moverlo más de 0,5 desde donde estaba, así un pedal en reposo en −1 no cuenta solo; las acciones que no son analógicas solo aceptan botones. Esc cancela; a los 6 s se cancela sola; Supr deja la celda vacía. Lo asignado se saca de las otras acciones que lo usaban y se avisa. Debajo: pedales, zona muerta y curva de la dirección y vibración. "Por defecto" vuelve todo atrás. Se guarda en `user://settings.json` (`bindings`, solo lo cambiado); "Restablecer" de Opciones no toca los controles. Con un mando conectado, el tutorial de controles muestra sus botones en lugar de las teclas.
- **Panel F3**: en el chasis, el acelerador y el freno que pide el piloto (barras verde y roja) y una marca con el volante sobre el eje delantero.
- **Verificación** (sin mando físico: eventos del mando simulados con `Input.parse_input_event()`):

| Entrada | Resultado |
|---|---|
| RT 0,03 / 0,25 / 0,50 / 1,00 | acelerador 0 / 0,21 / 0,47 / 1,00 |
| Palanca −0,05 / −0,10 / −0,50 / −1,00 | dirección 0 / 0,02 / 0,46 / 1,00 (con zona muerta 20 %: −0,50 → 0,38) |
| Pedal de volante −1 / 0 / 0,5 / 1 | 0 / 0,47 / 0,74 / 1,00 |
| RT 100 / 60 / 30 % | 0–100 en 2,85 / 2,88 / 4,17 s (con 60 % manda la tracción) |
| LT 100 / 50 % desde 100 km/h | 23,0 m (89 cuadros con ABS) / 22,3 m (sin ABS) |
| Palanca a la mitad, curva lineal / muy suave | volante 0,46 / 0,21 |
| Vibración (chico, grande) | quieto (0, 0) · arranque sin TC (0,50, 0,30: patina y el piso toca 7 cuadros) · ABS (0,50 / 0,15 en pulsos) · piano (0,35, 0) · pinchazo a 57 km/h (0,25, 0,97 con el aviso) · golpe 0,6 → 0,57 y 0,29 a los 10 cuadros · al 50 % el piano 0,18 · en 0 nada · en la pausa (0, 0) |
| Start / Start / B corriendo / Esc / B en la pausa | pausa / sigue / no pausa / pausa / vuelve |

  Asignación: A a "acelerar" lo saca de "adelantamiento"; E a "acelerar" lo saca de "subir marcha". Se recarga igual de `user://settings.json` y un archivo con basura no rompe nada (teclas inválidas fuera, eje 99 → nada, curva 1,7 → 1,5, vibración 400 → 100). En la pantalla: tecla K, eje 2 (0,3 no alcanza, 0,8 sí → "Palanca der. ←"), un eje en una acción digital no cuenta, botón B, Esc cancela, Supr borra, a los 6,0 s se cancela sola y Esc vuelve al tutorial sin cerrar el panel (la pantalla mide 481 px de los 510 del panel). **Sin mando nada cambió**: vuelta con el piloto automático 1:42.383 / 1:41.017 / 1:41.050 sin salidas, golpes ni daños, y la prueba del Paso 25 igual (0–100 2,78 s, frenada 60,9 m, 1,47 / 1,82 g). Falta probarlo con un mando y un volante de verdad. Capturas: `informes/capturas/paso37-asignar.png` (esperando una tecla para "Subir marcha", freno de mano en B, vibración 75 %), `paso37-f3-analogico.png` (gatillo al 58 % y palanca a 0,40: barras y marca en el chasis) y `paso37-pausa-controles.png` (tutorial con el botón "Asignar controles").
- **Cómo probar**: conectar un mando antes de abrir el juego (o después: lo detecta solo). En el menú, Controles muestra sus botones; con la cruceta y A se navega. En la carrera, RT / LT de a poco y F3 para ver las barras. Controles → Asignar controles: Enter en una celda y apretar la tecla / botón / eje nuevo. Con un volante: "Pedales: Volante (−1 a 1)" y, en Opciones, la dirección sin asistencia.

### Paso 38 — Línea de trazada (cierra la Fase D y el hito H2)
- **Trayectoria** (`RacingLine`, bloque `"racing_line"` de `data/tracks.json`): se calcula al cargar la pista. Cada punto del centerline se corre de costado hacia la posición que minimiza la curvatura respecto de sus vecinos ((4 · vecinos a `span` − vecinos a 2 · `span`) / 6, primero con vecinos lejanos —24 puntos— y después cercanos —12, 6, 3—, 60 vueltas cada uno), sin pasar de media pista menos 1,5 m. Así sale abierta antes de la curva, toca el vértice y sale abierta, y en las chicanas va derecho. Tarda ~0,4 s, en la pantalla de carga.
- **Velocidad objetivo** por punto: la de curva con el agarre del auto, \(v = \sqrt{f\,\mu\,g / (\kappa - f\,\mu\,k_{aero})}\), con \(f = 0{,}8\), μ del neumático × el compuesto y la carga aerodinámica del setup, hasta la máxima del limitador. Después se recorre hacia atrás con la frenada (0,85 × el mismo agarre + arrastre). Se recalcula al cambiar el setup.
- **Dibujo**: una cinta de 1 m sobre el asfalto (`ArrayMesh`, sin sombras, 5 cm arriba) con un shader (`shaders/racing_line.gdshader`) que la colorea según la velocidad del auto contra la objetivo de cada punto: **verde** (sobra margen), **amarillo** (levantar) y **rojo** (frenar: vas más rápido de lo que se puede ir ahí). El rojo aparece justo donde la curva de frenada cruza la velocidad actual, o sea en el punto de frenada. Se ve de 12 m atrás a 280 m adelante, con fundido al final.
- **Modos** (opción `racing_line` en `user://settings.json`, por defecto "sólo frenadas"; tecla **L**, acción nueva `racing_line`, asignable desde "Asignar controles"): completa → sólo frenadas (únicamente las partes amarilla y roja) → no. El HUD avisa "Línea de trazada: …". En el tutorial de controles, cámara y F3 comparten fila para que entre la de la L (509 de 510 px).
- **Verificación** (`paso38_line.gd`, 1.832 puntos):

| Prueba | Resultado |
|---|---|
| Cálculo de la trayectoria / velocidades | 407 ms (840 ms antes de guardar las posiciones en caché) / 21 ms |
| Desplazamiento máximo | 4,50 m (media pista − margen), 18 % de los puntos contra el margen |
| Radio mínimo por curva (15 curvas), centro → línea | promedio 16 → 23 m (×1,43); ej. 12 → 20 m, 14 → 23 m, 21 → 76 m (curva rápida) |
| Vuelta con piloto automático siguiendo la línea y sus velocidades | **1:18.450**, 0 salidas, 0 golpes, sin daños |
| La misma, por el centro y con esas velocidades | 1:25.217 (la línea vale 6,8 s) |
| Velocidades objetivo × 1,10 | 1:18.450 pero 6 salidas de pista: el 0,8 del agarre está cerca del límite |
| Color 15 m adelante del auto | frenando: rojo el 94 % del tiempo · acelerando: rojo el 5 % |
| 300 / 40 / 0 m antes de la curva más lenta (objetivo 151 / 139 / 50 km/h), a 80 / 140 / 190 km/h | verde-verde-rojo · verde-rojo-rojo · rojo-rojo-rojo |
| L desde "completa" / opción "off" | completa → sólo frenadas → no → completa · la cinta se oculta |

  **Sin la ayuda nada cambió**: vuelta con el piloto automático de siempre 1:42.383 / 1:41.017 / 1:41.050 sin salidas, golpes ni daños. Capturas: `informes/capturas/paso38-linea-completa.png` (T-cam a 191 km/h, el rojo empieza 17 m adelante), `paso38-solo-frenadas.png` (cámara TV a 174 km/h, sólo la zona de frenada en rojo hasta la curva) y `paso38-controles.png` (tutorial con la fila de la L).
- **Cómo probar**: F5 y práctica libre. Llegando a una curva la línea se pone roja donde hay que frenar; frenando hasta que deje de estar roja bajo el auto se entra a la velocidad justa. L cambia entre completa, sólo frenadas y apagada.

### Paso 39 — Telemetría por vuelta
- **Registro** (`TelemetryRecorder`, nodo `Telemetry` de la carrera; datos en `data/telemetry.json`): mientras corre el cronómetro guarda una muestra cada 0,05 s (20 por segundo) con tiempo de vuelta, **distancia desde la meta** siguiendo el trazado, velocidad, RPM, marcha, acelerador, freno y dirección que pide el piloto (los del Paso 37: teclado, gatillos o pedales) y posición (x, z). Cada vuelta es un `TelemetryLap` con un arreglo empaquetado por canal. Al cerrar la vuelta se agrega una última muestra con el tiempo exacto.
- **Vueltas**: se guardan las últimas 30 de la sesión, la última y la mejor válida (las inválidas por límites de pista quedan marcadas y no cuentan). La mejor vuelta válida de la pista se escribe en `user://telemetry_best_<pista>.json` (~90 kB) si es más rápida que la guardada, y se carga al empezar: es la referencia para el delta (Paso 40), los gráficos (41), el CSV (42) y el fantasma (43). Volver a la pista (R) descarta la vuelta en curso, igual que el cronómetro. Un archivo roto se ignora.
- **Pausa → Telemetría** (botón nuevo; los botones de la pausa bajaron de 54 a 46 px para que entren los 8): la vuelta que se está grabando, una tabla con las últimas 8 vueltas (tiempo, velocidad máxima / mínima / media, % del tiempo a fondo y frenando, cambios de marcha; la mejor resaltada y las inválidas en rojo con "inv.", más la guardada si es de otra sesión) y un gráfico de velocidad contra distancia de la última vuelta contra la mejor (o la anterior, si la última es la mejor), con una franja de acelerador y freno abajo.
- **Verificación** (`paso39_telemetry.gd`: 3 vueltas con el piloto que sigue la línea de trazada, la 2 invalidada a mano):

| Prueba | Resultado |
|---|---|
| Muestras por vuelta | 1.571 / 1.541 / 1.545 = tiempo / 0,05 + 2 (las esperadas), paso máximo 0,050 s |
| Distancia | de −3,6 m (el checkpoint de meta está antes de la línea) a 2.562,8 m (pista de 2.565,6 m), sin retrocesos, paso máximo 2,7 m |
| A los 30 s de la vuelta 1 | 841 m grabados / 842 m del auto · 107 / 108 km/h |
| Resumen de una vuelta | máx. 193 · mín. 50 · media 120 km/h · 69 % a fondo · 21 % frenando · marchas 3ª–8ª · 12.500 rpm |
| Vueltas 1:18.467 / 1:16.983 (inválida) / 1:17.167 | mejor = 3 (la 2 no cuenta), guardada la 3 |
| Archivo guardado y recargado | 90 kB, 1.545 muestras, misma velocidad (±0,006 km/h) en 5 distancias |
| Archivo roto / reinicio con 101 muestras | se ignora / vuelta en curso descartada, quedan 3 |
| Costo | 17 µs por muestra (0,33 ms por segundo de carrera) · resumen de 2.000 muestras 0,4 ms |

  La primera prueba encontró un error: en los primeros metros (antes de cruzar la línea) la distancia saltaba una vuelta entera de pista; ahora cada muestra toma la vuelta más cercana a la anterior. **Nada cambió en el manejo**: vuelta con el piloto automático de siempre 1:42.383 / 1:41.017 / 1:41.050 sin salidas, golpes ni daños. Capturas: `informes/capturas/paso39-pausa.png` (pausa con el botón Telemetría) y `paso39-telemetria.png` (tabla de 3 vueltas y gráfico de la 3 contra la 1).
- **Cómo probar**: F5, práctica libre, dar dos o tres vueltas y Esc → Telemetría.

### Paso 40 — Delta en vivo
- **Cálculo** (`LiveDelta`, nodo `LiveDelta` de la carrera; bloque `"delta"` de `data/telemetry.json`): cada cuadro, tiempo de la vuelta en curso menos el tiempo de la **referencia** en el mismo punto de la pista (interpolado por distancia en la telemetría del Paso 39). Negativo = más rápido. La referencia es la más rápida entre la mejor vuelta válida de la sesión y la guardada de la pista (`user://telemetry_best_<pista>.json`), y queda fija toda la vuelta. Suavizado de 0,15 s. Sin referencia (primera vuelta sin archivo guardado) no se muestra nada; un reinicio (R) lo borra.
- **Al cerrar la vuelta** queda 3 s el delta **final** (tiempo − tiempo de la referencia), igual al que se ve en vivo al cruzar la meta.
- **HUD**: caja debajo del cronómetro con el delta grande (verde si vas más rápido, rojo si más lento, gris con la vuelta invalidada), una barra que crece desde el centro (izquierda = ganando) hasta ±1 s y una flecha que dice si en este momento estás ganando (▼ verde) o perdiendo (▲ roja) tiempo.
- **Volante**: el "DELTA" de la pantalla, que antes sólo cambiaba al cerrar cada sector, ahora es el delta continuo, con los mismos colores (si no hay referencia sigue el de sectores).
- **Verificación** (`paso40_delta.gd`: piloto que sigue la línea; la vuelta 3 levanta al 85 % entre los 1.000 y los 1.400 m):

| Prueba | Resultado |
|---|---|
| Vuelta 1 sin referencia | 4.705 de 4.705 cuadros sin delta |
| Vuelta 2 (1:17.033) contra la 1 (1:18.417, salió de boxes) | −1,433 a los 500 m · −1,403 a 1.000 · −1,377 a 2.000 · final **−1,383** = 1:17.033 − 1:18.417 |
| Vuelta 3 (1:18.633) contra la 2, levantando de 1.000 a 1.400 m | −0,001 a 500 m · −0,017 a 1.000 · **+1,464** a 1.400 · +1,637 a 2.000 · final **+1,600** = 1:18.633 − 1:17.033 |
| En vivo al cruzar la meta / final | −1,377 / −1,383 y +1,593 / +1,600 (lo que queda es el suavizado) |
| Salto máximo entre cuadros | 0,027 s (sin saltos) |
| Referencia para la vuelta 4 | la 2 (la 3 fue más lenta) |
| Reinicio (R) | delta y referencia borrados |
| Escena nueva | la vuelta 1 ya compara contra la guardada |
| Costo | 0,4 µs por cálculo |

  **Nada cambió en el manejo**: vuelta con el piloto automático de siempre 1:42.383 / 1:41.017 / 1:41.050 sin salidas, golpes ni daños. Capturas: `informes/capturas/paso40-delta-verde.png` (vuelta 2, −1,402 ganando), `paso40-delta-rojo-volante.png` (cockpit levantando: +1,124 con la flecha roja en el HUD y en el volante) y `paso40-final.png` (vuelta 3 terminada: FINAL +1,600).
- **Cómo probar**: F5, práctica libre, una vuelta limpia y en la siguiente mirar la caja debajo del cronómetro (o la pantalla del volante en el cockpit).

### Paso 41 — Pantalla de análisis
- **Dónde**: Pausa → Telemetría → **Análisis** (botón nuevo). Es a pantalla completa (`TelemetryAnalysis`) y Esc vuelve a la tabla de telemetría.
- **Dos vueltas, A y B** (botones arriba; ← → o Enter cambian la vuelta): las de la sesión y la mejor guardada de la pista. Al abrir, A = la vuelta válida más rápida y B = la última (o la anterior, si la última es la más rápida).
- **Gráficos contra la distancia desde la meta** (`TelemetryPlots`), uno debajo del otro, A en el color del equipo y B en blanco: velocidad, **delta acumulado de B contra A** (verde si B va adelante, rojo si va atrás; es el mismo cálculo del delta en vivo), acelerador, freno, marcha, dirección y RPM. Líneas de los sectores (S2 a 855 m, S3 a 1.711 m) y eje cada 500 m.
- **Cursor**: con el foco en los gráficos, ← → lo mueven de a 10 m; con el mouse sigue al puntero. A la derecha, la tabla con los valores de A, B y B − A en el cursor (tiempo, velocidad, acelerador, freno, marcha, dirección, RPM).
- **Mapa** (`TelemetryTrackMap`): la pista vista desde arriba con el recorrido de B pintado de **verde donde gana tiempo** contra A, **rojo donde pierde** (el delta cambia más de 0,02 s en ~1 s) y gris donde van parejas, más un punto por vuelta en la posición del cursor.
- **Verificación** (`paso41_analysis.gd`: 3 vueltas con el piloto que sigue la línea; la 3 levanta al 85 % entre 1.000 y 1.400 m):

| Prueba | Resultado |
|---|---|
| Análisis sin vueltas | aviso "Todavía no hay vueltas completas", sin gráficos, foco en Volver |
| Al abrir | A = vuelta 2 (1:17.033, la más rápida), B = vuelta 3 (1:18.750) |
| Delta B − A | −0,031 a 500 m · +0,049 a 1.000 · +1,062 a 1.200 · **+1,624 a 1.400** · +1,712 a 2.000 · **+1,717 al final = 1:18.750 − 1:17.033** |
| Mapa | 392 muestras "pierde", **89 % entre 950 y 1.500 m** (con el umbral de 0,004 s eran 632 y 58 %: ruido) · 30 "gana" · 1.155 parejas |
| Cursor | 1.000 m + 3 × → = 1.030 m · mouse en x = 419 px → 1.250 m |
| Tabla a 1.250 m | velocidad 149 / 137 (−12) · marcha 8 / 7 · delta +1,173 |
| Selector B con ← | vuelta 3 → vuelta 2 |
| Esc / Esc | vuelve a Telemetría (foco en Análisis) / al menú de la pausa |
| Costo | delta de 1.577 muestras en 4,5 ms (al cambiar de vuelta) |

  La primera captura mostró la pausa por detrás: el fondo tenía tamaño cero (`set_anchors_preset` sin offsets); ahora usa `set_anchors_and_offsets_preset`. **Nada cambió en el manejo**: vuelta con el piloto automático de siempre 1:42.383 / 1:41.017 / 1:41.050. Capturas: `informes/capturas/paso41-analisis.png` (vuelta 3 contra la 2 con el cursor a 1.250 m: el delta sube donde levantó y el mapa lo marca en rojo) y `paso41-telemetria-boton.png` (tabla con el botón Análisis).
- **Cómo probar**: F5, práctica libre, dar dos o tres vueltas, Esc → Telemetría → Análisis; mover el mouse sobre los gráficos.

### Paso 42 — Exportación a CSV
- **Dónde**: en la pantalla de análisis (Pausa → Telemetría → Análisis), dos botones nuevos: **CSV A y B** (las dos vueltas elegidas; una sola si A = B) y **CSV todas** (las de la sesión y la mejor guardada de antes). Arriba aparece un aviso con el nombre del archivo y la carpeta real.
- **Archivos** (`TelemetryCsv`): en `user://telemetria/` (en Windows, `%APPDATA%\Godot\app_userdata\GodotF126\telemetria\`), con nombre `<pista>_<fecha>_<hora>_<vueltas>.csv`, por ejemplo `baku_v2_2026-11-06_13-55-22_A-v2_B-v3.csv` o `..._todas.csv`. Si ya existe (dos exportaciones en el mismo segundo) se agrega `_2`, `_3`…
  - **Datos**: una fila por muestra (cada 0,05 s) con `vuelta, origen (sesion / guardada), valida (1 / 0), tiempo_s, distancia_m, velocidad_kmh, rpm, marcha, acelerador, freno, direccion, x_m, z_m`. Mismos decimales que el archivo de la mejor vuelta (tiempo 3, distancia y velocidad 2, pedales y dirección 3, RPM y marcha enteros).
  - **Resumen** (`..._resumen.csv`): una fila por vuelta con compuesto, tiempo, largo de la pista, muestras, velocidad máxima / mínima / media, % a fondo, % frenando, cambios de marcha y RPM máximas.
- **Formato**: los números se escriben siempre igual, sin depender del idioma del sistema. Por defecto punto decimal y coma entre columnas (Python, MATLAB, R, Excel en inglés). Con `"decimal": ","` en el bloque `csv` de `data/telemetry.json` el separador pasa a `;`, que es lo que abre directo Excel en español. También se puede elegir otra carpeta, otro separador (por ejemplo tabulador) o no escribir el resumen.
- **Verificación** (`paso42_csv.gd`: las mismas 3 vueltas del Paso 41; relee cada archivo con `FileAccess.get_csv_line()` y lo compara con la telemetría en memoria; borra todo lo que escribe):

| Prueba | Resultado |
|---|---|
| Números | `1.500`, `0.000` (sin "−0"), `12345.68` (sin separador de miles), marcha `8` |
| Configuración | coma decimal → separador `;` y `1,500` · separador inválido → `,` · tabulador sí · decimal inválido → `.` |
| Sin vueltas | aviso "No hay vueltas para exportar", ningún archivo |
| CSV A y B (vueltas 2 y 3) | 3.120 filas = encabezado + 1.542 + 1.577 muestras, 13 columnas en todas, vuelta / origen / válida bien; **todos los valores iguales a la telemetría salvo el redondeo** (error máximo medio decimal) · 222 kB en 80 ms |
| Resumen | vuelta 2: 77,033 s, 1.542 muestras, 192,7 / 49,7 / 119,9 km/h, 68,8 % a fondo, 20,7 % frenando, 96 cambios · vuelta 3: 78,750 s, mínima 43,2 km/h (levantó) |
| Mismo segundo otra vez | `..._A-v2_B-v3_2.csv` |
| A = B | un archivo de una vuelta (`..._A-v2.csv`) |
| CSV todas, con la guardada de antes | 4 vueltas (3 de la sesión + "guardada"), 6.234 filas, todo igual · 150 ms |
| Coma decimal, sin resumen | un solo archivo, `2;sesion;1;4,950;214,22;64,92;8064;4;0,000;…`, releído con `;` sin diferencias |

  El primer aviso cortaba la ruta larga a mitad del nombre; ahora va en dos líneas (archivo y carpeta). **Nada cambió en el manejo**: vuelta con el piloto automático de siempre 1:42.383 / 1:41.017 / 1:41.050. Captura: `informes/capturas/paso42-exportar.png` (análisis de la vuelta 3 contra la 2 recién exportado, con el aviso arriba).
- **Cómo probar**: F5, práctica libre, dar dos vueltas, Esc → Telemetría → Análisis → **CSV A y B**, y abrir el archivo de la carpeta que muestra el aviso (en Excel en español, poner `"decimal": ","` en `data/telemetry.json`).

### Paso 43 — Auto fantasma
- **Qué es**: un auto semitransparente (`GhostCar`) que repite la **vuelta de referencia del delta en vivo**, o sea la más rápida entre la mejor válida de la sesión y la guardada de la pista, fija al empezar cada vuelta. Va **por tiempo**: con el cronómetro de la vuelta en curso toma dónde estaba la referencia en ese mismo segundo. Si se escapa adelante, ahí se está perdiendo tiempo; si queda atrás, se está ganando. Es la misma información que el delta, pero se ve en la pista.
- **Cómo se ve**: copia las mallas del auto (13 piezas: carrocería en el color del equipo aclarado, el resto oscuro) con un material transparente sin sombras, al 50 % de opacidad. **No choca** (no tiene física). A menos de 3 m del auto desaparece y hasta los 12 m se va haciendo visible, así no tapa la vista cuando va encima (en cockpit) ni parpadea. Se ve también en los espejos.
- **Cuándo no está**: sin vuelta de referencia (la primera vuelta de una pista nueva), antes de cruzar la meta, al volver a la pista con R (se descarta la vuelta) y cuando la referencia ya terminó su vuelta.
- **Tecla H** (acción `ghost`, se puede reasignar): lo muestra u oculta y lo guarda en la opción `ghost` de `user://settings.json`. Fila en el tutorial de controles y un consejo en la pantalla de carga. Opacidad, distancias y color en el bloque `ghost` de `data/telemetry.json`.
- **Telemetría con altura y rumbo**: el fantasma necesita la altura (la subida al castillo es de 12 m) y hacia dónde apunta el auto, y la telemetría sólo guardaba `x` / `z`. Se agregaron los canales `y` (m) y `yaw` (rumbo en rad), que también salen en el CSV (`y_m`, `rumbo_rad`). Una mejor vuelta guardada antes de este paso **se sigue cargando**: la altura sale del trazado en la distancia de cada muestra y el rumbo de la recta entre muestras vecinas.
- **Verificación** (`paso43_ghost.gd`: 3 vueltas con el piloto que sigue la línea, la 3 levanta al 85 % entre 1.000 y 1.400 m; después una escena nueva con la mejor vuelta en formato viejo):

| Prueba | Resultado |
|---|---|
| Formato viejo sin `y` / `yaw` | carga (faltan `y`, `yaw`); sin `x` no carga |
| Vuelta 1 (sin referencia) | fantasma oculto los 4.665 cuadros |
| Vuelta 2 (1:17.117) contra la 1 (1:18.467) | **siempre detrás** (4.582 de 4.582 cuadros), visible, nunca fuera de la pista, a ±0,03 m de la altura del trazado, rumbo a ≤ 24° del trazado (la línea ideal corta las curvas) |
| Vuelta 3 (1:18.700) contra la 2 | hasta los 1.000 m va **encima del auto** (misma manejada): desvanecido · 1.200 m: delta +0,957, fantasma **33 m adelante** · 1.400 m: +1,519, 33 m · 2.000 m: +1,590, 45 m · 2.500 m: +1,579, 62 m y ya cruzó la meta (oculto). La distancia es el delta por la velocidad (a 1.200 m: 0,96 s × ~125 km/h ≈ 33 m) |
| Mejor vuelta grabada | altura de −0,02 a 12,00 m (sube al castillo), rumbo de −π a π |
| Tecla H | sí → no (oculto, opción guardada en no) → sí |
| Volver a la pista (R) | oculto y sin referencia |
| Escena nueva con la mejor vuelta en formato viejo | carga como guardada; reconstruida contra lo grabado: altura media 0,009 m (máx 0,021), rumbo medio 0,7° (máx 3,7°); en la vuelta 1 aparece el fantasma de la guardada |
| Costo | 28 µs por cuadro (4 búsquedas binarias) |

  La primera corrida marcó errores de pose de 2 m y "fuera de la pista": era la prueba, que leía el fantasma antes de que se actualizara en ese cuadro y buscaba el punto de pista cercano desde el último donde lo había visto. Ahora el fantasma guarda con qué vuelta y en qué instante armó la pose. **Nada cambió en el manejo**: vuelta con el piloto automático de siempre 1:42.383 / 1:41.017 / 1:41.050; la prueba del Paso 42 sigue bien con las dos columnas nuevas. Capturas: `informes/capturas/paso43-fantasma.png` (cámara cercana en la vuelta 3, delta +0,520: el fantasma de la vuelta 2 doce metros adelante en la curva) y `paso43-fantasma-cockpit.png` (desde el cockpit, 15 m adelante).
- **Cómo probar**: F5, práctica libre, una vuelta limpia y en la siguiente buscar el auto transparente; levantar en alguna recta y verlo escaparse. H lo oculta.

### Paso 44 — IA que sigue la trazada
- **El piloto** (`AiDriver`, datos en `data/ai.json`): maneja un auto igual al del jugador (misma física de 4 ruedas, neumáticos, aero, ERS, combustible; setup por defecto, caja automática, ABS y TC 3) siguiendo la **línea de trazada del Paso 38**:
  - **Dirección**: apunta a un punto de la línea 10 m o 0,55 s adelante (lo que sea más) y gira proporcional al ángulo.
  - **Velocidad objetivo**: la de la línea un poco más adelante, que sale de la **curvatura** con el agarre del auto (μ × (g + carga aerodinámica)) y de la frenada hacia atrás desde cada curva. Pedales **proporcionales** al error: con el error en cero mantiene medio acelerador, a +1,5 m/s acelera a fondo, y frena desde 1 m/s de más (a fondo con 4 m/s).
  - **Ritmo** (`pace`, 0,5–1): baja la velocidad en curvas y frenadas, no en las rectas. Es la base de los niveles del Paso 45.
  - **Rescate**: si en 3 s avanza menos de 5 m por la pista, o va de contramano más de 2 s, vuelve a la línea (y esa vuelta no cuenta). Cuenta vueltas, tiempos, salidas de pista y golpes.
- **El auto de la IA** (`CarController.ai_controlled`): lee los pedales y la dirección de `ai_inputs` en lugar del teclado o el mando, no toma la cámara, no responde a las teclas (cámara, R, marchas…) y no suena. No tiene HUD, telemetría, delta ni fantasma; no cuenta para los límites de pista ni el cronómetro del jugador.
- **En práctica, tecla I** (acción `ai_rival`): suma un rival (el primer piloto de otro equipo: con Colapinto, Lando Norris en McLaren) 40 m detrás, sobre la línea y a la velocidad del jugador; otra vez I lo saca. En contrarreloj no hace nada. Fila en el panel de controles (junto a L y H, para que el panel siga entrando en la pausa) y un consejo en la pantalla de carga. Los autos chocan con la física normal; el contacto, las penalizaciones y no chocarse son de los Pasos 45 y 46.
- **Verificación** (`paso44_ai.gd`: la IA sola con el jugador congelado lejos y una cámara que la sigue; después el jugador con el piloto automático detrás de la IA):

| Prueba | Resultado |
|---|---|
| Auto de la IA | no toma la cámara, no suena, no lee teclas |
| Ritmo 1,0, 3 vueltas | **1:16.833** (saliendo de parado 40 m antes de la meta), **1:16.450, 1:16.517**; sin salidas, golpes ni rescates; a 4,6 m del centro como mucho |
| Curvas (11) | pasa a 53–75 km/h con objetivo de 50–70: **107 % de la objetivo** (como mucho 5 km/h más; la línea usa el 80 % del agarre, así que hay margen) |
| Ritmo 0,9, 1 vuelta | 1:20.100 (+3,58 s), curvas al **90 %** de las de ritmo 1,0, sin salidas ni golpes |
| De contramano | a los 2 s vuelve a la línea mirando bien |
| Tecla I | la saca y la vuelve a poner |
| Jugador detrás de la IA (larga 50 m adelante) | 25 s sin tocarse (mínimo 7,9 m entre centros), la IA sin salidas ni golpes |
| Costo | decisión de la IA 51 µs por cuadro; física **+2,8 ms por auto** (jugador solo 4,9 ms, con la IA 7,7 ms) |

  Para comparar: el piloto automático de las pruebas (todo o nada en los pedales) da ~1:17,0 en la misma línea; la IA, con pedales proporcionales, 1:16,5. La primera corrida marcó dos cosas que se corrigieron: el rescate por "casi quieto" no saltaba con el auto de contramano (moviéndose, pero para atrás), ahora mira cuánto avanza por la pista; y la fila nueva del panel de controles lo hacía de 536 px en un lugar de 510 (ahora 509). **El costo es un aviso para el Paso 47**: con 22 autos serían ~60 ms de física por cuadro; habrá que simplificar a los autos lejanos (menos pasos de física, sin desgaste ni temperatura, o un modelo cinemático sobre la línea) y medirlo en la PC del laboratorio. **Sin la IA nada cambió**: vuelta con el piloto automático de siempre 1:42.383 / 1:41.017 / 1:41.050. Capturas: `informes/capturas/paso44-ia.png` (la IA sola en la recta, cámara de seguimiento, sin HUD), `paso44-jugador-sigue.png` (el jugador a 170 km/h siguiendo a la IA, 21 m adelante) y `paso44-controles.png` (panel de controles con L · H · I).
- **Cómo probar**: F5, práctica libre, apretar I y dejarla pasar o seguirla.

### Paso 45 — IA con niveles de dificultad, defensa y adelantamientos
- **Niveles** (`data/ai.json` → `levels`; opción **"Nivel de la IA"** en el panel de opciones, por defecto Medio): cada uno tiene ritmo, error, margen para pasar y si defiende. Fácil 0,88 / ±5 % / no defiende; Medio 0,93 / ±3 %; Difícil 0,97 / ±2 %; Experto 1,0 / ±1 %. El **error** es por curva y por vuelta (entre 1 − error y 1 + error/4 de la objetivo) con semilla fija: la misma corrida da lo mismo. Cambiar la opción cambia a los rivales que ya están en pista. La IA calcula su velocidad objetivo con su propio auto (`RacingLine.speeds_for`).
- **Tráfico** (`RaceTraffic`, nuevo): sabe dónde está cada auto sobre la línea (índice, distancia por la pista, lateral y velocidad lateral), y de ahí salen:
  - **Rebufo**: pegado y en línea con el de adelante, hasta **25 % menos de CdA** (nada a 30 m, sólo arriba de 120 km/h; `CarController.slipstream`).
  - **Distancia en segundos al de adelante** para el **modo adelantamiento**: como en 2026, sólo se activa a menos de 1 s (`car.json` → `max_gap_s`); solo en pista vale siempre. Si no, avisa "A más de 1 s del auto de adelante".
  - **Contactos**: el centro del otro auto dentro de la caja de choque (6 × 1,9 m), medido en el marco del auto.
- **La IA en tráfico** (`AiDriver`):
  - **Sigue** al de adelante sin acercarse a menos de 8 m en su carril, previendo 0,8 s de la línea del otro.
  - **Pasa** cuando va más rápido que el de adelante por el margen de su nivel: arranca en recta, cerca del otro o de la frenada, se abre a 2,6 m de costado (con el centro a 1,2 m o más de la línea blanca) y aprovecha el rebufo y el modo adelantamiento. Si no sale, abandona y espera 2 s. **Por adentro** puede tirarse a menos de 14 m en la frenada: el de adelante le deja lugar.
  - **Defiende** (Medio, Difícil, Experto) una vez por recta si alguien está a menos de 1 s atrás.
  - **No se toca**: cede al que está al lado (el doble al que se tira por adentro); si un auto adelante está o va a estar en 0,4 s a menos de un ancho de costado, va 5 m/s más lento que él; con el volante a fondo y fuera de su carril levanta 2,5 m/s.
- **Tecla I**: suma hasta **3 rivales** de equipos distintos (con Colapinto: Norris, Russell, Leclerc), con el nivel de la opción, más atrás si el lugar está ocupado; la cuarta vez los saca. Cada auto puede usar menos **sub-pasos de neumáticos** (`ai.json` → `car.tyre_substeps`) para abaratar rivales.
- **Verificación** (`paso45_ai.gd`; el jugador congelado lejos y fuera del tráfico, cámara que sigue a la IA):

| Prueba | Resultado |
|---|---|
| Niveles, 1 vuelta lanzada sola | Fácil **1:21.550**, Medio **1:19.267**, Difícil **1:17.600**, Experto **1:16.500**; Medio otra vez 1:19.283; sin salidas, golpes ni rescates |
| Experto 80 m detrás de un Fácil | lo alcanza, toma el rebufo (17 %), usa el modo adelantamiento y lo pasa a los 54,8 s; **0 contactos**, como mucho a 1,3 m de costado lado a lado |
| Experto 30 m detrás de un Medio, 2 vueltas | 11 defensas del Medio, 7 intentos abandonados y 1 pasada; **0 contactos**, sin salidas ni golpes |
| Dos Expertos a 25 m, 1 vuelta | no pasa (5 abandonos), mínimo 9,6 m en el mismo carril; **0 contactos** |
| Rebufo en la recta más larga | 150 → 180 km/h en 3,87 s solo, 3,72 s con 13 %, 3,68 s con 25 % |
| Modo adelantamiento | solo sí; rival detrás no; a 0,84 s sí; a 2,52 s no |
| Tecla I y opción | 3 rivales de 3 equipos con el nivel de la opción; cambiarla los cambia; la cuarta I los saca |
| Costo | tráfico 365 µs por cuadro con 4 autos; decisión de la IA 25 µs; Experto con 4 sub-pasos 1:16.517 (con 8: 1:16.500) |
| Panel de opciones | 505 px con la fila nueva (lugar: 510) |

  **Pasar es difícil entre niveles parecidos en Bakú**: el limitador deja a todos a ~192–198 km/h en las rectas, así que el rebufo casi no suma y las pasadas son en la frenada y por adentro. Es lo esperable: el Experto pasa al Fácil enseguida, al Medio le cuesta y a otro Experto no. Lo que más trabajo dio fue no tocarse: la métrica de contacto medida por la pista fallaba en curvas (ahora mide en el marco del auto con la caja real), y hubo que agregar el lugar para el que se tira por adentro, la predicción de quién se cierra y la levantada con el auto subvirando. Probado aparte (`paso45_dbg3.gd`) en seis combinaciones de niveles y distancias: limpias salvo un toque leve (0,07) en Fácil contra Medio. La medida de física por auto es ruidosa con `--fixed-fps` (+1,0 ms con 8 sub-pasos, +2,6 con 4: no es creíble); vale la del Paso 44 (~2,2–2,8 ms por auto) y el aviso para el Paso 47. **Nada cambió en el manejo del jugador**: vuelta con el piloto automático de siempre 1:42.383 / 1:41.017 / 1:41.050; la prueba del Paso 44 sigue bien (ahora con el rival en Experto: 1:16.600, ritmo 0,9 al 90 % en curvas). Capturas: `informes/capturas/paso45-rebufo.png` (el Experto a 14 m en el rebufo del Fácil, 128 km/h), `paso45-adelantamiento.png` (lado a lado entrando a la curva, 77 contra 61 km/h) y `paso45-opciones.png` (panel con "Nivel de la IA").
- **Cómo probar**: F5, práctica libre, en Opciones elegir el nivel, apretar I tres veces y seguir a los rivales; con uno a menos de 1 s adelante, probar el modo adelantamiento.

### Paso 46 — Colisiones entre autos y penalizaciones
- **Toques entre autos** (`CarController.car_hit(otro, golpe)`): el auto ahora distingue si chocó contra un muro o contra otro auto. Los dos dañan igual (el alerón con la trompa y los pinchazos con las ruedas, como en el Paso 36) y sacuden la cámara, suenan y vibran; `wall_hit` queda sólo para los muros. También avisa el primer cuadro de un toque suave, para saber cuándo empezó.
- **Comisarios** (`RaceStewards`, datos en `data/stewards.json`): cada toque abre un incidente y a los 0,3 s se juzga con cómo venían los autos entre 0,3 y 0,05 s antes (el rebote no cuenta):
  - **De atrás** (los centros a más de 0,6 largos por la pista): culpa del de atrás si venía 1 m/s o más rápido.
  - **De costado** (superpuestos): culpa del que se movía hacia el otro a 0,8 m/s o más y 0,5 m/s más que el otro hacia él.
  - Si no, **incidente de carrera**, sin acción.
  - **Golpe** = el mayor entre la velocidad perdida en el toque y la velocidad con que se acercaban, sobre 15 m/s (como los muros). Menos de 0,05 es un roce y no se investiga.
  - **Sanción**: con golpe de 0,25 o más (unos 4 m/s), **5 s**; si no, **advertencia**, y a la tercera también 5 s.
- **El jugador**: sus penalizaciones van al cronómetro (`lap_timer.add_penalty`, que ahora junta los motivos: "Largada en falso, Choque por detrás a Lando Norris") y salen en los resultados. El HUD avisa todo lo que lo toca a él ("Advertencia 1/3 a Colapinto: …", "Toque entre Colapinto y Norris: sin acción") y las penalizaciones de los demás ("Penalización 5 s a Russell: choque por detrás a Norris"), con el apellido para que entre en pantalla. Los segundos y las advertencias de la IA quedan en los comisarios (`penalty_of()`, `warnings_of()`) para la carrera del Paso 47.
- **La IA** cuenta los toques aparte de los golpes a muros, después de un toque deja la pasada y espera 2 s, y tiene dos reglas nuevas para no tocarse: al lado de otro, si se le va encima más rápido que el otro hacia ella, levanta 5 m/s; y por su carril (pasando o defendiendo) mira 40 m adelante la curvatura del camino que de verdad va a hacer y frena para esa curva (`RacingLine.corner_speed()` y `brake_decel()`, el mismo modelo que la línea). `place_at()` acepta un lateral (para las pruebas y la grilla).
- **Verificación** (`paso46_collisions.gd`; los autos de la IA "a mano", con el piloto apagado, para provocar cada caso):

| Prueba | Resultado |
|---|---|
| De atrás a 15 m/s contra un auto parado | culpa del de atrás, golpe 1,0, **5 s**; su alerón al 40 %, el del otro intacto; los dos lo sienten como toque, ninguno como golpe a un muro |
| Tres toques leves de atrás (3 m/s más rápido) | golpe 0,20: advertencia 1/3, 2/3 y a la tercera **5 s** |
| Uno se cierra de costado a 4,3 m/s | culpa del que se cierra, golpe 0,29, 5 s |
| Los dos se juntan a la vez (2,3 m/s cada uno) | incidente de carrera, sin acción |
| Reglas sueltas (8 casos armados a mano) | todas bien; las advertencias se acumulan por auto |
| El jugador le pega de atrás a una IA parada a 11 m/s | **5 s en su cronómetro** ("Choque por detrás a Lando Norris") y aviso en el HUD; se frenan a 6 m entre centros (chocan de verdad) |
| IA contra IA (Experto 30 m detrás de un Medio, 1 vuelta) | 0 contactos, 0 incidentes, sin salidas ni golpes |
| Costo | comisarios ~8 µs por cuadro |

  La primera versión de la vuelta IA contra IA dio un toque real: el Experto se tiró por adentro de una curva lenta a 17 m/s (objetivo 14) y, con el volante a fondo, se fue de costado sobre el Medio a 3,7 m/s; los comisarios lo penalizaron bien. La línea calcula la velocidad con su curvatura, y el carril de adentro es más cerrado: de ahí la regla nueva del carril. **Las pruebas anteriores siguen bien**: la del Paso 45 con 0 fallas (mismos tiempos por nivel; lado a lado, separación mínima 2,2 m en lugar de 1,3), la del Paso 44 con 0 fallas, la de daños del Paso 36 con la misma tabla, y la vuelta con el piloto automático de siempre 1:42.383 / 1:41.017 / 1:41.050. Capturas: `informes/capturas/paso46-choque.png` (Russell le pega de atrás a Norris parado y el aviso de la penalización) y `paso46-jugador.png` (el jugador le pega de atrás a Norris: 5 s en su cronómetro).
- **Cómo probar**: F5, práctica libre, apretar I, dejar que el rival se acerque y frenar fuerte delante de él, o pegarle de atrás: sale el aviso y, si fue culpa del jugador, la penalización aparece en los resultados.

### Paso 47 — Clasificación y carrera con la grilla 2026 completa (22 autos)
- **Dos modos nuevos** en el menú (`data/modes.json`): **Clasificación** (1, 2, 3 o 5 vueltas lanzadas, solo en pista) y **Carrera** (2, 3, 5, 10 o 20 vueltas, largada detenida con los 22 autos). La clasificación termina con la tabla de tiempos y el botón **"Correr la carrera"**, que arma la carrera con esa grilla; si se elige Carrera sin haber clasificado, el jugador larga con su récord de la pista (o último si no tiene).
- **Clasificación estimada** (`RaceSession.qualifying()`): correr 21 vueltas de IA sería caro, así que el tiempo de cada rival sale de su ritmo. Cada nivel tiene su vuelta lanzada medida en el Paso 45 (`ai.json` → `lap_time`: Fácil 1:21,550 … Experto 1:16,500); cada piloto suma su `skill` (−2 a +2, Verstappen, Norris y Piastri arriba, Lindblad y Stroll abajo) × 0,01 al ritmo del nivel elegido, y el tiempo se interpola entre niveles con un ruido de hasta ±0,25 s. El ruido sale de la **semilla de la sesión**: la misma clasificación da la misma grilla y no depende de qué piloto eligió el jugador.
- **Grilla y largada**: de a dos, 8 m entre puestos y ±2 m de costado, detrás de la línea. Semáforo del Paso 17; los autos de la IA esperan con los controles apagados y largan con una reacción de 0,18–0,45 s (con semilla). La largada en falso del jugador suma 5 s en la carrera también.
- **Carrera** (`RaceSession`, nodo nuevo): ordena por vueltas y distancia (`RaceTraffic.distance`, desenvuelta por vuelta) y guarda cuándo pasa el líder por una marca cada 20 m, así la diferencia de cada uno es "cuánto después que el líder pasó por el mismo lugar" (los que todavía no llegaron a donde largó el líder: distancia / velocidad media del líder). Cuando el líder completa las vueltas sale la **bandera a cuadros**; cada uno termina al cruzar la meta. Cuando termina el jugador se abre el resultado; los que siguen en pista se cierran con su velocidad media (marcados con "≈").
- **Torre de tiempos** (`TimingTower`, a la izquierda del HUD; se refresca 4 veces por segundo): posición, color del equipo, código de 3 letras, diferencia con el líder ("Vuelta 1/3" en la punta, "+N vuelta(s)" si lo doblaron) y penalizaciones en rojo; el jugador resaltado.
- **Resultado**: posición, piloto, equipo, vueltas, tiempo o diferencia con el ganador, penalización (comisarios + largada en falso) y mejor vuelta; la más rápida en violeta, el jugador en amarillo. A la derecha: ganador, "Terminaste P5 (largaste P3)" y la vuelta más rápida. La pantalla completa sigue siendo del Paso 52.
- **Costo** (lo más difícil del paso): en esta PC (Intel UHD, Compatibility) la carrera daba **29,5 FPS** contra 58,9 de la contrarreloj. Ahora:
  - Neumáticos con 4 sub-pasos a menos de 150 m del jugador y 2 más lejos; los lejanos además deciden cada 2 cuadros (`ai.json` → `race`).
  - Las piezas chicas de los autos de la IA (menos de 0,8 m) no se dibujan a más de 60 m de la cámara.
  - `RaceTraffic` arma una vez por cuadro la lista de vecinos (el de adelante y el de atrás de cada uno) en lugar de buscarla en cada consulta.
  - Resultado: **38 FPS** en carrera (sin ventana, ~12 ms de física y scripts por cuadro con 22 autos, contra 15,7 ms con todo a 8 sub-pasos). Falta medirlo en la PC del laboratorio.
- **La IA en grupo** (con 22 autos aparecieron problemas que con 2 no se veían):
  - **Largada**: en la grilla escalonada cada auto esperaba al de la otra fila (8 m adelante en diagonal), porque calculaba que su línea iba a cruzarse con la de él, y además todos "defendían" hacia adentro de la curva 1: el fondo largaba 10 s tarde, en fila. Ahora sigue por su fila de la grilla hasta 2,5 s antes de la primera frenada (`hold_lane()`, sin defender), y debajo de 8 m/s sólo frena por el auto que tiene en su carril.
  - **Seguir**: mira hasta 3 autos encadenados adelante (en fila de a dos el más cercano suele ser el de la otra fila), en las horquillas toma la distancia en línea recta (el de adentro está más cerca de lo que dice la pista) y se acerca a cada uno con lo que frena a 15 m/s² (antes 25: sin aerodinámica, a poca velocidad no frena tanto, y en la curva 1 los autos se tocaban de atrás a 5–10 km/h y se llevaban 5 s).
  - **Pedales**: parado no frena (con la caja automática eso pone reversa) y no acelera si la objetivo es casi 0 (empujaba al de adelante); en una fila detrás de otro auto no cuenta como "trabado".
- **Verificación** (`paso47_race.gd`, carrera a 2 vueltas con el jugador manejado por la IA en Medio):

| Prueba | Resultado |
|---|---|
| Vuelta estimada por nivel | 81,550 / 79,267 / 77,600 / 76,500 s (iguales a las medidas) |
| Clasificación | 22 pilotos, misma semilla → misma grilla, ruido igual con otro piloto del jugador, jugador sin tiempo último, pole–último 1,92 s |
| Grilla | 22 autos en carrera y en el tráfico; el jugador (1:18,600) larga P3; separación mínima 8,1 m; nadie se mueve antes del apagado |
| Largada | sin largada en falso; a los 0,5 s largaron todos; a los 3,5 s casi todo el pelotón va a ~105 km/h de a dos |
| Torre a los 9 s | 22 filas, la penalización de Piastri en rojo; los 22 dentro de 6,3 s |
| Carrera | termina con la bandera a cuadros: Norris 2:41,967, Verstappen, Russell, Leclerc, el jugador 5.º; 13 pasadas, 0 golpes a muros, 0 salidas, 0 rescates |
| Comisarios | 12 incidentes: 6 roces que no se investigan, 2 sin acción, 2 advertencias y 2 penalizaciones (en la curva 1 de la vuelta 1: Piastri se cerró sobre Leclerc, Albon le pegó de atrás a Hamilton) |
| Resultado | 22 filas ordenadas por vueltas y tiempo con penalizaciones; penalización = comisarios + largada en falso |
| Clasificación → carrera | 1 vuelta, sólo el jugador en pista; tabla con "Correr la carrera"; guarda el tiempo; la carrera arma 22 autos y el jugador larga donde clasificó |

  Lo que más costó fue la curva 1 de la primera vuelta. La primera carrera completa dio **9 penalizaciones**, todas a 5–15 km/h: el pelotón se frenaba en cadena (cada uno apuntaba más lento que el de adelante) y los toques de atrás se juzgaban con la velocidad de 0,3 s antes, en plena frenada. Con la frenada de seguimiento realista quedaron en 1, pero el fondo seguía largando en fila; con la largada de a dos quedan 2 incidentes de carrera razonables y el pelotón llega junto a la curva 1. El resultado depende mucho de pequeños cambios (soltar la fila a 3 s de la frenada en lugar de 2,5 dio 3 penalizaciones): la curva 1 con 22 autos es caótica, como en la realidad. Los del fondo pierden mucho en esa curva (en 2 vueltas el último termina ~1 min detrás). **Sin la carrera nada cambió**: las pruebas de los Pasos 44, 45 y 46 siguen con 0 fallas y la vuelta con el piloto automático de siempre da 1:42.383 / 1:41.017 / 1:41.050 (esa prueba corre sin `--fixed-fps`; con `--fixed-fps 60` da 1:42.533 / 1:41.100 / 1:41.017, también con el código del Paso 46). Capturas: `informes/capturas/paso47-modos.png` (menú con los 4 modos), `paso47-clasificacion.png` (resultado de la clasificación con "Correr la carrera"), `paso47-grilla.png` (el jugador P3 en la grilla con el semáforo y la torre), `paso47-carrera.png` (a los 9 s, el aviso de la penalización de Piastri) y `paso47-resultado.png`.
- **Cómo probar**: F5, Jugar → Clasificación (1 vuelta), dar una vuelta y en el resultado "Correr la carrera". Esperar el semáforo y largar: la torre de la izquierda muestra la posición; al terminar la carrera sale el resultado con los 22.

### Paso 48 — Pit lane con limitador de velocidad y paradas en boxes
- **Calle de boxes** a la izquierda de la recta principal (`data/tracks.json` → `pit_lane`): se entra 470 m antes de la meta (rampa de 45 m que abre el muro de la izquierda), se sale 120 m después y vuelve a la pista con otra rampa. Tiene 8 m de ancho: el carril rápido (2,2 m del muro de boxes) y el de trabajo (6 m), con una línea blanca entre los dos. El **muro de boxes** (con colisión) la separa de la pista; el muro de afuera se corre hasta el fondo de la calle sólo en esa zona.
- **Boxes y garajes**: un rectángulo del color de cada equipo en el piso, cada 18 m desde 300 m antes de la meta, y detrás un garaje gris con una franja y el nombre del equipo. Los dos pilotos de un equipo comparten el box.
- **Limitador** (tecla **P**, botón B del control; se puede cambiar en Controles): limita a **80 km/h** cortando el acelerador cerca del límite (no frena: hay que llegar despacio a la línea). Los carteles "PIT 80" y "FIN 80" marcan la zona (400 m antes y 60 m después de la meta). Pasada "FIN 80" se apaga solo. **Ir a más de 81 km/h** en la zona son **+5 s** (una vez por pasada), con aviso en el HUD; en carrera se suman a la penalización del resultado.
- **Parada**: frenar dentro del rectángulo del equipo (±2,5 m) en el carril de trabajo. El auto queda sostenido (sin volante ni acelerador) **2,4 s** para cambiar neumáticos (el mismo compuesto, nuevos; el cambio de compuesto es del Paso 49) y **4 s más si hay que cambiar el alerón**; también se arreglan pinchazos y daño. El HUD muestra "PARADA EN BOXES x,x s" y, al terminar, qué se hizo.
- **En carrera la R ya no arregla el auto** (sigue devolviendo a la pista, pero con el daño): los avisos de alerón roto y pinchazo dicen "entrá a boxes". En práctica y contrarreloj se mantiene el arreglo con R.
- **La IA para en boxes** (`PitLane.path_lateral` y `speed_cap`): 50 m antes de la entrada se va al borde, entra por el carril rápido con el limitador al 95 % (frena con 9 m/s² hasta la línea), se desvía al carril de trabajo 25 m antes del box, frena con 5 m/s² hasta la marca, espera el servicio y vuelve al carril rápido; 40 m después de la salida retoma su línea. Mientras está en la calle no pasa ni defiende. `RaceSession` planea **una parada por auto en carreras de 8 vueltas o más** (entre el 35 % y el 65 % de la carrera, con la semilla de la sesión) y además manda a boxes a quien rompe el alerón o pincha (nunca en la última vuelta). En la torre de tiempos aparece **BOX**.
- **Lo que no cambió**: la colisión de la pista es la misma de antes (la calle apoya sobre el suelo general, a la misma altura); los límites de pista y la lista de vecinos de `RaceTraffic` separan la calle de la pista (un auto en boxes no frena a los que pasan por la recta).
- **Verificación** (`paso48_pit.gd`):

| Prueba | Resultado |
|---|---|
| Geometría | muro de afuera a 16,2 m en la zona y de vuelta en su lugar afuera; muro de boxes con colisión (un rayo lo toca); piso de la calle a 0,000 m; box de Alpine (6) a −210 m |
| Limitador en la recta | máximo 79,8 km/h |
| Parada del jugador (piloto automático a la marca) | entra a los 9,5 s, frena a 0,71 m de la marca, 6,4 s de parada (2,4 + 4 del alerón), se mueve 0,024 m sostenido; alerón y neumáticos nuevos; máx. 79,7 km/h; sin penalización, salidas, golpes ni rescates |
| Exceso de velocidad | a 107,5 km/h: 1 penalización de +5 s y la parada se hace igual |
| Carrera a 2 vueltas (paradas forzadas de Norris, Piastri, Verstappen, Alonso y Ocon) | los 5 paran una vez (los dos McLaren en el mismo box), ≤ 79,9 km/h, 0 golpes a muros, 0 rescates, sin excesos; la torre muestra BOX; los demás no paran; Norris pasa de P1 a P10–P13 (~20 s perdidos) |
| Plan a 10 vueltas | todas las paradas entre las vueltas 3 y 7 |

  La primera versión ensanchaba la colisión de la pista hasta el fondo de la calle, y la vuelta con el piloto automático del Paso 36 cambiaba hasta 0,1 s (los triángulos nuevos cambian cómo apoyan las ruedas): por eso la calle quedó sobre el suelo general, que ya está a la misma altura, y la vuelta volvió a dar exactamente lo mismo que antes: 1:42.383 / 1:41.017 / 1:41.050 (y 1:42.533 / 1:41.100 / 1:41.017 con `--fixed-fps 60`). **Las pruebas anteriores siguen bien**: Pasos 44, 45, 46 y 47 con 0 fallas (la carrera del Paso 47 da el mismo resultado: Norris 2:41,967, 13 pasadas, 0 rescates). Capturas: `informes/capturas/paso48-calle.png` (la calle con los garajes), `paso48-cenital.png` (vista desde arriba de la entrada), `paso48-limitador.png` (el jugador con el limitador encendido), `paso48-parada.png` (parado en el box de Alpine) y `paso48-carrera.png` (Norris y Verstappen en boxes, "BOX" en la torre).
- **Cómo probar**: F5, práctica libre. Después de la última curva, abrirse a la izquierda antes del muro de boxes, apretar P antes de la línea "PIT 80" (llegar a menos de 80 km/h) y frenar en el rectángulo rosa de Alpine (o el del equipo elegido). Probar también pasar sin limitador para ver la penalización.

### Paso 49 — Estrategia: cambio de compuesto, radio del ingeniero
- **Estrategia en carreras de 10 y 20 vueltas** (`data/strategy.json`, desde 8 vueltas): los neumáticos se gastan **2,5 veces más rápido** (si no, una carrera corta no alcanza para gastar nada) y hay que **usar dos compuestos**: quien termina con uno solo recibe **+30 s** ("Un solo compuesto"). En carreras de 2 a 5 vueltas y en práctica todo sigue como antes.
- **Modelo de estrategia** (`scripts/race/race_strategy.gd`, `RaceStrategy`): desgaste por vuelta de cada compuesto (blando 0,056 · medio 0,035 · duro 0,021, sacado del desgaste por MJ de `car.json`), cuántas vueltas aguanta hasta el 75 % (13 / 21 / 35) y cuánto cuesta cada vuelta según el agarre y el desgaste. Arma todos los planes de **una parada** con dos compuestos distintos que no pasen el límite y los ordena por tiempo total (con 21 s por la parada). A 10 vueltas el mejor es blando 6 + medio 4; a 20, medio 11 + blando 9.
- **La IA elige su plan** con la semilla de la sesión entre los que quedan a menos de 4 s del mejor, así no larga toda con lo mismo (en la prueba: 11 con blandos, 9 con medios y 1 con duros). Para en la vuelta del plan con el segundo compuesto, y si se gasta antes de tiempo (límite + 8 %, faltando 2 vueltas o más) para igual. Si para por un alerón o un pinchazo, elige con `next_compound` uno que cumpla la regla y aguante hasta el final.
- **La IA siente el desgaste**: al cerrar cada vuelta rehace sus velocidades de la línea con el agarre de sus neumáticos gastados (`RacingLine.speeds_for(car, true)`, 1,75 ms), así va un poco más lenta antes de parar y vuelve a su ritmo con los nuevos.
- **El jugador**: arranca con el compuesto elegido en el setup y recibe el mejor plan para ese compuesto. Con **O** (se puede cambiar en Controles) elige el compuesto que le van a poner en la próxima parada; el HUD dice cuál es el recomendado y si ya lo usó. En la calle de boxes el cartel de la parada muestra el compuesto (por ejemplo "· DURO").
- **Radio del ingeniero** (`scripts/race/engineer_radio.gd`, `EngineerRadio`): un panel arriba a la derecha ("RADIO · INGENIERO", del color del equipo) con mensajes de 5 s, nunca dos a menos de 6 s y sin repetir uno que ya está en la cola. Dice el plan al largar, recuerda la regla, en cada vuelta la posición y las diferencias con el de adelante y el de atrás, **"Box, box. Entrá esta vuelta: blando."** cuando toca parar (también con alerón roto, pinchazo, neumáticos gastados o la regla sin cumplir faltando 3 vueltas, y otra vez 900 m antes de la entrada), el desgaste al 30 % y 50 %, cuando el de adelante o el de atrás entra a boxes, "neumáticos fríos" al salir y la última vuelta. Por ahora es sólo texto, sin voz.
- **Torre de tiempos y resultado**: la torre muestra la letra del compuesto de cada auto con su color (S rojo, M amarillo, H blanco) y el resultado tiene una columna "Neum." con los compuestos usados (por ejemplo "M-S").
- **Verificación** (`paso49_strategy.gd`):

| Prueba | Resultado |
|---|---|
| Modelo | 54 planes a 10 vueltas y 90 a 20, todos con dos compuestos y dentro del límite; misma semilla, mismo plan; `next_compound` no repite el compuesto si falta cumplir la regla |
| Práctica | desgaste normal; O pasa medio → duro → blando; sin elegir se pone el mismo compuesto; parada con duros nuevos (desgaste 0); con desgaste la IA baja 2,02 % sus velocidades |
| Regla | con un solo compuesto: +30 s y aviso |
| Carrera de 10 vueltas (el jugador manejado por la IA, siguiendo la radio) | plan del jugador medio 4 + blando; la radio avisó "Box, box" en la vuelta 4 y paró en la 4; terminó M-S, 4.º. Las 21 IA pararon y usaron dos compuestos; nadie pasó el límite de desgaste; 5 golpes a muros, 0 rescates; ganó Verstappen (M-S) |
| Radio | 16 mensajes en 836 s: plan, regla, diferencias, box, otro que entra a boxes, neumáticos fríos, desgaste, última vuelta; nunca dos a menos de 6 s |
| Desgaste medido contra el modelo | medio 0,032 (0,035) · blando 0,061 (0,056) · duro 0,020 (0,021) por vuelta |

  El desgaste por vuelta del modelo empezó en 0,016 y se ajustó a 0,014 con lo medido en carrera. La radio avisaba el desgaste recién al 50 %, que en 10 vueltas casi nunca llega: ahora avisa al 30 % y al 50 %.
  **Se arregló un cierre de Godot que venía del Paso 47**: al salir de una carrera después de unos 30 s con toques entre autos (volver al menú, pasar a la clasificación o reiniciar), Jolt se caía al liberar los autos con el reporte de contactos encendido (sólo con Jolt; con GodotPhysics3D no pasaba). Ahora cada auto apaga `contact_monitor` y se saca del espacio de física en `NOTIFICATION_EXIT_TREE`, antes de que lo haga `CollisionObject3D`. La prueba completa del Paso 47 (carrera, clasificación y otra carrera) termina sin cerrarse y la repetición `paso49_reload.gd` (3 carreras de 30 s seguidas) también. **Las pruebas anteriores siguen bien**: Pasos 47 y 48 con 0 fallas (la carrera del Paso 47 da el mismo resultado: Norris 2:41,967) y la vuelta del Paso 36 igual que antes (1:42.533 / 1:41.100 / 1:41.017 con `--fixed-fps 60`). Capturas: `informes/capturas/paso49-radio.png` (el plan en la radio), `paso49-box.png` ("Box, box"), `paso49-calle.png` (en la calle con el compuesto de la parada) y `paso49-resultado.png` (la columna de compuestos).
- **Cómo probar**: F5, Carrera de 10 vueltas. Leer el plan en la radio, apretar O para ver los compuestos y entrar a boxes cuando el ingeniero dice "Box, box". Probar también terminar sin parar para ver los +30 s.

### Paso 50 — Banderas amarilla y azul, Safety Car
- **Dirección de carrera** (`scripts/race/race_control.gd`, `RaceControl`, datos en `data/race_control.json`; sólo en carrera). Revisa la pista 10 veces por segundo y cuesta **0,05–0,1 ms por cuadro**. Cada cosa que pasa queda en `history` y en la radio.
- **Auto lento**: un auto en pista (no en la calle de boxes) a menos de **30 km/h durante 1,5 s**, pasados 15 s de la largada y sin otro auto a menos de 20 m adelante (los que hacen fila detrás de uno parado no cuentan, así el embudo de la curva 1 no llena la pista de amarillas).
- **Bandera amarilla**: zona desde **220 m antes** del auto lento hasta 40 m después; dura mientras siga lento y 4 s más. En la zona la IA va al **80 %** de su velocidad objetivo y **nadie puede pasar** (salvo al auto lento o a uno que entra o sale de boxes). La IA ya no empieza ni sigue una pasada 150 m antes de la zona. Quien gana un lugar ahí recibe **+5 s** ("pasó a X con bandera amarilla"); devolver el lugar no se sanciona.
- **Bandera azul**: a quien tiene a menos de **1 s** detrás a un auto con una vuelta más. La IA levanta (90 % de su objetivo) y no defiende. El jugador ve "BANDERA AZUL · DEJÁ PASAR A …" y si no deja pasar en **10 s** recibe **+5 s**.
- **Safety Car**: sale si un auto sigue lento **6 s** (o hay 3 lentos a la vez). Aparece 80 m delante del líder: un auto plateado con franja verde, dos luces naranjas que titilan y el cartel "SAFETY CAR". Va a **130 km/h** como máximo y al 75 % de la velocidad de la línea en las curvas. Nadie puede pasar a nadie (+5 s) ni al Safety Car.
  - El primero lo sigue a **unos 25 m**: frena con el mismo perfil que el Safety Car pero en su propia posición, así frena en las mismas curvas. Los demás hacen fila a ~30 m y los que están lejos lo alcanzan con 60 km/h de más.
  - La torre muestra "SC · vuelta/vueltas" y la radio avisa ("Safety Car en pista", "Box, box" si la parada del plan estaba a 2 vueltas o menos; la IA también adelanta la suya).
  - Después de 40 s y con la pista limpia avisa "el Safety Car entra esta vuelta", desaparece en la entrada de boxes y la carrera vuelve a **verde al cruzar la meta**.
- **HUD**: franja arriba al centro: amarilla "BANDERA AMARILLA · NO PASAR", azul, naranja "SAFETY CAR · NO PASAR", "SAFETY CAR ENTRA ESTA VUELTA" y verde "BANDERA VERDE" por unos segundos.
- **Comisarios**: `RaceStewards.flag_penalty` agrega la sanción directa (sin investigar culpa) con el texto de cada bandera.
- **Verificación** (`paso50_flags.gd`, carrera de 5 vueltas con el jugador manejado por la IA):

| Prueba | Resultado |
|---|---|
| Amarilla (Norris frenado en una recta) | zona abierta, la IA al 80 % y sin pasar en la zona, el jugador ve la franja, la radio avisa; la zona se cierra cuando vuelve a andar y una amarilla corta no saca el Safety Car |
| Pasar con amarilla (armado) | +5 s con el texto; devolver el lugar no se sanciona |
| Azul (vuelta de diferencia armada) | el jugador doblado ve la azul con el nombre; la IA doblada levanta y no defiende; no dejar pasar: +5 s; sin la vuelta de diferencia se va |
| Safety Car (Verstappen parado 8,1 s) | aparece 80 m delante del líder; torre "SC · 1/5"; el primero lo sigue a 34 m de promedio y pegado no pasa los 145 km/h; el último pasa de 29,0 s a 18,8 s del primero; 0 sanciones a la IA; entra en la vuelta, desaparece en boxes y verde en la meta (130 s en total); la IA vuelve a correr libre |
| Carrera completa | terminó sin rescates; 1 sanción natural de la IA por amarilla (Gasly, a los 40 s) |

  El primero del Safety Car al principio quedaba a 70–100 m: frenaba para la velocidad que el Safety Car tenía en ese momento (lento en una curva cuando el líder todavía estaba en la recta). Ahora sigue el perfil del Safety Car en su propia posición. Las amarillas y el Safety Car salían solos en la curva 1 de la largada (el embudo baja a todos a menos de 30 km/h): por eso los 15 s de gracia, la fila que no cuenta y 3 autos lentos (no 2) para el Safety Car.
  **El cierre de Jolt del Paso 49 no estaba del todo arreglado**: repitiendo 3 carreras seguidas (`paso49_reload.gd`), el Paso 49 se cerraba en 3 de 4 corridas, al cambiar de escena o al salir (siempre en la misma dirección de Godot). Los autos de la IA y la calle de boxes se agregan después del auto y de la pista, así que al liberar la escena salían en otro orden. Ahora `Main` tiene un nodo guardián que siempre es su último hijo (Godot saca primero al último) y que saca todos los autos y áreas del espacio de Jolt antes que cualquier otra cosa. Las 3 carreras seguidas pasan en las 4 corridas; queda 1 cierre de 4 al salir de Godot con la carrera abierta (`quit()`, después de terminar todo). **Las pruebas anteriores siguen bien**: Pasos 47 y 48 con 0 fallas (la carrera del Paso 47 cambia un poco con las banderas: gana Norris en 2:41,667). La vuelta del Paso 36 da ahora 1:42.417 / 1:40.950 / 1:40.967 con `--fixed-fps 60`, igual con y sin los cambios de este paso (también en el commit del Paso 49), así que no viene del Paso 50. Capturas: `informes/capturas/paso50-amarilla.png`, `paso50-azul.png`, `paso50-safety-car.png`, `paso50-fila.png` y `paso50-resultado.png`.
- **Cómo probar**: F5, Carrera de 5 vueltas. Para ver una amarilla y el Safety Car, frenar y quedarse parado en la pista después de los primeros 15 s: a los 1,5 s sale la amarilla y a los 6 s el Safety Car. Ponerse detrás, no pasar a nadie y esperar la bandera verde en la meta.

### Paso 51 — Replays con cámaras de TV
- **Grabador** (`scripts/race/race_recorder.gd`, `RaceRecorder`, datos en `data/replay.json`; sólo en carrera). Cada **0,1 s** guarda la posición y la rotación de los 22 autos, un número para el orden (avance en metros, o el tiempo de llegada si ya terminó) y el Safety Car. Todo va en un solo arreglo de floats: **0,42 MB por minuto**, **0,05 ms** por muestra (sin pasar de 60 minutos). Entre dos muestras interpola la posición y la rotación (error contra lo real: 2 cm).
- **Repetición** (`scripts/ui/replay_viewer.gd`, `ReplayViewer`): se abre desde la pausa (botón **"Repetición"**, arranca 15 s antes de ahora) o desde el resultado (**"Ver repetición"**, arranca 12 s antes de tu llegada). El juego queda en pausa: los autos se mueven a su pose grabada y al salir (Esc) vuelven exactamente a donde estaban, con su velocidad, y la carrera sigue.
  - **Cámaras** (C): **TV** (las 10 torres del Paso 18, que cortan siguiendo al auto con la velocidad grabada), **persecución** (detrás y arriba, suavizada) y **a bordo**.
  - **Controles**: Espacio pausa, ←/→ 5 s, flechas arriba/abajo velocidad (×0,25 a ×4), Q/E auto anterior/siguiente, I próximo incidente (4 s antes), Inicio vuelve a la largada. La barra de abajo muestra los incidentes como marcas y se puede hacer clic o arrastrar para ir a cualquier momento.
  - **Pantalla**: "● REPETICIÓN", reloj de carrera y vuelta; la torre con las diferencias de ese momento (vueltas de menos y sanciones hasta ahí) y el auto seguido resaltado; abajo piloto, posición, velocidad, cámara y velocidad de reproducción. Al pasar por un incidente aparece el aviso ("Advertencia 1/3 a Hamilton: se cerró sobre Verstappen").
  - **Incidentes**: los de los comisarios (sanciones y advertencias) y los de dirección de carrera (amarillas, Safety Car, verde).
- `TvCameras` acepta otro auto a seguir y una fuente de velocidad; `RaceControl.safety_car_node()` da el Safety Car para grabarlo.
- **Verificación** (`paso51_replay.gd`, carrera de 2 vueltas con el jugador manejado por la IA):

| Prueba | Resultado |
|---|---|
| Desde la pausa (a los 60 s) | tapa la pausa y el HUD; los 22 autos vuelven 15 s atrás; la carrera no corre; se detiene al llegar a ahora; Esc devuelve los autos a su lugar (0,0000 m), la cámara del jugador y la pausa; la carrera sigue |
| Grabación | 1745 muestras en 174 s; poses contra las reales en 4 instantes: 0,022 m máx; orden igual al de la carrera (4/4); 0,42 MB/min; 0,049 ms por muestra |
| Desde el resultado | botón "Ver repetición"; arranca 12 s antes de la llegada (159,9 s); cámara de TV con el jugador, 2 cortes de torre; al final la torre coincide con el resultado (10/10) |
| Incidentes | 3 naturales (2 advertencias, 1 sanción); I salta 4 s antes y sigue al auto; se ve el aviso |
| Cámaras y controles | persecución a 12 m detrás; a bordo; C vuelve a la TV; E sigue al de atrás; pausa; ← 5 s; ×0,25; Esc vuelve al resultado |

  Primero la pose grabada iba 0,9 m atrás de la real: cada nodo lee las poses del paso de física anterior, así que la muestra se marca con el reloj de antes de sumar el cuadro. **Las pruebas anteriores siguen bien**: Pasos 47 y 50 con 0 fallas (el 47 tuvo un cierre de Jolt al salir con la carrera abierta, el mismo 1 de 4 conocido del Paso 50). Capturas: `informes/capturas/paso51-resultado.png` (el botón), `paso51-tv.png` (cámara de TV), `paso51-incidente.png` (el aviso), `paso51-persecucion.png` y `paso51-a-bordo.png`.
- **Cómo probar**: F5, Carrera de 2 vueltas. En plena carrera apretar Esc → "Repetición", mirar con C, Q/E e I, y salir con Esc para seguir corriendo. Al terminar, "Ver repetición" en el resultado.

### Paso 52 — Pantalla de resultados de carrera con puntos
- **Puntos** (`scripts/race/race_results.gd`, `RaceResults`, datos en `data/points.json`): 25-18-15-12-10-8-6-4-2-1 a los 10 primeros, como en 2026. No hay punto por vuelta rápida (se sacó en 2025), pero se puede activar en el JSON (`fastest_lap_points`, sólo si termina entre los `fastest_lap_top` primeros). Los equipos suman los puntos de sus dos pilotos; si empatan, gana el que tiene el mejor puesto.
- **Resultado de la carrera**, con tres vistas que se cambian con el botón "Ver …" o con ←/→:
  - **Pilotos**: posición, lugares ganados o perdidos contra la grilla (verde / rojo), piloto, equipo, vueltas, compuestos, paradas, tiempo o diferencia ("+1 vuelta" si quedó doblado; "≈" si seguía en pista), sanción, mejor vuelta y puntos. La vuelta más rápida en violeta y el jugador en amarillo.
  - **Equipos**: los 11 con sus dos pilotos (puesto y puntos) y el total.
  - **Sanciones**: minuto de carrera, piloto, sanción ("+5 s" o "Advertencia 1/3") y motivo. Están las de los comisarios (toques y banderas) y las que antes sólo sumaban segundos: largada en falso, exceso de velocidad en boxes y un solo compuesto (`RaceSession.add_extra_penalty()` ahora guarda el motivo).
  - A la derecha: **podio** con los 3 primeros (escalones del color del equipo, código y puntos), tu puesto con los lugares ganados y los puntos, los puntos de tu equipo y la vuelta más rápida. Siguen "Ver repetición", Repetir y Menú principal.
- **Guardado**: cada carrera queda en `user://last_race.json` (pista, vueltas, semilla, piloto del jugador, pilotos y equipos con puntos) para el campeonato del Paso 55.
- **Verificación** (`paso52_results.gd`, carrera de 2 vueltas con el jugador manejado por la IA):

| Prueba | Resultado |
|---|---|
| Tabla de puntos | 25 a 1 y 0 desde el 11.º; sin punto por vuelta rápida; otra tabla del JSON y el punto por vuelta rápida sólo en el top |
| Clasificación | mismo orden que la carrera; 101 puntos en total (VER 25, NOR 18, COL 15…); el jugador P3 largando P4 (+1); vuelta más rápida VER 1:18.467; diferencias "+s" (sin doblados en 2 vueltas) |
| Equipos | 11 equipos de 2, suma de sus pilotos, ordenados (McLaren 28, Red Bull 27, Ferrari 20, Alpine 16…) |
| Sanciones | 5 de los comisarios y una armada a los 30 s ("Exceso de velocidad en boxes" a Hadjar): aparece con el motivo, en su fila (+5 s) y en orden por el reloj de carrera |
| Guardado | `user://last_race.json` con 22 pilotos, 11 equipos y 101 puntos, la pista, las vueltas y el piloto del jugador |
| Pantalla | 22 filas de 11 columnas; podio VER-NOR-COL; botones dentro de la pantalla (el último termina en 662 de 720 px); botón y ←/→ cambian la vista y dan la vuelta; "Ver repetición" sigue andando y al volver queda la misma vista; el contrarreloj no muestra podio ni vistas |

  **Las pruebas anteriores siguen bien**: Pasos 47, 50 y 51 con 0 fallas y código de salida 0 (la carrera del Paso 47 sigue dando Norris 2:41,667). Capturas: `informes/capturas/paso52-pilotos.png`, `paso52-equipos.png` y `paso52-sanciones.png`.
- **Fase F cerrada: hito H3 alcanzado** (rivales con IA, carrera con largada, fantasma, repeticiones y resultado con puntos).
- **Cómo probar**: F5, Carrera de 2 vueltas. Al terminar, mirar el podio y los puntos; apretar ←/→ (o "Ver equipos") para ver los equipos y las sanciones.

### Paso 53 — Generador de pistas por puntos de control, reutilizable para otros circuitos
- **Un solo generador para todas las pistas**: `baku_track.gd` pasó a ser `scripts/track/track_generator.gd` (`TrackGenerator`) y la escena `scenes/tracks/track.tscn`; el nodo de `main.tscn` se llama `Track`. Arma la pista que pide `GameState.selected_track` (vacío = `default_track_id` de `data/tracks.json`, Bakú). Bakú se genera **idéntica** a antes: misma huella de centerline, muros, anchos, pianos, malla de colisión (10 992 caras), ciudad (378 edificios), carteles, línea ideal, cámaras de TV, boxes y zonas de modo recta.
- **Todo lo propio de Bakú salió del código a `tracks.json`**: el mar (`"sea"`: costa y dirección) y los monumentos (`"landmarks"`: ciudad vieja como caja y las tres Flame Towers como cilindros, cada uno con su radio libre para la ciudad). Una pista sin `"sea"` no tiene mar; sin `"city"` lleva la ciudad genérica de `CityBuilder` (con publicidad genérica en vez de "BAKU CITY CIRCUIT").
- **Lo que una pista nueva puede dejar en automático**:
  - **Calle de boxes** (`"pit_lane": {"auto": true}`): en la recta principal, del lado de adentro (a la izquierda si la vuelta es antihoraria), con entrada y salida 20 m después y antes de los pianos, rampas de 45 m, limitador y una caja por equipo cada 18 m (menos si no entra, mínimo 10 m). Si la recta es corta, no hay calle y queda un aviso. Cualquier clave que traiga el JSON se respeta.
  - **Zonas de modo recta** (sin `"aero_zones"`): las rectas de más de 300 m, desde 60 m después de la curva hasta 120 m antes de la siguiente.
  - Carteles de frenado, pianos, escapatorias, sectores, línea ideal, cámaras de TV y grilla ya salían del trazado.
- **Validación** al generar (`errors` / `warnings`, también en la consola como "Pista prueba: …"): menos de 3 puntos de control (usa el trazado de respaldo), tramos del polígono que se cruzan, radios que no entran entre los tramos (se achican), radios menores que media pista + banquina (el muro de adentro se dobla), partes del trazado que se tocan sin cruzarse (rectas paralelas muy cerca), vuelta de menos de 1 km, largada lejos del trazado o en una curva, y la calle de boxes automática que no entra. Bakú y la pista de prueba dan **0 errores y 0 avisos**.
- **Pista de prueba** (`"prueba"` en `tracks.json`): 6 puntos de control, 2336 m, todo automático (boxes, zonas, ciudad) y una torre como monumento. Sirve para probar el generador; la segunda pista de verdad es el Paso 54.
- **Vista previa en planta** (`scenes/track_preview.tscn`, `scripts/tools/track_preview.gd`): dibuja asfalto, muros, curvas (rojo), zonas de modo recta (verde), calle de boxes con las cajas de colores de los equipos (naranja), puntos de control numerados y el polígono que forman (amarillo), sectores (celeste), largada con el sentido de marcha, curvas numeradas y monumentos, más un panel con largo, anchos, sentido, boxes, zonas y los errores / avisos. ←/→ cambia de pista. No construye mallas (`preview_only`), así que tarda menos de un segundo. Desde la consola guarda una imagen: `Godot --path . res://scenes/track_preview.tscn -- --track prueba --save C:/tmp/prueba.png`.
- **Elegir pista sin menú**: `Godot --path . -- --track prueba` (el selector en el menú llega con el Paso 54). La pantalla de carga, el HUD, los récords (`records_key`) y el resultado usan el nombre y la clave de la pista elegida.
- `TrackGenerator.layout_override` acepta una pista con el formato de `tracks.json` sin tocar el archivo (lo usan las pruebas; sirve para un editor futuro).
- **Verificación** (`paso53_tracks.gd`; huella de Bakú con `paso53_fingerprint.gd`):

| Prueba | Resultado |
|---|---|
| Bakú igual que antes | huella idéntica en 32 valores (centerline, muros, malla de colisión, ciudad, carteles, línea ideal, TV, boxes, zonas, monumentos, mar, 13 nodos hijos) |
| Validación | ocho → "los tramos 1-2 y 3-0 se cruzan"; rectas a 14 m → "se toca consigo mismo"; radio de 3 m → error; radio de 400 m en tramos de 300 m → aviso; 2 puntos → error y trazado de respaldo; largada lejos → error; largada en una esquina → aviso y sin boxes; recta de 250 m → sin boxes y aviso; 900 m → aviso de vuelta corta |
| Automáticos | rectángulo de 700×300 m: boxes a la izquierda si es antihorario y a la derecha si es horario (siempre adentro); 2 zonas de modo recta |
| Pista de prueba en el juego | 11 cajas en orden dentro del limitador (−271 a −91 m), 3 zonas de modo recta, 10 cámaras de TV, 17 carteles, línea ideal, ciudad genérica, sin mar |
| Manejo | el jugador manejado por la IA da 2 vueltas (58,4 s y 56,8 s) sin golpes a muros, salidas ni rescates |
| Carrera | 22 autos, 2 vueltas, sin golpes a muros ni rescates de la IA, resultado con puntos |

  **Las pruebas anteriores siguen bien**: la vuelta del Paso 36 da exactamente 1:42,417 / 1:40,950 / 1:40,967 y los Pasos 47, 48, 51 y 52 dan 0 fallas (la carrera del Paso 47 sigue dando Norris 2:41,667). Las pruebas viejas sólo cambiaron el tipo (`TrackGenerator`) y el nombre del nodo (`Track`). Capturas: `informes/capturas/paso53-plano-baku.png`, `paso53-plano-prueba.png`, `paso53-prueba-curva.png`, `paso53-prueba-carrera.png` y `paso53-prueba-resultado.png`.
- **Cómo probar**: abrir `scenes/track_preview.tscn` y apretar F6 (←/→ cambia de pista). Para correr en la pista de prueba: `Godot --path GodotF126 -- --track prueba` y elegir cualquier modo.

### Paso 54 — Segunda pista
- **Autódromo de Buenos Aires (placeholder)** (`"buenos_aires"` en `data/tracks.json`): circuito permanente **inventado**, inspirado en el de Buenos Aires, NO el layout oficial. 3798 m en sentido horario, llano (hasta 2 m), 13 m de ancho: recta principal de 820 m, curva 1 cerrada, una "S", un curvón largo de 100 m de radio, chicana, la recta del fondo, una horquilla en dos curvas y la vuelta de cierre. 16 puntos de control y nada más: boxes (a la derecha, adentro), 3 zonas de modo recta, 16 curvas con carteles, cámaras de TV y línea ideal salen del generador del Paso 53. Banquinas más anchas (2,5 m) y escapatorias de 14 m.
- **Escenario de autódromo**: piso de césped (`"ground": {"color"}`, nuevo en el generador), sin mar, sin edificios (`"city"` con `rows: 0` y `fill_spacing: 0`), dos tribunas celestes y blancas (recta principal y curva 1), publicidad propia y el Obelisco (68 m) como monumento. El color de piso de cada horario de `lighting.json` es el de Bakú: una pista con `"ground"` propio lo conserva.
- **Elegir la pista en el menú**: nueva tarjeta "Pista ‹ Bakú ›" arriba de los modos (←/→ o Enter cambian entre las pistas con `"status": "jugable"`; muestra tipo, país y largo). Al confirmar el modo queda en `GameState.selected_track`; si cambia la pista, la clasificación anterior deja de valer para la carrera. La pantalla de carga, el HUD, los récords, la telemetría, el fantasma y el resultado guardado ya usaban la pista elegida (Paso 53). La pista de prueba no sale en el menú (`"status": "prueba"`).
- **El menú de modos entra en pantalla**: pista + 4 modos + neumáticos + setup no caben en 720 px (desde el Paso 47 la tarjeta de setup quedaba afuera). Ahora el panel va en un `ScrollContainer` que sigue el foco, sin barra visible.
- **IA calibrada por pista**: la clasificación estimada usaba la vuelta de cada nivel medida en Bakú (~79 s en Medio). Cada pista puede traer `"ai_lap_times"` (`RaceSession.track_ai_data()` los pone en lugar de los de `ai.json`). Medidos con el auto manejado por la IA, sin ajuste de piloto, en la segunda vuelta: Buenos Aires Fácil 1:36,700 · Medio 1:34,300 · Difícil 1:32,567 · Experto 1:31,350; pista de prueba 57,833 / 56,833 / 56,033 / 55,383. El mismo método en Bakú da 81,30 / 78,97 / 77,55 / 76,45 s, a menos de 0,3 s de los de `ai.json`.
- **Verificación** (`paso54_track.gd`; tiempos de la IA con `paso54_ailaps.gd`):

| Prueba | Resultado |
|---|---|
| Trazado | 3798 m, 0 errores y 0 avisos, horario, boxes adentro, recta de 820 m, 16 curvas, 3 zonas, césped y sin mar |
| IA por pista | Buenos Aires usa sus tiempos (Medio 94,3 s) y `ai.json` queda igual; Bakú sin cambios; pole estimada de la IA 1:33,254 (antes habría sido ~1:18, de Bakú) |
| Menú | tarjeta "Pista ‹ Bakú ›" → con → "Buenos Aires" (Autódromo · Argentina · 3,8 km); con el foco en Setup el panel se desplaza y la tarjeta termina en 712 de 720 px; al confirmar, `selected_track = buenos_aires` y la clasificación de Bakú deja de valer |
| Práctica | pantalla de carga con el nombre, récords con su clave, sin edificios, 2 tribunas, 342 paneles, el Obelisco, 10 cámaras de TV, 28 carteles, césped verde |
| Manejo | 2 vueltas con la IA en Medio: 1:35,667 y 1:34,300 (la calibrada) sin golpes, salidas ni rescates |
| Clasificación y carrera | con 93,5 s el jugador larga P4 (no en la pole); carrera de 22 a 2 vueltas que termina, ganador Piastri, 0 rescates; el resultado guardado es de Buenos Aires |
| Boxes | Norris, Verstappen y Alonso con parada forzada: los tres paran en su caja de la calle automática (2,4 s) sin exceso de velocidad |

  En la carrera con ventana (capturas) la IA no es determinista: en una de tres corridas tuvo 9 golpes a muros y 2 rescates; en las otras, 0. **Las pruebas anteriores siguen bien**: Bakú idéntica a la huella del Paso 53, la vuelta del Paso 36 1:42,417 / 1:40,950 / 1:40,967, y los Pasos 47 (Norris 2:41,667), 52 y 53 con 0 fallas. Capturas: `informes/capturas/paso54-plano.png`, `paso54-menu-pista.png`, `paso54-menu-setup.png`, `paso54-carga.png`, `paso54-recta.png`, `paso54-curvon.png`, `paso54-grilla.png`, `paso54-carrera.png` y `paso54-resultado.png`.
- **Cómo probar**: F5, Jugar, y en la tarjeta "Pista" apretar → hasta "Buenos Aires"; elegir un modo y un piloto.

### Paso 55 — Modo campeonato con varias carreras
- **Temporada** (`data/championship.json`, clase `Championship` en `scripts/race/championship.gd`): calendario de 2 fechas (Gran Premio de Azerbaiyán en Bakú y Gran Premio de Argentina en Buenos Aires), clasificación de 2 vueltas en cada una y la carrera con las vueltas elegidas al empezar (2, 3, 5 o 10). El mismo piloto toda la temporada. Se guarda en `user://championship.json` después de cada carrera; el calendario guardado manda (cambiar los datos no rompe una temporada empezada).
- **Menú**: nueva tarjeta "Campeonato ‹ 3 vueltas ›" (en `data/modes.json`). Sin temporada guardada, Enter pasa a elegir el piloto y arranca la fecha 1. Con una temporada a medias la tarjeta muestra "Campeonato ‹ Seguir: fecha 2/2 ›" y debajo la próxima pista, las vueltas y tu puesto ("Argentina · 2 vueltas · Franco Colapinto P4, 12 pts"); Enter sigue sin volver a elegir piloto, y ←/→ pasan a "Nueva · N vueltas" para empezar otra. Con la temporada terminada, la tarjeta dice el campeón. En el campeonato la tarjeta de pista no cuenta (manda el calendario).
- **Cada fecha**: clasificación (con "Fecha 1/2" en el HUD, la pausa y la pantalla de carga) → "Correr la carrera" → carrera con la grilla de esa clasificación (como en el Paso 47; la clasificación estimada de la IA usa los tiempos de cada pista, Paso 54). Cada fecha tiene una semilla nueva.
- **Resultado de la carrera**: además de Pilotos, Equipos y Sanciones (Paso 52), dos vistas nuevas: **Campeonato** (puesto, cambio contra la fecha anterior, piloto, equipo con su color, puesto en cada fecha y puntos) y **Constructores** (puntos de cada equipo por fecha y total). El resumen agrega "Campeonato: P4 con 12 pts (fecha 1/2)". En lugar de "Repetir" (repetir una fecha ya sumada la contaría dos veces) va "Siguiente: Argentina" o, en la última, "Final de temporada".
- **Final de temporada**: "Temporada 2026 — Campeón" con el podio de la temporada, las tablas de Campeonato y Constructores, el campeón de pilotos (puntos y victorias), el de equipos y tu puesto final.
- **Puntos y desempate**: los de cada carrera (`data/points.json`, Paso 52). Empate en puntos: más victorias, después más segundos puestos, etc.; si siguen iguales, por nombre (para que el orden no cambie entre corridas). En equipos cuentan los puestos de sus dos pilotos.
- **Arreglo**: en la pantalla de resultados, un botón con texto largo ("Ver campeonato equipos") se ensanchaba, asomaba a la derecha de los otros (hasta x = 1311 de 1280) y ← → movían el foco a ese botón en vez de cambiar la tabla. Los botones del resultado ahora tienen ancho fijo y recortan el texto, y las vistas tienen nombres cortos. Y en el menú, al volver con la temporada a medias el foco caía en la tarjeta Campeonato (la última) pero el panel no se desplazaba hasta ella, porque el foco llegaba antes de que el panel recién mostrado tuviera tamaño; ahora el menú la trae a la vista un cuadro después (`paso55_menu.gd`: la tarjeta queda en 634–712 px del panel 210–712).
- **Verificación** (`paso55_championship.gd`: una temporada de 2 fechas a 2 vueltas con el jugador manejado por la IA en Medio; la clasificación se cierra con un tiempo fijo, 0,4 % más lento que la pole de la IA):

| Prueba | Resultado |
|---|---|
| Datos sintéticos | sólo suma la carrera de la pista que toca y no suma después del final; empate 27–27 resuelto por la victoria, 18–18 por nombre; tabla después de la fecha 1; equipos = suma de sus pilotos por fecha; se guarda y se lee igual |
| Menú (temporada nueva) | "Campeonato ‹ 3 vueltas ›", ← elige 2, Enter pasa a elegir piloto; al confirmar Colapinto se guarda la temporada y arranca Bakú con clasificación de 2 vueltas |
| Fecha 1 (Bakú) | "Fecha 1/2 · Clasificación"; "Correr la carrera" larga la carrera de 2 vueltas; termina (170 s); sumada; 5 vistas; "Siguiente: Argentina" sin "Repetir"; botones dentro de la pantalla (terminan en 689 de 720 px); Colapinto P4 con 12 pts; → pasa a Constructores |
| Volver al menú y seguir | "Seguir: fecha 2/2" con "Argentina · 2 vueltas · Franco Colapinto P4, 12 pts"; →/← entre "Nueva · 2 vueltas" y "Seguir"; Enter sigue con Colapinto aunque en el menú hubiera otro piloto |
| Fecha 2 (Buenos Aires) | carrera que termina (197 s), sumada, "Final de temporada" |
| Suma | los puntos de los 22 pilotos y los 11 equipos son la suma de los `last_race.json` de las 2 fechas; tabla ordenada; el archivo guardado da la misma tabla |
| Desempate real | Verstappen 50 (1.º y 1.º); Colapinto, Piastri y Norris con 30: Colapinto (4.º y 2.º) y Piastri (2.º y 4.º) delante de Norris (3.º y 3.º) por el segundo puesto, y entre ellos por nombre |
| Final | "Temporada 2026 — Campeón", podio VER–COL–PIA, sólo las tablas del campeonato y "Menú principal"; "Campeón: Max Verstappen (Red Bull), 50 pts y 2 victorias"; el menú dice "Terminada: campeón Max Verstappen (50 pts)" |

  Unos 14 minutos sin ventana. **Las pruebas anteriores siguen bien**: Pasos 47 (Norris 2:41,667), 52, 53 y 54 con 0 fallas. Capturas: `informes/capturas/paso55-menu.png`, `paso55-resultado-1.png`, `paso55-pilotos-1.png`, `paso55-equipos-1.png`, `paso55-menu-seguir.png`, `paso55-carga.png`, `paso55-pilotos-2.png` y `paso55-campeon.png`.
- **Cómo probar**: F5, Jugar, bajar hasta "Campeonato", elegir las vueltas con ←/→, Enter y elegir el piloto. Después de cada carrera, "Siguiente" lleva a la próxima fecha; desde el menú principal se puede seguir la temporada más tarde.
