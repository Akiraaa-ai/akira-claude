extends CanvasLayer
## Duraklatma menüsü ve ayarlar (her sahnede çalışır, project.godot'ta "Duraklat" adıyla otomatik yüklenir).
## Esc: oyunu durdurur. Devam et, ayarlar, baştan başla, ana menü, oyundan çık.
## Ayarlar user://ayarlar.cfg dosyasına kaydedilir: ses, fare hassasiyeti, grafik kalitesi, tam ekran.

const ANA_MENU := "res://sahneler/baslangic.tscn"
const ILK_SAHNE := "res://sahneler/ev.tscn"
const DOSYA := "user://ayarlar.cfg"

var ses := 0.9
var fare := 1.0
var kalite := 1          # 0 düşük, 1 orta, 2 yüksek
var tam_ekran := true

var acik := false
var _kok: Control
var _ana: VBoxContainer
var _ayar: VBoxContainer
var _yazi: Font
var _onceki_fare := Input.MOUSE_MODE_CAPTURED

signal ayarlar_degisti

func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	_yukle()
	_uygula()
	_kur()
	_kok.visible = false
	get_tree().node_added.connect(_dugum_eklendi)

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


# ---------------- ayarlar ----------------
func _yukle() -> void:
	var c := ConfigFile.new()
	if c.load(DOSYA) != OK: return
	ses = c.get_value("ayar", "ses", ses)
	fare = c.get_value("ayar", "fare", fare)
	kalite = c.get_value("ayar", "kalite", kalite)
	tam_ekran = c.get_value("ayar", "tam_ekran", tam_ekran)

func _kaydet() -> void:
	var c := ConfigFile.new()
	c.set_value("ayar", "ses", ses); c.set_value("ayar", "fare", fare)
	c.set_value("ayar", "kalite", kalite); c.set_value("ayar", "tam_ekran", tam_ekran)
	c.save(DOSYA)

func _uygula() -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(ses, 0.0001)))
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if tam_ekran else DisplayServer.WINDOW_MODE_WINDOWED)
	var s := get_tree().current_scene if get_tree() else null
	if s: _kaliteyi_uygula(s)
	ayarlar_degisti.emit()

# yeni sahne yüklenince grafik kalitesi ona da uygulanır
func _dugum_eklendi(n: Node) -> void:
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
		env.ssao_enabled = env.get_meta("asil_ssao") and kalite >= 1
		env.ssr_enabled = env.get_meta("asil_ssr") and kalite >= 2
		env.volumetric_fog_enabled = env.get_meta("asil_hacim") and kalite >= 1
		env.glow_enabled = env.get_meta("asil_glow")
	var vp := get_viewport()
	vp.msaa_3d = [Viewport.MSAA_DISABLED, Viewport.MSAA_2X, Viewport.MSAA_4X][kalite]
	vp.scaling_3d_scale = [0.75, 1.0, 1.0][kalite]
	RenderingServer.directional_shadow_atlas_set_size([2048, 4096, 8192][kalite], true)
	vp.positional_shadow_atlas_size = [2048, 4096, 8192][kalite]


# ---------------- görünüm ----------------
func _kur() -> void:
	var f := SystemFont.new()
	f.font_names = PackedStringArray(["Courier New", "Courier", "Liberation Mono", "DejaVu Sans Mono", "monospace"])
	_yazi = f
	_kok = Control.new(); _kok.set_anchors_preset(Control.PRESET_FULL_RECT); add_child(_kok)
	var perde := ColorRect.new(); perde.color = Color(0, 0, 0, 0.72); perde.set_anchors_preset(Control.PRESET_FULL_RECT)
	_kok.add_child(perde)
	var kenar := ColorRect.new(); kenar.color = Color(0.02, 0.02, 0.025, 0.92)
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
	_ayar.position = Vector2(90, 220)
	_kok.add_child(_ayar)

## Ana menü de aynı ayar panelini kullanır.
func ayar_paneli(geri: Callable) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.custom_minimum_size = Vector2(440, 0)
	v.add_theme_constant_override("separation", 12)
	v.add_child(_etiket("AYARLAR", 40, Color(0.88, 0.86, 0.8)))
	v.add_child(_kaydirac("SES", ses, 0.0, 1.0, func(d: float) -> void: ses = d; _uygula()))
	v.add_child(_kaydirac("FARE HASSASİYETİ", fare, 0.3, 2.5, func(d: float) -> void: fare = d; _uygula()))
	var k := OptionButton.new()
	for ad in ["GRAFİK: DÜŞÜK", "GRAFİK: ORTA", "GRAFİK: YÜKSEK"]: k.add_item(ad)
	k.selected = kalite
	k.add_theme_font_override("font", _yazi); k.add_theme_font_size_override("font_size", 22)
	k.item_selected.connect(func(i: int) -> void: kalite = i; _uygula())
	v.add_child(k)
	var t := CheckButton.new(); t.text = "TAM EKRAN"; t.button_pressed = tam_ekran
	t.add_theme_font_override("font", _yazi); t.add_theme_font_size_override("font_size", 22)
	t.toggled.connect(func(b: bool) -> void: tam_ekran = b; _uygula())
	v.add_child(t)
	v.add_child(_dugme("GERİ", func() -> void: _kaydet(); geri.call()))
	v.visible = false
	return v

func _etiket(metin: String, boy: int, renk: Color) -> Label:
	var l := Label.new(); l.text = metin
	l.add_theme_font_override("font", _yazi); l.add_theme_font_size_override("font_size", boy)
	l.add_theme_color_override("font_color", renk)
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
	s.custom_minimum_size = Vector2(400, 28)
	s.value_changed.connect(ne)
	v.add_child(s)
	return v
