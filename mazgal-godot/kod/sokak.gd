@tool
extends Node3D
## Açılış sokağı: alp'in şehir modeli (orijinal, sıkıştırılmamış), gece, yağmur.

# şehir dosyası bu adlardan biriyle modeller/ klasöründe olabilir
const SEHIR_DOSYALARI := ["res://modeller/sehir.glb", "res://modeller/Terrain Remaked.glb", "res://dokular/source/Terrain Remaked.glb", "res://dokular/source/sehir.glb"]

@onready var sehir: Node3D = $Sehir
# şehir modelinin derinliği; ikinci kopya bu kadar kuzeyde (dünyada -z) durur
const SEHIR_BOY := 164.7771
## Şehir modeli Selim'e göre küçük kalıyordu (kapılar Selim boyundaydı). Şehir bu oranda büyütülür;
## Selim, arabalar ve kulübe gerçek boyunda kalır. Aşağıdaki dünya konumları ölçeksiz yazılıp bununla çarpılır.
const OLCEK := 1.4

func _ready() -> void:
	for yol in SEHIR_DOSYALARI:
		if ResourceLoader.exists(yol):
			sehir.add_child((load(yol) as PackedScene).instantiate())
			# şehir büyüsün diye aynı dosyanın ikinci kopyası kuzeye, ilkinin ucuna eklenir (tam boyut)
			var ikinci: Node3D = (load(yol) as PackedScene).instantiate()
			ikinci.name = "Sehir2"
			ikinci.position = Vector3(0, 0, SEHIR_BOY)
			sehir.add_child(ikinci)
			break
	if sehir.get_child_count() == 0:
		push_error("Şehir modeli bulunamadı: modeller/ klasörüne sehir.glb ya da Terrain Remaked.glb koy")
	_arabalari_kaldir()
	# şehirdeki bütün meshler gölge alır ve verir, üstünde yürünebilir
	for m in sehir.find_children("*", "MeshInstance3D", true, false):
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		if m.mesh and not Engine.is_editor_hint(): m.create_trimesh_collision()
	if Engine.is_editor_hint(): return
	_kenarlari_doldur()
	sehir.transform = Transform3D(Basis.from_scale(Vector3.ONE * OLCEK), Vector3.ZERO) * sehir.transform
	for n: Node3D in [$Kulube, $Araba, $Selim]:
		n.position = Vector3(n.position.x * OLCEK, n.position.y, n.position.z * OLCEK)
	_guvenlik_zemini()
	_sinir_duvarlari()
	_park_arabalari.call_deferred()
	_posta_kutusu()
	_mazgal_kur()
	_tabelalar()
	if has_meta("arkaplan"): return   # ana menünün arkasındaki görüntü
	_yolculuk_kur()

# Mazgal, şehir modelinin yola gömülü kahverengi rögar kapağıdır (alp: "şehirdeki mazgallardan kullansak").
# Kapağın kendi üçgenleri kopyalanır: kopya yana kaymış durur, yerinde aynı yuvarlak biçimde kapkara bir ağız açılır.
const MAZGAL_MALZEME := "Street_Assets.001"
func _mazgal_kur() -> void:
	if sehir.get_child_count() == 0: return
	var m := sehir.get_child(0).find_child("Plane_001", true, false) as MeshInstance3D
	if m == null or not (m.mesh is ArrayMesh): return
	var xf := m.global_transform
	for si in m.mesh.get_surface_count():
		var mat := m.mesh.surface_get_material(si) as BaseMaterial3D
		if mat == null or mat.resource_name != MAZGAL_MALZEME: continue
		var arr := m.mesh.surface_get_arrays(si)
		var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var uv: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV]
		var ind: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var bulundu := false
		for t in ind.size() / 3:
			var c := (xf * v[ind[t * 3]] + xf * v[ind[t * 3 + 1]] + xf * v[ind[t * 3 + 2]]) / 3.0
			if Vector2(c.x - MAZGAL.x, c.z - MAZGAL.z).length() > 0.7 * OLCEK: continue
			bulundu = true
			for q in 3:
				var w := xf * v[ind[t * 3 + q]]
				st.set_normal(Vector3.UP)
				st.set_uv(uv[ind[t * 3 + q]])
				st.add_vertex(Vector3(w.x - MAZGAL.x, 0.0, w.z - MAZGAL.z))
		if not bulundu: return
		var kapak_mesh := st.commit()
		# yana itilmiş kapak
		var kapak := MeshInstance3D.new()
		kapak.name = "MazgalKapak"
		kapak.mesh = kapak_mesh
		kapak.material_override = mat
		add_child(kapak)
		kapak.global_position = MAZGAL + Vector3(0.66 * OLCEK, 0.012, 0.3 * OLCEK)
		kapak.rotation.y = 0.55
		# kapağın yerinde kuyunun karanlığı (aynı yuvarlak maske, ışık ve sis almaz)
		var kara := mat.duplicate() as BaseMaterial3D
		kara.albedo_color = Color.BLACK
		kara.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		kara.disable_fog = true
		kara.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		kara.alpha_scissor_threshold = 0.5
		var agiz := MeshInstance3D.new()
		agiz.name = "MazgalAgzi"
		agiz.mesh = kapak_mesh
		agiz.material_override = kara
		agiz.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(agiz)
		agiz.global_position = MAZGAL + Vector3(0.0, 0.005, 0.0)
		return

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

# Şehir modelindeki eski arabaların yerlerine alp'in gönderdiği araç paketlerinden park halinde arabalar.
# [x, z, yön] (yön derece); ikinci şehir kopyasında aynı yerler SEHIR_BOY kadar kuzeyde tekrar edilir.
const ARAC_PAKETI := "res://modeller2/şehiriçin arabalar/low_poly_vehicle_mini_pack.glb"
const ARAC_PAKETI2 := "res://modeller2/şehiriçin arabalar/low_poly_vehicle_mini_pack_2.glb"
const PARK_YERLERI := [
	[-107.3, -69.4, 0.0], [-107.3, -50.1, 180.0], [-92.8, -3.4, 0.0], [-84.7, -3.4, 180.0], [-74.1, -3.4, 0.0],
	[-78.7, -91.5, 180.0], [-59.7, 13.2, 0.0], [-59.7, 22.85, 0.0], [-59.7, 27.15, 180.0], [-59.7, -34.4, 0.0],
	[-59.7, 43.9, 180.0], [-21.1, -39.3, 180.0], [-19.1, -27.85, 0.0], [-19.1, -23.55, 0.0], [-15.7, 44.3, 180.0],
	[-5.3, -91.5, 0.0], [5.3, 61.9, 180.0], [5.5, -91.5, 180.0], [28.3, -57.2, 0.0], [32.0, -35.9, 180.0],
	[32.1, -22.0, 0.0], [32.1, -68.7, 180.0],
]
const PARK_MODELLERI := [
	[ARAC_PAKETI, "sedan_body"], [ARAC_PAKETI2, "muscle_body_001"], [ARAC_PAKETI, "pickup_body_001"],
	[ARAC_PAKETI2, "suv_body_002"], [ARAC_PAKETI, "van_body_extra1"], [ARAC_PAKETI, "sedan_body_002"],
	[ARAC_PAKETI2, "muscle_body_003"], [ARAC_PAKETI2, "suv_body"], [ARAC_PAKETI, "sedan_body_001"],
	[ARAC_PAKETI, "pickup_body_002"], [ARAC_PAKETI2, "muscle_body"], [ARAC_PAKETI, "van_body_extra1_003"],
	[ARAC_PAKETI, "sedan_body_003"], [ARAC_PAKETI2, "suv_body_001"],
]

func _park_arabalari() -> void:
	var paketler := {}
	for y in [ARAC_PAKETI, ARAC_PAKETI2]:
		if ResourceLoader.exists(y): paketler[y] = (load(y) as PackedScene).instantiate()
	if paketler.is_empty(): return
	await get_tree().physics_frame
	var uzay := get_world_3d().direct_space_state
	var ana := Node3D.new(); ana.name = "ParkArabalari"; add_child(ana)
	var park_govde := StaticBody3D.new(); park_govde.name = "ParkCarpisma"; ana.add_child(park_govde)
	var sira := 0
	for kopya in [0.0, -SEHIR_BOY]:
		for p: Array in PARK_YERLERI:
			var m: Array = PARK_MODELLERI[sira % PARK_MODELLERI.size()]
			sira += 1
			if not paketler.has(m[0]): continue
			var kaynak := (paketler[m[0]] as Node).find_child(m[1], true, false) as Node3D
			if kaynak == null: continue
			var yer := Vector3(p[0], 0.0, float(p[1]) + kopya) * OLCEK
			var h := _zemin_y(uzay, yer, park_govde)
			if is_nan(h): continue
			yer.y = h
			_arac_koy(kaynak, paketler[m[0]], yer, float(p[2]), ana, park_govde, _kaldirim_bul(uzay, yer, park_govde))
	for k in paketler: (paketler[k] as Node).free()

func _zemin_y(uzay: PhysicsDirectSpaceState3D, yer: Vector3, haric: CollisionObject3D) -> float:
	var q := PhysicsRayQueryParameters3D.create(Vector3(yer.x, yer.y + 0.9, yer.z), Vector3(yer.x, yer.y - 3.0, yer.z))
	q.exclude = [haric.get_rid()]
	var r := uzay.intersect_ray(q)
	return NAN if r.is_empty() else float(r.position.y)


## Yolun ortasından en yakın kaldırıma: dört yöne bakıp zeminin kaldırım kadar (3-50 cm) yükseldiği
## ilk yeri bulur. [yön, uzaklık]; kaldırım yoksa yön sıfır.
func _kaldirim_bul(uzay: PhysicsDirectSpaceState3D, yer: Vector3, haric: CollisionObject3D) -> Array:
	var en_yakin := INF
	var yon := Vector3.ZERO
	for d: Vector3 in [Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.BACK]:
		var m := 0.25
		while m < 12.0 and m < en_yakin:
			var h := _zemin_y(uzay, yer + d * m, haric)
			if is_nan(h): break
			var fark := h - yer.y
			if fark > 0.5: break        # duvar ya da direk: kaldırım değil
			if fark > 0.03:
				en_yakin = m
				yon = d
				break
			m += 0.25
	return [yon, en_yakin]


func _arac_koy(kaynak: Node3D, kok: Node, yer: Vector3, aci: float, ana: Node3D, park_govde: StaticBody3D, kaldirim := [Vector3.ZERO, 0.0]) -> void:
	var don := Transform3D.IDENTITY
	var n: Node = kaynak
	while n != kok:
		don = (n as Node3D).transform * don
		n = n.get_parent()
	var kutu := AABB()
	var ilk := true
	for mi in kaynak.find_children("*", "MeshInstance3D", true, false) + ([kaynak] if kaynak is MeshInstance3D else []):
		var t := Transform3D.IDENTITY
		var c: Node = mi
		while c != kaynak:
			t = (c as Node3D).transform * t
			c = c.get_parent()
		var k: AABB = (don * t) * (mi as MeshInstance3D).get_aabb()
		kutu = k if ilk else kutu.merge(k)
		ilk = false
	var tut := Node3D.new(); tut.name = kaynak.name
	ana.add_child(tut)
	var kopya := kaynak.duplicate() as Node3D
	kopya.transform = don
	tut.add_child(kopya)
	tut.rotation_degrees.y = aci
	# yolun ortasında durmasın: kaldırıma paralel döner, sağ yanı kaldırımdan 30 cm beride durur
	var yan: Vector3 = kaldirim[0]
	if yan != Vector3.ZERO:
		var uzun := tut.basis * (Vector3(kutu.size.x, 0, 0) if kutu.size.x > kutu.size.z else Vector3(0, 0, kutu.size.z))
		if absf(uzun.normalized().dot(yan)) > 0.7: tut.rotation_degrees.y = aci + 90.0
		var en := minf(kutu.size.x, kutu.size.z)
		var kay := float(kaldirim[1]) - en * 0.5 - 0.3
		if kay > 0.0: yer += yan * kay
	var alt := Vector3(kutu.get_center().x, kutu.position.y, kutu.get_center().z)
	tut.position = yer - tut.basis * alt
	for mi in tut.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		for i in (mi as MeshInstance3D).mesh.get_surface_count():
			var mat := (mi as MeshInstance3D).get_active_material(i) as StandardMaterial3D
			if mat and mat.albedo_texture: (mi as MeshInstance3D).set_surface_override_material(i, _koyu_cam(mat, (mi as MeshInstance3D).global_transform * (mi as MeshInstance3D).get_aabb()))
	# çarpışma: aracın kutusu
	var cs := CollisionShape3D.new(); var b := BoxShape3D.new()
	b.size = kutu.size; cs.shape = b
	cs.transform = Transform3D(tut.basis, tut.position + tut.basis * kutu.get_center())
	park_govde.add_child(cs)

# Araç paketlerinde camlar ya dokunun yarı saydam pikselleri ya da aracın üst yarısındaki düz gri yüzeyler.
# İçleri görünmesin diye (alp) bunlar koyu ve parlak boyanır; "bel" camların alt hizasıdır (dünya yüksekliği).
const KOYU_CAM_SHADER := """shader_type spatial;
uniform sampler2D doku : source_color, filter_linear_mipmap;
uniform float puruz = 0.6;
uniform float bel = 0.0;
uniform float gri_ust = 0.85;   // beyaz gövdeli araçlarda cam gövdeden koyu gridir; açık gri gövde cam sayılmaz
varying float yukseklik;
varying float dikey;
void vertex() { yukseklik = (MODEL_MATRIX * vec4(VERTEX, 1.0)).y; dikey = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz).y; }
void fragment() {
	vec4 c = texture(doku, UV);
	float gri = step(max(c.r, max(c.g, c.b)) - min(c.r, min(c.g, c.b)), 0.07) * step(0.3, c.g) * step(c.g, gri_ust);
	float cam = max(1.0 - step(0.97, c.a), gri * step(bel, yukseklik) * step(dikey, 0.85));
	ALBEDO = mix(c.rgb, vec3(0.012, 0.014, 0.018), cam);
	ROUGHNESS = mix(puruz, 0.06, cam);
	SPECULAR = mix(0.5, 0.9, cam);
}
"""
var _cam_shader: Shader
func _koyu_cam(mat: StandardMaterial3D, kutu: AABB) -> ShaderMaterial:
	if _cam_shader == null:
		_cam_shader = Shader.new(); _cam_shader.code = KOYU_CAM_SHADER
	var m := ShaderMaterial.new(); m.shader = _cam_shader
	m.set_shader_parameter("doku", mat.albedo_texture)
	m.set_shader_parameter("puruz", mat.roughness)
	m.set_shader_parameter("bel", kutu.position.y + kutu.size.y * 0.55)
	var ad := mat.resource_name
	m.set_shader_parameter("gri_ust", 0.5 if ad.contains("white") or ad.begins_with("van") else 0.85)
	return m

