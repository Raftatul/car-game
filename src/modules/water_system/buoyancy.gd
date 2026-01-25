@tool
class_name Buoyancy
extends Node3D

signal water_entered
signal water_exited

@export var active: bool = true :
	set(value):
		active = value

@export var points: Array[Node3D]
@export_tool_button("Add Point") var add_point_delegate = _add_point

@export_range(0.0, 1.0, 0.01) var submerge_floor := 0.5
@export var bounciness := 1.0

@export_group("Drags")
@export var buo_damping := 0.05
@export var water_angular_drag := 0.1

@export_group("Debug")
@export var debug := false

var submerged := false
var submerged_percent := 0.0

var parent: Node3D = null

@onready var points_count = points.size()
@onready var water_body: WaterBody = get_tree().get_first_node_in_group("water_body")
@onready var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")


func _ready() -> void:
	parent = get_parent()


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	
	submerged_percent = 0.0
	
	for p in points:
		var point_position = p.global_position
		var depth = water_body.compute_wave_height(point_position) - point_position.y
		
		if depth > 0.0:
			var force = bounciness * gravity * depth
			
			if active:
				if debug:
					DebugDraw3D.draw_arrow(point_position, point_position + Vector3.UP * depth, Color.GREEN, 0.1)
				var relative_position = parent.to_local(point_position)
				_apply_force(delta, force, relative_position)
			
			submerged_percent += 1.0
		elif debug and active:
			DebugDraw3D.draw_arrow(point_position + Vector3.DOWN * depth, point_position , Color.RED, 0.1)
	
	submerged_percent /= points_count
	
	if submerged_percent < submerge_floor and submerged != false:
		submerged = false
		water_exited.emit()
	elif submerged_percent >= submerge_floor and submerged != true:
		submerged = true
		water_entered.emit()


func is_in_water() -> bool:
	return submerged


func get_depth() -> float:
	return water_body.compute_wave_height(global_position) - global_position.y


func _apply_force(delta: float, force: float, relative_position: Vector3) -> void:
	if parent is RigidBody3D:
		parent.apply_force(Vector3.UP * force, relative_position)
		
		if parent.linear_velocity.y > 0.0:
			parent.linear_velocity.y *= max(0.0, 1.0 - buo_damping / points_count)
		
		parent.angular_velocity *= max(0.0, 1.0 - water_angular_drag / points_count)
	elif parent is CharacterBody3D:
		parent.velocity += Vector3.UP * force * delta
		
		if parent.velocity.y > 0.0:
			parent.velocity.y *= 1.0 - buo_damping / points_count


func _add_point() -> void:
	if not is_inside_tree():
		return
	
	var _parent = get_parent().get_node(get_path())
	var node = Marker3D.new()
	node.name = "Pontoon"
	_parent.add_child(node, true)
	points.append(node)
	node.owner = owner
	
	notify_property_list_changed()
