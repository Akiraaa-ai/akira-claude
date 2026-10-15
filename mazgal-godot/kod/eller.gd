extends Node3D
## Selim'in elleri (alp'in gönderdiği eldivenli kollar, Arms.fbx). Kameranın çocuğu olarak durur.
## Her kol iki kemikli IK ile hedefe uzanır: omuz sabit, dirsek aşağı ve dışa bakar.
## Hedef yoksa kol aşağı iner ve görüş alanından çıkar.
##   uzan("sag", dunya_konumu, sure)   el o noktaya uzanır
##   birak("sag", sure)                 el aşağı iner
##   tut("sag", dugum)                  eşya avuçta durur (dugum ele bağlanır)
##   yumruk("sag", 0..1)                parmaklar kapanır

const MODEL := "res://modeller2/eller/Arms.fbx"
const OLCEK := 0.42
# omuzların kameraya göre yeri (kamera uzayında, metre)
const OMUZ := Vector3(0.0, -0.36, 0.16)
# kol aşağıdayken bileğin kamera uzayındaki yeri
const DINLEN := {"sol": Vector3(-0.32, -0.75, -0.05), "sag": Vector3(0.32, -0.75, -0.05)}

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
var gorunur_mu := false


func _ready() -> void:
	var m: Node3D = (load(MODEL) as PackedScene).instantiate()
	add_child(m)
	m.scale = Vector3.ONE * OLCEK
	_iskelet = m.find_child("Skeleton3D", true, false) as Skeleton3D
	for g in m.find_children("*", "GeometryInstance3D", true, false):
		var gi := g as GeometryInstance3D
		gi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		gi.extra_cull_margin = 2.0
	# model +z'ye bakıyor; kameranın önü -z
	m.rotation.y = PI
	for taraf in ["sol", "sag"]:
		var e := "L" if taraf == "sol" else "R"
		_kemik[taraf + "_ust"] = _iskelet.find_bone("upper_arm." + e)
		_kemik[taraf + "_on"] = _iskelet.find_bone("forearm." + e)
		_kemik[taraf + "_el"] = _iskelet.find_bone("hand." + e)
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


## El dünyadaki bir noktaya uzanır (bilek o noktaya gelir).
func uzan(taraf: String, dunya_konumu: Vector3, sure := 0.8) -> void:
	_baslangic[taraf] = _hedef[taraf]
	_dunya[taraf] = true
	_dunya_hedef[taraf] = dunya_konumu
	_sure[taraf] = maxf(sure, 0.01)
	_t[taraf] = 0.0
	visible = true


## El kamera uzayında bir noktaya gelir (örneğin telefonu yüzün önünde tutmak için).
func kamerada(taraf: String, konum: Vector3, sure := 0.8) -> void:
	_baslangic[taraf] = _hedef[taraf]
	_dunya[taraf] = false
	_bitis[taraf] = konum
	_sure[taraf] = maxf(sure, 0.01)
	_t[taraf] = 0.0
	visible = true


func birak(taraf: String, sure := 0.7) -> void:
	kamerada(taraf, DINLEN[taraf], sure)
	_yumruk_hedef[taraf] = 0.0


func yumruk(taraf: String, k: float) -> void:
	_yumruk_hedef[taraf] = k


## Eşyayı avuca alır. null verilirse bırakır (eşya olduğu yerde kalır).
func tut(taraf: String, esya: Node3D) -> void:
	var eski: Node3D = _tutulan[taraf]
	if eski and is_instance_valid(eski) and esya == null:
		var gt := eski.global_transform
		eski.get_parent().remove_child(eski)
		get_tree().current_scene.add_child(eski)
		eski.global_transform = gt
	_tutulan[taraf] = esya
	if esya:
		_yumruk_hedef[taraf] = 0.55


## Elin avuç noktası (dünya). Eşyayı bırakmak için kullanılır.
func avuc(taraf: String) -> Vector3:
	var el: int = _kemik[taraf + "_el"]
	var t := _iskelet.global_transform * _iskelet.get_bone_global_pose(el)
	var p := _iskelet.global_transform * _iskelet.get_bone_global_pose(_iskelet.find_bone("palm.02." + ("L" if taraf == "sol" else "R")))
	return t.origin.lerp(p.origin, 1.6)


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
		_kol(taraf, kam.global_transform * (_hedef[taraf] as Vector3))
		_parmaklar(taraf)
		var esya: Node3D = _tutulan[taraf]
		if esya and is_instance_valid(esya):
			esya.global_position = avuc(taraf)
	visible = acik
	gorunur_mu = acik


# iki kemikli IK: omuzdan bileğe, dirsek aşağı ve dışa
func _kol(taraf: String, bilek: Vector3) -> void:
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
	var g_on := Transform3D(Basis(q2) * on_dondu, e_s)
	sk.set_bone_global_pose(on, g_on)
	# el ön kolun devamı, avuç biraz içe ve aşağı döner
	var el_b := Basis(q2) * Basis(q1) * r_el.basis
	sk.set_bone_global_pose(el, Transform3D(el_b, b_s))


func _parmaklar(taraf: String) -> void:
	var e := "L" if taraf == "sol" else "R"
	var k: float = _yumruk[taraf]
	for p in ["f_index", "f_middle", "f_ring", "f_pinky"]:
		for n in [1, 2, 3]:
			var i := _iskelet.find_bone("%s.0%d.%s" % [p, n, e])
			if i < 0: continue
			var r := _iskelet.get_bone_rest(i).basis.get_rotation_quaternion()
			_iskelet.set_bone_pose_rotation(i, r * Quaternion(Vector3.RIGHT, k * (1.1 if n == 1 else 1.3)))
	for n in [2, 3]:
		var i := _iskelet.find_bone("thumb.0%d.%s" % [n, e])
		if i < 0: continue
		var r := _iskelet.get_bone_rest(i).basis.get_rotation_quaternion()
		_iskelet.set_bone_pose_rotation(i, r * Quaternion(Vector3.RIGHT, k * 0.7))
