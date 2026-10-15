extends SceneTree
## Test: modellerin boyutlarını ve düğüm adlarını yazar.
func aabb(n: Node) -> AABB:
	var a := AABB(); var ilk := true
	for m in n.find_children("*", "MeshInstance3D", true, false):
		var b: AABB = (m as MeshInstance3D).global_transform * (m as MeshInstance3D).get_aabb()
		if ilk: a = b; ilk = false
		else: a = a.merge(b)
	return a
func _init() -> void:
	for y in OS.get_cmdline_user_args():
		var s: Node3D = (load(y) as PackedScene).instantiate(); root.add_child(s)
		await process_frame
		var a := aabb(s)
		print(y, " boyut=", a.size, " min=", a.position)
		var adlar := []
		for n in s.find_children("*", "Node3D", true, false): adlar.append(n.name)
		print("  ", adlar.slice(0, 40))
	quit()
