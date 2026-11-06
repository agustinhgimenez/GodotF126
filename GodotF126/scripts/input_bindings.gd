class_name InputBindings
extends RefCounted
## Controles reasignables (Paso 37). Cada acción de data/input.json tiene teclas (por defecto
## las de project.godot) y un control del mando (por defecto el de "gamepad": un botón o un
## eje con su sentido). Lo que el jugador cambia llega como `overrides`
## ({acción: {"keys": [physical_keycode…], "pad": {"button": n} | {"axis": n, "sign": ±1} | {}}},
## sólo lo cambiado; lo guarda Settings) y apply() arma el InputMap.
## Los pedales analógicos se leen con pedal_strength(): con `full_range` acepta pedales de
## volante que van de −1 (suelto) a 1 (a fondo).

const DATA_PATH := "res://data/input.json"
## Acciones que aceptan un eje del mando (las demás, sólo botones: un eje dispararía la
## acción en cada movimiento).
const ANALOG_ACTIONS := ["accelerate", "brake", "steer_left", "steer_right", "handbrake"]
const PEDAL_ACTIONS := ["accelerate", "brake"]
const STEER_ACTIONS := ["steer_left", "steer_right"]
## Fuera de la lista: Start abre la pausa (Esc sigue siendo ui_cancel).
const PAUSE_ACTION := "pause"
## Los ui_* de Godot 4.7 sólo traen teclas: A acepta, B vuelve y la cruceta navega los menús.
const UI_PAD_BUTTONS := {
	"ui_accept": JOY_BUTTON_A, "ui_cancel": JOY_BUTTON_B,
	"ui_up": JOY_BUTTON_DPAD_UP, "ui_down": JOY_BUTTON_DPAD_DOWN,
	"ui_left": JOY_BUTTON_DPAD_LEFT, "ui_right": JOY_BUTTON_DPAD_RIGHT,
}
const KEY_NAMES := {
	"Up": "↑", "Down": "↓", "Left": "←", "Right": "→",
	"Space": "Espacio", "Escape": "Esc", "Enter": "Enter",
}
const BUTTON_NAMES := ["A", "B", "X", "Y", "Back", "Guía", "Start", "L3", "R3", "LB", "RB",
	"Cruceta ↑", "Cruceta ↓", "Cruceta ←", "Cruceta →"]
## Eje → [nombre con sentido −, nombre con sentido +].
const AXIS_NAMES := {
	0: ["Palanca ←", "Palanca →"], 1: ["Palanca ↑", "Palanca ↓"],
	2: ["Palanca der. ←", "Palanca der. →"], 3: ["Palanca der. ↑", "Palanca der. ↓"],
	4: ["LT −", "LT"], 5: ["RT −", "RT"],
}

static var _data: Dictionary = {}
## "dispositivo:eje" que ya pasaron por debajo de −0,5: son pedales de −1 a 1 (un gatillo en
## reposo da 0 y con full_range daría medio pedal).
static var _full_range_seen: Dictionary = {}


static func data() -> Dictionary:
	if _data.is_empty():
		_data = DataLoader.load_json(DATA_PATH)
	return _data


## Acciones reasignables en orden: [{"id", "name"}].
static func actions() -> Array:
	var result: Array = []
	for entry in data().get("actions", []):
		if entry is Dictionary and entry.has("id"):
			result.append(entry)
	return result


static func action_ids() -> PackedStringArray:
	var ids := PackedStringArray()
	for entry in actions():
		ids.append(str(entry["id"]))
	return ids


static func action_name(action: String) -> String:
	for entry in actions():
		if str(entry["id"]) == action:
			return str(entry.get("name", action))
	return action


static func is_analog(action: String) -> bool:
	return action in ANALOG_ACTIONS


