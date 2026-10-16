extends Node
## Oyunun açılışı: kulaklık uyarısı, arşiv kaydı yazısı, REC, jenerik ve MAZGAL logosu (geçilemez),
## ardından ana menü: arkada Selim'in gece karanlık yatak odası (şehir görünmez), dışarıda yağmur, radyo çalar.
## Yeni oyun ev.tscn ile başlar.

const ILK_SAHNE := "res://sahneler/ev.tscn"
const YATAK_ODASI := "res://modeller2/seliminevi/interior_8_bedroom.glb"
const ACILIS_SURESI := 21.0

const YAPIMCILAR := """[center][font_size=46]MAZGAL[/font_size]

[color=#8a8368]FİKİR, HİKÂYE VE YÖNETİM[/color]
alp

[color=#8a8368]SESLER[/color]
Selim ve anlatıcı: alp
Müzikler ve radyo şarkısı: alp
Yağmur: liecio (Pixabay)

[color=#8a8368]3D MODELLER (SKETCHFAB)[/color]
Yatak odası ve salon: dasy444
Banyo "Mildly Depressing Bathroom": Relvean (CC BY 4.0)
Mutfak: WeSVa
Kapı: Sam
Akıllı telefon: assetfactory
Tüplü TV: SketchyBot
TV sehpası: Graham Rust
Duvar saati: Reinaw13
Sigara paketi: Mark Peters (logosu kaldırıldı)
Araba: solid3DDD
Masa telefonu: Peter Gatchev
Tuşlu telefon: lemateis
El feneri: plazma019
Pil: trashbinkr
Şehir: (kaynak eklenecek)
Bekçi kulübesi: (kaynak eklenecek)

[color=#8a8368]MOTOR[/color]
Godot Engine (MIT lisansı)

[color=#8a8368]BAĞIMSIZ BİR YAPIM · 2026[/color][/center]"""

var T := 0.0
var durum := "acilis"
var _yazi: Font
var _kok: Control
var _kartlar := {}
var _bas: Label
var _menu: Control
var _yan: VBoxContainer
var _panel: Control
var _yapimcilar: RichTextLabel
var _kontroller: Label
var _ayar: Control
var _siyah: ColorRect
var _radyo: AudioStreamPlayer
var _yagmur_ses: AudioStreamPlayer
var _muzik: AudioStreamPlayer
const ACILIS_MUZIGI := "res://sesler/muzik_1.mp3"
var _tik: AudioStreamPlayer
var _sokak: Node3D
var _kamera: Camera3D

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var f := SystemFont.new()
	f.font_names = PackedStringArray(["Courier New", "Courier", "Liberation Mono", "DejaVu Sans Mono", "monospace"])
	_yazi = f
	_sesler_kur()
	_arayuz_kur()
	_sokak_kur.call_deferred()

func _sesler_kur() -> void:
	_yagmur_ses = AudioStreamPlayer.new(); add_child(_yagmur_ses)
	if ResourceLoader.exists("res://sesler/yagmur.mp3"):
		var y: AudioStream = load("res://sesler/yagmur.mp3")
		if y is AudioStreamMP3: (y as AudioStreamMP3).loop = true
		# açılışta yağmur duyulmaz; ana menü gelince yavaşça başlar
		_yagmur_ses.stream = y; _yagmur_ses.volume_db = -60.0
	# açılış jeneriğinin müziği (alp'in)
	_muzik = AudioStreamPlayer.new(); add_child(_muzik)
	if ResourceLoader.exists(ACILIS_MUZIGI):
		var m: AudioStream = load(ACILIS_MUZIGI)
		if m is AudioStreamMP3: (m as AudioStreamMP3).loop = true
		_muzik.stream = m; _muzik.volume_db = -8.0; _muzik.play()
	_radyo = AudioStreamPlayer.new(); add_child(_radyo)
	if ResourceLoader.exists("res://sesler/radyo.mp3"):
		var r: AudioStream = load("res://sesler/radyo.mp3")
		if r is AudioStreamMP3: (r as AudioStreamMP3).loop = true
		_radyo.stream = r; _radyo.volume_db = -60.0
	_tik = AudioStreamPlayer.new(); add_child(_tik)
	var hiz := 22050
	var veri := PackedByteArray(); veri.resize(int(hiz * 0.03) * 2)
	for i in int(hiz * 0.03):
		var t := float(i) / hiz
		veri.encode_s16(i * 2, int(clampf((sin(TAU * 2400.0 * t) * 0.5 + randf_range(-0.5, 0.5)) * exp(-t * 260.0), -1.0, 1.0) * 26000.0))
	var w := AudioStreamWAV.new(); w.format = AudioStreamWAV.FORMAT_16_BITS; w.mix_rate = hiz; w.data = veri
	_tik.stream = w; _tik.volume_db = -14.0

