extends Node3D
## −1 Arşiv: mazgaldan düşüşün ilk katı.
## Selim beton bir kuyunun dibinde uyanır, yerdeki kasetçaları bulur. Cızırtılı kasette tek duyulan
## "...oda 8... masa 14...". Numaralı kapılı ofis koridorunda 8 numaralı oda büyük ofistir; 14 numaralı
## masada Selim'in imzaladığı tutanak ve adının yazdığı giriş kartı durur. Koridorun sonundaki kilitli
## kapıya kart okutulur, tuş takımına karttaki tarih girilir, kapı açılır ve merdivenden −2'ye inilir.
## Koridor, oda duvarları, zemin ve tavan alp'in Flow dokularıyla kodda kurulur; eşyaların hepsi alp'in modelleri.

const D := "res://modeller2/mazgala düşüşsten sonraki haritalar/ofis koridoru/"
const KAPI := D + "door_with_doorframe.glb"
const OFIS := D + "office_large_room_free.glb"
const MASA := D + "game_ready_-_old_office_desk.glb"
const DOLAP := D + "office_filing_cabinet_free.glb"
const KLASOR_RAFI := D + "file_shelf.glb"
const METAL_DOLAP := D + "sci-fi_furniture_pack_aaa_shelving_unit_c.glb"
const TUS_TAKIMI := D + "keypad.glb"
const KOLI := D + "cardboard_box.glb"
const LAMBA := D + "ceiling_lowpoly_fluorescent_lamps_with_diffuser.glb"
const KART := D + "identification_card.glb"
const KASETCALAR := "res://modeller2/mazgalıniçinde kaset ve kaset çalar/pony_trueman_cassette_player.glb"
const FOTO := "res://modeller2/seliminevi/foto_vesikalik.jpg"
## alp kasa kapısı modelini gönderince bu adlardan biriyle klasöre atması yeter; yoksa ahşap kapı kullanılır.
const KASA_KAPISI := [D + "vault_door.glb", D + "kasa_kapisi.glb", D + "kasa_kapi.glb"]
const DUVAR_YIPRANMIS := D + "yıpranmış.jpg"
const DUVAR_TEMIZ := D + "temiz.jpg"
const ZEMIN := D + "zemin.jpg"
const TAVAN_DOKU := D + "tavan.jpg"
const BETON := D + "beton.jpg"
const SONRAKI := "res://sahneler/baslangic.tscn"   # −2 kurulana kadar kayıt burada kesilir

const Bodycam := preload("res://kod/bodycam.gd")
const Eller := preload("res://kod/eller.gd")
const Govde := preload("res://kod/govde.gd")
const Kagit := preload("res://kod/kagit.gd")
const Ev := preload("res://kod/ev.gd")

## Selim'in kartı ve tutanağı: ad soyad, tarih ve tuş takımının kodu (karttaki tarihin gün+ay'ı)
const AD_SOYAD := "SELİM KAYA"
const TARIH := "14.10.2026"
const KOD := "1410"

# ---------------- yerleşim (metre) ----------------
const TAVAN := 2.7
const KOR_YARI := 1.2            # koridor genişliğinin yarısı
const KOR_BOY := 36.0            # koridor z=0'dan z=-36'ya uzanır
const KAPI_ARA := 4.0            # kapılar her 4 m'de, iki yanda; sol tekler, sağ çiftler
const KAPI_SAYI := 8             # her yanda
const ACIK_ODALAR := [3, 11]     # gerçekten girilen küçük odalar (depo ve arşiv)
const OFIS_NO := 8
const OFIS_YERI := Vector3(60.0, 0.0, -16.0)   # büyük ofis koridordan ayrı durur, kapıdan geçişle girilir
const OFIS_ZEMIN := 0.237                       # modelin kendi zemin düzlemi
const OFIS_GIRIS := Vector3(-6.75, 0.0, -0.4)   # ofisin sol duvarındaki kapı (model içinde)
const MERDIVEN_YERI := Vector3(0.0, 10.0, -90.0)
const KUYU := Rect2(-1.6, 0.0, 3.2, 3.6)        # x, z, genişlik, derinlik: başlangıç odası
const KUYU_AGZI := Vector3(0.0, TAVAN, 1.9)
## Masa numaraları: ofisteki 12 küme, her kümede sırt sırta iki masa sütunu. [küme x, satır z'leri]
const MASA_KUMELERI := [
	[-5.14, [1.34, 2.57, 3.79, 5.01]], [-3.19, [1.34, 2.57, 3.79, 5.01]], [-0.72, [1.34, 2.57, 3.79, 5.01]],
	[1.70, [1.34, 2.57, 3.79, 5.01]], [3.73, [1.34, 2.57, 3.79, 5.01]], [5.95, [1.34, 2.57, 3.79, 5.01]],
	[-5.11, [-3.2, -2.0]], [-3.0, [-3.2, -2.0]], [-0.78, [-3.2, -2.0]],
	[1.56, [-3.2, -2.0]], [3.89, [-3.2, -2.0]], [6.0, [-3.2, -2.0]]]
const MASA_NO := 14
const MASA_YUKSEK := 0.77

const SATIRLAR := {
	"uyanis": ["res://sesler/selim_neredeyim.mp3", "SELİM", "Ah... neresi burası?"],
	"dustum": ["res://sesler/selim_kor_07.mp3", "SELİM", "Burası neresi, nereye düştüm ben? Allah'ım sen yardım et... Ne olur sadece bir kabus olsun."],
	"tepki": ["res://sesler/selim_kasettepki_01.mp3", "SELİM", "Bu... bu ses... Lan bu benim sesim? Ben böyle bir şey kaydetmedim ki..."],
	"vizilti": ["res://sesler/selim_kor_08.mp3", "SELİM", "Bu floresanların vızıltısı susmuyor... Beynimin içine iğne batırıyorlar sanki. Bi susun lan artık!"],
	"adim": ["res://sesler/selim_kor_09.mp3", "SELİM", "Alo? Bir adım sesi mi geldi az önce? Kim var orada... Ses ver!"],
	"oda8": ["res://sesler/selim_kapi_01.mp3", "SELİM", "Kol dönüyor... Kilitli değil. Ne var lan içeride? Açıyorum... Hadi bismillah."],
}
## Kaset: alp gerçek kaydı sesler/kaset_arsiv.mp3 olarak atınca o çalar; yoksa cızırtı ve altyazı.
const KASET_SES := "res://sesler/kaset_arsiv.mp3"
const KASET := [
	[0.0, "[cızırtı]"],
	[2.2, "...kimse... ..... aşağıda..."],
	[4.4, "...oda 8..."],
	[6.6, "[cızırtı]"],
	[8.4, "...masa 14..."],
	[10.6, "[kayıt kesiliyor]"],
	[12.2, ""],
]
const KASET_SURE := 12.4

var oyuncu: CharacterBody3D
var kamera: Camera3D
var bodycam: Bodycam
var eller: Eller
var govde: Govde
var siyah: ColorRect
var ipucu: Label
var altyazi: Label
var e_yazi: Label
var okuma: TextureRect
var kod_yazi: Label
var ses_selim: AudioStreamPlayer
var ses_vizilti: AudioStreamPlayer

var durum := "uyanis"
var dt_durum := 0.0
var _soylenen := {}
var _altyazi_bitis := 0.0
var _ipucu_bitis := 0
var _paketler := {}
var _kapilar: Array[Dictionary] = []
var _lambalar: Array[Dictionary] = []
var _merdiven_isiklar: Array[Light3D] = []
var _ofis_kapi: Dictionary
var _kod_kapi: Dictionary
var _kasetcalar: Node3D
var _kart: Node3D
var _tutanak_yeri := Vector3.ZERO
var _tutanak_doku: Texture2D
var _dosyalar: Array = []           # [konum, doku]
var _kart_var := false
var _kaset_dinlendi := false
var _kod := ""
var _kod_dogru := false
var _sonraki_karanlik := 40.0
var _karanlik_t := -1.0
var _hayalet: AudioStreamPlayer3D
var _hayalet_yer := Vector3.ZERO
var _hayalet_adim := 0.0
var _gecis := {}
var _ses_havuz: Array[AudioStreamPlayer] = []
var _sesler := {}


