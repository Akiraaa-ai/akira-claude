extends Node3D
## Selim'in elleri: alp'in gönderdiği Selim karakterinin (Ch17_nonPBR.fbx) kendi kolları.
## Karakterin gövdesinden yalnızca kollar ve eller (deri + gömlek kolu) ayrılıp kameraya bağlanır.
## Her kol iki kemikli IK ile hedefe uzanır: omuz sabit, dirsek aşağı ve dışa bakar.
## Hedef yoksa kol aşağı iner ve görüş alanından çıkar.
##   uzan("sag", dunya_konumu, sure)   el o noktaya uzanır
##   birak("sag", sure)                 el aşağı iner
##   tut("sag", dugum)                  eşya avuçta durur (dugum ele bağlanır)
##   tut("sag", dugum, yerel, sure)     eşya elin çerçevesinde "yerel" yerde durur, elle birlikte döner
##   yumruk("sag", 0..1, basparmak)     parmaklar kapanır (başparmak ayrıca verilebilir)
##   kamerada("sag", konum, sure, parmak, avuc_yonu)   el o yöne dönmüş olarak gelir
## Elin çerçevesi (cerceve): kökü bilek; y parmakların uzandığı yön, z avucun baktığı yön,
## x = y × z (sağ elde başparmak +x'te, sol elde -x'te).

const MODEL := "res://modeller2/selim/Ch17_nonPBR.fbx"
const MODEL_2 := "res://modeller2/selimvucudanimasyon/Ch17_nonPBR.fbx"   # alp'in bilgisayarında burada
const ON := "mixamorig1_"
# kollarda görünen parçalar: çıplak el ve kol derisi (Body) ile gömleğin kolu (Shirt)
const KOL_PARCALARI := ["Ch17_Body", "Ch17_Shirt"]
# omuzların kameraya göre yeri (kamera uzayında, metre)
const OMUZ := Vector3(0.0, -0.24, 0.12)
# kol aşağıdayken bileğin kamera uzayındaki yeri
const DINLEN := {"sol": Vector3(-0.3, -0.72, -0.02), "sag": Vector3(0.3, -0.72, -0.02)}

# hazır tutuşlar: eşyanın el çerçevesindeki yeri (kökü bilek, y parmaklar, z avuç, x sağ elde başparmak).
# Telefon: ekranı +z, üstü +y. Sırtı avuçta, üstü başparmağa doğru; parmaklar sol kenarını sarar, başparmak ekranın üstünde.
static func telefon_tutusu() -> Transform3D:
	var b := Basis(Vector3(0, -1, 0), Vector3(1, 0, 0), Vector3(0, 0, 1))
	return Transform3D(Basis(Vector3(0, 0, 1), deg_to_rad(20.0)) * b, Vector3(0.035, 0.095, 0.028))

# Diş fırçası: sapı +y (başı +y ucunda), kılları -z. Sap yumruğun içinden geçer, başı başparmak yanından çıkar.
static func firca_tutusu() -> Transform3D:
	return Transform3D(Basis(Vector3(0, 1, 0), Vector3(1, 0, 0), Vector3(0, 0, -1)), Vector3(0.05, 0.075, 0.022))

var _iskelet: Skeleton3D
var _kemik := {}          # "sag_ust" -> indeks ...
var _boy := {}            # "sag" -> [üst kol, ön kol]
var _hedef := {"sol": Vector3.ZERO, "sag": Vector3.ZERO}       # kamera uzayında bilek hedefi
var _baslangic := {"sol": Vector3.ZERO, "sag": Vector3.ZERO}
var _bitis := {"sol": Vector3.ZERO, "sag": Vector3.ZERO}
var _sure := {"sol": 1.0, "sag": 1.0}
var _t := {"sol": 1.0, "sag": 1.0}
var _dunya := {"sol": false, "sag": false}   # hedef dünyada sabit mi
var _dunya_hedef := {"sol": Vector3.ZERO, "sag": Vector3.ZERO}
var _yumruk := {"sol": 0.0, "sag": 0.0}
var _yumruk_hedef := {"sol": 0.0, "sag": 0.0}
var _tutulan := {"sol": null, "sag": null}
var _bas := {"sol": -1.0, "sag": -1.0}             # başparmak; -1: diğer parmaklarla birlikte
var _bas_hedef := {"sol": -1.0, "sag": -1.0}
# elin kamera uzayındaki dönüşü: çağrıldığı andaki dönüşten hedefe döner; hedef null ise ön kolun devamı
var _yon_bas := {"sol": Quaternion.IDENTITY, "sag": Quaternion.IDENTITY}
var _yon_son := {"sol": null, "sag": null}
var _yon_simdi := {"sol": Quaternion.IDENTITY, "sag": Quaternion.IDENTITY}
# ele bağlı eşyanın el çerçevesindeki yeri: tutulduğu andaki yerinden "son"a kayar
var _tut_bas := {"sol": null, "sag": null}
var _tut_son := {"sol": null, "sag": null}
var _tut_t := {"sol": 1.0, "sag": 1.0}
var _tut_sure := {"sol": 0.5, "sag": 0.5}
var _tut_olcek := {"sol": Vector3.ONE, "sag": Vector3.ONE}
var gorunur_mu := false


