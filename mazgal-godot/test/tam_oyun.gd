extends SceneTree
## Baştan sona oyun testi: ana menüden Yeni Oyun, evde gerçek oyuncu gibi yürüyüp bakarak E'ye basar,
## her odada sekiz yöne yürüyüp boşluğa çıkılıyor mu bakar. Sorunları "HATA" ile yazar.
## Argüman "devam": kayıttan Devam Et yolunu dener.

var hata := 0
var _son_kare := 0
var _son_kapi := Vector3.INF

func _init() -> void:
	await process_frame
	var args := OS.get_cmdline_user_args()
	var d := root.get_node("Duraklat")
	if "devam" in args:
		await _devam_testi(d)
		quit()
		return
	d.yeni_oyun()
	var menu: Node = (load("res://sahneler/baslangic.tscn") as PackedScene).instantiate()
	root.add_child(menu)
	current_scene = menu
	var t0 := Time.get_ticks_msec()
	while menu.durum != "bekle" and menu.durum != "menu":
		await process_frame
		if Time.get_ticks_msec() - t0 > 120000: _hata("açılış 'bekle' durumuna gelmedi: " + str(menu.durum)); break
	print("açılış bitti, durum=", menu.durum, " süre=", (Time.get_ticks_msec() - t0) / 1000.0)
	_tus(KEY_SPACE)
	await _sn(1.0)
	print("menü: ", menu.durum, " devam düğmesi var mı=", _dugme_var(menu, "DEVAM ET"))
	menu._yeni_oyun()
	var ev: Node = await _sahne_bekle("res://sahneler/ev.tscn")
	if ev == null: return
	await _ev_oyna(ev)
	var sokak: Node = await _sahne_bekle("res://sahneler/sokak.tscn")
	if sokak == null: return
	await _sokak_oyna(sokak)
	print("BİTTİ hata=", hata)
	quit()


func _hata(m: String) -> void:
	hata += 1
	print("HATA: ", m)


func _sn(s: float) -> void:
	var b := Time.get_ticks_msec()
	while Time.get_ticks_msec() - b < s * 1000.0: await process_frame


func _tus(k: Key) -> void:
	var e := InputEventKey.new(); e.physical_keycode = k; e.keycode = k; e.pressed = true
	Input.parse_input_event(e)
	await process_frame
	var r := InputEventKey.new(); r.physical_keycode = k; r.keycode = k; r.pressed = false
	Input.parse_input_event(r)


func _dugme_var(n: Node, metin: String) -> bool:
	for b in n.find_children("*", "Button", true, false):
		if (b as Button).text == metin: return true
	return false


func _sahne_bekle(yol: String) -> Node:
	var b := Time.get_ticks_msec()
	while current_scene == null or current_scene.scene_file_path != yol:
		await process_frame
		if Time.get_ticks_msec() - b > 300000:
			_hata("sahne açılmadı: " + yol)
			return null
	print("sahne açıldı: ", yol, " (", (Time.get_ticks_msec() - b) / 1000.0, " sn)")
	for i in 3: await process_frame
	return current_scene


