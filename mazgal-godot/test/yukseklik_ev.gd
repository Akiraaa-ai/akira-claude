extends SceneTree
## Test: ev odalarına çarpışma ekler, verilen xz noktalarında yukarıdan ışın atıp yüzey yüksekliğini ve çarpan meshi yazar.
## Argüman: "x,z" ... (başlangıç yüksekliği 2.6)
func _init() -> void:
	var ev: Node3D = (load("res://sahneler/ev.tscn") as PackedScene).instantiate()
	ev.set_script(null)
	root.add_child(ev)
	await process_frame
	var adlar := {}
	for m in ev.find_children("*", "MeshInstance3D", true, false):
		var mi := m as MeshInstance3D
		if mi.mesh == null: continue
		mi.create_trimesh_collision()
		for c in mi.get_children(): if c is StaticBody3D: adlar[(c as StaticBody3D).get_rid()] = mi.name
	await physics_frame
	await physics_frame
	var uzay := root.world_3d.direct_space_state
	for a in OS.get_cmdline_user_args():
		var k := a.split_floats(",")
		var ust := 2.6 if k.size() < 3 else k[2]
		var q := PhysicsRayQueryParameters3D.create(Vector3(k[0], ust, k[1]), Vector3(k[0], -1, k[1]))
		var r := uzay.intersect_ray(q)
		print(a, " -> ", (r.position.y if r else "yok"), " ", (adlar.get(r.rid, "?") if r else ""))
	quit()
