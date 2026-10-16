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

## Fase B — Motor, caja manual y cockpit ⏳

| Paso | Contenido | Estado |
|---|---|---|
| 3 | **Motor con RPM**: ralentí ~4.000, limitador ~12.500 rpm, curva de torque, las RPM salen de marcha + velocidad | ✅ |
| 4 | **Caja manual de 8 marchas + N + R** con levas: **E** sube, **Q** baja. Corte de potencia al cambiar, rebote en limitador, bloqueo de rebaje que pasaría de vueltas. **M** alterna manual / automática | ✅ |
| 5 | **Tablero en el HUD**: marcha grande (R, N, 1–8), RPM en barra con **luces de cambio** tipo F1 (verde → rojo → azul), velocímetro digital + **aguja analógica** | ✅ |
| 6 | **Volante 3D** en el cockpit: gira con la dirección (±180°), pantalla con marcha / RPM / velocidad / delta, LEDs de cambio arriba | ⏳ Siguiente |
| 7 | **Manos y brazos del piloto** sobre el volante: siguen el giro; los dedos accionan la leva al cambiar | |
| 8 | Cockpit detallado: halo, casco con visor, **espejos retrovisores** con imagen real (`SubViewport`), vibración de cámara con velocidad y pianos | |
| 9 | **Sonido de motor** generado por código en capas según RPM y acelerador; sonido de cambio, limitador y petardeo al soltar | |
| 10 | Sonidos de neumáticos (chirrido por deslizamiento), viento por velocidad, golpes contra muros | |

## Fase C — Menús y flujo de juego (cierra H1)

| Paso | Contenido | Estado |
|---|---|---|
| 11 | Menú principal con fondo 3D del auto girando y música | |
| 12 | **Selección de escudería → piloto** con tarjetas (color del equipo, número, bandera) desde `grid_2026.json` | |
| 13 | Livery de dos colores por equipo y número del piloto en el auto | |
| 14 | Opciones: caja manual / automática, ayudas, cámara por defecto, volumen, calidad gráfica; guardado en `user://settings.json` | |
| 15 | Pausa con Esc (Continuar / Reiniciar / Menú / Salir) | |
| 16 | Modo **Contrarreloj**: N vueltas y después pantalla de resultado con tiempos por vuelta y sectores | |
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