# ---------------------------------------------------------------- ev
func _ev_oyna(ev: Node) -> void:
	var b := Time.get_ticks_msec()
	while ev.faz != "oyun":
		await process_frame
		if Time.get_ticks_msec() - b > 90000: _hata("uyanış bitmedi, faz=" + str(ev.faz)); return
	print("uyanış bitti (", (Time.get_ticks_msec() - b) / 1000.0, " sn) eşyalar=", ev._esyalar.keys())
	var sira := ["yatak_kapi", "banyo_kapi", "banyo_isik", "lavabo", "dus", "banyo_cikis", "mutfak_kapi", "buzdolabi", "dolap", "masa", "telefon", "salon_kapi", "koltuk"]
	var gezildi := {}
	var bekleme := Time.get_ticks_msec()
	while is_instance_valid(ev) and ev.faz != "salon" and ev.faz != "yayin" and ev.faz != "saat" and ev.faz != "cikis":
		await process_frame
		if Time.get_ticks_msec() - bekleme > 120000:
			_hata("evde ilerlenemedi: faz=" + str(ev.faz) + " eşyalar=" + str(ev._esyalar.keys()))
			return
		if ev.faz == "tel_kaydir":
			await _sn(1.0)
			for i in 5:
				var w := InputEventMouseButton.new(); w.button_index = MOUSE_BUTTON_WHEEL_DOWN; w.pressed = true
				Input.parse_input_event(w)
				await _sn(0.7)
			var b2 := Time.get_ticks_msec()
			while not ev.tel_bildirim.visible and Time.get_ticks_msec() - b2 < 20000: await process_frame
			if not ev.tel_bildirim.visible: _hata("bildirim gelmedi")
			await _sn(1.0)
			await _tus(KEY_Q)
			await _sn(0.5)
			if ev.faz == "tel_kaydir": _hata("Q telefonu bırakmadı")
			continue
		if ev.faz != "oyun": continue
		# yeni bir odaya geçildiyse odayı gez, boşluğa çıkılıyor mu bak
		var oda := _oda(ev)
		if not gezildi.has(oda):
			gezildi[oda] = true
			await _gez(ev, oda)
		var hedef := ""
		for ad in sira:
			if ev._esyalar.has(ad): hedef = ad; break
		if hedef == "":
			if ev._esyalar.size() > 0: hedef = ev._esyalar.keys()[0]
			else: continue
		if hedef.ends_with("_kapi"): _son_kapi = ev._esyalar[hedef][0]
		var ok: bool = await _git_bak_bas(ev, hedef)
		if not ok and _son_kapi != Vector3.INF:
			# oyuncu gibi önce kapıdan geçer, sonra yeniden dener
			print("kapıdan geçip yeniden deniyor")
			# önce kapı hizasına (yalnız z), sonra kapıdan x yönünde 1.2 m içeri
			var kz := Vector3(ev.oyuncu.global_position.x, 0, _son_kapi.z)
			await _ev_yuru(ev, kz)
			var hx: float = ev._esyalar[hedef][0].x
			await _ev_yuru(ev, Vector3(_son_kapi.x + signf(hx - _son_kapi.x) * 1.2, 0, _son_kapi.z))
			ok = await _git_bak_bas(ev, hedef)
		if ok: bekleme = Time.get_ticks_msec()
		else:
			_hata("'" + hedef + "' seçilemedi; oyuncu=" + str(ev.oyuncu.global_position))
			return
	print("salon sinematiği başladı: ", ev.faz)
	b = Time.get_ticks_msec()
	while is_instance_valid(ev) and current_scene == ev:
		await process_frame
		if Time.get_ticks_msec() - b > 200000: _hata("salon/çıkış bitmedi faz=" + str(ev.faz)); return
	print("ev bitti (", (Time.get_ticks_msec() - b) / 1000.0, " sn)")


func _oda(ev: Node) -> String:
	var p: Vector3 = ev.oyuncu.global_position
	if p.x < 5.0: return "yatak"
	if p.x < 15.0: return "banyo"
	if p.x < 31.0: return "mutfak"
	return "salon"


## Odanın ortasından sekiz yöne yürür; ayağının altında zemin yoksa ya da alanın dışına çıktıysa yazar.
func _gez(ev: Node, oda: String) -> void:
	var bas: Vector3 = ev.oyuncu.global_position
	var yaw_bas: float = ev._yaw
	for i in 8:
		var aci := i * TAU / 8.0
		ev.oyuncu.global_position = bas
		ev._yaw = aci
		Input.action_press("ileri")
		var b := Time.get_ticks_msec()
		var bosluk := false
		while Time.get_ticks_msec() - b < 2500:
			await physics_frame
			if not _zemin_var(ev.oyuncu as Node3D): bosluk = true
		Input.action_release("ileri")
		await process_frame
		if bosluk: _hata(oda + " odasında boşluğa çıkıldı: yön " + str(i) + " konum " + str(ev.oyuncu.global_position))
	ev.oyuncu.global_position = bas
	ev._yaw = yaw_bas
	await process_frame
	print("gezildi: ", oda)


func _zemin_var(o: Node3D) -> bool:
	var q := PhysicsRayQueryParameters3D.create(o.global_position + Vector3(0, 1.0, 0), o.global_position + Vector3(0, -1.0, 0))
	q.exclude = [(o as CollisionObject3D).get_rid()]
	return not o.get_world_3d().direct_space_state.intersect_ray(q).is_empty()


