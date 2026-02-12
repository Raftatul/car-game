class_name Movement
extends Node

@export var body: RigidBodyCharacter

@export_group("Config")
@export var acceleration: float = 1.0
@export var move_speed: float = 1.0
@export var fast_move_speed: float = 1.0
@export var drag: float = 0.1

@export_group("Config/Jump")
@export var can_jump: bool = true
@export var jump_velocity: float = 1.0

@export_group("Config/Gravity")
@export var should_apply_gravity: bool = true
@export var max_gravity_speed: float = 30.0

@export_group("Config/Visual")
@export var model: Node3D
@export var model_rotation_speed: float = 1.0

var wants_jump: bool = false
var wants_to_move_fast: bool = false
var desired_move_dir: Vector3


func tick(delta: float) -> void:
	_apply_movement(delta)
	_apply_drag(delta)
	
	if should_apply_gravity:
		_apply_gravity(delta)
	
	if desired_move_dir: _apply_model_rotation(delta)
	
	if can_jump && wants_jump:
		_jump()
	
	body.push_away_rigid_bodies()
	body.move_and_slide()


func _apply_movement(delta: float) -> void:
	var dir: Vector3 = Vector3(desired_move_dir.x, 0.0, desired_move_dir.z)
	var max_speed: float = _get_move_speed()
	
	var target_vel: Vector3 = dir * max_speed
	target_vel.y = body.velocity.y
	body.velocity = body.velocity.move_toward(target_vel, acceleration * delta)


func _apply_gravity(delta: float) -> void:
	var gravity: Vector3 = body.get_gravity()
	body.velocity.y += gravity.y * delta
	body.velocity = body.velocity.limit_length(max_gravity_speed)


func _jump() -> void:
	wants_jump = false
	body.velocity.y = jump_velocity


func _apply_drag(delta: float) -> void:
	body.velocity = body.velocity.move_toward(body.velocity * Vector3.UP, drag * delta)


func _apply_model_rotation(delta: float) -> void:
	model.rotation.y = lerp_angle(model.rotation.y, atan2(-desired_move_dir.x, -desired_move_dir.z), model_rotation_speed * delta)
	model.rotation.x = lerp_angle(model.rotation.x, 0.0, model_rotation_speed * delta)
	model.rotation.z = lerp_angle(model.rotation.z, 0.0, model_rotation_speed * delta)


func _get_move_speed() -> float:
	if wants_to_move_fast: return fast_move_speed
	return move_speed
