class_name Llave extends Area2D
## Se recoge al pasar por encima. Flota un poco para que se note.

signal recogida

@onready var sprite: Sprite2D = $Sprite2D
@onready var sonido: AudioStreamPlayer2D = $Sonido


func _ready() -> void:
	var flotar := create_tween().set_loops()
	flotar.tween_property(sprite, "position:y", -4.0, 0.6).set_trans(Tween.TRANS_SINE)
	flotar.tween_property(sprite, "position:y", 0.0, 0.6).set_trans(Tween.TRANS_SINE)


func _on_body_entered(cuerpo: Node2D) -> void:
	if not (cuerpo is Jugador and cuerpo.esta_vivo):
		return
	set_deferred("monitoring", false)
	hide()
	recogida.emit()
	sonido.play()
	if sonido.stream:
		await sonido.finished
	queue_free()
