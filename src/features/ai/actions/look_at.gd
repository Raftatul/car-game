@tool
extends "res://addons/beehave/nodes/leaves/action.gd"

enum LOOK_TYPES {POSITION, TARGET}

@export var movement: Movement

@export var look_type: LOOK_TYPES = LOOK_TYPES.POSITION :
	set(v):
		look_type = v
		name = "LookAt%s" % (LOOK_TYPES.keys()[v] as String).to_pascal_case()

@export var rotation_speed: float = 1.0


func tick(actor: Node, blackboard: Blackboard) -> int:
	if !is_instance_valid(actor): return FAILURE
	if !is_instance_valid(movement): return FAILURE
	
	var look_dir: Vector3 = _get_look_dir(actor)
	movement.apply_model_rotation(look_dir, rotation_speed, get_process_delta_time())
	return SUCCESS


func _get_look_dir(actor: Entity) -> Vector3:
	match look_type:
		LOOK_TYPES.POSITION:
			if !actor.path.is_empty():
				return actor.global_position.direction_to(actor.get_last_path_pos())
		LOOK_TYPES.TARGET:
			if is_instance_valid(actor.current_target):
				return actor.global_position.direction_to(actor.current_target.global_position)
	return actor.global_basis.z
