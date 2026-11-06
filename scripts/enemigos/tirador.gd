class_name Tirador extends Enemigo
## NPC armado: hace guardia (o patrulla), dispara ráfagas cuando ve al jugador
## y va a revisar la última posición donde lo vio o donde escuchó un disparo.

@export_group("Disparo")
@export var velocidad_bala := 650.0
@export var tiempo_reaccion := 0.45  ## el láser te apunta este tiempo antes del primer tiro
@export var balas_por_rafaga := 3
@export var cadencia := 0.18
@export var pausa_entre_rafagas := 1.0
@export var color_bala := Color(1.0, 0.35, 0.35)
@export_flags_2d_physics var mascara_balas := 0
@export var alcance_laser := 900.0

@export_group("Puntos")
@export var puntos_al_morir := 200

@export_group("Guardia")
@export var ruta_patrulla: Array[Marker2D] = []
@export var velocidad_patrulla := 70.0
@export var espera_en_punto := 1.0

@onready var punta_arma: Marker2D = $PuntaArma
@onready var laser: Line2D = $Laser
@onready var sonido_disparo: AudioStreamPlayer2D = $Sonidos/Disparo

var ultima_posicion_conocida := Vector2.ZERO
var posicion_inicial := Vector2.ZERO
var rotacion_inicial := 0.0


func _ready() -> void:
	super()
	posicion_inicial = global_position
	rotacion_inicial = global_rotation


func puntos() -> int:
	return puntos_al_morir


func apunta_al_jugador(tolerancia_grados: float = 4.0) -> bool:
	var angulo := global_position.direction_to(jugador.global_position).angle()
	return absf(angle_difference(global_rotation, angulo)) <= deg_to_rad(tolerancia_grados)


## Hacia dónde apunta el arma: el punto que tiene enfrente, a la distancia del jugador.
## El láser y la bala usan esta misma dirección: la bala va exactamente por el láser.
func direccion_arma() -> Vector2:
	var distancia := 300.0
	if is_instance_valid(jugador):
		distancia = maxf(global_position.distance_to(jugador.global_position), 60.0)
	var mira := global_position + Vector2.RIGHT.rotated(global_rotation) * distancia
	return punta_arma.global_position.direction_to(mira)


func mostrar_laser(activo: bool) -> void:
	laser.visible = activo
	if not activo:
		return
	var desde := punta_arma.global_position
	var hasta := desde + direccion_arma() * alcance_laser
	var consulta := PhysicsRayQueryParameters2D.create(desde, hasta, mascara_balas)
	var impacto := get_world_2d().direct_space_state.intersect_ray(consulta)
	if impacto:
		hasta = impacto.position
	laser.points = PackedVector2Array([to_local(desde), to_local(hasta)])


func disparar() -> void:
	var dir := direccion_arma()
	var bala := Bala.new()
	bala.velocidad = velocidad_bala
	bala.color = color_bala
	get_tree().current_scene.add_child(bala)
	bala.preparar(punta_arma.global_position, dir, mascara_balas, global_position)
	Efectos.estallido(self, punta_arma.global_position, dir)
	sonido_disparo.pitch_scale = randf_range(0.85, 1.0)
	sonido_disparo.play()
	hizo_ruido.emit(global_position)


func oir_ruido(posicion: Vector2) -> void:
	if not esta_vivo:
		return
	if maquina.esta_en(NombresEstados.GUARDIA) or maquina.esta_en(NombresEstados.BUSCANDO):
		ultima_posicion_conocida = posicion
		maquina.cambiar_a(NombresEstados.BUSCANDO)


## Si le dispararon y sobrevivió (vida > 1), se da vuelta a buscar de dónde vino.
func al_recibir_golpe(direccion: Vector2) -> void:
	if maquina.esta_en(NombresEstados.GUARDIA) or maquina.esta_en(NombresEstados.BUSCANDO):
		ultima_posicion_conocida = global_position - direccion * 200.0
		maquina.cambiar_a(NombresEstados.BUSCANDO)


func desactivar_cuerpo() -> void:
	super()
	mostrar_laser(false)


func estado_tras_aturdimiento() -> StringName:
	if ve_al_jugador():
		return NombresEstados.ATACANDO
	if jugador_disponible():
		ultima_posicion_conocida = jugador.global_position
		return NombresEstados.BUSCANDO
	return NombresEstados.GUARDIA
