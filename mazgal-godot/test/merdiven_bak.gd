extends SceneTree
## Test: evden çıkışta 3 katlık merdiven boşluğu.
var ev: Node
func _init() -> void:
	ev = (load("res://sahneler/ev.tscn") as PackedScene).instantiate()
	root.add_child(ev)
	current_scene = ev
	await process_frame
	ev._ruya_bitir()
	ev._salon_basla()
	ev._gec("cikis")
	for a in [11.0, 13.6, 15.4, 17.0, 18.6, 20.5, 26.0, 31.6]:
		while ev.faz == "cikis" and ev.ft < a: await process_frame
		root.get_texture().get_image().save_jpg("/tmp/claude-0/godot/mer_%s.jpg" % a, 0.85)
	print("son ft=", ev.ft)
	quit()
