extends GameItem

@export var rope: Rope
@export var shoot_distance: float = 1.0
@export_flags_3d_physics var harpoon_mask: int = 1

@onready var end_anchor: Marker3D = $EndAnchor
@onready var pull_rope: PullRope = $PullRope


func _pre_use() -> void:
	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var dir: Vector3 = -player.camera.global_basis.z
	var from: Vector3 = player.camera.global_position
	var to: Vector3 = from + dir * shoot_distance
	var excludes: Array[RID] = [player]
	
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(from, to, harpoon_mask, excludes)
	
	var result: Dictionary = space_state.intersect_ray(query)
	if result:
		_connect_rope(result.collider, result.position)
		DebugDraw3D.draw_line(from, result.position, Color.GREEN, 5.0)
		DebugDraw3D.draw_sphere(result.position, 0.5, Color.RED, 5.0)
	else:
		DebugDraw3D.draw_ray(from, dir, shoot_distance, Color.GREEN, 5.0)
	
	consume_energy(energy / float(use_count))


func _post_use() -> void:
	_disconnect_rope()


func _connect_rope(node: Node3D, global_pos: Vector3) -> void:
	var distance: float = global_position.distance_to(global_pos)
	end_anchor.global_position = global_pos
	rope.end_anchor = end_anchor.get_path()
	rope.rope_length = distance
	rope.process_mode = Node.PROCESS_MODE_ALWAYS
	rope.visible = true


func _disconnect_rope() -> void:
	rope.end_anchor = ""
	rope.process_mode = Node.PROCESS_MODE_DISABLED
	rope.visible = false
