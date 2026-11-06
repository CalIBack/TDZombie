class_name Nivel extends Node2D
## Script compartido por todos los niveles: cuenta enemigos, suma puntos y decide victoria/derrota.
## Los puntos y el tiempo se guardan en Juego, así pasan al nivel siguiente.
## Se gana solo saliendo por la Salida (con la llave, si salida_requiere_llave está marcado).
## Matar enemigos no gana: el contador del HUD es informativo.
## La navegación se hornea en el editor: seleccioná "Navegacion" > Bake NavigationPolygon.

@export var nombre := "La Casa"
@export var musica: AudioStream
@export var salida_requiere_llave := true  ## la Meta solo funciona si recogiste la Llave
@export var radio_ruido_disparo := 550.0  ## a esta distancia se oye un disparo (salvo tras un vidrio)

@onready var contenedor_enemigos: Node2D = $Enemigos
@onready var jugador: Jugador = $Jugador
@onready var camara: Camara = $Camara
@onready var hud: Hud = $HUD

var total_enemigos := 0
var enemigos_vivos := 0
var tiempo := 0.0
var terminado := false
var tiene_llave := false


func _ready() -> void:
	# El número sale del orden de Juego.NIVELES (así también anda si lo abrís con F6).
	var indice := Juego.NIVELES.find(scene_file_path)
	if indice != -1:
		Juego.nivel_actual = indice + 1
	Juego.reproducir_musica(musica)

	# Busca en todo lo que cuelga de Enemigos, así podés ordenarlos en subcarpetas (Tiradores, Zombies...).
	for enemigo in _enemigos_dentro(contenedor_enemigos):
		total_enemigos += 1
		enemigo.murio.connect(_on_enemigo_murio)
		enemigo.hizo_ruido.connect(propagar_ruido)
	enemigos_vivos = total_enemigos

	hud.configurar(Juego.nivel_actual, nombre)
	hud.mostrar_llave(false, salida_requiere_llave)
	hud.actualizar_enemigos(enemigos_vivos, total_enemigos)
	hud.actualizar_puntos(Juego.puntos)


func _enemigos_dentro(nodo: Node) -> Array[Enemigo]:
	var lista: Array[Enemigo] = []
	for hijo in nodo.get_children():
		if hijo is Enemigo:
			lista.append(hijo)
		else:
			lista.append_array(_enemigos_dentro(hijo))
	return lista


func _process(delta: float) -> void:
	if terminado:
		return
	tiempo += delta
	hud.actualizar_tiempo(Juego.tiempo_partida + tiempo)


func _on_jugador_disparo_hecho(posicion: Vector2) -> void:
	camara.sacudir(4.0)
	propagar_ruido(posicion)


## Un disparo (tuyo o de un tirador) despierta a los zombies y alerta a los tiradores cercanos.
func propagar_ruido(posicion: Vector2) -> void:
	for nodo in get_tree().get_nodes_in_group("enemigos"):
		var enemigo := nodo as Enemigo
		if enemigo == null or not enemigo.esta_vivo:
			continue
		if enemigo.global_position.distance_to(posicion) <= radio_ruido_disparo and enemigo.escucha(posicion):
			enemigo.oir_ruido(posicion)


func _on_jugador_murio(causa: StringName) -> void:
	if terminado:
		return
	terminado = true
	camara.sacudir(14.0)
	Juego.sumar_tiempo(tiempo)
	hud.mostrar_derrota(causa, Juego.terminar_partida())


func _on_meta_jugador_llego() -> void:
	if salida_requiere_llave and not tiene_llave:
		hud.avisar("NECESITÁS LA LLAVE")
		return
	ganar("¡LLEGASTE A LA SALIDA!")


func _on_llave_recogida() -> void:
	tiene_llave = true
	hud.mostrar_llave(true, salida_requiere_llave)
	hud.avisar("¡TENÉS LA LLAVE! Andá a la salida")


func _on_enemigo_murio(enemigo: Enemigo) -> void:
	var ganados := enemigo.puntos()
	Juego.sumar_puntos(ganados)
	hud.actualizar_puntos(Juego.puntos, ganados)
	enemigos_vivos -= 1
	hud.actualizar_enemigos(enemigos_vivos, total_enemigos)
	camara.sacudir(7.0)


func ganar(motivo: String) -> void:
	if terminado or not jugador.esta_vivo:
		return
	terminado = true
	jugador.desactivar_controles()
	Juego.sumar_tiempo(tiempo)
	if Juego.hay_siguiente_nivel():
		hud.mostrar_nivel_superado(motivo)
	else:
		hud.mostrar_victoria_final(Juego.terminar_partida())
	get_tree().paused = true
