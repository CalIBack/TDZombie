class_name Puerta extends Node2D
## El origen del nodo es la BISAGRA; la hoja se extiende "largo_hoja" px hacia +X.
## Se abre hacia el lado contrario de quien la empuja. Si la abre el jugador,
## aturde a los enemigos que estén del otro lado (portazo).
## Para una pared vertical, rotá la puerta 90°; para la hoja derecha de una doble, 180°.

@export var largo_hoja := 64.0
@export var angulo_apertura := 95.0
@export var duracion_apertura := 0.16
@export var segundos_aturdimiento := 2.0
@export var alcance_portazo := 80.0

@onready var hoja: AnimatableBody2D = $Hoja
@onready var sonido: AudioStreamPlayer2D = $Sonido

var abierta := false


func _on_sensor_body_entered(cuerpo: Node2D) -> void:
	if abierta:
		return
	if (cuerpo is Jugador or cuerpo is Enemigo) and cuerpo.esta_vivo:
		abrir(cuerpo)


func abrir(quien: Node2D) -> void:
	abierta = true
	var lado_de_quien := signf(to_local(quien.global_position).y)
	if lado_de_quien == 0.0:
		lado_de_quien = -1.0
	var lado_apertura := -lado_de_quien

	sonido.play()
	var tween := create_tween()
	tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.tween_property(hoja, "rotation", deg_to_rad(angulo_apertura) * lado_apertura, duracion_apertura) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	if quien is Jugador:
		_portazo(lado_apertura)


func _portazo(lado: float) -> void:
	for nodo in get_tree().get_nodes_in_group("enemigos"):
		var enemigo := nodo as Enemigo
		if enemigo == null or not enemigo.esta_vivo:
			continue
		var local := to_local(enemigo.global_position)
		var en_barrido := local.x > -16.0 and local.x < largo_hoja + 20.0 \
			and signf(local.y) == lado and absf(local.y) < alcance_portazo
		if en_barrido:
			enemigo.aturdir(segundos_aturdimiento, global_position.direction_to(enemigo.global_position))
