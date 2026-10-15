extends CharacterBody3D
## Selim'in arabası: W gaz, S fren ve geri, A/D direksiyon. Tekerlekler döner, ön tekerlekler direksiyonla döner,
## kapılar açılıp kapanır. Yüksekliği yere atılan ışınla bulunur; kaldırıma çıkabilir, duvara çarpınca durur.

const AZAMI_HIZ := 13.0      # m/sn (yaklaşık 47 km/sa)
const GERI_HIZ := 4.0
const IVME := 4.2
const FREN := 10.0
const SURTUNME := 1.6
const DINGIL := 3.05         # ön ve arka tekerlek arası
const AZAMI_DIREKSIYON := 0.55
const TEKER_YARICAP := 0.37

@onready var model: Node3D = $Model
@onready var kamera: Camera3D = $Kamera
@onready var motor: AudioStreamPlayer3D = $Motor
@onready var radyo: AudioStreamPlayer = $Radyo

var surulebilir := false
var hiz := 0.0
var direksiyon := 0.0
var teker_aci := 0.0
var _iskelet: Skeleton3D
var _kemik := {}
var _kapi := {"DFL_8": 0.0, "DFR_6": 0.0}
var _kapi_hedef := {"DFL_8": 0.0, "DFR_6": 0.0}
var _bakis := Vector2.ZERO
var _motor_acik := false
var _motor_faz := 0.0
var _motor_oynatma: AudioStreamGeneratorPlayback
var _carpma_bekle := 0.0

func _ready() -> void:
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	_iskelet = model.find_child("Skeleton3D", true, false) as Skeleton3D
	if _iskelet:
		for ad in ["FL_2", "FR_0", "RL_3", "RR_1", "DFL_8", "DFR_6"]:
			_kemik[ad] = _iskelet.find_bone(ad)
	_camlari_duzelt()
	var gen := AudioStreamGenerator.new(); gen.mix_rate = 22050; gen.buffer_length = 0.25
	motor.stream = gen
	_yere_otur(true)

