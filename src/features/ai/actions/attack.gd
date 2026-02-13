@tool
extends "res://addons/beehave/nodes/leaves/action.gd"


func tick(actor: Node, blackboard: Blackboard) -> int:
	if !is_instance_valid(actor): return FAILURE
	if !is_instance_valid(actor.current_target): return FAILURE
	
	## TODO: Check if health component exists
	if actor.current_target is PlayerCharacter:
		actor.current_target.health_component.modify(actor.damage)
	return SUCCESS
