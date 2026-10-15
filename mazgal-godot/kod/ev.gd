extends Node3D
## Selim'in evi. Hiçbir sahneyi geçme tuşu yoktur.
## 18:00 uyanır (sinematik). Banyo, mutfak, telefon ve salona giriş oyuncunun elindedir:
## E ile etkileşir, fare tekerleğiyle telefonda video kaydırır, Q ile telefonu bırakır.
## Koltuğa oturunca TV'deki anlatıcı yayını, duvar saati ve çıkış yine sinematiktir.

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
	# iç ses: alp okuyunca dosyalar sesler/ klasörüne bu adlarla konur; dosya yokken yalnız altyazı çıkar
	"ic01": ["res://sesler/selim_ic_01.mp3", "Bu ışık da hep bozuk zaten."],
	"ic02": ["res://sesler/selim_ic_02.mp3", "Dolapta ne kaldıysa artık..."],
	"ic03": ["res://sesler/selim_ic_03.mp3", "Fatura da gelmiş. Sonra bakarım."],
	"ic04": ["res://sesler/selim_ic_04.mp3", "Tamam abi, tamam... ne zaman geç kaldım ki."],
}

# Odaların dünyadaki yerleri (ev.tscn ile aynı)
const SALON := Vector3(36, 0, 0)
const KOLTUK := Vector3(33.7, 1.12, -0.45)        # Selim'in koltuktaki göz hizası
const EKRAN := Vector3(38.228, 0.84, -0.4)        # TV ekranının ortası
const SAAT_YERI := Vector3(38.885, 2.05, -0.4)     # duvar saati (TV'nin üstünde)
const KASE := Vector3(27.4, 0.875, 1.18)            # Nesquik kâsesinin yeri (model gelince konacak)
const TEL_YATAK := Vector3(-1.5, 0.715, 0.8)        # uyanınca telefon yatağın üstünde
const TEL_MASA := Vector3(27.12, 0.865, 1.35)       # mutfak masasında
const TEL_OLCEK := 0.0217
const ALARM_KAPAN := 7.3
const BANYO_LAMBA := Vector3(11.79, 2.3, 0.79)
const LAVABO := Vector3(11.25, 0.9, -0.56)
const AYNA := Vector3(11.1, 1.62, -0.56)
const DUS_KAPI := Vector3(12.4, 1.2, 0.6)
const DOLAP := Vector3(24.38, 1.9, -3.1)            # mutfağın üst dolabı (Nesquik, kâse)
const BUZDOLABI_MODELI := "res://modeller2/seliminevi/buzdolabi.glb"   # alp gönderince
const BUZDOLABI_YERI := Vector3(24.2, 1.0, 2.4)
# Oyuncunun dolaşabileceği alanlar (odalar ve kapının önündeki koridor)
const BANYO_ALAN := [AABB(Vector3(11.08, 0, -3.35), Vector3(0.84, 3, 1.95)), AABB(Vector3(10.95, 0, -1.5), Vector3(2.1, 3, 3.7))]   # kapı önündeki dar koridor + banyo
const MUTFAK_ALAN := [AABB(Vector3(23.7, 0, -3.6), Vector3(4.6, 3, 6.9)), AABB(Vector3(28.2, 0, 1.95), Vector3(1.6, 3, 1.2))]
const SALON_ALAN := [AABB(Vector3(33.3, 0, -2.7), Vector3(5.4, 3, 5.5)), AABB(Vector3(36.0, 0, 2.7), Vector3(1.2, 3, 1.55))]
const YURUME := 1.7
const GOZ := 1.48
## Sinematik yollar 1.62 göz hizasıyla yazıldı; Selim kısaltıldı, ayakta duran kareler bu kadar alçalır.
const BOY_FARK := 0.14
const Eller := preload("res://kod/eller.gd")
const Kagit := preload("res://kod/kagit.gd")

# Modeller (alp'in gönderdiği dosyalar)
const KAPI_MODELI := "res://modeller2/seliminevi/doors_stylish_glass_door.glb"
const SAAT_MODELI := "res://modeller2/seliminevi/vintage_wooden_wall_clock_- (1).glb"
const SEHPA_MODELI := "res://modeller2/seliminevi/tv_stand.glb"
const PAKET_MODELI := "res://modeller2/seliminevi/sigara/sigara_paketi.gltf"
# Oda kapıları: [kapı ortası, yaw (yerel +x geçiş yönü), aynalı, karanlık koridor hangi yanda (yerel x: +1, -1, 0 yok)].
# Kapı açılınca kanat geçiş yönüne döner. Odalar ayrı yerlerde durduğu için kapının dışı karanlık koridor gibi kapatılır.
const KAPI_YATAK := [Vector3(3.30, 0.0, 1.6), 0.0, false, 1.0]
const KAPI_MUTFAK := [Vector3(28.33, 0.0, 2.55), 180.0, true, 0.0]
const KAPI_SALON := [Vector3(36.6, 0.0, 2.935), 90.0, false, -1.0]
# koridor dibindeki giriş kapıları (dışarısı karanlık perde)
const KAPI_BANYO_GIRIS := [Vector3(11.49, -0.01, -3.575), 90.0, false, 1.0]
const KAPI_MUTFAK_GIRIS := [Vector3(29.925, 0.0, 2.55), 0.0, false, 1.0]
const KAPI_SALON_GIRIS := [Vector3(36.6, 0.0, 4.325), -90.0, false, 1.0]
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
var kapi_banyo_giris: Node3D
var kapi_mutfak_giris: Node3D
var kapi_salon_giris: Node3D
var kapi_banyo: Node3D
var _banyo_acik: Transform3D
var _banyo_mentese := Vector3.ZERO
var ses_kapi: AudioStreamPlayer
var dakika := 20.0 * 60.0 + 10.0
var _saat_bas := 20.0 * 60.0 + 10.0
var _son_tik := 0.0
var _kapi_kokleri: Array[Node] = []
var su: GPUParticles3D
var buhar: GPUParticles3D

# oynanabilir kısım
var eller: Eller
var oyuncu: CharacterBody3D
var _yaw := 0.0
var _pitch := 0.0
var _kutular: Array = []
var _oturuyor := false
var _otur_konum := Vector3.ZERO
var _bob := 0.0
var _adim_t := 0.0
var _eylem := {}      # fazın içinde bir kez olan şeyler
var _zaman := {}      # kapı, lamba: ne zaman başladı
var _esyalar := {}    # ad -> [konum, menzil]
var _secili := ""
var _bas_konum := Vector3.ZERO
var _bas_bakis := Vector3.ZERO
var damla := 0.0
var damla_hedef := 0.0
var ayna_bugu := 0.0
var _ayna_mat: StandardMaterial3D
var _damla_mat: ShaderMaterial
var _damla_rect: ColorRect
var _dolap: Array = []
var tel_isigi: OmniLight3D
var tel_alarm: Control
var tel_bildirim: Control
var tel_ekran_mi: MeshInstance3D
var _kaydirilan := 0
var ses_alarm: AudioStreamPlayer
var ses_titresim: AudioStreamPlayer
var _ses_havuz: Array[AudioStreamPlayer] = []
var _sesler := {}
var gorev_yazi: Label
var e_yazi: Label
var _gorev_hedef := 0.0


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
	_dus_kur()
	_ayna_kur()
	# yatak odası kapısının dışında kısa, loş bir hol: kapı açılınca boşluk görünmesin
	_koridor(Vector3(3.27, -0.04, 0.85), Vector3(4.7, 2.45, 2.35), "-x")
	_koridor(Vector3(10.88, -0.01, -3.55), Vector3(12.1, 2.45, -1.52), "+z", true)
	_koridor(Vector3(28.4, 0, 1.95), Vector3(29.9, 2.5, 3.15), "-x", true)
	_koridor(Vector3(35.95, 0, 2.97), Vector3(37.25, 2.5, 4.3), "-z", true)
	# koridor kapılarının ardında da kısa holler: açılınca boşluk görünmesin
	_koridor(Vector3(10.74, -0.01, -5.0), Vector3(12.24, 2.45, -3.6), "+z")
	_koridor(Vector3(29.95, 0, 1.8), Vector3(31.35, 2.5, 3.3), "-x")
	# koridorların dibindeki kapılar: Selim bir odadan bunlardan geçerek öbürüne gelir
	kapi_banyo_giris = _kapi_kur(KAPI_BANYO_GIRIS)
	kapi_mutfak_giris = _kapi_kur(KAPI_MUTFAK_GIRIS)
	kapi_salon_giris = _kapi_kur(KAPI_SALON_GIRIS)
	_arayuz_kur()
	_oyun_arayuzu_kur()
	_damla_kur()
	_sesler_kur()
	_oyun_sesleri_kur()
	_tv_kur()
	_telefon_kur()
	_tel_ekstra_kur()
	_kagitlar_kur()
	_telefon_yataga()
	_oyuncu_kur()
	_carpisma_kur()
	eller = Eller.new()
	kamera.add_child(eller)
	# "Devam Et" ile gelindiyse kaydedilen noktadan başlar
	var d := get_node_or_null("/root/Duraklat")
	var nokta: String = str(d.baslangic_noktasi) if d else ""
	if d: d.baslangic_noktasi = ""
	_gec(nokta if nokta in KAYIT_NOKTALARI else "uyanis")


