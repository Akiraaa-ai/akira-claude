extends SceneTree
func _init() -> void:
	var s: Node3D = (load(OS.get_cmdline_user_args()[0]) as PackedScene).instantiate(); root.add_child(s)
	await process_frame
	for m in s.find_children("*", "MeshInstance3D", true, false):
		var mi := m as MeshInstance3D
		for i in mi.mesh.get_surface_count():
			print(mi.name, " ", mi.mesh.surface_get_material(i).resource_name if mi.mesh.surface_get_material(i) else "-", " ", mi.global_transform * mi.get_aabb())
	quit()
