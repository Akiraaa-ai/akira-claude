extends SceneTree
## Test: mutfaktaki fatura ve zarf, saatte ağır göz kapakları ve 00:00, evden çıkış, sokağın yüklenmesi.
var ev: Node
var n := 0

func _init() -> void:
	ev = (load("res://sahneler/ev.tscn") as PackedScene).instantiate()
	root.add_child(ev)
	current_scene = ev
	await process_frame
	ev._gec("mutfak")
	await _bekle(1.0)
	ev.oyuncu.global_position = Vector3(27.1, 0, 1.9)
	_bak(Vector3(27.1, 0.86, 1.1))
	await _bekle(0.8)
	_kare("masa_kagitlar")
	var c := ConfigFile.new(); c.load("user://kayit.cfg")
	print("kayit: ", c.get_value("kayit", "sahne", ""), " ", c.get_value("kayit", "nokta", ""))
	ev._salon_basla()
	ev._gec("yayin")
	await _bekle(2.0)
	_kare("yayin")
	print("crt: ", ev._crt.playing)
	ev._gec("saat")
	for t in [5.9, 9.1, 13.4]:
		while ev.ft < t: await process_frame
		_kare("saat")
	ev._gec("cikis")
	for t in [1.5, 4.8, 6.0, 9.0, 12.0]:
		while ev.ft < t: await process_frame
		_kare("cikis")
		print("tv=", ev.tv_acik, " salon_lamba=", ev.get_node("Isiklar/SalonLamba").light_energy)
	while ev.ft < 13.4: await process_frame
	var d := root.get_node("Duraklat")
	print("yukleniyor=", d.yukleniyor_mu())
	var b := Time.get_ticks_msec()
	while d.yukleniyor_mu() and Time.get_ticks_msec() - b < 240000: await process_frame
	await process_frame
	await process_frame
	_kare("sokak")
	print("sahne=", current_scene.scene_file_path if current_scene else "yok")
	quit()


func _kare(ad: String) -> void:
	n += 1
	root.get_texture().get_image().save_jpg("/tmp/claude-0/godot/cikis_%02d_%s.jpg" % [n, ad], 0.85)
	print("kare ", n, " ", ad, " faz=", ev.faz if is_instance_valid(ev) else "-", " ft=%.2f" % (ev.ft if is_instance_valid(ev) else 0.0))


func _bekle(sn: float) -> void:
	var bas: float = ev.T
	while ev.T - bas < sn: await process_frame


func _bak(hedef: Vector3) -> void:
	var goz: Vector3 = ev.oyuncu.global_position + Vector3(0, ev.GOZ, 0)
	var d := (hedef - goz).normalized()
	ev._yaw = atan2(-d.x, -d.z)
	ev._pitch = asin(d.y)
