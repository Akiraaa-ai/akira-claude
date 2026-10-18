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
	"ic04": ["res://sesler/selim_ic_04a.mp3", "Tamam abi, tamam... ne zaman geç kaldım ki."],   # alp'in kaydının ilk yarısı; ikinci yarısı kulübede
	# rüyadaki kadın (alp'in metni); ses dosyaları gelene kadar yalnız altyazı
	"ruya_sonra": ["res://sesler/selim_ruya_sonra.mp3", "Yine o siktir boktan rüya... Her gece aynı."],
	"ruya01": ["res://sesler/ruya_01.mp3", "Hoş geldin canım...", "KADIN"],
	"ruya02": ["res://sesler/ruya_02.mp3", "Burayı seviyorsun, değil mi? İyi ki geldin.", "KADIN"],
	"ruya03": ["res://sesler/ruya_03.mp3", "Seni o kadar çok özledim ki...", "KADIN"],
	"ruya04": ["res://sesler/ruya_04.mp3", "Ama ben gittiğimden beri hiçbir şey yapmamışsın Selim.", "KADIN"],
	"ruya05": ["res://sesler/ruya_05.mp3", "Hani hayatına devam edecektin? Bu ne hal böyle...", "KADIN"],
	"ruya06": ["res://sesler/ruya_06.mp3", "Ne kadar zayıflamışsın sen.", "KADIN"],
	"ruya07": ["res://sesler/ruya_08.mp3", "Senin suçun değildi diyorum. Duyuyor musun beni? Senin suçun değildi.", "KADIN"],   # kayıtlarda 07 ve 08 yer değiştirmiş
	"ruya08": ["res://sesler/ruya_07.mp3", "Beni unutma, ne olur. Ve biraz olsun yaşa... Sadece benim için.", "KADIN"],
	"ruya09": ["res://sesler/ruya_09.mp3", "Selim... Aşağıda bekliyorsun, biliyorum. Ama yukarıdaki de sendin.", "KADIN"],
	"ruya10": ["res://sesler/ruya_10.mp3", "Selim!", "KADIN"],
	"ruya11": ["res://sesler/ruya_11.mp3", "Selim!!", "KADIN"],
	"ruya12": ["res://sesler/ruya_12.mp3", "SELİM!!!", "KADIN"],
}

# Odaların dünyadaki yerleri (ev.tscn ile aynı)
const SALON := Vector3(7.45, 0, -1.905)
const KOLTUK := Vector3(5.15, 1.12, -2.355)        # Selim'in koltuktaki göz hizası
const EKRAN := Vector3(9.998, 0.85, -2.305)        # TV ekranının ortası
const SAAT_YERI := Vector3(10.335, 2.05, -2.305)     # duvar saati (TV'nin üstünde)
const KASE := Vector3(2.37, 0.625, -4.94)            # Nesquik kâsesinin yeri (model gelince konacak)
const TEL_YATAK := Vector3(-1.5, 0.652, 0.8)        # uyanınca telefon yatağın üstünde
const TEL_MASA := Vector3(2.07, 0.602, -4.9)       # mutfak masasında
const TEL_OLCEK := 0.0217
const ALARM_KAPAN := 7.3
const BANYO_LAMBA := Vector3(5.94, 2.3, 4.6)
const ISIK_DUGMESI := Vector3(5.07, 1.14, 2.71)   # banyonun ışık düğmesi (kapının yanındaki duvarda)
const LAVABO := Vector3(5.4, 0.9, 3.25)
const AYNA := Vector3(5.25, 1.62, 3.25)
const DUS_KAPI := Vector3(6.05, 1.05, 4.26)   # duş kabininin kapısı (yan camda)
const DUS_GENIS := 4.61   # kabin kapısının serbest kenarı (dünya z); modeldeki 0.64 dardı
const DUS_UST := 1.75    # kapı camların üst hizasına kadar uzar
const DOLAP := Vector3(-0.65, 1.9, -9.1)            # mutfağın üst dolabı (Nesquik, kâse)
const BUZDOLABI_MODELI := "res://modeller2/seliminevi/buzdolabi.glb"   # alp gönderince
const BUZDOLABI_YERI := Vector3(-0.83, 1.0, -3.6)
# Oyuncunun dolaşabileceği alanlar (odalar ve kapının önündeki koridor)
const BANYO_ALAN := [AABB(Vector3(5.1, 0, 2.51), Vector3(2.1, 3, 1.12)), AABB(Vector3(5.1, 0, 3.51), Vector3(0.92, 3, 2.5))]   # banyo (duş kabininin camları dışında)
const MUTFAK_ALAN := [AABB(Vector3(-1.33, 0, -9.5), Vector3(4.15, 3, 6.8))]
const SALON_ALAN := [AABB(Vector3(4.75, 0, -4.605), Vector3(5.4, 3, 5.5))]
const YURUME := 1.7
const GOZ := 1.6
## Sinematik yollar 1.62 göz hizasıyla yazıldı; Selim kısaltıldı, ayakta duran kareler bu kadar alçalır.
const BOY_FARK := 0.02
const Eller := preload("res://kod/eller.gd")
const Govde := preload("res://kod/govde.gd")
const Kagit := preload("res://kod/kagit.gd")
const Sigara := preload("res://kod/sigara.gd")

# Modeller (alp'in gönderdiği dosyalar)
const KAPI_MODELI := "res://modeller2/seliminevi/doors_stylish_glass_door.glb"
const SAAT_MODELI := "res://modeller2/seliminevi/vintage_wooden_wall_clock_- (1).glb"
const SEHPA_MODELI := "res://modeller2/seliminevi/tv_stand.glb"
const PAKET_MODELI := "res://modeller2/seliminevi/sigara/sigara_paketi.gltf"
# Kapılar: [kapı ortası, yaw (yerel +x geçiş yönü), aynalı, arkasındaki karanlık hangi yanda (yerel x: +1, -1, 0 yok)].
# Yatak odası kapısı tuğla hola açılır. Öbür odalar evde başka yerlerde durur: holdeki kapı ve odanın
# kendi kapısı karanlığa açılır, Selim karanlığa adım atınca öbür tarafta gözünü açar. Her geçişte tek kapı.
const KAPI_YATAK := [Vector3(3.30, 0.0, 1.6), 0.0, false, 0.0]
const KAPI_MUTFAK := [Vector3(3.3, 0.0, -3.45), 180.0, true, 0.0]
const KAPI_SALON := [Vector3(8.05, 0.0, 1.03), 90.0, false, 0.0]
## Dış kapı: holün doğu ucunda, merdiven boşluğuna açılır
const KAPI_DIS := [Vector3(10.31, 0.0, 1.6), 0.0, false, 0.0]

# Ev tek parça (alp, 2026-10-18): odalar holün çevresinde yan yana, kapılar açık, geçişte kararma yok.
# Kuzey-güney hol: batısında mutfak ve yatak odası, doğusunda salonun duvarı. Doğu-batı hol: kuzeyinde
# salon, güneyinde banyo, doğu ucunda dış kapı. Dikdörtgenler [x0, z0, x1, z1]: holün iç yüzü.
const HOL := [
	[3.3, -4.2, 4.49, 0.95],
	[3.3, 0.95, 10.31, 2.22],
]
# Holün kapılarının bulunduğu kenarları: duvarda kapı boşluğu kalır. [kenar, sabit, kapının ortası]
const HOL_KAPILAR := [["-x", 3.3, -3.45], ["-x", 3.3, 1.6], ["-z", 0.95, 8.05], ["+z", 2.22, 5.63], ["+x", 10.31, 1.6]]
# kapı eşiklerinde odanın zemini ile hol arasında kalan aralık
const HOL_ESIK := [[3.2, 1.0, 3.4, 2.2], [3.1, -4.0, 3.4, -2.9], [5.05, 2.2, 6.2, 2.4], [7.5, 0.8, 8.6, 1.0]]
const HOL_TAVAN := 2.6
const HOL_LAMBALAR := [Vector3(3.9, 2.3, -1.8), Vector3(5.6, 2.3, 1.6), Vector3(9.0, 2.3, 1.6)]
const HOL_TITREYEN := 1   # bu ampul arada bir çakıp söner
# Selim'in evde dolaşabileceği yerler (duvarlardan ~0.28 m içeride): odalar, hol ve kapı geçitleri
const YATAK_ALAN := [AABB(Vector3(-2.1, 0, -2.1), Vector3(5.1, 3, 5.1))]
const HOL_ALAN := [AABB(Vector3(3.58, 0, -3.92), Vector3(0.63, 3, 4.92)), AABB(Vector3(3.58, 0, 1.23), Vector3(6.45, 3, 0.71)),
	AABB(Vector3(2.9, 0, 1.2), Vector3(0.8, 3, 0.8)), AABB(Vector3(2.7, 0, -3.85), Vector3(1.0, 3, 0.8)),
	AABB(Vector3(7.65, 0, 0.6), Vector3(0.8, 3, 0.8)), AABB(Vector3(5.23, 0, 1.9), Vector3(0.8, 3, 0.8))]
# hedef odaya girilince o odanın işi başlar
var EV_ALAN: Array = YATAK_ALAN + HOL_ALAN + BANYO_ALAN + MUTFAK_ALAN + SALON_ALAN
const ODA_GIRIS := {
	"banyo": AABB(Vector3(4.9, 0, 2.55), Vector3(2.3, 3, 3.5)),
	"mutfak": AABB(Vector3(-1.5, 0, -9.9), Vector3(4.6, 3, 7.2)),
	"salon_kapisi": AABB(Vector3(4.7, 0, -4.7), Vector3(5.5, 3, 5.5)),
}
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
var ses_arka: AudioStreamPlayer   # uyanıştan sonra evde hafif çalan müzik
var ses_tik: AudioStreamPlayer
var ses_bip: AudioStreamPlayer
var ses_gurultu: AudioStreamPlayer
var _gen: AudioStreamGeneratorPlayback
var _lp := 0.0
var _lp2 := 0.0
var su_ses := 0.0
var su_hedef := 0.0
var ses_dus: AudioStreamPlayer   # duşun gerçek su sesi (sesler/dus.mp3)
var dus_ses := 0.0
var dus_hedef := 0.0
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
## Yayından önce TV'de sıradan bir program (alp): yerel kanalda hava durumu; sonra yayın bir anda araya girer.
const PROGRAM_SURE := 9.0
var tv_program: Control
var _program_kayan: Label
var ses_program: AudioStreamPlayer
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
var kapi_hol_banyo: Node3D
var kapi_hol_mutfak: Node3D
var kapi_hol_salon: Node3D
var kapi_dis: Node3D
var _yurume_girisi := false
var _hol_hedef := ""
var _kapanacak := {}          # menteşe -> kapanmaya başladığı an
var _hol_lambalar: Array[OmniLight3D] = []
var _uzaklasinca := {}        # açık kalan kapı -> true: Selim kanadın süpürdüğü yerden uzaklaşınca kapanır
var kapi_banyo: Node3D
var _banyo_acik: Transform3D
var _banyo_mentese := Vector3.ZERO
var ses_kapi: AudioStreamPlayer
var dakika := 20.0 * 60.0 + 10.0
var _saat_bas := 20.0 * 60.0 + 10.0
var _salon_giris := 0.0
var _son_tik := 0.0
var _kapi_kokleri: Array[Node] = []
var su: GPUParticles3D
var buhar: GPUParticles3D

# oynanabilir kısım
var eller: Eller
var govde: Govde       # Selim'in gövdesi: aşağı bakınca görünür, başın yalnızca gölgesi
var oyuncu: CharacterBody3D
var _yaw := 0.0
var _pitch := 0.0
var _kutular: Array = []
var _oturuyor := false
## evden çıkarken merdiven boşluğunda oyuncu kendi iner: yer ışınla bulunur, oda sınırları kalkar
var _merdivende := false
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
var ses_ambiyans: AudioStreamPlayer
var ses_saat_tik: AudioStreamPlayer
var _ses_havuz: Array[AudioStreamPlayer] = []
var _sesler := {}
var gorev_yazi: Label
var e_yazi: Label
var _gorev_hedef := 0.0


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	_mutfak_mobilyasi()
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
	_kabuk(Vector3(-0.55, 0, -3.99) + Vector3(-1.03, 0, -6.0), Vector3(4.25, 2.82, 3.50) + Vector3(-1.03, 0, -6.0), {"-x": mutfak_duvar, "+x": mutfak_duvar, "-z": mutfak_duvar, "+z": mutfak_duvar}, mutfak_duvar, {"+x": KAPI_MUTFAK[0].z})
	_kabuk(Vector3(-2.855, 0, -2.855) + SALON, Vector3(2.855, 2.7, 2.855) + SALON, {"+x": beton_x, "+z": beton_z}, beton_x, {"+z": KAPI_SALON[0].x})
	kapi_yatak = _kapi_kur(KAPI_YATAK)
	kapi_mutfak = _kapi_kur(KAPI_MUTFAK)
	kapi_salon = _kapi_kur(KAPI_SALON)
	_banyo_kapisi_kur()
	_dus_kapisi_kur()
	_tv_sehpasi()
	_saat_kur()
	_aile_fotografi()
	_foto_duvari()
	_mutfak_erzak()
	_yeni_esyalar()
	_paket_kur()
	_dus_kur()
	_ayna_kur()
	# tuğla hol; holdeki kapılar Selim'den öteye, karanlığa doğru itilerek açılır
	var tahta := _duvar_malzemesi($YatakOdasi, "Plane_Material_001_0", 0.3)
	var siva := _duvar_malzemesi($YatakOdasi, "Plane_004_Material_004_0", 0.25)
	_hol_kur(tugla, tahta, siva)
	_ampuller_kur()
	_tablolar_kur()
	kapi_dis = _kapi_kur(KAPI_DIS)
	# oda kapıları açık durur (alp: kapı animasyonu yok)
	# mutfak ve salon kapıları odanın içine açılır, holü kapatmasın
	for k: Node3D in [kapi_mutfak, kapi_salon]: k.set_meta("yon", -1.0)
	for k: Node3D in [kapi_yatak, kapi_mutfak, kapi_salon]: _kapi_ac(k, 1.0, 0.0, 0.5)
	_ev_parcalari_gizle()
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
	govde = Govde.new()
	govde.yelek = true      # modelde yeleğin altında gövde yok; alp gövdenin görünmesini istedi
	govde.goz = GOZ
	govde.eller = eller
	add_child(govde)
	# "Devam Et" ile gelindiyse kaydedilen noktadan başlar
	var d := get_node_or_null("/root/Duraklat")
	var nokta: String = str(d.baslangic_noktasi) if d else ""
	if d: d.baslangic_noktasi = ""
	# yeni oyun ve eve dönüş: Selim uyanmadan önce rüya görür
	_gec(nokta if nokta in KAYIT_NOKTALARI else "ruya")
	_isik_sekmesi_kur.call_deferred()


## Işık duvarlardan seker (VoxelGI): odalar gökyüzünün mavisiyle değil, lambanın sıcak ışığıyla dolar.
## Eşyalar kurulduktan sonra oda oda bir kez hesaplanır; lambalar yanıp sönünce sekme de canlı değişir.
const ISIK_SEKMESI := [   # [köşe, ölçü]
	[Vector3(-3.0, -0.2, -3.0), Vector3(6.5, 4.6, 6.5)],     # yatak odası
	[Vector3(3.2, -0.2, -4.3), Vector3(1.5, 3.0, 5.3)],      # hol (kuzey-güney)
	[Vector3(3.2, -0.2, 0.85), Vector3(7.2, 3.0, 1.5)],      # hol (doğu-batı)
	[Vector3(4.55, -0.2, 2.01), Vector3(3.2, 2.8, 4.2)],     # banyo
	[Vector3(-4.53, -0.2, -10.2), Vector3(8.2, 3.3, 7.8)],     # mutfak
	[Vector3(4.45, -0.2, -4.905), Vector3(6.2, 3.1, 6.2)],     # salon
]

func _isik_sekmesi_kur() -> void:
	for r in ISIK_SEKMESI:
		var g := VoxelGI.new()
		g.subdiv = VoxelGI.SUBDIV_64
		g.size = r[1]
		add_child(g)
		g.global_position = r[0] + r[1] * 0.5
		g.data = VoxelGIData.new()
		g.data.propagation = 0.7
		g.bake()


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
		"ruya": _ruya_kur()
		"banyo": _banyo_basla()
		"mutfak": _mutfak_basla()
		"salon_kapisi": _salon_basla()
		"salon": Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
		"saat":
			_saat_bas = 20.0 * 60.0 + (T - _salon_giris) / 60.0
			dakika = _saat_bas
		"yayin":
			tv_acik = true
			tv_t = 0.0
			# önce sıradan program; anlatıcı ve müzik yayın araya girince başlar (_tv_guncelle)
			if ses_program: ses_program.play()
			_crt_ac(true)


func _process(dt: float) -> void:
	if _bitti:
		return
	_ampul_parla()
	T += dt
	ft += dt
	sallanti = 1.0
	# TV ve telefon ekranları yalnızca görünürken çizilir (zayıf ekran kartlarında boşa iş yapılmasın)
	if tv_vp and tv_ust:
		var tv_calisiyor := tv_acik or float((tv_ust.material as ShaderMaterial).get_shader_parameter("acilis")) > 0.01
		tv_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS if tv_calisiyor else SubViewport.UPDATE_DISABLED
	if tel_vp and tel_ekran_mi:
		tel_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS if tel_ekran_mi.is_visible_in_tree() else SubViewport.UPDATE_DISABLED
	# gövde yalnızca serbest yürürken: oturma, yatma, sinematiklerde gölgesi kafayla uyuşmaz
	govde.visible = faz == "oyun"
	if govde.visible:
		govde.gorunur = not _oturuyor
		var kp := kamera.global_position
		govde.guncelle(Vector3(kp.x, oyuncu.global_position.y if _merdivende else 0.0, kp.z), kamera.global_rotation.y, dt)
	match faz:
		"ruya": _ruya(dt)
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
		"s_sigara": _s_sigara()
		"s_koltuk": _s_koltuk()
		"salon": _salon()
		"yayin": _yayin()
		"geri": _geri()
		"saat": _saat()
		"cikis": _cikis()
		"dis_kapi": _dis_kapi()
		"ev_cikis": _ev_cikis()
	siyah.color.a = clampf(karartma, 0.0, 1.0)
	_tv_guncelle(dt)
	_daktilo_guncelle()
	if altyazi.visible and T > _altyazi_bitis:
		altyazi.visible = false
	_saat_ibreleri()
	_gurultu_doldur(dt)
	_arka_muzik(dt)
	_ev_guncelle(dt)
	_secim_guncelle()


