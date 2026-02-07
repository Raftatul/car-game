class_name GameItem
extends Item

@export var anim_player: AnimationPlayer
@export var buoyancy: RigidBuoyancy

@onready var interactable: Interactable = $Interactable


func _ready() -> void:
	super()
	interactable.interacted.connect(_on_interactable_interacted)


func dropped() -> void:
	_rpc_enable_node.rpc()


@rpc("any_peer", "call_local", "reliable")
func _rpc_enable_node() -> void:
	set_deferred("process_mode", Node.PROCESS_MODE_INHERIT)


@rpc("any_peer", "call_local", "reliable")
func _rpc_disable_node() -> void:
	set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)


@rpc("any_peer", "call_local", "reliable")
func _rpc_play_animation(anim: String) -> void:
	if anim_player:
		anim_player.play(anim)


@rpc("any_peer", "call_local", "reliable")
func _rpc_stop_animation() -> void:
	if anim_player:
		anim_player.stop()


func _on_interactable_interacted(node: Node) -> void:
	if node is PlayerCharacter:
		if !node.inventory_component.is_inventory_full():
			node.inventory_component.add_item(self)
			_rpc_disable_node.rpc()