# alp'in yol tabelası paketi: direk ve üstündeki levha(lar) birlikte, kaldırımlara dikilir.
const TABELA_PAKETI := "res://şehir/road_signs_asset_pack__australian_american.glb"
const TABELA_OLCEK := 0.27   # paketin direği 11 birim; gerçek direk 3 m
## [direk, levhalar] paketteki adlarıyla
const TABELA_TAKIMLARI := [
	["Post_001_53", ["Sign_058_51"]], ["Post_002_54", ["Sign_256_56"]], ["Post_003_55", ["Sign_059_52"]],
	["Post_074_58", ["Sign_257_57"]], ["Post_036_66", ["Sign_027_59", "Sign_141_64"]],
	["Post_037_67", ["Sign_017_61", "Sign_142_65"]], ["Post_038_68", ["Sign_028_60"]],
]
## [takım, dünya konumu (ölçekli şehirde kaldırım), levhanın baktığı yön (yaw derece)]
const TABELALAR := [
	[0, Vector3(-9.0, 0, 9.5), 0.0],       # evin sokağı, kavşaktan önce sağda (kuzeye giden sürücüye bakar)
	[4, Vector3(-36.0, 0, -5.3), 90.0],    # orta cadde, batıya giderken sağda
	[1, Vector3(-62.0, 0, -5.3), 90.0],
	[5, Vector3(-70.8, 0, -8.0), 0.0],     # kulübeye dönülen kavşak
	[2, Vector3(-70.8, 0, -60.0), 0.0],
	[6, Vector3(-26.0, 0, 30.0), 180.0],   # evin karşı kaldırımı
	[3, Vector3(-16.0, 0, -12.0), 180.0],
]
func _tabelalar() -> void:
	if not ResourceLoader.exists(TABELA_PAKETI) or has_node("Tabelalar"): return
	var paket := (load(TABELA_PAKETI) as PackedScene).instantiate() as Node3D
	add_child(paket)   # dünya dönüşümü okunabilsin diye bir an sahneye girer
	var ana := Node3D.new(); ana.name = "Tabelalar"; add_child(ana)
	var govde := StaticBody3D.new(); ana.add_child(govde)
	for t in TABELALAR:
		tabela_koy(ana, govde, paket, TABELA_TAKIMLARI[t[0]], t[1], t[2], TABELA_OLCEK)
	paket.queue_free()

## Paketten bir direk ve levhalarını kopyalar. yaw: levhanın baktığı yön (0 = +z). Yeraltında da kullanılır (arsiv.gd).
static func tabela_koy(ana: Node3D, govde: StaticBody3D, paket: Node3D, takim: Array, yer_: Vector3, yaw: float, olcek: float) -> void:
	var direk := paket.find_child(takim[0], true, false) as Node3D
	if direk == null: return
	var dk := _dugum_kutusu(direk)
	# direğin dibi tabelanın başlangıcı; levhalar direğe göre yerinde kalır
	var taban := Vector3(dk.get_center().x, dk.position.y, dk.get_center().z)
	# paketteki levhaların yüzü +x'e bakar; -90 ile +z'ye çevrilir, sonra istenen yöne
	var yer := Transform3D(Basis(Vector3.UP, deg_to_rad(yaw - 90.0)).scaled(Vector3.ONE * olcek), yer_)
	for ad in [takim[0]] + takim[1]:
		var d := paket.find_child(ad, true, false) as Node3D
		if d == null: continue
		for mi in d.find_children("*", "MeshInstance3D", true, false) + ([d] if d is MeshInstance3D else []):
			var k := MeshInstance3D.new()
			k.mesh = (mi as MeshInstance3D).mesh
			ana.add_child(k)
			k.global_transform = yer * Transform3D(Basis(), -taban) * (mi as MeshInstance3D).global_transform
	var boy := dk.size.y * olcek
	var c := CollisionShape3D.new(); var b := CylinderShape3D.new()
	b.radius = 0.06; b.height = boy; c.shape = b; c.position = yer_ + Vector3(0, boy * 0.5, 0)
	govde.add_child(c)

static func _dugum_kutusu(n: Node3D) -> AABB:
	var kutu := AABB(); var ilk := true
	for mi in n.find_children("*", "MeshInstance3D", true, false) + ([n] if n is MeshInstance3D else []):
		var k: AABB = (mi as MeshInstance3D).global_transform * (mi as MeshInstance3D).get_aabb()
		kutu = k if ilk else kutu.merge(k); ilk = false
	return kutu

# Kulübenin masasında iki katlı evrak/mektup sepeti (alp'in double_letter_box modeli)
const POSTA_KUTUSU := "res://modeller2/klübe/double_letter_box.glb"
func _posta_kutusu() -> void:
	if not ResourceLoader.exists(POSTA_KUTUSU) or not has_node("Kulube"): return
	var m: Node3D = (load(POSTA_KUTUSU) as PackedScene).instantiate()
	m.name = "PostaKutusu"
	$Kulube.add_child(m)
	m.scale = Vector3.ONE * POSTA_OLCEK
	m.position = POSTA_YERI
	m.rotation_degrees = POSTA_DONUS

const POSTA_OLCEK := 1.2
const POSTA_YERI := Vector3(0.86, 1.14, -1.52)
const POSTA_DONUS := Vector3(0, 90, 0)

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
	if o == null or durum == "surus" or durum == "binis" or durum == "inis" or durum == "park": return
	if o.is_on_floor() and o.global_position.y > -0.3: _son_guvenli = o.global_position
	elif o.global_position.y < -6.0:
		o.global_position = _son_guvenli + Vector3(0, 0.3, 0); o.velocity = Vector3.ZERO

# Şehrin dış yollarının ötesi boştu (alp: "binalar olsun ki gidilmesin", "karanlık kalmasın").
# Oraya şehrin kendi bloklarının kopyaları dizilir: binalar, kaldırımlar, direkler ve lambaların ışığı.
# Bloklar şehrin ilk kopyasında, ölçeksiz dünya koordinatında [x0, x1, z0, z1] (test/_ust_bak.gd üstten görünüşüyle ölçüldü).
const BLOK_A := [-106.3, -66.2, -84.2, -3.2]   # batı sütununun kuzey bloğu
const BLOK_C := [-11.9, 25.4, -84.2, -3.2]     # doğu sütununun kuzey bloğu
const SEHIR_BATI := -117.4
const SEHIR_DOGU := 37.05
const SEHIR_GUNEY := 69.2
const KENAR_PAY := 3.5   # lamba kolları yola taştığı için blok bu kadar geniş alınır
func _kenarlari_doldur() -> void:
	if has_node("Kenarlar") or sehir.get_child_count() == 0: return
	var kaynak := sehir.get_child(0)
	var parcalar := {}
	for b in [BLOK_A, BLOK_C]: parcalar[b] = _blok_kes(kaynak, b)
	var kenar := Node3D.new(); kenar.name = "Kenarlar"; add_child(kenar)
	kenar.scale = Vector3.ONE * OLCEK
	var kuzey := -95.3 - SEHIR_BOY
	var blok_boy := 81.0
	var yerler := []   # [blok, kayma]
	# batı ve doğu: kuzeyin ötesinden güneyin ötesine kadar bloklar art arda
	for i in 6:
		var dz := kuzey - blok_boy - BLOK_A[2] + blok_boy * i
		yerler.append([BLOK_C, Vector3(SEHIR_BATI - BLOK_C[1], 0, dz)])
		yerler.append([BLOK_A, Vector3(SEHIR_DOGU - BLOK_A[0], 0, dz)])
	# güney ve kuzey: batıdan doğuya A ve C sırayla
	var x := SEHIR_BATI
	var sira := 0
	while x < SEHIR_DOGU:
		var b: Array = BLOK_A if sira % 2 == 0 else BLOK_C
		yerler.append([b, Vector3(x - b[0], 0, SEHIR_GUNEY - b[2])])
		yerler.append([b, Vector3(x - b[0], 0, kuzey - b[3])])
		x += b[1] - b[0]
		sira += 1
	var lambalar := $Lambalar
	for y in yerler:
		for m: Mesh in parcalar[y[0]]:
			var mi := MeshInstance3D.new(); mi.mesh = m; mi.position = y[1]
			kenar.add_child(mi)
		if lambalar.has_method("kopya_lambalar"): lambalar.kopya_lambalar(y[0], KENAR_PAY, y[1])

## kaynak şehrin bir bloğunun üçgenlerini (merkezi dikdörtgenin içindekiler) ölçeksiz dünya konumunda yeni meshlere kopyalar
func _blok_kes(kaynak: Node, b: Array) -> Array:
	var sonuc := []
	for m in kaynak.find_children("*", "MeshInstance3D", true, false):
		var mi := m as MeshInstance3D
		if not (mi.mesh is ArrayMesh): continue
		var pay := 0.3 if str(mi.name).begins_with("Plane") else KENAR_PAY
		var x0: float = b[0] - pay; var x1: float = b[1] + pay; var z0: float = b[2] - pay; var z1: float = b[3] + pay
		var xf := mi.global_transform
		var yeni := ArrayMesh.new()
		for si in mi.mesh.get_surface_count():
			if mi.mesh.surface_get_primitive_type(si) != Mesh.PRIMITIVE_TRIANGLES: continue
			var arr := mi.mesh.surface_get_arrays(si)
			var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var ind: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
			if ind.is_empty():
				ind.resize(v.size())
				for i in v.size(): ind[i] = i
			var w := PackedVector3Array(); w.resize(v.size())
			for i in v.size(): w[i] = xf * v[i]
			var sec := PackedInt32Array()
			for t in ind.size() / 3:
				var c := (w[ind[t * 3]] + w[ind[t * 3 + 1]] + w[ind[t * 3 + 2]]) / 3.0
				if c.x < x0 or c.x > x1 or c.z < z0 or c.z > z1: continue
				sec.append(ind[t * 3]); sec.append(ind[t * 3 + 1]); sec.append(ind[t * 3 + 2])
			if sec.is_empty(): continue
			var yeni_arr := arr.duplicate()
			yeni_arr[Mesh.ARRAY_VERTEX] = w
			var nb := xf.basis.orthonormalized()
			if arr[Mesh.ARRAY_NORMAL] != null:
				var n: PackedVector3Array = (arr[Mesh.ARRAY_NORMAL] as PackedVector3Array).duplicate()
				for i in n.size(): n[i] = nb * n[i]
				yeni_arr[Mesh.ARRAY_NORMAL] = n
			if arr[Mesh.ARRAY_TANGENT] != null:
				var tg: PackedFloat32Array = (arr[Mesh.ARRAY_TANGENT] as PackedFloat32Array).duplicate()
				for i in tg.size() / 4:
					var d := nb * Vector3(tg[i * 4], tg[i * 4 + 1], tg[i * 4 + 2])
					tg[i * 4] = d.x; tg[i * 4 + 1] = d.y; tg[i * 4 + 2] = d.z
				yeni_arr[Mesh.ARRAY_TANGENT] = tg
			yeni_arr[Mesh.ARRAY_INDEX] = sec
			yeni.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, yeni_arr)
			yeni.surface_set_material(yeni.get_surface_count() - 1, mi.mesh.surface_get_material(si))
		if yeni.get_surface_count() > 0: sonuc.append(yeni)
	return sonuc

# şehrin kenarlarına görünmez duvar: arabayla ya da yürüyerek boşluğa çıkılmaz
func _sinir_duvarlari() -> void:
	var g := StaticBody3D.new(); g.name = "SinirDuvarlari"; add_child(g)
	var kuzey := -95.5 - SEHIR_BOY
	var orta := (kuzey + 69.5) * 0.5
	var boy := 69.5 - kuzey + 5.0
	for d in [[Vector3(-117.5, 3, orta), Vector3(1, 8, boy)], [Vector3(37.5, 3, orta), Vector3(1, 8, boy)],
			[Vector3(-40, 3, kuzey), Vector3(160, 8, 1)], [Vector3(-40, 3, 69.5), Vector3(160, 8, 1)]]:
		var c := CollisionShape3D.new(); var b := BoxShape3D.new()
		var boyut: Vector3 = d[1]; var yer: Vector3 = d[0]
		b.size = Vector3(boyut.x * OLCEK, boyut.y, boyut.z * OLCEK); c.shape = b
		c.position = Vector3(yer.x * OLCEK, yer.y, yer.z * OLCEK); g.add_child(c)


# ---------------- Evden çıkış, arabaya biniş, kulübeye sürüş ----------------
# Selim evin kapısından çıkar (sağ alt blok), kapının önünde park etmiş arabasına yürür, E ile biner.
# Kuzeye sürer, ortadaki caddeden sola, sonra sağa döner; kulübenin önünde E ile iner.

