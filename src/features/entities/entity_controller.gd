extends CharacterBody3D

var target: Node3D

@onready var ai_movement: AIMovement = $AIMovement


func _physics_process(delta: float) -> void:
	if target:
		ai_movement.target_pos = target.global_position
	ai_movement.tick(delta)
	
	move_and_slide()


func _on_ai_sensor_target_in_range(_target: Node3D) -> void:
	target = _target


func _on_ai_sensor_target_out_of_range() -> void:
	target = null