## Uyanıştan sonra arkada hafif müzik. TV'deki yayın müziği çalarken ve evden çıkarken kısılır.
const ARKA_MUZIK := "res://sesler/muzik_3.mp3"
const ARKA_SES := -24.0

func _arka_muzik(dt: float) -> void:
	if ses_arka == null or ses_arka.stream == null:
		return
	var hedef := -80.0
	if not faz in ["ruya", "uyanis", "yayin", "geri", "saat", "cikis", "dis_kapi"] and not _merdivende:
		hedef = ARKA_SES
	if hedef > -80.0 and not ses_arka.playing:
		ses_arka.play()
	ses_arka.volume_db = move_toward(ses_arka.volume_db, hedef, dt * (8.0 if hedef > ses_arka.volume_db else 20.0))
	if ses_arka.playing and ses_arka.volume_db <= -79.0 and hedef <= -80.0:
		ses_arka.stop()


# ---------------------------------------------------------------- rüya (alp'in metni)
## Güneşli bir gün: Selim eski arabasıyla şehrin ortasındaki caddede ağır ağır gider, yavaş bir piyano.
## Yan koltuktaki kadın hiç görünmez (kamera hep yola bakar), yalnızca sesi duyulur.
## Sonra piyano kesilir, gök kararır, yağmur başlar; karşıdan farlar gelir, kadın Selim'e bağırır, fren, çarpma, karanlık.
## Bir saniyelik sessizlikten sonra alarm çalar, Selim nefes nefese uyanır.
## Rüya evden çok yukarıda kurulur: alp'in şehri (tek kopya, 1,4 ölçek) ve Selim'in arabası.
const RUYA_MERKEZ := Vector3(0, 600, 0)
const Sokak := preload("res://kod/sokak.gd")
const RUYA_ARABA := "res://modeller2/selim araba/old_car.glb"
## orta cadde (sokak sahnesinin koordinatları): doğudan batıya, sağ şerit
const RUYA_BAS := Vector3(44.0, 0.0, -1.3)
const RUYA_SON := Vector3(-150.0, 0.0, -1.3)
var _ruya_araba: Node3D
var _ruya_hiz := 6.0
var _ruya_yol := 0.0
var _ruya_yagmur: GPUParticles3D
var _karsi_far: Node3D
const RUYA_SIRA := [
	["ruya01", 1.6], ["ruya02", 1.6], ["ruya03", 3.0],
	["ruya04", 1.6], ["ruya05", 1.6], ["ruya06", 3.0],
	["ruya08", 1.8], ["ruya09", 1.8], ["ruya07", 2.6],
]
var _ruya_kok: Node3D
var _ruya_env: Environment
var _ev_env: Environment
var _ruya_gunes: DirectionalLight3D
var ses_piyano: AudioStreamPlayer
var ses_ruya_yagmur: AudioStreamPlayer
var _ruya_sira := 0
var _ruya_sonraki := 3.5
var _ruya_kirilma := -1.0   # piyanonun kesildiği an

func _ruya_kur() -> void:
	_ruya_kok = Node3D.new()
	_ruya_kok.name = "Ruya"
	add_child(_ruya_kok)
	_ruya_kok.position = RUYA_MERKEZ
	# gökyüzü: tepede açık mavi, ufukta altın beyazı
	var gok := ProceduralSkyMaterial.new()
	gok.sky_top_color = Color(0.36, 0.58, 0.95)
	gok.sky_horizon_color = Color(0.92, 0.9, 0.84)
	gok.ground_bottom_color = Color(1.0, 0.96, 0.9)
	gok.ground_horizon_color = Color(1.0, 0.94, 0.86)
	gok.sun_angle_max = 40.0
	gok.sun_curve = 0.08
	gok.sky_energy_multiplier = 1.1
	var sky := Sky.new()
	sky.sky_material = gok
	var e := Environment.new()
	e.background_mode = Environment.BG_SKY
	e.sky = sky
	e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	e.ambient_light_energy = 0.8
	e.tonemap_mode = Environment.TONE_MAPPER_ACES
	e.tonemap_exposure = 0.85
	e.glow_enabled = true
	e.glow_intensity = 0.6
	e.glow_bloom = 0.12
	e.glow_hdr_threshold = 0.85
	e.fog_enabled = true
	e.fog_light_color = Color(0.86, 0.88, 0.9)
	e.fog_density = 0.006
	e.fog_sky_affect = 0.4
	e.fog_sun_scatter = 0.2
	e.adjustment_enabled = true
	e.adjustment_saturation = 1.08
	_ruya_env = e
	var ortam := $Ortam as WorldEnvironment
	_ev_env = ortam.environment
	ortam.environment = _ruya_env
	_ruya_gunes = DirectionalLight3D.new()
	_ruya_gunes.light_color = Color(1.0, 0.9, 0.75)
	_ruya_gunes.light_energy = 1.4
	_ruya_gunes.shadow_enabled = true
	_ruya_gunes.directional_shadow_max_distance = 120.0
	_ruya_gunes.rotation_degrees = Vector3(-38.0, 120.0, 0.0)
	_ruya_kok.add_child(_ruya_gunes)
	$Aksam.visible = false
	_ruya_sahne_kur()
	ses_piyano = AudioStreamPlayer.new(); add_child(ses_piyano)
	var piyano := "res://sesler/ruya_piyano.mp3" if ResourceLoader.exists("res://sesler/ruya_piyano.mp3") else "res://sesler/muzik_4.mp3"
	if ResourceLoader.exists(piyano):
		ses_piyano.stream = load(piyano)
		ses_piyano.volume_db = -40.0
		ses_piyano.play()
	ses_ruya_yagmur = AudioStreamPlayer.new(); add_child(ses_ruya_yagmur)
	if ResourceLoader.exists("res://sesler/yagmur.mp3"):
		ses_ruya_yagmur.stream = load("res://sesler/yagmur.mp3")
	ses_ruya_yagmur.volume_db = -60.0
	_ruya_sira = 0
	_ruya_sonraki = 3.5
	_ruya_kirilma = -1.0
	karartma = 1.0
	# araba, kadının sözleri bitene kadar caddenin sonuna varmasın diye hız sözlerin süresine göre seçilir
	var sure := 3.5 + 9.0
	for sat: Array in RUYA_SIRA:
		var yol: String = SATIRLAR[sat[0]][0]
		sure += float(sat[1]) + (load(yol).get_length() if ResourceLoader.exists(yol) else 3.0)
	_ruya_hiz = clampf(RUYA_BAS.distance_to(RUYA_SON) / sure, 3.0, 9.0)
	_ruya_yol = 0.0


## Şehir modeli ve Selim'in arabası; şehirdeki eski model arabalar sokak sahnesindeki gibi çıkarılır.
func _ruya_sahne_kur() -> void:
	var sehir := Node3D.new()
	sehir.name = "RuyaSehir"
	_ruya_kok.add_child(sehir)
	# sokak.tscn'deki Sehir düğümü (180° dönük, kaydırılmış) ve sokak.gd'deki ölçek
	sehir.transform = Transform3D(Basis.from_scale(Vector3.ONE * Sokak.OLCEK), Vector3.ZERO) * Transform3D(Basis(Vector3.UP, PI), Vector3(-14.5, 0, -43.75))
	for yol: String in Sokak.SEHIR_DOSYALARI:
		if ResourceLoader.exists(yol):
			sehir.add_child((load(yol) as PackedScene).instantiate())
			break
	for m in sehir.find_children("*", "MeshInstance3D", true, false):
		var eski := (m as MeshInstance3D).mesh as ArrayMesh
		if eski == null: continue
		var kalan := []
		for i in eski.get_surface_count():
			var mat := eski.surface_get_material(i)
			if mat and mat.resource_name in Sokak.ARABA_MALZEMELERI: continue
			kalan.append(i)
		if kalan.size() == eski.get_surface_count(): continue
		var yeni := ArrayMesh.new()
		for i in kalan:
			yeni.add_surface_from_arrays(eski.surface_get_primitive_type(i), eski.surface_get_arrays(i))
			yeni.surface_set_material(yeni.get_surface_count() - 1, eski.surface_get_material(i))
		(m as MeshInstance3D).mesh = yeni
	_ruya_araba = Node3D.new()
	_ruya_araba.name = "RuyaAraba"
	_ruya_kok.add_child(_ruya_araba)
	if ResourceLoader.exists(RUYA_ARABA):
		var model: Node3D = (load(RUYA_ARABA) as PackedScene).instantiate()
		# sokak.tscn'deki Araba/Model dönüşü: arabanın önü -z
		model.transform = Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(0, 0, 0.08))
		_ruya_araba.add_child(model)
	# yağmur (kırılmaya kadar kapalı) ve karşıdan gelen farlar
	_ruya_yagmur = _yagmur_parcacik()
	_ruya_yagmur.emitting = false
	_ruya_kok.add_child(_ruya_yagmur)
	_karsi_far = Node3D.new()
	_karsi_far.visible = false
	_ruya_kok.add_child(_karsi_far)
	for x in [-0.65, 0.65]:
		var f := SpotLight3D.new()
		f.light_color = Color(1.0, 0.93, 0.8)
		f.light_energy = 14.0
		f.spot_range = 45.0
		f.spot_angle = 28.0
		f.position = Vector3(x, 1.0, 0)
		_karsi_far.add_child(f)
		var o := OmniLight3D.new()   # farın kendisi: gözü alan parlak nokta
		o.light_color = Color(1.0, 0.95, 0.85)
		o.light_energy = 3.0
		o.omni_range = 1.2
		o.position = Vector3(x, 1.0, -0.2)
		_karsi_far.add_child(o)
	_ruya_arac_koy(0.0)


func _yagmur_parcacik() -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.amount = 3000
	p.lifetime = 1.0
	p.visibility_aabb = AABB(Vector3(-20, -20, -20), Vector3(40, 30, 40))
	var m := ParticleProcessMaterial.new()
	m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	m.emission_box_extents = Vector3(14, 1, 14)
	m.direction = Vector3(0.05, -1, 0)
	m.spread = 2.0
	m.initial_velocity_min = 14.0
	m.initial_velocity_max = 17.0
	m.gravity = Vector3(0, -9.8, 0)
	p.process_material = m
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.7, 0.75, 0.85, 0.18)
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	var q := QuadMesh.new()
	q.size = Vector2(0.012, 0.45)
	q.material = mat
	p.draw_pass_1 = q
	return p


## Arabayı caddede ilerletir; kamera sürücü koltuğunda (sokak.tscn'deki Araba/Kamera), hep yola bakar.
func _ruya_arac_koy(sars: float) -> void:
	var yon := (RUYA_SON - RUYA_BAS).normalized()
	var p := RUYA_MERKEZ + RUYA_BAS + yon * _ruya_yol
	var b := Basis(Vector3.UP, atan2(-yon.x, -yon.z))
	_ruya_araba.global_transform = Transform3D(b, p)
	var goz := p + b * Vector3(-0.45, 1.32 + sin(ft * 3.1) * 0.006, -0.1)
	# baş hafifçe sağa sola, ama yan koltuğa dönmez
	var bak_yon := Basis(Vector3.UP, sin(ft * 0.13) * 0.07 + sin(ft * 0.31) * 0.03) * (b * Vector3(0, -0.06, -1))
	goz += Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)) * 0.012 * sars
	kamera.look_at_from_position(goz, goz + bak_yon, Vector3.UP)
	kamera.rotation.z += sin(ft * 0.7) * 0.006
	if _ruya_yagmur: _ruya_yagmur.global_position = p + Vector3(0, 9, 0) + yon * 6.0


func _ruya(dt: float) -> void:
	var sars := 0.0
	var hiz := _ruya_hiz
	if _ruya_kirilma >= 0.0:
		var k0 := ft - _ruya_kirilma
		sars = clampf((k0 - 2.0) / 4.0, 0.0, 1.0)
		# fren: 5.8'den sonra araba sert yavaşlar
		hiz = _ruya_hiz * (1.0 - smoothstep(5.8, 6.8, k0) * 0.85)
	_ruya_yol = minf(_ruya_yol + hiz * dt, RUYA_BAS.distance_to(RUYA_SON))
	_ruya_arac_koy(sars)
	if _ruya_kirilma < 0.0:
		# beyazdan açılır, piyano yükselir
		karartma = 1.0 - smoothstep(0.3, 3.0, ft)
		if ses_piyano.stream: ses_piyano.volume_db = move_toward(ses_piyano.volume_db, -9.0, dt * 12.0)
		if ft >= _ruya_sonraki:
			if _ruya_sira < RUYA_SIRA.size():
				var sat: Array = RUYA_SIRA[_ruya_sira]
				_ruya_sonraki = ft + _soyle(sat[0]) + float(sat[1])
				_ruya_sira += 1
			else:
				# piyano aniden kesilir, ışık titrer, yağmur gelir
				_ruya_kirilma = ft
				ses_piyano.stop()
				if ses_ruya_yagmur.stream: ses_ruya_yagmur.play()
		return
	var k := ft - _ruya_kirilma
	ses_ruya_yagmur.volume_db = move_toward(ses_ruya_yagmur.volume_db, -6.0, dt * 30.0)
	if _ruya_yagmur and k > 0.8: _ruya_yagmur.emitting = true
	_ruya_env.sky.sky_material.set("sky_top_color", Color(0.36, 0.58, 0.95).lerp(Color(0.12, 0.13, 0.15), smoothstep(0.0, 4.0, k)))
	_ruya_env.sky.sky_material.set("sky_horizon_color", Color(0.92, 0.9, 0.84).lerp(Color(0.2, 0.21, 0.23), smoothstep(0.0, 4.0, k)))
	_ruya_env.fog_density = lerpf(0.006, 0.03, smoothstep(0.0, 5.0, k))
	# karşıdan, Selim'in şeridine doğru farlar: 7.3'te çarpışırlar
	if k > 3.0 and _karsi_far:
		var yon := (RUYA_SON - RUYA_BAS).normalized()
		var biz := _ruya_araba.global_position
		var uzak := lerpf(70.0, 1.5, smoothstep(3.0, 7.3, k) * smoothstep(3.0, 7.3, k) * 0.4 + clampf((k - 3.0) / 4.3, 0.0, 1.0) * 0.6)
		_karsi_far.visible = true
		# son anda farlar arabanın içini bembeyaz doldurur
		for l in _karsi_far.get_children():
			if l is SpotLight3D: (l as SpotLight3D).light_energy = 14.0 * (1.0 + 4.0 * smoothstep(5.5, 7.3, k))
		_karsi_far.global_transform = Transform3D(Basis(Vector3.UP, atan2(yon.x, yon.z)), biz + yon * uzak + Vector3(0, 0, 0.6 * smoothstep(3.0, 7.0, k)))
	# ışık titrer ve söner, gökyüzü griye döner
	var titre := 1.0 if randf() < 0.75 else randf_range(0.15, 0.6)
	_ruya_env.tonemap_exposure = lerpf(0.85, 0.3, smoothstep(0.0, 5.0, k)) * titre
	_ruya_gunes.light_energy = lerpf(1.4, 0.1, smoothstep(0.0, 4.0, k)) * titre
	_ruya_env.fog_light_color = Color(0.86, 0.88, 0.9).lerp(Color(0.25, 0.27, 0.3), smoothstep(0.0, 5.0, k))
	_ruya_env.adjustment_saturation = lerpf(1.08, 0.3, smoothstep(0.0, 5.0, k))
	for c in [[1.4, "ruya10"], [2.9, "ruya11"], [4.3, "ruya12"]]:
		if k > float(c[0]) and not _soylenenler.has(c[1]): _soyle(c[1])
	if k > 5.8 and not _eylem.has("fren"):
		_eylem["fren"] = true
		_ses_cal("fren", 0.0)
	if k > 7.3 and not _eylem.has("carpma"):
		_eylem["carpma"] = true
		_ses_cal("carpma", 2.0)
		# ani kararma, sessizlik
		karartma = 1.0
		ses_ruya_yagmur.stop()
		ses_selim.stop()
		altyazi.visible = false
	if k > 7.3:
		karartma = 1.0
	if k > 8.5:
		_ruya_bitir()
		_gec("uyanis")
		_ses_cal("irkilme", -2.0)


func _ruya_bitir() -> void:
	if _ruya_kok: _ruya_kok.queue_free()
	_ruya_kok = null
	($Ortam as WorldEnvironment).environment = _ev_env
	$Aksam.visible = true
	if ses_piyano: ses_piyano.stop()
	if ses_ruya_yagmur: ses_ruya_yagmur.stop()
	if ses_ambiyans and ses_ambiyans.stream and not ses_ambiyans.playing: ses_ambiyans.play()


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
		# yatağın tuğla duvar tarafına (askılı sandalye, tablo) doğrulur, o taraftan kalkar
		[12.2, Vector3(-1.25, 1.18, -0.85), Vector3(-1.05, 0.0, -2.2)],
		[14.0, Vector3(-1.2, 1.2, -0.95), Vector3(-0.9, 0.05, -2.3)],
		[15.6, Vector3(-0.75, 1.63, -1.75), Vector3(-0.3, 1.45, -2.6)],
		[17.4, Vector3(0.4, 1.64, -0.35), Vector3(2.5, 1.45, 1.2)],
		[19.2, Vector3(1.6, 1.65, 1.3), Vector3(4.0, 1.45, 1.6)],
		[20.6, Vector3(2.3, 1.65, 1.6), Vector3(4.2, 1.45, 1.6)],
		[22.0, Vector3(3.35, 1.65, 1.6), Vector3(5.0, 1.45, 1.6)],
		# hola çıkar; karşısında banyonun kapısı
		[23.4, Vector3(4.3, 1.62, 1.7), Vector3(5.63, 1.3, 2.8)],
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
	if ft > 0.4 and not _eylem.has("nefes"):
		_eylem["nefes"] = true; _ses_cal("nefes_agir", -6.0)
	# gözünü açar açmaz, alarm daha çalarken söylenir; alarm o sırada biraz kısılır
	if ft > 2.2 and not _soylendi("ruya_sonra"): _soyle("ruya_sonra")
	ses_alarm.volume_db = -15.0 if ft > 2.2 and ft < ALARM_KAPAN else -9.0
	if ft > 9.2 and not _eylem.has("ic_cekis"):
		_eylem["ic_cekis"] = true; _ses_cal("ic_cekis", -4.0)
	if ft > 9.8 and not _eylem.has("carsaf"):
		_eylem["carsaf"] = true; _ses_cal("carsaf", -8.0)
	if ft > 12.0 and not _eylem.has("yatak1"):
		_eylem["yatak1"] = true; _ses_cal("yatak_gicirti", -10.0)
	if ft > 14.4 and not _eylem.has("yatak2"):
		_eylem["yatak2"] = true; _ses_cal("yatak_gicirti", -7.0)
	if ft > 15.0 and ft < 23.2:
		_adim_say(0.62)
	if ft > 3.4 and not _daktilo.has(saat_yazi) and saat_yazi.text != "18:00":
		_saat_goster("18:00")
	if ft >= 23.4:
		_bulanik(0.0)
		# holde: yatak odasının kapısı Selim uzaklaşınca kapanır; banyoya kendi yürür
		_hol_basla("banyo")


