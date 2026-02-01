@tool
class_name VolumetricRegion
extends CSGBox3D

@export var terrain: Terrain3D

@export_range(0.5, 10.0, 0.5, "or_greater") var grid_step: float = 2.0

@export_tool_button("Bake") var bake_delegate = _generate_points

@export_dir var save_path: String = "" :
	set(v):
		save_path = v
		update_configuration_warnings()

@export_storage var data: VolumetricPoints


func _ready() -> void:
	if Engine.is_editor_hint(): return
	
	#visible = false
	VolumetricNavigation.add_points(data, grid_step)
	set_process(false)


func _get_configuration_warnings() -> PackedStringArray:
	var result: PackedStringArray = []
	
	if save_path == "":
		result.append("save_path is null!")
	
	return result


func _generate_points() -> void:
	var aabb: AABB = global_transform * get_aabb()
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
		if not obstacle is VisualInstance3D:
			continue
		var aabb: AABB = obstacle.global_transform * obstacle.get_aabb()
		if aabb.has_point(world_point):
			return false
	
	if terrain:
		var intersect: Vector3 = terrain.get_intersection(world_point + Vector3.UP * 100.0, Vector3.DOWN)
		return intersect.y < world_point.y
	return true
