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
	if Engine.is_editor_hint(): return
	_guvenlik_zemini()
	_sinir_duvarlari()
	if has_meta("arkaplan"): return   # ana menünün arkasındaki görüntü
	_yolculuk_kur()

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
	if o == null or durum == "surus" or durum == "binis" or durum == "inis": return
	if o.is_on_floor() and o.global_position.y > -0.3: _son_guvenli = o.global_position
	elif o.global_position.y < -6.0:
		o.global_position = _son_guvenli + Vector3(0, 0.3, 0); o.velocity = Vector3.ZERO

# şehrin kenarlarına görünmez duvar: arabayla ya da yürüyerek boşluğa çıkılmaz
func _sinir_duvarlari() -> void:
	var g := StaticBody3D.new(); g.name = "SinirDuvarlari"; add_child(g)
	for d in [[Vector3(-117.5, 3, -13), Vector3(1, 8, 170)], [Vector3(37.5, 3, -13), Vector3(1, 8, 170)],
			[Vector3(-40, 3, -95.5), Vector3(160, 8, 1)], [Vector3(-40, 3, 69.5), Vector3(160, 8, 1)]]:
		var c := CollisionShape3D.new(); var b := BoxShape3D.new()
		b.size = d[1]; c.shape = b; c.position = d[0]; g.add_child(c)


# ---------------- Evden çıkış, arabaya biniş, kulübeye sürüş ----------------
# Selim evin kapısından çıkar (sağ alt blok), kapının önünde park etmiş arabasına yürür, E ile biner.
# Kuzeye sürer, ortadaki caddeden sola, sonra sağa döner; kulübenin önünde E ile iner.

const KULUBE_PARK := Vector3(-58.0, 0.0, -77.0)
const PARK_YARICAP := 8.0
const SATIRLAR := {
	"araba1": ["res://sesler/selim_araba_01.mp3", "SELİM", "Her gece aynı yol... aynı lambalar."],
	"araba2": ["res://sesler/selim_araba_02.mp3", "SELİM", "Bir şey olsun be. Bir şey..."],
	"amir1": ["res://sesler/amir_01.mp3", "AMİR", "Alo, Selim? Kulübede misin?"],
	"selim1": ["res://sesler/selim_01.mp3", "SELİM", "Buradayım abi, kulübeden ayrılmadım hiç."],
	"amir2": ["res://sesler/amir_02.mp3", "AMİR", "Santralden bağladılar demin... Biri aradı, mazgal açık kalmış diyor. Yalan yok, arayanın sesi de aynı sen ha, bir an 'bu herif benimle kafa mı buluyor' dedim."],
	"selim2": ["res://sesler/selim_02.mp3", "SELİM", "Kim dalga geçecek seninle, başkasıdır o."],
	"amir3": ["res://sesler/amir_03.mp3", "AMİR", "Çıkıver oradan iki adım, bakıver şuna. Çoluk çocuk geçiyor o yoldan, biri düşer eder Allah korusun, başımıza iş almayalım. Kapatıver kapağı da raporu düşelim sisteme."],
	"selim3": ["res://sesler/selim_03.mp3", "SELİM", "Tamam, anladım; iki dakikaya gidip oturturum kapağı yerine. Başımıza iş açılmasın, halledip haber veririm sana."],
	"mirilti": ["res://sesler/selim_05.mp3", "SELİM", "Kim açar ki bunu bu saatte..."],
	"ses": ["res://sesler/selim_06.mp3", "SELİM", "Bu... bu ne sesi?"],
}
const KONUSMA := ["amir1", "selim1", "amir2", "selim2", "amir3", "selim3"]
# açık mazgalın yeri (kulübeden sola, caddenin ortası); alp'in açık mazgal modeli gelince buraya konur
const MAZGAL := Vector3(-61.0, 0.0, -88.0)

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

func _yolculuk_kur() -> void:
	if not InputMap.has_action("etkiles"):
		InputMap.add_action("etkiles")
		var e := InputEventKey.new(); e.physical_keycode = KEY_E
		InputMap.action_add_event("etkiles", e)
	oyuncu = $Selim
	oyuncu_kamera = $Selim/Kafa/Kamera
	oyuncu_kamera.current = true
	_arayuz_kur()
	ses_selim = AudioStreamPlayer.new(); add_child(ses_selim)
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

