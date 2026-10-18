extends CanvasLayer
## Duraklatma menüsü ve ayarlar (her sahnede çalışır, project.godot'ta "Duraklat" adıyla otomatik yüklenir).
## Esc: oyunu durdurur, arkadaki görüntü bulanıklaşır. Devam et, ayarlar, baştan başla, ana menü, oyundan çık.
## Ayarlar user://ayarlar.cfg dosyasına kaydedilir: grafik (düşük/orta/yüksek/ultra), tam ekran,
## ses seviyeleri (ana, müzik, efekt, konuşma), fare hassasiyeti ve ters çevirme, altyazı, dil (TR/EN).

const ANA_MENU := "res://sahneler/baslangic.tscn"
const ILK_SAHNE := "res://sahneler/ev.tscn"
const DOSYA := "user://ayarlar.cfg"
const KAYIT := "user://kayit.cfg"
const Ceviri := preload("res://kod/ceviri.gd")
const KALITELER := ["DÜŞÜK", "ORTA", "YÜKSEK", "ULTRA"]
const DILLER := ["tr", "en"]

var ses := 0.9
var muzik := 0.8
var efekt := 1.0
var konusma := 1.0
var fare := 1.0
var ters_y := false
var kalite := 1          # 0 düşük, 1 orta, 2 yüksek, 3 ultra
var tam_ekran := true
var altyazi := true
var dil := "tr"

var acik := false
var _kok: Control
var _ana: VBoxContainer
var _ayar: Control
var _yazi: Font
var _onceki_fare := Input.MOUSE_MODE_CAPTURED
var _oynaticilar: Array[Node] = []
var _bus_sayac := 0.0
var _en: Translation
## Kayıttan devam edilince sahnenin başlayacağı nokta; sahne okuyup boşaltır.
var baslangic_noktasi := ""
## Kaçıncı gece: 1. gece kulübede bir şey olmaz, Selim eve dönüp yatar; 2. gece mazgal açılır.
var gece := 1
var _kayit_ikon: Control
var _kayit_ikon_t := 0.0
var _yukleme: Control
var _yukleme_cubuk: ColorRect
var _yukleme_yazi: Label
var _yuklenen := ""

signal ayarlar_degisti

func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ceviri_kur()
	_buslari_kur()
	_yukle()
	_uygula()
	_kur()
	_kok.visible = false
	_kayit_arayuzu_kur()
	get_tree().node_added.connect(_dugum_eklendi)
	# bu menüden önce yüklenmiş ses çalarlar da kanallara atansın
	for n in get_tree().root.find_children("*", "AudioStreamPlayer*", true, false):
		_oynaticilar.append(n)

## Ana menüdeyken Esc duraklatmaz.
func menude_mi() -> bool:
	var s := get_tree().current_scene
	return s == null or s.scene_file_path == ANA_MENU

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo and e.keycode == KEY_ESCAPE:
		if menude_mi() or yukleniyor_mu(): return
		get_viewport().set_input_as_handled()
		if acik: devam()
		else: duraklat()

func duraklat() -> void:
	acik = true
	_onceki_fare = Input.mouse_mode
	get_tree().paused = true
	_muzik_surdur()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_kok.visible = true
	_ana.visible = true; _ayar.visible = false
	(_ana.get_child(2) as Button).grab_focus()

func devam() -> void:
	acik = false
	_kok.visible = false
	get_tree().paused = false
	_menu_muzigi_dur()
	Input.mouse_mode = _onceki_fare if _onceki_fare != Input.MOUSE_MODE_VISIBLE else Input.MOUSE_MODE_CAPTURED
	_kaydet()

func _git(sahne: String) -> void:
	acik = false
	_kok.visible = false
	get_tree().paused = false
	_menu_muzigi_dur()
	_kaydet()
	get_tree().change_scene_to_file(sahne)


## Fare dikey yönü: ters çevirme açıksa -1.
func y_carpani() -> float:
	return -1.0 if ters_y else 1.0


