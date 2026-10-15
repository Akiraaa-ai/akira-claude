extends SceneTree
func _init() -> void:
	var s: Node = (load("res://modeller/sehir.glb") as PackedScene).instantiate()
	for m in s.find_children("*", "MeshInstance3D", true, false):
		var mi := m as MeshInstance3D
		for i in mi.mesh.get_surface_count():
			var mat := mi.mesh.surface_get_material(i)
			var aabb := Vector3.ZERO
			var arr := mi.mesh.surface_get_arrays(i)
			print(mi.name, " #", i, " ", mat.resource_name if mat else "-", " v=", (arr[0] as PackedVector3Array).size())
	quit()
