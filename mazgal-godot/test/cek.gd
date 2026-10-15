extends SceneTree
## Test: sokak sahnesini yükler, birkaç açıdan ekran görüntüsü alır.
var ac := [["kulube_dis", Vector3(-60,1.7,-86), Vector3(-52.5,1.2,-82)], ["araba", Vector3(-62,1.8,-73), Vector3(-58,0.8,-78)], ["kulube_ic", Vector3(-53.5,1.65,-81.2), Vector3(-53.4,1.1,-82.9)], ["ust", Vector3(-47,4,-78), Vector3(-53.5,1,-82)]]
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
		root.get_texture().get_image().save_jpg("/tmp/claude-0/godot/g_%s.jpg" % a[0], 0.9)
	quit()
