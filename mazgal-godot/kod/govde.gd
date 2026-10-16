extends Node3D
## Selim'in tüm gövdesi (alp'in gönderdiği Ch17_nonPBR.fbx). Aşağı bakınca gövde ve bacaklar görünür;
## baş görünmez (kamera kafanın içinde), yalnızca gölgesi düşer. Kollar, eller.gd bir şeye uzanmıyorken
## gövdenin kendi kollarıdır; uzanırken gövdenin kolları gizlenir, kameraya bağlı kollar görünür.
## Yürürken alp'in Mixamo yürüme animasyonu, dururken bekleme animasyonu oynar.
##   guncelle(konum, yon_y, dt)   her karede: ayakların yeri ve bakış yönü
##   goz = 1.48                    kameranın yerden yüksekliği: gövde gözleri buraya gelecek boyda durur
##   eller = <eller düğümü>        kameraya bağlı kollar görünürken gövdenin kolları gizlenir
##   gorunur = false               gövde gizlenir, gölgesi kalır (otururken, eğilirken)
##   yelek = false                 evde iş yeleği yok. Modelde yeleğin altında gövde yok (gömlek yalnızca
##                                 kollar ve yaka), bu yüzden yeleksizken belden yukarısı yalnızca gölge
##                                 düşer, aşağı bakınca bacaklar ve botlar görünür.

const MODEL := "res://modeller2/selim/Ch17_nonPBR.fbx"
const ANIM_YOLU := "res://modeller2/selimvucudanimasyon/"
const ANIMLER := {"yuru": "yürüme.fbx", "dur": "Standing Torch Idle 03.fbx"}
const GIZLI := ["Ch17_Helmet"]                     # baret Selim'in değil
const BAS_PARCALARI := ["Ch17_Hair", "Ch17_Eyelashes"]
const UST_PARCALAR := ["Ch17_Body", "Ch17_Shirt"]   # yeleksizken yalnızca gölge
const GERI := 0.12  # baş kameranın biraz arkasında durur: aşağı bakınca göğsün içi görünmez

var yelek := true
var goz := 1.48
var eller: Node3D
var gorunur := true
var _ap: AnimationPlayer
var _model: Node3D
var _iskelet: Skeleton3D
var _bas_kemik := -1
var _goz_model := 1.68
var _son := Vector3.INF
var _hiz := 0.0
var _govde_parca: Array[MeshInstance3D] = []   # gövde, bacaklar
var _kol_parca: Array[MeshInstance3D] = []     # gövdenin kolları


func _ready() -> void:
	if not ResourceLoader.exists(MODEL):
		push_warning("Selim'in modeli yok: " + MODEL)
		return
	_model = (load(MODEL) as PackedScene).instantiate()
	add_child(_model)
	_model.rotation.y = PI     # model +z'ye bakıyor
	var iskelet := _model.find_child("Skeleton3D", true, false) as Skeleton3D
	for g in _model.find_children("*", "MeshInstance3D", true, false):
		var mi := g as MeshInstance3D
		var ad := String(mi.name)
		mi.extra_cull_margin = 1.0
		if ad in GIZLI or (ad == "Ch17_Vest" and not yelek):
			mi.visible = false
			continue
		if ad in BAS_PARCALARI:
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
			continue
		# baş ve boyun yalnızca gölge; kollar ayrı parça; gerisi görünür
		var bas := mi.duplicate() as MeshInstance3D
		var kol := mi.duplicate() as MeshInstance3D
		mi.get_parent().add_child(bas)
		mi.get_parent().add_child(kol)
		bas.mesh = _suz(mi, iskelet, "bas")
		kol.mesh = _suz(mi, iskelet, "kol")
		mi.mesh = _suz(mi, iskelet, "govde")
		bas.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
		if ad in UST_PARCALAR and not yelek:
			# yeleksizken gövdenin üstü ve kolları havada kalır: yalnızca gölge
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
			kol.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
			continue
		_govde_parca.append(mi)
		_kol_parca.append(kol)
	# modelin göz hizası: baş kemiğinin biraz üstü
	_iskelet = iskelet
	_bas_kemik = iskelet.find_bone("mixamorig1_Head")
	if _bas_kemik >= 0:
		_goz_model = (iskelet.global_transform * iskelet.get_bone_global_rest(_bas_kemik).origin).y - global_position.y + 0.09
	_ap = AnimationPlayer.new()
	_model.add_child(_ap)
	_ap.root_node = _ap.get_path_to(iskelet.get_parent())
	var kitap := AnimationLibrary.new()
	for a_ad in ANIMLER:
		var a := _anim_yukle(ANIM_YOLU + ANIMLER[a_ad])
		if a: kitap.add_animation(a_ad, a)
	_ap.add_animation_library("", kitap)
	if _ap.has_animation("dur"): _ap.play("dur")