# menünün arkasında Selim'in gece yatak odası: pencereden soğuk ay ışığı, başucu lambası; kamera yavaşça süzülür
var _ampul: OmniLight3D
var _ampul_guc := 0.25
var _titreme := 0.0

func _sokak_kur() -> void:
	_sokak = Node3D.new()
	add_child(_sokak)
	move_child(_sokak, 0)
	_sokak.add_child((load(YATAK_ODASI) as PackedScene).instantiate())
	var ortam := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.01, 0.014, 0.03)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.3, 0.36, 0.55)
	env.ambient_light_energy = 0.09
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.glow_enabled = true
	env.glow_intensity = 0.4
	ortam.environment = env
	_sokak.add_child(ortam)
	# pencereden giren ay ışığı
	var ay := DirectionalLight3D.new()
	ay.light_color = Color(0.55, 0.65, 1.0)
	ay.light_energy = 0.45
	ay.shadow_enabled = true
	ay.rotation_degrees = Vector3(-22.0, -115.0, 0.0)
	_sokak.add_child(ay)
	# başucunda loş, arada titreyen bir lamba
	_ampul = OmniLight3D.new()
	_ampul.light_color = Color(1.0, 0.7, 0.42)
	_ampul.light_energy = _ampul_guc
	_ampul.omni_range = 3.5
	_ampul.shadow_enabled = true
	_sokak.add_child(_ampul)
	_ampul.position = Vector3(-1.7, 1.55, 0.74)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_kamera = Camera3D.new(); _kamera.fov = 62.0; _kamera.near = 0.03; _kamera.far = 60.0
	_sokak.add_child(_kamera)
	_kamera.current = true

func _process(dt: float) -> void:
	T += dt
	if _kamera:
		# kapının yanından boş yatağa bakan, çok yavaş süzülen kamera
		var yer := Vector3(2.5 + sin(T * 0.05) * 0.25, 1.62 + sin(T * 0.4) * 0.012, 1.4 + sin(T * 0.037) * 0.35)
		_kamera.global_position = yer
		_kamera.look_at(Vector3(-1.4, 0.8 + sin(T * 0.06) * 0.08, 0.0 + sin(T * 0.045) * 0.4))
	# ampul arada bir titrer
	if _ampul:
		_titreme -= dt
		if _titreme < -randf_range(4.0, 9.0): _titreme = randf_range(0.2, 0.6)
		_ampul.light_energy = _ampul_guc * (randf_range(0.15, 0.9) if _titreme > 0.0 else 1.0)
	if durum == "acilis": _acilis()
	elif durum == "menu":
		_radyo.volume_db = move_toward(_radyo.volume_db, -12.0, dt * 12.0)
		_yagmur_ses.volume_db = move_toward(_yagmur_ses.volume_db, -14.0, dt * 10.0)
		if _muzik.playing:
			_muzik.volume_db = move_toward(_muzik.volume_db, -60.0, dt * 20.0)
			if _muzik.volume_db <= -59.0: _muzik.stop()
		_siyah.color.a = move_toward(_siyah.color.a, 0.0, dt * 0.5)

func _input(e: InputEvent) -> void:
	if durum == "bekle" and ((e is InputEventKey and e.pressed) or (e is InputEventMouseButton and e.pressed)):
		get_viewport().set_input_as_handled()
		_menuyu_ac()

func _menuyu_ac() -> void:
	durum = "menu"
	_bas.visible = false
	for k in _kartlar.values(): (k as Control).visible = false
	_menu.visible = true
	if not _radyo.playing: _radyo.play()
	if not _yagmur_ses.playing and _yagmur_ses.stream: _yagmur_ses.play()
	(_yan.get_child(2) as Button).grab_focus()


# ---------------- açılış (geçilemez) ----------------
var _yazilan := {}
func _acilis() -> void:
	_kart("uyari", 0.5, 4.6)
	_kart("arsiv", 5.2, 10.0)
	_daktilo("arsiv", 5.6, 0.035)
	_kart("rec", 10.6, 13.4)
	_kart("jenerik", 14.0, 16.8)
	_kart("logo", 17.4, 999.0)
	if T >= ACILIS_SURESI:
		durum = "bekle"
		_bas.visible = true
	_siyah.color.a = 1.0
	if T > 17.4: _siyah.color.a = lerpf(1.0, 0.55, clampf((T - 17.4) / 3.0, 0.0, 1.0))

func _kart(ad: String, bas: float, bit: float) -> void:
	var k: Control = _kartlar[ad]
	var a := clampf((T - bas) / 0.8, 0.0, 1.0) * clampf((bit - T) / 0.8, 0.0, 1.0)
	k.visible = a > 0.0
	k.modulate.a = a

