extends Node3D
## Selim'in evi. Oyuncu oynamaz, baştan sona sinematiktir ve hiçbir sahneyi geçme tuşu yoktur.
## 18:00 uyanır, bir kez duşa girer, mutfakta Nesquik yer, telefonda video kaydırır,
## salonda TV'deki anlatıcı yayınını izler (ana tema), kamera duvar saatine geçer,
## saat su gibi akıp 00:00'a gelir ve Selim nöbete çıkar.

const SONRAKI := "res://sahneler/sokak.tscn"
const TELEFON_VIDEOSU := "res://telefon/tiktok.ogv"   # alp'in telefon videosu gelince buraya konur

# Eski oyundaki TV yayını: [başlangıç, bitiş, tür]. Anlatıcı sesi bu sürede okunur.
const TV_SURE := 58.6
const YAYIN := [
	[0.0, 1.0, "ac"], [1.0, 11.8, "video"], [11.8, 16.0, "foto1"], [16.0, 20.5, "foto2"], [20.5, 25.5, "cubuk"],
	[25.5, 31.0, "foto4"], [31.0, 36.5, "foto3"], [36.5, 43.5, "video"], [43.5, 48.0, "cubuk"], [48.0, 53.0, "kar"], [53.0, 58.6, "oda"],
]
const SATIRLAR := {
	"ev1": ["res://sesler/selim_ev_01.mp3", "Of... yine aynı saçmalık."],
	"ev2": ["res://sesler/selim_ev_02.mp3", "Saat kaç olmuş ya..."],
	"ev3": ["res://sesler/selim_ev_03.mp3", "Hadi bakalım Selim. Nöbet var."],
}

# Odaların dünyadaki yerleri (ev.tscn ile aynı)
const SALON := Vector3(36, 0, 0)
const KOLTUK := Vector3(33.7, 1.12, -0.45)        # Selim'in koltuktaki göz hizası
const EKRAN := Vector3(38.228, 0.84, -0.4)        # TV ekranının ortası
const SAAT_YERI := Vector3(38.885, 2.05, -0.4)     # duvar saati (TV'nin üstünde)
const KASE := Vector3(27.4, 0.875, 1.18)            # Nesquik kâsesi

# Modeller (alp'in gönderdiği dosyalar)
const KAPI_MODELI := "res://modeller2/seliminevi/doors_stylish_glass_door.glb"
const SAAT_MODELI := "res://modeller2/seliminevi/vintage_wooden_wall_clock_- (1).glb"
const SEHPA_MODELI := "res://modeller2/seliminevi/tv_stand.glb"
const PAKET_MODELI := "res://modeller2/seliminevi/sigara_paketi.glb"
# Oda kapıları: [kapı ortası, yaw (yerel +x geçiş yönü), aynalı, karanlık koridor hangi yanda (yerel x: +1, -1, 0 yok)].
# Kapı açılınca kanat geçiş yönüne döner. Odalar ayrı yerlerde durduğu için kapının dışı karanlık koridor gibi kapatılır.
const KAPI_YATAK := [Vector3(3.30, 0.0, 1.6), 0.0, false, 1.0]
const KAPI_MUTFAK := [Vector3(28.33, 0.0, 2.55), 180.0, true, 0.0]
const KAPI_SALON := [Vector3(36.6, 0.0, 2.935), 90.0, false, -1.0]
const KAPI_EN := 1.07
const KAPI_BOY := 2.14

@onready var kamera: Camera3D = $Kamera
@onready var telefon: Node3D = $Kamera/Telefon
@onready var tv: Node3D = $TV
@onready var tv_isigi: SpotLight3D = $Isiklar/TVIsigi

var faz := ""
var ft := 0.0          # fazın içindeki süre
var T := 0.0           # toplam süre
var karartma := 1.0
var sallanti := 1.0
var _bitti := false

# arayüz
var siyah: ColorRect
var saat_yazi: Label
var altyazi: Label
var baslik: Label
var _daktilo := {}     # Label -> [başlangıç, harf süresi, ses]
var _altyazi_bitis := 0.0

# sesler
var ses_selim: AudioStreamPlayer
var ses_anlatici: AudioStreamPlayer
var ses_muzik: AudioStreamPlayer
var ses_tik: AudioStreamPlayer
var ses_bip: AudioStreamPlayer
var ses_gurultu: AudioStreamPlayer
var _gen: AudioStreamGeneratorPlayback
var _lp := 0.0
var _lp2 := 0.0
var su_ses := 0.0
var su_hedef := 0.0
var kar_ses := 0.0
var kar_hedef := 0.0

# TV
var tv_vp: SubViewport
var tv_video: VideoStreamPlayer
var tv_foto: TextureRect
var tv_cubuk: Control
var tv_oda_kamera: Camera3D
var tv_ust: ColorRect
var tv_zemin: ColorRect
var tv_acik := false
var tv_t := 0.0
var _tv_kare: Array = []
var _fotolar := {}

# telefon
var tel_vp: SubViewport
var tel_akis: Control
var tel_videolar: Array[VideoStreamPlayer] = []
var _kaydirma := 0

# saat ve kâse
var saat: Node3D
var akrep: Node3D
var yelkovan: Node3D
var _ibre_dinlenme := {}   # ibre -> [saatin içindeki duruşu, 12'den saat yönünde açısı]
var kapi_yatak: Node3D
var kapi_mutfak: Node3D
var kapi_salon: Node3D
var kapi_banyo: Node3D
var _banyo_acik: Transform3D
var _banyo_mentese := Vector3.ZERO
var ses_kapi: AudioStreamPlayer
var dakika := 20.0 * 60.0 + 10.0
var _saat_bas := 20.0 * 60.0 + 10.0
var _son_tik := 0.0
var kasik: Node3D
var su: GPUParticles3D
var buhar: GPUParticles3D


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	$Aksam.rotation_degrees = Vector3(-14, -115, 0)
	for n in $Salon.find_children("Sphere*", "Node3D", true, false):
		(n as Node3D).visible = false
	for oda in [$YatakOdasi, $Banyo, $Mutfak, $Salon]:
		_camlari_duzelt(oda)
	# Modellerin açık kalan duvarlarını odanın kendi duvar malzemesiyle kapat; kapıların yerinde boşluk kalır
	var tugla := _duvar_malzemesi($YatakOdasi, "Plane_002_Material_002_0", 0.6)
	var mutfak_duvar := _duvar_malzemesi($Mutfak, "pCube38_standardSurface1_0", 0.0)
	var beton_z := _duvar_malzemesi($Salon, "Plane_Material_003_0", 0.2)
	var beton_x := _duvar_malzemesi($Salon, "Plane_Material_002_0", 0.19)
	_kabuk(Vector3(-2.40, -0.04, -2.40), Vector3(3.22, 4.25, 3.35), {"+x": tugla, "+z": tugla}, null, {"+x": KAPI_YATAK[0].z})
	_kabuk(Vector3(-0.55, 0, -3.99) + Vector3(24, 0, 0), Vector3(4.25, 2.82, 3.50) + Vector3(24, 0, 0), {"-x": mutfak_duvar, "+x": mutfak_duvar, "-z": mutfak_duvar, "+z": mutfak_duvar}, mutfak_duvar, {"+x": KAPI_MUTFAK[0].z})
	_kabuk(Vector3(-2.855, 0, -2.855) + SALON, Vector3(2.855, 4.2, 2.855) + SALON, {"+x": beton_x, "+z": beton_z}, beton_x, {"+z": KAPI_SALON[0].x})
	kapi_yatak = _kapi_kur(KAPI_YATAK)
	kapi_mutfak = _kapi_kur(KAPI_MUTFAK)
	kapi_salon = _kapi_kur(KAPI_SALON)
	_banyo_kapisi_kur()
	_tv_sehpasi()
	_saat_kur()
	_paket_kur()
	_kase_kur()
	_dus_kur()
	_arayuz_kur()
	_sesler_kur()
	_tv_kur()
	_telefon_kur()
	_gec("uyanis")


