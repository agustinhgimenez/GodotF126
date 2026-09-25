# GodotF126 — Simulador de Fórmula 1

Proyecto de la materia **350 — Ingeniería de Software Avanzado** (plan 2015).
Autor: **Agustín Giménez**.

GodotF126 es un videojuego-simulador de Fórmula 1 en tercera persona hecho con **Godot 4.3** y **GDScript**. La demo de cursada tiene un auto (Franco Colapinto, Alpine), una pista (Bakú, placeholder geométrico), física arcade jugable y HUD.

## 1. Instalar Godot 4.3
1. Entrar a <https://godotengine.org/download/archive/> y buscar **4.3-stable**.
2. Descargar **Godot Engine – Windows – Standard** (64 bit). **No** hace falta la versión .NET/C#.
3. Descomprimir el `.zip` en una carpeta, por ejemplo `C:\Godot\`.
4. Ejecutar `Godot_v4.3-stable_win64.exe`. No requiere instalación.

## 2. Abrir el proyecto
1. En el *Project Manager* de Godot, apretar **Import**.
2. Elegir el archivo:
   `C:\Users\CriptoAprendices\Desktop\Proyecto Ing Software Avanzado\GodotF126\project.godot`
3. Apretar **Import & Edit**. La primera vez Godot tarda unos segundos importando.

## 3. Jugar
Apretar **F5** (o el botón ▶ arriba a la derecha).

| Tecla | Acción |
|-------|--------|
| **W** | Acelerar |
| **S** | Frenar / marcha atrás |
| **A / D** | Girar izquierda / derecha |
| **Espacio** | Freno de mano |
| C | Cambiar cámara (TV / cercana / cockpit) |
| R | Volver a la largada (anula la vuelta) |
| Esc | Salir |

También funcionan las flechas del teclado.

## 4. Si algo falla
- **Pantalla negra o error de Vulkan**: el proyecto ya usa el renderer *GL Compatibility*. Actualizar drivers de video.
- **"Parse error" en un script**: verificar que la versión sea 4.3 (menú *Help → About*). Godot 3.x no abre este proyecto.
- **El auto no responde**: hacer clic dentro de la ventana del juego para darle foco.

## Contenido de esta carpeta
| Archivo / carpeta | Qué es |
|---|---|
| `GodotF126/` | Proyecto Godot (abrir `project.godot`) |
| `GodotF126/ROADMAP.md` | Plan iterativo, pasos 0 a 9 |
| `PARA-EL-PROFESOR-GodotF126-abstract.md` | Abstract + descripción breve para entregar |
| `informes/GodotF126-Agustin-Gimenez-formalizacion.md` | Formalización completa del proyecto |
| `PARA-EL-AGENTE-LOCAL.md` | Instrucciones para seguir desarrollando con un agente de IA |
| `DESTINO-WINDOWS.md` | Rutas y ubicación de archivos en Windows |

## Estado
- ✅ Paso 0: esqueleto del proyecto.
- ✅ Paso 1: auto manejable con WASD, pista de Bakú, HUD.
- ✅ Paso 2: cronómetro por sectores, mejor vuelta, récord guardado, cambio de cámara.
- ⏳ Paso 3: motor con RPM. Después: caja manual de 8 marchas, tablero con marcha/RPM/luces de cambio, volante 3D y manos del piloto.
- Plan completo de 60 pasos en 8 fases: ver `GodotF126/ROADMAP.md`.
- ❌ Todavía no hay `.exe` (Paso 8).
