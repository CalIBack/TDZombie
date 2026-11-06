class_name MaquinaEstados extends Node
## Cada hijo es un Estado. Solo el estado activo recibe proceso/física.

signal estado_cambiado(anterior: StringName, nuevo: StringName)

@export var estado_inicial: Estado
@export var debug := false

var actual: Estado
var _estados: Dictionary = {}


func _ready() -> void:
	for hijo in get_children():
		if hijo is Estado:
			hijo.actor = owner
			hijo.maquina = self
			_estados[hijo.name] = hijo
	if estado_inicial == null and not _estados.is_empty():
		estado_inicial = _estados.values()[0]
	# Diferido: así el actor ya terminó su _ready (y sus @onready) al entrar al primer estado.
	_arrancar.call_deferred()


func _arrancar() -> void:
	if estado_inicial and actual == null:
		cambiar_a(estado_inicial.name)


func cambiar_a(nombre: StringName) -> void:
	var nuevo: Estado = _estados.get(nombre)
	if nuevo == null:
		push_warning("%s: no existe el estado '%s'" % [owner.name, nombre])
		return
	if nuevo == actual:
		return
	var anterior: StringName = actual.name if actual else &""
	if actual:
		actual.salir()
	actual = nuevo
	if debug:
		print("[%s] %s -> %s" % [owner.name, anterior, nombre])
	actual.entrar()
	estado_cambiado.emit(anterior, nombre)


func nombre_actual() -> StringName:
	return actual.name if actual else &""


func esta_en(nombre: StringName) -> bool:
	return actual != null and actual.name == nombre


func _process(delta: float) -> void:
	if actual:
		actual.proceso(delta)


func _physics_process(delta: float) -> void:
	if actual:
		actual.fisica(delta)