# ---------------------------------------------------------------- oynanabilir ev
## Hol: Selim bir odadan çıkınca holde kendi yürür, sıradaki odanın kapısına gidip E'ye basar.
## Kamera nerede kaldıysa oyuncu oradan devam eder.
func _hol_basla(hedef: String) -> void:
	_oturuyor = false
	_oyuna_don()
	_kutular = EV_ALAN
	_esyalar.clear()
	_hol_hedef = hedef
	if not _icerde(oyuncu.global_position):
		push_warning("hol başlangıcı alanın dışında: " + str(oyuncu.global_position))
	match hedef:
		"banyo":
			_gorev("Banyoya git")
			# banyo karanlık; ışığı içeride düğmeden açılır
			$Isiklar/BanyoLamba.light_energy = 0.0
		"mutfak":
			_gorev("Mutfağa git")
		"salon_kapisi":
			_gorev("Salona git")
		"dis":
			_gorev("Evden çık")
			_esya("ev_kapisi", KAPI_DIS[0] + Vector3(-0.1, 1.05, 0), 2.0)


## Selim hedef odaya yürüyerek girince o odanın işi başlar (ışınlanma, kararma yok).
func _oda_girisi() -> void:
	if _hol_hedef == "" or not ODA_GIRIS.has(_hol_hedef): return
	var p := oyuncu.global_position
	var k: AABB = ODA_GIRIS[_hol_hedef]
	if p.x < k.position.x or p.x > k.end.x or p.z < k.position.z or p.z > k.end.z: return
	var h := _hol_hedef
	_hol_hedef = ""
	_gorev("")
	_yurume_girisi = true
	_gec(h)


## Banyo: kapının hemen içinden, karanlıkta başlar. Işık, duş, sonra lavaboda diş fırçalama.
func _banyo_basla() -> void:
	_saat_goster("18:20")
	_oyuncu_yerlestir(Vector3(5.65, 0.0, 2.76), PI, BANYO_ALAN)
	$Isiklar/BanyoLamba.light_energy = 0.0
	_gorev("Duş al")
	_esya("banyo_isik", ISIK_DUGMESI, 1.8)
	get_tree().create_timer(2.0, false).timeout.connect(func() -> void: if not _soylendi("ic01"): _soyle("ic01"))


## Mutfak: kapının hemen içinden başlar, kapı arkasında kapalı.
func _mutfak_basla() -> void:
	_saat_goster("19:05")
	_oyuncu_yerlestir(Vector3(2.42, 0.0, -3.5), PI * 0.5, MUTFAK_ALAN)
	_gorev("Bir şeyler ye")
	get_tree().create_timer(2.5, false).timeout.connect(func() -> void: if not _soylendi("ic02"): _soyle("ic02"))
	if ResourceLoader.exists(BUZDOLABI_MODELI): _esya("buzdolabi", BUZDOLABI_YERI, 2.0)
	else: _esya("dolap", DOLAP, 2.0)
	# telefon masada, ekranı kapalı
	telefon.visible = true
	_tel_ekran(false)
	telefon.position = TEL_MASA
	telefon.rotation = Vector3(-PI * 0.5, 0.35, 0)
	telefon.scale = Vector3.ONE * TEL_OLCEK


## Salon: kapının hemen içinden başlar, koltuğa oturunca TV sinematiği başlar.
func _salon_basla() -> void:
	_salon_giris = T   # duvar saati salona girince 20:00'ı gösterir
	_saat_goster("20:00")
	$Aksam.visible = false   # gece: güneş artık pencereden vurmaz
	($Ortam as WorldEnvironment).environment.ambient_light_energy = 0.2
	_oyuncu_yerlestir(Vector3(8.05, 0.0, 0.295), 0.0, SALON_ALAN)
	_esya("koltuk", KOLTUK + Vector3(0.2, -0.5, 0), 3.2)


func _etkiles(ad: String) -> void:
	_esya_kaldir(ad)
	match ad:
		"banyo_isik":
			_zaman["banyo_isik"] = T
			eller.uzan("sag", ISIK_DUGMESI + Vector3(0.04, 0, 0), 0.25)
			get_tree().create_timer(0.45, false).timeout.connect(func() -> void: eller.birak("sag", 0.4))
			_ses_cal("dugme", -8.0)
			_ses_cal("floresan_tik", -6.0)
			_esya("dus", DUS_KAPI, 2.6)
		"lavabo": _sahne("s_lavabo")
		"dus": _sahne("s_dus")
		"buzdolabi": _sahne("s_buzdolabi")
		"dolap": _sahne("s_dolap")
		"masa": _sahne("s_masa")
		"telefon": _sahne("s_tel_al")
		"koltuk": _sahne("s_koltuk")
		"dis_kapi": _gec("dis_kapi")
		"ev_kapisi": _gec("ev_cikis")


## Kilitli kısa sahne: kamera oyuncunun baktığı yerden başlar.
func _sahne(ad: String) -> void:
	_bas_konum = _ham(kamera.global_position)
	_bas_bakis = kamera.global_position - kamera.global_basis.z * 1.5
	_gec(ad)


## Duştan sonra lavaboda dişlerini fırçalar, ağzını çalkalar, aynada kendine bakar.
## (Diş fırçası modeli gelene kadar yalnızca eli görünür.)
func _s_lavabo() -> void:
	var dur := Vector3(5.93, 1.6, 3.25)
	_yol([[0.0, _bas_konum, _bas_bakis], [1.2, dur, LAVABO + Vector3(0, -0.1, 0)], [2.4, dur, AYNA],
		[9.0, dur + Vector3(-0.02, 0.01, 0), AYNA + Vector3(0, 0.03, 0)],
		[9.8, dur + Vector3(-0.1, -0.16, 0), LAVABO], [11.2, dur + Vector3(-0.08, -0.12, 0), LAVABO],
		[12.4, dur, AYNA], [14.0, dur + Vector3(-0.03, 0, 0), AYNA + Vector3(0, 0.02, 0)]], ft)
	var f_yer := firca.global_position + Vector3(0, 0.1, 0) if firca else LAVABO + Vector3(0.12, 0.12, 0.1)
	if ft > 0.9 and not _eylem.has("l_el"):
		_eylem["l_el"] = true
		eller.uzan("sag", f_yer, 0.6)
	if ft > 1.5 and not _eylem.has("l_al"):
		_eylem["l_al"] = true
		# sap yumruğun içinde, fırça elle birlikte döner
		if firca: eller.tut("sag", firca, Eller.firca_tutusu(), 0.4)
	if ft > 1.6 and not _eylem.has("l_agiz"):
		_eylem["l_agiz"] = true
		eller.esyayla("sag", _firca_agizda(0.0, 0.0), Eller.firca_tutusu(), 0.6)
		eller.yumruk("sag", 1.0, 0.9)   # fırçayı tutan yumruk, başparmak sapın üstünde
	# fırçalama: fırça ağızda kısa kısa gidip gelir
	if ft > 2.4 and ft < 8.8:
		var adim := int((ft - 2.4) / 0.16)
		if not _eylem.has("f%d" % adim):
			_eylem["f%d" % adim] = true
			eller.esyayla("sag", _firca_agizda(1.0 if adim % 2 else -1.0, float((adim >> 2) % 2)), Eller.firca_tutusu(), 0.15)
	if ft > 2.5 and not _eylem.has("l_ses"):
		_eylem["l_ses"] = true; _ses_cal("dis_fircalama", -6.0)
	if ft > 8.9 and not _eylem.has("l_birak"):
		_eylem["l_birak"] = true; eller.birak("sag", 0.5)
	# lavaboya eğilir, suyu açıp ağzını çalkalar
	if ft > 9.7 and not _eylem.has("l_su"):
		_eylem["l_su"] = true; su_hedef = 0.6
		eller.uzan("sag", _firca_xf.origin + Vector3(0, 0.1, 0) if firca else LAVABO + Vector3(0.12, 0.12, 0.0), 0.5)
	if ft > 10.25 and not _eylem.has("l_koy"):
		_eylem["l_koy"] = true
		if firca:
			eller.tut("sag", null)
			firca.global_transform = _firca_xf
	if ft > 10.4 and not _eylem.has("l_calkala"):
		_eylem["l_calkala"] = true; _ses_cal("su_carpma", -12.0)
	if ft > 10.7 and not _eylem.has("l_cek"):
		_eylem["l_cek"] = true; eller.birak("sag", 0.6)
	if ft > 11.3 and not _eylem.has("l_kapa"):
		_eylem["l_kapa"] = true; su_hedef = 0.0
	if ft >= 14.0:
		_hol_basla("mutfak")


## Fırçalarken fırçanın kamera uzayındaki yeri: başı ağızda, sapı aşağıda sağda yumrukta.
## kay: -1..1 sağa sola fırçalama, alt: 0..1 alt ve üst dişler.
func _firca_agizda(kay: float, alt: float) -> Transform3D:
	var y := Vector3(-0.7, 0.3, 0.65).normalized()
	var z := Vector3(0.3, 0.4, 1.0)
	z = (z - y * z.dot(y)).normalized()
	var bas := Vector3(0.012 * kay, -0.1 - 0.012 * alt, -0.18)
	return Transform3D(Basis(y.cross(z), y, z), bas - y * 0.07)


func _s_dus() -> void:
	# önce kabinin kapısını açıp içeri girer, sonra suyu açar (t: kabin içindeki zaman)
	var t := ft - 2.0
	if ft > 1.0 and not _eylem.has("d_tut"):
		_eylem["d_tut"] = true
		eller.uzan("sag", dus_kapi_kol.global_position if dus_kapi_kol else DUS_KAPI, 0.5)
	if ft > 2.1 and not _eylem.has("d_kol_birak"):
		_eylem["d_kol_birak"] = true
		eller.birak("sag", 0.4)
	_dus_kapisi(smoothstep(1.4, 2.3, ft) * (1.0 - smoothstep(3.6, 4.6, ft)))
	# sıcak su: buhar aynayı buğular
	if t > 6.0: ayna_bugu = maxf(ayna_bugu, clampf((t - 6.0) / 8.0, 0.0, 0.85))
	_yol([
		[0.0, _bas_konum, _bas_bakis],
		[1.3, Vector3(5.6, 1.62, 4.23), Vector3(6.11, 1.05, 4.26)],
		[2.2, Vector3(5.65, 1.62, 4.23), Vector3(6.55, 1.45, 4.41)],
		[2.9, Vector3(6.1, 1.62, 4.23), Vector3(6.7, 1.5, 5.21)],
		[3.4, Vector3(6.45, 1.62, 4.36), Vector3(6.73, 1.5, 5.91)],
		[4.6, Vector3(6.65, 1.62, 4.86), Vector3(6.75, 1.7, 6.01)],
		[5.4, Vector3(6.65, 1.55, 4.86), Vector3(6.75, 1.0, 6.06)],
		[5.7, Vector3(6.59, 1.6, 4.76), Vector3(6.65, 1.9, 6.06)],
		[9.0, Vector3(6.65, 1.6, 4.81), Vector3(6.55, 1.9, 6.06)],
		[13.0, Vector3(6.65, 1.6, 4.81), Vector3(6.45, 1.3, 6.06)],
	], ft)
	if t > 2.4 and not _eylem.has("d_ac"):
		_eylem["d_ac"] = true
		eller.uzan("sag", Vector3(6.75, 1.13, 5.91), 0.6)
	if t > 3.0 and not _eylem.has("d_birak"):
		_eylem["d_birak"] = true
		eller.birak("sag", 0.5)
	su.emitting = t > 3.1 and t < 10.8
	if ses_dus.stream: dus_hedef = 1.0 if su.emitting else 0.0
	else: su_hedef = 1.0 if su.emitting else 0.0
	# su önce soğuk: Selim irkilir, titrer; sonra ısınır, buhar çıkar
	if t > 3.3 and not _eylem.has("d_irkil"):
		_eylem["d_irkil"] = true; _ses_cal("irkilme", -3.0)
	var soguk := smoothstep(3.2, 3.4, t) * (1.0 - smoothstep(5.0, 6.5, t))
	sallanti = 1.0 + soguk * 6.0
	kamera.rotation.z += sin(t * 31.0) * 0.012 * soguk
	buhar.emitting = t > 6.0
	if t > 6.0: damla_hedef = 0.8
	karartma = _egri([[0, 0], [10.0, 0], [11.0, 1]], t)
	if t >= 11.6:
		su.emitting = false; buhar.emitting = false; su_hedef = 0.0; dus_hedef = 0.0
		damla_hedef = 0.0
		_dus_kapisi(0.0)
		_oyuncu_yerlestir(Vector3(5.9, 0.0, 2.91), 0.0, BANYO_ALAN)
		_gorev("Dişlerini fırçala")
		_esya("lavabo", LAVABO, 1.7)


## Duş kabini: yan camdaki kapı modelde dar ve alçaktı (0.61 x 1.45 m). Boşluk genişler, kapının
## üstündeki cam bölme kalkar, kanat boşluğu doldurur; kanat menteşesinden dışarı doğru açılır.
var dus_kapi: Node3D
var dus_kapi_kol: Node3D

func _dus_kapisi_kur() -> void:
	var kanat := $Banyo.find_child("GlassDoor", true, false) as Node3D
	var kanat_cam := $Banyo.find_child("GlassDoor_DirtyGlass_0", true, false) as MeshInstance3D
	if kanat == null or kanat_cam == null: return
	var ab := kanat_cam.global_transform * kanat_cam.get_aabb()
	var eski_kenar := ab.end.z
	var mentese := Vector3(ab.get_center().x, ab.position.y, ab.position.z)
	var oran := Vector3(1.0, (DUS_UST - ab.position.y) / ab.size.y, (DUS_GENIS - ab.position.z) / ab.size.z)
	# yan cam: kapı boşluğunun kenarı DUS_GENIS'e kayar, boşluğun üstündeki bölme silinir
	for ad in ["GlassScreen1_DirtyGlass_0", "GlassScreen1_Rubber_0"]:
		var m := $Banyo.find_child(ad, true, false) as MeshInstance3D
		if m == null: continue
		_mesh_esle(m, func(w: Vector3) -> Vector3:
				if absf(w.z - eski_kenar) < 0.02: w.z = DUS_GENIS
				return w,
			func(a: Vector3, b: Vector3, c: Vector3) -> bool:
				return maxf(a.z, maxf(b.z, c.z)) < eski_kenar + 0.02 and minf(a.y, minf(b.y, c.y)) > ab.end.y - 0.03 and minf(a.z, minf(b.z, c.z)) < 3.91)
	for m in kanat.find_children("*", "MeshInstance3D", true, false):
		_mesh_esle(m as MeshInstance3D, func(w: Vector3) -> Vector3: return mentese + (w - mentese) * oran, Callable())
	# menteşede dönen bir eksen; kol da kanatla birlikte döner ve yeni kenara taşınır
	dus_kapi = Node3D.new()
	dus_kapi.name = "DusKapisi"
	add_child(dus_kapi)
	dus_kapi.global_position = mentese
	kanat.reparent(dus_kapi, true)
	var kol := $Banyo.find_child("ShowerDoorKnob", true, false) as Node3D
	if kol:
		kol.reparent(dus_kapi, true)
		kol.global_position += Vector3(0.0, 1.0 - kol.global_position.y + 0.0, DUS_GENIS - eski_kenar)
		dus_kapi_kol = kol


func _dus_kapisi(k: float) -> void:
	if dus_kapi == null: return
	var once: float = dus_kapi.get_meta("k", 0.0)
	if once < 0.02 and k >= 0.02: _ses_cal("dolap", -16.0)
	dus_kapi.set_meta("k", k)
	dus_kapi.rotation.y = deg_to_rad(-95.0) * k


