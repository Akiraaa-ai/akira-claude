extends Node3D
## Açılış sokağı: alp'in şehir modeli (orijinal, sıkıştırılmamış), gece, yağmur.

@onready var sehir: Node3D = $Sehir

func _ready() -> void:
	# şehirdeki bütün meshler gölge alır ve verir
	for m in sehir.find_children("*", "MeshInstance3D", true, false):
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		_carpisma_ekle(m)

# yürünebilsin diye her mesh'e tam şekilli çarpışma eklenir
func _carpisma_ekle(m: MeshInstance3D) -> void:
	if m.mesh == null: return
	m.create_trimesh_collision()
