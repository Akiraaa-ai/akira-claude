extends SceneTree
## Test: şehrin kendi rögar kapağından yapılan açık mazgal.
func _init() -> void:
	var s: Node = load("res://sahneler/sokak.tscn").instantiate()
	root.add_child(s)
	current_scene = s
	for _i in 30: await process_frame
	var a := s.get_node_or_null("MazgalAgzi") as Node3D
	print("agiz=", a.global_position if a else null, " aabb=", a.get_aabb() if a else null)
	var k := Camera3D.new()
	s.add_child(k)
	var l := SpotLight3D.new(); l.spot_range = 8; l.light_energy = 3; k.add_child(l)
	for i in 2:
		k.look_at_from_position(s.MAZGAL + ([Vector3(-1.0, 1.55, 1.6), Vector3(-0.3, 1.0, 0.6)][i]), s.MAZGAL, Vector3.UP)
		k.current = true
		for _j in 10: await process_frame
		root.get_texture().get_image().save_jpg("/tmp/claude-0/godot/maz_%d.jpg" % (i + 1), 0.85)
	quit()
