class_name Jugador extends CharacterBody2D
## Top-down: se mueve con WASD, mira al mouse, dispara y recarga.
## Muere de un toque (mordida) o de un balazo.
## Sin animaciones: el sprite cambia entre tres texturas (sin arma, con arma, recargando).

signal municion_cambiada(actual: int, maxima: int)
signal recarga_cambiada(recargando: bool)
signal disparo_hecho(posicion: Vector2)
signal murio(causa: StringName)

const CAUSA_MORDIDA := &"mordida"
const CAUSA_DISPARO := &"disparo"

enum ResultadoDisparo { DISPARO, SIN_BALAS, EN_ESPERA }

@export_group("Movimiento")
@export var velocidad := 270.0
@export var aceleracion := 2400.0

@export_group("Arma")
@export var cadencia := 0.15
@export var municion_maxima := 12
@export var tiempo_recarga := 1.0
@export var dispersion_grados := 0.0  ## 0 = la bala va exactamente por el láser
@export var velocidad_bala := 1500.0
@export var color_bala := Color(1.0, 0.95, 0.6)
@export_flags_2d_physics var mascara_balas := 0  ## contra qué chocan las balas del jugador
@export var alcance_laser := 900.0

@export_group("Texturas")
@export var textura_sin_arma: Texture2D  ## hitman1_stand.png (al morir)
@export var textura_arma: Texture2D      ## hitman1_gun.png
@export var textura_recarga: Texture2D   ## hitman1_reload.png

@onready var sprite: Sprite2D = $Sprite2D
@onready var punta_arma: Marker2D = $PuntaArma
@onready var laser: Line2D = $Laser
@onready var maquina: MaquinaEstados = $MaquinaEstados
@onready var sonido_disparo: AudioStreamPlayer2D = $Sonidos/Disparo
@onready var sonido_sin_balas: AudioStreamPlayer2D = $Sonidos/SinBalas
@onready var sonido_recarga: AudioStreamPlayer2D = $Sonidos/Recarga
@onready var sonido_muerte: AudioStreamPlayer2D = $Sonidos/Muerte

var municion := 0
var esta_vivo := true
var controles_activos := true
var _enfriamiento := 0.0


func _ready() -> void:
	municion = municion_maxima
	usar_textura(textura_arma)
	municion_cambiada.emit.call_deferred(municion, municion_maxima)


func _process(delta: float) -> void:
	_enfriamiento = maxf(_enfriamiento - delta, 0.0)
	_actualizar_laser()


## Rayo desde la punta del arma hasta lo primero que pegaría una bala.
func _actualizar_laser() -> void:
	laser.visible = controles_activos
	if not laser.visible:
		return
	var desde := punta_arma.global_position
	var hasta := desde + direccion_apuntado() * alcance_laser
	var consulta := PhysicsRayQueryParameters2D.create(global_position, hasta, mascara_balas)
	var impacto := get_world_2d().direct_space_state.intersect_ray(consulta)
	if impacto:
		hasta = impacto.position
	laser.points = PackedVector2Array([to_local(desde), to_local(hasta)])


#region Acciones usadas por los estados

func leer_direccion() -> Vector2:
	if not controles_activos:
		return Vector2.ZERO
	return Input.get_vector("mover_izquierda", "mover_derecha", "mover_arriba", "mover_abajo")


func mover(delta: float, direccion: Vector2) -> void:
	velocity = velocity.move_toward(direccion * velocidad, aceleracion * delta)
	move_and_slide()


func apuntar() -> void:
	if controles_activos:
		look_at(get_global_mouse_position())


func quiere_disparar() -> bool:
	return controles_activos and Input.is_action_pressed("disparar")


func quiere_recargar() -> bool:
	return controles_activos and Input.is_action_just_pressed("recargar") and municion < municion_maxima


func intentar_disparar() -> ResultadoDisparo:
	if _enfriamiento > 0.0:
		return ResultadoDisparo.EN_ESPERA
	_enfriamiento = cadencia
	if municion <= 0:
		sonido_sin_balas.play()
		return ResultadoDisparo.SIN_BALAS

	municion -= 1
	municion_cambiada.emit(municion, municion_maxima)
	var dir := _direccion_de_disparo()
	_crear_bala(dir)
	Efectos.estallido(self, punta_arma.global_position, dir)
	_retroceso()

	sonido_disparo.pitch_scale = randf_range(0.92, 1.08)
	sonido_disparo.play()
	disparo_hecho.emit(global_position)
	return ResultadoDisparo.DISPARO


func empezar_recarga() -> void:
	usar_textura(textura_recarga)
	sonido_recarga.play()
	recarga_cambiada.emit(true)


func terminar_recarga() -> void:
	municion = municion_maxima
	usar_textura(textura_arma)
	recarga_cambiada.emit(false)
	municion_cambiada.emit(municion, municion_maxima)


func cancelar_recarga() -> void:
	usar_textura(textura_arma)
	recarga_cambiada.emit(false)


func usar_textura(textura: Texture2D) -> void:
	if textura:
		sprite.texture = textura

#endregion


## Lo llama la bala enemiga al impactar.
func recibir_danio(_cantidad: int, direccion: Vector2) -> void:
	if not esta_vivo:
		return
	velocity = direccion * 320.0
	Efectos.sangre(self, global_position, direccion, 16)
	morir(CAUSA_DISPARO)


func morir(causa: StringName) -> void:
	if not esta_vivo:
		return
	esta_vivo = false
	controles_activos = false
	maquina.cambiar_a(NombresEstados.MUERTO)
	murio.emit(causa)


func desactivar_controles() -> void:
	controles_activos = false


## Patada del arma: el sprite retrocede unos píxeles y vuelve.
func _retroceso() -> void:
	sprite.position.x = -3.0
	create_tween().tween_property(sprite, "position:x", 0.0, 0.08)


func direccion_apuntado() -> Vector2:
	var mouse := get_global_mouse_position()
	# Con el mouse pegado al jugador, apuntar desde la punta daría ángulos raros.
	if global_position.distance_to(mouse) > punta_arma.position.length() + 16.0:
		return punta_arma.global_position.direction_to(mouse)
	return Vector2.RIGHT.rotated(global_rotation)


func _direccion_de_disparo() -> Vector2:
	return direccion_apuntado().rotated(deg_to_rad(randf_range(-dispersion_grados, dispersion_grados)))


func _crear_bala(dir: Vector2) -> void:
	var bala := Bala.new()
	bala.velocidad = velocidad_bala
	bala.color = color_bala
	get_tree().current_scene.add_child(bala)
	bala.preparar(punta_arma.global_position, dir, mascara_balas, global_position)
