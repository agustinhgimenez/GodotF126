class_name TyreCompounds
extends RefCounted
## Compuestos, temperatura y desgaste de los neumáticos (Paso 33). El compuesto (blando /
## medio / duro, datos en "tyre_compounds" de data/car.json) es el mismo para las 4 ruedas;
## la temperatura y el desgaste son de cada rueda (CarWheel.temperature / wear).
## - Calor: la potencia de deslizamiento del neumático (|Fx · velocidad de patinada| +
##   |Fy · velocidad lateral|, que CarWheel junta en los sub-pasos) más el de rodar (la
##   carcasa que se deforma). Se enfría hacia la temperatura de la pista, más rápido cuanto
##   más rápido va.
## - Agarre: compuesto × temperatura × desgaste. Dentro de la ventana del compuesto
##   (temp_min–temp_max) no pierde nada; afuera pierde en forma cuadrática (frío o pasado).
## - Desgaste: proporcional a la energía de deslizamiento (MJ) y más rápido pasado de
##   temperatura; con el neumático gastado del todo pierde wear_grip_loss de agarre.

signal compound_changed(compound_name: String)

var compounds: Array = [
	{"id": "soft", "name": "Blando", "short": "S", "color": "#E8302A", "grip": 1.025, "temp_min": 60.0, "temp_max": 105.0, "wear_per_mj": 0.04},
	{"id": "medium", "name": "Medio", "short": "M", "color": "#F2C230", "grip": 1.0, "temp_min": 70.0, "temp_max": 120.0, "wear_per_mj": 0.025},
	{"id": "hard", "name": "Duro", "short": "H", "color": "#EDEDED", "grip": 0.975, "temp_min": 85.0, "temp_max": 130.0, "wear_per_mj": 0.015},
]
var index: int = 1
var default_index: int = 1
## °C con que salen los neumáticos (mantas) y de la pista.
var start_temp: float = 70.0
var track_temp: float = 35.0
## J por °C de la banda de rodadura (cuánto tarda en calentarse).
var heat_capacity: float = 15000.0
## W por °C que pierde parado y por cada m/s de velocidad.
var cooling: float = 40.0
var cooling_speed: float = 4.8
## W de calor por rodar = rolling_heat × carga estática (N) × velocidad (m/s). Como el
## enfriamiento también crece con la velocidad, rodando sin exigir el neumático queda cerca
## de track_temp + rolling_heat × carga / cooling_speed a cualquier velocidad.
var rolling_heat: float = 0.13
## °C fuera de la ventana con los que se pierde cold_loss / hot_loss de agarre (tope ahí).
var temp_span: float = 50.0
var cold_loss: float = 0.2
var hot_loss: float = 0.2
## Agarre que se pierde con el neumático gastado del todo (desgaste 1).
var wear_grip_loss: float = 0.15
## Desgaste extra por cada °C pasado de temp_max (0,05 = +5 %).
var overheat_wear: float = 0.05


func configure(data: Dictionary) -> void:
	start_temp = float(data.get("start_temp", start_temp))
	track_temp = float(data.get("track_temp", track_temp))
	heat_capacity = maxf(float(data.get("heat_capacity", heat_capacity)), 100.0)
	cooling = maxf(float(data.get("cooling", cooling)), 0.0)
	cooling_speed = maxf(float(data.get("cooling_speed", cooling_speed)), 0.0)
	rolling_heat = maxf(float(data.get("rolling_heat", rolling_heat)), 0.0)
	temp_span = maxf(float(data.get("temp_span", temp_span)), 1.0)
	cold_loss = clampf(float(data.get("cold_loss", cold_loss)), 0.0, 0.9)
	hot_loss = clampf(float(data.get("hot_loss", hot_loss)), 0.0, 0.9)
	wear_grip_loss = clampf(float(data.get("wear_grip_loss", wear_grip_loss)), 0.0, 0.9)
	overheat_wear = maxf(float(data.get("overheat_wear", overheat_wear)), 0.0)
	var list = data.get("compounds", [])
	if list is Array and not list.is_empty():
		compounds = list
	default_index = clampi(_find(str(data.get("default", ""))), 0, compounds.size() - 1)
	index = default_index


## Elige el compuesto por id (vacío o desconocido = el de por defecto).
func select(id: String) -> void:
	var found := _find(id)
	index = found if found >= 0 else default_index
	compound_changed.emit(str(compound()["name"]))


func compound() -> Dictionary:
	return compounds[index]


func compound_color() -> Color:
	return Color.from_string(str(compound().get("color", "#FFFFFF")), Color.WHITE)


## Juego nuevo en esa rueda: a la temperatura de las mantas y sin desgaste.
func fit(wheel: CarWheel) -> void:
	wheel.temperature = start_temp
	wheel.wear = 0.0
	wheel.slip_energy = 0.0


## Multiplica el μ de la rueda.
func grip_factor(wheel: CarWheel) -> float:
	return float(compound().get("grip", 1.0)) * temperature_factor(wheel.temperature) * (1.0 - wear_grip_loss * wheel.wear)


func temperature_factor(temperature: float) -> float:
	var c := compound()
	var low := float(c.get("temp_min", 70.0))
	var high := float(c.get("temp_max", 120.0))
	if temperature < low:
		return 1.0 - cold_loss * minf(pow((low - temperature) / temp_span, 2.0), 1.0)
	if temperature > high:
		return 1.0 - hot_loss * minf(pow((temperature - high) / temp_span, 2.0), 1.0)
	return 1.0


## −1 frío, 0 en la ventana, 1 pasado (para los colores del HUD).
func temperature_state(temperature: float) -> int:
	var c := compound()
	if temperature < float(c.get("temp_min", 70.0)):
		return -1
	if temperature > float(c.get("temp_max", 120.0)):
		return 1
	return 0


## Una vez por cuadro, con la energía de deslizamiento que juntó la rueda en los sub-pasos.
## speed: m/s del auto (enfría también a la rueda en el aire).
func update(wheel: CarWheel, speed: float, delta: float) -> void:
	var heat := wheel.slip_energy / delta
	if wheel.in_contact:
		heat += rolling_heat * wheel.static_load * absf(wheel.long_speed)
	var loss := (cooling + cooling_speed * absf(speed)) * (wheel.temperature - track_temp)
	wheel.temperature += (heat - loss) * delta / heat_capacity
	var overheat := maxf(wheel.temperature - float(compound().get("temp_max", 120.0)), 0.0)
	wheel.wear = minf(wheel.wear + wheel.slip_energy / 1.0e6 * float(compound().get("wear_per_mj", 0.025))
		* (1.0 + overheat_wear * overheat), 1.0)
	wheel.slip_energy = 0.0


func _find(id: String) -> int:
	for i in compounds.size():
		if str(compounds[i].get("id", "")) == id:
			return i
	return -1
