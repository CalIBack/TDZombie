class_name Hud extends CanvasLayer
## Munición, enemigos, puntos, tiempo, pausa y pantallas de fin de nivel y de partida.

const TEXTOS_DERROTA := {
	Jugador.CAUSA_MORDIDA: "TE MORDIERON",
	Jugador.CAUSA_DISPARO: "TE DISPARARON",
}

@onready var label_nivel: Label = %LabelNivel
@onready var label_tiempo: Label = %LabelTiempo
@onready var label_puntos: Label = %LabelPuntos
@onready var label_enemigos: Label = %LabelEnemigos
@onready var label_municion: Label = %LabelMunicion
@onready var label_llave: Label = %LabelLlave
@onready var label_aviso: Label = %LabelAviso
@onready var panel_pausa: Control = %PanelPausa
@onready var panel_fin: Control = %PanelFin
@onready var titulo_fin: Label = %TituloFin
@onready var detalle_fin: Label = %DetalleFin
@onready var boton_continuar: Button = %BotonContinuar
@onready var boton_siguiente: Button = %BotonSiguiente
@onready var boton_reintentar: Button = %BotonReintentar
@onready var boton_ranking: Button = %BotonRanking
@onready var boton_menu_fin: Button = %BotonMenuFin
@onready var flash_rojo: ColorRect = %FlashRojo
@onready var sonido_victoria: AudioStreamPlayer = %SonidoVictoria
@onready var sonido_derrota: AudioStreamPlayer = %SonidoDerrota

var juego_terminado := false
var partida_terminada := false  ## murió o ganó el último nivel: R empieza otra
var _municion := 0
var _municion_maxima := 0


func configurar(numero: int, nombre: String) -> void:
	label_nivel.text = "NIVEL %d — %s" % [numero, nombre.to_upper()]


func actualizar_tiempo(segundos: float) -> void:
	label_tiempo.text = Juego.formatear_tiempo(segundos)


## "ganados" > 0 hace saltar el contador para que se note que sumaste.
func actualizar_puntos(total: int, ganados: int = 0) -> void:
	label_puntos.text = "%s   %d PTS" % [Juego.nombre_jugador, total] if Juego.nombre_jugador != "" else "%d PTS" % total
	if ganados <= 0:
		return
	label_puntos.pivot_offset = label_puntos.size / 2.0
	label_puntos.scale = Vector2(1.35, 1.35)
	label_puntos.modulate = Color(1, 0.85, 0.3)
	var tween := create_tween().set_parallel()
	tween.tween_property(label_puntos, "scale", Vector2.ONE, 0.3)
	tween.tween_property(label_puntos, "modulate", Color.WHITE, 0.5)


func actualizar_enemigos(vivos: int, total: int) -> void:
	label_enemigos.text = "ENEMIGOS  %d / %d" % [vivos, total]


func actualizar_municion(actual: int, maxima: int) -> void:
	_municion = actual
	_municion_maxima = maxima
	label_municion.text = "BALAS  %d / %d" % [actual, maxima]
	label_municion.modulate = Color(1, 0.3, 0.3) if actual == 0 else Color.WHITE


func mostrar_llave(tiene: bool, hace_falta: bool) -> void:
	label_llave.visible = hace_falta
	label_llave.text = "LLAVE  ✓" if tiene else "LLAVE  —"
	label_llave.modulate = Color(1, 0.8, 0.25) if tiene else Color(1, 1, 1, 0.5)


## Mensaje en el centro de la pantalla que se desvanece solo.
func avisar(texto: String) -> void:
	label_aviso.text = texto
	label_aviso.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_interval(1.5)
	tween.tween_property(label_aviso, "modulate:a", 0.0, 0.6)


func mostrar_recargando(recargando: bool) -> void:
	if recargando:
		label_municion.text = "RECARGANDO..."
		label_municion.modulate = Color(1, 0.85, 0.3)
	else:
		actualizar_municion(_municion, _municion_maxima)


