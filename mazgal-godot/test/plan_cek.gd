extends SceneTree
## Test: ev odalarını tepeden (ortografik, tavansız) çeker. 1 piksel = 1 cm, resmin ortası odanın merkezi.
func _init() -> void:
	var ev: Node3D = (load("res://sahneler/ev.tscn") as PackedScene).instantiate()
	ev.set_script(null)
	root.add_child(ev)
	var env := WorldEnvironment.new(); env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR; env.environment.background_color = Color(0.1,0.1,0.3)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.environment.ambient_light_color = Color.WHITE; env.environment.ambient_light_energy = 1.2
	root.add_child(env)
	var cam := Camera3D.new(); root.add_child(cam); cam.current = true
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL; cam.size = 8.0; cam.near = 0.5; cam.far = 10
	for oda in [["yatak", Vector3(0.4,0,0.5)], ["banyo", Vector3(12,0,-0.6)], ["mutfak", Vector3(25.85,0,-0.25)], ["salon", Vector3(36,0,0)]]:
		cam.position = (oda[1] as Vector3) + Vector3(0, 2.6, 0)
		cam.rotation = Vector3(-PI/2, 0, 0)
		for _k in 12: await process_frame
		root.get_texture().get_image().save_jpg("/tmp/claude-0/godot/plan_%s.jpg" % oda[0], 0.85)
	quit()