## Camlar: yağmur damlaları birikir, ön camda silecekler geçtikçe silinir; motor yeni çalışınca kenarları buğulu.
const CAM_SHADER := """shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, unshaded;
uniform sampler2D ekran : hint_screen_texture, filter_linear_mipmap;
uniform float silecek_zaman = 0.0;
uniform float silecek = 0.0;
uniform float silecek_bos = 0.0;
uniform float bugu = 0.6;
uniform float hiz = 0.0;
varying vec3 yerel;
varying vec3 yerel_n;
float h(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
void vertex() { yerel = VERTEX; yerel_n = NORMAL; }
void fragment() {
	// ön cam: aracın önüne bakan, üst taraftaki cam
	bool on_cam = yerel.x > 30.0 && yerel.y > 64.0 && yerel_n.x > 0.25;
	vec2 p = on_cam ? vec2(yerel.z, length(yerel.xy - vec2(72.0, 68.0))) : vec2(yerel.x + yerel.z, yerel.y);
	p *= 0.32;
	// silecek: iki kol, 1.4 sn'de bir gidip gelir
	float P = 1.4;
	float son_gecis = 99.0;
	if (on_cam && silecek > 0.5) {
		for (int k = 0; k < 2; k++) {
			vec2 pv = vec2(k == 0 ? -22.0 : 20.0, 0.0);
			vec2 q = vec2(yerel.z, length(yerel.xy - vec2(72.0, 68.0))) - pv;
			if (length(q) < 44.0) {
				float th = clamp(atan(q.y, q.x) / 3.14159, 0.0, 1.0);
				float u1 = acos(clamp(1.0 - 2.0 * th, -1.0, 1.0)) / 6.28318;
				float u2 = 1.0 - u1;
				float u = fract(silecek_zaman / P);
				float g = u >= u2 ? u - u2 : (u >= u1 ? u - u1 : u + 1.0 - u2);
				son_gecis = min(son_gecis, g * P + silecek_bos);
			}
		}
	}
	float damla = 0.0;
	vec2 egim = vec2(0.0);
	for (int k = 0; k < 2; k++) {
		vec2 q = p * (1.0 + float(k) * 0.8);
		// yan camlarda araç hızlanınca damlalar geriye akar
		if (!on_cam) q.x += TIME * hiz * 0.08 * (1.0 + float(k));
		else q.y -= TIME * (0.08 + float(k) * 0.05);
		vec2 id = floor(q);
		vec2 f = fract(q) - 0.5;
		vec2 c = (vec2(h(id + 2.3), h(id + 7.1)) - 0.5) * 0.5;
		float r = 0.08 + 0.12 * h(id + 4.4);
		float gecikme = h(id + 9.7) * 1.2;
		float var_ = step(0.55, h(id + float(k))) * step(gecikme, son_gecis);
		float m = smoothstep(r, r * 0.4, length((f - c) * vec2(1.0, 0.8))) * var_;
		damla = max(damla, m);
		egim += (f - c) * m;
	}
	// buğu: kenarlardan başlar, motor ısındıkça çekilir
	float kenar = on_cam ? smoothstep(20.0, 45.0, abs(yerel.z)) + smoothstep(85.0, 100.0, yerel.y) : 0.6;
	float b = clamp(bugu * (0.15 + kenar), 0.0, 0.7);
	vec3 duz = textureLod(ekran, SCREEN_UV, b * 3.0).rgb;
	vec3 arka = textureLod(ekran, SCREEN_UV - egim * 0.05, 1.5 + b * 2.0).rgb;
	vec3 c = mix(duz * 0.92, arka * 1.2 + vec3(0.015), damla);
	c = mix(c, vec3(0.1, 0.105, 0.11) + c * 0.75, b * 0.35);
	ALBEDO = c;
}
"""
var cam_mat: ShaderMaterial
var silecek_acik := false
var _silecek_t := 0.0
var _bugu := 0.4
var _silecek_ses: AudioStreamPlayer3D
var _silecek_onceki := 0.0
var _silecek_bos := 0.0

func _camlari_duzelt() -> void:
	cam_mat = ShaderMaterial.new()
	var sh := Shader.new(); sh.code = CAM_SHADER
	cam_mat.shader = sh
	for m in model.find_children("*", "MeshInstance3D", true, false):
		var mi := m as MeshInstance3D
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		if mi.mesh == null: continue
		for i in mi.mesh.get_surface_count():
			var mat := mi.mesh.surface_get_material(i)
			if mat and "glass" in mat.resource_name.to_lower():
				mi.set_surface_override_material(i, cam_mat)
	_silecek_ses = AudioStreamPlayer3D.new()
	_silecek_ses.position = Vector3(0, 1.0, -1.0); _silecek_ses.volume_db = -12.0
	_silecek_ses.stream = _silecek_sesi()
	add_child(_silecek_ses)

## Silecek lastiğinin camda sürtünmesi: kısa, kuru bir sürtme ve sonunda tok bir vuruş.
func _silecek_sesi() -> AudioStream:
	for uz in ["ogg", "mp3", "wav"]:
		if ResourceLoader.exists("res://sesler/silecek." + uz): return load("res://sesler/silecek." + uz)
	var hz := 22050
	var n := int(hz * 0.62)
	var b := PackedByteArray(); b.resize(n * 2)
	var y := 0.0
	for i in n:
		var t := float(i) / hz
		y += (randf_range(-1.0, 1.0) - y) * 0.25
		var d := y * 0.35 * sin(PI * clampf(t / 0.55, 0.0, 1.0)) * (0.7 + 0.3 * sin(TAU * 31.0 * t))
		if t > 0.55: d += sin(TAU * 90.0 * t) * exp(-(t - 0.55) * 60.0) * 0.5
		b.encode_s16(i * 2, int(clampf(d, -1.0, 1.0) * 28000.0))
	var w := AudioStreamWAV.new(); w.format = AudioStreamWAV.FORMAT_16_BITS; w.mix_rate = hz; w.data = b
	return w

