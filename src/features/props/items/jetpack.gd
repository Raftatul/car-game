extends GameItem

@export var force: float = 1.0


func _pre_use() -> void:
	_rpc_play_animation.rpc("rotate")


func _can_consume_lifetime() -> bool:
	if actor is PlayerCharacter:
		return actor.buoyancy.is_in_water()
	return false


func _use(delta: float) -> void:
	if actor is PlayerCharacter:
		if actor.buoyancy.is_in_water():
			actor.velocity += actor.visual.global_basis.y * force * delta


func _post_use() -> void:
	_rpc_stop_animation.rpc()


func _lifetime_drained() -> void:
	_rpc_stop_animation.rpc()