# ---------------------------------------------------------------- akış
const KAYIT_NOKTALARI := ["banyo", "mutfak", "salon_kapisi"]

func _gec(ad: String) -> void:
	faz = ad
	ft = 0.0
	_eylem.clear()
	if ad in KAYIT_NOKTALARI:
		var d := get_node_or_null("/root/Duraklat")
		if d: d.kayit_noktasi(scene_file_path, ad)
	match ad:
		"banyo": _banyo_basla()
		"mutfak": _mutfak_basla()
		"salon_kapisi": _salon_basla()
		"salon": Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
		"saat":
			_saat_bas = 20.0 * 60.0 + 10.0 + T / 60.0
			dakika = _saat_bas
		"yayin":
			tv_acik = true
			tv_t = 0.0
			ses_anlatici.play()
			ses_muzik.play()
			_crt_ac(true)


func _process(dt: float) -> void:
	if _bitti:
		return
	T += dt
	ft += dt
	sallanti = 1.0
	match faz:
		"uyanis": _uyanis()
		"oyun": _oyun_kamera(dt)
		"s_lavabo": _s_lavabo()
		"s_dus": _s_dus()
		"gecis": _gecis_oyna()
		"s_buzdolabi": _s_buzdolabi()
		"s_dolap": _s_dolap()
		"s_masa": _s_masa()
		"s_tel_al": _s_tel_al()
		"tel_kaydir": _tel_kaydir()
		"s_tel_birak": _s_tel_birak()
		"s_koltuk": _s_koltuk()
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
	_ev_guncelle(dt)
	_secim_guncelle()


# ---------------------------------------------------------------- 1. uyanma (sinematik)
## Karanlık oda, perdeden akşam ışığı. Telefonda alarm çalar, titrer, ekranı odayı aydınlatır.
## Gözler bulanık açılır, kırpılır. Selim uzanıp alarmı kapatır, doğrulur, ayakları yere basar,
## sendeleyerek kalkar, kapıyı açıp çıkar.
func _uyanis() -> void:
	_yol([
		[0.0, Vector3(-1.95, 0.95, 0.15), Vector3(-1.4, 3.3, 0.35)],
		[3.6, Vector3(-1.95, 0.95, 0.15), Vector3(-1.6, 3.2, 0.6)],
		[5.2, Vector3(-1.92, 0.97, 0.2), TEL_YATAK + Vector3(0, 0.05, 0)],
		[8.2, Vector3(-1.9, 0.98, 0.25), TEL_YATAK],
		[9.6, Vector3(-1.9, 0.97, 0.2), Vector3(-1.0, 2.6, 0.4)],
		[12.2, Vector3(-1.25, 1.18, 0.95), Vector3(-1.05, 0.0, 2.3)],
		[14.0, Vector3(-1.2, 1.2, 1.05), Vector3(-0.9, 0.05, 2.4)],
		[15.6, Vector3(-1.05, 1.63, 1.45), Vector3(0.6, 1.4, 1.9)],
		[17.4, Vector3(0.6, 1.64, 1.55), Vector3(3.6, 1.45, 1.6)],
		[19.2, Vector3(2.3, 1.65, 1.6), Vector3(4.2, 1.45, 1.6)],
		[20.6, Vector3(3.35, 1.65, 1.6), Vector3(5.0, 1.45, 1.6)],
	], ft)
	# göz kırpma ve bulanık açılış
	karartma = _egri([[0, 1], [1.2, 1], [1.8, 0.4], [2.1, 0.92], [2.9, 0.2], [3.2, 0.7], [4.2, 0.0], [6.3, 0.0], [6.45, 0.85], [6.7, 0.0], [20.0, 0]], ft)
	_bulanik(_egri([[0, 0.32], [2.0, 0.3], [5.0, 0.12], [7.5, 0.0], [14.6, 0.0], [15.4, 0.05], [16.3, 0.0]], ft))
	# kalkarken sendeleme
	var sendele := smoothstep(14.0, 15.0, ft) * (1.0 - smoothstep(16.5, 18.0, ft))
	sallanti = 1.0 + sendele * 5.0
	kamera.rotation.z += sin(ft * 2.3) * 0.05 * sendele
	# alarm: telefon titrer, ekranı yanıp söner; Selim uzanıp kapatır
	var alarm := ft > 0.3 and ft < ALARM_KAPAN
	if alarm and not ses_alarm.playing:
		ses_alarm.play(); ses_titresim.play()
	if not alarm and ses_alarm.playing:
		ses_alarm.stop(); ses_titresim.stop()
		_tik(1.5, -8.0)
		tel_alarm.visible = false
		tel_ekran_mi.visible = false
	var titre := alarm and fmod(ft, 1.0) < 0.42
	telefon.position = TEL_YATAK + (Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)) * 0.0016 if titre else Vector3.ZERO)
	tel_isigi.position = TEL_YATAK + Vector3(0, 0.12, 0)
	tel_isigi.light_energy = (0.16 + 0.06 * sin(ft * 9.0)) if alarm else move_toward(tel_isigi.light_energy, 0.0, get_process_delta_time() * 0.4)
	if ft > 6.2 and not _eylem.has("uzan"):
		_eylem["uzan"] = true
		eller.uzan("sag", TEL_YATAK + Vector3(0.0, 0.06, -0.02), 1.0)
	if ft > ALARM_KAPAN + 0.35 and not _eylem.has("geri_cek"):
		_eylem["geri_cek"] = true
		eller.birak("sag", 0.9)
	# nefes, iç çekiş, çarşaf, yatak, yalın ayak adımlar
	if ft > 2.0 and not _eylem.has("nefes"):
		_eylem["nefes"] = true; _ses_cal("nefes_agir", -6.0)
	if ft > 9.2 and not _eylem.has("ic_cekis"):
		_eylem["ic_cekis"] = true; _ses_cal("ic_cekis", -4.0)
	if ft > 9.8 and not _eylem.has("carsaf"):
		_eylem["carsaf"] = true; _ses_cal("carsaf", -8.0)
	if ft > 12.0 and not _eylem.has("yatak1"):
		_eylem["yatak1"] = true; _ses_cal("yatak_gicirti", -10.0)
	if ft > 14.4 and not _eylem.has("yatak2"):
		_eylem["yatak2"] = true; _ses_cal("yatak_gicirti", -7.0)
	if ft > 15.0 and ft < 20.2:
		_adim_say(0.62)
	if ft > 3.4 and not _daktilo.has(saat_yazi) and saat_yazi.text != "18:00":
		_saat_goster("18:00")
	_kapi_ac(kapi_yatak, ft, 18.4, 19.6)
	if ft >= 20.6:
		_bulanik(0.0)
		# yatak odası kapısının eşiğinden banyo koridorunun kapısına geçer
		_gecis_basla([], null, Vector2.ZERO, 0.0, kapi_banyo_giris, _giris_yolu(KAPI_BANYO_GIRIS, Vector3(11.55, 0, -3.0), PI), "banyo")


# ---------------------------------------------------------------- oynanabilir ev
## Banyo: koridordan başlar. Kapı, ışık, lavabo, duş.
func _banyo_basla() -> void:
	_saat_goster("18:20")
	_oyuncu_yerlestir(Vector3(11.55, 0.0, -3.0), PI, BANYO_ALAN)
	$Isiklar/BanyoLamba.light_energy = 0.0
	_gorev("Duş al")
	_esya("banyo_kapi", Vector3(11.48, 1.05, -1.47), 2.1)
	get_tree().create_timer(2.0).timeout.connect(func() -> void: if not _soylendi("ic01"): _soyle("ic01"))


## Mutfak: kapının önünden başlar.
func _mutfak_basla() -> void:
	_saat_goster("19:05")
	_oyuncu_yerlestir(Vector3(29.25, 0.0, 2.5), PI * 0.5, MUTFAK_ALAN)
	_gorev("Bir şeyler ye")
	get_tree().create_timer(2.5).timeout.connect(func() -> void: if not _soylendi("ic02"): _soyle("ic02"))
	_esya("mutfak_kapi", KAPI_MUTFAK[0] + Vector3(0, 1.05, 0), 2.0)
	# telefon masada, ekranı kapalı
	telefon.visible = true
	_tel_ekran(false)
	telefon.position = TEL_MASA
	telefon.rotation = Vector3(-PI * 0.5, 0.35, 0)
	telefon.scale = Vector3.ONE * TEL_OLCEK


## Salon: kapının önünden başlar, koltuğa oturunca TV sinematiği başlar.
func _salon_basla() -> void:
	_saat_goster("20:00")
	$Aksam.visible = false   # gece: güneş artık pencereden vurmaz
	($Ortam as WorldEnvironment).environment.ambient_light_energy = 0.2
	_oyuncu_yerlestir(Vector3(36.6, 0.0, 3.8), 0.0, SALON_ALAN)
	_esya("salon_kapi", KAPI_SALON[0] + Vector3(0, 1.05, 0), 2.0)


