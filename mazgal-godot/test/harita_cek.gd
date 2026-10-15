extends SceneTree
## Test: şehri tepeden ortografik çeker (yol haritası). Argüman: merkez_x merkez_z boyut dosya
func _init() -> void:
	var a := OS.get_cmdline_user_args()
	var s: Node3D = load("res://sahneler/sokak.tscn").instantiate()
	root.add_child(s)
	var o: Node3D = s.get_node("Selim"); o.set_physics_process(false); o.set_process_unhandled_input(false)
	s.get_node("Yagmur").visible = false
	var env: Environment = s.get_node("Ortam").environment
	env.fog_enabled = false; env.volumetric_fog_enabled = false
	env.ambient_light_energy = 1.5; env.ambient_light_color = Color(1,1,1)
	var ay: DirectionalLight3D = s.get_node("Ay"); ay.light_energy = 1.2; ay.shadow_enabled = false
	for _i in 10: await process_frame
	var b := AABB(); var ilk := true
	for m in s.get_node("Sehir").find_children("*", "MeshInstance3D", true, false):
		var bb: AABB = (m as MeshInstance3D).global_transform * (m as MeshInstance3D).get_aabb()
		if ilk: b = bb; ilk = false
		else: b = b.merge(bb)
	print("SEHIR AABB ", b)
	var cam := Camera3D.new(); s.add_child(cam)
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	var cx := float(a[0]); var cz := float(a[1]); var boy := float(a[2])
	cam.size = boy; cam.far = 500
	cam.global_transform = Transform3D(Basis.from_euler(Vector3(-PI/2, 0, 0)), Vector3(cx, 150, cz))
	cam.current = true
	for _i in 20: await process_frame
	root.get_texture().get_image().save_jpg("/tmp/claude-0/godot/%s.jpg" % a[3], 0.9)
	quit()
