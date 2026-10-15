extends SceneTree
## Test: modelin içinden, göz hizasından dört yöne bakar. Argümanlar: yol ölçek ad [gizlenecek düğüm]
func _init() -> void:
	var a := OS.get_cmdline_user_args()
	var s: Node3D = (load(a[0]) as PackedScene).instantiate(); s.scale = Vector3.ONE * float(a[1]); root.add_child(s)
	if a.size() > 3:
		for n in s.find_children(a[3], "Node3D", true, false): (n as Node3D).visible = false
	var env := WorldEnvironment.new(); env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR; env.environment.background_color = Color(0.2,0.2,0.25)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.environment.ambient_light_color = Color.WHITE; env.environment.ambient_light_energy = 1.0
	root.add_child(env)
	var cam := Camera3D.new(); root.add_child(cam); cam.current = true; cam.fov = 90
	await process_frame
	var b := AABB(); var ilk := true
	for m in s.find_children("*", "MeshInstance3D", true, false):
		var mi := m as MeshInstance3D
		if not mi.is_visible_in_tree(): continue
		var bb: AABB = mi.global_transform * mi.get_aabb()
		if ilk: b = bb; ilk = false
		else: b = b.merge(bb)
	print(a[2], " boyut=", b.size, " min=", b.position)
	var c := b.get_center(); c.y = b.position.y + 1.6
	var i := 0
	for yon in [Vector3(1,0,0), Vector3(0,0,1), Vector3(-1,0,0), Vector3(0,0,-1)]:
		cam.position = c; cam.look_at(c + (yon as Vector3) + Vector3(0,-0.25,0))
		for _k in 15: await process_frame
		root.get_texture().get_image().save_jpg("/tmp/claude-0/godot/ic_%s_%d.jpg" % [a[2], i], 0.8)
		i += 1
	quit()
