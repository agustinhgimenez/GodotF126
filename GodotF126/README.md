# GodotF126 (proyecto Godot)

Simulador de Fórmula 1 en tercera persona hecho con **Godot 4.7 + GDScript**. Materia 350 — Ingeniería de Software Avanzado.

## Abrir y jugar
1. Abrir Godot 4.7 (Standard, no hace falta la versión .NET). Probado con 4.7.2.
2. **Import** → elegir `project.godot` de esta carpeta → *Import & Edit*.
3. Apretar **F5** (o el botón ▶ arriba a la derecha).

## Controles
| Tecla | Acción |
|-------|--------|
| W / ↑ | Acelerar |
| S / ↓ | Frenar (en automática, con el auto quieto: marcha atrás) |
| A / ← | Girar a la izquierda |
| D / → | Girar a la derecha |
| E / Q | Subir / bajar marcha (manual: R ↔ N ↔ 1 … 8) |
| M | Alternar caja manual / automática |
| Espacio | Freno de mano (derrape) |
| C | Cambiar cámara (TV / cercana / cockpit) |
| R | Volver a la largada (anula la vuelta) |
| Esc | Salir |

## Estructura
```
GodotF126/
  project.godot        configuración, input map, escena principal
  icon.svg
  ROADMAP.md           plan de 60 pasos en 8 fases
  data/
    grid_2026.json     grilla 2026 (11 equipos, 22 pilotos)
    tracks.json        metadatos de pistas
    car.json           masa, curva de torque, RPM, relaciones de marcha, tablero
  scenes/
    main.tscn          Main: entorno + BakuTrack + Car + HUD
    car.tscn           CharacterBody3D con componentes Engine y Gearbox, cámara 3ra persona
    tracks/baku.tscn   nodo con baku_track.gd
  scripts/
    main.gd            carga datos, spawnea auto, conecta pista/cronómetro/HUD
    car_controller.gd  física arcade y cámaras; usa motor y caja para acelerar
    car/car_engine.gd  motor: RPM, curva de torque, limitador, freno motor
    car/gearbox.gd     caja secuencial 8 marchas + N + R, manual (levas) o automática
    car/steering_wheel.gd  volante 3D del cockpit: giro, LEDs y pantalla
    baku_track.gd      genera la pista y los checkpoints por código
    lap_timer.gd       vueltas, sectores, mejor vuelta y récord
    hud.gd             tiempos, datos de piloto/pista, mensajes; contiene el tablero
    ui/dashboard.gd    tablero: luces de cambio, marcha, RPM, velocímetro con aguja
    ui/wheel_screen.gd pantalla del volante (se dibuja en un SubViewport)
    ui/hud_draw.gd     utilidades de dibujo compartidas (texto, colores de luces)
```

## Decisiones de diseño
- **Pista generada por código**: los puntos de control se suavizan (remuestreo + Chaikin) y se arma el asfalto y los muros como mallas; los muros usan colisión trimesh. Es fácil de modificar sin tocar el editor 3D.
- **Datos en JSON**: la grilla, las pistas y el auto están separados del código para poder ajustarlos sin reescribir nada.
- **Auto por componentes**: `Engine` (`CarEngine`) y `Gearbox` son nodos hijos del auto. El controlador les pide torque y relación; así la caja manual (Paso 4) y el sonido (Paso 9) se enchufan sin agrandar `car_controller.gd`.
- **Renderer GL Compatibility**: corre en PCs de laboratorio sin Vulkan. Se puede pasar a Forward+ en *Project Settings → Rendering → Renderer*.
- La pista de Bakú es un **placeholder geométrico**, no el trazado oficial FIA.

## Estado
Pasos 0 a 6 completos. Ver [ROADMAP.md](ROADMAP.md). Todavía **no hay ejecutable .exe** (eso es el Paso 59).