func _process(dt: float) -> void:
	if Engine.is_editor_hint() or oyuncu == null: return
	dt_durum += dt
	_physics_ugultu()
	if durum != "dusus" and durum != "karanlik":
		siyah.modulate.a = move_toward(siyah.modulate.a, 0.0, dt * 0.6)
	if _altyazi_bitis > 0.0 and Time.get_ticks_msec() / 1000.0 > _altyazi_bitis:
		altyazi.visible = false; _altyazi_bitis = 0.0
	match durum:
		"yuruyus": _yuruyus()
		"binis": _binis()
		"surus": _surus(dt)
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
	var uzak := Vector2(oyuncu.global_position.x - _surucu_kapisi().x, oyuncu.global_position.z - _surucu_kapisi().z).length()
	if uzak < 1.8:
		_ipucu("E  Arabaya bin", 0.0)
		if Input.is_action_just_pressed("etkiles"):
			_binise_basla()
	elif ipucu.text == "E  Arabaya bin":
		_ipucu("Arabana git", 0.0)

func _binise_basla() -> void:
	_ipucu("", 0.0)
	oyuncu.set_physics_process(false); oyuncu.set_process_unhandled_input(false)
	oyuncu.process_mode = Node.PROCESS_MODE_DISABLED
	(oyuncu.get_node("Govde") as CollisionShape3D).disabled = true
	_gecis_bas = oyuncu_kamera.global_transform
	araba.kapi("DFL_8", true)
	ses_kapi.global_position = _surucu_kapisi() + Vector3(0, 1, 0); ses_kapi.pitch_scale = 1.3; ses_kapi.volume_db = -10.0; ses_kapi.play()
	var kam := araba.get_node("Kamera") as Camera3D
	kam.rotation = Vector3(-0.04, 0, 0)
	_gecis_bit = kam.global_transform
	kam.global_transform = _gecis_bas
	kam.current = true
	_gec("binis")

# kapı açılır, Selim oturur, kapı kapanır, motor çalışır
func _binis() -> void:
	var kam := araba.get_node("Kamera") as Camera3D
	var u := smoothstep(0.5, 2.3, dt_durum)
	var ara := _gecis_bas.interpolate_with(_gecis_bit, u)
	ara.origin.y -= sin(u * PI) * 0.25
	kam.global_transform = ara
	if dt_durum > 2.4 and araba._kapi_hedef["DFL_8"] > 0.5:
		araba.kapi("DFL_8", false)
	if dt_durum > 2.95 and not _soylenen.has("kapi_kapandi"):
		_soylenen["kapi_kapandi"] = true
		ses_kapi.global_position = araba.global_position; ses_kapi.pitch_scale = 1.0; ses_kapi.volume_db = 0.0; ses_kapi.play()
	if dt_durum > 3.8:
		kam.transform = Transform3D(Basis.from_euler(Vector3(-0.04, 0, 0)), Vector3(-0.45, 1.32, -0.1))
		araba.motoru_calistir(true)
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
	var kulubeye := Vector2(araba.global_position.x - KULUBE_PARK.x, araba.global_position.z - KULUBE_PARK.z).length()
	if kulubeye < PARK_YARICAP and absf(araba.hiz) < 1.5:
		_ipucu("E  Arabadan in", 0.0)
		if Input.is_action_just_pressed("etkiles"):
			_inise_basla()
	elif ipucu.text == "E  Arabadan in":
		_ipucu("", 0.0)