const KULUBE_PARK := Vector3(-58.0, 0.0, -77.0) * OLCEK
const PARK_YARICAP := 8.0
const SATIRLAR := {
	"araba1": ["res://sesler/selim_araba_01.mp3", "SELİM", "Her gece aynı yol... aynı lambalar."],
	"araba2": ["res://sesler/selim_araba_02.mp3", "SELİM", "Bir şey olsun be. Bir şey..."],
	"amir1": ["res://sesler/amir_01.mp3", "AMİR", "Alo, Selim?"],
	"selim1": ["res://sesler/selim_01.mp3", "SELİM", "Buradayım abi, kulübeden ayrılmadım hiç."],
	"amir2": ["res://sesler/amir_02.mp3", "AMİR", "Kulübede misin? Santralden bağladılar demin... Biri aradı, mazgal açık kalmış diyor. Yalan yok, arayanın sesi de aynı sen ha, bir an 'bu herif benimle kafa mı buluyor' dedim."],
	"selim2": ["res://sesler/selim_02.mp3", "SELİM", "Kim dalga geçecek seninle, başkasıdır o."],
	"amir3": ["res://sesler/amir_03.mp3", "AMİR", "Çıkıver oradan iki adım, bakıver şuna. Çoluk çocuk geçiyor o yoldan, biri düşer eder Allah korusun, başımıza iş almayalım. Kapatıver kapağı da raporu düşelim sisteme."],
	"selim3": ["res://sesler/selim_03.mp3", "SELİM", "Tamam, anladım; iki dakikaya gidip oturturum kapağı yerine. Başımıza iş açılmasın, halledip haber veririm sana."],
	"mirilti": ["res://sesler/selim_05.mp3", "SELİM", "Kim açar ki bunu bu saatte..."],
	"ses": ["res://sesler/selim_06.mp3", "SELİM", "Bu... bu ne sesi?"],
	# iç ses: alp okuyunca sesler/ klasörüne bu adlarla konur; dosya yokken yalnız altyazı çıkar
	"ic05": ["res://sesler/selim_ic_04b.mp3", "SELİM", "Geldik. Yine bu kulübe."],   # alp'in selim_ic_04 kaydının ikinci yarısı
	"ic06": ["res://sesler/selim_ic_05.mp3", "SELİM", "Kayıt açık... kim izleyecekse."],   # alp bu satırı selim_ic_05 adıyla kaydetti
	"ic07": ["res://sesler/selim_ic_07.mp3", "SELİM", "Kanalı kim değiştirdi şimdi..."],
	"ic08": ["res://sesler/selim_ic_08.mp3", "SELİM", "Hadi bakalım. İki dakika."],
	# 1. gece: kulübede bir şey olmaz, sabah olur, Selim eve döner
	"ic09": ["res://sesler/selim_ic_09.mp3", "SELİM", "Yine bir şey olmadı... Sabah olmuş bile."],
	"ic10": ["res://sesler/selim_ic_10.mp3", "SELİM", "Eve gidip biraz uyuyayım."],
}
## Selim'in evinin önü: araba ilk gece buradan kalkar, eve dönünce buraya park edilir.
const EV_PARK := Vector3(-11.2, 0.0, 25.5 * OLCEK)   # sağdaki kaldırıma yanaşık (kaldırım taşı x -9.75), sürücü kapısı yola bakar
var eve_donus := false
const Eller := preload("res://kod/eller.gd")
const Govde := preload("res://kod/govde.gd")
var govde: Govde       # Selim'in gövdesi: aşağı bakınca görünür, başın yalnızca gölgesi
const Kagit := preload("res://kod/kagit.gd")
var _iz_son := Vector3(1e9, 0, 0)
var _iz_sayi := 0
var _iz_sol := false
const Bodycam := preload("res://kod/bodycam.gd")
const KONUSMA := ["amir1", "selim1", "amir2", "selim2", "amir3", "selim3"]
# açık mazgal: kulübeden sola, caddenin ortasında şehir modelinin kendi rögar kapaklarından biri (_mazgal_kur)
const MAZGAL := Vector3(-55.887, 0.0, -87.044) * OLCEK

var durum := "yuruyus"
var dt_durum := 0.0
var surus_suresi := 0.0
var _soylenen := {}
var _altyazi_bitis := 0.0
var _gecis_bas: Transform3D
var _gecis_bit: Transform3D

@onready var araba: CharacterBody3D = $Araba
var oyuncu: CharacterBody3D
var oyuncu_kamera: Camera3D
var siyah: ColorRect
var ipucu: Label
var altyazi: Label
var ses_selim: AudioStreamPlayer
var ses_kapi: AudioStreamPlayer3D
var ses_yagmur: AudioStreamPlayer

const Atmosfer := preload("res://kod/atmosfer.gd")
var atmosfer: Atmosfer

func _yolculuk_kur() -> void:
	oyuncu = $Selim
	oyuncu_kamera = $Selim/Kafa/Kamera
	oyuncu_kamera.current = true
	govde = Govde.new()
	add_child(govde)
	_arayuz_kur()
	ses_selim = AudioStreamPlayer.new(); add_child(ses_selim)
	# düşüşün sesleri önceden hazırlanır: en gergin anda takılma olmasın
	_cokme_sesi(); _gumbur_sesi()
	ses_kapi = AudioStreamPlayer3D.new(); ses_kapi.stream = _kapi_sesi(); ses_kapi.unit_size = 4.0; add_child(ses_kapi)
	($Araba/Carpma as AudioStreamPlayer3D).stream = _kapi_sesi()
	ses_yagmur = AudioStreamPlayer.new(); add_child(ses_yagmur)
	if ResourceLoader.exists("res://sesler/yagmur.mp3"):
		var y: AudioStream = load("res://sesler/yagmur.mp3")
		if y is AudioStreamMP3: (y as AudioStreamMP3).loop = true
		ses_yagmur.stream = y; ses_yagmur.volume_db = -8.0; ses_yagmur.play()
	# evin kapısı arkasından kapanır
	ses_kapi.global_position = oyuncu.global_position + Vector3(1.2, 1.0, 0)
	ses_kapi.play()
	_ipucu("Arabana git", 0.0)
	# fener kulübedeki masada: alınıp pili takılana kadar F çalışmaz
	(oyuncu.get_node("Kafa/Kamera/Fener") as SpotLight3D).visible = false
	oyuncu.fener_izin = false
	oyuncu.fener_bos.connect(func() -> void:
		if _fener_tutuldu and not _pil_takildi: _gecici_ipucu("Pil yok", 2.0))
	eller = Eller.new()
	oyuncu_kamera.add_child(eller)
	atmosfer = Atmosfer.new()
	atmosfer.ay = $Ay; atmosfer.ortam = $Ortam; atmosfer.oyuncu = oyuncu
	add_child(atmosfer)
	var d := get_node_or_null("/root/Duraklat")
	if d:
		var nokta := str(d.baslangic_noktasi)
		d.baslangic_noktasi = ""
		if nokta == "kulube": _kulubeden_basla.call_deferred()
		else: d.kayit_noktasi(scene_file_path, "yuruyus")

# kayıttan devam: araba kulübenin önüne park edilmiş, Selim kulübenin kapısında
func _kulubeden_basla() -> void:
	araba.global_position = KULUBE_PARK + Vector3(0, 0.5, 0)
	araba._yere_otur(true)
	oyuncu.global_position = _k(Vector3(-0.6, 0.3, -2.9))
	_ipucu("", 0.0)
	_gec("kulube")

func _process(dt: float) -> void:
	if Engine.is_editor_hint() or oyuncu == null: return
	dt_durum += dt
	_oyun_saati += dt
	# gövde yürürken görünür (arabada, otururken, düşerken gizli)
	govde.visible = (durum == "yuruyus" or durum == "mazgala" or durum == "kulube") and oyuncu.is_physics_processing()
	if govde.visible:
		govde.goz = oyuncu.BOY
		govde.eller = eller
		govde.gorunur = not Input.is_action_pressed("egil")
		govde.guncelle(oyuncu.global_position, oyuncu.global_rotation.y, dt)
	_physics_ugultu()
	if durum != "dusus" and durum != "karanlik":
		siyah.modulate.a = move_toward(siyah.modulate.a, 0.0, dt * 0.6)
	if _altyazi_bitis > 0.0 and T_simdi() > _altyazi_bitis:
		altyazi.visible = false; _altyazi_bitis = 0.0
	_kulube_guncelle(dt)
	if atmosfer:
		atmosfer.iceride = _kulube_ici(oyuncu.global_position)
		atmosfer.araba_gecebilir = durum in ["yuruyus", "kulube", "konusma", "mazgala"]
	_tarif_guncelle()
	match durum:
		"yuruyus": _yuruyus()
		"binis": _binis()
		"surus": _surus(dt)
		"park": _park()
		"inis": _inis()
		"kulube": _kulube()
		"konusma": _konusma()
		"mazgala": _mazgala()
		"kenar": _kenar(dt)
		"dusus": _dusus(dt)
		"karanlik": _karanlik()

func _gec(yeni: String) -> void:
	durum = yeni; dt_durum = 0.0

func _surucu_kapisi() -> Vector3:
	return araba.global_transform * Vector3(-1.45, 0.0, -0.35)

func _yuruyus() -> void:
	# kapı kolunun yanında küçük "E" yazısı; basınca el kapı koluna uzanır
	var kol := araba.global_transform * Vector3(-1.06, 0.95, -0.05)
	if _soylenen.has("kola_uzandi"):
		if dt_durum - float(_soylenen["kola_uzandi"]) > 0.45:
			_soylenen.erase("kola_uzandi")
			eller.birak("sag", 0.4)
			_binise_basla()
		return
	if _e_bak("araba", kol, "Arabaya bin", 2.4, false):
		_ipucu("", 0.0)
		eller.uzan("sag", kol, 0.45)
		_soylenen["kola_uzandi"] = dt_durum

func _binise_basla() -> void:
	_ipucu("", 0.0)
	# Selim'in görünmez gövdesi arabayla taşınır; kolları arabanın içinde görünmesin
	eller.visible = false
	oyuncu.set_physics_process(false); oyuncu.set_process_unhandled_input(false)
	oyuncu.process_mode = Node.PROCESS_MODE_DISABLED
	(oyuncu.get_node("Govde") as CollisionShape3D).disabled = true
	_gecis_bas = oyuncu_kamera.global_transform
	var kam := araba.get_node("Kamera") as Camera3D
	kam.rotation = Vector3(-0.04, 0, 0)
	_gecis_bit = kam.global_transform
	kam.global_transform = _gecis_bas
	kam.current = true
	_gec("binis")

# Selim kapının arkasına geçer, kapı dışa açılır (menteşe önde), açıklıktan girip oturur, kapı kapanır, motor çalışır
func _binis() -> void:
	var kam := araba.get_node("Kamera") as Camera3D
	var kol := araba.global_transform * Vector3(-1.06, 0.95, -0.05)
	# kapının açılırken süpürdüğü yerin dışında, kapının arka ucunda durur
	var dur := Transform3D(Basis(), araba.global_transform * Vector3(-1.6, 1.45, 0.45)).looking_at(kol, Vector3.UP)
	# kapı açıldıktan sonra kapıyla gövde arasındaki açıklık
	var ic := Transform3D(araba.global_basis * Basis.from_euler(Vector3(-0.15, -0.5, 0)), araba.global_transform * Vector3(-1.45, 1.3, -0.35))
	var ara: Transform3D
	if dt_durum < 0.6:
		ara = _gecis_bas.interpolate_with(dur, smoothstep(0.0, 0.6, dt_durum))
	elif dt_durum < 1.9:
		ara = dur.interpolate_with(ic, smoothstep(1.2, 1.9, dt_durum))
	else:
		var u := smoothstep(1.9, 2.7, dt_durum)
		ara = ic.interpolate_with(_gecis_bit, u)
		ara.origin.y -= sin(u * PI) * 0.2
	kam.global_transform = ara
	if dt_durum > 0.6 and not _soylenen.has("kapi_acildi"):
		_soylenen["kapi_acildi"] = true
		araba.kapi("DFL_8", true)
		ses_kapi.global_position = _surucu_kapisi() + Vector3(0, 1, 0); ses_kapi.pitch_scale = 1.3; ses_kapi.volume_db = -10.0; ses_kapi.play()
	if dt_durum > 2.8 and araba._kapi_hedef["DFL_8"] > 0.5:
		araba.kapi("DFL_8", false)
	if dt_durum > 3.35 and not _soylenen.has("kapi_kapandi"):
		_soylenen["kapi_kapandi"] = true
		ses_kapi.global_position = araba.global_position; ses_kapi.pitch_scale = 1.0; ses_kapi.volume_db = 0.0; ses_kapi.play()
	# kontak: marş birkaç kez öksürür, sonra motor tutar
	if dt_durum > 3.8 and not _soylenen.has("mars"):
		_soylenen["mars"] = true
		_kisa_ses(_mars_sesi(), araba.global_position + Vector3(0, 0.8, 0), 1.0, -4.0)
	if dt_durum > 3.8:
		kam.transform = kam.transform.interpolate_with(Transform3D(Basis.from_euler(Vector3(-0.04, 0, 0)), Vector3(-0.45, 1.32, -0.1)), 0.08)
		kam.position += Vector3(randf_range(-1, 1), randf_range(-1, 1), 0) * 0.002 * (1.0 if dt_durum < 5.4 else 0.0)
	if dt_durum > 5.6:
		kam.transform = Transform3D(Basis.from_euler(Vector3(-0.04, 0, 0)), Vector3(-0.45, 1.32, -0.1))
		araba.motoru_calistir(true)
		araba.silecek_acik = true
		araba.surulebilir = true
		ses_yagmur.volume_db = -14.0
		_ipucu("W gaz    S fren / geri    A D direksiyon", 7.0)
		_gec("surus")

