@tool
extends "res://addons/beehave/nodes/leaves/action.gd"


func tick(actor: Node, blackboard: Blackboard) -> int:
	if !is_instance_valid(actor): return FAILURE
	if !is_instance_valid(actor.current_target): return FAILURE
	var nav_region: VolumetricRegion = actor.nav_region
	if !is_instance_valid(nav_region): return FAILURE
	
	var target_pos: Vector3 = actor.current_target.global_position
	
	var path: PackedVector3Array = nav_region.get_shortest_path(actor.global_position, target_pos)
	if path.size() > 1:
		path.remove_at(0)
	
	actor.path = path
	
	return SUCCESS