## Eşyaya doğru yürür, ona bakar; E yazısı o eşya için çıkınca E'ye basar.
func _git_bak_bas(ev: Node, ad: String) -> bool:
	var hedef: Vector3 = ev._esyalar[ad][0]
	var menzil: float = ev._esyalar[ad][1]
	var b := Time.get_ticks_msec()
	var son := Vector3.INF
	var takili := 0.0
	while true:
		if not ev._esyalar.has(ad) or ev.faz != "oyun": return true
		var p: Vector3 = ev.oyuncu.global_position
		var yatay := Vector2(hedef.x - p.x, hedef.z - p.z)
		_bak(ev, hedef)
		await process_frame
		if ev._secili == ad and (yatay.length() < menzil * 0.8 or takili > 1.0):
			Input.action_release("ileri")
			await _tus(KEY_E)
			await _sn(0.3)
			print("E: ", ad, " -> faz=", ev.faz)
			return true
		if yatay.length() > 0.55:
			Input.action_press("ileri")
		else:
			Input.action_release("ileri")
		if p.distance_to(son) < 0.002: takili += 1.0 / 60.0
		else: takili = 0.0
		son = p
		if takili > 3.0 or Time.get_ticks_msec() - b > 25000:
			Input.action_release("ileri")
			print("takıldı: ", ad, " oyuncu=", p, " hedef=", hedef, " seçili=", ev._secili)
			return false
	return false


func _ev_yuru(ev: Node, h: Vector3) -> void:
	var b := Time.get_ticks_msec()
	while Vector2(h.x - ev.oyuncu.global_position.x, h.z - ev.oyuncu.global_position.z).length() > 0.3 and Time.get_ticks_msec() - b < 6000:
		_bak(ev, Vector3(h.x, ev.kamera.global_position.y, h.z))
		Input.action_press("ileri")
		await physics_frame
	Input.action_release("ileri")


func _bak(ev: Node, h: Vector3) -> void:
	var goz: Vector3 = ev.kamera.global_position
	var d := (h - goz).normalized()
	ev._yaw = atan2(-d.x, -d.z)
	ev._pitch = asin(clampf(d.y, -1.0, 1.0))