# ---------------------------------------------------------------- akış
func _gec(ad: String) -> void:
	faz = ad
	ft = 0.0
	match ad:
		"dus": _saat_goster("18:20")
		"mutfak_giris": _saat_goster("19:05")
		"telefon":
			telefon.visible = true
			for v in tel_videolar: v.play()
		"salon_giris":
			_saat_goster("20:00")
			$Aksam.visible = false   # gece: güneş artık pencereden vurmaz
			($Ortam as WorldEnvironment).environment.ambient_light_energy = 0.2
		"saat":
			_saat_bas = 20.0 * 60.0 + 10.0 + T / 60.0
			dakika = _saat_bas
		"yayin":
			tv_acik = true
			tv_t = 0.0
			ses_anlatici.play()
			ses_muzik.play()


func _process(dt: float) -> void:
	if _bitti:
		return
	T += dt
	ft += dt
	sallanti = 1.0
	match faz:
		"uyanis": _uyanis()
		"dus": _dus()
		"mutfak_giris": _mutfak_giris()
		"kahvalti": _kahvalti()
		"telefon": _telefon()
		"salon_giris": _salon_giris()
		"salon": _salon()
		"yayin": _yayin()
		"geri": _geri()
		"saat": _saat()
		"cikis": _cikis()
	siyah.color.a = clampf(karartma, 0.0, 1.0)
	_tv_guncelle(dt)
	_daktilo_guncelle()
	if altyazi.visible and T > _altyazi_bitis:
		altyazi.visible = false
	_saat_ibreleri()
	_gurultu_doldur(dt)


func _uyanis() -> void:
	_yol([
		[0.0, Vector3(-1.95, 0.95, 0.15), Vector3(-1.4, 3.3, 0.35)],
		[4.0, Vector3(-1.95, 0.95, 0.15), Vector3(-1.6, 3.2, 0.6)],
		[5.5, Vector3(-1.9, 0.97, 0.25), Vector3(-2.25, 0.6, 1.3)],
		[7.0, Vector3(-1.9, 0.97, 0.2), Vector3(-1.0, 2.6, 0.4)],
		[9.0, Vector3(-1.2, 1.3, 0.25), Vector3(1.5, 1.25, 0.6)],
		[11.0, Vector3(-0.3, 1.25, 0.9), Vector3(0.3, 0.6, 2.6)],
		[12.8, Vector3(0.1, 1.63, 1.45), Vector3(1.4, 1.5, 0.2)],
		[14.6, Vector3(1.9, 1.65, 1.55), Vector3(3.6, 1.45, 1.6)],
		[15.8, Vector3(2.55, 1.65, 1.6), Vector3(4.2, 1.45, 1.6)],
		[17.0, Vector3(3.35, 1.65, 1.6), Vector3(5.0, 1.45, 1.6)],
	], ft)
	# odadan kapıyı açıp çıkar
	_kapi_ac(kapi_yatak, ft, 14.4, 15.6)
	karartma = _egri([[0, 1], [1.2, 1], [1.6, 0.35], [1.9, 0.9], [2.6, 0.15], [2.9, 0.6], [3.6, 0], [16.0, 0], [16.9, 1]], ft)
	# telefonun alarmı, uzanıp kapatana kadar öter
	if ft > 0.3 and ft < 5.3 and fmod(ft, 0.9) < 0.02 + get_process_delta_time():
		if not ses_bip.playing: ses_bip.play()
	if ft > 3.4 and not _daktilo.has(saat_yazi) and saat_yazi.text != "18:00":
		_saat_goster("18:00")
	if ft >= 17.0: _gec("dus")


func _dus() -> void:
	# koridordan banyo kapısını açıp girer
	_yol([
		[0.0, Vector3(11.55, 1.65, -2.95), Vector3(11.5, 1.45, 0.0)],
		[1.5, Vector3(11.55, 1.65, -2.75), Vector3(11.7, 1.4, 1.0)],
		[4.0, Vector3(11.5, 1.65, -0.9), Vector3(12.5, 1.4, 1.6)],
		[6.0, Vector3(11.6, 1.65, 0.1), Vector3(12.6, 1.5, 1.8)],
		[7.5, Vector3(12.45, 1.62, 0.9), Vector3(12.58, 1.7, 2.15)],
		[10.0, Vector3(12.5, 1.55, 1.1), Vector3(12.6, 1.0, 2.25)],
		[12.5, Vector3(12.5, 1.6, 1.0), Vector3(12.4, 1.9, 2.25)],
		[15.5, Vector3(12.5, 1.6, 1.0), Vector3(12.3, 1.3, 2.25)],
	], ft)
	_banyo_kapisi(ft)
	karartma = _egri([[0, 1], [0.8, 0], [14.7, 0], [15.5, 1]], ft)
	su.emitting = ft > 6.9 and ft < 15.1
	buhar.emitting = ft > 7.5
	su_hedef = 1.0 if su.emitting else 0.0
	if ft >= 15.5:
		su.emitting = false
		buhar.emitting = false
		su_hedef = 0.0
		_gec("mutfak_giris")


## Mutfağa kapıdan girer, masaya oturur.
func _mutfak_giris() -> void:
	var otur := Vector3(27.4, 1.25, 1.85)
	_yol([
		[0.0, Vector3(29.15, 1.65, 2.5), Vector3(27.6, 1.35, 2.2)],
		[1.4, Vector3(28.95, 1.65, 2.5), Vector3(27.4, 1.3, 2.0)],
		[3.2, Vector3(27.95, 1.6, 2.35), Vector3(27.35, 1.0, 1.4)],
		[4.6, otur, KASE],
	], ft)
	_kapi_ac(kapi_mutfak, ft, 0.4, 1.5)
	karartma = _egri([[0, 1], [0.8, 0]], ft)
	if ft >= 4.6: _gec("kahvalti")


func _kahvalti() -> void:
	var otur := Vector3(27.4, 1.25, 1.85)
	_yol([[0.0, otur, KASE], [11.0, otur, KASE + Vector3(0.05, 0, 0)]], ft)
	karartma = 0.0
	# kaşık: kâseden ağza, tekrar kâseye
	var d := fmod(ft + 0.4, 2.8)
	var kase_p := KASE + Vector3(sin(ft * 1.7) * 0.025, 0.035, cos(ft * 1.3) * 0.02)
	var agiz_p := kamera.global_transform * Vector3(0.0, -0.13, -0.2)
	var k := 0.0
	if d < 0.8: k = 0.0
	elif d < 1.5: k = smoothstep(0.8, 1.5, d)
	elif d < 1.9: k = 1.0
	else: k = 1.0 - smoothstep(1.9, 2.6, d)
	kasik.visible = ft < 10.0 and k < 0.8
	kasik.global_position = kase_p.lerp(agiz_p, k)
	var sap := kamera.global_transform * Vector3(0.16, -0.22, 0.05)
	kasik.look_at(sap, Vector3.UP)
	# ağza götürürken baş biraz eğilir
	kamera.global_position += -kamera.global_basis.z * 0.05 * k + Vector3(0, -0.04 * k, 0)
	if ft >= 11.0: _gec("telefon")


