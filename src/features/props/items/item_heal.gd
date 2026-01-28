extends GameItem

@export var heal_delta: float = 50.0


func _can_consume_lifetime() -> bool:
	if actor is PlayerCharacter:
		return actor.health_component.get_percent() != 1.0
	return false


func _use(_delta: float) -> void:
	if actor is PlayerCharacter:
		actor.health_component.modify(heal_delta)