func _daktilo(ad: String, bas: float, hiz: float) -> void:
	for l in (_kartlar[ad] as Control).find_children("*", "Label", true, false):
		var lb := l as Label
		if not lb.has_meta("yaz"): continue
		var n := int((T - bas) / hiz)
		var uzun := tr(lb.text).length()
		bas += uzun * hiz + 0.4
		var once: int = _yazilan.get(lb, -1)
		lb.visible_characters = clampi(n, 0, uzun)
		if lb.visible_characters != once:
			_yazilan[lb] = lb.visible_characters
			if lb.visible_characters > 0 and lb.visible_characters < uzun: _tik.play()


# ---------------- arayüz ----------------
func _arayuz_kur() -> void:
	var cl := CanvasLayer.new(); cl.layer = 5; add_child(cl)
	_kok = Control.new(); _kok.set_anchors_preset(Control.PRESET_FULL_RECT); cl.add_child(_kok)
	_siyah = ColorRect.new(); _siyah.color = Color.BLACK; _siyah.set_anchors_preset(Control.PRESET_FULL_RECT)
	_siyah.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_kok.add_child(_siyah)
	_kartlar["uyari"] = _orta([["KULAKLIK ÖNERİLİR", 48, Color(0.88, 0.86, 0.8), false],
		["Bu oyun karanlık sahneler, titreyen ışıklar ve rahatsız edici sesler içerir.", 20, Color(0.54, 0.51, 0.41), false],
		["En iyi deneyim için ışıkları kapatın.", 20, Color(0.54, 0.51, 0.41), false]])
	_kartlar["arsiv"] = _orta([["FEN İŞLERİ MÜDÜRLÜĞÜ · ARŞİV", 22, Color(0.54, 0.51, 0.41), false],
		["Aşağıdaki görüntüler bir görevlinin yaka kamerasından", 30, Color(0.85, 0.83, 0.77), true],
		["kurtarılmıştır. Kayıt eksik ve hasarlıdır.", 30, Color(0.85, 0.83, 0.77), true],
		["KAYIT 1 / 4 · SELİM", 26, Color(0.85, 0.2, 0.18), true]])
	_kartlar["rec"] = _orta([["●  REC   14.10.2026   03:17:44", 44, Color(0.9, 0.22, 0.2), false],
		["BODYCAM · FEN İŞLERİ · BİRİM 07", 20, Color(0.54, 0.51, 0.41), false]])
	_kartlar["jenerik"] = _orta([["alp", 40, Color(0.88, 0.86, 0.8), false], ["sunar", 22, Color(0.54, 0.51, 0.41), false]])
	_kartlar["logo"] = _orta([["MAZGAL", 150, Color(0.88, 0.86, 0.8), false], ["bir bodycam kaydı", 22, Color(0.54, 0.51, 0.41), false],
		["BAĞIMSIZ BİR YAPIM · 2026", 18, Color(0.42, 0.4, 0.34), false]])
	for k in _kartlar.values(): (k as Control).visible = false
	_bas = _etiket("[ HERHANGİ BİR TUŞA BAS ]", 22, Color(0.75, 0.73, 0.66))
	_bas.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_bas.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_bas.offset_left = -400; _bas.offset_right = 400; _bas.offset_top = -140; _bas.offset_bottom = -100
	_bas.visible = false
	_kok.add_child(_bas)
	_menu_kur()

func _orta(satirlar: Array) -> Control:
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 14)
	for s in satirlar:
		var l := _etiket(s[0], s[1], s[2])
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if s[3]: l.set_meta("yaz", true); l.visible_characters = 0
		v.add_child(l)
	_kok.add_child(v)
	return v

