# GodotF126 — Guía para la defensa

## 1. Qué llevar

- **Notebook** con el `.exe` probado esa mañana (calidad Alta, una carrera de 2 vueltas completa).
- **Pendrive** con `GodotF126.exe` (105 MB), el video de la demo, el informe final y el manual en PDF.
- **Mando de Xbox** si se tiene (opcional).
- La dirección de la versión web anotada: [ingsoftwareavanzado.agustingimenez.ar](https://ingsoftwareavanzado.agustingimenez.ar/).

## 2. Orden de la presentación (~15 minutos)

| Tiempo | Qué | Material |
|---|---|---|
| 0–2 min | Problema y alcance: de la demo de la formalización al juego completo; los 4 hitos | Informe final, secciones 1–2 |
| 2–9 min | Demo en vivo: práctica con línea ideal y F3, pausa y análisis, carrera de 22, resultado y repetición | `.exe` (guion: `guion-video-demo.md`) |
| 9–12 min | Ingeniería: arquitectura por componentes, datos en JSON, pruebas (GUT + regresiones), rendimiento | Informe final, secciones 3, 6 y 7; el editor de Godot con el panel GUT |
| 12–14 min | Metodología: 60 pasos, ROADMAP con verificación por paso, riesgos | `ROADMAP.md`, `git log --oneline` |
| 14–15 min | Limitaciones y cierre; mostrar la versión web | Navegador |

Para mostrar los tests en vivo: abrir el proyecto en el editor → panel **GUT** abajo → **Run All** (~17 s, 67/67 en verde).

## 3. Plan B

| Si falla… | Hacer |
|---|---|
| La notebook o el `.exe` | El `.exe` del pendrive en una PC del laboratorio (no requiere instalar nada) |
| La PC del laboratorio va lenta | Antes de la demo: `GodotF126.exe -- --benchmark` (~15 s) y usar la calidad que recomienda; jugar práctica en vez de carrera |
| No hay forma de correr el juego | La versión web en cualquier navegador o el video del pendrive |
| No hay internet | El `.exe` funciona sin conexión |

## 4. Preguntas probables

**¿Por qué Godot y no Unity o Unreal?**
Libre y sin licencias, liviano (el `.exe` pesa 105 MB), exporta a Windows y a la web desde el mismo proyecto, GDScript con tipado estático es rápido de iterar y trae Jolt como motor de física. Unreal pide hardware que las PC del laboratorio no tienen.

**¿La física es real o arcade?**
Es un modelo por ruedas: cada una tiene suspensión, carga propia y un neumático con la fórmula mágica de Pacejka (fuerza según el deslizamiento y la deriva, combinadas en el círculo de fricción). Encima van la transferencia de peso, la carga aerodinámica que crece con la velocidad al cuadrado, el tren motriz con caja, diferencial, control de tracción y ERS, y el estado del auto (temperatura, desgaste, combustible, daños). Es simplificado respecto de un simulador profesional (sin modelo térmico de carcasa ni flexión), pero las magnitudes dan bien: 1,8 g en curva a 120 km/h, 0–100 en 2,8 s.

**¿Por qué 8 sub-pasos por cuadro?**
La curva de Pacejka es rígida: con un solo cálculo a 60 Hz el auto oscilaba de un cuadro al otro y quieto se deslizaba. Partir el cuadro en 8 y promediar la fuerza lo vuelve estable sin subir la frecuencia de toda la física.

**¿Cómo funciona la IA?**
Hay una línea ideal calculada al cargar la pista (curvatura mínima dentro de los límites) con una velocidad objetivo por punto, sacada del mismo modelo de agarre del auto. Cada piloto de la IA maneja el mismo auto físico con acelerador, freno y volante: no hace trampa con la física. El nivel cambia qué porcentaje de esa velocidad usa y cuántos errores comete. En tráfico decide pasadas, defiende y respeta banderas; su estrategia de boxes sale del desgaste.

**¿Cómo corren 22 autos con física completa?**
Nivel de detalle por distancia: los autos lejanos calculan los neumáticos con menos sub-pasos y deciden cada dos cuadros. En la notebook da 47 FPS en carrera. El Paso 58 bajó un 10 % el costo sin cambiar ningún resultado.

**¿Cómo saben que una optimización no rompió nada?**
La carrera de prueba es determinista: con la misma semilla y `--fixed-fps 60` da siempre la misma clasificación y los mismos 22 tiempos de llegada (Norris 2:41.667). Se corre antes y después del cambio y tiene que dar idéntica. Lo mismo con la vuelta del piloto automático y la huella de la pista generada.

**¿Qué prueban los tests?**
67 tests con GUT: la caja de cambios, el cronómetro y los sectores, que los 20 JSON carguen y sean coherentes (cada piloto tiene equipo, cada pista valida), los neumáticos y el clima, la estrategia, los puntos y el campeonato, y la física del auto real en una escena de prueba (acelera, frena, reversa, dobla).

**¿Qué cambió del plan original?**
La formalización era una demo: un auto, una pista, física arcade. Se armó el ROADMAP de 60 pasos con 4 hitos y se cumplió en orden. Entraron cosas que estaban fuera de alcance (IA de 22, segunda pista, clima, estrategia) porque la arquitectura por componentes y datos lo permitió sin rehacer lo anterior. Quedaron afuera el multijugador y los modelos 3D detallados.

**¿Qué fue lo más difícil?**
Tres cosas: hacer estable el neumático de Pacejka a 60 Hz (sub-pasos e integración implícita del giro de la rueda); que la IA pase sin chocarse (decidir el lado, abandonar la pasada y dejar lugar); y un cierre de Godot al salir de una carrera con contactos, que se rastreó hasta el orden en que Jolt liberaba los cuerpos y se resolvió sacándolos del espacio de física antes.

**¿Las pistas son las reales?**
No: son trazados inventados inspirados en Bakú y Buenos Aires. Las genera `TrackGenerator` desde una lista de puntos en un JSON, con validaciones (que no se cruce, radios posibles, que la largada no quede en curva). Agregar una pista es escribir datos.

**¿Cómo se relaciona con las unidades de la materia?**
Tipo de producto (simulador de entrenamiento: telemetría, línea ideal, fantasma), diseño y alcance (formalización, ROADMAP, hitos), guion (flujo de menús, campeonato, radio), física (modelo por ruedas) y nivel/HUD (pistas generadas, ciudad, tablero, torre, banderas). Está en la sección 10 del informe final.

**¿Por qué la versión web va más lenta?**
En el navegador el código corre en WebAssembly sin hilos y sin las optimizaciones nativas; la carrera de 22 es pura CPU. La práctica va bien (~40 FPS); para la carrera conviene el `.exe`.

**¿Qué harían a continuación?**
Física simplificada para los autos lejanos (60 FPS con 22), probar con un volante real, pistas con trazados oficiales y multijugador local.
