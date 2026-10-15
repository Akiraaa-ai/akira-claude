extends SceneTree
## Test: evin oynanabilir kısmını otomatik oynar (yürür, bakar, E'ye basar), yer yer kare kaydeder.
## Argüman: "uyanis" verilirse uyanma sinematiğinin karelerini de alır.
var ev: Node
var n := 0

func _init() -> void:
	ev = (load("res://sahneler/ev.tscn") as PackedScene).instantiate()
	root.add_child(ev)
	await process_frame
	var args := OS.get_cmdline_user_args()
	if "uyanis" in args:
		for t in [1.0, 2.6, 5.0, 6.9, 7.6, 12.5, 15.0, 19.0]:
			await _bekle_t(t)
			_kare("uyanis")
		await _bekle_faz("oyun")
	else:
		ev._gec("banyo")
	print("banyo: faz=", ev.faz, " oyuncu=", ev.oyuncu.global_position)
	await _bekle(1.2)
	_kare("banyo_giris")
	# kapı kapalıyken yürü: kapıdan geçememeli
	await _yuru("ileri", 2.0)
	print("kapali kapiya yurudu: ", ev.oyuncu.global_position)
	ev._etkiles("banyo_kapi")
	await _bekle(2.0)
	_kare("banyo_kapi_acik")
	await _yuru("ileri", 1.6)
	print("banyoya girdi: ", ev.oyuncu.global_position)
	_bak(ev.BANYO_LAMBA)
	await _bekle(0.2)
	print("secili (lamba bekleniyor): ", ev._secili)
	_kare("lamba_e")
	ev._etkiles("banyo_isik")
	await _bekle(2.0)
	_kare("lamba_acik")
	_git(Vector3(11.75, 0, -0.5))
	_bak(ev.LAVABO)
	await _bekle(0.2)
	print("secili (lavabo bekleniyor): ", ev._secili)
	ev._etkiles("lavabo")
	for t in [1.5, 3.0, 4.0, 8.0, 10.8]:
		await _bekle_ft(t)
		_kare("lavabo")
	await _bekle_faz("oyun")
	_bak(ev.DUS_KAPI)
	await _bekle(0.2)
	print("secili (dus bekleniyor): ", ev._secili)
	ev._etkiles("dus")
	for t in [2.6, 3.6, 5.0, 8.0, 10.5]:
		await _bekle_ft(t)
		_kare("dus")
	await _bekle_faz("oyun")
	await _bekle(1.0)
	_kare("dus_sonrasi")
	ev._etkiles("banyo_cikis")
	await _bekle_faz("oyun")
	await _bekle(1.0)
	_kare("mutfak_giris")
	ev._etkiles("mutfak_kapi")
	await _bekle(1.5)
	_kare("mutfak_kapi")
	await _yuru("ileri", 2.0)
	print("mutfaga girdi: ", ev.oyuncu.global_position)
	_git(Vector3(25.4, 0, -2.6))
	_bak(ev.DOLAP)
	await _bekle(0.3)
	print("secili (dolap bekleniyor): ", ev._secili)
	_kare("dolap_e")
	ev._etkiles("dolap")
	for t in [1.8, 2.6, 4.0]:
		await _bekle_ft(t)
		_kare("dolap")
	await _bekle_faz("oyun")
	_git(Vector3(27.5, 0, 2.3))
	_bak(Vector3(27.35, 0.85, 1.0))
	await _bekle(0.3)
	print("secili (masa bekleniyor): ", ev._secili)
	ev._etkiles("masa")
	for t in [2.0, 3.2, 4.5, 5.3, 8.0]:
		await _bekle_ft(t)
		_kare("masa")
	await _bekle_faz("oyun")
	_bak(ev.TEL_MASA)
	await _bekle(0.3)
	print("secili (telefon bekleniyor): ", ev._secili)
	_kare("telefon_e")
	ev._etkiles("telefon")
	await _bekle_faz("tel_kaydir")
	await _bekle(0.5)
	_kare("telefon")
	for i in 4:
		ev._kaydir(1)
		await _bekle(0.8)
	_kare("telefon_kaydir")
	await _bekle(1.0)
	print("bildirim: ", ev.tel_bildirim.visible)
	_kare("bildirim")
	ev._gec("s_tel_birak")
	for t in [1.1, 2.5]:
		await _bekle_ft(t)
		_kare("tel_birak")
	await _bekle_faz("oyun")
	await _bekle(1.2)
	_kare("salon_giris")
	ev._etkiles("salon_kapi")
	await _bekle(1.5)
	await _yuru("ileri", 2.2)
	print("salona girdi: ", ev.oyuncu.global_position)
	_bak(ev.KOLTUK + Vector3(0.2, -0.5, 0))
	await _bekle(0.3)
	print("secili (koltuk bekleniyor): ", ev._secili)
	_kare("koltuk_e")
	ev._etkiles("koltuk")
	await _bekle_faz("salon")
	await _bekle(1.5)
	_kare("salon")
	print("bitti T=", ev.T)
	quit()


func _kare(ad: String) -> void:
	n += 1
	root.get_texture().get_image().save_jpg("/tmp/claude-0/godot/oyun_%02d_%s.jpg" % [n, ad], 0.85)
	print("kare ", n, " ", ad, " faz=", ev.faz, " ft=%.2f" % ev.ft, " kam=", ev.kamera.global_position)


func _bekle(sn: float) -> void:
	var bas: float = ev.T
	while ev.T - bas < sn: await process_frame


func _bekle_t(t: float) -> void:
	while ev.ft < t: await process_frame


func _bekle_ft(t: float) -> void:
	var f: String = ev.faz
	while ev.ft < t and ev.faz == f: await process_frame


func _bekle_faz(f: String) -> void:
	var sinir: float = ev.T + 40.0
	while ev.faz != f and ev.T < sinir: await process_frame


func _yuru(eylem: String, sn: float) -> void:
	Input.action_press(eylem)
	await _bekle(sn)
	Input.action_release(eylem)
	await _bekle(0.3)


func _git(p: Vector3) -> void:
	ev.oyuncu.global_position = p


func _bak(hedef: Vector3) -> void:
	var goz: Vector3 = ev.oyuncu.global_position + Vector3(0, ev.GOZ, 0)
	if ev._oturuyor: goz = ev._otur_konum
	var d := (hedef - goz).normalized()
	ev._yaw = atan2(-d.x, -d.z)
	ev._pitch = asin(d.y)