# ---------------- ayarlar ----------------
func _yukle() -> void:
	var c := ConfigFile.new()
	if c.load(DOSYA) != OK:
		# ilk açılış: dizüstü bilgisayarların tümleşik ekran kartında (Intel Iris Xe gibi) düşük ayarla başlar
		var kart := RenderingServer.get_video_adapter_name().to_lower()
		if "intel" in kart or "llvmpipe" in kart: kalite = 0
		return
	ses = c.get_value("ayar", "ses", ses)
	muzik = c.get_value("ayar", "muzik", muzik)
	efekt = c.get_value("ayar", "efekt", efekt)
	konusma = c.get_value("ayar", "konusma", konusma)
	fare = c.get_value("ayar", "fare", fare)
	ters_y = c.get_value("ayar", "ters_y", ters_y)
	kalite = clampi(c.get_value("ayar", "kalite", kalite), 0, 3)
	tam_ekran = c.get_value("ayar", "tam_ekran", tam_ekran)
	altyazi = c.get_value("ayar", "altyazi", altyazi)
	dil = c.get_value("ayar", "dil", dil)

func _kaydet() -> void:
	var c := ConfigFile.new()
	for k in ["ses", "muzik", "efekt", "konusma", "fare", "ters_y", "kalite", "tam_ekran", "altyazi", "dil"]:
		c.set_value("ayar", k, get(k))
	c.save(DOSYA)

func _uygula() -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(ses, 0.0001)))
	for b in [["Muzik", muzik], ["Efekt", efekt], ["Konusma", konusma]]:
		var i := AudioServer.get_bus_index(b[0])
		if i >= 0: AudioServer.set_bus_volume_db(i, linear_to_db(maxf(float(b[1]), 0.0001)))
	# Türkçe asıl dildir; İngilizce çeviri yalnızca İngilizce seçiliyken etkin
	if dil == "en" and not TranslationServer.get_loaded_locales().has("en"): TranslationServer.add_translation(_en)
	elif dil != "en": TranslationServer.remove_translation(_en)
	TranslationServer.set_locale(dil)
	if DisplayServer.get_name() != "headless":
		var mod := DisplayServer.WINDOW_MODE_FULLSCREEN if tam_ekran else DisplayServer.WINDOW_MODE_WINDOWED
		if DisplayServer.window_get_mode() != mod: DisplayServer.window_set_mode(mod)
	var s := get_tree().current_scene if get_tree() else null
	if s: _kaliteyi_uygula(s)
	ayarlar_degisti.emit()


# ---------------- dil ----------------
func _ceviri_kur() -> void:
	_en = Translation.new()
	_en.locale = "en"
	for k: String in Ceviri.EN:
		_en.add_message(k, Ceviri.EN[k])


# ---------------- ses kanalları ----------------
## Müzik, efekt ve konuşma için ayrı kanallar. Sahnelerdeki ses çalarlar çaldıkları dosyaya göre kanala atanır.
func _buslari_kur() -> void:
	for ad in ["Muzik", "Efekt", "Konusma"]:
		if AudioServer.get_bus_index(ad) >= 0: continue
		AudioServer.add_bus()
		var i := AudioServer.bus_count - 1
		AudioServer.set_bus_name(i, ad)
		AudioServer.set_bus_send(i, "Master")

func _kanal(akis: AudioStream) -> String:
	if akis == null: return "Efekt"
	var yol := akis.resource_path.get_file().to_lower()
	if yol.begins_with("muzik") or yol.begins_with("radyo"): return "Muzik"
	if yol.begins_with("selim") or yol.begins_with("amir") or yol.begins_with("anlatici"): return "Konusma"
	return "Efekt"

func _process(dt: float) -> void:
	_kayit_guncelle(dt)
	_bus_sayac -= dt
	if _bus_sayac > 0.0: return
	_bus_sayac = 0.3
	var kalan: Array[Node] = []
	for n in _oynaticilar:
		if not is_instance_valid(n): continue
		kalan.append(n)
		var akis: AudioStream = n.get("stream")
		var hedef := _kanal(akis)
		if n.get("bus") != hedef: n.set("bus", hedef)
	_oynaticilar = kalan