## Teclas de project.godot y mando de data/input.json.
static func default_binding(action: String) -> Dictionary:
	var keys: Array = []
	var setting = ProjectSettings.get_setting("input/" + action)
	if setting is Dictionary:
		for event in setting.get("events", []):
			if event is InputEventKey:
				var key := event as InputEventKey
				keys.append(int(key.physical_keycode if key.physical_keycode != KEY_NONE else key.keycode))
	var pad = data().get("gamepad", {}).get(action, {})
	return {"keys": keys, "pad": sanitize_pad(pad)}


## Lo de `overrides` encima de los defaults.
static func binding(action: String, overrides: Dictionary) -> Dictionary:
	var result := default_binding(action)
	var saved = overrides.get(action)
	if saved is Dictionary:
		if saved.get("keys") is Array:
			var keys: Array = []
			for code in saved["keys"]:
				if (code is int or code is float) and int(code) > 0 and not int(code) in keys:
					keys.append(int(code))
			result["keys"] = keys
		if saved.has("pad"):
			result["pad"] = sanitize_pad(saved["pad"])
	return result


## {"button": n} (0–127), {"axis": n (0–9), "sign": ±1} o {} (nada).
static func sanitize_pad(pad) -> Dictionary:
	if not pad is Dictionary:
		return {}
	var button = pad.get("button")
	if (button is int or button is float) and int(button) >= 0 and int(button) < 128:
		return {"button": int(button)}
	var axis = pad.get("axis")
	if (axis is int or axis is float) and int(axis) >= 0 and int(axis) < 10:
		var sign_value = pad.get("sign", 1)
		return {"axis": int(axis), "sign": -1 if (sign_value is int or sign_value is float) and float(sign_value) < 0.0 else 1}
	return {}


## Arma el InputMap: teclas + mando de cada acción, zonas muertas (pedales fija, dirección
## `steer_deadzone` 0–1, el resto `button_deadzone`) y la acción de pausa del mando.
static func apply(overrides: Dictionary, steer_deadzone: float) -> void:
	var ids := action_ids()
	ids.append(PAUSE_ACTION)
	for action in ids:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		InputMap.action_erase_events(action)
		var bound := binding(action, overrides)
		for code in bound["keys"]:
			var key := InputEventKey.new()
			key.physical_keycode = int(code) as Key
			InputMap.action_add_event(action, key)
		var pad := pad_event(bound["pad"])
		if pad != null:
			InputMap.action_add_event(action, pad)
		var deadzone := float(data().get("button_deadzone", 0.5))
		if action in PEDAL_ACTIONS:
			deadzone = float(data().get("pedal_deadzone", 0.05))
		elif action in STEER_ACTIONS:
			deadzone = clampf(steer_deadzone, 0.0, 0.9)
		InputMap.action_set_deadzone(action, maxf(deadzone, 0.001))
	for action in UI_PAD_BUTTONS:
		var ui_button := pad_event({"button": UI_PAD_BUTTONS[action]})
		if InputMap.has_action(action) and not InputMap.action_has_event(action, ui_button):
			InputMap.action_add_event(action, ui_button)


static func pad_event(pad: Dictionary) -> InputEvent:
	if pad.has("button"):
		var button := InputEventJoypadButton.new()
		button.device = -1
		button.button_index = int(pad["button"]) as JoyButton
		return button
	if pad.has("axis"):
		var motion := InputEventJoypadMotion.new()
		motion.device = -1
		motion.axis = int(pad["axis"]) as JoyAxis
		motion.axis_value = -1.0 if int(pad.get("sign", 1)) < 0 else 1.0
		return motion
	return null


## Asigna `value` (teclas: Array de códigos; mando: dict) a `slot` ("keys" / "pad") de la
## acción y lo saca de las otras acciones que lo usaban. Devuelve {"overrides", "removed_from"}.
static func assign(overrides: Dictionary, action: String, slot: String, value) -> Dictionary:
	var result := overrides.duplicate(true)
	var removed := PackedStringArray()
	for other in action_ids():
		if other == action:
			continue
		var bound := binding(other, result)
		if slot == "keys":
			var kept: Array = []
			for code in bound["keys"]:
				if not code in value:
					kept.append(code)
			if kept.size() != bound["keys"].size():
				_set_slot(result, other, "keys", kept)
				removed.append(other)
		elif not (value as Dictionary).is_empty() and bound["pad"] == value:
			_set_slot(result, other, "pad", {})
			removed.append(other)
	_set_slot(result, action, slot, value)
	return {"overrides": result, "removed_from": removed}


