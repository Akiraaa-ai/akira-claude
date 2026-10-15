extends SceneTree
## Test: bulunan lamba başlarını kırmızı noktayla işaretleyip yakından çeker.
const ISARET := [Vector3(-66.4, 8.5, 26.0), Vector3(-94.3, 8.5, 4.4), Vector3(-102.0, 8.5, 36.2)]
const BAKIS := [["e", Vector3(-60, 2.0, 18), Vector3(-66.4, 7.5, 26.0)], ["f", Vector3(-88, 2.0, 0), Vector3(-94.3, 7.5, 4.4)], ["g", Vector3(-95, 2.0, 30), Vector3(-102.0, 7.5, 36.2)]]
func _init() -> void:
	var s: Node = load("res://sahneler/sokak.tscn").instantiate()
	s.set_meta("arkaplan", true)
	root.add_child(s)
	s.get_node("Selim").process_mode = Node.PROCESS_MODE_DISABLED
	s.get_node("Yagmur").visible = false
	var env: Environment = s.get_node("Ortam").environment
	env.fog_enabled = false; env.volumetric_fog_enabled = false; env.ambient_light_energy = 2.5; env.ambient_light_color = Color(0.7,0.7,0.75)
	var m := StandardMaterial3D.new(); m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; m.albedo_color = Color(1, 0, 0); m.no_depth_test = true
	var k := SphereMesh.new(); k.radius = 0.12; k.height = 0.24; k.material = m
	for p in ISARET:
		var mi := MeshInstance3D.new(); mi.mesh = k; s.add_child(mi); mi.global_position = p
	var cam := Camera3D.new(); s.add_child(cam); cam.current = true; cam.fov = 55
	for _i in 10: await process_frame
	for b in BAKIS:
		cam.global_position = b[1]; cam.look_at(b[2])
		for _i in 12: await process_frame
		root.get_texture().get_image().save_jpg("/tmp/claude-0/godot/lb_%s.jpg" % b[0], 0.85)
	quit()
