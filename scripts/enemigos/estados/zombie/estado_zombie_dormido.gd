extends Estado
## Quieto donde lo pusiste, mirando hacia donde lo rotaste. Si te ve, se despierta.

var zombie: Zombie:
	get:
		return actor as Zombie


func fisica(delta: float) -> void:
	zombie.frenar(delta)
	if zombie.ve_al_jugador():
		zombie.despertar()