func _ready() -> void:
	if not InputMap.has_action("etkiles"):
		InputMap.add_action("etkiles")
		var e := InputEventKey.new(); e.physical_keycode = KEY_E
		InputMap.action_add_event("etkiles", e)
	oyuncu = $Selim
	kamera = $Selim/Kafa/Kamera
	kamera.current = true
	(oyuncu.get_node("Adim") as AudioStreamPlayer3D).stream = _tok_sesi(95.0, 0.16, 0.6)
	(oyuncu.get_node("Adim") as AudioStreamPlayer3D).volume_db = -14.0
	_kuyu_kur()
	_koridor_kur()
	_ofis_kur()
	_kod_kapisi_kur()
	_merdiven_isiklar = Ev.merdiven_kur(self, MERDIVEN_YERI, Vector3(0, 0, 20), 1)
	_toz_kur()
	for p in _paketler: (_paketler[p] as Node).free()
	_paketler.clear()
	_arayuz_kur()
	govde = Govde.new()
	govde.fener = true     # mazgalın altında elinde fener: alp'in fenerli bekleme ve yürüme animasyonları
	add_child(govde)
	eller = Eller.new()
	kamera.add_child(eller)
	ses_selim = AudioStreamPlayer.new(); add_child(ses_selim)
	ses_vizilti = AudioStreamPlayer.new(); ses_vizilti.stream = _vizilti_sesi(); ses_vizilti.volume_db = -26.0
	add_child(ses_vizilti); ses_vizilti.play()
	_hayalet = AudioStreamPlayer3D.new(); _hayalet.stream = _tok_sesi(60.0, 0.3, 0.8); _hayalet.unit_size = 6.0
	add_child(_hayalet)
	var d := get_node_or_null("/root/Duraklat")
	if d:
		d.baslangic_noktasi = ""
		d.kayit_noktasi(scene_file_path, "")
	# Selim yerde, sırtüstü: kuyunun ağzından gelen soluk ışığa bakar
	oyuncu.global_position = Vector3(0.2, 0.0, 2.3)
	oyuncu.rotation.y = PI
	_oyuncu_dur(true)
	siyah.modulate.a = 1.0


# ================================================================ kurulum
func _malzeme(doku: String, metre: float, renk := Color.WHITE) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	if ResourceLoader.exists(doku): m.albedo_texture = load(doku)
	m.albedo_color = renk
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3.ONE / metre
	m.roughness = 0.9
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return m


## Duvar, zemin ya da tavan parçası: dokulu kutu ve çarpışması.
func _kutu(ana: Node3D, merkez: Vector3, boy: Vector3, mat: Material, carp := true) -> void:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new(); b.size = boy
	mi.mesh = b
	mi.material_override = mat
	ana.add_child(mi)
	mi.global_position = merkez
	if carp:
		var g := StaticBody3D.new()
		var s := CollisionShape3D.new(); var k := BoxShape3D.new(); k.size = boy
		s.shape = k; g.add_child(s); ana.add_child(g)
		g.global_position = merkez


## Modeli gerçek boyuna getirip yerleştirir. eksen: 0 en büyük boyut, 1 yükseklik.
func _model(yol: String, boy: float, yer: Vector3, aci: float, ana: Node3D, eksen := 1, carp := false) -> Node3D:
	if not ResourceLoader.exists(yol): return null
	if not _paketler.has(yol):
		var p := (load(yol) as PackedScene).instantiate() as Node3D
		_paketler[yol] = p
	var m := (_paketler[yol] as Node3D).duplicate() as Node3D
	ana.add_child(m)
	var kutu := _kutu_olc(m)
	var olcu: float = maxf(kutu.size.x, maxf(kutu.size.y, kutu.size.z)) if eksen == 0 else kutu.size.y
	var k := boy / maxf(olcu, 0.0001)
	m.scale = Vector3.ONE * k
	m.rotation.y = deg_to_rad(aci)
	var alt := Basis(Vector3.UP, deg_to_rad(aci)) * (Vector3(kutu.get_center().x, kutu.position.y, kutu.get_center().z) * k)
	m.global_position = yer - alt
	if carp:
		for mi in m.find_children("*", "MeshInstance3D", true, false):
			(mi as MeshInstance3D).create_trimesh_collision()
	return m


## Modelin kendi uzayındaki kutusu (ölçek ve dönüş uygulanmadan).
func _kutu_olc(m: Node3D) -> AABB:
	var kutu := AABB()
	var ilk := true
	for mi in m.find_children("*", "MeshInstance3D", true, false):
		var n: Node = mi
		var xf := Transform3D.IDENTITY
		while n != m:
			xf = (n as Node3D).transform * xf
			n = n.get_parent()
		var a := xf * (mi as MeshInstance3D).get_aabb()
		if ilk: kutu = a; ilk = false
		else: kutu = kutu.merge(a)
	return kutu


func _isik(ana: Node3D, yer: Vector3, renk: Color, enerji: float, menzil: float, golge := false) -> OmniLight3D:
	var o := OmniLight3D.new()
	o.light_color = renk
	o.light_energy = enerji
	o.omni_range = menzil
	o.omni_attenuation = 1.3
	o.shadow_enabled = golge
	ana.add_child(o)
	o.global_position = yer
	return o


## Tavana floresan armatürü ve ışığı. titrek: ara sıra titrer; olu: hiç yanmaz.
func _floresan(ana: Node3D, yer: Vector3, aci: float, titrek := false, olu := false) -> void:
	var m := _model(LAMBA, 1.2, yer + Vector3(0, -0.035, 0), aci, ana, 0)
	if m: m.global_position.y = yer.y - 0.035
	var o := _isik(ana, yer + Vector3(0, -0.35, 0), Color(0.86, 1.0, 0.9), 0.0 if olu else 0.85, 5.0, false)
	_lambalar.append({"isik": o, "guc": 0.0 if olu else 0.85, "titrek": titrek, "t": randf() * 5.0, "koridor": ana.name == "Koridor"})


func _kuyu_kur() -> void:
	var ana := Node3D.new(); ana.name = "Kuyu"; add_child(ana)
	var beton := _malzeme(BETON, 2.0, Color(0.75, 0.75, 0.72))
	var x0 := KUYU.position.x; var x1 := KUYU.end.x
	var z0 := KUYU.position.y; var z1 := KUYU.end.y
	var cx := (x0 + x1) * 0.5; var cz := (z0 + z1) * 0.5
	_kutu(ana, Vector3(cx, -0.1, cz), Vector3(KUYU.size.x, 0.2, KUYU.size.y), beton)
	_kutu(ana, Vector3(x0 - 0.1, TAVAN * 0.5, cz), Vector3(0.2, TAVAN, KUYU.size.y), beton)
	_kutu(ana, Vector3(x1 + 0.1, TAVAN * 0.5, cz), Vector3(0.2, TAVAN, KUYU.size.y), beton)
	_kutu(ana, Vector3(cx, TAVAN * 0.5, z1 + 0.1), Vector3(KUYU.size.x + 0.4, TAVAN, 0.2), beton)
	# koridora açılan kırık geçit (x -0.6..0.6, 2.1 m)
	_kutu(ana, Vector3((x0 - 0.6) * 0.5 - 0.1, TAVAN * 0.5, -0.1), Vector3(-0.6 - x0 + 0.2, TAVAN, 0.2), beton)
	_kutu(ana, Vector3((x1 + 0.6) * 0.5 + 0.1, TAVAN * 0.5, -0.1), Vector3(x1 - 0.6 + 0.2, TAVAN, 0.2), beton)
	_kutu(ana, Vector3(0, (2.1 + TAVAN) * 0.5, -0.1), Vector3(1.2, TAVAN - 2.1, 0.2), beton)
	# tavanda kuyunun ağzı (1x1); yukarı 9 m beton baca, tepede soluk sokak ışığı
	var ag := KUYU_AGZI
	_kutu(ana, Vector3(cx, TAVAN + 0.1, (z0 + ag.z - 0.5) * 0.5), Vector3(KUYU.size.x, 0.2, ag.z - 0.5 - z0), beton)
	_kutu(ana, Vector3(cx, TAVAN + 0.1, (ag.z + 0.5 + z1) * 0.5), Vector3(KUYU.size.x, 0.2, z1 - ag.z - 0.5), beton)
	_kutu(ana, Vector3((x0 + ag.x - 0.5) * 0.5, TAVAN + 0.1, ag.z), Vector3(ag.x - 0.5 - x0, 0.2, 1.0), beton)
	_kutu(ana, Vector3((ag.x + 0.5 + x1) * 0.5, TAVAN + 0.1, ag.z), Vector3(x1 - ag.x - 0.5, 0.2, 1.0), beton)
	var baca := 9.0
	for k in [[Vector3(-0.6, 0, 0), Vector3(0.2, baca, 1.4)], [Vector3(0.6, 0, 0), Vector3(0.2, baca, 1.4)], [Vector3(0, 0, -0.6), Vector3(1.0, baca, 0.2)], [Vector3(0, 0, 0.6), Vector3(1.0, baca, 0.2)]]:
		_kutu(ana, ag + k[0] + Vector3(0, baca * 0.5, 0), k[1], beton)
	var s := SpotLight3D.new()
	s.light_color = Color(0.55, 0.62, 0.8)
	s.light_energy = 2.2
	s.spot_range = 14.0
	s.spot_angle = 16.0
	s.shadow_enabled = true
	ana.add_child(s)
	s.global_position = ag + Vector3(0, baca - 0.3, 0)
	s.look_at(ag + Vector3(0.1, -2.0, 0.05))
	# bacadan damlayan su
	var p := GPUParticles3D.new()
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(0.4, 0.1, 0.4)
	pm.direction = Vector3.DOWN; pm.initial_velocity_min = 1.0; pm.initial_velocity_max = 2.0
	pm.gravity = Vector3(0, -9.8, 0)
	p.process_material = pm
	p.amount = 40; p.lifetime = 1.6
	var q := QuadMesh.new(); q.size = Vector2(0.008, 0.08)
	var qm := StandardMaterial3D.new(); qm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	qm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA; qm.albedo_color = Color(0.7, 0.75, 0.85, 0.35)
	qm.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	q.material = qm
	p.draw_pass_1 = q
	ana.add_child(p)
	p.global_position = ag + Vector3(0, 7.0, 0)
	# kasetçalar Selim'in düştüğü yerin yanında, bir kolinin önünde
	_model(KOLI, 0.55, Vector3(-1.05, 0.0, 0.55), 15.0, ana, 0)
	_kasetcalar = _model(KASETCALAR, 0.3, Vector3(-0.55, 0.0, 1.15), 120.0, ana, 0)
	_isik(ana, Vector3(0.0, 2.2, 0.5), Color(0.85, 1.0, 0.9), 0.15, 3.5)


