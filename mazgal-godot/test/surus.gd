extends SceneTree
## Test: sokak sahnesinde Selim arabaya biner, otomatik sürücü rotayı izler, konum ve takılmalar yazılır.
## Argüman "cek" verilirse yol boyunca ekran görüntüsü alınır.
var ROTA := [Vector2(-14, 22), Vector2(-14, 4), Vector2(-22, 0), Vector2(-54, 0), Vector2(-61, -7), Vector2(-61, -66), Vector2(-58.5, -75)]
func _init() -> void:
	var cek := "cek" in OS.get_cmdline_user_args()
	var s: Node = load("res://sahneler/sokak.tscn").instantiate()
	root.add_child(s)
	for _i in 10: await physics_frame
	var a: CharacterBody3D = s.get_node("Araba")
	var o: CharacterBody3D = s.get_node("Selim")
	print("baslangic araba ", a.global_position, " selim ", o.global_position)
	if cek: _kaydet("s_baslangic")
	s._binise_basla()
	var t := 0.0
	var resim := 0
	while s.durum != "surus":
		await physics_frame; t += 1.0 / 60.0
		if cek and int(t) != resim: resim = int(t); _kaydet("s_binis_%02d" % resim)
	print("surus basladi t=", t)
	var i := 0; var sure := 0.0; var son := a.global_position; var takili := 0.0; var yaz := 0.0; var foto := 0.0
	while i < ROTA.size() and sure < 120.0:
		await physics_frame; sure += 1.0 / 60.0
		var p := Vector2(a.global_position.x, a.global_position.z)
		var h: Vector2 = ROTA[i]
		if p.distance_to(h) < 3.5: i += 1; continue
		var ileri := -a.global_transform.basis.z
		var f := Vector2(ileri.x, ileri.z).normalized()
		var hedef := (h - p).normalized()
		var aci := f.angle_to(hedef)   # + ise sağa
		Input.action_release("sol"); Input.action_release("sag"); Input.action_release("ileri"); Input.action_release("geri")
		var yon: float = clamp(-aci * 2.5, -1.0, 1.0)
		if yon > 0: Input.action_press("sol", yon)
		elif yon < 0: Input.action_press("sag", -yon)
		var istenen := 9.0 if absf(aci) < 0.3 else 4.0
		if i == ROTA.size() - 1: istenen = 3.0
		if a.hiz < istenen: Input.action_press("ileri")
		elif a.hiz > istenen + 1.5: Input.action_press("geri")
		yaz += 1.0 / 60.0
		if yaz >= 1.0:
			yaz = 0.0
			var gidilen := a.global_position.distance_to(son); son = a.global_position
			print("t=%5.1f hedef=%d konum=(%.1f, %.2f, %.1f) hiz=%.1f gidilen=%.1f" % [sure, i, a.global_position.x, a.global_position.y, a.global_position.z, a.hiz, gidilen])
			if gidilen < 0.5: takili += 1.0
			if takili > 4: print("TAKILDI"); break
		if cek:
			foto += 1.0 / 60.0
			if foto > 4.0: foto = 0.0; _kaydet("s_surus_%03d" % int(sure))
	for ac in ["sol", "sag", "ileri", "geri"]: Input.action_release(ac)
	while a.hiz > 0.2:
		Input.action_press("geri"); await physics_frame
	Input.action_release("geri")
	for _k in 60: await physics_frame
	print("son konum ", a.global_position, " hiz ", a.hiz, " durum ", s.durum, " ipucu '", s.ipucu.text, "'")
	if s.ipucu.text.begins_with("E"):
		s._inise_basla()
		for _k in 200: await physics_frame
		print("indi: durum ", s.durum, " selim ", o.global_position)
		if cek: _kaydet("s_indi")
	quit()

func _kaydet(ad: String) -> void:
	root.get_texture().get_image().save_jpg("/tmp/claude-0/godot/%s.jpg" % ad, 0.85)