func _etkiles(ad: String) -> void:
	_esya_kaldir(ad)
	match ad:
		"banyo_kapi":
			_zaman["banyo_kapi"] = T
			_esya("banyo_isik", BANYO_LAMBA, 3.4)
		"banyo_isik":
			_zaman["banyo_isik"] = T
			_ses_cal("floresan_tik", -6.0)
			_esya("lavabo", LAVABO, 1.7)
			# duşa lavaboyu beklemeden de girilebilir
			_esya("dus", DUS_KAPI, 2.6)
		"lavabo": _sahne("s_lavabo")
		"dus":
			_esya_kaldir("lavabo")
			_sahne("s_dus")
		"banyo_cikis":
			_sahne("gecis")
			_gecis_basla([[0.0, _bas_konum, _bas_bakis],
					[1.2, Vector3(11.5, 1.62, -1.9), Vector3(11.5, 1.5, -3.5)],
					[2.5, Vector3(11.49, 1.62, -3.05), Vector3(11.49, 1.5, -4.6)],
					[3.2, Vector3(11.49, 1.62, -3.575), Vector3(11.49, 1.5, -5.0)]],
				kapi_banyo_giris, Vector2(1.7, 2.6), 3.2,
				kapi_mutfak_giris, _giris_yolu(KAPI_MUTFAK_GIRIS, Vector3(29.25, 0, 2.5), PI * 0.5), "mutfak")
			_gorev("")
		"mutfak_kapi":
			_zaman["mutfak_kapi"] = T
			if ResourceLoader.exists(BUZDOLABI_MODELI): _esya("buzdolabi", BUZDOLABI_YERI, 2.0)
			else: _esya("dolap", DOLAP, 2.0)
		"buzdolabi": _sahne("s_buzdolabi")
		"dolap": _sahne("s_dolap")
		"masa": _sahne("s_masa")
		"telefon": _sahne("s_tel_al")
		"salon_kapi":
			_zaman["salon_kapi"] = T
			_esya("koltuk", KOLTUK + Vector3(0.2, -0.5, 0), 3.2)
		"koltuk": _sahne("s_koltuk")


## Kilitli kısa sahne: kamera oyuncunun baktığı yerden başlar.
func _sahne(ad: String) -> void:
	_bas_konum = _ham(kamera.global_position)
	_bas_bakis = kamera.global_position - kamera.global_basis.z * 1.5
	_gec(ad)


func _s_lavabo() -> void:
	var dur := Vector3(11.78, 1.6, -0.56)
	_yol([[0.0, _bas_konum, _bas_bakis], [1.2, dur, LAVABO + Vector3(0, -0.1, 0)], [5.6, dur + Vector3(-0.08, -0.12, 0), LAVABO], [6.6, dur, AYNA], [11.0, dur + Vector3(-0.03, 0, 0), AYNA + Vector3(0, 0.02, 0)]], ft)
	if ft > 1.0 and not _eylem.has("l_el"):
		_eylem["l_el"] = true
		eller.uzan("sag", LAVABO + Vector3(0.12, 0.12, 0.1), 0.7)
		eller.uzan("sol", LAVABO + Vector3(0.12, 0.12, -0.12), 0.7)
		su_hedef = 0.6
	if ft > 2.6 and not _eylem.has("l_yuz"):
		_eylem["l_yuz"] = true
		eller.kamerada("sag", Vector3(0.07, -0.15, -0.24), 0.5)
		eller.kamerada("sol", Vector3(-0.07, -0.15, -0.24), 0.5)
		_ses_cal("su_carpma", -6.0)
	if ft > 3.2 and not _eylem.has("l_damla"):
		_eylem["l_damla"] = true; damla_hedef = 1.0
	if ft > 4.2 and not _eylem.has("l_birak"):
		_eylem["l_birak"] = true
		eller.birak("sag", 0.6); eller.birak("sol", 0.6)
		su_hedef = 0.0
	# aynada kendine bakar, ayna buğulanır
	ayna_bugu = clampf((ft - 6.0) / 5.0, 0.0, 0.85) if ft > 6.0 else ayna_bugu
	if ft >= 11.0:
		_oyuna_don()
		_esya("dus", DUS_KAPI, 2.6)


func _s_dus() -> void:
	_yol([
		[0.0, _bas_konum, _bas_bakis],
		[1.4, Vector3(12.3, 1.62, 0.55), Vector3(12.58, 1.5, 2.1)],
		[2.6, Vector3(12.5, 1.62, 1.05), Vector3(12.6, 1.7, 2.2)],
		[3.4, Vector3(12.5, 1.55, 1.05), Vector3(12.6, 1.0, 2.25)],
		[3.7, Vector3(12.44, 1.6, 0.95), Vector3(12.5, 1.9, 2.25)],
		[7.0, Vector3(12.5, 1.6, 1.0), Vector3(12.4, 1.9, 2.25)],
		[11.0, Vector3(12.5, 1.6, 1.0), Vector3(12.3, 1.3, 2.25)],
	], ft)
	if ft > 2.4 and not _eylem.has("d_ac"):
		_eylem["d_ac"] = true
		eller.uzan("sag", Vector3(12.6, 1.13, 2.1), 0.6)
	if ft > 3.0 and not _eylem.has("d_birak"):
		_eylem["d_birak"] = true
		eller.birak("sag", 0.5)
	su.emitting = ft > 3.1 and ft < 10.8
	su_hedef = 1.0 if su.emitting else 0.0
	# su önce soğuk: Selim irkilir, titrer; sonra ısınır, buhar çıkar
	if ft > 3.3 and not _eylem.has("d_irkil"):
		_eylem["d_irkil"] = true; _ses_cal("irkilme", -3.0)
	var soguk := smoothstep(3.2, 3.4, ft) * (1.0 - smoothstep(5.0, 6.5, ft))
	sallanti = 1.0 + soguk * 6.0
	kamera.rotation.z += sin(ft * 31.0) * 0.012 * soguk
	buhar.emitting = ft > 6.0
	if ft > 6.0: damla_hedef = 0.8
	karartma = _egri([[0, 0], [10.0, 0], [11.0, 1]], ft)
	if ft >= 11.6:
		su.emitting = false; buhar.emitting = false; su_hedef = 0.0
		damla_hedef = 0.0
		_oyuncu_yerlestir(Vector3(11.75, 0.0, -0.9), 0.0, BANYO_ALAN)
		_gorev("Mutfağa geç")
		_esya("banyo_cikis", Vector3(11.48, 1.05, -1.47), 1.6)


# ---------------------------------------------------------------- kapıdan kapıya geçiş
## Siyah ekran yok: Selim A odasının kapısını açıp eşiğe kadar yürür, aynı anda B odasının giriş
## kapısının eşiğinden içeri girer, kapı arkasından kapanır. Odalar ayrı modeller olduğu için eşikte geçilir.
var _gecis := {}

func _gecis_basla(a_yol: Array, a_kapi: Node3D, a_ac: Vector2, kesme: float, b_kapi: Node3D, b_yol: Array, sonraki: String) -> void:
	_gecis = {"a_yol": a_yol, "a_kapi": a_kapi, "a_ac": a_ac, "kesme": kesme, "b_kapi": b_kapi, "b_yol": b_yol, "sonraki": sonraki}
	_gec("gecis")


## Giriş kapısının eşiğinden odadaki başlangıç yerine yürüyen kamera yolu (son kare oyuncunun bakışıyla aynı).
func _giris_yolu(kapi: Array, hedef: Vector3, yaw: float) -> Array:
	var ileri := Vector3(-sin(yaw), 0.0, -cos(yaw))
	var esik := Vector3(kapi[0].x, 1.62, kapi[0].z)
	# eşik, kapının hedefe bakan ekseninde
	if absf(ileri.x) > absf(ileri.z): esik.z = hedef.z
	else: esik.x = hedef.x
	var son := Vector3(hedef.x, 1.62, hedef.z)
	var bakis_son := Vector3(hedef.x, GOZ, hedef.z) + Vector3(ileri.x, sin(-0.08), ileri.z)
	var sure := maxf(0.9, esik.distance_to(son) / 0.55)
	return [[0.0, esik, esik + ileri * 2.0 + Vector3(0, -0.1, 0)], [sure, son, bakis_son]]


func _kapi_kolu(mentese: Node3D) -> Vector3:
	var kol := mentese.find_child("Cube_015", true, false) as Node3D
	if kol == null: return mentese.global_position + Vector3(0, 1.0, 0)
	return _dunya_kutusu(kol).get_center()


func _gecis_oyna() -> void:
	karartma = 0.0
	var g := _gecis
	var kesme: float = g["kesme"]
	if ft < kesme:
		_yol(g["a_yol"], ft)
		var kapi: Node3D = g["a_kapi"]
		if kapi:
			var ac: Vector2 = g["a_ac"]
			_kapi_ac(kapi, ft, ac.x, ac.y)
			if ft > ac.x - 0.5 and not _eylem.has("kol"):
				_eylem["kol"] = true
				eller.uzan("sag", _kapi_kolu(kapi), 0.5)
			if ft > ac.x + 0.35 and not _eylem.has("kol_birak"):
				_eylem["kol_birak"] = true
				eller.birak("sag", 0.5)
		_adim_say(0.55)
		return
	var b_kapi: Node3D = g["b_kapi"]
	if not _eylem.has("esik"):
		_eylem["esik"] = true
		eller.birak("sag", 0.01)
		# giriş kapısı açık durur, Selim geçince arkasından kapanır
		b_kapi.set_meta("k", 1.0)
		b_kapi.rotation.y = -PI * 0.5 * 0.95
	var t := ft - kesme
	var b_yol: Array = g["b_yol"]
	_yol(b_yol, t)
	var bitis: float = b_yol[b_yol.size() - 1][0]
	_kapi_ac(b_kapi, t, bitis + 0.6, bitis - 0.2)
	_adim_say(0.55)
	if t >= bitis + 0.6:
		_gec(g["sonraki"])


