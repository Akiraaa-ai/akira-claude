extends SceneTree
## Test: her oda modelinde dikey büyük yüzeylerin malzemelerini alanına göre sıralar (duvar malzemesini bulmak için).
func _init() -> void:
	for yol in ["res://modeller2/seliminevi/interior_8_bedroom.glb", "res://modeller2/seliminevi/kitchen.glb", "res://modeller2/seliminevi/interior_15_mini_loft (1).glb"]:
		var s: Node3D = (load(yol) as PackedScene).instantiate()
		if "kitchen" in yol: s.scale = Vector3.ONE * 33
		root.add_child(s)
		await process_frame
		var alan := {}
		for m in s.find_children("*", "MeshInstance3D", true, false):
			var mi := m as MeshInstance3D
			for i in mi.mesh.get_surface_count():
				var mat := mi.mesh.surface_get_material(i)
				var arr := mi.mesh.surface_get_arrays(i)
				var v: PackedVector3Array = arr[0]
				var ind: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] else PackedInt32Array()
				var toplam := 0.0
				var n := ind.size() if ind.size() > 0 else v.size()
				for t in range(0, n, 3):
					var a: Vector3 = mi.global_transform * v[ind[t] if ind.size() else t]
					var b: Vector3 = mi.global_transform * v[ind[t+1] if ind.size() else t+1]
					var c: Vector3 = mi.global_transform * v[ind[t+2] if ind.size() else t+2]
					var nn := (b - a).cross(c - a)
					var ar := nn.length() * 0.5
					if ar > 0.0 and absf(nn.normalized().y) < 0.1: toplam += ar
				var ad := "%s/%s" % [mi.name, mat.resource_name if mat else "-"]
				var doku := ""
				if mat is StandardMaterial3D and (mat as StandardMaterial3D).albedo_texture: doku = (mat as StandardMaterial3D).albedo_texture.resource_path.get_file()
				var renk := (mat as StandardMaterial3D).albedo_color if mat is StandardMaterial3D else Color()
				alan[ad] = [toplam, doku, renk]
		var anahtarlar := alan.keys()
		anahtarlar.sort_custom(func(x, y): return alan[x][0] > alan[y][0])
		print("== ", yol)
		for k in anahtarlar.slice(0, 8): print("  %.1f m2  %s  %s  %s" % [alan[k][0], k, alan[k][1], alan[k][2]])
		s.queue_free()
	quit()
