extends RefCounted
## Duvara ya da masaya yapışan kağıtlar (çizelge, fatura, zarf) ve ıslak ayak izleri.
## Bunlar 3D model değil: yüzeye yansıtılan düz dokulardır (Decal). Yazılar oyunun içinde çizilir.

## Kağıt dokusu: arka plan rengi üstüne satır satır yazı. satirlar: [[metin, boy, renk, hiza], ...]
## resim: kağıda iliştirilen fotoğraf (ör. vesikalık), resim_yer: piksel olarak yeri; boşsa sağ üst köşe.
static func yazi_dokusu(kok: Node, boyut: Vector2i, zemin: Color, satirlar: Array, resim := "", resim_yer := Rect2()) -> ImageTexture:
	var vp := SubViewport.new()
	vp.size = boyut
	vp.transparent_bg = zemin.a < 1.0
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	kok.add_child(vp)
	var arka := ColorRect.new(); arka.color = zemin; arka.size = Vector2(boyut)
	vp.add_child(arka)
	if resim != "" and ResourceLoader.exists(resim):
		var r := TextureRect.new()
		r.texture = load(resim)
		r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		var yer := resim_yer if resim_yer.size != Vector2.ZERO else Rect2(boyut.x - 150, 100, 120, 160)
		r.position = yer.position
		r.size = yer.size
		vp.add_child(r)
	var yazi := SystemFont.new()
	yazi.font_names = PackedStringArray(["Courier New", "Liberation Mono", "DejaVu Sans Mono", "monospace"])
	var el := SystemFont.new()
	el.font_names = PackedStringArray(["Comic Sans MS", "Segoe Print", "DejaVu Sans", "sans-serif"])
	var y := 18.0
	for s in satirlar:
		var l := Label.new()
		l.text = str(s[0])
		var boy: int = int(s[1])
		l.add_theme_font_override("font", el if s.size() > 4 and bool(s[4]) else yazi)
		l.add_theme_font_size_override("font_size", boy)
		l.add_theme_color_override("font_color", s[2])
		l.horizontal_alignment = int(s[3]) as HorizontalAlignment
		l.position = Vector2(20, y)
		l.size = Vector2(boyut.x - 40, boy * 1.3)
		vp.add_child(l)
		y += boy * 1.45
	# Decal'ler görüntü dokusunu (ViewportTexture) izleyemez: yazı bir kez çizilir, resme çevrilir.
	# Resim hazır olana kadar boş bir doku döner, sonra aynı dokunun içi doldurulur.
	var img := Image.create(boyut.x, boyut.y, false, Image.FORMAT_RGBA8)
	img.fill(zemin)
	var doku := ImageTexture.create_from_image(img)
	_doldur(vp, doku)
	return doku


static func _doldur(vp: SubViewport, doku: ImageTexture) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	if not is_instance_valid(vp): return
	var yeni := ImageTexture.create_from_image(vp.get_texture().get_image())
	vp.queue_free()
	# decal atlası değişikliği görsün diye dokuyu kullanan decal'lere yeni doku verilir
	for d in doku.get_meta("decaller", []):
		if is_instance_valid(d): (d as Decal).texture_albedo = yeni


## Yüzeye yapıştırılan kağıt. yon: kağıdın baktığı yüzeyin içine doğru (ör. duvar için duvara doğru).
static func yapistir(kok: Node3D, doku: Texture2D, yer: Vector3, boyut: Vector2, yon: Vector3, egim := 0.0, derinlik := 0.3) -> Decal:
	var d := Decal.new()
	d.size = Vector3(boyut.x, derinlik, boyut.y)
	d.cull_mask = 1
	kok.add_child(d)
	d.texture_albedo = doku
	var liste: Array = doku.get_meta("decaller", [])
	liste.append(d)
	doku.set_meta("decaller", liste)
	d.global_position = yer
	# Decal kendi -Y ekseni boyunca yansıtır
	var asagi := yon.normalized()
	var yukari := Vector3.UP if absf(asagi.y) < 0.9 else Vector3.FORWARD
	var x := yukari.cross(-asagi).normalized()
	var z := x.cross(-asagi).normalized()
	d.global_basis = Basis(x, -asagi, z).rotated(asagi, egim)
	return d


## Islak ayakkabı izi dokusu (bir kez üretilir).
static var _iz: ImageTexture
static func iz_dokusu() -> ImageTexture:
	if _iz: return _iz
	var w := 64; var h := 160
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for py in h:
		for px in w:
			var u := (px - w * 0.5) / (w * 0.5)
			var v := float(py) / h
			# taban ve topuk iki oval
			var on := pow(u / 0.95, 2.0) + pow((v - 0.32) / 0.3, 2.0)
			var topuk := pow(u / 0.8, 2.0) + pow((v - 0.8) / 0.17, 2.0)
			var a := 0.0
			if on < 1.0 or topuk < 1.0:
				# taban desenine benzeyen çizgiler, kenara doğru solar
				var cizgi := 0.65 + 0.35 * sin(v * 90.0)
				a = cizgi * (1.0 - minf(on, topuk) * 0.6) * (0.6 + 0.4 * randf())
			img.set_pixel(px, py, Color(0.05, 0.045, 0.04, clampf(a, 0.0, 1.0) * 0.55))
	_iz = ImageTexture.create_from_image(img)
	return _iz
