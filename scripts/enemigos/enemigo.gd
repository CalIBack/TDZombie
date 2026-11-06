class_name Enemigo extends CharacterBody2D
## Base común de zombies y tiradores: vida, daño, muerte, aturdimiento, visión, oído y navegación.

signal murio(enemigo: Enemigo)
signal hizo_ruido(posicion: Vector2)  ## un disparo propio: el nivel avisa a los demás

@export var vida := 1
@export var velocidad := 115.0
@export var velocidad_giro := 7.0
@export var fuerza_empuje := 260.0
@export var tamanio_mancha := 1.0

@export_group("Variante")
## Marcá una, las dos o ninguna. Se aplican al empezar el nivel.
@export var tanque := false       ## cambia SOLO la vida
@export var vida_tanque := 4
@export var rapido := false       ## cambia SOLO la velocidad
@export var velocidad_rapido := 175.0

@export_group("Sentidos")
@export var rango_vision := 450.0
@export_range(10.0, 360.0) var angulo_vision := 110.0
@export var radio_cercania := 70.0  ## a esta distancia lo detecta aunque esté de espaldas
@export_flags_2d_physics var mascara_vision := 0  ## qué tapa la vista (y el jugador)
@export_flags_2d_physics var mascara_sonido := 0  ## qué tapa el sonido (el vidrio)

@onready var visual: Node2D = $Visual
@onready var sprite: Sprite2D = $Visual/Sprite2D
@onready var colision: CollisionShape2D = $CollisionShape2D
@onready var agente: NavigationAgent2D = $NavigationAgent2D
@onready var maquina: MaquinaEstados = $MaquinaEstados
@onready var sonido_impacto: AudioStreamPlayer2D = $Sonidos/Impacto
@onready var sonido_muerte: AudioStreamPlayer2D = $Sonidos/Muerte
@onready var sonido_golpe_puerta: AudioStreamPlayer2D = $Sonidos/GolpePuerta

var jugador: Jugador
var esta_vivo := true
var empuje := Vector2.ZERO
var tiempo_aturdido := 0.0


func _ready() -> void:
	_aplicar_variante()
	buscar_jugador.call_deferred()


## El tinte es solo una pista visual para reconocerlos: tanque más oscuro, rápido más rojo.
func _aplicar_variante() -> void:
	if tanque:
		vida = vida_tanque
		visual.modulate *= Color(0.6, 0.75, 0.6)
	if rapido:
		velocidad = velocidad_rapido
		visual.modulate *= Color(1.5, 0.6, 0.6)


## Cuántos puntos da al morir. Cada tipo de enemigo lo redefine.
func puntos() -> int:
	return 0


func buscar_jugador() -> void:
	if not is_instance_valid(jugador):
		jugador = get_tree().get_first_node_in_group("jugador") as Jugador


func jugador_disponible() -> bool:
	return is_instance_valid(jugador) and jugador.esta_vivo


#region Sentidos

## Tres pruebas: ¿está cerca?, ¿está delante?, ¿hay algo en el medio?
func ve_al_jugador() -> bool:
	if not jugador_disponible():
		return false
	var hacia := jugador.global_position - global_position
	var distancia := hacia.length()
	if distancia > rango_vision:
		return false
	if distancia > radio_cercania:
		var desvio := absf(angle_difference(global_rotation, hacia.angle()))
		if desvio > deg_to_rad(angulo_vision) / 2.0:
			return false
	var consulta := PhysicsRayQueryParameters2D.create(global_position, jugador.global_position, mascara_vision)
	var impacto := get_world_2d().direct_space_state.intersect_ray(consulta)
	return not impacto.is_empty() and impacto.collider == jugador


## Un rayo desde el ruido hasta el enemigo: si cruza vidrio, no lo escucha.
func escucha(posicion: Vector2) -> bool:
	var consulta := PhysicsRayQueryParameters2D.create(posicion, global_position, mascara_sonido)
	return get_world_2d().direct_space_state.intersect_ray(consulta).is_empty()

#endregion


#region Movimiento

## El mapa de navegación se hornea en el _ready del nivel, que corre DESPUÉS
## del de los enemigos. Hasta que el servidor sincroniza no hay rutas válidas.
func navegacion_lista() -> bool:
	return NavigationServer2D.map_get_iteration_id(agente.get_navigation_map()) > 0