func _s_buzdolabi() -> void:
	_yol([[0.0, _bas_konum, _bas_bakis], [1.0, BUZDOLABI_YERI + Vector3(1.0, 0.5, 0), BUZDOLABI_YERI], [5.0, BUZDOLABI_YERI + Vector3(1.0, 0.5, 0), BUZDOLABI_YERI + Vector3(0, -0.2, 0)]], ft)
	if ft > 0.8 and not _eylem.has("b_el"):
		_eylem["b_el"] = true
		eller.uzan("sag", BUZDOLABI_YERI + Vector3(0.35, 0.0, 0.0), 0.8)
	if ft > 2.6 and not _eylem.has("b_birak"):
		_eylem["b_birak"] = true
		eller.birak("sag", 0.7)
	if ft >= 5.0:
		_oyuna_don()
		_esya("dolap", DOLAP, 2.0)


func _s_dolap() -> void:
	_yol([[0.0, _bas_konum, _bas_bakis], [1.0, Vector3(25.45, 1.64, -2.95), DOLAP + Vector3(0, -0.15, 0)], [4.6, Vector3(25.45, 1.64, -2.95), DOLAP + Vector3(0, -0.22, 0)]], ft)
	var acik := smoothstep(1.0, 1.7, ft) * (1.0 - smoothstep(3.6, 4.3, ft))
	_dolap_kapaklari(acik)
	if ft > 1.6 and not _eylem.has("do_el"):
		_eylem["do_el"] = true
		eller.uzan("sag", DOLAP + Vector3(0.15, -0.05, 0.1), 0.7)
		_ses_cal("dolap", -10.0)
	if ft > 2.8 and not _eylem.has("do_birak"):
		_eylem["do_birak"] = true
		eller.birak("sag", 0.7)
	if ft >= 4.6:
		_oyuna_don()
		_esya("masa", Vector3(27.35, 0.85, 1.0), 1.9)


func _s_masa() -> void:
	var otur := Vector3(27.4, 1.25, 1.85)
	_yol([[0.0, _bas_konum, _bas_bakis], [1.6, Vector3(27.5, 1.6, 2.2), KASE], [2.6, otur, KASE], [9.0, otur, KASE + Vector3(0.05, 0, 0)]], ft)
	if ft > 1.8 and not _eylem.has("m_sandalye"):
		_eylem["m_sandalye"] = true; _ses_cal("sandalye", -8.0)
	if ft > 9.2 and not _soylendi("ic03"): _soyle("ic03")
	if ft > 3.0 and not _eylem.has("m_dok"):
		_eylem["m_dok"] = true; _ses_cal("dokme", -6.0)
	# kaşıkla yer: el kâseyle ağız arasında gidip gelir
	if ft > 4.4 and ft < 8.6:
		var tur := int((ft - 4.4) / 2.1)
		var d := fmod(ft - 4.4, 2.1)
		if not _eylem.has("m_%d" % tur):
			_eylem["m_%d" % tur] = true
			eller.uzan("sag", KASE + Vector3(0.05, 0.05, 0.08), 0.5)
			eller.yumruk("sag", 0.6)
		if d > 0.8 and not _eylem.has("m_a%d" % tur):
			_eylem["m_a%d" % tur] = true
			eller.kamerada("sag", Vector3(0.03, -0.14, -0.2), 0.45)
			_ses_cal("cigneme", -9.0)
	if ft > 8.7 and not _eylem.has("m_birak"):
		_eylem["m_birak"] = true
		eller.birak("sag", 0.6)
	if ft >= 9.0:
		_gorev("")
		_otur(otur, KASE + Vector3(0.05, 0, 0))
		_esya("telefon", TEL_MASA, 1.2)


func _s_tel_al() -> void:
	var otur := Vector3(27.4, 1.25, 1.85)
	_yol([[0.0, _bas_konum, _bas_bakis], [0.8, otur, TEL_MASA], [2.2, otur + Vector3(0, -0.02, 0), Vector3(27.4, 0.9, 1.2)]], ft)
	if ft > 0.3 and not _eylem.has("t_el"):
		_eylem["t_el"] = true
		eller.uzan("sag", TEL_MASA + Vector3(0, 0.03, 0.04), 0.6)
	if ft > 1.0 and not _eylem.has("t_al"):
		_eylem["t_al"] = true
		telefon.reparent(kamera, true)
		_tel_ekran(true)
		eller.kamerada("sag", Vector3(0.04, -0.19, -0.22), 0.6)
	if ft > 1.0:
		var k := smoothstep(1.0, 1.8, ft)
		telefon.position = telefon.position.lerp(Vector3(0.0, -0.035, -0.215), k)
		telefon.rotation = telefon.rotation.lerp(Vector3(deg_to_rad(-8.0), 0, 0), k)
		telefon.scale = Vector3.ONE * TEL_OLCEK
	if ft >= 2.2:
		_gec("tel_kaydir")
		_gorev("Fare tekerleği: kaydır")


## Telefonda video kaydırır; bir süre sonra bildirim gelir, Q ile telefon masaya ters bırakılır.
func _tel_kaydir() -> void:
	var otur := Vector3(27.4, 1.25, 1.85)
	_yol([[0.0, otur + Vector3(0, -0.02, 0), Vector3(27.4, 0.9, 1.2)], [20.0, otur + Vector3(0, -0.03, 0), Vector3(27.42, 0.89, 1.22)]], ft)
	sallanti = 0.6
	telefon.position = Vector3(0.0, -0.035, -0.215)
	telefon.rotation_degrees = Vector3(-8.0 + sin(T * 1.1) * 1.5, sin(T * 0.7) * 2.0, sin(T * 0.9) * 1.2)
	eller.kamerada("sag", Vector3(0.04, -0.19, -0.22), 0.01)
	eller.yumruk("sag", 0.45)
	if (_kaydirilan >= 4 or ft > 16.0) and not tel_bildirim.visible:
		tel_bildirim.visible = true
		_ses_cal("bildirim", -10.0)
		get_tree().create_timer(2.2).timeout.connect(func() -> void: if not _soylendi("ic04"): _soyle("ic04"))
		_zaman["bildirim"] = T
		_gorev("Q  Telefonu bırak")
	if tel_bildirim.visible:
		var u := clampf((T - float(_zaman["bildirim"])) / 0.4, 0.0, 1.0)
		tel_bildirim.position.y = lerpf(-120.0, 18.0, u)


func _s_tel_birak() -> void:
	var otur := Vector3(27.4, 1.25, 1.85)
	_yol([[0.0, otur, Vector3(27.42, 0.89, 1.22)], [1.2, otur, TEL_MASA], [3.4, otur + Vector3(0.1, 0.3, 0.2), Vector3(29, 1.4, 2.6)]], ft)
	if not _eylem.has("tb"):
		_eylem["tb"] = true
		_gorev("")
		telefon.reparent(self, true)
		eller.uzan("sag", TEL_MASA + Vector3(0, 0.05, 0.04), 0.9)
	# telefon masaya ekranı aşağı bakacak şekilde konur
	var k := smoothstep(0.1, 1.0, ft)
	telefon.global_position = telefon.global_position.lerp(TEL_MASA, k)
	telefon.global_rotation = telefon.global_rotation.lerp(Vector3(PI * 0.5, 0.35, 0), k)
	if ft > 1.0 and not _eylem.has("tb_ses"):
		_eylem["tb_ses"] = true
		_ses_cal("telefon_masa", -8.0)
		_tel_ekran(false)
		eller.birak("sag", 0.6)
	if ft >= 3.4:
		# kalkar, mutfak kapısından koridora, oradan dipteki kapıdan salonun koridoruna geçer
		var bas := Vector3(27.4, 1.25, 1.85) + Vector3(0.1, 0.3, 0.2)
		_gecis_basla([[0.0, bas, Vector3(29, 1.4, 2.6)],
				[1.1, Vector3(28.0, 1.62, 2.45), Vector3(29.6, 1.5, 2.55)],
				[2.2, Vector3(28.95, 1.62, 2.55), Vector3(30.6, 1.5, 2.55)],
				[3.3, Vector3(29.55, 1.62, 2.55), Vector3(31.0, 1.5, 2.55)],
				[3.9, Vector3(29.925, 1.62, 2.55), Vector3(31.3, 1.5, 2.55)]],
			kapi_mutfak_giris, Vector2(2.4, 3.3), 3.9,
			kapi_salon_giris, _giris_yolu(KAPI_SALON_GIRIS, Vector3(36.6, 0, 3.8), 0.0), "salon_kapisi")


