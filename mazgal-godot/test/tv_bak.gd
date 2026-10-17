extends SceneTree
var ev: Node
func _init() -> void:
	ev = (load("res://sahneler/ev.tscn") as PackedScene).instantiate()
	root.add_child(ev)
	current_scene = ev
	await process_frame
	ev._ruya_bitir()
	ev._salon_basla()
	ev._gec("yayin")
	for i in 5: await process_frame
	ev.tv_t = 44.0
	ev.set_process(false)
	ev.kamera.global_transform = Transform3D(Basis.looking_at(ev.EKRAN - Vector3(36.4, 1.0, -0.4)), Vector3(36.4, 1.0, -0.4))
	for i in 3:
		ev.tv_t += 0.05
		ev._tv_guncelle(0.05)
		await process_frame
	root.get_texture().get_image().save_jpg("/tmp/claude-0/godot/tv1.jpg", 0.85)
	quit()
