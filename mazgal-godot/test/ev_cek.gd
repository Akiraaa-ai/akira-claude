extends SceneTree
## Test: ev sinematiğini çalıştırır, verilen saniyelerde ekran görüntüsü alır. Argümanlar: saniye listesi
func _init() -> void:
	var ev: Node = (load("res://sahneler/ev.tscn") as PackedScene).instantiate()
	root.add_child(ev)
	var anlar := []
	for a in OS.get_cmdline_user_args(): anlar.append(float(a))
	var t := 0.0
	var i := 0
	Engine.time_scale = 1.0
	while i < anlar.size():
		await process_frame
		t = ev.T
		if t >= anlar[i]:
			root.get_texture().get_image().save_jpg("/tmp/claude-0/godot/ev_%03d.jpg" % int(anlar[i]), 0.85)
			print("kare ", anlar[i], " faz=", ev.faz, " ft=", ev.ft)
			i += 1
	quit()
