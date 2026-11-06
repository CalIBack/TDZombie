extends Estado
## Portazo: no se mueve ni ataca hasta que pasa el tiempo. El sprite tambalea.

var enemigo: Enemigo:
	get:
		return actor as Enemigo

var _tambaleo: Tween


func entrar() -> void:
	enemigo.sonido_golpe_puerta.play()
	enemigo.parpadear()
	_tambaleo = enemigo.create_tween().set_loops()
	_tambaleo.tween_property(enemigo.visual, "rotation", 0.35, 0.12)
	_tambaleo.tween_property(enemigo.visual, "rotation", -0.35, 0.12)


func fisica(delta: float) -> void:
	enemigo.frenar(delta)
	enemigo.tiempo_aturdido -= delta
	if enemigo.tiempo_aturdido <= 0.0:
		maquina.cambiar_a(enemigo.estado_tras_aturdimiento())


func salir() -> void:
	if _tambaleo:
		_tambaleo.kill()
	enemigo.visual.rotation = 0.0
