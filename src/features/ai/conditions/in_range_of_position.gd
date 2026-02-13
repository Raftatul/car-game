@tool
extends "res://addons/beehave/nodes/leaves/condition.gd"

@export var required_distance: float = 1.0


func tick(actor: Node, blackboard: Blackboard) -> int:
	if !is_instance_valid(actor): return FAILURE
	var distance: float = actor.global_position.distance_to(actor.get_last_path_pos())
	if distance <= required_distance: return SUCCESS
	return FAILURE
