extends SceneTree
## Test: modeli ölçekleyip yukarıdan ızgara halinde ışın atar, yükseklik haritası yazar. Argümanlar: yol ölçek adım
func _init() -> void:
	var a := OS.get_cmdline_user_args()
	var s: Node3D = (load(a[0]) as PackedScene).instantiate(); s.scale = Vector3.ONE * float(a[1]); root.add_child(s)
	await process_frame
	var b := AABB(); var ilk := true
	for m in s.find_children("*", "MeshInstance3D", true, false):
		(m as MeshInstance3D).create_trimesh_collision()
		var bb: AABB = (m as MeshInstance3D).global_transform * (m as MeshInstance3D).get_aabb()
		if ilk: b = bb; ilk = false
		else: b = b.merge(bb)
	for _i in 3: await physics_frame
	var uz := s.get_world_3d().direct_space_state
	var adim := float(a[2])
	var tepe := b.position.y + 2.2
	print("x: ", b.position.x, "..", b.end.x, "  z: ", b.position.z, "..", b.end.z, " ışın tepe ", tepe)
	var z := b.position.z + adim * 0.5
	while z < b.end.z:
		var satir := "z=%6.2f " % z
		var x := b.position.x + adim * 0.5
		while x < b.end.x:
			var r := uz.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(x, tepe, z), Vector3(x, b.position.y - 1, z)))
			satir += (" %4.2f" % r.position.y) if r else "   . "
			x += adim
		print(satir)
		z += adim
	quit()
