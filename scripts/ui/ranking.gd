class_name Ranking extends VBoxContainer
## Muestra el ranking de Juego: los 3 primeros en el podio y del 4.° al 10.° en una lista.
## Los colores del podio (oro, plata, bronce) están en cada Label de la escena.

@onready var _podio: Array[Control] = [%Primero, %Segundo, %Tercero]
@onready var lista: GridContainer = %Lista
@onready var label_vacio: Label = %LabelVacio


## "resaltar" es el puesto de la última partida (1 a 10), o -1 para no marcar ninguno.
func mostrar(resaltar: int = -1) -> void:
	var tabla := Juego.ranking
	for i in _podio.size():
		_llenar_escalon(_podio[i], tabla[i] if i < tabla.size() else {}, i + 1 == resaltar)

	for celda in lista.get_children():
		lista.remove_child(celda)
		celda.queue_free()
	for i in range(_podio.size(), tabla.size()):
		_agregar_fila(i + 1, tabla[i], i + 1 == resaltar)

	label_vacio.visible = tabla.is_empty()


func _llenar_escalon(escalon: Control, entrada: Dictionary, es_tuya: bool) -> void:
	var nombre: Label = escalon.get_node("Nombre")
	var puntos: Label = escalon.get_node("Puntos")
	var tiempo: Label = escalon.get_node("Tiempo")
	if entrada.is_empty():
		nombre.text = "—"
		puntos.text = ""
		tiempo.text = ""
		return
	nombre.text = ("► %s ◄" if es_tuya else "%s") % entrada.nombre
	puntos.text = "%d PTS" % entrada.puntos
	tiempo.text = Juego.formatear_tiempo(entrada.tiempo)


func _agregar_fila(puesto: int, entrada: Dictionary, es_tuya: bool) -> void:
	var textos := [
		"%d." % puesto,
		entrada.nombre,
		"%d PTS" % entrada.puntos,
		Juego.formatear_tiempo(entrada.tiempo),
	]
	for i in textos.size():
		var celda := Label.new()
		celda.text = textos[i]
		celda.add_theme_font_size_override("font_size", 20)
		if i == 1:
			celda.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if i >= 2:
			celda.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		if es_tuya:
			celda.add_theme_color_override("font_color", Color(0.35, 1.0, 0.95))
		lista.add_child(celda)
