extends GutTest
## Neumáticos (TyreCompounds, Pasos 33 y 56) y clima (Weather, Paso 56).

var tyres: TyreCompounds
var data: Dictionary


func before_each() -> void:
	data = DataLoader.load_json(DataLoader.CAR_PATH)["tyre_compounds"]
	tyres = TyreCompounds.new()
	tyres.configure(data)


func _grip(id: String, water: float) -> float:
	return TyreCompounds.mix_grip(tyres.compound_by_id(id), water)


func test_compuesto_por_defecto_y_seleccion() -> void:
	assert_eq(tyres.compound()["id"], "medium")
	tyres.select("soft")
	assert_eq(tyres.compound()["id"], "soft")
	tyres.select("no_existe")
	assert_eq(tyres.compound()["id"], "medium", "desconocido vuelve al de por defecto")


func test_mezcla_de_agarre_seco_y_mojado() -> void:
	var c := {"grip": 1.0, "wet_grip": 0.6}
	assert_eq(TyreCompounds.mix_grip(c, 0.0), 1.0)
	assert_almost_eq(TyreCompounds.mix_grip(c, 0.5), 0.8, 0.0001)
	assert_almost_eq(TyreCompounds.mix_grip(c, 1.0), 0.6, 0.0001)
	assert_almost_eq(TyreCompounds.mix_grip(c, 3.0), 0.6, 0.0001, "el agua se limita a 1")
	assert_eq(TyreCompounds.mix_grip({"grip": 0.9}, 1.0), 0.9, "sin wet_grip, el seco")


func test_orden_de_agarre_en_seco() -> void:
	assert_gt(_grip("soft", 0.0), _grip("medium", 0.0))
	assert_gt(_grip("medium", 0.0), _grip("hard", 0.0))
	assert_gt(_grip("hard", 0.0), _grip("intermediate", 0.0))
	assert_gt(_grip("intermediate", 0.0), _grip("wet", 0.0))


func test_orden_de_agarre_en_humedo_y_lluvia() -> void:
	assert_gt(_grip("intermediate", 0.5), _grip("medium", 0.5), "húmedo: intermedio")
	assert_gt(_grip("medium", 0.5), _grip("wet", 0.5))
	assert_gt(_grip("wet", 1.0), _grip("intermediate", 1.0), "lluvia: lluvia")
	assert_gt(_grip("intermediate", 1.0), _grip("soft", 1.0))


func test_agarre_con_el_agua_del_auto() -> void:
	assert_eq(tyres.compound_grip(tyres.compound()), 1.0)
	tyres.wetness = 1.0
	assert_almost_eq(tyres.compound_grip(tyres.compound()), float(tyres.compound()["wet_grip"]), 0.0001)


func test_temperatura_fuera_de_la_ventana_pierde_agarre() -> void:
	var c := tyres.compound()
	var low := float(c["temp_min"])
	var high := float(c["temp_max"])
	assert_eq(tyres.temperature_factor((low + high) * 0.5), 1.0)
	assert_lt(tyres.temperature_factor(low - 20.0), 1.0)
	assert_lt(tyres.temperature_factor(high + 20.0), 1.0)
	assert_gte(tyres.temperature_factor(-100.0), 1.0 - tyres.cold_loss, "la pérdida tiene tope")
	assert_eq(tyres.temperature_state(low - 1.0), -1)
	assert_eq(tyres.temperature_state(high + 1.0), 1)
	assert_eq(tyres.temperature_state(low + 1.0), 0)


func test_el_agua_enfria_mas() -> void:
	var dry_wheel := CarWheel.new(Vector3.ZERO, true, null)
	var wet_wheel := CarWheel.new(Vector3.ZERO, true, null)
	dry_wheel.temperature = 90.0
	wet_wheel.temperature = 90.0
	tyres.update(dry_wheel, 50.0, 0.5)
	tyres.wetness = 1.0
	tyres.wet_cooling = 1.5
	tyres.update(wet_wheel, 50.0, 0.5)
	assert_lt(dry_wheel.temperature, 90.0, "en el aire se enfría")
	assert_lt(wet_wheel.temperature, dry_wheel.temperature, "mojada se enfría más")


func test_clima_seco_no_cambia_nada() -> void:
	var dry := Weather.load_default("")
	var ai := DataLoader.load_json("res://data/ai.json")
	var preset := LightingRig.get_preset("sunset")
	assert_eq(dry.id, "dry")
	assert_true(dry.is_dry())
	assert_eq(dry.lap_factor(), 1.0)
	assert_eq(dry.ai_data(ai), ai)
	assert_eq(dry.light_preset(preset), preset)
	assert_eq(Weather.load_default("no_existe").id, "dry", "desconocido: seco")


func test_lluvia_aplicada_al_auto() -> void:
	var wet := Weather.load_default("wet")
	assert_eq(wet.wetness, 1.0)
	assert_true(wet.needs_rain_tyres())
	assert_eq(wet.compound("medium"), "wet")
	assert_eq(wet.label(), "pista mojada")
	var damp := Weather.load_default("damp")
	assert_eq(damp.compound("medium"), "intermediate")
	assert_true(damp.needs_rain_tyres(), "húmedo ya pide neumáticos de lluvia")


func test_lluvia_hace_mas_lenta_a_la_ia() -> void:
	var wet := Weather.load_default("wet")
	var ai := DataLoader.load_json("res://data/ai.json")
	var medium := float(ai["levels"]["medium"]["lap_time"])
	var slow := wet.ai_data(ai)
	assert_almost_eq(float(slow["levels"]["medium"]["lap_time"]), medium * wet.lap_factor(), 0.0001)
	assert_eq(float(ai["levels"]["medium"]["lap_time"]), medium, "no modifica el original")


func test_luz_de_lluvia_sin_tocar_el_preset() -> void:
	var wet := Weather.load_default("wet")
	var preset := LightingRig.get_preset("sunset")
	var before := JSON.stringify(preset)
	var gray := wet.light_preset(preset)
	assert_eq(JSON.stringify(preset), before, "el preset queda igual")
	assert_lt(float(gray["sun"]["energy"]), float(preset["sun"]["energy"]))
	assert_gt(float(gray["fog"]["density"]), 0.0)
