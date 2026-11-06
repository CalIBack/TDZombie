extends EstadoJugador
## Quieto o caminando: apunta, dispara y puede pasar a recargar.


func fisica(delta: float) -> void:
	moverse_y_apuntar(delta)

	if jugador.quiere_recargar():
		maquina.cambiar_a(NombresEstados.RECARGANDO)
		return

	if jugador.quiere_disparar():
		# Gatillar vacío suena el "click" y recarga sola.
		if jugador.intentar_disparar() == Jugador.ResultadoDisparo.SIN_BALAS:
			maquina.cambiar_a(NombresEstados.RECARGANDO)
