extends CharacterBody3D

@export var wandering_range: float = 1.0
@export var attack_range: float = 1.0
@export var damage_delta: float = -10.0

var target: PlayerCharacter

var start_pos: Vector3
var attacking: bool = false

@onready var ai_sensor: AISensor = $AISensor
@onready var ai_movement: AIMovement = $AIMovement
@onready var remote_transform: RemoteTransform3D = $RemoteTransform3D
@onready var timer_attack: Timer = $TimerAttack


func _ready() -> void:
	if !is_multiplayer_authority():
		set_process(false)
		set_physics_process(false)
		
		ai_sensor.process_mode = Node.PROCESS_MODE_DISABLED
	else:
		start_pos = global_position
		_set_random_wandering_target()


func _physics_process(delta: float) -> void:
	if target:
		if remote_transform.remote_path != NodePath(""):
			ai_movement.target_pos = global_position + Vector3(0.0, -10.0, 0.0)
		else:
			ai_movement.target_pos = target.global_position
	
	ai_movement.tick(delta)
	
	move_and_slide()


func _set_random_wandering_target() -> void:
	var random_offset: Vector3 = Vector3(randf_range(-wandering_range, wandering_range), randf_range(-wandering_range, wandering_range), randf_range(-wandering_range, wandering_range))
	ai_movement.target_pos = start_pos + random_offset


func _grab_player() -> void:
	attacking = true
	target.death.connect(_on_target_death)
	timer_attack.start()
	_rpc_grab_player.rpc(target.get_path())


@rpc("authority", "call_local", "reliable")
func _rpc_grab_player(path: NodePath) -> void:
	remote_transform.remote_path = path


@rpc("authority", "call_local", "reliable")
func _rpc_release_player() -> void:
	remote_transform.remote_path = ""


func _on_ai_sensor_target_in_range(_target: Node3D) -> void:
	if _target is PlayerCharacter:
		target = _target


func _on_ai_sensor_target_out_of_range() -> void:
	target = null


func _on_target_death() -> void:
	target.death.disconnect(_on_target_death)
	timer_attack.stop()
	attacking = false
	_rpc_release_player.rpc()


func _on_timer_attack_timeout() -> void:
	if target:
		target.health_component.modify(damage_delta)


func _on_ai_movement_target_reached() -> void:
	if target and !attacking:
		if target.global_position.distance_to(global_position) > attack_range:
			return
		_grab_player()
	else:
		_set_random_wandering_target()
