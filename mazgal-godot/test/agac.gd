extends SceneTree
## Test: bir modelin düğüm ağacını ve meshlerin dünya kutularını yazar. Argüman: yol
func _init() -> void:
	var s: Node3D = (load(OS.get_cmdline_user_args()[0]) as PackedScene).instantiate()
	root.add_child(s)
	await process_frame
	for n in s.find_children("*", "", true, false):
		var t := ""
		if n is MeshInstance3D:
			var bb: AABB = n.global_transform * n.get_aabb()
			t = " AABB %s..%s" % [bb.position, bb.end]
		print(str(s.get_path_to(n)), " [", n.get_class(), "]", t)
	quit()
