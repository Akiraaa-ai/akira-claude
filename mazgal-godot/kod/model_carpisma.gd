extends Node3D
## Bu düğümün altındaki bütün modellere gerçek şekilli çarpışma ve gölge ekler (kulübe, araba gibi).
## Adında "Glass" geçen malzemeler saydam, hafif yansıtan cama çevrilir.

static var _cam: StandardMaterial3D

func _ready() -> void:
	for m in find_children("*", "MeshInstance3D", true, false):
		var mi := m as MeshInstance3D
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		if mi.mesh == null: continue
		var cam_var := false
		for i in mi.mesh.get_surface_count():
			var mat := mi.mesh.surface_get_material(i)
			if mat and "glass" in mat.resource_name.to_lower():
				mi.set_surface_override_material(i, _cam_malzemesi()); cam_var = true
		if cam_var: mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if not mi.get_parent() is CollisionObject3D: mi.create_trimesh_collision()

static func _cam_malzemesi() -> StandardMaterial3D:
	if _cam == null:
		_cam = StandardMaterial3D.new()
		_cam.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_cam.albedo_color = Color(0.55, 0.62, 0.65, 0.18)
		_cam.metallic = 0.2
		_cam.roughness = 0.05
		_cam.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
	return _cam
