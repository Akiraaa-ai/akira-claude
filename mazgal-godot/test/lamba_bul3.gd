extends SceneTree
## Test: eski lamba kümelerinden yola çıkıp her lambanın direğini ve kol ucundaki başını (bir ya da iki baş) bulur.
const TOHUM := [Vector3(-107.4, 7.8, -76.0), Vector3(-107.4, 7.8, -65.9), Vector3(-107.4, 7.8, -55.8), Vector3(-107.4, 7.8, -45.6), Vector3(-107.4, 7.8, -35.5), Vector3(-107.4, 7.8, -25.4), Vector3(-107.4, 7.8, -15.3), Vector3(-105.9, 9.5, -81.9), Vector3(-102.0, 8.5, 15.7), Vector3(-102.0, 8.5, 26.0), Vector3(-102.0, 8.5, 36.2), Vector3(-102.0, 8.5, 46.4), Vector3(-98.1, 7.8, -85.3), Vector3(-94.3, 7.8, -5.9), Vector3(-94.3, 8.5, 4.4), Vector3(-94.3, 8.5, 54.0), Vector3(-86.0, 7.8, -85.3), Vector3(-84.2, 7.8, -5.9), Vector3(-84.2, 8.5, 4.4), Vector3(-84.2, 8.5, 54.0), Vector3(-74.0, 7.8, -85.3), Vector3(-74.0, 7.8, -5.9), Vector3(-74.0, 8.5, 4.4), Vector3(-74.0, 8.5, 54.0), Vector3(-68.1, 9.5, 4.2), Vector3(-66.4, 8.5, 15.8), Vector3(-66.4, 8.5, 26.0), Vector3(-66.4, 8.5, 36.2), Vector3(-66.4, 8.5, 46.4), Vector3(-64.7, 7.8, -72.2), Vector3(-64.7, 7.8, -60.8), Vector3(-64.7, 7.8, -49.4), Vector3(-64.7, 7.8, -38.0), Vector3(-64.7, 7.8, -26.7), Vector3(-64.7, 7.8, -15.3), Vector3(-52.3, 7.8, 15.8), Vector3(-52.3, 7.8, 26.0), Vector3(-52.3, 7.8, 36.2), Vector3(-52.3, 7.8, 46.4), Vector3(-50.6, 8.5, -72.3), Vector3(-50.6, 8.5, -60.9), Vector3(-50.6, 8.5, -49.5), Vector3(-50.6, 8.5, -38.1), Vector3(-50.6, 8.5, -26.7), Vector3(-50.6, 8.5, -15.3), Vector3(-43.0, 7.8, 2.7), Vector3(-43.0, 7.8, 59.5), Vector3(-43.0, 8.5, -3.9), Vector3(-41.5, 8.5, -83.6), Vector3(-35.6, 9.5, -83.7), Vector3(-32.0, 8.9, -72.4), Vector3(-31.1, 8.5, -3.9), Vector3(-29.5, 8.5, -49.4), Vector3(-29.2, 9.5, -61.1), Vector3(-27.9, 8.5, -38.0), Vector3(-26.3, 7.8, 2.7), Vector3(-26.3, 7.8, 59.5), Vector3(-26.3, 8.5, -26.5), Vector3(-24.6, 8.5, -15.1), Vector3(-23.1, 9.5, -75.9), Vector3(-19.7, 8.5, -65.4), Vector3(-18.4, 9.5, 56.1), Vector3(-18.1, 8.5, -54.6), Vector3(-17.0, 9.5, -32.8), Vector3(-16.9, 7.8, 12.0), Vector3(-16.9, 7.8, 24.7), Vector3(-16.9, 7.8, 37.4), Vector3(-16.9, 7.8, 50.2), Vector3(-16.6, 8.5, -43.8), Vector3(-14.7, 8.5, -83.6), Vector3(-13.8, 8.6, -22.2), Vector3(-12.0, 8.5, -11.5), Vector3(-9.2, 9.5, -3.8), Vector3(-6.8, 9.5, 6.1), Vector3(-6.6, 8.5, 15.7), Vector3(-6.6, 8.5, 26.0), Vector3(-6.6, 8.5, 36.2), Vector3(-6.6, 8.5, 46.4), Vector3(-3.9, 8.5, -83.6), Vector3(-3.2, 8.5, -3.9), Vector3(1.0, 8.5, 4.4), Vector3(1.0, 8.5, 54.0), Vector3(6.9, 8.5, -83.6), Vector3(7.2, 8.5, -3.9), Vector3(14.0, 8.5, 54.0), Vector3(17.7, 8.5, -3.9), Vector3(17.8, 8.5, -83.6), Vector3(17.8, 8.5, 4.4), Vector3(25.4, 8.5, -76.0), Vector3(25.4, 8.5, -65.2), Vector3(25.4, 8.5, -54.5), Vector3(25.4, 8.5, -43.7), Vector3(25.4, 8.5, -33.0), Vector3(25.4, 8.5, -22.2), Vector3(25.4, 8.5, -11.5), Vector3(25.4, 8.5, 12.0), Vector3(25.4, 8.5, 23.5), Vector3(25.4, 8.5, 35.0), Vector3(25.4, 8.5, 46.4), Vector3(25.6, 9.5, 52.3)]
func _init() -> void:
	var s: Node3D = (load("res://modeller/sehir.glb") as PackedScene).instantiate()
	root.add_child(s)
	s.transform = Transform3D(Basis(Vector3(-1,0,0), Vector3(0,1,0), Vector3(0,0,-1)), Vector3(-14.5, 0, -43.75))
	await process_frame
	var hepsi := PackedVector3Array()
	for m in s.find_children("*", "MeshInstance3D", true, false):
		var mi := m as MeshInstance3D
		for i in mi.mesh.get_surface_count():
			var mat := mi.mesh.surface_get_material(i)
			var ad: String = mat.resource_name if mat else "-"
			if not ad.begins_with("Street_Assets"): continue
			var v: PackedVector3Array = mi.mesh.surface_get_arrays(i)[0]
			for p in v: hepsi.append(mi.global_transform * p)
	# direk üstü fenerler: tohumun tam altında (0.35 m içinde) yerde noktası olanlar
	for t in TOHUM:
		var yer := 0; var ust_n := 0; var tepe := -99.0; var dip := 99.0
		for w in hepsi:
			if Vector2(w.x, w.z).distance_to(Vector2(t.x, t.z)) > 0.35: continue
			if w.y < 0.6: yer += 1
			elif w.y > t.y - 2.5 and w.y < t.y + 1.5: ust_n += 1; tepe = maxf(tepe, w.y); dip = minf(dip, w.y)
		if yer > 0 and ust_n > 0: print("FENER %.2f %.2f %.2f tepe %.2f dip %.2f yer %d ust %d" % [t.x, t.y, t.z, tepe, dip, yer, ust_n])
	var bulunan := []
	for t in TOHUM:
		var tp := Vector2(t.x, t.z)
		var ust := []; var alt_n := []
		var tepe := -99.0
		for w in hepsi:
			var u := Vector2(w.x, w.z).distance_to(tp)
			if u > 4.5: continue
			if w.y > t.y - 2.0 and w.y < t.y + 3.0: ust.append(w); tepe = maxf(tepe, w.y)
			elif w.y < 1.2: alt_n.append(w)
		# direk: üstte olup tam altında da noktası olan yer
		var dp := Vector2.ZERO; var dn := 0
		for w in ust:
			for a in alt_n:
				if Vector2(w.x, w.z).distance_to(Vector2(a.x, a.z)) < 0.3:
					dp += Vector2(w.x, w.z); dn += 1; break
		if dn == 0: print("YOK ", t); continue
		dp /= dn
		# başlar: direkten 1.2 m'den uzak üst noktalar, yönlere göre gruplanır
		var gruplar := []
		for w in ust:
			var d := Vector2(w.x, w.z) - dp
			if d.length() < 1.2: continue
			var ac := d.angle()
			var g = null
			for q in gruplar:
				if absf(angle_difference(q[0], ac)) < 0.7: g = q; break
			if g == null: gruplar.append([ac, d.length(), w]); continue
			if d.length() > g[1]: g[1] = d.length(); g[2] = w
		for q in gruplar:
			var uc: Vector3 = q[2]
			var bas := Vector3.ZERO; var bn := 0; var en_alt := 99.0
			for w in ust:
				if Vector2(w.x, w.z).distance_to(Vector2(uc.x, uc.z)) < 0.55:
					bas += w; bn += 1; en_alt = minf(en_alt, w.y)
			bas /= bn
			var k := Vector3(bas.x, en_alt, bas.z)
			var tekrar := false
			for b in bulunan:
				if Vector2(b.x, b.z).distance_to(Vector2(k.x, k.z)) < 1.0: tekrar = true
			if tekrar: continue
			bulunan.append(k)
			print("BAS %.2f %.2f %.2f direk %.2f %.2f kol %.2f" % [k.x, k.y, k.z, dp.x, dp.y, q[1]])
	quit()
