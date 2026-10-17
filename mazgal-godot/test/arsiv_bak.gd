extends SceneTree
var a: Node
func _cek(ad: String, yer: Vector3, hedef: Vector3) -> void:
	a.kamera.global_transform = Transform3D(Basis.looking_at(hedef - yer), yer)
	for i in 8: await process_frame
	root.get_texture().get_image().save_jpg("/tmp/claude-0/godot/ar_%s.jpg" % ad, 0.85)
func _init() -> void:
	a = (load("res://sahneler/arsiv.tscn") as PackedScene).instantiate()
	root.add_child(a)
	current_scene = a
	for i in 3: await process_frame
	a.durum = "test"
	a.siyah.modulate.a = 0.0
	a._oyuncu_dur(true)
	a.oyuncu.global_position = Vector3(0, -50, 0)
	var t: Vector3 = a._tutanak_yeri
	print("tutanak ", t)
	await _cek("1kuyu", Vector3(0.6, 1.5, 3.0), Vector3(0, 3.5, 1.9))
	await _cek("2koridor", Vector3(0, 1.6, 0.5), Vector3(0, 1.3, -30))
	await _cek("3kapilar", Vector3(0.6, 1.6, -10), Vector3(-1.2, 1.2, -13))
	await _cek("4ofis", a.OFIS_YERI + Vector3(-5.5, 1.85, -0.4), t)
	await _cek("5masa14", t + Vector3(0.0, 0.75, 0.8), t)
	await _cek("6kodkapi", Vector3(-0.3, 1.6, -32.5), Vector3(0.3, 1.2, -36))
	quit()