func fijar_destino(punto: Vector2) -> void:
	if agente.target_position.distance_squared_to(punto) > 64.0:
		agente.target_position = punto


## Sigue la ruta calculada; cuando ya no queda ruta va en línea recta a "punto_final".
func avanzar_hacia(punto_final: Vector2, delta: float, rapidez: float = velocidad) -> void:
	var siguiente := punto_final
	if navegacion_lista() and not agente.is_navigation_finished():
		siguiente = agente.get_next_path_position()
	caminar_en_direccion(global_position.direction_to(siguiente), delta, rapidez)


## Camina recto hacia "direccion". Si hay una pared en el medio, se desliza contra ella.
func caminar_en_direccion(direccion: Vector2, delta: float, rapidez: float = velocidad) -> void:
	velocity = direccion * rapidez + empuje
	_reducir_empuje(1200.0, delta)
	girar_hacia(direccion.angle(), delta)
	move_and_slide()
	_romper_vidrios_que_toco()


## Si al caminar chocó contra un vidrio, lo rompe y sigue.
func _romper_vidrios_que_toco() -> void:
	for i in get_slide_collision_count():
		var vidrio := get_slide_collision(i).get_collider() as Vidrio
		if vidrio:
			vidrio.romper(velocity.normalized())


func ir_hacia(destino: Vector2, delta: float, rapidez: float = velocidad) -> void:
	fijar_destino(destino)
	avanzar_hacia(destino, delta, rapidez)


func llego_al_destino() -> bool:
	return navegacion_lista() and agente.is_navigation_finished()


func frenar(delta: float) -> void:
	velocity = empuje
	_reducir_empuje(900.0, delta)
	move_and_slide()


func girar_hacia(angulo: float, delta: float, factor: float = 1.0) -> void:
	rotation = lerp_angle(rotation, angulo, 1.0 - exp(-velocidad_giro * factor * delta))


func _reducir_empuje(friccion: float, delta: float) -> void:
	empuje = empuje.move_toward(Vector2.ZERO, friccion * delta)


## Destello blanco breve al recibir un golpe.
func parpadear() -> void:
	sprite.self_modulate = Color(3, 1.5, 1.5)
	create_tween().tween_property(sprite, "self_modulate", Color.WHITE, 0.15)

#endregion


#region Daño

func recibir_danio(cantidad: int, direccion: Vector2) -> void:
	if not esta_vivo:
		return
	vida -= cantidad
	empuje = direccion * fuerza_empuje
	sonido_impacto.pitch_scale = randf_range(0.9, 1.15)
	sonido_impacto.play()
	Efectos.sangre(self, global_position, direccion, 10)
	if vida <= 0:
		morir(direccion)
		return
	parpadear()
	al_recibir_golpe(direccion)


func morir(direccion: Vector2 = Vector2.ZERO) -> void:
	if not esta_vivo:
		return
	esta_vivo = false
	empuje = direccion * fuerza_empuje * 1.4
	Efectos.dejar_mancha(self, global_position, tamanio_mancha)
	Efectos.sangre(self, global_position, direccion, 24)
	maquina.cambiar_a(NombresEstados.MUERTO)
	murio.emit(self)


## Portazo.
func aturdir(segundos: float, direccion: Vector2) -> void:
	if not esta_vivo:
		return
	tiempo_aturdido = maxf(tiempo_aturdido, segundos)
	empuje = direccion * 380.0
	maquina.cambiar_a(NombresEstados.ATURDIDO)


## Lo llama el estado Muerto.
func desactivar_cuerpo() -> void:
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 1)  # solo "mundo": el cadáver no atraviesa paredes
	# Al principio del contenedor: se dibuja debajo de los vivos.
	get_parent().move_child.call_deferred(self, 0)

#endregion


#region Para sobreescribir en cada tipo de enemigo

func estado_tras_aturdimiento() -> StringName:
	return NombresEstados.MUERTO


func al_recibir_golpe(_direccion: Vector2) -> void:
	pass


## El nivel lo llama cuando alguien dispara cerca y el sonido llega.
func oir_ruido(_posicion: Vector2) -> void:
	pass

#endregion
