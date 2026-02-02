class_name AIMovement
extends Node3D

signal target_reached

@export var body: CharacterBody3D
@export var model: Node3D
@export var acceleration: float = 1.0
@export var move_speed: float = 1.0
@export var model_rotation_speed: float = 1.0

@export_group("Debug")
@export var debug: bool = false

var _path: PackedVector3Array = []

@onready var target_pos: Vector3 = owner.global_position
@onready var nav_region: VolumetricRegion


func _ready() -> void:
	var parent: Node = get_parent()
	while parent is not VolumetricRegion and parent != get_tree().current_scene:
		parent = parent.get_parent()
		if parent is VolumetricRegion:
			nav_region = parent


func tick(delta: float) -> void:
	if !is_instance_valid(body): return
	
	if _path.is_empty() or target_pos != _path[-1]:
		_path = nav_region.get_shortest_path(owner.global_position, target_pos)
		if !_path.is_empty():
			_path.remove_at(0)
	
	if _path.size() > 0:
		if debug:
			var debug_path: PackedVector3Array = [global_position]
			debug_path.append_array(_path)
			DebugDraw3D.draw_arrow_path(debug_path, Color.RED)
		
		var move_dir: Vector3 = body.global_position.direction_to(get_next_path_position())
		var target_vel: Vector3 = move_dir * move_speed
		
		body.velocity = body.velocity.move_toward(target_vel + body.velocity * 0.1, delta * acceleration)
		
		if model:
			var right_vec: Vector3 = Vector3.UP.cross(move_dir.normalized()).normalized()
			var forward_vec: Vector3 = move_dir.normalized().cross(right_vec).normalized()
			var target_basis: Basis = Basis(right_vec, forward_vec, move_dir.normalized()).orthonormalized()
			
			if target_basis.is_conformal():
				var quat_target: Quaternion = target_basis.get_rotation_quaternion()
				model.quaternion = model.quaternion.slerp(quat_target, delta * model_rotation_speed)
		
		if body.global_position.distance_to(_path[0]) < 0.5:
			_path.remove_at(0)
	else:
		target_reached.emit()
		body.velocity.x = move_toward(body.velocity.x, 0.0, delta * acceleration)
		body.velocity.y = move_toward(body.velocity.y, 0.0, delta * acceleration)
		body.velocity.z = move_toward(body.velocity.z, 0.0, delta * acceleration)


func force_update_path() -> void:
	_path = nav_region.get_shortest_path(owner.global_position, target_pos)
	if !_path.is_empty():
		_path.remove_at(0)


func get_next_path_position() -> Vector3:
	if _path.is_empty():
		return get_parent().global_position
	return _path[0]


func distance_to_target() -> float:
	return global_position.distance_to(target_pos)