func _telefon() -> void:
	var otur := Vector3(27.4, 1.25, 1.85)
	_yol([[0.0, otur, KASE + Vector3(0.05, 0, 0)], [1.6, otur + Vector3(0, -0.02, 0), Vector3(27.4, 0.9, 1.2)], [12.0, otur + Vector3(0, -0.03, 0), Vector3(27.42, 0.89, 1.22)]], ft)
	karartma = _egri([[0, 0], [11.2, 0], [12, 1]], ft)
	sallanti = 0.6
	# telefon aşağıdan kaldırılır, kaydırdıkça hafif sallanır
	var kalk := smoothstep(0.3, 1.8, ft) * (1.0 - smoothstep(10.6, 11.8, ft))
	telefon.position = Vector3(0.0, lerpf(-0.45, -0.035, kalk), -0.215)
	telefon.rotation_degrees = Vector3(-8.0 + sin(T * 1.1) * 1.5, sin(T * 0.7) * 2.0, sin(T * 0.9) * 1.2)
	# her 2.3 saniyede bir sonraki videoya kaydırır
	if tel_akis:
		var hedef := int(floor(maxf(ft - 2.4, 0.0) / 2.3)) + (1 if ft > 2.4 else 0)
		hedef = mini(hedef, tel_akis.get_child_count() - 1)
		if hedef != _kaydirma:
			_kaydirma = hedef
			var tw := create_tween()
			tw.tween_property(tel_akis, "position:y", -720.0 * hedef, 0.32).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			_tik(1.8, -14.0)
	if ft >= 12.0:
		telefon.visible = false
		for v in tel_videolar: v.stop()
		_gec("salon_giris")


## Salona kapıdan girer, koltuğa oturur.
func _salon_giris() -> void:
	_yol([
		[0.0, Vector3(36.6, 1.65, 3.75), Vector3(36.4, 1.4, 1.0)],
		[1.4, Vector3(36.6, 1.65, 3.55), Vector3(36.2, 1.35, 0.6)],
		[3.0, Vector3(36.45, 1.65, 2.0), Vector3(35.2, 1.2, 0.0)],
		[4.6, Vector3(34.6, 1.5, 0.4), Vector3(33.6, 0.9, -0.5)],
		[6.2, KOLTUK + Vector3(0, 0, 0.05), EKRAN + Vector3(0, -0.05, 0)],
	], ft)
	_kapi_ac(kapi_salon, ft, 0.4, 1.5)
	if ft > 4.4: _kapi_ac(kapi_salon, ft, 5.6, 4.4)   # arkasından kapanır
	karartma = _egri([[0, 1], [0.8, 0]], ft)
	if ft >= 6.2: _gec("salon")


func _salon() -> void:
	_yol([[0.0, KOLTUK + Vector3(0, 0, 0.05), EKRAN + Vector3(0, -0.05, 0)], [7.0, KOLTUK, EKRAN]], ft)
	karartma = 0.0
	if ft > 1.2 and not _daktilo.has(baslik) and baslik.text == "":
		baslik.text = "MAZGAL"
		baslik.modulate.a = 1.0
		_daktilo_basla(baslik, 0.34, true)
	if ft > 5.0:
		baslik.modulate.a = maxf(0.0, 1.0 - (ft - 5.0) / 0.8)
	if ft >= 7.0: _gec("yayin")


func _yayin() -> void:
	_yol([[0.0, KOLTUK, EKRAN], [6.0, KOLTUK + Vector3(0.1, -0.02, 0), EKRAN], [18.0, Vector3(37.65, 0.86, -0.4), EKRAN]], ft)
	karartma = 0.0
	sallanti = 0.7
	# anlatıcının sesi bitince (dosya yoksa yayın süresi dolunca) biter
	var sure := ses_anlatici.stream.get_length() if ses_anlatici.stream else TV_SURE
	if ft >= sure + 0.6:
		ses_anlatici.stop()
		_gec("geri")


func _geri() -> void:
	_yol([[0.0, Vector3(37.65, 0.86, -0.4), EKRAN], [3.4, KOLTUK, EKRAN + Vector3(0, 0.05, 0)]], ft)
	if ft > 1.0 and not _soylendi("ev1"): _soyle("ev1")
	if ft >= 4.6: _gec("saat")


var _soylenenler := {}
func _soylendi(k: String) -> bool:
	return _soylenenler.has(k)


func _saat() -> void:
	var saat_on := SAAT_YERI + Vector3(-0.05, 0, 0)
	_yol([[0.0, KOLTUK, EKRAN + Vector3(0, 0.05, 0)], [3.0, KOLTUK, saat_on], [16.0, KOLTUK + Vector3(0.02, 0, 0), saat_on]], ft)
	if ft > 0.6 and not _soylendi("ev2"): _soyle("ev2")
	kamera.fov = lerpf(70.0, 7.0, smoothstep(0.8, 3.6, ft))
	sallanti = lerpf(1.0, 0.25, smoothstep(0.8, 3.6, ft))
	# saat su gibi akar: 20:10 -> 00:00
	var u := smoothstep(4.0, 13.0, ft)
	u = u * u * (3.0 - 2.0 * u)
	dakika = lerpf(_saat_bas, 24.0 * 60.0, u)
	if ft >= 16.0: _gec("cikis")


func _cikis() -> void:
	var saat_on := SAAT_YERI + Vector3(-0.05, 0, 0)
	_yol([
		[0.0, KOLTUK + Vector3(0.02, 0, 0), saat_on],
		[1.6, KOLTUK + Vector3(0.05, 0.03, 0.05), Vector3(36.0, 1.0, 1.5)],
		[3.3, Vector3(34.6, 1.65, 0.3), Vector3(36.3, 1.5, 2.5)],
		[5.0, Vector3(36.3, 1.65, 1.55), Vector3(36.6, 1.5, 3.2)],
		[6.6, Vector3(36.6, 1.65, 2.75), Vector3(36.6, 1.5, 4.5)],
	], ft)
	if ft > 0.3 and not _soylendi("ev3"): _soyle("ev3")
	kamera.fov = lerpf(7.0, 70.0, smoothstep(0.6, 2.0, ft))
	_kapi_ac(kapi_salon, ft, 4.5, 5.6)
	karartma = _egri([[0, 0], [5.6, 0], [6.6, 1]], ft)
	if ft >= 7.0:
		_bitti = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		get_tree().change_scene_to_file(SONRAKI)


# ---------------------------------------------------------------- kamera
## Anahtarlar: [süre, konum, bakılan nokta]. Catmull-Rom ile yumuşak geçer, elde taşınan kamera gibi hafif sallanır.
func _yol(anahtar: Array, t: float) -> void:
	var n := anahtar.size()
	var p: Vector3 = anahtar[n - 1][1]
	var b: Vector3 = anahtar[n - 1][2]
	if t <= anahtar[0][0]:
		p = anahtar[0][1]; b = anahtar[0][2]
	else:
		for i in n - 1:
			var t0: float = anahtar[i][0]
			var t1: float = anahtar[i + 1][0]
			if t >= t0 and t < t1:
				var u := (t - t0) / (t1 - t0)
				var i0 := maxi(i - 1, 0)
				var i3 := mini(i + 2, n - 1)
				p = _cr(anahtar[i0][1], anahtar[i][1], anahtar[i + 1][1], anahtar[i3][1], u)
				b = _cr(anahtar[i0][2], anahtar[i][2], anahtar[i + 1][2], anahtar[i3][2], u)
				break
	var s := sallanti
	p += Vector3(sin(T * 1.3) * 0.004 + sin(T * 2.9) * 0.002, sin(T * 0.9) * 0.006 + sin(T * 2.3) * 0.002, sin(T * 1.1) * 0.003) * s
	b += Vector3(sin(T * 0.7 + 1.0) * 0.012 + sin(T * 1.9) * 0.005, sin(T * 0.8 + 2.0) * 0.01, sin(T * 0.6) * 0.012) * s
	kamera.look_at_from_position(p, b, Vector3.UP)


func _cr(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, u: float) -> Vector3:
	var u2 := u * u
	var u3 := u2 * u
	return 0.5 * ((2.0 * p1) + (-p0 + p2) * u + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * u2 + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * u3)


func _egri(noktalar: Array, t: float) -> float:
	if t <= noktalar[0][0]: return noktalar[0][1]
	for i in noktalar.size() - 1:
		if t < noktalar[i + 1][0]:
			return lerpf(noktalar[i][1], noktalar[i + 1][1], (t - noktalar[i][0]) / (noktalar[i + 1][0] - noktalar[i][0]))
	return noktalar[noktalar.size() - 1][1]


