class_name InputsComponent
extends Node

var flat_input: Vector2 = Vector2.ZERO
var vertical_input: float = 0.0
var move_dir: Vector3 = Vector3.ZERO

var interaction_pressed: bool = false
var run_pressed: bool = false
var jump_pressed: bool = false
var dive_pressed: bool = false
var drop_pressed: bool = false
var use_item_pressed: bool = false
var scroll_up_pressed: bool = false
var scroll_down_pressed: bool = false


func update() -> void:
	flat_input = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	vertical_input = Input.get_axis("dive", "jump")
	move_dir = Vector3(flat_input.x, 0.0, flat_input.y)
	
	interaction_pressed = Input.is_action_pressed("interact")
	run_pressed = Input.is_action_pressed("run")
	jump_pressed = Input.is_action_just_pressed("jump")
	dive_pressed = Input.is_action_pressed("dive")
	use_item_pressed = Input.is_action_pressed("use_item")
	drop_pressed = Input.is_action_just_pressed("drop")
	scroll_up_pressed = Input.is_action_just_pressed("scroll_up")
	scroll_down_pressed = Input.is_action_just_pressed("scroll_down")
