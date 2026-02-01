extends Node3D

@export var agent_radius: float = 0.0

var points = {}

@onready var nav: AStar3D = AStar3D.new()


func _process(delta: float) -> void:
	for i in nav.get_point_count():
		var p: Vector3 = nav.get_point_position(i) - Vector3(2.0, 2.0, 2.0)
		DebugDraw3D.draw_aabb(AABB(p, Vector3(4.0, 4.0, 4.0)), Color.SEA_GREEN)


func add_points(data: VolumetricPoints, grid_step: float) -> void:
	if not is_instance_valid(data): return
	for p in data.points:
		_add_point(p, grid_step)
	_connect_points(grid_step)


func _add_point(point: Vector3, grid_step: float) -> void:
	var id := nav.get_available_point_id()
	nav.add_point(id, point)
	points[world_to_astar(point, grid_step)] = id


func _connect_points(grid_step: float) -> void:
	for point in points:
		var pos_str = point.split(",")
		var world_pos := Vector3(float(pos_str[0]), float(pos_str[1]), float(pos_str[2]))
		var search_coords = [-grid_step, 0, grid_step]
		for x in search_coords:
			for y in search_coords:
				for z in search_coords:
					var search_offset := Vector3(x, y, z)
					if search_offset == Vector3.ZERO:
						continue
					
					var potential_neighbor := world_to_astar(world_pos + search_offset, grid_step)
					if points.has(potential_neighbor):
						var current_id = points[point]
						var neighbor_id = points[potential_neighbor]
						if not nav.are_points_connected(current_id, neighbor_id):
							nav.connect_points(current_id, neighbor_id)


func find_path(from: Vector3, to: Vector3) -> PackedVector3Array:
	var start_id := nav.get_closest_point(from)
	var end_id := nav.get_closest_point(to)
	return nav.get_point_path(start_id, end_id)


func world_to_astar(world: Vector3, grid_step: float) -> String:
	var x = snapped(world.x, grid_step)
	var y = snapped(world.y, grid_step)
	var z = snapped(world.z, grid_step)
	return "%d,%d,%d" % [x, y, z]


func world_to_astar_vec3(world: Vector3, grid_step: float) -> Vector3:
	var x = snapped(world.x, grid_step)
	var y = snapped(world.y, grid_step)
	var z = snapped(world.z, grid_step)
	return Vector3(x, y, z)


func has_point(world: Vector3, grid_step: float) -> bool:
	var point: String = world_to_astar(world, grid_step)
	if !points.has(point):
		return false
	return nav.has_point(points[point])