func _camlar(dt: float) -> void:
	if cam_mat == null: return
	if silecek_acik or fmod(_silecek_t, 1.4) > 0.03:
		_silecek_t += dt
		_silecek_bos = 0.0
		# her yarım turda (bir uçtan öbürüne) sürtme sesi
		if floor(_silecek_t / 0.7) != floor(_silecek_onceki / 0.7): _silecek_ses.play()
		_silecek_onceki = _silecek_t
	else:
		_silecek_bos += dt
	if _motor_acik: _bugu = maxf(0.05, _bugu - dt * 0.012)
	cam_mat.set_shader_parameter("silecek_zaman", _silecek_t)
	cam_mat.set_shader_parameter("silecek", 1.0 if _silecek_t > 0.0 else 0.0)
	cam_mat.set_shader_parameter("silecek_bos", _silecek_bos)
	cam_mat.set_shader_parameter("bugu", _bugu)
	cam_mat.set_shader_parameter("hiz", absf(hiz))

## Kapıyı aç (true) ya da kapat (false). Sürücü kapısı "DFL_8".
func kapi(ad: String, acik: bool) -> void:
	_kapi_hedef[ad] = 1.0 if acik else 0.0

func motoru_calistir(acik: bool) -> void:
	_motor_acik = acik
	$Farlar.visible = acik
	$StopLambasi.visible = acik
	$Gosterge.visible = acik
	if acik:
		motor.play(); _motor_oynatma = motor.get_stream_playback()
		if radyo.stream: radyo.play()
	else:
		motor.stop(); _motor_oynatma = null; radyo.stop()

func _unhandled_input(e: InputEvent) -> void:
	if not surulebilir: return
	if e is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var d := get_node_or_null("/root/Duraklat")
		var h: float = 0.0022 * (float(d.fare) if d else 1.0)
		_bakis.x = clamp(_bakis.x - e.relative.x * h, deg_to_rad(-110), deg_to_rad(110))
		_bakis.y = clamp(_bakis.y - e.relative.y * h * (-1.0 if d and d.get("ters_y") == true else 1.0), deg_to_rad(-55), deg_to_rad(40))

func _physics_process(dt: float) -> void:
	var gaz := 0.0; var yon := 0.0
	if surulebilir:
		gaz = Input.get_axis("geri", "ileri")
		yon = Input.get_axis("sag", "sol")
	# hız
	if gaz > 0.0:
		hiz += (IVME if hiz >= 0.0 else FREN) * gaz * dt
	elif gaz < 0.0:
		hiz += (FREN if hiz > 0.0 else IVME * 0.6) * gaz * dt
	else:
		hiz = move_toward(hiz, 0.0, SURTUNME * dt)
	hiz = clamp(hiz - hiz * hiz * sign(hiz) * 0.004 * dt, -GERI_HIZ, AZAMI_HIZ)
	# direksiyon: hızlanınca daha az döner
	var hedef_dir: float = yon * AZAMI_DIREKSIYON * lerp(1.0, 0.45, clamp(abs(hiz) / AZAMI_HIZ, 0.0, 1.0))
	direksiyon = move_toward(direksiyon, hedef_dir, dt * 1.6)
	rotate_y(hiz * tan(direksiyon) / DINGIL * dt)
	var ileri := -global_transform.basis.z
	velocity = Vector3(ileri.x, 0.0, ileri.z).normalized() * hiz
	var once := global_position
	move_and_slide()
	# bir yere çarptıysa yavaşla
	_carpma_bekle -= dt
	if get_slide_collision_count() > 0:
		var gercek: float = (global_position - once).length() / max(dt, 0.001)
		if abs(hiz) > 2.0 and gercek < abs(hiz) * 0.5 and _carpma_bekle <= 0.0:
			_carpma_bekle = 0.6
			if has_node("Carpma"): ($Carpma as AudioStreamPlayer3D).play()
		hiz = sign(hiz) * min(abs(hiz), gercek)
	_yere_otur(false)
	_camlar(dt)
	_tekerler(dt)
	_kapilar(dt)
	_kamera(dt)
	_motor_sesi()

