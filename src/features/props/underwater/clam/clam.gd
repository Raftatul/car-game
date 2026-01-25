extends Node3D

@export var items: Array[PackedScene]

var player_count: int = 0

var item: Node3D = null

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
@onready var item_socket: Node3D = %ItemSocket


func _ready() -> void:
	if is_multiplayer_authority():
		_spawn_item()
	closed = false


func _spawn_item() -> void:
	item = items.pick_random().instantiate()
	item_socket.add_child(item)


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
