class_name Entity
extends CharacterBody3D

signal attacking

@export var movement: Movement

@export_group("Config/Attack")
@export var damage: float = 1.0

@export_group("Debug")
@export var debug_path: bool = false

var current_target: Node3D = null

var nav_region: VolumetricRegion

var path: PackedVector3Array = []

@onready var set_wandering_pos: Node = %SetWanderingPos


func _ready() -> void:
	var parent: Node = get_parent()
	if parent is VolumetricRegion:
		nav_region = parent
	while parent is not VolumetricRegion and parent != get_tree().current_scene:
		if parent is VolumetricRegion:
			nav_region = parent
			break
		parent = parent.get_parent()
	
	set_wandering_pos.from_point = global_position


func _process(delta: float) -> void:
	if debug_path:
		if path.size() > 0:
			var debug_path: PackedVector3Array = [global_position]
			debug_path.append_array(path)
			DebugDraw3D.draw_arrow_path(debug_path, Color.RED)


func _physics_process(delta: float) -> void:
	movement.tick(delta)


func attack() -> void:
	if !is_instance_valid(current_target): return
	
	current_target.health_component.modify(damage)
	attacking.emit()


func get_next_path_position() -> Vector3:
	if path.is_empty():
		return global_position
	var next: Vector3 = path[0]
	if path.size() <= 1: return next
	
	var dir_to_next: Vector3 = path[0].direction_to(path[1])
	var dir_to_actor: Vector3 = path[0].direction_to(global_position)
	
	var dot: float = dir_to_next.dot(dir_to_actor)
	if dot >= 0.0:
		path.remove_at(0)
	return path[0]


func set_path(_path: PackedVector3Array) -> void:
	path = _path


func get_last_path_pos() -> Vector3:
	if path.is_empty(): return global_position
	return path[-1]


func _on_ai_sensor_target_in_range(target: Node3D) -> void:
	current_target = target


func _on_health_component_health_changed(percent: float) -> void:
	if percent == 0.0:
		queue_free()
