extends Interactable


func get_can_be_interacted(node: Node) -> bool:
	if node is PlayerCharacter:
		return !node.inventory_component.is_inventory_full()
	return false
