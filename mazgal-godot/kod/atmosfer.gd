extends Node3D
## Gece sokağının havası: uzak şimşek ve gök gürültüsü, uzakta havlayan köpek, oluklardan akan su,
## arada bir yoldan geçen araba (sesi ve farlarının ışığı). Sesler sesler/ klasöründe varsa oradan,
## yoksa (köpek dışında) kendi üretilen seslerle çalar.
##   sesler/gok_gurultusu.*   sesler/kopek.*   sesler/oluk.*   sesler/gecen_araba.*

@export var ay: DirectionalLight3D
@export var ortam: WorldEnvironment
var oyuncu: Node3D
## Kulübenin içindeyken dışarıdaki sesler biraz boğuklaşır.
var iceride := false
## Selim araba sürerken yoldan başka araba geçmez.
var araba_gecebilir := true

var _ay_guc := 0.12
var _ortam_guc := 0.0
var _simsek_t := 0.0
var _simsek_sira := []
var _sonraki_simsek := 14.0
var _sonraki_kopek := 22.0
var _sonraki_araba := 35.0
var _gurultu: AudioStream
var _kopek: AudioStream
var _araba_ses: AudioStream
var _oluklar: Array[AudioStreamPlayer3D] = []
var _araba: AudioStreamPlayer3D
var _araba_isik: SpotLight3D
var _araba_bas := Vector3.ZERO
var _araba_bit := Vector3.ZERO
var _araba_t := -1.0
const ARABA_SURE := 7.0


func _ready() -> void:
	if ay: _ay_guc = ay.light_energy
	if ortam and ortam.environment: _ortam_guc = ortam.environment.ambient_light_energy
	_gurultu = _dosya("gok_gurultusu")
	if _gurultu == null: _gurultu = _gok_gurultusu_yap()
	_kopek = _dosya("kopek")
	_araba_ses = _dosya("gecen_araba")
	if _araba_ses == null: _araba_ses = _araba_sesi_yap()
	var oluk := _dosya("oluk", true)
	if oluk == null: oluk = _oluk_sesi_yap()
	for i in 3:
		var a := AudioStreamPlayer3D.new()
		a.stream = oluk; a.unit_size = 2.5; a.max_distance = 18.0; a.volume_db = -6.0
		a.pitch_scale = 0.9 + i * 0.12
		add_child(a)
		_oluklar.append(a)
	_araba = AudioStreamPlayer3D.new(); _araba.stream = _araba_ses; _araba.unit_size = 9.0
	_araba.doppler_tracking = AudioStreamPlayer3D.DOPPLER_TRACKING_IDLE_STEP
	add_child(_araba)
	_araba_isik = SpotLight3D.new()
	_araba_isik.light_color = Color(1.0, 0.92, 0.75); _araba_isik.light_energy = 0.0
	_araba_isik.spot_range = 28.0; _araba_isik.spot_angle = 32.0; _araba_isik.shadow_enabled = true
	add_child(_araba_isik)


func _dosya(ad: String, dongu := false) -> AudioStream:
	for uz in ["ogg", "mp3", "wav"]:
		var yol := "res://sesler/%s.%s" % [ad, uz]
		if ResourceLoader.exists(yol):
			var a: AudioStream = load(yol)
			if dongu and a is AudioStreamMP3: (a as AudioStreamMP3).loop = true
			if dongu and a is AudioStreamOggVorbis: (a as AudioStreamOggVorbis).loop = true
			return a
	return null