# yeni sahne yüklenince grafik kalitesi ona da uygulanır, ses çalarlar kanallara atanır
func _dugum_eklendi(n: Node) -> void:
	if n is AudioStreamPlayer or n is AudioStreamPlayer3D:
		_oynaticilar.append(n)
	if n == get_tree().current_scene or n is WorldEnvironment:
		_kaliteyi_uygula.call_deferred(n)
	elif n is Light3D or n is GPUParticles3D or n is Camera3D:
		_dugum_kalitesi.call_deferred(n)

## Düşük ayarda (zayıf ekran kartları için) ikincil ışıkların gölgesi kapanır, yağmur damlası azalır.
func _dugum_kalitesi(n: Node) -> void:
	if not is_instance_valid(n): return
	if n is Light3D and not n is DirectionalLight3D:
		var l := n as Light3D
		if not l.has_meta("asil_golge"): l.set_meta("asil_golge", l.shadow_enabled)
		var onemli := l.name == "Fener" or l.name == "Ampul" or l.name == "TVIsigi"
		l.shadow_enabled = bool(l.get_meta("asil_golge")) and (kalite >= 1 or onemli)
		# uzaktaki sokak lambaları düşük ayarda daha erken söner: ekran kartı aynı anda daha az ışık hesaplar
		if l.distance_fade_enabled:
			if not l.has_meta("asil_solma"): l.set_meta("asil_solma", Vector3(l.distance_fade_begin, l.distance_fade_length, l.distance_fade_shadow))
			var a: Vector3 = l.get_meta("asil_solma")
			var k: float = [0.45, 0.75, 1.0, 1.0][kalite]
			l.distance_fade_begin = a.x * k; l.distance_fade_length = a.y * k; l.distance_fade_shadow = a.z * k
	elif n is DirectionalLight3D:
		var d := n as DirectionalLight3D
		if not d.has_meta("asil_mesafe"): d.set_meta("asil_mesafe", d.directional_shadow_max_distance)
		d.directional_shadow_max_distance = minf(d.get_meta("asil_mesafe"), [40.0, 70.0, 100.0, 100.0][kalite])
	elif n is Camera3D:
		# sis zaten uzağı örter; düşük ayarda kamera o kadar uzağı çizmez
		var c := n as Camera3D
		if not c.has_meta("asil_uzak"): c.set_meta("asil_uzak", c.far)
		c.far = minf(c.get_meta("asil_uzak"), [180.0, 260.0, 4000.0, 4000.0][kalite])
	elif n is GPUParticles3D:
		(n as GPUParticles3D).amount_ratio = [0.35, 0.6, 1.0, 1.0][kalite]

func _kaliteyi_uygula(kok: Node) -> void:
	if not is_instance_valid(kok): return
	var ortamlar := kok.find_children("*", "WorldEnvironment", true, false)
	if kok is WorldEnvironment: ortamlar.append(kok)
	for o in ortamlar:
		var env := (o as WorldEnvironment).environment
		if env == null: continue
		if not env.has_meta("asil_ssao"):
			env.set_meta("asil_ssao", env.ssao_enabled); env.set_meta("asil_ssr", env.ssr_enabled)
			env.set_meta("asil_hacim", env.volumetric_fog_enabled); env.set_meta("asil_glow", env.glow_enabled)
			env.set_meta("asil_ssil", env.ssil_enabled)
		env.ssao_enabled = env.get_meta("asil_ssao") and kalite >= 1
		env.ssr_enabled = env.get_meta("asil_ssr") and kalite >= 2
		env.volumetric_fog_enabled = env.get_meta("asil_hacim") and kalite >= 1
		env.glow_enabled = env.get_meta("asil_glow")
		env.ssil_enabled = env.get_meta("asil_ssil") or kalite >= 3
		# hacimli sis kapanınca yerine ucuz derinlik sisi gelir; gece havası kaybolmasın
		if not env.has_meta("asil_sis"): env.set_meta("asil_sis", env.fog_enabled)
		env.fog_enabled = env.get_meta("asil_sis") or (env.get_meta("asil_hacim") and kalite == 0)
		if kalite == 0 and env.get_meta("asil_hacim"):
			env.fog_density = maxf(env.fog_density, env.volumetric_fog_density * 0.6)
			env.fog_light_color = env.volumetric_fog_albedo * 0.12
	for n in kok.find_children("*", "Light3D", true, false) + kok.find_children("*", "GPUParticles3D", true, false) + kok.find_children("*", "Camera3D", true, false):
		_dugum_kalitesi(n)
	var vp := get_viewport()
	vp.msaa_3d = [Viewport.MSAA_DISABLED, Viewport.MSAA_2X, Viewport.MSAA_4X, Viewport.MSAA_8X][kalite]
	vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR if kalite <= 1 else Viewport.SCALING_3D_MODE_BILINEAR
	vp.scaling_3d_scale = [0.77, 0.85, 1.0, 1.0][kalite]
	vp.mesh_lod_threshold = [1.5, 1.2, 1.0, 0.0][kalite]   # 4.0 modelleri kabalaştırıyordu
	var golge: int = [2048, 4096, 8192, 8192][kalite]
	RenderingServer.directional_shadow_atlas_set_size(golge, true)
	vp.positional_shadow_atlas_size = golge
	var yumusak := [RenderingServer.SHADOW_QUALITY_SOFT_VERY_LOW, RenderingServer.SHADOW_QUALITY_SOFT_LOW, RenderingServer.SHADOW_QUALITY_SOFT_MEDIUM, RenderingServer.SHADOW_QUALITY_SOFT_HIGH][kalite] as RenderingServer.ShadowQuality
	RenderingServer.directional_soft_shadow_filter_set_quality(yumusak)
	RenderingServer.positional_soft_shadow_filter_set_quality(yumusak)