func _unhandled_input(event: InputEvent) -> void:
	if not juego_terminado and event.is_action_pressed("pausa"):
		alternar_pausa()
		get_viewport().set_input_as_handled()
	elif partida_terminada and event.is_action_pressed("recargar"):
		Juego.empezar_partida(Juego.nombre_jugador)


func alternar_pausa() -> void:
	var pausado := not get_tree().paused
	get_tree().paused = pausado
	panel_pausa.visible = pausado
	if pausado:
		boton_continuar.grab_focus()


## Ganaste un nivel pero quedan más: los puntos y el tiempo siguen en el próximo.
func mostrar_nivel_superado(motivo: String) -> void:
	juego_terminado = true
	_mostrar_fin("NIVEL SUPERADO", Color(0.35, 1.0, 0.95))
	detalle_fin.text = "%s\n%s" % [motivo, _resumen_partida()]
	_mostrar_botones(true, false)
	sonido_victoria.play()
	boton_siguiente.grab_focus()


func mostrar_victoria_final(puesto: int) -> void:
	_terminar_partida()
	_mostrar_fin("¡GANASTE!", Color(1.0, 0.82, 0.25))
	detalle_fin.text = "%s\n%s" % [_resumen_partida(), _texto_puesto(puesto)]
	sonido_victoria.play()


func mostrar_derrota(causa: StringName, puesto: int) -> void:
	_terminar_partida()
	_mostrar_fin(TEXTOS_DERROTA.get(causa, "MORISTE"), Color(1.0, 0.25, 0.4))
	detalle_fin.text = "%s\n%s\n(%s para jugar de nuevo)" % [
		_resumen_partida(), _texto_puesto(puesto), _nombre_tecla("recargar")]
	sonido_derrota.play()
	var tween := create_tween()
	tween.tween_property(flash_rojo, "modulate:a", 0.55, 0.08)
	tween.tween_property(flash_rojo, "modulate:a", 0.25, 0.6)


func _terminar_partida() -> void:
	juego_terminado = true
	partida_terminada = true
	_mostrar_botones(false, true)
	boton_ranking.grab_focus()


func _mostrar_botones(siguiente: bool, fin_de_partida: bool) -> void:
	boton_siguiente.visible = siguiente
	boton_reintentar.visible = fin_de_partida
	boton_ranking.visible = fin_de_partida


func _resumen_partida() -> String:
	return "Puntos: %d     Tiempo: %s" % [Juego.puntos, Juego.formatear_tiempo(Juego.tiempo_partida)]


func _texto_puesto(puesto: int) -> String:
	if puesto == 1:
		return "★ ¡PRIMER PUESTO DEL RANKING! ★"
	if puesto > 0:
		return "Quedaste en el puesto %d del ranking" % puesto
	return "No entraste en el top %d" % Juego.LARGO_RANKING


func _mostrar_fin(titulo: String, color: Color) -> void:
	titulo_fin.text = titulo
	titulo_fin.modulate = color
	panel_fin.show()
	await get_tree().process_frame  # el Label necesita un frame para conocer su tamaño
	titulo_fin.pivot_offset = titulo_fin.size / 2.0
	titulo_fin.scale = Vector2(2.5, 2.5)
	create_tween().tween_property(titulo_fin, "scale", Vector2.ONE, 0.35) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _nombre_tecla(accion: StringName) -> String:
	for evento in InputMap.action_get_events(accion):
		if evento is InputEventKey:
			return OS.get_keycode_string(evento.physical_keycode)
	return "?"


#region Señales conectadas desde el editor

func _on_boton_continuar_pressed() -> void:
	alternar_pausa()


func _on_boton_menu_pressed() -> void:
	Juego.ir_al_menu()


func _on_boton_siguiente_pressed() -> void:
	Juego.ir_al_siguiente_nivel()


func _on_boton_reintentar_pressed() -> void:
	Juego.empezar_partida(Juego.nombre_jugador)


func _on_boton_ranking_pressed() -> void:
	Juego.ir_al_menu(true)

#endregion
