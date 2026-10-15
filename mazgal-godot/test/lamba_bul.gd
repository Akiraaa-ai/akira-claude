extends SceneTree
## Test: şehirdeki sokak eşyası yüzeylerinde yüksek noktaları (lamba başları) kümeler ve dünya konumlarını yazar.
func _init() -> void:
	var s: Node3D = (load("res://modeller/sehir.glb") as PackedScene).instantiate()
	root.add_child(s)
	s.transform = Transform3D(Basis(Vector3(-1,0,0), Vector3(0,1,0), Vector3(0,0,-1)), Vector3(-14.5, 0, -43.75))
	await process_frame
	var hucre := {}
	for m in s.find_children("*", "MeshInstance3D", true, false):
		var mi := m as MeshInstance3D
		for i in mi.mesh.get_surface_count():
			var mat := mi.mesh.surface_get_material(i)
			var ad: String = mat.resource_name if mat else "-"
			if not ad.begins_with("Street_Assets"): continue
			var v: PackedVector3Array = mi.mesh.surface_get_arrays(i)[0]
			for p in v:
				var w: Vector3 = mi.global_transform * p
				if w.y < 3.0: continue
				var k := Vector2i(floori(w.x / 2.0), floori(w.z / 2.0))
				if not hucre.has(k): hucre[k] = [Vector3.ZERO, 0, -99.0, ad]
				hucre[k][0] += w; hucre[k][1] += 1; hucre[k][2] = maxf(hucre[k][2], w.y)
	# komşu hücreleri birleştir
	var kumeler := []
	for k in hucre:
		var c: Vector3 = hucre[k][0] / hucre[k][1]
		var bulundu := false
		for q in kumeler:
			if Vector2(q[0].x, q[0].z).distance_to(Vector2(c.x, c.z)) < 3.0:
				q[0] = (q[0] * q[1] + c * hucre[k][1]) / (q[1] + hucre[k][1]); q[1] += hucre[k][1]; q[2] = maxf(q[2], hucre[k][2]); bulundu = true; break
		if not bulundu: kumeler.append([c, hucre[k][1], hucre[k][2], hucre[k][3]])
	for q in kumeler: print("LAMBA %.1f %.1f %.1f tepe=%.1f n=%d %s" % [q[0].x, q[0].y, q[0].z, q[2], q[1], q[3]])
	quit()
