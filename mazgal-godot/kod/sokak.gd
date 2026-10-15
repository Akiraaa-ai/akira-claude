@tool
extends Node3D
## Açılış sokağı: alp'in şehir modeli (orijinal, sıkıştırılmamış), gece, yağmur.

# şehir dosyası bu adlardan biriyle modeller/ klasöründe olabilir
const SEHIR_DOSYALARI := ["res://modeller/sehir.glb", "res://modeller/Terrain Remaked.glb", "res://dokular/source/Terrain Remaked.glb", "res://dokular/source/sehir.glb"]

@onready var sehir: Node3D = $Sehir

func _ready() -> void:
	for yol in SEHIR_DOSYALARI:
		if ResourceLoader.exists(yol):
			sehir.add_child((load(yol) as PackedScene).instantiate())
			break
	if sehir.get_child_count() == 0:
		push_error("Şehir modeli bulunamadı: modeller/ klasörüne sehir.glb ya da Terrain Remaked.glb koy")
	_arabalari_kaldir()
	# şehirdeki bütün meshler gölge alır ve verir, üstünde yürünebilir
	for m in sehir.find_children("*", "MeshInstance3D", true, false):
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		if m.mesh and not Engine.is_editor_hint(): m.create_trimesh_collision()
	if not Engine.is_editor_hint(): _guvenlik_zemini()

# şehir modelindeki park halindeki arabalar (tekerlek ve kasa yüzeyleri) çıkarılır; yerine alp'in arabası gelir
const ARABA_MALZEMELERI := ["WheelTex", "CarTex_1"]
func _arabalari_kaldir() -> void:
	for m in sehir.find_children("*", "MeshInstance3D", true, false):
		var eski := (m as MeshInstance3D).mesh as ArrayMesh
		if eski == null: continue
		var kalan := []
		for i in eski.get_surface_count():
			var mat := eski.surface_get_material(i)
			if mat and mat.resource_name in ARABA_MALZEMELERI: continue
			kalan.append(i)
		if kalan.size() == eski.get_surface_count(): continue
		var yeni := ArrayMesh.new()
		for i in kalan:
			yeni.add_surface_from_arrays(eski.surface_get_primitive_type(i), eski.surface_get_arrays(i))
			yeni.surface_set_material(yeni.get_surface_count() - 1, eski.surface_get_material(i))
		(m as MeshInstance3D).mesh = yeni

# şehrin altında görünmez düz zemin: modelde boşluk olan yerden aşağı düşülmez
func _guvenlik_zemini() -> void:
	var g := StaticBody3D.new(); g.name = "GuvenlikZemini"
	var c := CollisionShape3D.new(); var b := BoxShape3D.new()
	b.size = Vector3(1000, 1, 1000); c.shape = b; c.position = Vector3(0, -0.52, 0)
	g.add_child(c); add_child(g)

# yine de bir yerden düşülürse son güvenli noktaya geri konur
var _son_guvenli := Vector3.ZERO
func _physics_process(_dt: float) -> void:
	if Engine.is_editor_hint(): return
	var o := get_node_or_null("Selim") as CharacterBody3D
	if o == null: return
	if o.is_on_floor() and o.global_position.y > -0.3: _son_guvenli = o.global_position
	elif o.global_position.y < -6.0:
		o.global_position = _son_guvenli + Vector3(0, 0.3, 0); o.velocity = Vector3.ZERO