# ---------------------------------------------------------------- ev parçaları
## Model camları opaksa saydam cama çevirir.
func _camlari_duzelt(oda: Node) -> void:
	var cam := StandardMaterial3D.new()
	cam.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cam.albedo_color = Color(0.6, 0.66, 0.68, 0.16)
	cam.metallic = 0.2
	cam.roughness = 0.08
	for m in oda.find_children("*", "MeshInstance3D", true, false):
		var mi := m as MeshInstance3D
		if mi.mesh == null: continue
		for i in mi.mesh.get_surface_count():
			var mat := mi.mesh.surface_get_material(i)
			if mat and "glass" in mat.resource_name.to_lower():
				if mat is BaseMaterial3D and (mat as BaseMaterial3D).transparency != BaseMaterial3D.TRANSPARENCY_DISABLED: continue
				mi.set_surface_override_material(i, cam)


## Odadaki bir duvarın malzemesini kopyalar; kutulara dünya hizasında (triplanar) döşenir.
## yogunluk 0 ise model atlas dokusu kullandığı için duvarın atlas bölgesi kutunun her yüzüne gerilir.
func _duvar_malzemesi(oda: Node, mesh_adi: String, yogunluk: float) -> Material:
	var mi := oda.find_child(mesh_adi, true, false) as MeshInstance3D
	if mi == null or mi.mesh == null:
		var yedek := StandardMaterial3D.new(); yedek.albedo_color = Color(0.4, 0.38, 0.36); return yedek
	var asil := mi.get_active_material(0)
	var m := asil.duplicate() as StandardMaterial3D
	if m == null: return asil
	if yogunluk > 0.0:
		m.uv1_triplanar = true
		m.uv1_world_triplanar = true
		m.uv1_scale = Vector3.ONE * yogunluk
		m.uv1_triplanar_sharpness = 4.0
		if m.normal_enabled or m.roughness_texture or m.ao_enabled:
			m.uv2_triplanar = false
	else:
		# mutfak: duvarın atlas bölgesi (0.01..0.24, 0.01..0.41), koyu sıvalı duvar
		m.uv1_scale = Vector3(0.2, 0.3, 1.0)
		m.uv1_offset = Vector3(0.02, 0.03, 0.0)
	return m


## Odanın açık kalan kenarlarına o odanın kendi duvar malzemesiyle duvar (ve istenirse tavan) çeker.
## kenarlar: {"+x": malzeme, ...}; kapilar: {"+x": kapının duvar boyunca ortası} — orada kapı boşluğu bırakılır.
func _kabuk(a: Vector3, b: Vector3, kenarlar: Dictionary, tavan: Material, kapilar := {}) -> void:
	var k := 0.1
	var bosluk := 0.03
	var boy := b.y - a.y
	var orta := (a + b) * 0.5
	var olcu := b - a
	var parcalar := []   # [merkez, ebat, malzeme]
	for kenar: String in kenarlar:
		var mat: Material = kenarlar[kenar]
		var x_duvari := kenar.ends_with("x")
		var sabit: float
		match kenar:
			"+x": sabit = b.x + bosluk + k * 0.5
			"-x": sabit = a.x - bosluk - k * 0.5
			"+z": sabit = b.z + bosluk + k * 0.5
			_: sabit = a.z - bosluk - k * 0.5
		var u0: float = (a.z if x_duvari else a.x) - 0.2
		var u1: float = (b.z if x_duvari else b.x) + 0.2
		var dilimler := []   # [u0, u1, y0, y1]
		if kapilar.has(kenar):
			var c: float = kapilar[kenar]
			var k0 := c - KAPI_EN * 0.5
			var k1 := c + KAPI_EN * 0.5
			var ust := a.y + 0.04 + KAPI_BOY
			dilimler.append([u0, k0, a.y, b.y])
			dilimler.append([k1, u1, a.y, b.y])
			dilimler.append([k0, k1, ust, b.y])
		else:
			dilimler.append([u0, u1, a.y, b.y])
		for d in dilimler:
			var um: float = (d[0] + d[1]) * 0.5
			var ue: float = d[1] - d[0]
			var ym: float = (d[2] + d[3]) * 0.5
			var ye: float = d[3] - d[2]
			if x_duvari: parcalar.append([Vector3(sabit, ym, um), Vector3(k, ye, ue), mat])
			else: parcalar.append([Vector3(um, ym, sabit), Vector3(ue, ye, k), mat])
	if tavan:
		parcalar.append([Vector3(orta.x, b.y + bosluk + k * 0.5, orta.z), Vector3(olcu.x + 0.4, k, olcu.z + 0.4), tavan])
	for p in parcalar:
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = p[1]
		bm.material = p[2]
		mi.mesh = bm
		mi.position = p[0]
		add_child(mi)


## Kapı modeli (alp'in gönderdiği cam şeritli kapı). Modelde birkaç kapı yan yana durur; ilki kullanılır:
## kasa "Cube_001", kanat "Cube_008", kol "Cube_015". Kanat menteşe ekseninde döner.
func _kapi_kur(tanim: Array) -> Node3D:
	var kok := Node3D.new()
	kok.name = "Kapi"
	add_child(kok)
	kok.position = tanim[0]
	kok.rotation_degrees.y = tanim[1]
	if tanim[2]: kok.scale = Vector3(1, 1, -1)
	var model: Node3D = (load(KAPI_MODELI) as PackedScene).instantiate()
	kok.add_child(model)
	var tut := ["Cube_001", "Cube_008", "Cube_015"]
	var rn := model.find_child("RootNode", true, false)
	if rn:
		for c in rn.get_children():
			if not (str(c.name) in tut): (c as Node3D).visible = false
	var mentese := Node3D.new()
	mentese.name = "Mentese"
	kok.add_child(mentese)
	mentese.position = Vector3(0, 0, 0.476)
	for ad in ["Cube_008", "Cube_015"]:
		var n := model.find_child(ad, true, false)
		if n: n.reparent(mentese, true)
	mentese.set_meta("k", 0.0)
	if float(tanim[3]) != 0.0:
		var karanlik := StandardMaterial3D.new()
		karanlik.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		karanlik.albedo_color = Color(0.008, 0.008, 0.01)
		var perde := MeshInstance3D.new()
		var bm := BoxMesh.new(); bm.size = Vector3(0.02, 3.0, 3.0); bm.material = karanlik
		perde.mesh = bm
		perde.position = Vector3(1.4 * float(tanim[3]), 1.5, 0.0)
		kok.add_child(perde)
	return mentese


## Kapıyı t0..t1 arasında açar (t0 > t1 verilirse kapatır). Açılırken gıcırtı, kapanınca tok ses.
func _kapi_ac(mentese: Node3D, t: float, t0: float, t1: float) -> void:
	if mentese == null: return
	var k := smoothstep(t0, t1, t)
	var once: float = mentese.get_meta("k", 0.0)
	if once < 0.02 and k >= 0.02: _kapi_sesi(true)
	if once > 0.02 and k <= 0.02: _kapi_sesi(false)
	mentese.set_meta("k", k)
	mentese.rotation.y = -PI * 0.5 * k * 0.95


## Banyonun kendi kapısı modelde açık durur; başta kapalıya çevrilir, Selim girerken açılır.
func _banyo_kapisi_kur() -> void:
	var m := $Banyo.find_child("Door_Door_material_0", true, false) as Node3D
	if m == null: return
	kapi_banyo = m.get_parent() as Node3D if m.get_parent() is Node3D and m.get_parent() != $Banyo else m
	_banyo_acik = kapi_banyo.global_transform
	_banyo_mentese = $Banyo.global_transform * Vector3(-0.92, 0.0, -1.49)
	kapi_banyo.set_meta("k", 1.0)
	_banyo_kapisi(0.0)


