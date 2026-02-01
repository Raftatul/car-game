class_name AIMovement
extends Node3D

@export var body: CharacterBody3D
@export var model: Node3D
@export var acceleration: float = 1.0
@export var move_speed: float = 1.0
@export var model_rotation_speed: float = 1.0

var _path: PackedVector3Array = []

@onready var target_pos: Vector3 = owner.global_position


func tick(delta: float) -> void:
	if !is_instance_valid(body): return
	
	if _path.is_empty() or target_pos != _path[-1]:
		_path = _get_shortest_path(VolumetricNavigation.find_path(owner.global_position, target_pos))
		if !_path.is_empty():
			_path.remove_at(0)
	
	if _path.size() > 0:
		var debug: PackedVector3Array = [global_position]
		debug.append_array(_path)
		DebugDraw3D.draw_arrow_path(debug, Color.RED)
		var move_dir: Vector3 = body.global_position.direction_to(get_next_path_position())
		var target_vel: Vector3 = move_dir * move_speed
		
		body.velocity.x = move_toward(body.velocity.x, target_vel.x, delta * acceleration)
		body.velocity.y = move_toward(body.velocity.y, target_vel.y, delta * acceleration)
		body.velocity.z = move_toward(body.velocity.z, target_vel.z, delta * acceleration)
		
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
		body.velocity.x = move_toward(body.velocity.x, 0.0, delta * acceleration)
		body.velocity.y = move_toward(body.velocity.y, 0.0, delta * acceleration)
		body.velocity.z = move_toward(body.velocity.z, 0.0, delta * acceleration)


func get_next_path_position() -> Vector3:
	if _path.is_empty():
		return get_parent().global_position
	return _path[0]


func distance_to_target() -> float:
	return global_position.distance_to(target_pos)


func _get_shortest_path(path: PackedVector3Array) -> PackedVector3Array:
	
	DebugDraw3D.draw_arrow_path(path, Color.WHITE)
	
	if path.is_empty() || path.size() < 3:
		return path
	
	var idx: int = 0
	var short_path: PackedVector3Array = []
	for i in range(path.size()):
		var p: Vector3 = path[idx]
		short_path.append(p)
		
		if idx == path.size() - 1: break
		
		var flag: bool = false
		for j in range(path.size() - 1, idx, -1):
			var p_last: Vector3 = path[j]
			if _is_shortcut_valid(p, p_last):
				idx = j
				flag = true
				break
		
		if !flag:
			idx += 1
	
	if VolumetricNavigation.has_point(target_pos, 4.0):
		short_path[-1] = target_pos
	
	return short_path


func _is_shortcut_valid(p1: Vector3, p2: Vector3) -> bool:
	var distance: float = p1.distance_to(p2)
	var loop_count: int = floor(distance / 2.0)
	for i in range(loop_count):
		var p_lerp: Vector3 = lerp(p1, p2, i / float(loop_count))
		if !VolumetricNavigation.has_point(p_lerp, 4.0):
			return false
	return true