# ---------------- görünüm ----------------
func _kur() -> void:
	var f := SystemFont.new()
	f.font_names = PackedStringArray(["Courier New", "Courier", "Liberation Mono", "DejaVu Sans Mono", "monospace"])
	_yazi = f
	_kok = Control.new(); _kok.set_anchors_preset(Control.PRESET_FULL_RECT); add_child(_kok)
	# arkadaki oyun görüntüsü bulanıklaşır ve kararır
	var bulanik := ColorRect.new(); bulanik.set_anchors_preset(Control.PRESET_FULL_RECT)
	bulanik.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sm := ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = """shader_type canvas_item;
uniform sampler2D ekran : hint_screen_texture, filter_linear_mipmap;
void fragment() {
	vec2 p = SCREEN_PIXEL_SIZE * 6.0;
	vec3 c = vec3(0.0);
	for (int x = -2; x <= 2; x++) {
		for (int y = -2; y <= 2; y++) {
			c += textureLod(ekran, SCREEN_UV + vec2(float(x), float(y)) * p, 3.0).rgb;
		}
	}
	c /= 25.0;
	COLOR = vec4(c * 0.45, 1.0);
}
"""
	sm.shader = sh
	bulanik.material = sm
	_kok.add_child(bulanik)
	var kenar := ColorRect.new(); kenar.color = Color(0.02, 0.02, 0.025, 0.85)
	kenar.anchor_bottom = 1.0; kenar.offset_right = 560
	_kok.add_child(kenar)
	_ana = VBoxContainer.new()
	_ana.position = Vector2(90, 220); _ana.custom_minimum_size = Vector2(420, 0)
	_ana.add_theme_constant_override("separation", 14)
	_kok.add_child(_ana)
	_ana.add_child(_etiket("MAZGAL", 76, Color(0.88, 0.86, 0.8)))
	_ana.add_child(_etiket("●  DURAKLATILDI", 22, Color(0.85, 0.2, 0.18)))
	_ana.add_child(_dugme("DEVAM ET", devam))
	_ana.add_child(_dugme("AYARLAR", func() -> void: _ana.visible = false; _ayar.visible = true))
	_ana.add_child(_dugme("BAŞTAN BAŞLA", func() -> void: yeni_oyun(); _git(ILK_SAHNE)))
	_ana.add_child(_dugme("ANA MENÜ", func() -> void: _git(ANA_MENU)))
	_ana.add_child(_dugme("OYUNDAN ÇIK", func() -> void: _kaydet(); get_tree().quit()))
	_ana.add_child(_etiket("ESC  DEVAM ET", 16, Color(0.5, 0.5, 0.46)))
	_ayar = ayar_paneli(func() -> void: _ayar.visible = false; _ana.visible = true)
	_ayar.position = Vector2(90, 120)
	_kok.add_child(_ayar)

