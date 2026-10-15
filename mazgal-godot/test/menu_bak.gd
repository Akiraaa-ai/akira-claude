extends SceneTree
## Test: ESC menüsü (bulanık arka plan), ayarlar paneli, İngilizce dil ve ses kanalları.
func _init() -> void:
	var ev: Node = (load("res://sahneler/ev.tscn") as PackedScene).instantiate()
	root.add_child(ev)
	current_scene = ev
	await process_frame
	var d: Node = root.get_node("Duraklat")
	for n in ev.find_children("*", "AudioStreamPlayer", true, false): d._oynaticilar.append(n)
	ev._gec("banyo")
	for i in 40: await process_frame
	var bas := Time.get_ticks_msec()
	while Time.get_ticks_msec() - bas < 800: await process_frame
	d.duraklat()
	for i in 5: await process_frame
	root.get_texture().get_image().save_jpg("/tmp/claude-0/godot/menu_1.jpg", 0.85)
	d._ana.visible = false; d._ayar.visible = true
	for i in 5: await process_frame
	root.get_texture().get_image().save_jpg("/tmp/claude-0/godot/menu_2.jpg", 0.85)
	d.dil = "en"; d._uygula()
	for i in 5: await process_frame
	root.get_texture().get_image().save_jpg("/tmp/claude-0/godot/menu_3.jpg", 0.85)
	d.devam()
	for i in 10: await process_frame
	root.get_texture().get_image().save_jpg("/tmp/claude-0/godot/menu_4.jpg", 0.85)
	var say := {}
	for n in ev.find_children("*", "AudioStreamPlayer", true, false):
		var b: String = (n as AudioStreamPlayer).bus
		say[b] = say.get(b, 0) + 1
	print("oynatici ", d._oynaticilar.size(), " buslar ", AudioServer.bus_count)
	print("kanallar ", say, " anlatici=", ev.ses_anlatici.bus, " muzik=", ev.ses_muzik.bus)
	d.dil = "tr"; d._kaydet()
	quit()
