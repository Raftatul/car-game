extends Node3D

@export var grid_step: float = 2.0
@export var agent_radius: float = 0.0

var points = {}

@onready var nav: AStar3D = AStar3D.new()


func add_points(data: VolumetricPoints) -> void:
	if not is_instance_valid(data): return
	for p in data.points:
		_add_point(p)
	_connect_points()


func _check_obstacles(obstacles: Array, world_point: Vector3) -> bool:
	for obstacle in obstacles:
		var aabb: AABB = obstacle.global_transform * obstacle.get_aabb()
		if aabb.has_point(world_point):
			return false
	return true


func _add_point(point: Vector3) -> void:
	var id := nav.get_available_point_id()
	nav.add_point(id, point)
	points[world_to_astar(point)] = id


func _connect_points() -> void:
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
					
					var potential_neighbor := world_to_astar(world_pos + search_offset)
					if points.has(potential_neighbor):
						var current_id = points[point]
						var neighbor_id = points[potential_neighbor]
						if not nav.are_points_connected(current_id, neighbor_id):
							nav.connect_points(current_id, neighbor_id)


func find_path(from: Vector3, to: Vector3) -> PackedVector3Array:
	var start_id := nav.get_closest_point(from)
	var end_id := nav.get_closest_point(to)
	return nav.get_point_path(start_id, end_id)


func world_to_astar(world: Vector3) -> String:
	var x = snapped(world.x, grid_step)
	var y = snapped(world.y, grid_step)
	var z = snapped(world.z, grid_step)
	return "%d,%d,%d" % [x, y, z]