func _ready() -> void:
	var yol := MODEL if ResourceLoader.exists(MODEL) else MODEL_2
	if not ResourceLoader.exists(yol):
		push_warning("Selim'in modeli yok: " + MODEL)
		visible = false
		return
	var m: Node3D = (load(yol) as PackedScene).instantiate()
	add_child(m)
	_iskelet = m.find_child("Skeleton3D", true, false) as Skeleton3D
	for g in m.find_children("*", "MeshInstance3D", true, false):
		var mi := g as MeshInstance3D
		if not (String(mi.name) in KOL_PARCALARI):
			mi.queue_free()
			continue
		mi.mesh = _yalniz_kollar(mi)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.extra_cull_margin = 2.0
	# model +z'ye bakıyor; kameranın önü -z
	m.rotation.y = PI
	for taraf in ["sol", "sag"]:
		var e := "Left" if taraf == "sol" else "Right"
		_kemik[taraf + "_ust"] = _iskelet.find_bone(ON + e + "Arm")
		_kemik[taraf + "_on"] = _iskelet.find_bone(ON + e + "ForeArm")
		_kemik[taraf + "_el"] = _iskelet.find_bone(ON + e + "Hand")
		_hedef[taraf] = DINLEN[taraf]
		_bitis[taraf] = DINLEN[taraf]
	# modelin kökü: omuzların ortası kamera uzayında OMUZ'a gelsin
	var kam := get_parent() as Node3D
	var sg := _iskelet.global_transform
	var omuz_orta: Vector3 = (sg * _iskelet.get_bone_global_rest(_kemik["sol_ust"]).origin + sg * _iskelet.get_bone_global_rest(_kemik["sag_ust"]).origin) * 0.5
	m.global_position += kam.global_transform * OMUZ - omuz_orta
	sg = _iskelet.global_transform
	for taraf in ["sol", "sag"]:
		var a := sg * _iskelet.get_bone_global_rest(_kemik[taraf + "_ust"]).origin
		var b := sg * _iskelet.get_bone_global_rest(_kemik[taraf + "_on"]).origin
		var c := sg * _iskelet.get_bone_global_rest(_kemik[taraf + "_el"]).origin
		_boy[taraf] = [a.distance_to(b), b.distance_to(c)]
	visible = false


