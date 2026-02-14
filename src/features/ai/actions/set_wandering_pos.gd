@tool
extends "res://addons/beehave/nodes/leaves/action.gd"

@export var min_range: float = 1.0
@export var max_range: float = 1.0
@export var from_point: Vector3


func tick(actor: Node, blackboard: Blackboard) -> int:
	if !is_instance_valid(actor): return FAILURE
	var nav_region: VolumetricRegion = actor.nav_region
	if !is_instance_valid(nav_region): return FAILURE
	
	var target_pos: Vector3 = from_point + Vector3(randf_range(min_range, max_range), randf_range(min_range, max_range), randf_range(min_range, max_range))
	
	var path: PackedVector3Array = nav_region.get_shortest_path(actor.global_position, target_pos)
	if path.size() <= 1: return FAILURE
	
	path.remove_at(0)
	
	actor.set_path(path)
	
	return SUCCESS
