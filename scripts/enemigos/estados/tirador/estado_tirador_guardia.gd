extends EstadoTirador
## Sin ruta: vuelve a su puesto y mira hacia donde miraba al empezar.
## Con ruta: recorre los Marker2D en orden, esperando un rato en cada uno.

var _indice := 0
var _espera := 0.0


func entrar() -> void:
	_espera = 0.0


func fisica(delta: float) -> void:
	if tirador.ve_al_jugador():
		maquina.cambiar_a(NombresEstados.ATACANDO)
		return

	if tirador.ruta_patrulla.is_empty():
		_volver_al_puesto(delta)
	else:
		_patrullar(delta)


func _volver_al_puesto(delta: float) -> void:
	if tirador.global_position.distance_to(tirador.posicion_inicial) > 10.0:
		tirador.ir_hacia(tirador.posicion_inicial, delta, tirador.velocidad_patrulla)
	else:
		tirador.frenar(delta)
		tirador.girar_hacia(tirador.rotacion_inicial, delta, 0.5)


func _patrullar(delta: float) -> void:
	if _espera > 0.0:
		_espera -= delta
		tirador.frenar(delta)
		return
	var punto := tirador.ruta_patrulla[_indice]
	if not is_instance_valid(punto):
		_siguiente_punto()
		return
	if tirador.global_position.distance_to(punto.global_position) < 10.0:
		_espera = tirador.espera_en_punto
		_siguiente_punto()
		return
	tirador.ir_hacia(punto.global_position, delta, tirador.velocidad_patrulla)


func _siguiente_punto() -> void:
	_indice = (_indice + 1) % tirador.ruta_patrulla.size()