## Ana menü de aynı ayar panelini kullanır.
func ayar_paneli(geri: Callable) -> Control:
	var kap := ScrollContainer.new()
	kap.custom_minimum_size = Vector2(560, 860)
	kap.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var v := VBoxContainer.new()
	v.custom_minimum_size = Vector2(520, 0)
	v.add_theme_constant_override("separation", 10)
	kap.add_child(v)
	v.add_child(_etiket("AYARLAR", 40, Color(0.88, 0.86, 0.8)))
	v.add_child(_baslik("GÖRÜNTÜ"))
	v.add_child(_secim("GRAFİK KALİTESİ", KALITELER, kalite, func(i: int) -> void: kalite = i; _uygula()))
	v.add_child(_onay("TAM EKRAN", tam_ekran, func(b: bool) -> void: tam_ekran = b; _uygula()))
	v.add_child(_baslik("SES"))
	v.add_child(_kaydirac("ANA SES", ses, 0.0, 1.0, func(d: float) -> void: ses = d; _uygula()))
	v.add_child(_kaydirac("MÜZİK", muzik, 0.0, 1.0, func(d: float) -> void: muzik = d; _uygula()))
	v.add_child(_kaydirac("EFEKTLER", efekt, 0.0, 1.0, func(d: float) -> void: efekt = d; _uygula()))
	v.add_child(_kaydirac("KONUŞMALAR", konusma, 0.0, 1.0, func(d: float) -> void: konusma = d; _uygula()))
	v.add_child(_baslik("KONTROL VE DİL"))
	v.add_child(_kaydirac("FARE HASSASİYETİ", fare, 0.3, 2.5, func(d: float) -> void: fare = d; _uygula()))
	v.add_child(_onay("FAREYİ TERS ÇEVİR", ters_y, func(b: bool) -> void: ters_y = b; _uygula()))
	v.add_child(_onay("ALTYAZILAR", altyazi, func(b: bool) -> void: altyazi = b; _uygula()))
	v.add_child(_secim("DİL", ["TÜRKÇE", "ENGLISH"], DILLER.find(dil), func(i: int) -> void: dil = DILLER[i]; _uygula()))
	v.add_child(_dugme("GERİ", func() -> void: _kaydet(); geri.call()))
	kap.visible = false
	return kap

func _etiket(metin: String, boy: int, renk: Color) -> Label:
	var l := Label.new(); l.text = metin
	l.add_theme_font_override("font", _yazi); l.add_theme_font_size_override("font_size", boy)
	l.add_theme_color_override("font_color", renk)
	return l

func _baslik(metin: String) -> Label:
	var l := _etiket(metin, 18, Color(0.85, 0.2, 0.18))
	l.custom_minimum_size.y = 34
	l.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	return l

func _dugme(metin: String, ne: Callable) -> Button:
	var b := Button.new(); b.text = metin; b.flat = true
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_font_override("font", _yazi); b.add_theme_font_size_override("font_size", 30)
	b.add_theme_color_override("font_color", Color(0.72, 0.7, 0.64))
	b.add_theme_color_override("font_hover_color", Color(1, 0.96, 0.85))
	b.add_theme_color_override("font_focus_color", Color(1, 0.96, 0.85))
	b.pressed.connect(ne)
	return b

func _kaydirac(ad: String, deger: float, en_az: float, en_cok: float, ne: Callable) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_child(_etiket(ad, 20, Color(0.6, 0.58, 0.52)))
	var s := HSlider.new(); s.min_value = en_az; s.max_value = en_cok; s.step = 0.01; s.value = deger
	s.custom_minimum_size = Vector2(440, 26)
	s.value_changed.connect(ne)
	v.add_child(s)
	return v

func _onay(ad: String, deger: bool, ne: Callable) -> CheckButton:
	var t := CheckButton.new(); t.text = ad; t.button_pressed = deger
	t.add_theme_font_override("font", _yazi); t.add_theme_font_size_override("font_size", 20)
	t.add_theme_color_override("font_color", Color(0.72, 0.7, 0.64))
	t.toggled.connect(ne)
	return t

