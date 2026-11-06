class_name Camara extends Camera2D
## Sigue al objetivo adelantándose hacia el mouse, y tiembla con los disparos.

@export var objetivo: Node2D
@export_range(0.0, 1.0) var adelanto_mouse := 0.3
@export var suavizado := 8.0
@export var recuperacion_temblor := 30.0

var _temblor := 0.0


func _ready() -> void:
	if objetivo:
		global_position = objetivo.global_position


func _process(delta: float) -> void:
	if not is_instance_valid(objetivo):
		return
	var viewport := get_viewport()
	var desde_centro := viewport.get_mouse_position() - viewport.get_visible_rect().size / 2.0
	var destino := objetivo.global_position + desde_centro * adelanto_mouse / zoom
	global_position = global_position.lerp(destino, 1.0 - exp(-suavizado * delta))

	if _temblor > 0.0:
		offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _temblor
		_temblor = move_toward(_temblor, 0.0, recuperacion_temblor * delta)
	else:
		offset = Vector2.ZERO


func sacudir(fuerza: float) -> void:
	_temblor = maxf(_temblor, fuerza)