func _process(dt: float) -> void:
	if oyuncu == null: return
	var p := oyuncu.global_position
	# oluklar oyuncunun yakınındaki binaların köşelerinde gibi duyulur, yavaşça yer değiştirir
	for i in _oluklar.size():
		var a := _oluklar[i]
		var aci := float(i) * 2.1 + 0.4
		var hedef := p + Vector3(cos(aci) * 6.0, 2.5, sin(aci) * 6.0)
		if not a.playing:
			a.global_position = hedef; a.play(randf() * 2.0)
		a.global_position = a.global_position.lerp(hedef, dt * 0.05)
		a.volume_db = -14.0 if iceride else -6.0
	_simsek(dt)
	_sonraki_kopek -= dt
	if _sonraki_kopek <= 0.0:
		_sonraki_kopek = randf_range(40.0, 90.0)
		if _kopek:
			var aci := randf() * TAU
			_tek_ses(_kopek, p + Vector3(cos(aci) * 45.0, 3.0, sin(aci) * 45.0), randf_range(0.92, 1.05), -4.0, 30.0)
	_gecen_araba(dt, p)


# ---------------- şimşek ----------------
func _simsek(dt: float) -> void:
	_sonraki_simsek -= dt
	if _sonraki_simsek <= 0.0:
		_sonraki_simsek = randf_range(25.0, 60.0)
		simsek_cak(randf_range(0.5, 1.0))
	var parlak := 0.0
	if _simsek_t >= 0.0:
		_simsek_t += dt
		for c in _simsek_sira:
			var d: float = _simsek_t - float(c[0])
			if d >= 0.0: parlak = maxf(parlak, float(c[1]) * exp(-d * 18.0))
		if _simsek_t > 1.5: _simsek_t = -1.0
	if ay: ay.light_energy = _ay_guc + parlak * 3.5
	if ortam and ortam.environment: ortam.environment.ambient_light_energy = _ortam_guc + parlak * 0.9


## Bir şimşek çakar; gök gürültüsü uzaklığa göre birkaç saniye sonra gelir.
func simsek_cak(guc: float) -> void:
	_simsek_t = 0.0
	_simsek_sira = [[0.0, guc], [0.09, guc * 0.5], [0.22, guc * 0.9]]
	if randf() < 0.5: _simsek_sira.append([0.5, guc * 0.4])
	var gecikme := randf_range(1.2, 4.5)
	var tw := create_tween()
	tw.tween_interval(gecikme)
	tw.tween_callback(func() -> void:
		var a := AudioStreamPlayer.new(); a.stream = _gurultu
		a.volume_db = lerpf(-4.0, -12.0, gecikme / 4.5) - (5.0 if iceride else 0.0)
		a.pitch_scale = randf_range(0.85, 1.1)
		add_child(a); a.play(); a.finished.connect(a.queue_free))


# ---------------- geçen araba ----------------
func _gecen_araba(dt: float, p: Vector3) -> void:
	if _araba_t < 0.0:
		if araba_gecebilir: _sonraki_araba -= dt
		if _sonraki_araba > 0.0: return
		_sonraki_araba = randf_range(60.0, 120.0)
		# oyuncunun 12 m ötesinden, bakış yönüne dik bir çizgide geçer
		var ileri := -oyuncu.global_transform.basis.z; ileri.y = 0.0
		if ileri.length() < 0.1: ileri = Vector3.FORWARD
		ileri = ileri.normalized()
		var yan := ileri.cross(Vector3.UP).normalized()
		if randf() < 0.5: yan = -yan
		var orta := p + ileri * 12.0
		_araba_bas = orta - yan * 70.0 + Vector3(0, 0.7, 0)
		_araba_bit = orta + yan * 70.0 + Vector3(0, 0.7, 0)
		_araba_t = 0.0
		_araba.global_position = _araba_bas
		_araba.volume_db = -8.0 if iceride else 0.0
		_araba.play()
		return
	_araba_t += dt
	var u := clampf(_araba_t / ARABA_SURE, 0.0, 1.0)
	var yer := _araba_bas.lerp(_araba_bit, u)
	_araba.global_position = yer
	# farların ışığı yerde ve duvarlarda süpürür
	var yon := (_araba_bit - _araba_bas).normalized()
	_araba_isik.global_position = yer
	_araba_isik.look_at(yer + yon * 10.0 + Vector3(0, -0.6, 0), Vector3.UP)
	_araba_isik.light_energy = 2.2 * sin(u * PI)
	if _araba_t > ARABA_SURE:
		_araba_t = -1.0
		_araba_isik.light_energy = 0.0