## Bir modelin köşelerini dünya uzayında yeniden yerleştirir; sil doğruysa üçgen atılır.
func _mesh_esle(m: MeshInstance3D, f: Callable, sil: Callable) -> void:
	var gt := m.global_transform
	var ters := gt.affine_inverse()
	var yeni := ArrayMesh.new()
	for s in m.mesh.get_surface_count():
		var a := m.mesh.surface_get_arrays(s)
		var v: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
		var w := PackedVector3Array()
		w.resize(v.size())
		for i in v.size(): w[i] = gt * v[i]
		var ind: PackedInt32Array = a[Mesh.ARRAY_INDEX]
		if sil.is_valid() and ind.size() > 0:
			var kalan := PackedInt32Array()
			for t in range(0, ind.size(), 3):
				if not sil.call(w[ind[t]], w[ind[t + 1]], w[ind[t + 2]]):
					kalan.append(ind[t]); kalan.append(ind[t + 1]); kalan.append(ind[t + 2])
			a[Mesh.ARRAY_INDEX] = kalan
		for i in v.size(): v[i] = ters * (f.call(w[i]) as Vector3)
		a[Mesh.ARRAY_VERTEX] = v
		yeni.add_surface_from_arrays(m.mesh.surface_get_primitive_type(s), a, [], {}, m.mesh.surface_get_format(s))
		yeni.surface_set_material(s, m.get_active_material(s))
	m.mesh = yeni


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
	var g := _gecis
	var kesme: float = g["kesme"]
	# alp: kapılardan geçerken kamera sinematiği yok. Kapının sesi gelir, Selim anında öbür tarafta,
	# kontrol hemen ona döner. Yol kareleri yalnızca nereye varılacağını söyler.
	if not _eylem.has("aninda"):
		_eylem["aninda"] = true
		_kapi_sesi(true)
		g.erase("karart")
		var b_yol0: Array = g["b_yol"]
		ft = kesme + ((float(b_yol0[b_yol0.size() - 1][0]) + 0.6) if g["b_kapi"] else 0.0)
		eller.birak("sag", 0.01)
	# karanlığa açılan kapıdan geçerken ekran kararır
	karartma = smoothstep(kesme - float(g["karart"]), kesme, ft) if g.has("karart") else 0.0
	if ft < kesme:
		_yol(g["a_yol"], ft)
		var kapi: Node3D = g["a_kapi"]
		if kapi and g.has("kapa") and ft > float(g["kapa"]) and not _eylem.has("kapa"):
			# Selim geçti: kapı arkasından kapanır
			_eylem["kapa"] = true
			_kapanacak[kapi] = T
		if kapi and not _eylem.has("kapa"):
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
	if b_kapi == null:
		# karşı kapı yok: Selim aynı evin holüne ya da odasına geçti
		var kapi: Node3D = g["a_kapi"]
		if kapi and not _eylem.has("kapa") and not g.has("acik_kalsin"): _kapanacak[kapi] = T
		if g.has("hol_yer"):
			# holde, odanın kapısının önünde gözünü açar; kapı arkasından kapanır
			var tn: Array = g["hol_yer"]
			var hk: Node3D = g["hol_kapi"]
			var a := deg_to_rad(float(tn[1]))
			var ileri := Vector3(cos(a), 0.0, -sin(a))
			var p: Vector3 = tn[0] - ileri * 0.75
			kamera.look_at_from_position(Vector3(p.x, GOZ, p.z), Vector3(p.x, GOZ - 0.12, p.z) - ileri, Vector3.UP)
			hk.set_meta("k", 1.0)
			hk.rotation.y = PI * 0.5 * 0.95 * float(hk.get_meta("yon", 1.0))
			_kapanacak[hk] = T
		var sonraki: String = g["sonraki"]
		if sonraki.begins_with("hol:"): _hol_basla(sonraki.substr(4))
		else: _gec(sonraki)
		return
	if not _eylem.has("esik"):
		_eylem["esik"] = true
		eller.birak("sag", 0.01)
		# giriş kapısı açık durur, Selim geçince arkasından kapanır
		b_kapi.set_meta("k", 1.0)
		b_kapi.set_meta("yon", -1.0)   # geldiği holün tarafına açık
		b_kapi.rotation.y = -PI * 0.5 * 0.95
	var t := ft - kesme
	var b_yol: Array = g["b_yol"]
	_yol(b_yol, t)
	var bitis: float = b_yol[b_yol.size() - 1][0]
	_kapi_ac(b_kapi, t, bitis + 0.6, bitis - 0.2)
	if t < bitis: _adim_say(0.55)
	if t >= bitis + 0.6:
		b_kapi.set_meta("yon", 1.0)
		_gec(g["sonraki"])


func _s_buzdolabi() -> void:
	_yol([[0.0, _bas_konum, _bas_bakis], [1.0, BUZDOLABI_YERI + Vector3(1.0, 0.5, 0), BUZDOLABI_YERI], [5.0, BUZDOLABI_YERI + Vector3(1.0, 0.62, 0), BUZDOLABI_YERI + Vector3(0, -0.2, 0)]], ft)
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
	_yol([[0.0, _bas_konum, _bas_bakis], [1.0, Vector3(0.42, 1.64, -8.95), DOLAP + Vector3(0, -0.15, 0)], [4.6, Vector3(0.42, 1.64, -8.95), DOLAP + Vector3(0, -0.22, 0)]], ft)
	var acik := smoothstep(1.0, 1.7, ft) * (1.0 - smoothstep(3.6, 4.3, ft))
	_dolap_kapaklari(acik)
	if ft > 1.6 and not _eylem.has("do_el"):
		_eylem["do_el"] = true
		eller.uzan("sag", DOLAP + Vector3(0.15, -0.05, 0.1), 0.7)
		_ses_cal("dolap", -10.0)
	if ft > 2.3 and not _eylem.has("do_al") and gevrek:
		_eylem["do_al"] = true
		eller.tut("sag", gevrek)
	if ft > 2.8 and not _eylem.has("do_birak"):
		_eylem["do_birak"] = true
		# kutu elde, önde tutulur; masaya kadar taşınır
		if gevrek: eller.kamerada("sag", Vector3(0.14, -0.3, -0.42), 0.7)
		else: eller.birak("sag", 0.7)
	if ft >= 4.6:
		_oyuna_don()
		_esya("masa", Vector3(2.32, 0.6, -5.05), 1.9)


func _s_masa() -> void:
	var otur := Vector3(2.37, 1.25, -4.15)
	_yol([[0.0, _bas_konum, _bas_bakis], [1.6, Vector3(2.47, 1.6, -3.8), KASE], [2.6, otur, KASE], [9.0, otur, KASE + Vector3(0.05, 0, 0)],
			[10.0, otur, KASE + Vector3(0.18, 0, 0.08)], [12.6, otur, KASE + Vector3(0.24, 0.05, -0.04)], [ILAC_SURE + 9.0, otur, KASE + Vector3(0.05, 0, 0)]], ft)
	if ft > 1.8 and not _eylem.has("m_sandalye"):
		_eylem["m_sandalye"] = true; _ses_cal("sandalye", -8.0)
	if ft > 8.7 and not _soylendi("ic03"): _soyle("ic03")
	if ft > 2.4 and not _eylem.has("m_kutu") and gevrek and gevrek.get_parent() != null:
		_eylem["m_kutu"] = true
		eller.uzan("sag", KASE + Vector3(-0.2, 0.12, -0.05), 0.5)
	if ft > 2.95 and not _eylem.has("m_kutu_birak") and _eylem.has("m_kutu"):
		_eylem["m_kutu_birak"] = true
		eller.tut("sag", null)
		gevrek.global_rotation = Vector3(0, PI * 0.5, 0)
		var gk := _dunya_kutusu(gevrek)
		gevrek.global_position += KASE + Vector3(-0.24, -0.01, -0.1) - Vector3(gk.get_center().x, gk.position.y, gk.get_center().z)
		eller.birak("sag", 0.5)
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
	_ilac_ic(ft - 9.0)
	if ft >= ILAC_SURE + 9.0:
		_gorev("")
		_otur(otur, KASE + Vector3(0.05, 0, 0))
		_esya("telefon", TEL_MASA, 1.2)


func _s_tel_al() -> void:
	var otur := Vector3(2.37, 1.25, -4.15)
	_yol([[0.0, _bas_konum, _bas_bakis], [0.8, otur, TEL_MASA], [2.2, otur + Vector3(0, -0.02, 0), Vector3(2.37, 0.65, -4.92)]], ft)
	if ft > 0.3 and not _eylem.has("t_el"):
		_eylem["t_el"] = true
		eller.uzan("sag", TEL_MASA + Vector3(0, 0.03, 0.04), 0.6)
	if ft > 1.0 and not _eylem.has("t_al"):
		_eylem["t_al"] = true
		telefon.reparent(kamera, true)
		telefon.scale = Vector3.ONE * TEL_OLCEK
		_tel_ekran(true)
		# telefon avuca oturur, el onu yüzün önüne getirir; ikisi birlikte hareket eder
		eller.tut("sag", telefon, Eller.telefon_tutusu(), 0.5)
		eller.esyayla("sag", _tel_elde(), Eller.telefon_tutusu(), 0.8)
		eller.yumruk("sag", 0.65, 0.1)
	if ft >= 2.2:
		_gec("tel_kaydir")
		_gorev("Fare tekerleği: kaydır")


## Telefonun elde, kamera uzayındaki yeri: aşağıda, ortanın biraz sağında, ekranı göze dönük.
## sallan: elin hafif titremesi.
func _tel_elde(sallan := 0.0) -> Transform3D:
	var merkez := Vector3(0.04 + sin(T * 0.7) * 0.003 * sallan, -0.055 + sin(T * 1.1) * 0.002 * sallan, -0.245)
	var z := (-merkez + Vector3(0, 0.05, 0)).normalized()
	var y := Vector3(-0.08 + sin(T * 0.9) * 0.02 * sallan, 1.0, 0.0)
	y = (y - z * y.dot(z)).normalized()
	return Transform3D(Basis(y.cross(z), y, z), merkez)


## Telefonda video kaydırır; bir süre sonra bildirim gelir, Q ile telefon masaya ters bırakılır.
func _tel_kaydir() -> void:
	var otur := Vector3(2.37, 1.25, -4.15)
	_yol([[0.0, otur + Vector3(0, -0.02, 0), Vector3(2.37, 0.65, -4.92)], [20.0, otur + Vector3(0, -0.03, 0), Vector3(2.39, 0.64, -4.9)]], ft)
	sallanti = 0.6
	# telefon avuçta; el hafifçe sallanır, telefon onunla birlikte
	eller.esyayla("sag", _tel_elde(1.0), Eller.telefon_tutusu(), 0.01)
	if (_kaydirilan >= 4 or ft > 16.0) and not tel_bildirim.visible:
		tel_bildirim.visible = true
		_ses_cal("bildirim", -10.0)
		get_tree().create_timer(2.2, false).timeout.connect(func() -> void: if faz == "tel_kaydir" and not _soylendi("ic04"): _soyle("ic04"))
		_zaman["bildirim"] = T
		_gorev("Q  Telefonu bırak")
	if tel_bildirim.visible:
		var u := clampf((T - float(_zaman["bildirim"])) / 0.4, 0.0, 1.0)
		tel_bildirim.position.y = lerpf(-120.0, 18.0, u)


func _s_tel_birak() -> void:
	var otur := Vector3(2.37, 1.25, -4.15)
	_yol([[0.0, otur, Vector3(2.39, 0.64, -4.9)], [1.2, otur, TEL_MASA], [3.4, otur + Vector3(0.1, 0.3, 0.2), Vector3(3.97, 1.4, -3.4)]], ft)
	if not _eylem.has("tb"):
		_eylem["tb"] = true
		_gorev("")
		eller.tut("sag", null)
		telefon.reparent(self, true)
		eller.uzan("sag", TEL_MASA + Vector3(0, 0.05, 0.04), 0.9)
	# telefon masaya ekranı aşağı bakacak şekilde konur
	var k := smoothstep(0.1, 1.0, ft)
	telefon.global_position = telefon.global_position.lerp(TEL_MASA + Vector3(0, 0.005, 0), k)
	telefon.global_rotation = telefon.global_rotation.lerp(Vector3(PI * 0.5, 0.35, 0), k)
	if ft > 1.0 and not _eylem.has("tb_ses"):
		_eylem["tb_ses"] = true
		_ses_cal("telefon_masa", -8.0)
		_tel_ekran(false)
		eller.birak("sag", 0.6)
	if ft >= 3.4:
		# telefonu bırakınca masada bir sigara yakar
		_gec("s_sigara")


## Mutfak masasında sigara: paketten alır, çakmakla yakar, birkaç nefes çeker; sonra kalkıp çıkar.
var sigara: Node3D

func _s_sigara() -> void:
	var otur := Vector3(2.37, 1.25, -4.15)
	var pk := ($SigaraPaketi as Node3D).global_position if has_node("SigaraPaketi") else KASE + Vector3(0.24, 0.0, -0.16)
	if not _eylem.has("sg_kur"):
		_eylem["sg_kur"] = true
		if sigara == null:
			sigara = Sigara.new()
			add_child(sigara)
		sigara.kur(kamera, eller, pk)
	_yol([[0.0, otur + Vector3(0.1, 0.3, 0.2), Vector3(3.97, 1.4, -3.4)], [0.9, otur, pk], [2.4, otur, pk + Vector3(-0.3, 0.55, -0.3)],
		[8.0, otur + Vector3(0, -0.02, 0), Vector3(1.17, 1.15, -5.4)], [14.0, otur + Vector3(0.02, -0.03, 0), Vector3(0.77, 1.2, -5.0)],
		[Sigara.SURE, otur, Vector3(0.97, 1.15, -5.1)]], ft)
	if sigara.oynat(ft):
		_mutfaktan_cik(otur, Vector3(0.97, 1.15, -5.1))


## Kalkar, mutfak kapısını karanlığa doğru iter, holde gözünü açar; salona kendi yürür.
func _mutfaktan_cik(bas: Vector3, bakis: Vector3) -> void:
	_gecis_basla([[0.0, bas, bakis],
			[1.1, Vector3(2.4, 1.6, -3.55), Vector3(3.57, 1.3, -3.45)]],
		null, Vector2.ZERO, 1.2,
		null, [], "hol:salon_kapisi")


## Selim salona girince önce koltuğun üstündeki fotoğraf duvarına bakar (yaklaşık 30 sn), resimleri
## tek tek gezer; sonra koltuğa oturur ve TV sinematiği başlar.
const FOTO_SURE := 30.0
const F_COCUK := Vector3(4.61, 2.28, -1.145)
const F_VERANDA := Vector3(4.61, 1.66, -1.145)
const F_DUGUN := Vector3(4.61, 2.01, -1.885)
const F_AILE := Vector3(4.61, 2.01, -3.035)
const F_SEVGILI := Vector3(4.61, 2.28, -3.925)
const F_VESIKA := Vector3(4.61, 1.66, -3.925)

func _s_koltuk() -> void:
	var dur := Vector3(6.75, 1.62, -2.005)
	var yakin := Vector3(6.2, 1.6, -1.705)
	# 2. gün resimlere bakmadan doğrudan oturur
	if _gece() != 1:
		_oturma(ft, _bas_konum, _bas_bakis)
		return
	if ft < FOTO_SURE:
		_yol([[0.0, _bas_konum, _bas_bakis],
			[2.2, dur, Vector3(4.61, 1.9, -2.505)],
			[4.4, dur, Vector3(4.61, 1.95, -2.505)],
			[6.4, yakin, F_COCUK],
			[9.6, yakin + Vector3(-0.05, -0.01, 0), F_COCUK + Vector3(0, -0.02, 0)],
			[11.0, yakin, F_VERANDA],
			[14.0, yakin + Vector3(-0.03, 0, 0.02), F_VERANDA + Vector3(0, 0.02, 0)],
			[16.0, Vector3(6.15, 1.6, -2.255), F_DUGUN],
			[20.5, Vector3(6.07, 1.58, -2.255), F_DUGUN + Vector3(0, -0.03, 0)],
			[22.4, Vector3(6.15, 1.6, -2.805), F_AILE],
			[25.0, Vector3(6.13, 1.6, -2.855), F_AILE + Vector3(0, -0.02, 0)],
			[26.6, Vector3(6.2, 1.6, -3.255), F_SEVGILI],
			[28.0, Vector3(6.2, 1.6, -3.305), F_VESIKA],
			[FOTO_SURE, Vector3(6.2, 1.6, -3.305), F_VESIKA + Vector3(0, -0.04, 0)]], ft)
		if ft > 18.0 and not _eylem.has("f_ic"):
			_eylem["f_ic"] = true; _ses_cal("ic_cekis", -6.0)
		if ft > 23.5 and not _eylem.has("f_nefes"):
			_eylem["f_nefes"] = true; _ses_cal("nefes_agir", -12.0)
		return
	_oturma(ft - FOTO_SURE, Vector3(6.2, 1.6, -3.305), F_VESIKA + Vector3(0, -0.04, 0))


## Kaçıncı gece (Duraklat kaydından); 1. gün resimlere bakılır, MAZGAL yazısı çıkar.
func _gece() -> int:
	var d := get_node_or_null("/root/Duraklat")
	return int(d.gece) if d else 1


## Durduğu yerden koltuğa yürüyüp oturur; oturunca TV sinematiği başlar.
func _oturma(k: float, bas: Vector3, bakis: Vector3) -> void:
	_yol([[0.0, bas, bakis], [1.2, Vector3(6.05, 1.55, -2.505), KOLTUK + Vector3(-0.3, -0.5, -0.2)], [2.8, Vector3(5.95, 1.5, -1.705), KOLTUK + Vector3(-0.3, -0.5, -0.2)], [4.2, KOLTUK + Vector3(0, 0, 0.05), EKRAN + Vector3(0, -0.05, 0)]], k)
	if k > 3.4 and not _eylem.has("k_cok"):
		_eylem["k_cok"] = true; _ses_cal("koltuk", -6.0)
	if k >= 4.2:
		# kapı arkasından kapanır, TV sinematiği başlar
		_zaman.erase("salon_kapi")
		_gec("salon")


func _salon() -> void:
	_yol([[0.0, KOLTUK + Vector3(0, 0, 0.05), EKRAN + Vector3(0, -0.05, 0)], [7.0, KOLTUK, EKRAN]], ft)
	karartma = 0.0
	# MAZGAL yazısı yalnızca ilk gün çıkar
	if _gece() == 1 and ft > 1.2 and not _daktilo.has(baslik) and baslik.text == "":
		baslik.text = "MAZGAL"
		baslik.modulate.a = 1.0
		_daktilo_basla(baslik, 0.34, true)
	if ft > 5.0:
		baslik.modulate.a = maxf(0.0, 1.0 - (ft - 5.0) / 0.8)
	if ft >= 7.0: _gec("yayin")


func _yayin() -> void:
	_yol([[0.0, KOLTUK, EKRAN], [PROGRAM_SURE, KOLTUK + Vector3(0, -0.01, 0), EKRAN], [PROGRAM_SURE + 6.0, KOLTUK + Vector3(0.1, -0.02, 0), EKRAN], [PROGRAM_SURE + 18.0, Vector3(9.1, 0.86, -2.305), EKRAN]], ft)
	karartma = 0.0
	sallanti = 0.7
	# anlatıcının sesi bitince (dosya yoksa yayın süresi dolunca) biter
	var sure := (ses_anlatici.stream.get_length() if ses_anlatici.stream else TV_SURE) + PROGRAM_SURE
	if ft >= sure + 0.6:
		ses_anlatici.stop()
		_gec("geri")


func _geri() -> void:
	_yol([[0.0, Vector3(9.1, 0.86, -2.305), EKRAN], [3.4, KOLTUK, EKRAN + Vector3(0, 0.05, 0)]], ft)
	if ft > 1.0 and not _soylendi("ev1"): _soyle("ev1")
	if ft >= 4.6: _gec("saat")


var _soylenenler := {}
func _soylendi(k: String) -> bool:
	return _soylenenler.has(k)


