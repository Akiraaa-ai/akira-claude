extends CanvasLayer
## Yaka kamerası görüntüsü: balık gözü, gren, köşe kararması, hafif sallantı, ara sıra VHS bozulması,
## yanıp sönen REC, akan tarih ve saat damgası, pil göstergesi. Selim kamerayı takınca açılır.
##   ac(baslangic_saniye)   kamerayı açar (saat damgası o saniyeden akar, gece yarısından itibaren)
##   bozul(guc, sure)       kısa VHS bozulması


var acik := false
var _saniye := 0.0
var _pil := 0.86
var _rect: ColorRect
var _mat: ShaderMaterial
var _rec: Label
var _damga: Label
var _birim: Label
var _pil_kutu: Control
var _pil_dolgu: ColorRect
var _bozulma := 0.0
var _bozulma_sure := 0.0
var _sonraki_bozulma := 6.0
var _acilis := 0.0
var _t := 0.0


func _ready() -> void:
	layer = 8
	_rect = ColorRect.new()
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mat = ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = """shader_type canvas_item;
uniform sampler2D ekran : hint_screen_texture, filter_linear_mipmap;
uniform float zaman = 0.0;
uniform float bozulma = 0.0;
uniform float acilis = 1.0;
float h(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
void fragment() {
	vec2 uv = SCREEN_UV;
	// göğüse takılı kameranın sallantısı
	uv += vec2(sin(zaman * 1.3) * 0.0016 + sin(zaman * 3.1) * 0.0007, sin(zaman * 0.9) * 0.0018);
	// balık gözü
	vec2 m = uv - 0.5;
	float r2 = dot(m * vec2(1.6, 1.0), m * vec2(1.6, 1.0));
	uv = 0.5 + m * (1.0 + 0.16 * r2) / 1.06;
	// VHS: satır kayması ve renk ayrışması
	float satir = floor(uv.y * 180.0);
	float bant = step(0.985 - bozulma * 0.4, h(vec2(floor(zaman * 12.0), floor(uv.y * 24.0))));
	uv.x += (h(vec2(satir, floor(zaman * 30.0))) - 0.5) * 0.03 * bant * (0.3 + bozulma);
	float ayr = 0.0015 + bozulma * 0.012;
	vec3 c;
	c.r = textureLod(ekran, uv + vec2(ayr, 0.0), 0.0).r;
	c.g = textureLod(ekran, uv, 0.0).g;
	c.b = textureLod(ekran, uv - vec2(ayr, 0.0), 0.0).b;
	// gren ve tarama çizgileri
	float n = h(uv * vec2(640.0, 360.0) + fract(zaman * 7.3) * 113.0);
	c += (n - 0.5) * (0.07 + bozulma * 0.25);
	c *= 0.94 + 0.06 * sin(uv.y * 720.0);
	// soğuk, hafif yeşilimsi renk ve kontrast
	float g = dot(c, vec3(0.299, 0.587, 0.114));
	c = mix(vec3(g), c, 0.75) * vec3(0.95, 1.0, 0.97);
	c = (c - 0.5) * 1.12 + 0.5;
	// köşe kararması, balık gözünün dışı siyah
	float v = length(m * vec2(1.25, 1.0));
	c *= smoothstep(0.86, 0.3, v) * 1.08;
	c *= step(abs(uv.x - 0.5), 0.5) * step(abs(uv.y - 0.5), 0.5);
	// açılışta görüntü beyaz bir çizgiden açılır
	float ac = step(abs(SCREEN_UV.y - 0.5), max(acilis * 0.5, 0.002));
	c = mix(vec3(0.0), c, ac) + vec3(0.6) * (1.0 - smoothstep(0.0, 0.25, acilis)) * ac;
	COLOR = vec4(clamp(c, 0.0, 1.0), 1.0);
}
"""
	_mat.shader = sh
	_rect.material = _mat
	add_child(_rect)
	var yazi := SystemFont.new()
	yazi.font_names = PackedStringArray(["Courier New", "Courier", "Liberation Mono", "DejaVu Sans Mono", "monospace"])
	yazi.font_weight = 700
	_rec = _etiket(yazi, "●  REC", 34, Color(0.95, 0.18, 0.15))
	_rec.position = Vector2(90, 70)
	_birim = _etiket(yazi, "FEN İŞLERİ · BİRİM 07 · SELİM", 22, Color(0.92, 0.92, 0.86))
	_birim.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_birim.offset_left = 90; _birim.offset_top = -130
	_damga = _etiket(yazi, "", 30, Color(0.95, 0.95, 0.9))
	_damga.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_damga.offset_left = 90; _damga.offset_top = -95
	# pil: dış çerçeve, uç ve dolgu
	_pil_kutu = Control.new()
	_pil_kutu.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_pil_kutu.offset_left = -190; _pil_kutu.offset_top = 78
	add_child(_pil_kutu)
	var cerceve := Panel.new()
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0, 0, 0, 0)
	st.border_color = Color(0.95, 0.95, 0.9)
	st.set_border_width_all(3)
	cerceve.add_theme_stylebox_override("panel", st)
	cerceve.size = Vector2(70, 30)
	_pil_kutu.add_child(cerceve)
	var uc := ColorRect.new(); uc.color = Color(0.95, 0.95, 0.9); uc.position = Vector2(70, 9); uc.size = Vector2(6, 12)
	_pil_kutu.add_child(uc)
	_pil_dolgu = ColorRect.new(); _pil_dolgu.color = Color(0.95, 0.95, 0.9); _pil_dolgu.position = Vector2(6, 6); _pil_dolgu.size = Vector2(58, 18)
	_pil_kutu.add_child(_pil_dolgu)
	_gorunur(false)


