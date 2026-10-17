extends SceneTree
var ev: Node
func _init() -> void:
	ev = (load("res://sahneler/ev.tscn") as PackedScene).instantiate()
	root.add_child(ev)
	await process_frame
	ev._gec("banyo")
	ev._oyuncu_yerlestir(Vector3(11.75, 0.0, -0.9), 0.0, ev.BANYO_ALAN)
	ev._etkiles("banyo_isik")
	ev._esya("lavabo", ev.LAVABO, 1.7)
	ev._etkiles("lavabo")
	ev.karartma = 0.0
	for a in [2.0, 3.0, 5.0, 10.2, 13.0]:
		while ev.ft < a: await process_frame
		root.get_texture().get_image().save_jpg("/tmp/claude-0/godot/lav_%s.jpg" % a, 0.85)
	while ev.faz != "oyun": await process_frame
	print("esyalar ", ev._esyalar.keys(), " gorev ", ev.gorev_yazi.text)
	quit()
