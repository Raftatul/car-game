extends Interactable


func get_can_be_interacted(node: Node) -> bool:
	if node is PlayerCharacter:
		return !is_instance_valid(node.item_in_hand)
	return false
