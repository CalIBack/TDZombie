extends Estado
## El cuerpo queda oscurecido en el piso, sin colisiones.

var enemigo: Enemigo:
	get:
		return actor as Enemigo


func entrar() -> void:
	enemigo.sonido_muerte.play()
	enemigo.desactivar_cuerpo()
	var tween := enemigo.create_tween().set_parallel()
	tween.tween_property(enemigo.sprite, "self_modulate", Color(0.45, 0.3, 0.3), 0.25)
	tween.tween_property(enemigo.visual, "scale", enemigo.visual.scale * 0.85, 0.25)


func fisica(delta: float) -> void:
	enemigo.frenar(delta)
