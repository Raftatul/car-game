extends RigidBody3D

@export var move_force: float = 10.0

@onready var area: Area3D = $Area3D


func _physics_process(delta: float) -> void:
	var bodies: Array[Node3D] = area.get_overlapping_bodies().filter(_filter_players)
	var avr_pos: Vector3 = _get_average_pos(bodies)
	apply_central_force(avr_pos * move_force)


func _get_average_pos(bodies: Array[Node3D]) -> Vector3:
	var average_pos: Vector3 = Vector3.ZERO
	if bodies.is_empty():
		return average_pos
	
	for body in bodies:
		average_pos += to_local(body.global_position)
	return average_pos / bodies.size()


func _filter_players(a: Node) -> bool:
	return a is PlayerCharacter
