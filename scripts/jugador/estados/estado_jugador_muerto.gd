extends EstadoJugador
## Suelta el arma, se oscurece, se desliza un poco y deja de chocar con todo.


func entrar() -> void:
	jugador.usar_textura(jugador.textura_sin_arma)
	jugador.sonido_muerte.play()
	jugador.set_deferred("collision_layer", 0)
	Efectos.dejar_mancha(jugador, jugador.global_position, 1.2)
	var tween := jugador.create_tween()
	tween.tween_property(jugador.sprite, "modulate", Color(0.55, 0.35, 0.35), 0.3)


func fisica(delta: float) -> void:
	jugador.velocity = jugador.velocity.move_toward(Vector2.ZERO, 900.0 * delta)
	jugador.move_and_slide()
