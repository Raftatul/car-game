extends GameItem

@export var rope: Rope
@export var shoot_distance: float = 1.0
@export var pull_force: float = 1.0
@export_flags_3d_physics var harpoon_mask: int = 1

var pull_target: RigidBody3D
var end_offset: Vector3

@onready var end_anchor: Marker3D = $EndAnchor


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
	
	consume_energy(energy / float(use_count))


func _use(_delta: float) -> void:
	if pull_target:
		var dir: Vector3 = pull_target.global_position.direction_to(player.global_position)
		_server_rpc_pull_target.rpc(pull_target.get_path(), dir * pull_force)


func _post_use() -> void:
	_disconnect_rope()


func _connect_rope(node: Node3D, global_pos: Vector3) -> void:
	var distance: float = global_position.distance_to(global_pos)
	var relative_pos: Vector3 = Vector3.ZERO
	
	if node is RigidBody3D:
		pull_target = node
		relative_pos = pull_target.to_local(global_pos)
	
	_rpc_enable_rope.rpc(global_pos, relative_pos, distance)


func _disconnect_rope() -> void:
	pull_target = null
	_rpc_disable_rope.rpc()


@rpc("any_peer", "call_local", "reliable")
func _rpc_enable_rope(global_pos: Vector3, relative_pos: Vector3, distance: float) -> void:
	end_anchor.global_position = global_pos
	end_offset = relative_pos
	rope.rope_length = distance
	rope.process_mode = Node.PROCESS_MODE_ALWAYS
	rope.visible = true


@rpc("any_peer", "call_local", "reliable")
func _rpc_disable_rope() -> void:
	rope.process_mode = Node.PROCESS_MODE_DISABLED
	rope.visible = false


@rpc("any_peer", "call_local")
func _server_rpc_pull_target(node: NodePath, force:  Vector3) -> void:
	var body: RigidBody3D = get_tree().root.get_node(node)
	
	if !body: return
	
	body.apply_central_force(force)
	
	var distance: float = global_position.distance_to(body.global_position)
	rope.rope_length = distance
	end_anchor.global_position = body.global_transform * end_offset