func _surus(dt: float) -> void:
	# yağmur arabayla birlikte gelsin diye Selim'in görünmez gövdesi arabayla taşınır
	oyuncu.global_position = araba.global_position
	if absf(araba.hiz) > 1.0: surus_suresi += dt
	if surus_suresi > 4.0 and not _soylenen.has("araba1"): _soyle("araba1")
	if surus_suresi > 15.0 and not _soylenen.has("araba2"): _soyle("araba2")
	var hedef := EV_PARK if eve_donus else KULUBE_PARK
	var kulubeye := Vector2(araba.global_position.x - hedef.x, araba.global_position.z - hedef.z).length()
	if kulubeye < PARK_YARICAP and absf(araba.hiz) < 1.5:
		_ipucu("E  Arabadan in", 0.0)
		if Input.is_action_just_pressed("etkiles"):
			if eve_donus: _eve_var()
			else: _inise_basla()
	elif ipucu.text == "E  Arabadan in":
		_ipucu("", 0.0)
	if kulubeye < 30.0 and not _soylenen.has("kulube_ipucu") and not eve_donus:
		_soylenen["kulube_ipucu"] = true
		_ipucu("Kulübenin önüne park et", 6.0)

func _inise_basla() -> void:
	_ipucu("", 0.0)
	araba.surulebilir = false
	araba.hiz = 0.0
	araba.motoru_calistir(false)
	araba.silecek_acik = false
	_kisa_ses(_kontak_sesi(), araba.global_position + Vector3(0, 0.8, 0), 1.0, -10.0)
	_gec("park")

# motor kapandı: yağmurun tavana vuruşu ve soğuyan motorun tıkırtısı; birkaç saniye sonra kapı açılır
func _park() -> void:
	if dt_durum > 0.6 and not _soylenen.has("park_tik"):
		_soylenen["park_tik"] = true
		for i in 6:
			get_tree().create_timer(0.8 + i * randf_range(0.5, 0.9), false).timeout.connect(func() -> void:
				_kisa_ses(_tik_sesi(), araba.global_position + Vector3(0, 0.6, -1.8), randf_range(0.5, 0.8), -22.0))
	if dt_durum > 1.2 and not _soylenen.has("ic05"): _soyle("ic05")
	if dt_durum < 3.2: return
	araba.kapi("DFL_8", true)
	ses_kapi.global_position = _surucu_kapisi() + Vector3(0, 1, 0); ses_kapi.pitch_scale = 1.3; ses_kapi.volume_db = -10.0; ses_kapi.play()
	var kam := araba.get_node("Kamera") as Camera3D
	_gecis_bas = kam.global_transform
	# Selim kapının yanında, arabaya sırtı dönük durur
	var yer := araba.global_transform * Vector3(-1.9, 0.0, -0.2)
	oyuncu.global_position = Vector3(yer.x, araba.global_position.y + 0.3, yer.z)
	oyuncu.global_rotation = Vector3(0, araba.global_rotation.y + PI * 0.5, 0)
	(oyuncu.get_node("Kafa") as Node3D).rotation = Vector3.ZERO
	_gecis_bit = Transform3D(oyuncu.global_transform.basis, oyuncu.global_position + Vector3(0, oyuncu.BOY, 0))
	ses_yagmur.volume_db = -8.0
	_gec("inis")

func _inis() -> void:
	var kam := araba.get_node("Kamera") as Camera3D
	var u := smoothstep(0.5, 2.2, dt_durum)
	var ara := _gecis_bas.interpolate_with(_gecis_bit, u)
	ara.origin.y -= sin(u * PI) * 0.2
	kam.global_transform = ara
	if dt_durum > 2.3 and araba._kapi_hedef["DFL_8"] > 0.5:
		araba.kapi("DFL_8", false)
		ses_kapi.global_position = araba.global_position; ses_kapi.play()
		oyuncu.process_mode = Node.PROCESS_MODE_INHERIT
		oyuncu.set_physics_process(true); oyuncu.set_process_unhandled_input(true)
		(oyuncu.get_node("Govde") as CollisionShape3D).disabled = false
		oyuncu_kamera.current = true
		eller.visible = true
		var d := get_node_or_null("/root/Duraklat")
		if d: d.kayit_noktasi(scene_file_path, "kulube")
		_gec("kulube")



# ---------------- arayüz ve sesler ----------------
func _arayuz_kur() -> void:
	var cl := CanvasLayer.new(); cl.layer = 10; add_child(cl)
	siyah = ColorRect.new(); siyah.color = Color.BLACK
	siyah.set_anchors_preset(Control.PRESET_FULL_RECT); siyah.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cl.add_child(siyah)
	ipucu = Label.new()
	ipucu.add_theme_font_size_override("font_size", 20)
	ipucu.add_theme_color_override("font_color", Color(0.85, 0.85, 0.8, 0.75))
	ipucu.add_theme_color_override("font_outline_color", Color.BLACK)
	ipucu.add_theme_constant_override("outline_size", 8)
	ipucu.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ipucu.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	ipucu.offset_left = -700; ipucu.offset_right = 700; ipucu.offset_top = -70; ipucu.offset_bottom = -30
	cl.add_child(ipucu)
	altyazi = Label.new()
	altyazi.add_theme_font_size_override("font_size", 34)
	altyazi.add_theme_color_override("font_color", Color(0.95, 0.95, 0.92))
	altyazi.add_theme_color_override("font_outline_color", Color.BLACK)
	altyazi.add_theme_constant_override("outline_size", 10)
	altyazi.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	altyazi.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	altyazi.offset_left = -800; altyazi.offset_right = 800; altyazi.offset_top = -160; altyazi.offset_bottom = -100
	altyazi.visible = false
	cl.add_child(altyazi)
	e_yazi = Label.new()
	e_yazi.add_theme_font_size_override("font_size", 19)
	e_yazi.add_theme_color_override("font_color", Color(0.95, 0.95, 0.92))
	e_yazi.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	e_yazi.add_theme_constant_override("outline_size", 5)
	e_yazi.visible = false
	cl.add_child(e_yazi)
	tarif = Label.new()
	tarif.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	tarif.add_theme_font_size_override("font_size", 20)
	tarif.add_theme_color_override("font_color", Color(0.85, 0.85, 0.8, 0.8))
	tarif.add_theme_color_override("font_outline_color", Color.BLACK)
	tarif.add_theme_constant_override("outline_size", 8)
	tarif.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tarif.set_anchors_preset(Control.PRESET_CENTER_TOP)
	tarif.offset_left = -500; tarif.offset_right = 500; tarif.offset_top = 40; tarif.offset_bottom = 70
	cl.add_child(tarif)
	bodycam = Bodycam.new()
	add_child(bodycam)

var _ipucu_bitis := 0
func _ipucu(metin: String, sure: float) -> void:
	ipucu.text = metin
	if sure > 0.0:
		var bu := Time.get_ticks_msec() + int(sure * 1000.0)
		_ipucu_bitis = bu
		get_tree().create_timer(sure, false).timeout.connect(func() -> void:
			if _ipucu_bitis == bu and ipucu.text == metin: ipucu.text = "")

func _soyle(anahtar: String) -> float:
	_soylenen[anahtar] = true
	var s: Array = SATIRLAR[anahtar]
	var sure: float = 3.0 + str(s[2]).length() * 0.05
	if ResourceLoader.exists(s[0]):
		var akis: AudioStream = load(s[0])
		ses_selim.stream = akis; ses_selim.play()
		sure = akis.get_length() + 0.6
	altyazi.text = tr(s[1]) + ": " + tr(s[2])
	var d := get_node_or_null("/root/Duraklat")
	altyazi.visible = d == null or d.get("altyazi") != false
	_altyazi_bitis = T_simdi() + sure
	return sure

# kapı kapanma ve çarpma sesi: kısa, boğuk bir gümleme
# taş ve beton parçalarıyla kenarın çökmesi
## Ses bir kez üretilir, sonra saklanır (her seferinde yeniden üretmek o karede takılma yapıyordu).
var _cokme_sesi_hazir: AudioStream
func _cokme_sesi() -> AudioStream:
	if _cokme_sesi_hazir == null: _cokme_sesi_hazir = _cokme_sesi_yap()
	return _cokme_sesi_hazir

func _cokme_sesi_yap() -> AudioStream:
	for uz in ["ogg", "mp3", "wav"]:
		if ResourceLoader.exists("res://sesler/cokme." + uz): return load("res://sesler/cokme." + uz)
	var vurus := []
	for i in 14: vurus.append(randf_range(0.0, 1.1))
	return _wav_yap(1.6, func(t: float) -> float:
		var d := (randf() * 2.0 - 1.0) * 0.35 * exp(-t * 2.5)
		for v in vurus:
			var x: float = t - float(v)
			if x >= 0.0: d += (randf() * 2.0 - 1.0) * exp(-x * 45.0) * 0.5
		return d + sin(TAU * 55.0 * t) * exp(-t * 4.0) * 0.5)

# yere çarpma: tok, alçak bir gümbürtü
## Ses bir kez üretilir, sonra saklanır (her seferinde yeniden üretmek o karede takılma yapıyordu).
var _gumbur_sesi_hazir: AudioStream
func _gumbur_sesi() -> AudioStream:
	if _gumbur_sesi_hazir == null: _gumbur_sesi_hazir = _gumbur_sesi_yap()
	return _gumbur_sesi_hazir

func _gumbur_sesi_yap() -> AudioStream:
	for uz in ["ogg", "mp3", "wav"]:
		# carpma.mp3 rüyadaki araba kazası; düşüşün kendi sesi yere_carpma
		if ResourceLoader.exists("res://sesler/yere_carpma." + uz): return load("res://sesler/yere_carpma." + uz)
	return _wav_yap(1.2, func(t: float) -> float:
		return sin(TAU * (70.0 - t * 30.0) * t) * exp(-t * 5.0) * 0.9 + (randf() * 2.0 - 1.0) * exp(-t * 18.0) * 0.5)

# marş motoru: tırtıklı, alçak bir dönme sesi, üç öksürük
func _mars_sesi() -> AudioStream:
	for uz in ["ogg", "mp3", "wav"]:
		if ResourceLoader.exists("res://sesler/mars." + uz): return load("res://sesler/mars." + uz)
	return _wav_yap(1.9, func(t: float) -> float:
		var d := sin(TAU * 14.0 * t) * 0.5 + 0.5
		var mars := (sin(TAU * 220.0 * t + sin(TAU * 14.0 * t) * 2.0) * 0.25 + (randf() * 2.0 - 1.0) * 0.12) * d * smoothstep(1.6, 1.3, t)
		var tutma := (sin(TAU * 38.0 * t) * 0.5 + (randf() * 2.0 - 1.0) * 0.2) * smoothstep(1.25, 1.45, t) * smoothstep(1.9, 1.6, t)
		return (mars + tutma) * 0.8)

# kontak anahtarı çevrilir
func _kontak_sesi() -> AudioStreamWAV:
	return _wav_yap(0.12, func(t: float) -> float: return (randf() * 2.0 - 1.0) * exp(-t * 90.0) * 0.6 + sin(TAU * 1800.0 * t) * exp(-t * 120.0) * 0.2)

## Ses bir kez üretilir, sonra saklanır (her seferinde yeniden üretmek o karede takılma yapıyordu).
var _kapi_sesi_hazir: AudioStreamWAV
func _kapi_sesi() -> AudioStreamWAV:
	if _kapi_sesi_hazir == null: _kapi_sesi_hazir = _kapi_sesi_yap()
	return _kapi_sesi_hazir

