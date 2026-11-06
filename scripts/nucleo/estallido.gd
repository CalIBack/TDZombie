class_name Estallido extends Node2D
## Destello en forma de estrella que crece y se desvanece en pocos frames.

const DURACION := 0.09

var radio := 7.0
var color := Color(1.0, 0.9, 0.35)
var _t := 0.0


func _ready() -> void:
	z_index = 10
	# Brilla aunque esté fuera del cono de visión: así ves los fogonazos en la oscuridad.
	var material_sin_luz := CanvasItemMaterial.new()
	material_sin_luz.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	material = material_sin_luz
	rotation += randf_range(-0.3, 0.3)


func _process(delta: float) -> void:
	_t += delta
	if _t >= DURACION:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var avance := _t / DURACION
	var r := radio * (0.6 + avance * 0.8)
	var c := color
	c.a = 1.0 - avance
	var puntas := PackedVector2Array()
	for i in 10:
		var largo := r * (1.6 if i == 0 else 1.0) if i % 2 == 0 else r * 0.4
		puntas.append(Vector2.RIGHT.rotated(TAU * i / 10.0) * largo)
	draw_colored_polygon(puntas, c)
	draw_circle(Vector2.ZERO, r * 0.35, Color(1, 1, 1, c.a))
