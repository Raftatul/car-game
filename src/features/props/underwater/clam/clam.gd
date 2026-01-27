extends Node3D

@export var items: Array[PackedScene]

var player_count: int = 0

var item: GameItem = null

var closed: bool = true :
	set(v):
		if v == closed:
			return
		
		closed = v
		
		if closed:
			if item: item.interactable.process_mode = Node.PROCESS_MODE_DISABLED
			animation_player.play("close", 0.2)
		else:
			if item: item.interactable.process_mode = Node.PROCESS_MODE_INHERIT
			animation_player.play("open", 0.2)

@onready var animation_player: AnimationPlayer = $clam/AnimationPlayer
@onready var area: Area3D = $Area3D
@onready var item_socket: Node3D = %ItemSocket


func _ready() -> void:
	if is_multiplayer_authority():
		_spawn_item()
	closed = false


func _physics_process(_delta: float) -> void:
	if !is_multiplayer_authority(): return
	
	var bodies: Array = area.get_overlapping_bodies().filter(_filter_players)
	if bodies.is_empty() and closed:
		closed = false
	if !bodies.is_empty() and !closed:
		closed = true


func _spawn_item() -> void:
	item = items.pick_random().instantiate()
	item.buoyancy.active = false
	item.picked_up.connect(item.buoyancy.set.bind("active", true))
	item_socket.add_child(item)


func _filter_players(a: Node) -> bool:
	if not a is PlayerCharacter:
		return false
	return not a.masked
