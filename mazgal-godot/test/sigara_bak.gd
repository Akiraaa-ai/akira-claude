extends SceneTree
## Test: mutfakta sigara sahnesi.
var ev: Node
func _init() -> void:
	ev = (load("res://sahneler/ev.tscn") as PackedScene).instantiate()
	root.add_child(ev)
	current_scene = ev
	await process_frame
	ev._gec("mutfak")
	ev.karartma = 0.0
	ev._gec("s_sigara")
	for a in [1.0, 2.6, 3.3, 5.4, 8.0, 9.3, 11.4, 19.0]:
		while ev.faz == "s_sigara" and ev.ft < a: await process_frame
		root.get_texture().get_image().save_jpg("/tmp/claude-0/godot/sig_%s.jpg" % a, 0.85)
	while ev.faz == "s_sigara": await process_frame
	print("sonra faz=", ev.faz)
	quit()
