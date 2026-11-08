# GodotF126 — Simulador de Fórmula 1 — Informe final

**Autor:** Agustín Giménez
**Materia:** 350 — Ingeniería de Software Avanzado (plan 2015)
**Motor / lenguaje:** Godot 4.7.2 / GDScript
**Repositorio:** [github.com/agustinhgimenez/GodotF126](https://github.com/agustinhgimenez/GodotF126)
**Jugar online:** [ingsoftwareavanzado.agustingimenez.ar](https://ingsoftwareavanzado.agustingimenez.ar/)
**Fecha:** noviembre de 2026

---

## 1. Abstract

GodotF126 es un simulador de Fórmula 1 de la temporada 2026 hecho en Godot 4. Empezó como una demo acotada (un auto, una pista, física arcade y una vuelta cronometrada) y terminó, en 60 pasos incrementales, como un juego completo: física por cuatro ruedas con neumáticos tipo Pacejka, aerodinámica activa y ERS del reglamento 2026, telemetría para entrenar, carreras con los 22 autos de la grilla manejados por una IA que sigue, pasa y defiende, boxes y estrategia, banderas con Safety Car, comisarios, repeticiones, dos pistas, clima y un modo campeonato. Se entrega como ejecutable de Windows y se puede jugar en el navegador. Tiene 67 tests automáticos y una batería de pruebas de regresión que se corrieron en cada paso.

## 2. Del alcance inicial a lo entregado

La formalización de septiembre (`informes/GodotF126-Agustin-Gimenez-formalizacion.md`) fijó una demo de cursada y una lista explícita de cosas fuera de alcance. El plan se reorganizó en un ROADMAP de **60 pasos, 8 fases y 4 hitos**, y cada paso dejó una versión jugable.

| Hito | Paso | Contenido | Estado |
|---|---|---|---|
| H1 — Demo de cursada | 24 | Escudería y piloto, caja manual de 8 marchas, cockpit con volante y manos, sonido, vuelta cronometrada, resultado | ✅ |
| H2 — Simulador | 38 | Física de neumáticos, aero activa 2026, ERS, setup, línea de trazada | ✅ |
| H3 — Juego completo | 52 | Rivales con IA, carrera con largada, fantasma, repeticiones, resultado con puntos | ✅ |
| H4 — Entrega final | 60 | Tests, optimización, `.exe`, documentación y defensa | ✅ |

Lo que la formalización dejaba **fuera de alcance** y finalmente entró: IA para los 22 autos (Pasos 44–47), una segunda pista (54), clima (56), desgaste de neumáticos y estrategia de boxes (33, 48, 49). Sigue afuera el multijugador y los modelos 3D detallados de pilotos.

| Fase | Pasos | Qué dejó |
|---|---|---|
| A — Base | 0–2 | Proyecto, auto, pista de Bakú generada por código, cronómetro, cámaras |
| B — Motor, caja y cockpit | 3–10 | RPM, caja secuencial, tablero, volante 3D con manos, espejos, sonido sintetizado |
| C — Menús y flujo (H1) | 11–24 | Menú 3D, selección de piloto, liveries, opciones, pausa, contrarreloj, semáforo, límites de pista, ciudad, iluminación, tutorial, benchmark |
| D — Física (H2) | 25–38 | Cuatro ruedas, neumáticos, transferencia de peso, aerodinámica, aero activa, frenos y ABS, diferencial y TC, ERS, compuestos, combustible, setup, daños, mando y volante, línea ideal |
| E — Telemetría | 39–43 | Registro por vuelta, delta en vivo, análisis comparativo, CSV, auto fantasma |
| F — Rivales y carrera (H3) | 44–52 | IA con niveles, tráfico y rebufo, colisiones y comisarios, carrera de 22, boxes, estrategia, banderas y Safety Car, repeticiones, resultado con puntos |
| G — Contenido extra | 53–56 | Generador de pistas, Buenos Aires, campeonato, lluvia |
| H — Ingeniería y entrega (H4) | 57–60 | Tests con GUT, optimización, `.exe`, versión web, documentación |

## 3. Arquitectura

### 3.1 Escenas y flujo

`menu.tscn` (menú con el auto girando) → `loading.tscn` (carga en segundo plano, controles y consejos) → `main.tscn` (la sesión de juego) → pantalla de resultado → menú. Dos *autoloads* comparten estado entre escenas: `GameState` (pista, piloto, modo, clima, campeonato) y `Settings` (opciones del jugador, guardadas en `user://settings.json`).

### 3.2 El auto por componentes

`CarController` es un `RigidBody3D` (motor de física Jolt) que orquesta componentes chicos, cada uno con su responsabilidad y sus datos:

| Componente | Responsabilidad |
|---|---|
| `CarEngine`, `Gearbox` | RPM, curva de par, limitador; caja secuencial R/N/1–8, manual o automática |
| `CarWheel` ×4, `TyreModel`, `TyreCompounds` | Suspensión por rayo, fuerzas del neumático, temperatura y desgaste por compuesto |
| `AbsModel`, `Differential`, `TractionControl` | Frenos con ABS, diferencial autoblocante, control de tracción por niveles |
| `ActiveAero`, `Ers`, `Fuel` | Modo recta / curva y adelantamiento 2026, batería y MGU-K, combustible y masa |
| `CarDamage`, `CarSetup` | Alerón y pinchazos; setup que deriva carga, arrastre, rigideces y relación final |
| `EngineAudio`, `CarAudioFx` | Sonido sintetizado por código (motor, neumáticos, viento, golpes) |

Así cada paso del ROADMAP agregó un componente sin agrandar el controlador más allá de lo necesario, y cada componente se puede probar por separado (los tests de GUT instancian `Gearbox`, `LapTimer` o `TyreCompounds` solos).

### 3.3 La sesión de juego

`main.gd` arma la sesión según el modo: pista (`TrackGenerator`), cronómetro (`LapTimer`), línea ideal (`RacingLine`), telemetría (`TelemetryRecorder`, `LiveDelta`, `GhostCar`) y, en carrera, `RaceSession` (grilla, posiciones, vueltas, LOD de la IA), `RaceTraffic` (vecinos, rebufo, contactos), `RaceStewards` (incidentes y sanciones), `PitLane`, `RaceStrategy` y `EngineerRadio`, `RaceControl` (banderas y Safety Car) y `RaceRecorder` (repeticiones). Los sistemas se comunican por señales de Godot (`lap_completed`, `car_hit`, `decided`, `flag_changed`, …), no por referencias cruzadas.

### 3.4 Datos separados del código

Todo lo ajustable está en **20 archivos JSON** en `data/`: la grilla 2026, las pistas (puntos del trazado, boxes, ciudad, carteles), el auto (masa, aerodinámica, suspensión, neumáticos, frenos, ERS, combustible, daños), la IA, los modos, la estrategia, los comisarios, las banderas, el clima, los puntos, los controles y las opciones. `DataLoader` los lee y los tests verifican que existan y sean coherentes entre sí. Ajustar el juego no requiere tocar código.

### 3.5 Pistas generadas

`TrackGenerator` arma una pista completa desde una lista de puntos en `tracks.json`: redondea las esquinas con arcos, calcula curvatura, ancho, elevación, muros, pianos, escapatorias, carteles de frenado, sectores, calle de boxes y zonas de aerodinámica automáticas, y **valida** el trazado (cruces, radios imposibles, rectas que se tocan, largada en curva). La segunda pista se agregó escribiendo sólo datos.

## 4. Modelo físico

- **Cuatro ruedas con suspensión por rayo**: resorte, amortiguador, barras estabilizadoras y anti-cabeceo por eje. La carga de cada rueda sale de ahí, con la transferencia de peso en frenada, aceleración y curva.
- **Neumáticos**: fórmula mágica de Pacejka simplificada para la fuerza longitudinal (deslizamiento κ) y lateral (ángulo de deriva), combinadas en el círculo de fricción, con sensibilidad a la carga. El giro de cada rueda se integra en forma implícita. Las fuerzas se calculan en **8 sub-pasos** por cuadro de física para el jugador (estable con pasos de 1/60 s).
- **Aerodinámica**: carga (ClA) y arrastre (CdA) que crecen con el cuadrado de la velocidad, reparto adelante / atrás, efecto del piso según la altura. **Aero activa 2026**: modo recta (menos arrastre) y modo adelantamiento con energía por vuelta.
- **Tren motriz**: curva de par, caja de 8 marchas con tiempo de cambio, diferencial autoblocante, control de tracción, **ERS** con batería, recuperación en frenada y despliegue.
- **Estado del auto**: temperatura y desgaste por rueda y compuesto (blando, medio, duro, intermedio, lluvia), combustible que baja la masa vuelta a vuelta, daños en alerón y pinchazos, setup (alerones, altura, resortes, barras, presiones, relación final).
- **Clima**: el agua mezcla el agarre seco con el mojado de cada compuesto, enfría los neumáticos y cambia la estrategia.

Referencia de comportamiento con el setup por defecto (práctica, 20 kg de combustible): 0–100 km/h en 2,78 s con TC 3, frenada de 61 m desde 192 km/h, 1,47 g en curva a 60 km/h y 1,82 g a 120 km/h, vuelta a Bakú en ~1:41 con un piloto automático de pruebas.

## 5. Inteligencia artificial

- **Línea ideal** (`RacingLine`): trayectoria de curvatura mínima por suavizado iterativo del desplazamiento lateral de cada punto (de vecinos lejanos a cercanos), dentro de los límites de la pista, y velocidad objetivo por punto con el mismo modelo de agarre, carga y frenada que el auto.
- **Piloto** (`AiDriver`): sigue la línea mirando adelante según la velocidad, acelera y frena contra la velocidad objetivo con un factor por nivel (Fácil, Medio, Difícil, Experto) y errores por curva. En tráfico: sigue, decide pasadas por adentro o por afuera según el déficit de velocidad, abandona las que no prosperan, defiende una vez por recta, deja lugar al que se tira, respeta banderas y entra a boxes según su plan de estrategia.
- **Carrera de 22**: `RaceSession` aplica un nivel de detalle por distancia al jugador (menos sub-pasos de neumáticos y decisiones cada 2 cuadros lejos de la cámara). Los comisarios clasifican los toques (de atrás, de costado, incidente de carrera) con el historial de los segundos previos y sancionan.

## 6. Pruebas

**Tests automáticos (Paso 57)**: GUT 9.7.1, **67 tests** en 7 archivos (580 comprobaciones, ~17 s): caja de cambios, cronómetro, carga e integridad de los JSON, neumáticos y clima, estrategia, puntos y campeonato, validación de pistas y la física del auto real sobre un piso plano (acelera, frena, pone reversa, dobla). Se corren en el editor o por consola, y devuelven código 1 si algo falla.

**Pruebas de regresión por paso**: cada paso se cerró con scripts de prueba sin ventana (`-s`) que manejan el juego por código y comparan contra los valores anteriores. Las más usadas:

| Prueba | Qué fija |
|---|---|
| Vuelta del piloto automático en Bakú | 1:42.417 / 1:40.950 / 1:40.967 con `--fixed-fps 60`: cualquier cambio de la física del jugador la mueve |
| Carrera de 22 autos a 2 vueltas | Clasificación y tiempos de llegada exactos (Norris 2:41.667): determinista con semilla fija |
| Huella de la pista generada | Bakú idéntica antes y después del generador de pistas |
| Clima, campeonato, boxes, banderas, repeticiones | Conjuntos de comprobaciones con 0 fallas |

Las pruebas que manejan con la IA respaldan y restauran los récords y la telemetría del jugador, para no dejar datos de prueba.

## 7. Rendimiento

El proyecto usa el renderer **GL Compatibility** (OpenGL 3.3) para correr en PC sin Vulkan, como las del laboratorio.

| Medición (notebook i5-1334U, Intel UHD) | Resultado |
|---|---|
| Prueba de rendimiento del Paso 24 (render, 3 vistas × 3 calidades) | recomienda **Alta** (corrida del usuario, 23/10/2026; con el `.exe`, también Alta) |
| Práctica y contrarreloj | ~60 FPS |
| Carrera de 22 autos, con ventana (Paso 58) | **47 FPS** (antes de optimizar, 40–44) |
| Física de la carrera de 22, sin ventana | **11,2 ms** por cuadro (antes 12,4) |

En la carrera lo que limita es la CPU de la simulación, no el dibujo (~4,6 ms). El Paso 58 bajó el costo un 10 % con optimizaciones que **no cambian ningún resultado**: la carrera de prueba da exactamente la misma clasificación antes y después. Llegar a 60 FPS con 22 autos en esta PC requeriría simplificar la física de los autos lejanos, lo que cambia el comportamiento de la IA; se dejó como trabajo futuro.

## 8. Entrega

- **Ejecutable de Windows** (Paso 59): `GodotF126.exe`, un solo archivo de ~105 MB con los datos adentro; no requiere instalar nada. Se regenera con un comando (ver `DESTINO-WINDOWS.md`). Con `-- --benchmark` corre la prueba de rendimiento.
- **Versión web**: export de Godot a WebAssembly publicado en [ingsoftwareavanzado.agustingimenez.ar](https://ingsoftwareavanzado.agustingimenez.ar/) (VPS propio con nginx, detrás de Cloudflare; ~40 MB, de los que viajan ~10 MB porque Cloudflare los comprime). En el navegador la carrera de 22 va a ~18 FPS en la misma notebook: sirve para mostrar el juego; para jugar la carrera conviene el `.exe`.
- **Documentación**: manual de usuario (`informes/manual-de-usuario.md`), este informe, guion del video (`informes/guion-video-demo.md`), guía de la defensa (`informes/guia-defensa.md`), ROADMAP con el detalle y las pruebas de cada paso, y 166 capturas en `informes/capturas/`.

## 9. Metodología y gestión

Desarrollo **iterativo e incremental**: un paso por vez, cada uno con su verificación, su sección en el ROADMAP (qué se hizo, tabla de pruebas, regresiones, cómo probar) y su commit "Paso N: …". Entre el commit inicial (25/09/2026) y la entrega (08/11/2026) hubo **62 commits** (contando el de esta documentación). El proyecto tiene 84 scripts (~17.300 líneas de GDScript con tipado estático), 7 escenas, 2 shaders, 20 archivos de datos y 7 archivos de tests.

| Riesgo previsto | Qué pasó |
|---|---|
| Física demasiado compleja para el tiempo | Se empezó arcade y se pasó a cuatro ruedas recién en el Paso 25, con la demo ya cerrada |
| Crecimiento del alcance | El ROADMAP fijó el orden; lo extra (segunda pista, clima) entró en la Fase G, después del juego completo |
| Hardware del laboratorio sin Vulkan | Renderer Compatibility y benchmark propio (Paso 24) |
| Datos no incluidos en el export | Filtro `*.json` en los presets; verificado en el registro del export |
| Costo de 22 autos con física completa | Nivel de detalle por distancia (Paso 47) y optimización sin cambios de resultado (Paso 58) |
| Cierres del motor de física al liberar una carrera | Diagnosticado en el Paso 49: se saca el cuerpo del espacio de Jolt antes de liberarlo |

## 10. Encuadre en las unidades del programa

| Unidad | Tema | Aplicación |
|---|---|---|
| I | Tipos de producto | Simulador de entrenamiento no crítico con componente de entretenimiento; telemetría, línea ideal y fantasma como herramientas de aprendizaje |
| II | Diseño y alcance | Formalización con fuera de alcance explícito, ROADMAP de 60 pasos con hitos, decisiones registradas paso a paso |
| III | Guion | Flujo menú → modo → piloto → carga → sesión → resultado → repetición; campeonato como hilo de varias sesiones; radio del ingeniero |
| IV | Física | Modelo por ruedas con Pacejka, transferencia de peso, aerodinámica, tren motriz, estado del auto y clima |
| V | Nivel y HUD | Pistas generadas y validadas desde datos, ciudad con LOD, iluminación; HUD con tablero, torre, banderas, radio, delta y panel de telemetría |

## 11. Limitaciones y trabajo futuro

- Las pistas son **trazados inventados** inspirados en Bakú y Buenos Aires, no los oficiales.
- Los autos y pilotos son modelos geométricos simples.
- La carrera de 22 autos no llega a 60 FPS en una notebook con gráficos integrados (47 con el `.exe`, ~18 en el navegador). Mejora posible: física simplificada para los autos lejanos.
- Sin multijugador.
- El mando se probó por software; falta probarlo con un volante físico.

## 12. Conclusión

El proyecto cumplió los cuatro hitos. La decisión que más pesó fue trabajar en pasos chicos y verificables, con los datos fuera del código y pruebas que fijan los resultados: permitió reemplazar la física entera en la Fase D, agregar 21 rivales con IA y optimizar al final sin romper lo anterior, porque cada cambio se comparó contra lo que ya funcionaba.
