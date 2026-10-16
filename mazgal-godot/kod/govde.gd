extends Node3D
## Selim'in tüm gövdesi (alp'in gönderdiği Ch17_nonPBR.fbx). Kamera birinci şahıs olduğu için gövde
## kendisi görünmez, yalnızca gölgesi düşer. Yürürken alp'in Mixamo yürüme animasyonu, dururken
## bekleme animasyonu oynar. Ayaklar düğümün konumundadır, yüzü -z'ye bakar.
##   guncelle(konum, yon_y, dt)   her karede: ayakların yeri ve bakış yönü
##   yelek = false                 evde iş yeleği yok

const MODEL := "res://modeller2/selim/Ch17_nonPBR.fbx"
const ANIM_YOLU := "res://modeller2/selimvucudanimasyon/"
const ANIMLER := {"yuru": "yürüme.fbx", "dur": "Standing Torch Idle 03.fbx"}
const GIZLI := ["Ch17_Helmet"]          # baret Selim'in değil

var yelek := true
var _ap: AnimationPlayer
var _model: Node3D
var _son := Vector3.INF
var _hiz := 0.0


func _ready() -> void:
	_model = (load(MODEL) as PackedScene).instantiate()
	add_child(_model)
	_model.rotation.y = PI     # model +z'ye bakıyor
	for g in _model.find_children("*", "MeshInstance3D", true, false):
		var mi := g as MeshInstance3D
		if String(mi.name) in GIZLI or (String(mi.name) == "Ch17_Vest" and not yelek):
			mi.visible = false
			continue
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
		mi.extra_cull_margin = 1.0
	var iskelet := _model.find_child("Skeleton3D", true, false) as Skeleton3D
	_ap = AnimationPlayer.new()
	_model.add_child(_ap)
	_ap.root_node = _ap.get_path_to(iskelet.get_parent())
	var kitap := AnimationLibrary.new()
	for ad in ANIMLER:
		var a := _anim_yukle(ANIM_YOLU + ANIMLER[ad])
		if a: kitap.add_animation(ad, a)
	_ap.add_animation_library("", kitap)
	if _ap.has_animation("dur"): _ap.play("dur")


## Mixamo animasyonu "mixamorig_" kemik adlarıyla gelir, Selim'in iskeleti "mixamorig1_".
## Kemik yolları çevrilir, kalçanın ileri-yana kayması silinir (Selim yerinde yürür, oyuncu taşır).
func _anim_yukle(yol: String) -> Animation:
	if not ResourceLoader.exists(yol): return null
	var sahne: Node = (load(yol) as PackedScene).instantiate()
	var ap := sahne.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if ap == null or not ap.has_animation("mixamo_com"):
		sahne.free()
		return null
	var a := (ap.get_animation("mixamo_com") as Animation).duplicate(true) as Animation
	sahne.free()
	a.loop_mode = Animation.LOOP_LINEAR
	for i in a.get_track_count():
		var p := String(a.track_get_path(i))
		a.track_set_path(i, NodePath(p.replace("mixamorig_", "mixamorig1_")))
		if p.ends_with("mixamorig_Hips") and a.track_get_type(i) == Animation.TYPE_POSITION_3D:
			var ilk: Vector3 = a.track_get_key_value(i, 0)
			for k in a.track_get_key_count(i):
				var v: Vector3 = a.track_get_key_value(i, k)
				a.track_set_key_value(i, k, Vector3(ilk.x, v.y, ilk.z))
	return a


func guncelle(konum: Vector3, yon_y: float, dt: float) -> void:
	if _son != Vector3.INF and dt > 0.0:
		var h := Vector2(konum.x - _son.x, konum.z - _son.z).length() / dt
		_hiz = lerpf(_hiz, h, clampf(dt * 8.0, 0.0, 1.0))
	_son = konum
	global_position = konum
	global_rotation = Vector3(0, yon_y, 0)
	if _ap == null: return
	var hedef := "yuru" if _hiz > 0.4 else "dur"
	if _ap.has_animation(hedef) and _ap.current_animation != hedef:
		_ap.play(hedef, 0.3)
	if hedef == "yuru": _ap.speed_scale = clampf(_hiz / 1.4, 0.6, 1.6)
	else: _ap.speed_scale = 1.0
