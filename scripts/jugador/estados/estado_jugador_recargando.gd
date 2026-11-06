extends EstadoJugador
## Se mueve y apunta, pero no dispara hasta terminar.

var _restante := 0.0


func entrar() -> void:
	_restante = jugador.tiempo_recarga
	jugador.empezar_recarga()


func fisica(delta: float) -> void:
	moverse_y_apuntar(delta)
	_restante -= delta
	if _restante <= 0.0:
		jugador.terminar_recarga()
		maquina.cambiar_a(NombresEstados.NORMAL)


func salir() -> void:
	if _restante > 0.0:
		jugador.cancelar_recarga()
