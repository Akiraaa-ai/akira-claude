extends SceneTree
var ev: Node
func _kare(ad: String, kon: Vector3, bak: Vector3) -> void:
	ev.faz = "test"
	ev.kamera.look_at_from_position(kon, bak, Vector3.UP)
	for _k in 10: await process_frame
	root.get_texture().get_image().save_jpg("/tmp/claude-0/godot/esya_%s.jpg" % ad, 0.85)
func _init() -> void:
	ev = (load("res://sahneler/ev.tscn") as PackedScene).instantiate()
	root.add_child(ev)
	await process_frame
	ev._gec("salon_kapisi")
	ev.tv_acik = true
	ev.karartma = 0.0
	ev._bitti = false
	await _kare("salon_tv", Vector3(34.0, 1.2, -0.4), Vector3(38.5, 0.8, -0.4))
	await _kare("kumanda", Vector3(34.2, 1.1, -0.2), Vector3(34.8, 0.44, -0.55))
	await _kare("yatak", Vector3(1.5, 1.6, 0.0), Vector3(-1.5, 0.4, 0.0))
	await _kare("sut", Vector3(26.6, 1.3, 1.8), ev.KASE)
	quit()
