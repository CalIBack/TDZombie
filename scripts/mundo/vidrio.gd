class_name Vidrio extends StaticBody2D
## Panel de vidrio de 32 px. Frena el paso y el sonido, pero deja ver.
## Se rompe con una bala o cuando un enemigo lo empuja al caminar.
## Para una pared vertical, rotalo 90°.

signal roto

@onready var panel: Node2D = $Panel
@onready var colision: CollisionShape2D = $CollisionShape2D
@onready var restos: Node2D = $Restos
@onready var sonido: AudioStreamPlayer2D = $Sonido

var esta_roto := false


## Así lo trata la bala: igual que a un enemigo.
func recibir_danio(_cantidad: int, direccion: Vector2) -> void:
	romper(direccion)


func romper(direccion: Vector2 = Vector2.ZERO) -> void:
	if esta_roto:
		return
	esta_roto = true
	panel.hide()
	set_deferred("collision_layer", 0)
	colision.set_deferred("disabled", true)
	sonido.play()
	Efectos.vidrio_roto(self, global_position, direccion)
	_desparramar_restos(direccion)
	roto.emit()


## Los pedacitos (Restos) salen un poco hacia donde iba el golpe y quedan en el piso.
func _desparramar_restos(direccion: Vector2) -> void:
	restos.show()
	var empuje := direccion.normalized() * 10.0
	for pedazo: Node2D in restos.get_children():
		var destino := pedazo.position + empuje + Vector2(randf_range(-6, 6), randf_range(-6, 6))
		pedazo.rotation = randf() * TAU
		create_tween().tween_property(pedazo, "position", destino, 0.2).set_ease(Tween.EASE_OUT)
