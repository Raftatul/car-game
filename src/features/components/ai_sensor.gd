class_name AISensor
extends Area3D

signal target_in_range(_target: Node3D)
signal target_out_of_range()

@export var target_group: StringName = ""

var target: Node3D :
	set(v):
		if target:
			target_out_of_range.emit()
			
		target = v
		
		if target:
			target_in_range.emit(target)


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _get_overlapping_target() -> Node3D:
	var bodies: Array = get_overlapping_bodies()
	bodies.filter(_filter_targets)
	if !bodies.is_empty():
		return bodies[0]
	return null


func _filter_targets(a: Node3D) -> bool:
	return a.is_in_group(target_group)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group(target_group):
		target = body


func _on_body_exited(body: Node) -> void:
	if body == target:
		target = _get_overlapping_target()
