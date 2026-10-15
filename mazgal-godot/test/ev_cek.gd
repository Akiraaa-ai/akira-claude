extends SceneTree
## Test: ev sinematiğini çalıştırır, verilen saniyelerde ekran görüntüsü alır.
## Argümanlar: [faz:ad] saniye listesi (faz verilirse o fazdan başlar, saniyeler o andan sayılır)
func _init() -> void:
	var ev: Node = (load("res://sahneler/ev.tscn") as PackedScene).instantiate()
	root.add_child(ev)
	var anlar := []
	var bas := 0.0
	await process_frame
	for a in OS.get_cmdline_user_args():
		if a.begins_with("faz:"):
			ev._gec(a.substr(4))
			bas = ev.T
		else:
			anlar.append(float(a))
	var i := 0
	while i < anlar.size():
		await process_frame
		if ev.T - bas >= anlar[i]:
			root.get_texture().get_image().save_jpg("/tmp/claude-0/godot/ev_%03d.jpg" % int(anlar[i]), 0.85)
			print("kare ", anlar[i], " faz=", ev.faz, " ft=", ev.ft)
			i += 1
	quit()
