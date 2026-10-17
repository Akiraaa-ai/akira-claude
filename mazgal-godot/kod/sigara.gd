extends Node3D
## Sigara içme sahnesi (evde ve kulübede): paketten bir sigara alır, çakmakla yakar, birkaç nefes çeker.
## alp'in sigara ve çakmak modelleri kullanılır; köz ve duman ışık ve parçacıktır.
## Kullanım: kur(kamera, eller, paketin dünyadaki yeri), sonra her karede oynat(t). Bitince true döner.

const SIGARA_MODEL := "res://modeller2/modeller2/cigarette.glb"
const CAKMAK_MODEL := "res://modeller2/modeller2/lighter.glb"
const SIGARA_BOY := 0.085
const SURE := 21.0
# sigaranın dudaklardaki yeri (kamera uzayında)
const AGIZ := Vector3(0.012, -0.062, -0.085)
# nefesler: [elin ağza geldiği an, dumanın üflendiği an]
const NEFESLER := [[9.0, 11.2], [14.5, 16.7]]

var kamera: Camera3D
var eller: Node
var paket := Vector3.ZERO

var _sigara: Node3D
var _cakmak: Node3D
var _koz: OmniLight3D
var _koz_parca: GPUParticles3D
var _alev: OmniLight3D
var _duman: GPUParticles3D
var _ufle: GPUParticles3D
var _ses: AudioStreamPlayer
var _yapildi := {}
var _durum := "yok"     # sigara: yok, elde, agizda
var _cekis := 0.0       # köz parlaklığı (nefes çekerken artar)


func kur(k: Camera3D, e: Node, p: Vector3) -> void:
	kamera = k
	eller = e
	paket = p
	_yapildi.clear()
	_durum = "yok"
	if _sigara == null: _parcalari_kur()
	_sigara.visible = false
	_cakmak.visible = false
	_duman.emitting = false
	_ufle.emitting = false
	_koz_parca.emitting = false
	_koz.light_energy = 0.0
	_alev.light_energy = 0.0


func _bir_kez(ad: String, t: float, an: float) -> bool:
	if t < an or _yapildi.has(ad): return false
	_yapildi[ad] = true
	return true


func oynat(t: float) -> bool:
	# paketten bir sigara alır, dudaklarına götürür
	if _bir_kez("uzan", t, 0.0): eller.uzan("sag", paket + Vector3(0, 0.05, 0), 0.6)
	if _bir_kez("al", t, 0.75):
		_durum = "elde"
		_sigara.visible = true
		_ses_cal("paket", -14.0)
		eller.kamerada("sag", AGIZ + Vector3(0.02, -0.03, -0.06), 0.6)
		eller.yumruk("sag", 0.8)
	if _bir_kez("agiza", t, 1.45):
		_durum = "agizda"
		eller.birak("sag", 0.5)
	# çakmak: sol el yüzün önüne gelir, çakar, alev sigaranın ucunu yakar
	if _bir_kez("cakmak", t, 1.7):
		_cakmak.visible = true
		eller.kamerada("sol", AGIZ + Vector3(0.0, -0.075, -0.07), 0.5)
		eller.yumruk("sol", 0.7)
	if _bir_kez("cak", t, 2.4): _ses_cal("cakmak", -6.0)
	var alev := t > 2.45 and t < 3.9
	_alev.light_energy = (0.5 + 0.25 * sin(t * 47.0) + 0.1 * sin(t * 83.0)) if alev else 0.0
	if _bir_kez("yandi", t, 2.9):
		_duman.emitting = true
		_koz_parca.emitting = true
		_ses_cal("sigara_cek", -10.0)
		_nefes_cek()
	if _bir_kez("cakmak_birak", t, 3.95):
		eller.birak("sol", 0.6)
	if _bir_kez("cakmak_cep", t, 4.6): _cakmak.visible = false
	# ilk nefes: yakarken çekilir, sonra üflenir
	var cekis := smoothstep(2.9, 3.4, t) * (1.0 - smoothstep(4.4, 4.9, t))
	if _bir_kez("ufle0", t, 5.2): _ufle_bas()
	# sigarayı dudaklarından alır, elinde tutar
	if _bir_kez("elde0", t, 6.2):
		eller.kamerada("sag", AGIZ + Vector3(0.0, -0.02, -0.03), 0.4)
		eller.yumruk("sag", 0.8)
	if _bir_kez("indir0", t, 6.6):
		_durum = "elde"
		eller.kamerada("sag", Vector3(0.13, -0.2, -0.36), 0.9)
	for i in NEFESLER.size():
		var n: Array = NEFESLER[i]
		var a := float(n[0])
		var u := float(n[1])
		if _bir_kez("kaldir%d" % i, t, a - 0.8): eller.kamerada("sag", AGIZ + Vector3(0.0, -0.02, -0.03), 0.8)
		if _bir_kez("cek%d" % i, t, a):
			_durum = "agizda"
			_ses_cal("sigara_cek", -10.0)
			_nefes_cek()
		cekis = maxf(cekis, smoothstep(a, a + 0.4, t) * (1.0 - smoothstep(u - 1.0, u - 0.5, t)))
		if _bir_kez("indir%d" % (i + 1), t, u - 0.6):
			_durum = "elde"
			eller.kamerada("sag", Vector3(0.13, -0.2, -0.36), 0.8)
		if _bir_kez("ufle%d" % (i + 1), t, u): _ufle_bas()
	# son: sigara elde aşağıda kalır, el iner (söndürülmüş sayılır)
	if _bir_kez("son", t, SURE - 1.6):
		eller.birak("sag", 0.9)
	if _bir_kez("bitti", t, SURE - 0.7):
		_durum = "yok"
		_sigara.visible = false
		_duman.emitting = false
		_koz_parca.emitting = false
	_cekis = cekis
	return t >= SURE


