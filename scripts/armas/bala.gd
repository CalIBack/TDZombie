class_name Bala extends Node2D
## Rectángulo dibujado por código. Avanza con un rayo por frame (intersect_ray):
## a esta velocidad un Area2D podría saltarse una pared fina, el rayo nunca.
## No necesita escena: se crea con Bala.new().

var velocidad := 1500.0
var danio := 1
var alcance := 1800.0
var largo := 14.0
var ancho := 3.0
var color := Color(1.0, 0.95, 0.6)

var direccion := Vector2.RIGHT
var mascara := 0

var _origen_rayo := Vector2.INF
var _recorrido := 0.0
var _ignorar: Array[RID] = []  # vidrios que ya rompió esta bala


## Llamar justo DESPUÉS de add_child. "origen_rayo" es desde dónde sale el primer rayo
## (el centro del que dispara), para no atravesar una pared si el arma quedó metida en ella.
func preparar(posicion: Vector2, dir: Vector2, mascara_colision: int, origen_rayo: Vector2) -> void:
	global_position = posicion
	direccion = dir.normalized()
	mascara = mascara_colision
	_origen_rayo = origen_rayo
	global_rotation = direccion.angle()


func _draw() -> void:
	draw_rect(Rect2(-largo, -ancho / 2.0, largo, ancho), color)


func _physics_process(delta: float) -> void:
	var paso := direccion * velocidad * delta
	var desde := global_position
	if _origen_rayo != Vector2.INF:
		desde = _origen_rayo
		_origen_rayo = Vector2.INF
	var hasta := global_position + paso

	var consulta := PhysicsRayQueryParameters2D.create(desde, hasta, mascara, _ignorar)
	var impacto := get_world_2d().direct_space_state.intersect_ray(consulta)
	if impacto and impacto.collider is Vidrio:
		# Rompe el vidrio y sigue: el próximo frame el rayo ya no lo ve.
		impacto.collider.romper(direccion)
		_ignorar.append(impacto.rid)
	elif impacto:
		_impactar(impacto)
		return

	global_position = hasta
	_recorrido += paso.length()
	if _recorrido >= alcance:
		queue_free()


func _impactar(impacto: Dictionary) -> void:
	global_position = impacto.position
	Efectos.estallido(self, global_position, impacto.normal, 0.8)
	var objetivo: Object = impacto.collider
	if objetivo.has_method("recibir_danio"):
		objetivo.recibir_danio(danio, direccion)
	queue_free()