func _bolum(ad: String) -> String:
	if "Head" in ad or "Neck" in ad: return "bas"
	# yeleksizken belin üstü boş: bel de yalnızca gölge (aşağı bakınca pantolonun içi görünmesin)
	if not yelek and ("Hips" in ad or "Spine" in ad): return "bas"
	if ("Arm" in ad or "Hand" in ad) and not ("Shoulder" in ad): return "kol"
	return "govde"


## Gövde parçasından yalnızca istenen bölümün (baş, kol, gövde) kemiklerine bağlı üçgenleri alır.
func _suz(mi: MeshInstance3D, iskelet: Skeleton3D, bolum: String) -> ArrayMesh:
	var kaynak := mi.mesh
	var skin := mi.skin
	var bind_bolum := {}
	for i in skin.get_bind_count():
		var ad := String(skin.get_bind_name(i))
		if ad == "":
			var k := skin.get_bind_bone(i)
			if k >= 0: ad = iskelet.get_bone_name(k)
		bind_bolum[i] = _bolum(ad)
	var yeni := ArrayMesh.new()
	for s in kaynak.get_surface_count():
		var d := kaynak.surface_get_arrays(s)
		var kemik: PackedInt32Array = d[Mesh.ARRAY_BONES]
		var agirlik: PackedFloat32Array = d[Mesh.ARRAY_WEIGHTS]
		var n: int = (d[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
		var adim := kemik.size() / maxi(n, 1)
		# her köşe en çok ağırlığı olan bölüme düşer
		var benim := PackedByteArray(); benim.resize(n)
		for v in n:
			var w := {"bas": 0.0, "kol": 0.0, "govde": 0.0}
			for j in adim:
				w[bind_bolum.get(kemik[v * adim + j], "govde")] += agirlik[v * adim + j]
			var en := "govde"
			for b in w:
				if w[b] > w[en]: en = b
			benim[v] = 1 if en == bolum else 0
		var ind: PackedInt32Array = d[Mesh.ARRAY_INDEX]
		var secili := PackedInt32Array()
		for t in range(0, ind.size(), 3):
			# üçgen, köşelerinden en az ikisi bu bölümdeyse bu bölümündür (dikiş yerinde delik kalmaz)
			var say: int = benim[ind[t]] + benim[ind[t + 1]] + benim[ind[t + 2]]
			if say >= 2:
				secili.append(ind[t]); secili.append(ind[t + 1]); secili.append(ind[t + 2])
		if secili.is_empty(): continue
		d[Mesh.ARRAY_INDEX] = secili
		var bayrak: int = kaynak.surface_get_format(s) & Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS
		yeni.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, d, [], {}, bayrak)
		var mat := mi.get_active_material(s)
		if not yelek and bolum == "govde" and mat is BaseMaterial3D:
			# belden kesilen pantolonun içi yukarıdan bakınca boş görünmesin
			mat = (mat as BaseMaterial3D).duplicate()
			mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		yeni.surface_set_material(yeni.get_surface_count() - 1, mat)
	return yeni


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
	if _model == null: return
	if _son != Vector3.INF and dt > 0.0:
		var h := Vector2(konum.x - _son.x, konum.z - _son.z).length() / dt
		_hiz = lerpf(_hiz, h, clampf(dt * 8.0, 0.0, 1.0))
	_son = konum
	global_rotation = Vector3(0, yon_y, 0)
	# gözleri kameranın hizasında olacak boyda
	scale = Vector3.ONE * clampf(goz / _goz_model, 0.8, 1.1)
	# başı kameranın biraz arkasına gelir (yüzü -z'de); animasyon öne eğilse de göğüs kameranın altında kalır
	global_position = konum
	var yer := konum + global_basis.z * GERI
	if _bas_kemik >= 0:
		var bas := _iskelet.global_transform * _iskelet.get_bone_global_pose(_bas_kemik).origin
		global_position += Vector3(yer.x - bas.x, 0.0, yer.z - bas.z)
	else:
		global_position = yer
	var uzanan := eller != null and eller.visible
	# gizliyken de gölgesi düşer
	var acik := GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	var golge := GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
	for mi in _govde_parca: mi.cast_shadow = acik if gorunur else golge
	for mi in _kol_parca: mi.cast_shadow = acik if gorunur and not uzanan else golge
	if _ap == null: return
	var hedef := "yuru" if _hiz > 0.4 else "dur"
	if _ap.has_animation(hedef) and _ap.current_animation != hedef:
		_ap.play(hedef, 0.3)
	if hedef == "yuru": _ap.speed_scale = clampf(_hiz / 1.4, 0.6, 1.6)
	else: _ap.speed_scale = 1.0