var _nefes_no := 0

## Sigarayı çekerken duyulan nefes (alp'in kısa nefes kayıtları sırayla).
func _nefes_cek() -> void:
	_ses_cal(["selim_nefes_01", "selim_nefes_03", "selim_nefes_05"][_nefes_no % 3], -4.0)


func _ufle_bas() -> void:
	_yapildi["ufle_an"] = _zaman()
	_ses_cal("duman_ufle", -9.0)
	# alp'in kendi nefes kayıtlarından uzun olanlar: dumanı üfler
	_nefes_no += 1
	_ses_cal("selim_nefes_04" if _nefes_no % 2 == 0 else "selim_nefes_02", -4.0)
	_ufle.restart()
	_ufle.emitting = true


func _zaman() -> float:
	return Time.get_ticks_msec() / 1000.0


func _process(dt: float) -> void:
	if kamera == null or _sigara == null: return
	var cevir := Basis(Vector3.UP, PI * 0.5)   # modelin boyu x ekseni: kameranın önüne bakar
	match _durum:
		"agizda":
			_sigara.global_transform = kamera.global_transform * Transform3D(cevir, AGIZ)
		"elde":
			var avuc: Vector3 = eller.avuc("sag")
			_sigara.global_transform = Transform3D(kamera.global_basis * Basis(Vector3.UP, PI * 0.35) * Basis(Vector3.RIGHT, -0.4), avuc)
	if _cakmak.visible:
		_cakmak.global_transform = Transform3D(kamera.global_basis, eller.avuc("sol") + kamera.global_basis.y * 0.01)
		_alev.global_position = _cakmak.global_position + kamera.global_basis.y * 0.075
	# köz: nefes çekerken parlar
	var hedef := 0.08 + 0.55 * _cekis if _koz_parca.emitting else 0.0
	_koz.light_energy = move_toward(_koz.light_energy, hedef, dt * 3.0)
	# üflenen duman ağzın önünden çıkar
	if _ufle.emitting and _zaman() - float(_yapildi.get("ufle_an", -9.0)) > 1.4: _ufle.emitting = false
	_ufle.global_transform = Transform3D(kamera.global_basis, kamera.global_position + kamera.global_basis * Vector3(0, -0.07, -0.12))


