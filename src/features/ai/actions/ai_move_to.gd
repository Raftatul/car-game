@tool
extends "res://addons/beehave/nodes/leaves/action.gd"

@export var movement: Movement


func tick(actor: Node, blackboard: Blackboard) -> int:
	if !is_instance_valid(actor): return FAILURE
	if !is_instance_valid(movement): return FAILURE
	
	movement.desired_move_dir = actor.global_position.direction_to(actor.get_next_path_position())
	return SUCCESS
