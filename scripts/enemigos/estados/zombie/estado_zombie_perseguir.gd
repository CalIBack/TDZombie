extends Estado


func fisica(delta: float) -> void:
	(actor as Zombie).perseguir(delta)