func _saat() -> void:
	var saat_on := SAAT_YERI + Vector3(-0.05, 0, 0)
	_yol([[0.0, KOLTUK, EKRAN + Vector3(0, 0.05, 0)], [3.0, KOLTUK, saat_on], [16.0, KOLTUK + Vector3(0.02, 0, 0), saat_on]], ft)
	if ft > 0.6 and not _soylendi("ev2"): _soyle("ev2")
	if ses_saat_tik and ses_saat_tik.stream:
		if ft < 13.05 and not ses_saat_tik.playing: ses_saat_tik.play()
		elif ft >= 13.05 and ses_saat_tik.playing: ses_saat_tik.stop()
	kamera.fov = lerpf(70.0, 7.0, smoothstep(0.8, 3.6, ft))
	sallanti = lerpf(1.0, 0.25, smoothstep(0.8, 3.6, ft))
	# saat su gibi akar: 20:10 -> 23:00
	var u := smoothstep(4.0, 13.0, ft)
	u = u * u * (3.0 - 2.0 * u)
	dakika = lerpf(_saat_bas, 23.0 * 60.0, u)
	# göz kapakları ağırlaşır: yavaş, uzun kırpışlar
	karartma = _egri([[0, 0], [5.2, 0], [5.9, 0.75], [6.4, 0.1], [8.3, 0.1], [9.1, 0.9], [9.8, 0.2], [11.4, 0.2], [12.1, 0.95], [12.9, 0.15], [13.6, 0.0], [16, 0]], ft)
	_bulanik(_egri([[0, 0], [5.0, 0], [6.0, 0.12], [9.5, 0.2], [12.6, 0.25], [13.3, 0.0], [16, 0]], ft))
	# 23:00 olunca saat çalar; Selim irkilir
	if ft > 13.05 and not _eylem.has("gong"):
		_eylem["gong"] = true
		for i in 3:
			get_tree().create_timer(i * 1.15, false).timeout.connect(func() -> void: _ses_cal("saat_gong", -6.0))
	if ft >= 16.0: _gec("cikis")


func _cikis() -> void:
	var saat_on := SAAT_YERI + Vector3(-0.05, 0, 0)
	_yol([
		[0.0, KOLTUK + Vector3(0.02, 0, 0), saat_on],
		[1.6, KOLTUK + Vector3(0.05, 0.03, 0.05), Vector3(7.45, 1.0, -0.405)],
		[3.3, Vector3(6.05, 1.65, -1.605), Vector3(7.75, 1.5, 0.595)],
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
	if ft >= 3.3:
		# ayağa kalktı: dış kapıya kendi yürür
		_hol_basla("dis")


## Dış kapıda E: salonun ışığını kapatır, kapıdan çıkar; arkasında kapı kilitlenir, merdiven otomatiği yanar.
func _ev_cikis() -> void:
	if not _eylem.has("isik_kapa"):
		_eylem["isik_kapa"] = true
		_ses_cal("dugme", -8.0)
		($Isiklar/SalonLamba as Light3D).light_energy = 0.0
		if _salon_ampul: _salon_ampul.light_energy = 0.0
	_kapi_ac(kapi_dis, ft, 0.3, 1.2)
	karartma = _egri([[0, 0], [1.0, 0], [1.8, 1]], ft)
	if ft > 1.9 and not _eylem.has("kapi_kapa"):
		_eylem["kapi_kapa"] = true
		_ses_cal("dolap", -4.0)
	if ft > 2.5 and not _eylem.has("kilit"):
		_eylem["kilit"] = true
		_ses_cal("anahtar", -10.0)
		get_tree().create_timer(0.5, false).timeout.connect(func() -> void: _ses_cal("kilit", -6.0))
	if ft > 3.6 and not _eylem.has("otomat"):
		_eylem["otomat"] = true
		_ses_cal("otomat", -8.0)
		_merdiven_isik(true)
	if _merdiven_isiklar.is_empty(): _merdiven_in(ft)
	elif ft >= 4.0: _merdiven_basla()


## Ev tek parça olunca odaların modellerinde fazla kalan parçalar: salonun hola bakan pencereleri,
## banyonun kapı önündeki hol döşemesi.
func _ev_parcalari_gizle() -> void:
	for ad in ["Plane_002_Material_006_0", "Plane_002_Material_012_0", "Plane_004_Material_006_0", "Plane_004_Material_013_0", "Plane_Material_006_0"]:
		var n := $Salon.find_child(ad, true, false) as Node3D
		if n: n.visible = false
	var h := $Banyo.find_child("HallFlag__0", true, false) as Node3D
	if h: h.visible = false


# ---------------------------------------------------------------- merdiven boşluğu
## alp'in merdiven boşluğu modeli (horror_corridor_vr_room_baked.glb). Evden çıkarken 2 kat kesintisiz inilir.
## Bir modül bir tam kat: sahanlıktan bir kol aşağı (-4.0), bir kol yukarı (+3.9) gider. Modüller 7.9 m arayla
## üst üste dizilince bir katın aşağı kolu, alttaki katın yukarı kolunun başına bağlanır.
## Aynı boşluk ileride yeraltında da kullanılacak: merdiven_kur() başka sahneden de çağrılabilir.
const MERDIVEN_MODEL := YENI_MODELLER + "horror_corridor_vr_room_baked.glb"
## Taban y=30 (en alt kat 14.2): göz yükseklikleri hep _alcak eşiğinin üstünde kalsın (aynı boy düzeltmesi her karede).
const MERDIVEN_YERI := Vector3(80.0, 30.0, 0.0)
## 1 cm yana kayma: üst üste binen duvarlar aynı düzlemde titreşmesin
## model gerçeğin ~2,2 katı: 0,6 ile kapı 1,8–1,9 m, basamak 23 cm
const MERDIVEN_OLCEK := 0.6
const MERDIVEN_ARA := Vector3(0.01, -7.9 * MERDIVEN_OLCEK, 0.01)
const MERDIVEN_KAT := 3
const KAT_SURE := 11.0
## pişmiş ışığın gece payı (1 = modeldeki gibi gündüz parlaklığı)
const MERDIVEN_PARLAK := 0.3
var _merdiven_isiklar: Array[Light3D] = []


static func merdiven_kur(ana: Node3D, yer: Vector3, ara: Vector3, kat: int, carpisma := false) -> Array[Light3D]:
	var isiklar: Array[Light3D] = []
	if not ResourceLoader.exists(MERDIVEN_MODEL): return isiklar
	var paket := load(MERDIVEN_MODEL) as PackedScene
	for k in kat:
		var b := yer + ara * k
		var m := paket.instantiate() as Node3D
		m.name = "MerdivenKat%d" % k
		ana.add_child(m)
		m.global_position = b
		m.scale = Vector3.ONE * MERDIVEN_OLCEK
		if carpisma:
			# katlar arası geçit: alt sahanlığın çıkmaz duvarı (z 6.6) bir alttaki katın merdiven başına açılır.
			# En üst katta yukarıya, en alt katta aşağıya delik açılmaz.
			var delikler: Array[AABB] = []
			if k < kat - 1: delikler.append(AABB(Vector3(-4.9, -4.1, 6.5), Vector3(2.05, 3.6, 0.35)))
			if k > 0:
				delikler.append(AABB(Vector3(-4.9, 3.8, 6.5), Vector3(2.05, 2.4, 0.35)))
				# alttaki katın tavanı, üstteki katın aşağı inen kolunun içinden geçer: kolun üstünde açılır
				delikler.append(AABB(Vector3(-4.9, 5.85, 3.5), Vector3(6.35, 0.3, 3.15)))
				# küçülünce geçitte baş sığsın: ara sahanlığın üstü de açık
				delikler.append(AABB(Vector3(-4.9, 5.85, 6.5), Vector3(4.3, 0.3, 3.2)))
			for mi in m.find_children("*", "MeshInstance3D", true, false):
				if not delikler.is_empty(): _gecit_ac(mi as MeshInstance3D, delikler)
				(mi as MeshInstance3D).create_trimesh_collision()
		# modelin ışığı dokuya pişmiş (emission); otomatik lamba yanınca o da yanar
		for mi in m.find_children("*", "MeshInstance3D", true, false):
			for i in (mi as MeshInstance3D).mesh.get_surface_count():
				var mat := (mi as MeshInstance3D).get_active_material(i) as BaseMaterial3D
				if mat == null or not mat.emission_enabled: continue
				mat = mat.duplicate() as BaseMaterial3D
				mat.set_meta("parlak", mat.emission_energy_multiplier)
				mat.emission_energy_multiplier = 0.0
				(mi as MeshInstance3D).set_surface_override_material(i, mat)
				var tut := OmniLight3D.new()   # malzemeyi lambalarla birlikte bulmak için
				tut.visible = false
				tut.set_meta("malzeme", mat)
				ana.add_child(tut)
				isiklar.append(tut)
		# sahanlıkta, basamağın ortasında ve alt sahanlıkta otomatik lamba
		for l in [Vector3(3.2, 2.6, 6.6), Vector3(-0.6, 0.4, 5.1), Vector3(-4.0, -1.5, 6.6)]:
			var o := OmniLight3D.new()
			o.light_color = Color(1.0, 0.86, 0.62)
			o.omni_range = 5.5 * MERDIVEN_OLCEK
			o.omni_attenuation = 1.6
			o.light_energy = 0.0
			o.shadow_enabled = false
			ana.add_child(o)
			o.global_position = b + l * MERDIVEN_OLCEK
			isiklar.append(o)
	return isiklar


## Modelin yerel uzayında kutuların içinde kalan üçgenleri siler (görüntüden ve çarpışmadan).
static func _gecit_ac(mi: MeshInstance3D, kutular: Array[AABB]) -> void:
	var yerel := mi.transform   # modül kökünden mesh'e
	var p := mi.get_parent()
	while p and not p.name.begins_with("MerdivenKat"):
		if p is Node3D: yerel = (p as Node3D).transform * yerel
		p = p.get_parent()
	var yeni := ArrayMesh.new()
	for s in mi.mesh.get_surface_count():
		var dizi := mi.mesh.surface_get_arrays(s)
		var v: PackedVector3Array = dizi[Mesh.ARRAY_VERTEX]
		var idx: PackedInt32Array = dizi[Mesh.ARRAY_INDEX]
		if idx.is_empty():
			idx = PackedInt32Array(range(v.size()))
		var kalan := PackedInt32Array()
		for i in range(0, idx.size(), 3):
			var sil := false
			for k: AABB in kutular:
				if k.has_point(yerel * v[idx[i]]) and k.has_point(yerel * v[idx[i + 1]]) and k.has_point(yerel * v[idx[i + 2]]):
					sil = true
					break
			if not sil:
				kalan.append(idx[i]); kalan.append(idx[i + 1]); kalan.append(idx[i + 2])
		dizi[Mesh.ARRAY_INDEX] = kalan
		yeni.add_surface_from_arrays(mi.mesh.surface_get_primitive_type(s), dizi)
		yeni.surface_set_material(s, mi.mesh.surface_get_material(s))
	# yüzey malzemesi geçersiz kılınmışsa (ışık için kopyalanan) korunur
	var ozel: Array = []
	for s in mi.mesh.get_surface_count(): ozel.append(mi.get_surface_override_material(s))
	mi.mesh = yeni
	for s in ozel.size():
		if ozel[s]: mi.set_surface_override_material(s, ozel[s])


func _merdiven_isik(acik: bool) -> void:
	for o in _merdiven_isiklar:
		if o.has_meta("malzeme"):
			var mat := o.get_meta("malzeme") as BaseMaterial3D
			mat.emission_energy_multiplier = float(mat.get_meta("parlak")) * (MERDIVEN_PARLAK if acik else 0.0)
		else:
			o.light_energy = 0.55 if acik else 0.0
	# merdiven boşluğunda gece: ortam ışığı ve sis neredeyse söner, sadece otomatik lambalar
	if acik:
		var e := ($Ortam as WorldEnvironment).environment
		e.ambient_light_energy = 0.04
		e.fog_density = 0.008


## Kapı kilitlenince Selim üst kat sahanlığında kendi yürür; iki kat inip zemin kattaki dış kapıda E'ye basar.
## Bir modülde: sahanlık y=0 (x 1.5..4.8), aşağı kol z<6.6 (y -4'e), ara sahanlık x<-2.7, yukarı kol z>6.6 (y +3.9'a).
func _merdiven_basla() -> void:
	_merdivende = true
	oyuncu.global_position = MERDIVEN_YERI + Vector3(3.9, 0.0, 5.6) * MERDIVEN_OLCEK
	oyuncu.velocity = Vector3.ZERO
	_yaw = PI * 0.5
	_pitch = -0.2
	_oturuyor = false
	_kutular = []
	_esyalar.clear()
	_esya("dis_kapi", MERDIVEN_YERI + MERDIVEN_ARA * (MERDIVEN_KAT - 1) + Vector3(4.75, 1.1, 8.45) * MERDIVEN_OLCEK, 2.2)
	faz = "oyun"
	ft = 0.0
	_eylem.clear()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_gorev("Binadan çık")
	_oyun_kamera(0.0)


## En üst katta yukarı çıkan kol, en alt katta aşağı inen kol görünmez duvarla kapanır.
func _merdiven_engeller() -> void:
	var alt := MERDIVEN_YERI + MERDIVEN_ARA * (MERDIVEN_KAT - 1)
	var S := MERDIVEN_OLCEK
	for e in [[MERDIVEN_YERI + Vector3(1.7, 1.5, 8.1) * S, Vector3(0.2, 3.0, 3.0 * S)], [alt + Vector3(1.7, 0.5, 5.1) * S, Vector3(0.2, 3.0, 3.0 * S)]]:
		var g := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var k := BoxShape3D.new()
		k.size = e[1]
		cs.shape = k
		g.add_child(cs)
		add_child(g)
		g.global_position = e[0]


## Dış kapı: kilit, kapı, yağmur sesi yükselir, kararır, sokak.
func _dis_kapi() -> void:
	if not _eylem.has("dis_kapi"):
		_eylem["dis_kapi"] = true
		_gorev("")
		_ses_cal("kilit", -8.0)
		get_tree().create_timer(0.3, false).timeout.connect(func() -> void: _ses_cal("dolap", -4.0))
	karartma = _egri([[0, 0], [0.4, 0], [1.4, 1]], ft)
	_yagmur_ac(ft, 0.3, 2.4)
	if ft >= 2.8: _sokaga()


## (model yoksa) Kapı kilitlendikten sonra: üst kattan iki kat iner, zemin katta dış kapıya yürür, kapı açılınca yağmur.
func _merdiven_in(ft: float) -> void:
	if _merdiven_isiklar.is_empty():
		# model yoksa eski karanlık geçiş
		if ft > 9.0 and ft < 12.4: _adim_say(0.42)
		_yagmur_ac(ft, 10.5, 13.0)
		if ft >= 13.2: _sokaga()
		return
	if ft < 9.0: return
	var y := MERDIVEN_YERI
	var a := MERDIVEN_ARA
	# her kat 11 sn: sahanlık, aşağı kol, dönüş sahanlığı, ikinci kol, alttaki sahanlık
	var kat := clampi(int((ft - 9.0) / KAT_SURE), 0, 2)
	var b := y + a * kat
	if kat < 2:
		var s := 9.0 + KAT_SURE * kat
		_yol([
			[s, b + Vector3(3.9, 1.6, 5.6), b + Vector3(0.0, 1.2, 5.3)],
			[s + 1.0, b + Vector3(3.2, 1.6, 5.3), b + Vector3(-1.0, 0.0, 5.1)],
			[s + 2.2, b + Vector3(1.6, 1.3, 5.1), b + Vector3(-2.2, -1.6, 5.1)],
			[s + 4.6, b + Vector3(-2.6, -1.8, 5.1), b + Vector3(-4.6, -2.6, 5.4)],
			[s + 5.6, b + Vector3(-3.7, -2.4, 4.9), b + Vector3(-4.0, -2.6, 7.8)],
			[s + 6.6, b + Vector3(-3.6, -2.4, 7.9), b + Vector3(0.0, -5.5, 8.1)],
			[s + 9.2, b + Vector3(1.0, -5.6, 8.1), b + Vector3(3.0, -6.5, 7.6)],
			[s + 10.2, b + Vector3(2.8, -6.3, 7.6), b + Vector3(3.2, -6.6, 5.3)],
			[s + KAT_SURE, b + a + Vector3(3.9, 1.6, 5.6), b + a + Vector3(0.0, 1.2, 5.3)],
		], ft)
		if ft > s + 0.4 and ft < s + 10.2: _adim_say(0.42)
	else:
		var s := 9.0 + KAT_SURE * 2
		_yol([
			[s, b + Vector3(3.9, 1.6, 5.6), b + Vector3(0.0, 1.2, 5.3)],
			[s + 0.8, b + Vector3(3.0, 1.6, 5.3), b + Vector3(4.6, 1.4, 7.0)],
			[s + 2.6, b + Vector3(3.9, 1.6, 7.3), b + Vector3(5.0, 1.45, 7.7)],
		], ft)
		if ft > s + 0.2 and ft < s + 2.4: _adim_say(0.5)
	# açılışta göz açılır, dış kapıda kararır; katlar arasında kesme yok
	var son := 9.0 + KAT_SURE * 2
	karartma = _egri([[9.0, 1], [9.7, 0], [son + 2.3, 0], [son + 3.1, 1]], ft)
	if ft > son + 2.0 and not _eylem.has("dis_kapi"):
		_eylem["dis_kapi"] = true
		_ses_cal("kilit", -8.0)
		get_tree().create_timer(0.3, false).timeout.connect(func() -> void: _ses_cal("dolap", -4.0))
	_yagmur_ac(ft, son + 2.2, son + 4.4)
	if ft >= son + 4.8: _sokaga()


func _yagmur_ac(ft: float, bas: float, son: float) -> void:
	if ft <= bas: return
	if _yagmur_ev == null:
		_yagmur_ev = AudioStreamPlayer.new()
		_yagmur_ev.stream = _ses_bul("yagmur")
		add_child(_yagmur_ev)
		_yagmur_ev.volume_db = -40.0
		_yagmur_ev.play()
	_yagmur_ev.volume_db = lerpf(-40.0, -6.0, smoothstep(bas, son, ft))


func _sokaga() -> void:
	if _bitti: return
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
	var yan := float(tanim[3])
	if yan > 0.0: _karanlik_kutu(kok, Vector3(0.07, -0.01, -0.85), Vector3(1.8, 2.4, 0.85), "-x")
	elif yan < 0.0: _karanlik_kutu(kok, Vector3(-1.8, -0.01, -0.85), Vector3(-0.07, 2.4, 0.85), "+x")
	return mentese


## Kapının arkasındaki karanlık: a..b kutusunun açık yüzü dışındaki beş yüzü, ışık almayan siyah.
func _karanlik_kutu(ana: Node3D, a: Vector3, b: Vector3, acik: String) -> void:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.006, 0.006, 0.008)
	mat.disable_fog = true
	var o := (a + b) * 0.5
	var s := b - a
	var k := 0.02
	var yuzler := {
		"-y": [Vector3(o.x, a.y, o.z), Vector3(s.x, k, s.z)], "+y": [Vector3(o.x, b.y, o.z), Vector3(s.x, k, s.z)],
		"-x": [Vector3(a.x, o.y, o.z), Vector3(k, s.y, s.z)], "+x": [Vector3(b.x, o.y, o.z), Vector3(k, s.y, s.z)],
		"-z": [Vector3(o.x, o.y, a.z), Vector3(s.x, s.y, k)], "+z": [Vector3(o.x, o.y, b.z), Vector3(s.x, s.y, k)],
	}
	for y: String in yuzler:
		if y == acik: continue
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = yuzler[y][1]
		bm.material = mat
		mi.mesh = bm
		mi.position = yuzler[y][0]
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		ana.add_child(mi)


## Kapıyı t0..t1 arasında açar (t0 > t1 verilirse kapatır). Açılırken gıcırtı, kapanınca tok ses.
func _kapi_ac(mentese: Node3D, t: float, t0: float, t1: float) -> void:
	if mentese == null: return
	var k := smoothstep(t0, t1, t)
	var once: float = mentese.get_meta("k", 0.0)
	if once < 0.02 and k >= 0.02: _kapi_sesi(true)
	if once > 0.02 and k <= 0.02: _kapi_sesi(false)
	mentese.set_meta("k", k)
	# Selim'in açtığı kapı ona doğru açılır (çekilir); yon -1 olan kapı öbür tarafa açık durur
	mentese.rotation.y = PI * 0.5 * k * 0.95 * float(mentese.get_meta("yon", 1.0))


## Kapı Selim'e doğru açılırken kanadın süpürdüğü yerdeyse Selim kapıdan dik yönde biraz geri çekilir
func _kapidan_cekil(mentese: Node3D, t: float) -> void:
	if t > 1.2 or faz != "oyun" or oyuncu == null: return
	var m := Vector2(mentese.global_position.x, mentese.global_position.z)
	var kok := mentese.get_parent() as Node3D
	var kanat := (Vector2(kok.global_position.x, kok.global_position.z) - m).normalized()   # menteşeden kapının ortasına
	var dik := Vector2(-kanat.y, kanat.x)
	var p := Vector2(oyuncu.global_position.x, oyuncu.global_position.z)
	var a := (p - m).dot(kanat)
	var b := (p - m).dot(dik)
	if (p - m).length() >= 1.1 or a < -0.2 or a > 1.1: return
	var gerek := sqrt(maxf(0.0, 1.1 * 1.1 - a * a))
	var yon := signf(b) if absf(b) > 0.01 else 1.0
	var yeni_b := yon * move_toward(absf(b), maxf(absf(b), gerek), get_process_delta_time() * 2.5)
	var y2 := m + kanat * a + dik * yeni_b
	var y := Vector3(y2.x, 0.0, y2.y)
	if _icerde(y): oyuncu.global_position = y


## Banyonun kendi kapısı modelde açık durur; başta kapalıya çevrilir, Selim girerken açılır.
func _banyo_kapisi_kur() -> void:
	var m := $Banyo.find_child("Door_Door_material_0", true, false) as Node3D
	if m == null: return
	kapi_banyo = m.get_parent() as Node3D if m.get_parent() is Node3D and m.get_parent() != $Banyo else m
	_banyo_acik = kapi_banyo.global_transform
	_banyo_mentese = $Banyo.global_transform * Vector3(-0.92, 0.0, -1.49)
	kapi_banyo.set_meta("k", 1.0)
	_banyo_kapisi(2.0)
	# hola açılan kanat tam açılıp duvara yaslanır, holü kapatmaz
	var yasla := Transform3D(Basis(Vector3.UP, deg_to_rad(60.0)), Vector3.ZERO)
	kapi_banyo.global_transform = Transform3D(Basis(), _banyo_mentese) * yasla * Transform3D(Basis(), -_banyo_mentese) * kapi_banyo.global_transform


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
	m.position = Vector3(9.95, 0.0, -2.305)


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


## Salonun duvarındaki büyük çerçeveye ailenin fotoğrafı konur. Modelin kendi çerçevesi kalır,
## yalnızca içindeki resim değişir. Çerçevenin UV'si ters (v aşağıdan yukarı), burada düzeltilir.
const AILE_FOTO := "res://modeller2/seliminevi/aile_fotografi_cerceve.jpg"

func _aile_fotografi() -> void:
	var tuval := $Salon.find_child("Plane_002_Material_012_0", true, false) as MeshInstance3D
	if tuval == null or not ResourceLoader.exists(AILE_FOTO):
		return
	var m := StandardMaterial3D.new()
	m.albedo_texture = load(AILE_FOTO)
	m.roughness = 0.55
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	# modelin UV'si 0.036-0.964 (u) ve 0.009-0.991 (v) arası: fotoğrafı tam o alana yay, dikeyde çevir
	m.uv1_scale = Vector3(1.0 / 0.928, -1.0 / 0.9817, 1.0)
	m.uv1_offset = Vector3(-0.036 / 0.928, 0.9908 / 0.9817, 0.0)
	tuval.set_surface_override_material(0, m)


## Salonun koltuk üstündeki duvarı Selim'in fotoğraf duvarı: modelin ikinci büyük çerçevesine düğün
## fotoğrafı konur, alp'in çerçeve modeli küçültülmeden kopyalanıp yanlara dört küçük çerçeve olarak asılır.
## Duvar x = 4.61'de, odaya +x yönüne bakar; odadan bakınca sol taraf +z.
const FOTO_DUGUN := "res://modeller2/seliminevi/foto_dugun.jpg"
const FOTO_KUCUK := [
	["res://modeller2/seliminevi/foto_cocuk_vesikalik.jpg", Vector3(4.61, 2.28, -1.145)],
	["res://modeller2/seliminevi/foto_cocuk_veranda.jpg", Vector3(4.61, 1.66, -1.145)],
	["res://modeller2/seliminevi/foto_sevgili.jpg", Vector3(4.61, 2.28, -3.925)],
	["res://modeller2/seliminevi/foto_vesikalik.jpg", Vector3(4.61, 1.66, -3.925)],
]
const FOTO_KUCUK_BOY := 0.52                       # küçük çerçevelerin dış yüksekliği (m)
var foto_noktalari: Array[Vector3] = []             # Selim'in baktığı resimlerin ortaları

func _foto_duvari() -> void:
	var cerceve := $Salon.find_child("Plane_002_Material_006_0", true, false) as MeshInstance3D
	var tuval := $Salon.find_child("Plane_002_Material_012_0", true, false) as MeshInstance3D
	var tuval2 := $Salon.find_child("Plane_004_Material_013_0", true, false) as MeshInstance3D
	if tuval2 and ResourceLoader.exists(FOTO_DUGUN):
		_tuvale_resim(tuval2, tuval2.global_transform, load(FOTO_DUGUN))
		foto_noktalari.append((tuval2.global_transform * tuval2.get_aabb()).get_center())
	if tuval:
		foto_noktalari.append((tuval.global_transform * tuval.get_aabb()).get_center())
	if cerceve == null or tuval == null:
		return
	var dis: AABB = cerceve.global_transform * cerceve.get_aabb()
	var ic: AABB = tuval.global_transform * tuval.get_aabb()
	var orta := dis.get_center()
	for f in FOTO_KUCUK:
		if not ResourceLoader.exists(f[0]):
			continue
		var tex: Texture2D = load(f[0])
		# fotoğrafın en/boy oranına göre çerçeve: tuvalin oranı resminkine eşitlenir
		var oran := float(tex.get_width()) / float(tex.get_height())
		var sy := FOTO_KUCUK_BOY / dis.size.y
		var sz := (ic.size.y * sy * oran) / ic.size.z
		var hedef: Vector3 = f[1]
		var don := Transform3D(Basis.from_scale(Vector3(1, sy, sz)), hedef) * Transform3D(Basis(), -orta)
		var c := cerceve.duplicate() as MeshInstance3D
		var t := tuval.duplicate() as MeshInstance3D
		$Salon.add_child(c); $Salon.add_child(t)
		c.global_transform = don * cerceve.global_transform
		t.global_transform = don * tuval.global_transform
		_tuvale_resim(t, tuval.global_transform, tex)
		foto_noktalari.append(hedef)


## Tuval düzleminin UV'si dünyadaki konumdan yeniden hesaplanır: odadan bakınca resmin solu +z,
## üstü +y. Böylece modelin kendi (ters) UV'sine bakılmadan resim tam tuvale oturur.
func _tuvale_resim(mi: MeshInstance3D, xf: Transform3D, tex: Texture2D) -> void:
	var kaynak := mi.mesh
	var yeni := ArrayMesh.new()
	for s in kaynak.get_surface_count():
		var d := kaynak.surface_get_arrays(s)
		var v: PackedVector3Array = d[Mesh.ARRAY_VERTEX]
		var g := PackedVector3Array()
		for p in v: g.append(xf * p)
		var zmin := INF; var zmax := -INF; var ymin := INF; var ymax := -INF
		for p in g:
			zmin = minf(zmin, p.z); zmax = maxf(zmax, p.z); ymin = minf(ymin, p.y); ymax = maxf(ymax, p.y)
		var uv := PackedVector2Array()
		for p in g:
			uv.append(Vector2((zmax - p.z) / maxf(zmax - zmin, 0.0001), (ymax - p.y) / maxf(ymax - ymin, 0.0001)))
		d[Mesh.ARRAY_TEX_UV] = uv
		yeni.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, d)
	mi.mesh = yeni
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.roughness = 0.55
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	for s in yeni.get_surface_count():
		mi.set_surface_override_material(s, m)