## Sola-sağa seçim: "< ORTA >". Tıklayınca sıradakine geçer.
func _secim(ad: String, secenekler: Array, deger: int, ne: Callable) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_child(_etiket(ad, 20, Color(0.6, 0.58, 0.52)))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	var yazi := _etiket(secenekler[maxi(deger, 0)], 24, Color(0.92, 0.9, 0.84))
	yazi.custom_minimum_size.x = 220
	yazi.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var sec := [maxi(deger, 0)]
	var degis := func(yon: int) -> void:
		sec[0] = posmod(int(sec[0]) + yon, secenekler.size())
		yazi.text = secenekler[sec[0]]
		ne.call(int(sec[0]))
	var sol := _dugme("<", func() -> void: degis.call(-1))
	var sag := _dugme(">", func() -> void: degis.call(1))
	h.add_child(sol); h.add_child(yazi); h.add_child(sag)
	v.add_child(h)
	return v


# ---------------- kayıt ve yükleme ----------------
## Oyun kendiliğinden kaydeder: hangi sahne ve sahnenin hangi noktası. Sağ altta kayıt simgesi döner.
func kayit_noktasi(sahne: String, nokta: String) -> void:
	var c := ConfigFile.new()
	c.set_value("kayit", "sahne", sahne)
	c.set_value("kayit", "nokta", nokta)
	c.set_value("kayit", "gece", gece)
	c.set_value("kayit", "zaman", Time.get_datetime_string_from_system())
	c.save(KAYIT)
	_kayit_ikon_t = 2.6

func kayit_var() -> bool:
	var c := ConfigFile.new()
	return c.load(KAYIT) == OK and ResourceLoader.exists(str(c.get_value("kayit", "sahne", "")))

## Ana menüdeki "Devam Et": kayıt yükleme ekranıyla son noktadan açar.
func kayittan_devam() -> void:
	var c := ConfigFile.new()
	if c.load(KAYIT) != OK: return
	baslangic_noktasi = str(c.get_value("kayit", "nokta", ""))
	gece = int(c.get_value("kayit", "gece", 1))
	yukle(str(c.get_value("kayit", "sahne", ILK_SAHNE)), "KAYIT YÜKLENİYOR...")

func yeni_oyun() -> void:
	baslangic_noktasi = ""
	gece = 1
	DirAccess.remove_absolute(ProjectSettings.globalize_path(KAYIT))

## Sahneyi arkada yükler; bu sırada siyah ekranda yazı ve ince bir çubuk görünür.
func yukle(sahne: String, yazi := "YÜKLENİYOR...") -> void:
	_yuklenen = sahne
	_yukleme_yazi.text = yazi
	_yukleme_cubuk.size.x = 0.0
	_yukleme.visible = true
	get_tree().paused = false
	ResourceLoader.load_threaded_request(sahne)

func yukleniyor_mu() -> bool:
	return _yuklenen != ""

func _kayit_guncelle(dt: float) -> void:
	_kayit_ikon_t = maxf(0.0, _kayit_ikon_t - dt)
	_kayit_ikon.visible = _kayit_ikon_t > 0.0
	if _kayit_ikon.visible:
		_kayit_ikon.modulate.a = minf(1.0, _kayit_ikon_t) * (0.6 + 0.4 * sin(Time.get_ticks_msec() / 160.0))
		(_kayit_ikon.get_child(0) as Control).rotation += dt * 5.0
	if _yuklenen == "": return
	var ilerleme := []
	var d := ResourceLoader.load_threaded_get_status(_yuklenen, ilerleme)
	if ilerleme.size() > 0: _yukleme_cubuk.size.x = lerpf(_yukleme_cubuk.size.x, 520.0 * float(ilerleme[0]), 0.2)
	_yukleme_yazi.modulate.a = 0.55 + 0.45 * sin(Time.get_ticks_msec() / 300.0)
	if d == ResourceLoader.THREAD_LOAD_LOADED:
		var sahne := ResourceLoader.load_threaded_get(_yuklenen) as PackedScene
		_yuklenen = ""
		get_tree().change_scene_to_packed(sahne)
		# yeni sahne ilk karesini çizene kadar perde kalır
		await get_tree().process_frame
		await get_tree().process_frame
		_yukleme.visible = false
	elif d == ResourceLoader.THREAD_LOAD_FAILED or d == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		push_error("Sahne yüklenemedi: " + _yuklenen)
		_yuklenen = ""
		_yukleme.visible = false