func _s_koltuk() -> void:
	_yol([[0.0, _bas_konum, _bas_bakis], [1.8, Vector3(34.5, 1.5, 0.2), KOLTUK + Vector3(-0.3, -0.5, -0.2)], [3.2, KOLTUK + Vector3(0, 0, 0.05), EKRAN + Vector3(0, -0.05, 0)]], ft)
	if ft > 2.4 and not _eylem.has("k_cok"):
		_eylem["k_cok"] = true; _ses_cal("koltuk", -6.0)
	if ft >= 3.2:
		# kapı arkasından kapanır, TV sinematiği başlar
		_zaman.erase("salon_kapi")
		_kapi_ac(kapi_salon, 0.0, 0.0, 1.0)
		_gec("salon")


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
	# göz kapakları ağırlaşır: yavaş, uzun kırpışlar
	karartma = _egri([[0, 0], [5.2, 0], [5.9, 0.75], [6.4, 0.1], [8.3, 0.1], [9.1, 0.9], [9.8, 0.2], [11.4, 0.2], [12.1, 0.95], [12.9, 0.15], [13.6, 0.0], [16, 0]], ft)
	_bulanik(_egri([[0, 0], [5.0, 0], [6.0, 0.12], [9.5, 0.2], [12.6, 0.25], [13.3, 0.0], [16, 0]], ft))
	# 00:00 olunca saat çalar; Selim irkilir
	if ft > 13.05 and not _eylem.has("gong"):
		_eylem["gong"] = true
		for i in 3:
			get_tree().create_timer(i * 1.15).timeout.connect(func() -> void: _ses_cal("saat_gong", -6.0))
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
	_bulanik(0.0)
	# kalkarken TV'yi kapatır
	if ft > 1.1 and tv_acik:
		tv_acik = false
		_crt_ac(false)
		ses_muzik.stop()
		_ses_cal("dugme", -10.0)
	# kapının yanında ışığı kapatır
	if ft > 4.4 and not _eylem.has("isik_kapa"):
		_eylem["isik_kapa"] = true
		_ses_cal("dugme", -8.0)
		($Isiklar/SalonLamba as Light3D).light_energy = 0.0
	if ft > 3.4: _adim_say(0.55)
	_kapi_ac(kapi_salon, ft, 4.5, 5.6)
	karartma = _egri([[0, 0], [5.6, 0], [6.6, 1]], ft)
	# karanlıkta: kapı kapanır, kilitlenir, merdiven otomatiği yanar, basamaklar, kapı açılınca yağmur
	if ft > 6.7 and not _eylem.has("kapi_kapa"):
		_eylem["kapi_kapa"] = true
		_ses_cal("dolap", -4.0)
	if ft > 7.3 and not _eylem.has("kilit"):
		_eylem["kilit"] = true
		_ses_cal("anahtar", -10.0)
		get_tree().create_timer(0.5).timeout.connect(func() -> void: _ses_cal("kilit", -6.0))
	if ft > 8.6 and not _eylem.has("otomat"):
		_eylem["otomat"] = true
		_ses_cal("otomat", -8.0)
	if ft > 9.0 and ft < 12.4: _adim_say(0.42)
	if ft > 10.5:
		if _yagmur_ev == null:
			_yagmur_ev = AudioStreamPlayer.new()
			_yagmur_ev.stream = _ses_bul("yagmur")
			add_child(_yagmur_ev)
			_yagmur_ev.volume_db = -40.0
			_yagmur_ev.play()
		_yagmur_ev.volume_db = lerpf(-40.0, -6.0, smoothstep(10.5, 13.0, ft))
	if ft >= 13.2:
		_bitti = true
		var d := get_node_or_null("/root/Duraklat")
		if d: d.yukle(SONRAKI)
		else: get_tree().change_scene_to_file(SONRAKI)


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
	p.y = _alcak(p.y)
	var s := sallanti
	p += Vector3(sin(T * 1.3) * 0.004 + sin(T * 2.9) * 0.002, sin(T * 0.9) * 0.006 + sin(T * 2.3) * 0.002, sin(T * 1.1) * 0.003) * s
	b += Vector3(sin(T * 0.7 + 1.0) * 0.012 + sin(T * 1.9) * 0.005, sin(T * 0.8 + 2.0) * 0.01, sin(T * 0.6) * 0.012) * s
	kamera.look_at_from_position(p, b, Vector3.UP)


## Ayakta duran kamera karelerini Selim'in boyuna indirir (oturan/yatan kareler değişmez).
func _alcak(y: float) -> float:
	return y - BOY_FARK * smoothstep(1.3, 1.55, y)


## _alcak'ın tersi: canlı kameradan başlayan yolların ilk karesi için.
func _ham(p: Vector3) -> Vector3:
	var lo := p.y; var hi := p.y + BOY_FARK
	for i in 20:
		var m := (lo + hi) * 0.5
		if _alcak(m) < p.y: lo = m
		else: hi = m
	return Vector3(p.x, (lo + hi) * 0.5, p.z)


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
	_kapi_kokleri.append(kok)
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
	altyazi.text = tr("SELİM") + ": " + tr(s[1])
	altyazi.visible = _altyazi_acik()
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
	tel_ekran_mi = ekran


# ---------------------------------------------------------------- oyuncu
func _oyuncu_kur() -> void:
	oyuncu = CharacterBody3D.new()
	oyuncu.name = "Oyuncu"
	oyuncu.motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	var cs := CollisionShape3D.new()
	var kapsul := CapsuleShape3D.new()
	kapsul.radius = 0.22
	kapsul.height = 1.1
	cs.shape = kapsul
	# yerdeki halı, eşik gibi alçak şeylere takılmasın diye gövde yerden 0.5 m yukarıda başlar
	cs.position.y = 1.05
	oyuncu.add_child(cs)
	add_child(oyuncu)
	oyuncu.global_position = Vector3(0, -50, 0)


## Odaların modellerinden çarpışma yüzeyi çıkarır (oyuncu duvarlardan ve eşyalardan geçmesin).
func _carpisma_kur() -> void:
	var kokler: Array[Node] = [$Banyo, $Mutfak, $Salon, $TV]
	kokler.append_array(_kapi_kokleri)
	var sehpa := get_node_or_null("TVSehpasi")
	if sehpa: kokler.append(sehpa)
	for k in kokler:
		for m in k.find_children("*", "MeshInstance3D", true, false):
			var mi := m as MeshInstance3D
			if mi.mesh == null or not mi.is_visible_in_tree(): continue
			mi.create_trimesh_collision()


func _oyuncu_yerlestir(konum: Vector3, yaw: float, kutular: Array) -> void:
	oyuncu.global_position = Vector3(konum.x, 0.0, konum.z)
	oyuncu.velocity = Vector3.ZERO
	_yaw = yaw
	_pitch = -0.08
	_kutular = kutular
	_oturuyor = false
	_esyalar.clear()
	faz = "oyun"
	ft = 0.0
	_eylem.clear()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_oyun_kamera(0.0)


## Kilitli sahneden sonra oyuncuya geri döner; kamera nerede kaldıysa oradan devam eder.
func _oyuna_don() -> void:
	var p := kamera.global_position
	if not _oturuyor:
		oyuncu.global_position = Vector3(p.x, 0.0, p.z)
		oyuncu.velocity = Vector3.ZERO
	var bak := -kamera.global_basis.z
	_yaw = atan2(-bak.x, -bak.z)
	_pitch = asin(clampf(bak.y, -1.0, 1.0))
	faz = "oyun"
	ft = 0.0
	_eylem.clear()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


## Selim oturur: yürüyemez, sadece etrafına bakar.
func _otur(konum: Vector3, bakis: Vector3) -> void:
	_oturuyor = true
	_otur_konum = konum
	kamera.look_at_from_position(konum, bakis, Vector3.UP)
	_oyuna_don()


func _icerde(p: Vector3) -> bool:
	for k: AABB in _kutular:
		if p.x >= k.position.x and p.x <= k.end.x and p.z >= k.position.z and p.z <= k.end.z:
			return true
	return false


func _physics_process(dt: float) -> void:
	if faz != "oyun" or oyuncu == null or _oturuyor:
		return
	var g := Input.get_vector("sol", "sag", "ileri", "geri")
	var yon := Basis(Vector3.UP, _yaw) * Vector3(g.x, 0.0, g.y)
	oyuncu.velocity = oyuncu.velocity.lerp(yon * YURUME, minf(1.0, dt * 8.0))
	var once := oyuncu.global_position
	oyuncu.move_and_slide()
	var p := oyuncu.global_position
	p.y = 0.0
	if not _icerde(p):
		var px := Vector3(p.x, 0.0, once.z)
		var pz := Vector3(once.x, 0.0, p.z)
		if _icerde(px): p = px
		elif _icerde(pz): p = pz
		else: p = Vector3(once.x, 0.0, once.z)
	oyuncu.global_position = p


