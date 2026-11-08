extends GutTest
## Estrategia de neumáticos (RaceStrategy, Pasos 49 y 56), puntos (RaceResults, Paso 52) y
## campeonato (Championship, Paso 55). El campeonato se guarda en un archivo de prueba.

const SEASON_PATH := "user://gut_championship_test.json"


func _strategy(weather_id: String = "") -> RaceStrategy:
	var strategy := RaceStrategy.load_default()
	Weather.load_default(weather_id).apply_to_strategy(strategy)
	return strategy


func _row(id: String, pos: int, points: int, team: String) -> Dictionary:
	return {"driver_id": id, "driver": id.capitalize(), "code": id.left(3).to_upper(), "team_id": team,
		"team": team.capitalize(), "pos": pos, "points": points}


func _season() -> Championship:
	var season := Championship.new()
	season.configure({"save_path": SEASON_PATH, "calendar": [{"track_id": "baku"}, {"track_id": "buenos_aires"}]})
	return season


func after_all() -> void:
	if FileAccess.file_exists(SEASON_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SEASON_PATH))


func test_estrategia_en_seco() -> void:
	var s := _strategy()
	assert_eq(Array(s.ids()), ["soft", "medium", "hard"], "sólo lisos")
	assert_true(s.two_compound_rule)
	assert_true(s.applies(s.min_laps))
	assert_false(s.applies(s.min_laps - 1), "carrera corta sin estrategia")


func test_planes_en_seco_usan_dos_compuestos() -> void:
	var s := _strategy()
	var plans := s.plans(20)
	assert_gt(plans.size(), 0)
	for plan in plans:
		assert_ne(plan["first"], plan["second"], "dos compuestos distintos")
		assert_lt(int(plan["stint"]), 20, "con una parada")
	for i in plans.size() - 1:
		assert_lte(float(plans[i]["cost"]), float(plans[i + 1]["cost"]), "ordenados por costo")


func test_plan_con_el_compuesto_del_jugador() -> void:
	var s := _strategy()
	var plan := s.choose(20, null, "hard")
	assert_eq(plan["first"], "hard")
	assert_ne(plan["second"], "hard")


func test_siguiente_compuesto_cumple_la_regla() -> void:
	var s := _strategy()
	assert_ne(s.next_compound(8, ["medium"], true), "medium", "todavía falta otro compuesto")
	assert_true(RaceStrategy.rule_met(["medium", "hard"]))
	assert_false(RaceStrategy.rule_met(["medium", "medium"]))


func test_desgaste_por_compuesto() -> void:
	var s := _strategy()
	assert_gt(s.lap_wear("soft"), s.lap_wear("medium"))
	assert_gt(s.lap_wear("medium"), s.lap_wear("hard"))
	assert_lt(s.max_stint("soft"), s.max_stint("hard"))
	assert_true(s.worn_out(s.wear_limit + s.wear_margin, 5))
	assert_false(s.worn_out(s.wear_limit + s.wear_margin, 1), "en la última vuelta no para")


func test_estrategia_con_lluvia() -> void:
	var s := _strategy("wet")
	assert_eq(Array(s.ids()), ["intermediate", "wet"], "sólo de lluvia")
	assert_false(s.two_compound_rule)
	var plans := s.plans(10)
	assert_eq(plans[0]["first"], "wet")
	assert_true(plans.any(func(p: Dictionary) -> bool: return int(p["stint"]) == 10), "hay plan sin parar")
	assert_eq(s.next_compound(5, ["wet"], true), "wet", "sin la regla puede repetir")


func test_lisos_en_lluvia_paran_enseguida() -> void:
	var plan := _strategy("wet").choose(10, null, "medium")
	assert_eq(plan["first"], "medium")
	assert_eq(plan["second"], "wet")
	assert_lte(int(plan["stint"]), 2)


func test_humedo_larga_con_intermedios() -> void:
	assert_eq(_strategy("damp").plans(10)[0]["first"], "intermediate")


func test_puntos_por_puesto() -> void:
	var results := RaceResults.load_default()
	assert_eq(results.points_for(1), 25)
	assert_eq(results.points_for(10), 1)
	assert_eq(results.points_for(11), 0)
	assert_eq(results.points_for(0), 0)
	var total := 0
	for p in range(1, 23):
		total += results.points_for(p)
	assert_eq(total, 101, "101 puntos por carrera")


func test_punto_por_vuelta_rapida_configurable() -> void:
	var results := RaceResults.new()
	results.configure({"points": [10, 5], "fastest_lap_points": 1, "fastest_lap_top": 1})
	assert_eq(results.points_for(1, true), 11)
	assert_eq(results.points_for(2, true), 5, "sólo dentro del top")
	assert_eq(RaceResults.change_text(2), "+2")
	assert_eq(RaceResults.change_text(-1), "-1")
	assert_eq(RaceResults.change_text(0), "=")


func test_desempate_por_mejores_resultados() -> void:
	assert_eq(Championship.countback([1, 5], [2, 2]), 1, "una victoria gana")
	assert_eq(Championship.countback([2, 2], [2, 3]), 1)
	assert_eq(Championship.countback([4], [1]), -1)
	assert_eq(Championship.countback([3, 0], [3]), 0)


func test_temporada_suma_y_ordena() -> void:
	var season := _season()
	season.start("aaa", 3)
	assert_false(season.add_race({"track_id": "buenos_aires", "drivers": [_row("aaa", 1, 25, "x")]}),
		"no suma una pista que no es la de la fecha")
	assert_true(season.add_race({"track_id": "baku", "drivers": [_row("aaa", 1, 25, "x"), _row("bbb", 3, 15, "y"),
		_row("ccc", 2, 18, "x")]}))
	assert_true(season.add_race({"track_id": "buenos_aires", "drivers": [_row("aaa", 9, 2, "x"), _row("bbb", 4, 12, "y"),
		_row("ccc", 7, 6, "x")]}))
	assert_true(season.is_finished())
	var table := season.driver_standings()
	assert_eq(table.map(func(s: Dictionary) -> String: return "%s %d" % [s["driver_id"], s["points"]]),
		["aaa 27", "bbb 27", "ccc 24"], "empate en 27 resuelto por la victoria")
	assert_true(table[0]["player"])
	var teams := season.team_standings()
	assert_eq(teams.map(func(t: Dictionary) -> String: return "%s %d" % [t["team_id"], t["points"]]), ["x 51", "y 27"])


func test_temporada_se_guarda_y_se_lee() -> void:
	var season := _season()
	season.start("aaa", 5)
	season.add_race({"track_id": "baku", "drivers": [_row("aaa", 2, 18, "x")]})
	assert_true(season.save())
	var loaded := Championship.new()
	loaded.save_path = SEASON_PATH
	assert_true(loaded.load_state())
	assert_eq(loaded.round_count(), 2, "el calendario guardado manda")
	assert_eq(loaded.laps, 5)
	assert_eq(loaded.player_driver_id, "aaa")
	assert_eq(loaded.round_index(), 1)
	loaded.delete_saved()
	assert_false(FileAccess.file_exists(SEASON_PATH))