func _kapi_sesi_yap() -> AudioStreamWAV:
	var hiz := 22050
	var veri := PackedByteArray(); veri.resize(int(hiz * 0.45) * 2)
	var dusuk := 0.0
	for i in int(hiz * 0.45):
		var t := float(i) / hiz
		dusuk = lerpf(dusuk, randf() * 2.0 - 1.0, 0.08)
		var d := (sin(TAU * 62.0 * t) * 0.7 + dusuk * 1.4) * exp(-t * 14.0) + (randf() * 2.0 - 1.0) * 0.25 * exp(-t * 90.0)
		veri.encode_s16(i * 2, int(clampf(d, -1.0, 1.0) * 30000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS; w.mix_rate = hiz; w.data = veri
	return w


# ---------------- kulübe: telefon çalar, amirle konuşma ----------------
var _telefon: Node3D
var _zil: AudioStreamPlayer3D
# kulübe içi (Kulube düğümünün yerel koordinatları)
const BODYCAM_YERI := Vector3(0.72, 1.14, -1.18)
const OTURAK := Vector3(0.05, 0.0, -0.95)
const KTV_EKRAN := Vector3(0.755, 1.356, -0.55)
const KAPI_MENTESE := Vector3(-1.13, 0.0, -2.04)
# alp'in göndereceği kulübe eşyaları: [dosya, yer, yön, ölçek]; dosya gelince yerine konur
const KULUBE_ESYALARI := [
	["res://modeller2/klübe/bodycam.glb", Vector3(0.72, 1.14, -1.18), 90.0, 1.0],
	["res://modeller2/klübe/kul_tablasi.glb", Vector3(0.8, 1.14, -1.02), 0.0, 1.0],
	["res://modeller2/klübe/termos.glb", Vector3(0.95, 1.14, -0.15), 0.0, 1.0],
	["res://modeller2/klübe/cay_bardagi.glb", Vector3(0.7, 1.14, -0.25), 0.0, 1.0],
	["res://modeller2/klübe/sandalye.glb", Vector3(0.05, 0.0, -0.95), 90.0, 1.0],   # Antarct1c, Sketchfab Standard; önü +z
	["res://modeller2/klübe/aski.glb", Vector3(-1.32, 1.7, -0.6), 90.0, 1.0],
]
const YAGMURLU_CAM := """shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, unshaded;
uniform sampler2D ekran : hint_screen_texture, filter_linear_mipmap;
varying vec3 dunya;
float h(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
void vertex() { dunya = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec2 p = vec2(dunya.x + dunya.z, dunya.y) * 15.0;
	float damla = 0.0;
	vec2 egim = vec2(0.0);
	for (int k = 0; k < 2; k++) {
		vec2 q = p * (1.0 + float(k) * 0.7);
		float sut = floor(q.x);
		float hiz = 0.25 + h(vec2(sut, float(k))) * 0.6;
		q.y += TIME * hiz * (0.4 + float(k) * 0.3);
		vec2 id = floor(q);
		vec2 f = fract(q) - 0.5;
		vec2 c = (vec2(h(id + 2.3), h(id + 7.1)) - 0.5) * 0.5;
		float r = 0.07 + 0.1 * h(id + 4.4);
		float d = length((f - c) * vec2(1.0, 0.75));
		float var_ = step(0.68, h(id + float(k)));
		float m = smoothstep(r, r * 0.4, d) * var_;
		damla = max(damla, m);
		egim += (f - c) * m;
		// arkasında bıraktığı ince iz
		damla = max(damla, smoothstep(0.03, 0.0, abs(f.x - c.x)) * smoothstep(0.0, 0.5, f.y - c.y) * 0.2 * var_);
	}
	// damla arkasındaki görüntüyü kırar: dışarıdaki ışıklar damlanın içinde ters ve küçük görünür
	vec3 arka = textureLod(ekran, SCREEN_UV - egim * 0.06, 1.5).rgb;
	vec3 duz = textureLod(ekran, SCREEN_UV, 0.0).rgb;
	ALBEDO = mix(duz * 0.92, arka * 1.15 + vec3(0.015), damla);
	ALPHA = 1.0;
}
"""
var _adim := 0
var _k_zaman := {}
var _otur_bas := Vector3.ZERO
var _floresan: OmniLight3D
var _floresan_guc := 1.2
var _vizilti: AudioStreamPlayer3D
var _kapi: Node3D
var _kapi_acik: Transform3D
var _kapi_k := 0.0
var _bodycam_model: Node3D
var eller: Eller
var bodycam: Bodycam
var e_yazi: Label
var _konusma_sira := 0
var _satir_bitis := 0.0
var _bakis_bas: Basis

func _kulube() -> void:
	if _telefon == null: _kulube_kur()
	var ic := _kulube_ici(oyuncu.global_position)
	match _adim:
		0:
			if not ic:
				if dt_durum > 1.0 and ipucu.text == "": _ipucu("Kulübeye gir", 0.0)
				return
			_ipucu("", 0.0)
			_adim = 1
			_k_zaman["floresan"] = dt_durum
			_k_zaman["kapi_kapan"] = dt_durum + 1.2
		1:
			# masadaki yaka kamerası
			if _e_bak("bodycam", _k(BODYCAM_YERI), "Yaka kamerasını tak", 1.7):
				_adim = 2
				_k_zaman["bodycam"] = dt_durum
				get_tree().create_timer(2.6, false).timeout.connect(func() -> void: if not _soylenen.has("ic06"): _soyle("ic06"))
				eller.uzan("sag", _k(BODYCAM_YERI) + Vector3(0, 0.05, 0), 0.7)
		2:
			var t := dt_durum - float(_k_zaman["bodycam"])
			if t > 0.8 and not _soylenen.has("bc_gogus"):
				_soylenen["bc_gogus"] = true
				eller.kamerada("sag", Vector3(0.12, -0.42, -0.12), 0.6)
				if _bodycam_model: _bodycam_model.visible = false
			if t > 1.5 and not bodycam.acik:
				eller.birak("sag", 0.6)
				bodycam.ac(23.0 * 3600.0 + 41.0 * 60.0 + 12.0)
				_kisa_ses(_bip(), oyuncu.global_position + Vector3(0, 1.2, 0), 1.0, -8.0)
			if t > 2.4: _adim = 3
		3:
			if _e_bak("otur", _k(OTURAK) + Vector3(0, 0.6, 0), "Otur", 2.2):
				_adim = 4
				_oyuncuyu_dondur(true)
				_bakis_bas = oyuncu_kamera.global_basis
				_k_zaman["otur"] = dt_durum
				_otur_bas = oyuncu_kamera.global_position
		4:
			# oturunca önce bir sigara yakar, sonra TV'ye bakıp bekler
			var t := dt_durum - float(_k_zaman["otur"])
			if t < SIGARA_BAS or _sigara == null:
				_bekleme(t)
				return
			if not _soylenen.has("sigara_kur"):
				_soylenen["sigara_kur"] = true
				_sigara.kur(oyuncu_kamera, eller, _sigara_paketi.global_position if _sigara_paketi else _k(SIGARA_PAKETI_YERI))
			if not _sigara.oynat(t - SIGARA_BAS): return
			_bekleme(t - Sigara.SURE)
		6:
			_vardiya_bitti(dt_durum - float(_k_zaman["vardiya"]))
		5:
			# telefon çalıyor; oturduğu yerden açar
			if _e_bak("telefon", _telefon.global_position + Vector3(0, 0.05, 0), "Telefonu aç", 2.0, false):
				_soylenen["cevap"] = true
				_zil.stop()
				eller.uzan("sol", _telefon.global_position + Vector3(0, 0.06, 0), 0.5)
				_bakis_bas = oyuncu_kamera.global_basis
				_konusma_sira = 0; _satir_bitis = T_simdi() + 0.8
				_kisa_ses(_kapi_sesi(), _telefon.global_position, 2.2, -12.0)
				_gec("konusma")


func _gece() -> int:
	var d := get_node_or_null("/root/Duraklat")
	return int(d.gece) if d else 2


## 1. gece: uzun bir uyuklama, gözler açıldığında saat sabaha dayanmış; hiçbir şey olmamıştır.
## Selim kalkar, arabasına dönüp eve gider.
func _vardiya_bitti(v: float) -> void:
	siyah.modulate.a = smoothstep(0.0, 1.8, v) * (1.0 - smoothstep(4.0, 5.6, v))
	if v > 2.0 and not _soylenen.has("sabah"):
		_soylenen["sabah"] = true
		bodycam.saat_ilerlet(5.0 * 3600.0)
		_kanal_degistir("kar")
	if v > 6.0 and not _soylenen.has("ic09"): _soyle("ic09")
	if v > 10.0 and not _soylenen.has("ic10"): _soyle("ic10")
	if v > 12.5 and not _soylenen.has("kalkti"):
		_soylenen["kalkti"] = true
		siyah.modulate.a = 0.6
		var kapi := _k(KAPI_MENTESE + Vector3(0.5, 0, 0))
		oyuncu.global_rotation.y = atan2(-(kapi.x - oyuncu.global_position.x), -(kapi.z - oyuncu.global_position.z))
		(oyuncu.get_node("Kafa") as Node3D).rotation = Vector3.ZERO
		oyuncu_kamera.transform = Transform3D.IDENTITY
		_oyuncuyu_dondur(false)
		eve_donus = true
		_k_zaman.erase("kapi_kapan")   # kulübenin kapısı açılır
		_soylenen.erase("kola_uzandi")
		for a in ["kapi_acildi", "kapi_kapandi", "mars"]: _soylenen.erase(a)   # eve dönüşte araba kapısı yine açılsın
		_ipucu("Arabana dön", 0.0)
		_rota_i = 0
		_gec("yuruyus")
		_bodycam_birak()


## 1. gece kulübeden çıkarken yaka kamerasını çıkarıp masaya bırakır; kayıt kapanır.
## 2. gece takıp öyle gider.
func _bodycam_birak() -> void:
	eller.kamerada("sag", Vector3(0.12, -0.42, -0.12), 0.6)
	get_tree().create_timer(0.7, false).timeout.connect(func() -> void:
		eller.uzan("sag", _k(BODYCAM_YERI) + Vector3(0, 0.05, 0), 0.7))
	get_tree().create_timer(1.3, false).timeout.connect(func() -> void:
		if _bodycam_model: _bodycam_model.visible = true
		_kisa_ses(_bip(), oyuncu.global_position + Vector3(0, 1.2, 0), 0.8, -8.0)
		if bodycam and bodycam.acik: bodycam.kapat())
	get_tree().create_timer(1.9, false).timeout.connect(func() -> void: eller.birak("sag", 0.6))


## Eve varınca: ekran kararır, ev sahnesi 2. gecenin rüyasıyla başlar.
func _eve_var() -> void:
	_ipucu("", 0.0)
	araba.surulebilir = false
	araba.hiz = 0.0
	araba.motoru_calistir(false)
	araba.silecek_acik = false
	_kisa_ses(_kontak_sesi(), araba.global_position + Vector3(0, 0.8, 0), 1.0, -10.0)
	_gec("eve_varis")
	var tw := create_tween()
	tw.tween_property(siyah, "modulate:a", 1.0, 2.5)
	tw.tween_callback(func() -> void:
		var d := get_node_or_null("/root/Duraklat")
		if d == null:
			get_tree().change_scene_to_file("res://sahneler/ev.tscn")
			return
		d.gece = 2
		d.kayit_noktasi("res://sahneler/ev.tscn", "ruya")
		d.baslangic_noktasi = "ruya"
		d.yukle("res://sahneler/ev.tscn", ""))


## Kulübenin kendi yerel noktasını dünyaya çevirir.
func _k(yerel: Vector3) -> Vector3:
	return $Kulube.global_transform * yerel


func _kulube_ici(p: Vector3) -> bool:
	var y: Vector3 = $Kulube.global_transform.affine_inverse() * p
	return y.x > -1.3 and y.x < 1.35 and y.z > -2.0 and y.z < 0.05


## Bakılan eşyanın üstünde küçük "E" ve kısa yazı. E'ye basıldıysa true.
func _e_bak(ad: String, nokta: Vector3, metin: String, menzil: float, bakmali := true) -> bool:
	var kam := get_viewport().get_camera_3d()
	var d := nokta - kam.global_position
	var bak := -kam.global_basis.z
	var yakin := d.length() < menzil and (not bakmali or bak.dot(d.normalized()) > lerpf(0.8, 0.93, clampf((d.length() - 0.8) / 1.2, 0.0, 1.0)))
	if not yakin:
		if e_yazi.get_meta("ad", "") == ad: e_yazi.visible = false
		return false
	e_yazi.set_meta("ad", ad)
	e_yazi.text = "E  " + tr(metin)
	e_yazi.visible = true
	e_yazi.reset_size()
	var ekran := get_viewport().get_visible_rect().size
	var yer := kam.unproject_position(nokta) - Vector2(16, e_yazi.size.y * 0.5)
	if kam.is_position_behind(nokta): yer = ekran * 0.5
	e_yazi.position = yer.clamp(Vector2(60, 60), ekran - e_yazi.size - Vector2(60, 60))
	if Input.is_action_just_pressed("etkiles"):
		e_yazi.visible = false
		return true
	return false


## Oturup TV'ye bakar; kanal kendiliğinden değişir, göz kapakları ağırlaşır, saat akar. Sonunda telefon çalar.
func _bekleme(t: float) -> void:
	var goz := _k(OTURAK) + Vector3(0, 1.22, 0)
	var ekran := _k(KTV_EKRAN)
	var k := smoothstep(0.0, 1.6, t)
	oyuncu_kamera.global_position = _otur_bas.lerp(goz, k)
	var hedef := Basis.looking_at(ekran + Vector3(0, -0.05, 0) - oyuncu_kamera.global_position)
	oyuncu_kamera.global_basis = _bakis_bas.slerp(hedef, k).orthonormalized()
	if t > 0.6 and not _soylenen.has("sandalye"):
		_soylenen["sandalye"] = true
		_kisa_ses(_kapi_sesi(), goz + Vector3(0, -0.9, 0), 0.7, -14.0)
	# TV kanalları: [zaman, kanal]
	for c in [[2.0, "kar"], [2.4, "cubuk"], [8.5, "kar"], [8.8, "foto1"], [14.5, "kar"], [14.8, "foto3"], [20.5, "kar"], [20.9, "oda"], [27.0, "kar"]]:
		if t >= float(c[0]) and not _soylenen.has("kanal%.1f" % c[0]):
			_soylenen["kanal%.1f" % c[0]] = true
			_kanal_degistir(c[1])
	# ağır göz kapakları: üç kez kapanır, her açılışta saat ileri sarılmış olur
	var kapak := 0.0
	for g in [[10.5, 12.3], [16.5, 18.6], [23.0, 25.2]]:
		var a := float(g[0]); var b := float(g[1])
		if t > a and t < b:
			kapak = smoothstep(a, a + 0.9, t) * (1.0 - smoothstep(b - 0.5, b, t))
		if t > a + 0.9 and not _soylenen.has("uyuklama%.1f" % a):
			_soylenen["uyuklama%.1f" % a] = true
			bodycam.saat_ilerlet(randf_range(9.0, 14.0) * 60.0)
	siyah.modulate.a = kapak
	if t > 28.0 and _gece() == 1:
		# 1. gece telefon çalmaz: Selim uyuklar, uyandığında sabah olmuştur
		_adim = 6
		_k_zaman["vardiya"] = dt_durum
		return
	if t > 28.0 and not _zil.playing and not _soylenen.has("cevap"):
		_zil.play()
		bodycam.bozul(0.6, 0.4)
		_adim = 5


func _kulube_kur() -> void:
	_telefon = $Kulube/Telefon
	_zil = AudioStreamPlayer3D.new(); _zil.stream = _zil_sesi(); _zil.unit_size = 3.0; _zil.max_db = 3.0
	_telefon.add_child(_zil)
	# camlar: üstünden yağmur damlaları süzülür
	var cam := ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = YAGMURLU_CAM
	cam.shader = sh
	for m in $Kulube.find_children("*", "MeshInstance3D", true, false):
		var mi := m as MeshInstance3D
		if mi.mesh == null: continue
		for i in mi.mesh.get_surface_count():
			var mat := mi.mesh.surface_get_material(i)
			if mat and "glass" in mat.resource_name.to_lower():
				mi.set_surface_override_material(i, cam)
	# floresan: girince çakıp yanar, vızıldar
	_floresan = $Kulube/Ampul as OmniLight3D
	_floresan_guc = _floresan.light_energy
	_floresan.light_color = Color(0.88, 0.95, 1.0)
	_floresan.light_energy = 0.0
	_vizilti = AudioStreamPlayer3D.new(); _vizilti.stream = _vizilti_sesi(); _vizilti.unit_size = 1.5; _vizilti.volume_db = -20.0
	_floresan.add_child(_vizilti)
	# kapı: modelde açık durur; menteşesinin çevresinde döner
	_kapi = $Kulube/Bina.find_child("Door", true, false) as Node3D
	if _kapi: _kapi_acik = _kapi.global_transform
	_ktv_kur()
	# alp'in göndereceği eşyalar: dosyası varsa yerine konur
	for e in KULUBE_ESYALARI:
		var yol: String = e[0]
		# sandalye alp'te indirildiği adıyla da durabilir
		if not ResourceLoader.exists(yol) and yol.get_file() == "sandalye.glb":
			yol = yol.get_base_dir() + "/game-ready_folding_chair.glb"
			if not ResourceLoader.exists(yol): yol = "res://modeller2/game-ready_folding_chair.glb"
		if not ResourceLoader.exists(yol): continue
		var n: Node3D = (load(yol) as PackedScene).instantiate()
		$Kulube.add_child(n)
		n.position = e[1]; n.rotation_degrees.y = e[2]; n.scale = Vector3.ONE * float(e[3])
		if str(e[0]).get_file().begins_with("bodycam"): _bodycam_model = n
		if str(e[0]).get_file().begins_with("kul_tablasi"): _duman_kur(n.global_position + Vector3(0, 0.03, 0))
	# masada sigara paketi; Selim oturunca bir tane yakar
	_sigara_paketi = _model_koy(SIGARA_PAKETI, [], 0.0, SIGARA_PAKETI_YERI, 25.0)
	if _sigara == null:
		_sigara = Sigara.new()
		add_child(_sigara)
	# alp'in modeller2/modeller2'ye attığı eşyalar: masada yaka kamerası, termos ve çay bardağı
	if _bodycam_model == null: _bodycam_model = _model_koy(YENI_MODELLER + "vintage_camera.glb", [], 0.0, BODYCAM_YERI, 90.0)
	_model_koy(YENI_MODELLER + "rusty_canister_and_thermos.glb", ["Thermos_001_ThermosTX_001_0"], 0.30, Vector3(0.95, 1.14, -0.15), 0.0)
	_model_koy(YENI_MODELLER + "coffee__tea_mugs_free (1).glb", ["Cups_Cup3_0", "Cups_Tea_0", "Cups_Tea Bag_0"], 0.10, Vector3(0.72, 1.14, -0.22), 30.0)
	if eller == null:
		eller = Eller.new()
		oyuncu_kamera.add_child(eller)
	_fener_m = _masa_esyasi(FENER_MODEL, FENER_BOY, FENER_YERI, FENER_DONUS)
	_pil_m = _masa_esyasi(PIL_MODEL, PIL_BOY, PIL_YERI, PIL_DONUS)
	_cizelge_kur()


const YENI_MODELLER := "res://modeller2/modeller2/"
const Sigara := preload("res://kod/sigara.gd")
const SIGARA_PAKETI := "res://modeller2/seliminevi/sigara/sigara_paketi.gltf"
const SIGARA_PAKETI_YERI := Vector3(0.62, 1.14, -0.62)
const SIGARA_BAS := 2.0     # oturduktan kaç saniye sonra
var _sigara: Node3D
var _sigara_paketi: Node3D

## Kulübeye dik duran eşya: modelin yalnızca `parcalar` adlı yüzeyleri kalır (boşsa hepsi), boyu `boy`
## metre olur (0 ise modelin kendi ölçüsü), alt yüzünün ortası kulübedeki `yer`e oturur.
func _model_koy(yol: String, parcalar: Array, boy: float, yer: Vector3, aci: float) -> Node3D:
	if not ResourceLoader.exists(yol): return null
	var paket := load(yol) as PackedScene
	if paket == null: return null
	var kap := Node3D.new()
	kap.name = yol.get_file().get_basename()
	$Kulube.add_child(kap)
	var n: Node3D = paket.instantiate()
	kap.add_child(n)
	var a := AABB(); var ilk := true
	for m in n.find_children("*", "MeshInstance3D", true, false):
		var mi := m as MeshInstance3D
		if not parcalar.is_empty() and not (str(mi.name) in parcalar):
			mi.queue_free()
			continue
		var b: AABB = n.global_transform.affine_inverse() * mi.global_transform * mi.get_aabb()
		a = b if ilk else a.merge(b); ilk = false
	var o := boy / maxf(a.size.y, 0.001) if boy > 0.0 else 1.0
	n.scale = Vector3.ONE * o
	n.position = -Vector3(a.get_center().x, a.position.y, a.get_center().z) * o
	kap.position = yer
	kap.rotation_degrees.y = aci
	return kap


## Masaya konan eşya: modelin en uzun ekseni düğümün Z eksenine çevrilir, ortası düğümün merkezine
## gelir, boyu `boy` metre olur. Düğüm masada `donus` ile yatar.
func _masa_esyasi(yol: String, boy: float, yer: Vector3, donus: Vector3) -> Node3D:
	if not ResourceLoader.exists(yol): return null
	var kap := Node3D.new()
	$Kulube.add_child(kap)
	var n: Node3D = (load(yol) as PackedScene).instantiate()
	kap.add_child(n)
	var a := AABB(); var ilk := true
	for m in n.find_children("*", "MeshInstance3D", true, false):
		var mi := m as MeshInstance3D
		var b: AABB = n.global_transform.affine_inverse() * mi.global_transform * mi.get_aabb()
		a = b if ilk else a.merge(b); ilk = false
	var o := boy / maxf(a.get_longest_axis_size(), 0.001)
	var don := Basis.IDENTITY
	match a.get_longest_axis_index():
		Vector3.AXIS_X: don = Basis(Vector3.UP, -PI * 0.5)
		Vector3.AXIS_Y: don = Basis(Vector3.RIGHT, PI * 0.5)
	n.transform = Transform3D(don.scaled(Vector3.ONE * o), -(don * a.get_center()) * o)
	kap.rotation_degrees = donus
	# masanın üstüne oturur: alt yüzü masa hizasına gelir
	kap.position = yer
	var alt := 1e9
	for m in n.find_children("*", "MeshInstance3D", true, false):
		var mi := m as MeshInstance3D
		var b: AABB = mi.global_transform * mi.get_aabb()
		alt = minf(alt, b.position.y)
	kap.global_position.y += _k(yer).y - alt
	return kap


# arka duvarda nöbet çizelgesi: bu gecenin satırında Selim'in adı
func _cizelge_kur() -> void:
	var koyu := Color(0.12, 0.11, 0.1)
	var satirlar := [
		["FEN İŞLERİ MÜDÜRLÜĞÜ", 26, koyu, 1],
		["KULÜBE 07 · NÖBET ÇİZELGESİ · EKİM 2026", 20, koyu, 1],
		["", 10, koyu, 0],
		["TARİH      GÜNDÜZ        GECE (00-08)", 19, koyu, 0],
		["----------------------------------------", 19, koyu, 0],
		["10.10      Murat K.      Hasan T.", 19, koyu, 0],
		["11.10      Yusuf A.      Murat K.", 19, koyu, 0],
		["12.10      Hasan T.      Yusuf A.", 19, koyu, 0],
		["13.10      Murat K.      Hasan T.", 19, koyu, 0],
		["14.10      Yusuf A.      SELİM", 19, Color(0.55, 0.08, 0.06), 0],
		["15.10      Hasan T.      SELİM", 19, koyu, 0],
		["16.10      Murat K.      SELİM", 19, koyu, 0],
		["", 10, koyu, 0],
		["Nöbetçi kulübeden ayrılmaz.", 18, koyu, 0],
		["Arızalar telsizle / telefonla bildirilir.", 18, koyu, 0],
		["", 14, koyu, 0],
		["yine mi ben?", 22, Color(0.1, 0.14, 0.45), 2, true],
	]
	var doku := Kagit.yazi_dokusu(self, Vector2i(560, 720), Color(0.86, 0.83, 0.74), satirlar)
	var duvar := ($Kulube as Node3D).global_basis * Vector3(0, 0, -1)
	Kagit.yapistir(self, doku, _k(Vector3(0.55, 1.45, -1.98)), Vector2(0.32, 0.41), duvar, 0.03)


# kulübeye girerken ıslak ayakkabıların bıraktığı izler
func _ayak_izi() -> void:
	if _iz_sayi >= 16 or not _kulube_ici(oyuncu.global_position): return
	var p := oyuncu.global_position
	if Vector2(p.x - _iz_son.x, p.z - _iz_son.z).length() < 0.34: return
	var yon := Vector3(p.x - _iz_son.x, 0, p.z - _iz_son.z).normalized() if _iz_son.x < 1e8 else -oyuncu.global_basis.z
	_iz_son = p
	var q := PhysicsRayQueryParameters3D.create(p + Vector3(0, 0.8, 0), p + Vector3(0, -1.5, 0))
	q.exclude = [oyuncu.get_rid()]
	var r := get_world_3d().direct_space_state.intersect_ray(q)
	if r.is_empty(): return
	_iz_sayi += 1
	_iz_sol = not _iz_sol
	var yan := yon.cross(Vector3.UP).normalized() * (0.09 if _iz_sol else -0.09)
	var d := Kagit.yapistir(self, Kagit.iz_dokusu(), (r.position as Vector3) + yan, Vector2(0.11, 0.28), Vector3.DOWN, 0.0, 0.2)
	d.global_basis = Basis(Vector3.UP.cross(-yon).normalized(), Vector3.UP, -yon)
	# izler yavaşça kurur
	var tw := create_tween()
	tw.tween_interval(40.0)
	tw.tween_property(d, "modulate:a", 0.0, 50.0)


## Kapıyı kapatır (k=1) ya da açar (k=0).
func _kapi_dondur(k: float) -> void:
	if _kapi == null: return
	var h := _k(KAPI_MENTESE)
	var don := Transform3D(Basis(Vector3.UP, -PI * 0.5 * k), Vector3.ZERO)
	_kapi.global_transform = Transform3D(Basis(), h) * don * Transform3D(Basis(), -h) * _kapi_acik


func _kulube_guncelle(dt: float) -> void:
	if durum == "kulube" and _adim <= 3: _ayak_izi()
	if _floresan == null: return
	if _k_zaman.has("floresan"):
		var t := dt_durum - float(_k_zaman["floresan"]) if durum == "kulube" else 99.0
		if t < 1.6:
			_floresan.light_energy = _floresan_guc if fmod(t * 5.3 + sin(t * 19.0) * 0.4, 1.0) > 0.62 else 0.03
			if not _soylenen.has("floresan_tik"):
				_soylenen["floresan_tik"] = true
				_kisa_ses(_tik_sesi(), _floresan.global_position, 1.0, -6.0)
		else:
			_floresan.light_energy = _floresan_guc * (0.97 + 0.03 * sin(T_simdi() * 100.0))
			if not _vizilti.playing: _vizilti.play()
	# kapı: içeri girince arkadan kapanır, konuşma bitince açılır
	var hedef := 1.0 if (_k_zaman.has("kapi_kapan") and dt_durum >= float(_k_zaman["kapi_kapan"]) and durum == "kulube") or durum == "konusma" else _kapi_k
	if durum == "mazgala" or (eve_donus and durum == "yuruyus"): hedef = 0.0
	if not is_equal_approx(_kapi_k, hedef):
		var once := _kapi_k
		_kapi_k = move_toward(_kapi_k, hedef, dt * 1.2)
		_kapi_dondur(smoothstep(0.0, 1.0, _kapi_k))
		if once == 0.0 or once == 1.0:
			# açılış: alp'in kapı sesi (sesler/kapi_ac.mp3); kapanış: kısa vuruş
			if hedef < 0.5 and ResourceLoader.exists("res://sesler/kapi_ac.mp3"): _kisa_ses(load("res://sesler/kapi_ac.mp3"), _k(KAPI_MENTESE) + Vector3(0, 1, 0), 1.0, -6.0)
			else: _kisa_ses(_kapi_sesi(), _k(KAPI_MENTESE) + Vector3(0, 1, 0), 1.6 if hedef < 0.5 else 1.0, -10.0)
	if _ktv_vp: _ktv_guncelle(dt)
	if _vizilti and durum in ["mazgala", "kenar", "dusus", "karanlik"]:
		_vizilti.volume_db = move_toward(_vizilti.volume_db, -60.0, dt * 10.0)


# ---------------- kulübedeki TV: kanallar kendiliğinden değişir ----------------
var _ktv_vp: SubViewport
var _ktv_foto: TextureRect
var _ktv_cubuk: Control
var _ktv_kar: ColorRect
var _ktv_kamera: Camera3D
var _ktv_kanal := "kapali"
var _ktv_ses: AudioStreamPlayer3D

func _ktv_kur() -> void:
	_ktv_vp = SubViewport.new()
	_ktv_vp.size = Vector2i(320, 240)
	_ktv_vp.render_target_update_mode = SubViewport.UPDATE_ONCE   # kapalıyken bir kez çizilir, sonra durur
	add_child(_ktv_vp)
	var zemin := ColorRect.new(); zemin.color = Color(0.02, 0.02, 0.03); zemin.size = Vector2(320, 240)
	_ktv_vp.add_child(zemin)
	_ktv_foto = TextureRect.new()
	_ktv_foto.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_ktv_foto.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_ktv_foto.size = Vector2(320, 240)
	_ktv_vp.add_child(_ktv_foto)
	_ktv_cubuk = Control.new(); _ktv_cubuk.size = Vector2(320, 240)
	var renkler := [Color("c0c0c0"), Color("c0c000"), Color("00c0c0"), Color("00c000"), Color("c000c0"), Color("c00000"), Color("0000c0")]
	for i in 7:
		var r := ColorRect.new(); r.color = renkler[i]
		r.position = Vector2(i * 320.0 / 7.0, 0); r.size = Vector2(320.0 / 7.0 + 1.0, 165)
		_ktv_cubuk.add_child(r)
	var l := Label.new(); l.text = "GECE KUŞAĞI · KAMU YAYINI"
	l.add_theme_font_size_override("font_size", 15)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.size = Vector2(320, 30); l.position = Vector2(0, 190)
	_ktv_cubuk.add_child(l)
	_ktv_vp.add_child(_ktv_cubuk)
	_ktv_kamera = Camera3D.new(); _ktv_kamera.fov = 70.0
	_ktv_vp.add_child(_ktv_kamera)
	_ktv_kamera.current = false
	_ktv_kar = ColorRect.new(); _ktv_kar.size = Vector2(320, 240)
	var sm := ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = """shader_type canvas_item;
uniform float zaman = 0.0;
uniform float kar = 1.0;
float h(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
void fragment() {
	float n = h(floor(UV * vec2(160.0, 120.0)) + fract(zaman * 17.0) * 37.0);
	float s = 0.8 + 0.2 * step(0.5, fract(UV.y * 120.0));
	COLOR = vec4(vec3(n * s), kar);
}
"""
	sm.shader = sh
	_ktv_kar.material = sm
	_ktv_vp.add_child(_ktv_kar)
	var ekran := $Kulube/TV.find_child("Cube_CRTScreen_0", true, false) as MeshInstance3D
	if ekran:
		var em := StandardMaterial3D.new()
		em.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		em.albedo_texture = _ktv_vp.get_texture()
		ekran.material_override = em
	_ktv_ses = AudioStreamPlayer3D.new(); _ktv_ses.unit_size = 1.5; _ktv_ses.volume_db = -14.0
	_ktv_ses.stream = _kar_sesi()
	$Kulube/TV.add_child(_ktv_ses)
	_kanal_degistir("kapali")


func _kanal_degistir(kanal: String) -> void:
	if kanal == "foto1" and not _soylenen.has("ic07"):
		get_tree().create_timer(1.0, false).timeout.connect(func() -> void: _soyle("ic07"))
		_soylenen["ic07"] = true
	_ktv_kanal = kanal
	_ktv_vp.render_target_update_mode = SubViewport.UPDATE_ONCE if kanal == "kapali" else SubViewport.UPDATE_ALWAYS
	_ktv_foto.visible = kanal.begins_with("foto")
	_ktv_cubuk.visible = kanal == "cubuk"
	_ktv_kar.visible = kanal == "kar"
	_ktv_kamera.current = kanal == "oda"
	if kanal.begins_with("foto") and ResourceLoader.exists("res://tv/%s.jpg" % kanal):
		_ktv_foto.texture = load("res://tv/%s.jpg" % kanal)
	if kanal == "oda":
		# kanal, kulübeyi dışarıdan gösteren bir kameraya geçer
		_ktv_kamera.global_position = _k(Vector3(-3.5, 2.6, 2.6))
		_ktv_kamera.look_at(_k(OTURAK) + Vector3(0, 1.0, 0), Vector3.UP)
	if kanal == "kar":
		_ktv_ses.play()
		_kisa_ses(_tik_sesi(), _k(KTV_EKRAN), 0.7, -10.0)
	elif kanal != "kapali":
		_ktv_ses.stop()
		bodycam.bozul(0.3, 0.15)


func _ktv_guncelle(_dt: float) -> void:
	(_ktv_kar.material as ShaderMaterial).set_shader_parameter("zaman", T_simdi())
	if _ktv_kanal.begins_with("foto"):
		_ktv_foto.scale = Vector2.ONE * (1.0 + fmod(T_simdi(), 6.0) * 0.015)
	if _ktv_kanal == "oda":
		_ktv_kamera.global_position += Vector3(0.02, 0, 0.01) * _dt


func _duman_kur(yer: Vector3) -> void:
	var d := GPUParticles3D.new()
	d.amount = 40
	d.lifetime = 4.0
	d.position = yer
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0, 1, 0); pm.spread = 8.0
	pm.initial_velocity_min = 0.05; pm.initial_velocity_max = 0.1
	pm.gravity = Vector3(0.01, 0.04, 0)
	pm.turbulence_enabled = true; pm.turbulence_noise_strength = 0.4; pm.turbulence_noise_scale = 3.0
	pm.scale_min = 0.3; pm.scale_max = 1.0
	d.process_material = pm
	var q := QuadMesh.new(); q.size = Vector2(0.12, 0.12)
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.albedo_color = Color(0.8, 0.8, 0.82, 0.05)
	q.material = mat
	d.draw_pass_1 = q
	add_child(d)
	d.global_position = yer


func _tik_sesi() -> AudioStreamWAV:
	return _wav_yap(0.05, func(t: float) -> float: return (randf() * 2.0 - 1.0) * exp(-t * 160.0))


func _bip() -> AudioStreamWAV:
	return _wav_yap(0.25, func(t: float) -> float: return sin(TAU * 2600.0 * t) * 0.3 * (1.0 if t < 0.12 else 0.0))


func _kar_sesi() -> AudioStreamWAV:
	var w := _wav_yap(1.0, func(_t: float) -> float: return (randf() * 2.0 - 1.0) * 0.35)
	w.loop_mode = AudioStreamWAV.LOOP_FORWARD; w.loop_end = 22050
	return w


func _vizilti_sesi() -> AudioStream:
	if ResourceLoader.exists("res://sesler/floresan.mp3"):
		var a: AudioStream = load("res://sesler/floresan.mp3")
		if a is AudioStreamMP3: (a as AudioStreamMP3).loop = true
		return a
	var w := _wav_yap(1.0, func(t: float) -> float: return sin(TAU * 100.0 * t) * 0.3 + sin(TAU * 200.0 * t) * 0.12 + sin(TAU * 300.0 * t) * 0.05)
	w.loop_mode = AudioStreamWAV.LOOP_FORWARD; w.loop_end = 22050
	return w


func _wav_yap(sure: float, f: Callable) -> AudioStreamWAV:
	var hiz := 22050
	var veri := PackedByteArray(); veri.resize(int(hiz * sure) * 2)
	for i in int(hiz * sure):
		veri.encode_s16(i * 2, int(clampf(float(f.call(float(i) / hiz)), -1.0, 1.0) * 30000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS; w.mix_rate = hiz; w.data = veri
	return w


func _konusma() -> void:
	# kamera ahizeye ve masaya doğru bakar
	var hedef := Basis.looking_at(_telefon.global_position + Vector3(0, -0.1, 0) - oyuncu_kamera.global_position)
	oyuncu_kamera.global_basis = _bakis_bas.slerp(hedef, smoothstep(0.0, 1.0, dt_durum)).orthonormalized()
	# ahizeyi kulağına götürür
	if dt_durum > 0.6 and not _soylenen.has("ahize"):
		_soylenen["ahize"] = true
		eller.kamerada("sol", Vector3(-0.13, -0.04, -0.06), 0.6)
		eller.yumruk("sol", 0.6)
	if dt_durum < 1.0: return
	if T_simdi() >= _satir_bitis:
		if _konusma_sira >= KONUSMA.size():
			_kisa_ses(_kapi_sesi(), _telefon.global_position, 2.4, -12.0)
			eller.birak("sol", 0.6)
			# ayağa kalkar: kamera yeniden Selim'in başına bağlanır, kapıya döner
			siyah.modulate.a = 0.6
			var kapi := _k(KAPI_MENTESE + Vector3(0.5, 0, 0))
			oyuncu.global_rotation.y = atan2(-(kapi.x - oyuncu.global_position.x), -(kapi.z - oyuncu.global_position.z))
			(oyuncu.get_node("Kafa") as Node3D).rotation = Vector3.ZERO
			oyuncu_kamera.transform = Transform3D.IDENTITY
			_oyuncuyu_dondur(false)
			_ipucu(GOREV_MAZGAL, 0.0)
			get_tree().create_timer(1.0, false).timeout.connect(func() -> void: if not _soylenen.has("ic08"): _soyle("ic08"))
			_gec("mazgala")
			return
		_satir_bitis = T_simdi() + _soyle(KONUSMA[_konusma_sira]) + 0.3
		_konusma_sira += 1

## Oyun saati: Esc ile duraklatınca durur (gerçek saat dursaydı konuşmalar duraklamada ilerliyordu).
var _oyun_saati := 0.0
func T_simdi() -> float:
	return _oyun_saati

func _oyuncuyu_dondur(dur: bool) -> void:
	oyuncu.set_physics_process(not dur)
	oyuncu.set_process_unhandled_input(not dur)
	if dur: oyuncu.velocity = Vector3.ZERO


# ---------------- mazgal: fener ve pil, lambalar söner, eğilip bakar, itilir, düşüş ----------------
var _kenar_lamba: SpotLight3D
var _kenar_enerji := 0.0
var _titreme := 0.0
var _dusus_bas: Transform3D
var _ugultu: AudioStreamPlayer
var _ugultu_gen: AudioStreamGeneratorPlayback
var _ugultu_guc := 0.0
var _ugultu_faz := 0.0

# kulübenin masasındaki fener ve pil (alp'in modelleri)
const FENER_MODEL := "res://modeller2/el feneri ve pil/flashlight.glb"
const PIL_MODEL := "res://modeller2/el feneri ve pil/simple_battery (1).glb"
const FENER_BOY := 0.22
const PIL_BOY := 0.06
const FENER_YERI := Vector3(0.66, 1.14, -0.3)
const FENER_DONUS := Vector3(0, 70, 0)
const PIL_YERI := Vector3(0.64, 1.14, -0.8)
const PIL_DONUS := Vector3(0, 0, 0)
# fener elde: kamera uzayında duruşu
const FENER_ELDE := Vector3(0.16, -0.2, -0.45)
const GOREV_MAZGAL := "Mazgalı kontrol et"
var _fener_m: Node3D
var _pil_m: Node3D
var _alim := {}
var _fener_tutuldu := false
var _pil_takildi := false
var _sonen := []          # [lamba, başlangıç]
var _sonraki_sonme := 1.0
var _egil_bas := Vector3.ZERO

## Kısa süreli yazı; süre dolunca o anki görev yazısı geri gelir.
func _gecici_ipucu(metin: String, sure: float) -> void:
	var gorev := GOREV_MAZGAL if durum == "mazgala" else ""
	ipucu.text = metin
	var bu := Time.get_ticks_msec() + int(sure * 1000.0)
	_ipucu_bitis = bu
	get_tree().create_timer(sure, false).timeout.connect(func() -> void:
		if _ipucu_bitis == bu and ipucu.text == metin: ipucu.text = gorev if durum == "mazgala" else "")

func _mazgala() -> void:
	_sonmeler(get_process_delta_time())
	_fener_pil()
	var yatay := Vector2(oyuncu.global_position.x - MAZGAL.x, oyuncu.global_position.z - MAZGAL.z).length()
	if yatay < 9.0 and not _soylenen.has("mirilti"): _soyle("mirilti")
	if yatay < 2.4 and _e_bak("mazgal", MAZGAL, "Mazgala bak", 2.8):
		# bu andan sonra oyuncunun kontrolü yok
		_ipucu("", 0.0)
		_oyuncuyu_dondur(true)
		_bakis_bas = oyuncu_kamera.global_basis
		_egil_bas = oyuncu_kamera.global_position
		_kenar_lamba = _en_yakin_lamba(MAZGAL)
		if _kenar_lamba: _kenar_enerji = _kenar_lamba.light_energy
		_ugultu_kur()
		_gec("kenar")

# masadan feneri ve pili alır; oyun durmaz, Selim yürümeye devam edebilir
func _fener_pil() -> void:
	# ikisi yan yana: yalnızca bakılana daha yakın olanın yazısı çıkar
	var bak := -oyuncu_kamera.global_basis.z
	var aday := ""
	var en_iyi := -1.0
	for ad in ["fener", "pil"]:
		var m: Node3D = _fener_m if ad == "fener" else _pil_m
		if m == null or _alim.has(ad): continue
		var nokta := bak.dot((m.global_position - oyuncu_kamera.global_position).normalized())
		if nokta > en_iyi: en_iyi = nokta; aday = ad
	if aday == "fener" and _e_bak("fener", _fener_m.global_position, "Feneri al", 1.9):
		_alim["fener"] = dt_durum
		eller.uzan("sag", _fener_m.global_position, 0.45)
	elif aday == "pil" and _e_bak("pil", _pil_m.global_position, "Pili al", 1.9):
		_alim["pil"] = dt_durum
		eller.uzan("sol", _pil_m.global_position, 0.45)
	if e_yazi.visible and e_yazi.get_meta("ad", "") in ["fener", "pil"] and e_yazi.get_meta("ad", "") != aday:
		e_yazi.visible = false
	if _alim.has("fener") and not _fener_tutuldu and dt_durum - float(_alim["fener"]) > 0.45:
		_fener_tutuldu = true
		_fener_m.get_parent().remove_child(_fener_m)
		oyuncu_kamera.add_child(_fener_m)
		_fener_m.position = FENER_ELDE
		# modelin başı (camı) +Z yönünde: öne baksın diye döndürülür
		_fener_m.rotation_degrees = Vector3(0, 180, 0)
		var isik := oyuncu.get_node("Kafa/Kamera/Fener") as SpotLight3D
		isik.position = FENER_ELDE + Vector3(0, 0, -FENER_BOY * 0.5)
		eller.kamerada("sag", FENER_ELDE + Vector3(0.01, -0.04, 0.12), 0.45)
		eller.yumruk("sag", 0.7)
		_kisa_ses(_tik_sesi(), oyuncu_kamera.global_position, 0.6, -14.0)
	if _alim.has("pil") and _pil_m.visible and dt_durum - float(_alim["pil"]) > 0.45:
		_pil_m.visible = false
		eller.yumruk("sol", 0.6)
		_kisa_ses(_tik_sesi(), oyuncu_kamera.global_position, 0.5, -16.0)
	# pil fenere takılır: fener eldeyse sol el ona gider, tık sesiyle takar, sonra iner
	if _alim.has("pil") and not _pil_m.visible and _fener_tutuldu and not _pil_takildi:
		if not _alim.has("tak"):
			_alim["tak"] = dt_durum
			eller.kamerada("sol", FENER_ELDE + Vector3(-0.05, -0.02, 0.1), 0.4)
		elif dt_durum - float(_alim["tak"]) > 0.6:
			_pil_takildi = true
			eller.birak("sol", 0.5)
			eller.yumruk("sol", 0.0)
			_kisa_ses(_tik_sesi(), oyuncu_kamera.global_position, 1.4, -10.0)
			oyuncu.fener_izin = true
			_gecici_ipucu("F  Fener", 3.0)

# Selim kulübeden çıkınca yakındaki sokak lambaları birer birer titreyip söner
func _sonmeler(dt: float) -> void:
	for s_ in _sonen:
		var l: SpotLight3D = s_[0]
		var t: float = T_simdi() - float(s_[1])
		if not l.visible: continue
		if t < 1.4:
			var guc: float = float(s_[2])
			l.light_energy = guc * (randf_range(0.0, 0.45) if randf() < 0.5 else 0.9)
			if l.has_meta("hale"): (l.get_meta("hale") as OmniLight3D).light_energy = 0.7 * l.light_energy / guc
		else:
			l.visible = false
			for m in ["hale", "parilti"]:
				if l.has_meta(m): (l.get_meta(m) as Node3D).visible = false
			_kisa_ses(_kapi_sesi(), l.global_position, 3.5, -14.0)
	if _kulube_ici(oyuncu.global_position): return
	_sonraki_sonme -= dt
	if _sonraki_sonme > 0.0: return
	_sonraki_sonme = randf_range(1.3, 2.2)
	var mazgal_lamba := _en_yakin_lamba(MAZGAL)
	var p := oyuncu.global_position
	var en: SpotLight3D = null
	var d := 45.0
	for l in $Lambalar.get_children():
		if not (l is SpotLight3D) or not l.visible or l == mazgal_lamba: continue
		if _sonen.any(func(s_: Array) -> bool: return s_[0] == l): continue
		var u := Vector2(l.global_position.x - p.x, l.global_position.z - p.z).length()
		if u < d: d = u; en = l
	if en: _sonen.append([en, T_simdi(), en.light_energy])

func _kenar(dt: float) -> void:
	# Selim mazgalın kenarına çömelir ve içine bakar
	var t := dt_durum
	var yon := Vector3(MAZGAL.x - _egil_bas.x, 0.0, MAZGAL.z - _egil_bas.z)
	yon = yon.normalized() if yon.length() > 0.01 else Vector3.FORWARD
	var comel := Vector3(MAZGAL.x, 0.9, MAZGAL.z) - yon * 0.7
	var k := smoothstep(0.0, 1.4, t)
	var yer := _egil_bas.lerp(comel, k)
	# arkadan bir el iter: kamera öne ve aşağı savrulur
	var it := smoothstep(5.6, 5.85, t)
	yer += yon * 0.45 * it + Vector3(0, -0.15 * it, 0)
	var bakis := _bakis_bas.slerp(Basis.looking_at(MAZGAL + Vector3(0, -1.5, 0) - yer), k).orthonormalized()
	if it > 0.0: bakis = (Basis(bakis.x.normalized(), -0.6 * it) * bakis).orthonormalized()
	oyuncu_kamera.global_transform = Transform3D(bakis, yer)
	_ugultu_guc = 0.5 * smoothstep(0.3, 5.0, t)
	# yakındaki sokak lambası titrer ve söner
	if _kenar_lamba:
		if t < 1.9:
			_titreme -= dt
			if randf() < dt * 9.0: _titreme = randf_range(0.05, 0.15)
			_kenar_lamba.light_energy = _kenar_enerji * (randf_range(0.0, 0.5) if _titreme > 0.0 else 0.9)
		elif _kenar_lamba.visible:
			_kenar_lamba.visible = false
			for m in ["hale", "parilti"]:
				if _kenar_lamba.has_meta(m): (_kenar_lamba.get_meta(m) as Node3D).visible = false
			_kisa_ses(_kapi_sesi(), _kenar_lamba.global_position, 3.5, -16.0)
	# feneri hazırsa Selim onu açar
	var fener := oyuncu.get_node("Kafa/Kamera/Fener") as SpotLight3D
	if t > 2.8 and _pil_takildi and not fener.visible:
		fener.visible = true
		if oyuncu.has_method("_fener_tik"): oyuncu.call("_fener_tik")
	if t > 3.5 and not _soylenen.has("ses"): _soyle("ses")
	if t > 5.6 and not _soylenen.has("itildi"):
		_soylenen["itildi"] = true
		_kisa_ses(_gumbur_sesi(), yer - yon * 0.6 + Vector3(0, 0.3, 0), 1.7, 0.0)
		if bodycam: bodycam.bozul(0.9, 0.4)
	if t > 5.9:
		_kisa_ses(_cokme_sesi(), yer, 1.0, 2.0)
		_dusus_bas = oyuncu_kamera.global_transform
		_gec("dusus")

const DUSUS := 2.3
func _dusus(dt: float) -> void:
	var t := minf(dt_durum, DUSUS)
	var k := smoothstep(0.0, 0.4, t)
	var dus := maxf(0.0, t - 0.25)
	var cark := sin(t * 9.0) * 0.06 * clampf(t * 2.0, 0.0, 1.0)
	var yer := _dusus_bas.origin.lerp(Vector3(MAZGAL.x + 0.12, _dusus_bas.origin.y, MAZGAL.z - 0.1), k)
	yer.y = _dusus_bas.origin.y - 0.25 * k - 0.5 * 6.5 * dus * dus
	yer.x += cark
	var carpma := exp(-(t - 1.05) * 6.0) if t > 1.05 else 0.0
	var egim := _egri3([[0.0, -1.2], [0.35, -1.5], [0.9, 1.15], [1.5, 1.3], [DUSUS, 0.4]], t) + sin(t * 17.0) * 0.06 + carpma * 0.5 * sin(t * 40.0)
	var yuvarlanma := _egri3([[0.0, 0.0], [0.5, 0.35], [1.05, 0.7], [1.15, -0.4], [DUSUS, 1.6]], t) + carpma * 0.3
	var yon := _dusus_bas.basis.get_euler().y + t * 0.9
	oyuncu_kamera.global_transform = Transform3D(Basis.from_euler(Vector3(egim, yon, yuvarlanma)), yer)
	if t >= 1.05 and not _soylenen.has("carpti"):
		_soylenen["carpti"] = true
		_kisa_ses(_gumbur_sesi(), yer, 1.0, 6.0)
		if bodycam: bodycam.bozul(1.0, 0.6)
	if bodycam and randf() < 0.15: bodycam.bozul(randf_range(0.3, 0.8), 0.1)
	siyah.modulate.a = smoothstep(1.85, 2.25, t)
	_ugultu_guc = 0.5 + 0.3 * t / DUSUS
	ses_yagmur.volume_db = lerpf(-8.0, -40.0, t / DUSUS)
	if dt_durum >= DUSUS:
		_kisa_ses(_gumbur_sesi(), yer, 0.8, 8.0)
		if bodycam: bodycam.bozul(1.0, 2.0)
		ses_yagmur.stop()
		_ugultu_guc = 0.0
		_gec("karanlik")

# düşüşten sonra kamera bir an kesilir; Selim −1 Arşiv'de, kuyunun dibinde uyanır
const ARSIV := "res://sahneler/arsiv.tscn"
func _karanlik() -> void:
	siyah.modulate.a = 1.0
	if bodycam and bodycam.acik and dt_durum > 1.2:
		bodycam.kapat()
	if dt_durum > 4.0 and not _soylenen.has("arsiv"):
		_soylenen["arsiv"] = true
		var d := get_node_or_null("/root/Duraklat")
		if d: d.yukle(ARSIV)
		else: get_tree().change_scene_to_file(ARSIV)

func _en_yakin_lamba(p: Vector3) -> SpotLight3D:
	var en: SpotLight3D = null
	var d := 1e9
	for l in $Lambalar.get_children():
		if l is SpotLight3D:
			var u := Vector2(l.global_position.x - p.x, l.global_position.z - p.z).length()
			if u < d: d = u; en = l
	return en

func _egri3(n: Array, t: float) -> float:
	if t <= n[0][0]: return n[0][1]
	for i in n.size() - 1:
		if t < n[i + 1][0]: return lerpf(n[i][1], n[i + 1][1], (t - n[i][0]) / (n[i + 1][0] - n[i][0]))
	return n[n.size() - 1][1]

func _kisa_ses(akis: AudioStream, yer: Vector3, perde: float, db: float) -> void:
	var a := AudioStreamPlayer3D.new(); a.stream = akis; a.pitch_scale = perde; a.volume_db = db; a.unit_size = 5.0
	add_child(a); a.global_position = yer; a.play()
	a.finished.connect(a.queue_free)

# mazgalın içinden gelen alçak uğultu
func _ugultu_kur() -> void:
	_ugultu = AudioStreamPlayer.new()
	var g := AudioStreamGenerator.new(); g.mix_rate = 22050; g.buffer_length = 0.3
	_ugultu.stream = g; add_child(_ugultu); _ugultu.play()
	_ugultu_gen = _ugultu.get_stream_playback()

func _physics_ugultu() -> void:
	if _ugultu_gen == null: return
	for _i in _ugultu_gen.get_frames_available():
		_ugultu_faz += 1.0 / 22050.0
		var d := (sin(TAU * 48.0 * _ugultu_faz) * 0.6 + sin(TAU * 96.5 * _ugultu_faz) * 0.25 + randf_range(-0.15, 0.15)) * _ugultu_guc
		_ugultu_gen.push_frame(Vector2(d, d))

# eski telefon zili: iki kısa çalış, sonra sessizlik (döngü)
func _zil_sesi() -> AudioStreamWAV:
	var hiz := 22050
	var sure := 4.0
	var veri := PackedByteArray(); veri.resize(int(hiz * sure) * 2)
	for i in int(hiz * sure):
		var t := float(i) / hiz
		var acik := (t < 0.4) or (t > 0.6 and t < 1.0)
		var d := 0.0
		if acik:
			var cekic := 1.0 if fmod(t, 0.05) < 0.025 else -1.0
			d = (sin(TAU * 440.0 * t) * 0.35 + sin(TAU * 480.0 * t) * 0.35) * (0.7 + 0.3 * cekic)
		veri.encode_s16(i * 2, int(clampf(d, -1.0, 1.0) * 22000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS; w.mix_rate = hiz; w.data = veri
	w.loop_mode = AudioStreamWAV.LOOP_FORWARD; w.loop_end = int(hiz * sure)
	return w


# ---------------- yol tarifi ----------------
# Evden kulübeye: kuzeye düz, ortadaki caddeden sola, sonra sağa; kulübe sağda.
# Kulübeden mazgala: tarif mazgalın yönünü ve uzaklığını söyler.
const ROTA := [Vector3(-11.3, 0, 0.25) * OLCEK, Vector3(-57.2, 0, 0.25) * OLCEK, KULUBE_PARK]
var tarif: Label
var _rota_i := 0

func _tarif_guncelle() -> void:
	if durum == "surus":
		tarif.text = _surus_tarifi()
	elif durum == "mazgala":
		var yatay := Vector2(oyuncu.global_position.x - MAZGAL.x, oyuncu.global_position.z - MAZGAL.z).length()
		tarif.text = "" if yatay < 2.4 else tr("Mazgal: %d m, %s") % [int(round(yatay)), tr(_yon_adi(-oyuncu_kamera.global_basis.z, MAZGAL - oyuncu.global_position, false))]
	else:
		tarif.text = ""

func _rota() -> Array:
	if not eve_donus: return ROTA
	var r := ROTA.duplicate()
	r.reverse()
	r.append(EV_PARK)
	return r

func _surus_tarifi() -> String:
	var rota := _rota()
	var ad := "Ev" if eve_donus else "Kulübe"
	var p := araba.global_position
	while _rota_i < rota.size() - 1 and Vector2(p.x - rota[_rota_i].x, p.z - rota[_rota_i].z).length() < 10.0:
		_rota_i += 1
	# köşeyi kestiyse de sonraki caddeye girmiş sayılır
	for j in range(_rota_i + 1, rota.size()):
		var y := Geometry3D.get_closest_point_to_segment(Vector3(p.x, 0, p.z), rota[j - 1], rota[j])
		if Vector2(p.x - y.x, p.z - y.z).length() < 8.0: _rota_i = j
	var h: Vector3 = rota[_rota_i]
	var uzak := Vector2(p.x - h.x, p.z - h.z).length()
	var son := _rota_i == rota.size() - 1
	if son and uzak < PARK_YARICAP: return ""
	var yon := _yon_adi(-araba.global_basis.z, h - p, true)
	if yon != "ileride":
		return tr(ad + ": %s") % tr(yon)
	var m := int(maxf(10.0, round(uzak / 10.0) * 10.0))
	if son:
		return tr(ad + ": %d m ileride") % m if eve_donus else tr("Kulübe: %d m ileride, sağda") % m
	var a: Vector3 = rota[_rota_i - 1] if _rota_i > 0 else p
	var d1 := h - a; var d2: Vector3 = rota[_rota_i + 1] - h
	var sola := d1.cross(d2).y > 0.0
	return tr(ad + ": %d m sonra sola dön") % m if sola else tr(ad + ": %d m sonra sağa dön") % m

## hedefin bakılan yöne göre nerede olduğu; sürüşte "sola dön", yürürken "solunda"
func _yon_adi(ileri: Vector3, hedef: Vector3, surus: bool) -> String:
	var a := Vector2(ileri.x, ileri.z).angle_to(Vector2(hedef.x, hedef.z))
	if absf(a) < deg_to_rad(35.0): return "ileride"
	if absf(a) > deg_to_rad(120.0): return "geri dön" if surus else "arkanda"
	# Vector2(x, z) düzleminde açı artışı sağa dönüş demek
	if a > 0.0: return "sağa dön" if surus else "sağında"
	return "sola dön" if surus else "solunda"