func _oyun_kamera(dt: float) -> void:
	var konum := _otur_konum
	var yatay := 0.0
	if not _oturuyor:
		konum = oyuncu.global_position + Vector3(0.0, GOZ, 0.0)
		yatay = Vector2(oyuncu.velocity.x, oyuncu.velocity.z).length()
	var s := minf(1.0, yatay / YURUME)
	_bob += dt * (1.0 + yatay * 4.2)
	konum.y += sin(_bob * 2.0) * 0.022 * s + sin(T * 0.9) * 0.004
	konum.x += sin(T * 1.3) * 0.002
	kamera.global_position = konum
	kamera.rotation = Vector3(_pitch + sin(T * 0.8) * 0.004, _yaw + sin(T * 0.6) * 0.004, sin(_bob) * 0.01 * s)
	karartma = move_toward(karartma, 0.0, dt * 1.2)
	if yatay > 0.4:
		_adim_say(0.58)


func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventMouseMotion:
		if faz == "oyun" and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			var mm := e as InputEventMouseMotion
			var h := 0.0022 * _fare_carpani()
			_yaw -= mm.relative.x * h
			_pitch = clampf(_pitch - mm.relative.y * h * _y_carpani(), -1.4, 1.4)
	elif e is InputEventKey:
		var ke := e as InputEventKey
		if not ke.pressed or ke.echo: return
		if ke.physical_keycode == KEY_E and faz == "oyun" and _secili != "":
			_etkiles(_secili)
		elif ke.physical_keycode == KEY_Q and faz == "tel_kaydir" and tel_bildirim.visible:
			_gec("s_tel_birak")
	elif e is InputEventMouseButton:
		var mb := e as InputEventMouseButton
		if not mb.pressed or faz != "tel_kaydir": return
		if mb.button_index == MOUSE_BUTTON_WHEEL_DOWN: _kaydir(1)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP: _kaydir(-1)


func _y_carpani() -> float:
	var d := get_node_or_null("/root/Duraklat")
	return -1.0 if d and d.get("ters_y") == true else 1.0


func _altyazi_acik() -> bool:
	var d := get_node_or_null("/root/Duraklat")
	return d == null or d.get("altyazi") != false


# duraklatma menüsündeki fare hassasiyeti ayarı
func _fare_carpani() -> float:
	var d := get_node_or_null("/root/Duraklat")
	return float(d.get("fare")) if d and d.get("fare") != null else 1.0


# ---------------------------------------------------------------- etkileşim
## Etkileşilebilir nokta ekler: oyuncu yakındayken ve bakarken küçük "E" çıkar.
func _esya(ad: String, konum: Vector3, menzil: float) -> void:
	_esyalar[ad] = [konum, menzil]


func _esya_kaldir(ad: String) -> void:
	_esyalar.erase(ad)


func _secim_guncelle() -> void:
	_secili = ""
	if faz == "oyun":
		var en := -1.0
		var bak := -kamera.global_basis.z
		for ad: String in _esyalar:
			var e: Array = _esyalar[ad]
			var d: Vector3 = (e[0] as Vector3) - kamera.global_position
			if d.length() > float(e[1]): continue
			# yakındaki eşyaya bakmak için daha geniş açı yeter
			var c := bak.dot(d.normalized())
			var esik := lerpf(0.8, 0.93, clampf((d.length() - 0.8) / 1.2, 0.0, 1.0))
			if c > esik and c - esik > en:
				en = c - esik
				_secili = ad
	e_yazi.visible = _secili != ""
	if _secili != "":
		var p := kamera.unproject_position(_esyalar[_secili][0])
		var ekran := get_viewport().get_visible_rect().size
		e_yazi.position = (p - e_yazi.size * 0.5).clamp(Vector2(60, 60), ekran - e_yazi.size - Vector2(60, 60))


## Ekranın sol üstünde küçük görev yazısı. Boş verilirse söner.
func _gorev(metin: String) -> void:
	if metin == "":
		_gorev_hedef = 0.0
		return
	gorev_yazi.text = metin
	gorev_yazi.modulate.a = 0.0
	_gorev_hedef = 1.0


## Her karede: kapılar, banyo lambası, ayna buğusu, yüzdeki su damlaları, görev yazısı.
func _ev_guncelle(dt: float) -> void:
	if _zaman.has("banyo_kapi"): _banyo_kapisi(T - float(_zaman["banyo_kapi"]) + 0.5)
	if _zaman.has("mutfak_kapi"): _kapi_ac(kapi_mutfak, T - float(_zaman["mutfak_kapi"]), 0.0, 1.1)
	if _zaman.has("salon_kapi"): _kapi_ac(kapi_salon, T - float(_zaman["salon_kapi"]), 0.0, 1.1)
	if _zaman.has("banyo_isik"):
		# floresan: birkaç kez çakıp söner, sonra yanar
		var t := T - float(_zaman["banyo_isik"])
		var lamba := $Isiklar/BanyoLamba as OmniLight3D
		if t < 1.4:
			lamba.light_energy = 1.3 if fmod(t * 6.1 + sin(t * 23.0) * 0.4, 1.0) > 0.6 else 0.04
		else:
			lamba.light_energy = 1.3 + sin(T * 120.0) * 0.015
	damla_hedef = move_toward(damla_hedef, 0.0, dt * 0.07)
	damla = move_toward(damla, damla_hedef, dt * 2.0)
	_damla_mat.set_shader_parameter("miktar", damla)
	_damla_rect.visible = damla > 0.01
	_ayna_mat.albedo_color.a = ayna_bugu * 0.8
	gorev_yazi.modulate.a = move_toward(gorev_yazi.modulate.a, _gorev_hedef * 0.85, dt * 1.5)


## Mutfaktaki üst dolabın iki kapağı (modelde Door2 ve Door3) ortadan dışa açılır.
func _dolap_kapaklari(acik: float) -> void:
	if _dolap.is_empty():
		var parcalar := []
		for ad in ["Door2", "Door3"]:
			var n := $Mutfak.find_child(ad, true, false) as Node3D
			if n: parcalar.append([n, n.global_transform, _dunya_kutusu(n)])
		if parcalar.size() < 2: return
		parcalar.sort_custom(func(a: Array, b: Array) -> bool: return (a[2] as AABB).get_center().z < (b[2] as AABB).get_center().z)
		var k0: AABB = parcalar[0][2]
		var k1: AABB = parcalar[1][2]
		_dolap.append([parcalar[0][0], parcalar[0][1], Vector3(k0.end.x, 0.0, k0.position.z), 1.0])
		_dolap.append([parcalar[1][0], parcalar[1][1], Vector3(k1.end.x, 0.0, k1.end.z), -1.0])
	for d in _dolap:
		var h: Vector3 = d[2]
		var don := Transform3D(Basis(Vector3.UP, float(d[3]) * acik * deg_to_rad(100.0)), Vector3.ZERO)
		(d[0] as Node3D).global_transform = Transform3D(Basis(), h) * don * Transform3D(Basis(), -h) * (d[1] as Transform3D)


func _dunya_kutusu(n: Node3D) -> AABB:
	var kutu := AABB()
	var ilk := true
	var liste: Array = n.find_children("*", "MeshInstance3D", true, false)
	if n is MeshInstance3D: liste.append(n)
	for m in liste:
		var mi := m as MeshInstance3D
		var k: AABB = mi.global_transform * mi.get_aabb()
		kutu = k if ilk else kutu.merge(k)
		ilk = false
	return kutu


## Kapının dışındaki karanlık koridor: taban, tavan, yan duvarlar ve dip (kapı tarafı açık).
## dip_kapili ise açık tarafın karşısındaki dip duvarda ortada kapı boşluğu bırakılır.
func _koridor(a: Vector3, b: Vector3, acik: String, dip_kapili := false) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.18, 0.15)
	mat.roughness = 0.95
	var k := 0.05
	var o := (a + b) * 0.5
	var s := b - a
	var yuzler := {
		"-y": [Vector3(o.x, a.y - k * 0.5, o.z), Vector3(s.x, k, s.z)],
		"+y": [Vector3(o.x, b.y + k * 0.5, o.z), Vector3(s.x, k, s.z)],
		"-x": [Vector3(a.x - k * 0.5, o.y, o.z), Vector3(k, s.y, s.z)],
		"+x": [Vector3(b.x + k * 0.5, o.y, o.z), Vector3(k, s.y, s.z)],
		"-z": [Vector3(o.x, o.y, a.z - k * 0.5), Vector3(s.x, s.y, k)],
		"+z": [Vector3(o.x, o.y, b.z + k * 0.5), Vector3(s.x, s.y, k)],
	}
	# koridorda loş bir ampul
	var lamba := OmniLight3D.new()
	lamba.light_color = Color(1.0, 0.78, 0.55)
	lamba.light_energy = 0.7
	lamba.omni_range = 3.5
	lamba.shadow_enabled = true
	lamba.position = Vector3(o.x, b.y - 0.3, o.z)
	add_child(lamba)
	var dip := ""
	if dip_kapili:
		dip = ("-" if acik.begins_with("+") else "+") + acik.substr(1)
		var x_dip := dip.ends_with("x")
		var yuz: Array = yuzler[dip]
		var mrk: Vector3 = yuz[0]
		var c := mrk.z if x_dip else mrk.x
		var u0 := (a.z if x_dip else a.x)
		var u1 := (b.z if x_dip else b.x)
		var k0 := c - KAPI_EN * 0.5
		var k1 := c + KAPI_EN * 0.5
		var ust := a.y + KAPI_BOY + 0.04
		# kapının iki yanı ve üstü
		for d in [[u0, k0, a.y, b.y], [k1, u1, a.y, b.y], [k0, k1, ust, b.y]]:
			var um: float = (d[0] + d[1]) * 0.5
			var ue: float = d[1] - d[0]
			var ym: float = (d[2] + d[3]) * 0.5
			var ye: float = d[3] - d[2]
			if ue <= 0.001 or ye <= 0.001: continue
			var parca := MeshInstance3D.new()
			var pb := BoxMesh.new()
			pb.size = Vector3(k, ye, ue) if x_dip else Vector3(ue, ye, k)
			pb.material = mat
			parca.mesh = pb
			parca.position = Vector3(mrk.x, ym, um) if x_dip else Vector3(um, ym, mrk.z)
			add_child(parca)
	for y: String in yuzler:
		if y == acik or y == dip: continue
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = yuzler[y][1]
		bm.material = mat
		mi.mesh = bm
		mi.position = yuzler[y][0]
		add_child(mi)
		mi.create_trimesh_collision()


