@tool
class_name VolumetricRegion
extends Node3D

#region Navigation

const SHORTCUT_SUBSTEP: int = 5

@export_group("Debug")
@export var debug_paths: bool = false
@export var debug_region: bool = false

@export_group("")

var points = {}

@onready var nav: AStar3D = AStar3D.new()


func _ready() -> void:
	if Engine.is_editor_hint(): return
	
	if volume:
		volume.visible = false
	
	add_points()


func _process(_delta: float) -> void:
	if debug_region:
		for i in nav.get_point_count():
			var p: Vector3 = nav.get_point_position(i) - Vector3.ONE * (grid_step / 2.0)
			DebugDraw3D.draw_aabb(AABB(p, Vector3.ONE * grid_step), Color.SEA_GREEN)


func add_points() -> void:
	if not is_instance_valid(data): return
	for p in data.points:
		_add_point(p)
	_connect_points()


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


func world_to_astar(world: Vector3) -> String:
	var x = snapped(world.x, grid_step)
	var y = snapped(world.y, grid_step)
	var z = snapped(world.z, grid_step)
	return "%d,%d,%d" % [x, y, z]


func world_to_astar_vec3(world: Vector3) -> Vector3:
	var x = snapped(world.x, grid_step)
	var y = snapped(world.y, grid_step)
	var z = snapped(world.z, grid_step)
	return Vector3(x, y, z)


func has_point(world: Vector3) -> bool:
	var point: String = world_to_astar(world)
	if !points.has(point):
		return false
	return nav.has_point(points[point])


func find_path(from: Vector3, to: Vector3) -> PackedVector3Array:
	var start_id := nav.get_closest_point(from)
	var end_id := nav.get_closest_point(to)
	return nav.get_point_path(start_id, end_id)


func get_shortest_path(from: Vector3, to: Vector3) -> PackedVector3Array:
	var path: PackedVector3Array = find_path(from, to)
	
	if debug_paths: DebugDraw3D.draw_arrow_path(path, Color.WHITE)
	
	if path.is_empty() || path.size() < 3:
		if has_point(to):
			path[-1] = to
		return path
	
	var idx: int = 0
	var short_path: PackedVector3Array = []
	for i in range(path.size()):
		var p: Vector3 = path[idx]
		short_path.append(p)
		
		if idx == path.size() - 1: break
		
		var flag: bool = false
		for j in range(path.size() - 1, idx, -1):
			var p_last: Vector3 = path[j]
			if _is_shortcut_valid(p, p_last):
				idx = j
				flag = true
				break
		
		if !flag:
			idx += 1
	
	if has_point(to):
		short_path[-1] = to
	
	return short_path


func _is_shortcut_valid(p1: Vector3, p2: Vector3) -> bool:
	var distance: float = p1.distance_to(p2)
	var loop_count: int = floor(distance / grid_step) * SHORTCUT_SUBSTEP
	for i in range(loop_count):
		var p_lerp: Vector3 = lerp(p1, p2, i / float(loop_count))
		if !has_point(p_lerp):
			return false
	return true

#endregion

#region Volumetric Region

const OFFSETS: PackedVector3Array = [
	Vector3(0, 0, 0),
	Vector3(1, 1, 1),
	Vector3(-1, 1, 1),
	Vector3(-1, -1, 1),
	Vector3(-1, -1, -1),
	Vector3(1, -1, -1),
	Vector3(1, 1, -1),
	Vector3(-1, 1, -1),
	Vector3(1, -1, 1)]

@export var volume: CSGBox3D
@export var terrain: Terrain3D

@export_range(0.5, 10.0, 0.5, "or_greater") var grid_step: float = 2.0

@export_tool_button("Bake") var bake_delegate = _generate_points

@export_dir var save_path: String = "" :
	set(v):
		save_path = v
		update_configuration_warnings()

@export_storage var data: VolumetricPoints


func _get_configuration_warnings() -> PackedStringArray:
	var result: PackedStringArray = []
	
	if save_path == "":
		result.append("save_path is null!")
	
	return result


func _generate_points() -> void:
	if !is_instance_valid(volume): return
	
	var aabb: AABB = volume.global_transform * volume.get_aabb()
	var start_point: Vector3 = aabb.position
	
	var x_steps = aabb.size.x / grid_step
	var y_steps = aabb.size.y / grid_step
	var z_steps = aabb.size.z / grid_step

	var _data = VolumetricPoints.new()
	
	for x in x_steps:
		for y in y_steps:
			for z in z_steps:
				var next_point := start_point + Vector3(x, y, z) * grid_step
				if _check_obstacles(get_children(), next_point):
					_data.points.append(next_point)
	
	if save_path:
		var path: String = "%s/%s_%s.tres" % [save_path, owner.name.to_snake_case(), name.to_snake_case()]
		var error: Error = ResourceSaver.save(_data, path)
		if error == OK:
			data = ResourceLoader.load(path)
		
		EditorInterface.get_resource_filesystem().scan()
	
	notify_property_list_changed()


func _check_obstacles(obstacles: Array, world_point: Vector3) -> bool:
	for obstacle in obstacles:
		if not obstacle is VisualInstance3D or obstacle == volume:
			continue
		var aabb: AABB = obstacle.global_transform * obstacle.get_aabb()
		
		for offset in OFFSETS:
			var point: Vector3 = world_point + offset * (grid_step / 2.0)
			if aabb.has_point(point):
				return false
	
	if terrain:
		for offset in OFFSETS:
			var point_of: Vector3 = world_point + offset * (grid_step / 2.0)
			var intersection: Vector3 = terrain.get_intersection(point_of, Vector3.DOWN, true)
			if intersection.y >= point_of.y:
				return false
		var p: Vector3 = world_point - Vector3.ONE * (grid_step / 2.0)
		DebugDraw3D.draw_aabb(AABB(p, Vector3.ONE * grid_step), Color.SEA_GREEN, 10.0)
	return true

#endregion
