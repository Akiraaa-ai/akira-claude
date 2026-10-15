extends SceneTree
## Test: her odanın giriş noktasından birer kare (koridor ve ışık kontrolü).
func _init() -> void:
	var ev: Node = (load("res://sahneler/ev.tscn") as PackedScene).instantiate()
	root.add_child(ev)
	await process_frame
	for oda in ["banyo", "mutfak", "salon_kapisi"]:
		ev._gec(oda)
		var bas: float = ev.T
		while ev.T - bas < 1.5: await process_frame
		root.get_texture().get_image().save_jpg("/tmp/claude-0/godot/giris_%s.jpg" % oda, 0.85)
		print(oda, " secili=", ev._secili)
	ev._gec("banyo")
	ev._oyuncu_yerlestir(Vector3(11.75, 0.0, -0.9), 0.0, ev.BANYO_ALAN)
	var b2: float = ev.T
	while ev.T - b2 < 1.5: await process_frame
	root.get_texture().get_image().save_jpg("/tmp/claude-0/godot/giris_dus_sonrasi.jpg", 0.85)
	quit()