func _parcalari_kur() -> void:
	_sigara = Node3D.new()
	_sigara.name = "Sigara"
	add_child(_sigara)
	var uc := Vector3(SIGARA_BOY * 0.5, 0, 0)
	if ResourceLoader.exists(SIGARA_MODEL):
		var m: Node3D = (load(SIGARA_MODEL) as PackedScene).instantiate()
		_sigara.add_child(m)
		var a := _kutu(m)
		var o := SIGARA_BOY / maxf(a.size.x, 0.001)
		m.scale = Vector3.ONE * o
		m.position = -a.get_center() * o
	_cakmak = Node3D.new()
	_cakmak.name = "Cakmak"
	add_child(_cakmak)
	if ResourceLoader.exists(CAKMAK_MODEL):
		var c: Node3D = (load(CAKMAK_MODEL) as PackedScene).instantiate()
		_cakmak.add_child(c)
		var b := _kutu(c)
		c.position = -Vector3(b.get_center().x, b.position.y, b.get_center().z)
	# köz: ucunda turuncu ışık ve birkaç kıvılcım
	_koz = OmniLight3D.new()
	_koz.light_color = Color(1.0, 0.42, 0.12)
	_koz.omni_range = 0.45
	_koz.light_energy = 0.0
	_koz.position = uc
	_sigara.add_child(_koz)
	_koz_parca = _parcacik(6, 0.25, 0.007, Color(1.0, 0.45, 0.1, 1.0), true)
	_koz_parca.local_coords = true
	_koz_parca.position = uc
	(_koz_parca.process_material as ParticleProcessMaterial).initial_velocity_max = 0.0
	(_koz_parca.process_material as ParticleProcessMaterial).gravity = Vector3.ZERO
	_sigara.add_child(_koz_parca)
	# ucundan yükselen ince duman
	_duman = _parcacik(28, 3.0, 0.05, Color(0.75, 0.75, 0.78, 0.14), false)
	_duman.position = uc
	_sigara.add_child(_duman)
	# üflenen duman
	_ufle = _parcacik(40, 2.6, 0.16, Color(0.78, 0.78, 0.8, 0.16), false)
	var pm := _ufle.process_material as ParticleProcessMaterial
	pm.direction = Vector3(0, -0.15, -1); pm.spread = 18.0
	pm.initial_velocity_min = 0.35; pm.initial_velocity_max = 0.6
	pm.damping_min = 0.3; pm.damping_max = 0.5
	pm.scale_min = 0.5; pm.scale_max = 1.8
	add_child(_ufle)
	_alev = OmniLight3D.new()
	_alev.light_color = Color(1.0, 0.62, 0.25)
	_alev.omni_range = 1.6
	_alev.light_energy = 0.0
	add_child(_alev)
	_ses = AudioStreamPlayer.new()
	add_child(_ses)


func _parcacik(adet: int, omur: float, boy: float, renk: Color, parlak: bool) -> GPUParticles3D:
	var d := GPUParticles3D.new()
	d.amount = adet
	d.lifetime = omur
	d.emitting = false
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0, 1, 0); pm.spread = 10.0
	pm.initial_velocity_min = 0.03; pm.initial_velocity_max = 0.07
	pm.gravity = Vector3(0.005, 0.05, 0)
	pm.turbulence_enabled = true; pm.turbulence_noise_strength = 0.35; pm.turbulence_noise_scale = 2.5
	pm.scale_min = 0.4; pm.scale_max = 1.2
	var egri := Curve.new()
	egri.add_point(Vector2(0, 0.3)); egri.add_point(Vector2(1, 1.6))
	var ct := CurveTexture.new(); ct.curve = egri
	if not parlak: pm.scale_curve = ct
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1)); g.set_color(1, Color(1, 1, 1, 0))
	var gt := GradientTexture1D.new(); gt.gradient = g
	pm.color_ramp = gt
	d.process_material = pm
	var q := QuadMesh.new(); q.size = Vector2(boy, boy)
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.vertex_color_use_as_albedo = true
	mat.albedo_color = renk
	# yumuşak, yuvarlak bulut: ortası dolu, kenarı saydam
	var yuvarlak := GradientTexture2D.new()
	yuvarlak.fill = GradientTexture2D.FILL_RADIAL
	yuvarlak.fill_from = Vector2(0.5, 0.5); yuvarlak.fill_to = Vector2(0.5, 0.0)
	var yg := Gradient.new()
	yg.set_color(0, Color(1, 1, 1, 1)); yg.set_color(1, Color(1, 1, 1, 0))
	yuvarlak.gradient = yg
	yuvarlak.width = 64; yuvarlak.height = 64
	mat.albedo_texture = yuvarlak
	if parlak: mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	q.material = mat
	d.draw_pass_1 = q
	return d


