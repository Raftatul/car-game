extends GameItem

@export var force: float = 1.0

@onready var animation_player: AnimationPlayer = $jetpack/AnimationPlayer


func pre_use(_node: Node) -> void:
	animation_player.play("rotate")


func use(delta: float, node: Node) -> void:
	if node is PlayerCharacter:
		if node.buoyancy.is_in_water():
			node.velocity += node.visual.global_basis.y * force * delta


func post_use(_node: Node) -> void:
	animation_player.stop()
