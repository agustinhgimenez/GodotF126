# GodotF126 — Guion del video de demostración

Duración objetivo: **5 a 6 minutos**. Grabar con el `.exe` (`GodotF126/export/GodotF126.exe`) en pantalla completa a 1280×720 o más, con el sonido del juego. Para grabar en Windows: **Win + Alt + R** (Xbox Game Bar) o OBS. Narrar en vivo o grabar la voz después.

Antes de grabar: en Opciones, calidad **Alta** y las ayudas de la tabla de abajo; cerrar el resto de los programas y correr una carrera de prueba para que no aparezca nada inesperado.

| Ajuste | Valor para el video |
|---|---|
| Línea ideal (tecla **L** en pista) | Completa en la práctica, apagada en la carrera |
| Caja | Automática (manejar más tranquilo mientras se narra) |
| Control de tracción / ABS | 3 / encendido |
| Nivel de la IA | Medio |

---

## Escena 1 — Presentación (0:00–0:30)

**En pantalla:** el menú principal con el auto girando.
**Decir:** "GodotF126 es un simulador de Fórmula 1 de la temporada 2026, hecho en Godot 4 para Ingeniería de Software Avanzado. Tiene física por cuatro ruedas, los 22 autos de la grilla con inteligencia artificial, telemetría, boxes, clima y campeonato."

## Escena 2 — Elegir sesión (0:30–1:10)

**En pantalla:** Jugar → elegir **Práctica libre** → mostrar con ← / → la pista (Bakú) y el neumático → Escuderías: pasar por 2 o 3 equipos → elegir piloto → pantalla de carga.
**Decir:** "Se elige el modo, la pista, el clima, el neumático y el piloto. Los datos de la grilla, las pistas y el auto están en archivos JSON: el juego se ajusta sin tocar código."

## Escena 3 — Práctica y física (1:10–2:20)

**En pantalla:** una vuelta en cámara cockpit siguiendo la línea ideal (verde, amarillo, rojo). En una recta, **C** para pasar por las cámaras; volver al cockpit.
**Decir:** "Cada rueda tiene su suspensión y un modelo de neumático de Pacejka; hay transferencia de peso, carga aerodinámica y la aerodinámica activa de 2026. La línea indica dónde acelerar, levantar y frenar."
**Mostrar:** **F3** un momento (panel de telemetría: cargas, temperaturas, ERS) y el delta en vivo contra la mejor vuelta.

## Escena 4 — Pausa, telemetría y setup (2:20–3:00)

**En pantalla:** **Esc** → Telemetría → Análisis (comparación de dos vueltas, curvas de velocidad) → volver → Setup del auto (mover un alerón) → Volver al menú.
**Decir:** "La telemetría guarda cada vuelta y permite compararlas, o exportarlas a CSV. El setup cambia alerones, suspensión, presiones y la relación final."

## Escena 5 — Carrera de 22 autos (3:00–4:30)

**En pantalla:** Jugar → **Carrera** (2 vueltas) → semáforo y largada → primeras curvas con tráfico → cámara exterior (**C**) para que se vean los rivales → señalar la torre de tiempos a la izquierda → una pasada o una defensa de la IA.
**Decir:** "Los otros 21 autos los maneja una IA con la misma física: sigue la línea ideal, aprovecha el rebufo, pasa y defiende. Los comisarios analizan los toques y sancionan; hay banderas y Safety Car, y cada auto tiene su estrategia de boxes."
**Si se puede:** entrar a boxes (**P** limitador a 80 km/h, el auto para solo y cambia neumáticos) para mostrar la parada.
Dos vueltas en Bakú son ~3 minutos (el ganador llega en ~2:42): dejarla correr entera y recortar en la edición.

## Escena 6 — Resultado y repetición (4:30–5:15)

**En pantalla:** la clasificación final con los puntos (**← / →** pasa a sanciones y equipos) → Ver repetición → **C** hasta la cámara de TV, **Q / E** para cambiar de auto, **↑** para acelerar, **I** para saltar a un incidente.
**Decir:** "Al terminar, la clasificación da los puntos del campeonato y la repetición permite ver la carrera desde cualquier auto."

## Escena 7 — Versión web y cierre (5:15–6:00)

**En pantalla:** el navegador en [ingsoftwareavanzado.agustingimenez.ar](https://ingsoftwareavanzado.agustingimenez.ar/), el menú cargado y unos segundos de práctica.
**Decir:** "El juego también se puede jugar en el navegador, sin instalar nada. Se desarrolló en 60 pasos incrementales, con 67 tests automáticos y pruebas de regresión en cada paso. Gracias."

---

## Después de grabar

- Recortar esperas (cargas, tramos de carrera sin acción).
- Exportar en MP4 (H.264), 1080p o 720p, 30 o 60 FPS.
- Guardar una copia en el pendrive junto con el `.exe` (por si falla la demo en vivo).
