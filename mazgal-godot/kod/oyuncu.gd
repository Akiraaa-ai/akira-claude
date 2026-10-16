extends CharacterBody3D
## Selim: birinci şahıs yürüme, koşma (Shift), eğilme (Ctrl), fener (F), kafa sallanması.

@export var yurume := 2.6
@export var kosma := 5.2
@export var egilme := 1.3
@export var fare_hassas := 0.0022

@onready var kafa: Node3D = $Kafa
@onready var kamera: Camera3D = $Kafa/Kamera
@onready var fener: SpotLight3D = $Kafa/Kamera/Fener
@onready var adim: AudioStreamPlayer3D = $Adim

const BOY := 1.51
const EGIK_BOY := 0.95
var yercekimi: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var salinim := 0.0
var adim_sayac := 0.0
## Fener elde değilse ya da pili yoksa F bir şey yapmaz; sahne bunu duyup kısa bir yazı gösterebilir.
var fener_izin := true
signal fener_bos

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var h := fare_hassas * _fare_carpani()
		rotate_y(-e.relative.x * h)
		var d := get_node_or_null("/root/Duraklat")
		kafa.rotate_x(-e.relative.y * h * (-1.0 if d and d.get("ters_y") == true else 1.0))
		kafa.rotation.x = clamp(kafa.rotation.x, deg_to_rad(-85), deg_to_rad(85))
	elif e.is_action_pressed("fener"):
		if not fener_izin:
			fener_bos.emit()
			return
		fener.visible = not fener.visible
		_fener_tik()
	elif e is InputEventMouseButton and e.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

# el feneri düğmesi (sesler/fener.mp3)
var _fener_ses: AudioStreamPlayer
func _fener_tik() -> void:
	if not ResourceLoader.exists("res://sesler/fener.mp3"): return
	if _fener_ses == null:
		_fener_ses = AudioStreamPlayer.new()
		_fener_ses.stream = load("res://sesler/fener.mp3")
		_fener_ses.volume_db = -6.0
		add_child(_fener_ses)
	_fener_ses.pitch_scale = 1.0 if fener.visible else 0.92
	_fener_ses.play()

# duraklatma menüsündeki fare hassasiyeti ayarı
func _fare_carpani() -> float:
	var d := get_node_or_null("/root/Duraklat")
	return float(d.fare) if d else 1.0

func _physics_process(dt: float) -> void:
	if not is_on_floor():
		velocity.y -= yercekimi * dt
	var egik := Input.is_action_pressed("egil")
	var hiz := egilme if egik else (kosma if Input.is_action_pressed("kos") else yurume)
	var g := Input.get_vector("sol", "sag", "ileri", "geri")
	var yon := (transform.basis * Vector3(g.x, 0, g.y)).normalized()
	velocity.x = lerp(velocity.x, yon.x * hiz, min(1.0, dt * 10))
	velocity.z = lerp(velocity.z, yon.z * hiz, min(1.0, dt * 10))
	move_and_slide()

	# kafa yüksekliği ve yürürken sallanma (bodycam hissi)
	var yatay := Vector2(velocity.x, velocity.z).length()
	salinim += dt * yatay * 2.2
	var hedef: float = (EGIK_BOY if egik else BOY) + sin(salinim * 2.0) * 0.035 * min(1.0, yatay / 3.0)
	kafa.position.y = lerp(kafa.position.y, hedef, min(1.0, dt * 8))
	kamera.rotation.z = sin(salinim) * 0.012 * min(1.0, yatay / 3.0)

	# adım sesi
	if is_on_floor() and yatay > 0.5:
		adim_sayac -= dt * yatay
		if adim_sayac <= 0:
			adim_sayac = 1.6
			if adim.stream: adim.pitch_scale = randf_range(0.9, 1.1); adim.play()