func _menu_kur() -> void:
	_menu = Control.new(); _menu.set_anchors_preset(Control.PRESET_FULL_RECT); _menu.visible = false
	_kok.add_child(_menu)
	var golge := ColorRect.new(); golge.color = Color(0.01, 0.01, 0.015, 0.82)
	golge.anchor_bottom = 1.0; golge.offset_right = 620
	_menu.add_child(golge)
	var rec := _etiket("●  REC", 22, Color(0.9, 0.22, 0.2))
	rec.set_anchors_preset(Control.PRESET_TOP_RIGHT); rec.offset_left = -170; rec.offset_top = 40
	_menu.add_child(rec)
	_yan = VBoxContainer.new(); _yan.position = Vector2(100, 200)
	_yan.add_theme_constant_override("separation", 16)
	_menu.add_child(_yan)
	_yan.add_child(_etiket("MAZGAL", 96, Color(0.88, 0.86, 0.8)))
	_yan.add_child(_etiket("●  KAYIT 14.10.2026 · 00:00:00", 18, Color(0.6, 0.3, 0.26)))
	var d0 := get_node_or_null("/root/Duraklat")
	if d0 and d0.kayit_var():
		_yan.add_child(_dugme("DEVAM ET", func() -> void: _devam_et()))
	_yan.add_child(_dugme("YENİ OYUN", func() -> void: _yeni_oyun()))
	_yan.add_child(_dugme("AYARLAR", func() -> void: _goster("ayar")))
	_yan.add_child(_dugme("KONTROLLER", func() -> void: _goster("kontrol")))
	_yan.add_child(_dugme("YAPIMCILAR", func() -> void: _goster("yapimci")))
	_yan.add_child(_dugme("ÇIKIŞ", func() -> void: get_tree().quit()))
	var alt := _etiket("v0.9 · ERKEN ERİŞİM          KULAKLIK ÖNERİLİR", 16, Color(0.42, 0.4, 0.34))
	alt.set_anchors_preset(Control.PRESET_BOTTOM_LEFT); alt.offset_left = 100; alt.offset_top = -60
	_menu.add_child(alt)
	_panel = Control.new(); _panel.position = Vector2(760, 160); _panel.size = Vector2(1000, 800)
	_menu.add_child(_panel)
	_yapimcilar = RichTextLabel.new(); _yapimcilar.bbcode_enabled = true; _yapimcilar.text = YAPIMCILAR
	_yapimcilar.add_theme_font_override("normal_font", _yazi); _yapimcilar.add_theme_font_size_override("normal_font_size", 22)
	_yapimcilar.add_theme_color_override("default_color", Color(0.85, 0.83, 0.77))
	_yapimcilar.size = Vector2(900, 780); _yapimcilar.visible = false
	_panel.add_child(_yapimcilar)
	_kontroller = _etiket("KONTROLLER\n\nW A S D      yürü\nSHIFT        koş\nCTRL         eğil\nF            fener\nE            etkileşim\nQ            telefonu bırak\nTEKERLEK     telefonda kaydır\nESC          duraklat\n\nARABADA\nW            gaz\nS            fren / geri\nA D          direksiyon\nFARE         etrafa bak", 24, Color(0.85, 0.83, 0.77))
	_kontroller.visible = false
	_panel.add_child(_kontroller)
	var d := get_node_or_null("/root/Duraklat")
	if d:
		_ayar = d.ayar_paneli(func() -> void: _ayar.visible = false)
		_panel.add_child(_ayar)

func _goster(ne: String) -> void:
	_yapimcilar.visible = ne == "yapimci"
	_kontroller.visible = ne == "kontrol"
	if _ayar: _ayar.visible = ne == "ayar"
	if ne == "yapimci": _yapimcilar.scroll_to_line(0)

func _yeni_oyun() -> void:
	durum = "gidis"
	var tw := create_tween()
	tw.tween_property(_siyah, "color:a", 1.0, 1.2)
	tw.parallel().tween_property(_radyo, "volume_db", -60.0, 1.2)
	tw.parallel().tween_property(_yagmur_ses, "volume_db", -60.0, 1.2)
	tw.tween_callback(func() -> void:
		var d := get_node_or_null("/root/Duraklat")
		if d:
			d.yeni_oyun()
			d.yukle(ILK_SAHNE)
		else:
			get_tree().change_scene_to_file(ILK_SAHNE))

func _devam_et() -> void:
	durum = "gidis"
	var tw := create_tween()
	tw.tween_property(_siyah, "color:a", 1.0, 1.0)
	tw.parallel().tween_property(_radyo, "volume_db", -60.0, 1.0)
	tw.parallel().tween_property(_yagmur_ses, "volume_db", -60.0, 1.0)
	tw.tween_callback(func() -> void: get_node("/root/Duraklat").kayittan_devam())

func _etiket(metin: String, boy: int, renk: Color) -> Label:
	var l := Label.new(); l.text = metin
	l.add_theme_font_override("font", _yazi); l.add_theme_font_size_override("font_size", boy)
	l.add_theme_color_override("font_color", renk)
	return l

func _dugme(metin: String, ne: Callable) -> Button:
	var b := Button.new(); b.text = metin; b.flat = true
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_font_override("font", _yazi); b.add_theme_font_size_override("font_size", 34)
	b.add_theme_color_override("font_color", Color(0.7, 0.68, 0.62))
	b.add_theme_color_override("font_hover_color", Color(1, 0.96, 0.85))
	b.add_theme_color_override("font_focus_color", Color(1, 0.96, 0.85))
	b.mouse_entered.connect(func() -> void: _tik.play())
	b.pressed.connect(ne)
	return b
