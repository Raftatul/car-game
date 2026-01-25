extends Node3D

@export var movement_blend_speed: float = 5.0

var character: PlayerCharacter

var falling: bool = false
var moving: bool = false
var movement_blend: float = 0.0

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var state_machine: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/StateMachine/playback")


func _ready() -> void:
	character = owner
	character.jumped.connect(_on_jumped)


func _process(delta: float) -> void:
	var vel: Vector3 = character.velocity
	vel.y = 0.0
	
	if is_multiplayer_authority():
		_update_movement_blend(delta)
		moving = vel.length() != 0.0
		falling = !character.is_on_floor() or character.buoyancy.is_in_water()
	
	animation_tree.set("parameters/StateMachine/GroundMovement/blend_position", movement_blend)


func _update_movement_blend(delta: float) -> void:
	movement_blend = lerp(movement_blend, remap(character.speed, character.walk_speed, character.run_speed, 0.0, 1.0), delta * movement_blend_speed)


func _on_jumped() -> void:
	state_machine.travel.bind("up")
