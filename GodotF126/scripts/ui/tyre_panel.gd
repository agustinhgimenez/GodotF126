class_name TyrePanel
extends Control
## Neumáticos en el HUD (Paso 33), a la izquierda del tablero: el compuesto (círculo con su
## color y letra) y las 4 ruedas vistas desde arriba, cada una pintada según su temperatura
## (celeste fría, verde en la ventana del compuesto, roja pasada) con los °C y el desgaste.
## Abajo (Paso 34): barra de combustible con los kg y las vueltas que alcanzan.

const SIZE := Vector2(132, 184)
const COLOR_FUEL := Color(0.95, 0.55, 0.15)
const COLOR_COLD := Color(0.25, 0.55, 1.0)
const COLOR_OK := Color(0.2, 0.75, 0.35)
const COLOR_HOT := Color(1.0, 0.3, 0.2)
const COLOR_DIM := Color(1.0, 1.0, 1.0, 0.7)
const TYRE_SIZE := Vector2(46, 48)
## Esquina de cada rueda (mismo orden que CarController.wheels: DI, DD, TI, TD).
const TYRE_SPOTS := [Vector2(14, 44), Vector2(72, 44), Vector2(14, 100), Vector2(72, 100)]

var _car: CarController
var _font: Font
var _panel: StyleBoxFlat


func _ready() -> void:
	custom_minimum_size = SIZE
	size = SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_font = ThemeDB.fallback_font
	_panel = StyleBoxFlat.new()
	_panel.bg_color = Dashboard.COLOR_PANEL
	_panel.set_corner_radius_all(14)


func bind_car(car: CarController) -> void:
	_car = car


func _process(_delta: float) -> void:
	if _car != null:
		queue_redraw()


func _draw() -> void:
	draw_style_box(_panel, Rect2(Vector2.ZERO, SIZE))
	if _car == null or _car.wheels.size() != 4:
		return
	var tyres := _car.tyres
	var compound := tyres.compound()
	draw_string(_font, Vector2(14, 27), "NEUM.", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, COLOR_DIM)
	var badge := Vector2(SIZE.x - 30, 22)
	draw_circle(badge, 14.0, tyres.compound_color())
	draw_circle(badge, 9.0, Dashboard.COLOR_PANEL.lerp(Color.BLACK, 0.6))
	HudDraw.draw_text_centered(self, _font, str(compound.get("short", "?")), badge + Vector2(0, 1), 14, Color.WHITE)
	for i in 4:
		var wheel := _car.wheels[i]
		var rect := Rect2(TYRE_SPOTS[i], TYRE_SIZE)
		draw_rect(rect, temperature_color(tyres.temperature_state(wheel.temperature)))
		var center := rect.get_center()
		HudDraw.draw_text_centered(self, _font, "%d°" % roundi(wheel.temperature), center + Vector2(0, -8), 15, Color.WHITE)
		HudDraw.draw_text_centered(self, _font, "%d %%" % roundi(wheel.wear * 100.0), center + Vector2(0, 12), 12, Color.WHITE)
	var fuel := _car.fuel
	var bar := Rect2(14, 156, SIZE.x - 28, 18)
	draw_rect(bar, HudDraw.COLOR_OFF)
	var ratio := fuel.kg / fuel.capacity if fuel.capacity > 0.0 else 0.0
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * ratio, bar.size.y)), Color(COLOR_FUEL, 0.8))
	var text := "SIN COMB." if fuel.is_empty() else "%.1f kg · %d v" % [fuel.kg, floori(fuel.laps_left())]
	HudDraw.draw_text_centered(self, _font, text, bar.get_center() + Vector2(0, 1), 13,
		COLOR_HOT if fuel.is_empty() else Color.WHITE)


## state: TyreCompounds.temperature_state() (−1 frío, 0 en la ventana, 1 pasado).
static func temperature_color(state: int) -> Color:
	if state < 0:
		return Color(COLOR_COLD, 0.85)
	if state > 0:
		return Color(COLOR_HOT, 0.85)
	return Color(COLOR_OK, 0.85)