func _inise_basla() -> void:
	_ipucu("", 0.0)
	araba.surulebilir = false
	araba.hiz = 0.0
	araba.motoru_calistir(false)
	araba.kapi("DFL_8", true)
	ses_kapi.global_position = _surucu_kapisi() + Vector3(0, 1, 0); ses_kapi.pitch_scale = 1.3; ses_kapi.volume_db = -10.0; ses_kapi.play()
	var kam := araba.get_node("Kamera") as Camera3D
	_gecis_bas = kam.global_transform
	# Selim kapının yanında, arabaya sırtı dönük durur
	var yer := araba.global_transform * Vector3(-1.9, 0.0, -0.2)
	oyuncu.global_position = Vector3(yer.x, araba.global_position.y + 0.3, yer.z)
	oyuncu.global_rotation = Vector3(0, araba.global_rotation.y + PI * 0.5, 0)
	(oyuncu.get_node("Kafa") as Node3D).rotation = Vector3.ZERO
	_gecis_bit = Transform3D(oyuncu.global_transform.basis, oyuncu.global_position + Vector3(0, 1.65, 0))
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
		_gec("kulube")



# ---------------- arayüz ve sesler ----------------
func _arayuz_kur() -> void:
	var cl := CanvasLayer.new(); cl.layer = 10; add_child(cl)
	siyah = ColorRect.new(); siyah.color = Color.BLACK
	siyah.set_anchors_preset(Control.PRESET_FULL_RECT); siyah.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cl.add_child(siyah)
	ipucu = Label.new()
	ipucu.add_theme_font_size_override("font_size", 26)
	ipucu.add_theme_color_override("font_color", Color(0.85, 0.85, 0.8, 0.85))
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

