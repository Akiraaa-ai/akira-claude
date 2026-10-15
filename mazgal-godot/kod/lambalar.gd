extends Node3D
## Şehir modelindeki sokak lambalarının başlarına sarı sodyum ışık ve parlayan ampul koyar.
## Konumlar test/lamba_bul.gd ile şehir modelinden bulundu (lamba başlarının alt noktası).
const LAMBALAR := [
	Vector3(-107.4, 7.8, -76.0), Vector3(-107.4, 7.8, -65.9), Vector3(-107.4, 7.8, -55.8), Vector3(-107.4, 7.8, -45.6),
	Vector3(-107.4, 7.8, -35.5), Vector3(-107.4, 7.8, -25.4), Vector3(-107.4, 7.8, -15.3), Vector3(-105.9, 9.5, -81.9),
	Vector3(-102.0, 8.5, 15.7), Vector3(-102.0, 8.5, 26.0), Vector3(-102.0, 8.5, 36.2), Vector3(-102.0, 8.5, 46.4),
	Vector3(-98.1, 7.8, -85.3), Vector3(-94.3, 7.8, -5.9), Vector3(-94.3, 8.5, 4.4), Vector3(-94.3, 8.5, 54.0),
	Vector3(-86.0, 7.8, -85.3), Vector3(-84.2, 7.8, -5.9), Vector3(-84.2, 8.5, 4.4), Vector3(-84.2, 8.5, 54.0),
	Vector3(-74.0, 7.8, -85.3), Vector3(-74.0, 7.8, -5.9), Vector3(-74.0, 8.5, 4.4), Vector3(-74.0, 8.5, 54.0),
	Vector3(-68.1, 9.5, 4.2), Vector3(-66.4, 8.5, 15.8), Vector3(-66.4, 8.5, 26.0), Vector3(-66.4, 8.5, 36.2),
	Vector3(-66.4, 8.5, 46.4), Vector3(-64.7, 7.8, -72.2), Vector3(-64.7, 7.8, -60.8), Vector3(-64.7, 7.8, -49.4),
	Vector3(-64.7, 7.8, -38.0), Vector3(-64.7, 7.8, -26.7), Vector3(-64.7, 7.8, -15.3), Vector3(-52.3, 7.8, 15.8),
	Vector3(-52.3, 7.8, 26.0), Vector3(-52.3, 7.8, 36.2), Vector3(-52.3, 7.8, 46.4), Vector3(-50.6, 8.5, -72.3),
	Vector3(-50.6, 8.5, -60.9), Vector3(-50.6, 8.5, -49.5), Vector3(-50.6, 8.5, -38.1), Vector3(-50.6, 8.5, -26.7),
	Vector3(-50.6, 8.5, -15.3), Vector3(-43.0, 7.8, 2.7), Vector3(-43.0, 7.8, 59.5), Vector3(-43.0, 8.5, -3.9),
	Vector3(-41.5, 8.5, -83.6), Vector3(-35.6, 9.5, -83.7), Vector3(-32.0, 8.9, -72.4), Vector3(-31.1, 8.5, -3.9),
	Vector3(-29.5, 8.5, -49.4), Vector3(-29.2, 9.5, -61.1), Vector3(-27.9, 8.5, -38.0), Vector3(-26.3, 7.8, 2.7),
	Vector3(-26.3, 7.8, 59.5), Vector3(-26.3, 8.5, -26.5), Vector3(-24.6, 8.5, -15.1), Vector3(-23.1, 9.5, -75.9),
	Vector3(-19.7, 8.5, -65.4), Vector3(-18.4, 9.5, 56.1), Vector3(-18.1, 8.5, -54.6), Vector3(-17.0, 9.5, -32.8),
	Vector3(-16.9, 7.8, 12.0), Vector3(-16.9, 7.8, 24.7), Vector3(-16.9, 7.8, 37.4), Vector3(-16.9, 7.8, 50.2),
	Vector3(-16.6, 8.5, -43.8), Vector3(-14.7, 8.5, -83.6), Vector3(-13.8, 8.6, -22.2), Vector3(-12.0, 8.5, -11.5),
	Vector3(-9.2, 9.5, -3.8), Vector3(-6.8, 9.5, 6.1), Vector3(-6.6, 8.5, 15.7), Vector3(-6.6, 8.5, 26.0),
	Vector3(-6.6, 8.5, 36.2), Vector3(-6.6, 8.5, 46.4), Vector3(-3.9, 8.5, -83.6), Vector3(-3.2, 8.5, -3.9),
	Vector3(1.0, 8.5, 4.4), Vector3(1.0, 8.5, 54.0), Vector3(6.9, 8.5, -83.6), Vector3(7.2, 8.5, -3.9),
	Vector3(14.0, 8.5, 54.0), Vector3(17.7, 8.5, -3.9), Vector3(17.8, 8.5, -83.6), Vector3(17.8, 8.5, 4.4),
	Vector3(25.4, 8.5, -76.0), Vector3(25.4, 8.5, -65.2), Vector3(25.4, 8.5, -54.5), Vector3(25.4, 8.5, -43.7),
	Vector3(25.4, 8.5, -33.0), Vector3(25.4, 8.5, -22.2), Vector3(25.4, 8.5, -11.5), Vector3(25.4, 8.5, 12.0),
	Vector3(25.4, 8.5, 23.5), Vector3(25.4, 8.5, 35.0), Vector3(25.4, 8.5, 46.4), Vector3(25.6, 9.5, 52.3),
]
func _ready() -> void:
	var ampul := StandardMaterial3D.new()
	ampul.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ampul.albedo_color = Color(1.0, 0.78, 0.45)
	ampul.emission_enabled = true
	ampul.emission = Color(1.0, 0.7, 0.35)
	ampul.emission_energy_multiplier = 6.0
	var kure := SphereMesh.new()
	kure.radius = 0.22
	kure.height = 0.16
	kure.material = ampul
	for p in LAMBALAR:
		var bas: Vector3 = p
		var top := MeshInstance3D.new()
		top.mesh = kure
		top.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		top.position = bas + Vector3(0, -0.35, 0)
		add_child(top)
		var l := SpotLight3D.new()
		l.position = bas + Vector3(0, -0.5, 0)
		l.rotation_degrees.x = -90.0
		l.light_color = Color(1.0, 0.68, 0.32)
		l.light_energy = 9.0
		l.spot_range = 16.0
		l.spot_angle = 58.0
		l.spot_attenuation = 0.9
		l.shadow_enabled = true
		l.distance_fade_enabled = true
		l.distance_fade_begin = 55.0
		l.distance_fade_length = 15.0
		l.distance_fade_shadow = 28.0
		add_child(l)
		# lambanın etrafına hafif bir hale (direğin kendisini de aydınlatır)
		var h := OmniLight3D.new()
		h.position = bas + Vector3(0, -0.8, 0)
		h.light_color = Color(1.0, 0.7, 0.38)
		h.light_energy = 0.6
		h.omni_range = 5.0
		h.distance_fade_enabled = true
		h.distance_fade_begin = 55.0
		h.distance_fade_length = 15.0
		add_child(h)