func _koridor_kur() -> void:
	var ana := Node3D.new(); ana.name = "Koridor"; add_child(ana)
	var duvar := _malzeme(DUVAR_YIPRANMIS, 2.2)
	var zemin := _malzeme(ZEMIN, 1.6)
	var tavan := _malzeme(TAVAN_DOKU, 2.4)
	var cz := -KOR_BOY * 0.5
	_kutu(ana, Vector3(0, -0.1, cz), Vector3(KOR_YARI * 2.0 + 0.4, 0.2, KOR_BOY), zemin)
	_kutu(ana, Vector3(0, TAVAN + 0.1, cz), Vector3(KOR_YARI * 2.0 + 0.4, 0.2, KOR_BOY), tavan)
	# iki yan duvar, kapı boşluklarıyla
	for yan in [-1, 1]:
		var x: float = yan * (KOR_YARI + 0.1)
		var bas := 0.0
		for i in range(1, KAPI_SAYI + 1):
			var kz := -KAPI_ARA * i
			_duvar_parca(ana, x, bas, kz + 0.48, duvar)
			_kutu(ana, Vector3(x, (2.15 + TAVAN) * 0.5, kz), Vector3(0.2, TAVAN - 2.15, 0.96), duvar)
			bas = kz - 0.48
			var no: int = 2 * i - (1 if yan < 0 else 0)
			_kapi_ekle(ana, no, Vector3(yan * KOR_YARI, 0, kz), yan)
		_duvar_parca(ana, x, bas, -KOR_BOY, duvar)
	# koridorun sonundaki duvar (kilitli kapının boşluğu ortada)
	_kutu(ana, Vector3(-(KOR_YARI + 0.48) * 0.5 - 0.1, TAVAN * 0.5, -KOR_BOY - 0.1), Vector3(KOR_YARI - 0.48 + 0.4, TAVAN, 0.2), duvar)
	_kutu(ana, Vector3((KOR_YARI + 0.48) * 0.5 + 0.1, TAVAN * 0.5, -KOR_BOY - 0.1), Vector3(KOR_YARI - 0.48 + 0.4, TAVAN, 0.2), duvar)
	_kutu(ana, Vector3(0, (2.15 + TAVAN) * 0.5, -KOR_BOY - 0.1), Vector3(0.96, TAVAN - 2.15, 0.2), duvar)
	# floresanlar: her 3 m'de bir; biri ölü, ikisi titrek
	var n := 0
	var z := -1.5
	while z > -KOR_BOY + 0.5:
		_floresan(ana, Vector3(0, TAVAN, z), 0.0, n == 3 or n == 8, n == 6)
		n += 1
		z -= 3.0
	# kapı numaraları
	for k in _kapilar: _numara(ana, k)
	# açık küçük odalar
	_oda_kur(ana, 3, "depo")
	_oda_kur(ana, 11, "arsiv")


func _duvar_parca(ana: Node3D, x: float, z_bas: float, z_son: float, mat: Material) -> void:
	if z_bas - z_son < 0.01: return
	_kutu(ana, Vector3(x, TAVAN * 0.5, (z_bas + z_son) * 0.5), Vector3(0.2, TAVAN, z_bas - z_son), mat)


## Kapı: kasa ve kanat alp'in modeli; kanat menteşe ekseninde döner. yon: kapının koridordan odaya bakan yönü (x).
func _kapi_ekle(ana: Node3D, no: int, yer: Vector3, yan: int) -> Dictionary:
	var m := _model(KAPI, 2.15, yer, -90.0 * yan, ana)
	if m == null: return {}
	var icerisi := Vector3(yan, 0, 0)
	var k := _kapi_kanat(m, icerisi)
	k["no"] = no
	k["yer"] = yer
	k["icerisi"] = icerisi
	k["kilitli"] = not (no in ACIK_ODALAR or no == OFIS_NO)
	_kapilar.append(k)
	return k


## Kanadı menteşe noktasındaki bir pivota taşır ve kanadın çarpışmasını ekler.
func _kapi_kanat(m: Node3D, icerisi: Vector3) -> Dictionary:
	var kanat := m.find_child("Door_8", true, false) as Node3D
	var d := {"model": m, "acik": 0.0, "hedef": 0.0, "pivot": null, "aci": 0.0}
	if kanat == null: return d
	var kutu := AABB(); var ilk := true
	for mi in kanat.find_children("*", "MeshInstance3D", true, false):
		var a := (mi as MeshInstance3D).global_transform * (mi as MeshInstance3D).get_aabb()
		if ilk: kutu = a; ilk = false
		else: kutu = kutu.merge(a)
	# menteşe kolun tersindeki kenarda: kol tarafı Plane_5'in olduğu yer
	var kol := m.find_child("Plane_5", true, false) as Node3D
	var kol_yer := kol.global_position if kol else kutu.end
	var yatay := m.global_basis.x.normalized()
	var merkez := kutu.get_center()
	var yari := absf((kutu.size * yatay.abs()).dot(Vector3.ONE)) * 0.5
	var kol_yon := signf(yatay.dot(kol_yer - merkez))
	if kol_yon == 0.0: kol_yon = 1.0
	var mentese := merkez - yatay * kol_yon * yari
	mentese.y = kutu.position.y
	var pivot := Node3D.new()
	m.get_parent().add_child(pivot)
	pivot.global_position = mentese
	var gt := kanat.global_transform
	kanat.get_parent().remove_child(kanat)
	pivot.add_child(kanat)
	kanat.global_transform = gt
	# kanadın çarpışması (dönerken onunla birlikte döner)
	var g := AnimatableBody3D.new()
	g.sync_to_physics = false
	var s := CollisionShape3D.new(); var b := BoxShape3D.new()
	b.size = Vector3(yari * 2.0, kutu.size.y, 0.06)
	s.shape = b; g.add_child(s)
	pivot.add_child(g)
	g.global_transform = Transform3D(m.global_basis.orthonormalized(), merkez)
	# hangi yöne dönerse kanat odanın içine gider
	var c := merkez - mentese
	d["aci"] = 1.45 if c.rotated(Vector3.UP, 1.45).dot(icerisi) > c.rotated(Vector3.UP, -1.45).dot(icerisi) else -1.45
	d["pivot"] = pivot
	d["kol"] = merkez + yatay * kol_yon * yari * 0.8 + Vector3(0, 1.0 - (merkez.y - kutu.position.y), 0)
	return d


## Kapının üstünde küçük numara levhası (yazı, model değil).
func _numara(ana: Node3D, k: Dictionary) -> void:
	var l := Label3D.new()
	l.text = str(k["no"])
	l.font_size = 64
	l.pixel_size = 0.0022
	l.modulate = Color(0.12, 0.12, 0.1)
	l.outline_size = 0
	l.shaded = true
	ana.add_child(l)
	var ic: Vector3 = k["icerisi"]
	l.global_position = (k["yer"] as Vector3) - ic * 0.02 + Vector3(0, 2.3, 0)
	l.look_at(l.global_position - ic, Vector3.UP)
	l.rotate_object_local(Vector3.UP, PI)


func _kapi_bul(no: int) -> Dictionary:
	for k in _kapilar:
		if k["no"] == no: return k
	return {}


