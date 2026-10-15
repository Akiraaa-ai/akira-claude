extends GPUParticles3D
## Oyuncunun etrafında yağan yağmur; oyuncuyu takip eder.
## İnce, yarı saydam, uçları yumuşak damlalar; çatı, ağaç ve arabanın altına yağmur girmez (yükseklik haritası çarpışması);
## yere düşen damlalar küçük sıçramalar yapar.
@export var hedef: Node3D

var _sicrama: GPUParticles3D
var _carpisma: GPUParticlesCollisionHeightField3D

func _ready() -> void:
	amount = 14000
	lifetime = 1.1
	preprocess = 1.2
	fixed_fps = 0
	visibility_aabb = AABB(Vector3(-24, -14, -24), Vector3(48, 18, 48))
	var m := ParticleProcessMaterial.new()
	m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	m.emission_box_extents = Vector3(22, 0.5, 22)
	m.direction = Vector3(0.06, -1, 0.02)
	m.spread = 1.5
	m.initial_velocity_min = 15.0
	m.initial_velocity_max = 19.0
	m.gravity = Vector3(0, -9.8, 0)
	m.scale_min = 0.6
	m.scale_max = 1.25
	m.collision_mode = ParticleProcessMaterial.COLLISION_HIDE_ON_CONTACT
	m.collision_use_scale = true
	process_material = m
	# damla: ince dikey şerit, üst ucu silik, alt ucu biraz daha belirgin
	var grad := Gradient.new()
	grad.set_color(0, Color(1, 1, 1, 0)); grad.set_color(1, Color(1, 1, 1, 0))
	grad.add_point(0.75, Color(1, 1, 1, 1))
	var doku := GradientTexture2D.new()
	doku.gradient = grad; doku.width = 4; doku.height = 64
	doku.fill_from = Vector2(0, 0); doku.fill_to = Vector2(0, 1)
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.62, 0.68, 0.78, 0.13)
	mat.albedo_texture = doku
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	mat.billboard_keep_scale = true
	mat.distance_fade_mode = BaseMaterial3D.DISTANCE_FADE_PIXEL_ALPHA
	mat.distance_fade_min_distance = 0.3
	mat.distance_fade_max_distance = 1.6
	var q := QuadMesh.new(); q.size = Vector2(0.007, 0.55); q.material = mat
	draw_pass_1 = q
	_carpisma_kur()
	_sicrama_kur()

# çatıların, sundurmaların ve arabanın altına yağmur yağmasın
func _carpisma_kur() -> void:
	_carpisma = GPUParticlesCollisionHeightField3D.new()
	_carpisma.size = Vector3(48, 40, 48)
	_carpisma.resolution = GPUParticlesCollisionHeightField3D.RESOLUTION_512
	_carpisma.update_mode = GPUParticlesCollisionHeightField3D.UPDATE_MODE_ALWAYS
	_carpisma.follow_camera_enabled = true
	add_child.call_deferred(_carpisma)

# yere değen damlaların küçük sıçramaları
func _sicrama_kur() -> void:
	_sicrama = GPUParticles3D.new()
	_sicrama.amount = 2500
	_sicrama.lifetime = 0.22
	_sicrama.visibility_aabb = AABB(Vector3(-16, -2, -16), Vector3(32, 4, 32))
	var m := ParticleProcessMaterial.new()
	m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	m.emission_box_extents = Vector3(14, 0.0, 14)
	m.direction = Vector3(0, 1, 0)
	m.spread = 70.0
	m.initial_velocity_min = 0.4
	m.initial_velocity_max = 1.1
	m.gravity = Vector3(0, -6, 0)
	m.scale_min = 0.5; m.scale_max = 1.0
	var egri := CurveTexture.new(); var c := Curve.new()
	c.add_point(Vector2(0, 0.3)); c.add_point(Vector2(0.3, 1.0)); c.add_point(Vector2(1, 0.0))
	egri.curve = c
	m.scale_curve = egri
	_sicrama.process_material = m
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.7, 0.75, 0.85, 0.22)
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	var grad := Gradient.new()
	grad.set_color(0, Color(1, 1, 1, 1)); grad.set_color(1, Color(1, 1, 1, 0))
	var doku := GradientTexture2D.new()
	doku.gradient = grad; doku.fill = GradientTexture2D.FILL_RADIAL
	doku.fill_from = Vector2(0.5, 0.5); doku.fill_to = Vector2(0.5, 0.0)
	mat.albedo_texture = doku
	var q := QuadMesh.new(); q.size = Vector2(0.05, 0.05); q.material = mat
	_sicrama.draw_pass_1 = q
	add_child.call_deferred(_sicrama)

func _process(_dt: float) -> void:
	if hedef == null: return
	global_position = hedef.global_position + Vector3(0, 9, 0)
	if _sicrama and _sicrama.is_inside_tree():
		# sıçramalar yerde (oyuncunun ayak hizası), yağmur kalkanı olan yerlerde de görünse de küçük oldukları için sorun olmaz
		_sicrama.global_position = Vector3(hedef.global_position.x, hedef.global_position.y + 0.04, hedef.global_position.z)
