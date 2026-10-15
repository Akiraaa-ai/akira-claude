extends Node3D
## Şehir modelindeki sokak lambalarına sarı sodyum ışık verir. Işık lambanın başının içinden çıkar.
## Konumlar test/lamba_bul2.gd, lamba_bul3.gd ile şehir modelinden bulundu:
## KOLLU: direkten 2.8 m uzanan kolun ucundaki başın alt yüzü. FENER: direğin tepesindeki fenerin içi.
const KOLLU := [
	Vector3(-42.98, 7.76, 1.77), Vector3(-26.24, 7.76, 1.77), Vector3(-73.99, 7.76, -86.23), Vector3(-86.03, 7.76, -86.23),
	Vector3(-98.07, 7.76, -86.23), Vector3(-26.27, 7.76, 60.41), Vector3(-43.01, 7.76, 60.41), Vector3(-108.32, 7.76, -15.27),
	Vector3(-108.32, 7.76, -25.39), Vector3(-108.32, 7.76, -35.52), Vector3(-108.32, 7.76, -45.64), Vector3(-108.32, 7.76, -55.76),
	Vector3(-108.32, 7.76, -65.89), Vector3(-108.32, 7.76, -76.01), Vector3(-63.77, 7.76, -15.24), Vector3(-63.77, 7.76, -38.04),
	Vector3(-63.77, 7.76, -49.43), Vector3(-63.77, 7.76, -60.83), Vector3(-63.77, 7.76, -72.23), Vector3(-53.23, 7.76, 25.96),
	Vector3(-16.02, 7.76, 12.02), Vector3(-16.02, 7.76, 24.74), Vector3(-16.02, 7.76, 37.46), Vector3(-16.02, 7.76, 50.19),
	Vector3(-94.33, 7.76, -4.98), Vector3(-84.17, 7.76, -4.98), Vector3(-74.00, 7.76, -4.98), Vector3(-53.27, 7.76, 15.75),
	Vector3(-53.27, 7.76, 36.20),
]
const FENER := [
	Vector3(-102.00, 8.50, 15.70), Vector3(-102.00, 8.50, 26.00), Vector3(-102.00, 8.50, 36.20), Vector3(-102.00, 8.50, 46.40),
	Vector3(-94.30, 8.50, 4.40), Vector3(-94.30, 8.50, 54.00), Vector3(-84.20, 8.50, 4.40), Vector3(-84.20, 8.50, 54.00),
	Vector3(-74.00, 8.50, 4.40), Vector3(-74.00, 8.50, 54.00), Vector3(-66.40, 8.50, 15.80), Vector3(-66.40, 8.50, 26.00),
	Vector3(-66.40, 8.50, 36.20), Vector3(-66.40, 8.50, 46.40), Vector3(-50.60, 8.50, -72.30), Vector3(-50.60, 8.50, -60.90),
	Vector3(-50.60, 8.50, -49.50), Vector3(-50.60, 8.50, -38.10), Vector3(-50.60, 8.50, -26.70), Vector3(-50.60, 8.50, -15.30),
	Vector3(-43.00, 8.50, -3.90), Vector3(-41.50, 8.50, -83.60), Vector3(-31.10, 8.50, -3.90), Vector3(-29.50, 8.50, -49.40),
	Vector3(-27.90, 8.50, -38.00), Vector3(-26.30, 8.50, -26.50), Vector3(-24.60, 8.50, -15.10), Vector3(-19.70, 8.50, -65.40),
	Vector3(-18.10, 8.50, -54.60), Vector3(-16.60, 8.50, -43.80), Vector3(-14.70, 8.50, -83.60), Vector3(-13.80, 8.60, -22.20),
	Vector3(-12.00, 8.50, -11.50), Vector3(-6.60, 8.50, 15.70), Vector3(-6.60, 8.50, 26.00), Vector3(-6.60, 8.50, 36.20),
	Vector3(-6.60, 8.50, 46.40), Vector3(-3.90, 8.50, -83.60), Vector3(-3.20, 8.50, -3.90), Vector3(1.00, 8.50, 4.40),
	Vector3(1.00, 8.50, 54.00), Vector3(6.90, 8.50, -83.60), Vector3(7.20, 8.50, -3.90), Vector3(14.00, 8.50, 54.00),
	Vector3(17.70, 8.50, -3.90), Vector3(17.80, 8.50, -83.60), Vector3(17.80, 8.50, 4.40), Vector3(25.40, 8.50, -76.00),
	Vector3(25.40, 8.50, -65.20), Vector3(25.40, 8.50, -54.50), Vector3(25.40, 8.50, -43.70), Vector3(25.40, 8.50, -33.00),
	Vector3(25.40, 8.50, -22.20), Vector3(25.40, 8.50, -11.50), Vector3(25.40, 8.50, 12.00), Vector3(25.40, 8.50, 23.50),
	Vector3(25.40, 8.50, 35.00), Vector3(25.40, 8.50, 46.40),
]

func _ready() -> void:
	var parilti := _parilti_malzemesi()
	for p in KOLLU: _lamba(p + Vector3(0, -0.12, 0), parilti, 0.5)
	for p in FENER: _lamba(p + Vector3(0, -0.25, 0), parilti, 0.65)

func _lamba(bas: Vector3, parilti: Material, boy: float) -> void:
	var l := SpotLight3D.new()
	l.position = bas
	l.rotation_degrees.x = -90.0
	l.light_color = Color(1.0, 0.68, 0.32)
	l.light_energy = 14.0
	l.spot_range = 18.0
	l.spot_angle = 62.0
	l.spot_attenuation = 0.9
	l.shadow_enabled = true
	l.distance_fade_enabled = true
	l.distance_fade_begin = 55.0
	l.distance_fade_length = 15.0
	l.distance_fade_shadow = 28.0
	add_child(l)
	# başın kendisini ve direği hafifçe aydınlatan ışık
	var h := OmniLight3D.new()
	h.position = bas + Vector3(0, -0.15, 0)
	h.light_color = Color(1.0, 0.7, 0.38)
	h.light_energy = 0.7
	h.omni_range = 4.5
	h.distance_fade_enabled = true
	h.distance_fade_begin = 55.0
	h.distance_fade_length = 15.0
	add_child(h)
	l.set_meta("hale", h)
	# ampulün parıltısı (ışık efekti, model değil): kameraya dönük yumuşak bir ışık lekesi
	var q := QuadMesh.new(); q.size = Vector2(boy, boy); q.material = parilti
	var g := MeshInstance3D.new(); g.mesh = q
	g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	g.position = bas
	add_child(g)
	l.set_meta("parilti", g)

func _parilti_malzemesi() -> StandardMaterial3D:
	var grad := Gradient.new()
	grad.set_color(0, Color(1, 0.85, 0.6, 1)); grad.set_color(1, Color(1, 0.6, 0.25, 0))
	grad.add_point(0.25, Color(1, 0.75, 0.45, 0.8))
	var d := GradientTexture2D.new(); d.gradient = grad; d.width = 64; d.height = 64
	d.fill = GradientTexture2D.FILL_RADIAL; d.fill_from = Vector2(0.5, 0.5); d.fill_to = Vector2(0.5, 0.0)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.albedo_texture = d
	m.albedo_color = Color(1, 1, 1, 0.9)
	m.disable_receive_shadows = true
	return m