## Kapı numarasındaki küçük oda: koridor duvarının arkasında 4 x 3.6 m.
func _oda_kur(ana: Node3D, no: int, tur: String) -> void:
	var k := _kapi_bul(no)
	if k.is_empty(): return
	var ic: Vector3 = k["icerisi"]
	var kz: float = (k["yer"] as Vector3).z
	var x0: float = (KOR_YARI + 0.2) * ic.x
	var x1: float = x0 + 4.0 * ic.x
	var cx := (x0 + x1) * 0.5
	var duvar := _malzeme(DUVAR_TEMIZ, 2.2, Color(0.85, 0.88, 0.85))
	var zemin := _malzeme(ZEMIN, 1.6)
	var tavan := _malzeme(TAVAN_DOKU, 2.4)
	_kutu(ana, Vector3(cx, -0.1, kz), Vector3(4.0, 0.2, 3.6), zemin)
	_kutu(ana, Vector3(cx, TAVAN + 0.1, kz), Vector3(4.0, 0.2, 3.6), tavan)
	_kutu(ana, Vector3(x1 + 0.1 * ic.x, TAVAN * 0.5, kz), Vector3(0.2, TAVAN, 3.6), duvar)
	_kutu(ana, Vector3(cx, TAVAN * 0.5, kz - 1.9), Vector3(4.2, TAVAN, 0.2), duvar)
	_kutu(ana, Vector3(cx, TAVAN * 0.5, kz + 1.9), Vector3(4.2, TAVAN, 0.2), duvar)
	_floresan(ana, Vector3(cx, TAVAN, kz), 90.0, tur == "depo")
	var arka := x1 - 0.45 * ic.x
	var yuz := 90.0 if ic.x < 0 else -90.0    # arka duvardan koridora bakar
	if tur == "depo":
		_model(METAL_DOLAP, 2.0, Vector3(arka - 0.4 * ic.x, 0, kz - 1.0), yuz, ana, 1, true)
		_model(DOLAP, 1.32, Vector3(arka, 0, kz + 0.9), yuz, ana, 1, true)
		_model(KOLI, 0.55, Vector3(x0 + 1.2 * ic.x, 0, kz + 1.3), 20.0, ana, 0, true)
		_model(KOLI, 0.5, Vector3(x0 + 1.25 * ic.x, 0.25, kz + 1.3), -10.0, ana, 0)
		_model(KOLI, 0.55, Vector3(x0 + 2.0 * ic.x, 0, kz - 1.4), 70.0, ana, 0, true)
		_dosya_koy(Vector3(x0 + 1.2 * ic.x, 0.51, kz + 1.25), 2016, 0.4)
	else:
		_model(KLASOR_RAFI, 1.9, Vector3(arka, 0, kz - 0.9), yuz, ana, 1, true)
		_model(KLASOR_RAFI, 1.9, Vector3(arka, 0, kz + 0.1), yuz, ana, 1, true)
		_model(DOLAP, 1.32, Vector3(arka, 0, kz + 1.2), yuz, ana, 1, true)
		_model(MASA, 0.76, Vector3(cx, 0, kz - 1.35), 0.0, ana, 1, true)
		_dosya_koy(Vector3(cx - 0.25, 0.775, kz - 1.35), 2019, -0.2)
		_dosya_koy(Vector3(cx + 0.3, 0.775, kz - 1.3), 2023, 0.3)


## Selim'in personel dosyasının bir kopyası: aynı ad ve doğum tarihi, farklı işe giriş yılı.
func _dosya_koy(yer: Vector3, yil: int, aci: float) -> void:
	var doku := Kagit.yazi_dokusu(self, Vector2i(420, 594), Color(0.88, 0.86, 0.78), [
		["BELEDİYE FEN İŞLERİ MÜDÜRLÜĞÜ", 20, Color(0.15, 0.15, 0.2), HORIZONTAL_ALIGNMENT_CENTER],
		["PERSONEL DOSYASI", 26, Color(0.1, 0.1, 0.12), HORIZONTAL_ALIGNMENT_CENTER],
		["", 70, Color.BLACK, HORIZONTAL_ALIGNMENT_LEFT],
		["", 70, Color.BLACK, HORIZONTAL_ALIGNMENT_LEFT],
		["Adı Soyadı : " + AD_SOYAD, 18, Color(0.1, 0.1, 0.12), HORIZONTAL_ALIGNMENT_LEFT],
		["Doğum      : 03.04.1991", 18, Color(0.1, 0.1, 0.12), HORIZONTAL_ALIGNMENT_LEFT],
		["Görevi     : Gece bekçisi", 18, Color(0.1, 0.1, 0.12), HORIZONTAL_ALIGNMENT_LEFT],
		["İşe giriş  : 14.10.%d" % yil, 18, Color(0.1, 0.1, 0.12), HORIZONTAL_ALIGNMENT_LEFT],
		["Durumu     : KAYIP", 18, Color(0.45, 0.08, 0.06), HORIZONTAL_ALIGNMENT_LEFT],
	], FOTO)
	Kagit.yapistir(self, doku, yer, Vector2(0.21, 0.297), Vector3.DOWN, aci, 0.12)
	_dosyalar.append([yer, doku])


func _ofis_kur() -> void:
	var ana := Node3D.new(); ana.name = "Ofis"; add_child(ana)
	ana.global_position = OFIS_YERI - Vector3(0, OFIS_ZEMIN, 0)
	if ResourceLoader.exists(OFIS):
		var m := (load(OFIS) as PackedScene).instantiate() as Node3D
		ana.add_child(m)
		for mi in m.find_children("*", "MeshInstance3D", true, false):
			(mi as MeshInstance3D).create_trimesh_collision()
	var o := OFIS_YERI
	# ofisin tavanı (modelde yok) ve floresanlar
	var tavan := _malzeme(TAVAN_DOKU, 2.4)
	var t_y := 2.84 - OFIS_ZEMIN
	_kutu(self, o + Vector3(0.17, t_y + 0.1, -0.29), Vector3(14.3, 0.2, 13.95), tavan)
	for x in [-4.6, -1.9, 0.8, 3.5, 6.2]:
		for z in [-4.5, -1.2, 2.0, 4.6]:
			_floresan(self, o + Vector3(x, t_y, z), 0.0, randf() < 0.15, randf() < 0.1)
	# giriş kapısı ofisin içinden görünür; koridora dönüş buradan
	var giris := o + OFIS_GIRIS
	var km := _model(KAPI, 2.15, giris, -90.0, self)
	if km: _ofis_kapi = _kapi_kanat(km, Vector3(-1, 0, 0))
	# masa numaraları ve 14 numaralı masa
	var no := 1
	for kume in MASA_KUMELERI:
		for yan in [-1, 1]:
			for z in kume[1]:
				var masa := o + Vector3(float(kume[0]) + yan * 0.42, 0, float(z))
				var l := Label3D.new()
				l.text = str(no)
				l.font_size = 48
				l.pixel_size = 0.0022
				l.modulate = Color(0.1, 0.1, 0.1)
				l.shaded = true
				add_child(l)
				l.global_position = o + Vector3(float(kume[0]) + yan * 0.04, 1.12, float(z))
				l.look_at(l.global_position + Vector3(yan, 0, 0), Vector3.UP)
				l.rotate_object_local(Vector3.UP, PI)
				if no == MASA_NO: _masa14(masa, yan)
				no += 1


func _masa14(masa: Vector3, yan: int) -> void:
	var ust := masa + Vector3(-yan * 0.05, MASA_YUKSEK - OFIS_ZEMIN + 0.005, 0)
	_tutanak_doku = Kagit.yazi_dokusu(self, Vector2i(420, 594), Color(0.9, 0.9, 0.86), [
		["BELEDİYE FEN İŞLERİ MÜDÜRLÜĞÜ", 20, Color(0.15, 0.15, 0.2), HORIZONTAL_ALIGNMENT_CENTER],
		["ARIZA TUTANAĞI", 28, Color(0.1, 0.1, 0.12), HORIZONTAL_ALIGNMENT_CENTER],
		["Tarih  : " + TARIH + "  00:00", 18, Color(0.1, 0.1, 0.12), HORIZONTAL_ALIGNMENT_LEFT],
		["Yer    : Nöbet kulübesi önü, cadde", 18, Color(0.1, 0.1, 0.12), HORIZONTAL_ALIGNMENT_LEFT],
		["Arıza  : Mazgal kapağı açık.", 18, Color(0.1, 0.1, 0.12), HORIZONTAL_ALIGNMENT_LEFT],
		["Bildiren telefonla aradı.", 18, Color(0.1, 0.1, 0.12), HORIZONTAL_ALIGNMENT_LEFT],
		["Kontrole gelen personel düştü.", 18, Color(0.1, 0.1, 0.12), HORIZONTAL_ALIGNMENT_LEFT],
		["", 18, Color.BLACK, HORIZONTAL_ALIGNMENT_LEFT],
		["Tutanağı tutan: " + AD_SOYAD, 18, Color(0.1, 0.1, 0.12), HORIZONTAL_ALIGNMENT_LEFT],
		["Selim", 34, Color(0.1, 0.12, 0.35), HORIZONTAL_ALIGNMENT_RIGHT, true],
	])
	_tutanak_yeri = ust + Vector3(0, 0, -0.12)
	Kagit.yapistir(self, _tutanak_doku, _tutanak_yeri, Vector2(0.21, 0.297), Vector3.DOWN, 0.15, 0.12)
	_kart = _model(KART, 0.086, ust + Vector3(0, 0, 0.2), 0.0, self, 0)
	if _kart:
		# kart modeli dik duruyor: masaya yatırılır
		var y := _kart.global_position
		_kart.rotation = Vector3(-PI * 0.5, 0.4, 0)
		var kutu := _dunya_kutusu(_kart)
		_kart.global_position += (ust + Vector3(0, 0.003, 0.2)) - Vector3(kutu.get_center().x, kutu.position.y, kutu.get_center().z)
		y = y


