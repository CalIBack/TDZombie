class_name Estado extends Node
## Estado base. La MaquinaEstados le asigna "actor" y "maquina" antes de usarlo.

var actor: Node
var maquina: MaquinaEstados


func entrar() -> void:
	pass


func salir() -> void:
	pass


func fisica(_delta: float) -> void:
	pass


func proceso(_delta: float) -> void:
	pass
