extends SceneTree
## Test: sokak sahnesini yükler, birkaç açıdan ekran görüntüsü alır.
var ac := [["lamba_ara", Vector3(-60,1.7,-45), Vector3(-63,2.5,-20)], ["lamba_cadde", Vector3(-35,1.7,-9), Vector3(-70,3,-5)], ["lamba_kulube", Vector3(-58,1.7,-70), Vector3(-62,3,-50)], ["lamba_ust", Vector3(-40,18,-60), Vector3(-62,0,-30)]]
func _init() -> void:
	var s: Node = load("res://sahneler/sokak.tscn").instantiate()
	root.add_child(s)
	var o: Node3D = s.get_node("Selim")
	o.set_physics_process(false); o.set_process_unhandled_input(false)
	for _i in 30: await process_frame
	var cam: Camera3D = o.get_node("Kafa/Kamera")
	for a in ac:
		o.global_position = a[1] - Vector3(0,1.65,0)
		cam.look_at(a[2])
		for _i in 20: await process_frame
		root.get_texture().get_image().save_jpg("/tmp/claude-0/godot/l_%s.jpg" % a[0], 0.9)
	quit()
