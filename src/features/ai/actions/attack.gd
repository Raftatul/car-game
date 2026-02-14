@tool
extends "res://addons/beehave/nodes/leaves/action.gd"


func tick(actor: Node, blackboard: Blackboard) -> int:
	if !is_instance_valid(actor): return FAILURE
	if !is_instance_valid(actor.current_target): return FAILURE
	
	actor.attack()
	return SUCCESS