func _tek_ses(akis: AudioStream, yer: Vector3, perde: float, db: float, birim: float) -> void:
	var a := AudioStreamPlayer3D.new(); a.stream = akis; a.pitch_scale = perde; a.volume_db = db; a.unit_size = birim
	add_child(a); a.global_position = yer; a.play()
	a.finished.connect(a.queue_free)


# ---------------- üretilen sesler ----------------
func _wav(veri: PackedFloat32Array, hiz: int, dongu: bool) -> AudioStreamWAV:
	var b := PackedByteArray(); b.resize(veri.size() * 2)
	for i in veri.size():
		b.encode_s16(i * 2, int(clampf(veri[i], -1.0, 1.0) * 30000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS; w.mix_rate = hiz; w.data = b
	if dongu:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD; w.loop_end = veri.size()
	return w


# alçak, yuvarlanan gürültü: kahverengi gürültü, birkaç patlama ve uzun bir sönüş
func _gok_gurultusu_yap() -> AudioStreamWAV:
	var hiz := 22050
	var n := hiz * 7
	var v := PackedFloat32Array(); v.resize(n)
	var kahve := 0.0
	var alcak := 0.0
	var patlama := [[0.0, 1.0], [0.35, 0.7], [0.9, 0.85], [1.7, 0.5], [2.6, 0.35]]
	for i in n:
		var t := float(i) / hiz
		kahve = clampf(kahve + randf_range(-1.0, 1.0) * 0.06, -1.0, 1.0) * 0.998
		alcak += (kahve - alcak) * 0.04
		var zarf := 0.0
		for pt in patlama:
			var d: float = t - float(pt[0])
			if d >= 0.0: zarf += float(pt[1]) * (1.0 - exp(-d * 30.0)) * exp(-d * 0.9)
		v[i] = alcak * zarf * 2.2
	return _wav(v, hiz, false)


# oluktan akan su: küçük damla şıpırtıları ve ince akış sesi, döngü
func _oluk_sesi_yap() -> AudioStreamWAV:
	var hiz := 22050
	var n := hiz * 3
	var v := PackedFloat32Array(); v.resize(n)
	var akis := 0.0
	var damlalar := []
	for k in 40:
		damlalar.append([randf() * 3.0, randf_range(600.0, 1800.0), randf_range(0.15, 0.4)])
	for i in n:
		var t := float(i) / hiz
		akis += (randf_range(-1.0, 1.0) - akis) * 0.35
		var s := akis * 0.12
		for d in damlalar:
			var dt: float = t - float(d[0])
			if dt >= 0.0 and dt < 0.06:
				s += sin(TAU * float(d[1]) * (1.0 + dt * 8.0) * dt) * exp(-dt * 70.0) * float(d[2])
		v[i] = s
	return _wav(v, hiz, true)


# uzaktan gelip geçen araba: lastiklerin ıslak yoldaki hışırtısı ve alçak motor
func _araba_sesi_yap() -> AudioStreamWAV:
	var hiz := 22050
	var n := int(hiz * ARABA_SURE)
	var v := PackedFloat32Array(); v.resize(n)
	var hisirti := 0.0
	var faz := 0.0
	for i in n:
		var t := float(i) / hiz
		hisirti += (randf_range(-1.0, 1.0) - hisirti) * 0.5
		faz += 38.0 / hiz
		var motor := sin(TAU * faz) * 0.4 + sin(TAU * faz * 2.0) * 0.2
		var zarf := smoothstep(0.0, 1.0, t) * smoothstep(ARABA_SURE, ARABA_SURE - 1.0, t)
		v[i] = (hisirti * 0.5 + motor * 0.25) * zarf
	return _wav(v, hiz, false)