func _dunya_kutusu(m: Node3D) -> AABB:
	var kutu := AABB(); var ilk := true
	for mi in m.find_children("*", "MeshInstance3D", true, false):
		var a := (mi as MeshInstance3D).global_transform * (mi as MeshInstance3D).get_aabb()
		if ilk: kutu = a; ilk = false
		else: kutu = kutu.merge(a)
	return kutu


## Koridorun sonundaki kilitli kapı: kart okuyucu tuş takımı yanında, tarih üstünde.
func _kod_kapisi_kur() -> void:
	var yer := Vector3(0, 0, -KOR_BOY)
	var yol := KAPI
	for y in KASA_KAPISI:
		if ResourceLoader.exists(y): yol = y; break
	var m := _model(yol, 2.15, yer, 0.0, self)
	if m: _kod_kapi = _kapi_kanat(m, Vector3(0, 0, -1))
	_kod_kapi["kilitli"] = true
	var tus := _model(TUS_TAKIMI, 0.18, Vector3(0.85, 1.22, -KOR_BOY + 0.005), 0.0, self)
	_kod_kapi["tus"] = Vector3(0.85, 1.31, -KOR_BOY + 0.03)
	_kod_kapi["lamba"] = _isik(self, Vector3(0.85, 1.3, -KOR_BOY + 0.12), Color(1.0, 0.15, 0.1), 0.25, 0.8)
	if tus == null: _kod_kapi["tus"] = Vector3(0.85, 1.3, -KOR_BOY + 0.05)
	# kapının üstüne sürülmüş tarih
	var t := Kagit.yazi_dokusu(self, Vector2i(512, 128), Color(0, 0, 0, 0), [["", 4, Color.BLACK, HORIZONTAL_ALIGNMENT_CENTER], [TARIH, 64, Color(0.3, 0.05, 0.03, 0.9), HORIZONTAL_ALIGNMENT_CENTER, true]])
	Kagit.yapistir(self, t, Vector3(0, 2.38, -KOR_BOY - 0.0), Vector2(0.9, 0.22), Vector3(0, 0, -1), 0.0, 0.2)
	# kapının ardında kısa beton geçit ve merdivenin otomatik lambası
	var beton := _malzeme(BETON, 2.0, Color(0.7, 0.7, 0.68))
	_kutu(self, Vector3(0, -0.1, -KOR_BOY - 1.2), Vector3(1.6, 0.2, 2.0), beton)
	_kutu(self, Vector3(0, TAVAN + 0.1, -KOR_BOY - 1.2), Vector3(1.6, 0.2, 2.0), beton)
	_kutu(self, Vector3(-0.85, TAVAN * 0.5, -KOR_BOY - 1.2), Vector3(0.2, TAVAN, 2.0), beton)
	_kutu(self, Vector3(0.85, TAVAN * 0.5, -KOR_BOY - 1.2), Vector3(0.2, TAVAN, 2.0), beton)
	_kutu(self, Vector3(0, TAVAN * 0.5, -KOR_BOY - 2.3), Vector3(1.9, TAVAN, 0.2), beton)


func _toz_kur() -> void:
	var p := GPUParticles3D.new()
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(3, 1.3, 3)
	pm.gravity = Vector3(0, -0.01, 0)
	pm.initial_velocity_min = 0.0; pm.initial_velocity_max = 0.05
	pm.turbulence_enabled = true
	pm.turbulence_noise_strength = 0.2
	p.process_material = pm
	p.amount = 160; p.lifetime = 8.0
	var q := QuadMesh.new(); q.size = Vector2(0.006, 0.006)
	var qm := StandardMaterial3D.new()
	qm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	qm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	qm.albedo_color = Color(0.9, 0.9, 0.85, 0.35)
	qm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	q.material = qm
	p.draw_pass_1 = q
	p.local_coords = false
	p.name = "Toz"
	oyuncu.add_child(p)
	p.position = Vector3(0, 1.4, 0)


# ================================================================ arayüz
func _arayuz_kur() -> void:
	var cl := CanvasLayer.new(); cl.layer = 10; add_child(cl)
	okuma = TextureRect.new()
	okuma.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	okuma.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	okuma.set_anchors_preset(Control.PRESET_FULL_RECT)
	okuma.offset_top = 90; okuma.offset_bottom = -90
	okuma.visible = false
	cl.add_child(okuma)
	siyah = ColorRect.new(); siyah.color = Color.BLACK
	siyah.set_anchors_preset(Control.PRESET_FULL_RECT); siyah.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cl.add_child(siyah)
	ipucu = _etiket(cl, 20, Color(0.85, 0.85, 0.8, 0.75), 8)
	ipucu.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ipucu.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	ipucu.offset_left = -700; ipucu.offset_right = 700; ipucu.offset_top = -70; ipucu.offset_bottom = -30
	altyazi = _etiket(cl, 34, Color(0.95, 0.95, 0.92), 10)
	altyazi.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	altyazi.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	altyazi.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	altyazi.offset_left = -800; altyazi.offset_right = 800; altyazi.offset_top = -190; altyazi.offset_bottom = -100
	altyazi.visible = false
	e_yazi = _etiket(cl, 19, Color(0.95, 0.95, 0.92), 5)
	e_yazi.visible = false
	kod_yazi = _etiket(cl, 46, Color(0.55, 1.0, 0.6), 10)
	kod_yazi.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kod_yazi.set_anchors_preset(Control.PRESET_CENTER)
	kod_yazi.offset_left = -400; kod_yazi.offset_right = 400; kod_yazi.offset_top = 120; kod_yazi.offset_bottom = 200
	kod_yazi.visible = false
	bodycam = Bodycam.new()
	add_child(bodycam)


func _etiket(ana: Node, boy: int, renk: Color, kenar: int) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", boy)
	l.add_theme_color_override("font_color", renk)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", kenar)
	ana.add_child(l)
	return l


func _ipucu(metin: String, sure := 0.0) -> void:
	ipucu.text = metin
	if sure > 0.0:
		var bu := Time.get_ticks_msec() + int(sure * 1000.0)
		_ipucu_bitis = bu
		get_tree().create_timer(sure, false).timeout.connect(func() -> void:
			if _ipucu_bitis == bu and ipucu.text == metin: ipucu.text = "")


func _altyazi(kim: String, metin: String, sure: float) -> void:
	altyazi.text = (tr(kim) + ": " if kim != "" else "") + tr(metin)
	var d := get_node_or_null("/root/Duraklat")
	altyazi.visible = metin != "" and (d == null or d.get("altyazi") != false)
	_altyazi_bitis = _simdi() + sure


func _soyle(ad: String) -> float:
	_soylenen[ad] = true
	var s: Array = SATIRLAR[ad]
	var sure: float = 2.5 + str(s[2]).length() * 0.05
	if ResourceLoader.exists(s[0]):
		var akis: AudioStream = load(s[0])
		ses_selim.stream = akis; ses_selim.play()
		sure = akis.get_length() + 0.5
	_altyazi(s[1], s[2], sure)
	return sure


func _simdi() -> float:
	return Time.get_ticks_msec() / 1000.0


## Bakılan şeyin üstünde "E" yazısı; E'ye basıldıysa true.
func _e_bak(ad: String, nokta: Vector3, metin: String, menzil := 1.8) -> bool:
	var d := nokta - kamera.global_position
	var bak := -kamera.global_basis.z
	var yakin := d.length() < menzil and bak.dot(d.normalized()) > lerpf(0.78, 0.93, clampf((d.length() - 0.6) / 1.2, 0.0, 1.0))
	if not yakin:
		if e_yazi.get_meta("ad", "") == ad: e_yazi.visible = false
		return false
	e_yazi.set_meta("ad", ad)
	e_yazi.text = "E  " + tr(metin)
	e_yazi.visible = true
	e_yazi.reset_size()
	var ekran := get_viewport().get_visible_rect().size
	e_yazi.position = (kamera.unproject_position(nokta) - Vector2(16, e_yazi.size.y * 0.5)).clamp(Vector2(60, 60), ekran - e_yazi.size - Vector2(60, 60))
	if Input.is_action_just_pressed("etkiles"):
		e_yazi.visible = false
		return true
	return false


func _oyuncu_dur(dur: bool) -> void:
	oyuncu.set_physics_process(not dur)
	oyuncu.set_process_unhandled_input(not dur)
	if dur: oyuncu.velocity = Vector3.ZERO


# ================================================================ akış
func _gec(yeni: String) -> void:
	durum = yeni
	dt_durum = 0.0