func _banyo_kapisi(t: float) -> void:
	if kapi_banyo == null: return
	var k := smoothstep(0.5, 1.7, t)
	var once: float = kapi_banyo.get_meta("k", 1.0)
	if once < 0.02 and k >= 0.02: _kapi_sesi(true)
	kapi_banyo.set_meta("k", k)
	# açık hali modelde 120 derece; kapalıyken kanat duvara oturur
	var don := Transform3D(Basis(Vector3.UP, deg_to_rad(-120.0) * (1.0 - k)), Vector3.ZERO)
	kapi_banyo.global_transform = Transform3D(Basis(), _banyo_mentese) * don * Transform3D(Basis(), -_banyo_mentese) * _banyo_acik


## TV sehpası modeli (Graham Rust). Ön yüzü koltuğa bakar, TV'nin altında durur.
func _tv_sehpasi() -> void:
	var m: Node3D = (load(SEHPA_MODELI) as PackedScene).instantiate()
	m.name = "TVSehpasi"
	add_child(m)
	m.scale = Vector3.ONE * 0.0104
	m.rotation_degrees.y = -90.0
	m.position = Vector3(38.5, 0.0, -0.4)


## Sigara paketi (logosu silinmiş): mutfakta Selim'in masasında, kâsenin yanında.
func _paket_kur() -> void:
	var m: Node3D = (load(PAKET_MODELI) as PackedScene).instantiate()
	m.name = "SigaraPaketi"
	add_child(m)
	m.position = KASE + Vector3(0.24, -0.025, -0.16)
	m.rotation_degrees.y = 28.0


