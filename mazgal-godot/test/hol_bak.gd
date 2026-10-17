extends SceneTree
## Test: küçük hol, karanlığa açılan kapılar ve odalara geçiş.
var ev: Node

func _bekle(sn: float) -> void:
	var bas: float = ev.T
	while ev.T - bas < sn: await process_frame

func _kare(ad: String) -> void:
	root.get_texture().get_image().save_jpg("/tmp/claude-0/godot/hol_%s.jpg" % ad, 0.85)
	print(ad, " faz=", ev.faz, " ft=", snapped(ev.ft, 0.1), " oyuncu=", ev.oyuncu.global_position, " kar=", snapped(ev.karartma, 0.01))

func _init() -> void:
	ev = (load("res://sahneler/ev.tscn") as PackedScene).instantiate()
	root.add_child(ev)
	await process_frame
	ev._oyuncu_yerlestir(Vector3(4.1, 0, 1.7), -PI * 0.5, ev.HOL_ALAN)
	ev._hol_basla("banyo")
	for y in [["banyo", -PI * 0.5], ["mutfak", 0.0], ["salon", PI], ["yatak", PI * 0.5]]:
		ev._yaw = y[1]; ev._pitch = -0.05
		await _bekle(0.6)
		_kare("yon_" + y[0])
	ev._etkiles("hol_banyo")
	while ev.faz == "gecis" and ev.ft < 2.6: await process_frame
	_kare("banyo_kapi_acik")
	while ev.faz == "gecis": await process_frame
	await _bekle(1.5)
	_kare("banyo_ici")
	# banyodan çıkış
	ev._etkiles("banyo_cikis")
	while ev.faz == "gecis" and ev.ft < 2.6: await process_frame
	_kare("banyo_cikis_kapi")
	while ev.faz == "gecis": await process_frame
	await _bekle(1.5)
	_kare("hole_donus")
	ev._etkiles("hol_mutfak")
	while ev.faz == "gecis": await process_frame
	await _bekle(1.5)
	_kare("mutfak_ici")
	ev._yaw = -PI * 0.5
	await _bekle(0.5)
	_kare("mutfak_kapiya_bak")
	quit()
