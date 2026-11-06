extends Node
## AUTOLOAD "Juego" (escenas/autoload/juego.tscn): lo que sobrevive entre escenas
## (volumen, la partida en curso, el ranking y la música, que no se corta al cambiar de nivel).

const ESCENA_MENU := "res://escenas/ui/menu.tscn"
const NIVELES: Array[String] = [
	"res://escenas/mundo/lvl/lvl.tscn",
	"res://escenas/mundo/lvl/lvl2.tscn",
]
const RUTA_AJUSTES := "user://ajustes.cfg"
const LARGO_RANKING := 10
const LARGO_NOMBRE := 12

var volumen_general := 0.8
var volumen_musica := 0.6
var volumen_efectos := 0.8

var nivel_actual := 1
var nombre_jugador := ""
var puntos := 0
var tiempo_partida := 0.0  ## suma de los niveles ya terminados
var ranking: Array[Dictionary] = []  ## [{ nombre, puntos, tiempo }], ya ordenado
var ultimo_puesto := -1  ## puesto de la última partida, para resaltarla en el ranking
var abrir_ranking_en_menu := false

@onready var _musica: AudioStreamPlayer = $Musica


func _ready() -> void:
	cargar()
	aplicar_volumenes()


#region Audio

func aplicar_volumenes() -> void:
	_aplicar_bus(&"Master", volumen_general)
	_aplicar_bus(&"Musica", volumen_musica)
	_aplicar_bus(&"Efectos", volumen_efectos)


func _aplicar_bus(nombre: StringName, valor: float) -> void:
	var indice := AudioServer.get_bus_index(nombre)
	if indice == -1:
		push_warning("No existe el bus de audio '%s'" % nombre)
		return
	AudioServer.set_bus_volume_db(indice, linear_to_db(maxf(valor, 0.0001)))
	AudioServer.set_bus_mute(indice, valor <= 0.001)


## No reinicia la pista si ya está sonando (al reintentar un nivel la música sigue).
func reproducir_musica(pista: AudioStream) -> void:
	if pista == null:
		_musica.stop()
		return
	if _musica.stream == pista and _musica.playing:
		return
	_musica.stream = pista
	_musica.play()

#endregion


#region Partida
## Una partida va del nivel 1 hasta ganar el último o morir.
## Los puntos y el tiempo se arrastran de un nivel al siguiente.

func empezar_partida(nombre: String) -> void:
	nombre_jugador = limpiar_nombre(nombre)
	puntos = 0
	tiempo_partida = 0.0
	ultimo_puesto = -1
	grabar()
	ir_al_nivel(1)


func limpiar_nombre(nombre: String) -> String:
	return nombre.strip_edges().left(LARGO_NOMBRE).to_upper()


func sumar_puntos(cantidad: int) -> void:
	puntos += cantidad


func ir_al_nivel(numero: int) -> void:
	if numero < 1 or numero > NIVELES.size():
		ir_al_menu()
		return
	nivel_actual = numero
	get_tree().paused = false
	get_tree().change_scene_to_file(NIVELES[numero - 1])


func hay_siguiente_nivel() -> bool:
	return nivel_actual < NIVELES.size()


func sumar_tiempo(segundos: float) -> void:
	tiempo_partida += segundos


func ir_al_siguiente_nivel() -> void:
	ir_al_nivel(nivel_actual + 1)


## Cierra la partida (ganó el último nivel o murió) y la anota en el ranking.
## Devuelve el puesto (1 = primero) o -1 si no entró entre los mejores.
func terminar_partida() -> int:
	var entrada := {
		"nombre": nombre_jugador if nombre_jugador != "" else "SIN NOMBRE",
		"puntos": puntos,
		"tiempo": snappedf(tiempo_partida, 0.01),
	}
	ranking.append(entrada)
	ranking.sort_custom(va_antes)
	if ranking.size() > LARGO_RANKING:
		ranking.resize(LARGO_RANKING)
	ultimo_puesto = ranking.find(entrada) + 1
	if ultimo_puesto == 0:
		ultimo_puesto = -1
	grabar()
	return ultimo_puesto


## Orden del ranking: más puntos primero; si empatan, menos tiempo; si empatan, por nombre.
static func va_antes(a: Dictionary, b: Dictionary) -> bool:
	if a.puntos != b.puntos:
		return a.puntos > b.puntos
	if not is_equal_approx(a.tiempo, b.tiempo):
		return a.tiempo < b.tiempo
	return a.nombre.naturalnocasecmp_to(b.nombre) < 0


func ir_al_menu(abrir_ranking: bool = false) -> void:
	abrir_ranking_en_menu = abrir_ranking
	get_tree().paused = false
	get_tree().change_scene_to_file(ESCENA_MENU)


func formatear_tiempo(segundos: float) -> String:
	var minutos := floori(segundos / 60.0)
	return "%02d:%05.2f" % [minutos, fmod(segundos, 60.0)]

#endregion


#region Guardado

func grabar() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "general", volumen_general)
	cfg.set_value("audio", "musica", volumen_musica)
	cfg.set_value("audio", "efectos", volumen_efectos)
	cfg.set_value("jugador", "ultimo_nombre", nombre_jugador)
	cfg.set_value("ranking", "partidas", ranking)
	var error := cfg.save(RUTA_AJUSTES)
	if error != OK:
		push_warning("No se pudo guardar %s (error %d)" % [RUTA_AJUSTES, error])


func cargar() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(RUTA_AJUSTES) != OK:
		return
	volumen_general = cfg.get_value("audio", "general", volumen_general)
	volumen_musica = cfg.get_value("audio", "musica", volumen_musica)
	volumen_efectos = cfg.get_value("audio", "efectos", volumen_efectos)
	nombre_jugador = str(cfg.get_value("jugador", "ultimo_nombre", ""))
	ranking.clear()
	for entrada in cfg.get_value("ranking", "partidas", []):
		if entrada is Dictionary and entrada.has_all(["nombre", "puntos", "tiempo"]):
			ranking.append({
				"nombre": str(entrada.nombre),
				"puntos": int(entrada.puntos),
				"tiempo": float(entrada.tiempo),
			})
	ranking.sort_custom(va_antes)

#endregion