func _malzeme(renk: Color, puruz := 0.6, metal := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = renk
	m.roughness = puruz
	m.metallic = metal
	return m


func _kutu(ebat: Vector3, mat: Material, konum: Vector3, ana: Node3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = ebat
	bm.material = mat
	mi.mesh = bm
	mi.position = konum
	ana.add_child(mi)
	return mi


func _silindir(r: float, h: float, mat: Material, konum: Vector3, ana: Node3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = r
	cm.bottom_radius = r
	cm.height = h
	cm.radial_segments = 48
	cm.material = mat
	mi.mesh = cm
	mi.position = konum
	mi.rotation_degrees.x = 90.0
	ana.add_child(mi)
	return mi


## Duvar saati modeli (Reinaw13). Yüzü +z'ye bakar, salonun duvarına asılır. Akrep ve yelkovan ayrı parçalardır.
func _saat_kur() -> void:
	saat = (load(SAAT_MODELI) as PackedScene).instantiate()
	saat.name = "DuvarSaati"
	add_child(saat)
	saat.position = SAAT_YERI + Vector3(-0.02, 0, 0)
	saat.rotation_degrees.y = -90.0
	saat.scale = Vector3.ONE * 0.42
	akrep = saat.find_child("Akrep", true, false) as Node3D
	yelkovan = saat.find_child("Yelkovan", true, false) as Node3D
	await get_tree().process_frame
	for ibre: Node3D in [akrep, yelkovan]:
		if ibre == null: continue
		# ibrenin ucu: saatin merkezinden en uzak köşesi, buradan şu anki açısı bulunur
		var yerel: Transform3D = saat.global_transform.affine_inverse() * ibre.global_transform
		var uc := Vector2.ZERO
		for m in ibre.find_children("*", "MeshInstance3D", true, false):
			var mi := m as MeshInstance3D
			var arr := mi.mesh.surface_get_arrays(0)
			var don: Transform3D = saat.global_transform.affine_inverse() * mi.global_transform
			for v: Vector3 in arr[0]:
				var w := don * v
				if Vector2(w.x, w.y).length() > uc.length(): uc = Vector2(w.x, w.y)
		_ibre_dinlenme[ibre] = [yerel, atan2(uc.x, uc.y)]


func _saat_ibreleri() -> void:
	var gercek := dakika
	if faz != "saat" and faz != "cikis":
		gercek = 20.0 * 60.0 + 10.0 + T / 60.0
	_ibre_koy(yelkovan, TAU * fmod(gercek, 60.0) / 60.0)
	_ibre_koy(akrep, TAU * fmod(gercek / 60.0, 12.0) / 12.0)
	# tik sesi: saat akarken sıklaşır, sonra yine saniyede bire iner
	var aralik := 1.0
	if faz == "saat":
		var hiz := smoothstep(4.0, 7.0, ft) * (1.0 - smoothstep(10.0, 13.0, ft))
		aralik = lerpf(1.0, 0.045, hiz)
	if (faz == "saat" or faz == "cikis" or faz == "geri") and T - _son_tik >= aralik:
		_son_tik = T
		_tik(1.0 + randf() * 0.08, -16.0 if aralik > 0.5 else -20.0)


## İbreyi saatin merkezinden 12 yönünden saat yönünde "aci" kadar çevirir.
func _ibre_koy(ibre: Node3D, aci: float) -> void:
	if ibre == null or not _ibre_dinlenme.has(ibre): return
	var d: Array = _ibre_dinlenme[ibre]
	var don := Transform3D(Basis(Vector3(0, 0, 1), -(aci - float(d[1]))), Vector3.ZERO)
	ibre.global_transform = saat.global_transform * don * (d[0] as Transform3D)


func _kase_kur() -> void:
	var k := Node3D.new()
	k.name = "NesquikKasesi"
	add_child(k)
	k.position = KASE + Vector3(0, -0.025, 0)
	var seramik := _malzeme(Color(0.92, 0.9, 0.86), 0.25)
	var sut := _malzeme(Color(0.5, 0.33, 0.22), 0.3)
	var top := _malzeme(Color(0.24, 0.13, 0.07), 0.55)
	var kase := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.085; cm.bottom_radius = 0.045; cm.height = 0.06; cm.radial_segments = 48
	cm.material = seramik
	kase.mesh = cm
	kase.position.y = 0.03
	k.add_child(kase)
	var yuzey := MeshInstance3D.new()
	var ym := CylinderMesh.new()
	ym.top_radius = 0.078; ym.bottom_radius = 0.078; ym.height = 0.002; ym.radial_segments = 48
	ym.material = sut
	yuzey.mesh = ym
	yuzey.position.y = 0.0605
	k.add_child(yuzey)
	var sm := SphereMesh.new()
	sm.radius = 0.0075; sm.height = 0.015; sm.radial_segments = 10; sm.rings = 6
	sm.material = top
	for i in 46:
		var a := randf() * TAU
		var r := sqrt(randf()) * 0.07
		var mi := MeshInstance3D.new()
		mi.mesh = sm
		mi.position = Vector3(cos(a) * r, 0.062 + randf() * 0.004, sin(a) * r)
		k.add_child(mi)
	# kaşık: baş başlangıç noktasında, sap -z yönünde (ele doğru) uzanır
	kasik = Node3D.new()
	kasik.name = "Kasik"
	add_child(kasik)
	var celik := _malzeme(Color(0.85, 0.85, 0.87), 0.35, 0.6)
	var bas := MeshInstance3D.new()
	var bs := SphereMesh.new()
	bs.radius = 0.02; bs.height = 0.012; bs.material = celik
	bas.mesh = bs
	bas.scale = Vector3(0.8, 1.0, 1.25)
	kasik.add_child(bas)
	_kutu(Vector3(0.008, 0.003, 0.15), celik, Vector3(0, 0.004, -0.09), kasik)


func _dus_kur() -> void:
	var bas := Vector3(12.58, 1.7, 2.12)
	su = GPUParticles3D.new()
	su.amount = 900
	su.lifetime = 0.7
	su.emitting = false
	su.position = bas
	su.visibility_aabb = AABB(Vector3(-1, -2, -1), Vector3(2, 2.2, 2))
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0, -1, -0.35)
	pm.spread = 9.0
	pm.initial_velocity_min = 2.6
	pm.initial_velocity_max = 3.2
	pm.gravity = Vector3(0, -9.8, 0)
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.03
	su.process_material = pm
	var damla := QuadMesh.new()
	damla.size = Vector2(0.004, 0.06)
	var dm := StandardMaterial3D.new()
	dm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dm.albedo_color = Color(0.85, 0.9, 1.0, 0.35)
	dm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dm.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	damla.material = dm
	su.draw_pass_1 = damla
	add_child(su)
	buhar = GPUParticles3D.new()
	buhar.amount = 60
	buhar.lifetime = 6.0
	buhar.emitting = false
	buhar.position = Vector3(12.5, 0.6, 1.3)
	buhar.visibility_aabb = AABB(Vector3(-2, -1, -2), Vector3(4, 4, 4))
	var bp := ParticleProcessMaterial.new()
	bp.direction = Vector3(0, 1, 0)
	bp.spread = 40.0
	bp.initial_velocity_min = 0.05
	bp.initial_velocity_max = 0.2
	bp.gravity = Vector3(0, 0.05, 0)
	bp.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	bp.emission_box_extents = Vector3(0.5, 0.5, 0.9)
	bp.scale_min = 0.8
	bp.scale_max = 1.6
	buhar.process_material = bp
	var bulut := QuadMesh.new()
	bulut.size = Vector2(0.9, 0.9)
	var bmat := ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = """shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled;
void vertex() { MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]); }
void fragment() {
	float d = length(UV - 0.5) * 2.0;
	ALBEDO = vec3(0.92, 0.93, 0.95);
	ALPHA = smoothstep(1.0, 0.0, d) * 0.06 * COLOR.a;
}
"""
	bmat.shader = sh
	bulut.material = bmat
	buhar.draw_pass_1 = bulut
	add_child(buhar)


# ---------------------------------------------------------------- arayüz ve sesler
func _arayuz_kur() -> void:
	var cl := CanvasLayer.new()
	cl.layer = 10
	add_child(cl)
	var daktilo_yazi := SystemFont.new()
	daktilo_yazi.font_names = PackedStringArray(["Courier New", "Courier", "Liberation Mono", "DejaVu Sans Mono", "monospace"])
	siyah = ColorRect.new()
	siyah.color = Color.BLACK
	siyah.set_anchors_preset(Control.PRESET_FULL_RECT)
	siyah.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cl.add_child(siyah)
	saat_yazi = Label.new()
	saat_yazi.add_theme_font_override("font", daktilo_yazi)
	saat_yazi.add_theme_font_size_override("font_size", 44)
	saat_yazi.add_theme_color_override("font_color", Color(0.9, 0.88, 0.8))
	saat_yazi.add_theme_color_override("font_outline_color", Color.BLACK)
	saat_yazi.add_theme_constant_override("outline_size", 8)
	saat_yazi.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	saat_yazi.position = Vector2(80, -130)
	saat_yazi.offset_top = -130; saat_yazi.offset_left = 80
	cl.add_child(saat_yazi)
	altyazi = Label.new()
	altyazi.add_theme_font_size_override("font_size", 34)
	altyazi.add_theme_color_override("font_color", Color(0.95, 0.95, 0.92))
	altyazi.add_theme_color_override("font_outline_color", Color.BLACK)
	altyazi.add_theme_constant_override("outline_size", 10)
	altyazi.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	altyazi.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	altyazi.offset_left = -800; altyazi.offset_right = 800; altyazi.offset_top = -150; altyazi.offset_bottom = -90
	altyazi.visible = false
	cl.add_child(altyazi)
	baslik = Label.new()
	baslik.add_theme_font_override("font", daktilo_yazi)
	baslik.add_theme_font_size_override("font_size", 150)
	baslik.add_theme_color_override("font_color", Color(0.88, 0.86, 0.8))
	baslik.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	baslik.add_theme_constant_override("outline_size", 14)
	baslik.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	baslik.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	baslik.set_anchors_preset(Control.PRESET_FULL_RECT)
	cl.add_child(baslik)


func _saat_goster(metin: String) -> void:
	saat_yazi.text = metin
	saat_yazi.modulate.a = 1.0
	_daktilo_basla(saat_yazi, 0.16, true)


func _daktilo_basla(l: Label, hiz: float, ses: bool) -> void:
	l.visible_characters = 0
	_daktilo[l] = [T, hiz, ses, 0]


func _daktilo_guncelle() -> void:
	for l in _daktilo.keys():
		var d: Array = _daktilo[l]
		var n := int((T - d[0]) / d[1]) + 1
		if n > d[3] and n <= l.text.length():
			d[3] = n
			l.visible_characters = n
			if d[2]: _tik(2.2 + randf() * 0.3, -10.0)
		if T - d[0] > d[1] * l.text.length() + 3.0:
			# saat yazısı birkaç saniye kalır, sonra söner
			if l == saat_yazi:
				l.modulate.a = maxf(0.0, l.modulate.a - get_process_delta_time())
				if l.modulate.a <= 0.0: _daktilo.erase(l)
			else:
				_daktilo.erase(l)


func _soyle(anahtar: String) -> void:
	_soylenenler[anahtar] = true
	var s: Array = SATIRLAR[anahtar]
	var akis: AudioStream = load(s[0]) if ResourceLoader.exists(s[0]) else null
	var sure := 2.6
	if akis:
		ses_selim.stream = akis
		ses_selim.play()
		sure = akis.get_length() + 0.6
	altyazi.text = "SELİM: " + s[1]
	altyazi.visible = true
	_altyazi_bitis = T + sure


func _sesler_kur() -> void:
	ses_selim = AudioStreamPlayer.new(); add_child(ses_selim)
	ses_anlatici = AudioStreamPlayer.new(); add_child(ses_anlatici)
	if ResourceLoader.exists("res://sesler/anlatici.mp3"):
		ses_anlatici.stream = load("res://sesler/anlatici.mp3")
	ses_anlatici.volume_db = -2.0
	ses_muzik = AudioStreamPlayer.new(); add_child(ses_muzik)
	if ResourceLoader.exists("res://sesler/muzik_5.mp3"):
		var m: AudioStream = load("res://sesler/muzik_5.mp3")
		if m is AudioStreamMP3: (m as AudioStreamMP3).loop = true
		ses_muzik.stream = m
	ses_muzik.volume_db = -15.0
	ses_tik = AudioStreamPlayer.new(); add_child(ses_tik)
	ses_tik.max_polyphony = 6
	ses_tik.stream = _tik_sesi()
	ses_bip = AudioStreamPlayer.new(); add_child(ses_bip)
	ses_bip.stream = _bip_sesi()
	ses_bip.volume_db = -12.0
	ses_kapi = AudioStreamPlayer.new(); add_child(ses_kapi)
	ses_kapi.volume_db = -10.0
	ses_gurultu = AudioStreamPlayer.new(); add_child(ses_gurultu)
	var g := AudioStreamGenerator.new()
	g.mix_rate = 22050.0
	g.buffer_length = 0.25
	ses_gurultu.stream = g
	ses_gurultu.play()
	_gen = ses_gurultu.get_stream_playback()


func _kapi_sesi(acilis: bool) -> void:
	if ses_kapi == null: return
	ses_kapi.stream = _gicirti_sesi() if acilis else _kapanma_sesi()
	ses_kapi.play()


# kapı açılırken: önce mandal tıkı, sonra menteşe gıcırtısı
func _gicirti_sesi() -> AudioStreamWAV:
	var o := PackedFloat32Array()
	var hiz := 22050
	var faz := 0.0
	for i in int(hiz * 1.1):
		var t := float(i) / hiz
		var tik := (randf() * 2.0 - 1.0) * exp(-t * 180.0) * 0.8
		var f := 520.0 + sin(t * 5.0) * 140.0 + t * 90.0
		faz += f / hiz
		var gic := (fmod(faz, 1.0) * 2.0 - 1.0) * 0.12 * smoothstep(0.08, 0.25, t) * (1.0 - smoothstep(0.7, 1.1, t)) * (0.6 + 0.4 * sin(t * 37.0))
		o.append(tik + gic)
	return _wav(o, hiz)


func _kapanma_sesi() -> AudioStreamWAV:
	var o := PackedFloat32Array()
	var hiz := 22050
	var dusuk := 0.0
	for i in int(hiz * 0.4):
		var t := float(i) / hiz
		dusuk = lerpf(dusuk, randf() * 2.0 - 1.0, 0.08)
		o.append((sin(TAU * 70.0 * t) * 0.6 + dusuk * 1.2) * exp(-t * 16.0) + (randf() * 2.0 - 1.0) * 0.3 * exp(-t * 120.0))
	return _wav(o, hiz)


func _tik(perde: float, db: float) -> void:
	ses_tik.pitch_scale = perde
	ses_tik.volume_db = db
	ses_tik.play()


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


func _tik_sesi() -> AudioStreamWAV:
	var o := PackedFloat32Array()
	var hiz := 22050
	for i in int(hiz * 0.03):
		var t := float(i) / hiz
		o.append((sin(TAU * 2400.0 * t) * 0.5 + (randf() * 2.0 - 1.0) * 0.5) * exp(-t * 260.0))
	return _wav(o, hiz)


func _bip_sesi() -> AudioStreamWAV:
	var o := PackedFloat32Array()
	var hiz := 22050
	for i in int(hiz * 0.5):
		var t := float(i) / hiz
		var acik := 1.0 if fmod(t, 0.125) < 0.08 else 0.0
		o.append(sin(TAU * 1760.0 * t) * 0.35 * acik)
	return _wav(o, hiz)


## Duş suyu ve TV karı için gürültü üretir.
func _gurultu_doldur(dt: float) -> void:
	if _gen == null: return
	su_ses = move_toward(su_ses, su_hedef, dt * 1.5)
	kar_ses = move_toward(kar_ses, kar_hedef, dt * 6.0)
	var n := _gen.get_frames_available()
	for i in n:
		var w := randf() * 2.0 - 1.0
		_lp += (w - _lp) * 0.18
		_lp2 += (_lp - _lp2) * 0.5
		var s := _lp2 * su_ses * 0.55 + w * kar_ses * 0.05
		_gen.push_frame(Vector2(s, s))


# ---------------------------------------------------------------- TV
func _tv_kur() -> void:
	tv_vp = SubViewport.new()
	tv_vp.size = Vector2i(640, 480)
	tv_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(tv_vp)
	tv_zemin = ColorRect.new()
	tv_zemin.color = Color.BLACK
	tv_zemin.size = Vector2(640, 480)
	tv_vp.add_child(tv_zemin)
	tv_video = VideoStreamPlayer.new()
	if ResourceLoader.exists("res://tv/video1.ogv"):
		tv_video.stream = load("res://tv/video1.ogv")
	tv_video.loop = true
	tv_video.expand = true
	tv_video.volume_db = -80.0
	tv_video.size = Vector2(854, 480)
	tv_video.position = Vector2(-107, 0)
	tv_video.visible = false
	tv_vp.add_child(tv_video)
	tv_foto = TextureRect.new()
	tv_foto.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tv_foto.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	tv_foto.size = Vector2(640, 480)
	tv_foto.pivot_offset = Vector2(320, 240)
	tv_foto.visible = false
	tv_vp.add_child(tv_foto)
	for k in ["foto1", "foto2", "foto3", "foto4"]:
		var yol := "res://tv/%s.jpg" % k
		if ResourceLoader.exists(yol): _fotolar[k] = load(yol)
	# gece kuşağı renk çubukları
	tv_cubuk = Control.new()
	tv_cubuk.size = Vector2(640, 480)
	tv_cubuk.visible = false
	tv_vp.add_child(tv_cubuk)
	var renkler := [Color("c0c0c0"), Color("c0c000"), Color("00c0c0"), Color("00c000"), Color("c000c0"), Color("c00000"), Color("0000c0")]
	for i in 7:
		var r := ColorRect.new()
		r.color = renkler[i]
		r.position = Vector2(i * 640.0 / 7.0, 0)
		r.size = Vector2(640.0 / 7.0 + 1.0, 480 * 0.68)
		tv_cubuk.add_child(r)
	var alt := ColorRect.new()
	alt.color = Color(0.07, 0.07, 0.07)
	alt.position = Vector2(0, 480 * 0.68); alt.size = Vector2(640, 480 * 0.32)
	tv_cubuk.add_child(alt)
	var yazi := SystemFont.new()
	yazi.font_names = PackedStringArray(["Courier New", "Courier", "Liberation Mono", "DejaVu Sans Mono", "monospace"])
	yazi.font_weight = 700
	for satir in [["GECE KUŞAĞI · KAMU YAYINI", 34, 360], ["YAYINIMIZ BİRAZDAN DEVAM EDECEKTİR", 24, 420]]:
		var l := Label.new()
		l.text = satir[0]
		l.add_theme_font_override("font", yazi)
		l.add_theme_font_size_override("font_size", satir[1])
		l.add_theme_color_override("font_color", Color(0.87, 0.87, 0.87))
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.size = Vector2(640, 40)
		l.position = Vector2(0, satir[2] - 24)
		tv_cubuk.add_child(l)
	# "oda" karesi: TV, Selim'in oturduğu salonu gösterir
	tv_oda_kamera = Camera3D.new()
	tv_oda_kamera.fov = 62.0
	tv_oda_kamera.cull_mask = 1
	tv_vp.add_child(tv_oda_kamera)
	tv_oda_kamera.current = false
	# tüp efekti: tarama çizgileri, gren, kayan bant, köşe kararması, açılış çizgisi
	tv_ust = ColorRect.new()
	tv_ust.size = Vector2(640, 480)
	var sm := ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = """shader_type canvas_item;
uniform sampler2D ekran : hint_screen_texture, filter_linear_mipmap;
uniform float zaman = 0.0;
uniform float kar = 0.08;
uniform float kar_tam = 0.0;
uniform float acilis = 1.0;
uniform float kesit = 0.0;
float h(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
void fragment() {
	vec2 uv = SCREEN_UV;
	float satir = floor(uv.y * 240.0);
	uv.x += (h(vec2(satir, floor(zaman * 20.0))) - 0.5) * 0.02 * kesit * step(0.93, h(vec2(floor(zaman * 9.0), floor(satir / 8.0))));
	vec3 c = textureLod(ekran, uv, 0.6).rgb;
	float g = dot(c, vec3(0.299, 0.587, 0.114));
	c = mix(vec3(g), c, 0.7);
	c = (c - 0.5) * 1.18 + 0.53;
	float n = h(floor(uv * vec2(320.0, 240.0)) + vec2(fract(zaman * 13.1) * 91.0, fract(zaman * 7.7) * 57.0));
	c = mix(c, vec3(n), kar);
	c = mix(c, vec3(n * 0.85 + 0.08), kar_tam);
	c *= 0.74 + 0.26 * step(0.5, fract(uv.y * 160.0));
	float by = fract(zaman * 0.12) * 1.3 - 0.15;
	c += 0.07 * smoothstep(0.08, 0.0, abs(uv.y - by));
	float v = length((uv - 0.5) * vec2(1.0, 1.1));
	c *= smoothstep(0.8, 0.3, v);
	float acik = step(abs(uv.y - 0.5), max(acilis * 0.5, 0.003)) * step(0.0001, acilis);
	c = mix(vec3(0.0), c, acik);
	c += vec3(0.9) * (1.0 - smoothstep(0.0, 0.3, acilis)) * acik;
	COLOR = vec4(clamp(c, 0.0, 1.0), 1.0);
}
"""
	sm.shader = sh
	tv_ust.material = sm
	tv_vp.add_child(tv_ust)
	# ekran: TV'nin tüp camının hemen önündeki yüzey (TV'nin kendi ölçeğinde)
	var ekran := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(2.6, 2.05)
	ekran.mesh = qm
	ekran.position = Vector3(0, 1.7, 1.112)
	ekran.layers = 2
	var em := StandardMaterial3D.new()
	em.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	em.albedo_texture = tv_vp.get_texture()
	ekran.material_override = em
	tv.add_child(ekran)
	(tv_ust.material as ShaderMaterial).set_shader_parameter("acilis", 0.0)


func _tv_guncelle(dt: float) -> void:
	var um := tv_ust.material as ShaderMaterial
	um.set_shader_parameter("zaman", T)
	if not tv_acik:
		tv_isigi.light_energy = 0.0
		kar_hedef = 0.0
		return
	tv_t += dt
	var t := tv_t if tv_t < TV_SURE else 1.0 + fmod(tv_t - 1.0, TV_SURE - 1.0)
	var kare: Array = YAYIN[YAYIN.size() - 1]
	for k in YAYIN:
		if t < k[1]:
			kare = k
			break
	var tur: String = kare[2]
	var u := clampf((t - kare[0]) / (kare[1] - kare[0]), 0.0, 1.0)
	if kare != _tv_kare:
		_tv_kare = kare
		tv_video.visible = tur == "video"
		tv_foto.visible = tur.begins_with("foto")
		tv_cubuk.visible = tur == "cubuk"
		tv_oda_kamera.current = tur == "oda"
		tv_zemin.visible = tur != "oda"   # siyah zemin 3B görüntünün üstünü örtmesin
		if tur == "video":
			tv_video.play()
		else:
			tv_video.stop()
		if tur.begins_with("foto") and _fotolar.has(tur):
			tv_foto.texture = _fotolar[tur]
		if tur == "oda":
			tv_oda_kamera.global_position = SALON + Vector3(2.5, 2.4, 2.5)
			tv_oda_kamera.look_at(KOLTUK + Vector3(0, -0.2, 0), Vector3.UP)
	# kare içi hareketler
	if tur.begins_with("foto"):
		var yon := -0.5 if tur == "foto2" else 0.4
		tv_foto.scale = Vector2.ONE * lerpf(1.12, 1.0, u)
		tv_foto.position = Vector2(yon * 30.0 * (u - 0.5), 10.0 * (u - 0.5))
	if tur == "cubuk":
		(tv_cubuk.get_child(tv_cubuk.get_child_count() - 1) as Label).position.x = -(u - 0.5) * 640.0 * 0.15
	if tur == "oda":
		tv_oda_kamera.global_position += Vector3(-0.08, 0, -0.05) * dt
	var acilis := smoothstep(0.0, 0.45, t) if tur == "ac" else 1.0
	um.set_shader_parameter("acilis", acilis)
	var gecis: bool = t - kare[0] < 0.12 and kare[0] > 0.0
	var kar := 0.95 if gecis else (0.9 - (t - 0.45) * 1.2 if tur == "ac" and t > 0.45 else 0.08)
	um.set_shader_parameter("kar", clampf(kar, 0.06, 0.95))
	um.set_shader_parameter("kar_tam", 1.0 if tur == "kar" else 0.0)
	um.set_shader_parameter("kesit", 1.0)
	kar_hedef = 1.0 if (tur == "kar" or gecis or (tur == "ac" and t > 0.4)) else 0.12
	if faz != "yayin": kar_hedef *= 0.5
	# TV ışığı salona vurur, kareye göre titrer
	var guc := 0.55 if tur == "kar" else (0.9 if tur == "cubuk" else 0.65)
	tv_isigi.light_energy = 3.0 * guc * (0.85 + randf() * 0.3) * (acilis if tur == "ac" else 1.0)
	tv_isigi.light_color = Color(0.7, 0.75, 0.95) if tur != "cubuk" else Color(0.85, 0.8, 0.85)


# ---------------------------------------------------------------- telefon
func _telefon_kur() -> void:
	tel_vp = SubViewport.new()
	tel_vp.size = Vector2i(360, 720)
	tel_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(tel_vp)
	var zemin := ColorRect.new()
	zemin.color = Color.BLACK
	zemin.size = Vector2(360, 720)
	tel_vp.add_child(zemin)
	if ResourceLoader.exists(TELEFON_VIDEOSU):
		# alp'in kaydettiği telefon videosu
		var v := VideoStreamPlayer.new()
		v.stream = load(TELEFON_VIDEOSU)
		v.expand = true
		v.size = Vector2(360, 720)
		tel_vp.add_child(v)
		tel_videolar.append(v)
	else:
		# video gelene kadar: dikey video akışı
		tel_akis = Control.new()
		tel_vp.add_child(tel_akis)
		var icerik := ["video", "foto1", "foto3", "video", "foto4", "foto2"]
		var adlar := ["@gece.nobeti", "@sehir_isiklari", "@yagmurlu_sokak", "@kanal.34", "@eski_kaset", "@bilinmeyen_hesap"]
		var aciklama := ["bu saatte kim izliyor bunu", "gece 3'te çektim...", "sesi açın", "kimse inanmadı", "bulduğum kaset", "arkanıza bakmayın"]
		for i in icerik.size():
			var kart := Control.new()
			kart.position = Vector2(0, i * 720)
			kart.size = Vector2(360, 720)
			kart.clip_contents = true
			tel_akis.add_child(kart)
			if icerik[i] == "video" and tv_video.stream:
				var v := VideoStreamPlayer.new()
				v.stream = tv_video.stream
				v.expand = true
				v.loop = true
				v.volume_db = -80.0
				v.size = Vector2(1280, 720)
				v.position = Vector2(-460 + i * 37, 0)
				kart.add_child(v)
				tel_videolar.append(v)
			elif _fotolar.has(icerik[i]):
				var f := TextureRect.new()
				f.texture = _fotolar[icerik[i]]
				f.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				f.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
				f.size = Vector2(360, 720)
				kart.add_child(f)
			var golge := ColorRect.new()
			golge.color = Color(0, 0, 0, 0.35)
			golge.position = Vector2(0, 560); golge.size = Vector2(360, 160)
			kart.add_child(golge)
			var ad := Label.new()
			ad.text = adlar[i]
			ad.add_theme_font_size_override("font_size", 20)
			ad.position = Vector2(14, 610)
			kart.add_child(ad)
			var ac := Label.new()
			ac.text = aciklama[i]
			ac.add_theme_font_size_override("font_size", 17)
			ac.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
			ac.position = Vector2(14, 640)
			kart.add_child(ac)
			for j in 3:
				var dugme := Panel.new()
				var st := StyleBoxFlat.new()
				st.bg_color = Color(1, 1, 1, 0.85) if j == 0 else Color(0.15, 0.15, 0.15, 0.6)
				st.set_corner_radius_all(22)
				dugme.add_theme_stylebox_override("panel", st)
				dugme.position = Vector2(305, 380 + j * 80)
				dugme.size = Vector2(44, 44)
				kart.add_child(dugme)
				var sayi := Label.new()
				sayi.text = ["", "%d,%dB" % [3 + i * 7 % 40, i * 3 % 10], "%d" % (120 + i * 53)][j]
				sayi.add_theme_font_size_override("font_size", 14)
				sayi.position = Vector2(300, 428 + j * 80)
				kart.add_child(sayi)
		var ust := Label.new()
		ust.text = "Takip        Sana Özel"
		ust.add_theme_font_size_override("font_size", 19)
		ust.position = Vector2(92, 30)
		tel_vp.add_child(ust)
	var ekran := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(3.09, 6.2)
	ekran.mesh = qm
	ekran.position = Vector3(0, 0.235, 0.18)
	var em := StandardMaterial3D.new()
	em.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	em.albedo_texture = tel_vp.get_texture()
	ekran.material_override = em
	telefon.add_child(ekran)