static func _set_slot(overrides: Dictionary, action: String, slot: String, value) -> void:
	var entry: Dictionary = overrides.get(action, {}).duplicate(true) if overrides.get(action) is Dictionary else {}
	entry[slot] = value
	overrides[action] = entry


## El control del mando de un evento ({} si no es del mando).
static func pad_from_event(event: InputEvent) -> Dictionary:
	if event is InputEventJoypadButton:
		return {"button": int((event as InputEventJoypadButton).button_index)}
	if event is InputEventJoypadMotion:
		var motion := event as InputEventJoypadMotion
		return {"axis": int(motion.axis), "sign": -1 if motion.axis_value < 0.0 else 1}
	return {}


static func key_text(code: int) -> String:
	var text := OS.get_keycode_string(code as Key)
	return KEY_NAMES.get(text, text)


static func keys_text(keys: Array) -> String:
	var names := PackedStringArray()
	for code in keys:
		names.append(key_text(int(code)))
	return " / ".join(names) if not names.is_empty() else "—"


static func pad_text(pad: Dictionary) -> String:
	if pad.has("button"):
		var index := int(pad["button"])
		return BUTTON_NAMES[index] if index < BUTTON_NAMES.size() else "Botón %d" % index
	if pad.has("axis"):
		var axis := int(pad["axis"])
		var positive := int(pad.get("sign", 1)) >= 0
		if AXIS_NAMES.has(axis):
			return AXIS_NAMES[axis][1 if positive else 0]
		return "Eje %d %s" % [axis, "+" if positive else "−"]
	return "—"


## Nombres del mando de una acción del InputMap (para el panel de controles).
static func pad_names_for(action: String) -> PackedStringArray:
	var names := PackedStringArray()
	if not InputMap.has_action(action):
		return names
	for event in InputMap.action_get_events(action):
		var pad := pad_from_event(event)
		if not pad.is_empty():
			names.append(pad_text(pad))
	return names


## 0–1 del pedal: lo del InputMap (teclas, gatillos, Input.action_press de las pruebas) y, con
## `full_range`, los ejes de la acción leídos como pedales de −1 (suelto) a 1 (a fondo), sólo
## en los mandos donde ese eje ya pasó por debajo de −0,5.
static func pedal_strength(action: String, full_range: bool) -> float:
	var strength := Input.get_action_strength(action)
	if not full_range or not InputMap.has_action(action):
		return strength
	var deadzone := float(data().get("pedal_deadzone", 0.05))
	for event in InputMap.action_get_events(action):
		if not event is InputEventJoypadMotion:
			continue
		var motion := event as InputEventJoypadMotion
		var direction := -1.0 if motion.axis_value < 0.0 else 1.0
		for device in Input.get_connected_joypads():
			var value := Input.get_joy_axis(device, motion.axis) * direction
			var id := "%d:%d" % [device, motion.axis]
			if value < -0.5:
				_full_range_seen[id] = true
			if _full_range_seen.has(id):
				strength = maxf(strength, full_range_value(value, deadzone))
	return strength


## Pedal de −1 a 1 → 0–1 con zona muerta al principio.
static func full_range_value(value: float, deadzone: float) -> float:
	return clampf(inverse_lerp(deadzone, 1.0, (value + 1.0) * 0.5), 0.0, 1.0)


## Nombres de los mandos conectados.
static func connected_pads() -> PackedStringArray:
	var names := PackedStringArray()
	for device in Input.get_connected_joypads():
		names.append(Input.get_joy_name(device))
	return names
