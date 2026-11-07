class_name RaceStrategy
extends RefCounted
## Estrategia de neumáticos (Paso 49), datos en data/strategy.json. En carreras de `min_laps`
## vueltas o más los neumáticos se gastan `wear_scale` veces más rápido y hay que usar dos
## compuestos (si no, `rule_penalty` s al terminar).
## Modelo para planear (no simula el auto): el neumático más gastado pierde `lap_wear(id)` por
## vuelta; una vuelta pierde `base_lap` × `grip_time` × (agarre que le falta al compuesto y al
## desgaste) s; parar cuesta `pit_loss` s y un juego no se usa más allá de `wear_limit`.
## Un plan es {first, second, stint (vueltas con el primero), cost (s)}: una parada al final de
## la vuelta `stint` (la calle de boxes está antes de la meta).

const DATA_PATH := "res://data/strategy.json"

var min_laps: int = 8
var wear_scale: float = 2.5
var rule_penalty: float = 30.0
var reference_compound: String = "medium"
var wear_per_lap: float = 0.016
var base_lap: float = 80.0
var grip_time: float = 0.6
var pit_loss: float = 21.0
var wear_limit: float = 0.75
var wear_margin: float = 0.08
var choice_spread: float = 4.0
var radio: Dictionary = {}
## Bloque "compounds" de "tyre_compounds" (data/car.json) y su pérdida de agarre por desgaste.
var compounds: Array = []
var wear_grip_loss: float = 0.15


func configure(data: Dictionary, tyre_data: Dictionary) -> void:
	min_laps = maxi(int(data.get("min_laps", min_laps)), 2)
	for key in ["wear_scale", "rule_penalty", "wear_per_lap", "base_lap", "grip_time", "pit_loss", "wear_limit",
			"wear_margin", "choice_spread"]:
		if data.has(key):
			set(key, maxf(float(data[key]), 0.0))
	wear_scale = maxf(wear_scale, 0.1)
	wear_limit = clampf(wear_limit, 0.1, 1.0)
	reference_compound = str(data.get("reference_compound", reference_compound))
	var radio_data = data.get("radio", {})
	radio = radio_data if radio_data is Dictionary else {}
	var list = tyre_data.get("compounds", [])
	if list is Array and not list.is_empty():
		compounds = list
	wear_grip_loss = float(tyre_data.get("wear_grip_loss", wear_grip_loss))


static func load_default() -> RaceStrategy:
	var strategy := RaceStrategy.new()
	strategy.configure(DataLoader.load_json(DATA_PATH),
		DataLoader.load_json(DataLoader.CAR_PATH).get("tyre_compounds", {}))
	return strategy


## La carrera tiene estrategia (desgaste de carrera y dos compuestos obligatorios).
func applies(laps: int) -> bool:
	return laps >= min_laps


func ids() -> Array[String]:
	var list: Array[String] = []
	for c in compounds:
		list.append(str(c.get("id", "")))
	return list


func compound(id: String) -> Dictionary:
	for c in compounds:
		if str(c.get("id", "")) == id:
			return c
	return {}


func compound_name(id: String) -> String:
	return str(compound(id).get("name", id))


func short_name(id: String) -> String:
	return str(compound(id).get("short", id.left(1).to_upper()))


func compound_color(id: String) -> Color:
	return Color.from_string(str(compound(id).get("color", "#FFFFFF")), Color.WHITE)


## Desgaste por vuelta del neumático más gastado con el compuesto `id` (con `wear_scale`).
func lap_wear(id: String) -> float:
	var reference := float(compound(reference_compound).get("wear_per_mj", 0.025))
	var own := float(compound(id).get("wear_per_mj", reference))
	return wear_per_lap * own / maxf(reference, 0.0001) * wear_scale


## Vueltas que aguanta un juego nuevo de `id` sin pasar `wear_limit`.
func max_stint(id: String, wear_now: float = 0.0) -> int:
	return maxi(floori((wear_limit - wear_now) / maxf(lap_wear(id), 0.0001)), 0)


## s que pierde una vuelta con un juego de `id` que ya tiene `age` vueltas (contra agarre 1).
func lap_cost(id: String, age: float) -> float:
	var wear := minf((age + 0.5) * lap_wear(id), 1.0)
	var grip := float(compound(id).get("grip", 1.0)) * (1.0 - wear_grip_loss * wear)
	return base_lap * grip_time * (1.0 - grip)


func stint_cost(id: String, laps: int, start_age: float = 0.0) -> float:
	var total := 0.0
	for lap in laps:
		total += lap_cost(id, start_age + lap)
	return total


## Planes de una parada para `laps` vueltas (con `first` fijo si no está vacío), del más
## rápido al más lento. Si ninguno entra en `wear_limit`, todos sin ese límite.
func plans(laps: int, first: String = "") -> Array[Dictionary]:
	var list := _plans(laps, first, true)
	if list.is_empty():
		list = _plans(laps, first, false)
	list.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["cost"]) < float(b["cost"]))
	return list


func _plans(laps: int, first: String, limited: bool) -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	for a in ids():
		if not first.is_empty() and a != first:
			continue
		for b in ids():
			if b == a:
				continue
			for stint in range(1, laps):
				if limited and (stint > max_stint(a) or laps - stint > max_stint(b)):
					continue
				list.append({"first": a, "second": b, "stint": stint,
					"cost": stint_cost(a, stint) + stint_cost(b, laps - stint) + pit_loss})
	return list


## Un plan al azar entre los que están a menos de `choice_spread` s del mejor (o el mejor, sin
## rng). Vacío si no hay planes.
func choose(laps: int, rng: RandomNumberGenerator = null, first: String = "") -> Dictionary:
	var list := plans(laps, first)
	if list.is_empty():
		return {}
	if rng == null:
		return list[0]
	var count := 1
	while count < list.size() and float(list[count]["cost"]) <= float(list[0]["cost"]) + choice_spread:
		count += 1
	return list[rng.randi_range(0, count - 1)]


## Compuesto para una parada con `remaining` vueltas por delante: el más rápido que aguanta
## hasta el final (si ninguno, el que más dura); si la regla de los dos compuestos todavía no
## se cumple, uno sin usar.
func next_compound(remaining: int, used: Array, rule: bool) -> String:
	var best := ""
	var best_cost := INF
	var longest := ""
	for id in ids():
		if rule and _distinct(used) < 2 and used.has(id):
			continue
		var cost := stint_cost(id, maxi(remaining, 1))
		if remaining <= max_stint(id) and cost < best_cost:
			best = id
			best_cost = cost
		if longest.is_empty() or max_stint(id) > max_stint(longest):
			longest = id
	return best if not best.is_empty() else longest


## Hay que parar ya: el neumático más gastado pasó `wear_limit` + `wear_margin` y faltan dos
## vueltas o más.
func worn_out(wear: float, remaining: int) -> bool:
	return wear >= wear_limit + wear_margin and remaining >= 2


static func _distinct(used: Array) -> int:
	var seen := {}
	for id in used:
		seen[id] = true
	return seen.size()


## Cumple la regla: usó dos compuestos distintos.
static func rule_met(used: Array) -> bool:
	return _distinct(used) >= 2


## Texto de radio `key` con los valores de `values` ({lap}, {compound}…).
func radio_text(key: String, values: Dictionary = {}) -> String:
	var texts = radio.get("texts", {})
	var text := str(texts.get(key, "")) if texts is Dictionary else ""
	return text.format(values)
