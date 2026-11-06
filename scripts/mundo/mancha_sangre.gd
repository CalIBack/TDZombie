class_name ManchaSangre extends Node2D
## Mancha en el piso dibujada con círculos al azar.

const COLOR := Color(0.45, 0.0, 0.04, 0.85)

var tamanio := 1.0
var _gotas: Array[Vector3] = []  # x, y, radio


func _ready() -> void:
	_gotas.append(Vector3(0, 0, randf_range(12, 16) * tamanio))
	for i in randi_range(5, 9):
		var pos := Vector2.from_angle(randf() * TAU) * randf_range(8, 26) * tamanio
		_gotas.append(Vector3(pos.x, pos.y, randf_range(3, 8) * tamanio))
	scale = Vector2.ZERO
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.25) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _draw() -> void:
	for g in _gotas:
		draw_circle(Vector2(g.x, g.y), g.z, COLOR)
