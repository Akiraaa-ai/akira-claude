extends SceneTree
## Test: elleri kameranın önünde birkaç hedefe uzatıp çeker.
func _init() -> void:
	var env := WorldEnvironment.new(); env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR; env.environment.background_color = Color(0.3,0.3,0.35)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.environment.ambient_light_color = Color.WHITE; env.environment.ambient_light_energy = 0.8
	root.add_child(env)
	var isik := DirectionalLight3D.new(); root.add_child(isik); isik.rotation_degrees = Vector3(-40, 30, 0)
	var cam := Camera3D.new(); root.add_child(cam); cam.current = true; cam.fov = 70; cam.position = Vector3(0, 1.6, 0)
	var e: Node3D = (load("res://kod/eller.gd") as GDScript).new()
	cam.add_child(e)
	await process_frame
	print("boy ", e._boy)
	var hedefler := [["sag", Vector3(0.25, 1.2, -0.5)], ["sol", Vector3(-0.2, 1.45, -0.45)], ["sag", Vector3(0.05, 1.5, -0.35)]]
	var i := 0
	for h in hedefler:
		e.uzan(h[0], h[1], 0.3)
		if i == 2: e.yumruk("sag", 1.0)
		for _k in 40: await process_frame
		var sk: Skeleton3D = e.find_child("Skeleton3D", true, false)
		print(i, " vis=", e.visible, " hedef=", h[1], " elR=", (sk.global_transform * sk.get_bone_global_pose(sk.find_bone("hand.R"))).origin, " elL=", (sk.global_transform * sk.get_bone_global_pose(sk.find_bone("hand.L"))).origin, " omuzL=", (sk.global_transform * sk.get_bone_global_pose(sk.find_bone("upper_arm.L"))).origin, " omuz=", (sk.global_transform * sk.get_bone_global_pose(sk.find_bone("upper_arm.R"))).origin)
		var mi: MeshInstance3D = e.find_children("*", "MeshInstance3D", true, false)[0]
		print(" mesh aabb ", mi.global_transform * mi.get_aabb(), " skin ", mi.skin != null)
		root.get_texture().get_image().save_jpg("/tmp/claude-0/godot/el_%d.jpg" % i, 0.85)
		i += 1
	quit()
