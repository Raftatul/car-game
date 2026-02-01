extends CharacterBody3D

@export var attack_range: float = 1.0
@export var damage_delta: float = -10.0

@export var a: Node3D
@export var b: Node3D

var target: PlayerCharacter
var flipflop: bool = false

@onready var ai_movement: AIMovement = $AIMovement
@onready var remote_transform: RemoteTransform3D = $RemoteTransform3D
@onready var timer_attack: Timer = $TimerAttack


func _ready() -> void:
	ai_movement.target_pos = a.global_position


func _physics_process(delta: float) -> void:
	if target:
		if remote_transform.remote_path != NodePath(""):
			ai_movement.target_pos = global_position + Vector3(0.0, -10.0, 0.0)
		else:
			ai_movement.target_pos = target.global_position
		if ai_movement.distance_to_target() < attack_range and remote_transform.remote_path == NodePath(""):
			target.death.connect(_on_target_death)
			remote_transform.remote_path = target.get_path()
			timer_attack.start()
	
	#if ai_movement.distance_to_target() < attack_range:
		#flipflop = !flipflop
		#if flipflop:
			#ai_movement.target_pos = b.global_position
		#else:
			#ai_movement.target_pos = a.global_position
	
	ai_movement.force_update_path()
	ai_movement.tick(delta)
	
	move_and_slide()


func _on_ai_sensor_target_in_range(_target: Node3D) -> void:
	if _target is PlayerCharacter:
		target = _target


func _on_ai_sensor_target_out_of_range() -> void:
	target = null


func _on_target_death() -> void:
	target.death.disconnect(_on_target_death)
	remote_transform.remote_path = ""
	timer_attack.stop()


func _on_timer_attack_timeout() -> void:
	if target:
		target.health_component.modify(damage_delta)
