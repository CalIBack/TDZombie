extends EstadoTirador
## Va a la última posición conocida, mira alrededor un rato y vuelve a la guardia.

const TIEMPO_MIRANDO := 2.0
const VELOCIDAD_MIRAR := 2.5  ## rad/s

var _mirando := 0.0
var _en_camino := 0.0
var _destino := Vector2.ZERO


func entrar() -> void:
	_reiniciar()


func _reiniciar() -> void:
	_mirando = 0.0
	_en_camino = 0.0
	_destino = tirador.ultima_posicion_conocida
	tirador.fijar_destino(_destino)


func fisica(delta: float) -> void:
	if tirador.ve_al_jugador():
		maquina.cambiar_a(NombresEstados.ATACANDO)
		return

	# Escuchó otro disparo mientras buscaba: cambia de rumbo.
	if tirador.ultima_posicion_conocida.distance_to(_destino) > 32.0:
		_reiniciar()

	if _mirando > 0.0:
		_mirar_alrededor(delta)
		return

	_en_camino += delta
	var destino := _destino
	tirador.avanzar_hacia(destino, delta)

	# Margen inicial: el agente tarda un frame en marcar la ruta como no terminada.
	var llego := tirador.global_position.distance_to(destino) < 16.0 \
		or (_en_camino > 0.2 and tirador.llego_al_destino())
	if llego:
		_mirando = TIEMPO_MIRANDO


func _mirar_alrededor(delta: float) -> void:
	tirador.frenar(delta)
	tirador.rotation += sin(_mirando * 3.0) * VELOCIDAD_MIRAR * delta
	_mirando -= delta
	if _mirando <= 0.0:
		maquina.cambiar_a(NombresEstados.GUARDIA)
