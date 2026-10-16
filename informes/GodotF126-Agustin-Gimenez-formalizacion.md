# GodotF126 — Simulador de Fórmula 1 — formalización del proyecto

**Autor:** Agustín Giménez
**Materia:** 350 — Ingeniería de Software Avanzado (plan 2015)
**Motor / lenguaje:** Godot 4.7 / GDScript
**Fecha:** septiembre de 2026

---

## 1. Abstract

GodotF126 es un simulador de Fórmula 1 en tercera persona, pensado para entrenar el manejo de un auto de monoplaza en un circuito cerrado. El jugador controla aceleración, freno y dirección; el sistema responde con una física simplificada de agarre, deslizamiento y límites de velocidad en curva. Para la materia se entrega una demo jugable: un auto, un circuito, telemetría básica en pantalla y un modo de vuelta cronometrada. El motor elegido es Godot 4.

## 2. Descripción

### 2.1 Tipo de producto
Simulador de entrenamiento + juego de entretenimiento. No es un simulador crítico: un error del sistema no pone en riesgo personas ni bienes, y no requiere certificación. Esto permite priorizar jugabilidad y claridad de la física por sobre la fidelidad absoluta.

### 2.2 Objetivo
Que el jugador aprenda conceptos básicos de conducción de un monoplaza: puntos de frenado, trazada, pérdida de agarre al girar a alta velocidad y control del derrape, en un entorno seguro y repetible.

### 2.3 Usuarios
- Aficionados a la Fórmula 1 que quieren una experiencia simple de manejo.
- Uso académico: demostración de ingeniería de software aplicada a juegos y simuladores.

## 3. Alcance

### 3.1 Entregable de cursada (demo)
- 1 auto: Franco Colapinto (Alpine), con datos de la grilla 2026 en `data/grid_2026.json`.
- 1 pista: Bakú (Azerbaiyán), versión geométrica simplificada, **no** el trazado oficial FIA.
- Física arcade jugable.
- HUD con velocidad, piloto/equipo y pista; cronómetro de vuelta y telemetría básica.
- Flujo mínimo: menú → pista → resultado.

### 3.2 Fuera de alcance inicial
- Multijugador.
- IA para 22 autos (como mucho, 1 a 3 rivales simples en el Paso 6).
- Todas las pistas del calendario.
- Clima, desgaste de neumáticos, estrategia de boxes completa.
- Modelos 3D detallados de los 22 pilotos desde el día 1.

## 4. Justificación del motor
| Criterio | Godot 4 |
|---|---|
| Costo / licencia | Gratuito, MIT, sin regalías |
| Plataforma de entrega | Exporta a Windows (.exe) |
| Curva de aprendizaje | GDScript simple, editor liviano |
| Equipo | Adecuado para un solo desarrollador |
| Física | Motor 3D integrado (`CharacterBody3D`, colisiones) |

## 5. Encuadre en las unidades del programa
| Unidad | Tema | Aplicación |
|---|---|---|
| I | Tipos de producto (entretenimiento, juegos serios, simuladores de entrenamiento) | GodotF126 se clasifica como simulador de entrenamiento no crítico con componente de entretenimiento |
| II | Diseño y alcance | Definición de demo acotada, lista explícita de fuera de alcance, ROADMAP de 10 pasos |
| III | Guión mínimo | Flujo: menú → selección de piloto → vuelta cronometrada → pantalla de resultado |
| IV | Física | Modelo arcade: aceleración con caída cerca de la velocidad máxima, frenado, dirección que se endurece con la velocidad, agarre lateral y derrape con freno de mano |
| V | Nivel y HUD | Circuito generado por código (asfalto, muros con colisión, largada, escenografía) y HUD de velocidad, piloto y pista |

## 6. Arquitectura (versión actual)
- `main.tscn` — escena raíz: entorno (cielo, sol), pista, auto y HUD.
- `car_controller.gd` — control y física del auto; cámara en tercera persona.
- `baku_track.gd` — generación procedural de la pista a partir de puntos de control suavizados.
- `hud.gd` — interfaz de usuario.
- `data/*.json` — datos separados del código (grilla 2026, pistas).

## 7. Metodología y plan
Desarrollo iterativo e incremental. Cada paso deja una versión jugable:

| Paso | Contenido | Estado |
|---|---|---|
| 0 | Esqueleto del proyecto | Hecho |
| 1 | Auto con WASD + pista Bakú + HUD | Hecho |
| 2 | Cronómetro y línea de meta | Siguiente |
| 3 | Menú y selección de piloto | Pendiente |
| 4 | Telemetría | Pendiente |
| 5 | Mejor física | Pendiente |
| 6 | IA simple | Pendiente |
| 7 | Segunda pista | Pendiente |
| 8 | Export Windows (.exe) | Pendiente |
| 9 | Pulido para la materia | Pendiente |

## 8. Riesgos
| Riesgo | Mitigación |
|---|---|
| Física demasiado compleja para el tiempo disponible | Modelo arcade primero; mejoras en el Paso 5 |
| Crecimiento del alcance (más pistas, más autos) | Lista explícita de fuera de alcance; una pista hasta el Paso 7 |
| Hardware del laboratorio sin Vulkan | Renderer GL Compatibility |
| Datos no incluidos en el export | Filtro `*.json` en el preset de export (Paso 8) |

## 9. Estado actual
Los Pasos 0 a 3 están implementados (base, manejo, cronómetro y cámaras, motor con RPM) y se prueban abriendo `GodotF126/project.godot` en Godot 4.7 y apretando F5. Todavía no existe un ejecutable `.exe`; se generará en el Paso 59.
