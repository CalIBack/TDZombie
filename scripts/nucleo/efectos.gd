class_name Efectos
## Efectos generados por código: nada de escenas ni texturas.

const AMARILLO := Color(1.0, 0.85, 0.3)
const SANGRE := Color(0.6, 0.0, 0.05)


## Pequeño estallido amarillo: fogonazo del arma e impacto de bala.
static func estallido(referencia: Node, posicion: Vector2, direccion: Vector2, tamanio: float = 1.0) -> void:
	if not referencia.is_inside_tree():
		return
	var destello := Estallido.new()
	destello.radio = 7.0 * tamanio
	referencia.get_tree().current_scene.add_child(destello)
	destello.global_position = posicion
	destello.global_rotation = direccion.angle()

	var p := _particulas(referencia, posicion, 6, AMARILLO)
	p.lifetime = 0.2
	p.direction = direccion if direccion != Vector2.ZERO else Vector2.RIGHT
	p.spread = 45.0
	p.initial_velocity_min = 90.0 * tamanio
	p.initial_velocity_max = 220.0 * tamanio
	p.scale_amount_min = 1.5
	p.scale_amount_max = 3.0
	p.emitting = true


static func sangre(referencia: Node, posicion: Vector2, direccion: Vector2, cantidad: int) -> void:
	if not referencia.is_inside_tree():
		return
	var p := _particulas(referencia, posicion, cantidad, SANGRE)
	p.lifetime = 0.45
	p.direction = direccion if direccion != Vector2.ZERO else Vector2.RIGHT
	p.spread = 35.0
	p.initial_velocity_min = 120.0
	p.initial_velocity_max = 320.0
	p.damping_min = 400.0
	p.damping_max = 600.0
	p.scale_amount_min = 3.0
	p.scale_amount_max = 6.0
	p.emitting = true


static func vidrio_roto(referencia: Node, posicion: Vector2, direccion: Vector2) -> void:
	if not referencia.is_inside_tree():
		return
	var p := _particulas(referencia, posicion, 14, Color(0.7, 0.9, 1.0))
	p.lifetime = 0.35
	p.direction = direccion if direccion != Vector2.ZERO else Vector2.RIGHT
	p.spread = 70.0
	p.initial_velocity_min = 60.0
	p.initial_velocity_max = 220.0
	p.damping_min = 300.0
	p.damping_max = 500.0
	p.scale_amount_min = 1.5
	p.scale_amount_max = 3.5
	p.emitting = true


static func dejar_mancha(referencia: Node, posicion: Vector2, tamanio: float = 1.0) -> void:
	if not referencia.is_inside_tree():
		return
	var mancha := ManchaSangre.new()
	mancha.tamanio = tamanio
	var contenedor := referencia.get_tree().get_first_node_in_group("manchas")
	if contenedor == null:
		contenedor = referencia.get_tree().current_scene
	contenedor.add_child(mancha)
	mancha.global_position = posicion


static func _particulas(referencia: Node, posicion: Vector2, cantidad: int, color: Color) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.one_shot = true
	p.emitting = false
	p.amount = cantidad
	p.explosiveness = 1.0
	p.color = color
	p.finished.connect(p.queue_free)
	referencia.get_tree().current_scene.add_child(p)
	p.global_position = posicion
	return p
