class_name Interactor
extends Area3D

signal interaction_started(duration: float)
signal interaction_stopped()

@export var camera: Camera3D

var wants_interact: bool = false

var timer: Timer
var target: Interactable :
	set(v):
		if target:
			target.disable_preview()
			target.stop_interacting()
			_stop_timer()
		
		target = v
		
		if !(target and target.get_can_be_interacted(owner)):
			_stop_timer()


func _ready() -> void:
	timer = Timer.new()
	timer.one_shot = true
	timer.timeout.connect(_on_timer_timeout)
	add_child(timer)


func update() -> void:
	_check_for_targets()
	
	if !is_instance_valid(target): return
	
	if target.get_can_be_interacted(owner):
		target.enable_preview()
	
	if wants_interact:
		_try_start_timer()
	elif timer.time_left > 0.0:
		_stop_timer()


func _check_for_targets() -> void:
	var areas: Array[Area3D] = get_overlapping_areas()
	areas = areas.filter(_filter_interactable)
	if not areas.is_empty():
		areas.sort_custom(_sort_areas)
		var potential_target: Node = areas[0]
		
		if potential_target == target: return
		
		target = potential_target
		_stop_timer()
		timer.wait_time = target.interaction_time
	else:
		target = null


func _try_start_timer() -> void:
	if target.get_can_be_interacted(owner) and not timer.time_left > 0.0:
		target.start_interacting()
		timer.start()
		interaction_started.emit(timer.wait_time)


func _stop_timer() -> void:
	if target:
		target.stop_interacting()
	timer.stop()
	interaction_stopped.emit()


func _dot_to_node(node: Node3D) -> float:
	var dir: Vector3 = camera.global_position.direction_to(node.global_position)
	var dot: float = camera.global_basis.z.dot(dir)
	return dot


func _filter_interactable(a) -> bool:
	return a is Interactable


func _sort_areas(a: Node3D, b: Node3D) -> bool:
	var a_dot: float = _dot_to_node(a)
	var b_dot: float = _dot_to_node(b)
	return a_dot < b_dot


func _on_timer_timeout() -> void:
	if target:
		target.interact(owner)