## Mutfak modelindeki oturma eşyaları odaya göre çok iri geliyor: her biri kendi tabanının ortası
## etrafında gerçek boyuna küçültülür (masa 75 cm, koltuk 90 cm, hasır sehpa 59 cm, tabure 52 cm).
const MUTFAK_MOBILYA := {"Stol_Main": 0.58, "Divanus": 0.6, "Divan": 0.7, "Styl": 0.6}

func _mutfak_mobilyasi() -> void:
	for ad in MUTFAK_MOBILYA:
		var n := $Mutfak.find_child(ad, true, false) as Node3D
		if n == null: continue
		var k := _dunya_kutusu(n)
		var taban := Vector3(k.get_center().x, k.position.y, k.get_center().z)
		var f: float = MUTFAK_MOBILYA[ad]
		n.global_transform = Transform3D(Basis.from_scale(Vector3.ONE * f), taban - taban * f) * n.global_transform


## Mutfak dolaplarındaki abur cubur ve erzak (alp'in gönderdiği paketlerden), masada kaşık.
## Üst dolap (Door2/Door3) tabanı 1.602, yanındaki dolap (Door_2) 1.594, alttaki açık raflar 1.239 ve 0.903.
const ERZAK := "res://modeller2/seliminevi/food_collection_-_game_ready.glb"
const ERZAK2 := "res://modeller2/seliminevi/long_life_food.glb"
const KASIK := "res://modeller2/spoon.glb"
const ERZAK_YERLERI := [
	# Nesquik'in durduğu üst dolap: Selim'in uzandığı yerin önünde mısır gevreği
	[ERZAK, "SM_Cereal_01", Vector3(-0.91, 1.602, -9.02), 90.0],
	[ERZAK, "SM_Porridge_01", Vector3(-1.13, 1.602, -8.88), 90.0],
	[ERZAK, "SM_Coffee_Box_01", Vector3(-1.17, 1.602, -9.2), 90.0],
	[ERZAK, "SM_Candies_01", Vector3(-0.88, 1.602, -9.3), 80.0],
	[ERZAK, "SM_Chocolate_Bar_01", Vector3(-0.86, 1.617, -9.29), 100.0],
	[ERZAK, "SM_Chocolate_Bar_02", Vector3(-0.9, 1.602, -8.82), 70.0],
	[ERZAK, "SM_Chewing_Gum_01", Vector3(-0.83, 1.602, -8.85), 20.0],
	[ERZAK, "SM_Pasta_01", Vector3(-1.18, 1.602, -9.43), 90.0],
	[ERZAK2, "beans", Vector3(-0.98, 1.602, -9.42), 0.0],
	[ERZAK, "SM_Canned_Food_07", Vector3(-1.18, 1.602, -8.79), 0.0],
	[ERZAK, "SM_Canned_Food_08", Vector3(-1.2, 1.602, -9.02), 0.0],
	[ERZAK, "SM_Canned_Food_09", Vector3(-1.2, 1.682, -9.02), 30.0],
	# yandaki üst dolap
	[ERZAK2, "tomatoes", Vector3(-1.08, 1.594, -8.5), 0.0],
	[ERZAK, "SM_Canned_Food_06", Vector3(-1.18, 1.594, -8.3), 0.0],
	[ERZAK, "SM_Olive_Oil_01", Vector3(-1.21, 1.594, -8.12), 0.0],
	[ERZAK, "SM_Salt_02", Vector3(-1.13, 1.594, -8.62), 90.0],
	[ERZAK, "SM_Canned_Food_12", Vector3(-1.06, 1.594, -8.22), 0.0],
	# alttaki açık raflar
	[ERZAK2, "sardines", Vector3(-0.98, 1.239, -9.38), 15.0],
	[ERZAK, "SM_Canned_Food_05", Vector3(-0.98, 1.239, -8.88), 90.0],
	[ERZAK, "SM_Canned_Food_10", Vector3(-1.03, 1.239, -9.12), 0.0],
	[ERZAK, "SM_Canned_Food_11", Vector3(-0.98, 0.903, -9.3), 0.0],
	[ERZAK, "SM_Canned_Food_13", Vector3(-1.03, 0.903, -9.15), 0.0],
	[ERZAK, "SM_Matches_Box_01", Vector3(-0.93, 0.903, -8.9), 30.0],
]
var _paketler := {}

func _mutfak_erzak() -> void:
	var ana := Node3D.new()
	ana.name = "Erzak"
	add_child(ana)
	for e: Array in ERZAK_YERLERI:
		var n := _parca_koy(e[0], e[1], e[2], e[3], 1.0, ana)
		if e[1] == "SM_Cereal_01": gevrek = n
	# masada, kâsenin yanında kaşık (model 3.5 m boyunda geliyor, gerçek boyuna, 17 cm'ye getirilir)
	_parca_koy(KASIK, "", KASE + Vector3(0.13, -0.01, 0.02), 75.0, 0.17 / 3.56, ana)
	for k in _paketler: (_paketler[k] as Node).free()
	_paketler.clear()


## alp'in modeller2/modeller2'ye attığı eşyalar: yatağın yanında sandalye ve komidin, salonda kumanda,
## mutfak masasında süt. Model ölçüleri gerçek boylarına getirilir.
const YENI_MODELLER := "res://modeller2/modeller2/"
const YENI_TV := YENI_MODELLER + "tv_and_tv_stand.glb"
const FIRCA_YERI := Vector3(5.1, 0.908, 3.48)   # lavabonun duvar tarafındaki kenarı, süngerin yanı
var firca: Node3D
var gevrek: Node3D          # Selim'in dolaptan alıp masaya götürdüğü mısır gevreği kutusu
var ilac_kutusu: Node3D
var kapsul: Node3D          # alp'in ilaç modeli: kutudan alınan tek kapsül
var su_sisesi: Node3D
var _sise_xf: Transform3D
const ILAC_MODELI := "res://modeller2/seliminevi/variety_of_pills.glb"
var _firca_xf: Transform3D
func _yeni_esyalar() -> void:
	var ana := Node3D.new()
	ana.name = "YeniEsyalar"
	add_child(ana)
	_parca_koy(YENI_MODELLER + "chair.glb", "", Vector3(-1.0, 0.0, 1.78), 0.0, 1.0, ana)
	_parca_koy(YENI_MODELLER + "painted_wooden_nightstand.glb", "", Vector3(-2.1, 0.0, -1.62), 90.0, 1.0, ana)
	# lavabonun kenarında yatan diş fırçası (model dik geliyor: yatırılır, kılları yukarı)
	firca = _parca_koy(YENI_MODELLER + "toothbrush_low_poly.glb", "", Vector3.ZERO, 0.0, 1.0, ana)
	if firca:
		firca.rotation_degrees = Vector3(90, 6, 0)
		var fk := _dunya_kutusu(firca)
		firca.global_position += FIRCA_YERI - Vector3(fk.get_center().x, fk.position.y, fk.get_center().z)
		_firca_xf = firca.global_transform
	_parca_koy(ERZAK, "SM_Milk_Bottle_01", KASE + Vector3(-0.22, -0.01, -0.16), 20.0, 1.0, ana)
	# antidepresan: masada ilaç kutusu ve su şişesi; Selim yemekten sonra bir kapsül alıp suyla içer (alp)
	ilac_kutusu = _parca_koy(ERZAK, "SM_Pills_Box_01", KASE + Vector3(0.24, -0.01, 0.12), 15.0, 1.0, ana)
	su_sisesi = _parca_koy(ERZAK, "SM_Bottle_01", KASE + Vector3(0.34, -0.01, -0.12), 0.0, 1.0, ana)
	if su_sisesi: _sise_xf = su_sisesi.global_transform
	kapsul = _parca_koy(ILAC_MODELI, "Pill1", Vector3.ZERO, 0.0, 0.024, ana)
	if kapsul: kapsul.visible = false
	# kumanda sehpada yatar (model dik duruyor, 5 cm boyunda; gerçek boyu ~13 cm)
	var k := _parca_koy(YENI_MODELLER + "tv_remote_-_psx.glb", "", Vector3.ZERO, 0.0, 2.6, ana)
	if k:
		k.rotation_degrees = Vector3(-90, 75, 0)
		var kutu := _dunya_kutusu(k)
		k.global_position += Vector3(6.13, 0.445, -2.205) - Vector3(kutu.get_center().x, kutu.position.y, kutu.get_center().z)
	for p in _paketler: (_paketler[p] as Node).free()
	_paketler.clear()
	_merdiven_isiklar = merdiven_kur(ana, MERDIVEN_YERI, MERDIVEN_ARA, MERDIVEN_KAT, true)
	if not _merdiven_isiklar.is_empty(): _merdiven_engeller()


