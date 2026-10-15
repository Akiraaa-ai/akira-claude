extends SceneTree
## Test: oyuncu yere oturuyor mu, ileri yürüyebiliyor mu.
func _init() -> void:
	var s: Node = load("res://sahneler/sokak.tscn").instantiate()
	root.add_child(s)
	var o: CharacterBody3D = s.get_node("Selim")
	for _i in 120: await physics_frame
	print("dusus sonrasi y=", o.global_position.y, " yerde=", o.is_on_floor())
	Input.action_press("ileri")
	for _i in 180: await physics_frame
	print("3 sn yurudu: ", o.global_position, " yerde=", o.is_on_floor())
	quit()