func _etiket(f: Font, metin: String, boy: int, renk: Color) -> Label:
	var l := Label.new()
	l.text = metin
	l.add_theme_font_override("font", f)
	l.add_theme_font_size_override("font_size", boy)
	l.add_theme_color_override("font_color", renk)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	l.add_theme_constant_override("shadow_offset_x", 2)
	l.add_theme_constant_override("shadow_offset_y", 2)
	add_child(l)
	return l


func _gorunur(g: bool) -> void:
	_rect.visible = g
	_rec.visible = g
	_damga.visible = g
	_birim.visible = g
	_pil_kutu.visible = g


func ac(baslangic_saniye: float) -> void:
	acik = true
	_saniye = baslangic_saniye
	_acilis = 0.0
	_gorunur(true)
	bozul(0.8, 0.5)


func kapat() -> void:
	acik = false
	_gorunur(false)


func bozul(guc: float, sure: float) -> void:
	_bozulma = maxf(_bozulma, guc)
	_bozulma_sure = maxf(_bozulma_sure, sure)


## Kayıttaki saati ileri sarar (bekleme sahnesinde zaman akar).
func saat_ilerlet(saniye: float) -> void:
	_saniye += saniye


func _process(dt: float) -> void:
	if not acik: return
	_t += dt
	_saniye += dt
	_acilis = minf(1.0, _acilis + dt * 2.5)
	_pil = maxf(0.08, _pil - dt * 0.0004)
	# ara sıra kendiliğinden kısa bozulma
	_sonraki_bozulma -= dt
	if _sonraki_bozulma <= 0.0:
		_sonraki_bozulma = randf_range(7.0, 18.0)
		bozul(randf_range(0.25, 0.6), randf_range(0.12, 0.35))
	if _bozulma_sure > 0.0: _bozulma_sure -= dt
	else: _bozulma = move_toward(_bozulma, 0.0, dt * 3.0)
	_mat.set_shader_parameter("zaman", _t)
	_mat.set_shader_parameter("bozulma", _bozulma)
	_mat.set_shader_parameter("acilis", _acilis)
	_rec.modulate.a = 1.0 if fmod(_t, 1.0) < 0.6 else 0.0
	var s := int(_saniye) % 86400
	var gun := 14 + int(_saniye) / 86400
	_damga.text = "%02d.10.2026   %02d:%02d:%02d" % [gun, s / 3600, (s / 60) % 60, s % 60]
	_pil_dolgu.size.x = 58.0 * _pil
	_pil_dolgu.color = Color(0.95, 0.25, 0.2) if _pil < 0.2 else Color(0.95, 0.95, 0.9)
