extends CanvasLayer
## Duraklatma menüsü ve ayarlar (her sahnede çalışır, project.godot'ta "Duraklat" adıyla otomatik yüklenir).
## Esc: oyunu durdurur, arkadaki görüntü bulanıklaşır. Devam et, ayarlar, baştan başla, ana menü, oyundan çık.
## Ayarlar user://ayarlar.cfg dosyasına kaydedilir: grafik (düşük/orta/yüksek/ultra), tam ekran,
## ses seviyeleri (ana, müzik, efekt, konuşma), fare hassasiyeti ve ters çevirme, altyazı, dil (TR/EN).

const ANA_MENU := "res://sahneler/baslangic.tscn"
const ILK_SAHNE := "res://sahneler/ev.tscn"
const DOSYA := "user://ayarlar.cfg"
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
		if menude_mi(): return
		get_viewport().set_input_as_handled()
		if acik: devam()
		else: duraklat()

func duraklat() -> void:
	acik = true
	_onceki_fare = Input.mouse_mode
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_kok.visible = true
	_ana.visible = true; _ayar.visible = false
	(_ana.get_child(2) as Button).grab_focus()

func devam() -> void:
	acik = false
	_kok.visible = false
	get_tree().paused = false
	Input.mouse_mode = _onceki_fare if _onceki_fare != Input.MOUSE_MODE_VISIBLE else Input.MOUSE_MODE_CAPTURED
	_kaydet()

func _git(sahne: String) -> void:
	acik = false
	_kok.visible = false
	get_tree().paused = false
	_kaydet()
	get_tree().change_scene_to_file(sahne)


## Fare dikey yönü: ters çevirme açıksa -1.
func y_carpani() -> float:
	return -1.0 if ters_y else 1.0


# ---------------- ayarlar ----------------
func _yukle() -> void:
	var c := ConfigFile.new()
	if c.load(DOSYA) != OK: return
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
	var vp := get_viewport()
	vp.msaa_3d = [Viewport.MSAA_DISABLED, Viewport.MSAA_2X, Viewport.MSAA_4X, Viewport.MSAA_8X][kalite]
	vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR if kalite <= 1 else Viewport.SCALING_3D_MODE_BILINEAR
	vp.scaling_3d_scale = [0.67, 0.85, 1.0, 1.0][kalite]
	vp.mesh_lod_threshold = [4.0, 2.0, 1.0, 0.0][kalite]
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
	_ana.add_child(_dugme("BAŞTAN BAŞLA", func() -> void: _git(ILK_SAHNE)))
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
