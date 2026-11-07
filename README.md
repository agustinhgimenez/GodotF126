# GodotF126 — Simulador de Fórmula 1

Proyecto de la materia **350 — Ingeniería de Software Avanzado** (plan 2015).
Autor: **Agustín Giménez**.

GodotF126 es un videojuego-simulador de Fórmula 1 en tercera persona hecho con **Godot 4.7** y **GDScript**. La demo de cursada tiene un auto (Franco Colapinto, Alpine), una pista (Bakú, placeholder geométrico), física arcade jugable con motor por RPM y HUD.

## 1. Instalar Godot 4.7
1. Entrar a <https://godotengine.org/download/> y bajar la última **4.7.x stable** (probado con **4.7.2**).
2. Elegir **Godot Engine – Windows – Standard** (64 bit). **No** hace falta la versión .NET/C#.
3. Descomprimir el `.zip` en una carpeta, por ejemplo `C:\Godot\`.
4. Ejecutar `Godot_v4.7.2-stable_win64.exe`. No requiere instalación.

> El proyecto está guardado con Godot 4.7. Versiones anteriores (4.3–4.6) pueden no abrirlo bien; conviene que todo el equipo use la misma versión.

## 2. Abrir el proyecto
1. En el *Project Manager* de Godot, apretar **Import**.
2. Elegir el archivo `project.godot` dentro de la carpeta `GodotF126\` de este repositorio, por ejemplo:
   `C:\Users\btc\Desktop\GodotF126\GodotF126\project.godot`
3. Apretar **Import & Edit**. La primera vez Godot tarda unos segundos importando.

## 3. Jugar
Apretar **F5** (o el botón ▶ arriba a la derecha). Arranca el menú principal: **Jugar** (Enter o clic) → elegir modo (**Práctica libre** o **Contrarreloj**, con ← → para la cantidad de vueltas) → elegir escudería → elegir piloto → carga la pista. En Contrarreloj se larga desde la grilla con **semáforo de 5 luces**: hay que acelerar cuando se apagan (acelerar antes es largada en falso, +5 s). Al completar las vueltas aparece el resultado con los tiempos por vuelta y sector. Salirse de la pista con las cuatro ruedas (pasar la línea blanca) invalida la vuelta: no cuenta para mejor vuelta ni récord. En **Opciones** se elige caja, dirección asistida, cámara inicial, volúmenes y calidad; se guardan solas.

| Tecla | Acción |
|-------|--------|
| **W** | Acelerar |
| **S** | Frenar (en caja automática, con el auto quieto: marcha atrás) |
| **A / D** | Girar izquierda / derecha |
| **E / Q** | Subir / bajar marcha (caja manual: R, N, 1–8) |
| M | Alternar caja manual / automática |
| **Espacio** | Freno de mano |
| C | Cambiar cámara (TV / cercana / cockpit / T-cam / capot / cámaras de pista) |
| R | Volver a la largada (anula la vuelta) |
| Esc | Pausa: Continuar / Reiniciar / Opciones / Menú / Salir (en el menú: salir) |

También funcionan las flechas del teclado.

## 4. Si algo falla
- **Pantalla negra o error de Vulkan**: el proyecto ya usa el renderer *GL Compatibility*. Actualizar drivers de video.
- **"Parse error" en un script**: verificar que la versión sea 4.7 (menú *Help → About*). Godot 3.x no abre este proyecto.
- **El auto no responde**: hacer clic dentro de la ventana del juego para darle foco.

## Contenido de esta carpeta
| Archivo / carpeta | Qué es |
|---|---|
| `GodotF126/` | Proyecto Godot (abrir `project.godot`) |
| `GodotF126/ROADMAP.md` | Plan iterativo de 60 pasos en 8 fases |
| `PARA-EL-PROFESOR-GodotF126-abstract.md` | Abstract + descripción breve para entregar |
| `informes/GodotF126-Agustin-Gimenez-formalizacion.md` | Formalización completa del proyecto |
| `informes/capturas/` | Capturas del juego para informes y presentaciones |
| `informes/audio/` | Muestras de sonido grabadas del juego |
| `PARA-EL-AGENTE-LOCAL.md` | Instrucciones para seguir desarrollando con un agente de IA |
| `DESTINO-WINDOWS.md` | Rutas y ubicación de archivos en Windows |

## Estado
- ✅ Paso 0: esqueleto del proyecto.
- ✅ Paso 1: auto manejable con WASD, pista de Bakú, HUD.
- ✅ Paso 2: cronómetro por sectores, mejor vuelta, récord guardado, cambio de cámara.
- ✅ Paso 3: motor con RPM (ralentí 4.000, limitador 12.500, curva de torque), caja automática provisoria de 8 marchas, marcha y RPM en el HUD. Datos en `GodotF126/data/car.json`.
- ✅ Paso 4: caja manual de 8 marchas + N + R con levas (E/Q), corte de potencia al cambiar, bloqueo de rebaje que pasaría de vueltas, M alterna manual / automática.
- ✅ Paso 5: tablero en el HUD con marcha grande, 15 luces de cambio tipo F1 (verde → rojo → azul, parpadeo en el limitador), RPM y velocímetro digital + aguja analógica.
- ✅ Paso 6: volante 3D en la cámara cockpit que gira ±180° con la dirección, con LEDs de cambio y pantalla (marcha, velocidad, RPM, modo, tiempo de vuelta y delta por sector contra la mejor vuelta).
- ✅ Paso 7: manos y brazos del piloto sobre el volante (siguen el giro; brazos con cinemática inversa de dos tramos), y el índice tira de la leva al cambiar. Captura: `informes/capturas/paso7-cockpit.png`.
- ✅ Paso 8: cockpit detallado: halo con pilar central, casco con visera y visor, espejos retrovisores con imagen real (`SubViewport`), vibración de cámara con la velocidad y golpes (muros, cambios de marcha). Capturas: `informes/capturas/paso8-cockpit.png` y `paso8-tv.png`.
- ✅ Paso 9: sonido de motor sintetizado por código (V6, tono según RPM, combustión según acelerador, turbo), limitador entrecortado, golpe de caja al cambiar y petardeo al soltar. Muestra grabada: `informes/audio/paso9-motor.wav`.
- ✅ Paso 10: chirrido de neumáticos al derrapar y con freno de mano, viento según la velocidad, golpes y roce contra los muros (todo sintetizado por código). Muestras: `informes/audio/paso10-efectos.wav` y `paso10-motor-y-efectos.wav`.
- ✅ Paso 11: menú principal (escena de arranque) con el auto girando sobre una plataforma con el color del equipo, música generada por código y botones Jugar / Salir; Esc en la pista vuelve al menú. Captura: `informes/capturas/paso11-menu.png`; música: `informes/audio/paso11-musica.wav`.
- ✅ Paso 12: selección de escudería → piloto con tarjetas (color del equipo, número, bandera dibujada por código y país); el auto del menú toma el color del equipo y la carrera usa el piloto elegido. Capturas: `informes/capturas/paso12-escuderias.png`, `paso12-pilotos.png`, `paso12-banderas.png`.
- ✅ Paso 13: livery de dos colores por equipo (principal en la carrocería; secundario en alerones y franjas) y número del piloto en el morro y la cubierta del motor. Capturas: `informes/capturas/paso13-menu.png`, `paso13-carrera.png`.
- ✅ Paso 14: opciones en el menú (caja inicial, dirección asistida, cámara inicial, volúmenes general / motor / efectos / música, calidad gráfica, pantalla completa) guardadas en `user://settings.json`. Captura: `informes/capturas/paso14-opciones.png`.
- ✅ Paso 15: pausa con Esc (todo se congela y el auto se calla) con Continuar / Reiniciar / Opciones / Menú principal / Salir. Capturas: `informes/capturas/paso15-pausa.png`, `paso15-opciones.png`.
- ✅ Paso 16: modo Contrarreloj (1 a 10 vueltas elegidas en el menú) con pantalla de resultado: tiempo y sectores de cada vuelta, mejores en violeta, tiempo total y récord; Repetir o volver al menú. Capturas: `informes/capturas/paso16-modos.png`, `paso16-resultado.png`.
- ✅ Paso 17: largada detenida en Contrarreloj con semáforo de 5 luces (en el pórtico y en el HUD), tiempo de reacción y detección de salto con +5 s de penalización. Capturas: `informes/capturas/paso17-semaforo.png`, `paso17-resultado-salto.png`.
- ✅ Paso 18: cámaras extra: T-cam sobre el airbox, cámara de capot y 10 cámaras de TV fijas en la pista que cortan a la más cercana y hacen zoom sobre el auto. Capturas: `informes/capturas/paso18-tcam.png`, `paso18-capot.png`, `paso18-pista-2.png`.
- ✅ Paso 19: pianos rojos y blancos en las curvas (vibran y retumban al pisarlos), escapatorias del lado de afuera y límites de pista: con las cuatro ruedas afuera la vuelta queda invalidada. Capturas: `informes/capturas/paso19-curva-arriba.png`, `paso19-invalidada.png`.
- ✅ Paso 20: carteles de frenado 150 / 100 / 50 m antes de cada curva, del lado de afuera y detrás del muro (sólo donde la recta previa alcanza). Capturas: `informes/capturas/paso20-carteles.png`, `paso20-cockpit.png`.
- ✅ Paso 21: Bakú mejorado (aproximado, no es el layout oficial FIA): 2,6 km con recta junto al mar, ángulos rectos de la ciudad, subida de 12 m al sector del castillo de 7,6 m de ancho y bajada. Trazado en `data/tracks.json`. Capturas: `informes/capturas/paso21-trazado.png`, `paso21-subida.png`, `paso21-castillo-cockpit.png`.
- ✅ Paso 22: ciudad generada desde el trazado — 389 edificios, 3 tribunas con techo y 267 paneles de publicidad genérica en los muros, con LOD (ventanas y textos se dejan de dibujar de lejos). Capturas: `informes/capturas/paso22-tribunas.png`, `paso22-publicidad.png`, `paso22-arriba.png`.
- ✅ Paso 23: iluminación de atardecer (presets en `data/lighting.json`, opción "Hora de la carrera": Atardecer / Día), sombras según la calidad gráfica y mar con shader propio que refleja el cielo y el sol. Capturas: `informes/capturas/paso23-costa.png`, `paso23-ciudad-atardecer.png`, `paso23-ciudad-dia.png`.
- ✅ Paso 24: pulido de H1 — tutorial de controles (botón "Controles" en menú y pausa, teclas leídas del input map), pantalla de carga con barra, consejos y controles (la primera vez espera Enter) y prueba de rendimiento para la PC del laboratorio (`scenes/benchmark.tscn`, recomienda calidad e informa en `user://benchmark.txt`). Capturas: `informes/capturas/paso24-carga.png`, `paso24-menu-controles.png`. **Hito H1 (demo de cursada) alcanzado.**
- ✅ Paso 25: modelo por 4 ruedas — el auto es un cuerpo rígido (`RigidBody3D`, motor de física Jolt) con suspensión por rayo en cada rueda (resorte + amortiguador), neumático simple por rueda con círculo de fricción, tracción trasera y frenos repartidos; cabecea y rola solo. Vuelta con piloto automático: 1:37.6. Capturas: `informes/capturas/paso25-ruedas.png`, `paso25-frenada.png`.
- ✅ Paso 26: neumáticos con la "fórmula mágica" de Pacejka (curva lateral y longitudinal, combinadas, con sensibilidad a la carga); cada rueda gira por su cuenta, así que puede patinar o bloquearse (limitadores provisorios hasta el ABS y el control de tracción); cálculo en 8 sub-pasos por cuadro para que sea estable. Vuelta con piloto automático: 1:38.4. Captura: `informes/capturas/paso26-curvas.png`.
- ✅ Paso 27: transferencia de peso — suspensión por eje, barras estabilizadoras (el auto rola la mitad) y anti-cabeceo; panel de cargas por rueda con la tecla F3 que compara la transferencia medida con la cuenta (coincide 97–100 %). Vuelta con piloto automático: 1:38.6. Capturas: `informes/capturas/paso27-curva.png`, `paso27-frenada.png`.
- ✅ Paso 28: aerodinámica — carga ½·ρ·ClA·v² repartida entre los ejes (0,77 × el peso a 200 km/h; el auto baja y agarra más cuanto más rápido) y arrastre en el centro de presión; el neumático quedó con el agarre mecánico (μ 1,75). Panel F3 con carga y arrastre. Vuelta con piloto automático: 1:40.1. Captura: `informes/capturas/paso28-curva-rapida.png`.
- ✅ Paso 29: aero activa 2026 — modo recta (alerones abiertos: ClA × 0,6, CdA × 0,7) en las zonas de recta de `tracks.json`, automático o manual con F, que se cierra solo al frenar, girar o salir de la zona; modo adelantamiento con G (+100 kW, 0,5 MJ por vuelta). Indicadores en el tablero, el volante y el panel F3. En la vuelta casi no se nota por el limitador en 8ª (se ajusta en el Paso 35). Captura: `informes/capturas/paso29-modo-recta.png`.
- ✅ Paso 30: frenos — ABS opcional que suelta y vuelve a apretar cada rueda (62 m desde 194 km/h; sin ABS las ruedas se bloquean: 76 m y el auto no dobla) y reparto de frenada ajustable con Z / X (45–75 %; muy atrás el auto se cruza al frenar en curva). Luz ABS y reparto en el tablero, el volante y el panel F3. Capturas: `informes/capturas/paso30-frenada-abs.png`, `paso30-bloqueo.png`.
- ✅ Paso 31: diferencial autoblocante (precarga + bloqueo según el par) y control de tracción con niveles 0–3 (opción y tecla T) que reemplaza al limitador provisorio: 0–100 en 2,78 s con TC 3 y 3,33 s sin TC; saliendo a fondo de una curva lenta, sin TC el auto hace un trompo, con TC 1 derrapa ~20° y con TC 3 sale derecho. Luz TC en el tablero, el volante y el panel F3. Capturas: `informes/capturas/paso31-tc-actuando.png`, `paso31-sin-tc.png`.
- ✅ Paso 32: ERS 2026 — batería de 4 MJ y MGU-K de 350 kW que despliega acelerando y recupera frenando (freno por cable: la frenada no cambia), tope de 8,5 MJ por vuelta, modos Ataque / Normal / Recarga con la tecla V, y el modo adelantamiento sale de la batería. 0–185 km/h en 4,93 s en Ataque contra 5,85 s sin ERS; en Normal la batería queda pareja vuelta a vuelta. Batería en el tablero, el volante y el panel F3. Capturas: `informes/capturas/paso32-recuperando.png`, `paso32-volante.png`.
- ✅ Paso 33: neumáticos — compuestos blando / medio / duro (se eligen en la pantalla de modo), temperatura y desgaste por rueda. Calientan con el deslizamiento y al rodar, y el agarre baja fríos, pasados o gastados (frenada 180→0: 54 m blando, 56 m medio, 57 m duro; 64 m con el medio frío y 65 m gastado). Un patinazo sin TC lleva las traseras de 90 a 131 °C. En una tanda el blando es el más rápido pero se pasa de temperatura atrás y se gasta tres veces más rápido que el duro. Widget de neumáticos en el HUD y temperatura y desgaste en el panel F3. Capturas: `informes/capturas/paso33-neumaticos.png`, `paso33-modos.png`.
- ✅ Paso 34: combustible — el motor quema según la potencia (20,7 g/s a fondo), el auto pesa seco + combustible y la masa baja a medida que se quema. Carga justa para el contrarreloj y 20 kg en práctica; sin combustible se apaga. Con el tanque lleno (70 kg) 0–180 en 5,17 s contra 5,00 s y frenada 180→0 en 56,4 m contra 55,6 m. Barra de combustible en el HUD y línea en el panel F3. Capturas: `informes/capturas/paso34-combustible.png`, `paso34-sin-combustible.png`.
- ✅ Paso 35: setup del auto — alerones delantero y trasero, altura del piso, resortes y barras por eje, presiones por eje y relación final, con datos en `data/setup.json` y guardado en `user://setup.json`. Se elige desde la elección de modo (y en práctica desde la pausa). El piso toca y pierde carga si el auto va muy bajo y blando. Con la caja larga (2,40) el auto llega a 243 km/h y la vuelta del piloto automático baja 1,6 s. Capturas: `informes/capturas/paso35-menu-setup.png`, `paso35-piso-toca.png`.
- ✅ Paso 36: daños — los golpes de trompa contra los muros dañan el alerón delantero (menos carga adelante: roto, el auto subvira mucho) y los golpes con una rueda la pinchan (poco agarre, arrastre, rueda más baja; el auto tira para ese lado). También pincha un neumático gastado del todo. R repara todo. Avisos en el HUD, alerón y pinchazos en el panel de neumáticos y en F3. Capturas: `informes/capturas/paso36-choque.png`, `paso36-aleron-pinchazo.png`.
- ✅ Paso 37: joystick y volante — mando por defecto (gatillos analógicos para acelerar y frenar, palanca para doblar, Start pausa, A / B / cruceta en los menús), curva y zona muerta de la dirección, pedales de volante de −1 a 1, vibración (golpes, daños, piso, pianos, ABS, patinaje) y una pantalla "Asignar controles" para cambiar cada tecla y botón (se guarda en `user://settings.json`). En F3, barras del acelerador y el freno. Capturas: `informes/capturas/paso37-asignar.png`, `paso37-f3-analogico.png`.
- ✅ Paso 38: línea de trazada — trayectoria ideal calculada al cargar (abre antes de la curva, toca el vértice, sale abierta: radios 1,43 veces más grandes que por el centro) con velocidad objetivo según el agarre y la aerodinámica del auto. Sobre el asfalto se pone verde, amarilla o roja según tu velocidad contra la objetivo: el rojo marca el punto de frenada. Tecla L: completa / sólo frenadas (por defecto) / apagada. Siguiéndola, el piloto automático da la vuelta en 1:18.450 sin salirse (1:25.217 por el centro). **Fase D cerrada: hito H2 alcanzado.** Capturas: `informes/capturas/paso38-linea-completa.png`, `paso38-solo-frenadas.png`.
- ✅ Paso 39: telemetría por vuelta — 20 muestras por segundo de velocidad, RPM, marcha, acelerador, freno, dirección y posición contra la distancia desde la meta. Se guardan las vueltas de la sesión y la mejor de la pista queda en `user://` para los próximos pasos (delta, gráficos, CSV, fantasma). En la pausa, "Telemetría" muestra una tabla por vuelta (tiempo, velocidades, % a fondo y frenando, cambios) y la velocidad de la última vuelta contra la mejor. Capturas: `informes/capturas/paso39-telemetria.png`, `paso39-pausa.png`.
- ✅ Paso 40: delta en vivo — debajo del cronómetro y en la pantalla del volante, cuánto vas ganando (verde) o perdiendo (rojo) contra la mejor vuelta (de la sesión o la guardada de la pista) en el mismo punto, con una barra de ±1 s y una flecha de tendencia. Al cruzar la meta queda 3 s el delta final, que coincide con la diferencia de tiempos. Capturas: `informes/capturas/paso40-delta-verde.png`, `paso40-delta-rojo-volante.png`, `paso40-final.png`.
- ✅ Paso 41: pantalla de análisis — desde Pausa → Telemetría → Análisis, dos vueltas a elegir (de la sesión o la guardada) con velocidad, delta acumulado, acelerador, freno, marcha, dirección y RPM contra la distancia, un cursor con los valores de las dos en ese punto y un mapa de la pista que marca en verde dónde se gana tiempo y en rojo dónde se pierde. Capturas: `informes/capturas/paso41-analisis.png`, `paso41-telemetria-boton.png`.
- ✅ Paso 42: exportación a CSV — en la pantalla de análisis, "CSV A y B" y "CSV todas" escriben en `user://telemetria/` un archivo con una fila por muestra (tiempo, distancia, velocidad, RPM, marcha, acelerador, freno, dirección, posición) y un resumen por vuelta, listos para Excel, Python o MATLAB. Separador y signo decimal en `data/telemetry.json` (coma decimal → `;` para Excel en español). Captura: `informes/capturas/paso42-exportar.png`.
- ✅ Paso 43: auto fantasma — un auto semitransparente repite la mejor vuelta (de la sesión o la guardada) al mismo tiempo que la vuelta en curso: si se escapa adelante, ahí se pierde tiempo. Se desvanece cuando está encima del auto, no choca y se muestra u oculta con H. La telemetría ahora graba también altura y rumbo (las vueltas guardadas antes se reconstruyen con la pista). **Fase E cerrada.** Capturas: `informes/capturas/paso43-fantasma.png`, `paso43-fantasma-cockpit.png`.
- ✅ Paso 44: IA que sigue la trazada — un piloto de la IA maneja un auto con la misma física que el del jugador sobre la línea de trazada, con la velocidad objetivo que sale de la curvatura y pedales proporcionales: da vueltas de 1:16,5 sin salidas ni golpes, y con ritmo 0,9 pasa las curvas al 90 %. En práctica, I suma o saca un rival. Capturas: `informes/capturas/paso44-ia.png`, `paso44-jugador-sigue.png`, `paso44-controles.png`.
- ✅ Paso 45: IA con niveles de dificultad, defensa y adelantamientos - cuatro niveles (Fácil 1:21,6 a Experto 1:16,5) elegibles en Opciones; los autos de la IA se siguen, se pasan por adentro en la frenada, defienden y se dejan lugar sin tocarse. Rebufo (hasta 25 % menos de resistencia) y modo adelantamiento sólo a menos de 1 s del de adelante. En práctica, I suma hasta 3 rivales. Capturas: `informes/capturas/paso45-rebufo.png`, `paso45-adelantamiento.png`, `paso45-opciones.png`.
- ✅ Paso 46: Colisiones entre autos y penalizaciones - los toques entre autos dañan como los muros y los juzgan comisarios: de atrás, culpa del que venía más rápido; de costado, del que se cerró; si no, incidente de carrera. El culpable recibe una advertencia o, si el golpe fue fuerte (o a la tercera advertencia), 5 s; las del jugador van a su cronómetro y todo se avisa en el HUD. La IA frena para la curva de su carril al pasar y ya no se toca en las pruebas. Capturas: `informes/capturas/paso46-choque.png`, `paso46-jugador.png`.
- ✅ Paso 47: Clasificación y carrera con la grilla 2026 completa (22 autos) - modos nuevos Clasificación (vueltas lanzadas; los tiempos de la IA se estiman por el ritmo de cada piloto, con semilla) y Carrera (largada detenida con los 22 autos de a dos, torre de tiempos en el HUD, bandera a cuadros y resultado con penalizaciones y vuelta más rápida). Desde el resultado de la clasificación, "Correr la carrera". Los autos lejos del jugador usan menos física y las piezas chicas lejanas no se dibujan (38 FPS con 22 autos en Intel UHD). Capturas: `informes/capturas/paso47-modos.png`, `paso47-clasificacion.png`, `paso47-grilla.png`, `paso47-carrera.png`, `paso47-resultado.png`.
- ✅ Paso 48: Pit lane con limitador de velocidad y paradas en boxes - calle de boxes a la izquierda de la recta principal con muro, garajes y un box por equipo; limitador de 80 km/h con la tecla P (+5 s por exceso); parada de 2,4 s con neumáticos nuevos (+4 s si hay que cambiar el alerón). En carrera la R ya no arregla el auto: hay que entrar a boxes. La IA para en boxes (una parada planeada en carreras de 8 vueltas o más, o por alerón roto o pinchazo) y la torre muestra "BOX". Capturas: `informes/capturas/paso48-calle.png`, `paso48-cenital.png`, `paso48-limitador.png`, `paso48-parada.png`, `paso48-carrera.png`.
- ⏳ Paso 49: Estrategia: cambio de compuesto, radio del ingeniero.
- Plan completo de 60 pasos en 8 fases: ver `GodotF126/ROADMAP.md`.
- ❌ Todavía no hay `.exe` (Paso 59).
