extends SceneTree
## Test: oyuncu şehrin dışına/boşluğa konursa düşmüyor mu.
func _init() -> void:
	var s: Node = load("res://sahneler/sokak.tscn").instantiate()
	root.add_child(s)
	var o: CharacterBody3D = s.get_node("Selim")
	for _i in 60: await physics_frame
	o.global_position = Vector3(300, 2, 300)
	for _i in 120: await physics_frame
	print("disarida y=", o.global_position.y, " yerde=", o.is_on_floor())
	quit()
