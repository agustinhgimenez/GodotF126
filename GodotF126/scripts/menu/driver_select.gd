class_name DriverSelect
extends VBoxContainer
## Selección de escudería → piloto (Paso 12), armada por código desde grid_2026.json.
## Etapa 1: tarjetas de las escuderías (color, nombre y apellidos de sus pilotos).
## Etapa 2: tarjetas de los pilotos del equipo (número, nombre, bandera y país).
## Avisa con preview_changed lo que tiene el foco, para que el menú pinte el auto.

signal preview_changed(team: Dictionary, driver: Dictionary)
signal confirmed(driver_id: String)
signal cancelled

enum Stage { TEAM, DRIVER }

const TEAM_COLUMNS := 2
const TEAM_CARD_SIZE := Vector2(270, 58)
const DRIVER_CARD_SIZE := Vector2(260, 230)
const FLAG_SIZE := Vector2(54, 36)

var stage: Stage = Stage.TEAM

var _teams: Array = []
var _team_index: int = 0
var _current_driver_id: String = ""
var _heading: Label
var _team_grid: GridContainer
var _driver_row: HBoxContainer
var _team_buttons: Array[Button] = []


func _ready() -> void:
	add_theme_constant_override("separation", 14)
	_heading = UiKit.make_label("", 26)
	add_child(_heading)
	_team_grid = GridContainer.new()
	_team_grid.columns = TEAM_COLUMNS
	_team_grid.add_theme_constant_override("h_separation", 10)
	_team_grid.add_theme_constant_override("v_separation", 10)
	add_child(_team_grid)
	_driver_row = HBoxContainer.new()
	_driver_row.add_theme_constant_override("separation", 16)
	add_child(_driver_row)
	var hint := UiKit.make_label("Flechas para elegir · Enter para confirmar · Esc para volver", 16)
	hint.add_theme_color_override("font_color", Color(0.7, 0.72, 0.78))
	add_child(hint)


func setup(grid: Dictionary, current_driver_id: String) -> void:
	_teams = grid.get("teams", [])
	_current_driver_id = current_driver_id
	for button in _team_buttons:
		button.queue_free()
	_team_buttons.clear()
	for i in _teams.size():
		var button := _make_team_card(_teams[i])
		var index := i
		button.focus_entered.connect(func() -> void: _on_team_focused(index))
		button.pressed.connect(func() -> void: _open_drivers(index))
		_team_grid.add_child(button)
		_team_buttons.append(button)
	_team_index = maxi(_find_team_of(current_driver_id), 0)


## Empieza por las escuderías, con el foco en el equipo del piloto actual.
func open() -> void:
	_show_teams()


## Esc: del piloto vuelve a las escuderías; de las escuderías sale (cancelled).
func back() -> void:
	if stage == Stage.DRIVER:
		_show_teams()
	else:
		cancelled.emit()


func _show_teams() -> void:
	stage = Stage.TEAM
	_heading.text = "Elegí escudería"
	_team_grid.visible = true
	_driver_row.visible = false
	if not _team_buttons.is_empty():
		_team_buttons[_team_index].grab_focus()


func _open_drivers(index: int) -> void:
	stage = Stage.DRIVER
	_team_index = index
	var team: Dictionary = _teams[index]
	_heading.text = "Elegí piloto — %s" % str(team.get("name", ""))
	for child in _driver_row.get_children():
		child.queue_free()
	var focus_button: Button = null
	for driver in team.get("drivers", []):
		var button := _make_driver_card(team, driver)
		var driver_data: Dictionary = driver
		button.focus_entered.connect(func() -> void: preview_changed.emit(team, driver_data))
		button.pressed.connect(func() -> void: confirmed.emit(str(driver_data.get("id", ""))))
		_driver_row.add_child(button)
		if focus_button == null or str(driver.get("id", "")) == _current_driver_id:
			focus_button = button
	_team_grid.visible = false
	_driver_row.visible = true
	if focus_button != null:
		focus_button.grab_focus()


func _on_team_focused(index: int) -> void:
	_team_index = index
	preview_changed.emit(_teams[index], {})


func _make_team_card(team: Dictionary) -> Button:
	var color := Color.html(str(team.get("color", "#FFFFFF")))
	var button := UiKit.make_button("", color, TEAM_CARD_SIZE)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 0)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiKit.place(box, Vector4(0, 0, 1, 1), Vector4(22, 6, -10, -6))
	button.add_child(box)
	box.add_child(UiKit.make_label(str(team.get("name", "")), 22))
	var surnames := PackedStringArray()
	for driver in team.get("drivers", []):
		var full_name := str(driver.get("name", ""))
		surnames.append(full_name.get_slice(" ", full_name.get_slice_count(" ") - 1))
	var drivers_label := UiKit.make_label(" · ".join(surnames), 14)
	drivers_label.add_theme_color_override("font_color", Color(0.75, 0.77, 0.82))
	box.add_child(drivers_label)
	return button


func _make_driver_card(team: Dictionary, driver: Dictionary) -> Button:
	var color := Color.html(str(team.get("color", "#FFFFFF")))
	var button := UiKit.make_button("", color, DRIVER_CARD_SIZE)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 6)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiKit.place(box, Vector4(0, 0, 1, 1), Vector4(22, 10, -12, -10))
	button.add_child(box)

	var number := UiKit.make_label(UiKit.number_text(driver.get("number", "")), 72)
	number.add_theme_color_override("font_color", color)
	box.add_child(number)
	var name_label := UiKit.make_label(str(driver.get("name", "")), 24)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(name_label)

	var country := str(driver.get("country", ""))
	var country_row := HBoxContainer.new()
	country_row.add_theme_constant_override("separation", 10)
	country_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(country_row)
	var flag := FlagIcon.new()
	flag.custom_minimum_size = FLAG_SIZE
	flag.set_country(country)
	country_row.add_child(flag)
	var country_label := UiKit.make_label(FlagIcon.country_name(country), 18)
	country_label.add_theme_color_override("font_color", Color(0.8, 0.82, 0.86))
	country_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	country_row.add_child(country_label)
	return button


func _find_team_of(driver_id: String) -> int:
	for i in _teams.size():
		for driver in _teams[i].get("drivers", []):
			if str(driver.get("id", "")) == driver_id:
				return i
	return -1
