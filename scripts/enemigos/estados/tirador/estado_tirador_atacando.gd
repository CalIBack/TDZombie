extends EstadoTirador
## Tiene al jugador a la vista: se queda quieto, gira hacia él y dispara ráfagas.

const TOLERANCIA_PERDIDA := 0.3  ## segundos sin verlo antes de ir a buscarlo

var _reaccion := 0.0
var _hasta_disparo := 0.0
var _balas_en_rafaga := 0
var _sin_ver := 0.0


func entrar() -> void:
	_reaccion = tirador.tiempo_reaccion
	_hasta_disparo = 0.0
	_balas_en_rafaga = tirador.balas_por_rafaga
	_sin_ver = 0.0


func salir() -> void:
	tirador.mostrar_laser(false)


func fisica(delta: float) -> void:
	tirador.frenar(delta)
	if not tirador.jugador_disponible():
		maquina.cambiar_a(NombresEstados.GUARDIA)
		return

	if not tirador.ve_al_jugador():
		_sin_ver += delta
		tirador.mostrar_laser(true)
		if _sin_ver >= TOLERANCIA_PERDIDA:
			maquina.cambiar_a(NombresEstados.BUSCANDO)
		return

	_sin_ver = 0.0
	tirador.mostrar_laser(true)
	tirador.ultima_posicion_conocida = tirador.jugador.global_position
	var angulo := tirador.global_position.direction_to(tirador.jugador.global_position).angle()
	tirador.girar_hacia(angulo, delta, 1.5)

	if _reaccion > 0.0:
		_reaccion -= delta
		return

	_hasta_disparo -= delta
	if _hasta_disparo > 0.0 or not tirador.apunta_al_jugador():
		return

	if _balas_en_rafaga > 0:
		tirador.disparar()
		_balas_en_rafaga -= 1
		_hasta_disparo = tirador.cadencia
	else:
		_balas_en_rafaga = tirador.balas_por_rafaga
		_hasta_disparo = tirador.pausa_entre_rafagas