func _kayit_arayuzu_kur() -> void:
	_kayit_ikon = Control.new()
	_kayit_ikon.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_kayit_ikon.offset_left = -300; _kayit_ikon.offset_top = -90
	add_child(_kayit_ikon)
	var halka := Panel.new()
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0, 0, 0, 0)
	st.border_color = Color(0.9, 0.88, 0.8)
	st.set_border_width_all(3)
	st.border_width_top = 0
	st.set_corner_radius_all(14)
	halka.add_theme_stylebox_override("panel", st)
	halka.size = Vector2(28, 28)
	halka.pivot_offset = Vector2(14, 14)
	_kayit_ikon.add_child(halka)
	var l := _etiket("KAYDEDİLİYOR", 18, Color(0.9, 0.88, 0.8))
	l.position = Vector2(42, 2)
	_kayit_ikon.add_child(l)
	_kayit_ikon.visible = false
	_yukleme = Control.new()
	_yukleme.set_anchors_preset(Control.PRESET_FULL_RECT)
	_yukleme.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_yukleme)
	var siyah := ColorRect.new(); siyah.color = Color.BLACK; siyah.set_anchors_preset(Control.PRESET_FULL_RECT)
	_yukleme.add_child(siyah)
	_yukleme_yazi = _etiket("", 26, Color(0.88, 0.86, 0.8))
	_yukleme_yazi.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_yukleme_yazi.offset_left = 120; _yukleme_yazi.offset_top = -170
	_yukleme.add_child(_yukleme_yazi)
	var alt := ColorRect.new(); alt.color = Color(0.2, 0.2, 0.2)
	alt.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	alt.offset_left = 120; alt.offset_top = -120; alt.offset_right = 640; alt.offset_bottom = -116
	_yukleme.add_child(alt)
	_yukleme_cubuk = ColorRect.new(); _yukleme_cubuk.color = Color(0.85, 0.2, 0.18)
	_yukleme_cubuk.position = Vector2.ZERO; _yukleme_cubuk.size = Vector2(0, 4)
	alt.add_child(_yukleme_cubuk)
	_yukleme.visible = false


# ---------------------------------------------------------------- duraklatınca müzik
## Oyun durunca çalan müzik (radyo, arka plan müziği) kesilmez; hiç müzik çalmıyorsa menü müziği başlar.
const MENU_MUZIGI := "res://sesler/muzik_2.mp3"
var _menu_muzik: AudioStreamPlayer

func _muzik_mu(p: Node) -> bool:
	var akis: AudioStream = p.get("stream")
	if akis == null: return false
	var yol := akis.resource_path.get_file()
	return yol.begins_with("muzik_") or yol.begins_with("radyo")

func _muzik_surdur() -> void:
	var caliyor := false
	var sahne := get_tree().current_scene
	if sahne:
		for p in sahne.find_children("*", "AudioStreamPlayer", true, false) + sahne.find_children("*", "AudioStreamPlayer3D", true, false):
			if _muzik_mu(p):
				p.process_mode = Node.PROCESS_MODE_ALWAYS
				if p.get("playing") and float(p.get("volume_db")) > -60.0: caliyor = true
	if caliyor or not ResourceLoader.exists(MENU_MUZIGI): return
	if _menu_muzik == null:
		_menu_muzik = AudioStreamPlayer.new()
		_menu_muzik.process_mode = Node.PROCESS_MODE_ALWAYS
		_menu_muzik.stream = load(MENU_MUZIGI)
		add_child(_menu_muzik)
	_menu_muzik.volume_db = -16.0
	_menu_muzik.play()

func _menu_muzigi_dur() -> void:
	if _menu_muzik and _menu_muzik.playing: _menu_muzik.stop()
