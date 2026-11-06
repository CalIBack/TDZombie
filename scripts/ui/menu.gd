extends Control
## Menú principal: jugar (primero pide el nombre), ranking, opciones y salir.

@export var musica: AudioStream

@onready var panel_principal: Control = %PanelPrincipal
@onready var panel_nombre: Control = %PanelNombre
@onready var panel_ranking: Control = %PanelRanking
@onready var panel_opciones: Control = %PanelOpciones
@onready var boton_jugar: Button = %BotonJugar
@onready var campo_nombre: LineEdit = %CampoNombre
@onready var boton_empezar: Button = %BotonEmpezar
@onready var ranking: Ranking = %Ranking
@onready var boton_volver_ranking: Button = %BotonVolverRanking
@onready var slider_general: HSlider = %SliderGeneral
@onready var slider_musica: HSlider = %SliderMusica
@onready var slider_efectos: HSlider = %SliderEfectos
@onready var valor_general: Label = %ValorGeneral
@onready var valor_musica: Label = %ValorMusica
@onready var valor_efectos: Label = %ValorEfectos
@onready var sonido_prueba: AudioStreamPlayer = %SonidoPrueba


func _ready() -> void:
	get_tree().paused = false
	Juego.reproducir_musica(musica)

	slider_general.set_value_no_signal(Juego.volumen_general * 100.0)
	slider_musica.set_value_no_signal(Juego.volumen_musica * 100.0)
	slider_efectos.set_value_no_signal(Juego.volumen_efectos * 100.0)
	_actualizar_porcentajes()

	# Al terminar una partida se vuelve acá con el ranking abierto y tu puesto marcado.
	if Juego.abrir_ranking_en_menu:
		Juego.abrir_ranking_en_menu = false
		_abrir(panel_ranking)
		ranking.mostrar(Juego.ultimo_puesto)
		boton_volver_ranking.grab_focus()
	else:
		boton_jugar.grab_focus()


func _abrir(panel: Control) -> void:
	for p in [panel_principal, panel_nombre, panel_ranking, panel_opciones]:
		p.visible = p == panel


func _empezar() -> void:
	var nombre := Juego.limpiar_nombre(campo_nombre.text)
	if nombre.is_empty():
		return
	Juego.empezar_partida(nombre)


func _actualizar_porcentajes() -> void:
	valor_general.text = "%d%%" % slider_general.value
	valor_musica.text = "%d%%" % slider_musica.value
	valor_efectos.text = "%d%%" % slider_efectos.value


#region Señales conectadas desde el editor

func _on_boton_jugar_pressed() -> void:
	_abrir(panel_nombre)
	campo_nombre.text = Juego.nombre_jugador  # el último que jugó, para no reescribirlo
	_on_campo_nombre_text_changed(campo_nombre.text)
	campo_nombre.grab_focus()
	campo_nombre.select_all()


func _on_campo_nombre_text_changed(texto: String) -> void:
	boton_empezar.disabled = Juego.limpiar_nombre(texto).is_empty()


func _on_campo_nombre_text_submitted(_texto: String) -> void:
	_empezar()


func _on_boton_empezar_pressed() -> void:
	_empezar()


func _on_boton_ranking_pressed() -> void:
	_abrir(panel_ranking)
	ranking.mostrar()
	boton_volver_ranking.grab_focus()


func _on_boton_opciones_pressed() -> void:
	_abrir(panel_opciones)
	slider_general.grab_focus()


func _on_boton_volver_pressed() -> void:
	Juego.grabar()
	_abrir(panel_principal)
	boton_jugar.grab_focus()


func _on_boton_salir_pressed() -> void:
	get_tree().quit()


func _on_slider_general_value_changed(valor: float) -> void:
	Juego.volumen_general = valor / 100.0
	Juego.aplicar_volumenes()
	_actualizar_porcentajes()


func _on_slider_musica_value_changed(valor: float) -> void:
	Juego.volumen_musica = valor / 100.0
	Juego.aplicar_volumenes()
	_actualizar_porcentajes()


func _on_slider_efectos_value_changed(valor: float) -> void:
	Juego.volumen_efectos = valor / 100.0
	Juego.aplicar_volumenes()
	_actualizar_porcentajes()
	sonido_prueba.play()

#endregion
