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
Apretar **F5** (o el botón ▶ arriba a la derecha). Arranca el menú principal: **Jugar** (Enter o clic) carga la pista.

| Tecla | Acción |
|-------|--------|
| **W** | Acelerar |
| **S** | Frenar (en caja automática, con el auto quieto: marcha atrás) |
| **A / D** | Girar izquierda / derecha |
| **E / Q** | Subir / bajar marcha (caja manual: R, N, 1–8) |
| M | Alternar caja manual / automática |
| **Espacio** | Freno de mano |
| C | Cambiar cámara (TV / cercana / cockpit) |
| R | Volver a la largada (anula la vuelta) |
| Esc | Volver al menú (en el menú: salir) |

También funcionan las flechas del teclado.

## 4. Si algo falla
- **Pantalla negra o error de Vulkan**: el proyecto ya usa el renderer *GL Compatibility*. Actualizar drivers de video.
- **"Parse error" en un script**: verificar que la versión sea 4.7 (menú *Help → About*). Godot 3.x no abre este proyecto.
- **El auto no responde**: hacer clic dentro de la ventana del juego para darle foco.

## Contenido de esta carpeta
| Archivo / carpeta | Qué es |
|---|---|
| `GodotF126/` | Proyecto Godot (abrir `project.godot`) |
| `GodotF126/ROADMAP.md` | Plan iterativo, pasos 0 a 9 |
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
- ⏳ Paso 12: selección de escudería y piloto.
- Plan completo de 60 pasos en 8 fases: ver `GodotF126/ROADMAP.md`.
- ❌ Todavía no hay `.exe` (Paso 59).
