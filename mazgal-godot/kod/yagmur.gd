extends GPUParticles3D
## Oyuncunun etrafında yağan yağmur; oyuncuyu takip eder.
@export var hedef: Node3D
func _process(_dt: float) -> void:
	if hedef: global_position = hedef.global_position + Vector3(0, 8, 0)