var _ipucu_bitis := 0
func _ipucu(metin: String, sure: float) -> void:
	ipucu.text = metin
	if sure > 0.0:
		var bu := Time.get_ticks_msec() + int(sure * 1000.0)
		_ipucu_bitis = bu
		get_tree().create_timer(sure).timeout.connect(func() -> void:
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
	_altyazi_bitis = Time.get_ticks_msec() / 1000.0 + sure
	return sure

# kapı kapanma ve çarpma sesi: kısa, boğuk bir gümleme
func _kapi_sesi() -> AudioStreamWAV:
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
var _konusma_sira := 0
var _satir_bitis := 0.0
var _bakis_bas: Basis

func _kulube() -> void:
	if _telefon == null:
		_telefon = $Kulube/Telefon
		_zil = AudioStreamPlayer3D.new(); _zil.stream = _zil_sesi(); _zil.unit_size = 3.0; _zil.max_db = 3.0
		_telefon.add_child(_zil)
	# Selim arabadan inince biraz sonra kulübedeki telefon çalmaya başlar
	if dt_durum > 2.5 and not _zil.playing and not _soylenen.has("cevap"):
		_zil.play()
		_ipucu("Kulübedeki telefon çalıyor", 6.0)
	var uzak := oyuncu.global_position.distance_to(_telefon.global_position)
	if uzak < 1.9 and _zil.playing:
		_ipucu("E  Telefonu aç", 0.0)
		if Input.is_action_just_pressed("etkiles"):
			_soylenen["cevap"] = true
			_zil.stop()
			_ipucu("", 0.0)
			_oyuncuyu_dondur(true)
			_bakis_bas = oyuncu_kamera.global_basis
			_konusma_sira = 0; _satir_bitis = 0.0
			_kisa_ses(_kapi_sesi(), _telefon.global_position, 2.2, -12.0)
			_gec("konusma")
	elif ipucu.text == "E  Telefonu aç":
		_ipucu("", 0.0)

func _konusma() -> void:
	# kamera ahizeye ve masaya doğru bakar
	var hedef := Basis.looking_at(_telefon.global_position + Vector3(0, -0.1, 0) - oyuncu_kamera.global_position)
	oyuncu_kamera.global_basis = _bakis_bas.slerp(hedef, smoothstep(0.0, 1.0, dt_durum)).orthonormalized()
	if dt_durum < 1.0: return
	if T_simdi() >= _satir_bitis:
		if _konusma_sira >= KONUSMA.size():
			_kisa_ses(_kapi_sesi(), _telefon.global_position, 2.4, -12.0)
			_oyuncuyu_dondur(false)
			_ipucu("Mazgala bak: kulübeden çık, caddenin ortası", 8.0)
			_gec("mazgala")
			return
		_satir_bitis = T_simdi() + _soyle(KONUSMA[_konusma_sira]) + 0.3
		_konusma_sira += 1

func T_simdi() -> float:
	return Time.get_ticks_msec() / 1000.0

func _oyuncuyu_dondur(dur: bool) -> void:
	oyuncu.set_physics_process(not dur)
	oyuncu.set_process_unhandled_input(not dur)
	if dur: oyuncu.velocity = Vector3.ZERO


# ---------------- mazgal: lamba söner, fener açılır, kenar çöker, düşüş ----------------
var _kenar_lamba: SpotLight3D
var _kenar_enerji := 0.0
var _titreme := 0.0
var _dusus_bas: Transform3D
var _ugultu: AudioStreamPlayer
var _ugultu_gen: AudioStreamGeneratorPlayback
var _ugultu_guc := 0.0
var _ugultu_faz := 0.0

func _mazgala() -> void:
	var yatay := Vector2(oyuncu.global_position.x - MAZGAL.x, oyuncu.global_position.z - MAZGAL.z).length()
	if yatay < 9.0 and not _soylenen.has("mirilti"): _soyle("mirilti")
	if yatay < 1.6:
		_oyuncuyu_dondur(true)
		_bakis_bas = oyuncu_kamera.global_basis
		_kenar_lamba = _en_yakin_lamba(MAZGAL)
		if _kenar_lamba: _kenar_enerji = _kenar_lamba.light_energy
		_ugultu_kur()
		_gec("kenar")

func _kenar(dt: float) -> void:
	# Selim mazgalın içine bakar
	var hedef := Basis.looking_at(MAZGAL + Vector3(0, -1.5, 0) - oyuncu_kamera.global_position)
	oyuncu_kamera.global_basis = _bakis_bas.slerp(hedef, smoothstep(0.0, 1.4, dt_durum)).orthonormalized()
	_ugultu_guc = 0.5 * smoothstep(0.3, 5.0, dt_durum)
	# yakındaki sokak lambası titrer ve söner
	if _kenar_lamba:
		if dt_durum < 1.9:
			_titreme -= dt
			if randf() < dt * 9.0: _titreme = randf_range(0.05, 0.15)
			_kenar_lamba.light_energy = _kenar_enerji * (randf_range(0.0, 0.5) if _titreme > 0.0 else 0.9)
		elif _kenar_lamba.visible:
			_kenar_lamba.visible = false
			for m in ["hale", "parilti"]:
				if _kenar_lamba.has_meta(m): (_kenar_lamba.get_meta(m) as Node3D).visible = false
			_kisa_ses(_kapi_sesi(), _kenar_lamba.global_position, 3.5, -16.0)
	var fener := oyuncu.get_node("Kafa/Kamera/Fener") as SpotLight3D
	if dt_durum > 2.8 and not fener.visible: fener.visible = true
	if dt_durum > 3.5 and not _soylenen.has("ses"): _soyle("ses")
	if dt_durum > 5.9:
		# kenar çöker
		_kisa_ses(_kapi_sesi(), oyuncu.global_position, 0.6, 4.0)
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
		_kisa_ses(_kapi_sesi(), yer, 0.7, 6.0)
	siyah.modulate.a = smoothstep(1.85, 2.25, t)
	_ugultu_guc = 0.5 + 0.3 * t / DUSUS
	ses_yagmur.volume_db = lerpf(-8.0, -40.0, t / DUSUS)
	if dt_durum >= DUSUS:
		_kisa_ses(_kapi_sesi(), yer, 0.5, 8.0)
		ses_yagmur.stop()
		_ugultu_guc = 0.0
		_gec("karanlik")

# labirent Godot'a taşınınca buradan ona geçilecek; şimdilik kayıt kesilir ve ana menüye dönülür
func _karanlik() -> void:
	siyah.modulate.a = 1.0
	if dt_durum > 2.5 and not _soylenen.has("kesildi"):
		_soylenen["kesildi"] = true
		altyazi.text = "KAYIT KESİLDİ"
		altyazi.visible = true
		_altyazi_bitis = T_simdi() + 4.0
	if dt_durum > 7.0:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		get_tree().change_scene_to_file("res://sahneler/baslangic.tscn")

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
