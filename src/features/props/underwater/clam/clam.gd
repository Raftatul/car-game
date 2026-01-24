extends Node3D

var player_count: int = 0

var closed: bool = true :
	set(v):
		if v == closed:
			return
		
		closed = v
		
		if closed:
			animation_player.play("close")
		else:
			animation_player.play("open")

@onready var animation_player: AnimationPlayer = $clam/AnimationPlayer
@onready var area: Area3D = $Area3D


func _ready() -> void:
	closed = false


func _on_area_3d_body_entered(body: Node3D) -> void:
	if not is_multiplayer_authority():
		return
	
	if not body is PlayerCharacter:
		return
	
	player_count += 1
	closed = true


func _on_area_3d_body_exited(body: Node3D) -> void:
	if not is_multiplayer_authority():
		return
	
	if not body is PlayerCharacter:
		return
	
	player_count -= 1
	closed = player_count != 0
	closed = false