func _process(dt: float) -> void:
	dt_durum += dt
	if _altyazi_bitis > 0.0 and _simdi() > _altyazi_bitis:
		altyazi.visible = false; _altyazi_bitis = 0.0
	govde.visible = durum == "oyun" and oyuncu.is_physics_processing()
	if govde.visible:
		govde.goz = oyuncu.BOY
		govde.eller = eller
		govde.gorunur = not Input.is_action_pressed("egil")
		govde.guncelle(oyuncu.global_position, oyuncu.global_rotation.y, dt)
	_lambalari_isle(dt)
	_kapilari_isle(dt)
	if not _gecis.is_empty(): _gecisi_isle(dt)
	match durum:
		"uyanis": _uyanis()
		"kaset": _kaset()
		"oyun": _oyun(dt)
		"kod": _kod_gir()
		"cikis": _cikis()


## Selim beton zeminde gözlerini açar, bacanın ağzına bakar, doğrulur.
func _uyanis() -> void:
	var t := dt_durum
	if t > 0.3 and not bodycam.acik:
		bodycam.ac(0.0)
		bodycam.bozul(1.0, 1.4)
	siyah.modulate.a = 1.0 - smoothstep(0.8, 3.0, t) * (0.85 + 0.15 * smoothstep(4.0, 5.0, t))
	var yer := Vector3(0.2, 0.0, 2.3)
	var yat := Transform3D(Basis.looking_at(KUYU_AGZI + Vector3(0, 6, 0.2) - (yer + Vector3(0, 0.25, 0))), yer + Vector3(0, 0.25, 0))
	var otur := Transform3D(Basis.looking_at(Vector3(-0.5, 0.2, 1.0) - (yer + Vector3(0, 0.9, 0.1))), yer + Vector3(0, 0.9, 0.1))
	var kalk := Transform3D(Basis.looking_at(Vector3(0.0, 1.2, -2.0) - (yer + Vector3(0, oyuncu.BOY, 0))), yer + Vector3(0, oyuncu.BOY, 0))
	var xf := yat
	if t > 5.0: xf = yat.interpolate_with(otur, smoothstep(5.0, 7.0, t))
	if t > 8.5: xf = otur.interpolate_with(kalk, smoothstep(8.5, 10.5, t))
	kamera.global_transform = xf
	if t > 3.2 and not _soylenen.has("uyanis"): _soyle("uyanis")
	if t > 10.6:
		siyah.modulate.a = 0.0
		kamera.position = Vector3.ZERO
		kamera.rotation = Vector3.ZERO
		var bak := Vector3(0.0, 1.2, -2.0) - yer
		oyuncu.rotation.y = atan2(-bak.x, -bak.z)
		(oyuncu.get_node("Kafa") as Node3D).rotation.x = 0.0
		(oyuncu.get_node("Kafa/Kamera/Fener") as SpotLight3D).visible = false
		_oyuncu_dur(false)
		_soyle("dustum")
		_ipucu("F: fener", 5.0)
		_gec("oyun")


func _oyun(dt: float) -> void:
	var p := oyuncu.global_position
	# kasetçalar
	if not _kaset_dinlendi and _kasetcalar and _e_bak("kaset", _kasetcalar.global_position + Vector3(0, 0.08, 0), "Kasetçaları al"):
		_oyuncu_dur(true)
		eller.uzan("sag", _kasetcalar.global_position + Vector3(0, 0.08, 0), 0.6)
		_gec("kaset")
		return
	# kapılar
	for k in _kapilar:
		if (k["acik"] as float) > 0.5 and k["no"] != OFIS_NO: continue
		if _e_bak("kapi%d" % k["no"], k["kol"], "Kapıyı aç", 1.6):
			_kapi_dene(k)
	# ofisin içinden koridora dönüş
	if not _ofis_kapi.is_empty() and _e_bak("ofis_cik", _ofis_kapi["kol"], "Koridora dön", 1.6):
		_ses_cal("kapi_ac", -8.0)
		_gecis_basla(_kapi_bul(OFIS_NO)["yer"] as Vector3 + Vector3(-0.8, 0, 0), 0.0)
	# 14 numaralı masa
	if _tutanak_yeri != Vector3.ZERO and _e_bak("tutanak", _tutanak_yeri, "Tutanağı oku", 1.4):
		_oku(_tutanak_doku, 5.0)
	if _kart and not _kart_var and _e_bak("kart", _kart.global_position, "Kartı al", 1.4):
		_kart_var = true
		eller.uzan("sag", _kart.global_position, 0.5)
		get_tree().create_timer(0.5, false).timeout.connect(func() -> void:
			_kart.visible = false
			eller.birak("sag", 0.6)
			_ses_cal("kagit", -12.0)
			_oku(_kart_dokusu(), 5.0)
			_ipucu("Kilitli kapıyı bul", 6.0))
	for f in _dosyalar:
		if _e_bak("dosya%s" % str(f[0]), f[0], "Dosyayı oku", 1.4):
			_oku(f[1], 5.0)
	# kilitli kapı
	if not _kod_kapi.is_empty() and not _kod_dogru and _e_bak("tus", _kod_kapi["tus"], "Kart okut", 1.5):
		if not _kart_var:
			_ses_cal("bip_red", -10.0)
			_ipucu("Kart gerekli", 2.5)
		else:
			eller.uzan("sag", _kod_kapi["tus"], 0.5)
			_ses_cal("bip", -10.0)
			(_kod_kapi["lamba"] as OmniLight3D).light_color = Color(1.0, 0.75, 0.2)
			_kod = ""
			_oyuncu_dur(true)
			_gec("kod")
	if _kod_dogru and (_kod_kapi["acik"] as float) > 0.6 and p.z < -KOR_BOY + 0.4:
		_oyuncu_dur(true)
		_gec("cikis")
	if okuma.visible and Input.is_action_just_pressed("etkiles") and okuma.get_meta("bas", 0.0) + 0.3 < _simdi():
		okuma.visible = false
	# floresan vızıltısı koridorda ilk kez kulağa batınca
	if p.z < -6.0 and not _soylenen.has("vizilti") and _kaset_dinlendi: _soyle("vizilti")
	_karanlik_isle(dt)


func _kapi_dene(k: Dictionary) -> void:
	if k["kilitli"]:
		_ses_cal("kilitli", -9.0)
		_ipucu("Kilitli", 1.5)
		return
	if k["no"] == OFIS_NO:
		if not _soylenen.has("oda8"): _soyle("oda8")
		_ses_cal("kapi_ac", -6.0)
		k["hedef"] = 0.25
		var giris := OFIS_YERI + OFIS_GIRIS + Vector3(0.7, 0, 0)
		_gecis_basla(giris, -PI * 0.5)
		return
	_ses_cal("kapi_ac", -6.0)
	k["hedef"] = 1.0


## Kısa kararma ve yer değiştirme (kapıdan ofise ya da ofisten koridora).
func _gecis_basla(yer: Vector3, yon: float) -> void:
	_oyuncu_dur(true)
	_gecis = {"t": 0.0, "yer": yer, "yon": yon, "tasindi": false}


func _gecisi_isle(dt: float) -> void:
	_gecis["t"] += dt
	var t: float = _gecis["t"]
	siyah.modulate.a = smoothstep(0.0, 0.5, t) * (1.0 - smoothstep(0.9, 1.5, t))
	if t > 0.6 and not _gecis["tasindi"]:
		_gecis["tasindi"] = true
		oyuncu.global_position = _gecis["yer"]
		oyuncu.rotation.y = _gecis["yon"]
		for k in _kapilar: if k["no"] == OFIS_NO: k["hedef"] = 0.0
		_ses_cal("dolap", -12.0)
	if t > 1.5:
		siyah.modulate.a = 0.0
		_gecis = {}
		if durum == "oyun": _oyuncu_dur(false)


func _kapilari_isle(dt: float) -> void:
	var hepsi: Array = _kapilar.duplicate()
	if not _kod_kapi.is_empty(): hepsi.append(_kod_kapi)
	if not _ofis_kapi.is_empty(): hepsi.append(_ofis_kapi)
	for k in hepsi:
		var hiz := 0.5 if k == _kod_kapi else 1.4
		k["acik"] = move_toward(k["acik"], k["hedef"], dt * hiz)
		var pv: Node3D = k["pivot"]
		if pv: pv.rotation.y = float(k["aci"]) * smoothstep(0.0, 1.0, k["acik"])


func _oku(doku: Texture2D, sure: float) -> void:
	if doku == null: return
	okuma.texture = doku
	okuma.visible = true
	okuma.set_meta("bas", _simdi())
	_ses_cal("kagit", -14.0)
	get_tree().create_timer(sure, false).timeout.connect(func() -> void:
		if okuma.texture == doku: okuma.visible = false)


