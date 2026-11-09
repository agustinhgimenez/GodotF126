extends GutTest
## Caja de cambios (Gearbox, Paso 4): marchas manuales, reversa, rebajes bloqueados y automática.

var box: Gearbox


func before_each() -> void:
	box = autofree(Gearbox.new())
	box.configure(DataLoader.load_json(DataLoader.CAR_PATH).get("gearbox", {}))
	box.manual = true


func test_configura_desde_car_json() -> void:
	assert_eq(box.get_gear_count(), 8, "8 marchas")
	assert_eq(box.gear, 1, "arranca en 1.ª")
	assert_almost_eq(box.get_ratio_for(1), 5.43 * box.final_drive, 0.001)
	assert_eq(box.get_ratio_for(Gearbox.NEUTRAL), 0.0, "neutro sin relación")


func test_sube_hasta_la_octava_y_no_mas() -> void:
	for i in 10:
		box.shift_up(0.0)
	assert_eq(box.gear, 8)
	assert_eq(box.get_gear_label(), "8")


func test_baja_a_neutro_y_reversa_quieto() -> void:
	box.shift_down(0.0)
	assert_eq(box.get_gear_label(), "N")
	assert_eq(box.get_direction(), 0)
	box.shift_down(0.0)
	assert_eq(box.get_gear_label(), "R")
	assert_eq(box.get_direction(), -1)
	box.shift_down(0.0)
	assert_eq(box.gear, Gearbox.REVERSE, "no hay nada debajo de R")


func test_niega_la_reversa_en_movimiento() -> void:
	box.shift_down(0.0)
	watch_signals(box)
	box.shift_down(5.0)
	assert_eq(box.gear, Gearbox.NEUTRAL)
	assert_signal_emitted(box, "shift_denied")


func test_niega_el_rebaje_que_pasa_de_vueltas() -> void:
	box.shift_up(0.0)
	box.shift_up(0.0)
	assert_eq(box.gear, 3)
	assert_gt(box.rpm_at_speed(2, 40.0), box.limiter_rpm, "a 40 m/s la 2.ª pasaría del limitador")
	watch_signals(box)
	box.shift_down(40.0)
	assert_eq(box.gear, 3)
	assert_signal_emitted_with_parameters(box, "shift_denied", ["Rebaje bloqueado: pasaría de vueltas"])
	box.shift_down(10.0)
	assert_eq(box.gear, 2, "despacio sí rebaja")


func test_corta_la_potencia_durante_el_cambio() -> void:
	box.shift_up(0.0)
	assert_true(box.is_shifting())
	box.update(8000.0, box.shift_time + 0.01)
	assert_false(box.is_shifting())


func test_rpm_proporcionales_a_la_velocidad() -> void:
	assert_almost_eq(box.rpm_at_speed(4, 40.0), 2.0 * box.rpm_at_speed(4, 20.0), 0.01)
	assert_gt(box.rpm_at_speed(3, 30.0), box.rpm_at_speed(4, 30.0), "marcha más corta, más vueltas")


func test_automatica_sube_y_baja_por_rpm() -> void:
	box.manual = false
	box.update(box.shift_up_rpm + 100.0, box.min_shift_interval + 0.01)
	assert_eq(box.gear, 2, "sube al pasar shift_up_rpm")
	box.update(box.shift_up_rpm + 100.0, 0.01)
	assert_eq(box.gear, 2, "no cambia otra vez antes de min_shift_interval")
	box.update(box.shift_down_rpm - 100.0, box.min_shift_interval + 0.01)
	assert_eq(box.gear, 1, "baja debajo de shift_down_rpm")


func test_las_levas_no_cambian_en_automatica() -> void:
	box.manual = false
	box.shift_up(0.0)
	assert_eq(box.gear, 1)


func test_pasar_a_automatica_saca_de_neutro() -> void:
	box.shift_down(0.0)
	box.toggle_mode()
	assert_false(box.manual)
	assert_eq(box.gear, 1)
