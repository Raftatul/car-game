class_name InputsComponent
extends Node

var interaction_pressed: bool = false


func update() -> void:
	interaction_pressed = Input.is_action_pressed("interact")