## Karakterin tek parça gövdesinden yalnızca kol kemiklerine bağlı üçgenler alınır (gövde, baş,
## bacak kamerada görünmesin diye). Köşeler aynı kalır, sadece üçgen listesi süzülür.
func _yalniz_kollar(mi: MeshInstance3D) -> ArrayMesh:
	var kaynak := mi.mesh
	var skin := mi.skin
	var kol := {}
	for i in skin.get_bind_count():
		var ad := String(skin.get_bind_name(i))
		if ad == "":
			var k := skin.get_bind_bone(i)
			if k >= 0: ad = _iskelet.get_bone_name(k)
		if ("Arm" in ad or "Hand" in ad) and not ("Shoulder" in ad):
			kol[i] = true
	var yeni := ArrayMesh.new()
	for s in kaynak.get_surface_count():
		var d := kaynak.surface_get_arrays(s)
		var kemik: PackedInt32Array = d[Mesh.ARRAY_BONES]
		var agirlik: PackedFloat32Array = d[Mesh.ARRAY_WEIGHTS]
		var n: int = (d[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
		var adim := kemik.size() / maxi(n, 1)
		var kolda := PackedByteArray(); kolda.resize(n)
		for v in n:
			var w := 0.0
			for j in adim:
				if kol.has(kemik[v * adim + j]): w += agirlik[v * adim + j]
			kolda[v] = 1 if w > 0.5 else 0
		var ind: PackedInt32Array = d[Mesh.ARRAY_INDEX]
		var secili := PackedInt32Array()
		for t in range(0, ind.size(), 3):
			if kolda[ind[t]] and kolda[ind[t + 1]] and kolda[ind[t + 2]]:
				secili.append(ind[t]); secili.append(ind[t + 1]); secili.append(ind[t + 2])
		d[Mesh.ARRAY_INDEX] = secili
		var bayrak: int = kaynak.surface_get_format(s) & Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS
		yeni.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, d, [], {}, bayrak)
		yeni.surface_set_material(s, mi.get_active_material(s))
	return yeni


## El dünyadaki bir noktaya uzanır (bilek o noktaya gelir).
func uzan(taraf: String, dunya_konumu: Vector3, sure := 0.8) -> void:
	_baslangic[taraf] = _hedef[taraf]
	_yon_bas[taraf] = _yon_simdi[taraf]
	_yon_son[taraf] = null
	_dunya[taraf] = true
	_dunya_hedef[taraf] = dunya_konumu
	_sure[taraf] = maxf(sure, 0.01)
	_t[taraf] = 0.0
	visible = _iskelet != null


## El kamera uzayında bir noktaya gelir (örneğin telefonu yüzün önünde tutmak için).
## parmak ve avuc_yonu verilirse el o yöne döner (kamera uzayında: parmakların uzandığı yön, avucun baktığı yön).
func kamerada(taraf: String, konum: Vector3, sure := 0.8, parmak := Vector3.ZERO, avuc_yonu := Vector3.ZERO) -> void:
	_baslangic[taraf] = _hedef[taraf]
	_yon_bas[taraf] = _yon_simdi[taraf]
	_yon_son[taraf] = null if parmak == Vector3.ZERO else el_yonu(parmak, avuc_yonu)
	_dunya[taraf] = false
	_bitis[taraf] = konum
	_sure[taraf] = maxf(sure, 0.01)
	_t[taraf] = 0.0
	visible = _iskelet != null


## Eşyayı tutan el, eşya kamera uzayında "esya_xf"te duracak biçimde gelir (yerel: tut'a verilen yer).
func esyayla(taraf: String, esya_xf: Transform3D, yerel: Transform3D, sure := 0.8) -> void:
	var el := esya_xf * yerel.affine_inverse()
	kamerada(taraf, el.origin, sure, el.basis.y, el.basis.z)


func birak(taraf: String, sure := 0.7) -> void:
	kamerada(taraf, DINLEN[taraf], sure)
	_yumruk_hedef[taraf] = 0.0


## Parmaklar k kadar kapanır; basparmak verilmezse başparmak da parmaklarla birlikte kapanır.
func yumruk(taraf: String, k: float, basparmak := -1.0) -> void:
	_yumruk_hedef[taraf] = k
	_bas_hedef[taraf] = basparmak
	if basparmak >= 0.0 and _bas[taraf] < 0.0: _bas[taraf] = _yumruk[taraf] * 0.7


## İki yönden elin kamera uzayındaki dönüşü: y parmaklar, z avucun baktığı yön.
static func el_yonu(parmak: Vector3, avuc_yonu: Vector3) -> Quaternion:
	var y := parmak.normalized()
	var z := (avuc_yonu - y * avuc_yonu.dot(y)).normalized()
	return Basis(y.cross(z), y, z).get_rotation_quaternion()


## Eşyayı avuca alır. null verilirse bırakır (eşya olduğu yerde kalır).
## yerel verilirse eşya elin çerçevesinde (bkz. cerceve) o yerde durur ve elle birlikte döner;
## tutulduğu andaki yerinden oraya "sure" içinde kayar (masadan alınırken eşya sıçramasın).
func tut(taraf: String, esya: Node3D, yerel: Variant = null, sure := 0.5) -> void:
	var eski: Node3D = _tutulan[taraf]
	if eski and is_instance_valid(eski) and esya == null:
		var gt := eski.global_transform
		eski.get_parent().remove_child(eski)
		get_tree().current_scene.add_child(eski)
		eski.global_transform = gt
	_tutulan[taraf] = esya
	_tut_son[taraf] = yerel
	if esya and yerel != null and _iskelet:
		var gt := esya.global_transform
		_tut_olcek[taraf] = gt.basis.get_scale()
		gt.basis = gt.basis.orthonormalized()
		_tut_bas[taraf] = cerceve(taraf).affine_inverse() * gt
		_tut_t[taraf] = 0.0
		_tut_sure[taraf] = maxf(sure, 0.01)
	if esya and yerel == null:
		_yumruk_hedef[taraf] = 0.55


## Elin dünyadaki çerçevesi: kökü bilek, y parmaklar, z avucun baktığı yön (ölçeksiz).
func cerceve(taraf: String) -> Transform3D:
	if _iskelet == null: return global_transform
	var t := _iskelet.global_transform * _iskelet.get_bone_global_pose(_kemik[taraf + "_el"])
	t.basis = t.basis.orthonormalized()
	return t


## Elin avuç noktası (dünya). Eşyayı bırakmak için kullanılır.
func avuc(taraf: String) -> Vector3:
	if _iskelet == null: return global_position
	var el: int = _kemik[taraf + "_el"]
	var t := _iskelet.global_transform * _iskelet.get_bone_global_pose(el)
	var p := _iskelet.global_transform * _iskelet.get_bone_global_pose(_iskelet.find_bone(ON + ("Left" if taraf == "sol" else "Right") + "HandMiddle1"))
	return t.origin.lerp(p.origin, 0.8)


func _process(dt: float) -> void:
	if _iskelet == null: return
	var kam := get_parent() as Node3D
	var ters := kam.global_transform.affine_inverse()
	var acik := false
	for taraf in ["sol", "sag"]:
		_t[taraf] = minf(1.0, _t[taraf] + dt / _sure[taraf])
		var k := smoothstep(0.0, 1.0, _t[taraf])
		var son: Vector3 = (ters * _dunya_hedef[taraf]) if _dunya[taraf] else _bitis[taraf]
		_hedef[taraf] = (_baslangic[taraf] as Vector3).lerp(son, k)
		_yumruk[taraf] = move_toward(_yumruk[taraf], _yumruk_hedef[taraf], dt * 3.0)
		if (_hedef[taraf] as Vector3).distance_to(DINLEN[taraf]) > 0.05: acik = true
		if _bas_hedef[taraf] >= 0.0: _bas[taraf] = move_toward(_bas[taraf], _bas_hedef[taraf], dt * 3.0)
		else: _bas[taraf] = -1.0
		# elin dönüşü: hedefi yoksa ön kolun devamı (_kol hesaplar)
		var yon: Variant = _yon_son[taraf]
		var q: Quaternion = (_yon_bas[taraf] as Quaternion).slerp(yon, k) if yon != null else Quaternion.IDENTITY
		_kol(taraf, kam.global_transform * (_hedef[taraf] as Vector3), q if yon != null else null, k)
		_parmaklar(taraf)
		var esya: Node3D = _tutulan[taraf]
		if esya and is_instance_valid(esya):
			if _tut_son[taraf] != null:
				_tut_t[taraf] = minf(1.0, _tut_t[taraf] + dt / _tut_sure[taraf])
				var yerel: Transform3D = (_tut_bas[taraf] as Transform3D).interpolate_with(_tut_son[taraf], smoothstep(0.0, 1.0, _tut_t[taraf]))
				var gt := cerceve(taraf) * yerel
				esya.global_transform = Transform3D(gt.basis * Basis.from_scale(_tut_olcek[taraf]), gt.origin)
			else:
				esya.global_position = avuc(taraf)
	visible = acik
	gorunur_mu = acik


# iki kemikli IK: omuzdan bileğe, dirsek aşağı ve dışa.
# yon (kamera uzayında elin dönüşü) verilirse el o yöne döner, ön kol da bileğin kıvrılmaması için
# kendi ekseninde ona doğru biraz döner. Verilmezse el ön kolun devamıdır; k ile serbest dönüşe karışır.
func _kol(taraf: String, bilek: Vector3, el_yon: Variant = null, k := 1.0) -> void:
	var sk := _iskelet
	var sg := sk.global_transform
	var sgi := sg.affine_inverse()
	var ust: int = _kemik[taraf + "_ust"]
	var on: int = _kemik[taraf + "_on"]
	var el: int = _kemik[taraf + "_el"]
	var r_ust := sk.get_bone_global_rest(ust)
	var r_on := sk.get_bone_global_rest(on)
	var r_el := sk.get_bone_global_rest(el)
	var omuz := sg * r_ust.origin
	var l1: float = _boy[taraf][0]
	var l2: float = _boy[taraf][1]
	var d := bilek - omuz
	var uz := clampf(d.length(), 0.05, (l1 + l2) * 0.999)
	var yon := d.normalized()
	bilek = omuz + yon * uz
	# kosinüs kuralı: omuzdan dirseğe açı
	var a := acos(clampf((l1 * l1 + uz * uz - l2 * l2) / (2.0 * l1 * uz), -1.0, 1.0))
	var kam := (get_parent() as Node3D).global_transform.basis
	var dis := kam.x * (-1.0 if taraf == "sol" else 1.0)
	var kutup := (-kam.y * 1.0 + dis * 0.8).normalized()
	var dik := (kutup - yon * kutup.dot(yon)).normalized()
	var dirsek := omuz + (yon * cos(a) + dik * sin(a)) * l1
	# iskelet uzayında yönler
	var o_s := sgi * omuz
	var e_s := sgi * dirsek
	var b_s := sgi * bilek
	var rest_d1 := (r_on.origin - r_ust.origin).normalized()
	var rest_d2 := (r_el.origin - r_on.origin).normalized()
	var q1 := Quaternion(rest_d1, (e_s - o_s).normalized())
	var g_ust := Transform3D(Basis(q1) * r_ust.basis, r_ust.origin)
	sk.set_bone_global_pose(ust, g_ust)
	var on_dondu := Basis(q1) * r_on.basis
	var q2 := Quaternion((Basis(q1) * rest_d2).normalized(), (b_s - e_s).normalized())
	var on_b := Basis(q2) * on_dondu
	# el ön kolun devamı
	var el_b := Basis(q2) * Basis(q1) * r_el.basis
	# kamera uzayı -> iskelet uzayı (dönüş)
	var kam_s := (sgi.basis * kam).orthonormalized()
	if el_yon == null:
		# serbest el: son verilen dönüşten ön kolun devamına döner
		var serbest := (kam_s.inverse() * el_b.orthonormalized()).get_rotation_quaternion()
		var q_kam := (_yon_bas[taraf] as Quaternion).slerp(serbest, k)
		el_b = kam_s * Basis(q_kam)
	else:
		el_b = kam_s * Basis(el_yon as Quaternion)
		# ön kol kendi ekseninde avucun yönüne doğru döner (bilek burulmasın)
		var eksen := (b_s - e_s).normalized()
		var on_z := on_b.z - eksen * on_b.z.dot(eksen)
		var el_z := el_b.z - eksen * el_b.z.dot(eksen)
		if on_z.length() > 0.01 and el_z.length() > 0.01:
			var aci := on_z.normalized().signed_angle_to(el_z.normalized(), eksen)
			on_b = Basis(eksen, aci * 0.6) * on_b
	_yon_simdi[taraf] = (kam_s.inverse() * el_b.orthonormalized()).get_rotation_quaternion()
	sk.set_bone_global_pose(on, Transform3D(on_b, e_s))
	sk.set_bone_global_pose(el, Transform3D(el_b, b_s))


var _parmak_kemik := {}   # taraf -> [[kemik, dinlenme dönüşü, katsayı, başparmak mı], ...]; her karede ad aranmasın

func _parmaklar(taraf: String) -> void:
	if not _parmak_kemik.has(taraf):
		var e := "Left" if taraf == "sol" else "Right"
		var liste := []
		for p in ["Index", "Middle", "Ring", "Pinky"]:
			for n in [1, 2, 3]:
				var i := _iskelet.find_bone(ON + e + "Hand" + p + str(n))
				if i >= 0: liste.append([i, _iskelet.get_bone_rest(i).basis.get_rotation_quaternion(), 1.1 if n == 1 else 1.3, false])
		for n in [2, 3]:
			var i := _iskelet.find_bone(ON + e + "HandThumb" + str(n))
			if i >= 0: liste.append([i, _iskelet.get_bone_rest(i).basis.get_rotation_quaternion(), 0.7, true])
		_parmak_kemik[taraf] = liste
	var k: float = _yumruk[taraf]
	var bas: float = _bas[taraf] if _bas[taraf] >= 0.0 else k
	# Mixamo parmak kemikleri yerel z ekseni etrafında bükülür (sol ve sağda ters yön)
	var yon := 1.0 if taraf == "sol" else -1.0
	for b in _parmak_kemik[taraf]:
		var kk: float = bas if b[3] else k
		_iskelet.set_bone_pose_rotation(b[0], (b[1] as Quaternion) * Quaternion(Vector3.FORWARD, yon * kk * float(b[2])))
