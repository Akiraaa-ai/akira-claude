extends SceneTree
## Test: her sokak lambasının direğini ve kolun ucundaki başını ayrı bulur; ışığın çıkacağı nokta = başın alt yüzü.
func _init() -> void:
	var s: Node3D = (load("res://modeller/sehir.glb") as PackedScene).instantiate()
	root.add_child(s)
	s.transform = Transform3D(Basis(Vector3(-1,0,0), Vector3(0,1,0), Vector3(0,0,-1)), Vector3(-14.5, 0, -43.75))
	await process_frame
	var noktalar := []
	for m in s.find_children("*", "MeshInstance3D", true, false):
		var mi := m as MeshInstance3D
		for i in mi.mesh.get_surface_count():
			var mat := mi.mesh.surface_get_material(i)
			var ad: String = mat.resource_name if mat else "-"
			if not ad.begins_with("Street_Assets"): continue
			var v: PackedVector3Array = mi.mesh.surface_get_arrays(i)[0]
			for p in v:
				var w: Vector3 = mi.global_transform * p
				if w.y >= 2.5: noktalar.append(w)
	# direkler: 2.5-3.5 m arasındaki noktalar, 0.6 m'lik kümeler
	var direkler := []
	for w in noktalar:
		if w.y > 3.5: continue
		var bulundu := false
		for q in direkler:
			if Vector2(q[0].x, q[0].y).distance_to(Vector2(w.x, w.z)) < 0.6:
				q[1] += Vector2(w.x, w.z); q[2] += 1; q[0] = q[1] / q[2]; bulundu = true; break
		if not bulundu: direkler.append([Vector2(w.x, w.z), Vector2(w.x, w.z), 1])
	for d in direkler:
		var dp: Vector2 = d[0]
		# direğin tepesine kadar noktalar ve kol
		var ust := []
		var tepe := -99.0
		for w in noktalar:
			var u := Vector2(w.x, w.z).distance_to(dp)
			if u < 3.6 and w.y > 3.5 and w.y < 12.0:
				ust.append(w); tepe = maxf(tepe, w.y)
		if ust.size() < 10 or tepe < 5.0: continue
		var uzak := 0.0; var uc := dp
		for w in ust:
			var u := Vector2(w.x, w.z).distance_to(dp)
			if w.y > tepe - 1.0 and u > uzak: uzak = u; uc = Vector2(w.x, w.z)
		var bas := Vector2.ZERO; var bn := 0; var alt := 99.0
		for w in ust:
			if Vector2(w.x, w.z).distance_to(uc) < 0.6:
				bas += Vector2(w.x, w.z); bn += 1; alt = minf(alt, w.y)
		bas /= bn
		print("LAMBA2 direk=(%.2f,%.2f) bas=(%.2f,%.2f) alt=%.2f tepe=%.2f kol=%.2f n=%d" % [dp.x, dp.y, bas.x, bas.y, alt, tepe, uzak, ust.size()])
	quit()
