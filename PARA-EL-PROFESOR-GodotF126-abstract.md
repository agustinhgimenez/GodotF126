# GodotF126 — Simulador de Fórmula 1 — formalización del proyecto

**Autor:** Agustín Giménez
**Materia:** 350 — Ingeniería de Software Avanzado (plan 2015)
**Motor:** Godot 4.3 (GDScript)

---

## Abstract

GodotF126 es un simulador de Fórmula 1 en tercera persona, pensado para entrenar el manejo de un auto de monoplaza en un circuito cerrado. El jugador controla aceleración, freno y dirección; el sistema responde con una física simplificada de agarre, deslizamiento y límites de velocidad en curva. Para la materia se entrega una demo jugable: un auto, un circuito, telemetría básica en pantalla y un modo de vuelta cronometrada. El motor elegido es Godot 4.

## Descripción breve

- **Tipo de producto:** simulador de entrenamiento + juego de entretenimiento. No es un simulador crítico (no hay riesgo para personas ni certificación).
- **Entregable de cursada (demo):**
  - 1 auto (Franco Colapinto, Alpine, grilla 2026 cargada desde JSON).
  - 1 pista: Bakú (Azerbaiyán), versión geométrica simplificada, no el trazado oficial FIA.
  - Física arcade: aceleración, freno, marcha atrás, dirección dependiente de la velocidad, agarre y derrape con freno de mano.
  - HUD: velocidad, piloto/equipo, pista; luego cronómetro y telemetría.
  - Flujo mínimo: menú → pista → resultado.
- **Fuera de alcance inicial:** multijugador, IA de 22 autos, todas las pistas del calendario, clima, estrategia de boxes completa, modelos 3D detallados de los 22 pilotos.
- **Por qué Godot:** gratuito y de código abierto (sin licencias ni regalías), exporta a Windows, liviano y apto para un solo desarrollador.
- **Metodología:** desarrollo iterativo e incremental con un ROADMAP de 60 pasos agrupados en 8 fases y 4 hitos; cada paso deja una versión jugable. El hito 1 (demo de cursada) incluye caja de cambios manual de 8 marchas, tablero con marcha, RPM y luces de cambio, volante 3D en el cockpit, sonido de motor, selección de escudería y piloto, y vuelta cronometrada.

## Encuadre en el programa

| Unidad | Tema | Aplicación en GodotF126 |
|---|---|---|
| I | Tipos de producto: juegos, juegos serios, simuladores | Simulador de entrenamiento con componente de entretenimiento |
| II | Diseño y alcance | Documento de alcance, demo acotada, ROADMAP iterativo |
| III | Guión mínimo | Flujo menú → selección de piloto → carrera → resultado |
| IV | Física | Modelo arcade de aceleración, frenado, agarre y derrape |
| V | Nivel y HUD | Circuito de Bakú generado por código, HUD de velocidad/tiempos/telemetría |

## Estado al momento de la entrega

- Completos y jugables en el editor de Godot: Paso 0 (esqueleto), Paso 1 (auto con WASD, pista Bakú, HUD) y Paso 2 (cronómetro por sectores, mejor vuelta, récord guardado, tres cámaras).
- Próximo: motor con RPM y caja de cambios manual.
