@abstract
class_name GameItem
extends Item

@onready var interactable: Interactable = $Interactable


func _ready() -> void:
	interactable.interacted.connect(_on_interactable_interacted)


@abstract
func pre_use(node: Node) -> void


@abstract
func use(delta: float, node: Node) -> void


@abstract
func post_use(node: Node) -> void


func dropped() -> void:
	_rpc_enable_node.rpc()


@rpc("any_peer", "call_local", "reliable")
func _rpc_enable_node() -> void:
	set_deferred("process_mode", Node.PROCESS_MODE_INHERIT)


@rpc("any_peer", "call_local", "reliable")
func _rpc_disable_node() -> void:
	set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)


func _on_interactable_interacted(node: Node) -> void:
	if node is PlayerCharacter:
		if !node.inventory_component.is_inventory_full():
			node.inventory_component.add_item(self)
			_rpc_disable_node.rpc()
