extends SceneTree
## Test: odalardaki büyük dikey yüzeylerin hangi yöne baktığını ve nerede durduğunu yazar.
func _init() -> void:
	for yol in ["res://modeller2/seliminevi/interior_8_bedroom.glb", "res://modeller2/seliminevi/interior_15_mini_loft (1).glb", "res://modeller2/seliminevi/kitchen.glb", "res://modeller2/seliminevi/mildly_depressing_bathroom.glb"]:
		if not ResourceLoader.exists(yol):
			print("atlandı (dosya yok): ", yol)
			continue
		var s: Node3D = (load(yol) as PackedScene).instantiate()
		if "kitchen" in yol: s.scale = Vector3.ONE * 33
		root.add_child(s)
		await process_frame
		var alan := {}
		for m in s.find_children("*", "MeshInstance3D", true, false):
			var mi := m as MeshInstance3D
			for i in mi.mesh.get_surface_count():
				var arr := mi.mesh.surface_get_arrays(i)
				var v: PackedVector3Array = arr[0]
				var ind: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] else PackedInt32Array()
				var n := ind.size() if ind.size() > 0 else v.size()
				for t in range(0, n, 3):
					var a: Vector3 = mi.global_transform * v[ind[t] if ind.size() else t]
					var b: Vector3 = mi.global_transform * v[ind[t+1] if ind.size() else t+1]
					var c: Vector3 = mi.global_transform * v[ind[t+2] if ind.size() else t+2]
					var nn := (b - a).cross(c - a)
					var ar := nn.length() * 0.5
					if ar < 0.05: continue
					nn = nn.normalized()
					var eksen := ""
					var k := 0.0
					if absf(nn.x) > 0.95: eksen = "x"; k = a.x
					elif absf(nn.z) > 0.95: eksen = "z"; k = a.z
					else: continue
					var anahtar := "%s=%.2f %s" % [eksen, k, mi.name]
					alan[anahtar] = alan.get(anahtar, 0.0) + ar
		var ks := alan.keys()
		ks.sort_custom(func(x, y): return alan[x] > alan[y])
		print("== ", yol)
		for kk in ks.slice(0, 14): print("  %.1f  %s" % [alan[kk], kk])
		s.queue_free()
	quit()