var _kart_doku: Texture2D
func _kart_dokusu() -> Texture2D:
	if _kart_doku == null:
		_kart_doku = Kagit.yazi_dokusu(self, Vector2i(640, 404), Color(0.92, 0.93, 0.95), [
			["BELEDİYE FEN İŞLERİ — ARŞİV GİRİŞ KARTI", 22, Color(0.1, 0.2, 0.45), HORIZONTAL_ALIGNMENT_CENTER],
			["", 30, Color.BLACK, HORIZONTAL_ALIGNMENT_LEFT],
			["                " + AD_SOYAD, 30, Color(0.08, 0.08, 0.1), HORIZONTAL_ALIGNMENT_LEFT],
			["                Gece bekçisi", 22, Color(0.2, 0.2, 0.22), HORIZONTAL_ALIGNMENT_LEFT],
			["", 30, Color.BLACK, HORIZONTAL_ALIGNMENT_LEFT],
			["                " + TARIH, 30, Color(0.45, 0.08, 0.06), HORIZONTAL_ALIGNMENT_LEFT],
		], FOTO, Rect2(30, 70, 150, 200))
	return _kart_doku


## Kasetçalar: Selim alır, düğmeye basar, cızırtılı kayıt çalar.
var _kaset_ses: AudioStreamPlayer
func _kaset() -> void:
	var t := dt_durum
	if t > 0.6 and _kasetcalar.get_parent() != eller.get_parent():
		var gt := _kasetcalar.global_transform
		_kasetcalar.get_parent().remove_child(_kasetcalar)
		kamera.add_child(_kasetcalar)
		_kasetcalar.global_transform = gt
		eller.kamerada("sag", Vector3(0.1, -0.22, -0.32), 0.7)
	if t > 0.6:
		var hedef := Transform3D(Basis.from_euler(Vector3(0.9, PI * 0.5, 0)) * Basis.from_scale(_kasetcalar.global_basis.get_scale()), Vector3(0.02, -0.17, -0.36))
		_kasetcalar.transform = _kasetcalar.transform.interpolate_with(hedef, minf(1.0, get_process_delta_time() * 6.0))
	if t > 1.5 and _kaset_ses == null:
		_ses_cal("dugme", -6.0)
		_kaset_ses = AudioStreamPlayer.new()
		_kaset_ses.stream = load(KASET_SES) if ResourceLoader.exists(KASET_SES) else _cizirti_sesi()
		add_child(_kaset_ses)
		_kaset_ses.play()
	var kt := t - 1.6
	for i in KASET.size():
		var s: Array = KASET[i]
		if kt >= float(s[0]) and not _soylenen.has("kaset%d" % i):
			_soylenen["kaset%d" % i] = true
			_altyazi("KASET", s[1], 2.4)
			if str(s[1]).contains("oda") or str(s[1]).contains("masa"): bodycam.bozul(0.5, 0.3)
			else: bodycam.bozul(0.3, 0.2)
	if kt > KASET_SURE and not _soylenen.has("tepki"):
		if _kaset_ses: _kaset_ses.stop()
		_ses_cal("dugme", -8.0)
		var s := _soyle("tepki")
		_soylenen["tepki_bitis"] = t + s
	if _soylenen.has("tepki_bitis") and t > float(_soylenen["tepki_bitis"]):
		_kasetcalar.visible = false   # cebine koyar
		eller.birak("sag", 0.6)
		_kaset_dinlendi = true
		_ipucu("Oda 8'i bul", 8.0)
		_oyuncu_dur(false)
		_gec("oyun")


## Tuş takımına karttaki tarih girilir (gün ve ay). Klavyedeki rakamlar; E vazgeçer.
func _kod_gir() -> void:
	kod_yazi.visible = true
	var goster := ""
	for i in 4: goster += (_kod[i] if i < _kod.length() else "_") + " "
	kod_yazi.text = tr("KOD") + ":  " + goster
	if Input.is_action_just_pressed("etkiles") and dt_durum > 0.3:
		kod_yazi.visible = false
		eller.birak("sag", 0.5)
		_oyuncu_dur(false)
		_gec("oyun")


func _unhandled_input(e: InputEvent) -> void:
	if durum != "kod" or not (e is InputEventKey) or not e.pressed or e.echo: return
	var k := e as InputEventKey
	var r := -1
	if k.keycode >= KEY_0 and k.keycode <= KEY_9: r = k.keycode - KEY_0
	elif k.keycode >= KEY_KP_0 and k.keycode <= KEY_KP_9: r = k.keycode - KEY_KP_0
	elif k.keycode == KEY_BACKSPACE and _kod.length() > 0:
		_kod = _kod.left(_kod.length() - 1)
		return
	if r < 0 or _kod.length() >= 4: return
	_kod += str(r)
	_ses_cal("tus", -12.0)
	if _kod.length() < 4: return
	if _kod == KOD:
		_kod_dogru = true
		(_kod_kapi["lamba"] as OmniLight3D).light_color = Color(0.2, 1.0, 0.3)
		_ses_cal("bip", -8.0)
		get_tree().create_timer(0.5, false).timeout.connect(func() -> void: _ses_cal("surgu", -4.0))
		get_tree().create_timer(2.0, false).timeout.connect(func() -> void:
			_ses_cal("gicirti", -6.0)
			_kod_kapi["hedef"] = 1.0
			for o in _merdiven_isiklar: _merdiven_isik_ac(o))
		get_tree().create_timer(0.8, false).timeout.connect(func() -> void:
			kod_yazi.visible = false
			eller.birak("sag", 0.5)
			_oyuncu_dur(false)
			_gec("oyun"))
	else:
		_ses_cal("bip_red", -8.0)
		bodycam.bozul(0.2, 0.15)
		get_tree().create_timer(0.6, false).timeout.connect(func() -> void: _kod = "")


func _merdiven_isik_ac(o: Light3D) -> void:
	if o.has_meta("malzeme"):
		var mat := o.get_meta("malzeme") as BaseMaterial3D
		mat.emission_energy_multiplier = float(mat.get_meta("parlak")) * Ev.MERDIVEN_PARLAK
	else:
		o.light_energy = 0.55


## Kapıdan geçince: merdiven boşluğunda bir kat iner, sonra kayıt kesilir (−2 yakında).
func _cikis() -> void:
	var t := dt_durum
	siyah.modulate.a = _egri([[0, 0], [0.6, 1], [1.2, 1], [1.8, 0], [7.4, 0], [8.2, 1]], t)
	if t > 1.0:
		var b := MERDIVEN_YERI
		var anahtar := [
			[1.2, b + Vector3(3.9, 1.6 - 0.14, 5.6), b + Vector3(0.0, 1.2, 5.3)],
			[2.2, b + Vector3(3.2, 1.6 - 0.14, 5.3), b + Vector3(-1.0, 0.0, 5.1)],
			[3.4, b + Vector3(1.6, 1.3 - 0.14, 5.1), b + Vector3(-2.2, -1.6, 5.1)],
			[5.8, b + Vector3(-2.6, -1.8 - 0.14, 5.1), b + Vector3(-4.6, -2.6, 5.4)],
			[6.8, b + Vector3(-3.7, -2.4 - 0.14, 4.6), b + Vector3(-4.0, -2.6, 7.8)],
		]
		var p: Vector3 = anahtar[0][1]; var h: Vector3 = anahtar[0][2]
		for i in anahtar.size() - 1:
			if t >= float(anahtar[i][0]):
				var u := clampf((t - float(anahtar[i][0])) / (float(anahtar[i + 1][0]) - float(anahtar[i][0])), 0.0, 1.0)
				u = smoothstep(0.0, 1.0, u)
				p = (anahtar[i][1] as Vector3).lerp(anahtar[i + 1][1], u)
				h = (anahtar[i][2] as Vector3).lerp(anahtar[i + 1][2], u)
		p.y += sin(t * 9.0) * 0.012
		kamera.global_transform = Transform3D(Basis.looking_at(h - p), p)
		if t > 1.6 and t < 6.8 and fmod(t, 0.45) < get_process_delta_time(): _ses_cal("adim", -14.0)
	if t > 8.3 and not _soylenen.has("kesildi"):
		_soylenen["kesildi"] = true
		bodycam.kapat()
		_altyazi("", "−2", 3.0)
	if t > 11.5:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		var d := get_node_or_null("/root/Duraklat")
		if d: d.yukle(SONRAKI)
		else: get_tree().change_scene_to_file(SONRAKI)
		set_process(false)


func _egri(n: Array, t: float) -> float:
	if t <= n[0][0]: return n[0][1]
	for i in n.size() - 1:
		if t < n[i + 1][0]: return lerpf(n[i][1], n[i + 1][1], (t - n[i][0]) / (n[i + 1][0] - n[i][0]))
	return n[n.size() - 1][1]