## Banyo aynasının önünde buğu katmanı (sıcak sudan sonra ayna buğulanır).
func _ayna_kur() -> void:
	var mi := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(0.33, 0.75)
	_ayna_mat = StandardMaterial3D.new()
	_ayna_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ayna_mat.albedo_color = Color(0.86, 0.88, 0.9, 0.0)
	_ayna_mat.roughness = 1.0
	qm.material = _ayna_mat
	mi.mesh = qm
	mi.position = AYNA + Vector3(0.025, 0.005, -0.005)
	mi.rotation_degrees.y = 90.0
	add_child(mi)


## Yüzdeki ve kameradaki su damlaları (lavabo ve duştan sonra).
func _damla_kur() -> void:
	var cl := CanvasLayer.new()
	cl.layer = 5
	add_child(cl)
	_damla_rect = ColorRect.new()
	_damla_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_damla_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_damla_mat = ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = """shader_type canvas_item;
uniform sampler2D ekran : hint_screen_texture, filter_linear_mipmap;
uniform float miktar = 0.0;
float h(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 oran = vec2(SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x, 1.0);
	vec2 kay = vec2(0.0);
	float isik = 0.0;
	for (int k = 0; k < 2; k++) {
		vec2 g = uv * oran * (6.0 + float(k) * 5.0) + vec2(0.0, -miktar * 0.15 * float(k + 1));
		vec2 id = floor(g);
		vec2 f = fract(g) - 0.5;
		if (h(id + float(k) * 7.0) < miktar * 0.7) {
			vec2 c = (vec2(h(id + 1.3), h(id + 2.1)) - 0.5) * 0.5;
			float r = 0.1 + 0.18 * h(id + 3.7);
			vec2 d = f - c;
			float m = smoothstep(r, r * 0.75, length(d));
			kay += d * m * 0.07;
			isik += m * smoothstep(0.0, r, length(d - vec2(-0.3, 0.3) * r)) * 0.0;
		}
	}
	vec3 c = textureLod(ekran, uv - kay, 0.0).rgb;
	vec3 bul = textureLod(ekran, uv, 2.5).rgb;
	COLOR = vec4(mix(c, bul, miktar * 0.3), 1.0);
}
"""
	_damla_mat.shader = sh
	_damla_rect.material = _damla_mat
	_damla_rect.visible = false
	cl.add_child(_damla_rect)


## Gözler açılırken bulanıklık (alan derinliği).
func _bulanik(m: float) -> void:
	var ca := ($Ortam as WorldEnvironment).camera_attributes as CameraAttributesPractical
	if ca == null: return
	ca.dof_blur_far_enabled = m > 0.001
	ca.dof_blur_near_enabled = m > 0.001
	ca.dof_blur_far_distance = 0.4
	ca.dof_blur_far_transition = 1.2
	ca.dof_blur_near_distance = 0.35
	ca.dof_blur_amount = m


# ---------------------------------------------------------------- telefon ekranı
## Telefon yatağın üstünde başlar; alarm ekranı açık.
func _telefon_yataga() -> void:
	telefon.reparent(self, false)
	telefon.scale = Vector3.ONE * TEL_OLCEK
	telefon.position = TEL_YATAK
	telefon.rotation = Vector3(-PI * 0.5, 0.5, 0.0)
	telefon.visible = true
	tel_ekran_mi.visible = true
	tel_alarm.visible = true
	tel_isigi = OmniLight3D.new()
	tel_isigi.light_color = Color(0.75, 0.82, 1.0)
	tel_isigi.omni_range = 1.4
	tel_isigi.omni_attenuation = 2.0
	tel_isigi.light_energy = 0.0
	add_child(tel_isigi)
	tel_isigi.position = TEL_YATAK + Vector3(0, 0.12, 0)


func _tel_ekran(acik: bool) -> void:
	tel_ekran_mi.visible = acik
	tel_alarm.visible = false
	for v in tel_videolar:
		if acik: v.play()
		else: v.stop()


func _kaydir(yon: int) -> void:
	var n := tel_akis.get_child_count() if tel_akis else 6
	var yeni := clampi(_kaydirma + yon, 0, n - 1)
	if yeni == _kaydirma: return
	_kaydirma = yeni
	_kaydirilan += 1
	if tel_akis:
		var tw := create_tween()
		tw.tween_property(tel_akis, "position:y", -720.0 * yeni, 0.32).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tik(1.8, -14.0)


## Alarm ekranı ve gelen mesaj bildirimi (telefonun kendi ekranında).
func _tel_ekstra_kur() -> void:
	tel_alarm = ColorRect.new()
	(tel_alarm as ColorRect).color = Color(0.04, 0.04, 0.07)
	tel_alarm.size = Vector2(360, 720)
	tel_vp.add_child(tel_alarm)
	for satir in [["18:00", 96, 190], ["Alarm", 26, 310], ["Kapatmak için kaydır", 17, 600]]:
		var l := Label.new()
		l.text = satir[0]
		l.add_theme_font_size_override("font_size", satir[1])
		l.add_theme_color_override("font_color", Color(0.92, 0.92, 0.95))
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.size = Vector2(360, 120)
		l.position = Vector2(0, satir[2] - 60)
		tel_alarm.add_child(l)
	tel_alarm.visible = false
	tel_bildirim = Panel.new()
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.13, 0.13, 0.15, 0.96)
	st.set_corner_radius_all(16)
	tel_bildirim.add_theme_stylebox_override("panel", st)
	tel_bildirim.position = Vector2(12, -120)
	tel_bildirim.size = Vector2(336, 128)
	tel_vp.add_child(tel_bildirim)
	var kim := Label.new()
	kim.text = "Mesajlar · Amir · şimdi"
	kim.add_theme_font_size_override("font_size", 18)
	kim.add_theme_color_override("font_color", Color(0.7, 0.7, 0.72))
	kim.position = Vector2(16, 10)
	tel_bildirim.add_child(kim)
	var ne := Label.new()
	ne.text = "Gece 12'de kulübede ol. Geç kalma."
	ne.add_theme_font_size_override("font_size", 24)
	ne.autowrap_mode = TextServer.AUTOWRAP_WORD
	ne.size = Vector2(310, 80)
	ne.position = Vector2(16, 38)
	tel_bildirim.add_child(ne)
	tel_bildirim.visible = false


# ---------------------------------------------------------------- küçük arayüz ve sesler
func _oyun_arayuzu_kur() -> void:
	var cl := CanvasLayer.new()
	cl.layer = 9
	add_child(cl)
	gorev_yazi = Label.new()
	gorev_yazi.add_theme_font_size_override("font_size", 22)
	gorev_yazi.add_theme_color_override("font_color", Color(0.92, 0.9, 0.85))
	gorev_yazi.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	gorev_yazi.add_theme_constant_override("outline_size", 5)
	gorev_yazi.position = Vector2(48, 40)
	gorev_yazi.modulate.a = 0.0
	cl.add_child(gorev_yazi)
	e_yazi = Label.new()
	e_yazi.text = "E"
	e_yazi.add_theme_font_size_override("font_size", 17)
	e_yazi.add_theme_color_override("font_color", Color(0.95, 0.95, 0.92))
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0, 0, 0, 0.45)
	st.border_color = Color(0.95, 0.95, 0.92, 0.7)
	st.set_border_width_all(2)
	st.set_corner_radius_all(6)
	st.content_margin_left = 9; st.content_margin_right = 9
	st.content_margin_top = 2; st.content_margin_bottom = 2
	e_yazi.add_theme_stylebox_override("normal", st)
	e_yazi.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	e_yazi.size = Vector2(30, 28)
	e_yazi.visible = false
	cl.add_child(e_yazi)


func _oyun_sesleri_kur() -> void:
	ses_alarm = AudioStreamPlayer.new(); add_child(ses_alarm)
	ses_alarm.stream = _ses_bul("alarm")
	ses_alarm.volume_db = -9.0
	ses_titresim = AudioStreamPlayer.new(); add_child(ses_titresim)
	ses_titresim.stream = _ses_bul("titresim")
	ses_titresim.volume_db = -14.0


