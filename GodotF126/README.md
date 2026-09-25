# GodotF126 (proyecto Godot)

Simulador de Fórmula 1 en tercera persona hecho con **Godot 4.3 + GDScript**. Materia 350 — Ingeniería de Software Avanzado.

## Abrir y jugar
1. Abrir Godot 4.3 (Standard, no hace falta la versión .NET).
2. **Import** → elegir `project.godot` de esta carpeta → *Import & Edit*.
3. Apretar **F5** (o el botón ▶ arriba a la derecha).

## Controles
| Tecla | Acción |
|-------|--------|
| W / ↑ | Acelerar |
| S / ↓ | Frenar / marcha atrás |
| A / ← | Girar a la izquierda |
| D / → | Girar a la derecha |
| Espacio | Freno de mano (derrape) |
| C | Cambiar cámara (TV / cercana / cockpit) |
| R | Volver a la largada (anula la vuelta) |
| Esc | Salir |

## Estructura
```
GodotF126/
  project.godot        configuración, input map, escena principal
  icon.svg
  ROADMAP.md           pasos 0–9
  data/
    grid_2026.json     grilla 2026 (11 equipos, 22 pilotos)
    tracks.json        metadatos de pistas
  scenes/
    main.tscn          Main: entorno + BakuTrack + Car + HUD
    car.tscn           CharacterBody3D, carrocería de cajas, cámara 3ra persona
    tracks/baku.tscn   nodo con baku_track.gd
  scripts/
    main.gd            carga datos, spawnea auto, conecta pista/cronómetro/HUD
    car_controller.gd  física arcade y cámaras
    baku_track.gd      genera la pista y los checkpoints por código
    lap_timer.gd       vueltas, sectores, mejor vuelta y récord
    hud.gd             velocímetro, tiempos, datos de piloto/pista
```

## Decisiones de diseño
- **Pista generada por código**: los puntos de control se suavizan (remuestreo + Chaikin) y se arma el asfalto y los muros como mallas; los muros usan colisión trimesh. Es fácil de modificar sin tocar el editor 3D.
- **Datos en JSON**: la grilla y las pistas están separadas del código para poder agregar selección de piloto (Paso 3) sin reescribir nada.
- **Renderer GL Compatibility**: corre en PCs de laboratorio sin Vulkan. Se puede pasar a Forward+ en *Project Settings → Rendering → Renderer*.
- La pista de Bakú es un **placeholder geométrico**, no el trazado oficial FIA.

## Estado
Pasos 0, 1 y 2 completos. Ver [ROADMAP.md](ROADMAP.md). Todavía **no hay ejecutable .exe** (eso es el Paso 8).