# ================================================================ ışık ve karanlık
func _lambalari_isle(dt: float) -> void:
	for l in _lambalar:
		var o: OmniLight3D = l["isik"]
		var guc: float = l["guc"]
		if _karanlik_t >= 0.0 and l["koridor"]:
			o.light_energy = 0.0
			continue
		if l["titrek"]:
			l["t"] = float(l["t"]) - dt
			if float(l["t"]) < 0.0:
				l["t"] = randf_range(0.04, 0.25) if randf() < 0.7 else randf_range(1.5, 5.0)
				o.light_energy = guc * (randf_range(0.0, 0.3) if randf() < 0.5 else 1.0)
		else:
			o.light_energy = guc
	var yakin := 99.0
	for l in _lambalar:
		if (l["guc"] as float) > 0.0: yakin = minf(yakin, (l["isik"] as Node3D).global_position.distance_to(kamera.global_position))
	ses_vizilti.volume_db = lerpf(-14.0, -40.0, clampf((yakin - 0.5) / 6.0, 0.0, 1.0)) if _karanlik_t < 0.0 else -60.0


## Kaset dinlendikten sonra koridorda ara sıra ışıklar söner; karanlıkta arkadan ayak sesleri yaklaşır.
func _karanlik_isle(dt: float) -> void:
	var p := oyuncu.global_position
	var koridorda := p.z < -1.0 and p.z > -KOR_BOY and absf(p.x) < KOR_YARI
	if _karanlik_t >= 0.0:
		_karanlik_t += dt
		_hayalet_adim -= dt
		if _hayalet_adim <= 0.0 and _karanlik_t < 2.2:
			_hayalet_adim = 0.55
			_hayalet_yer = _hayalet_yer.move_toward(p, 0.5)
			_hayalet.global_position = _hayalet_yer
			_hayalet.pitch_scale = randf_range(0.85, 1.0)
			_hayalet.play()
		if _karanlik_t > 2.4:
			_karanlik_t = -1.0
			_ses_cal("otomat", -12.0)
			bodycam.bozul(0.6, 0.25)
			if not _soylenen.has("adim"): _soyle("adim")
		return
	if not _kaset_dinlendi or not koridorda: return
	_sonraki_karanlik -= dt
	if _sonraki_karanlik <= 0.0:
		_sonraki_karanlik = randf_range(35.0, 60.0)
		_karanlik_t = 0.0
		_ses_cal("otomat", -10.0)
		bodycam.bozul(0.8, 0.4)
		var arka := kamera.global_basis.z
		arka.y = 0.0
		_hayalet_yer = p + arka.normalized() * 5.0
		_hayalet_adim = 0.4


# ================================================================ sesler
func _ses_cal(ad: String, db: float) -> void:
	var akis := _ses_bul(ad)
	if akis == null: return
	var p: AudioStreamPlayer = null
	for s in _ses_havuz:
		if not s.playing: p = s; break
	if p == null:
		p = AudioStreamPlayer.new(); add_child(p); _ses_havuz.append(p)
	p.stream = akis
	p.volume_db = db
	p.play()


func _ses_bul(ad: String) -> AudioStream:
	if _sesler.has(ad): return _sesler[ad]
	var akis: AudioStream = null
	for uz in ["mp3", "ogg", "wav"]:
		var yol := "res://sesler/%s.%s" % [ad, uz]
		if ResourceLoader.exists(yol): akis = load(yol); break
	if akis == null: akis = _yedek_ses(ad)
	_sesler[ad] = akis
	return akis


## alp gerçek sesleri gönderene kadar geçici sentez sesler (aynı adla sesler/ klasörüne atılınca onlar çalar).
func _yedek_ses(ad: String) -> AudioStream:
	var hiz := 22050
	var o := PackedFloat32Array()
	match ad:
		"adim": return _tok_sesi(95.0, 0.16, 0.6)
		"kilitli":
			for i in int(hiz * 0.5):
				var t := float(i) / hiz
				var d := 0.0
				for v in [0.0, 0.12, 0.27]:
					var x: float = t - v
					if x >= 0.0: d += ((randf() * 2.0 - 1.0) * 0.4 + sin(TAU * 900.0 * x) * 0.25) * exp(-x * 60.0)
				o.append(d)
		"kapi_ac", "dolap":
			for i in int(hiz * 0.9):
				var t := float(i) / hiz
				o.append((randf() * 2.0 - 1.0) * exp(-t * 30.0) * 0.4 + sin(TAU * (180.0 + 40.0 * sin(t * 11.0)) * t) * 0.1 * smoothstep(0.1, 0.3, t) * exp(-t * 3.0))
		"bip", "tus":
			var f := 1800.0 if ad == "bip" else 1200.0
			for i in int(hiz * (0.18 if ad == "bip" else 0.06)):
				var t := float(i) / hiz
				o.append(sin(TAU * f * t) * 0.3)
		"bip_red":
			for i in int(hiz * 0.45):
				var t := float(i) / hiz
				o.append(signf(sin(TAU * 220.0 * t)) * 0.15 * (1.0 if fmod(t, 0.22) < 0.17 else 0.0))
		"surgu":
			for i in int(hiz * 1.2):
				var t := float(i) / hiz
				var d := 0.0
				for v in [0.0, 0.35, 0.7]:
					var x: float = t - v
					if x >= 0.0: d += (sin(TAU * 90.0 * x) * 0.5 + (randf() * 2.0 - 1.0) * 0.4) * exp(-x * 14.0)
				o.append(d * 0.7)
		"gicirti":
			for i in int(hiz * 2.6):
				var t := float(i) / hiz
				o.append(sin(TAU * (300.0 + 120.0 * sin(t * 2.3) + 40.0 * sin(t * 17.0)) * t) * 0.12 * smoothstep(0.0, 0.3, t) * (1.0 - smoothstep(2.0, 2.6, t)) + (randf() * 2.0 - 1.0) * 0.03)
		"kagit":
			for i in int(hiz * 0.35):
				var t := float(i) / hiz
				o.append((randf() * 2.0 - 1.0) * 0.25 * sin(PI * t / 0.35))
		"dugme":
			for i in int(hiz * 0.08):
				var t := float(i) / hiz
				o.append((randf() * 2.0 - 1.0) * exp(-t * 200.0) * 0.7 + sin(TAU * 2400.0 * t) * exp(-t * 150.0) * 0.2)
		"otomat":
			for i in int(hiz * 0.5):
				var t := float(i) / hiz
				o.append((randf() * 2.0 - 1.0) * exp(-t * 90.0) * 0.8 + sin(TAU * 60.0 * t) * exp(-t * 8.0) * 0.3)
		_: return null
	return _wav(o, hiz)


func _tok_sesi(f: float, sure: float, gurultu: float) -> AudioStreamWAV:
	var o := PackedFloat32Array()
	var hiz := 22050
	var dusuk := 0.0
	for i in int(hiz * sure):
		var t := float(i) / hiz
		dusuk = lerpf(dusuk, randf() * 2.0 - 1.0, 0.1)
		o.append((sin(TAU * f * t) * 0.5 + dusuk * gurultu) * exp(-t * 28.0))
	return _wav(o, hiz)


## Kasetin cızırtısı: bant hışırtısı, dalgalanma, ara ara boğuk konuşma sesine benzeyen uğultu.
func _cizirti_sesi() -> AudioStreamWAV:
	var hiz := 22050
	var o := PackedFloat32Array()
	var dusuk := 0.0
	for i in int(hiz * (KASET_SURE + 0.5)):
		var t := float(i) / hiz
		dusuk = lerpf(dusuk, randf() * 2.0 - 1.0, 0.3)
		var ses := 0.0
		for s in [[2.2, 1.6], [4.4, 1.3], [8.4, 1.5]]:
			var x: float = t - float(s[0])
			if x > 0.0 and x < float(s[1]):
				var hece := 0.5 + 0.5 * sin(TAU * 4.5 * x)
				ses += (sin(TAU * (120.0 + 15.0 * sin(x * 3.0)) * t) * 0.25 + sin(TAU * 240.0 * t) * 0.1) * hece * sin(PI * x / float(s[1]))
		var patlama := (randf() * 2.0 - 1.0) * 0.6 if randf() < 0.0008 else 0.0
		var son := 1.0 - smoothstep(KASET_SURE - 1.6, KASET_SURE - 1.0, t)
		o.append(((randf() * 2.0 - 1.0) * 0.07 + dusuk * 0.08) * (0.8 + 0.2 * sin(t * 1.7)) + ses * son + patlama)
	return _wav(o, hiz)


func _vizilti_sesi() -> AudioStreamWAV:
	var hiz := 22050
	var o := PackedFloat32Array()
	for i in hiz:
		var t := float(i) / hiz
		o.append(sin(TAU * 100.0 * t) * 0.18 + sin(TAU * 200.0 * t) * 0.06 + sin(TAU * 7000.0 * t) * 0.01 + (randf() * 2.0 - 1.0) * 0.01)
	var w := _wav(o, hiz)
	w.loop_mode = AudioStreamWAV.LOOP_FORWARD
	w.loop_end = hiz
	return w


func _wav(ornek: PackedFloat32Array, hiz: int) -> AudioStreamWAV:
	var veri := PackedByteArray()
	veri.resize(ornek.size() * 2)
	for i in ornek.size():
		veri.encode_s16(i * 2, int(clampf(ornek[i], -1.0, 1.0) * 32000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = hiz
	w.data = veri
	return w
