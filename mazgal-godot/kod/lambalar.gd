extends Node3D
## Ana cadde ve ara sokak boyunca sarı sodyum sokak lambası ışıkları.
const YOLLAR := [
	[Vector3(-110, 0, -5.5), Vector3(35, 0, -5.5)],
	[Vector3(-66, 0, -90), Vector3(-66, 0, -8)],
]
func _ready() -> void:
	for y in YOLLAR:
		var a: Vector3 = y[0]; var b: Vector3 = y[1]
		var n := int(a.distance_to(b) / 28.0)
		for i in n + 1:
			var l := OmniLight3D.new()
			l.position = a.lerp(b, float(i) / max(1, n)) + Vector3(0, 6.5, 0)
			l.light_color = Color(1.0, 0.68, 0.32)
			l.light_energy = 2.2
			l.omni_range = 16.0
			l.omni_attenuation = 1.4
			l.shadow_enabled = i % 2 == 0
			add_child(l)
