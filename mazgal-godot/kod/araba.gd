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

func _camlari_duzelt() -> void:
	for m in model.find_children("*", "MeshInstance3D", true, false):
		var mi := m as MeshInstance3D
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		if mi.mesh == null: continue
		for i in mi.mesh.get_surface_count():
			var mat := mi.mesh.surface_get_material(i)
			if mat and "glass" in mat.resource_name.to_lower():
				var cam := StandardMaterial3D.new()
				cam.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				cam.albedo_color = Color(0.5, 0.56, 0.6, 0.16)
				cam.roughness = 0.05; cam.metallic = 0.2
				mi.set_surface_override_material(i, cam)

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
		var yon := 1.0 if ad == "DFL_8" else -1.0
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
