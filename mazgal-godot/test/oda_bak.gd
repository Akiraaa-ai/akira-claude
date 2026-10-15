extends SceneTree
## Test: bir modeli boş, aydınlık sahnede dört açıdan çeker. Argümanlar: yol ölçek ad
func _init() -> void:
	var a := OS.get_cmdline_user_args()
	var s: Node3D = (load(a[0]) as PackedScene).instantiate(); s.scale = Vector3.ONE * float(a[1]); root.add_child(s)
	var env := WorldEnvironment.new(); env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR; env.environment.background_color = Color(0.2,0.2,0.25)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.environment.ambient_light_color = Color.WHITE; env.environment.ambient_light_energy = 1.0
	root.add_child(env)
	var cam := Camera3D.new(); root.add_child(cam); cam.current = true; cam.fov = 75
	await process_frame
	var b := AABB(); var ilk := true
	for m in s.find_children("*", "MeshInstance3D", true, false):
		var bb: AABB = (m as MeshInstance3D).global_transform * (m as MeshInstance3D).get_aabb()
		if ilk: b = bb; ilk = false
		else: b = b.merge(bb)
	var c := b.get_center(); var r := b.size.length() * 0.55
	var i := 0
	for yon in [Vector3(1,1.2,1), Vector3(-1,1.2,-1), Vector3(0,3,0.01), Vector3(0.2, 0.05, 0.2)]:
		if i == 3: cam.position = c + Vector3(0, -b.size.y*0.15, 0); cam.look_at(c + Vector3(1, -b.size.y*0.15, 0.3))
		else: cam.position = c + (yon as Vector3).normalized() * r; cam.look_at(c)
		for _k in 15: await process_frame
		root.get_texture().get_image().save_jpg("/tmp/claude-0/godot/oda_%s_%d.jpg" % [a[2], i], 0.85)
		i += 1
	quit()
