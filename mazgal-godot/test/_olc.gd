extends SceneTree
func _init() -> void:
	await process_frame
	var p: PackedScene = load("res://sahneler/ev.tscn")
	var ev: Node3D = p.instantiate()
	for oda in ["Banyo", "YatakOdasi", "Mutfak", "Salon"]:
		var o := ev.get_node_or_null(oda)
		if o == null: continue
		var liste := []
		for m in o.find_children("*", "MeshInstance3D", true, false):
			pass
	root.add_child(ev)
	await process_frame
	for oda in ["Banyo"]:
		var o := ev.get_node(oda)
		for m in o.find_children("*", "MeshInstance3D", true, false):
			var mi := m as MeshInstance3D
			var a: AABB = mi.global_transform * mi.get_aabb()
			if a.size.y > 1.2: print(oda, " ", mi.name, " ", a)
	print("kapı:", ev._dunya_kutusu(ev.kapi_yatak.get_parent()))
	quit()
