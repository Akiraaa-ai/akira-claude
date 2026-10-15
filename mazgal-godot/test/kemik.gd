extends SceneTree
func _init() -> void:
	var s: Node3D = (load(OS.get_cmdline_user_args()[0]) as PackedScene).instantiate()
	root.add_child(s)
	await process_frame
	for sk in s.find_children("*", "Skeleton3D", true, false):
		var k := sk as Skeleton3D
		for i in k.get_bone_count():
			print(i, " ", k.get_bone_name(i), " parent=", k.get_bone_parent(i), " global_rest_origin=", (k.global_transform * k.get_bone_global_rest(i)).origin, " rest_basis=", k.get_bone_rest(i).basis.get_euler())
	for ap in s.find_children("*", "AnimationPlayer", true, false):
		print("anim ", (ap as AnimationPlayer).get_animation_list())
	quit()