# ---------------------------------------------------------------- sokak
func _sokak_oyna(s: Node) -> void:
	var o: CharacterBody3D = s.oyuncu
	await _sn(1.0)
	# arabaya yürü
	var kol: Vector3 = s.araba.global_transform * Vector3(-1.06, 0.95, -0.05)
	# sürücü kapısı arabanın öbür yanında: oyuncu gibi arabanın arkasından dolaşır
	for yer in [Vector3(1.6, 0, 3.2), Vector3(-1.9, 0, 3.2), Vector3(-1.9, 0, 0.3)]:
		var h: Vector3 = s.araba.global_transform * yer
		var b0 := Time.get_ticks_msec()
		while Vector2(h.x - o.global_position.x, h.z - o.global_position.z).length() > 0.4 and Time.get_ticks_msec() - b0 < 8000:
			o.global_rotation.y = atan2(-(h.x - o.global_position.x), -(h.z - o.global_position.z))
			Input.action_press("ileri")
			await physics_frame
		Input.action_release("ileri")
	var b := Time.get_ticks_msec()
	while s.durum == "yuruyus":
		var d := kol - o.global_position
		o.global_rotation.y = atan2(-d.x, -d.z)
		var kam: Camera3D = s.oyuncu_kamera
		var kd := (kol - kam.global_position).normalized()
		(o.get_node("Kafa") as Node3D).rotation.x = asin(kd.y)
		if Vector2(d.x, d.z).length() > 1.3: Input.action_press("ileri")
		else: Input.action_release("ileri")
		await process_frame
		if s.e_yazi.visible and s.e_yazi.get_meta("ad", "") == "araba":
			Input.action_release("ileri")
			Input.action_press("etkiles"); await process_frame; await process_frame; Input.action_release("etkiles")
			await _sn(0.5)
		if Time.get_ticks_msec() - b > 40000: _hata("arabaya binilemedi, oyuncu=" + str(o.global_position) + " kapı=" + str(kol)); return
	print("arabaya binildi (", (Time.get_ticks_msec() - b) / 1000.0, " sn)")
	while s.durum != "surus": await process_frame
	# kısa sürüş, sonra kulübenin önüne (yol bulma yok, ışınla)
	Input.action_press("ileri"); await _sn(3.0); Input.action_release("ileri")
	print("sürüş hızı: ", s.araba.hiz)
	if absf(s.araba.hiz) < 1.0: _hata("araba gitmiyor")
	await _sn(2.0)
	s.araba.global_position = s.KULUBE_PARK + Vector3(0, 0.5, 0); s.araba.hiz = 0.0
	await _sn(1.0)
	Input.action_press("etkiles"); await process_frame; await process_frame; Input.action_release("etkiles")
	b = Time.get_ticks_msec()
	while s.durum != "kulube":
		await process_frame
		if Time.get_ticks_msec() - b > 20000: _hata("arabadan inilemedi durum=" + str(s.durum)); return
	print("indi, oyuncu=", o.global_position)
	await _sn(0.5)
	# kulübenin kapısına yürü, içeri gir
	var kapi_ici: Vector3 = s._k(Vector3(-0.2, 0.3, -1.3))
	if not await _yuru(s, o, kapi_ici, 30.0): _hata("kulübeye girilemedi, oyuncu=" + str(o.global_position) + " hedef=" + str(kapi_ici)); return
	print("kulübede, adım=", s._adim)
	# yaka kamerası, otur
	for adim in [[1, s._k(s.BODYCAM_YERI)], [3, s._k(s.OTURAK) + Vector3(0, 0.6, 0)]]:
		b = Time.get_ticks_msec()
		while s._adim < adim[0]:
			await process_frame
			if Time.get_ticks_msec() - b > 15000: _hata("kulübe adımı " + str(adim[0]) + " gelmedi, adım=" + str(s._adim)); return
		b = Time.get_ticks_msec()
		while s._adim == adim[0]:
			var hedef: Vector3 = adim[1]
			if Vector2(hedef.x - o.global_position.x, hedef.z - o.global_position.z).length() > 1.0:
				await _yuru(s, o, Vector3(hedef.x, o.global_position.y, hedef.z), 5.0, 0.9)
			_bak_sokak(s, hedef)
			await process_frame
			if s.e_yazi.visible:
				Input.action_press("etkiles"); await process_frame; await process_frame; Input.action_release("etkiles")
			await _sn(0.2)
			if Time.get_ticks_msec() - b > 20000: _hata("kulübede '" + str(adim[0]) + "' adımında E çıkmadı, oyuncu=" + str(o.global_position) + " e=" + str(s.e_yazi.visible)); return
		print("kulübe adımı geçti: ", adim[0], " -> ", s._adim)
	b = Time.get_ticks_msec()
	while s._adim < 5:
		await process_frame
		if Time.get_ticks_msec() - b > 60000: _hata("telefon çalmadı"); return
	print("telefon çalıyor (", (Time.get_ticks_msec() - b) / 1000.0, " sn bekleme)")
	await _sn(0.5)
	b = Time.get_ticks_msec()
	while s.durum == "kulube":
		_bak_sokak(s, s._telefon.global_position)
		Input.action_press("etkiles"); await process_frame; await process_frame; Input.action_release("etkiles")
		await _sn(0.3)
		if Time.get_ticks_msec() - b > 15000: _hata("telefon açılamadı e=" + str(s.e_yazi.visible)); return
	b = Time.get_ticks_msec()
	while s.durum == "konusma":
		await process_frame
		if Time.get_ticks_msec() - b > 120000: _hata("konuşma bitmedi"); return
	print("konuşma bitti (", (Time.get_ticks_msec() - b) / 1000.0, " sn), durum=", s.durum)
	if s.ipucu.text != "Mazgalı kontrol et": _hata("görev yazısı yok: '" + s.ipucu.text + "'")
	# masadan feneri ve pili al (oyun durmamalı), sonra F ile feneri yak
	await _yuru(s, o, s._k(Vector3(0.1, 0, -0.55)), 6.0, 0.3)
	for ad in ["fener", "pil"]:
		var m: Node3D = s._fener_m if ad == "fener" else s._pil_m
		if m == null: _hata(ad + " modeli yok"); continue
		b = Time.get_ticks_msec()
		while not s._alim.has(ad):
			_bak_sokak(s, m.global_position)
			await process_frame
			if s.e_yazi.visible and s.e_yazi.get_meta("ad", "") == ad:
				Input.action_press("etkiles"); await process_frame; await process_frame; Input.action_release("etkiles")
			if Time.get_ticks_msec() - b > 8000: _hata(ad + " alınamadı e=" + s.e_yazi.text); break
		if o.is_physics_processing() == false: _hata(ad + " alınırken oyuncu dondu")
		print("alındı: ", ad)
		await _sn(1.2)
	if not o.fener_izin: _hata("pil takılınca F açılmadı")
	await _tus(KEY_F)
	await _sn(0.3)
	print("fener yandı mı=", (o.get_node("Kafa/Kamera/Fener") as SpotLight3D).visible)
	# kulübe kapısından dışarı, sonra mazgala yürü
	for yer in [Vector3(-0.6, 0, -1.5), Vector3(-0.6, 0, -2.9)]:
		await _yuru(s, o, s._k(yer), 6.0, 0.3)
	var sonmeden := _yanan(s)
	if not await _yuru(s, o, s.MAZGAL, 90.0, 1.8): _hata("mazgala varılamadı, oyuncu=" + str(o.global_position) + " mazgal=" + str(s.MAZGAL)); return
	await _sn(4.0)
	var sonra := _yanan(s)
	print("yanan lamba: ", sonmeden, " -> ", sonra)
	if sonra >= sonmeden: _hata("lambalar sönmedi")
	# mazgala bak, E
	b = Time.get_ticks_msec()
	while s.durum == "mazgala":
		_bak_sokak(s, s.MAZGAL)
		await process_frame
		if s.e_yazi.visible and s.e_yazi.get_meta("ad", "") == "mazgal":
			Input.action_press("etkiles"); await process_frame; await process_frame; Input.action_release("etkiles")
		if Time.get_ticks_msec() - b > 8000: _hata("mazgalda E çıkmadı e=" + s.e_yazi.text + " uzaklık=" + str(o.global_position.distance_to(s.MAZGAL))); return
	print("mazgala bakıldı, durum=", s.durum, " yazı='", s.ipucu.text, "'")
	b = Time.get_ticks_msec()
	while current_scene == s:
		await process_frame
		if Time.get_ticks_msec() - b > 60000: _hata("düşüş/karanlık bitmedi durum=" + str(s.durum)); return
	await process_frame
	print("düşüşten sonra sahne: ", current_scene.scene_file_path if current_scene else "yok")


