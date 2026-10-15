extends SceneTree
func _init() -> void:
	var s: Node3D = (load("res://modeller2/klübe/booth/Booth.gltf") as PackedScene).instantiate(); root.add_child(s)
	for m in s.find_children("*", "MeshInstance3D", true, false): m.create_trimesh_collision()
	for _i in 3: await physics_frame
	var uz := s.get_world_3d().direct_space_state
	var satir := ""
	for zi in [-12, -6]:
		satir = "z=%5.2f " % (zi * 0.1)
		for xi in [8]:
			var q := PhysicsRayQueryParameters3D.create(Vector3(xi*0.1, 2.0, zi*0.1), Vector3(xi*0.1, 0.05, zi*0.1))
			var r := uz.intersect_ray(q)
			satir += ("%.3f" % r.position.y) if r and r.position.y < 1.8 else " ."
		print(satir)
	quit()
