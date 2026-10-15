extends SceneTree
## Test: ev.tscn'i betiksiz, aydınlık açar; verilen noktalardan bakış çeker. Argüman: "x,y,z:bx,by,bz" ...
func _init() -> void:
	var ev: Node3D = (load("res://sahneler/ev.tscn") as PackedScene).instantiate()
	ev.set_script(null)
	root.add_child(ev)
	var env := WorldEnvironment.new(); env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR; env.environment.background_color = Color(0.1,0.1,0.3)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.environment.ambient_light_color = Color.WHITE; env.environment.ambient_light_energy = 1.0
	root.add_child(env)
	var cam := Camera3D.new(); root.add_child(cam); cam.current = true; cam.fov = 80; cam.near = 0.03
	var i := 0
	for a in OS.get_cmdline_user_args():
		var p := a.split(":")
		var k := p[0].split_floats(",")
		var b := p[1].split_floats(",")
		cam.look_at_from_position(Vector3(k[0], k[1], k[2]), Vector3(b[0], b[1], b[2]))
		for _k in 10: await process_frame
		root.get_texture().get_image().save_jpg("/tmp/claude-0/godot/goz_%d.jpg" % i, 0.85)
		i += 1
	quit()