## Yeni TV ve sehpası (alp'in modeli): eski tüplü TV ile sehpanın yerine geçer, yayın düz ekrana basılır.
func _yeni_tv(em: Material) -> void:
	if not ResourceLoader.exists(YENI_TV): return
	var m: Node3D = (load(YENI_TV) as PackedScene).instantiate()
	m.name = "YeniTV"
	add_child(m)
	m.scale = Vector3.ONE * 0.23
	m.rotation_degrees.y = -90.0
	var ekran := m.find_child("Cube_001_Material_003_0", true, false) as MeshInstance3D
	var kutu := _dunya_kutusu(m)
	# sehpa salonun duvarına (x 38.8) dayanır, ekranın ortası eski ekranın hizasına gelir
	m.global_position += Vector3(38.8 - kutu.end.x, -kutu.position.y, 0.0)
	if ekran:
		var e := _dunya_kutusu(ekran)
		m.global_position.z += EKRAN.z - e.get_center().z
		if em is StandardMaterial3D:
			(em as StandardMaterial3D).uv1_scale = Vector3.ONE
			(em as StandardMaterial3D).uv1_offset = Vector3.ZERO
		_ekran_uv_duzelt(ekran)
		ekran.material_override = em
		ekran.layers = 2
	tv.visible = false
	var eski := get_node_or_null("TVSehpasi") as Node3D
	if eski: eski.visible = false


## Yeni TV'nin ekran yüzeyinin UV'si 90 derece dönük (görüntü dikey çıkıyordu).
## UV'yi ekranın dünyadaki duruşuna göre yeniden yazar: soldan sağa (+z) u, yukarıdan aşağı v.
## Ekran 4:3'ten geniş: görüntü genişliğe oturur, üstü ve altı eşit kırpılır.
func _ekran_uv_duzelt(ekran: MeshInstance3D) -> void:
	var am := ArrayMesh.new()
	var en := 1.0; var boy := 1.0
	for y in ekran.mesh.get_surface_count():
		var a := ekran.mesh.surface_get_arrays(y)
		var v: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
		var dv: Array[Vector3] = []
		var alt := Vector3.INF; var ust := -Vector3.INF
		for p in v:
			var d := ekran.global_transform * p
			dv.append(d); alt = alt.min(d); ust = ust.max(d)
		en = maxf(ust.z - alt.z, 0.001); boy = maxf(ust.y - alt.y, 0.001)
		var gorunen := minf(1.0, boy / en * 4.0 / 3.0)
		var uv := PackedVector2Array()
		for d in dv:
			uv.append(Vector2((d.z - alt.z) / en, 0.5 - gorunen * 0.5 + gorunen * (ust.y - d.y) / boy))
		a[Mesh.ARRAY_TEX_UV] = uv
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, a)
	ekran.mesh = am


## Bir modelin (ya da içindeki bir parçanın) kopyasını, alt yüzünün ortası verilen noktaya gelecek şekilde koyar.
func _parca_koy(yol: String, ad: String, yer: Vector3, aci: float, olcek: float, ana: Node3D) -> Node3D:
	if not ResourceLoader.exists(yol):
		return null
	if not _paketler.has(yol):
		_paketler[yol] = (load(yol) as PackedScene).instantiate()
	var kok: Node = _paketler[yol]
	var kaynak: Node3D = kok as Node3D if ad == "" else kok.find_child(ad, true, false) as Node3D
	if kaynak == null:
		return null
	var don := Transform3D.IDENTITY
	if kaynak != kok:
		var n: Node = kaynak
		while n != kok:
			don = (n as Node3D).transform * don
			n = n.get_parent()
	var kopya := kaynak.duplicate() as Node3D
	kopya.transform = don
	# kopyanın kendi içindeki kutusu
	var kutu := AABB()
	var ilk := true
	var liste: Array = kaynak.find_children("*", "MeshInstance3D", true, false)
	if kaynak is MeshInstance3D: liste.append(kaynak)
	for m in liste:
		var n: Node = m
		var yol_t := Transform3D.IDENTITY
		while n != kaynak:
			yol_t = (n as Node3D).transform * yol_t
			n = n.get_parent()
		var k: AABB = (don * yol_t) * (m as MeshInstance3D).get_aabb()
		kutu = k if ilk else kutu.merge(k)
		ilk = false
	var tut := Node3D.new()
	tut.name = kaynak.name if ad != "" else yol.get_file().get_basename()
	ana.add_child(tut)
	tut.add_child(kopya)
	tut.scale = Vector3.ONE * olcek
	tut.rotation_degrees.y = aci
	var alt := Vector3(kutu.get_center().x, kutu.position.y, kutu.get_center().z)
	tut.position = yer - tut.basis * alt
	return tut


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
		gercek = 20.0 * 60.0 + (T - _salon_giris) / 60.0
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
	var bas := Vector3(6.73, 1.7, 5.93)
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
	buhar.position = Vector3(6.65, 0.6, 5.11)
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


func _soyle(anahtar: String) -> float:
	_soylenenler[anahtar] = true
	var s: Array = SATIRLAR[anahtar]
	var kim: String = s[2] if s.size() > 2 else "SELİM"
	var yol: String = s[0]
	# 2. gecenin rüyası: alp'in ruya2_01..12 kayıtları varsa onlar çalar (sıra anahtarın numarasıdır)
	if anahtar.begins_with("ruya") and anahtar.substr(4).is_valid_int() and _gece() >= 2:
		var ikinci := "res://sesler/ruya2_%s.mp3" % anahtar.substr(4)
		if ResourceLoader.exists(ikinci): yol = ikinci
	var akis: AudioStream = load(yol) if ResourceLoader.exists(yol) else null
	var sure := 2.6 if kim == "SELİM" else 2.2 + str(s[1]).length() * 0.06
	if akis:
		ses_selim.stream = akis
		ses_selim.play()
		sure = akis.get_length() + 0.6
	altyazi.text = tr(kim) + ": " + tr(s[1])
	altyazi.visible = _altyazi_acik()
	_altyazi_bitis = T + sure
	return sure


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
	ses_dus = AudioStreamPlayer.new(); add_child(ses_dus)
	if ResourceLoader.exists("res://sesler/dus.mp3"):
		var ds: AudioStream = load("res://sesler/dus.mp3")
		if ds is AudioStreamMP3: (ds as AudioStreamMP3).loop = true
		ses_dus.stream = ds
	ses_arka = AudioStreamPlayer.new(); add_child(ses_arka)
	if ResourceLoader.exists(ARKA_MUZIK):
		var am: AudioStream = load(ARKA_MUZIK)
		if am is AudioStreamMP3: (am as AudioStreamMP3).loop = true
		ses_arka.stream = am
	ses_arka.volume_db = -80.0
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
	if acilis and ResourceLoader.exists("res://sesler/kapi_ac.mp3"):
		ses_kapi.stream = load("res://sesler/kapi_ac.mp3")   # alp'in kapı açma sesi
		ses_kapi.volume_db = -4.0
	else:
		ses_kapi.stream = _gicirti_sesi() if acilis else _kapanma_sesi()
		ses_kapi.volume_db = -10.0
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
	dus_ses = move_toward(dus_ses, dus_hedef, dt * 1.2)
	if ses_dus.stream:
		if dus_ses > 0.001 and not ses_dus.playing: ses_dus.play()
		elif dus_ses <= 0.001 and ses_dus.playing: ses_dus.stop()
		ses_dus.volume_db = linear_to_db(maxf(dus_ses, 0.0001)) - 4.0
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
	_program_kur(yazi)
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
	// görüntünün en dış pikselleri ekran kopyasının kenarından renk sızdırıyordu: tüpün kenarı siyah
	vec2 su = SCREEN_UV;
	c *= step(0.012, su.x) * step(su.x, 0.988) * step(0.015, su.y) * step(su.y, 0.985);
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
	em.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	ekran.material_override = em
	tv.add_child(ekran)
	# modelin kendi tüp camında renk çubukları resmi var; kenarları düz yüzeyin dışına taşıyordu.
	# görüntü doğrudan bu kavisli cama basılır, düz yüzey kullanılmaz.
	var tup := tv.find_child("Cube_CRTScreen_0", true, false) as MeshInstance3D
	if tup:
		tup.material_override = em
		em.uv1_scale = Vector3(1, -1, 1)   # camın UV'si ters
		em.uv1_offset = Vector3(0, 1, 0)
		tup.layers = 2
		ekran.visible = false
	_yeni_tv(em.duplicate())
	(tv_ust.material as ShaderMaterial).set_shader_parameter("acilis", 0.0)


func _tv_guncelle(dt: float) -> void:
	var um := tv_ust.material as ShaderMaterial
	um.set_shader_parameter("zaman", T)
	if not tv_acik:
		# kapatılınca ekran söner: görüntü, video ve odayı çeken kamera durur
		um.set_shader_parameter("acilis", move_toward(float(um.get_shader_parameter("acilis")), 0.0, dt * 5.0))
		if tv_video and tv_video.is_playing(): tv_video.stop()
		if tv_oda_kamera: tv_oda_kamera.current = false
		_tv_kare = []
		tv_isigi.light_energy = 0.0
		kar_hedef = 0.0
		return
	var onceki_t := tv_t
	tv_t += dt
	if tv_program: tv_program.visible = tv_t < PROGRAM_SURE
	if tv_t < PROGRAM_SURE:
		_program_oyna(dt, um)
		return
	if onceki_t < PROGRAM_SURE:
		# yayın araya girer: program sesi kesilir, parazit patlar, anlatıcı başlar
		if ses_program: ses_program.stop()
		ses_anlatici.play()
		ses_muzik.play()
		_ses_cal("crt", -4.0)
		_tv_kare = []
	var t := tv_t - PROGRAM_SURE
	t = t if t < TV_SURE else 1.0 + fmod(t - 1.0, TV_SURE - 1.0)
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
	var acilis := 1.0   # TV program sırasında açıldı; yayın açık ekrana girer
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
	kapsul.radius = 0.17   # dar banyo ve kapı aralarında takılmasın
	kapsul.height = 1.1
	cs.shape = kapsul
	# yerdeki halı, eşik gibi alçak şeylere takılmasın diye gövde yerden 0.5 m yukarıda başlar
	cs.position.y = 1.05
	oyuncu.add_child(cs)
	add_child(oyuncu)
	oyuncu.global_position = Vector3(0, -50, 0)


## Odaların modellerinden çarpışma yüzeyi çıkarır (oyuncu duvarlardan ve eşyalardan geçmesin).
func _carpisma_kur() -> void:
	var kokler: Array[Node] = [$YatakOdasi, $Banyo, $Mutfak, $Salon, $TV]
	kokler.append_array(_kapi_kokleri)
	var sehpa := get_node_or_null("TVSehpasi")
	if sehpa: kokler.append(sehpa)
	for k in kokler:
		for m in k.find_children("*", "MeshInstance3D", true, false):
			var mi := m as MeshInstance3D
			if mi.mesh == null or not mi.is_visible_in_tree(): continue
			mi.create_trimesh_collision()


func _oyuncu_yerlestir(konum: Vector3, yaw: float, kutular: Array) -> void:
	# ev tek parça: yürüyerek girildiyse Selim olduğu yerde kalır, her yere yürüyebilir
	if not _yurume_girisi:
		oyuncu.global_position = Vector3(konum.x, 0.0, konum.z)
		oyuncu.velocity = Vector3.ZERO
		_yaw = yaw
		_pitch = -0.08
	_yurume_girisi = false
	_kutular = EV_ALAN if not kutular.is_empty() else kutular
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
	if _merdivende:
		_basamak(dt)
		return
	var p := oyuncu.global_position
	p.y = 0.0
	if not _icerde(p):
		var px := Vector3(p.x, 0.0, once.z)
		var pz := Vector3(once.x, 0.0, p.z)
		if _icerde(px): p = px
		elif _icerde(pz): p = pz
		else: p = Vector3(once.x, 0.0, once.z)
		# görünmez sınıra yaslanınca adım sesi ve sallantı olmasın: hız gerçek harekete eşitlenir
		if dt > 0.0:
			oyuncu.velocity.x = (p.x - once.x) / dt
			oyuncu.velocity.z = (p.z - once.z) / dt
	oyuncu.global_position = p
	_oda_girisi()


## Merdivende ayak altındaki basamağı ışınla bulur; gövde basamaklara yumuşakça iner/çıkar.
func _basamak(dt: float) -> void:
	var p := oyuncu.global_position
	var q := PhysicsRayQueryParameters3D.create(p + Vector3(0, 0.9, 0), p + Vector3(0, -1.5, 0))
	q.exclude = [oyuncu.get_rid()]
	var r := get_world_3d().direct_space_state.intersect_ray(q)
	if r.is_empty(): return
	p.y = lerpf(p.y, (r.position as Vector3).y, minf(1.0, dt * 12.0))
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
	for m: Node3D in _uzaklasinca.keys():
		if faz == "oyun" and Vector2(oyuncu.global_position.x - m.global_position.x, oyuncu.global_position.z - m.global_position.z).length() > 1.3:
			_uzaklasinca.erase(m)
			_kapanacak[m] = T
	for m: Node3D in _kapanacak.keys():
		var t := T - float(_kapanacak[m])
		_kapi_ac(m, t, 1.0, 0.0)
		if t > 1.2: _kapanacak.erase(m)
	if _hol_lambalar.size() > HOL_TITREYEN:
		# holün ortasındaki ampul: çoğu zaman yanar, arada bir titreyip söner
		var l := _hol_lambalar[HOL_TITREYEN]
		var d := fmod(T, 9.0)
		l.light_energy = 0.75 if d < 7.6 or fmod(d * 7.3 + sin(T * 31.0), 1.0) > 0.45 else 0.05
	if _zaman.has("banyo_kapi"): _banyo_kapisi(T - float(_zaman["banyo_kapi"]) + 0.5)
	if _zaman.has("mutfak_kapi"):
		_kapi_ac(kapi_mutfak, T - float(_zaman["mutfak_kapi"]), 0.0, 1.1)
		_kapidan_cekil(kapi_mutfak, T - float(_zaman["mutfak_kapi"]))
	if _zaman.has("salon_kapi"):
		_kapi_ac(kapi_salon, T - float(_zaman["salon_kapi"]), 0.0, 1.1)
		_kapidan_cekil(kapi_salon, T - float(_zaman["salon_kapi"]))
	if _zaman.has("salon_kapa"): _kapi_ac(kapi_salon, T - float(_zaman["salon_kapa"]), 1.0, 0.0)
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


## Tuğla holü kurar: her dikdörtgenin zemini ve tavanı, birleşik şeklin dış kenarlarına duvar.
## Başka bir dikdörtgene açılan, önceki dikdörtgenle aynı olan ya da HOL_ACIK'taki kenar parçalarına duvar çekilmez.
func _hol_kur(duvar: Material, zemin: Material, tavan: Material) -> void:
	# holün kendi kopyaları: tahta mat, tuğlada parlama yok
	duvar = duvar.duplicate()
	zemin = zemin.duplicate()
	if duvar is StandardMaterial3D: (duvar as StandardMaterial3D).metallic_specular = 0.2
	if zemin is StandardMaterial3D:
		(zemin as StandardMaterial3D).metallic = 0.0
		(zemin as StandardMaterial3D).roughness = 0.75
	var k := 0.1
	var e := 0.01
	var kutular := []   # [merkez, ebat, malzeme, çarpışma]
	for r in HOL + HOL_ESIK:
		var o := Vector3((r[0] + r[2]) * 0.5, 0.0, (r[1] + r[3]) * 0.5)
		var en := Vector3(r[2] - r[0], 0.0, r[3] - r[1])
		kutular.append([o + Vector3(0, -0.025, 0), Vector3(en.x, 0.05, en.z), zemin, true])
		kutular.append([o + Vector3(0, HOL_TAVAN + 0.05, 0), Vector3(en.x, 0.1, en.z), tavan, false])
	for i in HOL.size():
		var r: Array = HOL[i]
		# [kenar, sabit, u0, u1, dışarı yönü]
		for kenar in [["-x", r[0], r[1], r[3]], ["+x", r[2], r[1], r[3]], ["-z", r[1], r[0], r[2]], ["+z", r[3], r[0], r[2]]]:
			var x_kenari: bool = kenar[0].ends_with("x")
			var dis := -1.0 if kenar[0].begins_with("-") else 1.0
			var c: float = kenar[1]
			var parcalar := [[float(kenar[2]), float(kenar[3])]]
			for j in HOL.size():
				if j == i: continue
				var q: Array = HOL[j]
				# kenarın hemen dışı öbür dikdörtgenin içindeyse oraya açıktır
				var dx: float = c + dis * e
				if x_kenari and dx > q[0] and dx < q[2]: parcalar = _aralik_cikar(parcalar, q[1], q[3])
				if not x_kenari and dx > q[1] and dx < q[3]: parcalar = _aralik_cikar(parcalar, q[0], q[2])
				# önceki dikdörtgenin aynı kenarı: duvar zaten orada
				if j < i:
					var qc: float = q[0 if kenar[0] == "-x" else 2 if kenar[0] == "+x" else 1 if kenar[0] == "-z" else 3]
					if absf(qc - c) < 0.001:
						parcalar = _aralik_cikar(parcalar, q[1], q[3]) if x_kenari else _aralik_cikar(parcalar, q[0], q[2])
			var kapi_u := INF
			for a in HOL_KAPILAR:
				if a[0] == kenar[0] and absf(float(a[1]) - c) < 0.001 and float(a[2]) > float(kenar[2]) and float(a[2]) < float(kenar[3]):
					kapi_u = a[2]
					parcalar = _aralik_cikar(parcalar, kapi_u - KAPI_EN * 0.5, kapi_u + KAPI_EN * 0.5)
					# kapının üstü
					var ust := KAPI_BOY + 0.04
					var orta_k := c + (-1.0 if kenar[0].begins_with("-") else 1.0) * k * 0.5
					var ebat := Vector3(k, HOL_TAVAN + 0.1 - ust, KAPI_EN) if x_kenari else Vector3(KAPI_EN, HOL_TAVAN + 0.1 - ust, k)
					var yer := Vector3(orta_k, (ust + HOL_TAVAN + 0.1) * 0.5, kapi_u) if x_kenari else Vector3(kapi_u, (ust + HOL_TAVAN + 0.1) * 0.5, orta_k)
					kutular.append([yer, ebat, duvar, false])
			for pr in parcalar:
				var u0: float = pr[0]
				var u1: float = pr[1]
				if u1 - u0 < 0.02: continue
				# dış köşede duvar kalınlığı kadar uzar (köşede delik kalmasın)
				var s0 := Vector2(c + dis * k * 0.5, u0 - k * 0.5)
				var s1 := Vector2(c + dis * k * 0.5, u1 + k * 0.5)
				# kapı boşluğunun kenarında uzamaz
				if not _holde(s0, x_kenari) and absf(u0 - (kapi_u + KAPI_EN * 0.5)) > 0.001: u0 -= k
				if not _holde(s1, x_kenari) and absf(u1 - (kapi_u - KAPI_EN * 0.5)) > 0.001: u1 += k
				var um := (u0 + u1) * 0.5
				var ue := u1 - u0
				var orta := c + dis * k * 0.5
				if x_kenari: kutular.append([Vector3(orta, HOL_TAVAN * 0.5, um), Vector3(k, HOL_TAVAN + 0.1, ue), duvar, true])
				else: kutular.append([Vector3(um, HOL_TAVAN * 0.5, orta), Vector3(ue, HOL_TAVAN + 0.1, k), duvar, true])
	for p in kutular:
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = p[1]
		bm.material = p[2]
		mi.mesh = bm
		mi.position = p[0]
		add_child(mi)
		if p[3]: mi.create_trimesh_collision()
	# loş, sarı ampuller; biri arada bir çakıp söner
	for i in HOL_LAMBALAR.size():
		var l := OmniLight3D.new()
		l.light_color = Color(1.0, 0.8, 0.58)
		l.light_energy = 0.75
		l.omni_range = 4.2
		l.omni_attenuation = 1.4
		l.shadow_enabled = i == 0 or i == HOL_TITREYEN
		l.position = HOL_LAMBALAR[i]
		add_child(l)
		_hol_lambalar.append(l)