func _isin(yer: Vector3) -> Variant:
	var q := PhysicsRayQueryParameters3D.create(yer + Vector3(0, 2.0, 0), yer + Vector3(0, -3.0, 0))
	q.exclude = [get_rid()]
	var oyuncu := get_tree().current_scene.get_node_or_null("Selim") if get_tree().current_scene else null
	if oyuncu is CollisionObject3D: q.exclude.append((oyuncu as CollisionObject3D).get_rid())
	var r := get_world_3d().direct_space_state.intersect_ray(q)
	return r.position.y if r else null

# arabanın yüksekliği ve öne-arkaya eğimi ön ve arka dingilin altındaki yere göre bulunur
func _yere_otur(ani: bool) -> void:
	var ileri := -global_transform.basis.z; ileri.y = 0; ileri = ileri.normalized()
	var on: Variant = _isin(global_position + ileri * 1.5)
	var arka: Variant = _isin(global_position - ileri * 1.5)
	if on == null and arka == null: return
	if on == null: on = arka
	if arka == null: arka = on
	var y: float = (float(on) + float(arka)) * 0.5
	var egim: float = atan2(float(on) - float(arka), 3.0)
	global_position.y = y if ani else lerp(global_position.y, y, 0.35)
	model.rotation.z = lerp(model.rotation.z, egim, 1.0 if ani else 0.25)

func _tekerler(dt: float) -> void:
	if _iskelet == null: return
	teker_aci -= hiz / TEKER_YARICAP * dt
	for ad in ["FL_2", "FR_0", "RL_3", "RR_1"]:
		var i: int = _kemik[ad]
		if i < 0: continue
		var q := _iskelet.get_bone_rest(i).basis.get_rotation_quaternion()
		if ad.begins_with("F"): q = q * Quaternion(Vector3(0, 0, 1), direksiyon)
		q = q * Quaternion(Vector3(0, 1, 0), teker_aci)
		_iskelet.set_bone_pose_rotation(i, q)

func _kapilar(dt: float) -> void:
	if _iskelet == null: return
	for ad in _kapi:
		_kapi[ad] = move_toward(_kapi[ad], _kapi_hedef[ad], dt * 1.8)
		var i: int = _kemik[ad]
		if i < 0: continue
		var k: float = ease(_kapi[ad], -2.0)
		var yon := -1.0 if ad == "DFL_8" else 1.0
		var q := _iskelet.get_bone_rest(i).basis.get_rotation_quaternion() * Quaternion(Vector3(0, 0, 1), yon * k * 1.1)
		_iskelet.set_bone_pose_rotation(i, q)

var _sarsinti := 0.0
func _kamera(dt: float) -> void:
	if not surulebilir: return
	_sarsinti += dt * (2.0 + abs(hiz) * 1.3)
	var titreme: float = 0.004 * clamp(abs(hiz) / 6.0, 0.0, 1.0)
	kamera.rotation = Vector3(_bakis.y + sin(_sarsinti * 7.1) * titreme - 0.04, _bakis.x + sin(_sarsinti * 3.3) * titreme * 0.6, sin(_sarsinti * 2.2) * titreme)

# motor: devir hıza göre yükselen, kaba bir dalga + biraz gürültü
func _motor_sesi() -> void:
	if _motor_oynatma == null: return
	var devir: float = 26.0 + abs(hiz) * 4.2 + (8.0 if Input.is_action_pressed("ileri") and surulebilir else 0.0)
	var kac := _motor_oynatma.get_frames_available()
	for _i in kac:
		_motor_faz = fmod(_motor_faz + devir / 22050.0, 1.0)
		var d := (_motor_faz * 2.0 - 1.0) * 0.35 + sin(_motor_faz * TAU * 2.0) * 0.25 + randf_range(-0.08, 0.08)
		d *= 0.55
		_motor_oynatma.push_frame(Vector2(d, d))