func _kutu(n: Node3D) -> AABB:
	var a := AABB(); var ilk := true
	for m in n.find_children("*", "MeshInstance3D", true, false):
		var mi := m as MeshInstance3D
		var t := Transform3D.IDENTITY
		var c: Node = mi
		while c != n:
			t = (c as Node3D).transform * t
			c = c.get_parent()
		var b: AABB = t * mi.get_aabb()
		a = b if ilk else a.merge(b); ilk = false
	return a


# ---------------------------------------------------------------- sesler
## res://sesler/<ad>.mp3 ya da .ogg varsa o çalar; yoksa yedek ses üretilir.
var _sesler := {}

func _ses_cal(ad: String, db: float) -> void:
	if not _sesler.has(ad):
		var akis: AudioStream = null
		for uz in ["mp3", "ogg", "wav"]:
			var yol := "res://sesler/%s.%s" % [ad, uz]
			if ResourceLoader.exists(yol):
				akis = load(yol)
				break
		_sesler[ad] = akis if akis else _yedek(ad)
	if _sesler[ad] == null: return
	var p := AudioStreamPlayer.new()
	p.stream = _sesler[ad]
	p.volume_db = db
	add_child(p)
	p.play()
	p.finished.connect(p.queue_free)


func _yedek(ad: String) -> AudioStream:
	var hiz := 22050
	var o := PackedFloat32Array()
	var dusuk := 0.0
	match ad:
		"cakmak":
			# çark sürtünmesi, çıt, sonra alevin hışırtısı
			for i in int(hiz * 1.4):
				var t := float(i) / hiz
				var r := randf() * 2.0 - 1.0
				dusuk = lerpf(dusuk, r, 0.25)
				var cark := r * 0.5 * exp(-t * 60.0)
				var hisirti := dusuk * 0.12 * smoothstep(0.05, 0.12, t) * (1.0 - smoothstep(1.1, 1.4, t))
				o.append(cark + hisirti)
		"sigara_cek":
			# kağıdın cızırtısı: seyrek çıtırtılar
			for i in int(hiz * 1.5):
				var t := float(i) / hiz
				var r := randf() * 2.0 - 1.0
				dusuk = lerpf(dusuk, r, 0.1)
				var cit := r * 0.35 if randf() < 0.004 else 0.0
				o.append((dusuk * 0.05 + cit) * sin(PI * t / 1.5))
		"duman_ufle":
			for i in int(hiz * 1.8):
				var t := float(i) / hiz
				dusuk = lerpf(dusuk, randf() * 2.0 - 1.0, 0.18)
				o.append(dusuk * 0.22 * smoothstep(0.0, 0.25, t) * (1.0 - smoothstep(0.9, 1.8, t)))
		"paket":
			for i in int(hiz * 0.35):
				var t := float(i) / hiz
				o.append((randf() * 2.0 - 1.0) * 0.18 * exp(-fmod(t, 0.09) * 50.0) * exp(-t * 5.0))
		_:
			return null
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = hiz
	var b := PackedByteArray()
	b.resize(o.size() * 2)
	for i in o.size(): b.encode_s16(i * 2, int(clampf(o[i], -1.0, 1.0) * 32767.0))
	w.data = b
	return w