## parcalar'dan [a, b] aralığını çıkarır.
func _aralik_cikar(parcalar: Array, a: float, b: float) -> Array:
	var sonuc := []
	for pr in parcalar:
		var u0: float = pr[0]
		var u1: float = pr[1]
		if b <= u0 or a >= u1:
			sonuc.append(pr)
			continue
		if a > u0: sonuc.append([u0, a])
		if b < u1: sonuc.append([b, u1])
	return sonuc


## Kenara göre (sabit, u) noktası holün içinde mi.
func _holde(nokta: Vector2, x_kenari: bool) -> bool:
	var x := nokta.x if x_kenari else nokta.y
	var z := nokta.y if x_kenari else nokta.x
	for r in HOL:
		if x > r[0] and x < r[2] and z > r[1] and z < r[3]: return true
	return false


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
	# evin uğultusu: rüyadan çıkınca başlar, hep alçaktan çalar
	ses_ambiyans = AudioStreamPlayer.new(); add_child(ses_ambiyans)
	ses_ambiyans.stream = _ses_bul("ev_ambiyans")
	ses_ambiyans.volume_db = -22.0
	# saate bakarken tik tak
	ses_saat_tik = AudioStreamPlayer.new(); add_child(ses_saat_tik)
	ses_saat_tik.stream = _ses_bul("saat_tik")
	ses_saat_tik.volume_db = -12.0


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
	elif ad in ["alarm", "titresim", "crt", "ev_ambiyans", "saat_tik"]:
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
		"fren":
			# lastik çığlığı: titreyen, alçalan tiz bir ses
			for i in int(hiz * 1.6):
				var t := float(i) / hiz
				var f := 2600.0 - t * 700.0 + sin(t * 90.0) * 120.0
				o.append((sin(TAU * f * t) * 0.35 + (randf() * 2.0 - 1.0) * 0.25) * smoothstep(0.0, 0.08, t) * (1.0 - smoothstep(1.3, 1.6, t)))
			return _wav(o, hiz)
		"carpma":
			var dusuk := 0.0
			for i in int(hiz * 1.4):
				var t := float(i) / hiz
				dusuk = lerpf(dusuk, randf() * 2.0 - 1.0, 0.25)
				o.append(clampf((sin(TAU * 55.0 * t) * 0.9 + dusuk * 1.2 + (randf() * 2.0 - 1.0) * 0.5 * exp(-t * 6.0)) * exp(-t * 3.5), -1.0, 1.0))
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
		"dis_fircalama":
			# fırçanın dişlerde kısa kısa sürtünmesi
			var yuksek := 0.0
			for i in int(hiz * 6.0):
				var t := float(i) / hiz
				var r := randf() * 2.0 - 1.0
				yuksek = r - yuksek * 0.6
				o.append(yuksek * 0.12 * (0.35 + 0.65 * absf(sin(PI * t * 3.2))) * smoothstep(0.0, 0.2, t) * (1.0 - smoothstep(5.6, 6.0, t)))
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
	Kagit.yapistir(self, fatura, Vector3(1.92, 0.62, -5.02), Vector2(0.15, 0.21), Vector3.DOWN, 0.35, 0.12)
	var zarf := Kagit.yazi_dokusu(self, Vector2i(560, 320), Color(0.82, 0.76, 0.62), [
		["T.C.", 18, koyu, 0],
		["BELEDİYE FEN İŞLERİ MÜDÜRLÜĞÜ", 18, koyu, 0],
		["", 30, koyu, 0],
		["Sn. SELİM", 24, koyu, 1],
		["KİŞİYE ÖZEL", 20, Color(0.6, 0.1, 0.08), 1],
	])
	Kagit.yapistir(self, zarf, Vector3(2.47, 0.62, -5.15), Vector2(0.23, 0.13), Vector3.DOWN, -0.2, 0.12)


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


# ---------------- tavan ampulleri ve tablolar ----------------
## alp'in gönderdiği LED ampul tavana takılır; odanın ışığı ampulün hemen altından çıkar ve ampul ışıkla birlikte parlar.
const AMPUL_MODELI := "res://modeller2/seliminevi/led_light_bulb_9w.glb"
const AMPUL_OLCEK := 0.032   # model 3,8 birim boyunda; gerçek ampul 12 cm
## [ampulün tavana değdiği nokta, ışığın adı ya da yeni ışık için boş, menzil, parlaklık]
const AMPULLER := [
	[Vector3(0.4, 3.88, 0.47), "", 7.0, 0.9],                 # yatak odası (model tavanı)
	[Vector3(0.82, 2.85, -6.25), "MutfakLamba", 7.5, 1.5],   # mutfak (_kabuk tavanı)
	[Vector3(7.45, 2.73, -1.905), "", 7.5, 1.0],                 # salon (_kabuk tavanı)
	[Vector3(5.94, 2.215, 4.59), "BanyoLamba", 0.0, 0.0],   # banyo: modelin tavan armatürünün altında, floresan gibi çakar
]
var _ampuller := []   # [ışık, parlayan malzeme, ilk parlaklık]
var _salon_ampul: OmniLight3D   # evden çıkarken salonun ışığıyla birlikte kapanır

func _ampuller_kur() -> void:
	if not ResourceLoader.exists(AMPUL_MODELI): return
	var paket := load(AMPUL_MODELI) as PackedScene
	var liste := AMPULLER.duplicate()
	for i in HOL_LAMBALAR.size():
		liste.append([Vector3(HOL_LAMBALAR[i].x, HOL_TAVAN, HOL_LAMBALAR[i].z), "hol%d" % i, 0.0, 0.0])
	for a in liste:
		var tavan: Vector3 = a[0]
		var m := paket.instantiate() as Node3D
		m.name = "Ampul"
		add_child(m)
		# vida yukarıda, cam aşağıda
		m.basis = Basis(Vector3.RIGHT, PI).scaled(Vector3.ONE * AMPUL_OLCEK)
		m.position = tavan - Vector3(0, 1.92 * AMPUL_OLCEK, 0)
		var cam: StandardMaterial3D = null
		for mi in m.find_children("*", "MeshInstance3D", true, false):
			(mi as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			for i in (mi as MeshInstance3D).mesh.get_surface_count():
				var mat := (mi as MeshInstance3D).get_active_material(i) as StandardMaterial3D
				if mat == null or mat.resource_name != "bulb": continue
				cam = mat.duplicate() as StandardMaterial3D
				cam.emission_enabled = true
				cam.emission = Color(1.0, 0.85, 0.6)
				(mi as MeshInstance3D).set_surface_override_material(i, cam)
		var ad: String = a[1]
		var l: OmniLight3D
		if ad.begins_with("hol"):
			l = _hol_lambalar[int(ad.substr(3))]
		elif ad != "":
			l = get_node("Isiklar/" + ad) as OmniLight3D
		else:
			l = OmniLight3D.new()
			l.light_color = Color(1.0, 0.82, 0.6)
			l.light_energy = a[3]
			l.omni_range = a[2]
			l.omni_attenuation = 1.2
			l.shadow_enabled = true
			l.name = "Ampul%d" % _ampuller.size()
			add_child(l)
			if tavan.distance_to(SALON) < 4.0: _salon_ampul = l
		if float(a[2]) > 0.0: l.omni_range = a[2]
		if float(a[3]) > 0.0: l.light_energy = a[3]
		# ışık ampulün camının içinden çıkar (camın kendisi gölge vermez)
		l.global_position = tavan - Vector3(0, 0.1, 0)
		_ampuller.append([l, cam, maxf(l.light_energy, 0.01)])

func _ampul_parla() -> void:
	for a in _ampuller:
		var l := a[0] as Light3D
		if a[1] == null or not is_instance_valid(l): continue
		var oran := l.light_energy / float(a[2]) if l.visible else 0.0
		(a[1] as StandardMaterial3D).emission_energy_multiplier = 4.0 * clampf(oran, 0.0, 1.5)

## alp'in gönderdiği tablo paketi: holün ve odaların boş duvarlarına asılır.
const TABLO_MODELI := "res://modeller2/seliminevi/free_medieval_paintings_pack.glb"
## [paketteki tablonun adı, duvardaki orta noktası, duvardan odaya bakan yön (yaw derece), yükseklik (m)]
const TABLOLAR := [
	["cuadro_3", Vector3(3.3, 1.6, -1.5), 90.0, 0.55],     # hol, mutfakla yatak odası kapısı arası
	["cuadro_14", Vector3(4.49, 1.6, -2.2), -90.0, 0.5],   # hol, salonun duvarı
	["cuadro_5", Vector3(6.4, 1.6, 0.95), 0.0, 0.55],      # hol, salon kapısının solu
	["cuadro_10", Vector3(8.6, 1.6, 2.22), 180.0, 0.5],    # hol, banyo ile dış kapı arası
	["cuadro_21", Vector3(8.05, 1.9, -4.765), 0.0, 0.65],    # salon
]

func _tablolar_kur() -> void:
	if not ResourceLoader.exists(TABLO_MODELI): return
	var paket := (load(TABLO_MODELI) as PackedScene).instantiate()
	add_child(paket)   # dünya dönüşümü okunabilsin diye bir an sahneye girer
	for t in TABLOLAR:
		var dugum := paket.find_child(t[0], true, false)
		if dugum == null: continue
		for mi in dugum.find_children("*", "MeshInstance3D", true, false):
			var kaynak := mi as MeshInstance3D
			var xf := kaynak.global_transform
			var kutu: AABB = xf * kaynak.get_aabb()
			var olcek: float = t[3] / kutu.size.y
			var tablo := MeshInstance3D.new()
			tablo.name = "Tablo"
			tablo.mesh = kaynak.mesh
			for i in kaynak.mesh.get_surface_count():
				tablo.set_surface_override_material(i, kaynak.get_active_material(i))
			add_child(tablo)
			# tablonun ortası dünyanın başlangıcına, arka yüzü duvara (yerel -z) gelir
			var ic := Transform3D(xf.basis, xf.origin - kutu.get_center() + Vector3(0, 0, kutu.size.z * 0.5))
			tablo.transform = Transform3D(Basis(Vector3.UP, deg_to_rad(t[2])).scaled(Vector3.ONE * olcek), t[1]) * ic
	paket.queue_free()


## Yemekten sonra antidepresan (alp): kutudan bir kapsül alır, ağzına atar, sudan bir yudum içer. t: yemeğin bitişinden beri.
const ILAC_SURE := 7.2
func _ilac_ic(t: float) -> void:
	if t < 0.0 or ilac_kutusu == null: return
	if t > 0.2 and not _eylem.has("i_uzan"):
		_eylem["i_uzan"] = true
		var ik := _dunya_kutusu(ilac_kutusu)
		eller.uzan("sag", ik.get_center() + Vector3(0, ik.size.y * 0.5 + 0.03, 0.03), 0.6)
		_ses_cal("dolap", -18.0)
	if t > 0.9 and not _eylem.has("i_al") and kapsul:
		_eylem["i_al"] = true
		kapsul.visible = true
		kapsul.global_position = eller.avuc("sag")
		eller.tut("sag", kapsul)
		eller.yumruk("sag", 0.7)
	if t > 1.4 and not _eylem.has("i_agiz"):
		_eylem["i_agiz"] = true
		eller.kamerada("sag", Vector3(0.03, -0.12, -0.18), 0.5)
	if t > 2.0 and not _eylem.has("i_yut"):
		_eylem["i_yut"] = true
		eller.tut("sag", null)
		if kapsul: kapsul.visible = false
		eller.birak("sag", 0.5)
	if su_sisesi == null: return
	if t > 2.6 and not _eylem.has("s_uzan"):
		_eylem["s_uzan"] = true
		var sk := _dunya_kutusu(su_sisesi)
		eller.uzan("sag", sk.get_center() + Vector3(0.04, 0.0, 0.03), 0.6)
	if t > 3.3 and not _eylem.has("s_al"):
		_eylem["s_al"] = true
		eller.tut("sag", su_sisesi)
		eller.yumruk("sag", 0.75)
	if t > 3.6 and not _eylem.has("s_agiz"):
		_eylem["s_agiz"] = true
		eller.kamerada("sag", Vector3(0.04, -0.1, -0.2), 0.6)
	# şişe ağza gelince kameraya doğru eğilir, içtikten sonra doğrulur
	if t > 3.3 and t < 6.2:
		var egim := smoothstep(4.1, 4.6, t) * (1.0 - smoothstep(5.3, 5.7, t)) * 1.1
		var sag_yon := kamera.global_basis.x
		su_sisesi.global_basis = Basis(sag_yon, egim) * _sise_xf.basis
	if t > 5.7 and not _eylem.has("s_geri"):
		_eylem["s_geri"] = true
		eller.uzan("sag", _sise_xf.origin + Vector3(0, 0.12, 0), 0.6)
	if t > 6.35 and not _eylem.has("s_birak"):
		_eylem["s_birak"] = true
		eller.tut("sag", null)
		su_sisesi.global_transform = _sise_xf
		eller.birak("sag", 0.6)


## Yerel kanalda gece hava durumu (2B ekran; kişi ya da telifli görüntü yok).
const PROGRAM_SEHIRLER := [["İSTANBUL", "9°", "Sağanak"], ["ANKARA", "4°", "Bulutlu"], ["İZMİR", "13°", "Yağmurlu"], ["BURSA", "8°", "Sağanak"], ["TRABZON", "7°", "Yağmurlu"], ["ANTALYA", "15°", "Parçalı bulutlu"]]
func _program_kur(yazi: Font) -> void:
	tv_program = Control.new()
	tv_program.size = Vector2(640, 480)
	tv_program.visible = false
	tv_vp.add_child(tv_program)
	tv_vp.move_child(tv_program, tv_ust.get_index() if tv_ust and tv_ust.get_parent() == tv_vp else tv_vp.get_child_count() - 1)
	var zemin := ColorRect.new()
	zemin.size = Vector2(640, 480)
	zemin.color = Color(0.05, 0.16, 0.36)
	tv_program.add_child(zemin)
	var bant := ColorRect.new()
	bant.size = Vector2(640, 62); bant.color = Color(0.92, 0.55, 0.08)
	tv_program.add_child(bant)
	var etiket := func(metin: String, boy: int, yer: Vector2, renk := Color(0.95, 0.95, 0.95), en := 600.0) -> Label:
		var l := Label.new()
		l.text = metin
		l.add_theme_font_override("font", yazi)
		l.add_theme_font_size_override("font_size", boy)
		l.add_theme_color_override("font_color", renk)
		l.position = yer; l.size = Vector2(en, boy + 8)
		tv_program.add_child(l)
		return l
	etiket.call("HAVA DURUMU", 34, Vector2(24, 12), Color(0.08, 0.08, 0.12))
	etiket.call("ŞEHİR TV", 22, Vector2(500, 18), Color(0.08, 0.08, 0.12), 130.0)
	etiket.call("Bu gece ve yarın", 22, Vector2(24, 76), Color(0.75, 0.85, 1.0))
	for i in PROGRAM_SEHIRLER.size():
		var c: Array = PROGRAM_SEHIRLER[i]
		var y := 116.0 + i * 46.0
		var satir := ColorRect.new()
		satir.position = Vector2(20, y - 4); satir.size = Vector2(600, 40)
		satir.color = Color(1, 1, 1, 0.06 if i % 2 == 0 else 0.0)
		tv_program.add_child(satir)
		etiket.call(c[0], 26, Vector2(32, y))
		etiket.call(c[1], 28, Vector2(330, y - 1), Color(1.0, 0.85, 0.35), 90.0)
		etiket.call(c[2], 22, Vector2(420, y + 3), Color(0.8, 0.88, 1.0), 200.0)
	var alt := ColorRect.new()
	alt.position = Vector2(0, 420); alt.size = Vector2(640, 60); alt.color = Color(0.02, 0.05, 0.12)
	tv_program.add_child(alt)
	_program_kayan = etiket.call("Gece boyunca kuvvetli sağanak bekleniyor · Sürücülerin dikkatli olması öneriliyor · Rögar kapaklarının açık kalmaması için belediye uyardı · Yarın sabah sıcaklıklar düşüyor ·", 22, Vector2(640, 436), Color(0.95, 0.95, 0.95), 2400.0)
	ses_program = AudioStreamPlayer.new()
	if ResourceLoader.exists("res://sesler/radyo.mp3"): ses_program.stream = load("res://sesler/radyo.mp3")
	ses_program.volume_db = -20.0
	add_child(ses_program)

func _program_oyna(dt: float, um: ShaderMaterial) -> void:
	tv_video.visible = false; tv_foto.visible = false; tv_cubuk.visible = false
	tv_oda_kamera.current = false
	tv_zemin.visible = true
	if _program_kayan: _program_kayan.position.x -= 70.0 * dt
	var acilis := smoothstep(0.0, 0.45, tv_t)
	um.set_shader_parameter("acilis", acilis)
	um.set_shader_parameter("kar", clampf(0.9 - (tv_t - 0.45) * 1.6, 0.05, 0.9) if tv_t > 0.45 else 0.9)
	um.set_shader_parameter("kar_tam", 0.0)
	um.set_shader_parameter("kesit", 0.0)
	# son saniyede görüntü bozulmaya başlar
	if tv_t > PROGRAM_SURE - 1.2:
		um.set_shader_parameter("kesit", 1.0)
		um.set_shader_parameter("kar", 0.05 + (tv_t - (PROGRAM_SURE - 1.2)) * 0.5)
	kar_hedef = 0.12
	tv_isigi.light_energy = 3.0 * 0.6 * (0.92 + randf() * 0.12) * acilis
	tv_isigi.light_color = Color(0.6, 0.72, 1.0)

