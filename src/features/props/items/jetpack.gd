extends GameItem

@export var force: float = 1.0


func _process(delta: float) -> void:
	DebugDraw3D.draw_sphere(to_global(get("center_of_mass")), 0.5, Color.RED)

func _pre_use() -> void:
	_rpc_play_animation.rpc("rotate")


func _use(delta: float) -> void:
	if actor is PlayerCharacter:
		if actor.is_in_water:
			actor.velocity += actor.visual.global_basis.y * force * delta


func _post_use() -> void:
	_rpc_stop_animation.rpc()


func _lifetime_drained() -> void:
	_rpc_stop_animation.rpc()