## sesler/<ad>.mp3 (ya da .ogg/.wav) varsa onu çalar; yoksa basit bir yedek ses, o da yoksa sessiz geçer.
func _ses_cal(ad: String, db: float) -> void:
	var akis := _ses_bul(ad)
	if akis == null: return
	var p: AudioStreamPlayer = null
	for s in _ses_havuz:
		if not s.playing:
			p = s
			break
	if p == null:
		p = AudioStreamPlayer.new()
		add_child(p)
		_ses_havuz.append(p)
	p.stream = akis
	p.volume_db = db
	p.pitch_scale = randf_range(0.95, 1.05)
	p.play()


func _ses_bul(ad: String) -> AudioStream:
	if _sesler.has(ad): return _sesler[ad]
	var akis: AudioStream = null
	for uz in ["mp3", "ogg", "wav"]:
		var yol := "res://sesler/%s.%s" % [ad, uz]
		if ResourceLoader.exists(yol):
			akis = load(yol)
			break
	if akis == null:
		akis = _yedek_ses(ad)
	elif ad == "alarm" or ad == "titresim":
		if akis is AudioStreamMP3: (akis as AudioStreamMP3).loop = true
		elif akis is AudioStreamOggVorbis: (akis as AudioStreamOggVorbis).loop = true
	_sesler[ad] = akis
	return akis


## Gerçek ses dosyası gelene kadar kullanılan yedek sesler.
func _yedek_ses(ad: String) -> AudioStream:
	var hiz := 22050
	var o := PackedFloat32Array()
	match ad:
		"alarm":
			for i in int(hiz * 1.0):
				var t := float(i) / hiz
				var acik := 1.0 if fmod(t, 0.25) < 0.12 and t < 0.5 else 0.0
				o.append(sin(TAU * 1568.0 * t) * 0.3 * acik + sin(TAU * 2093.0 * t) * 0.1 * acik)
			return _dongu(_wav(o, hiz))
		"titresim":
			for i in int(hiz * 1.0):
				var t := float(i) / hiz
				var acik := 1.0 if t < 0.42 else 0.0
				o.append((sin(TAU * 160.0 * t) * 0.5 + (randf() - 0.5) * 0.2) * acik)
			return _dongu(_wav(o, hiz))
		"bildirim":
			for i in int(hiz * 0.5):
				var t := float(i) / hiz
				var f := 1318.0 if t < 0.12 else 1760.0
				o.append(sin(TAU * f * t) * 0.3 * exp(-fmod(t, 0.12) * 18.0))
			return _wav(o, hiz)
		"floresan_tik":
			for i in int(hiz * 0.6):
				var t := float(i) / hiz
				var tik := (randf() * 2.0 - 1.0) * (exp(-t * 90.0) + exp(-maxf(t - 0.18, 0.0) * 90.0) * float(t > 0.18) * 0.7)
				o.append(tik * 0.7 + sin(TAU * 100.0 * t) * 0.05 * smoothstep(0.2, 0.4, t))
			return _wav(o, hiz)
		"telefon_masa", "dolap", "sandalye":
			return _tok_sesi(140.0 if ad == "telefon_masa" else 90.0, 0.35, 1.0)
		"adim_yalin":
			return _tok_sesi(70.0, 0.18, 0.5)
		"crt":
			for i in int(hiz * 1.0):
				var t := float(i) / hiz
				o.append(sin(TAU * 10000.0 * t) * 0.04 + sin(TAU * 50.0 * t) * 0.12 + sin(TAU * 100.0 * t) * 0.06 + (randf() * 2.0 - 1.0) * 0.015)
			return _dongu(_wav(o, hiz))
		"saat_gong":
			for i in int(hiz * 2.4):
				var t := float(i) / hiz
				var z := exp(-t * 1.6)
				o.append((sin(TAU * 392.0 * t) * 0.35 + sin(TAU * 784.0 * t) * 0.12 * exp(-t * 3.0) + sin(TAU * 1176.0 * t) * 0.06 * exp(-t * 5.0) + sin(TAU * 196.0 * t) * 0.1) * z * (1.0 - exp(-t * 300.0)))
			return _wav(o, hiz)
		"dugme":
			for i in int(hiz * 0.08):
				var t := float(i) / hiz
				o.append((randf() * 2.0 - 1.0) * exp(-t * 200.0) * 0.7 + sin(TAU * 2400.0 * t) * exp(-t * 150.0) * 0.2)
			return _wav(o, hiz)
		"kilit":
			for i in int(hiz * 0.6):
				var t := float(i) / hiz
				var d := 0.0
				for v in [0.0, 0.22, 0.42]:
					var x: float = t - v
					if x >= 0.0: d += ((randf() * 2.0 - 1.0) * 0.5 + sin(TAU * 1500.0 * x) * 0.3) * exp(-x * 90.0)
				o.append(d)
			return _wav(o, hiz)
		"anahtar":
			for i in int(hiz * 0.7):
				var t := float(i) / hiz
				o.append((sin(TAU * 3100.0 * t) * 0.2 + sin(TAU * 4250.0 * t) * 0.15) * exp(-fmod(t, 0.11) * 40.0) * exp(-t * 3.0) + (randf() * 2.0 - 1.0) * 0.05 * exp(-fmod(t, 0.11) * 60.0))
			return _wav(o, hiz)
		"otomat":
			for i in int(hiz * 1.4):
				var t := float(i) / hiz
				o.append((randf() * 2.0 - 1.0) * exp(-t * 120.0) * 0.8 + (sin(TAU * 100.0 * t) * 0.08 + sin(TAU * 200.0 * t) * 0.03) * smoothstep(0.05, 0.3, t))
			return _wav(o, hiz)
		"su_carpma":
			var dusuk := 0.0
			for i in int(hiz * 0.7):
				var t := float(i) / hiz
				dusuk = lerpf(dusuk, randf() * 2.0 - 1.0, 0.35)
				o.append(dusuk * 0.6 * exp(-t * 5.0))
			return _wav(o, hiz)
	return null


## Mutfak masasında ödenmemiş fatura ve belediyeden gelmiş açılmamış zarf.
func _kagitlar_kur() -> void:
	var koyu := Color(0.12, 0.12, 0.13)
	var fatura := Kagit.yazi_dokusu(self, Vector2i(420, 600), Color(0.9, 0.9, 0.88), [
		["ELEKTRİK FATURASI", 26, koyu, 1],
		["EKİM 2026", 18, koyu, 1],
		["", 10, koyu, 0],
		["Abone    : SELİM", 17, koyu, 0],
		["Dönem    : 09.2026", 17, koyu, 0],
		["Tüketim  : 312 kWh", 17, koyu, 0],
		["", 10, koyu, 0],
		["Son ödeme: 14.10.2026", 19, koyu, 0],
		["TUTAR    : 1.284,60 TL", 21, koyu, 0],
		["", 16, koyu, 0],
		["GECİKMİŞ BORÇ", 28, Color(0.7, 0.08, 0.06), 1],
		["", 12, koyu, 0],
		["ödenecek... maaş yatınca", 18, Color(0.1, 0.14, 0.45), 2, true],
	])
	Kagit.yapistir(self, fatura, Vector3(26.82, 0.87, 1.12), Vector2(0.15, 0.21), Vector3.DOWN, 0.35, 0.12)
	var zarf := Kagit.yazi_dokusu(self, Vector2i(560, 320), Color(0.82, 0.76, 0.62), [
		["T.C.", 18, koyu, 0],
		["BELEDİYE FEN İŞLERİ MÜDÜRLÜĞÜ", 18, koyu, 0],
		["", 30, koyu, 0],
		["Sn. SELİM", 24, koyu, 1],
		["KİŞİYE ÖZEL", 20, Color(0.6, 0.1, 0.08), 1],
	])
	Kagit.yapistir(self, zarf, Vector3(27.45, 0.87, 1.02), Vector2(0.23, 0.13), Vector3.DOWN, -0.2, 0.12)


var _crt: AudioStreamPlayer3D
var _yagmur_ev: AudioStreamPlayer

## Tüplü TV'nin ince yüksek vızıltısı ve alçak uğultusu; TV açıkken çalar.
func _crt_ac(acik: bool) -> void:
	if _crt == null:
		_crt = AudioStreamPlayer3D.new()
		_crt.stream = _ses_bul("crt")
		_crt.unit_size = 1.5; _crt.volume_db = -14.0
		add_child(_crt)
		_crt.global_position = EKRAN
	if acik: _crt.play()
	else: _crt.stop()


func _tok_sesi(f: float, sure: float, gurultu: float) -> AudioStreamWAV:
	var o := PackedFloat32Array()
	var hiz := 22050
	var dusuk := 0.0
	for i in int(hiz * sure):
		var t := float(i) / hiz
		dusuk = lerpf(dusuk, randf() * 2.0 - 1.0, 0.1)
		o.append((sin(TAU * f * t) * 0.5 + dusuk * gurultu) * exp(-t * 28.0))
	return _wav(o, hiz)


func _dongu(w: AudioStreamWAV) -> AudioStreamWAV:
	w.loop_mode = AudioStreamWAV.LOOP_FORWARD
	w.loop_begin = 0
	w.loop_end = w.data.size() / 2
	return w


func _adim_say(aralik: float) -> void:
	_adim_t += get_process_delta_time()
	if _adim_t >= aralik:
		_adim_t = 0.0
		_ses_cal("adim_yalin", -17.0)
