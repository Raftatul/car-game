class_name VolumetricAI
extends Node3D

@export var target_pos: Vector3
@export var move_speed: float = 1.0

var path: Array


func _ready() -> void:
	path = VolumetricNavigation.find_path(global_position, target_pos)


func _physics_process(delta: float) -> void:
	if get_tree().get_first_node_in_group("players"):
		set_target_position(get_tree().get_first_node_in_group("players").global_position)
	
	if path.size() > 0:
		DebugDraw3D.draw_points(path, DebugDraw3D.POINT_TYPE_SPHERE, 0.5, Color.RED)
		global_position = global_position.move_toward(path[0], delta * move_speed)
		
		if global_position.distance_to(path[0]) < 0.5:
			path.remove_at(0)


func set_target_position(target_position: Vector3) -> void:
	path = VolumetricNavigation.find_path(global_position, target_position)
	path.remove_at(0)
