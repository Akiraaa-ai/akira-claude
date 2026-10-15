extends SceneTree
## Test: sokak sahnesini yükler, birkaç açıdan ekran görüntüsü alır.
var ac := [["kulube", Vector3(-60,1.7,-6), Vector3(-60,1.5,-40)], ["kavsak", Vector3(-45,1.7,1.5), Vector3(-62,1.5,-10)], ["mazgal", Vector3(6,1.7,5), Vector3(0,0.4,0)], ["cadde", Vector3(-30,1.7,1.5), Vector3(20,2,0)]]
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