func _yanan(s: Node) -> int:
	var n := 0
	for l in s.get_node("Lambalar").get_children():
		if l is SpotLight3D and l.visible: n += 1
	return n


func _bak_sokak(s: Node, h: Vector3) -> void:
	var o: Node3D = s.oyuncu
	var kam: Camera3D = s.oyuncu_kamera
	var d := h - kam.global_position
	o.global_rotation.y = atan2(-d.x, -d.z)
	(o.get_node("Kafa") as Node3D).rotation.x = asin(clampf(d.normalized().y, -1.0, 1.0))


func _yuru(s: Node, o: CharacterBody3D, hedef: Vector3, sure: float, yakin := 0.4) -> bool:
	var b := Time.get_ticks_msec()
	var son := o.global_position
	var takili := 0.0
	while Vector2(hedef.x - o.global_position.x, hedef.z - o.global_position.z).length() > yakin:
		if s.durum != "kulube" and s.durum != "mazgala" and s.durum != "yuruyus":
			Input.action_release("ileri"); return true
		var d := hedef - o.global_position
		o.global_rotation.y = atan2(-d.x, -d.z)
		(o.get_node("Kafa") as Node3D).rotation.x = 0.0
		Input.action_press("ileri")
		await physics_frame
		if o.global_position.distance_to(son) < 0.001: takili += 1.0 / 60.0
		else: takili = 0.0
		son = o.global_position
		if takili > 3.0 or Time.get_ticks_msec() - b > sure * 1000.0:
			Input.action_release("ileri")
			print("yürürken takıldı: ", o.global_position, " hedef ", hedef)
			return false
	Input.action_release("ileri")
	return true


# ---------------------------------------------------------------- devam et
func _devam_testi(d: Node) -> void:
	print("kayıt var mı=", d.kayit_var())
	var menu: Node = (load("res://sahneler/baslangic.tscn") as PackedScene).instantiate()
	root.add_child(menu)
	current_scene = menu
	while menu.durum != "bekle" and menu.durum != "menu": await process_frame
	_tus(KEY_SPACE)
	await _sn(1.0)
	print("devam düğmesi=", _dugme_var(menu, "DEVAM ET"))
	menu._devam_et()
	var b := Time.get_ticks_msec()
	while current_scene == menu or current_scene == null:
		await process_frame
		if Time.get_ticks_msec() - b > 300000: _hata("devam sahnesi açılmadı"); return
	for i in 10: await process_frame
	var s := current_scene
	print("devam sahnesi: ", s.scene_file_path, " durum/faz=", s.get("durum"), "/", s.get("faz"))
