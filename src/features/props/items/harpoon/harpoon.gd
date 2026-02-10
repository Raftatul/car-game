extends GameItem

@export var pull_rope: PullRope
@export var shoot_distance: float = 1.0
@export_flags_3d_physics var collision_mask: int = 1


func _pre_use() -> void:
	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var dir: Vector3 = -player.camera.global_basis.z
	var from: Vector3 = player.camera.global_position
	var to: Vector3 = from + dir * shoot_distance
	var excludes: Array[RID] = [player]
	
	var query := PhysicsRayQueryParameters3D.create(from, to, collision_mask, excludes)
	
	DebugDraw3D.draw_ray(from, dir, shoot_distance, Color.GREEN, 5.0)
	
	var result := space_state.intersect_ray(query)
	if result:
		DebugDraw3D.draw_sphere(result.position, 0.5, Color.RED, 5.0)
	
	consume_energy(energy / float(use_count))
