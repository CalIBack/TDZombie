class_name Meta extends Area2D

signal jugador_llego


func _on_body_entered(cuerpo: Node2D) -> void:
	if cuerpo is Jugador and cuerpo.esta_vivo:
		jugador_llego.emit()
