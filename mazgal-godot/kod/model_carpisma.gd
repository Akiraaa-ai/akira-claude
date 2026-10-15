extends Node3D
## Bu düğümün altındaki bütün modellere gerçek şekilli çarpışma ve gölge ekler (kulübe, araba gibi).
func _ready() -> void:
	for m in find_children("*", "MeshInstance3D", true, false):
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		if m.mesh and not m.get_parent() is CollisionObject3D: m.create_trimesh_collision()
