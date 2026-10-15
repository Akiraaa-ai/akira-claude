extends SceneTree
## Test: kulübe sahnesi. Selim kulübeye girer, yaka kamerasını takar, oturur, TV'yi izler, telefonu açar.
var s: Node
var n := 0

func _init() -> void:
	s = (load("res://sahneler/sokak.tscn") as PackedScene).instantiate()
	root.add_child(s)
	current_scene = s
	for i in 5: await process_frame
	var o: CharacterBody3D = s.oyuncu
	o.global_position = s._k(Vector3(-0.6, 0.3, -2.9))
	s._gec("kulube")
	await _bekle(1.5)
	_kare("disari")
	o.global_position = s._k(Vector3(-0.2, 0.3, -1.3))
	await _bekle(2.5)
	_kare("ic_floresan")
	_bak(s._k(s.BODYCAM_YERI))
	await _bekle(0.3)
	_kare("bodycam_e")
	await _bas()
	while s._adim < 3: await process_frame
	await _bekle(0.5)
	_kare("bodycam_acik")
	print("adim=", s._adim, " bodycam=", s.bodycam.acik)
	_bak(s._k(s.OTURAK) + Vector3(0, 0.6, 0))
	await _bekle(0.3)
	while s._adim == 3:
		await _bas()
		await _bekle(0.2)
	for t in [3.0, 9.0, 11.5, 15.5, 21.5, 24.0]:
		await _bekle_t(t)
		_kare("bekleme")
	while s._adim < 5: await process_frame
	await _bekle(0.5)
	print("adim=", s._adim, " zil=", s._zil.playing)
	s.atmosfer.simsek_cak(1.0)
	await _bekle(0.05)
	_kare("simsek")
	while s.durum == "kulube":
		await _bas()
		await _bekle(0.2)
	await _bekle(2.0)
	_kare("konusma")
	print("durum=", s.durum)
	while s.durum == "konusma": await process_frame
	await _bekle(1.5)
	_kare("mazgala")
	print("durum=", s.durum)
	quit()


var _bas_t := 0.0
func _bekle_t(t: float) -> void:
	while s.dt_durum - float(s._k_zaman.get("otur", 0.0)) < t: await process_frame


func _kare(ad: String) -> void:
	n += 1
	root.get_texture().get_image().save_jpg("/tmp/claude-0/godot/kulube_%02d_%s.jpg" % [n, ad], 0.85)
	print("kare ", n, " ", ad, " durum=", s.durum, " adim=", s._adim, " e=", s.e_yazi.visible, " ", s.e_yazi.text)


func _bekle(sn: float) -> void:
	var b := Time.get_ticks_msec()
	while Time.get_ticks_msec() - b < sn * 1000.0: await process_frame


func _bas() -> void:
	Input.action_press("etkiles")
	await process_frame
	await process_frame
	Input.action_release("etkiles")
	await process_frame


func _bak(h: Vector3) -> void:
	var o: CharacterBody3D = s.oyuncu
	var kam: Camera3D = s.oyuncu_kamera
	var d := (h - kam.global_position).normalized()
	o.global_rotation.y = atan2(-d.x, -d.z)
	(o.get_node("Kafa") as Node3D).rotation.x = asin(d.y)
