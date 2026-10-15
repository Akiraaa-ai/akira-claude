extends Node3D
## Açılış sokağı: alp'in şehir modeli (orijinal, sıkıştırılmamış), gece, yağmur.

# şehir dosyası bu adlardan biriyle modeller/ klasöründe olabilir
const SEHIR_DOSYALARI := ["res://modeller/sehir.glb", "res://modeller/Terrain Remaked.glb"]

@onready var sehir: Node3D = $Sehir

func _ready() -> void:
	for yol in SEHIR_DOSYALARI:
		if ResourceLoader.exists(yol):
			sehir.add_child((load(yol) as PackedScene).instantiate())
			break
	if sehir.get_child_count() == 0:
		push_error("Şehir modeli bulunamadı: modeller/ klasörüne sehir.glb ya da Terrain Remaked.glb koy")
	# şehirdeki bütün meshler gölge alır ve verir, üstünde yürünebilir
	for m in sehir.find_children("*", "MeshInstance3D", true, false):
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		if m.mesh: m.create_trimesh_collision()
