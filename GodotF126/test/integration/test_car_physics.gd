extends GutTest
## Física básica del auto (CarController) sobre un piso plano, manejado por código como la IA:
## acelera, sube de marcha, frena hasta casi parar y no se da vuelta.

const CAR_SCENE := preload("res://scenes/car.tscn")

var car: CarController


func before_each() -> void:
	var floor := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(4000.0, 2.0, 4000.0)
	shape.shape = box
	shape.position = Vector3(0.0, -1.0, 0.0)
	floor.add_child(shape)
	add_child_autofree(floor)

	car = CAR_SCENE.instantiate() as CarController
	car.ai_controlled = true
	car.position = Vector3(0.0, 0.6, 0.0)
	add_child_autofree(car)
	car.configure(DataLoader.load_json(DataLoader.CAR_PATH))
	car.fit_tyres("")
	car.fill_fuel(car.fuel.practice_kg)
	car.gearbox.manual = false
	car.spawn_transform = car.global_transform
	car.reset_to_spawn()


func _upright() -> float:
	return car.global_transform.basis.y.dot(Vector3.UP)


func test_queda_apoyado_en_el_piso() -> void:
	await wait_physics_frames(60)
	assert_true(car.wheels.all(func(w: CarWheel) -> bool: return w.in_contact), "las cuatro ruedas tocan el piso")
	assert_lt(car.get_speed_kmh(), 1.0, "quieto sin acelerar")
	assert_gt(_upright(), 0.99)


func test_acelera_y_sube_de_marcha() -> void:
	await wait_physics_frames(30)
	car.ai_inputs = Vector3(1.0, 0.0, 0.0)
	await wait_physics_frames(180)
	var kmh := car.get_speed_kmh()
	assert_gt(kmh, 100.0, "en 3 s a fondo: %.0f km/h" % kmh)
	assert_lt(kmh, 250.0)
	assert_gt(car.gearbox.gear, 1, "la caja automática subió (marcha %d)" % car.gearbox.gear)
	assert_gt(car.forward_speed, 0.0, "va para adelante")
	assert_gt(_upright(), 0.98, "derecho")


func test_frena_hasta_casi_parar() -> void:
	await wait_physics_frames(30)
	car.ai_inputs = Vector3(1.0, 0.0, 0.0)
	await wait_physics_frames(150)
	var fast := car.get_speed_kmh()
	car.ai_inputs = Vector3(0.0, 1.0, 0.0)
	await wait_physics_frames(60)
	assert_lt(car.get_speed_kmh(), fast * 0.6, "en 1 s frenando pierde velocidad")
	var frames := 0
	while car.forward_speed > 1.0 and frames < 300:
		await wait_physics_frames(1)
		frames += 1
	assert_lt(car.forward_speed, 1.0, "se detiene frenando")
	car.ai_inputs = Vector3.ZERO
	await wait_physics_frames(60)
	assert_lt(car.get_speed_kmh(), 5.0, "termina casi parado")
	assert_gt(_upright(), 0.98)


func test_freno_parado_pone_reversa() -> void:
	await wait_physics_frames(30)
	car.ai_inputs = Vector3(0.0, 1.0, 0.0)
	await wait_physics_frames(120)
	assert_eq(car.gearbox.gear, Gearbox.REVERSE, "caja automática: freno con el auto quieto = reversa")
	assert_lt(car.forward_speed, -1.0, "va para atrás")
	assert_gte(car.forward_speed, -car.max_reverse_speed - 0.5, "con el tope de reversa")


func test_dobla_hacia_donde_se_pide() -> void:
	await wait_physics_frames(30)
	car.ai_inputs = Vector3(0.6, 0.0, 0.0)
	await wait_physics_frames(90)
	var heading := -car.global_transform.basis.z
	car.ai_inputs = Vector3(0.4, 0.0, 0.5)
	await wait_physics_frames(60)
	var turned := heading.signed_angle_to(-car.global_transform.basis.z, Vector3.UP)
	assert_ne(turned, 0.0)
	assert_gt(absf(turned), deg_to_rad(10.0), "giró %.0f°" % rad_to_deg(turned))
	assert_gt(_upright(), 0.98)
