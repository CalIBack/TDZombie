class_name Zombie extends Enemigo
## Arranca dormido. Se despierta si ve al jugador, si escucha un disparo o si le pegan,
## y a partir de ahí lo persigue sin parar. Si lo toca, lo mata.

## Usa el mapa de navegación para rodear paredes. Si no, va derecho hacia vos y se choca.
@export var inteligente := false
@export var intervalo_ruta := 0.25  ## cada cuánto recalcula el camino (solo inteligente)
@export var variacion_pitch := 0.2  ## cada zombie suena entre 1 - esto y 1 + esto

@export_group("Puntos")
@export var puntos_tonto := 100
@export var puntos_inteligente := 200
@export var puntos_variante := 300  ## tanque o rápido
@export var puntos_tanque_y_rapido := 500

@onready var zona_mordida: Area2D = $ZonaMordida
@onready var sonido_grunido: AudioStreamPlayer2D = $Sonidos/Grunido

var despierto := false
var _hasta_ruta := 0.0


func _ready() -> void:
	super()
	# Variación para que no caminen todos sincronizados.
	velocidad *= randf_range(0.92, 1.08)
	# Cada zombie con su propio tono: así se distingue que son varios.
	sonido_grunido.pitch_scale = randf_range(1.0 - variacion_pitch, 1.0 + variacion_pitch)


func despertar() -> void:
	if despierto or not esta_vivo:
		return
	despierto = true
	_empezar_grunido()
	if maquina.esta_en(NombresEstados.DORMIDO):
		maquina.cambiar_a(NombresEstados.PERSEGUIR)


## Lo llama el estado Perseguir cada frame de física.
func perseguir(delta: float) -> void:
	if not is_instance_valid(jugador):
		frenar(delta)
		return
	if inteligente:
		_hasta_ruta -= delta
		if _hasta_ruta <= 0.0:
			fijar_destino(jugador.global_position)
			_hasta_ruta = intervalo_ruta
		avanzar_hacia(jugador.global_position, delta)
	else:
		caminar_en_direccion(global_position.direction_to(jugador.global_position), delta)
	_morder_si_alcanza()


## Tanque o rápido pesan más que ser inteligente; con las dos variantes da el máximo.
func puntos() -> int:
	if tanque and rapido:
		return puntos_tanque_y_rapido
	if tanque or rapido:
		return puntos_variante
	if inteligente:
		return puntos_inteligente
	return puntos_tonto


## Revisar el solapamiento cada frame (en vez de solo con body_entered) arregla
## que no muerda si el jugador ya estaba encima al despertar o al salir del aturdimiento.
func _morder_si_alcanza() -> void:
	if not jugador_disponible():
		return
	for cuerpo in zona_mordida.get_overlapping_bodies():
		if cuerpo == jugador:
			jugador.morir(Jugador.CAUSA_MORDIDA)
			return


func oir_ruido(_posicion: Vector2) -> void:
	despertar()


func al_recibir_golpe(_direccion: Vector2) -> void:
	despertar()


## El audio está en bucle (Loop en el panel Importar). Arranca desde un punto al azar
## para que dos zombies que se despiertan juntos no suenen sincronizados.
func _empezar_grunido() -> void:
	if sonido_grunido.stream == null or sonido_grunido.playing:
		return
	sonido_grunido.play(randf() * sonido_grunido.stream.get_length())


func estado_tras_aturdimiento() -> StringName:
	if not despierto:
		despierto = true
		_empezar_grunido()
	return NombresEstados.PERSEGUIR


func desactivar_cuerpo() -> void:
	super()
	sonido_grunido.stop()
	zona_mordida.set_deferred("monitoring", false)
