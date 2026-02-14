@tool
extends "res://addons/beehave/nodes/leaves/condition.gd"

enum RANGE_TYPES {POSITION, TARGET}

@export var range_type: RANGE_TYPES = RANGE_TYPES.POSITION :
	set(v):
		range_type = v
		name = "InRangeOf%s" % (RANGE_TYPES.keys()[v] as String).to_pascal_case()

@export var required_distance: float = 1.0


func tick(actor: Node, blackboard: Blackboard) -> int:
	if !is_instance_valid(actor): return FAILURE
	var distance: float = _get_distance_to(actor)
	if distance <= required_distance: return SUCCESS
	return FAILURE


func _get_distance_to(actor: Entity) -> float:
	match range_type:
		RANGE_TYPES.POSITION:
			return actor.global_position.distance_to(actor.get_last_path_pos())
		RANGE_TYPES.TARGET:
			if !is_instance_valid(actor.current_target): return 0.0
			return actor.global_position.distance_to(actor.current_target.global_position)
	return 0.0
