extends Movement

@export_group("Config/Visual") 
@export var offset: Vector3

var right_axis: Vector3 = Vector3.ZERO


func _apply_movement(delta: float) -> void:
	var max_speed: float = _get_move_speed()
	var target_vel: Vector3 = desired_move_dir * max_speed
	body.velocity = body.velocity.move_toward(target_vel, acceleration * delta)


func _apply_drag(delta: float) -> void:
	body.velocity = body.velocity.move_toward(Vector3.ZERO, drag * delta)


func apply_model_rotation(dir: Vector3, rotation_speed: float, delta: float) -> void:
	var right_vec: Vector3 = Vector3.UP.cross(dir).normalized()
	if dir.abs() == Vector3.UP:
		if right_axis == Vector3.ZERO:
			right_axis = -model.global_basis.x
		right_vec = right_axis
	else:
		right_axis = Vector3.ZERO
	
	var forward_vec: Vector3 = dir.normalized().cross(right_vec).normalized()
	var target_basis: Basis = Basis(-right_vec, dir.normalized(), forward_vec).orthonormalized()
	
	target_basis = target_basis.rotated(target_basis.x, deg_to_rad(offset.x))
	target_basis = target_basis.rotated(target_basis.y, deg_to_rad(offset.y))
	target_basis = target_basis.rotated(target_basis.z, deg_to_rad(offset.z))
	
	var quat_target: Quaternion = target_basis.get_rotation_quaternion()
	model.quaternion = model.quaternion.slerp(quat_target, delta * rotation_speed)
