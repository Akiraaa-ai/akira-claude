extends SceneTree
## Test: sokak. Arabaya bin (E ve el), marş, silecekli sürüş, kulübe önünde park ve sessizlik, kulübeye yürü,
## ıslak izler ve nöbet çizelgesi. Kayıt noktaları yazılıyor mu.
var s: Node
var n := 0

func _init() -> void:
	s = (load("res://sahneler/sokak.tscn") as PackedScene).instantiate()
	root.add_child(s)
	current_scene = s
	for i in 5: await process_frame
	var d := root.get_node_or_null("Duraklat")
	var c := ConfigFile.new(); c.load("user://kayit.cfg")
	print("kayit: ", c.get_value("kayit", "sahne", ""), " ", c.get_value("kayit", "nokta", ""))
	var o: CharacterBody3D = s.oyuncu
	var kol: Vector3 = s.araba.global_transform * Vector3(-1.06, 0.95, -0.05)
	o.global_position = s.araba.global_transform * Vector3(-2.2, 0.3, 0.6)
	await _bekle(0.5)
	_bak(kol)
	await _bekle(0.6)
	_kare("kapi_e")
	await _bas()
	await _bekle(0.25)
	_kare("el_kolda")
	while s.durum != "surus": await process_frame
	_kare("marş_sonrasi")
	await _bekle(2.0)
	_kare("silecek")
	Input.action_press("ileri")
	await _bekle(3.0)
	Input.action_release("ileri")
	_kare("surus")
	# kulübenin önüne ışınla
	s.araba.global_position = s.KULUBE_PARK + Vector3(0, 0.5, 0)
	s.araba.hiz = 0.0
	await _bekle(1.0)
	await _bas()
	await _bekle(0.3)
	print("durum=", s.durum)
	_kare("park")
	while s.durum != "kulube": await process_frame
	c.load("user://kayit.cfg")
	print("kayit: ", c.get_value("kayit", "sahne", ""), " ", c.get_value("kayit", "nokta", ""))
	o.global_position = s._k(Vector3(-0.6, 0.3, -2.9))
	await _bekle(1.0)
	for p in [Vector3(-0.6, 0.3, -1.8), Vector3(-0.3, 0.3, -1.5), Vector3(0.0, 0.3, -1.2), Vector3(0.2, 0.3, -1.0)]:
		o.global_position = s._k(p)
		await _bekle(0.3)
	print("iz=", s._iz_sayi)
	_bak(s._k(Vector3(0.55, 1.45, -1.98)))
	await _bekle(0.5)
	_kare("cizelge")
	_bak(s._k(Vector3(-0.2, 0.0, -1.5)))
	await _bekle(0.3)
	_kare("izler")
	quit()


func _kare(ad: String) -> void:
	n += 1
	root.get_texture().get_image().save_jpg("/tmp/claude-0/godot/yol_%02d_%s.jpg" % [n, ad], 0.85)
	print("kare ", n, " ", ad, " durum=", s.durum, " e=", s.e_yazi.visible, " ", s.e_yazi.text, " | ", s.ipucu.text)


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
