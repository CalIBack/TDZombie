class_name EstadoJugador extends Estado

var jugador: Jugador:
	get:
		return actor as Jugador


func moverse_y_apuntar(delta: float) -> Vector2:
	jugador.apuntar()
	var direccion := jugador.leer_direccion()
	jugador.mover(delta, direccion)
	return direccion
